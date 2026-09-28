#include <stdlib.h>
int h(int a, int k);
extern int G;
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q) + cq_measure(G); }
