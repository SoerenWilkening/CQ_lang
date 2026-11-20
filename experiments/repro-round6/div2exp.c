/* GMP __gmpz_divisible_2exp_p (reduced): a quantum branch whose one arm holds a loop with an early exit straight into
   the join (C), the other arm a value of its own for C's phi, walked after the loop's tail. */
typedef struct { int alloc, size; unsigned long *d; } mpz;
unsigned long limbs[4] = {0, 0, 5, 8};
mpz zs[2] = {{4, 3, limbs}, {4, -2, limbs + 1}};
int g(const mpz *a, unsigned long bits)
{
  unsigned long n = bits / 64;
  int size = a->size;
  unsigned long as = size < 0 ? -size : size;
  if (n >= as)
    return size == 0;
  const unsigned long *p = a->d;
  for (unsigned long i = 0; i < n; i++)
    if (p[i] != 0)
      return 0;
  return (p[n] & ((1ul << (bits % 64)) - 1)) == 0;
}
int f(unsigned k0, unsigned bits0, double th)
{
  unsigned k = k0, bits = bits0;
  cq_theta(&k, th);
  cq_theta(&bits, th);
  return g(&zs[k & 1], bits & 255);
}
