# Secured-environment-on-Linux
Advanced Linux Administration Projec

This Bash script allows you to easily create, open, and close an encrypted disk image using LUKS on Linux. It automates the setup of a secure storage volume, making it simple to manage encrypted data with just a few commands.

## Features

- **Create** an encrypted disk image of configurable size and password.
- **Open** and mount the encrypted volume for use.
- **Close** and safely unmount the volume.
- Automatic privilege escalation (runs as root if needed).
- Error handling at every step.

## Requirements

- Linux system with `cryptsetup` and `losetup` utilities.
- Root privileges (the script will prompt for `sudo` if not run as root).

## Usage

```bash
./script.sh {install|open|close} [options]
```

### Commands

- `install` : Create and mount a new encrypted volume.
- `open`    : Open and mount an existing encrypted volume.
- `close`   : Unmount and close the encrypted volume.

### Options

- `-p, --password <password>` : Set the password for the encrypted volume (default: `azerty123`)
- `-s, --size <size>`         : Set the size of the image file in GB (default: `5`)

### Examples

**Create a 10GB encrypted volume with a custom password:**
```bash
./script.sh install -p mysecret -s 10
```

**Open the encrypted volume:**
```bash
./script.sh open -p mysecret
```

**Close the encrypted volume:**
```bash
./script.sh close
```

## How It Works

- The script creates a disk image (`cc.img`) and sets up a loop device.
- It formats the image with LUKS encryption using your password.
- The encrypted device is formatted with ext4 and mounted at `/mnt`.
- When closing, it unmounts `/mnt`, closes the LUKS mapping, and detaches the loop device.

## Security Note

**Do not use the default password in production!**  
Always set a strong, unique password for your encrypted volumes.

## Troubleshooting

- Make sure you run the script as root or with `sudo`.
- If you see errors about devices being busy or already open, ensure you have closed previous sessions.
- The script manages only one volume (`cc.img`) and mapping (`safe`) at a time.

---

**Author:**  
sdai02
