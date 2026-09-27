#!/bin/bash
cd "$(dirname "$0")"
python3 - <<'EOF'
s = open("FA_F80.s1.ll").read()
old = "@hfl(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #2 {\n  %3 = fadd"
assert s.count(old) == 1
new = ("@hfl(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #2 {\n"
       "  %vsfp.i = bitcast x86_fp80 %0 to i80   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)\n"
       "  %vsfp.c = icmp eq i80 %vsfp.i, 0\n"
       "  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join\nvsfp.arm:\n  br label %vsfp.join\nvsfp.join:\n"
       "  %3 = fadd")
open("FA_F80s.s1.ll", "w").write(s.replace(old, new))
EOF
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
for t in m12 main_c113 final; do
  CQ_DEADARG_DBG=1 "$S/frozen/cq-opt.$t" -passes=cq-lowering -S FA_F80s.s1.ll -o "FA_F80s.$t.s2.ll" 2> "FA_F80s.$t.err"
  rc=$?
  printf 'FA_F80s %-10s rc=%s drops=%s %s\n' "$t" "$rc" "$(grep -c CQ_DEADARG "FA_F80s.$t.err")" "$(grep -o 'error: .*' "FA_F80s.$t.err" | head -1 | cut -c1-140)"
done
