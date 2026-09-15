/* slice_loop_pairing_rootmint.c — bd `test_C_libtooling-tu9q` (2026-09-15), THE
   IN-LOOP PAIRING, in its cleanest form: a bounded loop with NO TAINTED CONTROL
   FLOW AT ALL whose body mints a per-trip `cq_template_lshr_i32_hl` rail — a
   which-path copy of the loop-INVARIANT register `y` — and whose `y` is then
   RE-ROTATED after the loop and measured.

   On the pre-tu9q compiler this program was a LOUD DECLINE (bd
   `test_C_libtooling-s82e`, owner ruling D4: rolled emitted 10 trace lines against
   this file's hand-unrolled twin's 14, the four missing being
   `cq_template_lshr_i32_hl_unc` + `cqrt_free` twice, so the tensored
   `cqrt_ry_i32(h0, 0.9)` acted on a DECOHERED mixture where the twin acted on the
   pure state — different unitaries, `CLAUDE.md` Rule 8).

   `lowerLoops` now offers the loop `markIfRailLocal` on the ROOT MINT `y`, the
   spine discharges the rail IN-BODY once per trip, and this file's trace is
   BYTE-IDENTICAL to `slice_loop_pairing_rootmint_unrolled.c`'s — which is what
   `e2e-loop-pairing-rootmint-twin-identical` gates.

   ⚠ THE ORDER IS THE RULE-6 ARGUMENT: `_unc` FIRST (the adjoint returns the rail
   to |0>), `cqrt_free` SECOND. Freeing before the adjoint would be the hidden
   measurement that collapses `y`. The measured `and` rail and `y` itself are
   never freed at all. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
