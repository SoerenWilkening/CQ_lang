#!/bin/bash
# Run ONE mutant of the Track A injection matrix: apply, rebuild BOTH targets at
# -j2, run `lit --filter railbank`, report CAUGHT/MISSED, ALWAYS revert.
# $1 = name  $2 = file  $3 = old  $4 = new     (pattern must occur EXACTLY once)
set -uo pipefail
cd /Users/sorenwilkening/Desktop/CQ_A
mkdir -p /tmp/ta
cp ir-pass/src/QramLowering.cpp /tmp/ta/Q.keep
cp ir-pass/src/RailBankPromote.cpp /tmp/ta/P.keep
revert() { cp /tmp/ta/Q.keep ir-pass/src/QramLowering.cpp; cp /tmp/ta/P.keep ir-pass/src/RailBankPromote.cpp; }
trap revert EXIT INT TERM HUP
python3 - "$2" "$3" "$4" <<'PY' || { echo "$1|MUTATION-HOLE(pattern not unique)"; exit 1; }
import sys
p,o,n=sys.argv[1],sys.argv[2],sys.argv[3]
s=open(p).read()
if s.count(o)!=1: sys.exit(3)
open(p,"w").write(s.replace(o,n))
PY
if ! cmake --build build -j2 > /tmp/ta/mut.build 2>&1; then
  echo "$1|BUILDFAIL|$(grep -m1 error: /tmp/ta/mut.build | cut -c1-100)"; exit 0; fi
out=$(cd build && lit ir-pass/test --filter railbank 2>&1)
fails=$(printf '%s\n' "$out" | grep -c '^FAIL:')
names=$(printf '%s\n' "$out" | grep '^FAIL:' | sed 's/^FAIL: CQ IR-pass :: //;s/ (.*//' | tr '\n' ' ')
if [ "$fails" -gt 0 ]; then echo "$1|CAUGHT($fails)|$names"; else echo "$1|**MISSED**"; fi
