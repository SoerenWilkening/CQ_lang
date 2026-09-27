#include <stdlib.h>
static volatile int K = 0;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = (q > 3) ? K : 0; q = cq_theta(q, .7); return r + cq_measure(q); }
