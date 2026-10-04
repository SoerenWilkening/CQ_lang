/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, th)` -> `cq_phi(th)` at every site (branch phase by kickback).
   FLAG (PRD S6.3): the tainted arm now holds 2 cq_phi calls, which the Inc-1
   decline partition refuses ("an arm with N>1 cq_phi calls"). Expected
   post-increment class is a DECLINE, not an accept -- an owner call, not this
   migration's: the kickback needs no angle sum (two rz_i1 on the SAME flag are
   exact), so the N>1 refusal is a scoping choice, not a physics one.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_phase_ifelse_derived.c — Phase 4.1 follow-on e2e smoke
   (test_C_libtooling-9hh): a two-arm PHASE if/else routing a DERIVED base — the
   routed handle is a pre-region cq_phi result, not the bare theta. The only
   test layer that LINKS, so it proves the derived-base accept emits exactly the
   symbol set the runtime resolves (Rule 2, Rule 16).

   SOURCE INTENT (derived base + two-arm phase if/else — §5b over a criterion-3
   derived base):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       cq_phi(0.9);                          // UNCONDITIONAL pre-region Rz
       if (q > 5) { rz(q, 0.25); rz(q, 0.125); }    // then arm (flag)
       else       { rz(q, 0.75); }                  // else arm (¬flag, X-bracket)
       measure q

   The arms are deliberately ASYMMETRIC (two gates vs one): with ONE gate per
   arm, clang -O1 SimplifyCFG hoists the common `cq_phi(q, ·)` call and folds
   the branch into a tainted-condition ANGLE SELECT
   (`select i1, double a, double b`) — the 4.4-deferred shape that loudly
   DECLINES (Rule 9: never assume the CFG survives -O1). Unequal gate counts
   cannot be hoisted/sunk, so the genuine if/else diamond reaches the pass with
   the pre-region cq_phi as both arms' shared spine base.

   Both arm spines bottom at that pre-region cq_phi — the LIVE derived base.
   Routing it is correct because Rz is diagonal: basis(q) is unchanged by the
   pre-rotation, so the flag minted from icmp(q) is recoverable by icmp_inv(q),
   and rotation lowering RAUWs the theta and pre-phi results to the SAME i32
   handle. The pinned trace is the §5b dual-rail stream plus ONE unconditional
   cqrt_rz that MUST precede the flag mint (the pre-rotation is not part of the
   routed region).

   The runtime is trace-only and the region is flattened to straight-line code,
   so every emitted gate fires unconditionally; the trace is fully deterministic
   regardless of q's value. cq_theta/cq_phi/cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc i32(3), ry_i32)  */
    cq_phi(0.9);            /* pre-region Rz — the DERIVED routed base   */
    if (q > 5) {                   /* tainted condition -> swap-route both arms */
        cq_phi(0.25);       /* then gate 1 (Rz) — VERBATIM on its rail   */
        cq_phi(0.125);      /* then gate 2 (Rz) — VERBATIM on its rail   */
    } else {
        cq_phi(0.75);       /* else gate (Rz) — VERBATIM on its rail     */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
