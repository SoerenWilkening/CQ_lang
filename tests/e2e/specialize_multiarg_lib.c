/* specialize_multiarg_lib.c — the CLASSICAL library TU for the Phase 6.2 golden
   (test_C_libtooling-mvna.8, WI-2.6). Like specialize_lib.c it MUST compile
   without the CQ.h intrinsic surface (C18 — run_slice_multi.sh applies
   `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at compile
   if the harness ever force-includes CQ.h into a lib TU.

   `combine` is a TWO-parameter pure-classical straight-line i32 body. The caller
   hands it THREE call sites with two DISTINCT taint signatures:
     * combine(quantum, classical) → mask 0b01 → clone @__cq_q_combine_01, where
       arg0 is the handle: `t = a + b` lowers HL (handle+classical) and the reuse
       of arg0 in `t * a` lowers QQ (handle+handle).
     * combine(classical, quantum) → mask 0b10 → clone @__cq_q_combine_10, the
       OPPOSITE orientation: arg1 is the handle, so `t * a` reads arg0 classically
       and lowers HL. The two clones therefore have GENUINELY different gate
       streams — the (callee,mask) cache key earning its keep (C7), not a rename.
   A third site repeats combine(quantum, classical): same (callee,mask) → CACHE
   HIT, reusing @__cq_q_combine_01 (no second clone). This is the only layer that
   LINK-proves both distinct clones + the shared one resolve and signature-match
   through llvm-link. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int combine(int a, int b) {
    int t = a + b;
    return t * a;
}
