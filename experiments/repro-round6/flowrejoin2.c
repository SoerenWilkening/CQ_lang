/* cq-a0x8d (glpk glp_analyze_bound), with a quantum phi at S: in a quantum arm of a classically bounded trip, a quantum test under c < 0 jumps to W
   and otherwise falls into the test of c == 1, whose own quantum test jumps to W or falls to S; c == 1 false goes to S.
   The open flow (past c == 1) rejoins with the classical edge into S before W runs (rule 14 with 8, 9). */
int a[8];
int f(unsigned x0, double th, int n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int r = 0;
  for (int c = -1; c < n; c += 2) {
    int t = a[(c + 2) & 7];
    if ((x >> 6) & 1) {
      r += 1;
    } else {
      int v = t + (int)(x & 1);
      if (c < 0 && ((x >> (t & 3)) & 1))
        goto W;
      if (c == 1) {
        v = t * 3 + (int)((x >> 2) & 1);
        if ((x >> ((t + 1) & 3)) & 2)
          goto W;
      }
      a[2] += v;
      goto J;
    W:
      a[3] += 7 + t;
    J:
      r += a[c & 7];
    }
  }
  return r;
}
