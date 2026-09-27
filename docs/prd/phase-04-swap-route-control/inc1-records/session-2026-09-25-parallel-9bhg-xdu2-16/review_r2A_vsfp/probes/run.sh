#!/bin/bash
# usage: run.sh <bin: S|O> <file.c|file.ll> [extra clang args]
WT=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
LLVM=/usr/local/opt/llvm@19/bin
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
case "$1" in S) B=$WT/build/ir-pass/cq-opt;; O) B=$SP/frozen/cq-opt.main_aee8;; *) B=$1;; esac
f=$2; shift 2
base=$(basename "$f"); base=${base%.*}
tag=$(basename $B | tr -c 'a-zA-Z0-9_\n' '_')
out=$SP/r2A/out; mkdir -p $out
if [[ "$f" == *.c ]]; then
  "$LLVM/clang" -I$WT/include -include CQ.h -O1 -emit-llvm -S "$f" -o $out/$base.s1.ll "$@" || { echo "CLANG FAIL"; exit 1; }
  s1=$out/$base.s1.ll
else
  s1=$f
fi
if [ ! -s "$s1" ]; then echo "EMPTY MODULE"; exit 1; fi
"$B" -load-pass-plugin x -passes=cq-lowering -S "$s1" -o $out/$base.$tag.s2.ll 2> $out/$base.$tag.err
rc=$?
echo "== $base [$tag] opt rc=$rc stderr_bytes=$(wc -c < $out/$base.$tag.err)"
head -c 600 $out/$base.$tag.err
if [ $rc -eq 0 ]; then
  python3 $WT/tools/free_pairing_check.py $out/$base.$tag.s2.ll 2>&1 | tail -2
  if grep -q "define.*@main" $out/$base.$tag.s2.ll; then
    "$LLVM/clang" $out/$base.$tag.s2.ll $WT/build/runtime/libcq_templates.a $WT/build/runtime/libcq_runtime.a -o $out/$base.$tag.exe 2>/dev/null && $out/$base.$tag.exe > $out/$base.$tag.trace 2>&1; echo "run rc=$? lines=$(wc -l < $out/$base.$tag.trace)"
  fi
fi
