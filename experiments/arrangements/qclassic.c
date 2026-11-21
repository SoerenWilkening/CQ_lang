/* (ii) the same calls with no quantum data in memory: x is quantum but never stored. The calls stay plain C calls. */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
long evaluate(void);
long sum(const long *p, long n);
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int main(int argc, char **argv) {
  (void)argv;
  long n = 3 + (argc > 99);
  long x = 7;
  cq_theta(&x, 0.0);
  long e = evaluate();
  long s = sum(A, n);
  printf("%ld %ld %ld\n", e, s, cq_measure(x + s));
  return 0;
}
