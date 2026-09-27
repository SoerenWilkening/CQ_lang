#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
static const int tab[8] = {3,1,4,1,5,9,2,6};
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); _Bool b = cq_theta((_Bool)(m & 1), .5); _Bool b2 = cq_theta((_Bool)(n & 1), .4); int t = m + 1; b = cq_theta(b, .7); return t + cq_measure(b) + cq_measure(b2); }
