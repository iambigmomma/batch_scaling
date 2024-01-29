#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"

# Fetch and list Load Balancers
echo "Fetching available load balancers..."
lbs_response=$(curl -X GET "https://api.digitalocean.com/v2/load_balancers" \
    -H "Authorization: Bearer $api_token")

echo "Available load balancers:"
echo "$lbs_response" | jq -r '.load_balancers[] | "\(.name) - ID: \(.id), Region: \(.region.slug)"'

# Prompt for Load Balancer ID
read -p "Enter the ID of the Load Balancer: " load_balancer_id

# Prompt for tag
read -p "Enter the tag for selecting droplets to remove from the load balancer: " droplet_tag

# Fetch Droplets with the specified tag
droplets_response=$(curl -X GET "https://api.digitalocean.com/v2/droplets?tag_name=$droplet_tag" \
    -H "Authorization: Bearer $api_token")

droplet_ids=$(echo "$droplets_response" | jq -r '.droplets[] | .id')
droplet_names=$(echo "$droplets_response" | jq -r '.droplets[] | .name')

if [ -z "$droplet_names" ]; then
    echo "No droplets found with the tag '$droplet_tag'."
    exit 1
fi

echo "Droplets with tag '$droplet_tag':"
echo "$droplet_names"

# Confirm removal
read -p "Are you sure you want to remove these droplets from the load balancer? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Droplet removal cancelled."
    exit 1
fi

# Convert droplet IDs to JSON array
droplet_ids_json=$(echo $droplet_ids | jq -R 'split(" ") | map(tonumber)')

# Remove Droplets from Load Balancer
remove_response=$(curl -X DELETE "https://api.digitalocean.com/v2/load_balancers/$load_balancer_id/droplets" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    -d "{\"droplet_ids\":$droplet_ids_json}")

# Parse and display the response
if [ "$(echo "$remove_response" | jq -r '.id')" != "null" ]; then
    echo "Droplets successfully removed from the load balancer."
else
    echo "Failed to remove droplets from the load balancer."
    echo "Error: $(echo "$remove_response" | jq -r '.message')"
fi
