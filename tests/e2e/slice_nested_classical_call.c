/* dm7f.16.1: real -O1 nested classical classifier in main and a lifted body.
   Each basis x selects x-y for x>y && y>3, x+y for x>y && y<=3, else y.
   The classifier stays a call. Copy merges preserve x; clone scratch is
   cleared by the mechanically mirrored phase-free gate stream before free.
   Runtime y exercises both classical branches; traces witness gate/ABI/link
   behavior and complement the independent analytic edge-transfer review. */
#include "CQ.h"
#include <stdlib.h>

__attribute__((noinline)) int classify(double y) { return y > 3.0; }

__attribute__((noinline)) double nested(double x, double y) {
  if (x > y) {
    if (classify(y)) return x - y;
    return x + y;
  }
  return y;
}

__attribute__((noinline)) double direct(double x, double y) {
  cq_theta(&x, 0.5);
  double r = y;
  if (x > y) {
    if (classify(y)) r = x - y;
    else r = x + y;
  }
  return cq_measure(r);
}

__attribute__((noinline)) double lifted(double x, double y) {
  cq_theta(&x, 0.5);
  return cq_measure(nested(x, y));
}

int main(int argc, char **argv) {
  double x = argc > 1 ? strtod(argv[1], 0) : 7.0;
  double y = argc > 2 ? strtod(argv[2], 0) : 4.0;
  (void)direct(x, y);
  (void)lifted(x, y);
  (void)lifted(x, y - 2.0);
  return 0;
}
