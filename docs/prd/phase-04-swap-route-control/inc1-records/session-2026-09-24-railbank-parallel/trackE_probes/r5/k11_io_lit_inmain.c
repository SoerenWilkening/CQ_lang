#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) { int m = atoi(argv[1]), n = atoi(argv[2]);
  int q2 = cq_theta(0, .5); int q = cq_theta(m, .5); int v = 3;
  if (q > 5) { printf("%d", q); v = 7; }
  int a = 7; if ((q2 > 1) & (v * m == n)) a += 3;
  return cq_measure(a) + cq_measure(q2); }
