#!/bin/bash
# redgreen_r2.sh — round 2's changed/new fixtures through their OWN RUN lines on five binaries:
# the merged pre-fix build (M), round 1 (R1 = 93c65d0d), the two frozen oracles and the SUBJECT.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
RG=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/nlfd_probes/tools/redgreen.sh
# lit.cfg.py refuses a debugalloc OLDER than the cq-opt under test (bd m91g): hand it a FRESH copy
# (new mtime) so a binary copied after the last build is not refused. No fixture here uses it.
D=$SP/nlfd/bin/cq-opt-debugalloc.fresh
cp -f "$W/build/ir-pass/cq-opt-debugalloc" "$D"
F='unc_twin|musttail_forward_preallocated|clone_demoted|unread_scalar_inner_inst|unread_scalar_outer_nn|unread_scalar_classical_inst|musttail_inner_slot'
for b in "$SP/nlfd/bin/cq-opt.M" "$SP/nlfd/bin/cq-opt.R1" "$SP/frozen/cq-opt.main_9a230646" \
         "$SP/frozen/cq-opt.main_ba4fdad4" "$W/build/ir-pass/cq-opt"; do
  echo "=== $(basename "$b") $(shasum -a 256 "$b" | cut -c1-16)"
  "$RG" "$b" "$D" "$F" | grep -v "^Total\|Failed Tests"
done
