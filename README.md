# AxNux

A minimal, customized Linux distribution built from scratch.

## Overview

AxNux is a lightweight Linux distribution designed to be minimal, efficient, and customizable. It's built with a focus on simplicity and performance, making it suitable for resource-constrained environments or specialized use cases.

## Features

- Minimal bootable Linux system
- BusyBox-based userland providing essential Unix utilities
- Simple init system
- Custom kernel configuration
- Small footprint (fits in a 50MB boot image)
- Nano-X Window Manager support

## Boot Components

- **bzImage**: The Linux kernel
- **init.cpio**: Initial RAM filesystem containing the root filesystem
- **boot.img**: Bootable FAT32 image with SYSLINUX bootloader

## Building

To build AxNux from source:

1. Make sure you have the necessary build dependencies installed
2. Compile or download a Linux kernel (bzImage)
3. Create an initramfs (init.cpio) containing the desired system files
4. Create a bootable image using the following commands:
   ```bash
   mkdir -p bootdir
   mkfs.vfat -F 32 -n BOOT -C bootdir/boot.img 50000
   mcopy -i bootdir/boot.img bzImage ::/bzImage
   mcopy -i bootdir/boot.img init.cpio ::/init.cpio
   # Create and copy SYSLINUX configuration
   syslinux bootdir/boot.img
   ```

## Management Script

The `axnux.sh` script provides an easy way to build, manage and run AxNux:

```bash
Usage: ./axnux.sh [options]

Options:
  -h, --help           Show help message
  -r, --run            Run AxNux in QEMU
  -m, --memory SIZE    Set QEMU memory size in MB (default: 256)
  -c, --cores NUMBER   Set number of CPU cores (default: 1)
  -s, --serial         Use serial console instead of graphical
  -b, --build          Build initramfs
  -a, --all            Build all (initramfs and update boot img)
  -k, --kernel         Use custom kernel (bzImage)
  -u, --update-boot    Update boot.img with new initramfs
```

Example: `./axnux.sh --build --run --memory 512`

## Booting with QEMU

You can test the distribution in QEMU with:

```bash
qemu-system-x86_64 -drive format=raw,file=bootdir/boot.img
```

Or more easily using the management script:

```bash
./axnux.sh --run
```

## Directory Structure

The project contains the following key files and directories:

- `axnux.sh`: Main management script
- `build_initramfs.sh`: Script to build the initial RAM filesystem
- `bzImage`: Linux kernel image
- `init.cpio`: Compressed initial RAM filesystem
- `bootdir/boot.img`: Bootable disk image
- `initramfs/`: Directory containing all files that go into the RAM filesystem
  - `init`: Init script that runs when the system boots
  - `bin/`, `sbin/`: Essential system binaries
  - `usr/bin/`, `usr/sbin/`: Additional utilities

The booted system contains:
- `/bin`, `/sbin`: Essential system binaries
- `/usr/bin`, `/usr/sbin`: Additional utilities
- `/etc`: Configuration files
- `/dev`: Device files
- `/proc`, `/sys`: Virtual filesystems for system information

## Contributing

Contributions to AxNux are welcome! Feel free to submit pull requests or open issues for bugs and feature requests.

