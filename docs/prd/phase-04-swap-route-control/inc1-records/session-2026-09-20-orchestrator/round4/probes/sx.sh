#!/bin/zsh
set -u
LLVM=/usr/local/opt/llvm@19/bin
WT=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a34343933d983a536
OUT=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad/out
echo "== NATIVE C caller (clang emits signext) =="
"$LLVM/clang" -O1 probes/sx_signext.c "$WT/build/runtime/libcq_templates.a" "$WT/build/runtime/libcq_runtime.a" -o "$OUT/sxc" 2>&1 | grep -v "built for newer"
"$OUT/sxc"
echo "== the PASS's declaration shape (no signext) =="
"$LLVM/clang" probes/sx_nosignext.ll "$WT/build/runtime/libcq_templates.a" "$WT/build/runtime/libcq_runtime.a" -o "$OUT/sxl" 2>&1 | grep -v "built for newer\|overriding the module\|warning generated"
"$OUT/sxl"
