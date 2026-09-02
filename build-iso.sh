#!/bin/bash
# Build script for HiFam Arch ISO

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_PROFILE="${ISO_PROFILE:-$SCRIPT_DIR}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/hifam-arch-iso-output}"
WORK_DIR="${WORK_DIR:-$HOME/hifam-arch-work}"
MKARCHISO_WORK_DIR="$WORK_DIR/mkarchiso"

run_root() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

echo "╔════════════════════════════════════════╗"
echo "║  HiFam Arch ISO Build Script           ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Warning: Running as root. This is required for mkarchiso."
else
    echo "Note: This script will use sudo for mkarchiso."
fi

# Check if archiso is installed
if ! command -v mkarchiso &> /dev/null; then
    echo "Error: archiso not found!"
    echo "Install it with: sudo pacman -S archiso"
    exit 1
fi

# Check if profile exists
if [ ! -d "$ISO_PROFILE" ]; then
    echo "Error: ISO profile not found at $ISO_PROFILE"
    exit 1
fi

# Verify critical files
echo "Verifying profile structure..."
REQUIRED_FILES=(
    "$ISO_PROFILE/profiledef.sh"
    "$ISO_PROFILE/packages.x86_64"
    "$ISO_PROFILE/airootfs/root/arch-install.sh"
    "$ISO_PROFILE/airootfs/root/install-hifam.sh"
    "$ISO_PROFILE/airootfs/root/post-install.sh"
    "$ISO_PROFILE/airootfs/root/copy-hifam-configs.sh"
    "$ISO_PROFILE/airootfs/root/hifam-config/user_configuration.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        echo "Warning: $file not found!"
    else
        echo "✓ $(basename "$file")"
    fi
done

echo ""
echo "Profile: $ISO_PROFILE"
echo "Output: $OUTPUT_DIR"
echo "Work dir: $WORK_DIR"
echo ""

# Clean previous build
if [ -d "$WORK_DIR" ]; then
    echo "Cleaning previous work directory..."
    read -p "Remove $WORK_DIR? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -rf "$WORK_DIR"
    fi
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
run_root rm -rf "$MKARCHISO_WORK_DIR"
mkdir -p "$WORK_DIR"

# Build the ISO
echo ""
echo "=== Building ISO ==="
echo "This may take several minutes..."
echo ""

run_root mkarchiso -v -w "$MKARCHISO_WORK_DIR" -o "$OUTPUT_DIR" "$ISO_PROFILE"

BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  Build Successful!                     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "ISO location: $OUTPUT_DIR"
    ls -lh "$OUTPUT_DIR"/*.iso 2>/dev/null || echo "ISO file not found in output directory"
    echo ""
    echo "Next steps:"
    echo "  1. Test in VM: qemu-system-x86_64 -enable-kvm -m 4G -boot d -cdrom $OUTPUT_DIR/*.iso"
    echo "  2. Write to USB: sudo dd if=$OUTPUT_DIR/*.iso of=/dev/sdX bs=4M status=progress"
    echo "  3. Boot from USB and run: ./install-hifam.sh"
else
    echo ""
    echo "Build failed with exit code $BUILD_EXIT"
    echo "Check the output above for errors"
    exit $BUILD_EXIT
fi

exit 0
