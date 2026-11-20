/* cq-iaz30 (GSL gsl_min_find_bracket): a classically bounded loop (case 3) whose classical bound `i < n` is tested in a
   block before the latch's quantum test, with an earlier quantum exit whose arm keeps a store (one exit hub). */
int g[4];
int f(unsigned x0, double th, int n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned a = 1, b = 2;
  int i = 0;
  do {
    if (((x >> (i & 15)) & 6) == 6) {
      g[2] = (int)a;
      return 99;
    }
    if ((x >> (i & 15)) & 1) {
      g[0] += 1;
      a += b;
    } else {
      g[1] += 1;
      b += 3;
    }
    i++;
  } while (i < n && ((a + b) & 7) != 5);
  g[3] = (int)b;
  return (int)(a * 16 + b);
}
