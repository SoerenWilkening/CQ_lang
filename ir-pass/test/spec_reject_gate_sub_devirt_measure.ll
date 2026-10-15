; spec_reject_gate_sub_devirt_measure.ll — DECLINE: THE POSITIVE PIN of `scanBody`'s
; Measurement clause (bd test_C_libtooling-p3kd.21, R11 r1 item 3), which
; spec_reject_measurement.ll pinned before p3kd.21 turned it into an accept.
;
;   typedef int (*fp_t)(void *, int, int);
;   __attribute__((noinline)) static int g(void *f, int n, int x) {
;     int m = cq_measure(x + 1);
;     if (n > 0) return ((fp_t)f)(f, n - 1, x) + m;
;     return m;
;   }
;   printf("%d\n", g((void *)g, argc, q));   // q quantum
;
; As spec_reject_gate_sub_devirt_primitive.ll: the devirtualized inner call is
; refused by the inline history and reaches the specializer, which refuses to lift
; a body that measures. Mirrors the diagnostic character-for-character.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function g i32 (ptr, i32, i32): cq specialization: callee measures under quantum lift

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %4 = tail call i32 @g(ptr noundef nonnull @g, i32 noundef %0, i32 noundef %3)
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal i32 @g(ptr noundef %0, i32 noundef %1, i32 noundef %2) #3 {
  %4 = add nsw i32 %2, 1
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %6 = icmp sgt i32 %1, 0
  br i1 %6, label %7, label %11

7:                                                ; preds = %3
  %8 = add nsw i32 %1, -1
  %9 = tail call i32 %0(ptr noundef %0, i32 noundef %8, i32 noundef %2) #5
  %10 = add nsw i32 %9, %5
  br label %11

11:                                               ; preds = %3, %7
  %12 = phi i32 [ %10, %7 ], [ %5, %3 ]
  ret i32 %12
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
