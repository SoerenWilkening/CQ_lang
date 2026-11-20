/* r8 (GMP __gmpn_hgcd2_jacobi): two irreducible Euclid loops; the second is entered at either half from the two exit
   arms of the first. After fix-irreducible the second loop's guard header is entered from two blocks of the first loop's
   exit arm with different classical starts: its header phis are their merge (rules 9, 14). */
unsigned f(unsigned x0, double th, unsigned a, unsigned b)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned ah, bh;
  a = a % 4096 + 1;
  b = b % 4096 + 1;
  if (a < b) goto subB;
  for (;;) {
    if (a < 4) { ah = a * 3; bh = b; goto subA_s; }
    a = a % b;
    x += a;
    if (a == 0) goto done;
  subB:
    if (b < 4) { ah = a; bh = b * 5; goto subB_s; }
    b = b % a;
    x ^= b;
    if (b == 0) goto done;
  }
  for (;;) {
  subA_s:
    if (ah < 3) goto done;
    x += ah;
    ah = ah / 3;
  subB_s:
    if (bh < 2) goto done;
    x ^= bh;
    bh = bh / 2;
  }
done:
  return x + a + b;
}
