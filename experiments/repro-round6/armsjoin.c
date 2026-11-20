/* cq-a0x8d (glpk _glp_wclique, glp_analyze_coef): in a classically bounded trip, both arms of a classical branch hold a
   quantum branch whose edges meet at W before the arms' classical join: the arms' flows join first (rule 14 with 8, 9). */
int a[8];
int f(unsigned x0, double th, int n, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  for (int i = 0; i < n; i++) {
    if (c == i)
      continue;
    if (c > i) {
      if ((x >> (i & 7)) & 1)
        goto W;
    } else {
      if ((x >> ((i + 3) & 7)) & 2)
        goto W;
    }
    continue;
  W:
    a[i & 7] += i + 1;
  }
  return a[0] + 2 * a[1] + 3 * a[2] + 5 * a[3];
}
