#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int q = cq_theta(m & 7, .5); int x = q; if (b) { x = q * 3; volatile int z = x; } q = cq_theta(q, .7); return cq_measure(q) + cq_measure(b) + (x > 100); }
