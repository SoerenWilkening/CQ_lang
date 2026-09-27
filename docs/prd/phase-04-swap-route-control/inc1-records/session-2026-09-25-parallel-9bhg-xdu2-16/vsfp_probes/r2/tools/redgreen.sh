#!/bin/bash
# redgreen.sh : run the bd vsfp fixture family (every fixture this branch added or
# changed) through the scratch lit site config against the ORACLE, round 1 (v5) and the
# final binary. The debugalloc driver is irrelevant to the family (no family fixture
# uses %debugalloc-cq-opt) but the site config requires one that is not older than cq-opt.
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
cd "$V" || exit 1
python3 - > family_regex.txt <<'EOF'
import pathlib
V = pathlib.Path('/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp')
names = set()
for l in (V / "st_now.txt").read_text().splitlines():
    n = l[3:].split(" -> ")[-1].replace("ir-pass/test/", "")
    if n.endswith(".ll") and l[:2] != " D":
        names.add(n)
for l in (V / "st_r1.txt").read_text().splitlines():
    n = l.replace("ir-pass/test/", "")
    if n.endswith(".ll") and (pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test") / n).exists():
        names.add(n)
print("^CQ IR-pass :: (" + "|".join(sorted(n.replace(".", "\\.") for n in names)) + ")$")
EOF
touch bin/cq-opt-debugalloc.r2g.copy 2>/dev/null
cp -f bin/cq-opt-debugalloc.N0_null bin/cq-opt-debugalloc.any
touch bin/cq-opt-debugalloc.any
RX=$(cat family_regex.txt)
for T in "main:$V/../frozen/cq-opt.main_aee8" "v5:$V/bin/cq-opt.v5" "r2g:$V/bin/cq-opt.r2g"; do
  tag=${T%%:*}; bin=${T#*:}
  VSFP_CQ_OPT="$bin" VSFP_DEBUGALLOC="$V/bin/cq-opt-debugalloc.any" lit --timeout 60 litora --filter "$RX" > "rg_$tag.log" 2>&1
  pass=$(grep -c "^PASS:" "rg_$tag.log"); fail=$(grep -c "^FAIL:\|^TIMEOUT:" "rg_$tag.log"); xf=$(grep -c "^XFAIL:" "rg_$tag.log")
  echo "$tag: PASS=$pass FAIL=$fail XFAIL=$xf"
done
