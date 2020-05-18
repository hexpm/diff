#!/bin/sh

file=$1
from_line=$2
lines_to_read=$3
direction=$4

if [ $direction = "down" ]
then
  TAIL="$(tail -n+$from_line $file)"
  TMP_STATUS=$?
  printf '%s' "$TAIL" | head -n$lines_to_read
  FINAL_STATUS=$?
else
  HEAD="$(head -n$from_line $file)"
  TMP_STATUS=$?
  printf '%s' "$HEAD" | tail -n$lines_to_read
  FINAL_STATUS=$?
fi

[ $TMP_STATUS -gt 0 ] && exit $TMP_STATUS || exit $FINAL_STATUS