; taint_reject_quantum_return_volatile_flag.ll — DECLINE (bd test_C_libtooling-3jru).
;
; Rule-13 round 4 (q61): `slice` returns `cq_measure(a) + flag`, where the
; `volatile _Bool flag` is rewritten under the quantum condition `(q > 1) & flag`;
; after the arm is flattened `flag` is a quantum-condition mux, so `slice`'s `ret`
; is tainted and its use in `main` is refused (the oracle declined `control flow`
; at an earlier owner). Pinned as the owner that speaks on this binary.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   __attribute__((noinline)) static int slice(int m, int n) {
;     volatile _Bool flag = (m == n);
;     int q = 0; cq_theta(&q, 0.5);
;     int a = 7;
;     if ((q > 1) & flag) { flag = 0; a += 3; }
;     return cq_measure(a) + flag;
;   }
;   int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
;
; bd p3kd.21 (2026-10-15) — NOW AN ACCEPT; the file name and the DECLINE text above
; are history. `slice` holds `cq_theta` and returns a value its own register decides (the
; volatile flag's quantum-condition mux, pinned nowhere else), so its used result
; is compiled at the call site (trigger (c)). The register is the caller's own and the
; module compiles as its hand-inlined twin does on the pre-change binary (`slice` force-inlined: the same gates; -O1 spells the flag test `slt`/`or`
; there and `sgt`/`and` here).
; `main` MEASURES what it returns (a register returned from `main` is refused,
; spec_reject_gate_sub_main_return.ll; bd r2j3.35), so the stream below is the
; accepted one plus that measurement. The 3jru refusal itself is unchanged and
; still pinned by taint_reject_quantum_return_fnptr.ll and
; spec_reject_predicted_classical_round2_return_crossing.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @main(
; CHECK: [[K:%[0-9]+]] = icmp eq i32 %5, %8
; CHECK: [[Q:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[C:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: [[F:%[0-9a-z_.]+]] = call i32 @cq_template_and_i1_hl(i32 [[C]], i1 [[K]])
; CHECK-NEXT: call void @cqrt_xorc_i1(i32 [[F]], i1 [[K]])
; CHECK: [[M:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(
; CHECK-NEXT: [[W:%[0-9a-z_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 [[F]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[W]], i32 [[M]])
; CHECK-NEXT: [[MW:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[W]])
; CHECK-NEXT: ret i32 [[MW]]
; CHECK-NOT: @slice(

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r4/q61_volatile_arm.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r4/q61_volatile_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call fastcc i32 @slice(i32 noundef %5, i32 noundef %8)
  %cq.main.m = call i32 @cq_measure_si32(i32 %9)
  ret i32 %cq.main.m
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %3)
  %4 = icmp eq i32 %0, %1
  %5 = zext i1 %4 to i8
  store volatile i8 %5, ptr %3, align 1, !tbaa !10
  %6 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %7 = icmp slt i32 %6, 2
  %8 = load volatile i8, ptr %3, align 1, !tbaa !10, !range !12, !noundef !13
  %9 = icmp eq i8 %8, 0
  %10 = or i1 %7, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %2
  store volatile i8 0, ptr %3, align 1, !tbaa !10
  br label %12

12:                                               ; preds = %11, %2
  %13 = phi i32 [ 10, %11 ], [ 7, %2 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %15 = load volatile i8, ptr %3, align 1, !tbaa !10, !range !12, !noundef !13
  %16 = zext nneg i8 %15 to i32
  %17 = add nsw i32 %14, %16
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3)
  ret i32 %17
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"_Bool", !8, i64 0}
!12 = !{i8 0, i8 2}
!13 = !{}
