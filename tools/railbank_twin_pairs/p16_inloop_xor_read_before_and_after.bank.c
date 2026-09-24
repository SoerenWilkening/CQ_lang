/* F-1: the bank read before AND after the in-place xor loop; must DECLINE. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 int q = cq_theta(seed, 0.5); int b[n]; int s = 0; int r = cq_theta(seed, .2);
 for (int i = 0; i < n; ++i) b[i] = q;
 for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
 for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
 for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
