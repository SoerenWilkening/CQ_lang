#!/bin/bash
# bash, NOT zsh — zsh does not word-split an unquoted $var, which silently made
# every row of an earlier sweep pass ONE argument and read as a dropped trip.
B=./t5c_classical_break_taken.bin
for n in 0 1 2 3 4; do
  set --
  i=0; while [ $i -lt $n ]; do set -- "$@" x; i=$((i+1)); done
  out=$("$B" "$@")
  echo "argc=$((n+1)) lim=$((n+2)) | lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ') mints=$(printf '%s\n' "$out" | grep -c 'lshr_i32_hl(') uncs=$(printf '%s\n' "$out" | grep -c 'lshr_i32_hl_unc') frees=$(printf '%s\n' "$out" | grep -c cqrt_free) ry=$(printf '%s\n' "$out" | grep -c cqrt_ry)"
done
