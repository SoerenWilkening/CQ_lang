#include <stdlib.h>
int h(int a, int k);

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t * 3; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }
