/* --cq-check case (a): every listed call has classical actuals and nothing stores a rail, so each stays the C call
 * (rule 16: an ordinary host call, or under the quantum predicate an effect entry). */
long sum_to(const long *a, long n);
long axpb(long a, long x, long b);
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
long use2(long x0, long n0, double th) {
  long x = x0, n = n0 & 7;
  cq_theta(&x, th);
  long r = sum_to(A, n) + axpb(3, n, 1);
  if (x > 3)
    r += axpb(n, n, 2);
  return cq_measure(r + x);
}
