#include <stdlib.h>
int G;
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); G = q; int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q) + cq_measure(G); }
