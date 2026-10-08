; control_classical_call_arm_accept_noundef_return_total.ll — ACCEPT (bd test_C_libtooling-bwfp).
; The positive twin of control_classical_call_arm_twin_accept_noundef_return_poison.ll
; (a bwfp decline until dm7f.21 hoisted a speculation-safe twin there).
; `@pf`'s return is `noundef`, and its body creates no poison, so a defined argument
; gives a defined result. The argument `%a` is `add nsw` (poison on overflow) and
; `@pf`'s parameter is NOT `noundef`, but its poison would flow through the body to the
; `noundef` return: the hoist freezes it (`hoistedArgPoisonIsUB`), like a `noundef`
; parameter's argument (bd 9hea).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = add nsw i32 %k, 1
; CHECK:       %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %[[A]]
; CHECK-NEXT:  %[[R:[a-zA-Z0-9_.]+]] = call i32 @pf(i32 %[[FR]])
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal noundef i32 @pf(i32 %x) #0 {
entry:
  %c = icmp eq i32 %x, 7
  %v = select i1 %c, i32 1, i32 2
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %a = add nsw i32 %k, 1
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
