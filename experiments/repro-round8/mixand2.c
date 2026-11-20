/* r8 (GLPK _glp_spx_primal shape): a multi-exit loop whose trip branches on `q && c > 5` (rule 8: C && Q, no branch
   on C in the trip); the arm ends in a quantum exit test whose trip goes on into the join. That edge changed form under
   the isDate fix (real -> linearized): the result must stay the C program's. */
int out[4];
int f(int n, unsigned x0, double th, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned y = x;
  for (int i = 0; i < n; i++) {
    if (y == 7)
      break;
    if ((y & 1) && c > 5) {
      if (c > 8) {
        out[i & 3] = (int)y;
        y = y >> 1;
      } else {
        out[(i + 1) & 3] = (int)y;
        y = y * 3;
      }
      if (y == 9)
        break;
    }
    y = y + 5;
    if ((y & 12) == 12)
      break;
  }
  return (int)y;
}
