/* tests/calls: setvbuf's -1 for a type outside {0, 1, 2} stores no errno (owner ruling 2026-11-13, as musl setvbuf.c).
   clang -O1 -S -emit-llvm -include CQ.h of this file. */
#include <errno.h>
#include <stdio.h>
int sv_rail(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  errno = 0;
  int r = setvbuf(stdout, 0, x, 0);
  return cq_measure(r) + cq_measure(errno);
}
