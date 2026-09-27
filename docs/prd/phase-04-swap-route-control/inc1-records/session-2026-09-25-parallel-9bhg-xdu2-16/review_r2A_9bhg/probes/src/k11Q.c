#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g2(int a, int b);
static const int tab[8] = {3,1,4,1,5,9,2,6};
volatile int gsink;
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .3); int a[8] = {0}; a[q2 & 7] = f(m); int r = a[n & 7]; return cq_measure(r); }
