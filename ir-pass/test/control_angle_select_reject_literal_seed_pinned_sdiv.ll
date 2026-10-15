; control_angle_select_reject_literal_seed_pinned_sdiv.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item A1; the drbq.13 `t = q / 4` variant of review p7):
;
;     int q = k; cq_theta(&q, .5); _Bool c = 0; cq_theta(&c, .6); int t = q / 4;
;     if (t == 5) { cq_theta(&t, c ? .9 : .3); }
;
; InstCombine moves the compare SIDEWAYS (`(q & -4) == 20`) and IPSCCP/GVN put the
; literal 5 for `t` inside the arm, so the angle select's
; consumer is `cq_theta_si32(i32 5, sel)` on a `nomerge` call site with NO merge,
; while the source rotated `t` IN PLACE. Two fences refuse it, and the ORDER is
; what picks the message: the enclosing tainted diamond (an angle select inside
; an arm) declines `control flow` first, which MASKS the angle-select fence
; `angleSelectLiteralSeedPinned` (S3's literal half: F2's question at the
; consumer, which proves `t == 5` there through F2's forward model of `sdiv`). The masked fence is pinned directly by
; `control_angle_select_reject_literal_seed_lvi_pinned.ll` and
; `..._forward_pinned.ll`. RETIREMENT TRIGGER: the day a nested-arm widening
; admits this diamond, this file's string becomes F2's
; `state prep seed is proven equal to the condition register` — re-derive it
; then; it must NEVER become an accept. The `t = q / 4` and on-wire spellings
; are `..._pinned_sdiv.ll` / `..._pinned_onwire.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2
  %4 = sdiv i32 %2, 4
  %5 = and i32 %2, -4
  %6 = icmp eq i32 %5, 20
  br i1 %6, label %7, label %10

7:                                                ; preds = %1
  %8 = select i1 %3, double 9.000000e-01, double 3.000000e-01
  %9 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef %8) #2
  br label %10

10:                                               ; preds = %7, %1
  %11 = phi i32 [ %9, %7 ], [ %4, %1 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %14 = add nsw i32 %13, %12
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #3
  %16 = zext i1 %15 to i32
  %17 = add nsw i32 %14, %16
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
