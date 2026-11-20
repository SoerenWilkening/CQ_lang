/* cq-rb96s (GLPK mpl_constraint_statement, reduced): a switch on a quantum value whose default an earlier switch on the
   same value excludes. -O1 keeps the default block (a call), its path predicate false: the pass asked for a flag of the
   false predicate. */
int g[4];
int hits;
__attribute__((noinline)) void fail(int line) { hits += line; }
int deadsw(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned op = x & 7;
  int k;
  switch (op) {
  case 1: k = 11; fail(1); break;
  case 2: k = 4; break;
  case 3: k = 9; fail(2); break;
  default:
    return -1;
  }
  if (x & 8) {
    switch (op) {
    case 1: g[0] = 5; break;
    case 2: g[1] = 6; break;
    case 3: g[2] = 7; break;
    default: fail(3800); break;
    }
  } else {
    switch (op) {
    case 1: g[1] = 8; break;
    case 2: g[2] = 9; break;
    default: fail(3819); break;
    }
  }
  return g[0] + g[1] + g[2] + hits + k;
}
