; condtree_classical_leaf_accept_zeroext_toggle.ll — ACCEPT (bd test_C_libtooling-xdu2.13).
;
; Rule-13 round 2 F-2 (reviewer probe q90): a `_Bool` toggled in a rolled loop
; (`f = !f` → `xor i1 %f, true` in a φ). The runtime's `bool b_classical`
; parameter is `zeroext` under Clang's ABI, and without the attribute the callee
; read non-0/1 bytes (measured 2/254/253 — UB for a C `bool`). The literal slot
; of the forward AND of its `_unc` now carries `zeroext`. The DATA path's `_hl`
; mints (bd ix2v) are NOT changed by this increment. Red on bc42274e (no
; `zeroext`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK: entry:
; CHECK: %f0 = trunc i32 %m to i1
; CHECK-NEXT: br label %loop
; CHECK: loop:
; CHECK-NEXT: %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
; CHECK-NEXT: %f = phi i1 [ %f0, %entry ], [ %fn, %loop ]
; CHECK-NEXT: %s = phi i32 [ 0, %entry ], [ %s1, %loop ]
; CHECK-NEXT: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %i)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 1)
; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %f)
; CHECK-NEXT: %[[V3:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[V4:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V4]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: %[[V5:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[V2]], i32 %[[V5]], i32 %[[V3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %f)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V1]], i32 %[[V0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V1]])
; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V3]])
; CHECK-NEXT: %s1 = add i32 %s, %[[V6]]
; CHECK-NEXT: %fn = xor i1 %f, true
; CHECK-NEXT: %i1 = add nuw nsw i32 %i, 1
; CHECK-NEXT: %done = icmp eq i32 %i1, 3
; CHECK-NEXT: br i1 %done, label %exit, label %loop
; CHECK: exit:
; CHECK-NEXT: ret i32 %s1
;
; NEG-NOT: select i1
; NEG-NOT: cq.predmux

define i32 @slice(i32 %m) {
entry:
  %f0 = trunc i32 %m to i1
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %f = phi i1 [ %f0, %entry ], [ %fn, %loop ]
  %s = phi i32 [ 0, %entry ], [ %s1, %loop ]
  %q = call i32 @cq_theta_si32(i32 %i, double 5.000000e-01)
  %t = icmp sgt i32 %q, 1
  %c = and i1 %t, %f
  %a = select i1 %c, i32 10, i32 7
  %ma = call i32 @cq_measure_si32(i32 %a)
  %s1 = add i32 %s, %ma
  %fn = xor i1 %f, true
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %s1
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
