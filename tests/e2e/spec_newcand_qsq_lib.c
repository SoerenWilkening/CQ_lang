/* spec_newcand_qsq_lib.c — the CLASSICAL library TU for the bd 9paa e2e golden
   (the round-2 spec-clone DETECTION). Like spec_replan_qpow_lib.c it MUST compile
   WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh applies
   `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at compile if
   the harness ever force-includes CQ.h into a lib TU.

   `qsq` is a SINGLE-parameter pure-classical straight-line i32 body (`v*v`). In this
   slice the caller passes `qsq(y)` where `y` is the control-merge register `%out`
   (round-2 quantum) and NO round-1 theta handle — so it reads NO tainted operand at
   `detectSpecializations` (pre-emit) and is never a round-1 candidate. 9paa's round-2
   `detectSpecializations` (in `repropagateControlMerges`, after `%out` re-taints)
   DETECTS it and the driver clones @__cq_q_qsq_1 with `mul v,v` lowering bare-QQ (the
   merged register read as a HANDLE, not an `_hl` classical literal — the D2 miscompile
   fix). Bennett-wrapped (compute -> cqrt_copy_i32 -> reverse-play -> free the scratch);
   the borrowed quantum input `%out` is read-only-preserved, left allocated (Rule-6 safe
   leak). This is the ONLY layer that LINK-proves @__cq_q_qsq_1 + the cq_template_mul_i32
   QQ producer + its _unc twin resolve and signature-match through llvm-link. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int qsq(int v) {
    return v * v;
}
