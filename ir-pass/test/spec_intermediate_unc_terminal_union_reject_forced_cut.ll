; spec_intermediate_unc_terminal_union_reject_forced_cut.ll — DECLINE, as main,
; character for character (bd test_C_libtooling-p3kd.13, R11 review round 8, F1).
; Reviewer probe p1 `@fx`: a record cut by the frontier FIXPOINT's forced borrow,
; not by the first frontier.
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int fx(int s) {
;       int p = s & 7; cq_theta(&p, 0.5);
;       int x = (s >> 3) & 7; cq_theta(&x, 0.5);
;       int a = tbl[x];
;       int R = p + (a >> 4);
;       int t = R * 5; cq_theta(&t, 0.4);
;       cq_theta(&p, -0.3);
;       int r = h(R); cq_theta(&r, 0.2);
;       cq_theta(&x, -0.5);
;       return cq_measure(p) + cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv; return fx(argc); }
;
; THE SHAPE. The template terminal t alone leaves R open (the clone call h(R)
; consumes it), so `TmplOk` is false: main on this module is rc 1 with the
; diagnostic below (cq-opt 716269bc). The union {t, r} closes R. It is measured
; upstream (p, x), so its first frontier borrows {arr, p, x}, which cuts only p's and
; x's own Rys. The whole-group retry then sees p moved (`Ry(p, -0.3)`) inside R's
; window, and the fixpoint FORCES R (`recordLiveAcrossMove`: h(R) reads it after
; the move) and borrows it — which cuts R's dead ancestors `Y = a >> 4` and the QROM
; record `a = tbl[x]`. R itself is the ruled disposition (bd 01po.8); its ancestors
; are not. R = p + (a >> 4) carries no x information (every entry is < 16), but
; `a` does.
; THE DEFECT THIS PINS (snapshot 1b5e9b82, R11 r8 reviewer, measured: rc 0, four
; unlocated M-A `live derived record` warnings): t and r reversed, R left, M-B
; reverses the template record Y, and `cqrt_qram_load_i32(arr, x)` is never
; `_unc`'d nor freed before `cqrt_ry_i32(x, -0.5)` and a measure of x — `a` dephases
; x where the source does not (the dead-record-live-across-move ruling of
; 2026-10-05). r7's `Cut` measured only the FIRST frontier's cut, which is empty
; here.
; NOW (`neverWorse`, TerminalGroups.cpp): `GroupProbe::Cut` is taken after the plans
; commit, against the FINAL frontier, exempting only the own gates of the measured
; rails and the forced record R. Y and the load remain, so the group splits and the
; template terminal gets main's decline (Y alone, which M-B would discharge, would
; split it too: THE `Cut` CLAUSE IS COARSE, TerminalGroups.h).
; NOT FIXED HERE: the all-template twin (probe p1 `fk`, `int r = R * 7` in place of
; the clone call) is main's own planner and emits the same wrong stream at rc 0 —
; appended to bd r2j3.23, pre-existing, unit D.
; RETIREMENT TRIGGER: unit D (bd r2j3.23) reverses a record a forced borrow cuts
; before its parent's next move, or fails loudly; the `Cut` clause can then ask
; that planner predicate instead (`firstHazardousCutRecord`, a follow-up), and an
; accept here must show `cqrt_qram_load_i32_unc` before `cqrt_ry_i32(x, -0.5)`.
; Change this fixture in that reviewed change, never by reflex.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function fx i32 (i32): cq uncompute: dead chain would free a measured register
; CHECK-NOT: internal invariant

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @fx(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @fx(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = sext i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %7
  %9 = load i32, ptr %8, align 4
  %10 = ashr i32 %9, 4
  %11 = add nsw i32 %10, %3
  %12 = mul nsw i32 %11, 5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 4.000000e-01) #4
  %14 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -3.000000e-01) #4
  %15 = tail call fastcc i32 @h(i32 noundef %11)
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 2.000000e-01) #4
  %17 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef -5.000000e-01) #4
  %18 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %20 = add nsw i32 %19, %18
  ret i32 %20
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
