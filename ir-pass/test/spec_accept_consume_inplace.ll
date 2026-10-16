; spec_accept_consume_inplace.ll — ACCEPT, in place across a lifted call (bd
; test_C_libtooling-r2j3.37 / .37.1; owner-ruling-r2j3-37-lower-it-2026-10-16).
;
; WAS (main ef72239c, a SILENT MISCOMPILE): `r = fx(t, a)` with
; `fx(t,a){ t ^= a; return t; }` lifted to the Bennett clone `__cq_q_fx_11`, the
; old `t` rail standing beside `r` and recording `a`; the later Ry on `a` was
; dephased (the `_Bool` twin: P(a=0, r=0) 0.7960 emitted vs 0.7659 for the
; program's circuit, independent state-vector replay of the trace; rc 0).
;
; THE MECHANISM (SpecializeConsume.h; design of record bd r2j3.37.1): the lifted
; call becomes ONE call to a CONSUMING CLONE `__cq_q_<f>_<mask>_c<k>` that maps
; |t>|a> -> |f(t,a)>|a> on the dead argument t's own rail (slot k), tagged
; `!cq.inplace.qq`; its body is the in-place gates the in-place rounds mint, one per
; op of f's return chain, each fed by a parameter, a constant or a lifted SOURCE
; clone (computed, used, uncomputed and freed inside the body). The decision is
; the inlined twin's (InPlaceQQConsume.cpp).
;
; Pinned per function (each the C in f1.c, lane L scratch, clang-19 -O1):
;   c_xor     fx = t ^ a (i32)           -> __cq_q_fx_11_c0 = cqrt_xor_i32(a, t)
;   c_add     fadd = t + a (u8)          -> cqrt_add_i8(a, t)
;   c_sub     fsub = t - a (u8)          -> cqrt_sub_i8(a, t) (t the minuend)
;   c_nested  g = f3(t,a,0) ^ b: f3's chain substituted at g's inner call
;             -> cnot(a,t); xorc(t,0); cnot(b,t); f3's clone is not called
;   c_leaf    fl = t ^ (a & b): a SOURCE clone `fl__cqsrc0` computes a&b, with
;             t's slot recorded dead and passed 0; cnot(s, t); its twin
;             uncomputes s; s freed (2b-verified) — all inside the one call
;   c_inc     inc = t + 3: the classical immediate -> cqrt_addc_i8(t, 3)
;   c_id      id = t: `returned` already makes the call the register itself
; Analytic replay (scratch state-vector, lane L): every `_Bool` function equals
; its textbook circuit (CNOT / Toffoli) on all outcomes; stage 2b 3 verified, 0/0.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; ERR-NOT: error
; ERR-NOT: warning
;
; CHECK-LABEL: define i32 @c_xor(
; CHECK:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[A]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @__cq_q_fx_11_c0(i32 [[T]], i32 [[A]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[A]], double 0x3FE6666666666666)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[A]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-LABEL: define {{.*}}i32 @c_add(
; CHECK:      call void @__cq_q_fadd_11_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i8(i32 [[A]], double 0x3FE6666666666666)
; CHECK-LABEL: define {{.*}}i32 @c_sub(
; CHECK:      call void @__cq_q_fsub_11_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]]), !cq.inplace.qq
; CHECK-LABEL: define {{.*}}i32 @c_nested(
; CHECK:      call void @__cq_q_g_111_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]], i32 [[B:%[a-z0-9]+]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; CHECK-LABEL: define {{.*}}i32 @c_leaf(
; CHECK:      call void @__cq_q_fl_111_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]], i32 [[B:%[a-z0-9]+]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; CHECK-LABEL: define {{.*}}i32 @c_inc(
; CHECK:      call void @__cq_q_inc_1_c0(i32 [[T:%[a-z0-9]+]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i8(i32 [[T]], double 0x3FE6666666666666)
; CHECK-LABEL: define {{.*}}i32 @c_id(
; CHECK:      [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 0x3FE6666666666666)
;
; The bodies: one in-place gate per chain op; the leaf's source inside the call.
; CHECK-LABEL: define internal void @__cq_q_fx_11_c0(i32 %0, i32 %1)
; CHECK-NEXT: call void @cqrt_xor_i32(i32 %1, i32 %0), !cq.inplace.qq
; CHECK-NEXT: ret void
; CHECK-LABEL: define internal void @__cq_q_fadd_11_c0(i32 %0, i32 %1)
; CHECK-NEXT: call void @cqrt_add_i8(i32 %1, i32 %0), !cq.inplace.qq
; CHECK-LABEL: define internal void @__cq_q_fsub_11_c0(i32 %0, i32 %1)
; CHECK-NEXT: call void @cqrt_sub_i8(i32 %1, i32 %0), !cq.inplace.qq
; CHECK-LABEL: define internal void @__cq_q_g_111_c0(i32 %0, i32 %1, i32 %2)
; CHECK-NEXT: call void @cqrt_cnot(i32 %1, i32 %0), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_xorc_i1(i32 %0, i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %2, i32 %0), !cq.inplace.qq
; CHECK-NEXT: ret void
; CHECK-LABEL: define internal void @__cq_q_fl_111_c0(i32 %0, i32 %1, i32 %2)
; CHECK-NEXT: [[S:%[0-9]+]] = call i32 @__cq_q_fl__cqsrc0_111(i32 0, i32 %1, i32 %2)
; CHECK-NEXT: call void @cqrt_cnot(i32 [[S]], i32 %0), !cq.inplace.qq
; CHECK-NEXT: call void @__cq_q_fl__cqsrc0_111_unc(i32 [[S]], i32 0, i32 %1, i32 %2)
; CHECK-NEXT: call void @cqrt_free(i32 [[S]])
; CHECK-NEXT: ret void
; CHECK-LABEL: define internal void @__cq_q_inc_1_c0(i32 %0)
; CHECK-NEXT: call void @cqrt_addc_i8(i32 %0, i8 3)
; CHECK-NEXT: ret void
; No out-of-place clone of any chain function survives (only the leaf's source).
; NOCLONE-NOT: define {{.*}}@__cq_q_{{(fx|fadd|fsub|g|f3|inc|id|fl)_[01]+\(}}
; RUN: %filecheck %s --check-prefix=NOCLONE < %t.ll
source_filename = "f1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @fx(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = xor i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @fadd(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = add i8 %1, %0
  ret i8 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @fsub(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = sub i8 %0, %1
  ret i8 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @f3(i1 noundef zeroext %0, i1 noundef zeroext %1, i1 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = xor i1 %0, %1
  %5 = xor i1 %4, %2
  ret i1 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @g(i1 noundef zeroext %0, i1 noundef zeroext %1, i1 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = tail call zeroext i1 @f3(i1 noundef zeroext %0, i1 noundef zeroext %1, i1 noundef zeroext false)
  %5 = xor i1 %4, %2
  ret i1 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @fl(i1 noundef zeroext %0, i1 noundef zeroext %1, i1 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = and i1 %1, %2
  %5 = xor i1 %4, %0
  ret i1 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @inc(i8 noundef zeroext %0) local_unnamed_addr #0 {
  %2 = add i8 %0, 3
  ret i8 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @id(i1 noundef returned zeroext %0) local_unnamed_addr #0 {
  ret i1 %0
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @c_xor() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #4
  %3 = tail call i32 @fx(i32 noundef %2, i32 noundef %1)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 511) i32 @c_add() local_unnamed_addr #1 {
  %1 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #4
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #4
  %3 = tail call zeroext i8 @fadd(i8 noundef zeroext %2, i8 noundef zeroext %1)
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %1, double noundef 0x3FE6666666666666) #4
  %5 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %4) #5
  %6 = zext i8 %5 to i32
  %7 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %3) #5
  %8 = zext i8 %7 to i32
  %9 = add nuw nsw i32 %8, %6
  ret i32 %9
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 511) i32 @c_sub() local_unnamed_addr #1 {
  %1 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #4
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #4
  %3 = tail call zeroext i8 @fsub(i8 noundef zeroext %2, i8 noundef zeroext %1)
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %1, double noundef 0x3FE6666666666666) #4
  %5 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %4) #5
  %6 = zext i8 %5 to i32
  %7 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %3) #5
  %8 = zext i8 %7 to i32
  %9 = add nuw nsw i32 %8, %6
  ret i32 %9
}

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 8) i32 @c_nested() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01) #4
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #4
  %4 = tail call zeroext i1 @g(i1 noundef zeroext %3, i1 noundef zeroext %1, i1 noundef zeroext %2)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #4
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 3.000000e-01) #4
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #5
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #5
  %10 = select i1 %9, i32 2, i32 0
  %11 = or disjoint i32 %10, %8
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %13 = select i1 %12, i32 4, i32 0
  %14 = or disjoint i32 %11, %13
  ret i32 %14
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 8) i32 @c_leaf() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01) #4
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #4
  %4 = tail call zeroext i1 @fl(i1 noundef zeroext %3, i1 noundef zeroext %1, i1 noundef zeroext %2)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #4
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 3.000000e-01) #4
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #5
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #5
  %10 = select i1 %9, i32 2, i32 0
  %11 = or disjoint i32 %10, %8
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %13 = select i1 %12, i32 4, i32 0
  %14 = or disjoint i32 %11, %13
  ret i32 %14
}

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 256) i32 @c_inc() local_unnamed_addr #1 {
  %1 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #4
  %2 = tail call zeroext i8 @inc(i8 noundef zeroext %1)
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef 0x3FE6666666666666) #4
  %4 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %3) #5
  %5 = zext i8 %4 to i32
  ret i32 %5
}

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 2) i32 @c_id() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #4
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #5
  %4 = zext i1 %3 to i32
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @c_xor()
  %2 = tail call i32 @c_add()
  %3 = add nsw i32 %2, %1
  %4 = tail call i32 @c_sub()
  %5 = add nsw i32 %3, %4
  %6 = tail call i32 @c_nested()
  %7 = add nsw i32 %5, %6
  %8 = tail call i32 @c_leaf()
  %9 = add nsw i32 %7, %8
  %10 = tail call i32 @c_inc()
  %11 = add nsw i32 %9, %10
  %12 = tail call i32 @c_id()
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
