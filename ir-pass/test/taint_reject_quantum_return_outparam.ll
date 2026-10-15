; taint_reject_quantum_return_outparam.ll — DECLINE (bd test_C_libtooling-3jru).
;
; Rule-13 round 3 r12: `void g2(int k, int *o) { *o = h(k); }` with `h`
; returning a register. Before 3jru the store was UNTAINTED (so no store guard);
; with `h(k)` tainted at its call site the existing store-escape guard now fires,
; which is the owner that speaks first.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   __attribute__((noinline)) int h(int k) { cq_theta(&k, 0.7); return k; }
;   __attribute__((noinline)) void g(int k, int *o) { *o = h(k); }
;   __attribute__((noinline)) static int slice(int m, int n) {
;     int q = 0; cq_theta(&q, 0.5);
;     int r; g(m, &r);
;     int a = 7;
;     if ((q > 1) & (r == n)) a += 3;
;     return cq_measure(q) + cq_measure(a);
;   }
;   int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
;
; bd p3kd.21 R11 r1 fix (2026-10-15) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. `g` and `h` are GATE SUBROUTINES (`h` holds `cq_theta`, `g` calls it) and
; the module defines `main`, so after `g` is compiled at its site in `slice` (a
; pointer argument the callee stores a register through) and `h` at its site
; in turn, both are erased (R11 r1 item 5); the standalone `g` body whose store
; was this fixture's decline no longer exists. The register is the caller's own, and
; the module compiles exactly as its hand-inlined twin does on the pre-change
; binary (same gate stream as taint_reject_quantum_return_helper_arg.ll's twin, minus
; the lifted `tw`). The 3jru refusal itself is unchanged and still pinned by
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
; CHECK-NEXT: [[C1:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: [[C2:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[R]], i32 %1)
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
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[C2]], i32 [[R]], i32 %1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[C1]], i32 [[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C1]])
; CHECK-NEXT: [[MQ:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-NEXT: [[MA:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[OUT]])
; CHECK-NOT: @g(
; CHECK-NOT: @h(

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r12_outparam_untainted.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r12_outparam_untainted.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #5
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define void @g(i32 noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #0 {
  %3 = tail call i32 @h(i32 noundef %0)
  store i32 %3, ptr %1, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !10
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !10
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call fastcc i32 @slice(i32 noundef %5, i32 noundef %8)
  ret i32 %9
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5
  call void @g(i32 noundef %0, ptr noundef nonnull %3)
  %5 = icmp sgt i32 %4, 1
  %6 = load i32, ptr %3, align 4, !tbaa !6
  %7 = icmp eq i32 %6, %1
  %8 = and i1 %5, %7
  %9 = select i1 %8, i32 10, i32 7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %12 = add nsw i32 %11, %10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5
  ret i32 %12
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
