#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"

# Initialize variables for pagination
page=1
per_page=20 # Adjust per_page as needed
has_next_page=true

echo "List of Snapshot:"

# Loop through all pages of snapshots
while [ "$has_next_page" = true ]; do
    response=$(curl -s -X GET -H "Content-Type: application/json" \
      -H "Authorization: Bearer $api_token" \
      "https://api.digitalocean.com/v2/snapshots?resource_type=droplet&page=$page&per_page=$per_page")

    # Extract and print snapshot information from current page
    echo "$response" | jq -r '.snapshots[] | "\(.name) - ID: \(.id)"'
    
    # Determine if there is a next page
    next_page=$(echo "$response" | jq -r '.links.pages.next')
    if [ "$next_page" != "null" ]; then
        ((page++))
    else
        has_next_page=false
    fi
done


