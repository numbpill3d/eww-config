#!/bin/bash
# Desktop Companion Controller
# Manages character switching, emotions, and interactions

COMPANION_DIR="$HOME/.config/eww/companion"
STATE_DIR="$COMPANION_DIR/state"
CHAR_DIR="$COMPANION_DIR/characters"
CURRENT_CHAR_FILE="$STATE_DIR/current_char"
DIALOG_FILE="$STATE_DIR/current_dialog"
STATUS_FILE="$STATE_DIR/current_status"
ASCII_FRAME_FILE="$STATE_DIR/ascii_frame"

# Initialize directories
mkdir -p "$STATE_DIR" "$CHAR_DIR"

# Initialize state files if they don't exist
[ ! -f "$CURRENT_CHAR_FILE" ] && echo "xethis" > "$CURRENT_CHAR_FILE"
[ ! -f "$DIALOG_FILE" ] && echo "System initializing..." > "$DIALOG_FILE"
[ ! -f "$STATUS_FILE" ] && echo "idle" > "$STATUS_FILE"
[ ! -f "$ASCII_FRAME_FILE" ] && echo "0" > "$ASCII_FRAME_FILE"

# Function to send desktop notification
send_notification() {
    local char="$1"
    local message="$2"
    notify-send -a "Companion: $char" -i dialog-information "$message"
}

# Function to get current character
get_current_char() {
    cat "$CURRENT_CHAR_FILE"
}

# Function to switch character
switch_char() {
    local new_char="$1"
    echo "$new_char" > "$CURRENT_CHAR_FILE"
    
    # Load character config
    if [ -f "$CHAR_DIR/${new_char}.conf" ]; then
        source "$CHAR_DIR/${new_char}.conf"
        echo "$CHAR_GREETING" > "$DIALOG_FILE"
        send_notification "$CHAR_NAME" "Now talking with $CHAR_NAME"
    fi
}

# Function to get character name
get_char_name() {
    local char=$(get_current_char)
    if [ -f "$CHAR_DIR/${char}.conf" ]; then
        source "$CHAR_DIR/${char}.conf"
        echo "$CHAR_NAME"
    else
        echo "UNKNOWN"
    fi
}

# Function to get emotion value
get_emotion() {
    local char=$(get_current_char)
    local emotion_type="$1"
    local value=$(python3 "$COMPANION_DIR/emotions.py" get "$char" "$emotion_type")
    echo "DEBUG_EMOTION_VALUE:${value}"
    echo "${value}"
}

# Function to modify emotion
modify_emotion() {
    local char=$(get_current_char)
    local emotion_type="$1"
    local change="$2"
    python3 "$COMPANION_DIR/emotions.py" modify "$char" "$emotion_type" "$change"
}

# Function to get dialog
get_dialog() {
    cat "$DIALOG_FILE"
}

# Function to get status
get_status() {
    cat "$STATUS_FILE"
}

# Function to get ASCII art frame
get_ascii() {
    local char=$(get_current_char)
    local frame=$(cat "$ASCII_FRAME_FILE")
    
    if [ -f "$CHAR_DIR/${char}.conf" ]; then
        source "$CHAR_DIR/${char}.conf"
        
        # Cycle through animation frames
        case $frame in
            0) echo "$ASCII_FRAME_1" ;;
            1) echo "$ASCII_FRAME_2" ;;
            2) echo "$ASCII_FRAME_3" ;;
            *) echo "$ASCII_FRAME_1" ;;
        esac
        
        # Increment frame counter
        next_frame=$(( (frame + 1) % 3 ))
        echo "$next_frame" > "$ASCII_FRAME_FILE"
    fi
}

# Interaction: Talk
interact_talk() {
    local char=$(get_current_char)
    source "$CHAR_DIR/${char}.conf"
    
    # Increase affection and trust slightly
    modify_emotion "love" 2
    modify_emotion "trust" 1
    modify_emotion "mood" 3
    
    # Generate response
    local response=$(python3 "$COMPANION_DIR/emotions.py" generate_dialog "$char" "talk")
    echo "$response" > "$DIALOG_FILE"
    echo "talking" > "$STATUS_FILE"
    
    send_notification "$CHAR_NAME" "Conversation started"
    
    # Reset status after delay
    sleep 5
    echo "idle" > "$STATUS_FILE"
}

# Interaction: Give Gift
interact_gift() {
    local char=$(get_current_char)
    source "$CHAR_DIR/${char}.conf"
    
    # Significant affection boost
    modify_emotion "love" 5
    modify_emotion "respect" 2
    modify_emotion "mood" 5
    
    # Generate response
    local response=$(python3 "$COMPANION_DIR/emotions.py" generate_dialog "$char" "gift")
    echo "$response" > "$DIALOG_FILE"
    echo "happy" > "$STATUS_FILE"
    
    send_notification "$CHAR_NAME" "Gift received!"
    
    sleep 5
    echo "idle" > "$STATUS_FILE"
}

# Interaction: Ignore
interact_ignore() {
    local char=$(get_current_char)
    source "$CHAR_DIR/${char}.conf"
    
    # Decrease affection and mood
    modify_emotion "love" -3
    modify_emotion "trust" -2
    modify_emotion "mood" -5
    
    # Generate response
    local response=$(python3 "$COMPANION_DIR/emotions.py" generate_dialog "$char" "ignore")
    echo "$response" > "$DIALOG_FILE"
    echo "sad" > "$STATUS_FILE"
    
    send_notification "$CHAR_NAME" "..."
    
    sleep 5
    echo "idle" > "$STATUS_FILE"
}

# Interaction: Insult
interact_insult() {
    local char=$(get_current_char)
    source "$CHAR_DIR/${char}.conf"
    
    # Major negative impact
    modify_emotion "love" -5
    modify_emotion "respect" -8
    modify_emotion "trust" -4
    modify_emotion "mood" -8
    
    # Generate response
    local response=$(python3 "$COMPANION_DIR/emotions.py" generate_dialog "$char" "insult")
    echo "$response" > "$DIALOG_FILE"
    echo "angry" > "$STATUS_FILE"
    
    send_notification "$CHAR_NAME" "How dare you."
    
    sleep 5
    echo "idle" > "$STATUS_FILE"
}

# Main command handler
case "$1" in
    get)
        case "$2" in
            current_char) get_current_char ;;
            char_name) get_char_name ;;
            love) get_emotion "love" ;;
            respect) get_emotion "respect" ;;
            trust) get_emotion "trust" ;;
            mood) get_emotion "mood" ;;
            dialog) get_dialog ;;
            status) get_status ;;
            ascii) get_ascii ;;
            *) echo "Unknown get parameter: $2" ;;
        esac
        ;;
    switch)
        switch_char "$2"
        ;;
    talk)
        interact_talk &
        ;;
    gift)
        interact_gift &
        ;;
    ignore)
        interact_ignore &
        ;;
    insult)
        interact_insult &
        ;;
    *)
        echo "Desktop Companion Controller"
        echo "Usage: $0 {get|switch|talk|gift|ignore|insult} [args]"
        ;;
esac
