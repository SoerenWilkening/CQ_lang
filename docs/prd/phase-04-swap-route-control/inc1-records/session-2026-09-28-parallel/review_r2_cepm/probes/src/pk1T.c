#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y, z; if (q > 5) { cq_phi(0.2); y = n; z = m; } else { cq_phi(0.3); cq_phi(0.1); y = m; z = n; } g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q) + z; }
