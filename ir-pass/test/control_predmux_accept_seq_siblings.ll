; control_predmux_accept_seq_siblings.ll — ACCEPT (3c6m.14 L6 Inc 1): TWO
; SEQUENTIAL same-source sibling regions, pure-value — the 1dky shape (the
; first region's merge hosts the second's tainted br, which the block-lifetime
; guard declines today as `nested control flow under quantum control`). Each
; sibling here is itself NESTED (W1) so PredMux claims them; the fixpoint
; flattens one region per round (PRD-3c6m.14 §4.6) — the erf two-exp-bodies
; composition in miniature.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %r1a, label %m1
r1a:
  %v1 = add i32 %q, 1
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %r1b, label %m1
r1b:
  %v2 = xor i32 %v1, 3
  br label %m1
m1:
  %p1 = phi i32 [ %q, %entry ], [ %v1, %r1a ], [ %v2, %r1b ]
  %c3 = icmp sgt i32 %p1, 7
  br i1 %c3, label %r2a, label %m2
r2a:
  %v3 = mul i32 %p1, 5
  %c4 = icmp slt i32 %p1, 100
  br i1 %c4, label %r2b, label %m2
r2b:
  %v4 = add i32 %v3, 9
  br label %m2
m2:
  %p2 = phi i32 [ %p1, %m1 ], [ %v3, %r2a ], [ %v4, %r2b ]
  %m  = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}

; both regions flatten; the second's conditions read the FIRST region's muxed
; out-rail (onward control on %out — the yn71/dugh round-2 substrate):
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
