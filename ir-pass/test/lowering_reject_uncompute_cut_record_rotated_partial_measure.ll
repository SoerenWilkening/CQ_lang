; lowering_reject_uncompute_cut_record_rotated_partial_measure.ll — DECLINE (bd
; test_C_libtooling-r2j3.24, batch 053 unit D, R11 round 1 finding A-F1, probe
; a4_cmkr). The GARBAGE exemption must hold on EVERY path to the move.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int cmkr(int s) {
;       int x = s & 7; cq_theta(&x, 0.5);
;       int q = x * 3; cq_theta(&q, 0.3); int a = q + 2;
;       int t = a * 5; cq_theta(&t, 0.4); int r = a * 7; cq_theta(&r, 0.2);
;       int acc = 0; if (s > 100) acc = cq_measure(q);
;       cq_theta(&x, -0.5); return acc + cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv; return cmkr(argc); }
;
; main fc6ee653 and the round-1 snapshot 3aa47cb3: rc 0. q (rotated, measured on
; s > 100 only) is a cut record of x; the snapshot's garbage test exempted it because
; SOME reader of q (`a = q + 2`) is reachable after q's Ry — but the plan reverses
; `a`, and the only kept reader (the measurement) sits on one arm, so on s <= 100
; q stays an un-collapsed dead record of x across `cqrt_ry_i32(x, -0.5)`.
; NOW (R11 r1 invariant, per (record, move)): garbage only when the rotation and a
; KEPT reader lie on EVERY path to the move; neither holds here, no measurement
; covers every path to the move, nothing keeps q across it: hazardous, unreversed,
; LOUD at q's producer.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function cmkr i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @cmkr(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @cmkr(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = mul nsw i32 %3, 3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #3
  %6 = add nsw i32 %5, 2
  %7 = mul nsw i32 %6, 5
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 4.000000e-01) #3
  %9 = mul nsw i32 %6, 7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01) #3
  %11 = icmp sgt i32 %0, 100
  br i1 %11, label %12, label %14

12:
  %13 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  br label %14

14:
  %15 = phi i32 [ %13, %12 ], [ 0, %1 ]
  %16 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  %18 = add nsw i32 %17, %15
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
