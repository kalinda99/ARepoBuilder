#!/bin/bash
export logs=/build/logs # Defines path to logs folder

# run the automater script inside of a screen and log the output to a file. This script is executed by the systemd service.
screen -r build -p 0 -X stuff "sh automate.sh | tee -a $logs/builder-service.log$(printf \\r)"
