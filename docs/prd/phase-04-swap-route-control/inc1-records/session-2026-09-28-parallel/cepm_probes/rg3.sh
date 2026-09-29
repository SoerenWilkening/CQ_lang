#!/bin/bash
# rg3.sh fixture.ll... : redgreen.py on the frozen ORACLE, the round-1b subject and the round-2
# subject (frozen copies in $S/cepm).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
D="$(cd "$(dirname "$0")" && pwd)"
for b in "$S/frozen/cq-opt.main_9a230646" "$S/cepm/cq-opt.subj2" "$S/cepm/cq-opt.subj3"; do
  echo "== $(basename "$b")"
  python3 "$D/redgreen.py" "$b" "$@"
done
