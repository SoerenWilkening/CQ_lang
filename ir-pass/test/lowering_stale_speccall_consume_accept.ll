; lowering_stale_speccall_consume_accept.ll — ACCEPT, in place (bd
; test_C_libtooling-r2j3.37.1; the dead twin of
; lowering_stale_speccall_independent_gates_placed_accept.ll). `r = f(q, p)` with
; `f(x,y) = x*3 + y` reads `q` after `cq_theta(&q2, .3)` rotated its wire (bd
; r2j3.6) and leaves `p` DEAD. The stale read is PLACED before the gate (57ch (A))
; and the call is then consumed in place on `p`: inside the one call, the source
; clone `f__cqsrc0` computes 3q from the OLD q, `cqrt_add_i32` adds it into `p`'s
; rail, the source is uncomputed and freed — all before the Ry on q2. The trace
; (lane L) is p += 3·q_old then Ry(.3) on q. (Under the batch-055 return-chain
; hoist this shape was LOUD: the hoisted source temporary had to be discharged
; after the gate; the consuming clone keeps it inside the call.)
;
; THE MECHANISM (SpecializeConsume.h; design of record bd r2j3.37.1): the lifted
; call becomes ONE call to a CONSUMING CLONE `__cq_q_<f>_<mask>_c<k>` that maps
; |t>|a> -> |f(t,a)>|a> on the dead argument t's own rail (slot k), tagged
; `!cq.inplace.qq`; its body is the in-place gates the in-place rounds mint, one per
; op of f's return chain, each fed by a parameter, a constant or a lifted SOURCE
; clone (computed, used, uncomputed and freed inside the body). The decision is
; the inlined twin's (InPlaceQQConsume.cpp).
;
; Source: f6.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; ERR-NOT: error
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      [[Q:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[P:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[P]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[P]], double 2.000000e-01)
; CHECK-NEXT: call void @__cq_q_f_11_c1(i32 [[Q]], i32 [[P]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 3.000000e-01)
; CHECK-LABEL: define internal void @__cq_q_f_11_c1(i32 %0, i32 %1)
; CHECK-NEXT: [[S:%[0-9]+]] = call i32 @__cq_q_f__cqsrc0_11(i32 %0, i32 0)
; CHECK-NEXT: call void @cqrt_add_i32(i32 [[S]], i32 %1), !cq.inplace.qq
; CHECK-NEXT: call void @__cq_q_f__cqsrc0_11_unc(i32 [[S]], i32 %0, i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 [[S]])
source_filename = "f6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #3
  %5 = tail call i32 @f(i32 noundef %1, i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
