#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = cq_theta(q, .7); return t + cq_measure(r); }
int main(int c, char **v) { return f(atoi(v[1])); }
