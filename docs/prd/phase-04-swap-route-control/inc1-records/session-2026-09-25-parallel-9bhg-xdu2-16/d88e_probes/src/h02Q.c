#include <stdlib.h>
int h(int a, int k);

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int x = m; if (t > 3) x = m + 5; int r = t; if (m > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(x); }
