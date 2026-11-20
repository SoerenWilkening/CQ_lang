/* Sibling of resieve_exitvalue (cq-rb96s): two exits, a quantum one and a classical one behind a quantum branch; the
   counter and a value computed in the trip are read after the loop. */
unsigned tab[4];
unsigned out[4];
int resieve2(unsigned x0, double th, unsigned n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  tab[0] = x & 1;
  tab[1] = (x >> 1) & 1;
  tab[2] = 1;
  tab[3] = x >> 2;
  unsigned i = 0, s = 0;
  for (;;) {
    i++;
    s += tab[i & 3];
    if (tab[i & 3] & 1) {
      if (i > (n & 3))
        break;
      out[i & 3] |= i;
    } else if (tab[i & 3] == 4)
      break;
  }
  return out[1] + out[2] + i * 16 + s * 256;
}
