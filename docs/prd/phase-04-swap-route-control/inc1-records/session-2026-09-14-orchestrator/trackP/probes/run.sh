#!/bin/zsh
# Track P probe runner. Run from a repo root; BUILD selects the binary measured.
#   BUILD=<dir> ./run.sh <dir-with-probes> [probe ...]
set -u
LLVM=/usr/local/opt/llvm@19/bin
REPO=${REPO:-$PWD}
BUILD=${BUILD:-$REPO/build}
h=$(shasum -a 256 $BUILD/ir-pass/cq-opt | cut -d' ' -f1)
echo "# binary $BUILD/ir-pass/cq-opt sha256 ${h:0:16}"
D=${1:?dir}; shift
cd $REPO
setopt NULL_GLOB
if [[ $# -eq 0 ]]; then set -- $D/*.c $D/*.ll; fi
for f in "$@"; do
  [[ -e $f ]] || continue
  n=${f:t:r}; o=$D/$n
  if [[ $f == *.c ]]; then
    "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S $f -o $o.s1.ll 2>$o.cc.err || { echo "$n | CLANG-FAIL"; continue; }
  else cp -f $f $o.s1.ll; fi
  "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S $o.s1.ll -o $o.s2.ll >$o.out 2>$o.err
  e=$?
  if [[ $e == 0 ]]; then
    p=$(python3 tools/free_pairing_check.py $o.s2.ll 2>&1 | tail -1)
    "$LLVM/clang" $o.s2.ll $BUILD/runtime/libcq_templates.a $BUILD/runtime/libcq_runtime.a -o $o.bin 2>$o.link.err \
      && "$o.bin" > $o.trace 2>&1 && t=$(wc -l < $o.trace | tr -d ' ') || t=LINKFAIL
    echo "$n | exit=0 | ACCEPT | trace=$t | 2b: $p"
  else
    d=$(grep -m1 'error:' $o.err | sed 's/.*cq /cq /')
    echo "$n | exit=$e | $d"
  fi
done
