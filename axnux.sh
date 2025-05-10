#!/bin/bash
# AxNux Management Script
# Created: May 10, 2025
# Description: A script to simplify working with AxNux and Nano-X window manager

# Default settings
QEMU_MEMORY=256
QEMU_CORES=1
DISPLAY_OPTION="-display gtk,gl=on"
BUILD_ALL=0
BUILD_INITRAMFS=0
UPDATE_BOOT_IMG=0
USE_KERNEL=0
USE_SERIAL=0

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            AxNux Manager               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Function to display help
show_help() {
    echo -e "${GREEN}AxNux Management Script${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -r, --run            Run AxNux in QEMU"
    echo "  -m, --memory SIZE    Set QEMU memory size in MB (default: 256)"
    echo "  -c, --cores NUMBER   Set number of CPU cores (default: 1)"
    echo "  -s, --serial         Use serial console instead of graphical"
    echo "  -b, --build          Build initramfs"
    echo "  -a, --all            Build all (initramfs and update boot img)"
    echo "  -k, --kernel         Use custom kernel (bzImage)"
    echo "  -u, --update-boot    Update boot.img with new initramfs"
    echo "  -d, --debug-init     Apply debugging changes to init script"
    echo "  --check-init         Check init script for common errors"
    echo ""
    echo "Examples:"
    echo "  $0 --run                   # Run AxNux in QEMU with default settings"
    echo "  $0 --build --run           # Build initramfs and run AxNux"
    echo "  $0 --all --run             # Build all and run AxNux"
    echo "  $0 --memory 512 --run      # Run AxNux with 512MB RAM"
    echo "  $0 --serial --run          # Run with serial console"
    echo ""
}

# Function to build initramfs
build_initramfs() {
    echo -e "${YELLOW}Building initramfs...${NC}"
    
    # First, ensure init script is executable
    echo -e "${YELLOW}Checking init script...${NC}"
    if [ ! -f "initramfs/init" ]; then
        echo -e "${RED}Error: init script not found!${NC}"
        exit 1
    fi
    
    # Make sure it's executable
    chmod +x initramfs/init
    
    # Check if init is a shell script and has correct format
    echo -e "${YELLOW}Validating init script format...${NC}"
    if head -1 initramfs/init | grep -q "^#!/bin/sh"; then
        echo -e "${GREEN}Init script has correct shebang line.${NC}"
    else
        echo -e "${RED}Warning: Init script doesn't have proper #!/bin/sh shebang!${NC}"
        echo -e "${YELLOW}Fixing init script format...${NC}"
        sed -i '1s/^.*$/\#!\/bin\/sh/' initramfs/init
        echo -e "${GREEN}Init script fixed.${NC}"
    fi
    
    # Build initramfs with careful format specification
    echo -e "${YELLOW}Building initramfs with init at root level...${NC}"
    cd initramfs && find . -print0 | cpio --null -o -H newc | gzip -9 > ../init.cpio
    cd ..
    
    # Verify the init file is in the archive
    echo -e "${YELLOW}Verifying init in archive...${NC}"
    if gunzip -c init.cpio | cpio -t | grep -q "^\.\/init$"; then
        echo -e "${GREEN}Init found in archive at correct location.${NC}"
    else
        echo -e "${RED}ERROR: Init not found in archive or at wrong location!${NC}"
        echo -e "${YELLOW}Contents of archive (first few entries):${NC}"
        gunzip -c init.cpio | cpio -t | head -10
    fi
    
    echo -e "${GREEN}Initramfs built successfully!${NC}"
}

# Function to update boot.img
update_boot_img() {
    echo -e "${YELLOW}Updating boot.img with new initramfs...${NC}"
    
    if [ ! -f "init.cpio" ]; then
        echo -e "${RED}Error: init.cpio not found. Build initramfs first.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Copying init.cpio to bootdir...${NC}"
    cp init.cpio bootdir/
    
    echo -e "${CYAN}To update the actual boot.img, run the following commands manually:${NC}"
    echo "mkdir -p /tmp/boot_mnt"
    echo "sudo mount -o loop bootdir/boot.img /tmp/boot_mnt"
    echo "sudo cp bootdir/init.cpio /tmp/boot_mnt/init.cpio"
    echo "sudo umount /tmp/boot_mnt"
    
    echo -e "${GREEN}Boot image preparation completed!${NC}"
}

# Function to run AxNux in QEMU
run_axnux() {
    local QEMU_OPTS=""
    local KERNEL_OPT=""
    local INITRD_OPT=""
    local CONSOLE_OPT="console=tty1"
    
    # Simplified root parameters - focus on finding init
    local APPEND_EXTRA="rdinit=/init"
    
    if [ $USE_KERNEL -eq 1 ]; then
        if [ ! -f "bzImage" ]; then
            echo -e "${RED}Error: bzImage not found.${NC}"
            exit 1
        fi
        
        if [ ! -f "init.cpio" ]; then
            echo -e "${RED}Error: init.cpio not found. Build initramfs first.${NC}"
            exit 1
        fi
        
        KERNEL_OPT="-kernel bzImage"
        INITRD_OPT="-initrd init.cpio"
    else
        if [ ! -f "bootdir/boot.img" ]; then
            echo -e "${RED}Error: boot.img not found.${NC}"
            exit 1
        fi
    fi
    
    if [ $USE_SERIAL -eq 1 ]; then
        DISPLAY_OPTION="-nographic"
        CONSOLE_OPT="console=ttyS0"
        echo -e "${YELLOW}Using serial console. Press Ctrl+A, X to exit QEMU.${NC}"
    else
        echo -e "${YELLOW}Using graphical console. Close the QEMU window to exit.${NC}"
    fi
    
    echo -e "${YELLOW}Starting AxNux in QEMU...${NC}"
    
    if [ $USE_KERNEL -eq 1 ]; then
        FULL_APPEND="$CONSOLE_OPT $APPEND_EXTRA"
        echo -e "${CYAN}QEMU options: -m $QEMU_MEMORY -smp $QEMU_CORES $DISPLAY_OPTION $KERNEL_OPT $INITRD_OPT -append \"$FULL_APPEND\"${NC}"
        qemu-system-x86_64 -m $QEMU_MEMORY -smp $QEMU_CORES $DISPLAY_OPTION $KERNEL_OPT $INITRD_OPT -append "$FULL_APPEND" -enable-kvm
    else
        echo -e "${CYAN}QEMU options: -m $QEMU_MEMORY -smp $QEMU_CORES $DISPLAY_OPTION -hda bootdir/boot.img${NC}"
        qemu-system-x86_64 -m $QEMU_MEMORY -smp $QEMU_CORES $DISPLAY_OPTION -hda bootdir/boot.img -enable-kvm
    fi
}

