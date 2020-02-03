#!/bin/bash

pkgname=$(basename "$PWD") # Defines the current directory name without path, which is the name of the pkg
# set -e # Stops script if any errors are encountered

# checkpkg
git clean -fxd

if [ "$rfull" = true ]; then
  arch-nspawn $CHROOT/$USER pacman -Syy
  printf "Checking if ${b}$pkgname${n} has already been built, perhaps as a depend...\n"
  if ! arch-nspawn $CHROOT/$USER pacman -Ss "^$pkgname$"; then
    printf "Cool, $pkgname isn't in your repo yet, let's build it now :)\n"
  else
    printf "Looks like $pkgname is in your repo already, no need to build it again, moving on...\n"
    exit 0
  fi
fi

if [ "$ckupdate" = true ]; then #if update var is set to true then check for updates
  printf "\nChecking ${b}$pkgname${n}...\n"
  if git reset --hard && git pull | grep -q 'Already up to date.'; then # Ends if a git folder hasn't changed
      echo "Up to date. Nothing to do for $pkgname.\n"
      exit 0

  else
      echo "Changes to $pkgname found, moving to next step..."
      if [ "$firstbuild" = true ] || [ "$rfull" = true ]; then
        ckdepends
      fi
      echo Starting makepkg...
      if mkpkg; then
        if sigpkg; then
          echo "Package signed :)"
          if [ "$firstbuild" = false ]; then
            rmold
          fi
          echo "Moving pkg to repo folder..."
          mv *.pkg.tar* $pkgdir/
          echo "Updating repo database..."
          repoup
          echo "Removing left over junk..."
          git clean -fxd\n
          exit 0

        else
          echo "Uh oh! Signing of $pkgname didn't work!"
          echo "$pkgname - signing failed on $date" >> $logs/sig-fail.log
          git clean -fxd\n
          exit 1
        fi

      else
        echo "Uh oh, building of $pkgname failed! :("
        echo "$pkgname - failed on $date" >> $logs/build-fail.log
        git clean -fxd\n
        exit 1
      fi
  fi

elif [ "$ckupdate" = false ]; then
  git reset --hard && git pull
  echo "Building ${b}$pkgname${n}..."
    if [ "$firstbuild" = true ] || [ "$rfull" = true ]; then
      ckdepends
    fi
    echo Starting makepkg...
    if mkpkg; then
      if sigpkg; then
        echo "Package signed :)"
        if [ "$firstbuild" = false ]; then
          rmold
        fi
        echo "Moving pkg to repo folder..."
        mv *.pkg.tar* $pkgdir/
        echo "Updating repo database..."
        repoup
        echo "Removing left over junk..."
        git clean -fxd\n
        exit 0

      else
        echo "Uh oh! Signing of $pkgname didn't work!"
        echo "$pkgname - signing failed on $date" >> $logs/sig-fail.log
        git clean -fxd\n
        exit 1
      fi

    else
      echo "Uh oh, building of $pkgname failed! :("
      echo "$pkgname - failed on $date" >> $logs/build-fail.log
      git clean -fxd\n
      exit 1
    fi

fi
