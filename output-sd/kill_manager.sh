#!/bin/sh
# kill_manager.sh

# Attendre que manager apparaisse dans les process
while ! pidof manager > /dev/null 2>&1; do
    sleep 0.2
done
killall manager
