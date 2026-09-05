/* 3qlq Inc 1: migrated to register-free cq_phi -- `int p = cq_phi(p0, 0.3)` -> `int p = p0; cq_phi(0.3);`.
   FLAG (RENAME SITE): the rewrite preserves the DATA FLOW (p == p0) but not the
   PHASE. This slice exists to compare a comparand that CARRIES A RELATIVE PHASE
   against slice_loop_break_qq.c, whose comparand is a bare theta mint. After the
   migration p IS the bare theta mint (the phase is a deleted global phase), so the
   two slices are the same program. Purpose does NOT survive.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_loop_break_qq_phase.c — Phase 7.4 (epic y05j) coverage lock
   (test_C_libtooling-mvrb). The PHASE-CARRYING-COMPARAND value-arm `break`: the
   tainted Q==Q condition compares the rail against a loop-invariant comparand `p`
   that carries a RELATIVE PHASE (an Rz / cq_phi in p's lineage) — vs
   slice_loop_break_qq.c, whose comparand is a bare cq_theta mint:

       int p0 = cq_theta(pseed, 0.5);
       int p = p0; cq_phi(0.3);       // Rz — p now carries a relative phase
       int q  = cq_theta(seed, 0.25);
       for (int i = 0; i < n; i++) {
           q = q ^ 5;                  // in-place value rail
           if (q == p) break;          // TAINTED Q==Q break (rail vs phase-p)
       }
       return cq_measure(q);

   WHY THE COMPARAND'S RELATIVE PHASE RIDES INERT (cleared by a 5-lens adversarial
   Rule-13 sign-off 2026-06-30): the entire break construct (forward capture + exit
   consolidation + reverse-play) emits ONLY computational-basis PERMUTATION gates —
   NO Ry/Rz/Hadamard inside it. The ONLY cqrt_rz is PRE-LOOP (it prepares p's phase,
   outside the construct). So the construct is a fixed basis permutation; p's relative
   phase rides inert and p is consumed EXCLUSIVELY as a control/operand of the QQ
   eq-compare (+matched _unc) — never rotated, copied into `out`, measured, or freed.
   p is restored exactly (phase intact) and LEFT ALLOCATED (Rule-6 safe leak); the
   trace shows the pre-loop cqrt_rz_i32(h0, 0.3) and NO cqrt_free(h0). This is DISTINCT
   from the B3 phase fence (which declines a phase ESCAPING ANSWER — there method-B's
   copy-out would dephase, Rule 7); a phase on the COMPARAND is never copied out.

   The only layer that LINKS the bare-QQ compare + its _unc for the break path with a
   phase-carrying comparand. The bound `n` is a runtime 4 for a deterministic trace;
   ZERO measurements inserted; `noinline` keeps the function boundary. */
__attribute__((noinline))
int run(int seed, int pseed, int n) {
    int p0 = cq_theta(pseed, 0.5);
    int p = p0; cq_phi(0.3);           /* Rz — phase-carrying comparand */
    int q  = cq_theta(seed, 0.25);
    for (int i = 0; i < n; i++) {
        q = q ^ 5;                      /* in-place value rail self-update */
        if (q == p)                     /* TAINTED Q==Q break flag (rail vs phase-p) */
            break;
    }
    return cq_measure(q);
}
int main(void) { (void) run(3, 7, 4); return 0; }
