; spec_reject_gate_sub_recursive.ll — DECLINE (bd test_C_libtooling-p3kd.21). A
; non-tail-RECURSIVE gate subroutine with a runtime depth:
;
;   __attribute__((noinline)) static bool rr(int n, bool t) {
;       if (n > 0) { t = rr(n - 1, t); cq_theta(&t, 0.1); t = rr(n - 2, t); }
;       return t;
;   }
;   q = rr(argc, q);
;
; Call-site compilation (SpecializeGateInline.h) never inlines a member of a call
; cycle (it would not terminate), so the call keeps its existing loud owner, the
; specializer's recursion check. The depth is classical (`argc`), not
; quantum-dependent, so this is a compiler GAP under NORTHSTAR goal 1, not a
; physics decline (follow-up filed from bd p3kd.21). A TAIL-recursive gate
; subroutine is not this: `-O1` turns it into a loop, and it compiles
; (spec_accept_gate_sub_tailrec_loop.ll). Mirrors the diagnostic
; character-for-character. `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq specialization: recursive callee has no static depth bound

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %4 = tail call fastcc zeroext i1 @rr(i32 noundef %0, i1 noundef zeroext %3)
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %6 = zext i1 %5 to i32
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc zeroext i1 @rr(i32 noundef %0, i1 noundef zeroext %1) unnamed_addr #2 {
  br label %3

3:                                                ; preds = %7, %2
  %4 = phi i32 [ %0, %2 ], [ %11, %7 ]
  %5 = phi i1 [ %1, %2 ], [ %10, %7 ]
  %6 = icmp sgt i32 %4, 0
  br i1 %6, label %7, label %12

7:                                                ; preds = %3
  %8 = add nsw i32 %4, -1
  %9 = tail call fastcc zeroext i1 @rr(i32 noundef %8, i1 noundef zeroext %5)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 1.000000e-01) #4
  %11 = add nsw i32 %4, -2
  br label %3

12:                                               ; preds = %3
  ret i1 %5
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
