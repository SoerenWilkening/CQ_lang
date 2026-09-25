#include <stdlib.h>
__attribute__((noinline)) int f1(int m) { int q = cq_theta(m, .5); int t = m + 1; int r = t; if (m > 3) r = cq_theta(t, .2); return cq_measure(r); }
__attribute__((noinline)) int f2(int m) { int a = cq_theta(m, .3); int r = m; if (m > 2) r = cq_theta(a, .4) + 0; int b = cq_theta(m + 1, .1); if (m > 6) r = b; return cq_measure(r); }
int main(int c, char **v) { int m = atoi(v[1]); return f1(m) + f2(m); }
