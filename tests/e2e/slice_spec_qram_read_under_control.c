/* slice_spec_qram_read_under_control.c — bd 20xt.4 Inc 2 (blocker c) e2e smoke:
 * a const-global tainted-index QROM read (`kTable[id]`) inside a Phase-6
 * SPECIALIZED callee that is called UNDER QUANTUM CONTROL (a nested tainted
 * diamond), so PredMux must prove the callee speculatable to hoist the call.
 *
 * This is the atan2l->inner-atanl payoff in isolation: `atanl` (read
 * `atanhi[id]`/`atanlo[id]`) is called inside a tainted diamond, so the
 * pending-spec pure-callee proof (`isSpeculatablePureCalleeBody`, PredMux E4)
 * must admit the QROM read to flatten the diamond + hoist the call. Inc 2
 * (blocker c) teaches `isSpeculatableDataflow` that admit via the taint-blind
 * `qromReadShapeInScope` (the SAME structural shape the emitter re-proves —
 * Rule 14). Without it the diamond declines "nested control flow under quantum
 * control"; with it the flatten hoists the call unconditional, the Phase-6
 * clone Bennett-wraps it, and the 4.4 controlled-copy merge selects the result.
 *
 * The `noinline` callee `lookup` stays outlined at -O1; the nested `if`
 * (q>5 then q>10) keeps a PredMux-claimable nested tainted region whose inner
 * arm holds the tainted-arg call. Golden = the gate trace: exactly 1 `cqrt_ry`
 * + 1 `cqrt_measure` (Rule 5), 1 `cqrt_qram_alloc_f64` (the array handle, a
 * classical resource token NEVER freed), the load rail reversed via
 * `cqrt_qram_load_f64_unc` before its free, and the flattened diamond's
 * controlled-copy / flag-strip stream. Straight-line Inc-1 clone case is
 * covered by slice_spec_qram_read.c; this adds the under-control hoist.
 */
#include "CQ.h"

/* A constant, initialised QROM table (the immutable lookup). */
static const double kTable[4] = {1.5, 2.5, 3.5, 4.5};

/* Pure-classical callee: its ONLY memory access is a const-global tainted-index
 * read — the shape blocker (c) admits into the pure-callee speculation proof. */
__attribute__((noinline)) static double lookup(double x) {
  int id = ((int)x) & 3; /* index masked in-bounds [0,3] */
  return kTable[id] + x;  /* the QROM read: kTable[id] */
}

int main(void) {
  double q = cq_theta(0.5, 0.5);
  double r = 0.0;
  if (q > 5.0) {          /* outer tainted guard */
    if (q > 10.0)         /* inner tainted guard → nested region PredMux claims */
      r = lookup(q);      /* the pending-spec call under quantum control */
    else
      r = q + 1.0;
  }
  cq_measure(r);
  return 0;
}
