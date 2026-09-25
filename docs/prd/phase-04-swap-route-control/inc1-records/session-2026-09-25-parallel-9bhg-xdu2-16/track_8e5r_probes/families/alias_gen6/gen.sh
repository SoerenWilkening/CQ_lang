#!/bin/bash
cd "$(dirname "$0")"
EXTRA=( "__attribute__((noinline)) int f(int m) { int q9 = cq_theta(m, .5); return hz(q9, m); }|acc += f(n);"
        "__attribute__((noinline)) int f(int m) { int q9 = cq_theta(m, .5); return h(q9, m); }|acc += f(n);"
        "|int t9 = hz(q, m); int w9 = g(t9); acc += w9;"
        "|int t9 = h(q, m); int w9 = g(t9); acc += w9;"
        "|int t9 = hz(q2, n); acc += g(t9);" )
POS=( 0 1 2 )
i=0
for e in "${!EXTRA[@]}"; do for p in "${POS[@]}"; do
  i=$((i+1)); n=w$i
  DEF="${EXTRA[$e]%%|*}"; USE="${EXTRA[$e]#*|}"
  A=""; B=""; C=""
  case $p in 0) A="$USE";; 1) B="$USE";; 2) C="$USE";; esac
  cat > $n.c <<EOF
#include <stdlib.h>
int h(int a, int k); int hz(int a, int k); int g(int a); int k1(int a, int b);
$DEF
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  $A
  int arr[8] = {0}; arr[q2 & 7] = 7; arr[q & 7] = 9; int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);
  $B
  int u = k1(m, q); int v = k1(n, q2);
  $C
  return acc + cq_measure(u) + cq_measure(v) + cq_measure(q2) + cq_measure(q); }
EOF
done; done; echo "generated $i"
