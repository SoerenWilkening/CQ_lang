#!/bin/bash
# golden_movers.sh : the two EXISTING e2e goldens this change moves (slice_libm_real_
# {atan2l,coshl}). For each: the ORACLE trace (= the committed golden), the SUBJECT
# trace, the 2b census of both, the unified diff, and entangle.py's findings on both
# (a regeneration must not ADD a finding). Writes results/golden_movers.txt.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
R=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
G=$R/tools/gen_golden.sh
OUT=$R/results/golden_movers
mkdir -p "$OUT"
for n in slice_libm_real_atan2l slice_libm_real_coshl; do
  echo "=================== $n"
  bash "$G" "$S/bin/cq-opt.oracle" "$W/tests/e2e/$n.c" > "$OUT/$n.oracle.trace" 2> "$OUT/$n.oracle.err"
  bash "$G" "$S/bin/cq-opt.subject_v2" "$W/tests/e2e/$n.c" > "$OUT/$n.subject.trace" 2> "$OUT/$n.subject.err"
  echo "oracle trace == committed golden: $(cmp -s "$OUT/$n.oracle.trace" "$W/tests/e2e/$n.expected.log" && echo YES || echo NO)"
  echo "ORACLE  $(grep free_pairing "$OUT/$n.oracle.err")"
  echo "SUBJECT $(grep free_pairing "$OUT/$n.subject.err")"
  echo "--- diff (golden -> subject):"
  diff "$W/tests/e2e/$n.expected.log" "$OUT/$n.subject.trace"
  for side in oracle subject; do
    f=$(python3 "$R/tools/entangle.py" --quiet-controls "$OUT/$n.$side.trace" | grep -c '^    !! ')
    fr=$(python3 "$R/tools/entangle.py" --quiet-controls "$OUT/$n.$side.trace" | grep '^    !! ' | grep -vc UNCLASSIFIED)
    echo "entangle.py $side: $f findings ($fr not 'UNCLASSIFIED')"
  done
done
