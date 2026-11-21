#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
long vsum(long k, long n, ...);
int main(int argc, char **argv) {
  (void)argv;
  long k = 10, n = 3 + (argc > 99), x = 4;
  cq_theta(&x, 0.0);
  long r = vsum(k, n, 1L, 2L, x);   /* fixed actuals classical, a variadic rail: the all-ones 110_t (rule 27) */
  printf("%ld\n", cq_measure(r));
  return 0;
}
