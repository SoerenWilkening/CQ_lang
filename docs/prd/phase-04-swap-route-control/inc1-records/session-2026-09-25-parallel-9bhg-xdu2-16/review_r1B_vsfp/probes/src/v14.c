#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int r = 3; if (b) r = cq_theta(3, .2); int t = h(r, m); r = cq_theta(r, .7); return t + cq_measure(r) + cq_measure(b); }
