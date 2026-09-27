#include <stdlib.h>
static volatile int K = 5;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = (q > 3) ? K : 9; if (q > 3) cq_phi(1.0); q = cq_theta(q, .7); return cq_measure(r) + cq_measure(q); }
