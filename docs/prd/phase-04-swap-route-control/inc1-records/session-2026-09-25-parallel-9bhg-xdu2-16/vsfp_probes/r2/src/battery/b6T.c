#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t; }
int main(int c, char **v) { int m = atoi(v[1]); int q2 = cq_theta(m, .3); int p2 = q2 + 2; int u = f(m) + 1; int r = cq_theta(q2, .9); return u + cq_measure(r); }
