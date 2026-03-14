#!/bin/sh
# KIRC LAUNCHER SCRIPT
SERVER="irc.libera.chat"
PORT="6667"
CHANNEL="#anonymous"
if [ -z "$1" ]; then
    echo "USAGE: ./kirc.sh username <password>"
    exit 1
fi
if [ -z "$2" ]; then
    ./kirc -s "$SERVER" -p "$PORT" -c "$CHANNEL" -r "$1" -u "$1" "$1"
else
    ./kirc -s "$SERVER" -p "$PORT" -c "$CHANNEL" -r "$1" -u "$1" -k "$2" "$1"
fi
#