# Function to modify init script for debugging
fix_init_for_debugging() {
    echo -e "${YELLOW}Modifying init script for better Nano-X debugging...${NC}"
    
    cat > initramfs/init << 'EOF'
#!/bin/sh

# Basic init script for AxNux with Nano-X

# Mount essential filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Set up the environment
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export TERM=linux

# Display some debug info
echo "AxNux with Nano-X window manager"
echo "Kernel version: $(uname -a)"
echo "Available devices in /dev:"
ls -l /dev
echo "Mounted filesystems:"
mount

# Set up framebuffer
if [ -e /dev/fb0 ]; then
    echo "Framebuffer found: /dev/fb0"
else
    echo "WARNING: No framebuffer device found!"
fi

# Start Nano-X window manager
echo "Starting Nano-X window manager..."
if [ -x /usr/bin/nano-X ]; then
    /usr/bin/nano-X &
    sleep 1
    echo "Nano-X started"
else
    echo "ERROR: nano-X not found or not executable!"
fi

# Start terminal
if [ -x /usr/bin/nxterm ]; then
    /usr/bin/nxterm &
    echo "nxterm started"
else
    echo "ERROR: nxterm not found!"
fi

# Start shell - this prevents init from exiting
echo "Starting shell..."
exec /bin/sh
EOF

    # Make sure init script is properly executable
    chmod +x initramfs/init
    echo -e "${GREEN}Init script modified for better debugging!${NC}"
}

# Function to check init script for common errors
check_init_script() {
    echo -e "${YELLOW}Checking init script for common errors...${NC}"
    
    if [ ! -f "initramfs/init" ]; then
        echo -e "${RED}Error: init script does not exist!${NC}"
        return 1
    fi
    
    if [ ! -x "initramfs/init" ]; then
        echo -e "${RED}Error: init script is not executable!${NC}"
        echo -e "${YELLOW}Fixing permissions...${NC}"
        chmod +x initramfs/init
        echo -e "${GREEN}Fixed.${NC}"
    fi
    
    # Check shebang
    if ! head -1 initramfs/init | grep -q "^#!/bin/sh"; then
        echo -e "${RED}Warning: Init script doesn't have proper #!/bin/sh shebang!${NC}"
    fi
    
    # Check for common errors in the script
    if grep -q "[^-]rm " initramfs/init; then
        echo -e "${RED}Warning: Init script contains 'rm' command which might be dangerous in init!${NC}"
    fi
    
    echo -e "${GREEN}Init script check completed.${NC}"
    return 0
}

# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )           show_help
                                exit
                                ;;
        -r | --run )            RUN_AXNUX=1
                                ;;
        -m | --memory )         shift
                                QEMU_MEMORY=$1
                                ;;
        -c | --cores )          shift
                                QEMU_CORES=$1
                                ;;
        -s | --serial )         USE_SERIAL=1
                                ;;
        -b | --build )          BUILD_INITRAMFS=1
                                ;;
        -a | --all )            BUILD_ALL=1
                                ;;
        -k | --kernel )         USE_KERNEL=1
                                ;;
        -u | --update-boot )    UPDATE_BOOT_IMG=1
                                ;;
        -d | --debug-init )     FIX_INIT=1
                                ;;
        --check-init )          CHECK_INIT=1
                                ;;
        * )                     echo -e "${RED}Unknown parameter: $1${NC}"
                                show_help
                                exit 1
                                ;;
    esac
    shift
done

# If no arguments given, show help
if [ $# -eq 0 ] && [ -z "$RUN_AXNUX" ] && [ $BUILD_INITRAMFS -eq 0 ] && [ $BUILD_ALL -eq 0 ] && [ $UPDATE_BOOT_IMG -eq 0 ] && [ -z "$FIX_INIT" ] && [ -z "$CHECK_INIT" ]; then
    show_help
    exit 0
fi

# Check init script if requested
if [ ! -z "$CHECK_INIT" ]; then
    check_init_script
fi

# Fix init script if requested
if [ ! -z "$FIX_INIT" ]; then
    fix_init_for_debugging
fi

# Build all if requested
if [ $BUILD_ALL -eq 1 ]; then
    BUILD_INITRAMFS=1
    UPDATE_BOOT_IMG=1
fi

# Build initramfs if requested
if [ $BUILD_INITRAMFS -eq 1 ]; then
    build_initramfs
fi

# Update boot.img if requested
if [ $UPDATE_BOOT_IMG -eq 1 ]; then
    update_boot_img
fi

# Run AxNux if requested
if [ ! -z "$RUN_AXNUX" ]; then
    run_axnux
fi

exit 0