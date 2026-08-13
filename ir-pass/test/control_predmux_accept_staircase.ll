; control_predmux_accept_staircase.ll — ACCEPT (3c6m.14 L6 Inc 1): the
; STAIRCASE of chained early-exits (the cbrt/libm early-return idiom) — a
; single return merge with FOUR incomings from different nest depths, single
; phi (>2 incomings = witness W3, nested terminators = W1). Today:
; `nested control flow under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i64 @cq_theta_sl(i64, double)
declare i64 @cq_measure_sl(i64)

define i64 @probe(i64 %u0) {
entry:
  %q  = call i64 @cq_theta_sl(i64 %u0, double 5.000000e-01)
  %c1 = icmp sgt i64 %q, 100
  br i1 %c1, label %exit1, label %s2
exit1:
  %e1 = add i64 %q, 1
  br label %merge
s2:
  %c2 = icmp sgt i64 %q, 50
  br i1 %c2, label %exit2, label %s3
exit2:
  %e2 = xor i64 %q, 2
  br label %merge
s3:
  %c3 = icmp sgt i64 %q, 10
  br i1 %c3, label %exit3, label %s4
exit3:
  %e3 = mul i64 %q, 3
  br label %merge
s4:
  %e4 = add i64 %q, 4
  br label %merge
merge:
  %rm = phi i64 [ %e1, %exit1 ], [ %e2, %exit2 ], [ %e3, %exit3 ], [ %e4, %s4 ]
  %m  = call i64 @cq_measure_sl(i64 %rm)
  ret i64 %m
}

; i64 data path end-to-end; the chain (innermost select first in the stream):
;   out   = (¬c1∧¬c2)∧c3 ? e3 : e4     [two chained Toffolis]
;   out10 = ¬c1∧c2       ? e2 : out
;   out14 = c1           ? e1 : out10
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK:     %[[NC1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sle_i64_hl(i32 %[[Q]], i64 100)
; CHECK:     %[[NC2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sle_i64_hl(i32 %[[Q]], i64 50)
; CHECK:     %[[G1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[NC1]], i32 %[[NC2]], i32 %[[G1]])
; CHECK:     %[[C3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[Q]], i64 10)
; CHECK:     call void @cqrt_toffoli(i32 %[[G1]], i32 %[[C3]],
; CHECK:     call void @cqrt_copy_i64_controlled(
; CHECK:     call i32 @cq_template_icmp_sle_i64_hl(i32 %[[Q]], i64 100)
; CHECK:     call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[Q]], i64 50)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i64_controlled(
; CHECK:     call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[Q]], i64 100)
; CHECK:     call void @cqrt_copy_i64_controlled(
; CHECK:     call i64 @cqrt_measure_i64(
; CHECK-NOT: br i1
; CHECK-NOT: phi i64
; CHECK-NOT: select i1
