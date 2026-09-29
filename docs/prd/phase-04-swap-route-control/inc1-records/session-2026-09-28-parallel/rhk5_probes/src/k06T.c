/* k06T — hand-inlined twin of k06 */
#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q & 3; int u = p + q; int w = q * 5; if (u == 10) cq_phi(3.14159); if (w == 15) cq_phi(0.25); int q2 = cq_theta(q, .7); int s = p + 1; return cq_measure(s) + cq_measure(q2); }
