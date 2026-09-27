#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return cq_measure(t) + cq_measure(b); }
