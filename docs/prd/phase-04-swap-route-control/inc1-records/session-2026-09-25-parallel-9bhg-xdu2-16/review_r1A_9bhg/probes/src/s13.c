#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

__attribute__((noinline)) int f13(int m) { int q = cq_theta(m, .5); int t = h(q, m); int u = h(q, t); return u; }
int main(int c, char **v) { int m = atoi(v[1]); return f13(m) & 7; }
