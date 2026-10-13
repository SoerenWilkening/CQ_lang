; spec_intermediate_unc_terminal_union_percomp.ll — ACCEPT, PER COMPONENT (bd
; test_C_libtooling-p3kd.13, R11 review round 6, I1): a `!TmplOk` union planned by
; the frontier fixpoint per component, each component at its own anchor. Reviewer
; probe P4.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int pc(int s) {
;       int q = s & 7; cq_theta(&q, 0.5); int t2 = q * 5; cq_theta(&t2, 0.4);
;       int acc = 0;
;       if (s > 3) { int u = (s >> 2) & 7; cq_theta(&u, 0.3); int t1 = u * 3;
;                    cq_theta(&t1, 0.25); acc = s; }
;       int w = (s >> 4) & 7; cq_theta(&w, 0.35); int r = h(w); cq_theta(&r, 0.2);
;       return acc + cq_measure(w); }
;     int main(int argc, char **argv) { (void)argv; return pc(argc) + pc(argc + 4); }
;
; THE POPULATION. The template terminals {t2, t1} are closed and not measured
; upstream, so their one plan (no fixpoint) sits past the merge and DECLINES — main
; on this module: rc 1, `dead chain spans divergent control-flow arms` (measured,
; no-B binary). The clone terminal r reads the MEASURED w, so the union is measured
; upstream; its first frontier borrows only w and cuts nothing but w's own Ry and
; the fixpoint borrows nothing more (`GroupProbe::Cut` empty), the whole-group
; retry refuses on the
; same divergence, and the fixpoint plans {t2, q}, {t1, u} and {r} each at its own
; anchor — every check main's planner asks is asked of each component.
; LIFO per component (pinned below): t2 and q reversed BEFORE the branch; t1 and u
; inside the arm, at the arm's end; r's Ry, twin and free before the measure of w.
; Trace (pc(1) else path, pc(5) then path) and stage 2b: 7 frees verified, 0
; violations, 0 left dirty. The two warnings are the M-A `live derived record`
; warnings R11 r3 F2 disclosed (main never reaches that check here: it declines in
; uncompute first); pinned by count so a change shows.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error
; WARN-COUNT-2: warning: {{.*}}in function pc i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning

; CHECK-LABEL: define internal fastcc i32 @pc(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T2]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; CHECK-NEXT: icmp sgt i32
; CHECK-NEXT: br i1
; CHECK:      %[[U:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[U]], double 3.000000e-01)
; CHECK-NEXT: %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[U]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T1]], double -2.500000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T1]], i32 %[[U]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T1]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[U]], double -3.000000e-01)
; CHECK-NEXT: br label
; CHECK:      phi i32
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[W]], double 3.500000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[W]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R]], i32 %[[W]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[W]])
; CHECK-NOT:  call void @cqrt_free
; CHECK:      ret i32

declare i32 @cq_theta_si32(i32 noundef, double noundef) #2
declare i32 @cq_measure_si32(i32 noundef) #2

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @pc(i32 noundef %0)
  %4 = add nsw i32 %0, 4
  %5 = tail call fastcc i32 @pc(i32 noundef %4)
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

define internal fastcc i32 @pc(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = mul nsw i32 %3, 5
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 4.000000e-01) #4
  %6 = icmp sgt i32 %0, 3
  br i1 %6, label %7, label %13

7:
  %8 = lshr i32 %0, 2
  %9 = and i32 %8, 7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 3.000000e-01) #4
  %11 = mul nsw i32 %10, 3
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 2.500000e-01) #4
  br label %13

13:
  %14 = phi i32 [ %0, %7 ], [ 0, %1 ]
  %15 = lshr i32 %0, 4
  %16 = and i32 %15, 7
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 3.500000e-01) #4
  %18 = tail call fastcc i32 @h(i32 noundef %17)
  %19 = tail call i32 @cq_theta_si32(i32 noundef %18, double noundef 2.000000e-01) #4
  %20 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %21 = add nsw i32 %20, %14
  ret i32 %21
}

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}
attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
