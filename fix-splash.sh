#!/bin/bash
# Create proper splash images for bootloaders

SOURCE="/home/hpham/hifam-arch-files/images/hifam-flag.png"
SYSLINUX_OUT="/home/hpham/hifam-arch/syslinux/splash.png"
GRUB_OUT="/home/hpham/hifam-arch/grub/splash.png"

echo "Creating optimized splash images..."
echo "Source: $SOURCE"

# Check if ffmpeg is available
if command -v ffmpeg &> /dev/null; then
    echo "Using ffmpeg..."
    
    # Create 640x480 centered splash for Syslinux
    ffmpeg -i "$SOURCE" -vf "scale=640:480:force_original_aspect_ratio=decrease,pad=640:480:(ow-iw)/2:(oh-ih)/2:black" -pix_fmt rgb24 "$SYSLINUX_OUT" -y 2>/dev/null
    echo "✓ Syslinux: $SYSLINUX_OUT (640x480)"
    
    # Copy original for GRUB (GRUB handles any size)
    cp "$SOURCE" "$GRUB_OUT"
    echo "✓ GRUB: $GRUB_OUT (original size)"
    
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick..."
    
    # Create 640x480 centered splash for Syslinux
    convert "$SOURCE" -resize 640x480 -background black -gravity center -extent 640x480 "$SYSLINUX_OUT"
    echo "✓ Syslinux: $SYSLINUX_OUT (640x480)"
    
    # Copy for GRUB
    cp "$SOURCE" "$GRUB_OUT"
    echo "✓ GRUB: $GRUB_OUT (original size)"
    
else
    echo "WARNING: Neither ffmpeg nor ImageMagick found!"
    echo "Copying image as-is (may not display properly in Syslinux)"
    cp "$SOURCE" "$SYSLINUX_OUT"
    cp "$SOURCE" "$GRUB_OUT"
    echo ""
    echo "For proper splash images, install one of:"
    echo "  sudo pacman -S imagemagick"
    echo "  sudo pacman -S ffmpeg"
    echo ""
    echo "Then re-run this script."
fi

echo ""
echo "Done! Rebuild ISO to apply changes:"
echo "  cd ~/hifam-arch && ./build-iso.sh"
