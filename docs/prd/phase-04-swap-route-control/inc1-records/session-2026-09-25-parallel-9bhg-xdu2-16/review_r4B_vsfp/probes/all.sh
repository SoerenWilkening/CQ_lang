#!/bin/bash
# all.sh — re-run every r4B probe (verdicts on SUBJ, NOFREE, LIFO, MAIN) and the twin pairs.
cd "$(dirname "$0")"
declare -A ARG=( [t1e]="3 4" [t1f]="3 4" [c1_stack3]="3 3" [c1_stack3T]="3 3" [c2_stackval]="3 3" [c2_stackvalT]="3 3" [c3_theta]="3 3" [c3_thetaT]="3 3" [c4_loop]="3 3" [c4_loopT]="3 3" [c5_loopval]="3 3" [t3]=1 )
for f in src/*.c src/*.ll; do n=$(basename "$f"); n=${n%.*}; a=${ARG[$n]:-5}; ./run.sh "$n" "$a"; done
echo "=== twin pairs (trace byte-diff; SUBJ/NOFREE/LIFO of the probe vs SUBJ of its twin)"
for p in u1:u1T u2:u2T u3:u3T u5:u5T u6:u6T c1_stack3:c1_stack3T c2_stackval:c2_stackvalT c3_theta:c3_thetaT c4_loop:c4_loopT c5_loopval:c4_loopT w1:w1T w2:w2T w3:w3T x1:x1T n1:n1T n2:n2T t2:t2T s2_pragma_val:s2_pragma_valT s1_pragma:s1_pragmaT; do ./pair.sh "${p%%:*}" "${p##*:}"; done
