#!/usr/bin/env bash
set -euo pipefail

# Simple installer for waybar-simple-calendar
# - copies calendar.sh, README.md, LICENSE to destination (default: ~/.local/share/waybar/waybar-simple-calendar)
# - marks calendar.sh executable
# - optionally attempts to inject a JSON snippet into a Waybar JSON config (creates a backup)
#
# Usage:
#   ./install.sh          # normal install
#   ./install.sh --dest /some/path
#   ./install.sh --no-config   # skip attempting config injection
#   ./install.sh --help

DEST="$HOME/.local/share/waybar/waybar-simple-calendar"
INJECT_CONFIG=true

usage() {
    cat <<EOF
Usage: $0 [--dest DIR] [--no-config] [--help]

Options:
  --dest DIR     Destination directory (default: $DEST)
  --no-config    Do not attempt to edit Waybar config
  --help         Show this message
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dest)
            shift
            DEST="$1"
            ;;
        --no-config)
            INJECT_CONFIG=false
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
    shift
done

# Ensure script is run from the project directory that contains calendar.sh
PROJ_FILES=(calendar.sh README.md LICENSE)
for f in "${PROJ_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "Error: required file '$f' not found in current directory. Run this from the repository root."
        exit 1
    fi
done

echo "Installing to: $DEST"
mkdir -p "$DEST"
cp -v "${PROJ_FILES[@]}" "$DEST/"
chmod +x "$DEST/calendar.sh"
echo "Files copied and calendar script made executable."

# JSON snippet to add to Waybar config (uses the installed path)
EXEC_PATH="$DEST/calendar.sh"
read -r -d '' SNIPPET <<EOF || true
"custom/calendar": {
    "exec": "$EXEC_PATH",
    "interval": 3600,
    "return-type": "json",
    "on-click": "$EXEC_PATH",
    "signal": 8
}
EOF

# Write a helper file containing the snippet in the install directory
echo "$SNIPPET" > "$DEST/waybar-calendar-snippet.txt"
echo "Wrote JSON snippet to: $DEST/waybar-calendar-snippet.txt"

# Try to find Waybar config files
CONFIG_CANDIDATES=(
    "$HOME/.config/waybar/config"
    "$HOME/.config/waybar/config.json"
    "$HOME/.config/waybar/config.jsonc"
)

found_configs=()
for c in "${CONFIG_CANDIDATES[@]}"; do
    if [ -f "$c" ]; then
        found_configs+=("$c")
    fi
done

if [ "$INJECT_CONFIG" = false ]; then
    echo "Skipping config injection (user requested --no-config)."
else
    if [ ${#found_configs[@]} -eq 0 ]; then
        echo "No Waybar config file found in the common locations:"
        printf '  %s\n' "${CONFIG_CANDIDATES[@]}"
        echo "You can copy the snippet from: $DEST/waybar-calendar-snippet.txt into your Waybar config."
    else
        echo "Found Waybar config file(s):"
        printf '  %s\n' "${found_configs[@]}"
        for cfg in "${found_configs[@]}"; do
            echo
            echo "Attempting to inject into: $cfg"
            # Backup
            timestamp=$(date +%Y%m%d%H%M%S)
            bak="${cfg}.bak.${timestamp}"
            cp -v "$cfg" "$bak"
            echo "Backup created: $bak"

            # Attempt a safe JSON edit using python3
            if ! command -v python3 >/dev/null 2>&1; then
                echo "python3 is not available; cannot auto-edit JSON. Please add the snippet manually."
                continue
            fi

            # Python script: load JSON, add "custom/calendar" key if missing, add the module name
            python3 - <<PYTHON || {
                echo "Auto-injection failed for $cfg (python exited with error). Restoring backup."
                cp -v "$bak" "$cfg"
                continue
            }
import json,sys,shutil,datetime,os
cfg_path = os.path.expanduser(sys.argv[1])
exec_path = os.path.expanduser(sys.argv[2])
module_key = "custom/calendar"
# Prepare the module dict
module_value = {
    "exec": exec_path,
    "interval": 3600,
    "return-type": "json",
    "on-click": exec_path,
    "signal": 8
}
try:
    with open(cfg_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    # Not valid JSON -> bail out
    print("Config is not valid JSON or could not be parsed; skipping auto-injection.")
    raise SystemExit(2)

changed = False
if module_key not in data:
    data[module_key] = module_value
    changed = True
# Find a modules list to add the module name into
for loc in ("modules-right", "modules-left", "modules-center"):
    if loc in data and isinstance(data[loc], list):
        if module_key not in data[loc]:
            data[loc].append(module_key)
            changed = True
        break

if changed:
    # Write back pretty JSON
    with open(cfg_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    print("Auto-injection complete. Original backed up at: " + sys.argv[1] + ".bak." + datetime.datetime.now().strftime('%Y%m%d%H%M%S'))
else:
    print("No changes required (module key already present or no suitable modules array found).")
PYTHON "$cfg" "$EXEC_PATH"
        done
    fi
fi

echo
echo "Installation finished."
echo
echo "If the installer couldn't edit your Waybar config automatically, add the following snippet into your Waybar JSON config file (top-level), and then add \"custom/calendar\" into your modules-left / modules-right array where you want it to appear:"
echo
cat "$DEST/waybar-calendar-snippet.txt"
echo
echo "Example: in your Waybar config's top-level add the snippet above, and ensure the string \"custom/calendar\" is present in the modules array you use (e.g. \"modules-right\")."
echo
echo "Done."
