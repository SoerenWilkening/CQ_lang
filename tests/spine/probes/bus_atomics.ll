; /* tests/spine probe (CR rules 4, 24): cmpxchg and atomicrmw are a bus load, the templates and a kept store. */
; _Atomic int c1 = 2, c2 = 3, c3 = 4;
; int atomics(int x0, double tx) {
;   int x = x0;
;   cq_theta(&x, tx);
;   int a = __c11_atomic_exchange(&c1, x, 5);
;   int exp = 3;
;   __c11_atomic_compare_exchange_strong(&c2, &exp, x, 5, 5);
;   int b = __c11_atomic_fetch_and(&c3, x, 5);
;   return cq_measure(a + exp + b);
; }
; ModuleID = 'bus_atomics.c'
source_filename = "bus_atomics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@c1 = global i32 2, align 4
@c2 = global i32 3, align 4
@c3 = global i32 4, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @atomics(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = atomicrmw xchg ptr @c1, i32 %3 seq_cst, align 4
  %5 = cmpxchg ptr @c2, i32 3, i32 %3 seq_cst seq_cst, align 4
  %6 = extractvalue { i32, i1 } %5, 0
  %7 = atomicrmw and ptr @c3, i32 %3 seq_cst, align 4
  %8 = add nsw i32 %6, %4
  %9 = add nsw i32 %8, %7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
; USERCHECK atomics
; CHECK-COUNT atomics: call void @cqrt_qram_store_i32_hl( 3
