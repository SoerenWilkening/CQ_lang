#!/bin/bash
# Replicates tools/loop_twin_matrix.py's per-side stages for ONE bespoke pair, on
# the MERGED binary. Hardened against the three lies Track S measured on its own
# harness (stale trace, 0-byte .c, empty count reported as a result).
set -u
L=/usr/local/opt/llvm@19/bin
R=/Users/sorenwilkening/Desktop/CQ_merge
B=$R/build
cell="$1"; rolled="$2"; unrolled="$3"
side() { # $1 src  $2 workdir -> echoes "<disp>|<2b>|<lines>|<tracefile>"
  local src="$1" w="$2"
  [ -s "$src" ] || { echo "VACUOUS-SRC|-|-|"; return; }
  rm -f "$w/s1.ll" "$w/s2.ll" "$w/a" "$w/trace"
  "$L/clang" -I$R/include -include CQ.h -O1 -emit-llvm -S "$src" -o "$w/s1.ll" 2>/dev/null || { echo "CLANGERR|-|-|"; return; }
  [ -s "$w/s1.ll" ] || { echo "VACUOUS-S1|-|-|"; return; }
  "$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering -S "$w/s1.ll" -o "$w/s2.ll" 2>"$w/err"
  if [ $? -ne 0 ]; then echo "DECLINE|-|-|$(grep -o 'cq [a-z].*' "$w/err" | head -1)"; return; fi
  local twob; twob=$(python3 $R/tools/free_pairing_check.py "$w/s2.ll" 2>&1 | tail -1)
  "$L/clang" "$w/s2.ll" "$B/runtime/libcq_templates.a" "$B/runtime/libcq_runtime.a" -o "$w/a" 2>/dev/null || { echo "LINKFAIL|$twob|-|"; return; }
  "$w/a" > "$w/trace" 2>/dev/null
  [ -f "$w/trace" ] || { echo "NOTRACE|$twob|-|"; return; }
  echo "ACCEPT|$twob|$(wc -l < "$w/trace" | tr -d ' ')|$w/trace"
}
w1=$(mktemp -d); w2=$(mktemp -d)
r=$(side "$rolled" "$w1"); u=$(side "$unrolled" "$w2")
rd=${r%%|*}; ud=${u%%|*}
rl=$(echo "$r" | cut -d'|' -f3); ul=$(echo "$u" | cut -d'|' -f3)
rt=$(echo "$r" | cut -d'|' -f4-); ut=$(echo "$u" | cut -d'|' -f4-)
if [ "$rd" = "DECLINE" ] && [ "$ud" = "DECLINE" ]; then v="DECLINE-BOTH"
elif [ "$rd" != "$ud" ]; then v="DISPOSITION-MISMATCH"
elif [ "$rd" = "ACCEPT" ]; then
  if cmp -s "$w1/trace" "$w2/trace"; then v="ACCEPT-IDENTICAL"; else v="TRACE-DIVERGENCE"; fi
else v="OTHER($rd/$ud)"; fi
echo "cell $cell : $v"
echo "   rolled   : $r"
echo "   unrolled : $u"
if [ "$v" = "TRACE-DIVERGENCE" ]; then
  echo "   first differing line:"; diff "$w1/trace" "$w2/trace" | head -6 | sed 's/^/     /'
  echo "   diff sha256: $(diff -u "$w1/trace" "$w2/trace" | shasum -a 256 | cut -c1-32)"
fi
rm -rf "$w1" "$w2"
