#!/usr/bin/env python3
"""
Create proper splash images for Syslinux and GRUB
Syslinux needs 640x480 PNG with indexed colors
"""
try:
    from PIL import Image
    import sys
    import os

    source_image = "/home/hpham/hifam-arch-files/images/hifam-flag.png"
    syslinux_output = "/home/hpham/hifam-arch/syslinux/splash.png"
    grub_output = "/home/hpham/hifam-arch/grub/splash.png"

    print("Creating optimized splash images...")
    
    # Load original image
    img = Image.open(source_image)
    print(f"Original: {img.size} - {img.mode}")
    
    # Create Syslinux version (640x480, centered on black background)
    syslinux_bg = Image.new('RGB', (640, 480), (0, 0, 0))
    
    # Calculate position to center logo
    logo_width, logo_height = img.size
    x = (640 - logo_width) // 2
    y = (480 - logo_height) // 2
    
    # Convert RGBA to RGB if needed
    if img.mode == 'RGBA':
        # Create RGB version with black background
        rgb_img = Image.new('RGB', img.size, (0, 0, 0))
        rgb_img.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
        img = rgb_img
    
    # Paste logo centered
    syslinux_bg.paste(img, (x, y))
    
    # Convert to indexed color (256 colors) for Syslinux
    syslinux_final = syslinux_bg.convert('P', palette=Image.ADAPTIVE, colors=256)
    syslinux_final.save(syslinux_output, 'PNG')
    print(f"✓ Syslinux: {syslinux_output} (640x480, indexed)")
    
    # Create GRUB version (keep original size, just ensure RGB)
    grub_img = Image.open(source_image)
    if grub_img.mode == 'RGBA':
        # GRUB can handle transparency, but RGB is safer
        grub_bg = Image.new('RGB', grub_img.size, (0, 0, 0))
        grub_bg.paste(grub_img, mask=grub_img.split()[3])
        grub_img = grub_bg
    grub_img.save(grub_output, 'PNG', optimize=True)
    print(f"✓ GRUB: {grub_output} ({grub_img.size})")
    
    print("\nDone! Splash images created.")
    
except ImportError:
    print("ERROR: Pillow not installed!")
    print("Install with: pip install Pillow")
    print("\nOr install manually:")
    print("  sudo pacman -S python-pillow")
    sys.exit(1)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
