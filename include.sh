#!/bin/bash
# This script contains all functions and variables and is sourced by other scripts

# export variables so other scripts can use them
export ARB=/home/kalinda/ARepoBuilder
source $ARB/vars.sh # read user variables file
export logs=$repodir/logs # Defines path to logs folder
export aur="https://aur.archlinux.org"
export date=$(date)
export b=$(tput bold) # Makes text written after it bold
export n=$(tput sgr0) # and puts text written after it back to normal
aur_url="https://aur.archlinux.org/packages"
pkgname=$(basename "$PWD") # Defines the current directory name without path, which is the name of the pkg

if [ "$keychain" = true ]; then
  eval `keychain --noask --eval $keyname` # use keychain so we don't need to enter a password for our server
fi

# check for missing packages
function missingpkgs {
  pkglist=$( ( cd $builddir && find . -maxdepth 1 -mindepth 1 -type d -printf '%h\0%d\0%p\n' | sort -t '\0' | awk -F '\0' '{print $3}' | tr -d "./" ) )
  for p in $pkglist
  do
    printf "\nLooking for $b$p$n...\n"
    if test -f $pkgs/$p*.pkg.tar.xz; then # this doesn't worrk very well, it lists things it shouldn't, I have to find a better way to check this
      printf "\n$b$p$n exists, moving on...\n"
    else
      echo "Looks like $b$p$n isn't in your repo yet, adding to list in $b$ARB/missing-pkgs$n... " 
      ( cd $builddir/"$p" && basename "$PWD" ) >> missing-pkgs
    fi
  done
}

function execbuild {
  dirlist=$(find $builddir -maxdepth 1 -type d \( ! -name . \) | sort)
  for d in $dirlist
  do
    ( cd "$d" && sh $ARB/build.sh )
  done
}

function mvpkgs {
  dirlist=$(find $builddir -maxdepth 1 -type d \( ! -name . \) | sort)
  for d in $dirlist
  do
    ( cd "$d" && mv *.pkg.tar.xz* $pkgs/ )
  done
}

function siggy {
  echo "Making fake file for you to sign..."
  echo "Hi, I'm a file! o/" >> $builddir/file.txt
  echo "Signing file..."
  gpg --detach-sign $builddir/file.txt
  rm $builddir/file.*
  echo "All done, file deleted! You can press ctrl+a+d now to detach from the screen! o/"
}

function checkpkg {
  # create array in case there is more than one pkg file
  if [ 'lib32-qt4' == $pkgname ]; then
    echo "$pkgname detected, you should build this in a clean chroot."
    echo "Yeah, I know, it's TODO."

  else
    echo "No need for an array, moving on..."
  fi
}

# this is buggy still, it adds packages it doesn't need to
function ckdepends {
  chroot=$repodir/chroot
  echo "Checking depends and makedepends for $pkgname..."
  echo $(cat PKGBUILD | sed -n '/depends=(/{:start /)/!{N;b start};/^depends=*/p}' | egrep -v '(^[[:space:]]*#|^[[:space:]]*$)') >> depends
  echo $(cat PKGBUILD | sed -n '/makedepends=(/{:start /)/!{N;b start};/^makedepends=*/p}' | egrep -v '(^[[:space:]]*#|^[[:space:]]*$)') >> depends
  source $(pwd)/depends

  deparr=( "${depends[@]/%>=*/}" "${makedepends[@]/%>=*/}" )
  rm depends

  for pkg in "${deparr[@]}"
  do
    printf "\nLooking for $pkg...\n"
    if ! arch-nspawn $chroot/$USER pacman -Ss "^$pkg$"; then
      echo "$pkg not found in repos, getting from AUR and adding to your repo..."
      export ckupdate=false
      if ( cd $builddir && git clone $aur/$pkg.git ); then
        echo "Added $pkg, building it now..."
        ( cd $builddir/$pkg && sh $ARB/build.sh )
      else
        export firstbuild=true
        echo "Oops, looks like you've already cloned $pkg, so let's build it now :)"
        ( cd $buildir/$pkg && $ARB/build.sh )
      fi
      arch-nspawn $chroot/$USER pacman -Syy
      echo "$pkg will be installed during makepkg"
    else
      echo "$pkg is in the repos, yay! It will install during makepkg :)"
    fi
  done
}

# remove the old package
function rmold {
  if [[ "$trash" = true ]]; then
    echo "Removing old version of $pkgname..."
    trash-put $pkgs/$pkgname*.pkg.tar.xz*
  elif [[ "$trash" = false ]]; then
    echo "Removing old version of $pkgname..."
    rm $pkgs/$pkgname*.pkg.tar.xz*
  fi
}

