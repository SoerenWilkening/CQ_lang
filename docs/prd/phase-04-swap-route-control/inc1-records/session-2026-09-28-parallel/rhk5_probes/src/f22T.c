/* f22T — hand-inlined twin of f22 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int acc = 0; for (int i = 0; i < m; i++) { int p = q * 3; int u = p ^ q; int s = p + 1; if (u == 10) cq_phi(3.14159); acc += cq_measure(s); } q = cq_theta(q, .7); return acc + cq_measure(q); }
