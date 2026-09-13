#!/bin/zsh
# Track R impl runner — same pipeline as probes/run.sh, but BUILD is a parameter
# and the ORACLE hash check is replaced by PRINTING the hash it measured.
set -u
LLVM=/usr/local/opt/llvm@19/bin
R=${CQR:-$(pwd)}
BUILD=${BUILD:-$R/build}
P=${CQP:?set CQP to the probes dir}
W=${CQW:-$(mktemp -d)}
mkdir -p "$W"
echo "# binary: $(shasum -a 256 $BUILD/ir-pass/cq-opt | cut -c1-16)   build=$BUILD"
if [[ $# -gt 0 ]]; then FILES=($@); else FILES=($(ls $P/b_* $P/v_* $P/r_* $P/w_* 2>/dev/null | grep -E "\.(c|ll)$")); fi
for f in $FILES; do
  [[ -e $f ]] || f=$P/$f
  B=$(basename $f); N=${B%.*}
  if [[ "$f" == *.c ]]; then
    "$LLVM/clang" -I$R/include -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$W/$N.s1.ll" 2>/dev/null || { echo "$N | CLANG-FAIL"; continue; }
    S1="$W/$N.s1.ll"
  else
    S1="$f"
  fi
  O=$("$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$S1" -o "$W/$N.s2.ll" 2>&1); E=$?
  if [[ $E -eq 0 ]]; then
    FP=$(python3 $R/tools/free_pairing_check.py "$W/$N.s2.ll" 2>&1 | tail -1)
    if "$LLVM/clang" "$W/$N.s2.ll" $BUILD/runtime/libcq_templates.a $BUILD/runtime/libcq_runtime.a -o "$W/$N.a" 2>/dev/null; then TR=$("$W/$N.a" | wc -l | tr -d ' '); else TR=LINKFAIL; fi
    echo "$N | exit=0 | ACCEPT | $TR trace lines | 2b: $FP"
  else
    echo "$N | exit=$E | DECLINE | $(echo "$O" | grep -m1 'error:' | sed 's/^.*: cq /cq /')"
  fi
done
echo "# work dir: $W"
