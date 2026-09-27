#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); _Bool b = cq_theta((_Bool)(n & 1), .5); int p = b ? 9 : 4; int t = m + 1; int u = t + 1; b = cq_theta(b, .7); return u + cq_measure(b) + cq_measure(q); }
