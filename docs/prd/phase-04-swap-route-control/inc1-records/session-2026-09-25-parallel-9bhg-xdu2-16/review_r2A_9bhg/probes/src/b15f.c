#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
static const int tab[8] = {3,1,4,1,5,9,2,6};
__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
int main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }
