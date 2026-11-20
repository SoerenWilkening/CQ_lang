/* r7 (GMP __gmpz_congruent_2exp_p as compiled, cong_fn.ll): K-loops nested in other K-loops' exit arms (tails), and a
   K-loop in a classically bounded loop's exit arm whose continuation phi has incomings from another K-loop's arm (rules 9,
   14). Driver: two mpz images and the bit count, functions of the quantum x. */
struct mpz { int alloc, size; unsigned long *d; };
unsigned long la[4], lc[4];
struct mpz A, C;
int __gmpz_congruent_2exp_p(struct mpz *, struct mpz *, unsigned long);
int f(unsigned x0, double th, unsigned long nb)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int sa = x & 3, sc = (x >> 2) & 3;
  A.size = (x >> 4) & 1 ? -sa : sa;
  C.size = (x >> 5) & 1 ? -sc : sc;
  for (int k = 0; k < 4; k++) {
    la[k] = (x >> (6 + k)) & 1 ? ~0UL : (x >> (10 + k)) & 1;
    lc[k] = (x >> (14 + k)) & 1 ? ~0UL : (x >> (18 + k)) & 1;
  }
  A.d = la;
  C.d = lc;
  return __gmpz_congruent_2exp_p(&A, &C, nb & 255);
}
