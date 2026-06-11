/* slice_control_value_diamond.c — Phase 4.2 e2e smoke (WI-6): the RSSA
   swap-routed VALUE-arm diamond (method-B), the only test layer that LINKS and
   so the ONLY proof that 4.2's new runtime symbol cqrt_copy_i32 resolves and
   signature-matches against libcq_runtime (Rule 2, Rule 16) — verify-clean and
   "runs without crashing" prove neither.

   SOURCE INTENT (one-arm diamond, multi-op VALUE arm — §5d / method-B):
       q : tainted quantum handle (condition register, cq_theta == Ry)
       p : tainted quantum handle (value register, disjoint from q)
       if (q > 5) { p = p+3; p = p*5; p = p^9; p = p+1; p = p*7; p = p^2; }
       measure p

   The arm rewrites a VALUE (a basis label on p), not a phase, so it is a value
   arm: compute the chain on a |0> work rail, COPY the answer out (cqrt_copy_i32,
   the sole basis copy), then REVERSE-PLAY the chain so the rail returns to |0>
   and is freed clean (method-B; Rule 7 — a CNOT copies a label, not a phase, so
   method-B must NEVER touch a phase arm). NOT classical control over quantum
   state: the swap-route lowering mints the flag from the tainted icmp, CSWAPs p
   into the rail, runs the chain VERBATIM and UNCONTROLLED on the rail, CSWAPs
   back (the phi is the adjoint of the split, same flag), copies p -> out, then
   route-back-dagger / chain adjoints (_inv twins, reversed) / route-in-dagger
   return the rail to |0> for a clean free; the icmp_inv strips the boolean.
   EXACTLY TWO frees (work rail + flag); out and the restored source p are NEVER
   freed (either free is a hidden measurement). ZERO controlled gates, NO
   surviving `phi i32`, NO added measure (control_swap_value_diamond.ll is the
   pinned IR contract; IMPLEMENTATION-4.2 §5d).

   WHY THE TRACE IS DETERMINISTIC: the runtime is trace-only and the diamond is
   flattened to straight-line code, so every emitted gate fires unconditionally
   regardless of q's value. WHY A 6-OP CHAIN (Rule 9/11, PRD §8.4 — measured
   against clang -O1 on this tree): a single-op or short (<=4 cheap ops) value
   arm FOLDS TO A TAINTED SELECT at -O1 (SimplifyCFG speculation — 4.4 territory,
   loudly declined `select`); only a longer linear chain SURVIVES as a clean
   br-diamond. clang REASSOCIATES the arm's constant folds (p+3; p*5 -> p*5; +15
   ...), so the golden pins the POST-reassociation trace, captured from REAL
   linked output (templates BEFORE runtime — load-bearing link order). cq_theta/
   cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);          /* taint q -> condition handle (alloc, ry)   */
    p = cq_theta(p, 0.25);         /* taint p -> value handle (alloc, ry)       */
    if (q > 5) {                   /* tainted condition -> swap-route the arm    */
        p = p + 3;                 /* value-arm op 1 (basis rewrite on the rail) */
        p = p * 5;                 /* value-arm op 2                             */
        p = p ^ 9;                 /* value-arm op 3                             */
        p = p + 1;                 /* value-arm op 4                             */
        p = p * 7;                 /* value-arm op 5                             */
        p = p ^ 2;                 /* value-arm op 6                             */
    }
    return cq_measure(p);          /* reads the copied-out answer (out)          */
}
int main(void) { (void) slice(); return 0; }
