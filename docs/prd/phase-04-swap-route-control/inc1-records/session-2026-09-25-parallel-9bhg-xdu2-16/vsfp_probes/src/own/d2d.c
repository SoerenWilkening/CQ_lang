#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) void sink(int x) { (void)x; }
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = q + 5; int r = cq_theta(u, .2); return cq_measure(r) + (t > 1000); }
