#!/bin/bash
# R13 reviewer probe driver (review_r13_railbank, session 2026-09-15). Runs ONE .c through stage1 + cq-opt on THREE binaries.
# Never writes into any worktree. Always checks the stage-1 module is non-trivial.
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
BASE=/Users/sorenwilkening/Desktop/CQ_A
SUBJ=/Users/sorenwilkening/Desktop/CQ_B
W=${W:-$(mktemp -d)}
mkdir -p "$W"
P="$1"; B=$(basename "$P" .c)
"$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$W/$B.s1.ll" 2>"$W/$B.cc.err" || { echo "$B: CLANG-FAILED"; sed -n '1,5p' "$W/$B.cc.err"; exit 9; }
# VACUITY GUARD (bd empty-module-accepts-vacuity-trap): the module must define a
# function with a real body and at least one cq_* call.
ndef=$(grep -c '^define' "$W/$B.s1.ll")
ncq=$(grep -c '@cq_' "$W/$B.s1.ll")
nun=$(grep -c 'unreachable' "$W/$B.s1.ll")
ninst=$(wc -l < "$W/$B.s1.ll" | tr -d ' ')
if [ "$ndef" -eq 0 ] || [ "$ncq" -eq 0 ]; then
  echo "$B: VACUOUS-STAGE1 defines=$ndef cqcalls=$ncq lines=$ninst -- probe measures NOTHING"
  exit 8
fi
echo "$B  [stage1: defines=$ndef cq_calls=$ncq unreachable=$nun lines=$ninst]"
for tag in ORACLE BASE_A SUBJ_B; do
  case $tag in
    ORACLE) D=$ORC;; BASE_A) D=$BASE;; SUBJ_B) D=$SUBJ;;
  esac
  out=$("$D/build/ir-pass/cq-opt" -load-pass-plugin "$D/build/ir-pass/libCQPass.so" \
          -passes=cq-lowering -S "$W/$B.s1.ll" -o "$W/$B.$tag.s2.ll" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    printf '  %-7s DECLINE  %s\n' "$tag" "$(printf '%s' "$out" | sed -n '1s/.*error: //p' | cut -c1-110)"
  else
    pair=$(python3 $SUBJ/tools/free_pairing_check.py "$W/$B.$tag.s2.ll" 2>&1 | tail -1)
    "$LLVM/clang" "$W/$B.$tag.s2.ll" "$D/build/runtime/libcq_templates.a" "$D/build/runtime/libcq_runtime.a" \
        -o "$W/$B.$tag.exe" 2>/dev/null && "$W/$B.$tag.exe" > "$W/$B.$tag.trace" 2>&1
    printf '  %-7s ACCEPT   trace=%s lines | 2b: %s\n' "$tag" "$(wc -l < "$W/$B.$tag.trace" 2>/dev/null | tr -d ' ')" "$pair"
  fi
done
