#!/bin/bash
# binmodes.sh FILE N BIN:MODE... — (rc, stdout-hash) distribution per config.
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
cd "$T"
f=$1; N=$2; shift 2
for spec in "$@"; do
  b=${spec%%:*}; m=${spec##*:}
  echo "$spec: $(./dist.sh "./cq-opt.$b" "$m" "$f" "$N")"
done
