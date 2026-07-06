#!/usr/bin/env bash
# build.sh — reproduce every artifact in this folder from the .c sources.
# Run from the repo root:  bash demo/foo_superposition/build.sh
set -euo pipefail

LLVM=/usr/local/opt/llvm@19/bin           # opt/clang/llvm-link (not on PATH on this machine)
ROOT=$(cd "$(dirname "$0")/../.." && pwd)  # repo root
PLUGIN="$ROOT/build/ir-pass/libCQPass.so"  # the cq-lowering pass (build it: cmake --build build --target CQPass)
TPL="$ROOT/build/runtime/libcq_templates.a"
RT="$ROOT/build/runtime/libcq_runtime.a"    # link order: templates BEFORE runtime
D="$ROOT/demo/foo_superposition"
cd "$ROOT"

echo "### 1. foo.c — the FAITHFUL adjustment (single file) — DECLINES"
"$LLVM/clang" -Iinclude -O1 -emit-llvm -S "$D/foo.c" -o "$D/foo.frontend.ll"
if "$LLVM/opt" -load-pass-plugin "$PLUGIN" -passes=cq-lowering -S "$D/foo.frontend.ll" -o /dev/null 2>"$D/foo.decline.txt"; then
  echo "  (unexpected: compiled)"; else echo "  declined (expected):"; cat "$D/foo.decline.txt"; fi

echo "### 2. foo_working.c — compiler-SUPPORTED single-file variant — RUNS (foo inlined)"
"$LLVM/clang" -Iinclude -O1 -emit-llvm -S "$D/foo_working.c" -o "$D/foo_working.frontend.ll"
"$LLVM/opt" -load-pass-plugin "$PLUGIN" -passes=cq-lowering -S "$D/foo_working.frontend.ll" -o "$D/foo_working.lowered.ll"
"$LLVM/clang" "$D/foo_working.lowered.ll" "$TPL" "$RT" -o "$D/.working_exe"
"$D/.working_exe" > "$D/foo_working.trace.log"; rm -f "$D/.working_exe"
cat "$D/foo_working.trace.log"

echo "### 3. foo_spec_*.c — MULTI-FILE so foo stays un-inlined -> quantum CLONE @__cq_q_foo_1"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S "$D/foo_spec_caller.c" -o "$TMP/cq.ll"
"$LLVM/clang" -Iinclude              -O1 -emit-llvm -S "$D/foo_spec_lib.c"    -o "$TMP/lib.ll"
"$LLVM/llvm-link" -S "$TMP/cq.ll" "$TMP/lib.ll" -o "$TMP/combined.ll"
"$LLVM/opt" -load-pass-plugin "$PLUGIN" -passes=cq-lowering -S "$TMP/combined.ll" -o "$D/foo_spec.lowered.ll"
"$LLVM/clang" "$D/foo_spec.lowered.ll" "$TPL" "$RT" -o "$TMP/spec_exe"
"$TMP/spec_exe" > "$D/foo_spec.trace.log"
cat "$D/foo_spec.trace.log"

echo "### 3b. the ORIGINAL foo body (IN-BODY CONTROL) un-inlined -> 5po2 LIFTS it to a clone"
# The original `int foo(int b){int a=0; if(b<5) a+=b; return a;}` is `select(b<5,b,0)`
# at -O1. Un-inlined + handed a superposition, Phase-6 specialization (issue 5po2)
# lifts it into @__cq_q_foo_1, emitting the select as a controlled-XOR copy and
# Bennett-reversing it. (Pre-5po2 this DECLINED "callee contains tainted control
# flow under quantum lift"; it now runs.)
rm -f "$D/foo_spec_original_inbody.decline.txt"   # stale pre-5po2 artifact
printf 'int foo(int b){int a=0; if(b<5) a+=b; return a;}\n' > "$TMP/orig.c"
"$LLVM/clang" -Iinclude -O1 -emit-llvm -S "$TMP/orig.c" -o "$TMP/orig.ll"
"$LLVM/llvm-link" -S "$TMP/cq.ll" "$TMP/orig.ll" -o "$TMP/orig_combined.ll"
"$LLVM/opt" -load-pass-plugin "$PLUGIN" -passes=cq-lowering -S "$TMP/orig_combined.ll" -o "$D/foo_spec_inbody.lowered.ll"
"$LLVM/clang" "$D/foo_spec_inbody.lowered.ll" "$TPL" "$RT" -o "$TMP/inbody_exe"
"$TMP/inbody_exe" > "$D/foo_spec_inbody.trace.log"
cat "$D/foo_spec_inbody.trace.log"

echo "### 3c. the SINGLE-FILE noinline foo -> foo lifts, but main's OUTER if still declines (a8c0)"
# foo.c with __attribute__((noinline)) keeps foo un-inlined. foo itself now lifts
# (5po2), but main's `if (a != 0) a = cq_phi(a, ...)` is a SEPARATE tainted-control
# decline (the const-folded phase/value merge — bd issue a8c0), so the whole
# module still declines. This isolates the remaining frontier from foo.
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S "$D/foo_noinline.c" -o "$D/foo_noinline.frontend.ll"
"$LLVM/opt" -load-pass-plugin "$PLUGIN" -passes=cq-lowering -S "$D/foo_noinline.frontend.ll" -o /dev/null 2>"$D/foo_noinline.decline.txt" || true
cat "$D/foo_noinline.decline.txt"
echo "### done."
