#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

int G(int m);
__attribute__((noinline)) int F(int m) { int q = cq_theta(m, .5); int t = h(q, m); if (m > 0) return G(m - 1) + t; return t; }
__attribute__((noinline)) int G(int m) { return F(m) * 2; }
int main(int c, char **v) { int m = atoi(v[1]); return G(m) & 7; }
