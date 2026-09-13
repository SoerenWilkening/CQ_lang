#!/bin/zsh
# Track R probe runner — ORACLE ONLY, read-only.  Run from the REPO ROOT:
#     docs/prd/.../trackR/probes/run.sh            # every probe
#     docs/prd/.../trackR/probes/run.sh r_R1*.ll   # a subset
# Each row: <probe> | exit | ACCEPT/DECLINE | trace lines + stage-2b, or the
# diagnostic verbatim.  With CQDBG=1 each DECLINE also prints its CQ_CTRL_DBG
# anchor.  ORACLE sha256 is checked first and the script STOPS if it moved.
set -u
LLVM=/usr/local/opt/llvm@19/bin
R=$(pwd)
P=$(cd $(dirname $0) && pwd)
W=${CQW:-$(mktemp -d)}
ORACLE=fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661
H=$(shasum -a 256 "$R/build/ir-pass/cq-opt" | cut -d' ' -f1)
[[ "$H" == "$ORACLE" ]] || { echo "STOP: build/ir-pass/cq-opt is $H, not the session ORACLE $ORACLE"; exit 9; }
if [[ $# -gt 0 ]]; then FILES=($@); else FILES=($(ls $P/b_* $P/v_* $P/r_* $P/w_* 2>/dev/null | grep -E "\.(c|ll)$")); fi
for f in $FILES; do
  [[ -e $f ]] || f=$P/$f
  B=$(basename $f); N=${B%.*}
  if [[ "$f" == *.c ]]; then
    "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$W/$N.s1.ll" 2>/dev/null || { echo "$N | CLANG-FAIL"; continue; }
    S1="$W/$N.s1.ll"
  else
    S1="$f"
  fi
  O=$("$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$S1" -o "$W/$N.s2.ll" 2>&1); E=$?
  if [[ $E -eq 0 ]]; then
    FP=$(python3 tools/free_pairing_check.py "$W/$N.s2.ll" 2>&1 | tail -1)
    if "$LLVM/clang" "$W/$N.s2.ll" build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o "$W/$N.a" 2>/dev/null; then TR=$("$W/$N.a" | wc -l | tr -d ' '); else TR=LINKFAIL; fi
    echo "$N | exit=0 | ACCEPT | $TR trace lines | 2b: $FP"
  else
    echo "$N | exit=$E | DECLINE | $(echo "$O" | grep -m1 'error:' | sed 's/^.*: cq /cq /')"
    [[ "${CQDBG:-}" == 1 ]] && CQ_CTRL_DBG=1 "$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$S1" -o /dev/null 2>&1 | grep -m1 CQ_CTRL_DBG | sed 's/^/    anchor: /'
  fi
done
echo "# work dir: $W"
