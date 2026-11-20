/* r7 (GMP __gmpn_hgcd2_jacobi, reduced): a classically bounded loop entered in the middle (goto): fix-irreducible's guard
   header is entered by a back edge from each former entry's predecessor in the cycle, several latches; they meet at one
   back-edge block before the constructions (rule 14 "Irreducible control flow"). */
int f(unsigned x0, double th, int n, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned s = 0;
  int i = 0;
  if (c)
    goto mid;
  do {
    s += x & 3;
    if (c > 5)
      s *= 3;
  mid:
    s ^= x >> (i & 7);
    i++;
  } while (i < n);
  return (int)s;
}
