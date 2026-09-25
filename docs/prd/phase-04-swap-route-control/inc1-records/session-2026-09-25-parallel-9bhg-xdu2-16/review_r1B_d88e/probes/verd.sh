#!/bin/bash
# verd.sh name... : opt-only verdict on ora and subj, and s2 identity
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rB_d88e
cd "$R/p" || exit 1
n=0
for b in "$@"; do
  b="${b%.c}"; n=$((n+1))
  [ -s "$b.s1.ll" ] || { echo "$b MISSING"; continue; }
  for t in ora subj; do
    "$R/bin/cq-opt.$t" -passes=cq-lowering -S "$b.s1.ll" -o "$b.$t.s2.ll" 2> "$b.$t.err"; rc=$?
    msg=$(grep -o 'error: .*' "$b.$t.err" | head -1 | sed 's/.*): //' | cut -c1-90)
    w=$(grep -c 'warning:' "$b.$t.err")
    eval "rc_$t=\$rc; msg_$t=\"\$msg\"; w_$t=\$w"
  done
  same=""; cmp -s "$b.ora.s2.ll" "$b.subj.s2.ll" && same="S2="
  printf '%-8s ora[rc=%s w=%s %s] subj[rc=%s w=%s %s] %s\n' "$b" "$rc_ora" "$w_ora" "$msg_ora" "$rc_subj" "$w_subj" "$msg_subj" "$same"
done
echo "denominator: $n"
