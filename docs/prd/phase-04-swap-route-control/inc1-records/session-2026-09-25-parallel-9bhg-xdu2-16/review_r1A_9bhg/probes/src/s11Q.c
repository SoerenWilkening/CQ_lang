#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

__attribute__((noinline)) int g(int a) { int (*volatile fp)(int) = f; return a + fp(3); }
int main(int c, char **v) { int n = atoi(v[2]); int q2 = cq_theta(n, .3); int u = g(q2); return cq_measure(u); }
