; spec_intermediate_unc_terminal_union_reject_partial_measure.ll — DECLINE, as main,
; character for character (bd test_C_libtooling-p3kd.13, R11 review round 9, F1).
; Reviewer probe p1 `cm`: a rail measured on SOME paths only, exempted as
; "measured".
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int cm(int s) {
;       int x = s & 7; cq_theta(&x, 0.5);
;       int q = x * 3;
;       int a = q + 2;
;       int t = a * 5; cq_theta(&t, 0.4);
;       int r = h(a); cq_theta(&r, 0.2);
;       int acc = 0;
;       if (s > 100) acc = cq_measure(q);
;       cq_theta(&x, -0.5);
;       return acc + cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv; return cm(argc); }
;
; THE SHAPE. The template terminal t alone leaves `a` open (the clone call h(a)
; consumes it), so `TmplOk` is false: main on this module is rc 1 with the
; diagnostic below (cq-opt 716269bc). q = x * 3 is a full record of x, measured
; ONLY when s > 100. The union {t, r} closes `a`; measured upstream (q, x), its
; first frontier (bd ptue) borrows q and x, so q's own `mul` is cut.
; THE DEFECT THIS PINS (snapshot 9be748ef, R11 r9 reviewer, measured: rc 0, three
; unlocated M-A `live derived record` warnings): t, r and `a` reversed, q's
; `cq_template_mul_i32_hl(x, 3)` never `_unc`'d nor freed, and on the s <= 100 path
; `cqrt_ry_i32(x, -0.5)` runs while q = 3x is live — it dephases x where the source
; does not (the dead-record-live-across-move ruling of 2026-10-05). r8's `Cut`
; exempted every rail in `DataDag::MeasuredRails`, which holds a rail with ANY
; measurement sink.
; NOW (`neverWorse`, TerminalGroups.cpp): a measured rail's own gates are exempt
; from `GroupProbe::Cut` only when one of its measurements post-dominates it
; (`measuredOnEveryPath`, Uncomputation.cpp, asked of the planner's PDT). q's does
; not, so q's `mul` stays cut, the group splits and the template terminal gets
; main's decline.
; NOT FIXED HERE: the all-template twin (probe p3 `cmk`, `int r = a * 7` in place
; of the clone call) is main's own planner and emits the same wrong stream at rc 0
; — bd r2j3.24, pre-existing, unit D.
; RETIREMENT TRIGGER: bd r2j3.24 lands (main's planner stops treating a rail
; measured on some paths as untouchable, or fails loudly): re-measure main; the
; `Cut` clause may then ask the planner's own predicate, and an accept here must
; show `cq_template_mul_i32_hl_unc` of q before `cqrt_ry_i32(x, -0.5)` on the
; s <= 100 path. Change this fixture in that reviewed change, never by reflex.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function cm i32 (i32): cq uncompute: dead chain would free a measured register
; CHECK-NOT: internal invariant

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @cm(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @cm(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, 2
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #4
  %8 = tail call fastcc i32 @h(i32 noundef %5)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  %10 = icmp sgt i32 %0, 100
  br i1 %10, label %11, label %13

11:
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  br label %13

13:
  %14 = phi i32 [ %12, %11 ], [ 0, %1 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #4
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
  %17 = add nsw i32 %16, %14
  ret i32 %17
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
