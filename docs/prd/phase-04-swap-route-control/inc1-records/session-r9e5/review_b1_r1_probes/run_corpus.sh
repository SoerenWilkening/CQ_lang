#!/bin/bash
# run_corpus.sh [PRE|POST] — re-run the whole round-1 review probe corpus on one binary.
#   POST (default) = build/ir-pass/{cq-opt,libCQPass.so} (the branch)
#   PRE            = the saved pre-B.1 pair (path below; re-save it if the scratch dir is gone)
# Prints one line per probe: <name> rc=<n> <first diagnostic | trace line count>.
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=${CQ_ROOT:-/Users/sorenwilkening/Desktop/CQ_lang}
HERE=$(cd "$(dirname "$0")" && pwd)
PRE=${CQ_PRE:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad/impl_b1/pre}
which=${1:-POST}
if [ "$which" = "PRE" ]; then OPT="$PRE/cq-opt"; PLUG="$PRE/libCQPass.so"; else OPT="$ROOT/build/ir-pass/cq-opt"; PLUG="$ROOT/build/ir-pass/libCQPass.so"; fi
T=$(mktemp -d)
for f in "$HERE"/c/*.c "$HERE"/ll/*.ll; do
  b=$(basename "$f"); b="${b%.*}"
  case "$f" in
    *.c) "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$b CLANGFAIL"; continue; } ;;
    *.ll) cp -f "$f" "$T/s1.ll" ;;
  esac
  "$OPT" -load-pass-plugin "$PLUG" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>"$T/err"; rc=$?
  if [ $rc -ne 0 ]; then
    echo "$b rc=$rc $(grep -o 'cq [a-z ]*\(lowering\|escape\|specialization\): [^;]*' "$T/err" | head -1)"
  else
    python3 "$ROOT/tools/free_pairing_check.py" "$T/s2.ll" > "$T/2b" 2>&1
    n=$(grep -c 'call' "$T/s2.ll")
    echo "$b rc=0 accepted (2b: $(sed -n 's/.*: \([0-9]* verified.*\)/\1/p' "$T/2b" | head -1))"
  fi
done
rm -rf "$T"
