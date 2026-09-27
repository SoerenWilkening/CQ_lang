#include <stdlib.h>
static volatile int K = 0;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); _Bool b = q > 3; int r = b ? K : 0; int mb = cq_measure(b); q = cq_theta(q, .7); return r + mb + cq_measure(q); }
