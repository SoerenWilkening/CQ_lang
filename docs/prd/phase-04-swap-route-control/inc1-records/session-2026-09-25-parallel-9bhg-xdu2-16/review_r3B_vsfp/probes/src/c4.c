#include <stdlib.h>
static volatile int K = 4;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = cq_theta(m & 3, .4); int r = (q > 3) ? ((p > 1) ? K : 7) : 9; return cq_measure(r) + cq_measure(q) + cq_measure(p); }
