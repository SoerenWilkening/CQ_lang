/* tests/calls: the errno of raise's computed failure value (owner ruling 2026-11-13, CR rule 16 Results, the signal
   table's raise): in the complement branch, EINVAL (22) through the module's errno accessor (a Darwin module's __error)
   under "sig outside [0, 64]", with the -1. clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <errno.h>
#include <signal.h>
/* a classical constant number under a quantum predicate */
int rs_const(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  int r = 5;
  if (x & 1)
    r = raise(70);
  return cq_measure(x) + cq_measure(r) + cq_measure(errno);
}
/* a classical run-time number under a quantum predicate (s ^ 70: from 64 to 78 for s in [0, 8]; r unmeasured: cq-pbpju) */
int rs_cls(int x0, int s, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  if (x & 1)
    raise(s ^ 70);
  return cq_measure(x) + cq_measure(errno);
}
/* a rail number */
int rs_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  int r = raise(x);
  return cq_measure(r) + cq_measure(errno);
}
