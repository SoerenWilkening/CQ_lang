#include <stdlib.h>
int h(int a, int k);
int G(int n); int G2(int n);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int (*fp)(int) = (m > 4) ? G : G2; int q = cq_theta(m, .5); int y = fp(n); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
