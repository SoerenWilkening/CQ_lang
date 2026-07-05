/* spec_chained_ctl_lib.c — the CLASSICAL library TU for the bd afmv e2e golden (the chained
   onward-control -> spec re-plan miscompile fix). Like spec_replan_qpow_lib.c it MUST compile
   WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh applies `-include CQ.h` to the
   CQ TU only); the tripwire below fails LOUDLY at compile if the harness ever force-includes
   CQ.h into a lib TU.

   `gg` is a TWO-parameter pure-classical straight-line i32 body (`a*b`). In this slice the
   caller passes `gg(w, q)` where `q` is the theta handle (round-1 quantum, so gg is a ROUND-1
   Phase-6 Pending candidate, mask 0b10) and `w` is the region-2 yn71 control rail `%out2`
   (quantum only after the round-2 control fixpoint). The afmv fix re-widens gg's mask to 0b11
   so the driver clones @__cq_q_gg_11 with `mul a,b` lowering bare-QQ (the %out2 rail read as a
   HANDLE, `cq_template_mul_i32` NOT `_hl` — the miscompile fix). Bennett-wrapped (compute ->
   cqrt_copy_i32 -> reverse-play -> free); the borrowed quantum inputs q and %out2 are
   read-only-preserved, left allocated (Rule-6 safe leak). The ONLY layer that LINK-proves
   @__cq_q_gg_11 + the cq_template_mul_i32 QQ producer + its _unc twin resolve and
   signature-match through llvm-link. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int gg(int a, int b) {
    return a * b;
}
