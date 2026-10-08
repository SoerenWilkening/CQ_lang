; lowering_stale_speccall_reject_carried_writer_conflict.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 6 F2): the decline twin of
; lowering_stale_speccall_carried_writer_accept.ll.
;
;   int counter;
;   __attribute__((noinline)) int bump(void) { return ++counter; }
;   __attribute__((noinline)) int f2(int x, int k) { return x * 3 + k; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int c0 = counter;                // reads counter BEFORE bump()
;     int r = f2(q, bump());           // stale q; bump() would be carried above c0
;     return (int)cq_measure(r) + (int)cq_measure(q2) + c0;
;   }
;
; Carrying `bump()` above the gate would move a WRITE of `counter` above the load
; `c0 = counter`, so `c0` would read the incremented value. Clause (e) refuses it (a
; moved writer crosses no access, asked of `bump`'s own memory summary), and the
; stale fence declines. This is the first fixture that reaches clause (e)'s writer
; term with a carried call (reachable since review round 5).
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@counter = local_unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define range(i32 -2147483647, -2147483648) i32 @bump() local_unnamed_addr #0 {
  %1 = load i32, ptr @counter, align 4, !tbaa !6
  %2 = add nsw i32 %1, 1
  store i32 %2, ptr @counter, align 4, !tbaa !6
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #4
  %3 = load i32, ptr @counter, align 4, !tbaa !6
  %4 = tail call i32 @bump()
  %5 = tail call i32 @f2(i32 noundef %1, i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #5
  %8 = add i32 %6, %3
  %9 = add i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
