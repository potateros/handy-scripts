#!/bin/bash

# Check if at least 2 arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <audio_file> <transcript_name>"
  exit 1
fi

# Assign the arguments to variables
AUDIO_NAME=$1
TRANSCRIPT_NAME=$2

# Convert to WAV with 16kHz sampling rate
ffmpeg -i "${AUDIO_NAME}" -ar 16000 audio.wav

# Segment the audio file into 10-minute chunks
ffmpeg -i audio.wav -f segment -segment_time 600 -c copy audio_chunk_%03d.wav

# Calculate the number of segments
segment_count=$(ls audio_chunk_*.wav | wc -l)

# Function to add time offset to a timestamp
add_time_offset() {
  local timestamp=$1
  local offset_minutes=$2

  local orig_hours=$(echo "$timestamp" | cut -d: -f1 | tr -d '[]')
  local orig_minutes=$(echo "$timestamp" | cut -d: -f2)
  local seconds=$(echo "$timestamp" | cut -d: -f3 | cut -d' ' -f1)

  local total_minutes=$((orig_hours * 60 + orig_minutes + offset_minutes))
  local new_hours=$((total_minutes / 60))
  local new_minutes=$((total_minutes % 60))

  printf "[%02d:%02d:%s]" $new_hours $new_minutes $seconds
}

for i in $(seq 0 $((segment_count - 1)))
do
  # Format the numbers to three digits with leading zeros
  input_number=$(printf "%03d" $i)
  output_number=$((i + 1))

  # Transcribe the audio chunk with Whisper.cpp
  ./main -m ./models/ggml-large-v3.bin --max-context 64 -f "./audio_chunk_${input_number}.wav" > "${TRANSCRIPT_NAME}-${output_number}.txt"

  # Calculate the offset in minutes
  offset_minutes=$((i * 10))

  # Read the file and modify the timestamps
  while read -r line; do
    if [[ $line =~ \[([0-9]{2}):([0-9]{2}):([0-9]{2}\.[0-9]{3})\] ]]; then
      start_timestamp="${BASH_REMATCH[0]}"
      new_start_timestamp=$(add_time_offset "$start_timestamp" $offset_minutes)
      line=${line//$start_timestamp/$new_start_timestamp}
    fi
    echo "$line"
  done < "${TRANSCRIPT_NAME}-${output_number}.txt" > tmpfile && mv tmpfile "${TRANSCRIPT_NAME}-${output_number}.txt"

done

# Combine all transcripts into a single file
cat ${TRANSCRIPT_NAME}-*.txt > combined_transcript.txt
