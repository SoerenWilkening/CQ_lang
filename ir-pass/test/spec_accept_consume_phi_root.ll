; spec_accept_consume_phi_root.ll — ACCEPT, in place per arm (bd
; test_C_libtooling-r2j3.37.4; R11 r1 rL1B-F1, the φ half). The select-root shape
; of spec_accept_consume_select_root.ll kept as control flow (hand IR):
; `br (n > 2) hi, lo; hi: x = (a ^ t) + 5; lo: x = t - a; m: φ(hi x, lo x)`, `n`
; classical, `t` dead. The φ's two incomings hang under the two edges of ONE
; conditional branch, so it is planned as the select on that branch's condition
; (`phiSel`); the consumer branches on it (a lifted source returns the
; condition) and runs each arm in place. WAS (d019f260): silently out of place,
; old `t` rail kept; (681333ae): loud. A φ whose arm reads a value that does
; not dominate the callee's `ret` stays loud (spec_reject_consume_phi_arm_local.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      call void @__cq_q_f_011_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]], i32 %0), !cq.inplace.qq
; CHECK-LABEL: define internal i8 @__cq_q_f__cqsrc0_011(
; CHECK:      [[GT:%[0-9]+]] = icmp sgt i32 %2, 2
; CHECK-NEXT: [[Z:%[0-9]+]] = zext i1 [[GT]] to i8
; CHECK-NEXT: ret i8 [[Z]]
; CHECK-LABEL: define internal void @__cq_q_f_011_c0(i32 %0, i32 %1, i32 %2)
; CHECK-NEXT: [[C:%[0-9]+]] = call i8 @__cq_q_f__cqsrc0_011(i32 0, i32 0, i32 %2)
; CHECK-NEXT: [[B:%[0-9]+]] = icmp ne i8 [[C]], 0
; CHECK-NEXT: br i1 [[B]], label %[[HI:[0-9]+]], label %[[LO:[0-9]+]]
; CHECK:      [[HI]]:
; CHECK-NEXT: call void @cqrt_xor_i8(i32 %1, i32 %0), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_addc_i8(i32 %0, i8 5)
; CHECK:      [[LO]]:
; CHECK-NEXT: call void @cqrt_sub_i8(i32 %1, i32 %0), !cq.inplace.qq
source_filename = "p5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @f(i8 noundef zeroext %0, i8 noundef zeroext %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %2, 2
  br i1 %4, label %hi, label %lo
hi:
  %5 = xor i8 %1, %0
  %6 = add i8 %5, 5
  br label %m
lo:
  %7 = sub i8 %0, %1
  br label %m
m:
  %8 = phi i8 [ %6, %hi ], [ %7, %lo ]
  ret i8 %8
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 511) i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #3
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #3
  %5 = tail call zeroext i8 @f(i8 noundef zeroext %4, i8 noundef zeroext %3, i32 noundef %0)
  %6 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5) #4
  %7 = zext i8 %6 to i32
  %8 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %3) #4
  %9 = zext i8 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
