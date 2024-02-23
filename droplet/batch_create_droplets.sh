#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"
default_droplet_image="ubuntu-20-04-x64"
default_droplet_name_prefix="my-droplet"
default_droplet_region="nyc3"
default_droplet_size="s-4vcpu-8gb-amd"
default_number_of_droplets=3

# Fetch and list SSH Keys
echo "Fetching available SSH keys..."
ssh_keys_response=$(curl -X GET "https://api.digitalocean.com/v2/account/keys" \
    -H "Authorization: Bearer $api_token")

echo "Available SSH keys:"
echo "$ssh_keys_response" | jq -r '.ssh_keys[] | "\(.name) - ID: \(.id)"'

# Prompt for SSH Key IDs
read -p "Enter the SSH Key IDs to attach to the new droplets (comma-separated): " input_ssh_key_ids
# Format the input as an array
attach_ssh_keys="[$(echo $input_ssh_key_ids | sed 's/, */,/g')]"

# Continue with your script...

# Fetch and list Projects
echo "Fetching available projects..."
projects_response=$(curl -X GET "https://api.digitalocean.com/v2/projects" \
    -H "Authorization: Bearer $api_token")

echo "Available projects:"
echo "$projects_response" | jq -r '.projects[] | "\(.name) - ID: \(.id)"'

# Prompt for Project ID
read -p "Enter the Project ID to associate with the new droplets: " project_id

# Prompt for Image Source (OS image or Snapshot) with default
read -p "Do you want to create droplets from an OS image or restore from a snapshot? (os/snapshot) [os]: " image_source
image_source=${image_source:-os}
droplet_image=""

if [ "$image_source" == "snapshot" ]; then
    # Fetch and list Snapshots
    echo "Fetching available droplet snapshots..."
    snapshots_response=$(curl -X GET "https://api.digitalocean.com/v2/snapshots?resource_type=droplet" \
        -H "Authorization: Bearer $api_token")

    echo "Available snapshots:"
    echo "$snapshots_response" | jq -r '.snapshots[] | "\(.name) - ID: \(.id)"'

    # Prompt for Snapshot ID
    read -p "Enter the Snapshot ID to use for creating droplets: " droplet_image
else
    # Default OS Image
    droplet_image=$default_droplet_image
fi

# Other Configuration Inputs with defaults
read -p "Enter droplet name prefix [${default_droplet_name_prefix}]: " droplet_name_prefix
droplet_name_prefix=${droplet_name_prefix:-$default_droplet_name_prefix}

read -p "Enter droplet region (e.g., nyc1) [${default_droplet_region}]: " droplet_region
droplet_region=${droplet_region:-$default_droplet_region}

read -p "Enter droplet size (e.g., s-1vcpu-1gb) [${default_droplet_size}]: " droplet_size
droplet_size=${droplet_size:-$default_droplet_size}

read -p "Enter the number of droplets to create [${default_number_of_droplets}]: " number_of_droplets
number_of_droplets=${number_of_droplets:-$default_number_of_droplets}

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
        -d "{\"name\":\"$droplet_name\",\"region\":\"$droplet_region\",\"size\":\"$droplet_size\",\"image\":\"$droplet_image\"$tag_json,\"ssh_keys\":${attach_ssh_keys}}")

    # Check if the droplet was created successfully
    if [ "$(echo "$create_response" | jq -r '.droplet')" != "null" ]; then
        created_droplet_id=$(echo $create_response | jq -r '.droplet.id')
        created_droplet_ids+=("$created_droplet_id")
        echo "Created droplet: $droplet_name (ID: $created_droplet_id)"
    else
        echo "Failed to create droplet: $droplet_name"
        echo "Error: $(echo "$create_response" | jq -r '.message')"
        exit 1
    fi
    sleep 1
done
# Fetch and list Firewalls
echo "Fetching available firewalls..."
firewalls_response=$(curl -X GET "https://api.digitalocean.com/v2/firewalls" \
    -H "Authorization: Bearer $api_token")

echo "Available firewalls:"
echo "$firewalls_response" | jq -r '.firewalls[] | "\(.name) - ID: \(.id)"'

# Prompt for Firewall ID (optional)
read -p "Enter the Firewall ID to attach to the created droplets (leave empty for no attachment): " firewall_id

if [ ! -z "$firewall_id" ]; then
    # Convert droplet IDs to JSON array
    droplet_ids_json=$(printf ', %s' "${created_droplet_ids[@]}")
    droplet_ids_json="[${droplet_ids_json:2}]" # Remove leading comma and space

    # Attach Firewall to Droplets
    firewall_response=$(curl -X POST "https://api.digitalocean.com/v2/firewalls/$firewall_id/droplets" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" \
        -d "{\"droplet_ids\": $droplet_ids_json}")

    echo "Firewall attachment response: $firewall_response"
else
    echo "Skipping firewall attachment."
fi

# Attach Droplets to Project
resources_json=$(printf ', "do:droplet:%s"' "${created_droplet_ids[@]}")
resources_json="[${resources_json:2}]" # Remove leading comma and space

project_attachment_response=$(curl -X POST "https://api.digitalocean.com/v2/projects/$project_id/resources" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    -d "{\"resources\": $resources_json}")

echo "Project attachment response: $project_attachment_response"

# Final Output
echo "Creation process complete."
