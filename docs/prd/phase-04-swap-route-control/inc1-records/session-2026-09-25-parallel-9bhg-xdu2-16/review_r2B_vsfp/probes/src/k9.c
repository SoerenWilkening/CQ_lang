#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int r = h(p, m); int u = p + 1; b = cq_theta(b, .7); return r + cq_measure(u) + cq_measure(b); }
