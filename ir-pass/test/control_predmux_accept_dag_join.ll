; control_predmux_accept_dag_join.ll — ACCEPT (3c6m.14 L6 Inc 1): CROSS-ARM
; DAG reconvergence — an interior join reached from TWO DIFFERENT arms of the
; outer branch (the scalbn `.thread4.i` shape), with TWO phis at the join whose
; muxed outputs feed further speculated ops before the return merge. The join
; block's predicate is a genuine OR of two edge predicates (PRD-3c6m.14 §4.3).
; Today: `nested control flow under quantum control`.
;
;   if (q > 5) { t = q+1; if (q > 7) goto join;      else goto merge(t); }
;   else       { t = q+2; if (q < 2) goto join;      else goto merge(q^5); }
;   join: (u = phi t; v = phi const) w = u+v -> merge(w)
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
  br i1 %c1, label %left, label %right
left:
  %t1 = add i32 %q, 1
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %join, label %merge
right:
  %t2 = add i32 %q, 2
  %c3 = icmp slt i32 %q, 2
  br i1 %c3, label %join, label %rtail
rtail:
  %t3 = xor i32 %q, 5
  br label %merge
join:
  %u = phi i32 [ %t1, %left ], [ %t2, %right ]
  %v = phi i32 [ 4, %left ], [ 9, %right ]
  %w = add i32 %u, %v
  br label %merge
merge:
  %rm = phi i32 [ %t1, %left ], [ %t3, %rtail ], [ %w, %join ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; the join's two phis mux under the SAME edge predicate (c1∧c2, re-minted per
; select — the cleared per-select flag lifecycle), the const arm preloads a
; literal rail, the speculated add recombines the two muxed rails (QQ
; template), then the return chain applies rm = (c1∧¬c2)?t1:((¬c1∧¬c3)?t3:w):
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; u-mux: flag c1∧c2 picks t1 over t2
; CHECK:     %[[C1A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[C2A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_toffoli(i32 %[[C1A]], i32 %[[C2A]],
; CHECK:     call void @cqrt_copy_i32_controlled(
; v-mux: same predicate, const arms preload literal rails 4 / 9
; CHECK:     call void @cqrt_toffoli(
; CHECK:     %[[K4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[K4]],
; CHECK:     %[[K9:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 9)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[K9]],
; the speculated join-body add recombines the two mux out-rails (QQ form):
; CHECK:     call i32 @cq_template_add_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; return chain inner select: ¬c1∧¬c3 = (sle 5)∧(sge 2)
; CHECK:     call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 2)
; CHECK:     call void @cqrt_toffoli(
; return chain outer select: c1∧¬c2 = (sgt 5)∧(sle 7)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
