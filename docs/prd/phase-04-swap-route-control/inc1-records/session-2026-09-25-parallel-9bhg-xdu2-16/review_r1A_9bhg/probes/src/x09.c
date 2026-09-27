#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); if (t > 3) cq_phi(0.3); return t; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) * 2; }
