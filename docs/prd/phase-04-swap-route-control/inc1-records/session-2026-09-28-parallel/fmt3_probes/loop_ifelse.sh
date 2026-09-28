#!/bin/bash
# The new C-level accept fmt3 creates: the in-loop if/else of two chained Ry. For the rolled
# slice and its hand-unrolled twin, under the PRE-fmt3 header (orig_inc) and the committed
# nomerge header: verdict, rolledness of stage 1 (a loop back edge survives?), STRICT 2b, trace.
# Writes the goldens only with --write.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3
L=/usr/local/opt/llvm@19/bin
OPT=$W/build/ir-pass/cq-opt
O=$S/loopifelse; mkdir -p "$O"
for inc in orig new; do
  I=$W/include; [ "$inc" = orig ] && I=$S/orig_inc
  for n in slice_control_inplace_ry_loop_ifelse slice_control_inplace_ry_loop_ifelse_unrolled; do
    "$L/clang" -I"$I" -include CQ.h -O1 -emit-llvm -S "$W/tests/e2e/$n.c" -o "$O/$n.$inc.s1.ll"
    backedges=$(grep -c "^.*phi i32.*%[0-9]*, %[0-9]*\ ].*\[" "$O/$n.$inc.s1.ll")
    loops=$(grep -c "llvm.loop\|; Loop:" "$O/$n.$inc.s1.ll")
    if "$OPT" -passes=cq-lowering -S "$O/$n.$inc.s1.ll" -o "$O/$n.$inc.s2.ll" 2> "$O/$n.$inc.err"; then
      "$L/clang" "$O/$n.$inc.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$O/$n.$inc.exe" 2>/dev/null
      "$O/$n.$inc.exe" > "$O/$n.$inc.trace"
      echo "$inc $n: ACCEPT trace=$(wc -l < "$O/$n.$inc.trace" | tr -d ' ') loopmd=$loops s2lines=$(wc -l < "$O/$n.$inc.s2.ll" | tr -d ' ') 2b=[$(python3 "$W/tools/free_pairing_check.py" "$O/$n.$inc.s2.ll" | tail -1)]"
    else
      echo "$inc $n: DECLINE [$(grep -m1 -o 'cq [a-z]* lowering: .*' "$O/$n.$inc.err")] loopmd=$loops"
    fi
  done
done
if cmp -s "$O/slice_control_inplace_ry_loop_ifelse.new.trace" "$O/slice_control_inplace_ry_loop_ifelse_unrolled.new.trace"; then
  echo "new header: ROLLED trace == UNROLLED twin trace (byte-identical)"
else
  echo "new header: ROLLED vs UNROLLED DIFFER:"; diff "$O/slice_control_inplace_ry_loop_ifelse.new.trace" "$O/slice_control_inplace_ry_loop_ifelse_unrolled.new.trace"
fi
grep -c "br i1" "$O/slice_control_inplace_ry_loop_ifelse.new.s1.ll" | sed 's/^/rolled stage-1 br i1 count: /'
if [ "${1:-}" = "--write" ]; then
  cp -f "$O/slice_control_inplace_ry_loop_ifelse.new.trace" "$W/tests/e2e/slice_control_inplace_ry_loop_ifelse.expected.log"
  cp -f "$O/slice_control_inplace_ry_loop_ifelse_unrolled.new.trace" "$W/tests/e2e/slice_control_inplace_ry_loop_ifelse_unrolled.expected.log"
  echo "WROTE both goldens"
fi
# K-independence of the ROLLED lowered IR: K = 3 vs K = 1000 (only the bound constant may differ).
sed 's/i < 3;/i < 1000;/' "$W/tests/e2e/slice_control_inplace_ry_loop_ifelse.c" > "$O/k1000.c"
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$O/k1000.c" -o "$O/k1000.s1.ll"
"$OPT" -passes=cq-lowering -S "$O/k1000.s1.ll" -o "$O/k1000.s2.ll"
echo "K=1000 lowered lines (no comments/metadata): $(grep -v '^;\|^$\|^!\|source_filename' "$O/k1000.s2.ll" | wc -l | tr -d ' ')   K=3: $(grep -v '^;\|^$\|^!\|source_filename' "$O/slice_control_inplace_ry_loop_ifelse.new.s2.ll" | wc -l | tr -d ' ')"
diff <(grep -v '^;\|^$\|^!\|source_filename' "$O/k1000.s2.ll") <(grep -v '^;\|^$\|^!\|source_filename' "$O/slice_control_inplace_ry_loop_ifelse.new.s2.ll")
