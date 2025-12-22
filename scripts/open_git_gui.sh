#!/bin/bash
# Opens your preferred git GUI or terminal

# Try different git GUIs in order of preference
if command -v gitg &> /dev/null; then
    gitg &
elif command -v gitk &> /dev/null; then
    gitk --all &
elif command -v git-cola &> /dev/null; then
    git-cola &
else
    # Fallback to terminal with lazygit if available
    if command -v lazygit &> /dev/null; then
        konsole -e lazygit &
    else
        konsole -e "cd ~/projects && bash" &
    fi
fi
