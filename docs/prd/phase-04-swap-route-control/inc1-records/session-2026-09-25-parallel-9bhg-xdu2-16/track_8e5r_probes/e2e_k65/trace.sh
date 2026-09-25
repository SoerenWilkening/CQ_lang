#!/bin/bash
# trace.sh <bin> <mode> <tag> — stage 2 + 2b + link + run for the e2e k65 probe.
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
D=$(cd "$(dirname "$0")" && pwd)
cd "$D"
b=$1; mode=$2; tag=$3
if [ "$mode" = system ]; then env -u CQ_OPT_DEBUG_ALLOC "$b" -passes=cq-lowering -S combined.ll -o "$tag.s2.ll"
else CQ_OPT_DEBUG_ALLOC=$mode "$b" -passes=cq-lowering -S combined.ll -o "$tag.s2.ll"; fi
echo "opt rc=$?"
python3 "$W/tools/free_pairing_check.py" "$tag.s2.ll" | tail -2
"$L/clang" "$tag.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$tag.exe" 2>/dev/null
./"$tag.exe" > "$tag.trace"; echo "run rc=$? lines=$(wc -l < "$tag.trace")"
