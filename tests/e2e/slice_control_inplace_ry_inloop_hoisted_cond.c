/* slice_control_inplace_ry_inloop_hoisted_cond.c — the e2e half of bd
   `test_C_libtooling-drbq.12` (2026-09-17), and it exists because this is the ONLY
   test layer that LINKS and RUNS: the golden below is the first evidence that the
   newly-admitted program emits a stream whose every symbol resolves and
   signature-matches, and that the rails pair (Rule 2 + stage 2b).

   THE PROGRAM IS THE CUSTOMER'S SIMPLEST SPELLING, verbatim from PRD §13.10 Q1 and
   §13.11 worry 7 — the one the PRD says "is what a user writes first":

       for (i = 0; i < 2; ++i) { if (q == 5) r = cq_theta(r, 0.9); }

   with `r` on a rail disjoint from `q` and NO gate on `q` anywhere in the body. That
   makes `q` loop-INVARIANT, so `clang -O1` LICM-hoists the compare out of the loop
   header (the region's `Pred`) into the preheader, and until this bead
   `condWireDisposition`'s P4 precondition refused any compare that does not live in
   `Pred` — before the arm's own Ry was even looked at. It was pinned as a deliberate
   over-decline by
   `ir-pass/test/control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll`, which
   is the same module at the IR layer and is now an ACCEPT.

   WHAT THE GOLDEN SAYS, and it is the reason the workaround is retired. The trace is
   BYTE-FOR-BYTE the stream of the `volatile int off` twin `q == off` (which defeats
   LICM and has lowered since drbq Inc 3) with the literal `5` in place of the opaque
   load — the already-Rule-13-cleared in-place controlled-Ry stream, not a new one.
   Per trip: mint the eq-flag from q's handle, `cqrt_ry_i32_controlled` on r, the
   `_unc` strip, one `cqrt_free`.

   THE INVARIANTS TO READ IT BY:
     * `h0` is the USER's condition register. It appears only as arg-0 of the flag
       mint and of the `_unc` strip, as the CONTROL of the controlled rotation, and
       in its measure. It is never `cqrt_x`-bracketed and never freed.
     * `h1` is the rotated register. `Ry(0.9)|psi> != |0>`, so it is FROZEN — left
       allocated on purpose (Rule 6's "left allocated, never freed dirty").
     * The only freed rails are the per-trip flags `h2` and `h3`, each returned to
       |0> by its own forward mint / `_unc` strip pair before `cqrt_free`.

   WHY THE FLAG IS MINTED PER TRIP THOUGH THE COMPARE IS EVALUATED ONCE: the emitter
   builds at `Pred->getTerminator()`, which is inside the loop. That is the right
   circuit precisely because the hoist's own precondition is loop-invariance — and if
   the RAIL changed under an invariant SSA name, the condition-wire walk would decline
   it (a body gate reaches the mint around the back edge, so it is not provably
   post-stream). The negative
   `ir-pass/test/control_inplace_ry_reject_crossblock_cond_wire_gate_in_gap.ll` is
   exactly that program, with its accepting one-line control beside it.

   The runtime is trace-only and the diamond is flattened, so every emitted gate fires
   unconditionally and the trace is deterministic regardless of q's value. */
int slice(void) {
    int q = 0;
    int r = 0;
    q = cq_theta(q, 0.5);              /* alloc i32(0) + ry — the CONDITION rail   */
    r = cq_theta(r, 0.3);              /* a SECOND, disjoint rail                  */
    for (int i = 0; i < 2; ++i) {
        if (q == 5) {                  /* LICM hoists this compare out of the loop */
            r = cq_theta(r, 0.9);      /* the arm Ry — CONTROLLED and IN PLACE     */
        }
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
