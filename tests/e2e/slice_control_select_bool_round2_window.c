/* slice_control_select_bool_round2_window.c — bd test_C_libtooling-r9e5
   (Inc 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1): THE ROUND-2 TAINT WINDOW,
   ACCEPTED, and it is the discriminator that the fix is a RE-VERIFICATION and
   not a refusal of the window.

   Two TUs through the shipped 6.5 recipe (per-TU `-O1` IR -> `llvm-link` -> ONE
   `cq-lowering`), because the window needs a callee `clang` cannot inline:

       int ext_f(int a);                 // _lib.c: { return a + 100; }
       int q = 3; q = cq_theta(q, 0.5);
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
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b = cq_theta(x, 0.25);
    int a = b ? 2 : 5;
    bool b3 = cq_theta(x, 0.9);
    return cq_measure(a) + cq_measure(b3) + keep;
}

int main(void) {
    (void) slice();
    return 0;
}
