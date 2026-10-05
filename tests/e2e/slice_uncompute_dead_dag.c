/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(b, 0.5) and (void) cq_phi(prod, 0.30)
     NEW IDIOM: if (b > 100) cq_phi(0.5)  and  if (prod == 4) cq_phi(0.30)

   WHY. Under owner decision D1 `cq_phi` takes no register, so the documented
   "Rz keep-alive" — the opaque READER that stopped `clang -O1` deleting the dead
   tainted lineage this slice exists to exercise — no longer reads anything, and
   the whole lineage is DCE'd at STAGE 1 (prep-b PROBE 2, measured: the migrated
   `slice_intrinsic_bswap` lost its `llvm.bswap.i32` outright). Nothing else in
   `CQ.h` reads a quantum value without being a sink or a non-diagonal gate
   (PRE_DISPOSITIONS.md §5 OQ-1 checks all four candidates).

   The replacement consumer is a KICKBACK UNDER A DERIVED CONDITION, which is the
   honest CQ consumer for a dead chain: it exercises the forward chain, the flag
   mint, `cqrt_rz_i1`, the compare `_unc` strip, the chain's OWN `_unc` reversal
   and the frees — i.e. it keeps exactly the coverage this slice was written for.
   RECOVERED AND MEASURED IN THE GOLDEN BELOW:
     cq_template_shl_i32_hl_unc + cqrt_xorc_i32 (in-place) + cq_template_mul_i32_unc

   ⚠ THE CONDITION'S SHAPE IS LOAD-BEARING, NOT DECORATION. A plain equality
   against a constant is folded THROUGH the very op under test whenever that op
   is invertible — MEASURED: `bswap(c) == K` becomes `c == bswap(K)` and the
   bswap disappears; `clz(c) == 12` becomes a range test on `c`; `sext(b) == K`
   becomes `b == K`; `-fc == K` becomes `fc == -K`; `(a<<2)^9 == 9` becomes a
   mask test. Where that happened the condition was changed to one the folder
   cannot invert — an ORDERED compare, or a Q+Q op against a second tainted
   register whose operands are both non-constant — and the recovered `_unc`
   symbol above is the witness that it worked. */
