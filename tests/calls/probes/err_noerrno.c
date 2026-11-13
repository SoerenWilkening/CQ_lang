/* tests/calls: fseek and raise with a failing argument in a module with no errno accessor (owner ruling 2026-11-13): no
   EINVAL store and no accessor declared. clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <signal.h>
#include <stdio.h>
int ne_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  int r = fseek(stdout, 0, x);
  int s = raise(x);
  return cq_measure(r) + cq_measure(s);
}
