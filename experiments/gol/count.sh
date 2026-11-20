#!/bin/sh
# count.sh [-DROWS=.. -DCOLS=.. -DQCELLS=.. -DGENS=..]: lowers life.c with the Game of Life source as one program, links
# the precompiled libc and the counting backend, prints gates, depth and qubits. Run sweep.sh once first. build/kernel.ll is
# addPadding and nextGen cut from the module: with the whole file the link fails, because rleGame's controlled clone
# calls a controlled sscanf that the precompiled libc does not export.
set -eu
cd "$(dirname "$0")"
E=$(cd .. && pwd)
N=life$(echo "$*" | tr -cd 'A-Z0-9=' | tr '=' '_'); mkdir -p build/count
rm -f build/count/$N build/count/$N.txt      # never report a stale run
s=$(date +%s)
$E/../driver/cqcc life.c build/kernel.ll -w "$@" --cq-roots $E/lib/libc.roots \
    --backend -L$E/lib --backend -lqc --backend -L$E/lib/backend --backend -lcq_backend --backend -lcq_gates_count \
    $E/lib/musl_stubs.o -o build/count/$N 2>&1 | grep -v 'ld: warning' | tail -6 || true
echo "== $N: lowered and linked in $(( $(date +%s) - s )) s"
s=$(date +%s)
env CQ_COUNT=build/count/$N.txt perl -e 'alarm '${LIMIT:-600}'; exec @ARGV' build/count/$N > build/count/$N.log 2>&1 || true
echo "== $N: ran $(( $(date +%s) - s )) s"
if [ -s build/count/$N.txt ]; then tr '\n' ' ' < build/count/$N.txt; echo; else tail -2 build/count/$N.log | cut -c1-220; fi
