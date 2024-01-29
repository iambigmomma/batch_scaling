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
read -p "Enter the tag for selecting droplets to add to the load balancer: " droplet_tag

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

# Confirm addition
read -p "Are you sure you want to add these droplets to the load balancer? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Droplet addition cancelled."
    exit 1
fi

# Convert droplet IDs to JSON array
droplet_ids_json=$(echo $droplet_ids | jq -R 'split(" ") | map(tonumber)')

# Add Droplets to Load Balancer
add_response=$(curl -X POST "https://api.digitalocean.com/v2/load_balancers/$load_balancer_id/droplets" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    -d "{\"droplet_ids\":$droplet_ids_json}")

# Parse and display the response
if [ "$(echo "$add_response" | jq -r '.id')" != "null" ]; then
    echo "Droplets successfully added to the load balancer."
else
    echo "Failed to add droplets to the load balancer."
    echo "Error: $(echo "$add_response" | jq -r '.message')"
fi
