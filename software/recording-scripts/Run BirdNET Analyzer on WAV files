#!/usr/bin/env python3

"""
Run BirdNET Analyzer on WAV files in the same folder as this script.

HOW TO USE ON A MAC
-------------------

1. Put this Python file in the same folder as the WAV files you want to analyze.

2. Open Terminal.

3. Activate your BirdNET Analyzer virtual environment:

       source "$HOME/Code/birdnet-analyzer-venv/bin/activate"

   Your prompt should then begin with something like:

       (birdnet-analyzer-venv)

4. Go to the folder that contains this script and your WAV files.
   Example:

       cd "/Volumes/T7/NFC recordings/2025-10-03"

   Or, if the files are on your Desktop:

       cd "$HOME/Desktop"

5. Run this script:

       python run_birdnet_on_wavs.py

6. The first run is a DRY RUN. It will show which files would be analyzed,
   but it will not run BirdNET.

7. When the dry run looks right, open this file in a text editor and change:

       DRY_RUN = True

   to:

       DRY_RUN = False

8. Run it again:

       python run_birdnet_on_wavs.py

WHAT THIS SCRIPT DOES
---------------------

- Looks only in the folder where this Python file is saved.
- Finds .wav or .WAV files in that folder only.
- If REQUIRE_NFC_FILENAME is True, only analyzes files whose names begin with:

      NFCs starting YYYY-MM-DD HH-MM-SS

  Example:

      NFCs starting 2025-10-03 20-09-26.wav

- If NIGHT_ONLY is True, only analyzes files with start hours:

      20, 21, 22, 23, 00, 01, 02, 03

  This includes 8:00 PM through 3:59:59 AM.
  It excludes 4:00 AM through 7:59:59 PM.

- Calculates BirdNET --week from the date in the filename.
- Keeps the Boston-area coordinates:

      latitude:  42.4154
      longitude: -71.1565

- Creates one output folder per WAV file, in the same folder as the WAV:

      BirdNET results YYYY-MM-DD HH-MM

- Runs BirdNET Analyzer with CSV, table, and Audacity label output.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


# -----------------------------
# User settings
# -----------------------------

LAT = "42.4154"
LON = "-71.1565"

MIN_CONF = "0.25"
SENSITIVITY = "1.0"

# True = only analyze files named like:
# NFCs starting 2025-10-03 20-09-26.wav
#
# False = analyze all .wav/.WAV files in the folder.
REQUIRE_NFC_FILENAME = True

# True = only include files with filename times from 20:00:00 through 03:59:59.
# Only applies when REQUIRE_NFC_FILENAME is True.
NIGHT_ONLY = True

# True = show what would happen, but do not run BirdNET.
# Change to False when ready.
DRY_RUN = True

# True = skip a file if its output folder already exists.
SKIP_IF_OUTPUT_EXISTS = True


NFC_PATTERN = re.compile(
    r"^NFCs starting "
    r"(?P<date>\d{4}-\d{2}-\d{2}) "
    r"(?P<hour>\d{2})-(?P<minute>\d{2})-(?P<second>\d{2})"
    r"\.[Ww][Aa][Vv]$"
)


def birdnet_week_from_date(date_string: str) -> int:
    """
    Convert YYYY-MM-DD to BirdNET's approximate 1-48 week value.

    BirdNET uses four week bins per month:
    Jan = 1-4, Feb = 5-8, ..., Dec = 45-48.

    Days 1-7   = week 1 of month
    Days 8-14  = week 2 of month
    Days 15-21 = week 3 of month
    Days 22+   = week 4 of month
    """
    _year_text, month_text, day_text = date_string.split("-")
    month = int(month_text)
    day = int(day_text)

    if day <= 7:
        week_in_month = 1
    elif day <= 14:
        week_in_month = 2
    elif day <= 21:
        week_in_month = 3
    else:
        week_in_month = 4

    return (month - 1) * 4 + week_in_month


def find_wav_files(folder: Path) -> list[Path]:
    """Return direct-child WAV files in this folder."""
    wavs = []
    for path in folder.iterdir():
        if path.is_file() and path.suffix.lower() == ".wav":
            wavs.append(path)
    return sorted(wavs)


def check_birdnet_available() -> None:
    """Confirm BirdNET Analyzer is available in the current Python environment."""
    command = [sys.executable, "-m", "birdnet_analyzer.analyze", "--help"]

    result = subprocess.run(
        command,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        text=True,
    )

    if result.returncode != 0:
        print("ERROR: BirdNET Analyzer is not available in this Python environment.")
        print()
        print("Try running:")
        print('  source "$HOME/Code/birdnet-analyzer-venv/bin/activate"')
        print("  python run_birdnet_on_wavs.py")
        sys.exit(1)


def should_include_file(wav_path: Path) -> tuple[bool, str | None, str | None, str | None, int | None, str | None]:
    """
    Decide whether a WAV should be analyzed.

    Returns:
        include, date, hour, minute, birdnet_week, skip_reason
    """
    if not REQUIRE_NFC_FILENAME:
        return True, None, None, None, None, None

    match = NFC_PATTERN.match(wav_path.name)
    if not match:
        return False, None, None, None, None, "filename pattern"

    date_string = match.group("date")
    hour = match.group("hour")
    minute = match.group("minute")

    hour_number = int(hour)

    if NIGHT_ONLY:
        if not (hour_number >= 20 or hour_number < 4):
            return False, date_string, hour, minute, None, "outside target time window"

    week = birdnet_week_from_date(date_string)

    return True, date_string, hour, minute, week, None


def output_folder_for(wav_path: Path, date_string: str | None, hour: str | None, minute: str | None) -> Path:
    """Create the intended BirdNET output folder path."""
    if date_string and hour and minute:
        return wav_path.parent / f"BirdNET results {date_string} {hour}-{minute}"

    return wav_path.parent / f"BirdNET results {wav_path.stem}"


def format_command_for_display(command: list[str]) -> str:
    """Return a shell-readable version of a command for logging."""
    formatted_parts = []
    for part in command:
        if " " in part or "'" in part or '"' in part:
            escaped = part.replace('"', '\\"')
            formatted_parts.append(f'"{escaped}"')
        else:
            formatted_parts.append(part)
    return " ".join(formatted_parts)


def run_birdnet(wav_path: Path, output_folder: Path, birdnet_week: int | None) -> int:
    """Run BirdNET Analyzer on one WAV file."""
    command = [
        sys.executable,
        "-m",
        "birdnet_analyzer.analyze",
        str(wav_path),
        "-o",
        str(output_folder),
        "--lat",
        LAT,
        "--lon",
        LON,
        "--min_conf",
        MIN_CONF,
        "--sensitivity",
        SENSITIVITY,
        "--rtype",
        "csv",
        "table",
        "audacity",
        "--additional_columns",
        "lat",
        "lon",
        "week",
        "sensitivity",
        "min_conf",
        "model",
    ]

    if birdnet_week is not None:
        command.extend(["--week", str(birdnet_week)])

    print()
    print("Running BirdNET:")
    print(format_command_for_display(command))
    print()

    result = subprocess.run(command, text=True)
    return result.returncode


def main() -> None:
    script_folder = Path(__file__).resolve().parent

    print(f"Script folder: {script_folder}")
    print(f"Python: {sys.executable}")
    print()

    check_birdnet_available()

    wav_files = find_wav_files(script_folder)

    if not wav_files:
        print("No WAV files found in this folder.")
        sys.exit(0)

    print(f"Found {len(wav_files)} WAV file(s) in this folder.")
    print()

    candidates: list[tuple[Path, Path, int | None]] = []

    skipped_pattern = 0
    skipped_time = 0
    skipped_existing = 0

    for wav_path in wav_files:
        include, date_string, hour, minute, birdnet_week, skip_reason = should_include_file(wav_path)

        if not include:
            if skip_reason == "outside target time window":
                skipped_time += 1
                print(f"Skipping outside target time window: {wav_path.name}")
            elif skip_reason == "filename pattern":
                skipped_pattern += 1
                print(f"Skipping filename that does not match NFC pattern: {wav_path.name}")
            else:
                print(f"Skipping: {wav_path.name}")
            continue

        out_folder = output_folder_for(wav_path, date_string, hour, minute)

        if SKIP_IF_OUTPUT_EXISTS and out_folder.exists():
            skipped_existing += 1
            print(f"Skipping because output folder already exists: {out_folder.name}")
            continue

        candidates.append((wav_path, out_folder, birdnet_week))

    print()
    print("Summary before analysis")
    print("-----------------------")
    print(f"Candidate files:                  {len(candidates)}")
    print(f"Skipped, filename pattern issue:   {skipped_pattern}")
    print(f"Skipped, outside time window:      {skipped_time}")
    print(f"Skipped, output folder exists:     {skipped_existing}")
    print()

    if not candidates:
        print("No files to analyze.")
        sys.exit(0)

    if DRY_RUN:
        print("DRY RUN MODE: BirdNET will not run.")
        print("Change DRY_RUN = True to DRY_RUN = False when ready.")
        print()
        for wav_path, out_folder, birdnet_week in candidates:
            print(f"Would analyze: {wav_path.name}")
            print(f"Would output:  {out_folder}")
            print(f"BirdNET week:  {birdnet_week if birdnet_week is not None else '[none]'}")
            print()
        sys.exit(0)

    analyzed = 0
    failed = 0

    for wav_path, out_folder, birdnet_week in candidates:
        out_folder.mkdir(parents=True, exist_ok=True)

        print("=" * 72)
        print(f"Analyzing: {wav_path.name}")
        print(f"Output:    {out_folder}")
        print(f"Week:      {birdnet_week if birdnet_week is not None else '[none]'}")

        exit_code = run_birdnet(wav_path, out_folder, birdnet_week)

        if exit_code == 0:
            analyzed += 1
            print(f"Done: {wav_path.name}")
        else:
            failed += 1
            print(f"ERROR: BirdNET failed for {wav_path.name} with exit code {exit_code}")

    print()
    print("Final summary")
    print("-------------")
    print(f"Analyzed successfully: {analyzed}")
    print(f"Failed:                {failed}")


if __name__ == "__main__":
    main()
