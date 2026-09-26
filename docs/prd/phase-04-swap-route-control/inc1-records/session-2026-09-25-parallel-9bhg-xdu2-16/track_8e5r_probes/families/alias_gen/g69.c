#include <stdlib.h>
int gx(int a, int b); int gy(int a, int b); int gz(int a, int b); int gc(int a, int b); int gk(int a, int b); int gm(int a, int b);
static const int TB[8] = {3,1,4,1,5,9,2,6};
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int acc = 0;
  int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int r0 = TB[q2 & 7]; acc += cq_measure(r0);
  int u = gm(m, q); int v = gz(n, q2);
  return acc + cq_measure(u) + cq_measure(v) + cq_measure(q2); }
