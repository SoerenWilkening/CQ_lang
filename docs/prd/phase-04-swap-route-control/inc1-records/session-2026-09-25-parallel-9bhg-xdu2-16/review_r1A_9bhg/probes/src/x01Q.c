#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);

static const int tab[8] = {3,1,4,1,5,9,2,6};
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return tab[t & 7]; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) * 2; }
