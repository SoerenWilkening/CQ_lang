/* f23T — hand-inlined twin of f23 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int acc = 0; for (int i = 0; i < m; i++) { int s = p + 1; acc += cq_measure(s); } int u = p ^ q; if (u == 10) cq_phi(3.14159); q = cq_theta(q, .7); return acc + cq_measure(q); }
