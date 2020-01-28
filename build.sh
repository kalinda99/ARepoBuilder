#!/bin/bash

pkgname=$(basename "$PWD") # Defines the current directory name without path, which is the name of the pkg
set -e # Stops script if any errors are encountered

checkpkg
if [[ $ckupdate == "true" ]]; then #if update var is set to true then check for updates
  echo Checking $pkgname...
  if git reset --hard && git pull | grep -q 'Already up to date.'; then # Ends if a git folder hasn't changed
      echo "Up to date. Nothing to do for $pkgname."

  else
      echo Changes to $pkgname found, moving to next step...
      echo Starting makepkg...
      mkpkg

      if [[ $? -eq 0 ]]; then
        sigpkg

        if [[ $? -eq 0 ]]; then
          echo "Package signed :)"
          if [[ $firstbuild == "false" ]]; then
            rmold
          fi
          echo "Moving pkg to repo folder..."
          mv *.pkg.tar* $pkgdir/
          echo "Updating repo database..."
          repoup
          echo "Removing left over junk..."
          git clean -fx
          exit 0

        else
          echo "Uh oh! Signing of $pkgname didn't work!"
          echo "$pkgname - signing failed on $date" >> $logs/sig-fail.log
          git clean -fx
          exit 1
        fi

      else
        echo "Uh oh, building of $pkgname failed! :("
        echo "$pkgname - failed on $date" >> $logs/build-fail.log
        git clean -fx
        exit 1
      fi
  fi

elif [[ $ckupdate == "false" ]]; then
  echo "Building $pkgname..."
  echo Starting makepkg...
  mkpkg

  if [[ $? -eq 0 ]]; then
    sigpkg

    if [[ $? -eq 0 ]]; then
      echo "Package signed :)"
      if [[ $firstbuild == "false" ]]; then
        rmold
      fi
      echo Moving pkg to repo folder...
      mv *.pkg.tar* $pkgdir/
      echo "Updating repo database..."
      repoup
      echo "Removing left over junk..."
      git clean -fx
      exit 0

    else
      echo "Uh oh! Signing of $pkgname didn't work!"
      echo "$pkgname - signing failed on $date" >> $logs/sig-fail.log
      git clean -fx
      exit 1
    fi

  else
    echo "Uh oh, building of $pkgname failed! :("
    echo "$pkgname - failed on $date" >> $logs/build-fail.log
    git clean -fx
    exit 1
  fi

fi
