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
/* slice_compare_qq.c — Phase 7.1 Increment A e2e smoke: a tainted Q+Q
   (both-operands-tainted) DATA-position compare. The ONLY layer that LINKS, so
   the only proof that `cq_template_icmp_<pred>_i32(i32, i32)` (the bare-QQ
   forward) AND its void `_unc` twin `cq_template_icmp_<pred>_i32_unc(out, a, b)`
   both resolve and signature-match against the generated runtime ABI (Rule 2,
   Rule 16). A green `opt -verify` and a passing FileCheck on the .ll fixtures
   are NOT this proof — they assert IR text and never link.

   Two independent Q+Q lineages in a `__attribute__((noinline))` helper:

   (A) MEASURED Q+Q — proves the FORWARD bare-QQ symbol.
       `xi < yi` over two i32 thetas → `cq_template_icmp_slt_i32(hi, hj)` → a
       flag handle → `zext i1->i32` bridge → `cqrt_measure_i32`. The recovered
       logical width is i32 from each `cq_theta` mint (both operands are
       i32-laundered handles at the icmp, so the width is unrecoverable from
       their SSA type — Increment A feeds it from `HandleWidth`).

   (B) DEAD Q+Q — proves the `_unc` TWIN.
       `pi == qi` over two more i32 thetas → `cq_template_icmp_eq_i32(hp, hq)`,
       kept alive past `-O1` DCE by a `cq_phi` (Rz) keep-alive whose own result
       is dropped, then never measured/returned. The whole-DAG uncompute spine
       (gated OFF in `main`, so the `noinline` boundary is LOAD-BEARING)
       recovers the dead compare flag and reverses it ONCE via its void `_unc`
       twin `cq_template_icmp_eq_i32_unc(out, hp, hq)` (recompute-and-XOR from
       the live sources), then frees the rail. NO added measurement (Rules 5/6),
       NO `_inv`, NO `cqrt_cswap`.

   `noinline` is LOAD-BEARING (same as slice_uncompute_dead_dag.c): Phase-5
   uncompute is gated OFF in `main`, and at `-O1` clang would otherwise inline
   `slice` into `main` so the uncompute never runs. `cq_phi` (a side-effecting
   extern reading its operand) keeps the dead compare-B chain alive.

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh
   (-include CQ.h -I include). */
__attribute__((noinline))
void slice(int x, int y) {
    /* (A) measured Q+Q compare — proves the forward bare-QQ symbol. */
    int xi = cq_theta(x, 0.25);   /* taint x -> handle (alloc i32 + ry)   */
    int yi = cq_theta(y, 0.50);   /* taint y -> handle (alloc i32 + ry)   */
    int lt = (xi < yi);           /* icmp slt QQ -> flag -> zext -> measure */
    (void) cq_measure(lt);

    /* (B) dead, unmeasured Q+Q compare — proves the `_unc` twin. */
    int pi = cq_theta(x, 0.10);   /* alloc i32 + ry                       */
    int qi = cq_theta(y, 0.20);   /* alloc i32 + ry                       */
    int eq = (pi == qi);          /* icmp eq QQ -> flag (dead)            */
    cq_phi(0.30);      /* Rz keep-alive; result dropped (dead) */
}
int main(void) { slice(3, 7); return 0; }
