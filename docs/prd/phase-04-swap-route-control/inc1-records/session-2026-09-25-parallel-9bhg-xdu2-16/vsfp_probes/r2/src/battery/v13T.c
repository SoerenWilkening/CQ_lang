#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int q = cq_theta(m, .4); int r = q; if (b) r = cq_theta(q, .2); int t = m + 1; r = cq_theta(r, .7); return t + cq_measure(r) + cq_measure(b); }
