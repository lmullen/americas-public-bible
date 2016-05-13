#!/usr/bin/env bash

shopt -s globstar # requires Bash v4+
wc -w $1/**/*.txt | sed -e "s/\s\+/,/g" -e "s/^,//" -e "/total/d"