/* 3qlq Inc 1: migrated to register-free cq_phi -- `(void) cq_phi(<dead value>, th)` -> `cq_phi(th)`.
   FLAG (KEEP-ALIVE SITE -- MEASURED, and this is the migration's headline cost):
   `(void) cq_phi(<dead>, th)` was a keep-alive. Rz is a side-effecting extern that
   READS ITS OPERAND, which is the only reason `-O1` DCE could not drop the dead
   arithmetic this slice exists to exercise. A register-free `cq_phi(th)` reads
   NOTHING, so the dead lineage is deleted AT STAGE 1, before the pass runs -- the
   loss is not one trace line, it is the whole chain and the `_unc` symbol the slice
   was written to LINK. Measured on slice_intrinsic_bswap: the `llvm.bswap.i32` is
   absent from stage-1 IR. There is no drop-in replacement in CQ.h (cq_measure is a
   SINK and, before bd ptue (2026-10-05), turned the shape into `dead chain would
   free a measured register`; an unknown extern is declineTaintEscapes; a volatile
   local is erased by the fenv ruling's eraseDeadVolatileScalarStores). OWNER QUESTION -- see PRE_DISPOSITIONS.md.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_uncompute_dead_dag.c — Phase 5 (WI-6, test_C_libtooling-p2s2.6): the
   FIRST end-to-end proof of the whole-DAG uncompute spine — the only layer that
   LINKS, so the only proof every void in-place `_unc` symbol the emitter mints
   (WI-3/WI-4) resolves AND signature-matches against the generated runtime ABI
   (WI-2) (Rule 2, Rule 16). A green `opt -verify` and a passing FileCheck on the
   .ll fixtures are NOT this proof: the ir-pass fixtures assert IR text and never
   link, so a name/signature disagreement between the generator and the emitter is
   invisible to them. This slice caught exactly that — the QQ `_unc` form was
   generated as `cq_template_mul_i32_qq_unc` while the emitter (and every fixture)
   emits the BARE `cq_template_mul_i32_unc` (matching the bare forward QQ form);
   the two never met until this link. See docs/prd/phase-05-uncomputation.

   TWO dead, unmeasured, unreturned source-derived tainted handles in a
   `__attribute__((noinline))` helper. `noinline` is LOAD-BEARING: Phase 5
   uncompute is gated OFF in `main` (FreePoint.cpp — `main`'s handles are
   reclaimed at process exit, so they are a recognized escape). At `-O1` clang
   would inline `slice` into `main` and the inlined copy would carry NO uncompute,
   while the real (uncompute-bearing) `slice` would be dead and never run — the
   trace would show only the forward chain. `noinline` forces the function
   boundary so the uncompute actually executes. This is also a faithful program:
   a subroutine that prepares quantum scratch and drops it without measuring.

   Each chain's dead terminal is read by the condition of a kickback `cq_phi`
   (`b > 100`, `prod == 4`), which stops `-O1` DCE-ing the dead arithmetic — so
   a real `cq_template_*` terminal survives to be uncomputed. The flag takes one
   `cqrt_rz_i1` and is stripped by its compare `_unc`; the pass then reverses the
   chain ONCE in reverse program order (LIFO): each gate adjointed exactly once
   via the void in-place `_unc` form (DD-3 slots: `out` first, then the forward
   operands in order), the chain rail freed after its last reverse-use, then the
   flag. NO fresh-minting `_inv`, NO added measurement (Rules 5/6), NO
   `cqrt_cswap`.

   Each chain reverses right after its own kickback, in program order (chain 1
   first). Exactly FOUR frees (h1,h2 then h5,h6): each chain rail, then its flag.

   The three cq_theta registers (h0, h3, h4) are neither reverse-rotated nor
   freed. It was SIX frees before M-C Increment 2c (bd test_C_libtooling-6uqc):
   `b = b ^ 9` used to MINT a rail (`cq_template_xor_i32_hl`) with its own free,
   and now mutates the `shl` rail in place (`cqrt_xorc_i32`), one fewer alloc
   AND one fewer free. It was FIVE until 3qlq Inc 1 (a3c1513d), whose golden
   dropped the theta registers' reverse Ry and free. A free that disappears
   without its alloc would be the Rule-6 defect this slice exists to catch.

   TWO distinct `_unc` symbols are now exercised at the link layer — the BARE QQ
   `cq_template_mul_i32_unc` (the WI-6-caught fix) and
   `cq_template_shl_i32_hl_unc` — plus the in-place `cqrt_xorc_i32`, whose
   adjoint is the IDENTICAL call (self-inverse), emitted before the `shl` `_unc`
   that reads the rail it restored. `cq_template_xor_i32_hl_unc` left this slice
   with 2c and is NOT uncovered: it still links in slice_control_value_diamond,
   slice_loop_iter_local and spec_twoarm_caller (6 occurrences, measured).

   cq_theta/cq_phi resolve from CQ.h, force-included by run_slice.sh
   (-include CQ.h -I include). */
__attribute__((noinline))
void slice(int x, int y) {
    /* (1) linear Q+C (_hl) chain, dropped without measure. */
    int a = x; cq_theta(&a, 0.25); /* taint x -> handle (alloc + ry)            */
    int b = a << 2;              /* shl_hl                                    */
    b = b ^ 9;                   /* cqrt_xorc_i32, in place on the shl rail   */
    if (b > 100) cq_phi(0.5);       /* kickback keep-alive (rz_i1 on flag)       */

    /* (2) Q+Q (_qq) product, dropped without measure — the bare-QQ `_unc`. */
    int p = x; cq_theta(&p, 0.10); /* alloc + ry                                */
    int q = y; cq_theta(&q, 0.20); /* alloc + ry                                */
    int prod = p * q;            /* mul_qq (operands ordered by BirthOrder)   */
    if (prod == 4) cq_phi(0.30);   /* kickback keep-alive (rz_i1 on flag)       */
}
int main(void) { slice(2, 5); return 0; }
