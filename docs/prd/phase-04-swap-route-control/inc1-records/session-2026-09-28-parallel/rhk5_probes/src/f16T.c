/* f16T — hand-inlined twin of f16 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); static const int T[8] = {3, 1, 4, 1, 5, 9, 2, 6}; int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = T[q & 7]; if (u == 10) cq_phi(3.14159); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q); }
