; spec_accept_select_derived_true.ll — ACCEPT (bd p3kd.7.1; was
; spec_reject_select_derived_true.ll, a 5po2 slice-1 accept-shape boundary): a
; lifted `select` whose TRUE arm is the DERIVED value `b + 1` and whose false arm
; is constant zero. The retired `isLiftableSelect` required a param-direct true
; arm next to a zero false arm, so this declined `InBodyControl`, although
; `lowerCloneSelect`'s one-copy fast path lowers it: the derived arm is a data
; template captured into the forward stream, controlled-copied into the |0> select
; rail, and reversed and freed by the Bennett wrap.
;
; Trace check, |b>: flag = [b < 5]; sel = flag·(b+1); out = sel. Reverse: the
; copy, then the compare `_unc`, then the add `_unc`, so every scratch rail is |0>
; before its free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %d = add i32 %b, 1
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %d, i32 0   ; derived (non-param) true arm
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[D]], i32 %[[SEL]])
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[D]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
