#!/bin/bash
# D2 (+ D2T) as 2-TU, re-spell D2's @h with the branch-only read, lower on three
# binaries, then twin-compare R6r/R6T and D2r/D2T traces on m12.
cd "$(dirname "$0")"
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r2B_9bhg/probes/src
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
for m in D2 D2T; do
  cp -f "$R/$m.c" "$m.c"; cp -f "$R/lib.c" "$m.lib.c"
  "$L/clang" -O1 -emit-llvm -S -Wno-everything "$m.lib.c" -o "$m.lib.ll"
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S -Wno-everything "$m.c" -o "$m.caller.ll"
  "$L/llvm-link" -S "$m.caller.ll" "$m.lib.ll" -o "$m.s1.ll"
done
python3 - <<'EOF'
s = open("D2.s1.ll").read()
import re
m = re.search(r"(define [^\n]*@h\(i32 noundef %0, i32 noundef %1\)[^\n]*\{\n)(  %3 = add nsw i32 %1, 1)", s)
assert m
read_i = ("  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)\n"
          "  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join\nvsfp.arm:\n  br label %vsfp.join\nvsfp.join:\n")
open("D2r.s1.ll", "w").write(s[:m.end(1)] + read_i + s[m.start(2):])
EOF
for m in D2 D2r D2T; do
  for t in m12 main_c113 final; do
    CQ_DEADARG_DBG=1 "$S/frozen/cq-opt.$t" -passes=cq-lowering -S "$m.s1.ll" -o "$m.$t.s2.ll" 2> "$m.$t.err"
    rc=$?
    printf '%-5s %-10s rc=%s drops=%s %s\n' "$m" "$t" "$rc" "$(grep -c CQ_DEADARG "$m.$t.err")" "$(grep -o 'error: .*' "$m.$t.err" | head -1 | cut -c1-110)"
  done
done
trace() {
  "$L/clang" -Wno-everything "$1" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$1.exe"
  for a in "5 7" "2 9" "1 1" "4 4"; do
    # shellcheck disable=SC2086
    "./$1.exe" $a; echo "exit=$?"
  done
}
for pair in "R6r R6T" "D2r D2T"; do
  set -- $pair
  trace "$1.m12.s2.ll" > "$1.trace"; trace "$2.m12.s2.ll" > "$2.trace"
  if cmp -s "$1.trace" "$2.trace"; then echo "$1 vs $2 (m12): TRACE-IDENT ($(wc -l < "$1.trace") lines)"; else echo "$1 vs $2: DIFF"; diff "$1.trace" "$2.trace" | head -20; fi
  for m in "$1" "$2"; do printf '  2b %s: ' "$m"; python3 "$W/tools/free_pairing_check.py" "$m.m12.s2.ll" | tail -1 | sed 's/.*file(s), //'; done
done
