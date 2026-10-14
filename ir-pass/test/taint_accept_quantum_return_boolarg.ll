; taint_accept_quantum_return_boolarg.ll (formerly taint_reject_quantum_return_boolarg.ll)
; — ACCEPT since bd test_C_libtooling-p3kd.21; was a DECLINE (bd test_C_libtooling-3jru).
;
; Rule-13 round 3 r04: `slice(g(x) == n)` — the literal is a `_Bool` ARGUMENT of
; `slice`, computed in `main` from the returned register. With the return tainted,
; the tainted `bool` argument reaches the Phase-6 specializer first, which declines
; with its own string (pinned here, the owner that speaks first).
;
; bd p3kd.9 (2026-10-13): a tainted `_Bool` (i1) argument is now a lift-boundary
; handle (`liftHandleWidth`: it has `cqrt_copy_i1`), so the per-site ABI check no
; longer speaks first. The next owner is the body scan: `slice` itself calls
; `cq_theta`/`cq_measure`, and lifting stays classical-callee-only (owner ruling
; owner-ruling-lift-classical-only-2026-10-06), so it declines `callee contains a
; quantum primitive`. Still a loud decline of the same program, now on its true
; ground; the expectation moved with the capability change (R10).
;
; Source (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   __attribute__((noinline)) int g(int k) { cq_theta(&k, 0.7); return k; }
;   __attribute__((noinline)) static int slice(_Bool c) {
;     int q = 0; cq_theta(&q, 0.5);
;     int a = 7;
;     if ((q > 1) & c) a += 3;
;     return cq_measure(q) + cq_measure(a);
;   }
;   int main(int argc, char **argv) { int r = g(atoi(argv[1])); return slice(r == atoi(argv[2])); }
;
;
; bd p3kd.21 (2026-10-14): both `g` (a used quantum return, the 3jru crossing)
; and `slice` (a tainted `_Bool` argument) are GATE SUBROUTINES and are compiled
; at their call sites (SpecializeGateInline.h), and both are then erased (the
; module defines `main`). Inlined, `main` rotates `r`'s register in place,
; computes `c = (r == n)` as a compare flag, and `slice`'s select
; `(q > 1) & c ? 10 : 7` is the 4.4 controlled-copy merge on the Toffoli of the
; two flags; both flags are uncomputed and freed, `q` and the merge rail are
; measured. The CHECKs capture every rail and pin each `_unc` right before its
; `cqrt_free` (R11 r1 item 8, reviewer mutant M3). The 3jru refusal itself is
; unchanged and still pinned by taint_reject_quantum_return_fnptr.ll and
; spec_reject_predicted_classical_round2_return_crossing.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @main(
; CHECK: [[R:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[R]], double 0x3FE6666666666666)
; CHECK: [[N:%[0-9]+]] = tail call i32 @atoi(
; CHECK-NEXT: [[Q:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[C1:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[R]], i32 [[N]])
; CHECK-NEXT: [[C2:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: [[G:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[C1]], i32 [[C2]], i32 [[G]])
; CHECK-NEXT: [[OUT:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: [[S1:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 [[G]], i32 [[S1]], i32 [[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 [[G]])
; CHECK-NEXT: [[S2:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 [[G]], i32 [[S2]], i32 [[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 [[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[C1]], i32 [[C2]], i32 [[G]])
; CHECK-NEXT: call void @cqrt_free(i32 [[G]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[C2]], i32 [[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C2]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[C1]], i32 [[R]], i32 [[N]])
; CHECK-NEXT: call void @cqrt_free(i32 [[C1]])
; CHECK-NEXT: [[MQ:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-NEXT: [[MA:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[OUT]])
; CHECK-NEXT: {{%[0-9]+}} = add nsw i32 [[MA]], [[MQ]]
; CHECK-NOT: @slice(
; CHECK-NOT: @g(

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r04_boolarg.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r04_boolarg.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #4
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @g(i32 noundef %5)
  %7 = getelementptr inbounds i8, ptr %1, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !6
  %9 = tail call i32 @atoi(ptr nocapture noundef %8)
  %10 = icmp eq i32 %6, %9
  %11 = tail call fastcc i32 @slice(i1 noundef zeroext %10)
  ret i32 %11
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i1 noundef zeroext %0) unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %3 = icmp sgt i32 %2, 1
  %4 = and i1 %3, %0
  %5 = select i1 %4, i32 10, i32 7
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
