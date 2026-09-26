#!/bin/bash
# e2e_rg.sh BIN N [MODE] — run the e2e-spec-scrub-dangling-key harness N times
# with cq-opt=BIN under CQ_OPT_DEBUG_ALLOC=MODE (default lifo); tally rc.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
L=/usr/local/opt/llvm@19/bin
BIN=$1; N=${2:-10}; MODE=${3:-lifo}
pass=0; fail=0
for i in $(seq 1 "$N"); do
  CQ_OPT_DEBUG_ALLOC=$MODE bash "$W/tests/e2e/run_slice_multi.sh" "$L/clang" "$BIN" "$L/llvm-link" \
    "$W/build/ir-pass/libCQPass.so" "$W/include" \
    "$W/tests/e2e/spec_scrub_dangling_key_caller.c" "$W/tests/e2e/spec_scrub_dangling_key_lib.c" \
    "$W/build/runtime/libcq_runtime.a" "$W/build/runtime/libcq_templates.a" \
    "$W/tests/e2e/spec_scrub_dangling_key_caller.expected.log" > /dev/null 2>&1
  if [ $? -eq 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
done
echo "e2e-spec-scrub-dangling-key BIN=$(basename "$BIN") mode=$MODE runs=$N pass=$pass fail=$fail"
