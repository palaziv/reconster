#!/bin/bash

dir=$1
programName=$(basename "$dir")

# check if bbrf program already exists
output=$(bbrf programs --show-empty-scope)
if echo "$output" | grep -qw "$programName"; then
    echo "BBRF: program $programName found"
else
    echo "BBRF: program not found. Creating one using 'bbrf new $programName'..."
    bbrf new $programName

    read -p "Enter inscope domains/IPs (separated by spaces; note that this is required): " inscope
    if [ -z "$inscope" ]; then
        bbrf inscope add $inscope -p $programName
    else
        echo "No inscope specified. Exiting ..."
        exit 1
    fi

    read -p "Enter outscope domains/IPs (separated by spaces): " outscope
    if [ -z "$outscope" ]; then
        bbrf outscope add $outscope -p $programName
    fi
fi

echo "BBRF: adding subdomains..."
# first add all found subdomains even unresolved ones
cat "$dir/all_subs.txt" | bbrf domain add - -p $programName -s subfinder

# now add/update resolved domains with their ips
cat "$dir/resolved_with_ips.txt" | bbrf domain add - -p $programName -s dnsx
# add does not work when the domain already exists, so do an update
cat "$dir/resolved_with_ips.txt" | bbrf domain update - -p $programName -s dnsx

echo "BBRF: adding URLs..."
# add urls with status code and content length
#cat "$dir/metadata.txt" | awk '{print $1" "$2" "$4}' | tr -d '[]' | bbrf url add - -p $programName -s httpx

while IFS= read -r line; do
    # Use jq to extract the necessary fields
    url=$(echo "$line" | jq -r '.url')
    status_code=$(echo "$line" | jq -r '.status_code')
    content_length=$(echo "$line" | jq -r '.content_length')
    title=$(echo "$line" | jq -r '.title')
    location=$(echo "$line" | jq -r '.location')
    webserver=$(echo "$line" | jq -r 'if .webserver then .webserver else "" end')
    tech_list=$(echo "$line" | jq -r 'if .tech then .tech else [] end')
  
    # construct the bbrf command with the extracted fields
    cmd="bbrf url add \"$url\" \"$status_code\" \"$content_length\" -t title:\"$title\" -t location:\"$location\" -t webserver:\"$webserver\""

    # Add a tag for each technology
    for tech in $(echo "$tech_list" | jq -r '.[]'); do
        cmd="$cmd -t tech:\"$tech\""
    done

    eval $cmd
done < $dir/metadata.txt