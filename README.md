# What it will look like:

<img width="350" height="860" alt="image" src="https://github.com/user-attachments/assets/20fde120-16f0-4b2c-9921-71abe6880e01" />


# Installation (automated)

This repository includes an installer script: `install.sh`. The installer will:

- Copy `calendar.sh`, `README.md`, and `LICENSE` to `~/.local/share/waybar/waybar-simple-calendar` (or a custom `--dest` you provide).
- Make `calendar.sh` executable.
- Create `waybar-calendar-snippet.txt` in the install directory containing the JSON snippet for manual insertion.
- Attempt to automatically inject the module into your Waybar JSON config (and add the module name into `modules-left` / `modules-right` / `modules-center` if present).
  - The installer tolerates the common non-strict JSON pattern of trailing commas by applying a safe sanitization heuristic before parsing.
  - If parsing or injection fails, a backup of your config is kept (with timestamp) and the backup is restored.
- Always restart Waybar at the end of the installation:
  - It will try `systemctl --user restart waybar.service` if a user service exists.
  - If that fails or doesn't exist, it will `pkill waybar` and attempt to start `waybar` directly (detached) and log output to `~/.local/share/waybar/waybar-simple-calendar/waybar.log`.

To install:

1. From the repository root:
   - Make the installer executable:
     ```
     chmod +x install.sh
     ```
   - Run it:
     ```
     ./install.sh
     ```
2. Optional flags:
   - `--dest /some/path` — change installation destination (default: `~/.local/share/waybar/waybar-simple-calendar`)
   - `--no-config` — do not attempt automatic Waybar config injection
   - `--help` — show help

## Notes about automatic injection

- The installer only supports automatic injection for JSON-based Waybar configs.
  - If your Waybar config is TOML or another format, the installer will not inject and will print the JSON snippet for manual insertion.
- If your JSON config contains trailing commas (a common issue), the installer applies a heuristic to remove trailing commas before parsing. Manual removal of trailing commas in your config is still the recommended fix.
- Backups:
  - Before modifying any config file the installer creates a backup with a timestamp suffix (e.g. `config.bak.20250309120000`).

## Restart & logs

- The installer will always attempt to restart Waybar after running.
- If Waybar is started directly by the script, logs are written to:
  - `~/.local/share/waybar/waybar-simple-calendar/waybar.log`
- If your system uses a user systemd service for Waybar, the installer will attempt to restart via `systemctl --user restart waybar.service` and you can monitor logs with:
  - `journalctl --user -u waybar.service -f`

## Troubleshooting

- If Waybar does not show or the module doesn't appear:
  - Check the installer output for errors during injection.
  - Inspect the Waybar log file:
    ```
    tail -f ~/.local/share/waybar/waybar-simple-calendar/waybar.log
    ```
    or if using systemd:
    ```
    journalctl --user -u waybar.service -f
    ```
  - Ensure you run the installer from the same graphical session where Waybar should run (environment variables like `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY` or `DISPLAY` need to be present when starting Waybar).
  - Ensure the `calendar.sh` path in the config matches the install destination.
- If the installer fails to modify your config, it will leave a `.bak` file next to it; manually compare/merge and add the snippet into the config.


# Installation (manually):

```
"custom/calendar": {
    "exec": "~/.local/share/waybar/waybar-simple-calendar/calendar.sh",
    "interval": 3600,
    "return-type": "json",
    "on-click": "~/.local/share/waybar/waybar-simple-calendar/calendar.sh",
    "signal": 8
}
```

Make it executable:

```
chmod +x calendar.sh
```


# Uninstall

To remove the installed files:

```
rm -rf ~/.local/share/waybar/waybar-simple-calendar
```

You will need to remove the `custom/calendar` module entry from your Waybar config manually.
