/* mpn_div_q reached with classical sizes and pointers, a quantum limb in memory (its in-place entry). */
typedef unsigned long limb;
void __gmpn_div_q(limb *qp, const limb *np, long nn, const limb *dp, long dn, limb *scratch);
int main(void) {
  limb n[6] = {5, 6, 7, 8, 9, 10}, d[3] = {3, 0, 1}, q[6] = {0}, s[64] = {0};
  unsigned char x = 0;
  cq_theta(&x, 1.5707963267948966);
  n[0] = x & 7;
  __gmpn_div_q(q, n, 6, d, 3, s);
  return cq_measure((int)q[0]);
}
