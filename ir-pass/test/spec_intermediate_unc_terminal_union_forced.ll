; spec_intermediate_unc_terminal_union_forced.ll — ACCEPT (bd test_C_libtooling-p3kd.13,
; R11 review round 3, F3): the terminal UNION reaching the frontier FIXPOINT, which
; leaves the shared template interior as a FORCED record. Reviewer probe P2.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int fr(int m)  { int q = m & 7; cq_theta(&q, .5); int a = q + 2; cq_theta(&q, .3);
;                      int t = a * 5; cq_theta(&t, .4); int r = h(a); cq_theta(&r, .2);
;                      return cq_measure(q); }
;     int frk(int m) { ... the same with `int t2 = a * 7; cq_theta(&t2, .2);` for r }
;
; @fr — NEW ACCEPT. The template terminal t alone leaves `a` open (the clone call
;   consumes it outside the group), and main DECLINES (`dead chain would free a
;   measured register`). The union probe plans out through the frontier fixpoint:
;   q moved (`cq_theta(&q, .3)`) between a's birth and its later readers, so `a` is
;   a FORCED record (left allocated, never freed) while t and r are each reversed at
;   their own anchor — t's `mul_unc` and free, then r's Ry, twin and free.
; @frk — the all-template control main already lowers: @fr's disposition equals it
;   gate for gate, with the twin where @frk has `mul_unc`.
; @fr is the `!TmplOk` branch's ACCEPT direction (R11 r5; the decline direction is
;   the spec_intermediate_unc_terminal_union_reject_* family — borrowed_divergent,
;   measured_store, clone_store, measured_rail_cut{,_divergent}): the union's first
;   frontier borrows only the measured q and cuts nothing but q's own Rys, and
;   only the fixpoint forces `a`, whose borrow cuts nothing but a's own `add`: so
;   `GroupProbe::Cut`, taken against the FINAL frontier since R11 r8, is empty.
;   A mutant requiring the union to reverse-play that whole first DAG declines @fr
;   (measured, snapshot 4433275d: rc 1, `dead chain would free a measured register`).
; Stage 2b on this module: 8 frees verified, 0 violations; 2 rails left dirty —
; the forced record `a` of @fr and of @frk alike.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define i32 @fr(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[A]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[A]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[A]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; The forced record `a` is never adjointed or freed: the CHECK-NEXT chain above
; covers every line from the alloc to the measure, and these two the rest of @fr
; (R11 r4 F-C: the `add_unc` half was claimed and not checked).
; CHECK-NOT:  add_i32_hl_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[A]])
; CHECK:      ret i32

; CHECK-LABEL: define i32 @frk(
; CHECK:      %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(
; CHECK-NOT:  add_i32_hl_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[A2]])
; CHECK:      call void @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[A2]], i32 5)
; CHECK-NOT:  add_i32_hl_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[A2]])
; CHECK:      call void @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[A2]], i32 7)
; CHECK-NOT:  add_i32_hl_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[A2]])
; CHECK:      ret i32

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1
declare i32 @cq_measure_si32(i32 noundef) #1

define i32 @fr(i32 noundef %0) #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = add nsw i32 %3, 2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #4
  %6 = mul nsw i32 %4, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #4
  %8 = tail call fastcc i32 @h(i32 noundef %4)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %10
}

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @frk(i32 noundef %0) #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = add nsw i32 %3, 2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #4
  %6 = mul nsw i32 %4, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #4
  %8 = mul nsw i32 %4, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %10
}
attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
