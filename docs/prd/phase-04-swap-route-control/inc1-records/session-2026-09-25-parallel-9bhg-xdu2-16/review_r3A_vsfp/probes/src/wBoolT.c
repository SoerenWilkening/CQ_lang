#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool q = cq_theta((_Bool)(m & 7), .5); _Bool p = q ^ (_Bool)1; int r = m + 1; int s = (int)cq_measure(p); q = cq_theta(q, .7); return r + s + (int)cq_measure(q); }
