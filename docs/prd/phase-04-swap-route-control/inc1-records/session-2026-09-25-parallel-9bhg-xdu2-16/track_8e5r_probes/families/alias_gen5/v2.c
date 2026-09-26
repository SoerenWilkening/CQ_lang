#include <stdlib.h>
int h(int a, int k); int k1(int a, int b); int k2(int a, int b);
static const int TB[8] = {3,1,4,1,5,9,2,6};
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q2 = cq_theta(n, .25); int q3 = cq_theta(m, .3);
  int t = f(m);
  int arr[8] = {0}; arr[q2 & 7] = 7; arr[q3 & 7] = 9; int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);
  int u = k1(t, q2); int v = k1(t + n, q3);
  return acc + cq_measure(u) + cq_measure(v) + cq_measure(q2) + cq_measure(q3); }
