#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
static const int tab[8] = {3,1,4,1,5,9,2,6};
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); long p = (long)q << 2; int t = h((int)p, m); q = cq_theta(q, .7); return t + cq_measure(q); }
