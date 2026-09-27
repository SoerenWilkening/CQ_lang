#!/bin/bash
cd "$(dirname "$0")"
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
for b in "$@"; do
  for t in m12 main_c113 new3; do
    out=$(CQ_DEADARG_DBG=1 "$S/frozen/cq-opt.$t" -passes=cq-lowering -S "$b.s1.ll" -o "$b.$t.s2.ll" 2>&1); rc=$?
    d=$(printf '%s\n' "$out" | grep -c CQ_DEADARG_DBG)
    e=$(printf '%s\n' "$out" | grep -o 'error: .*' | head -1 | sed 's/error: <unknown>:0:0: //' | cut -c1-100)
    cl=$(grep -o '@__cq_q_h_[0-9]*(' "$b.$t.s2.ll" 2>/dev/null | head -1)
    printf '%-4s %-10s rc=%s drops=%s clone=%-14s %s\n' "$b" "$t" "$rc" "$d" "$cl" "$e"
  done
done
