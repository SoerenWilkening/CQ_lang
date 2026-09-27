#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int x = cq_theta(m & 7, .5); int r = b ? x : 7; int t = m + 1; if (r == 5) cq_phi(3.14159); x = cq_theta(x, .3); return t + cq_measure(x) + cq_measure(b); }
