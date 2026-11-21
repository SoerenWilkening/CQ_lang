#!/bin/zsh
# build.sh <tag> <cq build dir> <gates: replay|count>: the library and the program with that build's plugin, linked with the
# backend built in ../backend; runs it. Outputs in out/<tag>-<gates>/.
set -eu
T=${0:A:h}; S=${T:h}
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang
SF=/Users/sorenwilkening/Desktop/Projects/CQ_lang/softfloat/build
O=$T/out/${PROG:-prog}-$1-$3; mkdir -p $O
export CQ_BUILD_DIR=$2
printf "${ROOTS:-sum_to\naxpb\nmix7\nhorner\n}" > $O/lib.roots
$W/driver/cqcc --cq-lib --cq-roots $O/lib.roots $T/${LIB:-lib}.c -S -o $O/lib.ll 2> $O/lib.err
$W/driver/cqcc --cq-lib --cq-roots $O/lib.roots $T/${LIB:-lib}.c -c -o $O/libq.a 2>> $O/lib.err
# The original library, compiled natively: linked after the lowered one, it provides every C symbol (rule 27).
/usr/local/opt/llvm@19/bin/clang -O1 -c $T/${LIB:-lib}.c -o $O/libnative.o
$W/driver/cqcc $T/${PROG:-prog}.c --cq-roots $O/lib.roots -S -o $O/prog.ll 2> $O/prog.err
$W/driver/cqcc $T/${PROG:-prog}.c --cq-roots $O/lib.roots --no-softfloat \
  --backend $O/libq.a --backend $O/libnative.o --backend $SF/libqsoftfloat.a --backend $SF/libqsoftfloat_f80.a \
  --backend -L$S/lib/backend-replay --backend -lcq_backend --backend -lcq_gates_$3 -o $O/prog 2>> $O/prog.err
env CQ_COUNT=$O/counts.txt $O/prog > $O/run.txt 2>&1 || echo "exit $?" >> $O/run.txt
cat $O/run.txt
echo "   lowered library defines: $(/usr/local/opt/llvm@19/bin/llvm-nm --defined-only --extern-only --format=just-symbols $O/libq.a | grep -v ':$' | tr '\n' ' ')"
[ -s $O/counts.txt ] && tr '\n' ' ' < $O/counts.txt && echo
