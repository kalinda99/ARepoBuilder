#!/bin/bash
ARB=$HOME/ARepoBuilder
source $ARB/include.sh # Call the include script so we can use our functions and variables

# welcome and present list of options
echo "Hello, welcome to A Repo Builder, glad you're here! Please choose from the following options so we can get started:"
while true; do
echo "1: New repo"
echo "2: Check and update packages"
echo "3: Rebuild and upload packages"
echo "4: Rebuild repo datebase"
echo "5: Add new packages to existing repo"
echo "6: Remove packages from existing repo"
echo "7: Check for missing packages in repo"
echo "8: Quit"

read option # read user input
    case $option in
    1)
    source $ARB/add-repo.sh; break;;
    2)
    export ckupdate=true
    export firstbuild=false
    execbuild
    upload; break;;
    3)
    source $ARB/rebuild.sh; break;;
    4)
    rbdb
    upload; break;;
    5)
    source $ARB/add-pkg.sh; break;;
    6)
    source $ARB/remove-pkg.sh; break;;
    7)
    missingpkgs ## this function needs work
    read -p "Do you want to build these packages now? " yna
    while true; do
      case $yna in
        [Yy]* ) echo "Okay, starting build..."
                echo
                export ckupdate=false
                export firstbuild=false
                # export rfull=true
                mlist=$(cat missing-pkgs)
                for mp in "${mlist[@]}"
                do
                  ( cd $builddir/$mp && sh $ARB/builld.sh )
                done
                upload
                echo "All done, yay!"
                echo; break;;
        [Nn]* ) echo "Cool, you can find the missing package list in $b$ARB/missing-pkgs$n and you can build          them from the Rebuild and Upload Packages menu by selecting Rebuild from List.";
                echo; break;;
        [Aa]* ) echo "Cool, have a nice day, exiting..."
                echo; exit;;
        * ) echo "I can't do that, Dave. Please choose either [Yy]es, [Nn]o, or [Aa]bort."; continue;;
      esac
    done; break;;
    8)
    echo "Thanks for stopping by, have a nice day!"; exit;;
    *)
    echo "I can't do that, Dave. Please choose one of the options."; continue;;
esac
done
