#!/bin/zsh

set -u

# ============================================================
# analyze_last_night.zsh
#
# Usage:
#   /bin/zsh "$HOME/Desktop/analyze_last_night.zsh" YYYY-MM-DD
#
# Example:
#   /bin/zsh "$HOME/Desktop/analyze_last_night.zsh" 2026-06-05
#
# This script:
#   1. Takes the session date from AppleScript.
#   2. Finds matching Audition WAV exports on the Desktop.
#   3. Moves them into ~/Desktop/NFC_Recordings/[sessionDate]/audio/
#   4. Runs BirdNET Analyzer.
#   5. Moves BirdNET outputs out of /audio and into /results/birdnet/.
#   6. Runs Nighthawk.
#   7. Writes a simple summary file.
# ============================================================

# -------------------------
# User-editable settings
# -------------------------

DESKTOP="$HOME/Desktop"

# BirdNET virtual environment Python
BIRDNET_PYTHON="$HOME/Code/BirdNET-Analyzer/.venv/bin/python"

# Nighthawk conda environment name
NIGHTHAWK_CONDA_ENV="nighthawk-0.3.1"

# Recording location
LATITUDE="42.415"
LONGITUDE="-71.156"

# BirdNET settings
BIRDNET_MIN_CONF="0.25"

# Final morning cutoff. This should match the AppleScript finalStopTime.
FINAL_STOP_TIME="06:15"

# File naming pattern produced by your AppleScript
FILENAME_PREFIX="NFCs starting"

# Base output folder
BASE_OUTPUT_DIR="$DESKTOP/NFC_Recordings"

# -------------------------
# Helper functions
# -------------------------

log() {
  echo "$@"
}

