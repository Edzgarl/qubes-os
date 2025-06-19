#!/bin/bash

# Path to your Perl script
PERL_SCRIPT="/opt/qubes-screenshooter/send-screenshot-to-chosen-vm.pl" # Adjust if necessary

# Temporary directory for screenshots in dom0
# Using a dedicated cache directory is cleaner than /tmp directly for user items
TMP_DIR="${HOME}/.cache/qubes_flameshot_tmp"
mkdir -p "$TMP_DIR"

# Generate a unique filename for the screenshot
# Using epoch seconds and nanoseconds for uniqueness, plus a random number
# Alternatively, mktemp can be used if available and preferred:
# TMP_SCREENSHOT_PATH=$(mktemp "${TMP_DIR}/flameshot-XXXXXX.png")
# However, mktemp creates a 0-byte file immediately. Flameshot might not like overwriting.
# So, we generate a name and flameshot creates the file.
RAND_SUFFIX=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
TMP_SCREENSHOT_PATH="${TMP_DIR}/flameshot-$(date +%s%N)-${RAND_SUFFIX}.png"

# Ensure TMP_SCREENSHOT_PATH is not taken (highly unlikely but good practice)
while [ -f "$TMP_SCREENSHOT_PATH" ]; do
    RAND_SUFFIX=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    TMP_SCREENSHOT_PATH="${TMP_DIR}/flameshot-$(date +%s%N)-${RAND_SUFFIX}.png"
done

# --- Option 1: Interactive GUI selection with flameshot ---
# Use 'flameshot gui -p <path>'
# The script will pause here until flameshot GUI is closed (either by saving or cancelling)
flameshot gui -p "$TMP_SCREENSHOT_PATH"

# --- Option 2: Fullscreen capture with flameshot (uncomment to use instead) ---
# flameshot full -p "$TMP_SCREENSHOT_PATH"

# Check if the screenshot file was actually created and is not empty
if [ -f "$TMP_SCREENSHOT_PATH" ] && [ -s "$TMP_SCREENSHOT_PATH" ]; then
    # Screenshot saved, now call the Perl script with the path
    "$PERL_SCRIPT" "$TMP_SCREENSHOT_PATH"

    # The Perl script should handle moving the file.
    # If qvm-move-to-vm in Perl script is guaranteed to delete the source,
    # then no further cleanup of TMP_SCREENSHOT_PATH is needed here on success.
    # If the Perl script might leave the file in dom0 on error, or if you want
    # to be certain, you could add: rm -f "$TMP_SCREENSHOT_PATH"
    # But it's better if the Perl script manages its input file.
else
    # Flameshot was cancelled, or failed to save.
    notify-send -u normal "Flameshot Qubes" "Screenshot cancelled or not saved."
    # Clean up the potentially empty file if one was created by mktemp (not applicable with current TMP_SCREENSHOT_PATH generation)
    # rm -f "$TMP_SCREENSHOT_PATH" # Only if mktemp was used and might create an empty file
fi

# Optional: Advanced cleanup of old files in the temp directory (e.g., older than 1 hour)
find "$TMP_DIR" -name "flameshot-*.png" -mmin +60 -delete
