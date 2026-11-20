/* GMP __gmpz_divisible_2exp_p (reduced): a quantum branch whose one arm holds a loop with an early exit straight into
   the join, the other arm a value of its own for the join's phi. */
unsigned long limbs[4] = {0, 0, 5, 8};
int f(int size0, unsigned bits0, double th)
{
  int size = size0;
  unsigned bits = bits0;
  cq_theta(&size, th);
  cq_theta(&bits, th);
  unsigned n = bits >> 2;
  unsigned a = size < 0 ? -size : size;
  if (__builtin_expect(n >= a, 1))
    return size == 0;
  for (unsigned i = 0; i < n; i++)
    if (limbs[i & 3] != 0)
      return 0;
  return (limbs[n & 3] & ((1ul << (bits & 3)) - 1)) == 0;
}
