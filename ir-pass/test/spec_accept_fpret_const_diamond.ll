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
; handle. (A genuine separate-`ret` multi-exit fp form declines cleanly via the
; `normalizeReturnMerge` type-guard — `spec_reject_multiexit_fp.ll`.)
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

; the tainted-controlled const-return clone is rewritten to an i32-handle return:
; CHECK: define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK: %h_cmp = call i32 @cq_template_fcmp_ogt_f80_hl(i32 %x, x86_fp80 0xK4005C700000000000000)
; both fp sentinels materialized into leaked |const⟩ rails, muxed on the flag:
; CHECK: %selop = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFF8000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %h_cmp, i32 %selop, i32 %cqq.sel)
; CHECK: %selop1 = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFE8000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %h_cmp, i32 %selop1, i32 %cqq.sel)
; the fp copy-out to the i32 handle + the single Bennett reverse + frees:
; CHECK: %cqq.out = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK: call void @cqrt_copy_f80(i32 %cqq.sel, i32 %cqq.out)
; CHECK: call void @cq_template_fcmp_ogt_f80_hl_unc(i32 %h_cmp, i32 %x, x86_fp80 0xK4005C700000000000000)
; CHECK: ret i32 %cqq.out
