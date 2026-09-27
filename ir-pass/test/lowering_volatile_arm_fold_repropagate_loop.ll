; lowering_volatile_arm_fold_repropagate_loop.ll — DECLINE with the twin's string (bd
; test_C_libtooling-otam; bd vsfp Rule-13 r2A F-WA-1, probe `loop2`).
;
; The arm fold inside a runtime-trip loop, the select accumulated across iterations. Round 2
; emitted classical arithmetic on `%out` rail handles across the back edge and dropped the
; measurement; the fenv-intended twin declines `cq loop lowering: loop-carried tainted value
; crosses iterations`, and with the re-propagate so does this.
;
; Caller TU (clang -O1 -include CQ.h):
;   int main(int argc, char **argv) {
;     int q = cq_theta(0, 0.7);
;     int acc = 0;
;     for (int i = 0; i < argc; i++) {
;       int d;
;       if (q > i) { volatile int z = 1; d = 2; } else { d = 1; }
;       acc += d;
;     }
;     return cq_measure(acc);
;   }
;
; Regenerate: clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o <body>
;
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}cq loop lowering: loop-carried tainted value crosses iterations

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r3p/loop2.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r3p/loop2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %14, %2
  %7 = phi i32 [ 0, %2 ], [ %16, %14 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8

9:                                                ; preds = %2, %14
  %10 = phi i32 [ %17, %14 ], [ 0, %2 ]
  %11 = phi i32 [ %16, %14 ], [ 0, %2 ]
  %12 = icmp sgt i32 %4, %10
  br i1 %12, label %13, label %14

13:                                               ; preds = %9
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3)
  store volatile i32 1, ptr %3, align 4, !tbaa !6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3)
  br label %14

14:                                               ; preds = %9, %13
  %15 = phi i32 [ 2, %13 ], [ 1, %9 ]
  %16 = add nuw nsw i32 %15, %11
  %17 = add nuw nsw i32 %10, 1
  %18 = icmp eq i32 %17, %0
  br i1 %18, label %6, label %9, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
