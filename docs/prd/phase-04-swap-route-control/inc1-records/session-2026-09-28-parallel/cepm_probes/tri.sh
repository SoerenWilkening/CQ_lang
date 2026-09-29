#!/bin/bash
# tri.sh member... : twincmp over the named members on three binaries — the frozen ORACLE,
# the round-1b subject ($S/cepm/cq-opt.subj2) and the round-2 subject ($S/cepm/cq-opt.subj3).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
D="$(cd "$(dirname "$0")" && pwd)"
for b in ora "$S/cepm/cq-opt.subj2" "$S/cepm/cq-opt.subj3"; do
  bash "$D/twincmp.sh" "$b" "$@" 2>&1 | cut -c1-220
done
