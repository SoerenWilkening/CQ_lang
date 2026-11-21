/* Gate counts of calls whose loop bound is classical. sum_to(A, n): every actual classical. horner(x, n): x quantum,
 * n classical (n = 3 < K and n = 6 > K). All-ones: n is a seed rail and each loop a quantum-exit K-loop (K = 4: 6 trips
 * are cut to 4, a different value); arrangements: masks 00 and 10, classical loops. */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif

long sum_to(const long *a, long n);
long horner(long x, long n);

long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};

int main(int argc, char **argv) {
  (void)argv;
  long n = 4 + (argc > 99);
  long x = 7;
  cq_theta(&x, 0.0);
  long r = x;
  long h3 = horner(x, n - 1);
  long h6 = 0;
  printf("%ld %ld %ld\n", cq_measure(r), cq_measure(h3), cq_measure(h6));
  return 0;
}
