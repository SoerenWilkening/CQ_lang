/* cq-a0x8d (gmp __gmpn_mu_bdiv_q, __gmpn_mu_bdiv_qr): in a classically bounded trip, a K-loop under a quantum test exits
   into a join that a classical skip also enters (a real edge, so the K-unit ends in a real branch) with a literal on its
   exit edge: the unit's edge carries a seed of the literal and the select over the quantum test's other edge (rules 7, 9). */
long a[16];
int f(unsigned x0, double th, int n, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int s = 0;
  for (int i = 0; i < n; i++) {
    int t = s;
    if (c != i) {
      t = s + ((x >> (i & 7)) & 3);
      if (t == 2) {
        long *p = &a[i & 7];
        long v;
        do {
          v = *p + 1;
          *p++ = v;
        } while (v == 0);
        t = 1;
      }
    }
    s = t + (int)a[(i + 1) & 7];
  }
  return s;
}
