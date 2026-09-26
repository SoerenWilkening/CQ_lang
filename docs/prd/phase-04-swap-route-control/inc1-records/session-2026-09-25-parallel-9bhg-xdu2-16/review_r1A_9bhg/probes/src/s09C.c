#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

__attribute__((noinline)) int f9(int m) { int q = cq_theta(m, .5); int s = 0; for (int i = 0; i < m; i++) s += h(q, i); return s; }
int main(int c, char **v) { int m = atoi(v[1]); return f9(m) & 7; }
