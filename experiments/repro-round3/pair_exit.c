/* cq-03rdt (GSL specfunc psi_complex_rhp): a classical-bound loop whose trip calls a clone returning two values
   ({i64, i64}); both results are carried and read after the loop. The second result names the first through the
   call group's alias: recordDeferred took it for an exit rail that is no pending rail of the loop's scopes. */
typedef struct { long a, b; } pr;
__attribute__((noinline)) pr sub2(long x, long y, long k) { pr r = {x - k, y ^ k}; return r; }
long pair_exit(long x0, long y0, int n) {
  long x = x0, y = y0;
  cq_theta(&x, 0.5);
  cq_theta(&y, 0.25);
  for (int k = n & 3; k > 0; k--) {
    pr r = sub2(x, y, k);
    x = r.a;
    y = r.b;
  }
  return cq_measure(x + 3 * y);
}
