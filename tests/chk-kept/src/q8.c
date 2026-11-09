/* tests/chk-kept (CR rule 20 Allocation, §6 item 1, cq-0ldab): fill allocates a block whose size is a rail with no
 * bound, so the allocation is made at K2 bytes and its overflow predicate n > K2 is kept. It stores to memory, so its
 * call stays in the arm, which the C program does not take on most inputs: the circuit runs the _ctl clone under the
 * arm flag, and the clone's n > K2 stays live at exit where the C program never allocated. The angle is a nonzero
 * literal, so the register is in no known basis state. */
#include <stdlib.h>
unsigned char *sink;
__attribute__((noinline)) int fill(unsigned n) {
  unsigned char *p = malloc(n);
  p[0] = (unsigned char)n;
  sink = p;
  return p[0];
}
int q8(int x0) {
  int x = x0;
  cq_theta(&x, 0.5);
  int r = 1;
  if ((unsigned)x >= 0xfffffff0u)
    r = fill((unsigned)x);
  return cq_measure(r);
}
