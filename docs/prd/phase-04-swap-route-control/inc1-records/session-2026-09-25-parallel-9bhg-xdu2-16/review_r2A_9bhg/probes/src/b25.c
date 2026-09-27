#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .3); int p = (q2 > 3) ? 9 : 4; int t = h(p, m); q2 = cq_theta(q2, .7); return t + cq_measure(q2) + cq_measure(q); }
