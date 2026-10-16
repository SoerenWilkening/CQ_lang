; spec_accept_consume_repro.ll — ACCEPT, in place (bd test_C_libtooling-r2j3.37,
; the reporter's repro; .37.1). `r = f(t, a)` with `f(t,a){ t ^= a; return t; }`,
; `t` dead, then `cq_theta(&a, .7)`. WAS (main ef72239c, silent): the Bennett
; clone's copy-out left the old `t` beside `r`, recording `a`, so the Ry on `a`
; was dephased (`_Bool` twin P(a=0, r=0) 0.7960 vs 0.7659). NOW one consuming call
; `cqrt_xor_i32(a, t)` in place; the `_Bool` twin's trace replays to 0.7659.
;
; THE MECHANISM (SpecializeConsume.h; design of record bd r2j3.37.1): the lifted
; call becomes ONE call to a CONSUMING CLONE `__cq_q_<f>_<mask>_c<k>` that maps
; |t>|a> -> |f(t,a)>|a> on the dead argument t's own rail (slot k), tagged
; `!cq.inplace.qq`; its body is the in-place gates the in-place rounds mint, one per
; op of f's return chain, each fed by a parameter, a constant or a lifted SOURCE
; clone (computed, used, uncomputed and freed inside the body). The decision is
; the inlined twin's (InPlaceQQConsume.cpp).
;
; Source: g1.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[A]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @__cq_q_f_11_c0(i32 [[T]], i32 [[A]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[A]], double 0x3FE6666666666666)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[A]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-LABEL: define internal void @__cq_q_f_11_c0(i32 %0, i32 %1)
; CHECK-NEXT: call void @cqrt_xor_i32(i32 %1, i32 %0), !cq.inplace.qq
; CHECK-NEXT: ret void
source_filename = "g1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = xor i32 %1, %0
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #3
  %3 = tail call i32 @f(i32 noundef %2, i32 noundef %1)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %7 = add nsw i32 %6, %5
  ret i32 %7
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
