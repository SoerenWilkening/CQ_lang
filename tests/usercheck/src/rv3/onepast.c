/* cq-985fi: a pointer one past the end of A is also the address of B, placed after it; the read e[-1 - (k & 3)] is
   inside A and defined (LLVM: the pointer is based on A). The probe and the oracle both keep it in the domain. */
char A[4] = {1, 2, 3, 4};
char B[4] = {5, 6, 7, 8};
__attribute__((noinline)) int rdend(char *e, int k) { return e[-1 - (k & 3)] + k; }
int f(int a, int b, double t) { int q = b; cq_theta(&q, t);
  int r;
  if (q & 1) r = rdend(A + 4, q);
  else r = q * 3 + B[a & 3];
  return cq_measure(r); }
