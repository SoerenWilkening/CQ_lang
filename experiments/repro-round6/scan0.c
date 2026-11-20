/* GMP __gmpz_scan0 (reduced): a quantum branch whose one arm holds a K-loop (quantum exit) whose exit arm joins the
   other arm's code at a block that holds a classically bounded loop with a quantum exit; that loop runs in the K-loop's
   trips for the unit's paths (its tail), and its predicate over the function also holds the other arm's atoms. */
unsigned long limbs[6] = {0, 0xff00, ~0ul, ~0ul, 0x10000, 0};
long f(int s0, unsigned b0, double th)
{
  int s = s0;
  unsigned b = b0;
  cq_theta(&s, th);
  cq_theta(&b, th);
  unsigned long w;
  unsigned i = b & 3;
  if (s >= 0) {
    w = limbs[i];
    if (w == ~0ul) {
      do {
        i++;
        if (i == 5)
          return 320;
        w = limbs[i];
      } while (w == ~0ul);
    }
    w = ~w;
  } else {
    w = limbs[i] & (b >> 2);
    if (w == 0) {
      while (i < 4 && limbs[i + 1] == 0)
        i++;
      w = limbs[i + 1];
      if (w == 0)
        return -1;
    }
  }
  int c = 0;
  while ((w & 0xff) == 0 && c < 56) {
    w >>= 8;
    c += 8;
  }
  return i * 64 + c + (long)(w & 0xff);
}
