/* A library function called through a pointer the program takes: the address is the original library's (native) sum,
 * and the clone table's row of sum is keyed by that address, so a call with a quantum actual reaches sum's table clone
 * and a classical one through the same pointer runs native code. Every quantum value is a basis state (angle 0). */
#include <stdio.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
long evaluate(void);
long sum(const long *p, long n);
long other(const long *p, long n) { return -n; }
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
long (*volatile pick[2])(const long *, long) = {sum, other};
int main(int argc, char **argv) {
  (void)argv;
  long (*fp)(const long *, long) = pick[argc > 99];
  long n = 3;                 /* within K = 4: a quantum-bound loop runs min(K, n) trips (rule 14) */
  cq_theta(&n, 0.0);          /* quantum basis 3 */
  long q = fp(A, n);          /* indirect, quantum actual: sum's table clone through the row */
  long c = fp(A, 2);          /* indirect, classical actuals */
  printf("%ld %ld %d\n", cq_measure(q), c, fp == sum);
  return 0;
}
