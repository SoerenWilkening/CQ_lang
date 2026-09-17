#!/bin/bash
# matrix.sh <TAG> — run loop_twin_matrix against one of my four binaries,
# writing the verdict table with --out (the committed table is NEVER touched).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad
TAG="$1"
export CQ_LD="$W/build/tests/e2e/cq_link.sh"
python3 "$W/tools/loop_twin_matrix.py" \
  --clang /usr/local/opt/llvm@19/bin/clang \
  --opt "$S/bins/cq-opt.$TAG" \
  --plugin "$S/bins/libCQPass.$TAG.so" \
  --include "$W/include" \
  --runtime "$W/build/runtime/libcq_runtime.a" \
  --templates "$W/build/runtime/libcq_templates.a" \
  --phi-surface void \
  --out "$S/matrix.$TAG.txt" \
  --jobs 3
echo "matrix $TAG exit=$?"
