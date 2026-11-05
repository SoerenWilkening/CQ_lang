/* tests/spine probe (CR rule 21): the integer compare of addresses, a pointer merge under a quantum flag, ptrtoint and
 * inttoptr as identities, null as the literal 0. */
#include <stdint.h>
int A = 1, B = 2;
int ptr_ops(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  int *p = x > 0 ? &A : &B;
  int same = p == &A;
  int nul = p == 0;
  uintptr_t u = (uintptr_t)p;
  int *q = (int *)(u & ~(uintptr_t)0);
  int v = *q;
  return cq_measure(v + same + nul);
}
