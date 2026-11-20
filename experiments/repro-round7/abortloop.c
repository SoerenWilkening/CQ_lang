/* A loop with a classical bound and a quantum abort exit (GMP's ASSERT_ALWAYS in mpn_preinv_mu_div_qr): a non-pure
   callee with classical arguments in its body runs under the trip predicate, so it is the _ctl clone. */
#include <stdlib.h>
__attribute__((noinline)) long bump(long *p) { p[0] += 1; return p[1] > 5; }
__attribute__((noinline)) long walk(long *a, int n) {
  long s = 0;
  for (int i = 0; i < n; i++) {
    long c = bump(a + i);
    if (c) abort();
    s += a[i];
  }
  return s;
}
int main(void) {
  long a[6] = {1, 2, 3, 4, 5, 6};
  unsigned char q = 0;
  cq_theta(&q, 1.5707963267948966);
  a[2] = 3 + (q & 7);
  return cq_measure((int)walk(a, 4));
}
