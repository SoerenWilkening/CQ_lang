/* tests/calls: signal with an invalid number (rule 16; owner 2026-11-12, cq-silnj). Valid: 1 <= sig <= 64 and none of
   9, 19, 32, 33, 34; invalid: SIG_ERR, no load and no store, EINVAL at __errno_location() (defined here as a lifted musl
   body defines it). clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <signal.h>
static int hits, err;
int *__errno_location(void) { return &err; }
static void h(int s) { hits += s; }
static int cls(void (*r)(int)) { return r == SIG_ERR ? 2 : r != 0; }
/* a classical invalid constant: SIG_ERR, errno EINVAL */
int sv_const(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  void (*r)(int) = signal(SIGKILL, h);
  return cq_measure(x) + cq_measure(cls(r)) + cq_measure(*__errno_location());
}
/* a classical number known only at run time */
int sv_runtime(int k, int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  void (*r)(int) = signal(k, h);
  return cq_measure(x) + cq_measure(cls(r)) + cq_measure(*__errno_location());
}
/* a rail number, valid and invalid, the result read and errno read after */
int sv_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  void (*r)(int) = signal(x, h);
  return cq_measure(cls(r)) + cq_measure(*__errno_location());
}
/* a rail number under a quantum predicate */
int sv_rail_pred(int x0, double th, int k) {
  int x = x0, c = 0;
  cq_theta(&x, th);
  if (x > k)
    c = cls(signal(x & 63, h));
  return cq_measure(c) + cq_measure(*__errno_location());
}
