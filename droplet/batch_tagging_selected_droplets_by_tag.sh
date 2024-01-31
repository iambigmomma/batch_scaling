#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"

# Prompt for existing tag to select droplets
read -p "Enter the existing tag to select droplets: " existing_tag

# Fetch Droplets with the specified tag
droplets_response=$(curl -X GET "https://api.digitalocean.com/v2/droplets?tag_name=$existing_tag" \
    -H "Authorization: Bearer $api_token")

droplet_ids=$(echo "$droplets_response" | jq -r '.droplets[] | .id')
droplet_names=$(echo "$droplets_response" | jq -r '.droplets[] | .name')

echo "Droplets with tag '$existing_tag':"
echo "$droplet_names"

# Check if droplets are found
if [ -z "$droplet_ids" ]; then
    echo "No droplets found with the tag '$existing_tag'."
    exit 1
fi

# Prompt for action: add or remove tags
read -p "Do you want to add or remove tags? (add/remove): " action

# Function to create a new tag
create_tag() {
    tag_name="$1"
    curl -X POST "https://api.digitalocean.com/v2/tags" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$tag_name\"}"
}

# Add or Remove Tags
if [ "$action" == "add" ]; then
    read -p "Enter comma-separated tags to add: " tags_to_add
    IFS=',' read -r -a tags <<< "$tags_to_add"
    for tag in "${tags[@]}"
    do
        # Create the tag if it doesn't exist
        create_tag_response=$(create_tag "$tag")
        echo "Create tag '$tag' response: $create_tag_response"
        
        # Correctly format droplet_ids as a JSON array
        resources_json=$(echo "$droplet_ids" | jq -R 'split(" ") | map({"resource_id": ., "resource_type": "droplet"})'| sed '$!{N;s/]\n\[/,/;P;D;}')

        # Add new tags to each droplet
        add_tag_response=$(curl -X POST "https://api.digitalocean.com/v2/tags/$tag/resources" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" \
            -d "{\"resources\": $resources_json}")
        echo "Added tag '$tag' to droplets successfully!"
    done
elif [ "$action" == "remove" ]; then
    read -p "Enter comma-separated tags to remove: " tags_to_remove
    IFS=',' read -r -a tags <<< "$tags_to_remove"
    for tag in "${tags[@]}"
    do
        # Correctly format droplet_ids as a JSON array
        resources_json=$(echo "$droplet_ids" | jq -R 'split(" ") | map({"resource_id": ., "resource_type": "droplet"})'| sed '$!{N;s/]\n\[/,/;P;D;}')

        # Remove tags from each droplet
        remove_tag_response=$(curl -X DELETE "https://api.digitalocean.com/v2/tags/$tag/resources" \
            -H "Authorization: Bearer $api_token" \
            -H "Content-Type: application/json" \
            -d "{\"resources\": $resources_json}")
        echo "Removed tag '$tag' from droplets successfully!"
    done
else
    echo "Invalid action selected."
fi
