/* tests/calls: signal's EINVAL through a Darwin module's errno accessor (owner 2026-11-12, clarifying cq-silnj). Built
   the Darwin way: <errno.h> of the macOS SDK makes errno (*__error()), declared, no __errno_location. An invalid sig
   stores EINVAL (22) through __error() under not v. clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <errno.h>
#include <signal.h>
static int hits;
static void h(int s) { hits += s; }
static int cls(void (*r)(int)) { return r == SIG_ERR ? 2 : r != 0; }
/* a classical invalid constant */
int se_const(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  void (*r)(int) = signal(SIGKILL, h);
  return cq_measure(x) + cq_measure(cls(r)) + cq_measure(errno);
}
/* a rail number: EINVAL under not v */
int se_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  void (*r)(int) = signal(x, h);
  return cq_measure(cls(r)) + cq_measure(errno);
}
