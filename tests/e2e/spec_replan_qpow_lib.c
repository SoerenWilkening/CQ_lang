/* spec_replan_qpow_lib.c — the CLASSICAL library TU for the bd 0vvq Increment 2
   e2e golden (the Phase-6 spec-clone RE-PLAN). Like specialize_multiarg_lib.c it
   MUST compile WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh
   applies `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at
   compile if the harness ever force-includes CQ.h into a lib TU.

   `qpow` is a TWO-parameter pure-classical straight-line i32 body (`base*base +
   exp`) — the exact shape the ir-pass fixture control_classical_call_arm_accept_
   onward_spec_call.ll pins. In this slice the caller passes `qpow(q, y)` where `q`
   is the theta handle (round-1 quantum) and `y` is the control-merge register
   `%out` (round-2 quantum). At `detectSpecializations` (pre-emit) `y` is untainted,
   so the candidate is FROZEN mask `0b01`; `repropagateControlMerges`'s round-2
   re-plan recomputes it to `0b11`, so the driver clones @__cq_q_qpow_11 with BOTH
   `mul base,base` and `add sq,exp` lowering bare-QQ (the merged register read as a
   HANDLE, not an `_hl` classical literal — the D2 miscompile fix). Bennett-wrapped
   (compute -> cqrt_copy_i32 -> reverse-play -> free); the borrowed quantum inputs
   `q` and `%out` are read-only-preserved, left allocated (Rule-6 safe leak). This
   is the ONLY layer that LINK-proves @__cq_q_qpow_11 + the cq_template_*_i32 QQ
   producers + their _unc twins resolve and signature-match through llvm-link. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int qpow(int base, int exp) {
    int sq = base * base;
    return sq + exp;
}
