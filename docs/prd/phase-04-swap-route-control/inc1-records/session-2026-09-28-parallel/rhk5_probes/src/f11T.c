/* f11T — hand-inlined twin of f11 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); short q = cq_theta((short)(m & 7), .5); short p = q * 3; short u = p ^ q; int s = q + 1; if (u == 10) cq_phi(3.14159); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q); }
