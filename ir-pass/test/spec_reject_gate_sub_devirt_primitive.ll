; spec_reject_gate_sub_devirt_primitive.ll — DECLINE: THE POSITIVE PIN of
; `scanBody`'s QuantumPrimitive clause (bd test_C_libtooling-p3kd.21, R11 r1 item
; 3), the Rule-7 copy-out guard spec_reject_cq_primitive.ll pinned before p3kd.21
; turned it into an accept.
;
;   typedef int (*fp_t)(void *, int, int);
;   __attribute__((noinline)) static int g(void *f, int n, int x) {
;     cq_theta(&x, 0.1);
;     if (n > 0) return ((fp_t)f)(f, n - 1, x);
;     return x;
;   }
;   int r = g((void *)g, argc, q);   // q quantum
;
; The first call is compiled at its site; the devirtualized inner `g(g, …, x)` is
; refused by the inline history (spec_reject_gate_sub_devirt_self_call.ll), so it
; reaches the specializer with a quantum argument, and `scanBody` refuses to
; Bennett-lift a body holding a rotation. Every other gate call is compiled at its
; site, so a gate callee reaches a lift site only this way, as a call-cycle member
; (the recursion check speaks first), as an interposable callee (the link-exact
; check speaks first), or through a site `InlineFunction` refuses. Mirrors the
; diagnostic character-for-character. `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function g i32 (ptr, i32, i32): cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %4 = tail call i32 @g(ptr noundef nonnull @g, i32 noundef %0, i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %5)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal i32 @g(ptr noundef %0, i32 noundef %1, i32 noundef %2) #2 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e-01) #4
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %3
  %7 = add nsw i32 %1, -1
  %8 = tail call i32 %0(ptr noundef %0, i32 noundef %7, i32 noundef %4) #5
  br label %9

9:                                                ; preds = %3, %6
  %10 = phi i32 [ %8, %6 ], [ %4, %3 ]
  ret i32 %10
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
