#!/bin/bash

baseDir="$(pwd)/recon"

read -p "Enter organization name: " org_name

read -p "Enter root domains (separated by spaces): " root_domains

if [ ! -d "${baseDir}/${org_name}" ]; then
        mkdir ${baseDir}/${org_name}
        echo "Created directory: '$org_name'"
        for domain in ${root_domains}; do
            echo ${domain} >> "${baseDir}/${org_name}/rootdomain.txt"
        done
else
        echo "'$org_name' already exists."
        echo "Finding subdomains..."
fi

./stage2.sh "${baseDir}/${org_name}" $org_name
