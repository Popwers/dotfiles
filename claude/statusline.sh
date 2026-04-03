#!/bin/bash
input=$(cat)

# ── Colors ──────────────────────────────────────────────────────
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
MAGENTA='\033[35m'; BLUE='\033[34m'; DIM='\033[2m'; BOLD='\033[1m'
RESET='\033[0m'

# ── Extract all fields (single jq call) ────────────────────────
eval "$(echo "$input" | jq -r '
  @sh "MODEL=\(.model.display_name)",
  @sh "DIR=\(.workspace.current_dir)",
  @sh "PCT=\(.context_window.used_percentage // 0 | floor)",
  @sh "LINES_ADD=\(.cost.total_lines_added // 0)",
  @sh "LINES_DEL=\(.cost.total_lines_removed // 0)",
  @sh "FIVE_H=\(.rate_limits.five_hour.used_percentage // empty)",
  @sh "FIVE_H_RESET=\(.rate_limits.five_hour.resets_at // empty)",
  @sh "SEVEN_D=\(.rate_limits.seven_day.used_percentage // empty)"
')"

# ── Model icon (nerd font) ────────────────────────────────────
case "$MODEL" in
    *Opus*)   MODEL_ICON="󰧑";;
    *Sonnet*) MODEL_ICON="󰖙";;
    *Haiku*)  MODEL_ICON="󰌪";;
    *)        MODEL_ICON="󰚩";;
esac

# ── Battery icon (nerd font, dynamic) ─────────────────────────
battery_icon() {
    local remaining=$((100 - ${1:-0}))
    if [ "$remaining" -ge 90 ]; then echo "󰁹"
    elif [ "$remaining" -ge 70 ]; then echo "󰂀"
    elif [ "$remaining" -ge 50 ]; then echo "󰁾"
    elif [ "$remaining" -ge 30 ]; then echo "󰁼"
    elif [ "$remaining" -ge 10 ]; then echo "󰁻"
    else echo "󰂎"; fi
}

# ── Git (cached 5s) ────────────────────────────────────────────
CACHE_FILE="/tmp/claude-statusline-git"
CACHE_MAX_AGE=5

cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git branch --show-current 2>/dev/null)
        DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
        BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
        echo "$BRANCH|$DIRTY|$AHEAD|$BEHIND" > "$CACHE_FILE"
    else
        echo "|||" > "$CACHE_FILE"
    fi
fi

IFS='|' read -r BRANCH DIRTY AHEAD BEHIND < "$CACHE_FILE"

# ── Block bar builder ──────────────────────────────────────────
make_block_bar() {
    local pct_raw=$1 bar_width=20
    local pct_int=$(printf '%.0f' "$pct_raw")
    local filled=$((pct_int * bar_width / 100))
    local empty=$((bar_width - filled))
    local color
    if [ "$pct_int" -ge 80 ]; then color="$RED"
    elif [ "$pct_int" -ge 50 ]; then color="$YELLOW"
    else color="$GREEN"; fi
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    local dim_blocks=""
    for ((i=0; i<empty; i++)); do dim_blocks="${dim_blocks}█"; done
    echo "${color}${bar}${RESET}${DIM}${dim_blocks}${RESET} ${pct_int}%"
}

# ── Context (icon + color) ─────────────────────────────────────
if [ "$PCT" -ge 90 ]; then CTX_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then CTX_COLOR="$YELLOW"
else CTX_COLOR="$GREEN"; fi

# ── Git info ───────────────────────────────────────────────────
GIT_INFO=""
if [ -n "$BRANCH" ]; then
    GIT_EXTRA=""
    [ "${DIRTY:-0}" -gt 0 ] && GIT_EXTRA="${YELLOW}●${DIRTY}${RESET}"
    [ "${AHEAD:-0}" -gt 0 ] && GIT_EXTRA="${GIT_EXTRA:+$GIT_EXTRA }${GREEN}↑${AHEAD}${RESET}"
    [ "${BEHIND:-0}" -gt 0 ] && GIT_EXTRA="${GIT_EXTRA:+$GIT_EXTRA }${RED}↓${BEHIND}${RESET}"
    GIT_INFO=" │ ${BLUE}󰊢 ${BRANCH}${RESET}${GIT_EXTRA:+ $GIT_EXTRA} ${GREEN}+${LINES_ADD}${RESET} ${RED}-${LINES_DEL}${RESET}"
fi

# ── Rate limits ────────────────────────────────────────────────
LIMITS=""
if [ -n "$FIVE_H" ]; then
    FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
    BATT=$(battery_icon "$FIVE_H_INT")
    # Reset countdown
    RESET_INFO=""
    if [ -n "$FIVE_H_RESET" ]; then
        NOW=$(date +%s)
        REMAINING=$((FIVE_H_RESET - NOW))
        if [ "$REMAINING" -gt 0 ]; then
            HOURS=$((REMAINING / 3600))
            MINS=$(( (REMAINING % 3600) / 60 ))
            if [ "$HOURS" -gt 0 ]; then
                RESET_INFO=" ${BLUE}󰑐 ${HOURS}h${MINS}m${RESET}"
            else
                RESET_INFO=" ${BLUE}󰑐 ${MINS}m${RESET}"
            fi
        fi
    fi
    LIMITS=" │ ${BATT} $(make_block_bar "$FIVE_H")${RESET_INFO}"
    if [ -n "$SEVEN_D" ]; then
        SEVEN_D_INT=$(printf '%.0f' "$SEVEN_D")
        [ "$SEVEN_D_INT" -ge 75 ] && LIMITS="${LIMITS} ${RED}7d:${SEVEN_D_INT}%${RESET}"
    fi
fi

# ── Output ─────────────────────────────────────────────────────
echo -e "${DIM}󰉋${RESET} ${YELLOW}${DIR##*/}${RESET} │ ${MAGENTA}${BOLD}${MODEL_ICON} ${MODEL}${RESET} │ ${CTX_COLOR}⚡ ${PCT}%${RESET}${GIT_INFO}${LIMITS}"
