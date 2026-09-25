#!/bin/bash
L=/usr/local/opt/llvm@19/bin
cd "$(dirname "$0")"
$L/clang -O1 -emit-llvm -S lib.c -o lib.ll
PRE=( "int r0 = TB[q2 & 7]; acc += cq_measure(r0);" "int arr[8] = {0}; arr[q2 & 7] = 7; int r1 = arr[q & 7]; acc += cq_measure(r1);" "int arr[8] = {0}; arr[q2 & 7] = 7; arr[q & 7] = 9; int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);" "int r0 = TB[q2 & 7]; int r4 = TB[q & 7]; acc += cq_measure(r0) + cq_measure(r4);" )
CAL=( k1 k2 k3 k4 )
i=0
for p in "${!PRE[@]}"; do for c1 in "${CAL[@]}"; do for c2 in "${CAL[@]}"; do for ord in 0 1; do
  i=$((i+1)); n=k$i
  if [ $ord = 0 ]; then BODY="${PRE[$p]}
  int u = $c1(m, q); int v = $c2(n, q2);"; else BODY="int u = $c1(m, q);
  ${PRE[$p]}
  int v = $c2(n, q2);"; fi
  cat > $n.c <<EOF
#include <stdlib.h>
int k1(int a, int b); int k2(int a, int b); int k3(int a, int b); int k4(int a, int b);
static const int TB[8] = {3,1,4,1,5,9,2,6};
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  $BODY
  return acc + u + v + cq_measure(q2) + cq_measure(q); }
EOF
done; done; done; done; echo "generated $i"
