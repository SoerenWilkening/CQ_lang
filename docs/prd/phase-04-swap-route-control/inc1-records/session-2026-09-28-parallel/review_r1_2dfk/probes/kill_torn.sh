#!/bin/bash
# r1 2dfk: SIGKILL a cold run_slice.sh at a random point, 40 times, into a private
# cache; any recorded .out must equal the golden (no torn entry), and a following
# warm run must pass.
. /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/r1_env.sh
PR=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/r1_kill_rc; export CQ_RUNCACHE=$PR
G=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/slice_grover_oracle_uncompute.expected.log
torn=0; complete=0; tmpl=0
for i in $(seq 1 40); do
  rm -rf $PR; mkdir -p $PR
  /bin/bash /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/run_slice.sh /usr/local/opt/llvm@19/bin/clang /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/ir-pass/cq-opt /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/ir-pass/libCQPass.so /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/include /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/slice_grover_oracle_uncompute.c /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/runtime/libcq_runtime.a /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/runtime/libcq_templates.a /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/slice_grover_oracle_uncompute.expected.log > /dev/null 2>&1 & pid=$!
  perl -e 'select(undef,undef,undef,rand(1.0))'
  kill -9 $pid 2>/dev/null; wait $pid 2>/dev/null
  sleep 0.3   # let orphaned children (cp/mv/slice) finish or die
  for f in $(find $PR -name '*.out' -o -name '*.ok'); do
    case $f in *.out) if cmp -s $f $G; then complete=$((complete+1)); else torn=$((torn+1)); echo "TORN $f"; fi;; esac
  done
  tmpl=$((tmpl + $(find $PR -name '*.tmp' | wc -l)))
  /bin/bash /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/run_slice.sh /usr/local/opt/llvm@19/bin/clang /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/ir-pass/cq-opt /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/ir-pass/libCQPass.so /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/include /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/slice_grover_oracle_uncompute.c /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/runtime/libcq_runtime.a /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/build/runtime/libcq_templates.a /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_2dfk/tests/e2e/slice_grover_oracle_uncompute.expected.log > /dev/null 2>&1 || { echo "iter $i: warm run after kill FAILED"; }
done
echo "40 kills: complete .out entries=$complete torn=$torn tmp-leftovers=$tmpl"
