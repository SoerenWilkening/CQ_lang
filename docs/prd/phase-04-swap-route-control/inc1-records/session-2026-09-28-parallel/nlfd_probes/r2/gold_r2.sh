#!/bin/bash
# gold_r2.sh [--write] : the three round-2 e2e slices (r1B F-r1B-5 / owner ruling 2026-09-29) and
# their twins, with the harness recipe (tools/mkgold.sh), on the SUBJECT and on the frozen `main`
# oracles 9a230646 and ba4fdad4; then tools/trace_twin_equiv.py over each SUBJECT pair. With
# --write the SUBJECT traces become the goldens.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
H=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/nlfd_probes/tools
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
O=$SP/nlfd/gold2; mkdir -p "$O"
E=$W/tests/e2e
for mt in rhk5_window clone_partial_drop clone_live_arg; do
  for tag in S OA OB; do
    case $tag in S) b=$W/build/ir-pass/cq-opt;; OA) b=$SP/frozen/cq-opt.main_9a230646;; OB) b=$SP/frozen/cq-opt.main_ba4fdad4;; esac
    printf '%-22s %-2s slice: ' "$mt" "$tag"; "$H/mkgold.sh" "$b" "$E/slice_spec_musttail_$mt.c" "$E/spec_musttail_${mt}_lib.c" "$O/$mt.$tag.trace"
    printf '%-22s %-2s twin : ' "$mt" "$tag"; "$H/mkgold.sh" "$b" "$E/slice_spec_musttail_${mt}_twin.c" - "$O/${mt}_twin.$tag.trace"
  done
  python3 "$W/tools/trace_twin_equiv.py" --quiet-controls "$O/$mt.S.trace" "$O/${mt}_twin.S.trace" | tail -1
  if [ "${1:-}" = "--write" ]; then
    cp -f "$O/$mt.S.trace" "$E/slice_spec_musttail_$mt.expected.log"
    cp -f "$O/${mt}_twin.S.trace" "$E/slice_spec_musttail_${mt}_twin.expected.log"
  fi
done
