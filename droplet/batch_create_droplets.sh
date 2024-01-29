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
created_droplets=()
for (( i=1; i<=number_of_droplets; i++ ))
do
    droplet_name="${droplet_name_prefix}-${i}"
    create_response=$(curl -X POST "https://api.digitalocean.com/v2/droplets" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$droplet_name\",\"region\":\"$droplet_region\",\"size\":\"$droplet_size\",\"image\":\"$droplet_image\"$tag_json}")

    created_droplet_name=$(echo $create_response | jq -r '.droplet.name')
    created_droplets+=("$created_droplet_name")
    echo "Created droplet: $created_droplet_name"
done

# Final Output
echo "List of created droplets:"
for droplet in "${created_droplets[@]}"; do
    echo "$droplet"
done

echo "Creation process complete."
