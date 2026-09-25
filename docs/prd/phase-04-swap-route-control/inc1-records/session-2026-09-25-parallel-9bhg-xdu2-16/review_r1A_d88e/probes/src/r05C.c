#include <stdlib.h>
int h(int a, int k); int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t1 = h(q, m); int t2 = g(t1, m); int r = t2; if (m > 3) r = cq_theta(t2, .2); return cq_measure(r); }
