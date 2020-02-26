#!/bin/bash

pkgname=$(basename "$PWD") # Defines the current directory name without path, which is the name of the pkg
# set -x # Uncomment to see what commands/vars are being used, better error checking

# checkpkg
git clean -fxd

if [ "$rfull" = true ]; then
  chroot=$repodir/chroot
  arch-nspawn $chroot/$USER pacman -Syy
  printf "Checking if ${b}$pkgname${n} has already been built, perhaps as a depend...\n"
  if ! arch-nspawn $chroot/$USER pacman -Ss "^$pkgname$"; then
    printf "Cool, $pkgname isn't in your repo yet, let's build it now :)\n"
  else
    printf "Looks like $pkgname is in your repo already, no need to build it again, moving on...\n"
    exit 0
  fi
fi

if [ "$ckupdate" = true ]; then # if update var is set to true then skip building if there's no new updates
  printf "\nChecking $b$pkgname$n...\n"
  if git reset --hard && git pull | grep -q 'Already up to date.'; then # Ends if a git folder hasn't changed
      echo "Up to date. Nothing to do for $pkgname."
      exit 0

  else
      echo "Changes to $pkgname found, moving to next step..."
      if [ "$firstbuild" = true ] || [ "$rfull" = true ]; then
        ckdepends
      fi
      echo Starting makepkg...
      if mkpkg; then # if makepkg works, then
        if [ "$gpgpkg" = true ]; then # if pkg signing is turned on, then
          if sigpkg; then # if pkkg signing works, then
            echo "Package signed :)"
            if [ "$firstbuild" = false ]; then
              rmold
            fi
            echo "Moving pkg to repo folder..."
            mv *.pkg.tar* $pkgs/
            echo "Updating repo database..."
            repoup
            echo "Removing left over junk..."
            git clean -fxd\n
            exit 0

          else # if signing fails, then
            echo "Uh oh! Signing of $pkgname didn't work!"
            echo "$pkgname - signing failed on $date" >> $logs/sig-fail.log
            git clean -fxd \n
            exit 1
          fi

        else # if pkg signing isn't turned on, carry on without it
          if [ "$firstbuild" = false ]; then
            rmold
          fi
          echo "Moving pkg to repo folder..."
          mv *.pkg.tar* $pkgs/
          echo "Updating repo database..."
          repoup
          echo "Removing left over junk..."
          git clean -fxd \n
          exit 0
        fi

      else # if makepkg fails, then
        echo "Uh oh, building of $pkgname failed! :("
        echo "$pkgname - failed on $date" >> $logs/build-fail.log
        git clean -fxd\n
        exit 1
      fi
  fi

else # if update var is false, check for updates and build no matter what
  git reset --hard && git pull
  echo "Building $b$pkgname$n..."
    if [ "$firstbuild" = true ] || [ "$rfull" = true ]; then
      ckdepends
    fi
    echo Starting makepkg...
    if mkpkg; then  
      if [ "$gpgpkg" = true ]; then # if pkg signing is turned on, then
        if sigpkg; then # if pkkg signing works, then
          echo "Package signed :)"
          if [ "$firstbuild" = false ]; then
            rmold
          fi
          echo "Moving pkg to repo folder..."
          mv *.pkg.tar* $pkgs/
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
        if [ "$firstbuild" = false ]; then
          rmold
        fi
        echo "Moving pkg to repo folder..."
        mv *.pkg.tar* $pkgs/
        echo "Updating repo database..."
        repoup
        echo "Removing left over junk..."
        git clean -fxd\n
        exit 0
      fi

    else
      echo "Uh oh, building of $pkgname failed! :("
      echo "$pkgname - failed on $date" >> $logs/build-fail.log
      git clean -fxd\n
      exit 1
    fi

fi
