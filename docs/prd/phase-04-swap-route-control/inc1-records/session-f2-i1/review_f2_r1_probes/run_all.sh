#!/bin/bash
# review_f2_r1 probe runner (round 1, independent Rule-13 review of bd `drbq.14`).
#
#   ./run_all.sh [NEW_WORKTREE] [OLD_WORKTREE]
#
# Defaults: NEW=/Users/sorenwilkening/Desktop/CQ_f2 (the narrowed branch),
#           OLD=/Users/sorenwilkening/Desktop/CQ_lang (main 0c7380c, the ORACLE).
# Prints, for every probe, `NEW rc=<n> [diag] | OLD rc=<n> [diag]`.
# rc=0 ACCEPT, rc=1 loud decline.  NOTHING here is a ctest entry.
set -u
NEW="${1:-/Users/sorenwilkening/Desktop/CQ_f2}"
OLD="${2:-/Users/sorenwilkening/Desktop/CQ_lang}"
LLVM=/usr/local/opt/llvm@19/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

one() {  # $1 = stage-1 .ll ; $2 = label
  "$NEW/build/ir-pass/cq-opt" -passes=cq-lowering -S "$1" -o "$T/n.ll" 2>"$T/n.err"; rn=$?
  "$OLD/build/ir-pass/cq-opt" -passes=cq-lowering -S "$1" -o "$T/o.ll" 2>"$T/o.err"; ro=$?
  dn=$(grep -oE 'lowering: .*' "$T/n.err" | head -1 | cut -c1-58)
  do_=$(grep -oE 'lowering: .*' "$T/o.err" | head -1 | cut -c1-58)
  printf "%-26s NEW rc=%d %-58s | OLD rc=%d %s\n" "$2" "$rn" "$dn" "$ro" "$do_"
}

echo "===== plain C at -O1 (c/) ====="
for f in "$HERE"/c/*.c; do
  b=$(basename "$f" .c)
  "$LLVM/clang" -I"$NEW/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/$b.s1.ll" 2>/dev/null || { echo "$b CLANG-FAIL"; continue; }
  one "$T/$b.s1.ll" "$b"
done
echo
echo "===== hand IR (ll/) — the alpha 2x2 and the beta observability pairs ====="
for f in "$HERE"/ll/*.ll; do one "$f" "$(basename "$f" .ll)"; done
echo
echo "===== rivals of the 4 NEW accepts (rival/) — all must DECLINE on NEW ====="
for f in "$HERE"/rival/*.ll; do one "$f" "$(basename "$f" .ll)"; done
