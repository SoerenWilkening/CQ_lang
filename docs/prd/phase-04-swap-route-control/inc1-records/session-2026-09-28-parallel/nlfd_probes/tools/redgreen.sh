#!/bin/bash
# redgreen.sh <cq-opt> <cq-opt-debugalloc> <filter-regex>
#   Runs this worktree's lit fixtures (ir-pass/test) through a SCRATCH site config whose
#   %cq-opt / %debugalloc-cq-opt are the given binaries (e.g. the frozen ORACLE), so a new
#   fixture's RED on the oracle is measured with the fixture's own RUN lines.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
B=$1; DA=$2; F=$3
S=$SP/nlfd/litsite_$(basename "$B"); mkdir -p "$S"
cat > "$S/lit.site.cfg.py" <<EOF
import lit.llvm
config.cq_opt = "$B"
config.cq_opt_debugalloc = "$DA"
config.cq_pass_plugin = "$W/build/ir-pass/libCQPass.so"
config.filecheck = "/usr/local/opt/llvm@19/bin/FileCheck"
config.llvm_tools_dir = "/usr/local/opt/llvm@19/bin"
config.test_exec_root = "$S/out"
lit_config.load_config(config, "$W/ir-pass/test/lit.cfg.py")
EOF
lit -j4 -v "$S" --filter "$F" 2>&1 | grep -E "^(PASS|FAIL|XFAIL|UNRESOLVED)|Total|Passed|Failed"
