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
#
# ⚠ A DECLINE IS A COMPILER VERDICT, NOT A SCRIPT FAILURE.  This script runs
# under `set -euo pipefail`, so before this banner existed a loud
# `DiagnosticInfoUnsupported` (opt exits non-zero — the Prime Directive's whole
# mechanism) killed the script right after a full stage-1 IR dump and left one
# bare `error:` line on stderr.  It read as a broken script, and was reported as
# one (bd test_C_libtooling-fn1q).  Catch it, say what it is, and exit with the
# compiler's own status.
# ⚠ `rc` is captured on the line AFTER the command and BEFORE anything else —
# never inside an `if ! cmd; then rc=$?`, where `$?` is the negated compound's
# status (0) rather than opt's.  Same trap as a `$?` read after a pipe.
set +e
"$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering \
    -S "$OUT/s1.O1.ll" -o "$OUT/s2.lowered.ll" 2>"$OUT/s2.stderr"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  printf '\n\033[1;31m── STAGE 2 · DECLINED ────────────────────────────────\033[0m\n'
  printf '\033[1mThe CQ lowering pass REFUSED this program.  That is a compiler\n'
  printf 'verdict, not a script error\033[0m — `opt` exited %s and lowered nothing.\n\n' "$rc"
  cat "$OUT/s2.stderr"
  printf '\nA loud failure beats a silent miscompile, but it is only a VALID decline\n'
  printf 'when physics forbids the program (NORTHSTAR.md, goal 1).  Otherwise it is\n'
  printf 'a compiler gap: this program SHOULD lower, and that is a defect worth filing.\n\n'
  printf 'Stage-1 IR (the pass input) is at:\n  %s\n' "$OUT/s1.O1.ll"
  printf 'Stage-2 stderr is at:\n  %s\n\n' "$OUT/s2.stderr"
  exit "$rc"
fi
# A decline is loud and fatal above; anything on stderr HERE is a warning that
# still lowered (e.g. the ruled `lyyf` live-derived-record warning).  Show it —
# it is a statement about the emitted circuit.
if [ -s "$OUT/s2.stderr" ]; then
  printf '\n\033[1;33m── STAGE 2 · WARNINGS (lowered anyway, exit 0) ───────\033[0m\n'
  cat "$OUT/s2.stderr"
fi
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
