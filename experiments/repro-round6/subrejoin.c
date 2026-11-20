/* cq-a0x8d (gmp __gmpn_brootinv): in a classically bounded trip, a quantum arm holds a classically bounded sub-loop whose exit
   edge enters the latch block straight, and the other quantum arm has code still to walk: the sub-loop's real edge into the
   join ends in a rejoin block (rule 14 with rules 8, 9). */
int a[8];
int f(unsigned x0, double th, int n, int m)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int acc = 0;
  for (int i = n; i > 0; i--) {
    int k = a[i & 7] + 1;
    if ((x >> (i & 7)) & 1) {
      int j = m;
      do { a[j & 7] ^= j + k; } while (--j > 0);
    } else {
      a[(k + 1) & 7] += 3;
    }
    acc += a[i & 3];
  }
  return acc + a[1];
}
