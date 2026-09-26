#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); _Bool b = q > 3; int r = 0; int mb = cq_measure(b); q = cq_theta(q, .7); return r + mb + cq_measure(q); }
