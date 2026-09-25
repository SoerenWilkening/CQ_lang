#include <stdlib.h>
int k1(int a, int b); int k2(int a, int b); int k3(int a, int b); int k4(int a, int b);
static const int TB[8] = {3,1,4,1,5,9,2,6};
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int u = k2(m, q);
  int arr[8] = {0}; arr[q2 & 7] = 7; arr[q & 7] = 9; int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);
  int v = k1(n, q2);
  return acc + u + v + cq_measure(q2) + cq_measure(q); }
