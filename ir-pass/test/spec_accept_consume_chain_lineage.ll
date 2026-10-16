; spec_accept_consume_chain_lineage.ll — ACCEPT, in place (bd
; test_C_libtooling-r2j3.37.1): `t ^= a; r = f(t, b)` with `f(t,b) = t ^ b`. The
; call's argument is `t ^ a`, not a `cq_theta` result. The QQ round asks whether
; that xor's result survives: it is read DEAD in a chain slot of a lifted call
; whose result survives (`continuesThroughLiftedChain`, E3 across the call), so
; the xor converts onto `t`'s rail; the call then reads `t`'s register, which is
; dead user data, and is consumed. Both in place: cnot(a, t), then the consumer's
; cnot(b, t). Analytic replay equals the textbook t ^= a; t ^= b on all outcomes.
; WAS (main ef72239c): `t ^ a` out of place as a temporary read by the clone,
; discharged, the old `t` left beside `r` (silent, rc 0).
;
; THE MECHANISM (SpecializeConsume.h; design of record bd r2j3.37.1): the lifted
; call becomes ONE call to a CONSUMING CLONE `__cq_q_<f>_<mask>_c<k>` that maps
; |t>|a> -> |f(t,a)>|a> on the dead argument t's own rail (slot k), tagged
; `!cq.inplace.qq`; its body is the in-place gates the in-place rounds mint, one per
; op of f's return chain, each fed by a parameter, a constant or a lifted SOURCE
; clone (computed, used, uncomputed and freed inside the body). The decision is
; the inlined twin's (InPlaceQQConsume.cpp).
;
; Source: f8.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      [[B:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_cnot(i32 [[A]], i32 [[T]]), !cq.inplace.qq
; CHECK-NEXT: call void @__cq_q_f_11_c0(i32 [[T]], i32 [[B]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 3.000000e-01)
source_filename = "f8.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i1 %0, %1
  ret i1 %3
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 8) i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01) #3
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #3
  %4 = xor i1 %1, %3
  %5 = tail call zeroext i1 @f(i1 noundef zeroext %4, i1 noundef zeroext %2)
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #3
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 3.000000e-01) #3
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #4
  %9 = zext i1 %8 to i32
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #4
  %11 = select i1 %10, i32 2, i32 0
  %12 = or disjoint i32 %11, %9
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #4
  %14 = select i1 %13, i32 4, i32 0
  %15 = or disjoint i32 %12, %14
  ret i32 %15
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

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
