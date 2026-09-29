#include <stdlib.h>
void g(int a);
int ext_f(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); y = cq_theta(y, .3); return cq_measure(q2) + cq_measure(q) + cq_measure(y); }
