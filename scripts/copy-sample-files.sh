#!/bin/bash

mkdir -p ~/dev/public-bible/data/sample
cd /Volumes/RESEARCH/chronicling-america/ocr
rsync -av --files-from=/Users/lmullen/dev/public-bible/temp/sample-files.txt . \
  ~/dev/public-bible/data/sample

