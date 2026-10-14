; lowering_volatile_arm_fold_cascade_merge_phi.ll — DECLINE with the twin's string (bd
; test_C_libtooling-1xp9; r3B probe `u4`, the second merge has a φ). Round 3 segfaulted (exit
; 139), round 2 aborted in the verifier (exit 134). Now a clean decline with the SAME string as
; the fenv-intended twin `u4T` (`control flow under quantum control` — a pre-existing shape the
; control layer does not claim), which is what a crash regression pin must show: rc 1, not 139.
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int main(int c, char **v) {
;     int m = atoi(v[1]);
;     _Bool a = m > 5, b = m < 2;
;     int q = m & 7; cq_theta(&q, .5);
;     _Bool p;
;     if (q > 3) { volatile int z = 1; p = a; } else { p = b; }
;     int r = m + 7;
;     if (p) { volatile int w = 2; r = m; }
;     return cq_measure(q) + a + b + r;
;   }
;
; Regenerate: clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o <body>
;
;
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}cq controlled lowering: control flow under quantum control

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r4b/u4.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r4b/u4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = getelementptr inbounds i8, ptr %1, i64 8
  %6 = load ptr, ptr %5, align 8, !tbaa !6
  %7 = tail call i32 @atoi(ptr nocapture noundef %6)
  %8 = icmp sgt i32 %7, 5
  %9 = icmp slt i32 %7, 2
  %10 = and i32 %7, 7
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 5.000000e-01) #4
  %12 = icmp sgt i32 %11, 3
  br i1 %12, label %13, label %14

13:                                               ; preds = %2
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3)
  store volatile i32 1, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3)
  br label %14

14:                                               ; preds = %2, %13
  %15 = phi i1 [ %8, %13 ], [ %9, %2 ]
  %16 = add nsw i32 %7, 7
  br i1 %15, label %17, label %18

17:                                               ; preds = %14
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4)
  store volatile i32 2, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4)
  br label %18

18:                                               ; preds = %17, %14
  %19 = phi i32 [ %7, %17 ], [ %16, %14 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %21 = zext i1 %8 to i32
  %22 = zext i1 %9 to i32
  %23 = add nuw nsw i32 %22, %21
  %24 = add i32 %23, %19
  %25 = add i32 %24, %20
  %cq.main.m = call i32 @cq_measure_si32(i32 %25)
  ret i32 %cq.main.m
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
