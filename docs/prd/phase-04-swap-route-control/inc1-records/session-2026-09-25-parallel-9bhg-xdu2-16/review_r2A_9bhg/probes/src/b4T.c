#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int p = q * 3; int t = m + 1; return t + cq_measure(q); }
int main(int c, char **v) { return f(atoi(v[1])); }
