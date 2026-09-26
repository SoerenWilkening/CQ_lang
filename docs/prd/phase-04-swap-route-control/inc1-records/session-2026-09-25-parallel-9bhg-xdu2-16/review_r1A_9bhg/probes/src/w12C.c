#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }

static const int tab[8] = {1,2,3,4,5,6,7,8};
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int t = f(m); int q2 = cq_theta(n, .3); int r = tab[q2 & 7] + t; return cq_measure(r); }
