/* onward_ctl_phase_caller.c — the CQ translation unit for the yn71 (Phase 4×6, the
   CONTROL case) e2e golden: a 6.5 classical-call arm whose UNTAINTED merge `%out`
   feeds an ONWARD TAINTED-CONTROL phase arm. The only test layer that LINKS, so the
   ONLY proof that yn71's re-detected + emitted onward controlled phase — the routed
   `cqrt_cswap`/`cqrt_rz` stream over `%out` under a flag minted from `icmp(%out, k)`
   — resolves + signature-matches against libcq_runtime (Rule 2, Rule 16).

   SOURCE INTENT (the CONTROL case yn71 converts from decline):
       q : theta-tainted condition handle
       int y = 5;
       if (q > 5)  y = ext_f(7);        // R1: 6.5 classical-call arm -> %out = (q>5)?107:5
       if (y > 50) y = cq_phi(y, 0.25); // R2: ONWARD CONTROLLED phase on the merge %out
       measure y

   `y = (q>5)?ext_f(7):5` = (q>5)?107:5, entangled with q (its VALUE is
   control-dependent on the quantum q, though data-untainted at round-1 — the
   dugh untainted-merge shape). Because `ext_f` is only
   DECLARED here (its pure body arrives from onward_ctl_phase_lib.c at link time),
   clang -O1 cannot constant-fold `ext_f(7)` nor the downstream `y > 50` into the merge
   incomings — so `if (y > 50)` survives -O1 as a REAL icmp+br diamond (NOT a phi-of-
   constants, which is what folds a switch-const `if (r > k)` into a multi-phi C1
   decline). The `cq_phi` is an OPAQUE call, not speculatable, so the diamond never
   collapses to a `select`.

   R1's merge `%out` is data-untainted at round-1 (the straight-through is `q`, the arm
   is the classical `ext_f(7)`), so `if (y > 50)` is a CLASSICAL branch then. dugh's
   `repropagateControlMerges` re-seeds the second propagation from the emitted `%out`,
   tainting `icmp sgt %out, 50`; PRE-yn71 `declineReClassifiedControl` declined the new
   tainted-condition branch. yn71 RE-DETECTS it (`detectAndLowerOnwardControl`) and
   `SwapRouteEmit` emits the routed phase arm ON `%out`: flag = `icmp(%out, 50)`, route
   `%out` into a |0> rail (`cqrt_cswap`), VERBATIM `cqrt_rz(rail, 0.25)`, route back,
   free the rail, `icmp_inv`-strip + free the flag; the measure reads `%out`. q, %out,
   and the materialized `ext_f(7)` scratch are LEFT ALLOCATED (Rule 6/8); EXACTLY TWO
   frees (the R1 ccarm flag + the R2 phase-arm flag) plus the ONE route-rail free. */
int ext_f(int a);

int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);          /* taint q -> condition handle (alloc, ry)     */
    int y = 5;
    if (q > 5)                     /* R1: tainted-condition classical-call arm     */
        y = ext_f(7);              /* pure classical call -> route-merged %out      */
    if (y > 50)                    /* R2: ONWARD tainted control on the merge %out  */
        y = cq_phi(y, 0.25);       /* controlled phase arm (routed cswap+rz on out) */
    return cq_measure(y);          /* reads the (conditionally) phased answer        */
}

int main(void) { (void) slice(); return 0; }
