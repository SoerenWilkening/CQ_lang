/* Sibling of resieve_exitvalue (cq-rb96s): a do-while whose only exit is a classical test two quantum branches deep,
   each branch holding a store (so -O1 keeps them branches); a carried (non-affine) value and the counter are read after
   the loop. */
unsigned tab[4];
unsigned out[4];
int resieve3(unsigned x0, double th, unsigned n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  tab[0] = x & 1;
  tab[1] = (x >> 1) & 3;
  tab[2] = 3;
  tab[3] = x >> 2;
  unsigned i = 0, h = 1;
  do {
    i++;
    h = h * 3 + i;
    if (tab[i & 3] & 1) {
      out[0] += i;
      if (tab[i & 3] & 2) {
        out[i & 3] ^= h;
        if (i >= (n & 7))
          break;
      }
    }
  } while (1);
  return h + i * 1000 + out[0] + out[1] + out[2] + out[3];
}
