/* cq-ad51l (SQLite jsonExtractFunc, reduced): a classically bounded loop whose trip holds a quantum branch; each arm
   holds a classical branch (`p == 0`, `n == 2`) with an edge straight into the trip's join. At the real edge of one arm's
   classical branch, a linearized incoming of the join from the other arm's region holds on part of that edge's path
   only (its own classical fact is another argument's). */
int out[8], cnt;
__attribute__((noinline)) static int put(int v)
{
  out[cnt++ & 7] = v;
  return v;
}
int f(int *p, int n, unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int s = 0;
  for (int i = 1; i < n; i++) {
    int v;
    if ((x >> i) & 1) {
      if (p == 0)
        v = 1;
      else if (x & 8)
        v = put(2 + *p);
      else
        v = put(3);
    } else {
      if (n == 2)
        v = 4;
      else if (x & 4)
        v = put(5);
      else
        v = put(6);
    }
    s += v;
  }
  return s;
}
