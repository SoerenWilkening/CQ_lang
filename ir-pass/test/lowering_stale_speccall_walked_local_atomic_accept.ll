; lowering_stale_speccall_walked_local_atomic_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 6 F1: the accept side of the capture
; exception, where it is actually asked; OWNER RULING 2026-10-08 as clarified, bd
; memory owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08).
;
;   int calls;
;   __attribute__((noinline)) int h(int x) {
;     int a = x;
;     int old = __atomic_fetch_add(&a, 1, __ATOMIC_SEQ_CST);  // never-captured local
;     calls++;                                                  // so h is NOT memory(none)
;     return old + a;
;   }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int k = h(argc);                                  // crossed: its body is WALKED
;     int b = argc;
;     int old = __atomic_fetch_add(&b, 2, __ATOMIC_SEQ_CST);  // crossed DIRECTLY
;     int r = f(q);                                     // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + k + old + b + calls;
;   }
;
; `h` writes a global and is not `nosync`, so `callCrossable` cannot stop at a memory
; summary: it walks `h`'s body and `isObservableOrderedEvent` meets the seq_cst
; `atomicrmw` on `%a`, a never-captured alloca (`PointerMayBeCaptured` false): not
; observable, crossable. `main`'s own seq_cst `atomicrmw` on `%b` is a crossed
; instruction (clause (d)) asked the same predicate. Both are the capture exception's
; ACCEPT branch; the three earlier local-atomic accepts reach their verdict through
; the `memory(none)` summary and never inspect the atomic. This file is what a
; "every atomic is observable" or "captured = true" mutant must fail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:.*]], double 5.000000e-01)
; CHECK-NEXT: call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: tail call i32 @h(
; CHECK:      atomicrmw add ptr %{{.*}}, i32 2 seq_cst

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@calls = local_unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #5
  store i32 %0, ptr %2, align 4, !tbaa !6
  %3 = atomicrmw add ptr %2, i32 1 seq_cst, align 4
  %4 = load i32, ptr @calls, align 4, !tbaa !6
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr @calls, align 4, !tbaa !6
  %6 = load i32, ptr %2, align 4, !tbaa !6
  %7 = add nsw i32 %6, %3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #5
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #6
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #6
  %6 = tail call i32 @h(i32 noundef %0)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5
  store i32 %0, ptr %3, align 4, !tbaa !6
  %7 = atomicrmw add ptr %3, i32 2 seq_cst, align 4
  %8 = call i32 @f(i32 noundef %4)
  %9 = call i32 @cq_measure_si32(i32 noundef %8) #5
  %10 = call i32 @cq_measure_si32(i32 noundef %5) #5
  %11 = load i32, ptr %3, align 4, !tbaa !6
  %12 = load i32, ptr @calls, align 4, !tbaa !6
  %13 = add i32 %7, %6
  %14 = add i32 %13, %9
  %15 = add i32 %14, %10
  %16 = add nsw i32 %15, %11
  %17 = add nsw i32 %16, %12
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
