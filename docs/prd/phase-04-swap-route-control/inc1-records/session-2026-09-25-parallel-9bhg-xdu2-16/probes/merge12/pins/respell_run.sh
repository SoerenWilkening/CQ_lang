#!/bin/bash
cd "$(dirname "$0")"
python3 - <<'EOF'
def edit(src, dst, old, new):
    s = open(src).read()
    assert s.count(old) == 1, (src, s.count(old))
    open(dst, "w").write(s.replace(old, new))
read_fp = ("  %vsfp.c = fcmp oeq x86_fp80 %0, 0xK00000000000000000000   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)\n"
           "  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join\nvsfp.arm:\n  br label %vsfp.join\nvsfp.join:\n")
edit("FA_F80.s1.ll", "FA_F80r.s1.ll",
     "@hfl(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #2 {\n  %3 = fadd",
     "@hfl(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #2 {\n" + read_fp + "  %3 = fadd")
read_i = ("  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)\n"
          "  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join\nvsfp.arm:\n  br label %vsfp.join\nvsfp.join:\n")
edit("R6.s1.ll", "R6r.s1.ll",
     "@h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {\n  %3 = add",
     "@h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {\n" + read_i + "  %3 = add")
print("edited")
EOF
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
for m in FA_F80 FA_F80r FAT_F80 R6 R6r R6T; do
  for t in m12 main_c113 final; do
    CQ_DEADARG_DBG=1 "$S/frozen/cq-opt.$t" -passes=cq-lowering -S "$m.s1.ll" -o "$m.$t.s2.ll" 2> "$m.$t.err"
    rc=$?
    printf '%-8s %-10s rc=%s drops=%s %s\n' "$m" "$t" "$rc" "$(grep -c CQ_DEADARG "$m.$t.err")" "$(grep -o 'error: .*' "$m.$t.err" | head -1 | cut -c1-100)"
  done
done
