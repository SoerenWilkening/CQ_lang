#!/bin/bash
# eq.sh NAME... — trace_twin_equiv on out/NAME.S.trace vs out/NAME_T.S.trace (full verdict line)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
HERE=$(cd "$(dirname "$0")" && pwd)
for n in "$@"; do
  [ -f $HERE/out/$n.S.trace ] && [ -f $HERE/out/${n}_T.S.trace ] || { echo "$n: n/a"; continue; }
  echo "$n: $(python3 $W/tools/trace_twin_equiv.py --quiet-controls $HERE/out/$n.S.trace $HERE/out/${n}_T.S.trace | tail -1 | sed 's/^[^:]*: //')"
done
