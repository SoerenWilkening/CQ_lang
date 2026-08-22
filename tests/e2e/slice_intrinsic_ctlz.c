/* slice_intrinsic_ctlz.c — bd ww4c Increment 0 (PRD-ww4c-ctlz-idiom.md §9), the
   e2e link proof for the Class-2 (non-injective pure total) `ctlz` family.

   WHY IT EXISTS, measured (bd ww4c, 2026-08-21): `cq_template_ctlz_i32` had NEVER
   appeared in a linked e2e golden — zero hits across tests/e2e, while `ctpop` had
   two and `bswap` one. It was proven at the IR layer
   (ir-pass/test/lowering_intrinsic_ctlz_i32.ll) and in the archive (`nm -g`:
   T _cq_template_ctlz_i32, T _cq_template_ctlz_i32_unc) and UNPROVEN at the only
   layer that LINKS. The ww4c recognizer emits this exact call, so it lands on
   proven ground rather than on two unknowns at once.

   Structure copied from slice_intrinsic_ctpop.c, the Class-2 model, plus one
   lineage this slice needs that ctpop does not (C, below):

   (A) MEASURED forward ctlz — proves the FORWARD producer.
   (B) DEAD ctlz kept alive by a `cq_phi` — proves the void `_unc` twin
       cq_template_ctlz_i32_unc(out, src) and the Class-2 recompute-from-live-source
       discipline: the dead ctlz is reversed by recomputing it from its STILL-LIVE
       source, and the source is uncomputed + freed ONLY AFTER its own `_unc` (a
       source freed before its `_unc` is the silent-collapse class). No `_inv` —
       ctlz is not invertible.
   (C) MEASURED forward ctlz in the OTHER immarg spelling — see below.

   THE IMMARG, and what this golden can and cannot witness (PRD §4.5(1) in
   miniature). `llvm.ctlz` carries an `is_zero_poison` i1 IMMARG. The ww4c
   recognizer must emit the literal `i1 false`, because PoisonFacts.cpp:27-38
   (`curatedIntrinsicCanBePoison`) returns `!Flag || !Flag->isZero()`, so
   PredMuxFlatten (:174-207) accepts a cone containing ctlz/cttz/abs ONLY when that
   immarg is a ConstantInt ZERO — and LLVM's canonical idiom output emits `i1 true`,
   so a verbatim copy would decline the very cell ww4c exists to unblock.

   Measured with this clang at the -O1 floor: `__builtin_clz(x)` emits `i1 true`
   (it is UB at 0), while the total spelling `x ? __builtin_clz(x) : 32` folds to a
   single `@llvm.ctlz.i32(%x, i1 false)` — no select, no branch survives. So A and B
   carry the FALSE form the recognizer depends on, and C carries the TRUE form.

   They trace IDENTICALLY, and that is the point rather than a defect: Rule 15's
   width-only ABI DROPS the immarg (intrinsic_table.yaml:33-38), lowering the TOTAL
   function — both `fwd` and `_unc` use the same total f, so ctlz(0) is the honest
   32 and the rail zeroes correctly either way. C is here to MEASURE that
   indistinguishability at the linked ABI rather than assert it. The consequence the
   immarg really does have — the PredMux cone fence — is an IR-layer property that
   NO golden can witness at any ABI; it is pinned by
   ir-pass/test/lowering_intrinsic_ctlz_i32.ll, which asserts both spellings.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
__attribute__((noinline))
void slice(unsigned x) {
    /* (A) measured forward ctlz, `i1 false` — the form the ww4c recognizer emits. */
    unsigned a = cq_theta(x, 0.25);
    int b = a ? __builtin_clz(a) : 32;   /* -> llvm.ctlz.i32(%a, i1 false) */
    (void) cq_measure(b);

    /* (B) dead ctlz — proves the `_unc` twin + recompute-from-live-source. */
    unsigned c = cq_theta(x, 0.10);
    int d = c ? __builtin_clz(c) : 32;    /* dead */
    (void) cq_phi(d, 0.30);               /* Rz keep-alive; result dropped */

    /* (C) measured forward ctlz, `i1 true` — Rule 15 drops the immarg, so this
       traces byte-identically to (A). Measured, not assumed. */
    unsigned e = cq_theta(x, 0.50);
    int f = __builtin_clz(e);             /* -> llvm.ctlz.i32(%e, i1 true) */
    (void) cq_measure(f);
}
int main(void) { slice(0x000f0f0fu); return 0; }
