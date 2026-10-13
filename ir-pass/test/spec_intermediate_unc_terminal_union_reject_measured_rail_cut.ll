; spec_intermediate_unc_terminal_union_reject_measured_rail_cut.ll — DECLINE, as
; main, character for character (bd test_C_libtooling-p3kd.13, R11 review round 7,
; F1). Reviewer probe q4 `qc`: the template group itself measured upstream. Its twin
; with the template group NOT measured upstream is
; spec_intermediate_unc_terminal_union_reject_measured_rail_cut_divergent.ll (q6).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int qc(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int a = tbl[k]; int m = a >> 1; int v = m ^ 9;
;       int t = v * 5; cq_theta(&t, 0.4);
;       int r = h(v); cq_theta(&r, 0.2);
;       int mm = cq_measure(m);
;       cq_theta(&k, -0.5);
;       return mm + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return qc(argc); }
;
; THE SHAPE. a = tbl[k] is a QROM-load record of k, reachable only through the
; MEASURED m. The template terminal t is itself measured upstream (m, k), and its
; own plan refuses on the open copy v (the clone call h(v) consumes it), so `TmplOk`
; is false: main on this module is rc 1 with the diagnostic below (cq-opt 716269bc).
; The union {t, r} closes v. Measured upstream, its first frontier (bd ptue) BORROWS
; m and k, which CUTS `cqrt_qram_load_i32(arr, k)`; the M-B interior partition
; restores a cut `cq_template_*` record but refuses a load
; (`isInteriorTerminalHandle`; lowering_uncompute_interior_leak_qram_load.ll).
; THE DEFECT THIS PINS (snapshot e075f4ff, R11 r7 reviewer, measured: rc 0, three
; unlocated M-A `live derived record` warnings): v, t and r reversed, the load never
; `_unc`'d nor freed, then `cqrt_ry_i32(k, -0.5)` and a measure of k. With m = 1,
; k in {0, 6} and a in {3, 2} tells them apart, so Ry(k, -0.5)'s interference is
; wrong (the dead-record-live-across-move ruling of 2026-10-05). e075f4ff's store
; clause could not see it: a load is no store, and it was the MEASURED-RAIL half of
; the first frontier that cut it.
; NOW (`neverWorse`, TerminalGroups.cpp): under `!TmplOk` the union must leave
; nothing cut (`GroupProbe::Cut` empty). It cuts the load, so the group splits
; and the template terminal gets main's decline.
; NOT FIXED HERE: the all-template twin (probe q5 `qk`, `int r = v * 7` in place of
; the clone call) is main's own planner and emits the same wrong stream at rc 0 —
; bd r2j3.23, pre-existing, unit D.
; RETIREMENT TRIGGER: bd r2j3.23 lands (a record a frontier borrow cuts is reversed
; before its parent's next move, or the pass fails loudly; or M-B admits a QRAM-load
; interior). Re-measure main: the `Cut` clause may then relax and this function
; lower, and an accept must show `cqrt_qram_load_i32_unc` before
; `cqrt_ry_i32(k, -0.5)`. Change this fixture in that reviewed change, never by reflex.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function qc i32 (i32): cq uncompute: dead chain would free a measured register
; CHECK-NOT: internal invariant

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @qc(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @qc(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = ashr i32 %6, 1
  %8 = xor i32 %7, 9
  %9 = mul nsw i32 %8, 5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 4.000000e-01) #4
  %11 = tail call fastcc i32 @h(i32 noundef %8)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 2.000000e-01) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %14 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #4
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %16 = add nsw i32 %15, %13
  ret i32 %16
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
