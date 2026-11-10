/* tests/replay probe (cq-kcn5i, arguments and pure helpers): a _ctl clone whose store is under its predicate argument
 * itself (the store marks the argument store_kept) and whose address comes from a pure helper of the module, called
 * under four predicates that are different rails and read the same for a small a. */
#include "CQ.h"
char cell[8] = {1, 2, 3, 4, 5, 6, 7, 8};
__attribute__((noinline, optnone)) char *where(void) { return cell; }
__attribute__((noinline, weak)) void put(int i, char v) {
  char *p = where();
  p[i] = (char)(p[i + 1] + v);
}
int rp_arg(int a, double th) {
  cq_theta(&a, th);
  if (a > 1)
    put(2, 5);
  if (a > 2)
    put(2, 5);
  if (a > 3)
    put(2, 5);
  if (a > 4)
    put(2, 5);
  return cq_measure(cell[2]) + cq_measure(cell[1]);
}
