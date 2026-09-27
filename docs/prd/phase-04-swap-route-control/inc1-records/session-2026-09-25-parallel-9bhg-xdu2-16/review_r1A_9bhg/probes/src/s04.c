#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

__attribute__((noinline)) int f4(int m, int n) { int q = cq_theta(m, .5); int q2 = cq_theta(n, .5); int t = h(q, m); return (q2 > 3) ? t : q2; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); return f4(m, n) & 7; }
