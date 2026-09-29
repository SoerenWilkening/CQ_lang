#!/bin/bash
# rgm.sh fixture.ll... : redgreen.py on the frozen MAIN ba4fdad4 (rhk5 + z0re), cepm ALONE (round 2,
# $S/cepm/cq-opt.subj3) and the MERGED binary ($S/cepm/cq-opt.merged).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
D="$(cd "$(dirname "$0")" && pwd)"
for b in "$S/frozen/cq-opt.main_ba4fdad4" "$S/cepm/cq-opt.subj3" "$S/cepm/cq-opt.merged"; do
  echo "== $(basename "$b")"
  python3 "$D/redgreen.py" "$b" "$@"
done
