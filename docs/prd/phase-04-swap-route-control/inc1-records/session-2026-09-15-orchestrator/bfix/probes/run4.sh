#!/bin/bash
# BFIX probe driver (session 2026-09-15, fix agent). Runs ONE .c through stage 1
# and then through FOUR cq-opt binaries: ORACLE, BASE_A, SUBJ_B (the reviewed
# Track B binary = the BEFORE for the P1) and FIX (this worktree).
# Never writes into any worktree but this one's scratch.  Carries the reviewer's
# vacuity guard verbatim (bd memory `empty-module-accepts-vacuity-trap`).
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
BASE=/Users/sorenwilkening/Desktop/CQ_A
SUBJ=/Users/sorenwilkening/Desktop/CQ_B
FIX=${CQ_FIX_ROOT:-/Users/sorenwilkening/Desktop/CQ_BFIX}
W=${W:-$(mktemp -d)}
mkdir -p "$W"
P="$1"; B=$(basename "$P" .c)
CFLAGS=${CFLAGS:--O1 -g}
"$LLVM/clang" -I/Users/sorenwilkening/Desktop/CQ_BFIX/include -include CQ.h $CFLAGS -emit-llvm -S "$P" -o "$W/$B.s1.ll" 2>"$W/$B.cc.err" \
  || { echo "$B: CLANG-FAILED"; sed -n '1,5p' "$W/$B.cc.err"; exit 9; }
ndef=$(grep -c '^define' "$W/$B.s1.ll"); ncq=$(grep -c '@cq_' "$W/$B.s1.ll")
nun=$(grep -c 'unreachable' "$W/$B.s1.ll"); ninst=$(wc -l < "$W/$B.s1.ll" | tr -d ' ')
if [ "$ndef" -eq 0 ] || [ "$ncq" -eq 0 ]; then
  echo "$B: VACUOUS-STAGE1 defines=$ndef cqcalls=$ncq lines=$ninst -- probe measures NOTHING"; exit 8
fi
echo "$B  [stage1: defines=$ndef cq_calls=$ncq unreachable=$nun lines=$ninst]"
for tag in ORACLE BASE_A SUBJ_B FIX; do
  case $tag in ORACLE) D=$ORC;; BASE_A) D=$BASE;; SUBJ_B) D=$SUBJ;; FIX) D=$FIX;; esac
  if [ ! -x "$D/build/ir-pass/cq-opt" ]; then printf '  %-7s NO-BINARY (absence, not a result)\n' "$tag"; continue; fi
  out=$("$D/build/ir-pass/cq-opt" -load-pass-plugin "$D/build/ir-pass/libCQPass.so" \
          -passes=cq-lowering -S "$W/$B.s1.ll" -o "$W/$B.$tag.s2.ll" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    printf '  %-7s DECLINE  %s\n' "$tag" "$(printf '%s' "$out" | head -1 | sed -e 's/.*: in function [^:]*: //' -e 's/^error: //' | cut -c1-96)@$(printf '%s' "$out" | head -1 | grep -o '\.c:[0-9]*:[0-9]*' | head -1)"
  else
    pair=$(python3 /Users/sorenwilkening/Desktop/CQ_BFIX/tools/free_pairing_check.py "$W/$B.$tag.s2.ll" 2>&1 | tail -1)
    rm -f "$W/$B.$tag.trace"
    "$LLVM/clang" "$W/$B.$tag.s2.ll" "$D/build/runtime/libcq_templates.a" "$D/build/runtime/libcq_runtime.a" \
        -o "$W/$B.$tag.exe" 2>/dev/null && "$W/$B.$tag.exe" > "$W/$B.$tag.trace" 2>&1
    printf '  %-7s ACCEPT   trace=%s lines | 2b: %s\n' "$tag" "$(wc -l < "$W/$B.$tag.trace" 2>/dev/null | tr -d ' ')" "$pair"
  fi
done
