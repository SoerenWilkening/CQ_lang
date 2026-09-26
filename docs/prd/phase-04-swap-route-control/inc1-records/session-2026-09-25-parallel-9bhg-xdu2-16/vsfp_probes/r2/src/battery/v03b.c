#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b + 1; int p2 = cq_theta(p, .3); int t = h(p2, m); b = cq_theta(b, .7); return t + cq_measure(b); }
