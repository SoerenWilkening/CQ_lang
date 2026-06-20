/* specialize_intrinsic_lib.c — the CLASSICAL library translation unit for the
   Phase 7.1-E follow-up golden (test_C_libtooling-mvjc). Like specialize_lib.c it
   must compile WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh
   applies `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at
   compile if the harness ever force-includes CQ.h into a lib TU.

   `popcount_helper` is exactly the body the 7.1-E follow-up accepts: a VISIBLE,
   PURELY-CLASSICAL, NON-RECURSIVE, single-basic-block i32 body whose only
   non-arithmetic op is a CURATED reversible intrinsic. `__builtin_popcount`
   lowers (clang -O1) to `@llvm.ctpop.i32`, which `isCuratedReversibleIntrinsic`
   recognizes by exact id + table width. The caller hands a TAINTED argument, so
   the specializer clones it into `__cq_q_popcount_helper_1`, lowers the ctpop to
   the frozen `cq_template_ctpop_i32` producer and the `+ 1` to an `_hl` add, and
   Bennett-wraps it (compute -> cqrt_copy_i32 -> LIFO reverse via `_unc` ->
   free) — the `_unc` of the Class-2 ctpop recomputing from the still-live
   source. Pre-follow-up this whole candidate loud-declined (the intrinsic read as
   a declaration-only nested call). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int popcount_helper(int a) {
    return __builtin_popcount(a) + 1;
}
