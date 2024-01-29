# DigitalOcean Droplet and Load Balancer Management Scripts

This repository contains a collection of scripts organized into separate folders for automating various operations related to DigitalOcean droplets and load balancers. These scripts use the DigitalOcean API to perform batch operations on droplets and manage their association with load balancers.

## Folder Structure

- `droplet/`: Scripts related to droplet management.
- `lb/`: Scripts related to load balancer management.

## Scripts

### Droplet Management (`droplet/` folder)

#### 1. Batch Create Droplets
`droplet/batch_create_droplets.sh`: Automates the creation of a specified number of DigitalOcean droplets with optional tagging. It prompts for configuration details and an optional tag.

#### 2. Batch Delete Droplets
`droplet/batch_delete_droplets.sh`: Facilitates the batch deletion of DigitalOcean droplets based on a specified tag. It lists available tags, allows tag selection, and deletes the associated droplets after confirmation.

### Load Balancer Management (`lb/` folder)

#### 3. Batch Add Droplets to Load Balancer
`lb/batch_add_to_lb.sh`: Enables batch addition of droplets to a specified load balancer's backend pool. It lists available load balancers, prompts for a load balancer ID, and adds droplets based on a specified tag after confirmation.

#### 4. Batch Remove Droplets from Load Balancer
`lb/batch_remove_from_lb.sh`: Allows for batch removal of droplets from a specified load balancer's backend pool. The user selects a load balancer and a tag, and the script removes the droplets after confirmation.

## Prerequisites
- DigitalOcean API Token (`DO_API_TOKEN` environment variable).
- `curl` command-line tool for making API requests.
- `jq` command-line tool for parsing JSON responses.

## Usage
Set the `DO_API_TOKEN` environment variable with your DigitalOcean API token before running the scripts. Each script guides through the required inputs and is run in a bash-compatible shell.

## Disclaimer
These scripts are for convenience and should be used responsibly. Test them in a safe environment before production use. We are not responsible for unintended consequences.

## License
These scripts are released under the MIT License.
