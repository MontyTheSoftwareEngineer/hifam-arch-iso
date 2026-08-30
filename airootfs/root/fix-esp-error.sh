#!/bin/bash
# Quick Fix for ESP Detection Issue
# Use this if archinstall fails to detect ESP

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  HiFam Arch - ESP Detection Fix                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "The ESP detection error happens when archinstall can't find"
echo "or create an EFI System Partition."
echo ""
echo "SOLUTIONS:"
echo ""
echo "Option 1: Use Interactive Disk Configuration (RECOMMENDED)"
echo "  • Run: archinstall"
echo "  • Configure disk layout manually in the TUI"
echo "  • Select your disk and let archinstall partition it"
echo "  • Load your config when prompted"
echo ""
echo "Option 2: Use GRUB Instead of Limine"
echo "  • GRUB is more flexible with disk configurations"
echo "  • Config updated to use GRUB by default"
echo ""
echo "Option 3: Manual Partitioning (Advanced)"
echo "  • Partition disk yourself with fdisk/cfdisk"
echo "  • Create ESP: 512MB FAT32, set type to EFI System"
echo "  • Then run archinstall --config with --advanced"
echo ""

read -p "Which option? (1=Interactive, 2=Continue with GRUB config, 3=Manual): " choice

case $choice in
    1)
        echo ""
        echo "Starting archinstall in interactive mode..."
        echo "TIP: In the menu, configure disk first, then load config."
        sleep 2
        archinstall
        ;;
    2)
        echo ""
        echo "Using GRUB configuration..."
        if [ -f "/root/hifam-config/user_configuration.json" ]; then
            archinstall --config /root/hifam-config/user_configuration.json \
                       --creds /root/hifam-config/user_credentials.json
        else
            echo "Config not found! Running interactive mode."
            archinstall
        fi
        ;;
    3)
        echo ""
        echo "Manual partitioning instructions:"
        echo ""
        echo "1. List disks: lsblk"
        echo "2. Partition: cfdisk /dev/sdX"
        echo "   • Create EFI partition: 512MB, type 'EFI System'"
        echo "   • Create root partition: remaining space, type 'Linux filesystem'"
        echo "3. Format EFI: mkfs.fat -F32 /dev/sdX1"
        echo "4. Format root: mkfs.ext4 /dev/sdX2"
        echo "5. Mount root: mount /dev/sdX2 /mnt"
        echo "6. Mount EFI: mkdir -p /mnt/boot && mount /dev/sdX1 /mnt/boot"
        echo "7. Then run archinstall --advanced"
        echo ""
        echo "Or use this automated helper:"
        read -p "Enter disk to partition (e.g., /dev/sda): " DISK
        if [ -b "$DISK" ]; then
            echo "Creating partition table on $DISK..."
            echo "WARNING: This will ERASE ALL DATA on $DISK!"
            read -p "Continue? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                parted -s "$DISK" mklabel gpt
                parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
                parted -s "$DISK" set 1 esp on
                parted -s "$DISK" mkpart primary ext4 513MiB 100%
                echo "Partitions created. Formatting..."
                mkfs.fat -F32 "${DISK}1"
                mkfs.ext4 "${DISK}2"
                echo "Mounting..."
                mount "${DISK}2" /mnt
                mkdir -p /mnt/boot
                mount "${DISK}1" /mnt/boot
                echo ""
                echo "✓ Disk ready! Now run: archinstall --mount-point /mnt"
            else
                echo "Aborted."
            fi
        else
            echo "Error: $DISK is not a block device"
        fi
        ;;
    *)
        echo "Invalid choice. Running interactive mode."
        archinstall
        ;;
esac
