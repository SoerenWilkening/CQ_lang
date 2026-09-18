#!/bin/bash
# ab.sh <probe.c> — run one C probe through stages 1,2,2b,3,4 on MAIN and COMPOSED.
# Tags:  MAIN     = /Users/.../CQ_lang/build/ir-pass/cq-opt            (main 78b6bf64)
#        COMPOSED = /private/tmp/claude-501/cq-composed/build/…/cq-opt (main + tu9q P0+P3)
LLVM=/usr/local/opt/llvm@19/bin
R=/Users/sorenwilkening/Desktop/Projects/CQ_lang
S=/private/tmp/claude-501/adj4jok
mkdir -p "$S"
bin_for() { [ "$1" = MAIN ] && echo "$R/build/ir-pass/cq-opt" || echo /private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt; }

C="$1"; n=$(basename "$C" .c)
for TAG in MAIN COMPOSED; do
  d="$S/$TAG"; mkdir -p "$d"
  "$LLVM/clang" -I$R/include -include CQ.h -O1 -emit-llvm -S "$C" -o "$d/$n.s1.ll" 2>"$d/$n.cc.err" \
    || { echo "$n|$TAG|CLANGFAIL"; continue; }
  "$(bin_for $TAG)" -passes=cq-lowering -S "$d/$n.s1.ll" -o "$d/$n.s2.ll" 2>"$d/$n.opt.err"
  rc=$?                                   # captured IMMEDIATELY, no pipeline (PROTOCOL 1)
  if [ $rc -ne 0 ]; then
    echo "$n|$TAG|DECLINE($rc)|$(grep -m1 'error:' "$d/$n.opt.err" | sed 's/.*: cq /cq /' | cut -c1-62)"
    continue
  fi
  warn=$(grep -c 'warning:' "$d/$n.opt.err")
  python3 $R/tools/free_pairing_check.py "$d/$n.s2.ll" > "$d/$n.2b.txt" 2>&1; b2=$?
  cen=$(grep -oE '[0-9]+ template rail mint\(s\) of which [0-9]+ left dirty' "$d/$n.2b.txt" | head -1)
  vio=$(grep -oE '[0-9]+ verified, [0-9]+ violation\(s\), [0-9]+ unproven' "$d/$n.2b.txt" | head -1)
  "$LLVM/clang" "$d/$n.s2.ll" $R/build/runtime/libcq_templates.a $R/build/runtime/libcq_runtime.a \
      -o "$d/$n.exe" 2>/dev/null && "$d/$n.exe" > "$d/$n.trace" 2>&1
  echo "$n|$TAG|ACCEPT|ll=$(grep -c . "$d/$n.s2.ll") tr=$(wc -l < "$d/$n.trace" 2>/dev/null|tr -d ' ') warn=$warn 2b=$b2 [$vio] [$cen]"
done
