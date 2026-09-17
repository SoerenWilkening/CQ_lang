#!/bin/bash
# traces.sh <BUILD> <INC> <file.c ...> — trace only, one block per file
for f in "${@:3}"; do
  echo "===== $(basename "$f" .c) ====="
  /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/15feda8c-ff76-4035-8aec-acbfe9c14725/scratchpad/full.sh "$1" "$2" "$f" 2>/dev/null \
    | sed -n '/^== trace:/,/^TMP=/p' | sed '1d;$d'
done
