#!/bin/bash

echo What kind of packages do you want to add?
echo 1: AUR packages
echo 2: Other, including Git and local
echo 3: Use list of packages
read np

if ! [[ $np =~ ^[1-3] ]] ; then
    echo "Please choose one of the options listed."

else
    if [[ $np = 1 ]] ; then
        source $ARB/add-aur.sh
    fi

    if [[ $np = 2 ]] ; then
        echo "TODO"
    fi

    if [[ $np = 3 ]] ; then
        echo "Please enter the path and name of the text file with your package list:"
        read -e file
        while IFs='' read -r line || [[ -n "$line" ]]; do # courtesy of https://stackoverflow.com/a/10929511
            echo $line
            ( cd $builddir && git clone https://aur.archlinux.org/$line.git )
        done < $file
        while true; do # ask if user wants to build and upload the pkg now
            read -p "Do you want to build these packages and add them to your repo now? " yn
            case $yn in
                [Yy]* ) exec 3<"$file" # Uses 3 to run the file inputs so you can still take regular inputs and thus be able to let makepkg install depends, courtesy of https://stackoverflow.com/a/35131166
                        while read -r -u 3 line; do
                            ( cd $builddir/$line && sh $ARB/build.sh )    
                        done
                        echo "Syncing with SSH server..."
                        upload
                        if [[ "$website" = true ]]; then
                            listupdate
                        fi
                        echo "All done!"; break;;
                [Nn]* ) echo "Understood, have a good day!"; exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi

fi
