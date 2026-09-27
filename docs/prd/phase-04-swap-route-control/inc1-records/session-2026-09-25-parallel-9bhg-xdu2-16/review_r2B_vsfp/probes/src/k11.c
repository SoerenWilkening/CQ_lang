#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int r = h(p, m); int s = h(p, r); q = cq_theta(q, .7); return s + cq_measure(q); }
