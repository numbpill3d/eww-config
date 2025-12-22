#!/bin/bash
# Digital Domain Automated Watchers

SCRIPT_DIR="$HOME/.config/eww/scripts"
LOG_DIR="$HOME/.local/share/eww/logs"
mkdir -p "$LOG_DIR"

# Git auto backup
git_auto_backup() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Starting git backup check..." >> "$LOG_DIR/git_backup.log"
    
    # Add your repositories here
    local repos=(
        "$HOME/projects"
    )
    
    for repo in "${repos[@]}"; do
        if [ -d "$repo/.git" ]; then
            cd "$repo" || continue
            
            # Auto-commit if there are changes
            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                git add -A
                git commit -m "Auto-backup: $timestamp"
                echo "  [✓] Auto-committed changes in $repo" >> "$LOG_DIR/git_backup.log"
            fi
            
            # Auto-push if there are unpushed commits
            local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if [ -n "$branch" ]; then
                local unpushed=$(git log origin/"$branch".."$branch" --oneline 2>/dev/null | wc -l)
                if [ "$unpushed" -gt 0 ]; then
                    if git push origin "$branch" &>> "$LOG_DIR/git_backup.log"; then
                        echo "  [✓] Pushed $unpushed commit(s) from $repo" >> "$LOG_DIR/git_backup.log"
                        notify-send "Git Backup" "Pushed $unpushed commit(s) from $(basename "$repo")" -t 3000
                    else
                        echo "  [X] Failed to push from $repo" >> "$LOG_DIR/git_backup.log"
                        notify-send "Git Backup Failed" "Could not push from $(basename "$repo")" -u critical -t 8000
                    fi
                fi
            fi
        fi
    done
}

# System health check
system_health_check() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Running system health check..." >> "$LOG_DIR/health_check.log"
    
    # Check disk space
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        notify-send "Disk Space Critical" "Root partition at ${disk_usage}% capacity" -u critical -t 15000
        echo "  [!] Critical disk space: ${disk_usage}%" >> "$LOG_DIR/health_check.log"
    fi
    
    # Check for failed systemd services
    local failed=$(systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l)
    if [ "$failed" -gt 0 ]; then
        local services=$(systemctl --failed --no-legend --no-pager 2>/dev/null | awk '{print $1}' | head -n 3 | tr '\n' ' ')
        notify-send "Failed Services" "$failed service(s) failed: $services" -u critical -t 10000
        echo "  [!] Failed services: $services" >> "$LOG_DIR/health_check.log"
    fi
}

# Website availability check
website_availability_check() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Checking website availability..." >> "$LOG_DIR/website_check.log"
    
    "$SCRIPT_DIR/check_websites.sh" >> "$LOG_DIR/website_check.log" 2>&1
}

# Log cleanup
log_cleanup() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning old logs..." >> "$LOG_DIR/cleanup.log"
    
    # Rotate logs if they're too large
    for log in "$LOG_DIR"/*.log; do
        if [ -f "$log" ]; then
            local size=$(stat -c%s "$log")
            if [ "$size" -gt 1048576 ]; then  # 1MB
                mv "$log" "${log}.old"
                echo "Rotated log: $(basename "$log")" >> "$LOG_DIR/cleanup.log"
            fi
        fi
    done
    
    # Delete old rotated logs
    find "$LOG_DIR" -name "*.log.old" -mtime +7 -delete
}

# Main execution
case "$1" in
    git-backup)
        git_auto_backup
        ;;
    health-check)
        system_health_check
        ;;
    website-check)
        website_availability_check
        ;;
    log-cleanup)
        log_cleanup
        ;;
    all)
        git_auto_backup
        system_health_check
        website_availability_check
        ;;
    *)
        echo "Usage: $0 {git-backup|health-check|website-check|log-cleanup|all}"
        exit 1
        ;;
esac
