#!/bin/bash
# probe.sh <probe.c> [ORACLE|SUBJECT]  -- the PROTOCOL per-probe pipeline, full output.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/Projects/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc
f="$1"; which="${2:-SUBJECT}"
if [ "$which" = "ORACLE" ]; then B="$ORC"; else B="$SUBJ"; fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
name=$(basename "$f" .c)
echo "################ $name  [$which  $(shasum -a 256 "$B/build/ir-pass/cq-opt" | cut -c1-16)] ################"
"$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>"$T/c.err" \
  || { echo "CLANG FAILED"; cat "$T/c.err"; exit 1; }
"$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" \
    -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>"$T/opt.err"
rc=$?
echo "opt exit=$rc"
echo "--- stderr ($(wc -c < "$T/opt.err" | tr -d ' ') bytes) ---"
cat "$T/opt.err"
if [ $rc -ne 0 ]; then echo "=== DECLINED ==="; exit 0; fi
echo "--- stage 2b (STRICT) ---"
python3 "$SUBJ/tools/free_pairing_check.py" "$T/s2.ll" 2>&1 | tail -6
echo "--- link + run ---"
"$LLVM/clang" "$T/s2.ll" "$B/build/runtime/libcq_templates.a" "$B/build/runtime/libcq_runtime.a" -o "$T/a" 2>/dev/null \
  && "$T/a" > "$T/trace.txt" 2>&1 && { echo "TRACE LINES: $(wc -l < "$T/trace.txt" | tr -d ' ')"; cat "$T/trace.txt"; } \
  || echo "LINK/RUN FAILED"
echo "--- gate-symbol MULTISET (symbol names only, sorted) ---"
sed 's/(.*//' "$T/trace.txt" 2>/dev/null | sort | uniq -c | sed 's/^ *//'
echo "--- _unc / free census in lowered IR ---"
echo "cq_template_*_unc calls: $(grep -cE 'call .*@cq_template_[a-z0-9_]*_unc' "$T/s2.ll")"
echo "cqrt_free calls:         $(grep -cE 'call .*@cqrt_free' "$T/s2.ll")"
