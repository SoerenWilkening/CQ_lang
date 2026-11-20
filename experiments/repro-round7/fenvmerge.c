/* Attempted reduction of __gmpn_div_q's fenv merge: classical double compares (GMP's mu-vs-dc threshold) in arms of
   quantum branches on limbs, with in-place callees between them. */
__attribute__((noinline)) long dc(long *q, long *n, long nn) { q[0] = n[0] + nn; return q[0] > 4; }
__attribute__((noinline)) long mu(long *q, long *n, long nn) { q[0] = n[0] - nn; return q[0] < 2; }
__attribute__((noinline)) void divq(long *q, long *n, long nn, long dn) {
  if (n[1] > 3) {
    if ((double)dn * 3600.0 + (double)nn * 200.0 > (double)nn * (double)dn)
      dc(q, n, nn);
    else
      mu(q, n, nn);
  } else if (n[0] > 1) {
    if ((double)dn * 3600.0 + (double)nn * 200.0 > (double)nn * (double)dn)
      dc(q, n, dn);
    else
      mu(q, n, dn);
  }
}
int main(void) {
  long n[4] = {1, 2, 3, 4}, q[4] = {0};
  unsigned char x = 0;
  cq_theta(&x, 1.5707963267948966);
  n[0] = x & 3;
  n[1] = (x >> 2) & 7;
  divq(q, n, 3, 2);
  return cq_measure((int)q[0]);
}
