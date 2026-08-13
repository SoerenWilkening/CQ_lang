; control_predmux_accept_twophi_merge.ll — ACCEPT (3c6m.14 L6 Inc 1): an
; interior merge with TWO phis sharing the same edge predicates (the lround
; %50/%103 shape: hi/lo words muxed together), whose muxed outputs are
; recombined by further speculated ops before the return. Witness W3 (≥2 phis).
; Today: `nested control flow under quantum control` (multi-phi merges have no
; owner). The shared condition flag across two selects is the p2-probed
; substrate shape.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm, label %inner
inner:
  %c2 = icmp slt i32 %q, 2
  br i1 %c2, label %arm2, label %join
arm:
  %a1 = add i32 %q, 1
  %b1 = xor i32 %q, 7
  br label %join
arm2:
  %a2 = mul i32 %q, 3
  br label %join
join:
  %u = phi i32 [ %a1, %arm ], [ %a2, %arm2 ], [ %q, %inner ]
  %v = phi i32 [ %b1, %arm ], [ 11, %arm2 ], [ 13, %inner ]
  %w = add i32 %u, %v
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 2)
; two select chains (one per phi) over the same predicates, then the add:
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cq_template_add_i32(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
