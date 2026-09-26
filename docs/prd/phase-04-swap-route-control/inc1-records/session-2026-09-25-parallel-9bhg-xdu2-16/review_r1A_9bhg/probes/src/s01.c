#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

__attribute__((noinline)) int fr(int m) { int q = cq_theta(m, .5); int t = h(q, m); if (m > 0) return fr(m - 1) + t; return t; }
int main(int c, char **v) { int m = atoi(v[1]); return fr(m) & 7; }
