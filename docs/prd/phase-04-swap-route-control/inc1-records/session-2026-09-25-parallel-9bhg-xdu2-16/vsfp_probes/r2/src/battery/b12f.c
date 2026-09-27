#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
static const int tab[8] = {3,1,4,1,5,9,2,6};
__attribute__((noinline)) int f(int m, int n) { int q = cq_theta(m, .5); int p = q > 3; int t = h(p, m); q = cq_theta(q, .7); return t + cq_measure(q); }
int main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }
