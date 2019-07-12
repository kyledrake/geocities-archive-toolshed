#!/bin/bash
# Finds missing files in SRCS/HREFS from the HTML that are supposed to be in the archive, compiles them into a single list (combined-deduped.log).
# This file will be used by the next script to download missing pieces from the Internet Archive.
# Usage: ARCHIVE_PATH=~/www.geocities.com MISSING_OUT_DIR=~/missing-out ./002-find-missing-files.sh

mkdir -p $MISSING_OUT_DIR
ls -1 $ARCHIVE_PATH | parallel -j6 ruby lib/find-missing-files-parallel.rb $ARCHIVE_PATH {} $MISSING_OUT_DIR/{}-files.log $MISSING_OUT_DIR/{}-checkpoint.log
cat $MISSING_OUT_DIR/*-files.log > $MISSING_OUT_DIR/combined.log
sort -u $MISSING_OUT_DIR/combined.log >$MISSING_OUT_DIR/combined-deduped.log
