#!/bin/bash
# one.sh <fixture.ll> — A/B one fixture. Per-file temp paths so it is safe under xargs -P.
O="$CQ_ORACLE"; SUBJ="$CQ_SUBJECT"
f="$1"; n=$(basename "$f"); t=$(mktemp -d)
"$O"    -passes=cq-lowering -S "$f" -o "$t/o.ll" 2>"$t/o.err"; orc=$?   # rc on the NEXT line, never after a pipe
"$SUBJ" -passes=cq-lowering -S "$f" -o "$t/s.ll" 2>"$t/s.err"; src=$?
# ⚠ THE PATTERN MUST COVER EVERY DIAGNOSTIC FAMILY, NOT JUST `… lowering:`.
# Rule-13 round 1 (F-6): the first spelling was `cq [a-z]* lowering: …`, which
# cannot match `cq taint escape: …`, so a decline->decline STRING MOVE in that
# family scored SAME. A harness that cannot see a class of move is not measuring
# that class — it is reporting silence about it.
omsg=$(grep -m1 -o 'error:.*' "$t/o.err" | cut -c1-90)
smsg=$(grep -m1 -o 'error:.*' "$t/s.err" | cut -c1-90)
osha=$([ $orc -eq 0 ] && shasum -a 256 "$t/o.ll" | cut -c1-16 || echo "-")
ssha=$([ $src -eq 0 ] && shasum -a 256 "$t/s.ll" | cut -c1-16 || echo "-")
verd="SAME"
[ "$orc" != "$src" ] && { [ $orc -ne 0 ] && verd="D->A" || verd="A->D"; }
[ "$verd" = SAME ] && [ $orc -ne 0 ] && [ "$omsg" != "$smsg" ] && verd="STRING"
[ "$verd" = SAME ] && [ $orc -eq 0 ] && [ "$osha" != "$ssha" ] && verd="STREAM"
printf '%s\t%s\t%s/%s\t%s\t%s\n' "$n" "$verd" "$orc" "$src" "$omsg" "$smsg"
rm -rf "$t"
