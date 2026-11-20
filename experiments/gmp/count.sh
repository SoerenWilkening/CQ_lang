#!/bin/sh
# count.sh <driver.c>: lowers one driver together with GMP (${GMP_IR:-build/linked.ll}, the whole library as -O1 IR) as one program,
# links the precompiled libc and the counting backend, prints gates, depth and qubits.
set -eu
cd "$(dirname "$0")"
D=$1; shift; N=$(basename "$D" .c)
E=$(cd .. && pwd)
mkdir -p build/count
s=$(date +%s)
$E/../driver/cqcc "$D" ${GMP_IR:-build/linked.ll} -Isrc/gmp-6.3.0 -include math.h -w --cq-roots $E/lib/libc.roots \
    --backend -L$E/lib --backend -lqc --backend -L$E/lib/backend --backend -lcq_backend --backend -lcq_gates_count \
    $E/lib/musl_stubs.o --save-temps build/count/$N.tmp -o build/count/$N "$@" 2>&1 | grep -v 'ld: warning' | tail -6 || true
echo "== $N: lowered and linked in $(( $(date +%s) - s )) s"
s=$(date +%s)
env CQ_COUNT=build/count/$N.txt perl -e 'alarm '${LIMIT:-900}'; exec @ARGV' build/count/$N > build/count/$N.log 2>&1 || true
echo "== $N: ran $(( $(date +%s) - s )) s"
if [ -s build/count/$N.txt ]; then tr '\n' ' ' < build/count/$N.txt; echo; else tail -2 build/count/$N.log | cut -c1-220; fi