time_to_minutes() {
  # Convert HH:MM to minutes after midnight.
  # Example: 06:15 -> 375
  local hhmm="$1"
  local hh="${hhmm%%:*}"
  local mm="${hhmm##*:}"

  # Force base-10 interpretation so leading zeroes are safe.
  echo $((10#$hh * 60 + 10#$mm))
}

find_conda() {
  # AppleScript-launched shell scripts often cannot see the same PATH as Terminal.
  # Check PATH first, then common Miniconda/Homebrew locations.
  if command -v conda >/dev/null 2>&1; then
    command -v conda
    return 0
  fi

  local candidates=(
    "/opt/miniconda3/bin/conda"
    "/opt/homebrew/Caskroom/miniconda/base/bin/conda"
    "/opt/homebrew/bin/conda"
    "/usr/local/Caskroom/miniconda/base/bin/conda"
    "/usr/local/bin/conda"
    "$HOME/miniconda3/bin/conda"
    "$HOME/anaconda3/bin/conda"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

move_wav_to_audio_dir() {
  local src="$1"
  local base
  base="$(basename "$src")"

  if [[ "$src" == "$AUDIO_DIR/$base" ]]; then
    return 0
  fi

  if [[ -f "$AUDIO_DIR/$base" ]]; then
    log "Audio already exists in destination, leaving source in place:"
    log "  Source: $src"
    log "  Destination: $AUDIO_DIR/$base"
  else
    log "Moving audio:"
    log "  From: $src"
    log "  To:   $AUDIO_DIR/$base"
    mv "$src" "$AUDIO_DIR/$base"
  fi
}

# -------------------------
# Argument handling
# -------------------------

if [[ $# -lt 1 ]]; then
  log "ERROR: Missing session date."
  log "Usage: /bin/zsh $0 YYYY-MM-DD"
  exit 1
fi

SESSION_DATE="$1"

if ! echo "$SESSION_DATE" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  log "ERROR: Session date must be in YYYY-MM-DD format. Got: $SESSION_DATE"
  exit 1
fi

# Compute next calendar date using macOS date syntax
NEXT_DATE="$(date -j -v+1d -f "%Y-%m-%d" "$SESSION_DATE" "+%Y-%m-%d")"

FINAL_STOP_MINUTES="$(time_to_minutes "$FINAL_STOP_TIME")"

NIGHT_DIR="$BASE_OUTPUT_DIR/$SESSION_DATE"
AUDIO_DIR="$NIGHT_DIR/audio"
RESULTS_DIR="$NIGHT_DIR/results"
BIRDNET_OUT="$RESULTS_DIR/birdnet"
NIGHTHAWK_OUT="$RESULTS_DIR/nighthawk"
SUMMARY_DIR="$RESULTS_DIR/summary"

mkdir -p "$AUDIO_DIR" "$BIRDNET_OUT" "$NIGHTHAWK_OUT" "$SUMMARY_DIR"

log "============================================================"
log "NFC analysis started: $(date '+%Y-%m-%d %H:%M:%S')"
log "Session date: $SESSION_DATE"
log "Next date: $NEXT_DATE"
log "Night folder: $NIGHT_DIR"
log "Audio folder: $AUDIO_DIR"
log "BirdNET output folder: $BIRDNET_OUT"
log "Nighthawk output folder: $NIGHTHAWK_OUT"
log "============================================================"

# -------------------------
# Preflight checks
# -------------------------

if [[ ! -x "$BIRDNET_PYTHON" ]]; then
  log "ERROR: BirdNET Python was not found or is not executable:"
  log "$BIRDNET_PYTHON"
  exit 1
fi

CONDA_CMD="$(find_conda)"
conda_status=$?

if [[ "$conda_status" -ne 0 || -z "$CONDA_CMD" ]]; then
  log "ERROR: conda was not found."
  log "Try this in Terminal:"
  log "  which conda"
  log "Then update the conda candidate paths in this script if needed."
  exit 1
fi

log "Using BirdNET Python: $BIRDNET_PYTHON"
log "Using conda: $CONDA_CMD"

# -------------------------
# Gather matching WAV files
#
# Rule:
#   Include all Desktop files from the session date:
#     NFCs starting YYYY-MM-DD HH-MM-SS.wav
#
#   Include Desktop files from the next morning up to FINAL_STOP_TIME:
#     NFCs starting NEXT_DATE HH-MM-SS.wav
# -------------------------

log ""
log "Gathering Desktop WAV files for this recording night..."

# Session-date files
find "$DESKTOP" -maxdepth 1 -type f \( -name "$FILENAME_PREFIX $SESSION_DATE *.wav" -o -name "$FILENAME_PREFIX $SESSION_DATE *.WAV" \) -print0 |
while IFS= read -r -d '' f; do
  move_wav_to_audio_dir "$f"
done

# Next-date morning files
find "$DESKTOP" -maxdepth 1 -type f \( -name "$FILENAME_PREFIX $NEXT_DATE *.wav" -o -name "$FILENAME_PREFIX $NEXT_DATE *.WAV" \) -print0 |
while IFS= read -r -d '' f; do
  base="$(basename "$f")"

  # Extract HH-MM-SS from:
  # NFCs starting YYYY-MM-DD HH-MM-SS.wav
  time_part="${base#$FILENAME_PREFIX $NEXT_DATE }"
  time_part="${time_part%.*}"

  # Require a recognizable HH-MM-SS pattern.
  if ! echo "$time_part" | grep -Eq '^[0-9]{2}-[0-9]{2}-[0-9]{2}$'; then
    log "Skipping next-date WAV with unexpected filename time: $base"
    continue
  fi

  hour="${time_part%%-*}"
  rest="${time_part#*-}"
  minute="${rest%%-*}"

  file_hhmm="${hour}:${minute}"
  file_minutes="$(time_to_minutes "$file_hhmm")"

  # Include only files before noon and before or at the final stop time.
  if [[ "$file_minutes" -lt 720 && "$file_minutes" -le "$FINAL_STOP_MINUTES" ]]; then
    move_wav_to_audio_dir "$f"
  else
    log "Skipping next-date WAV outside morning cutoff: $base"
  fi
done

# Count audio files
wav_count="$(find "$AUDIO_DIR" -maxdepth 1 -iname "*.wav" | wc -l | tr -d ' ')"

log "WAV files in audio folder: $wav_count"

if [[ "$wav_count" == "0" ]]; then
  log "ERROR: No matching WAV files found."
  log "Expected Desktop files like:"
  log "  $FILENAME_PREFIX $SESSION_DATE HH-MM-SS.wav"
  log "  $FILENAME_PREFIX $NEXT_DATE HH-MM-SS.wav"
  exit 1
fi

# -------------------------
# Run BirdNET Analyzer
# -------------------------

log ""
log "Running BirdNET Analyzer..."
log "Started BirdNET: $(date '+%Y-%m-%d %H:%M:%S')"

"$BIRDNET_PYTHON" -m birdnet_analyzer.analyze "$AUDIO_DIR" \
  --output "$BIRDNET_OUT" \
  --lat "$LATITUDE" \
  --lon "$LONGITUDE" \
  --min_conf "$BIRDNET_MIN_CONF" \
  --rtype csv table \
  --split_tables

birdnet_status=$?

log "Finished BirdNET: $(date '+%Y-%m-%d %H:%M:%S')"
log "BirdNET exit status: $birdnet_status"

if [[ "$birdnet_status" -ne 0 ]]; then
  log "WARNING: BirdNET returned a non-zero exit status. Continuing to Nighthawk."
fi

# BirdNET may place some outputs beside the audio files.
# Move non-audio result files out of /audio and into /results/birdnet/.
log ""
log "Tidying BirdNET outputs..."

find "$AUDIO_DIR" -maxdepth 1 -type f \( \
  -iname "*.csv" -o \
  -iname "*.txt" -o \
  -iname "*.parquet" \
\) -print0 |
while IFS= read -r -d '' result_file; do
  result_base="$(basename "$result_file")"
  log "Moving BirdNET result to birdnet folder: $result_base"
  mv "$result_file" "$BIRDNET_OUT/$result_base"
done

# -------------------------
# Run Nighthawk
# -------------------------

log ""
log "Running Nighthawk..."
log "Started Nighthawk: $(date '+%Y-%m-%d %H:%M:%S')"

"$CONDA_CMD" run -n "$NIGHTHAWK_CONDA_ENV" nighthawk "$AUDIO_DIR"/*.wav \
  --raven-output \
  --audacity-output \
  --output-dir "$NIGHTHAWK_OUT"

nighthawk_status=$?

log "Finished Nighthawk: $(date '+%Y-%m-%d %H:%M:%S')"
log "Nighthawk exit status: $nighthawk_status"

if [[ "$nighthawk_status" -ne 0 ]]; then
  log "WARNING: Nighthawk returned a non-zero exit status."
fi

# -------------------------
# Build simple summary
# -------------------------

SUMMARY_FILE="$SUMMARY_DIR/morning_summary.txt"

{
  echo "NFC Morning Analysis Summary"
  echo "============================"
  echo ""
  echo "Session date: $SESSION_DATE"
  echo "Analysis completed: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "Audio folder:"
  echo "$AUDIO_DIR"
  echo ""
  echo "BirdNET results folder:"
  echo "$BIRDNET_OUT"
  echo ""
  echo "Nighthawk results folder:"
  echo "$NIGHTHAWK_OUT"
  echo ""
  echo "Audio files:"
  find "$AUDIO_DIR" -maxdepth 1 -iname "*.wav" -print | sort
  echo ""
  echo "BirdNET result files:"
  find "$BIRDNET_OUT" -maxdepth 2 -type f -print | sort
  echo ""
  echo "Nighthawk result files:"
  find "$NIGHTHAWK_OUT" -maxdepth 2 -type f -print | sort
} > "$SUMMARY_FILE"

log ""
log "Summary written to:"
log "$SUMMARY_FILE"

log ""
log "Opening night folder..."
open "$NIGHT_DIR"

log ""
log "NFC analysis finished: $(date '+%Y-%m-%d %H:%M:%S')"
log "============================================================"

exit 0
