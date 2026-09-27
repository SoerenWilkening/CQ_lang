#!/bin/bash
L=/usr/local/opt/llvm@19/bin; W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cd "$(dirname "$0")"
$L/clang -O1 -emit-llvm -S lib.c -o lib.ll
PRE=( "if (q2 > 3) cq_phi(3.14159);" "int r0 = TB[q2 & 7]; acc += cq_measure(r0);" "int arr[8] = {0}; arr[q2 & 7] = 7; int r1 = arr[q & 7]; acc += cq_measure(r1);" "int r2 = q2; if (q > 3) r2 = q2 + 5; acc += cq_measure(r2);" "int r3 = q > 2 ? q2 + 1 : q2; acc += cq_measure(r3);" "if (q2 == 5) cq_phi(1.0); if (q2 < 2) cq_phi(0.5);" )
CAL=( gx gy gz gc gk gm )
i=0
for p in "${!PRE[@]}"; do for c1 in "${CAL[@]}"; do for c2 in "${CAL[@]}"; do
  i=$((i+1)); n=g$i
  cat > $n.c <<EOF
#include <stdlib.h>
int gx(int a, int b); int gy(int a, int b); int gz(int a, int b); int gc(int a, int b); int gk(int a, int b); int gm(int a, int b);
static const int TB[8] = {3,1,4,1,5,9,2,6};
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  ${PRE[$p]}
  int u = $c1(m, q); int v = $c2(n, q2);
  return acc + cq_measure(u) + cq_measure(v) + cq_measure(q2); }
EOF
done; done; done; echo "generated $i"
ls g*.c | xargs -P6 -I{} bash -c 'b=$(basename {} .c); '$L'/clang -I'$W'/include -include CQ.h -O1 -emit-llvm -S {} -o $b.caller.ll 2>/dev/null && '$L'/llvm-link -S $b.caller.ll lib.ll -o $b.s1.ll'
echo "s1: $(ls g*.s1.ll | wc -l)"; for f in g*.s1.ll; do [ -s $f ] || echo "EMPTY $f"; done
