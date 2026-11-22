#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// cq-us8cz (CR rules 8, 16): a quantum test's one arm holds a classical test whose one side is a dead end (abort) and
// whose other side mints the value the join reads; TinyEMU i440fx_read_data's shape. Walker::next (dead ends first)
// went from the abort straight to the join, skipping the live side, and the join's merge arm was read where it was
// not minted: an internal error at pred's joinAbove.
int f(int a, int c) {
  cq_theta(&a, 1.0);
  int r = 0;
  if (!(a & 1)) {
    if (c == 3) abort();
    r = a * 5 + 7;
  }
  return cq_measure(r);
}
