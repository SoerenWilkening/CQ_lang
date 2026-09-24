/* the ARRAY-FREE twin of p16. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 int q = cq_theta(seed, 0.5); int c = q; int s = 0; int r = cq_theta(seed, .2);
 for (int i = 0; i < n; ++i) s += cq_measure(c);
 for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
 for (int i = 0; i < n; ++i) s += cq_measure(c);
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
