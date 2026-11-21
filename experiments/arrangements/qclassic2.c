/* (ii') as qclassic.c, the calls in a static function no event precedes (rule 16: an ordinary host call). */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
long evaluate(void);
long sum(const long *p, long n);
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
__attribute__((noinline)) static long work(long n) { return evaluate() * 100 + sum(A, n); }
int main(int argc, char **argv) {
  (void)argv;
  long x = 7;
  cq_theta(&x, 0.0);
  long w = work(3 + (argc > 99));
  printf("%ld %ld\n", w, cq_measure(x + w));
  return 0;
}
