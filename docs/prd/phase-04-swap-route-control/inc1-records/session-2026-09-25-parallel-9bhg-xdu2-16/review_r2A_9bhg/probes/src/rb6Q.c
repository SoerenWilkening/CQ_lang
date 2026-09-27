#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int x = f(m); int q2 = cq_theta(n, .3); int r = (q2 == x) ? 1 : 2; return cq_measure(r) + cq_measure(q2); }
