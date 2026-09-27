#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); if (t > 3) cq_phi(.3); return t; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); int q2 = cq_theta(m, .3); int p = q2 + 1; q2 = cq_theta(q2, .4); int s = cq_theta(p, .2); return cq_measure(s) + x; }
