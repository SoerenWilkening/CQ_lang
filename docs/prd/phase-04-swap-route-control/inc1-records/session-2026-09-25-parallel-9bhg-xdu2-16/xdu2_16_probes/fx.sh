#!/bin/bash
# fx.sh OPT fixture.ll... — run the pass on each fixture, print rc + first error line.
OPT=$1; shift
for f in "$@"; do
  err=$("$OPT" -passes=cq-lowering -S "$f" -o /dev/null 2>&1 >/dev/null); rc=$?
  echo "$(basename "$f"): rc=$rc $(printf '%s\n' "$err" | grep -m1 'error:' | sed 's/.*error: //')"
done
