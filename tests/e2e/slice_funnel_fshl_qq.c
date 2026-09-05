/* 3qlq Inc 1: migrated to register-free cq_phi -- `(void) cq_phi(<dead value>, th)` -> `cq_phi(th)`.
   FLAG (KEEP-ALIVE SITE -- MEASURED, and this is the migration's headline cost):
   `(void) cq_phi(<dead>, th)` was a keep-alive. Rz is a side-effecting extern that
   READS ITS OPERAND, which is the only reason `-O1` DCE could not drop the dead
   arithmetic this slice exists to exercise. A register-free `cq_phi(th)` reads
   NOTHING, so the dead lineage is deleted AT STAGE 1, before the pass runs -- the
   loss is not one trace line, it is the whole chain and the `_unc` symbol the slice
   was written to LINK. Measured on slice_intrinsic_bswap: the `llvm.bswap.i32` is
   absent from stage-1 IR. There is no drop-in replacement in CQ.h (cq_measure is a
   SINK and turns the shape into `dead chain would free a measured register`; an
   unknown extern is declineTaintEscapes; a volatile local is erased by the fenv
   ruling's eraseDeadVolatileScalarStores). OWNER QUESTION -- see PRE_DISPOSITIONS.md.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_funnel_fshl_qq.c — bd 20xt.1 e2e link-layer smoke (Rule 2 / Rule 16) for
   the general constant-amount funnel shift fshl(a,b,n) with a!=b + BOTH data
   operands quantum handles. This is the ONLY layer that LINKS and proves the new
   frozen symbols cq_template_fshl_i32_qql[_unc] RESOLVE and SIGNATURE-MATCH — the
   lit fixtures cover the lowering, but not the link (the exact gap the Rule-13
   adversarial review flagged; it also confirmed both symbols resolve via a manual
   link+run, which this commits as a regression baseline).

   Two funnels, each with LINEAR (no-fan-out) sources so the whole-DAG uncompute
   engages (Rule 8):
     - r = (a<<16)|(b>>16)  -> fshl.i32(a,b,16), MEASURED  -> the FORWARD qql only.
     - dead = (c<<8)|(d>>24) -> fshl.i32(c,d,8), phase-armed by cq_phi (Rz) then
       dead -> reverse-play: the void cq_template_fshl_i32_qql_unc(out,c,d,8)
       recompute-and-XOR from the still-LIVE c,d,8 zeroes the rail, which is then
       freed (Rule 6), and c,d are ry-reversed + freed. Sources kept live through
       the forward pass; every rail freed only at |0> (0 double-frees).

   `slice` is __attribute__((noinline)) so the trace deterministically reflects the
   slice() lowering (main's discarded-result inline copy drops the dead-funnel
   uncompute — a pre-existing terminal-selection behavior when the measured result
   is dead; noinline pins the canonical forward+_unc shape). */
#include <stdint.h>

__attribute__((noinline))
unsigned int slice(void) {
    unsigned int a = cq_theta(7u, 0.5);
    unsigned int b = cq_theta(9u, 0.25);
    unsigned int r = (a << 16) | (b >> 16);      /* fshl(a,b,16) -> qql, measured */
    unsigned int c = cq_theta(3u, 0.375);
    unsigned int d = cq_theta(5u, 0.125);
    unsigned int dead = (c << 8) | (d >> 24);    /* fshl(c,d,8) -> qql, dead */
    cq_phi(0.6);                    /* Rz keep-alive -> reverse-play _unc */
    return cq_measure(r);
}

int main(void) {
    (void) slice();
    return 0;
}
