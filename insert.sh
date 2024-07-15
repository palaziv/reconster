#!/bin/bash

dir=$1
programName=$(basename "$dir")

# check if bbrf program already exists
output=$(bbrf programs --show-empty-programs)
if echo "$output" | grep -qw "$programName"; then
    echo "BBRF: program $programName found"
else
    echo "BBRF: program not found. Creating one using 'bbrf new $programName'..."
    bbrf new $programName
fi

# first add all found subdomains even unresolved ones
cat "$dir/all_subs.txt" | bbrf domain add - -p $programName -s recon

file_name="$dir/resolved_with_ips.txt"

while read -r line; do
    bbrf domain add $line -p $programName -s recon
done < $file_name