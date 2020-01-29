#!/bin/bash

echo "Hello! We see you rebooted, so now you're going to need to authenticate your ssh key for arepobuilder."
echo
echo "So let's enter the screen session so you can enter your ssh paasphrase. After you've done that, press Ctrl+A+D to detech from the screen session and close this window."
echo
echo "Thanks and have a nice day!"

echo "Please type screen -r build below to enter screen:"
screen -r build

exit 0
