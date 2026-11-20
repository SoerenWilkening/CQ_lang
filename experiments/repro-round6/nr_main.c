/* GLPK glp_mincost_relax4 (reduced): under a quantum predicate, a call of a function that does not return (defined in
   another translation unit, so the call site has no noreturn and its result is read after it). */
int stub(int *p);
int cell;
int f(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  if (x & 1) {
    int r = stub(&cell);
    if (r == 0)
      return 7;
    return r + 1;
  }
  return 2;
}
