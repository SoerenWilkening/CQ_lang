#include <stdlib.h>
int h(int a, int b, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); int t = h(q, p, m); p = cq_theta(p, .4); return cq_measure(q) + cq_measure(p); }
