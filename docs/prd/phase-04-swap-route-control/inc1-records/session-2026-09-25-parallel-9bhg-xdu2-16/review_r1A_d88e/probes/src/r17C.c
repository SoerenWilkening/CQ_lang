#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) void f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); int z = cq_measure(r); (void)z; } int main(int c, char **v) { int m = atoi(v[1]); f(m); return 0; }
