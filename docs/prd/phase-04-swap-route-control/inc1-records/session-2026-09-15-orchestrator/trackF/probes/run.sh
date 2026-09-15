#!/bin/bash
# run.sh <BUILD_DIR> <file.ll>...   -> "<name> | ACCEPT|DECLINE exit=N | <diagnostic>"
B="$1"; shift
for f in "$@"; do
  out=$("$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o /dev/null 2>&1)
  rc=$?
  msg=$(printf '%s' "$out" | sed -n 's/.*: \(cq [a-z].*\)$/\1/p' | head -1)
  if [ $rc -eq 0 ]; then echo "$(basename "$f") | ACCEPT exit=0 |"
  else echo "$(basename "$f") | DECLINE exit=$rc | $msg"; fi
done
