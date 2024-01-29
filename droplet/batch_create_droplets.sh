#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"
droplet_name_prefix="${DO_DROPLET_NAME_PREFIX:-my-droplet}"
droplet_region="${DO_DROPLET_REGION:-nyc1}"
droplet_size="${DO_DROPLET_SIZE:-s-1vcpu-1gb}"
droplet_image="${DO_DROPLET_IMAGE:-ubuntu-20-04-x64}"
number_of_droplets="${DO_NUMBER_OF_DROPLETS:-5}"

# Prompt for tag (optional)
read -p "Enter an optional tag for the new droplets (leave empty for no tag): " droplet_tag
tag_json=""
if [ ! -z "$droplet_tag" ]; then
    tag_json=",\"tags\":[\"$droplet_tag\"]"
fi

# Create Droplets and Output List
echo "Creating droplets..."
created_droplet_ids=()
for (( i=1; i<=number_of_droplets; i++ ))
do
    droplet_name="${droplet_name_prefix}-${i}"
    create_response=$(curl -X POST "https://api.digitalocean.com/v2/droplets" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$droplet_name\",\"region\":\"$droplet_region\",\"size\":\"$droplet_size\",\"image\":\"$droplet_image\"$tag_json}")

    created_droplet_id=$(echo $create_response | jq -r '.droplet.id')
    created_droplet_ids+=("$created_droplet_id")
    echo "Created droplet: $droplet_name (ID: $created_droplet_id)"
done

# Fetch and list Firewalls
echo "Fetching available firewalls..."
firewalls_response=$(curl -X GET "https://api.digitalocean.com/v2/firewalls" \
    -H "Authorization: Bearer $api_token")

echo "Available firewalls:"
echo "$firewalls_response" | jq -r '.firewalls[] | "\(.name) - ID: \(.id)"'

# Optional Firewall Attachment
read -p "Do you want to attach a firewall to the created droplets? (yes/no): " attach_firewall
if [ "$attach_firewall" == "yes" ]; then
    read -p "Enter the Firewall ID: " firewall_id

    # Convert droplet IDs to JSON array
    droplet_ids_json=$(echo "${created_droplet_ids[@]}" | jq -R 'split(" ") | map(tonumber)')

    # Attach Firewall to Droplets
    firewall_response=$(curl -X POST "https://api.digitalocean.com/v2/firewalls/$firewall_id/droplets" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        -d "{\"droplet_ids\":$droplet_ids_json}")

    echo "Firewall attachment response: $firewall_response"
else
    echo "Skipping firewall attachment."
fi

# Final Output
echo "Creation process complete."
