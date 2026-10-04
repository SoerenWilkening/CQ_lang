/* F-1 with a constant (3) trip count and a trip-dependent immediate (q ^= k). */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 int q = seed; cq_theta(&q, 0.5); int b[n]; int s = 0;
 for (int i = 0; i < n; ++i) b[i] = q;
 for (int k = 0; k < 3; ++k) { if (q > k) cq_phi(0.3); q ^= k; }
 for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
 return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
