; lowering_uncompute_joint_measure_cut_record.ll — ACCEPT (bd
; test_C_libtooling-r2j3.24, batch 053 unit D). The joint-cover twin of
; lowering_reject_uncompute_partial_measure_cut_record.ll: q is measured on EVERY
; path, but by two different measurements, neither of which post-dominates it.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int both(int s) {
;       int x = s & 7; cq_theta(&x, 0.5);
;       int q = x * 3; int a = q + 2;
;       int t = a * 5; cq_theta(&t, 0.4);
;       int r = a * 7; cq_theta(&r, 0.2);
;       int acc;
;       if (s > 100) acc = cq_measure(q); else acc = (int)cq_measure((unsigned)q);
;       cq_theta(&x, -0.5);
;       return acc + cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv; return both(argc); }
; (`cq_measure_si32` on one arm, `cq_measure_ui32` on the other: -O1 cannot merge
; them, which it does for two identical measurements.)
;
; main fc6ee653 lowered it (rc 0, three M-A warnings) and that was CORRECT: q is
; collapsed on every path before x moves, so its record of x is a product. The cut
; set (TerminalGroups.h) exempts a measured rail's own gates only when it is measured
; on every path; R11 r9 (bd p3kd.13) spelt that as ONE post-dominating measurement,
; which made the first draft of unit D DECLINE this program — a new over-decline of
; a correct accept. `measuredOnEveryPath` now walks the joint cover: from q's
; definition every path reaches a block holding a measurement of q before an exit.
; So q's `mul` is exempt, nothing hazardous is cut, and the module lowers as main
; did: a reversed and freed, q left (measured), x not un-rotated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define internal fastcc i32 @both(
; CHECK:      %[[X:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[X]], i32 3)
; CHECK:      call void @cq_template_add_i32_hl_unc(
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[X]], double -5.000000e-01)
; CHECK-NOT:  call void @cqrt_free(i32 %[[Q]])
; CHECK:      ret i32


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @both(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @both(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, 2
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #3
  %8 = mul nsw i32 %5, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #3
  %10 = icmp sgt i32 %0, 100
  br i1 %10, label %11, label %13

11:
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  br label %15

13:
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %4) #4
  br label %15

15:
  %16 = phi i32 [ %12, %11 ], [ %14, %13 ]
  %17 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  %19 = add nsw i32 %18, %16
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
