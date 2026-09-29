#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); if (q > 5) { int t = h(q, m); if (t > n) cq_phi(0.4); } return cq_measure(q); }
