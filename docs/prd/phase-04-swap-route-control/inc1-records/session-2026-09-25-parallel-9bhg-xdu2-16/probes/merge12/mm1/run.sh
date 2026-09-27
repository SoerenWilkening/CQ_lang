#!/bin/bash
# mm1 (r6_vsfp) vs a hand-inlined twin mm1T (h2(p, k) -> k + 1), both 2-TU with mm1's lib.
cd "$(dirname "$0")"
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r6_vsfp/probes/csrc
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
cp -f "$R/mm1.c" mm1.c; cp -f "$R/mm1.lib.c" mm1.lib.c; cp -f "$R/mm1.lib.c" mm1T.lib.c
python3 - <<'EOF'
s = open("mm1.c").read()
old = "__attribute__((musttail)) return h2(p, k);"
assert s.count(old) == 1
open("mm1T.c", "w").write(s.replace(old, "return k + 1;"))
EOF
for m in mm1 mm1T; do
  "$L/clang" -O1 -emit-llvm -S -Wno-everything "$m.lib.c" -o "$m.lib.ll"
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S -Wno-everything "$m.c" -o "$m.caller.ll"
  "$L/llvm-link" -S "$m.caller.ll" "$m.lib.ll" -o "$m.s1.ll"
  for t in m12 main_c113; do
    CQ_DEADARG_DBG=1 "$S/frozen/cq-opt.$t" -passes=cq-lowering -S "$m.s1.ll" -o "$m.$t.s2.ll" 2> "$m.$t.err"
    echo "$m $t rc=$? drops=$(grep -c CQ_DEADARG "$m.$t.err") $(grep -o 'error: .*' "$m.$t.err" | head -1 | cut -c1-100) warn=$(grep -c 'warning:' "$m.$t.err")"
  done
done
for m in mm1 mm1T; do
  "$L/clang" -Wno-everything "$m.m12.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$m.exe" 2>/dev/null
  : > "$m.trace"
  for a in "5 7" "2 9" "10 3" "3 3"; do
    # shellcheck disable=SC2086
    "./$m.exe" $a >> "$m.trace"; echo "exit=$?" >> "$m.trace"
  done
  printf '2b %s: ' "$m"; python3 "$W/tools/free_pairing_check.py" "$m.m12.s2.ll" | tail -1 | sed 's/.*file(s), //'
done
cmp -s mm1.trace mm1T.trace && echo "mm1 vs mm1T: TRACE-IDENT ($(wc -l < mm1.trace) lines)" || { echo "mm1 vs mm1T: DIFF"; diff mm1.trace mm1T.trace; }
