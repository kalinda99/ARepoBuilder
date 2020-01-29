#!/bin/bash

echo "Please enter the exact name of the AUR packages seperated by spaces. No need to add .git at the end, I will do that for you."
read -a yourlist # takes user input as array
#gitclone=$(git clone https://aur.archlinux.org/$pkg.git)

for pkg in "${yourlist[@]}"; do
  echo "Pulling $pkg from AUR Git repo...."
  git clone $aur/$pkg.git
  echo Done!
done

while true; do # ask if user wants to build and upload the pkg now
  read -p "Do you want to build these packages and add them to your repo now? " yn
  case $yn in
      [Yy]* ) export ckupdate=false
              export firstbuild=true
              for pkg in "${yourlist[@]}"; do
                echo "Adding build script to package folder..."                
                ( cd $builddir/$pkg && sh $ARB/build.sh )
                echo "Syncing with SSH server..."
                upload
                listupdate
              done
              break;;
      [Nn]* ) echo "Understood, have a good day!"; exit;;
      * ) echo "Please answer yes or no."
          continue;;
  esac
done
