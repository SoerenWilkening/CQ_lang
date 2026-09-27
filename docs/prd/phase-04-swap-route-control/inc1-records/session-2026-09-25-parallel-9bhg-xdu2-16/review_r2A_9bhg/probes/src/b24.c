#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p; switch (q & 3) { case 0: p = 5; break; case 1: p = 7; break; case 2: p = 11; break; default: p = 1; } int t = h(p, m); q = cq_theta(q, .7); return t + cq_measure(q); }
