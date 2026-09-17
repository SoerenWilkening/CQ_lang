#!/bin/bash
# ab.sh <file.c>  — run the same source through ORACLE (main build) and SUBJECT (worktree)
set -uo pipefail
L=/usr/local/opt/llvm@19/bin
O=/Users/sorenwilkening/Desktop/Projects/CQ_lang
W=/Users/sorenwilkening/Desktop/Projects/cq-wt-zujr
SC=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/f7470aeb-8222-4499-94df-fe0b1a412365/scratchpad/zujr
IN="$1"; B=$(basename "$IN" .c)
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$IN" -o "$SC/$B.ab.ll" 2>/dev/null || { echo "$B STAGE1-FAIL"; exit 2; }
for tag in ORACLE SUBJECT; do
  [[ $tag == ORACLE ]] && P="$O/build/ir-pass/libCQPass.so" || P="$W/build/ir-pass/libCQPass.so"
  E=$(CQ_CTRL_DBG=1 "$L/opt" -load-pass-plugin "$P" -passes=cq-lowering -S "$SC/$B.ab.ll" -o "$SC/$B.$tag.ll" 2>&1); X=$?
  D=$(echo "$E" | grep -E "^(error|warning)" | head -1)
  A=$(echo "$E" | grep "decline \[" | tail -1)
  printf "%-10s %-8s exit=%d %s\n" "$B" "$tag" "$X" "${D:-ACCEPT}"
  [[ -n "$A" ]] && echo "            $A"
done
