#!/bin/bash
# Update HiFam Logo/Splash - Replace logo everywhere
# Usage: ./update-logo.sh /path/to/new-logo.png

set -e

NEW_LOGO="$1"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                                                                  ║"
echo "║  HiFam Logo/Splash Updater                                       ║"
echo "║                                                                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Check if logo file provided
if [ -z "$NEW_LOGO" ]; then
    echo "Usage: $0 /path/to/new-logo.png"
    echo ""
    echo "This script will update your HiFam logo in all locations:"
    echo "  • Source image in hifam-arch-files/images/"
    echo "  • Syslinux boot splash (BIOS)"
    echo "  • GRUB boot splash (UEFI)"
    echo "  • Plymouth theme logo"
    echo "  • ISO profile"
    echo ""
    exit 1
fi

# Check if file exists
if [ ! -f "$NEW_LOGO" ]; then
    echo "ERROR: File not found: $NEW_LOGO"
    exit 1
fi

# Check if it's a PNG
if ! file "$NEW_LOGO" | grep -q "PNG image"; then
    echo "ERROR: File is not a PNG image"
    echo "Please provide a PNG file"
    exit 1
fi

echo "New logo: $NEW_LOGO"
file "$NEW_LOGO"
echo ""

# Confirm
read -p "Update all HiFam logos with this image? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Updating logos..."
echo "════════════════════════════════════════════════════════════"

# Update source image
echo ""
echo "1. Updating source image..."
cp "$NEW_LOGO" ~/hifam-arch-files/images/hifam-flag.png
echo "   ✓ ~/hifam-arch-files/images/hifam-flag.png"

# Update Syslinux splash (640x480, centered, RGB)
echo ""
echo "2. Creating Syslinux splash (640x480, RGB)..."
if command -v ffmpeg &> /dev/null; then
    ffmpeg -i "$NEW_LOGO" \
           -vf "scale=640:480:force_original_aspect_ratio=decrease,pad=640:480:(ow-iw)/2:(oh-ih)/2:black" \
           -pix_fmt rgb24 \
           ~/hifam-arch/syslinux/splash.png -y 2>/dev/null
    echo "   ✓ ~/hifam-arch/syslinux/splash.png (640x480, RGB)"
elif command -v convert &> /dev/null; then
    convert "$NEW_LOGO" \
            -resize 640x480 \
            -background black \
            -gravity center \
            -extent 640x480 \
            ~/hifam-arch/syslinux/splash.png
    echo "   ✓ ~/hifam-arch/syslinux/splash.png (640x480)"
else
    echo "   ⚠ Neither ffmpeg nor ImageMagick found!"
    echo "   Copying original (may not display properly in Syslinux)"
    cp "$NEW_LOGO" ~/hifam-arch/syslinux/splash.png
fi

# Update GRUB splash (original size)
echo ""
echo "3. Updating GRUB splash..."
cp "$NEW_LOGO" ~/hifam-arch/grub/splash.png
echo "   ✓ ~/hifam-arch/grub/splash.png (original size)"

# Update Plymouth theme logo
echo ""
echo "4. Updating Plymouth theme logo..."
cp "$NEW_LOGO" ~/hifam-arch/airootfs/usr/share/plymouth/themes/hifam/logo.png
echo "   ✓ ~/hifam-arch/airootfs/usr/share/plymouth/themes/hifam/logo.png"

# Update in hifam-config (so it gets copied during installation)
echo ""
echo "5. Updating hifam-config copy..."
mkdir -p ~/hifam-arch/airootfs/root/hifam-config/images
cp "$NEW_LOGO" ~/hifam-arch/airootfs/root/hifam-config/images/hifam-flag.png
echo "   ✓ ~/hifam-arch/airootfs/root/hifam-config/images/hifam-flag.png"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Logo updated in all locations!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Updated files:"
echo "  • Source: ~/hifam-arch-files/images/hifam-flag.png"
echo "  • Syslinux: ~/hifam-arch/syslinux/splash.png"
echo "  • GRUB: ~/hifam-arch/grub/splash.png"
echo "  • Plymouth: ~/hifam-arch/airootfs/usr/share/plymouth/themes/hifam/logo.png"
echo "  • ISO config: ~/hifam-arch/airootfs/root/hifam-config/images/hifam-flag.png"
echo ""
echo "Next steps:"
echo "  1. Commit changes to git (optional):"
echo "     cd ~/hifam-arch-files"
echo "     git add images/hifam-flag.png"
echo "     git commit -m 'Update HiFam logo'"
echo "     git push"
echo ""
echo "  2. Rebuild ISO:"
echo "     cd ~/hifam-arch"
echo "     ./build-iso.sh"
echo ""
echo "  3. Test the new ISO to see your logo on:"
echo "     • Boot menu (Syslinux/GRUB)"
echo "     • Plymouth splash screen"
echo ""

exit 0
