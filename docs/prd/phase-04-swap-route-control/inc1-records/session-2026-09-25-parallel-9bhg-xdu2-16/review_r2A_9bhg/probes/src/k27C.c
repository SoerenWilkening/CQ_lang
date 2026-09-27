#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g2(int a, int b);
static const int tab[8] = {3,1,4,1,5,9,2,6};
volatile int gsink;
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .3); int x = f(m); int y = f(m + 1); if (q2 > 3 && x > y) cq_phi(.3); return cq_measure(q2); }
