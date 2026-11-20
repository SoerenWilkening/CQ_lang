#!/bin/sh
# One-time build of everything the experiments link, into lib/. Nothing here is rebuilt per experiment.
#   lib/libqc.a        the ISO C library (musl b1efda5), lowered once (README "Lowered libraries")
#   lib/libc.roots     its root list, given to every cqcc run
#   lib/backend/       opcode_quantum_operations with its counting gate backend
# SoftFloat is softfloat/build/libqsoftfloat*.a, which cqcc links by itself.
# Resumable: a finished archive is skipped. MUSL / BACKEND name the checkouts.
set -eu
cd "$(dirname "$0")"
ROOT=$(cd .. && pwd)
MUSL=${MUSL:-$ROOT/../wt/bundle-src/musl}
BACKEND=${BACKEND:-$ROOT/../opcode_quantum_operations}
mkdir -p lib && cd lib

test "$(git -C "$MUSL" rev-parse HEAD)" = b1efda5b91735e33635376ca11c9b497a1c66e39
ls "$ROOT"/softfloat/build/libqsoftfloat.a "$ROOT"/softfloat/build/libqsoftfloat_f80.a >/dev/null

cmake -S "$BACKEND" -B backend -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}/clang" >/dev/null
cmake --build backend -j4 --target cq_backend cq_gates_count >/dev/null

if [ ! -s bundle/libc.ll ]; then
    mkdir -p bundle
    python3 "$ROOT/bundle/build.py" --full --musl "$MUSL" --out bundle/libc.ll
    echo '["libc.ll"]' > bundle/manifest.json
fi
export CQ_BUNDLE_MANIFEST="$PWD/bundle/manifest.json"
for g in ctype locale string multibyte stdlib time math stdio complex; do
    [ -s libq_$g.a ] && continue
    echo "== $g $(date +%H:%M:%S)"
    "$ROOT/driver/cqcc" --cq-lib --cq-roots "$ROOT/bundle/roots/$g.roots" -o libq_$g.tmp.a
    mv libq_$g.tmp.a libq_$g.a
done
libtool -static -o libqc.a libq_*.a
cat "$ROOT"/bundle/roots/*.roots > libc.roots
echo "== done $(date +%H:%M:%S)"; ls -la libqc.a libc.roots backend/*.a
