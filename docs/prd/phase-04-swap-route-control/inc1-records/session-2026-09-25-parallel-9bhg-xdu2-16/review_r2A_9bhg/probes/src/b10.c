#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b + 1; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
