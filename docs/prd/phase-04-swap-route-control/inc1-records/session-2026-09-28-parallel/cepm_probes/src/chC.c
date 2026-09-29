#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t1 = h(q, m); int t2 = h(q, t1); if (t2 > n) q = cq_theta(q, .2); return cq_measure(q); }
