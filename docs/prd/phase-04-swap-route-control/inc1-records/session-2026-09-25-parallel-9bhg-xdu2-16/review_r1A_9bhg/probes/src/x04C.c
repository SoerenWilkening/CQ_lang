#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = t; for (int i = 0; i < m; i++) r = r * 3 + 1; return r; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) * 2; }
