/* (iii) gate count of sum(A, n): n classical (3 < K, 8 > K), A holding a rail. Arrangements: the 00 clone, a
 * classical loop. All-ones (build-ref): n a seed rail, a quantum-exit K-loop (K = 4). */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
long sum(const long *p, long n);
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int main(int argc, char **argv) {
  (void)argv;
  long n = 3 + (argc > 99);
  long x = 7;
  cq_theta(&x, 0.0);
  A[2] = x;
  long s3 = sum(A, n), s8 = sum(A, n + 5);
  printf("%ld %ld\n", cq_measure(s3), cq_measure(s8));
  return 0;
}
