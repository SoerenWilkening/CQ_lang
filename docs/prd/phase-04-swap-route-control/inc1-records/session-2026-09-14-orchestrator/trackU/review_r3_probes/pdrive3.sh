#!/bin/bash
# $1 = probe stem (expects <stem>_u.ll and <stem>_z.ll here)
# Prints the three verdicts:  O_u (oracle/undef)  S_u (subject/undef)  O_z (oracle/zero twin)
# and the EQUALITY the rule claims:  S_u == O_z.
D=$(cd "$(dirname "$0")" && pwd)
O=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
S=/Users/sorenwilkening/Desktop/CQ_undef/build/ir-pass/cq-opt
T=$(mktemp -d)
for f in "$D/$1_u.ll" "$D/$1_z.ll"; do
  [ -s "$f" ] || { echo "FATAL: $f missing or ZERO BYTES (passthrough trap)"; exit 2; }
done
run() { "$1" -passes=cq-lowering -S "$2" -o "$3.ll" 2>"$3.err"; echo $? > "$3.rc"; }
run "$O" "$D/$1_u.ll" "$T/Ou"
run "$S" "$D/$1_u.ll" "$T/Su"
run "$O" "$D/$1_z.ll" "$T/Oz"
strip() { sed -e '/^; ModuleID/d' -e '/^source_filename/d' "$1" 2>/dev/null; }
say() { local t=$1; local rc=$(cat $T/$t.rc)
  if [ "$rc" != 0 ]; then printf '  %-4s exit %-3s DECLINE : %s\n' "$t" "$rc" "$(grep -o 'cq [a-z].*' $T/$t.err | head -1)"
  else printf '  %-4s exit %-3s ACCEPT  : %s gate line(s)\n' "$t" "$rc" "$(grep -cE 'call .*@(cqrt_|cq_template_)' $T/$t.ll)"; fi; }
echo "### $1"
say Ou; say Su; say Oz
if [ "$(cat $T/Su.rc)" != "$(cat $T/Oz.rc)" ]; then echo "  >>> S_u != O_z  (EXIT CODE DIFFERS)  <<<"
elif [ "$(cat $T/Su.rc)" != 0 ]; then
  if diff -q $T/Su.err $T/Oz.err >/dev/null; then echo "  S_u == O_z  (identical decline)"; else echo "  >>> S_u != O_z  (DECLINE MESSAGE DIFFERS) <<<"; diff $T/Su.err $T/Oz.err | head -6; fi
else
  if diff -q <(strip $T/Su.ll) <(strip $T/Oz.ll) >/dev/null; then echo "  S_u == O_z  (byte-identical IR)"
  else echo "  >>> S_u != O_z  (IR DIFFERS) <<<"; diff <(strip $T/Su.ll) <(strip $T/Oz.ll) | head -25; fi
fi
echo "  --- SUBJECT emitted stream (Rule 2: read the stream, not the exit code) ---"
grep -oE 'call [^@]*@(cqrt_|cq_template_)[a-zA-Z0-9_]*\([^)]*\)' $T/Su.ll 2>/dev/null | sed 's/^/    /'
[ -n "$KEEP" ] && cp -f $T/* "$D/out_$1_" 2>/dev/null
echo "$T" > /tmp/last_pdrive3
