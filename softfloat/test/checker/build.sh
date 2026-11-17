#!/bin/sh
# Build the checker's inputs for a sample of lowered SoftFloat roots (entries.c): the library's clang -O1
# module (build.sh ir) internalized to the sampled roots, compiled with the entries by cqcc into
# build/chk/<prog>/tmp/{linked.ll,lowered.ll}. Then check.sh <prog> e_<root> per entry (check_some.sh for
# several): cqcheck user --o1 linked.ll --lowered lowered.ll --entry e_<root> --light --samples 16.
#   softfloat/test/checker/build.sh default|f80   (needs build/cqsf.O1.ll or build/cqsf_f80.O1.ll: build.sh lib)
set -eu
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$(dirname "$T")")
LLVM=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
CQCC=${CQCC:-$SF/../driver/cqcc}
P=${1:-default}
D=$SF/build/chk/$P; rm -rf "$D"; mkdir -p "$D"
if [ "$P" = f80 ]; then M=$SF/build/cqsf_f80.O1.ll; DEF=-DCQ_F80; else M=$SF/build/cqsf.O1.ll; DEF=; fi
"$LLVM/clang" -E $DEF -P "$T/entries.c" -I"$SF/../spec" | grep -oE '\bcqsf_[a-z0-9_]+\(' | tr -d '(' | sort -u > "$D/roots.txt"
"$LLVM/opt" -S -passes=internalize,globaldce -internalize-public-api-file="$D/roots.txt" "$M" -o "$D/roots.ll"
cp -f "$T/entries.c" "$D/entries.c"
nice -n 10 "$CQCC" -S $DEF --save-temps "$D/tmp" "$D/entries.c" "$D/roots.ll" -o "$D/out.ll"
ls "$D/tmp"
