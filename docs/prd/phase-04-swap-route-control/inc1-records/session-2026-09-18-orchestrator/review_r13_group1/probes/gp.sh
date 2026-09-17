#!/bin/bash
# gp.sh <probe.c> <BUILDROOT> <TAG> [argv...]  — PRIVATE harness, r13 group1 reviewer.
set -u
LLVM=/usr/local/opt/llvm@19/bin
REPO=/Users/sorenwilkening/Desktop/Projects/CQ_lang
MY=/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/15feda8c-ff76-4035-8aec-acbfe9c14725/scratchpad/r13g1_private
W=$MY/work
P="$1"; BUILD="$2"; TAG="$3"; shift 3
B=$(basename "$P" .c); B=$(basename "$B" .ll)
mkdir -p "$W"
H=$(shasum -a 256 "$BUILD/ir-pass/cq-opt" | cut -c1-16)
echo "######## $B [$TAG $H] ########"
case "$P" in
  *.ll) S1="$P" ;;
  *)
    if [ ! -s "$P" ]; then echo "VACUOUS-EMPTY"; exit 2; fi
    grep -qE 'cq_theta|cq_phi|cq_measure' "$P" || { echo "VACUOUS-NOQUANTUM"; exit 2; }
    S1="$W/$B.$TAG.s1.ll"
    "$LLVM/clang" -I"$REPO/include" -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$S1" 2>"$W/$B.$TAG.c.err" || { echo "CLANG-FAIL"; cat "$W/$B.$TAG.c.err"; exit 3; }
    [ -s "$S1" ] || { echo "VACUOUS-EMPTY-S1"; exit 2; } ;;
esac
S2="$W/$B.$TAG.s2.ll"; EXE="$W/$B.$TAG.exe"; TR="$W/$B.$TAG.trace"
rm -f "$S2" "$EXE" "$TR"
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$S1" -o "$S2" 2>"$W/$B.$TAG.opt.err"
RC=$?
echo "opt exit=$RC"
if [ $RC -ne 0 ]; then echo "--- DECLINE:"; cat "$W/$B.$TAG.opt.err"; exit 0; fi
if [ -s "$W/$B.$TAG.opt.err" ]; then echo "--- WARN:"; sed 's/^.*: cq /cq /' "$W/$B.$TAG.opt.err" | grep . ; else echo "--- stderr: 0 bytes"; fi
echo "--- 2b: $(cd "$REPO" && python3 tools/free_pairing_check.py "$S2" 2>&1 | tail -1)"
echo "--- rolled: $(grep -c 'llvm.loop' "$S2") !llvm.loop refs"
"$LLVM/clang" "$S2" "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o "$EXE" 2>"$W/$B.$TAG.link.err" || { echo "LINK-FAIL"; cat "$W/$B.$TAG.link.err"; exit 4; }
"$EXE" "$@" > "$TR" 2>&1
echo "--- trace: $(wc -l < "$TR" | tr -d ' ') lines"
grep -o '^[a-z_0-9]*' "$TR" | sort | uniq -c | awk '{printf "    %s %s\n",$1,$2}'
