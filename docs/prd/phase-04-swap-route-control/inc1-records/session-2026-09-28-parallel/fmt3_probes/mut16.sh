#!/bin/bash
# fmt3 round 2 — the per-token MUTATION MATRIX for tests/frontend/cq_theta_nomerge_widths.c
# (and, for the record, cq_theta_nomerge.c). For each of the 16 `CQ_THETA_NOMERGE_` tokens in
# the COMMITTED include/CQ.h: build a header with exactly that one token deleted, run the
# fixture's RUN line (clang -O1 … | FileCheck) and record CAUGHT (FileCheck fails) or MISSED.
# Controls, run FIRST: NULL (the committed header, nothing deleted) must PASS; ALL (every token
# deleted) and OLD (git show 9a230646:include/CQ.h) must FAIL.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/mut16
rm -rf "$S"; mkdir -p "$S"
HDR=$W/include/CQ.h
run_fixture() {   # $1 = include dir, $2 = fixture; prints rc of FileCheck (0 = pass)
  "$L/clang" -I"$1" -O1 -emit-llvm -include CQ.h -S "$2" -o "$S/out.ll" 2> "$S/clang.err" || { echo 99; return; }
  "$L/FileCheck" "$2" < "$S/out.ll" > "$S/fc.out" 2>&1
  echo $?
}
failing_fn() {    # first CHECK-LABEL function that failed, for the matrix
  grep -o 'CHECK-LABEL: define {{.\*}} @[a-z0-9_]*' "$S/fc.out" | head -1 | sed 's/.*@//'
  grep -m1 -o 'input.*@nm_[a-z0-9]*' "$S/fc.out" >/dev/null 2>&1
}
for FX in "$W/tests/frontend/cq_theta_nomerge_widths.c" "$W/tests/frontend/cq_theta_nomerge.c"; do
  echo "=== fixture $(basename "$FX")"
  mkdir -p "$S/null"; cp -f "$HDR" "$S/null/CQ.h"
  echo "CONTROL NULL (committed header): FileCheck rc=$(run_fixture "$S/null" "$FX")   (must be 0)"
  mkdir -p "$S/all"; sed 's/^CQ_THETA_NOMERGE_ //' "$HDR" > "$S/all/CQ.h"
  echo "CONTROL ALL-DELETED: FileCheck rc=$(run_fixture "$S/all" "$FX")   (must be non-0)"
  mkdir -p "$S/old"; git -C "$W" show 9a230646:include/CQ.h > "$S/old/CQ.h"
  echo "CONTROL OLD header (9a230646): FileCheck rc=$(run_fixture "$S/old" "$FX")   (must be non-0)"
  caught=0; missed=0
  grep -n '^CQ_THETA_NOMERGE_ ' "$HDR" | while IFS=: read -r ln rest; do
    name=$(echo "$rest" | grep -o 'cq_theta_[a-z0-9]*')
    d="$S/m_$name"; mkdir -p "$d"
    sed "${ln}s/^CQ_THETA_NOMERGE_ //" "$HDR" > "$d/CQ.h"
    ndel=$(diff "$HDR" "$d/CQ.h" | grep -c '^<')
    rc=$(run_fixture "$d" "$FX")
    if [ "$rc" = 0 ]; then v=MISSED; else v=CAUGHT; fi
    echo "MUTANT delete-token line $ln ($name, $ndel line changed): FileCheck rc=$rc  $v"
  done
done
# ---- which FUNCTION each widths-fixture mutant fails (must be exactly its own row) ----
FX=$W/tests/frontend/cq_theta_nomerge_widths.c
echo "=== per-mutant failing functions (widths fixture)"
for d in "$S"/m_cq_theta_*; do
  name=$(basename "$d" | sed 's/^m_//')
  "$L/clang" -I"$d" -O1 -emit-llvm -include CQ.h -S "$FX" -o "$S/out.ll" 2>/dev/null
  "$L/FileCheck" "$FX" < "$S/out.ll" > "$S/fc.out" 2>&1
  lines=$(grep -o "cq_theta_nomerge_widths.c:[0-9]*:[0-9]*: error" "$S/fc.out" | cut -d: -f2 | sort -un | tr '\n' ' ')
  fns=$(for ln in $lines; do awk -v L="$ln" 'NR<=L && /CHECK-LABEL/ {f=$0} NR==L {print f}' "$FX" | grep -o '@nm_[a-z0-9]*'; done | sort -u | tr '\n' ' ')
  echo "$name -> fails: $fns"
done
