#!/usr/bin/env bash

# ======= Configurable colors =======
COLOR_TODAY="#ff5555"    # red for today
COLOR_WEEK="#8888ff"     # blue for ISO week numbers
# ==================================

# Today
TODAY=$(date +%-d)
MONTH=$(date +%-m)
YEAR=$(date +%Y)

# Previous and next months
PREV_MONTH=$(date -d "last month" +%m)
NEXT_MONTH=$(date -d "next month" +%m)
PREV_YEAR=$(date -d "last month" +%Y)
NEXT_YEAR=$(date -d "next month" +%Y)

# Function to generate a month with week numbers and optional highlight
gen_month() {
    local m=$1
    local y=$2
    local highlight=$3

    # Include week numbers
    cal_out=$(cal -w -m "$m" "$y")

    # Process each line
    newcal=""
    while IFS= read -r line; do
        # First 3 characters = week number
        week=${line:0:3}
        days=${line:3}

        # Color week number
        week="<span foreground='$COLOR_WEEK'>$week</span>"

        # Highlight today only in the current month
        if [[ "$highlight" == "yes" ]]; then
            # Match day with optional leading space
            days=$(echo "$days" | sed -E "s/(^| )$TODAY( |$)/\1<span foreground='$COLOR_TODAY'><b>$TODAY<\/b><\/span>\2/g")
        fi

        newcal+="$week$days"$'\n'
    done <<< "$cal_out"

    echo "$newcal"
}

# Generate previous/current/next months
CAL_PREV=$(gen_month "$PREV_MONTH" "$PREV_YEAR" "no")
CAL_CUR=$(gen_month "$MONTH" "$YEAR" "yes")
CAL_NEXT=$(gen_month "$NEXT_MONTH" "$NEXT_YEAR" "no")

# Combine months vertically
calendar="$CAL_PREV"$'\n\n'"$CAL_CUR"$'\n\n'"$CAL_NEXT"

# Escape newlines for JSON
calendar=$(echo "$calendar" | sed ':a;N;$!ba;s/\n/\\n/g')

# Output JSON for Waybar
printf '{"text":"   ","tooltip":"<tt>%s</tt>"}\n' "$calendar"
