/* slice_measure_classical_only.c — bd test_C_libtooling-21mg: the PURELY CLASSICAL
   corner, and the only slice in this directory whose golden is EMPTY.

   No `cq_theta` anywhere, so nothing in the program is quantum — but the module is
   NOT a pass passthrough: `taint.MeasureCalls` is non-empty, so
   `CQLoweringPass::run`'s early-out does not fire and `lowerMeasures` does the
   work. Every `cq_measure` here is a measure of a classical value (a constant, an
   argument-derived sum, an fp product, a `select`) and lowers to that value.

   WHAT THE EMPTY GOLDEN WITNESSES: ZERO trace lines means zero `cqrt_*` calls were
   emitted — no `cqrt_measure_<W>`, and above all NO `cqrt_alloc_<W>`. Minting a
   rail for a value the taint analysis says is classical is the f64/angle
   miscompile family (Rule 3 / Key Prohibitions), and `@f_double` below is its f64
   member: an `fmul double` whose result is classical must not become
   `cqrt_alloc_f64`. This is also the layer that proves the classical path needs NO
   new runtime symbol — the program LINKS against both archives and references
   nothing from either (Rule 2).

   On `main` e96f89c / 86c0d25 every one of these four calls declined
   `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle`.

   lit twin: `lowering_measure_classical_accept.ll`. */
#include "CQ.h"

static int f_ssa(int n) { int a = n + 3; return cq_measure(a); }
static double f_double(double x) { double y = x * 2.0; return cq_measure(y); }
static int f_select(int n) { int a = n > 2 ? 9 : 1; return cq_measure(a); }

int slice(void) {
    bool b = 0;
    int s = cq_measure(b) + f_ssa(4) + f_select(5) + (int) f_double(1.5);
    return s;
}

int main(void) {
    (void) slice();
    return 0;
}
