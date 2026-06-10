# NFC Tools

NFC Tools records overnight audio and helps you review possible nocturnal flight calls from migrating birds.

It is designed for people who want to leave a computer and microphone running overnight, then review bird-call detections the next day. It can record audio in timed WAV files, analyze each completed recording segment, show detections in a local browser interface, and export results for further review.

NFC Tools runs on your own computer. Audio stays on your device.

## What you need

- A Mac, Windows, or Linux computer that can stay on overnight.
- Python 3.10 or newer, if you are running from source.
- A microphone. A built-in mic is fine for testing, but an external USB mic or purpose-built NFC microphone is much better.
- Enough disk space for overnight WAV recordings. Plan on several GB per night, depending on sample rate, channels, and recording length.
- Internet access during setup, especially if installing analyzers.

## How to start the app from this repository

These steps are for someone who downloaded or cloned the repository and wants to run NFC Tools from source.

### 1. Open a terminal

On macOS, open **Terminal**.

On Windows, open **PowerShell**.

On Linux, open your usual terminal app.

### 2. Go to the NFC Tools folder

From the repository root, run:

```bash
cd software/nfc-tools
