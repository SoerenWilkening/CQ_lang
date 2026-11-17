#!/bin/sh
# The link test: a program with double arithmetic, lowered by cqcc, linked against libqsoftfloat.a and a
# toy backend that defines integer templates only (gen_toy_backend.py), run, and compared with the same
# C program built natively.
#   softfloat/test/run_link_test.sh [PROG.c]      (default test/prog_double.c with its host main PROG_main.c;
#                                                  needs build/libqsoftfloat.a)
# Environment as for build.sh (CQ_PLUGIN, CQ_BUILD_DIR, CQ_SPEC_DIR).
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$T")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
CQCC=${CQCC:-$SF/../driver/cqcc}
P=${1:-$T/prog_double.c}
B=$SF/build/link; mkdir -p "$B"
n=$(basename "$P" .c)
# 1. the expected output: the C program itself
M=${P%.c}_main.c
"$LLVM/clang" -O1 '-Dcq_theta(p, a)=((void)0)' '-Dcq_measure(x)=(x)' "$P" "$M" -lm -o "$B/$n.native"
"$LLVM/clang" -O1 -c "$M" -o "$B/${n}_main.o"
"$B/$n.native" > "$B/$n.expected"
# 2. the lowered program and the backend generated for what it and the library declare
nice -n 10 "$CQCC" -S "$P" -o "$B/$n.lowered.ll"
python3 "$T/gen_toy_backend.py" "$B/toy_backend.c" "$B/$n.lowered.ll" "$SF"/build/cqsf.groups/g.*.lowered.ll \
    --library-manifest "$SF/build/manifest.json"
"$LLVM/clang" -O1 -c "$B/toy_backend.c" -o "$B/toy_backend.o"
echo "float templates the program calls:"
grep -ohE 'call [a-z0-9]+ @cq_template_f[a-z0-9_]*|call [a-z0-9]+ @cq_template_(sqrt|floor|sitofp|fptosi|fpext|fptrunc|is_fpclass)[a-z0-9_]*' \
    "$B/$n.lowered.ll" | sed 's/.*@//' | sort -u | tr '\n' ' '; echo
# 3. link: the program, the lowered library, the integer-only backend
nice -n 10 "$CQCC" "$P" "$B/${n}_main.o" -L"$SF/build" -lqsoftfloat --backend "$B/toy_backend.o" -o "$B/$n.exe"
"$B/$n.exe" > "$B/$n.out"
echo "expected: $(cat "$B/$n.expected")"
echo "lowered:  $(cat "$B/$n.out")"
cmp -s "$B/$n.expected" "$B/$n.out" && echo "link test: PASS" || { echo "link test: FAIL"; exit 1; }
