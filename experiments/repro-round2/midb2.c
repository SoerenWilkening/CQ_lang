/* cq-iaz30: as midb.c, the earlier quantum exit inside a quantum arm of the trip (its test does not dominate the
   mid-trip classical bound, which still sees its flag in the linearized trip). */
int g[4];
int f(unsigned x0, double th, int n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned a = 1, b = 2;
  int i = 0;
  do {
    if ((x >> (i & 15)) & 1) {
      g[0] += 1;
      a += b;
      if ((a & 7) == 3) {
        g[2] = (int)a;
        return 99;
      }
    } else {
      g[1] += 1;
      b += 3;
    }
    i++;
  } while (i < n && ((a + b) & 7) != 5);
  g[3] = (int)b;
  return (int)(a * 16 + b);
}
