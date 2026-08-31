# HiFam Arch

HiFam Arch is a custom Arch Linux ISO built with `archiso`.

## Build

Install `archiso`:

```bash
sudo pacman -S archiso
```

Build the ISO:

```bash
sudo mkarchiso -v -w ~/archiso-work -o ~/archiso-out ~/hifam-arch-iso
```

The finished ISO will be placed in:

```text
~/archiso-out/
```

## Test in QEMU

Install QEMU:

```bash
sudo pacman -S qemu-desktop
```

Create a 22 GB virtual disk:

```bash
qemu-img create -f qcow2 ~/arch-test.qcow2 22G
```

Boot the HiFam Arch ISO:

```bash
qemu-system-x86_64 -enable-kvm -m 4G -smp 4 \
  -cdrom ~/archiso-out/hifam-arch-2026.08.31-x86_64.iso \
  -drive file=$HOME/arch-test.qcow2,format=qcow2 \
  -boot d
```

### QEMU Options

* `-enable-kvm` — Enable KVM hardware virtualization
* `-m 4G` — Allocate 4 GB of RAM
* `-smp 4` — Use 4 virtual CPU cores
* `-cdrom` — Boot from the HiFam Arch ISO
* `-drive` — Attach the virtual disk
* `-boot d` — Boot from the CD-ROM first

