#!/usr/bin/env bash

# Audio Recording Script - Records system audio (not microphone)

RECORDINGS_DIR="$HOME/Recordings"
PID_FILE="/tmp/audio-recording.pid"
STATUS_FILE="/tmp/audio-recording-status"

mkdir -p "$RECORDINGS_DIR"

# Check if recording is active
if [ -f "$PID_FILE" ]; then
    # Stop recording
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        rm -f "$PID_FILE" "$STATUS_FILE"
        notify-send "Recording Stopped" -t 1500
    else
        rm -f "$PID_FILE" "$STATUS_FILE"
    fi
else
    # Start recording
    FILENAME="$RECORDINGS_DIR/audio_$(date +%Y-%m-%d_%H-%M-%S).mp3"
    
    # Get default audio sink (system audio output)
    SINK=$(pactl get-default-sink)
    
    if [ -z "$SINK" ]; then
        notify-send "Recording Error" "Could not detect system audio" -u critical -t 2000
        exit 1
    fi
    
    # Start recording system audio only (not microphone)
    pw-record --target "$SINK.monitor" --channels 2 "$FILENAME" &
    
    # Save PID
    echo $! > "$PID_FILE"
    echo "recording" > "$STATUS_FILE"
    
    notify-send "Recording Started" -t 1500
fi
