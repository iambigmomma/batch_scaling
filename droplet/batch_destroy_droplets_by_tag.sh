#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"

# Prompt for tag
read -p "Enter the tag for the droplets to destroy: " droplet_tag

# Get Droplet IDs and Names
droplets_info=$(curl -X GET "https://api.digitalocean.com/v2/droplets?tag_name=$droplet_tag" \
    -H "Authorization: Bearer $api_token" \
    | jq '.droplets[] | {id: .id, name: .name}')

echo "Droplets with tag '$droplet_tag':"
echo "$droplets_info"

# Confirm destruction
read -p "Are you sure you want to destroy these droplets? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Droplet destruction cancelled."
    exit 1
fi

# Destroy Droplets and Output List
echo "Destroying droplets..."
destroyed_droplets=()
for row in $(echo "${droplets_info}" | jq -r '. | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    droplet_id=$(_jq '.id')
    droplet_name=$(_jq '.name')

    destroy_response=$(curl -X DELETE "https://api.digitalocean.com/v2/droplets/$droplet_id" \
        -H "Authorization: Bearer $api_token")

    destroyed_droplets+=("$droplet_name")
    echo "Destroyed droplet: $droplet_name"
done

# Final Output
echo "List of destroyed droplets:"
for droplet in "${destroyed_droplets[@]}"; do
    echo "$droplet"
done

echo "Destruction process complete."
