#!/bin/bash
# the e2e-spec-scrub-dangling-key slice, with OPT replaced by a policy wrapper
# (rb8_interpose), N runs each; prints PASS/FAIL counts. Positive control:
# ORA.lifo must FAIL, ORA.nofree must PASS (golden == no-reuse reference).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
N=${N:-3}
for opt in "$@"; do
  p=0; f=0
  for i in $(seq 1 $N); do
    if env -u CQ_OPT_DEBUG_ALLOC bash $W/tests/e2e/run_slice_multi.sh /usr/local/opt/llvm@19/bin/clang "$opt" /usr/local/opt/llvm@19/bin/llvm-link $W/build/ir-pass/libCQPass.so $W/include $W/tests/e2e/spec_scrub_dangling_key_caller.c $W/tests/e2e/spec_scrub_dangling_key_lib.c $W/build/runtime/libcq_runtime.a $W/build/runtime/libcq_templates.a $W/tests/e2e/spec_scrub_dangling_key_caller.expected.log > /dev/null 2>&1; then p=$((p+1)); else f=$((f+1)); fi
  done
  echo "$(basename $opt): PASS $p FAIL $f of $N"
done
