; lowering_stale_speccall_carried_local_atomic_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 5 R5-1).
;
;   __attribute__((noinline)) int h(int x) {
;     int a = x;
;     int old = __atomic_fetch_add(&a, 1, __ATOMIC_SEQ_CST);   // a local, never escapes
;     return old + a;
;   }
;   __attribute__((noinline)) int f2(int x, int k) { return x * 3 + k; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int r = f2(q, h(argc));          // stale q; h(argc) scheduled after the gate
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; `h(argc)` is a CLASSICAL operand scheduled after the gate, so the placement carries
; it to the slot with the call. A carried operand is asked the same question as a
; crossed call (`carriableEffects` = no observable ordered event, and a call only if
; `callCrossable`). `h` is carried because -O1 infers it `memory(none)`:
; `callCrossable` accepts on that summary and never inspects the atomic (LLVM's
; inference ignores an atomic on any alloca; the ESCAPE of its address would itself
; be a modeled effect). The capture test's own accept branch is pinned by
; lowering_stale_speccall_walked_local_atomic_accept.ll.
; The CHECK chain pins `h` and the clone call between the two Ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:.*]], double 5.000000e-01)
; CHECK-NEXT: %[[K:.*]] = tail call i32 @h(
; CHECK-NEXT: tail call i32 @__cq_q_f2_01(i32 noundef %[[H]], i32 noundef %[[K]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #4
  store i32 %0, ptr %2, align 4, !tbaa !6
  %3 = atomicrmw add ptr %2, i32 1 seq_cst, align 4
  %4 = load i32, ptr %2, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #4
  ret i32 %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #5
  %5 = tail call i32 @h(i32 noundef %0)
  %6 = tail call i32 @f2(i32 noundef %3, i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
