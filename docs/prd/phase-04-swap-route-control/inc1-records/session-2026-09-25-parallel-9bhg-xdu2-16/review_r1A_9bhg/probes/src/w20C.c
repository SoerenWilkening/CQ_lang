#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int t = f(m); int q2 = cq_theta(n, .3); int r = (t > 3) ? q2 : q2 + 1; return cq_measure(r); }
