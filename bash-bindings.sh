#!/bin/bash

case "$1" in
    "send_message")
        ~/.config/eww/cyber_chat.sh send_message
        ;;
    *)
        echo "Unknown command: $1"
        ;;
esac
