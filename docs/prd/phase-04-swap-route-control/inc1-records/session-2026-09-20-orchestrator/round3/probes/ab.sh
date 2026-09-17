#!/bin/bash
# ab.sh <probe.c ...>  — first-wall string per binary, 4-way
LLVM=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad
BINS=$S/bins
for C in "$@"; do
  n=$(basename "$C" .c)
  printf '%-34s' "$n"
  for TAG in BASE MAIN TU9QONLY COMPOSED; do
    d=$S/out/$TAG; mkdir -p "$d"
    "$LLVM/clang" -I$W/include -include CQ.h -O1 -emit-llvm -S "$C" -o "$d/$n.s1.ll" 2>/dev/null || { printf ' | %-28s' "CLANGFAIL"; continue; }
    "$BINS/cq-opt.$TAG" -load-pass-plugin "$BINS/libCQPass.$TAG.so" -passes=cq-lowering -S "$d/$n.s1.ll" -o "$d/$n.s2.ll" 2>"$d/$n.opt.err"
    rc=$?
    if [ $rc -eq 0 ]; then
      L=$(grep -c . "$d/$n.s2.ll")
      msg="ACCEPT($L)"
    else
      msg=$(sed -n 's/.*: cq \(.*\)$/\1/p' "$d/$n.opt.err" | head -1 | cut -c1-40)
      [ -z "$msg" ] && msg="EXIT$rc:$(head -c 40 $d/$n.opt.err | tr '\n' ' ')"
    fi
    printf ' | %-44s' "$msg"
  done
  echo
done
