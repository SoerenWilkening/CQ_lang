/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, th)` -> `cq_phi(th)` at every site (branch phase by kickback).
   FLAG (PRD S6.3): the tainted arm now holds 2 cq_phi calls, which the Inc-1
   decline partition refuses ("an arm with N>1 cq_phi calls"). Expected
   post-increment class is a DECLINE, not an accept -- an owner call, not this
   migration's: the kickback needs no angle sum (two rz_i1 on the SAME flag are
   exact), so the N>1 refusal is a scoping choice, not a physics one.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_cond_datause.c — ziov WI-1 e2e smoke: a tainted control compare
   reused as DATA (the shared-condition-flag path). The only test layer that
   LINKS, so it proves the shared flag's data consumers (cq_template_zext +
   cq_template_add over the SAME icmp handle) resolve and signature-match against
   the runtime (Rule 2, Rule 16).

   SOURCE INTENT (cond-datause — owner 2026-06-15):
       q : tainted quantum handle
       int f = (q > 5);                          // DATA use of the condition
       if (q > 5) { cq_phi(.25); cq_phi(.75); }   // CONTROL use
       measure(q + f)

   clang -O1 CSEs `f = (q>5)` and `if (q>5)` to ONE `icmp sgt q, 5` with two uses
   (a `br` and a `zext`). The OLD flat classifier declined this outright
   ("condition used outside the branch"); ziov re-derives the correct lowering:
   the compare IS the control flag, so the route AND the data use must read ONE
   shared physical flag. The flag is minted ONCE (h1), CSWAP-routes q into the |0>
   work rail for the verbatim arm Rz gates, routes back, frees the rail — then the
   SAME flag h1 feeds the data `zext` (h3) and `add` (h4), and is NEITHER stripped
   (no icmp_inv) NOR freed: its data lineage flows into the measured value, which
   owns the handle. Contrast slice_control_phase_diamond.c (no data use), which
   strips + frees the flag. EXACTLY ONE free (the rail), ONE icmp mint, no
   `_inv` strip, ZERO controlled gates.

   The data use feeds the side-effecting `cq_measure`, so it survives clang's DCE
   even when `main` discards slice's result (a discarded PURE data use is DCE'd
   back to the ordinary strip+free control shape — verified; here the measure
   keeps the shared path live in the executed `main` copy). */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc i32(3), ry_i32)   */
    int f = (q > 5);               /* DATA use of the condition compare          */
    if (q > 5) {                   /* CONTROL use — clang CSEs to ONE icmp        */
        cq_phi(0.25);       /* arm gate 1 (Rz) — VERBATIM on the rail     */
        cq_phi(0.75);       /* arm gate 2 (Rz) — VERBATIM on the rail     */
    }
    return cq_measure(q + f);      /* f feeds the measured value (owns the flag) */
}
int main(void) { (void) slice(); return 0; }
