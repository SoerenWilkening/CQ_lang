#include <stdlib.h>

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; int u = t * 3; int r = t; if (m > 3) r = cq_theta(t, .2); int s = cq_measure(r); return u + s; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
