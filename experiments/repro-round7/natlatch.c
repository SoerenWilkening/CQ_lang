/* r7 (GMP __gmpn_hgcd2_jacobi, reduced): a classically bounded loop entered in the middle (goto): fix-irreducible's guard
   header is entered by a back edge from each former entry's predecessor in the cycle, several latches (rule 14). */
int f(unsigned x0, double th, int n, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned s = 0;
  int i = 0;
  for (;;) {
    s += x & 3;
    i++;
    if (i >= n)
      break;
    s ^= x >> (i & 7);
    i++;
    if (i >= n)
      break;
  }
  return (int)s;
}

