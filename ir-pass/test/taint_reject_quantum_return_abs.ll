; taint_reject_quantum_return_abs.ll — DECLINE (bd test_C_libtooling-3jru).
;
; Rule-13 round 3 r01: `abs(g(m))` → `@llvm.abs` (a declaration) hid the call
; from the syntactic conjunct (d) this change first shipped. At the taint layer the
; call result is simply tainted.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   __attribute__((noinline)) int g(int k) { cq_theta(&k, 0.7); return k; }
;   __attribute__((noinline)) static int slice(int m, int n) {
;     int q = 0; cq_theta(&q, 0.5);
;     int r = g(m);
;     int ar = abs(r);
;     int a = 7;
;     if ((q > 1) & (ar == n)) a += 3;
;     return cq_measure(q) + cq_measure(a);
;   }
;   int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
;
; bd p3kd.21 (2026-10-14) — NOW AN ACCEPT; the file name and the DECLINE text
; above are history. The returning callee is a GATE SUBROUTINE (it holds
; `cq_theta`), so its call is compiled at the call site (SpecializeGateInline.h,
; trigger (c): a used register return) and the 3jru crossing no longer exists: the
; register is the caller's own. Measured: the lowered body is identical, call for
; call, to `clang -O1` of the same source with the helper force-inlined, on the
; pre-change binary (taint_reject_quantum_return_helper_arg.ll's twin). The CHECKs
; capture every rail and pin each operand, each `_unc` right before its
; `cqrt_free`, and the user's measurements (R11 r1 item 8: reviewer mutants M1-M3
; reading the handle id classically, deleting a `cq_measure`, or dropping an
; `_unc`, are killed). The 3jru refusal itself is unchanged and still pinned by
; taint_reject_quantum_return_fnptr.ll and
; spec_reject_predicted_classical_round2_return_crossing.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define internal fastcc i32 @slice(
; CHECK-NEXT: [[Q:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[R:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[R]], double 0x3FE6666666666666)
; CHECK-NEXT: [[S:%[0-9a-z_.]+]] = call i32 @cq_template_abs_i32(i32 [[R]])
; CHECK-NEXT: [[C1:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: [[C2:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[S]], i32 %1)
; CHECK-NEXT: [[G:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[C1]], i32 [[C2]], i32 [[G]])
; CHECK-NEXT: [[OUT:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[G]], i32 [[OUT]], i32 10)
; CHECK-NEXT: call void @cqrt_x(i32 [[G]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[G]], i32 [[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 [[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[C1]], i32 [[C2]], i32 [[G]])
; CHECK-NEXT: call void @cqrt_free(i32 [[G]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[C2]], i32 [[S]], i32 %1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[C1]], i32 [[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C1]])
; CHECK-NEXT: [[MQ:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-NEXT: [[MA:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[OUT]])
; CHECK-NEXT: {{%[0-9]+}} = add nsw i32 [[MA]], [[MQ]]
; CHECK-NOT: call {{.*}}@g(

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r01_abs.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r01_abs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #5
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call fastcc i32 @slice(i32 noundef %5, i32 noundef %8)
  ret i32 %9
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %4 = tail call i32 @g(i32 noundef %0)
  %5 = tail call i32 @llvm.abs.i32(i32 %4, i1 true)
  %6 = icmp sgt i32 %3, 1
  %7 = icmp eq i32 %5, %1
  %8 = and i1 %6, %7
  %9 = select i1 %8, i32 10, i32 7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
