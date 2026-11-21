/* --cq-check case: declared-clone calls in several arrangements; the checker's stand-in models the library. */
long sum_to(const long *a, long n);
long axpb(long a, long x, long b);
long mix7(const long *p, long n, long step, double w, double c, int neg, const long *q);

long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
long B[8] = {1, 1, 1, 1, 1, 1, 1, 1};

long use(long x0, long n0, double th) {
  long x = x0, n = n0 & 7;
  cq_theta(&x, th);
  long r = sum_to(A, n) + axpb(x, 2, n) + axpb(3, n, 1);   /* 00, 100, 000 */
  long s = mix7(A, n, 1, 1.0, 0.5, 0, B) + mix7(A, x & 7, 1, 1.0, 0.5, 0, B);   /* no class, integer class */
  if (x > 3)
    r += axpb(n, n, 2);   /* under a quantum predicate: 000_t_ctl */
  return cq_measure(r + s);
}
