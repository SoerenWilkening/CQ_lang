#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = q + 5; int w = t + 1; int r = cq_theta(u, .2); return cq_measure(r) + cq_measure(w); }
