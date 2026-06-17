/* slice_control_switch_value.c — Phase 4.5 e2e smoke (WI-6,
   test_C_libtooling-bkpz.6): the RSSA swap-routed homogeneous-VALUE switch
   (N-way method-B), the only test layer that LINKS and so the ONLY proof that
   the value switch emitter's symbol set (the eq-flag template + `_inv`,
   cqrt_cswap routes, the verbatim add HL templates + their `_inv` reverse-play
   adjoint, and the cqrt_copy_i32 basis copy-out) resolves and signature-matches
   against libcq_runtime (Rule 2, Rule 16).

   SOURCE INTENT (homogeneous VALUE-arm switch on a SHARED routed base p != q,
   empty default — the §4B ACCEPT shape, control_swap_switch_value.ll is the
   pinned IR contract):
       q : tainted quantum SCRUTINEE handle (the condition register)
       p : a SECOND tainted quantum handle (the routed value base, p != q — the
           C2 anchor; routing q would clobber the eq-flags it reads, §3c)
       switch (q) { case 0: p=p+1; case 1: p=p+2; }   // pure linear VALUE arms
       measure p

   The value arms write a base (p) that derives from a NON-constant tainted
   handle, so clang -O1 keeps the real `switch` (the merge phi over p+1/p+2/p is
   not a const-mux it can fold to a select). The eq-flags f_i=(q==c_i) are
   MUTUALLY EXCLUSIVE, so the forward stage interleaves per case: mint f_i ->
   |0> rail -> cswap route-in (positive polarity, NO ¬-bracket) -> the add chain
   VERBATIM on the rail (HL templates) -> cswap route-back (p holds the muxed
   answer). Then ONE cqrt_copy_i32(p,out) basis copy-out (after the route-backs,
   before any R†), the LIFO reverse-play (case 1 then case 0: route-back† ·
   add `_inv` adjoint · route-in†; the §8.5 seam — route cswaps are bracketed by
   emitRoute, NEVER fed to the inverter), the rail frees (on the FINAL threaded
   handle), the icmp_eq_inv flag strips (each reads pristine q == q0), the flag
   frees. RAUW merge->out — the measure reads the copied answer.

   EXACTLY FOUR frees (2 rails + 2 flags). p (restored to p0) and out (the
   result) are NEVER freed — either free is a hidden measurement that collapses
   the superposition (Rule 6 / Rule 8). Contrast the data-mux switch (no rail, no
   reverse-play: it leaks the deltas) and the phase switch (the answer is a phase
   on q, no copy-out). ZERO controlled gates beyond route cswaps; no surviving
   `phi i32`. The runtime is trace-only and the region is flattened to straight-
   line code, so every emitted gate fires unconditionally; cqrt_measure returns 0.
   The golden pins the trace captured from REAL linked output (templates BEFORE
   runtime — load-bearing link order). cq_theta/cq_measure resolve from CQ.h. */
int slice(void) {
    int q = 3, p = 4;
    q = cq_theta(q, 0.5);          /* taint q -> scrutinee handle               */
    p = cq_theta(p, 0.7);          /* taint p -> routed value base (p != q)      */
    switch (q) {                   /* tainted switch -> N-way method-B value     */
        case 0: p = p + 1; break;  /* arm 0 — pure value chain on rail 0         */
        case 1: p = p + 2; break;  /* arm 1 — pure value chain on rail 1         */
    }
    return cq_measure(p);          /* reads the copied-out muxed answer (out)    */
}
int main(void) { (void) slice(); return 0; }
