; spec_accept_multiexit_fp.ll — ACCEPT (bd p3kd.7.8; formerly
; spec_reject_multiexit_fp.ll, the 5po2 I2 defensive boundary). A GENUINE
; multi-exit (separate `ret` blocks) fp80 helper lifted with a quantum argument.
;
; WHY IT FLIPPED. The old decline guarded a mistyped-phi hazard that came from
; ORDER: `cloneFor` rewrote the fp return to an i32 handle BEFORE any lowering, so
; `normalizeReturnMerge` would have built an i32 phi over `x86_fp80` values; it
; bailed and the backstop declined. Owner ruling 2026-10-07 (Q2): the clone keeps
; its fp signature while main's stage list runs and is retyped afterwards
; (`retypeCloneSignature`), so the return merge is well typed and the clone
; lowers like the clang -O1 single-exit form (e2e spec_multiexit).
;
; helper(x) = x > 2.0 ? 1.0 : x*x. Lowered: the fmul and the fcmp flag, a
; controlled-copy merge of the |1.0> constant rail and x*x under the flag into a
; fresh rail, the copy-out, the mirror reverse; the |1.0> rail is a classical
; product state and stays allocated (R5), every |0> rail is freed after the reverse.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define x86_fp80 @example(
; CHECK:       call i32 @__cq_q_helper_1(i32
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK:       %[[SQ:[^ ]+]] = call i32 @cq_template_fmul_f80(i32 %x, i32 %x)
; CHECK-NEXT:  %[[F:[^ ]+]] = call i32 @cq_template_fcmp_ogt_f80_hl(i32 %x, x86_fp80 0xK40008000000000000000)
; CHECK-NEXT:  %[[OUT:[^ ]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK-NEXT:  %[[ONE:[^ ]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFF8000000000000000)
; CHECK-NEXT:  call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[ONE]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[SQ]], i32 %[[OUT]])
; CHECK-NEXT:  %[[CO:[^ ]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK-NEXT:  call void @cqrt_copy_f80(i32 %[[OUT]], i32 %[[CO]])
; CHECK-NEXT:  call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[SQ]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[ONE]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cq_template_fcmp_ogt_f80_hl_unc(i32 %[[F]], i32 %x, x86_fp80 0xK40008000000000000000)
; CHECK-NEXT:  call void @cq_template_fmul_f80_unc(i32 %[[SQ]], i32 %x, i32 %x)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SQ]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT:  ret i32 %[[CO]]
;
; The constant rail is never freed:
; RUN: %filecheck --check-prefix=KEEP %s < %t.ll
; KEEP:     %[[ONE:[^ ]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFF8000000000000000)
; KEEP-NOT: call void @cqrt_free(i32 %[[ONE]])

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @helper(x86_fp80 %x) {
entry:
  %t = fcmp ogt x86_fp80 %x, 0xK40008000000000000000
  br i1 %t, label %a, label %b
a:
  ret x86_fp80 0xK3FFF8000000000000000
b:
  %m = fmul x86_fp80 %x, %x
  ret x86_fp80 %m
}

define x86_fp80 @example(x86_fp80 %u) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  %r = call x86_fp80 @helper(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

