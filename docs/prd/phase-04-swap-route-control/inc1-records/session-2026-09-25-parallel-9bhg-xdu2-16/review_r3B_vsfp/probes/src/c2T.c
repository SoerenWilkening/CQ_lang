#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = cq_theta(m & 3, .4); int r; if (q > 3) { r = (p > 1) ? 4 : 7; } else r = 9; q = cq_theta(q, .7); return cq_measure(r) + cq_measure(q) + cq_measure(p); }
