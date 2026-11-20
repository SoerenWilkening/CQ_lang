#!/bin/sh
# mask_sweep.sh <linked.ll> <outdir> <roots.txt> [plugin]: lowers every function of a module under every mix of classical
# and quantum arguments except all-classical. One generated driver per (function, mask) calls it from a program, classical
# arguments from argc, quantum ones from cq_theta, so the pass makes that mask's clone. The module's other functions
# (roots.txt, as ../per_function.sh writes it) are declared roots, so a call stays a call.
set -eu
IN=$1; OUT=$2; ROOTS=$3
R=$(cd "$(dirname "$0")/.." && pwd)
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
PLUGIN=${4:-$R/build/pass/libCQLower.so}
mkdir -p "$OUT"
echo "=== 2. every argument mask"
# function|ret|arg types, from the IR
grep '^define ' "$IN" | sed -E 's/^define ([^@]*)@([A-Za-z0-9_]+)\((.*)\) .*$/\2|\1|\3/' |
python3 -c '
import sys, re
ct = {"i32": "int", "i64": "long", "i8": "char", "i16": "short", "ptr": "void *", "void": "void", "double": "double"}
for line in sys.stdin:
    f, ret, args = line.rstrip("\n").split("|")
    ret = ct[[t for t in ret.split() if t in ct][-1]]
    tys = [ct[next(t for t in a.split() if t in ct)] for a in args.split(",") if a.strip()]
    n = len(tys)
    for m in range(1, 1 << n):
        mask = "".join("1" if m >> (n - 1 - i) & 1 else "0" for i in range(n))
        out = ["#include <math.h>", "#include <stdint.h>", "static char obj[4096];",
               "%s %s(%s);" % (ret, f, ", ".join(tys)), "int main(int argc, char **argv) {"]
        call = []
        for i, t in enumerate(tys):
            if mask[i] == "1":
                out.append("    unsigned char q%d = 0; cq_theta(&q%d, M_PI_2);" % (i, i))
                call.append("(void *)((uintptr_t)obj + q%d)" % i if t == "void *" else "(%s)q%d" % (t, i))
            else:
                call.append("(void *)(obj + argc)" if t == "void *" else "(%s)(argc + %d)" % (t, i))
        out.append("    %s(%s);" % (f, ", ".join(call)))
        out.append("    return cq_measure(argc);\n}")
        open(sys.argv[1] + "/%s.%s.c" % (f, mask), "w").write("\n".join(out) + "\n")
' "$OUT"
: > $OUT/results.txt
for d in $OUT/*.c; do
    b=$(basename "$d" .c); f=${b%.*}; m=${b##*.}
    "$L/llvm-extract" --func="$f" -S "$IN" -o "$OUT/$f.fn.ll"
    grep -vx "$f" "$ROOTS" > "$OUT/$b.roots"
    if CQ_BUILD_DIR=$(dirname "$(dirname "$PLUGIN")") perl -e 'alarm 300; exec @ARGV' "$R/driver/cqcc" -S "$d" "$OUT/$f.fn.ll" -w \
           --cq-roots "$OUT/$b.roots" -o "$OUT/$b.out.ll" > "$OUT/$b.err" 2>&1; then
        # the clone the pass made for this call: its mask as the pass names it
        got=$(grep -oE "^define [^@]*@__cq_q_${f}_[01]+" "$OUT/$b.out.ll" | sed -E 's/.*_([01]+)$/\1/' | sort -u | tr '\n' ' ')
        echo "$f|$m|ok|$got" >> $OUT/results.txt
    else
        echo "$f|$m|FAIL|$(grep -m1 -E 'LLVM ERROR|site:|error' "$OUT/$b.err" | cut -c1-150)" >> $OUT/results.txt
    fi
    rm -f "$OUT/$b.out.ll" "$OUT/$b.roots"
done
echo "masks: $(wc -l < $OUT/results.txt | tr -d ' ')   ok: $(grep -c '|ok|' $OUT/results.txt)"
grep -v '|ok|' $OUT/results.txt || true
