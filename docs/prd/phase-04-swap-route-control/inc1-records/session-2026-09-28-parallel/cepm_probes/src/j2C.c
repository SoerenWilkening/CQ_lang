#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; u = cq_theta(u, .3); return cq_measure(u); }
