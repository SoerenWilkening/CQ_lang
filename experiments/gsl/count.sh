#!/bin/sh
# count.sh <driver.c> [cqcc flags]: lowers one driver against the precompiled lowered GSL and libc, links the counting
# backend and prints gates, depth and qubits. GSL archives: ../lib/gsl-noout (built with -cq-no-output) first, then
# ../lib/gsl for the sub-libraries not rebuilt.
set -eu
cd "$(dirname "$0")"
D=$1; shift; N=$(basename "$D" .c)
E=$(cd .. && pwd); G=src/gsl-2.8
mkdir -p build/count
cat $E/lib/gsl/*.roots | sort -u > build/gsl.all.roots
LIBS=$(for a in $E/lib/gsl-noout/libq_*.a; do printf ' --backend %s' $a; done; for a in $E/lib/gsl/libq_*.a; do [ -e $E/lib/gsl-noout/$(basename $a) ] || printf ' --backend %s' $a; done)
$E/../driver/cqcc "$D" -I$G -include math.h -w --cq-roots $E/lib/libc.roots --cq-ext-roots build/gsl.all.roots $LIBS \
    --backend -L$E/lib --backend -lqc --backend -L$E/lib/backend --backend -lcq_backend --backend -lcq_gates_count \
    $E/lib/musl_stubs.o -o build/count/$N "$@" 2>&1 | grep -v 'ld: warning' || true
s=$(date +%s)
env CQ_COUNT=build/count/$N.txt perl -e 'alarm '${LIMIT:-600}'; exec @ARGV' build/count/$N > build/count/$N.log 2>&1 || true
echo "== $N ($(( $(date +%s) - s )) s)"
if [ -s build/count/$N.txt ]; then tr '\n' ' ' < build/count/$N.txt; echo; else tail -2 build/count/$N.log | cut -c1-200; fi
