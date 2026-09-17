#!/bin/bash
# full.sh <BUILD_DIR> <REPO_ROOT_for_include> <file.c>
# stage1 -> stage2 -> free-pairing -> link -> run; prints trace
LLVM=/usr/local/opt/llvm@19/bin
BUILD="$1"; INC="$2"; f="$3"
n=$(basename "$f" .c)
TMP=${TMPDIR_OVERRIDE:-$(mktemp -d)}
mkdir -p "$TMP"
"$LLVM/clang" -I"$INC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$TMP/$n.s1.ll" || exit 1
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering \
    -S "$TMP/$n.s1.ll" -o "$TMP/$n.s2.ll" 2> "$TMP/$n.err"
rc=$?
echo "== opt exit=$rc  stderr:"; cat "$TMP/$n.err"
[ $rc -ne 0 ] && { echo "TMP=$TMP"; exit $rc; }
echo "== free_pairing (STRICT):"
python3 "$INC/tools/free_pairing_check.py" "$TMP/$n.s2.ll"
echo "== lowered line count: $(grep -c . "$TMP/$n.s2.ll")"
"$LLVM/clang" "$TMP/$n.s2.ll" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o "$TMP/$n.exe" 2>/dev/null || { echo "LINK FAIL"; echo "TMP=$TMP"; exit 1; }
echo "== trace:"
"$TMP/$n.exe"
echo "TMP=$TMP"
