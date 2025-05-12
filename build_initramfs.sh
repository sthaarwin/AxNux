#!/bin/bash
# Simple script to build initramfs for AxNux

echo "Building AxNux initramfs..."

# Make sure init script is executable
echo "Making init script executable..."
chmod +x initramfs/init

# Check if init exists
if [ ! -f "initramfs/init" ]; then
    echo "ERROR: init script not found!"
    exit 1
fi

echo "Building initramfs with a very simple and direct method..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Copy all files from initramfs to temp dir
echo "Copying files to temporary directory..."
cp -a initramfs/* $TEMP_DIR/

# Make absolutely sure init is executable
chmod +x $TEMP_DIR/init

# Create the initramfs from the temp directory
echo "Creating initramfs archive..."
cd $TEMP_DIR
find . | cpio -H newc -o | gzip > ../init.cpio
cd ..

# Clean up
echo "Cleaning up temporary directory..."
rm -rf $TEMP_DIR

# Verify contents
echo "Verifying archive contents..."
if gunzip -c init.cpio | cpio -t | grep -q "init" || gunzip -c init.cpio | cpio -t | grep -q "./init"; then
    echo "SUCCESS: Init script found in archive."
else
    echo "ERROR: Init script not found in archive!"
    echo "Archive contents (first 20 entries):"
    gunzip -c init.cpio | cpio -t | head -20
    exit 1
fi

echo "Initramfs built successfully."