/* slice_uncompute_interior_chain.c — M-B Increment 5a (bd test_C_libtooling-6uqc).
   bd 6uqc's P1, end to end: the FIRST program in which a compiler-materialized
   INTERIOR rail — one that is neither a dead terminal nor a measured value — is
   uncomputed and freed.

       cq_theta(&a, 0.5);
       int f = sqrt(a + 3.0) <= 5.0;
       return cq_measure(f);

   WHAT WAS WRONG AT HEAD (c36934a). `clang -O1` DCEs only chains that are dead
   BEFORE the pass, and this one is live into a `zext` whose result is measured,
   so `sitofp`, `fadd`, `sqrt` and the pre-`zext` `fcmp` all survive as allocated
   rails. None is a TERMINAL — each has a forward consumer — so
   `ChainWalk::isTerminalHandle` is false for every one of them, the whole-DAG
   spine is never seeded anywhere in the chain, and the module lowers, links and
   runs with FOUR basis records of the wire minted and never discharged. `opt`
   exits 0; `opt -verify` is clean; `free_pairing_check.py` is silent because it
   does not track template-minted rails (bd 1739). The golden byte-diff was happy
   too — this trace's first six lines are unchanged.

   WHY IT IS A CORRECTNESS DEFECT AND NOT A QUBIT LEAK. C full-expression
   semantics ends those temporaries' lifetime at the `;`, so the faithful lowering
   is Bennett compute+uncompute. Leaving them allocated leaves them ENTANGLED with
   `a`, and any later non-diagonal step on `a` — the next Grover `cq_theta` — is
   physically dephased by them. bd 6uqc's P4 is this program plus a chained
   `cq_theta`, and at HEAD it DECLINES at the M-A live-record guard for exactly
   that reason. This slice is the straight-line half; the chained-theta half is
   slice_uncompute_interior_chained_theta.c.

   WHAT THE GOLDEN WITNESSES — and it is ORDER, which is the whole soundness
   claim in emitted form:
     * the reversal is LIFO. `fcmp_unc` reads `h3` before `sqrt_unc` zeroes it;
       `sqrt_unc` reads `h2` before `fadd_unc` zeroes it; and so on. Every `_unc`
       recomputes its rail from parents that still hold their PRODUCER-TIME values
       (invariant (d) of the bd 261j(a) record algebra), which is what makes each
       `cqrt_free` a free of a provably-|0> rail rather than a hidden measurement.
     * each rail is freed IMMEDIATELY after the adjoint that zeroes it, and never
       before a later reverse-read of it.
     * the whole reversal lands BEFORE `cqrt_measure_i32(h5)`. The measurement
       reads only `h5`, which the reversal never touches.
     * `h0` — the `cqrt_alloc`-minted source wire — is NEVER adjointed and NEVER
       freed. It is a BORROWED parent: its gate is `cqrt_ry`, which is not a basis
       permutation, so once `h5` holds a record of it `Ry†` does not return it to
       |0> and `cqrt_free(h0)` would be a hidden measurement (Rule 6). The absence
       of `cqrt_ry_i32(h0, -0x1p-1)` and of `cqrt_free(h0)` from this trace is a
       positive assertion, not an omission.

   IT IS NOT, BY ITSELF, CORRECTNESS EVIDENCE. A cleared golden has encoded a
   dephased circuit before (bd nepx). The evidence is this trace PLUS strict
   stage-2b free-pairing (no --allow-unproven) PLUS the analytic argument above
   PLUS the independent adversarial round.

   `noinline` is LOAD-BEARING for a different reason than in
   slice_uncompute_dead_dag.c. There it is because Phase-5 uncompute is gated OFF
   in `main`; the INTERIOR partition is deliberately NOT gated off in `main` (an
   interior discharge is about restoring |0> before later interference, not only
   about reclaiming a register at exit). What `noinline` buys here is that the
   trace comes from a real callee rather than from an inlined copy, so the golden
   pins the reversal in the function that owns it.

   The runtime is trace-only, so every gate fires unconditionally and the trace is
   deterministic regardless of `a`. */
#include <math.h>

__attribute__((noinline))
int slice(int a) {
    cq_theta(&a, 0.5);
    int f = sqrt(a + 3.0) <= 5.0;
    return cq_measure(f);
}
int main(void) { (void) slice(1); return 0; }
