#!/bin/bash


# Ensure the script is run as root, otherwise re-execute with sudo
if [[ "$EUID" -ne 0 ]]; then
    exec sudo "$0" "$@"
    exit 0
fi

# INSTALL COMMAND: Create and set up the encrypted volume
if [ "$1" == "install" ]; then
    shift 
    SIZE="5"                # Default image size in GB
    PASSWORD="azerty123"    # Default password

    # Parse command-line options for password and size
    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -p | --password) 
                if [[ -n "$2" ]]; then
                    PASSWORD="$2"
                    shift 2
                fi
                ;;
            -s | --size)
                if [[ -n "$2" ]]; then
                    SIZE="$2"
                    shift 2
                fi
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Install cryptsetup if not present
    if ! command -v cryptsetup &> /dev/null; then 
        apt-get update
        apt-get install cryptsetup
    else
        # Create a random image file of specified size
        dd if=/dev/random of=cc.img bs=1G count="$SIZE"
        if [ $? -ne 0 ]; then
            echo "Failed to create image file. Please check your permissions or available disk space."
            exit 1
        fi

        IMAGE_FILE="cc.img"
        # Set up a loop device for the image file
        LOOPDEV=$(losetup -f --show "$IMAGE_FILE")

        # Format the loop device with LUKS encryption using the provided password
        if [ -z "$PASSWORD" ]; then
            echo -n "azerty123"| cryptsetup --batch-mode luksFormat "$LOOPDEV"
            if [ $? -ne 0 ]; then
                echo "luksFormat failed. Please check your permissions or the device."
                exit 1
            fi

            echo -n "azerty123" | cryptsetup open --type luks "$LOOPDEV" safe
            if [ $? -ne 0 ]; then
                echo "Failed to open the encrypted volume. Please check your permissions or the device."
                exit 1
            fi
        else
            echo -n "$PASSWORD" | cryptsetup --batch-mode luksFormat "$LOOPDEV"
            if [ $? -ne 0 ]; then
                echo "luksFormat failed. Please check your permissions or the device."
                exit 1
            fi

            echo -n "$PASSWORD" | cryptsetup open --type luks "$LOOPDEV" safe
            if [ $? -ne 0 ]; then
                echo "Failed to open the encrypted volume. Please check your permissions or the device."
                exit 1
            fi
        fi

        # Format the encrypted volume with ext4 filesystem
        mkfs.ext4 -L secret /dev/mapper/safe
        if [ $? -ne 0 ]; then
            echo "Failed to format the encrypted volume. Please check your permissions or the device."
            exit 1
        fi

        # Mount the encrypted volume to /mnt
        mount /dev/mapper/safe /mnt
        if [ $? -ne 0 ]; then
            echo "Failed to mount the encrypted volume. Please check your permissions or the device."
            exit 1
        fi

        echo "Installation complete. You can now use the encrypted volume."
        exit 0
    fi

# OPEN COMMAND: Open and mount the encrypted volume
elif [ "$1" == "open" ]; then
    IMAGE_FILE="cc.img"
    # Set up a loop device for the image file
    LOOPDEV=$(losetup -f --show "$IMAGE_FILE" | cut -d: -f1)

    # Check if the encrypted volume is already open
    if [ -e /dev/mapper/safe ]; then
        echo "The encrypted volume is already open. Please close it first."
        losetup -d "$LOOPDEV"
        exit 1
    fi

    # Open the encrypted volume
    cryptsetup open --type luks "$LOOPDEV" safe
    if [ $? -ne 0 ]; then
        echo "Failed to open the encrypted volume. Please check your permissions or the device."
        exit 1
    fi

    # Mount the encrypted volume to /mnt
    mount /dev/mapper/safe /mnt
    if [ $? -ne 0 ]; then
        echo "Failed to mount the encrypted volume. Please check your permissions or the device."
        cryptsetup luksClose safe
        losetup -d "$LOOPDEV"
        exit 1
    fi

    echo "Encrypted volume opened and mounted at /mnt." 
    exit 0

# CLOSE COMMAND: Unmount and close the encrypted volume
elif [ "$1" == "close" ]; then
    IMAGE_FILE="cc.img"
    # Find the loop device associated with the image file
    LOOPDEV=$(losetup -j "$IMAGE_FILE" | cut -d: -f1)
    # Unmount the volume
    umount /mnt
    # Close the encrypted volume
    sudo cryptsetup luksClose safe
    if [ $? -ne 0 ]; then
        echo "Failed to close the encrypted volume. Please check your permissions or the device."
        exit 1
    fi
    # Detach the loop device
    sudo losetup -d "$LOOPDEV"
    if [ $? -ne 0 ]; then
        echo "Failed to detach the loop device. Please check your permissions or the device."

        exit 1
    fi
    echo "Encrypted volume closed and unmounted."
    exit 0

# HELP: Print usage information
else 
    echo "Usage: $0 {install|open|close} [options]"
    echo "Options:"
    echo "  -p, --password <password>  Set the password for the encrypted volume (default: azerty123)"
    echo "  -s, --size <size>           Set the size of the image file in GB (default: 5)"
    exit 1
fi