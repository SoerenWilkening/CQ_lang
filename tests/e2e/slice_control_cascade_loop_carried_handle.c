/* slice_control_cascade_loop_carried_handle.c — bd `test_C_libtooling-zujr`,
 * THE LOOP-CARRIED HANDLE VARIABLE, and this file is the E4 RECORD OF RECORD for
 * the increment: it is `example/grover/grover_oracle_uncompute.c` IN ITS LOOP
 * FORM, verbatim, minus the comments.
 *
 * WHAT IT IS. `a` is a register that CROSSES THE BACK EDGE **and** is RE-MINTED
 * EVERY TRIP — the third kind of loop-carried register, beside (b)/(b') the rail
 * that crosses in place and (c) the iteration-local rail.  `clang -O1`
 * if-converts `if (b0[i]) a -= 3;` into a 4.4 DATA SELECT, whose emitter mints a
 * FRESH `%out = cqrt_alloc_i32(0)` per activation, so `a`'s header phi is
 *
 *     %a = phi i32 [ 5, %entry ], [ %out, %latch ]
 *
 * — a phi of two HANDLES under the loop's own CLASSICAL exit test.  Exactly one
 * incoming is live per trip and WHICH one is a classical fact, so this is a
 * handle VARIABLE, not the no-cloning data mux `declineClassicalMuxes` refuses.
 * The owner's ruling of 2026-09-17: *"the runtime needs nothing — a handle is an
 * `i32` and a loop-carried `i32` is ordinary classical data"*.
 *
 * THE ONE THING THE MODULE WAS MISSING is the TRIP-1 REGISTER: the entry
 * incoming is the literal `5`, so trip 1 would pass a classical literal into a
 * gate slot that wants a handle.  `promoteLoopCarriedHandleSeeds` materialises
 * `cqrt_alloc_i32(5)` in the PREHEADER — line 1 of the golden, and the owner's
 * ruling (1).  The FLAT twin already does exactly this, as the
 * `cqrt_alloc_i32(5)` copy source inside its trip-1 mux.
 *
 * READ THE GOLDEN BY THESE INVARIANTS:
 *   * `h0`/`h5`/`h10` are the SUCCESSIVE REGISTERS `a` names.  Each is read only
 *     as a compare operand, as an `add` operand and as the SOURCE of a
 *     `cqrt_copy_i32_controlled` — never `cqrt_x`-bracketed, never freed.
 *   * every `cqrt_x` sits on the ancilla `h4`/`h9`/`h14`, whose `x ^ x = 0`
 *     return makes its `cqrt_free` a proven-|0> one; so does every `h1`/`h6`/`h11`
 *     compare flag, stripped by its own `_unc` before its free.
 *   * `h2`/`h7`/`h12` are the bank rails `b0[0..2]`, parked in the `bool b0[3]`
 *     rail bank (bd `xdu2`) and measured at the end.
 *   * `h3`/`h8`/`h13` are the arm's `a - 3` chain rails, LEFT ALLOCATED — the
 *     3qlq Inc-2 PRD §0 E1 policy.
 *   * ⚠ PARITY WITH THE FLAT TWIN NO LONGER HOLDS (bd r2j3.32, measured
 *     2026-10-15). This form leaves 6 rails undischarged (`h0`, `h3`, `h5`,
 *     `h8`, `h10`, `h13`); the flat twin now 4, because it REVERSES its trip-1
 *     and trip-2 `a`-mux rails after the last trip, while here `h5`/`h10` stay
 *     allocated: each is the next trip's copy source, so its reversal is LIFO
 *     ACROSS trips (a post-loop reverse loop, not yet emitted). See the twin's
 *     header. Before r2j3.32 both forms left 6.
 *
 * ⚠ THIS GOLDEN IS 50 LINES AND ITS HAND-UNROLLED TWIN IS 55 (45 before bd
 * r2j3.32, whose ten extra lines are the reversal above). The fold half IS THE
 * OWNER'S RULING (2), NOT A DEFECT: `clang -O1` stamps `llvm.loop.unroll.disable`
 * and does not peel, so the rolled form emits a REAL compare + strip on EVERY
 * trip, while `-O1` folds the flat twin's trip-1 compare to `true` (`a = 5`) and
 * its trip-2 compare to `!b0[0]` (which it spells by additivity,
 * `ry(h5,.5); ry_controlled(h0,h5,-.5)`).  SAME UNITARY, DIFFERENT BYTES — trip 1
 * fires `Ry(.5)` controlled on a flag that is |1> deterministically, which IS the
 * twin's unconditional `Ry(.5)`.  Byte-identity is an INSTRUMENT here, not the
 * target; the witness is that per-trip argument, written out at
 * `loopCarriedHandlePhi` in `LoopLowering.cpp`.
 *
 * ⚠ K-INDEPENDENT, measured: the lowered module is 75 lines at K=3 and 75 lines
 * at K=1000 (`$SES/probes/k3.c`, `k1000.c`; measured without `-g`).
 */
#include "CQ.h"

int main(void) {
    int a = 5;
    bool b0[3];

    for (int i = 0; i < 3; ++i) {
        if (a >= 3) {
            cq_theta(&b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }

    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);
}
