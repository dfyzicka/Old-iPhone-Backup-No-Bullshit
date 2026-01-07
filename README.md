# OLD-iPhone-Backup-No-Bullshit 📱💾

**[English](#english) | [Русский](#russian)**

A robust PowerShell script to salvage photos and videos from old iPhones (and other MTP devices) to Windows 10/11, preserving folder structure and sanity.

---

## <a name="english"></a>English

### The Backstory
I had an **iPhone 7 Plus (512GB)** and a **Windows 11** PC.
Trying to copy thousands of files via Windows Explorer was a nightmare:
1. **Crashes** in the middle of the process without logs.
2. **"Device Unreachable"** errors appearing randomly.
3. **Hanging indefinitely** on "Calculating time...".
4. Standard Windows Import dumps everything into one folder or by date, ruining my album structure.

Standard PowerShell `Copy-Item` fails with MTP devices because paths like `This PC\iPhone\...` are virtual. I needed a solution that copies files recursively, keeps the `DCIM\100APPLE` folder structure, filters weird duplicates, and doesn't crash on large video files.

### How It Works
This script uses the Windows **Shell.Application** COM object to interface with the MTP driver, but with a unique logic we discovered through trial and error:

*   **Batch "Burst" Mode:** Instead of waiting for each file (too slow) or spamming commands (crashes the driver), the script sends copy commands in **batches of 19**, then **pauses for 3 seconds**.
*   **Native Queue Handling:** For small files (photos), the batches fly through. For large files (videos), Windows opens its native copy dialog, automatically blocking the script until the resource is free. This acts as a natural load balancer.
*   **Phantom Duplicate Filter:** iPhones often present the same file twice via MTP (e.g., `IMG_0401.AAE` appearing twice). The script filters duplicates by name to prevent the annoying "File already exists" popup.
*   **Recursive:** Recreates the exact folder structure (`100APPLE`, `101APPLE`...) on your destination drive.

### Usage

1. Download `Backup-iPhone.ps1`.
2. Open it in a text editor. You can tweak the "Burst" settings if your phone is slower/faster:
   ```powershell
   $BatchSize = 19        # Number of files to send in one burst
   $BatchDelaySec = 3     # Pause in seconds after each burst
