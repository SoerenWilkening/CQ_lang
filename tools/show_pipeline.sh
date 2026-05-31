#!/usr/bin/env bash
# show_pipeline.sh — run the taint-driven pipeline on one example and dump
# every intermediate so you can SEE what each stage produces. Same 4 stages
# as tests/e2e/run_slice.sh, but emits the IR to a visible out-dir instead of
# diffing a golden in a tempdir.
#
#   ./tools/show_pipeline.sh <source.c> [outdir]
#
# Toolchain + artifacts are auto-resolved from the Homebrew llvm@19 install and
# the build/ tree (override with CLANG/OPT/PASS/RT/TPL/INC env vars).
set -euo pipefail

SRC=${1:?usage: show_pipeline.sh <source.c> [outdir]}
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT=${2:-"$ROOT/build/pipeline-out/$(basename "${SRC%.c}")"}

LLVM=${LLVM:-/usr/local/opt/llvm@19/bin}
CLANG=${CLANG:-$LLVM/clang}
OPT=${OPT:-$LLVM/opt}
PASS=${PASS:-$ROOT/build/ir-pass/libCQPass.so}
RT=${RT:-$ROOT/build/runtime/libcq_runtime.a}
TPL=${TPL:-$ROOT/build/runtime/libcq_templates.a}
INC=${INC:-$ROOT/include}

mkdir -p "$OUT"
hr() { printf '\n\033[1m── %s ─────────────────────────────────────────\033[0m\n' "$1"; }

hr "STAGE 0 · CQ source ($SRC)"
cat "$SRC"

# Stage 1a: raw -O0 IR — orientation only (allocas/loads/stores, @cq_* calls).
"$CLANG" -I"$INC" -include CQ.h -O0 -emit-llvm -S "$SRC" -o "$OUT/s0.O0.ll"

# Stage 1b: -O1 IR — what the pass ACTUALLY receives (mem2reg/SROA cleaned).
"$CLANG" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$OUT/s1.O1.ll"
hr "STAGE 1 · clang -O1 IR  (pass input — @cq_* intrinsics still present)"
grep -vE '^\s*(target |source_filename|attributes #|![0-9])' "$OUT/s1.O1.ll" | grep -vE '^\s*$' | grep -vE '^; '

# Stage 2: the CQ lowering pass.
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$OUT/s1.O1.ll" -o "$OUT/s2.lowered.ll"
hr "STAGE 2 · opt -passes=cq-lowering  (lowered — only cqrt_*/cq_template_* remain)"
grep -vE '^\s*(target |source_filename|attributes #|![0-9])' "$OUT/s2.lowered.ll" | grep -vE '^\s*$' | grep -vE '^; '

# Stage 3: link against templates THEN runtime (link-order matters).
"$CLANG" "$OUT/s2.lowered.ll" "$TPL" "$RT" -o "$OUT/slice" 2>/dev/null
hr "STAGE 3 · link  →  $OUT/slice"

# Stage 4: run — the program prints its circuit trace to stdout.
hr "STAGE 4 · run  (runtime circuit trace)"
"$OUT/slice"

hr "intermediates written to  $OUT/"
ls -1 "$OUT"
