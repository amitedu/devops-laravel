#!/bin/bash

my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

source $my_path/../common/helpers.sh

title "Existing Applications"

# Ensure the apps directory exists
if [[ ! -d $my_path/../apps ]]; then
  sudo mkdir -p $my_path/../apps
fi

existing_apps=$(ls $my_path/../apps/ 2>/dev/null | grep '\.sh$' | grep -v '^_app\.sh$' | sed -e 's|\.[^.]*$||')

if [ -z "$existing_apps" ]; then
  status "No applications currently installed."
else
  echo "$existing_apps"
fi
echo ""
echo ""

