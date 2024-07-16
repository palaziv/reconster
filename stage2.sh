#!/bin/bash

recon() {
        dir=$1
        programName=$2

        echo "Gathering subdomains for $programName..."
        subfinder -dL "${dir}/rootdomain.txt" -all -silent | anew -q "${dir}/all_subs.txt"

        echo "Resolving found subdomains..."
        # Run dnsx and store output in a temporary file
        dnsx -l "${dir}/all_subs.txt" -silent -a -resp -nc | tr -d '[]' > "${dir}/dnsx.tmp"
        awk '{print $1}' "${dir}/dnsx.tmp" | anew -q "${dir}/resolved.txt"
        awk '{print $1":"$3}' "${dir}/dnsx.tmp" | anew -q "${dir}/resolved_with_ips.txt"
        rm "${dir}/dnsx.tmp"

        echo "Gathering http metadata..."
        # probe both http and https with "-no-fallback"
        httpx -silent -l "${dir}/resolved.txt" -no-fallback -ports 80,443,4000,4443,4080,8000,8080,8443,8888,9090 -j | anew -q "${dir}/metadata.txt"

        # TODO: gowitness
        cat "$dir/metadata.txt" | jq -r '.url' | gowitness file -f - --screenshot-path "${dir}/screenshots"

        # TODO: dorking (https://github.com/xnl-h4ck3r/xnldorker/tree/main)
        # TODO: waymore + katana

        echo "Adding to BBRF..."
        ./insert.sh $dir
}

if [ "$#" -ne 2 ]; then
        echo "Usage: $0 /path/to/directory program/organization name"
        exit 1
fi

dir=$1
programName=$2

recon $dir $programName