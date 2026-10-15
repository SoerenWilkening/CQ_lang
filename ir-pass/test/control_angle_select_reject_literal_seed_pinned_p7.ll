; control_angle_select_reject_literal_seed_pinned_p7.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item A1; review probe revC54b/p7, plain C at -O1):
;
;     int t = k; cq_theta(&t, .5); _Bool c = 0; cq_theta(&c, .6);
;     if (t == 5) { cq_theta(&t, c ? .9 : .3); }
;
; GVN substitutes the literal 5 for `t` inside the arm, so the angle select's
; consumer is `cq_theta_si32(i32 5, sel)` on a `nomerge` call site with NO merge,
; while the source rotated `t` IN PLACE. Two fences refuse it, and the ORDER is
; what picks the message: the enclosing tainted diamond (an angle select inside
; an arm) declines `control flow` first, which MASKS the angle-select fence
; `angleSelectLiteralSeedPinned` (S3's literal half: F2's question at the
; consumer, which proves `t == 5` there). The masked fence is pinned directly by
; `control_angle_select_reject_literal_seed_lvi_pinned.ll` and
; `..._forward_pinned.ll`. RETIREMENT TRIGGER: the day a nested-arm widening
; admits this diamond, this file's string becomes F2's
; `state prep seed is proven equal to the condition register` — re-derive it
; then; it must NEVER become an accept. The `t = q / 4` spelling is
; `..._pinned_sdiv.ll`. The ON-WIRE twin `int q = k; cq_theta(&q, .5); int t = q;
; if (t == 5) …` is THIS module byte for byte after -O1 (`t = q` is one SSA
; value), so it has no file of its own (L7 duplicate-body rule). The delegated
; ruling allowed it to accept as the owner-ruled α trade; it does not (the
; enclosing diamond declines first, and the angle-select fence asks no CondWire
; exclusion — the safe direction, recorded).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2
  %4 = icmp eq i32 %2, 5
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = select i1 %3, double 9.000000e-01, double 3.000000e-01
  %7 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef %6) #2
  br label %8

8:                                                ; preds = %5, %1
  %9 = phi i32 [ %7, %5 ], [ %2, %1 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #3
  %12 = zext i1 %11 to i32
  %13 = add nsw i32 %10, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
