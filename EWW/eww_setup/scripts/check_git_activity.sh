#!/bin/bash
# Git activity monitoring script
# Monitors specified repositories for changes

# Configuration - EDIT THIS SECTION WITH YOUR REPOS
GIT_REPOS=(
    "$HOME/projects"
    "$HOME/code"
    # Add your repository paths here
)

STATE_FILE="/tmp/git_activity_state"
NOTIF_FILE="/tmp/git_last_notif"

activity=""
changes_detected=0

# Function to check a single repository
check_repo() {
    local repo_path="$1"
    
    if [ ! -d "$repo_path/.git" ]; then
        return
    fi
    
    cd "$repo_path" || return
    
    # Fetch updates silently
    git fetch --all &> /dev/null
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        activity="${activity}[!] Uncommitted changes in $(basename "$repo_path")\n"
        changes_detected=1
    fi
    
    # Check for unpushed commits
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        local unpushed=$(git log origin/"$branch".."$branch" --oneline 2>/dev/null | wc -l)
        if [ "$unpushed" -gt 0 ]; then
            activity="${activity}[↑] $unpushed unpushed commit(s) in $(basename "$repo_path")\n"
            changes_detected=1
        fi
        
        # Check for unpulled commits
        local unpulled=$(git log "$branch"..origin/"$branch" --oneline 2>/dev/null | wc -l)
        if [ "$unpulled" -gt 0 ]; then
            activity="${activity}[↓] $unpulled new commit(s) in $(basename "$repo_path")\n"
            changes_detected=1
            
            # Send notification if new commits
            if [ ! -f "$NOTIF_FILE" ] || [ $(( $(date +%s) - $(stat -c %Y "$NOTIF_FILE" 2>/dev/null || echo 0) )) -gt 300 ]; then
                notify-send "Git Activity" "New commits in $(basename "$repo_path")" -u normal -t 5000
                touch "$NOTIF_FILE"
            fi
        fi
    fi
    
    # Check for untracked files
    local untracked=$(git ls-files --others --exclude-standard | wc -l)
    if [ "$untracked" -gt 0 ]; then
        activity="${activity}[?] $untracked untracked file(s) in $(basename "$repo_path")\n"
    fi
}

# Scan all configured repositories
for repo in "${GIT_REPOS[@]}"; do
    if [ -d "$repo" ]; then
        # If it's a directory with subdirectories that might be repos
        if [ -d "$repo/.git" ]; then
            check_repo "$repo"
        else
            # Check subdirectories
            for subrepo in "$repo"/*; do
                if [ -d "$subrepo/.git" ]; then
                    check_repo "$subrepo"
                fi
            done
        fi
    fi
done

# Output result
if [ -z "$activity" ]; then
    echo "All repositories clean"
else
    echo -e "$activity" | head -c 200
fi

# Log state for comparison
echo "$changes_detected" > "$STATE_FILE"
