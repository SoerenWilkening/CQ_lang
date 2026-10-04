/* slice_spec_qram_read.c — bd 20xt.4 Inc 1 e2e smoke: a const-global tainted-index
 * QROM read (`tbl[id]`) inside a Phase-6 SPECIALIZED callee. The `noinline` callee
 * `lookup` stays outlined at -O1, so a tainted-arg call becomes a clone-on-taint
 * candidate whose body holds the QROM read. `scanBody` admits the gep+load shape;
 * the clone lowers it to `cqrt_qram_alloc_f64` (array-handle birth) + `cqrt_qram_load
 * _f64` (Toffoli copy-out) and the Bennett wrap reverses the load via
 * `cqrt_qram_load_f64_unc` then frees the value rail — the array handle (a classical
 * resource token) is never freed. This is the spec-callee edition of the top-level
 * Phase-7.5 QROM read, the atan2l inner-atanl `atanhi[id]`/`atanlo[id]` capability
 * in isolation (straight-line: no control, no index-select). Golden = trace byte-diff.
 */
#include "CQ.h"

/* A constant, initialised QROM table (the immutable lookup). */
static const double kTable[4] = {1.5, 2.5, 3.5, 4.5};

/* Pure-classical callee with a STRAIGHT-LINE const-global tainted-index read. */
__attribute__((noinline)) static double lookup(double x) {
  int id = ((int)x) & 3; /* index masked in-bounds [0,3] */
  return kTable[id] + x;  /* the QROM read: kTable[id] */
}

int main(void) {
  double q = 0.5; cq_theta(&q, 0.5);
  double r = lookup(q);
  cq_measure(r);
  return 0;
}
