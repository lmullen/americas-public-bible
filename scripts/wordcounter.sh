#!/usr/bin/env bash

shopt -s globstar # requires Bash v4+
>&2 echo "Counting words in $1"
wc -w $1/**/*.txt | sed -e "s/\s\+/,/g" -e "s/^,//" -e "/total/d"