# run the chroot makepkg, done as a function so it can be easily changed later if I want
function mkpkg {
  chroot=$repodir/chroot
  if makechrootpkg -u -r $chroot -- --clean; then
    return 0

  else # if any other exit code, return a 1 exit code because it didn't work
    return 1
  fi
}

function sigpkg {
  echo "Signing package..."
  for i in $(stat -c "%F %n" *.pkg.tar* | grep "regular file" | cut -d' ' -f 3-)
  do
    if gpg --detach-sign $i; then
      return 0
    else
      return 1
    fi
  done

  # if [[ $? -eq 0 ]]; then # same as above, if signing works say so and return a 0 exit code
  #   return 0

  # else # return a 1, meaning failure, if you get any other exit code
  #   return 1
  # fi
}

# update the repo db
function repoup {
  if [ 'unityhub' == $pkgname ]; then
    repo-add -s -v $pkgs/$reponame.db.tar.gz $pkgs/unityhub*.pkg.tar

  else
    repo-add -s -v $pkgs/$reponame.db.tar.gz $pkgs/$pkgname*.pkg.tar.xz
  fi
}

# rebuild the ENTIRE repo db
function rbdb {
  repo-add -s -v $pkgs/$reponame.db.tar.gz $pkgs/*.pkg.tar.xz

  # one for unityhub because it's missing the xz
  repo-add -s -v $pkgs/$reponame.db.tar.gz $pkgs/unityhub*.pkg.tar
}

# Function to run rsync for uploading packages
function upload {
  printf "\nUploading on $date...\n"
  if [[ "$knockon" = true ]]; then
    knock-ssh
  fi
  rsync --exclude="._sync_*" -rulgvzz -e "ssh -p $port" --progress --delete $pkgs/ $address:$sshpath | tee -a $logs/upload.log
}

 # update the newly updated pkg list on the website
function listupdate {
  # make array of last seven updated pkgs/last seven files changed in pkgdir
  pkgups=$(cd $pkgs && find . -maxdepth 1 -mindepth 1 -type f  -name "*.pkg.tar.xz" -printf "%T@ %Tc %p\n" | sort -t '\0' | awk '{print $9}' | sed 's@./@@' | tail -7 | tr "\n" " ")
  read -r -a pkgupdates <<< "$pkgups"

  # iterate through that array and make it into a list in a file
  for p in "${pkgupdates[@]}"
  do
    pacman -Qp $pkgs/$p >> updated.txt
  done

  # array to list packages WITH their ver numbers but without extensions and architechture for website
  list2=$(cd $pkgs && find . -maxdepth 1 -mindepth 1 -type f  -name "*.pkg.tar.xz" -printf "%T@ %Tc %p\n" | sort -t '\0' | awk '{print $9}' | sed 's@./@@' | sed 's/-x86_64.*//' | sed 's/-any.*//' | tail -7 | tr "\n" " ")
  read -r -a plist <<< "$list2"

  # array to list pkgs without their ver numbers for aur urls
  # this sed removes the space and everything after, thus getting the ver number out of the output
  updated=$(cat updated.txt | sed 's/\s.*$//' | tr "\n" " ")
  read -r -a novers <<< "$updated"

  # make edits to index.html with newly updated package list, the numbers (25s, etc) correspond to their lines in the index.html file. Modify the code below accordinly to use it to update your own website.
  sed -i -e '25s@<li>.*$@'"<li><a href="$aur_url/${novers[6]}" target="_blank">${plist[6]}</a></li>"'@' -e '26s@<li>.*$@'"<li><a href="$aur_url/${novers[5]}" target="_blank">${plist[5]}</a></li>"'@' -e '27s@<li>.*$@'"<li><a href="$aur_url/${novers[4]}" target="_blank">${plist[4]}</a></li>"'@' -e '28s@<li>.*$@'"<li><a href="$aur_url/${novers[3]}" target="_blank">${plist[3]}</a></li>"'@' -e'29s@<li>.*$@'"<li><a href="$aur_url/${novers[2]}" target="_blank">${plist[2]}</a></li>"'@' -e '30s@<li>.*$@'"<li><a href="$aur_url/${novers[1]}" target="_blank">${plist[1]}</a></li>"'@' -e '31s@<li>.*$@'"<li><a href="$aur_url/${novers[0]}" target="_blank">${plist[0]}</a></li>"'@' $sitedir/index.html

  # upload new index.html file to server
  if [[ "$knockon" = true ]]; then
    knock-ssh
  fi
  scp -P $port $sitedir/index.html $address:$sitepath

  rm updated.txt
}

# export functions to subshells
typeset -fx ckdepends
typeset -fx execbuild
typeset -fx sigpkg
typeset -fx checkpkg
typeset -fx rmold
typeset -fx mkpkg
typeset -fx repoup
typeset -fx upload
typeset -fx listupdate
