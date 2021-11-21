#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

add_vyos_user() {
  user=$1
  keytype=$2
  key=$3

  configure
  set system login user "$user" authentication public-keys "$user" type "$keytype"
  set system login user "$user" authentication public-keys "$user" key "$key"
  commit
  exit
}

provision_users() {
  WAIT=$1
  TIMEOUT=$2
  METADATA_SSH_EP="http://metadata.google.internal/computeMetadata/v1/project/attributes/ssh-keys?alt=text&wait_for_change=$WAIT&timeout_sec=$TIMEOUT"
  METADATA_REGEXP='([a-zA-Z_]+):([^ ]+) ([^ ]+).*'

  echo "Fetching metadata keys, wait=$WAIT, TIMEOUT=$TIMEOUT"
  curl -s $METADATA_SSH_EP -H "Metadata-Flavor: Google" | while read -r line
  do
    if [[ $line =~ $METADATA_REGEXP ]]; then
      username=${BASH_REMATCH[1]}
      keytype=${BASH_REMATCH[2]}
      key=${BASH_REMATCH[3]}
      echo -e "---------\nFound key\n---------\nUser: $username\nKeytype: $keytype\nkey: $key\n\n"
      add_vyos_user "$username" "$keytype" "$key"
    fi
  done
}

# Perform a first run without waiting
provision_users "false" 0

# From now on, start a waiter that provisions new users
while true
do
  provision_users "true" 60
done