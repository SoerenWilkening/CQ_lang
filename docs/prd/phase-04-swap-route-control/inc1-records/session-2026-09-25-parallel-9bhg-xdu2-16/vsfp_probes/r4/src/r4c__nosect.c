#include <stdlib.h>
static volatile int K = 7;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); if (q > 3) (void)K; q = cq_theta(q, .7); return cq_measure(q); }
