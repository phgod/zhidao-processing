#!/bin/bash
# Simple script to automatically process the audio files in zhidao (Haoran Zhang, 20190518)
# Requirements: 
# 1. sox
# 2. Handlers for the audio formats used (e.g. libsox-fmt-mp3 for mp3)
# 3. The files defined by PRE_AUDIO and POST_AUDIO must exist.
# How to use:
# 1. Put all the audio files into the directory defined by INPUT_DIR.
# 2. Run this script "./process.sh".

INPUT_DIR="input" # Directory containing the audio files to be converted
OUTPUT_DIR="output" # The converted audio files will be found here

INPUTS="$INPUT_DIR"/*

PRE_AUDIO="開場聲效.mp3"
POST_AUDIO="問卷呼籲.mp3"

TEMP_DIR="temp"
MONO_AUDIO="$TEMP_DIR/mono.mp3"

DENOISED_AUDIO="$TEMP_DIR/denoised.mp3"
NOISE_AUDIO="$TEMP_DIR/noise-audio.mp3"
NOISE_PROF="$TEMP_DIR/noise.prof"

NORMALIZED_AUDIO="$TEMP_DIR/normalized.mp3"

mkdir -p $TEMP_DIR

if [ ! -d $OUTPUT_DIR ]; then
  echo "Creating $OUTPUT_DIR to hold the results..."
  mkdir $OUTPUT_DIR
fi

for INPUT in $INPUTS; do

  OUTPUT=$OUTPUT_DIR/$(basename "$INPUT")
  
  echo "### Processing $INPUT... ###"

  ##### STEP 0: Reduce to mono #####
  sox "$INPUT" "$MONO_AUDIO" channels 1
  
  ##### Step 1: Noise reduction #####
  
  echo "Producing noise profile using the first 0.9s (assume this is silence)..."
  sox "$MONO_AUDIO" $NOISE_AUDIO trim 0 0.900
  sox $NOISE_AUDIO -n noiseprof $NOISE_PROF
  
  echo "Reducing noise using this noise profile..."
  sox "$MONO_AUDIO" $DENOISED_AUDIO noisered $NOISE_PROF 0.21
  
  ##### Step 2: Normalization #####
  
  echo "Normalizing to -1dB..."
  sox $DENOISED_AUDIO $NORMALIZED_AUDIO gain -n -1
  
  ##### Step 3: Concatenate with PRE_AUDIO and POST_AUDIO #####
  
  echo "Concatenating with $PRE_AUDIO and $POST_AUDIO..."
  sox $PRE_AUDIO $NORMALIZED_AUDIO $POST_AUDIO "$OUTPUT"
  
  echo "Done. File saved as $OUTPUT."
  
  ##### Step 4: Cleaning up #####
  
  echo "Cleaning up temporary files..."
  echo ""

done

rm -r $TEMP_DIR
echo "All done."


