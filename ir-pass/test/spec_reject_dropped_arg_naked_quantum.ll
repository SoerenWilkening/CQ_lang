; spec_reject_dropped_arg_naked_quantum.ll — DECLINE, the oracle's verdict (bd
; test_C_libtooling-ctz4, bd vsfp Rule-13 r1A F-VA-1 `naked2`).
;
; `ident(q)` with `q` quantum and a `naked` callee. The oracle declines at the specializer
; (inline assembly cannot be lifted) — correct. Round 1's drop rewrote the argument to `0`
; first, so the call stopped being a Phase-6 site and the module ACCEPTED at exit 0 with the
; asm receiving 0. With DAE's `naked` precondition mirrored the drop leaves the call alone
; and the verdict is the oracle's again; the census line must be absent.
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int ident(int a);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = ident(q); return r + cq_measure(q); }
; Library TU (plain C, no CQ.h):
;   __attribute__((naked, noinline)) int ident(int a) { __asm__("movl %edi, %eax\n\tret"); }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (inline assembly)

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #4
  %8 = tail call i32 @ident(i32 noundef %7) #4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: naked noinline nounwind ssp uwtable
define i32 @ident(i32 noundef %0) #3 {
  tail call void asm sideeffect "movl %edi, %eax\0A\09ret", "~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !10
  unreachable
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { naked noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i64 62, i64 80}
