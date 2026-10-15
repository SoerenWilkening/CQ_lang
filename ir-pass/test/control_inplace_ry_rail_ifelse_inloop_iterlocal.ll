; control_inplace_ry_rail_ifelse_inloop_iterlocal.ll — ACCEPT (bd
; test_C_libtooling-dm7f.54, item F: the fixture behind the round-1 report's
; "in-loop two-arm rail, rolled, correct per iteration" — NARROWED to what it
; shows). An ITERATION-LOCAL target (`bool t` declared in the body, re-minted
; every trip) under a two-arm `_Bool` if/else, in a classically-bounded loop:
;
;     for (int i = 0; i < 3; i++) { bool t = 0; cq_theta(&t, .4);
;       if (a) cq_theta(&t, .7); else cq_theta(&t, .3); acc += cq_measure(t); }
;
; Per trip: a fresh rail, Ry(.4), the CNOT copy flag of `a`, the X-bracket pair,
; the un-copy and a proven-|0> free — the flat stream rolled (IR size independent
; of the trip count). A LOOP-CARRIED target (review H5, revC54a/p5, `t` declared
; outside the loop) still declines `control flow inside a loop body`
; (`control_inplace_ry_reject_rail_ifelse_inloop_carried.ll`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK:      br i1

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #2
  br label %8

4:                                                ; preds = %16
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #3
  %6 = zext i1 %5 to i32
  %7 = add nuw nsw i32 %20, %6
  ret i32 %7

8:                                                ; preds = %2, %16
  %9 = phi i32 [ 0, %2 ], [ %21, %16 ]
  %10 = phi i32 [ 0, %2 ], [ %20, %16 ]
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #2
  br i1 %3, label %12, label %14

12:                                               ; preds = %8
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 0x3FE6666666666666) #2
  br label %16

14:                                               ; preds = %8
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 3.000000e-01) #2
  br label %16

16:                                               ; preds = %14, %12
  %17 = phi i1 [ %13, %12 ], [ %15, %14 ]
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #3
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %10, %19
  %21 = add nuw nsw i32 %9, 1
  %22 = icmp eq i32 %21, 3
  br i1 %22, label %4, label %8
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
