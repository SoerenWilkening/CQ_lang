#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h2(q, m); }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); int q2 = cq_theta(m, .3); int p = q2 + 1; q2 = cq_theta(q2, .4); int s = cq_theta(p, .2); return cq_measure(s) + x; }
