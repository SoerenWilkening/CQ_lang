/* the ARRAY-FREE twin of p15. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 int q = cq_theta(seed, 0.5); int c = q; int s = 0;
 for (int k = 0; k < 3; ++k) { if (q > k) cq_phi(0.3); q ^= k; }
 for (int i = 0; i < n; ++i) s += cq_measure(c);
 return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
