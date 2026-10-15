; control_inplace_ry_reject_rail_ifelse_inloop_carried.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item F; review H5, revC54a/p5): the two-arm `_Bool`
; if/else on a LOOP-CARRIED target (`t` lives across trips) in a runtime-bounded
; loop. Not part of this change's accept class; it keeps the loop scope's
; string (the R7 loop half has no clause for this rail). Filed under the loop
; umbrella with the angle-select-in-a-loop follow-up.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control

define range(i32 0, 3) i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #3
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %11, label %4

4:                                                ; preds = %18, %1
  %5 = phi i1 [ false, %1 ], [ %19, %18 ]
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #4
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #4
  %9 = zext i1 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10

11:                                               ; preds = %1, %18
  %12 = phi i32 [ %20, %18 ], [ 0, %1 ]
  %13 = phi i1 [ %19, %18 ], [ false, %1 ]
  br i1 %2, label %14, label %16

14:                                               ; preds = %11
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 0x3FE6666666666666) #3
  br label %18

16:                                               ; preds = %11
  %17 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 3.000000e-01) #3
  br label %18

18:                                               ; preds = %14, %16
  %19 = phi i1 [ %15, %14 ], [ %17, %16 ]
  %20 = add nuw nsw i32 %12, 1
  %21 = icmp eq i32 %20, %0
  br i1 %21, label %4, label %11
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

define noundef i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @slice(i32 noundef 3)
  ret i32 0
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
