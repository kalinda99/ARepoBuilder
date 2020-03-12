#!/bin/bash
# have not updated this file in a long time, stuff could be broken, but it should all work ok
shopt -s extglob nullglob

# Create array from list of builddir folders
if [[ -z $omitdir ]]; then
   pkgarray=( "$builddir"/*/ )
else
   pkgarray=( "$builddir"/!($omitdir)/ )
fi
# remove leading builddir:
pkgarray=( "${pkgarray[@]#"$builddir/"}" )
# remove trailing backslash and insert Exit choice
pkgarray=( Exit "${pkgarray[@]%/}" )

# Check to ensure there are folders in the builddir.
if ((${#pkgarray[@]}<=1)); then
    printf "No package folders found, looks like you don't have a repo. Exiting.\n"
    exit 0
fi

echo "What type of package do you want to remove?"
while true; do
echo "1: SSH Remote repo package"
echo "2: Local repo package"
echo "3: Return to the previous menu"
echo "4: Quit"

read option # read user choice
    case $option in
    1)
    echo "Okay, cool, which package do you want to remove?"
    printf 'Please choose from the following. Enter 0 to exit.\n'
    for i in "${!pkgarray[@]}"; do
        printf '   %d %s\n' "$i" "${pkgarray[i]}"
    done
    printf '\n'; break;;
    2)
    echo "Sure, what is the name of the package you want to delete?"; break;;
    3)
    echo "Sure thing, taking you back!"
    source $ARB/arepobuilder.sh; break;;
    4)
    echo "Okay, goodbye!"; break;;
    *)
    echo "I can't do that, Dave. Please choose one of the numbers listed."; continue;;
esac
done

if [ $option = "1" ]; then
    while true; do
        read -e -r -p 'Your choice: ' choice
            # Check that user's choice is a valid number
            if [[ $choice = +([[:digit:]]) ]]; then
            # Force the number to be interpreted in radix 10
            ((choice=10#$choice))
            # Check that choice is a valid choice
            ((choice<${#pkgarray[@]})) && break
        fi
        printf 'Invalid choice, please start again.\n'
    done

# At this point, you're sure the variable choice contains
# a valid choice.
    if ((choice==0)); then
        printf 'Good bye.\n'
        exit 0
    fi

    # Now do the work on the pkg folder
    printf "Cool, You've chosen \`%s'. I will remove this package for you.\n" "${pkgarray[choice]}"
    echo "Removing package from local folders..."
    if [[ "$trash" = true ]]; then
        trash-put $pkgs/${pkgarray[choice]}*.pkg.tar.xz
        trash-put $pkgs/${pkgarray[choice]}*.pkg.tar.xz.sig
        echo "Removing ${pkgarray[choice]}'s build folder..."
        trash-put -d $builddir/${pkgarray[choice]}        
    elif [[ "$trash" = false ]]; then
        rm $pkgs/${pkgarray[choice]}*.pkg.tar.xz
        rm $pkgs/${pkgarray[choice]}*.pkg.tar.xz.sig
        echo "Removing ${pkgarray[choice]}'s build folder..."
        rm -rf $builddir/${pkgarray[choice]}
    fi
    echo "Removing from repo database..."
    repo-remove -s -v $pkgs/$reponame*.db.tar.gz ${pkgarray[choice]}
    echo "Syncing remote server..."
    upload
    listupdate
    echo "All done! ${pkgarray[choice]} is no longer in your repo!"


elif [ $option = "2" ]; then
    read name
    while true; do
        read -p "You've enetered $name for deletion. This will remove this package from the repo database and your local repo folder. Are you sure you want to do this?" yna
        case $yna in
            [Yy]* ) echo "Removing package from local folder..."
                    if [[ "$trash" = true ]]; then
                        trash-put $pkgs/$name*.pkg.tar.xz
                    elif [[ "$trash" = false ]]; then
                        rm $pkgs/$name*.pkg.tar.xz
                    fi
                    echo "Removing from repo database..."
                    repo-remove $pkgs/$reponame*.db.tar.gz $name
                    echo "All done! $name is no longer in your repo!"; break;;
            [Nn]* ) read -p "Alright, which package would you like to remove?" name; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
    done
fi
