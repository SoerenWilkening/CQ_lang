/* cq-03rdt: the return merge's predicate (the early-return arm's flag) is read after a K-loop whose
   body branches on the same classical condition. Before the fix pred built that flag per edge at a
   join inside the loop body (a |0> seed per trip, nothing undid it) and uncompute crashed in
   cyclePoint (GSL filter/impulse, ode-initval rk2imp_apply; movstat, bspline: the same per-trip
   flag left pending at the return). */
int g[8];
static int body(long n, int use, int m) {
  if (use && m / use != n)
    return 19;
  for (long i = 0; i < n; ++i)
    if (use)
      g[i & 7] = 1;
  return 0;
}
int flag_loop(long n0, int use, int m0, double th) {
  long n = n0;
  int m = m0;
  cq_theta(&n, th);
  cq_theta(&m, th);
  return cq_measure(body(n, use, m));
}
