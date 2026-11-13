/* tests/calls: the errno of fseeko's computed failure value (owner ruling 2026-11-13, CR rule 16 Results): EINVAL (22)
   through the module's errno accessor (here a Darwin module's __error, macOS SDK <errno.h>) under "whence outside
   {0, 1, 2}", with the -1. clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <errno.h>
#include <stdio.h>
/* a classical constant whence under a quantum predicate */
int fo_const(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  int r = 5;
  if (x & 1)
    r = fseeko(stdout, 0, 7);
  return cq_measure(x) + cq_measure(r) + cq_measure(errno);
}
/* a classical run-time whence (w ^ 3: the sampler's w = 0 fails); the call an effect entry by its rail offset */
int fo_cls(int x0, int w, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  int r = fseeko(stdout, x, w ^ 3);
  return cq_measure(r) + cq_measure(errno);
}
/* a rail whence */
int fo_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  int r = fseeko(stdout, 0, x);
  return cq_measure(r) + cq_measure(errno);
}
/* the result unread: the store all the same */
int fo_unread(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  fseeko(stdout, 0, x);
  return cq_measure(errno);
}
