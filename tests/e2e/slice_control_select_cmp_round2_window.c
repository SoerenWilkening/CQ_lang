/* slice_control_select_cmp_round2_window.c — Track A.1 (bd
   test_C_libtooling-9pum): THE ROUND-2 TAINT WINDOW AT A COMPARE LEAF,
   ACCEPTED — the discriminator that `reverifyCmpCondReads` is a
   RE-VERIFICATION and not a refusal of the window. The COMPARE twin of
   `slice_control_select_bool_round2_window`.

   Two TUs through the shipped 6.5 recipe (per-TU `-O1` IR -> `llvm-link` -> ONE
   `cq-lowering`), because the window needs a callee `clang` cannot inline:

       int ext_f(int a);                 // _lib.c: { return a + 100; }
       int q = 3; q = cq_theta(q, 0.5);
       int y = 5;
       if (q > 5) y = ext_f(7);          // the 6.5 classical-call arm -> %out
       int keep = cq_measure(y);         // keeps %out live
       int x = (y != 0);                 // CLASSICAL at round 1, TAINTED at round 2
       int b = cq_theta(x, 0.25);        // the rail the select's compare reads
       int a = (b == 1) ? 2 : 5;         // the 4.4 copy merge
       int b3 = cq_theta(x, 0.9);        // the SIBLING — after the select

   `%x` is the `%out`-derived seed that gate 2c saw as CLASSICAL (round-1 taint)
   and `lowerRotations` sees as TAINTED (final taint), so `b` and `b3` are ONE
   physical rail — the exact window in which the SAME program with the sibling
   BEFORE the select is a wrong unitary (lit:
   `control_swap_reject_select_cmp_round2_plainc_twotu.ll`, the committed linked
   stage-1 module of that program, ACCEPT on `main` 0c7380c).

   HERE IT IS CORRECT AND IT STILL LOWERS. The sibling runs after the merge, so
   the register the copies control on really is `Ry(0.25)|x>` — the label `b`
   names — and the trace is source order, gate for gate:

       cq_template_icmp_ne_i32_hl(h2, 0) ... zext  <- %x's rail
       cqrt_ry_i32(h_cast, 0x1p-2)                 <- b
       cq_template_icmp_eq_i32_hl(h_cast, 1)       <- the merge flag
       ... the merge on h_cast ... cqrt_free
       cqrt_ry_i32(h_cast, 0x1.ccccccccccccdp-1)   <- b3, AFTER the merge

   `reverifyCmpCondReads` re-asks rung (iii) at the recorded read point (that
   `icmp_eq` mint) with FINAL taint: the position-free walk DOES now find the
   sibling, it is CLEAN taint-blind (so the window really is open), and the DT
   prong then proves the sibling runs after every execution of the read.

   ORDER IS THE ASSERTION, and STRICT stage 2b. */
int ext_f(int a);

int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    int x = (y != 0);
    int b = cq_theta(x, 0.25);
    int a = (b == 1) ? 2 : 5;
    int b3 = cq_theta(x, 0.9);
    return cq_measure(a) + cq_measure(b3) + keep;
}

int main(void) {
    (void) slice();
    return 0;
}
