#!/bin/sh
# One-time: lowers GSL sub-libraries, one module each, into ../lib/gsl/libq_<name>.a.
#   ./build_lib.sh statistics sort sys ...
# Roots of a sub-library are the functions its native archive exports; calls into libc and into the
# other sub-libraries stay calls of their lowered clones (--cq-ext-roots). Resumable.
set -eu
cd "$(dirname "$0")"
G=src/gsl-2.8
L=${GSL_OUT:-../lib/gsl}   # GSL_OUT, CQFLAGS: a second build, e.g. GSL_OUT=../lib/gsl-noout CQFLAGS=-cq-no-output
mkdir -p $L build
# A native build, only to read each sub-library's exported names.
ls $G/sys/.libs/*.a >/dev/null 2>&1 || make -C $G -j4 >/dev/null 2>&1
for a in $G/*/.libs/*.a; do
    d=$(basename "$(dirname "$(dirname "$a")")")
    [ -s $L/$d.roots ] || nm -g --defined-only "$a" 2>/dev/null | awk '$2 == "T" { sub(/^_/, "", $3); print $3 }' | sort -u > $L/$d.roots
done
for d in "$@"; do
    [ -s $L/libq_$d.a ] && continue
    srcs=$(python3 -c '
import re, sys
t = open(sys.argv[1] + "/Makefile.am").read().replace("\\\n", " ")
m = re.search(r"^lib\w+_la_SOURCES\s*=(.*)$", t, re.M)
print(" ".join(sys.argv[1] + "/" + f for f in m.group(1).split() if f.endswith(".c")))' $G/$d)
    cat $(ls $L/*.roots | grep -v "/$d.roots") > build/$d.ext.roots
    echo "== $d $(date +%H:%M:%S) $(wc -l < $L/$d.roots) roots"
    if ../../driver/cqcc --cq-lib --cq-roots $L/$d.roots --cq-ext-roots ../lib/libc.roots \
        --cq-ext-roots build/$d.ext.roots ${CQFLAGS:-} $srcs -I$G -I$G/$d -DHAVE_CONFIG_H -w -o $L/libq_$d.tmp.a
    then mv $L/libq_$d.tmp.a $L/libq_$d.a; echo "   ok $(date +%H:%M:%S) $(wc -c < $L/libq_$d.a) bytes"
    else echo "   FAILED $(date +%H:%M:%S)"; fi
done
