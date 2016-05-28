#!/usr/bin/env bash

rsync -azP --exclude '*.csv' --log-file=logs/rsync.log /media/lmullen/data/chronicling-america/ocr vrc:/data/chronicling-america
