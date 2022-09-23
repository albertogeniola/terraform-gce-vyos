#!/bin/bash
# Args check
if [ $# -ne 4 ]
  then
    echo "Missing required arguments."
    exit 1
fi

API_HOST=$1
API_PORT=$2
API_KEY=$3
API_KEY_NAME=$4

# Sets up the API endpoint for later use
source /opt/vyatta/etc/functions/script-template
configure
set service https api-restrict virtual-host "$API_HOST"
set service https api port $API_PORT
set service https api keys id "$API_KEY_NAME" key "$API_KEY"
commit
exit
