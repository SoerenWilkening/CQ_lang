/* cq-ad51l (SQLite jsonExtractFunc, reduced): a classically bounded loop whose trip holds a quantum branch; each arm
   holds a classical branch (`p == 0`, `n == 2`) with an edge straight into the trip's join. At the real edge of one arm's
   classical branch, a linearized incoming of the join from the other arm's region holds on part of that edge's path
   only (its fact is another argument's: `p != 0`); at it, the other cases of a quantum switch are still to walk. */
int out[8], cnt;
__attribute__((noinline)) static int putA(int v) { out[cnt++ & 7] = v; return v; }
__attribute__((noinline)) static int putB(int v) { out[cnt++ & 7] = v + 1; return v; }
__attribute__((noinline)) static int putC(int v) { out[cnt++ & 7] = v + 2; return v; }
__attribute__((noinline)) static int putD(int v) { out[cnt++ & 7] = v + 3; return v; }
__attribute__((noinline)) static int putE(int v) { out[cnt++ & 7] = v + 4; return v; }
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
        v = putA(2 + *p);
      else
        v = putB(3);
    } else {
      switch ((x >> 2) & 3) {
      case 0:
        if (n == 2) {
          v = 4;
          break;
        }
        v = putC(5);
        break;
      case 1:
        v = putD(6);
        break;
      default:
        v = putE(7);
        break;
      }
    }
    s += v;
  }
  return s;
}
