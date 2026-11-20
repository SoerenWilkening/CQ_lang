#!/bin/sh
# The eigensolver as one program: eigen.c lowered together with the GSL sub-libraries it uses, so classical
# arguments (sizes, strides, error checks) stay classical. libc and SoftFloat are still the precompiled ones.
set -eu
cd "$(dirname "$0")"
E=$(cd .. && pwd); G=src/gsl-2.8
mkdir -p build
SRCS=$(for d in eigen linalg blas cblas matrix vector block permutation sort complex err sys; do python3 -c '
import re, sys
t = open(sys.argv[1] + "/Makefile.am").read().replace("\\\n", " ")
m = re.search(r"^lib\w+_la_SOURCES\s*=(.*)$", t, re.M)
print(" ".join(sys.argv[1] + "/" + f for f in m.group(1).split() if f.endswith(".c")))' $G/$d; done)
INC=$(for d in eigen linalg blas cblas matrix vector block permutation sort complex err sys; do printf ' -I%s' $G/$d; done)
echo "== lower and link"
time $E/../driver/cqcc ${DRIVER:-eigen.c} $SRCS -I$G $INC -DHAVE_CONFIG_H -include math.h -w --cq-roots $E/lib/libc.roots \
    --backend -L$E/lib --backend -lqc --backend -L$E/lib/backend --backend -lcq_backend --backend -lcq_gates_count \
    $E/lib/musl_stubs.o --save-temps build/eigenw.tmp -o build/eigenw "$@"
echo "== count"
time env CQ_COUNT=build/eigenw.counts.txt perl -e 'alarm ${LIMIT:-1800}; exec @ARGV' build/eigenw || true
cat build/eigenw.counts.txt
