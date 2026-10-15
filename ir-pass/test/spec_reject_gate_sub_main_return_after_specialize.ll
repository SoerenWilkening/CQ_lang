; spec_reject_gate_sub_main_return_after_specialize.ll — DECLINE (bd p3kd.21 R11 r2
; F1 decision). `main` returns a value that is a register AFTER specialization:
;
;   __attribute__((noinline)) int h(int a, int k) { return a + k; }   // reads `a`
;   int main(int argc, char **argv) { ...; cq_theta(&q, 0.5); return h(q, m); }
;
; `h` is lifted on `q` and its clone returns a register (`q + m`), so the
; specializer's verdict keeps `main`'s `ret` tainted, and the decision taken after
; `specialize()` (`declineTaintedMainReturns`) refuses it. Mirrors the diagnostic
; character-for-character. `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function main i32 (i32, ptr): cq taint escape: quantum value returned from main without cq_measure

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5)
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
