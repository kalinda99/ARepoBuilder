#!/bin/bash

echo "Please answer the following questions"
echo
echo "What is the name of your repo?"
read reponame
while true; do
    read -p "You have chosen $b$reponame$n as your reponame. Are you sure you want this? Y/n? You can also type A to abort and exit for now. " yna
        case $yna in
            [Yy]* ) echo "export reponame=$reponame" >> $ARB/vars.sh; break;;
            [Nn]* ) read -p "Name of your repo?" reponame; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
done

echo
echo "Okay, now we need the path to the repo folder on your system, WITHOUT the trailing /. Two folders will be created inside this path:"
echo "$b YOUR PATH/build$n is where packages will be built, each package will have its own folder."
echo "$b YOUR PATH/pkgs$n is where packages will go. Your remote server, if you're using one, will be an exact mirror of this folder."
echo
echo "Enter the path of your repo on your system: "
read -e repodir
    while true; do
    read -p "You've entered $b$repodir$n for your repo path. Is this dorrect? " yna
    case $yna in
        [Yy]* ) mkdir $repodir/build
                mkdir $repodir/pkgs
                echo "export repodir=$repodir" >> $ARB/vars.sh
                echo "export pkgdir=$repodir/pkgs" >> $ARB/vars.sh
                echo "export builddir=$repodir/build" >> $ARB/vars.sh; break;;
        [Nn]* ) read -e -p "Your repo path? " repodir; continue;;
        [Aa]* ) echo Understood, have a nice day.; exit;;
        * ) echo Huh? Please choose either Y, N, or A.; continue;;
    esac
    done

while true; do
echo "Now, what is the source for $reponame?"
echo "1) SSH (for online web server repos or LAN servers)"
echo "2) Local path (a folder on $HOSTNAME)"
echo "3) Nevermind, return to the main menu"
echo "4) I don't want to do this right now, abort and exit"
read source

case $source in
    1)
    echo "Awesome, you've chosen SSH. Please remember that you will need to setup an SSH agent (I reccomend Keychain - https://wiki.archlinux.org/index.php/SSH_keys#Keychain) if you want to automate your package building process and keep password asks to a minnimum. We will be asking about this soon!"; break;;
    2)
    echo "You've chosen to use a path on $HOSTNAME, cool!"; break;;
    3)
    echo "Understood!"
    source $ARB/arepobuilder; break;;
    4)
    echo Understood, have a nice day!; exit;;
    *)
    echo "Wat? I need a number between 1 and 3."; continue;;
esac
done

if [ $source = "1" ]; then
    echo
    echo "First thing's first - What port is your SSH server on? 22 is the default, but you may have changed it."
    read port
    while true; do
        read -p "You've entered port $b$port$n for your SSH server. Is this dorrect? " yna
        case $yna in
            [Yy]* ) echo "export port=$port" >> $ARB/vars.sh; break;;
            [Nn]* ) read -p "Your port number? " port; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
    done
    echo
    echo "Now, enter the address of your SSH server in the following format:$b user@hostname.com$n"
    read address
    while true; do
        read -p "You've entered $b$address$n for your SSH address, is this correct? "
        case $yna in
            [Yy]* ) echo "export address='$address'" >> $ARB/vars.sh; break;;
            [Nn]* ) read -p "What is your SSH address? " address; continue;;
            [Aa]* ) echo Understood, have a nice day.; exit;;
            * ) echo Huh? Please choose either Y, N, or A.; continue;;
        esac
    done

    while true; do
    read -p "Have you setup keychain for SSH? " yna
    case $yna in
        [Yy]* ) echo "Good choice!"
                echo "export keychain=true" >> $ARB/vars.sh
                keychain="true"; break;;
        [Nn]* ) echo "Cool, if you set it up in the future you can always change the keychain variable in             $b$ARB/vars.sh$n to true and adding a variable for keyname."
                echo "export keychain='false'" >> $ARB/vars.sh
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
                [Yy]* ) echo "export keyname=$keyname" >> $ARB/vars.sh; break;;
                [Nn]* ) read -p "What is your SSH key file name? It's located in $HOME/.ssh by default. If you put it somewhere else, you MUST include the path. " keyname; continue;;
                [Aa]* ) echo Understood, have a nice day.; exit;;
                * ) echo Huh? Please choose either Y, N, or A.; continue;;
            esac
        done
    fi

    echo
    echo "I am now going to need the$b FULL PATH$n to your repo on your SSH server, entered like a normal Linux path. Please enter it below."
    read sshpath
    while true; do
        read -p "You've entered $b$sshpath$n. Is this right? "
        case $yna in
            [Yy]* ) echo "export sshpath=$sshpath" >> $ARB/vars.sh; break;;
            [Nn]* ) read -p "What is your SSH path? " sshpath; continue;;
            [Aa]* ) echo "Understood, have a nice day."; exit;;
            * ) echo "Huh? Please choose either Y, N, or A."; continue;;
        esac
    done

    while true; do
        read -p "Okay, almost done now! Lastly, are you using$b port knocking$n to access your remote server? "
        case $yna in
            [Yy]* ) echo "Nice, now I'm going to need to know your ports."
                    echo "export knockon=true" >> $ARB/vars.sh; break;;
            [Nn]* ) echo "Awesome! Then that concludes the setup! Thanks for using ARB! Returning to the main         menu..."
                    echo "export knockon=false" >> $ARB/vars.sh
                    source $ARB/arepobuilder; break;;
            [Aa]* ) echo "Understood, have a nice day."; exit;;
            * ) echo "Huh? Please choose either Y, N, or A."; continue;;
        esac
    done

    echo "Please enter your ports below, seperated by spaces: "
    read knockports
    while true; do
        read -p "You entered $knockports for your ports, are they correct? "
        case "$yna" in
            [Yy]* ) echo "Thanks very much, that concludes the setup! Taking you back to the main menu..."
                    echo "export knockports='$knockports'" >> $ARB/vars.sh
                    echo "alias knock-ssh="knock -v -d 300 $server $knockports"" >> $ARB/vars.sh
                    echo "Before you start building, please make sure you've got a$b clean chroot$n setup as this program relies on that for making packages. See https://wiki.archlinux.org/index.php/DeveloperWiki:Building_in_a_clean_chroot for more info."
                    echo "Returning to the main menu..."
                    echo
                    source $ARB/arepobuilder; break;;
            [Nn]* ) read -p "Please enter your ports seperated by spaces. " knockports; continue;;
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
            [Yy]* ) echo "export path=$local" >> $ARB/vars.sh; break;;
            [Nn]* ) read -p "Your repo path?" port; continue;;
            [Aa]* ) echo "Understood, have a nice day."; exit;;
            * ) echo "Huh? Please choose either Y, N, or A."; continue;;
        esac
    done
fi
