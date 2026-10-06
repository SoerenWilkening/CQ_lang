; spec_accept_select_classical_cond_const_arm.ll — ACCEPT (bd p3kd.7.2; was
; spec_reject_select_mixed_param.ll, the 5po2 slice-1 load-bearing safety gate):
; `select(icmp(c, 5), b, 0)` with `b` quantum and `c` classical. A classical choice
; of rail (owner ruling 2026-10-06; CloneRailSelect.h): the constant arm 0 is
; materialized to its own rail (left allocated, separable classical data) and the
; select picks either the BORROWED parameter `b` or that rail. The copy-out reads
; the chosen rail and never writes it; there is no forward gate, so nothing is
; reversed and nothing is freed (the copy-out rail is returned).
;
; Trace check: out = (c < 5) ? b : 0, the source.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  %t = icmp slt i32 %c, 5            ; condition tests %c, true arm routes %b
  %s = select i1 %t, i32 %b, i32 0
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %u1)   ; arg0 tainted, arg1 classical
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_01(i32 %b, i32 %c)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[C:[a-zA-Z0-9_.]+]] = icmp slt i32 %c, 5
; CHECK-NEXT:  %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[FC:[a-zA-Z0-9_.]+]] = freeze i1 %[[C]]
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = select i1 %[[FC]], i32 %b, i32 %[[K]]
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S]], i32 %[[OUT]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
