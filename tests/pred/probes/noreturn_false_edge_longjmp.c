#include "CQ.h"
#include <setjmp.h>
// USERCHECK f
// cq-172vi: an unpaired longjmp on a compare's false edge (rules 16, 24): nothing here pairs it with a setjmp.
jmp_buf env;
int f(int a) {
  cq_theta(&a, 1.0);
  if (a & 2) longjmp(env, 1);
  return cq_measure(a);
}
