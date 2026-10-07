; spec_accept_fp_select_constconst_f80.ll — ACCEPT (bd 20xt.3, the
; materialize-classical-arm widening): a CONST/CONST x86_fp80 select inside a
; Phase-6 lifted clone — the atan2l → inner `atanl` |x|≥2^64 overflow arm
; `z = (expsign<0) ? -π/2 : +π/2` (s_atanl.c block %20; both arms `ConstantFP`).
; Before 20xt.3 `isLiftableFpSelect` required BOTH arms non-constant, so this was
; the FIRST blocker of the atan2l cell (InBodyControl). Now each fp `ConstantFP`
; arm is materialized to a fresh `cqrt_alloc_f80(<const>)` |const⟩ rail via
; `materializeCopySource` and controlled-copied into the |0⟩ out rail — the SAME
; two-copy kjd1 stream the value/value fabs shape emits (Rule 14). The two
; materialized |const⟩ rails are separable classical data: LEFT allocated (leaked,
; Rule 6), NEVER freed; each copy is captured + reverse-played by the Bennett wrap,
; and the out rail is uncomputed to |0⟩ and freed. A `fptosi` reads the merge rail
; (the p119.6 clone-HandleWidth compose) so the return copies out an i32 handle.
; (Hand-written: clang -O1 const-folds a const-cond fp select and never emits the
; select; this pins the shape that survives a genuine tainted-cond overflow arm.)
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list (main's 4.4
; CondTreeEmit flag + SelectMergeEmit merge, which materializes each constant arm
; through the same SelectMergeEmit `materializeCopySource` named above). The
; two-copy stream and both |const> materializations are unchanged. What moved: the
; merge's own flag strip (trailing `cqrt_x`, compare `_unc`, free) is elided inside a
; clone, so the forward ends with the bracket OPEN (F = [n<=0]) and the mirror's
; single `cqrt_x` between the two copies closes it. Hand trace, |n>: SEL = [n>0]·T
; ⊕ [n<=0]·FA = (n>0)?+pi/2:-pi/2 (f80 bit patterns), R = fptosi(SEL); the mirror's
; fptosi `_unc` zeroes R, the ¬flag copy XORs FA back, F→[n>0], the flag copy XORs
; T back (SEL = +0.0, all bits 0), the `_unc` zeroes F. F, SEL and R are |0> at
; their frees; T and FA (non-zero constants) stay allocated, which the full-body
; CHECK-NEXT pin through `}` enforces (it replaces the old CHECK-NOTs, which scanned
; only the window between SEL's free and the `ret`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %c = icmp sgt i32 %n, 0
  %a = select i1 %c, x86_fp80 0xK3FFFC90FDAA22168C235, x86_fp80 0xKBFFFC90FDAA22168C235
  %r = fptosi x86_fp80 %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; The sgt flag over the tainted param, then the |0> f80 out rail.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %n, i32 0)
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; TRUE const (+pi/2) materialized to its own |const> rail, copied on the flag.
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFFC90FDAA22168C235)
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; FALSE const (-pi/2) materialized to its own |const> rail, copied on the ¬flag.
; CHECK-NEXT: %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xKBFFFC90FDAA22168C235)
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[FA]], i32 %[[SEL]])
; The fptosi reads the merge rail (p119.6 clone-HandleWidth), then copy-out.
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f80_to_i32(i32 %[[SEL]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[OUT]])
; Bennett reverse, the exact mirror: the fptosi `_unc`, the self-inverse copies
; (reading the STILL-LIVE materialized const rails) around the closing `cqrt_x`,
; the flag `_unc`, then the proven-|0> frees.
; CHECK-NEXT: call void @cq_template_fptosi_f80_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[FA]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %n, i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; The two |const> rails ([[T]], [[FA]]) are LEAKED — never freed (Rule 6): the
; body ends here.
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
