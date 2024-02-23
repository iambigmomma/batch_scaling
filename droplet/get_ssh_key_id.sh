#!/bin/bash

# Configuration from Environment Variables
api_token="${DO_API_TOKEN}"




# Get SSH Key IDs and Names
sshkey_info=$(curl -X GET -H "Content-Type: application/json" \
  -H "Authorization: Bearer $api_token" \
  "https://api.digitalocean.com/v2/account/keys" | jq -r '.ssh_keys[]')

echo "List of SSH Key:"
echo "$sshkey_info"
