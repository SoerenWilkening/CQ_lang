#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? t : 7; int u = m + 1; b = cq_theta(b, .7); return u + cq_measure(b) + cq_measure(q); }
