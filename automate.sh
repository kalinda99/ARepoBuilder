#!/bin/bash
source $(pwd)/include.sh # Call the include script so we can use our functions and variables
export ckupdate=true
export firstbuild=false
date=$(date)

echo "Automated repobuilder running on $date"
# enter each folder and run build.sh
execbuild
# use rsync to upload/sync pkg folder on server
upload
# update list of newly updated pkgs on the website
listupdate
