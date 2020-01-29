#!/bin/bash

# make an array, this find + sort command lists folders in aphabetical order so it's less of a pain
pkgarray=($(( cd $builddir && find . -maxdepth 1 -mindepth 1 -type d -printf '%h\0%d\0%p\n' | sort -t '\0' | awk -F '\0' '{print $3}' | tr -d "./") ))

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
echo "3: Return to the previous menu"
echo "4: Quit"
read option

while true; do
case $option in
  1)
  echo "Alright, here we go!"; break;;
  2)
  echo "Okay!"; break;;
  3)
  echo "Sure thing, taking you back!"
  source $ARB/arepobuilder; break;;
  4)
  echo "Okay, goodbye!"; break;;
  *)
  echo "I can't do that, Dave. Please choose one of the numbers listed."; continue;;
esac
done

if [ $option = "1" ]; then
read -p "Do you really want to rebuild all your packages, upload them, and update the repo database? This might take a while depending on the size of your repo." yna
  while true; do
      case $yna in
          [Yy]* ) echo "Okay, rebuilding all packages in $reponame..."
                  export ckupdate="false" && export firstbuild="false"
                  execbuild
                  rbdb
                  upload
                  break;;
          [Nn]* ) echo "Okay, returning to the main menu..."
                  source $ARB/arepobuilder; break;;
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
  for p in "${multipkg[@]}"
  do
    echo "Rebuilding $p..."
    echo "Checking for updates..."
    ( cd $builddir/$p && sh $ARB/build.sh )
    echo "All done, $p has been rebuilt!"
  done
  echo "Syncing with SSH server..."
  upload
  listupdate
  rm $builddir/rb-pkgs

fi
