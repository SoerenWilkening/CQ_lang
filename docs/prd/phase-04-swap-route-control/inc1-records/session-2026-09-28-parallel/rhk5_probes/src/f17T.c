/* f17T — hand-inlined twin of f17 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = (q * 5 + 3) ^ 6; if (u == 10) cq_phi(3.14159); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q); }
