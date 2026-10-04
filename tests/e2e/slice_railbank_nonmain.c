/* slice_railbank_nonmain.c — THE D1 SPINE DOOR, end to end, OUTSIDE `main`.
   bd `xdu2` / L-1a Increment W1, the SECOND HALF (Track B, session 2026-09-15).

   ⚠ `noinline` IS LOAD-BEARING AND IS NOT STYLE.  `FreePoint::computeFreePoint`
   short-circuits EVERY handle in `main` to `Escaped`, so inside `main` the
   disposition of a rail parked in a bank cell is decided by accident.  Without
   `noinline`, `-O1` inlines `kern` into `main` and the question DISAPPEARS —
   which is exactly how a real hazard comes to look absent (MEASURED on
   `trackB/probes/b14_bank_nonmain.c`).

   ⚠ AND THE OUTSIDE-`main` POPULATION IS THE COMMON CASE, NOT THE EDGE.
   MEASURED over an 80-slice sample of `tests/e2e/slice_*.c`, compiled `-O1` and
   attributed per defining function: 4 confine the quantum work to `main`, 10 to
   a non-`main` helper, 66 to BOTH — **76 of 80 carry it outside `main`**.

   WHAT WENT WRONG THERE BEFORE THE FIX, measured in all three directions:
     * `ChainWalk::isTerminalHandle` `continue`s on a non-`CallInst` user, so the
       bank `store` is SILENTLY SKIPPED and the rail is nominated as a DEAD
       terminal;
     * outside `main` the store then falls to `FirstUnrecognized` and the module
       LOUD-DECLINES `cq uncompute: tainted handle reaches an unrecognized user`
       — an over-decline of this very slice, written in the house style;
     * with the store deleted the spine ADJOINTS AND FREES the rail:
       `ry(+0.5); ry(-0.5); cqrt_free` per cell at `opt` exit 0 with stage 2b
       reporting `1 verified, 0 violation(s), 0 unproven` — the spine
       un-preparing and freeing the three qubits the user is about to measure.

   The golden below has NO `cqrt_free` line and NO negative-angle `cqrt_ry`,
   and that absence is the fix.  The rails are LEFT ALLOCATED (Rule 6). */
#include "CQ.h"

__attribute__((noinline)) int kern(void) {
    bool b0[3];
    int s = 0;
    for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}

int main(void) { (void) kern(); return 0; }
