; lowering_reject_volatile_global_addrspace.ll — DECLINE (owner ruling 2026-09-26, bd memory
; `owner-ruling-volatile-unreachable-object-2026-09-26`: a volatile access is unobservable only if
; the object is unreachable from outside the program — never in a named section or at a fixed
; address, the ways MMIO is declared; bd test_C_libtooling-qce6, bd vsfp Rule-13 r4B F-YB-1).
;
; `static volatile int __attribute__((address_space(1))) K = 7;` · `if (q > 3) r = K;`. `#pragma clang section` does not set the IR `section` field: it attaches the global
; attribute `bss-section`/`data-section`, which the backend honours and `hasSection()` misses, so
; round 4 folded the device read to its INITIALIZER and ACCEPTED the program by deleting the
; quantum branch (exit 0, 2b clean). A NON-DEFAULT ADDRESS SPACE is refused too (owner decision
; 2026-09-27, conservative: device memory on GPU/embedded targets). Round 5 adds
; `G.hasImplicitSection()` and `G.getAddressSpace() != 0`; the volatile read stays in the tainted
; arm and the module declines exactly as its explicit-`section` sibling does on round 4 and 5
; (`value-arm swap-route`; the ORACLE declines this shape earlier, `control flow`).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   static volatile int __attribute__((address_space(1))) K = 7;
;   int main(int c, char **v) {
;     int q = atoi(v[1]) & 7; cq_theta(&q, .5);
;     int r = 0;
;     if (q > 3) r = K;
;     return cq_measure(r) + cq_measure(q);
;   }
;
; Regenerate: clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o <body>
;
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}cq controlled lowering: value-arm swap-route under quantum control

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r5b/g_as.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r5b/g_as.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@K = internal addrspace(1) global i32 7, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #3
  %8 = icmp sgt i32 %7, 3
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = load volatile i32, ptr addrspace(1) @K, align 4, !tbaa !10
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi i32 [ %10, %9 ], [ 0, %2 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %15 = add nsw i32 %14, %13
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
