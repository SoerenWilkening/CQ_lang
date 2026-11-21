/* (i) quantum data in memory, every actual classical: evaluate() and sum(A, n) take the v / 00 clones. Every quantum
 * value is a basis state (angle 0), so the measured outcomes are the C program's. -DNATIVE: the reference. */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
extern long G[4];
long evaluate(void);
long sum(const long *p, long n);
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int main(int argc, char **argv) {
  (void)argv;
  long n = 3 + (argc > 99), m = 8 + (argc > 99);
  long x = 7;
  cq_theta(&x, 0.0);
  A[2] = x;          /* a rail stored into the program's array */
  G[1] = x + 1;      /* and into the library's global */
  long e = evaluate();
  long s3 = sum(A, n), s8 = sum(A, m);
  printf("%ld %ld %ld\n", cq_measure(e), cq_measure(s3), cq_measure(s8));
  return 0;
}
