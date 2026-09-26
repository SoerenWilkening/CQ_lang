#include <stdlib.h>
int h(int a, int k); int hz(int a, int k); int g(int a); int k1(int a, int b);

int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  
  int arr[8] = {0}; arr[q2 & 7] = 7; arr[q & 7] = 9; int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);
  
  int u = k1(m, q); int v = k1(n, q2);
  int t9 = hz(q, m); int w9 = g(t9); acc += w9;
  return acc + cq_measure(u) + cq_measure(v) + cq_measure(q2) + cq_measure(q); }
