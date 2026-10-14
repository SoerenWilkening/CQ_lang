; lowering_uncompute_cut_record_measured_before_move.ll — ACCEPT, byte-identical to
; main fc6ee653 (bd test_C_libtooling-r2j3.24, batch 053 unit D, R11 round 1
; finding C-F1: an over-decline the snapshot added).
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int armm(int s) {
;       int x = s & 7; cq_theta(&x, 0.5);
;       int q = x * 3; int a = q + 2;
;       int t = a * 5; cq_theta(&t, 0.4); int r = a * 7; cq_theta(&r, 0.2);
;       if (s > 100) { int m = cq_measure(q); cq_theta(&x, -0.5); return m + cq_measure(x); }
;       return cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv; return armm(argc); }
;
; q is measured on the s > 100 arm only, so its own gate is a cut record (r2j3.24),
; and snapshot 3aa47cb3 declined it: its measured-rail test asked for a measurement
; on every path to an EXIT. But x's only move is on that arm, after the measurement,
; so q is collapsed on every path to the move — main's accept was correct. NOW the
; question is asked per move: every path from q to `cqrt_ry_i32(x, -0.5)` passes a
; measurement of q, so the record is harmless and the module lowers as main did.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define internal fastcc i32 @armm(
; CHECK:      %[[X:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[X]], i32 3)
; CHECK:      call void @cq_template_add_i32_hl_unc(
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[X]], double -5.000000e-01)
; CHECK-NOT:  call void @cqrt_free(i32 %[[Q]])
; CHECK:      ret i32


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @armm(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @armm(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, 2
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #3
  %8 = mul nsw i32 %5, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #3
  %10 = icmp sgt i32 %0, 100
  br i1 %10, label %11, label %16

11:
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %15 = add nsw i32 %14, %12
  br label %18

16:
  %17 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  br label %18

18:
  %19 = phi i32 [ %15, %11 ], [ %17, %16 ]
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
