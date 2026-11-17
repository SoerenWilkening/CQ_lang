#!/bin/sh
# Build the CQ float-template library from the patched SoftFloat (softfloat/README.md).
#
#   softfloat/build.sh gen              regenerate cq/sf_unity.h, the roots, the shims and the root lists
#   softfloat/build.sh native           build/native/: the roots and SoftFloat as ordinary host code (self-test)
#   softfloat/build.sh ir [LIST]        build/<list>.O1.ll: clang -O1 of the roots, internalized to LIST
#   softfloat/build.sh lib [LIST]       lower the roots of LIST (default cqsf.roots) and make libqsoftfloat.a
#                                       (cqsf_f80.roots: libqsoftfloat_f80.a)
#
# Environment: CQ_LLVM_BIN (default /usr/local/opt/llvm@19/bin), CQCC (default ../driver/cqcc), CQ_PLUGIN and
# CQ_BUILD_DIR as cqcc reads them, CQSF_GROUP (roots per cq-lower run, default 40), CQSF_JOBS (default 1).
set -eu
SF=$(cd "$(dirname "$0")" && pwd)
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
CQCC=${CQCC:-$SF/../driver/cqcc}
B=$SF/build
CFLAGS="-I$SF/upstream/include -I$SF/upstream/8086-SSE -I$SF/cq -DSOFTFLOAT_FAST_INT64 -DINLINE_LEVEL=5 -DSOFTFLOAT_FAST_DIV32TO16 -DSOFTFLOAT_FAST_DIV64TO32"
mkdir -p "$B"

ir() {   # $1 = root list -> build/<stem>.O1.ll
    stem=$(basename "$1" .roots)
    # The integer-only inner bodies and the outer roots are separate units (cq/cqsf_inner.c, header).
    "$LLVM/clang" -O1 $CFLAGS -S -emit-llvm "$SF/cq/cqsf_inner.c" -o "$B/cqsf_inner.ll"
    "$LLVM/clang" -O1 -S -emit-llvm "$SF/cq/cqsf_roots.c" -o "$B/cqsf_roots.ll"
    "$LLVM/llvm-link" -S "$B/cqsf_roots.ll" "$B/cqsf_inner.ll" -o "$B/$stem.all.ll"
    # Only the roots stay external: every SoftFloat function is inlined (always_inline) and then dead.
    "$LLVM/opt" -S -passes=internalize,globaldce -internalize-public-api-file="$1" "$B/$stem.all.ll" -o "$B/$stem.O1.ll"
}

case "${1:-}" in
gen)
    python3 "$SF/tools/gen_unity.py"
    python3 "$SF/gen/gen_cqsf.py"
    ;;
native)
    mkdir -p "$B/native"
    "$LLVM/clang" -O1 $CFLAGS -c "$SF/cq/cqsf_inner.c" -o "$B/native/cqsf_inner.o"
    "$LLVM/clang" -O1 -c "$SF/cq/cqsf_roots.c" -o "$B/native/cqsf_roots.o"
    ;;
ir)
    ir "${2:-$SF/cqsf.roots}"
    ;;
lib)
    list=${2:-$SF/cqsf.roots}
    stem=$(basename "$list" .roots)
    case $stem in cqsf) out=libqsoftfloat ;; cqsf_f80) out=libqsoftfloat_f80 ;; *) out=lib$stem ;; esac
    ir "$list"
    rm -rf "$B/$stem.groups"; mkdir -p "$B/$stem.groups"
    split -l "${CQSF_GROUP:-40}" "$list" "$B/$stem.groups/g."
    objs=""
    for g in "$B/$stem.groups"/g.*; do
        n=$(basename "$g")
        # The group's roots only: cqcc --cq-lib exports them and their table clones.
        "$LLVM/opt" -S -passes=internalize,globaldce -internalize-public-api-file="$g" "$B/$stem.O1.ll" -o "$g.in.ll"
        cp -f "$g" "$g.roots"
        t0=$(date +%s)
        nice -n 10 "$CQCC" --cq-lib -S --cq-roots "$g.roots" "$g.in.ll" -o "$g.lowered.ll"
        # What cqcc -c does with the lowered module (driver/cqcc, step 4).
        "$LLVM/clang" -O1 -Xclang -disable-llvm-passes -c -x ir "$g.lowered.ll" -o "$g.o"
        echo "lowered $n: $(wc -l < "$g") roots in $(( $(date +%s) - t0 ))s"
        objs="$objs $g.o"
    done
    shim=cqsf_shims; [ "$stem" = cqsf_f80 ] && shim=cqsf_shims_f80
    "$LLVM/clang" -O1 -c "$SF/cq/$shim.c" -o "$B/$shim.o"
    # The lowered modules register their table clones (__cq_clone_register, CR §1.3), a bundle host symbol.
    # cqcc links bundle/host/cq_host.c into a program only when the program's own module asks for a host
    # symbol or a root list is given; as an archive member it is pulled exactly when nothing else defined it.
    "$LLVM/clang" -O1 -c "$SF/../bundle/host/cq_host.c" -o "$B/cq_host.o"
    rm -f "$B/$out.a"
    "$LLVM/llvm-ar" rcs "$B/$out.a" "$B/$shim.o" $objs "$B/cq_host.o"
    echo "$B/$out.a"
    ;;
*)
    sed -n '2,13p' "$0"; exit 2 ;;
esac
