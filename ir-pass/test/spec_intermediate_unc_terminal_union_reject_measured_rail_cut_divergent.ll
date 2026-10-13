; spec_intermediate_unc_terminal_union_reject_measured_rail_cut_divergent.ll —
; DECLINE, as main, character for character (bd test_C_libtooling-p3kd.13, R11
; review round 7, F1). Reviewer probe q6 `pq`: the template group NOT measured
; upstream. Its twin with the template group itself measured upstream is
; spec_intermediate_unc_terminal_union_reject_measured_rail_cut.ll (q4).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int pq(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int q = (s >> 3) & 7; cq_theta(&q, 0.5); int t2 = q * 5; cq_theta(&t2, 0.4);
;       int acc = 0;
;       if (s > 3) { int u = (s >> 2) & 7; cq_theta(&u, 0.3); int t1 = u * 3;
;                    cq_theta(&t1, 0.25); acc = s; }
;       int a = tbl[k];
;       int m = a >> 1;
;       int r = h(m); cq_theta(&r, 0.2);
;       int mm = cq_measure(m);
;       cq_theta(&k, -0.5);
;       return acc + mm + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return pq(argc) + pq(argc + 4); }
;
; THE SHAPE. The template terminals {t2, t1} reach no measured rail and no record of
; k; their one plan declines on the divergent arm (`TmplOk` false): main on this
; module is rc 1 with the diagnostic below (cq-opt 716269bc). Only the CLONE terminal
; r reaches the MEASURED m and, through it, the QROM-load record a = tbl[k]. The
; union is measured upstream; its first frontier (bd ptue) borrows m and k and CUTS
; `cqrt_qram_load_i32(arr, k)`, which the M-B interior partition refuses (a load is
; no `cq_template_*` interior); the fixpoint plans {t2, q}, {t1, u} and {r}.
; THE DEFECT THIS PINS (snapshot e075f4ff, R11 r7 reviewer, measured: rc 0, four
; unlocated M-A `live derived record` warnings): t2/q, t1/u and r reversed, the load
; never `_unc`'d nor freed, then `cqrt_ry_i32(k, -0.5)` and a measure of k — the
; record a dephases k where the source does not (the dead-record-live-across-move
; ruling of 2026-10-05). It was a new customer of the bd r2j3.23 stream where main
; declines.
; NOW (`neverWorse`, TerminalGroups.cpp): under `!TmplOk` the union must leave
; nothing cut (`GroupProbe::Cut` empty). It cuts the load, so the group splits
; and the template terminals get main's decline.
; NOT FIXED HERE: bd r2j3.23 (main's own planner, all-template; probe q5 `qk`).
; RETIREMENT TRIGGERS. (a) bd r2j3.23 lands: re-measure main; the `Cut` clause may
; relax, and an accept must show `cqrt_qram_load_i32_unc` before
; `cqrt_ry_i32(k, -0.5)`. (b) The dead-terminal spine stops declining a dead rotated
; rail in a classical arm (kMsgDivergentArm, a p3kd.13 follow-up): {t2, t1} then plan
; (`TmplOk`) and that branch governs — re-measure main and the union together.
; Change this fixture in that reviewed change, never by reflex.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function pq i32 (i32): cq uncompute: dead chain spans divergent control-flow arms
; CHECK-NOT: internal invariant

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @pq(i32 noundef %0)
  %4 = add nsw i32 %0, 4
  %5 = tail call fastcc i32 @pq(i32 noundef %4)
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

define internal fastcc i32 @pq(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = mul nsw i32 %6, 5
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 4.000000e-01) #4
  %9 = icmp sgt i32 %0, 3
  br i1 %9, label %10, label %16

10:
  %11 = lshr i32 %0, 2
  %12 = and i32 %11, 7
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 3.000000e-01) #4
  %14 = mul nsw i32 %13, 3
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 2.500000e-01) #4
  br label %16

16:
  %17 = phi i32 [ %0, %10 ], [ 0, %1 ]
  %18 = sext i32 %3 to i64
  %19 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4
  %21 = ashr i32 %20, 1
  %22 = tail call fastcc i32 @h(i32 noundef %21)
  %23 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 2.000000e-01) #4
  %24 = tail call i32 @cq_measure_si32(i32 noundef %21) #5
  %25 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #4
  %26 = add nsw i32 %24, %17
  %27 = tail call i32 @cq_measure_si32(i32 noundef %25) #5
  %28 = add nsw i32 %26, %27
  ret i32 %28
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) #2

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
