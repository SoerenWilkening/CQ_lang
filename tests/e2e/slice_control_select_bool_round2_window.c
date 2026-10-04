/* ⚠ UNREGISTERED SINCE 2026-09-14 (bd test_C_libtooling-3d8q, OWNER RULING
   2026-09-14 — the stale-reader fence). This file is NOT an e2e test any more:
   `tests/e2e/CMakeLists.txt` no longer registers `e2e-slice-control-select-bool-round2-window`,
   and `slice_control_select_bool_round2_window.expected.log` was DELETED. It is
   kept in the tree, with its `_lib.c`, as the record of a program that used to
   lower and now loudly declines. Same disposition, same reason, and the same
   shape as `slice_control_switch_phase.c` took on 2026-09-05.

   MEASURED at the merge gate of 2026-09-14 (merged binary `cq-opt`
   `5c6f7490a81c7505…`; the program ACCEPTED on the frozen session ORACLE
   `f7b65d8c`), on the linked two-TU module this slice builds:

       exit 1
       cq opcode lowering: rotation/measure operand predates a non-diagonal gate

   WHY IT DECLINES. The program ends

       bool b  = cq_theta(x, 0.25);   -- consumes the name `x`
       ... the 4.4 merge on that rail ...
       bool b3 = cq_theta(x, 0.9);    -- the SIBLING, reads `x` a SECOND time

   so `b3` names `Ry(0.9)|x>` while the register holds `Ry(0.9)Ry(0.25)|x>`: two
   sibling rotations emitting on ONE physical register. That is
   `docs/frontend.md` §3.2's linear rule ("a rotation consumes the old name") and
   it is the project's P1 stale-reader class — the one known silent miscompile bd
   `3d8q` was opened to close. THE HEADER BELOW IS KEPT VERBATIM and its
   correctness claim is TRUE OF EXACTLY ONE OF THE TWO READS: everything it says
   about ORDER is about the MERGE's read of `b`, and it says nothing about `b3`'s
   own read. `b3` is where the defect is.

   ⚠ NO GOLDEN WAS REGENERATED, AND NONE COULD BE. A decline has no trace, and
   the e2e layer has no decline runner: this slice's own registration block said
   so in the CMakeLists — "`run_slice*.sh` runs under `set -euo pipefail` and
   byte-diffs a golden, so a program whose `opt` exits non-zero cannot be a
   passing slice at all (there is no WILL_FAIL and no decline runner in this
   file)". The deleted golden was a record of the ORACLE's circuit for a program
   the compiler now calls a miscompile; it is gone, not rewritten.

   THE DECLINE IS PINNED, at the only layer that can hold it:
   `ir-pass/test/control_swap_reject_select_rail_round2_window.ll`
   carries the VERBATIM linked stage-1 module of this slice, with the diagnostic
   mirrored character-for-character. Converting this slice therefore costs ZERO
   coverage — it moves the same program from a layer that cannot express its
   verdict to one that can.

   RETIREMENT TRIGGER (L8): if the open question recorded in
   `ir-pass/test/control_swap_select_cmp_round2_window_accept.ll` — whether the
   CHAINED rewrite (`cq_theta(b, 0.9)` instead of a sibling on `x`) is a separate
   over-decline — resolves as an over-decline and the chained spelling is made to
   lower, then this slice becomes registrable again with that one line changed
   and the header below intact. RE-DERIVE THE GOLDEN FROM THE FIXED COMPILER at
   that point; do NOT restore the deleted one, and do not re-register without a
   freshly derived golden. */
/* slice_control_select_bool_round2_window.c — bd test_C_libtooling-r9e5
   (Inc 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1): THE ROUND-2 TAINT WINDOW,
   ACCEPTED, and it is the discriminator that the fix is a RE-VERIFICATION and
   not a refusal of the window.

   Two TUs through the shipped 6.5 recipe (per-TU `-O1` IR -> `llvm-link` -> ONE
   `cq-lowering`), because the window needs a callee `clang` cannot inline:

       int ext_f(int a);                 // _lib.c: { return a + 100; }
       int q = 3; cq_theta(&q, 0.5);
       int y = 5;
       if (q > 5) y = ext_f(7);          // the 6.5 classical-call arm -> %out
       int keep = cq_measure(y);         // keeps %out live as an i32 phi
       bool x = (y != 0);                // CLASSICAL at round 1, TAINTED at round 2
       bool b  = cq_theta(x, 0.25);      // the rail the select reads
       int a = b ? 2 : 5;                // the 4.4 copy merge on that rail
       bool b3 = cq_theta(x, 0.9);       // the SIBLING — after the select

   `%x` is the `%out`-derived seed the §14.3 rail ladder saw as CLASSICAL (round-1
   taint) and `lowerRotations` sees as TAINTED (final taint), so `b` and `b3` are
   ONE physical rail — the exact window in which the SAME program with the
   sibling BEFORE the select is a wrong unitary
   (`control_swap_reject_select_rail_round2_plainc_twotu.ll`, the committed
   stage-1 module of that program, and `..._round2_sibling_theta.ll`).

   HERE IT IS CORRECT AND IT STILL LOWERS. The sibling runs after the merge, so
   the register the copies read really is `Ry(0.25)|x>` — the label `b` names —
   and the trace is the source order, gate for gate:

       cq_template_icmp_ne_i32_hl(h2, 0) -> h5     <- %x's rail
       cqrt_ry_i1(h5, 0x1p-2)                      <- b
       cqrt_alloc_i1(0) -> h6; cqrt_cnot(h5, h6)   <- the copy flag
       ... the §5a merge on h6 ... cqrt_free(h6)
       cqrt_ry_i1(h5, 0x1.ccccccccccccdp-1)        <- b3, AFTER the merge

   `reverifyRailCondReads` re-asks rung (iii) at the recorded read point (the
   first `cqrt_cnot`) with FINAL taint: the position-free walk DOES now find the
   sibling — the F-1b-1 tainted-parent ancestry reaches it — and the DT prong
   then proves it runs after every execution of that read, which is
   `ProvenPostRegion`. Option 3 of the review (treat any non-`Constant` arg-0 as
   chained) would have refused this program; option 1 keeps it.

   ORDER IS THE ASSERTION. No `cqrt_x` on either user register (h0, h5), one
   `cqrt_free` per minted flag and none of a user register, STRICT stage 2b. */
int ext_f(int a);

int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b = x; cq_theta(&b, 0.25);
    int a = b ? 2 : 5;
    bool b3 = x; cq_theta(&b3, 0.9);
    return cq_measure(a) + cq_measure(b3) + keep;
}

int main(void) {
    (void) slice();
    return 0;
}
