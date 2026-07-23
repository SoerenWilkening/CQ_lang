/* slice_spec_qrom_read_arm_escape.c — bd 20xt.5.2 e2e smoke (the FINAL atan2l
 * blocker: inner-atanl clone-control). A Phase-6 SPECIALIZED callee with INTERNAL
 * tainted control — a tainted diamond whose arm reads a const-global table
 * `kTable[id]` and whose merged value ESCAPES to the callee's `ret` with NO
 * measure. This is the atanl `atanhi[id]`→fmuladd→ret shape in isolation: the
 * read's loaded value coherently escapes the clone return.
 *
 * Pre-20xt.5.2 the clone's PredMux `ClaimAll` flatten LEFT at its E4-gep gate
 * because `classifyQromReadUnderControl`'s coherent-escape no-cloning fence
 * returned `No` for the arm-resident read (its value reaches the clone's non-`main`
 * ret with no measure) — `lowerCloneControl` declined "callee contains tainted
 * control flow under quantum lift". The `inBennettClone` bypass (threaded from
 * `ClaimAll`, the sole `flattenPredMuxRegions(claimAll=true)` caller) makes the
 * read claimable: the diamond flattens, `lowerQramReads(inBennettClone=true)`
 * lowers the read (the surviving source `& 3` keeps the gep index provably
 * in-bounds), and the Bennett wrap COPIES the return out to a fresh basis rail then
 * reverses the WHOLE forward stream (the qram-load `_unc` + the index), so the
 * coherent escape is SOUND by Bennett.
 *
 * Golden = the gate trace: exactly 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), 1
 * `cqrt_qram_alloc_f64` (the array handle — a classical resource token NEVER
 * freed), the load rail reversed via `cqrt_qram_load_f64_unc` BEFORE its free (Rule
 * 8), the fp arm-merge controlled-copy stream, the copy-out, and the LIFO reverse.
 * The straight-line Inc-1 clone read is covered by slice_spec_qram_read.c and the
 * under-control HOIST by slice_spec_qram_read_under_control.c; this adds the
 * INTERNAL clone-control read whose value coherently escapes the clone ret.
 */
#include "CQ.h"

/* A constant, initialised QROM table (the immutable lookup). */
static const double kTable[4] = {1.5, 2.5, 3.5, 4.5};

/* Pure-classical callee: an INTERNAL tainted diamond whose arm reads kTable[id]
 * (a masked tainted index) and whose merged value escapes to the ret with NO
 * measure — the coherent-escape shape the clone-control lowering must reverse. */
__attribute__((noinline)) static double reduce(double x) {
  double base;
  if (x > 1.0) {                       /* internal tainted guard (diamond) */
    long id = ((long)(x * 4.0)) & 3;   /* masked tainted index, in-bounds [0,3] */
    base = kTable[id] + x;             /* the QROM read kTable[id] in the arm */
  } else {
    base = x;                          /* the no-read escape arm */
  }
  return base;                         /* coherent escape: no measure inside reduce */
}

int main(void) {
  double q = cq_theta(0.5, 0.5);
  double r = reduce(q);   /* the spec-clone whose internal read escapes to its ret */
  cq_measure(r);
  return 0;
}
