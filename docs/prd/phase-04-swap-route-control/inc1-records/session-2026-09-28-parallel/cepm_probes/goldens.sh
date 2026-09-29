#!/bin/bash
# goldens.sh OPT [check] : (re)generate the four bd cepm / bd 3zr4 e2e goldens with OPT
# (default: write them into tests/e2e; `check`: write to a temp dir and diff against the
# committed ones), then compare each subject golden with its twin's.
set -uo pipefail
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
D="$(cd "$(dirname "$0")" && pwd)"
E="$W/tests/e2e"
OPT=${1:-$W/build/ir-pass/cq-opt}
MODE=${2:-write}
OUTD="$E"; [ "$MODE" = check ] && OUTD=$(mktemp -d)
R="$E/spec_reading_g_lib.c $E/spec_reading_f2_lib.c $E/spec_reading_f3_lib.c"
H="$E/spec_reading_h_lib.c"
X="$E/spec_round2_lib.c"
gen() { bash "$D/mkgolden.sh" "$OPT" "$E/$1.c" "$2" "$OUTD/$1.expected.log" || echo "FAILED $1"; }
gen slice_spec_predicted_classical_branch "$H $R"
gen slice_spec_predicted_classical_branch_twin "$R"
gen slice_spec_predicted_classical_round2 "$H $R $X"
gen slice_spec_predicted_classical_round2_twin "$R $X"
for b in branch round2; do
  if cmp -s "$OUTD/slice_spec_predicted_classical_$b.expected.log" "$OUTD/slice_spec_predicted_classical_${b}_twin.expected.log"; then
    echo "$b: TWIN-IDENTICAL ($(wc -l < "$OUTD/slice_spec_predicted_classical_$b.expected.log" | tr -d ' ') lines)"
  else
    echo "$b: DIFFERS FROM TWIN"
  fi
done
if [ "$MODE" = check ]; then
  for f in "$OUTD"/*.expected.log; do
    cmp -s "$f" "$E/$(basename "$f")" && echo "same as committed: $(basename "$f")" || echo "DIFFERS from committed: $(basename "$f")"
  done
  rm -rf "$OUTD"
fi
