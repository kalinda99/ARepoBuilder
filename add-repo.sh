#!/bin/bash

echo Please answer the following questions
echo
echo The name of your repo?
read reponame
while true; do
    read -p "You have chosen $reponame as your reponame. Are you sure you want this? Y/n? You can also type A to abort and exit for now." yna
        case $yna in
            [Yy]* ) echo "export reponame=$reponame" >> $ARB/repodir.sh
                    chmod +x $ARB/repodir.sh
                    break;;
            [Nn]* ) read -p "Name of your repo?" reponame; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
done
while true; do
    echo "Okay, now we need the path to the repo folder on your system, WITHOUT the trailing /. Two folders will be created inside this path:"
    echo "YOUR PATH/build is where packages will be built, each package will have its own folder."
    echo "YOUR PATH/pkgs is where packages will go. Your remote server, if you're using one, will be an exact mirror of this folder."
    echo ""
    echo "Enter the path of your repo on your system:"
    read repodir
        while true; do
        read -p "You've entered port $builddir for your repo path. Is this dorrect? " yna
        case $yna in
            [Yy]* ) mkdir $repodir/build
                    mkdir $repodir/pkgs
                    echo "export repodir=$repodir" >> $ARB/vars.sh
                    echo "export pkgdir=$repodir/pkgs" >> $ARB/vars.sh
                    echo "export builddir=$repodir/build" >> $ARB/vars.sh
                    echo "vars.sh, which will contain your variables, has been created in $repodir :) You can modify it at any time."
                    chmod +x $repodir/vars.sh; break;;
            [Nn]* ) read -p "Your repo path?" builddir; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
done

while true; do
echo "Now, what is the source for $reponame?"
echo "1) SSH (for online web server repos or LAN servers)"
echo "2) Local path (a folder on $HOSTNAME)"
echo "3) Nevermind, return to the previous menu"
echo "4) I don't want to do this right now, abort and exit"
read source

case $source in
    1)
    echo "Awesome, you've chosen SSH. Please remember that you will need to setup an SSH agent (I reccomend Keychain - https://wiki.archlinux.org/index.php/SSH_keys#Keychain) if you want to automate your package building process and keep password asks to a minnimum. We will be asking about this soon!"; break;;
    2)
    echo "You've chosen to use a path on $HOSTNAME, cool!"; break;;
    3)
    echo "Understood!"
    source $buildir/arepobuilder; break;;
    4)
    echo Understood, have a nice day!; exit;;
    *)
    echo "Wat? I need a number between 1 and 3."; continue;;
esac
done

if [ $source = "1" ]; then
    echo "First thing's first - What port is your SSH server on? 22 is the default, but you may have changed it."
    read port
    while true; do
        read -p "You've entered port $port for your SSH server. Is this dorrect? " yna
        case $yna in
            [Yy]* ) echo "export port=$port" >> $repodir/vars.sh; break;;
            [Nn]* ) read -p "Your port number?" port; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
    done
    echo "Now, enter the address of your SSH server in the following format: user@hostname.com"
    read address
    while true; do
        read -p "You've entered $address for your SSH address, is this correct? "
        case $yna in
            [Yy]* ) echo "export address='$address'" >> $repodir/vars.sh; break;;
            [Nn]* ) read -p "What is your SSH address?" address; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
    done

    while true; do
    read -p "Have you setup keychain for SSH agent? " yna
    case $yna in
        [Yy]* ) echo "Good choice!"
                echo "export keychain='true'" >> $repodir/vars.sh
                keychain="true"; break;;
        [Nn]* ) echo "Cool, you can always set it up yourself by changing the keychain variable in $ARB/               vars.sh to true and adding a variable for keyname."
                echo "export keychain='false'" >> $repodir/vars.sh
                keychain="false"; break;;
        [Aa]* ) echo "Alirghty, see you!"; exit;;
        * ) echo "Huh? I need either y/n or a to abort."; continue;;
        esac
    done

    if [[ $keychain = "true" ]]; then
        echo "Please provide the name of your SSH key file, located in $HOME/.ssh by default. If you put it somewhere else, you MUST include the path." 
        read keyname
        while true; do
        read -p "You've entered $keyname, is this correct? "
        case $yna in
            [Yy]* ) echo "export keyname='$keyname'" >> $repodir/vars.sh; break;;
            [Nn]* ) read -p "What is your SSH key file name? It's located in $HOME/.ssh by default. If you put it somewhere else, you MUST include the path." keyname; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
    fi

    echo "Okay, almost done now! Lastly, I am going to need the FULL PATH to your repo on your SSH server, entered like a normal Linux path. Please enter it below."
    read sshpath
    while true; do
        read -p "You've entered $sshpath. Is this right? "
        case $yna in
            [Yy]* ) echo "export sshpath=$sshpath" >> $repodir/vars.sh; break;;
            [Nn]* ) read -p "What is your SSH path?" sshpath; continue;;
            [Aa]* ) echo "Understood, have a nice day."; exit;;
            * ) echo "Huh? Please choose either Y, N, or A."; continue;;
        esac
    done

# The section below isn't really done yet.
elif [ $source = "2" ]; then
    echo "Okay! What is your local path?"
    read local
    while true; do
        read -p "You've entered $local for your repo path. Is this dorrect? " yna
        case $yna in
            [Yy]* ) echo "export path=$local" >> $repodir/vars.sh; break;;
            [Nn]* ) read -p "Your repo path?" port; continue;;
            [Aa]* ) echo "Understood, have a nice day."; exit;;
            * ) echo "Huh? Please choose either Y, N, or A."; continue;;
        esac
    done
fi
