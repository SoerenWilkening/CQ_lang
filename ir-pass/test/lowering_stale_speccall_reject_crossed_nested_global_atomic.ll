; lowering_stale_speccall_reject_crossed_nested_global_atomic.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 5 R5-1; OWNER RULING 2026-10-08, bd memory
; owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08).
;
;   int calls;
;   int g_ctr;
;   __attribute__((noinline)) int h(int x) {
;     int old = __atomic_fetch_add(&g_ctr, 1, __ATOMIC_SEQ_CST);   // a GLOBAL
;     return old + x;
;   }
;   __attribute__((noinline)) void tick(void) { calls = h(calls); }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     tick();                          // CROSSED; h one call level down
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + calls;
;   }
;
; The decline twin of lowering_stale_speccall_crossed_nested_local_atomic_accept.ll:
; the atomic's object is a global, visible outside `h`, so it is an observable ordered
; event, and the walk of `tick` refuses it one level down. The stale fence declines.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g_ctr = global i32 0, align 4
@calls = local_unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = atomicrmw add ptr @g_ctr, i32 1 seq_cst, align 4
  %3 = add nsw i32 %2, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, inaccessiblemem: none) uwtable
define void @tick() local_unnamed_addr #1 {
  %1 = load i32, ptr @calls, align 4, !tbaa !6
  %2 = tail call i32 @h(i32 noundef %1)
  store i32 %2, ptr @calls, align 4, !tbaa !6
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #5
  tail call void @tick()
  %3 = tail call i32 @f(i32 noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #6
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #6
  %6 = add nsw i32 %5, %4
  %7 = load i32, ptr @calls, align 4, !tbaa !6
  %8 = add nsw i32 %6, %7
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
