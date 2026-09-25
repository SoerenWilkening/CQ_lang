#include <stdlib.h>

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; int r = t; if (m > 3) r = cq_theta(t, .2); return t * 3 + cq_measure(r); }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) + 1; }
