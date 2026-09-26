#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);

__attribute__((noinline)) int f(int m, int n) { int q = cq_theta(m, .5); int t = h(q, m); int r = n; if (q > 3) r = n + 1; return t + r; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); return f(m, n) * 2; }
