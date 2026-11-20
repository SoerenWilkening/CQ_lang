#!/bin/sh
# Lowers eigen_jacobi.c against the precompiled lowered GSL and libc, links the counting backend, prints gates, depth, qubits.
set -eu
cd "$(dirname "$0")"
E=$(cd .. && pwd); G=src/gsl-2.8
mkdir -p build
cat $E/lib/gsl/*.roots | sort -u > build/gsl.all.roots
echo "== lower and link"
time $E/../driver/cqcc eigen_jacobi.c -I$G -include math.h -w --cq-roots $E/lib/libc.roots --cq-ext-roots build/gsl.all.roots \
    $(for a in ${GSL_LIB:-$E/lib/gsl-noout}/libq_*.a; do printf ' --backend %s' $a; done) \
    --backend -L$E/lib --backend -lqc --backend -L$E/lib/backend --backend -lcq_backend --backend -lcq_gates_count \
    $E/lib/musl_stubs.o --save-temps build/eigenj.tmp -o build/eigenj "$@"
echo "== count"
time env CQ_COUNT=build/eigen_jacobi.counts.txt perl -e 'alarm ${LIMIT:-1800}; exec @ARGV' build/eigenj || true
cat build/eigen_jacobi.counts.txt
