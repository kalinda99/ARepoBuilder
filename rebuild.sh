#!/bin/bash

# make an array, this find + sort command lists folders in aphabetical order so it's less of a pain
pkgarray=($( ( cd $builddir && find . -maxdepth 1 -mindepth 1 -type d -printf '%h\0%d\0%p\n' | sort -t '\0' | awk -F '\0' '{print $3}' | tr -d "./" ) ))

function options {
num=0
for i in ${pkgarray[@]}; do
  echo "$num) $i"
  ((num++))
done
}

function dirlist {
while [[ "$show_clean" =~ [A-Za-z] || -z "$show_clean"  ]]; do
  options
  read -p "Select the packages you wish to rebuild and upload: " show
  show_clean=$(echo $show)
  selected=$(\
  for s in $show_clean; do
    echo -n "\${pkgarray[${s}]},"
  done)
  selected_clean=$(echo $selected|sed 's/,/ /g')
done
eval "echo $selected_clean" >> $builddir/rb-pkgs # Make the selected pkgs into a file
}

echo "How shall we proceed?"
echo "1: Rebuild all packages in your repo"
echo "2: Rebuild select packages"
echo "3: Rebuild from list"
echo "4: Return to the previous menu"
echo "5: Quit"
read option

while true; do
case $option in
  1)
  echo "Alright, here we go!"; break;;
  2)
  echo "Okay!"; break;;
  3)
  echo "Okay!"; break;;
  4)
  echo "Sure thing, taking you back!"
  source $ARB/arepobuilder.sh; break;;
  5)
  echo "Okay, goodbye!"; break;;
  *)
  echo "I can't do that, Dave. Please choose one of the numbers listed."; continue;;
esac
done

if [ $option = "1" ]; then
read -p "Do you really want to rebuild all your packages, upload them, and update the repo database? This might take a while depending on the size of your repo. " yna
  while true; do
      case $yna in
          [Yy]* ) echo "Okay, rebuilding all packages in $reponame..."
                  export ckupdate=false
                  export firstbuild=false
                  export rfull=true
                  echo "Refreshing pacman databases..."
                  arch-nspawn $CHROOT/$USER pacman -Syy
                  echo "Starting the rebuild, hold onto your butts..."
                  execbuild
                  upload; break;;
          [Nn]* ) echo "Okay, returning to the main menu..."
                  source $ARB/arepobuilder.sh; break;;
          [Aa]* ) echo "Understood, goodbye!"; exit;;
          * ) echo Wha? Please choose either Y, N, or A.; continue
      esac
  done

elif [ $option = "2" ]; then
  dirlist
  pkgfile=$(cat $builddir/rb-pkgs)
  read -r -a multipkg <<< "$pkgfile" # Create new array from the pkg file

  export ckupdate=false
  export firstbuild=false
  # export rfull=true
  for p in "${multipkg[@]}"
  do
    ( cd $builddir/$p/ && sh $ARB/build.sh )
  done
  echo "Syncing with SSH server..."
  upload
  # listupdate
  rm $builddir/rb-pkgs

elif [ $option = "3" ]; then
  export ckupdate=false
  export rfull=true
  export firstbuild=true
  echo
  echo "Please type the$b full path$n to your list and ensure that each line contains a package name, the path is not needed as we will be using your default build folder."
  read -e file
  while IFs='' read -r line || [[ -n "$line" ]]; do # courtesy of https://stackoverflow.com/a/10929511
      ( cd $builddir/$line && sh $ARB/build.sh )
  done < $file
  echo "Syncing with SSH server..."
  upload
  # listupdate

fi
