#!/bin/bash
set -uo pipefail
L=/usr/local/opt/llvm@19/bin
O=/Users/sorenwilkening/Desktop/Projects/CQ_lang
W=/Users/sorenwilkening/Desktop/Projects/cq-wt-zujr2
SC=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/f7470aeb-8222-4499-94df-fe0b1a412365/scratchpad/zujr
IN="$1"; B=$(basename "$IN" .c)
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$IN" -o "$SC/$B.ab.ll" 2>/dev/null || { echo "$B STAGE1-FAIL"; exit 2; }
for tag in ORACLE SUBJECT; do
  [[ $tag == ORACLE ]] && P="$O/build/ir-pass/libCQPass.so" || P="$W/build/ir-pass/libCQPass.so"
  E=$("$L/opt" -load-pass-plugin "$P" -passes=cq-lowering -S "$SC/$B.ab.ll" -o "$SC/$B.$tag.ll" 2>&1); X=$?
  if [[ $X -eq 0 ]]; then
    "$L/clang" "$SC/$B.$tag.ll" "/Users/sorenwilkening/Desktop/Projects/cq-wt-zujr/build/runtime/libcq_templates.a" "/Users/sorenwilkening/Desktop/Projects/cq-wt-zujr/build/runtime/libcq_runtime.a" -o "$SC/$B.$tag.bin" 2>/dev/null && "$SC/$B.$tag.bin" > "$SC/$B.$tag.trace" 2>&1
    printf "%-26s %-8s exit=0 ACCEPT trace=%s %s\n" "$B" "$tag" "$(wc -l < "$SC/$B.$tag.trace" 2>/dev/null | tr -d ' ')" "$(echo "$E"|grep -c warning) warn"
  else
    printf "%-26s %-8s exit=%d %s\n" "$B" "$tag" $X "$(echo "$E"|grep -E '^error'|sed 's/.*): //'|head -1)"
  fi
done
