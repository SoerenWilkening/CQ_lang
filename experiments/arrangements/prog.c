/* Calls of the library's functions in several arrangements. Every quantum value is a basis state (angle 0), so the
 * measured outcomes are the C program's values, which main prints. Built natively (-DNATIVE) the same program prints
 * the reference. */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif   /* otherwise cqcc includes CQ.h */

long sum_to(const long *a, long n);
long axpb(long a, long x, long b);
long mix7(const long *p, long n, long step, double w, double c, int neg, const long *q);

long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
long B[8] = {1, 1, 1, 1, 1, 1, 1, 1};

int main(int argc, char **argv) {
  (void)argv;
  long n = 5 + (argc > 99);     /* classical, not a constant */
  long x = 7, w2 = 3;
  double w = 2.0;
  cq_theta(&x, 0.0);            /* quantum basis 7 */
  cq_theta(&w2, 0.0);           /* quantum basis 3 */
  cq_theta(&w, 0.0);            /* quantum basis 2.0 */
  long r1 = sum_to(A, n);              /* 00: all classical */
  long r2 = sum_to(A, w2);             /* 01: quantum bound, classical pointer */
  long r3 = axpb(x, 2, 1);             /* 100 */
  long r4 = axpb(3, x, w2);            /* 011 */
  long r5 = mix7(A, n, 1, 1.0, 0.5, 0, B);   /* no class quantum */
  long r6 = mix7(A, n, 1, w, 0.5, 1, B);     /* fp class quantum */
  long r7 = mix7(A, w2, 1, 1.0, 0.0, 0, B);  /* integer class quantum */
  printf("%ld %ld %ld %ld %ld %ld %ld\n", cq_measure(r1), cq_measure(r2), cq_measure(r3), cq_measure(r4),
         cq_measure(r5), cq_measure(r6), cq_measure(r7));
  return 0;
}
