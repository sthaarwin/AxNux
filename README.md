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

## Booting with QEMU

You can test the distribution in QEMU with:

```bash
qemu-system-x86_64 -drive format=raw,file=bootdir/boot.img
```

## Directory Structure

The main components of the system are:
- `/bin`, `/sbin`: Essential system binaries
- `/usr/bin`, `/usr/sbin`: Additional utilities
- `/etc`: Configuration files
- `/dev`: Device files
- `/proc`, `/sys`: Virtual filesystems for system information

## Contributing

Contributions to AxNux are welcome! Feel free to submit pull requests or open issues for bugs and feature requests.

