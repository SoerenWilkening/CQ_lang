; spec_intermediate_unc_leak_select_gap.ll — ACCEPT, LEFT ALLOCATED: a KNOWN GAP,
; pinned at PARITY (bd test_C_libtooling-p3kd.13). A clone result consumed ONLY by
; a tainted `select`'s merge stays allocated — exactly as a TEMPLATE intermediate
; in the same position does.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int sel_clone(int m)    { int q = m & 7; cq_theta(&q, .5); int p = h(q);
;                               int s = (q > 2) ? p : q + 1; return cq_measure(s); }
;     int sel_template(int m) { ... int p = q * 3 + 1; int s = (q > 2) ? p : q + 1; ... }
;
; WHY. The 4.4 merge (`SelectMergeEmit`) READS the arm value through
; `cqrt_copy_<W>_controlled(flag, arm, out)`, and the M-B interior predicate
; (`ChainWalk::isInteriorConsumer`) refuses every `_controlled` gate as a
; consumer, so neither arm rail is an interior candidate: `%3` (the clone) and
; `%h_op` (the template `mul`) both leak, and stage 2b counts them dirty. p3kd.13
; gave clone results the template's discharge, not more; this shape is a gap of
; BOTH.
;
; MEASURED (2026-10-08): admitting a controlled copy's READ slots as an interior
; consumer discharges both rails here (prototype, not shipped) and changes the
; lowered output of 139 existing lit fixtures (rc and diagnostics unchanged), the
; PredMux / select-merge / rail-bank families — a template-wide capability change
; that needs its own review. Filed as the follow-up drafted in the p3kd.13 report.
;
; RETIREMENT TRIGGER (L7): when a controlled copy's source becomes an interior
; consumer, both functions discharge their arm rail after the copy; flip this file
; to an ACCEPT, DISCHARGED pin then.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @sel_clone(
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[R]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT:  @__cq_q_h_1_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[R]])
; CHECK:      ret i32

; CHECK-LABEL: define i32 @sel_template(
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT:  @cq_template_mul_i32_hl_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[T]])
; CHECK:      ret i32

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @sel_clone(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = icmp sgt i32 %3, 2
  %6 = add nsw i32 %3, 1
  %7 = select i1 %5, i32 %4, i32 %6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %8
}

define i32 @sel_template(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = mul nsw i32 %3, 3
  %5 = icmp sgt i32 %3, 2
  %6 = select i1 %5, i32 %4, i32 %3
  %7 = add nsw i32 %6, 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %8
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
