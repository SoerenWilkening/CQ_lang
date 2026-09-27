#!/bin/bash
# redgreen3.sh : the round-3 fixture family (every fixture round 3 added or changed, from
# st_r5.txt) through the scratch lit site config against the ORACLE, round 1, round 2 and
# the round-3 subject. Prints PASS/FAIL per binary with the denominator, then per file.
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
cd "$V" || exit 1
RX=$(python3 -c "
import re
n=[l[3:].replace('ir-pass/test/','').strip() for l in open('st_r5.txt') if l.strip()]
print('^CQ IR-pass :: (' + '|'.join(re.escape(x) for x in sorted(n)) + ')\$')")
cp -f bin/cq-opt-debugalloc.N0_null bin/cq-opt-debugalloc.any
touch bin/cq-opt-debugalloc.any
for T in "main:$V/../frozen/cq-opt.main_aee8" "v5:$V/bin/cq-opt.v5" "r2g:$V/bin/cq-opt.r2g" "r3a:$V/bin/cq-opt.r3a" "r4keep:$V/bin/cq-opt.r4keep" "${SUBJ:-r5a}:$V/bin/cq-opt.${SUBJ:-r5a}"; do
  tag=${T%%:*}; bin=${T#*:}
  DA="$V/bin/cq-opt-debugalloc.$tag"; [ -f "$DA" ] || DA="$V/bin/cq-opt-debugalloc.any"  # main/v5/r2g: round-3 objects (u2's nofree RUN then measures round 3, noted)
  touch "$DA"
  VSFP_CQ_OPT="$bin" VSFP_DEBUGALLOC="$DA" lit --timeout 60 litora --filter "$RX" > "rg5_$tag.log" 2>&1
  pass=$(grep -c "^PASS:" "rg5_$tag.log"); fail=$(grep -c "^FAIL:\|^TIMEOUT:" "rg5_$tag.log")
  echo "$tag: PASS=$pass FAIL=$fail of $(grep -c . st_r5.txt)"
done
for f in $(python3 -c "print(' '.join(l[3:].replace('ir-pass/test/','').strip() for l in open('st_r5.txt') if l.strip()))"); do
  row="$f"
  for tag in main v5 r2g r3a r4keep ${SUBJ:-r5a}; do
    if grep -q "^PASS: CQ IR-pass :: $f " "rg5_$tag.log"; then row="$row $tag=G"; else row="$row $tag=R"; fi
  done
  echo "$row"
done
