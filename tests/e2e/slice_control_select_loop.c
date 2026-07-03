/* slice_control_select_loop.c — bd 9ymx e2e smoke (owner decision 2026-07-03:
   conditionals in loops are ALLOWED — option (a)): a tainted-condition fp
   ternary INSIDE a classical bounded loop, through the FULL pipeline. This is
   the -O1-NATURAL loop-conditional shape: LICM hoists the loop-invariant
   `q > 0.5` compare into the guard block while the select (loop-variant
   false operand `(double)i`) stays in the body — compare and select in
   DIFFERENT blocks, which gate 2c's first cut blanket-declined and the 9ymx
   relaxation accepts (the position-free router-crossing wire walk owns
   condition-wire staleness with no window; see SelectClassify gate 2c).

   PER-ITERATION SEMANTICS (the documented contract): each of the 3
   iterations mints a fresh flag from the UNCHANGED q wire, allocates a fresh
   |0> out rail and a fresh materialized scratch for (double)i, copies on
   flag/¬flag, strips the flag back to |0> and frees it — the ONLY free per
   iteration. The per-iteration measure is user-written (Rule 5). q stays
   allocated across all iterations (Rule 6); handle IDs grow monotonically
   with i, so the trace is deterministic (volatile n=3 keeps the loop from
   full unrolling; the trace-only runtime makes every iteration's stream
   unconditional). */
double slice(void) {
    volatile int n = 3;
    double q = cq_theta(0.3, 0.5);
    double acc = 0.0;
    for (int i = 0; i < n; i++) {
        double sel = (q > 0.5) ? q : (double)i;   /* loop-variant ternary */
        acc = cq_measure(sel);
    }
    return acc;
}
int main(void) { (void) slice(); return 0; }
