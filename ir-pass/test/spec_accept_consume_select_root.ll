; spec_accept_consume_select_root.ll — ACCEPT, in place per arm (bd
; test_C_libtooling-r2j3.37.3; R11 r1 rL1B-F1). The reviewer's rL1B/p5.c:
; `f(t,a,n){ if (n>2) { x = t^a; x += 5; return x; } return t - a; }`, `-O1` a
; select at the return root, `n` CLASSICAL, `t` dead. WAS (main ef72239c and
; through d019f260): no plan for a select root, the site stayed the out-of-place
; clone and the old `t` rail stood beside `r`, silently. NOW the plan has a
; select node and the consumer BRANCHES on the classical condition (a lifted
; source returns it): then-arm `xor(a, t); addc(t, 5)`, else-arm
; `sub(a, t)` — each arm in place, under classical control. Traces (lane L):
; argc=1 -> `cqrt_sub_i8(a, t)`; argc=4 -> `cqrt_xor_i8(a, t); cqrt_addc_i8(t, 5)`.
; The φ spelling lowers the same way (spec_accept_consume_phi_root.ll); a
; QUANTUM condition (spec_reject_consume_quantum_select.ll) stays loud.
;
; Source: p5.c (rL1B), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      call void @__cq_q_f_011_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]], i32 %0), !cq.inplace.qq
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
  %5 = xor i8 %1, %0
  %6 = add i8 %5, 5
  %7 = sub i8 %0, %1
  %8 = select i1 %4, i8 %6, i8 %7
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
