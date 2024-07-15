#!/bin/bash

recon() {
        dir=$1
        programName=$2

        echo "Gathering subs for $programName..."
        subfinder -dL "${dir}/rootdomain.txt" -all -silent | anew -q "${dir}/all_subs.txt"

        echo "Resolving found subdomains..."
        # Run dnsx and store output in a temporary file
        dnsx -l "${dir}/all_subs.txt" -silent -a -resp -nc | tr -d '[]' > "${dir}/dnsx.tmp"
        awk '{print $1}' "${dir}/dnsx.tmp" | anew -q "${dir}/resolved.txt"
        awk '{print $1":"$3}' "${dir}/dnsx.tmp" | anew -q "${dir}/resolved_with_ips.txt"
        rm "${dir}/dnsx.tmp"

        echo "Gathering http metadata..."
        # probe both http and https with "-no-fallback"
        # TODO: check if we can use -q with anew or if the output is necessary
        httpx -silent -l "${dir}/resolved.txt" -no-fallback -ports 80,443,4000,4443,4080,8000,8080,8443,8888,9090 -sc -title -ct -location -server -td -method -ip -cname -cdn -nc | anew -q "${dir}/metadata.txt"

        echo "Separating subs by status code..."
        grep '\[200\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/200.txt"
        grep '\[301\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/301.txt"
        grep '\[302\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/302.txt"
        grep '\[401\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/401.txt"
        grep '\[403\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/403.txt"
        grep '\[404\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/404.txt"
        grep '\[500\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/500.txt"
        grep '\[502\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/502.txt"
        grep '\[503\]' "${dir}/metadata.txt" | cut -d " " -f 1 | cut -d "/" -f 3 > "${dir}/503.txt"

        echo "Inserting records into the database..."
        programName=$(basename "$dir")
        python3 "./insert.py" "${dir}/all_subs.txt" ${programName}

        echo "Updating status codes..."
        python3 "./update.py" "${dir}" ${programName} 
}

# Checking if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
        echo "Usage: $0 /path/to/directory program/organization name"
        exit 1
fi

# Extract provided arguments
dir=$1
programName=$2

recon $dir $programName