/* slice_loop_break_qq_derived.c — Phase 7.4 (epic y05j) coverage lock
   (test_C_libtooling-1784). The DERIVED-COMPARAND value-arm `break`: the tainted
   Q==Q condition compares the rail against a loop-invariant comparand `p` that is
   itself a DERIVED (non-mint) tainted value — `p = p0 + 5`, whose producer chain is
   p0 (cq_theta) -> p (add). Vs slice_loop_break_qq.c (a bare cq_theta mint comparand):

       int p0 = cq_theta(pseed, 0.5);
       int p  = p0 + 5;                // DERIVED loop-invariant comparand (p0 -> p)
       int q  = cq_theta(seed, 0.25);
       for (int i = 0; i < n; i++) {
           q = q ^ 5;                  // in-place value rail
           if (q == p) break;          // TAINTED Q==Q break (rail vs derived-p)
       }
       return cq_measure(q);

   WHY THE DERIVATION CHAIN p0 -> p RIDES INERT AND IS LEFT ALLOCATED (cleared by a
   5-lens adversarial Rule-13 sign-off 2026-06-30; structurally identical to the
   blessed bare-mint comparand, derivation strictly OUTSIDE the permutation): the
   break construct emits ONLY basis-permutation gates (no Ry/Rz/H inside); the lone
   deriving op cq_template_add_i32_hl(p0, 5) is PRE-LOOP. Both the derived comparand
   `p` AND its ancestor `p0` are consumed ONLY as operands of the QQ eq-compare
   (+matched _unc) — never rotated, copied into `out`, measured, or freed.
   isTerminalHandle is FALSE for both, and the compares feed control toffoli/cnot (not
   a kept data carrier), so the whole-DAG uncompute spine never enqueues them: the
   deriving add is NEVER reversed (no cq_template_add_i32_hl_unc in the trace) and
   NEITHER p0 NOR p is freed dirty — both LEFT ALLOCATED (two entangled rails instead
   of the bare-mint's one, the Rule-6 safe leak). NB the symmetric-XOR fold
   `p = p0 ^ 3` with an xor rail rides the E8 kMsgBreakUnemittable decline (clang -O1
   reassociates `(q^9)==(p0^3)` so the break-cond reads the PRE-mutation rail) — a
   different shape, over-declined safe.

   The only layer that LINKS the bare-QQ compare + its _unc for the break path with a
   derived comparand. The bound `n` is a runtime 4 for a deterministic trace; ZERO
   measurements inserted; `noinline` keeps the function boundary. */
__attribute__((noinline))
int run(int seed, int pseed, int n) {
    int p0 = pseed; cq_theta(&p0, 0.5);
    int p  = p0 + 5;                    /* DERIVED loop-invariant comparand (p0 -> p) */
    int q = seed; cq_theta(&q, 0.25);
    for (int i = 0; i < n; i++) {
        q = q ^ 5;                      /* in-place value rail self-update */
        if (q == p)                     /* TAINTED Q==Q break flag (rail vs derived-p) */
            break;
    }
    return cq_measure(q);
}
int main(void) { (void) run(3, 7, 4); return 0; }
