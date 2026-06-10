# NFC Tools

**Record and identify night-flying birds.**

NFC Tools is a free app for Mac, Windows, and Linux that records audio
overnight and tells you which birds it heard. It's designed for
naturalists, classrooms, and curious people — no programming required.

## What you'll need

- A computer that can stay on overnight (laptop or desktop).
- A microphone — even a built-in laptop mic works for testing, but a
  cheap external USB mic placed near a window or on a roof works much
  better. A parabolic dish or a "deck mic" pointed at the sky is best.
- Internet access (only during setup; recording itself is offline).
- About 10 GB of free disk space per night.

## Install

1. Download NFC Tools for your operating system from the releases page.
2. Open the downloaded file:
   - Mac: drag NFC Tools into your Applications folder.
   - Windows: run the installer.
   - Linux: run the AppImage, or install the .deb.
3. Launch NFC Tools. A browser window will open with the setup wizard.

## First-run setup

The wizard walks you through four steps:

1. Where you are. Type your town and click "Look up" to fill in the
   coordinates. (You can also paste exact latitude/longitude.)
2. Your microphone. Pick the input device and click Test. You should
   see "Levels look good." If not, pick another mic or move it.
3. When to record. Defaults are 9 PM to 6:15 AM, which works for most
   people. You can also click "Suggest times based on sunset/sunrise."
4. Analyzers. Leave both BirdNET and Nighthawk checked unless you know
   you want only one. They will download in the background after you
   save (about 200 to 500 MB total).

## Running a session

From the Dashboard, click "Start tonight's session" before you go to
bed. The app will record audio in 1-hour clips, run each clip through
the analyzers as soon as it is saved, and stop automatically at your
scheduled end time.

## Auto-record every night (optional)

Open the app, click Auto-record in the menu, and click "Enable nightly
recording." Your computer will start a session by itself each night
at your configured start time. To turn it off, return to the same
page and click Disable.

- Keep your computer plugged in and not asleep at start time.
- This uses your operating system's user-level scheduler. No admin
  rights are required.

## Sunset / sunrise presets

In Settings (or first-run setup), click "Suggest times based on
sunset/sunrise." Pick a preset:

- Civil twilight: 30 min after sunset to 30 min before sunrise. Best
  for most migration nights.
- Astronomical: 90 min after sunset to 90 min before sunrise.
- Dusk to dawn: sunset to sunrise.
- Evening only / Morning only: partial nights.

Times are computed for your location.

## Browsing detections

Click Detections in the menu and pick a night. You will see:

1. Tonight at a glance: a species summary with detection counts and
   best confidence.
2. Individual detections: every detection with a play button to hear
   a short clip from the recording.

Filter by minimum confidence, by analyzer, or by species name. Click
"Export CSV" to download the filtered list.

## Sharing with eBird

After a session, go to Detections, choose a night, set a reasonable
confidence threshold (0.7+ recommended), and use the eBird-format CSV
export. Listen to clips before submitting! Automated detections are
not perfect; eBird requires you to vouch for your checklist.

## When something goes wrong

The Diagnostics page in the menu runs a health check and explains
problems in plain language. Click "Download diagnostics bundle" to
get a zip file you can email to whoever is helping you.

## What the analyzers do (and don't do)

- BirdNET identifies a wide range of bird sounds.
- Nighthawk is specialized for the brief flight calls birds make
  while migrating at night.
- Both can guess wrong, especially at low confidence. Treat the
  results as leads, not certainties. Listen to the clip yourself
  before reporting a rare bird.

## Privacy

NFC Tools runs entirely on your computer. Recordings stay on your
device. The only network requests it makes are:

- Downloading the analyzers and ffmpeg the first time.
- Looking up weather (optional; can be disabled).
- Looking up a town's coordinates if you use the search box.

No audio is uploaded anywhere.

## License

MIT. See LICENSE.
