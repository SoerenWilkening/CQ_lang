; lowering_stale_speccall_reject_crossed_escaped_local_atomic.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 5 R5-1; OWNER RULING 2026-10-08, bd memory
; owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08).
;
;   int *published;
;   __attribute__((noinline)) int h(int x) {
;     int a = x;
;     published = &a;                  // the local's address ESCAPES
;     int old = __atomic_fetch_add(&a, 1, __ATOMIC_SEQ_CST);
;     published = 0;
;     return old + a;
;   }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int k = h(argc);                 // CROSSED
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + k;
;   }
;
; The atomic is on a local, but its address is stored to a global first, so it may be
; visible outside `h` (`PointerMayBeCaptured`): an observable ordered event, refused.
; The escape is a STORE rather than an opaque call so that the escape test itself is
; what declines (an opaque call in the body would refuse the crossing on its own).
; Contrast lowering_stale_speccall_crossed_local_atomic_accept.ll. The stale fence
; declines.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@published = local_unnamed_addr global ptr null, align 8

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #5
  store i32 %0, ptr %2, align 4, !tbaa !6
  store ptr %2, ptr @published, align 8, !tbaa !10
  %3 = atomicrmw add ptr %2, i32 1 seq_cst, align 4
  store ptr null, ptr @published, align 8, !tbaa !10
  %4 = load i32, ptr %2, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #5
  ret i32 %5
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
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #6
  %5 = tail call i32 @h(i32 noundef %0)
  %6 = tail call i32 @f(i32 noundef %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %9 = add i32 %7, %5
  %10 = add i32 %9, %8
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
