; spec_accept_clone_switch_unreachable_default.ll — ACCEPT (bd p3kd.7.1): an
; exhaustive tainted switch whose default is `unreachable`, the shape `clang -O1`
; emits for `switch (x & 3)` with all four cases written (openlibm's atan2 family
; carries it). `scanBody` admitted neither the `switch` nor the `unreachable`
; terminator. The clone's PredMux tolerates the `unreachable` sink (bd 20xt.5 (d):
; no basis state enters it, so it contributes no merge incoming) and flattens the
; switch into a three-select chain whose base is the last listed case; the
; `unreachable` block is erased. `lowerCloneSelect` lowers the chain.
;
; Trace check, |x> basis state, k = x & 3:
;   s1 = [k==2]·(5x) ⊕ [k!=2]·(x-1)
;   s2 = [k==1]·(x+4) ⊕ [k!=1]·s1
;   s3 = [k==0]·3 ⊕ [k!=0]·s2
; k=0 → 3, k=1 → x+4, k=2 → 5x, k=3 → x-1: the switch on every reachable k.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %k = and i32 %x, 3
  switch i32 %k, label %dflt [
    i32 0, label %merge
    i32 1, label %one
    i32 2, label %two
    i32 3, label %three
  ]
one:
  %a1 = add i32 %x, 4
  br label %merge
two:
  %a2 = mul i32 %x, 5
  br label %merge
three:
  %a3 = add i32 %x, -1
  br label %merge
dflt:
  unreachable
merge:
  %r = phi i32 [ 3, %entry ], [ %a1, %one ], [ %a2, %two ], [ %a3, %three ]
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(
; CHECK:       call i32 @__cq_q_helper_1(i32
;
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[K:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %x, i32 3)
; CHECK-NEXT:  %[[A3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %x, i32 -1)
; CHECK-NEXT:  %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %x, i32 5)
; CHECK-NEXT:  %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %x, i32 4)
; CHECK-NEXT:  %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 2)
; CHECK-NEXT:  %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[A2]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[A3]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT:  %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 1)
; CHECK-NEXT:  %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[A1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 0)
; CHECK-NEXT:  %[[S3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[K3]], i32 %[[S3]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[S2]], i32 %[[S3]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S3]], i32 %[[OUT]])
; The reverse: every copy inside its bracket in reverse order, then the three
; compare `_unc`s and the four data `_unc`s, then the frees.
; CHECK:       call void @cq_template_and_i32_hl_unc(i32 %[[K]], i32 %x, i32 3)
; CHECK-NOT:   call void @cqrt_free(i32 %[[K3]])
; CHECK:       call void @cqrt_free(i32 %[[S3]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
