#!/bin/bash
# gen_all_goldens.sh : the six rhk5 e2e goldens. Subjects on THIS build; every twin on
# THIS build AND on the ORACLE (a twin must not move — it contains no clone call).
# Writes into tests/e2e/ only when WRITE=1; otherwise prints diffs against the files.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
G="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/tools/gen_golden.sh"
S=$W/build/ir-pass/cq-opt
O=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5/bin/cq-opt.oracle
E=$W/tests/e2e
OUT=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/results/goldens
mkdir -p "$OUT"
while read -r name lib; do
  [ -z "$name" ] && continue
  libp=""; [ "$lib" != "-" ] && libp="$E/$lib"
  bash "$G" "$S" "$E/$name.c" $libp > "$OUT/$name.subject.log" 2> "$OUT/$name.subject.err"
  echo "rc=$? $name (subject) $(grep free_pairing "$OUT/$name.subject.err" | sed 's/.*mint(s) of which/left/') warn=$(grep -c warning: "$OUT/$name.subject.err")"
  bash "$G" "$O" "$E/$name.c" $libp > "$OUT/$name.oracle.log" 2> "$OUT/$name.oracle.err"
  echo "rc=$? $name (oracle)  $(grep free_pairing "$OUT/$name.oracle.err" | sed 's/.*mint(s) of which/left/') warn=$(grep -c warning: "$OUT/$name.oracle.err")"
  if [ "${WRITE:-0}" = 1 ]; then cp -f "$OUT/$name.subject.log" "$E/$name.expected.log"; fi
done <<'EOF'
slice_spec_clone_read_in_window spec_dropped_arg_lib.c
slice_spec_clone_read_in_window_twin -
slice_spec_clone_consumes_chain_rail spec_dropped_arg_lib.c
slice_spec_clone_consumes_chain_rail_twin -
slice_spec_clone_read_nested spec_clone_read_nested_lib.c
slice_spec_clone_read_nested_twin -
EOF
for p in slice_spec_clone_read_in_window slice_spec_clone_consumes_chain_rail slice_spec_clone_read_nested; do
  echo "== $p twin: subject-build vs oracle-build twin trace: $(cmp -s "$OUT/${p}_twin.subject.log" "$OUT/${p}_twin.oracle.log" && echo IDENTICAL || echo DIFFERENT)"
  python3 "$W/tools/trace_twin_equiv.py" --quiet-controls "$OUT/$p.subject.log" "$OUT/${p}_twin.subject.log" | tail -1
  python3 "$W/tools/trace_twin_equiv.py" --quiet-controls "$OUT/$p.oracle.log" "$OUT/${p}_twin.oracle.log" | tail -1 | sed 's/^/  ORACLE: /'
done
