#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int p = q * 3; int t = h(p, m); if (t > 3) q = cq_theta(q, .2); return cq_measure(q); }
