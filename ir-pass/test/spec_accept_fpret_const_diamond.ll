; spec_accept_fpret_const_diamond.ll — Phase 6 / issue 5po2 I2 (Rule-13
; CONFIRMED-finding regression probe, the POSITIVE half): an fp-return diamond whose
; BOTH arms are classical fp constants (`if(q>C) return 1.0 : return 0.75` — the
; overflow/underflow-sentinel shape, pre-merged by clang -O1 into a single-exit
; merge phi of constants) now LOWERS to a correct reversible embedding. The fix is in
; `predictReturnTainted`: a constant/const-phi return that is CONTROL-DEPENDENT on a
; tainted branch is not param-derived (a constant is not a param user), so the
; param-forward closure missed it and UNDER-predicted classical — `cloneFor` then kept
; the `x86_fp80` return while `lowerCloneSelect` minted a tainted i32 out rail → a
; mistyped `ret` (a verify-DIRTY / broken module, exit 134, NO house diagnostic).
; `predictReturnTainted` now over-approximates: a tainted conditional terminator ⇒
; predict the return tainted ⇒ `cloneFor` rewrites the return to i32. The clone
; MATERIALIZES both fp sentinels (leaked |const⟩ rails), muxes via
; `cqrt_copy_f80_controlled`, copies out via `cqrt_copy_f80`, and returns the i32
; handle. (A genuine separate-`ret` multi-exit fp form used to decline via the
; `normalizeReturnMerge` type-guard; since bd p3kd.7.8 it lowers too —
; `spec_accept_multiexit_fp.ll`, formerly `spec_reject_multiexit_fp.ll`.)
;
; bd p3kd.7.8: main's stage list now lowers the clone. The clone keeps its
; `x86_fp80` signature during main's stages and `retypeCloneSignature` installs
; the i32 handle afterwards (still gated on `predictReturnTainted`); the merge is
; main's SelectMergeEmit (rail `%out`, was `%cqq.sel`), the forward's closing
; `cqrt_x` strip is elided by the Bennett wrap, and the reverse is the exact
; mirror. Hand trace, flag t=[x>C]: copy_c(t,|1.0>) then copy_c(¬t,|0.75>) gives
; out = t ? 1.0 : 0.75; copy-out; the mirror replays copy_c(¬t,|0.75>), `cqrt_x`
; (flag back to t), copy_c(t,|1.0>) (out back to 0) and the fcmp `_unc`, so the
; flag and `out` are |0> at their frees. The |1.0>/|0.75> rails are non-zero
; constants and stay allocated (CHECK-NEXT body: no free for them).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @helper(x86_fp80 %x) {
entry:
  %t = fcmp ogt x86_fp80 %x, 0xK4005C700000000000000
  br i1 %t, label %a, label %b
a:
  br label %m
b:
  br label %m
m:
  %r = phi x86_fp80 [ 0xK3FFF8000000000000000, %a ], [ 0xK3FFE8000000000000000, %b ]
  ret x86_fp80 %r
}

define x86_fp80 @example(x86_fp80 %u) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  %r = call x86_fp80 @helper(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

; the caller passes the handle and measures the returned handle:
; CHECK-LABEL: define x86_fp80 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %
; CHECK:       call x86_fp80 @cqrt_measure_f80(i32 %[[R]])
; the tainted-controlled const-return clone is rewritten to an i32-handle return:
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[FL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f80_hl(i32 %x, x86_fp80 0xK4005C700000000000000)
; both fp sentinels materialized into leaked |const⟩ rails, muxed on the flag:
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK-NEXT:  call void @cqrt_xorc_f80_controlled(i32 %[[FL]], i32 %[[SEL]], x86_fp80 0xK3FFF8000000000000000)
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FL]])
; CHECK-NEXT:  call void @cqrt_xorc_f80_controlled(i32 %[[FL]], i32 %[[SEL]], x86_fp80 0xK3FFE8000000000000000)
; the fp copy-out to the i32 handle + the single Bennett mirror + frees:
; CHECK-NEXT:  %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK-NEXT:  call void @cqrt_copy_f80(i32 %[[SEL]], i32 %[[CO]])
; CHECK-NEXT:  call void @cqrt_xorc_f80_controlled(i32 %[[FL]], i32 %[[SEL]], x86_fp80 0xK3FFE8000000000000000)
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FL]])
; CHECK-NEXT:  call void @cqrt_xorc_f80_controlled(i32 %[[FL]], i32 %[[SEL]], x86_fp80 0xK3FFF8000000000000000)
; CHECK-NEXT:  call void @cq_template_fcmp_ogt_f80_hl_unc(i32 %[[FL]], i32 %x, x86_fp80 0xK4005C700000000000000)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[FL]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  ret i32 %[[CO]]
; CHECK-NEXT:  }
