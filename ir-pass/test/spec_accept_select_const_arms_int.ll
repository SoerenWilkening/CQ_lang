; spec_accept_select_const_arms_int.ll — ACCEPT (bd p3kd.7.1): an INTEGER select
; with TWO constant arms inside a lifted callee, `(b > 5) ? 7 : 9` (the `clang -O1`
; spelling of `if (b > 5) return 7; return 9;`). Openlibm's exp/expf/tgammal and
; remquof carry this shape (`select i1 %c, i32 C1, i32 C2`). `scanBody` used to
; admit an integer select only with a const-ZERO false arm or two derived arms, so
; this declined `InBodyControl` although `lowerCloneSelect` already lowers it: each
; `ConstantInt` arm is materialized to its own `cqrt_alloc_i32(<K>)` rail by
; `materializeCopySource` (the fp `ConstantFP` arm of bd 20xt.3, integer edition),
; controlled-copied into the |0> select rail under the flag (true arm) and under
; the X-bracketed ¬flag (false arm), and left allocated (separable classical data,
; never reversed, never freed). The Bennett reverse replays the two copies in
; reverse order inside their brackets, then the compare `_unc`, and frees only the
; flag and the select rail.
;
; Trace check, |b> basis state: flag = [b > 5]; sel = flag·7 ⊕ ¬flag·9; out = sel.
; Reverse: ¬flag·9 then flag·7 restore sel to |0>; the `_unc` restores the flag.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp sgt i32 %b, 5
  %s = select i1 %t, i32 7, i32 9
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %[[H]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[R]])
;
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K7]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  %[[K9:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 9)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K9]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K9]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K7]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
