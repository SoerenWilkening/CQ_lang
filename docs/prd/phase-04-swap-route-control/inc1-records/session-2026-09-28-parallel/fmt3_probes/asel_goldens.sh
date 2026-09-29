#!/bin/bash
# fmt3 Phase 2 — the angle-select Ry family under the COMMITTED nomerge include/CQ.h.
#   * each if/else slice: new trace + STRICT 2b + warning count (its golden is regenerated
#     from this output ONLY if --write is given);
#   * each _ternary slice: its trace must be BYTE-IDENTICAL to the PRE-fmt3 golden of the
#     matching if/else slice (read from git HEAD~ via `git show`, i.e. the file as committed
#     before this track), with the same warning count.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
OPT=$W/build/ir-pass/cq-opt
O=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/asel2
mkdir -p "$O"
WRITE=${1:-}
run() {  # $1 = slice basename; prints the trace path
  local n=$1
  "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$W/tests/e2e/$n.c" -o "$O/$n.s1.ll" || return 9
  "$OPT" -passes=cq-lowering -S "$O/$n.s1.ll" -o "$O/$n.s2.ll" 2> "$O/$n.err" || { echo "  $n STAGE2 DECLINE: $(grep -m1 error "$O/$n.err")"; return 9; }
  echo "  $n: warnings=$(grep -c warning "$O/$n.err") 2b=[$(python3 "$W/tools/free_pairing_check.py" "$O/$n.s2.ll" | tail -1)]"
  "$L/clang" "$O/$n.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$O/$n.exe" 2>/dev/null || return 9
  "$O/$n.exe" > "$O/$n.trace"
}
for base in slice_control_angle_select_ry slice_control_angle_select_ry_ne slice_control_angle_select_ry_derived_base; do
  echo "== $base"
  git -C "$W" show "9a230646:tests/e2e/$base.expected.log" > "$O/$base.OLD.expected.log"
  run "$base"
  if cmp -s "$O/$base.trace" "$W/tests/e2e/$base.expected.log"; then echo "  if/else trace == committed golden"; else echo "  if/else trace DIFFERS from committed golden:"; diff "$W/tests/e2e/$base.expected.log" "$O/$base.trace" | sed 's/^/    /'; fi
  if [ "$WRITE" = "--write" ]; then cp -f "$O/$base.trace" "$W/tests/e2e/$base.expected.log"; echo "  WROTE golden"; fi
  run "${base}_ternary"
  if cmp -s "$O/${base}_ternary.trace" "$O/$base.OLD.expected.log"; then echo "  ternary trace == PRE-fmt3 if/else golden (byte-identical)"; else echo "  ternary trace DIFFERS from the pre-fmt3 golden:"; diff "$O/$base.OLD.expected.log" "$O/${base}_ternary.trace" | sed 's/^/    /'; fi
  if [ "$WRITE" = "--write" ]; then cp -f "$O/$base.OLD.expected.log" "$W/tests/e2e/${base}_ternary.expected.log"; echo "  WROTE ternary golden (= pre-fmt3 golden)"; fi
done
