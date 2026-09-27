#include <stdlib.h>
int K(int x);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = m + 1; q = cq_theta(q, .7); return u + cq_measure(q) + 0 * r; }
