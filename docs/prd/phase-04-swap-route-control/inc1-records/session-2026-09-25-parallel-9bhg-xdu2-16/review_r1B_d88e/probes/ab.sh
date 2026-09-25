#!/bin/bash
# ab.sh : oracle-vs-subject A/B over every p/*.s1.ll, NULL CONTROL (oracle vs oracle) first.
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rB_d88e
cd "$R/p" || exit 1
n=0; d=0
for f in *.s1.ll; do n=$((n+1))
  a=$( { ../bin/cq-opt.ora -passes=cq-lowering -S "$f" -o - 2>&1; echo "rc=$?"; } | shasum | cut -c1-12)
  a2=$( { ../bin/cq-opt.ora -passes=cq-lowering -S "$f" -o - 2>&1; echo "rc=$?"; } | shasum | cut -c1-12)
  [ "$a" != "$a2" ] && { d=$((d+1)); echo "NULL-DIFF $f"; }
done
echo "NULL CONTROL: denominator=$n oracle-vs-oracle diffs=$d"
n=0; ad=0; da=0; ds=0; st=0
for f in *.s1.ll; do b=${f%.s1.ll}; n=$((n+1))
  ../bin/cq-opt.ora -passes=cq-lowering -S "$f" -o ab_o.ll 2>ab_o.err; ro=$?
  ../bin/cq-opt.subj -passes=cq-lowering -S "$f" -o ab_s.ll 2>ab_s.err; rs=$?
  if [ $ro = 0 ] && [ $rs != 0 ]; then ad=$((ad+1)); echo "A->D $b :: $(grep -o 'error: .*' ab_s.err | sed 's/.*): //')"
  elif [ $ro != 0 ] && [ $rs = 0 ]; then da=$((da+1)); echo "D->A $b"
  elif [ $ro != 0 ]; then cmp -s ab_o.err ab_s.err || { ds=$((ds+1)); echo "DIAG $b :: $(grep -o 'error: .*' ab_o.err | sed 's/.*): //') -> $(grep -o 'error: .*' ab_s.err | sed 's/.*): //')"; }
  else cmp -s ab_o.ll ab_s.ll || { st=$((st+1)); echo "STREAM $b"; }; fi
done
echo "A/B: denominator=$n A->D=$ad D->A=$da DIAG=$ds STREAM=$st"
