#!/bin/bash
# HiFam Arch Auto-Setup Runner
# This script runs all setup scripts in order and tracks completion

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETE_FILE="$SCRIPT_DIR/complete"

# Check if already completed
if [ -f "$COMPLETE_FILE" ]; then
    echo "HiFam setup already completed. Exiting."
    exit 0
fi

echo "╔════════════════════════════════════════╗"
echo "║   HiFam Arch Auto-Setup                ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Running setup scripts in $SCRIPT_DIR..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Track if any script fails
FAILED=0

# Run all numbered scripts in order
for script in "$SCRIPT_DIR"/[0-9]*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        script_name=$(basename "$script")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running: $script_name"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Run the script
        if "$script"; then
            echo "✓ $script_name completed successfully"
        else
            echo "✗ $script_name failed (exit code: $?)"
            FAILED=1
        fi
        echo ""
    fi
done

# Mark as complete if all succeeded
if [ $FAILED -eq 0 ]; then
    touch "$COMPLETE_FILE"
    echo "╔════════════════════════════════════════╗"
    echo "║  ✅ HiFam Setup Complete!              ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Setup has been completed and marked as done."
    echo "This script will not run again."
    echo ""
    echo "Please logout and login to see all changes."
    exit 0
else
    echo "╔════════════════════════════════════════╗"
    echo "║  ⚠️  Some Scripts Failed                ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Setup completed with errors. Not marking as complete."
    echo "Fix the errors and run this script again."
    exit 1
fi
