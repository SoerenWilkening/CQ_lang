/* tests/calls: signal with an invalid number in a module with no errno accessor (owner 2026-11-12, clarifying
   cq-silnj): neither __errno_location nor __error present, so no EINVAL store and no accessor declared.
   clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <signal.h>
static int hits;
static void h(int s) { hits += s; }
static int cls(void (*r)(int)) { return r == SIG_ERR ? 2 : r != 0; }
int sn_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  void (*r)(int) = signal(x, h);
  return cq_measure(cls(r));
}
int sn_const(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  void (*r)(int) = signal(SIGKILL, h);
  return cq_measure(x) + cq_measure(cls(r));
}
