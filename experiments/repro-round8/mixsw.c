/* r8 (SQLite isDate, reduced): a classically bounded loop whose trip switches on a quantum value. One case tests
   `q || i > 1` (a mixed condition rule 8 keeps as one flag: no classical conjunct to factor out) and then runs a
   quantum branch whose arms meet at the switch's join; the cases before it in the source run inner loops, which the
   trip walks after it. The `i <= 1` conjunct of that arm's predicate opens no classical region: its edge into the
   join is linearized, and the open flow goes on into the inner loops' cases. */
int out[4];
int f(int n, unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int r = 0;
  for (int i = 1; i < n; i++) {
    switch ((x >> i) & 3) {
    case 1: {
      int k = 0;
      while (k < 4 && ((x >> k) & 1))
        k++;
      r += k;
      break;
    }
    case 2: {
      int k = 0;
      while (k < 3 && ((x >> (k + 2)) & 1))
        k++;
      r ^= k;
      break;
    }
    case 0:
      if (((x >> 5) & 1) || i > 1)
        break;
      if (out[x & 3] & 1)
        out[x & 3] &= ~1;
      break;
    default:
      r += 1;
    }
  }
  return r;
}
