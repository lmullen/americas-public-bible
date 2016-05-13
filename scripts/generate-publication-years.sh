#!/usr/bin/env bash

# Create a list of absolute paths for the combinations of publication and year
# in the Chronicling America dataset.

OCRDIR="/Volumes/RESEARCH/chronicling-america/ocr"
find $OCRDIR -mindepth 2 -maxdepth 2 -type d 
