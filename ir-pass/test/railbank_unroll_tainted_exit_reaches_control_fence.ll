; PROBE (bd `test_C_libtooling-01po.19`, review round 1 item 3): an early exit on an
; UNMEASURED quantum cell. The constant max trip admits the unroll, and every exit
; stays a conditional branch on a QUANTUM condition, which the control chain owns: it
; must lower it or fail loudly, never treat it as classical control. Today it is loud.
; RETIREMENT TRIGGER: when the control chain lowers this, re-derive as an ACCEPT.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial: an early exit on an UNMEASURED quantum cell. The constant max trip
;      admits the unroll; the exits stay conditional branches on quantum conditions,
;      which the control chain then owns (lower or loud), never a classical branch. */
;   int main(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .5);
;     for (int i = 1; i < 4; i++) q[i] ^= q[i - 1];
;     int n = 0;
;     for (int i = 0; i < 4; i++) { if (q[i]) break; n++; }
;     return cq_measure(n);
;   }
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank'
; CHECK: CQ_RAILBANK_UNROLL_DBG: @main array {{.*}}scalarized
; CHECK: cq controlled lowering: control flow under quantum control

; ModuleID = 'exit_tainted.c'
source_filename = "exit_tainted.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #4
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 4
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2
  %12 = load i8, ptr %1, align 4
  br label %13

13:                                               ; preds = %11, %13
  %14 = phi i8 [ %12, %11 ], [ %19, %13 ]
  %15 = phi i64 [ 1, %11 ], [ %20, %13 ]
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = icmp ne i8 %17, %14
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %16, align 1, !tbaa !6
  %20 = add nuw nsw i64 %15, 1
  %21 = icmp eq i64 %20, 4
  br i1 %21, label %22, label %13, !llvm.loop !15

22:                                               ; preds = %13, %27
  %23 = phi i64 [ %28, %27 ], [ 0, %13 ]
  %24 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %23
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  br i1 %26, label %30, label %27

27:                                               ; preds = %22
  %28 = add nuw nsw i64 %23, 1
  %29 = icmp eq i64 %28, 4
  br i1 %29, label %32, label %22, !llvm.loop !16

30:                                               ; preds = %22
  %31 = trunc i64 %23 to i32
  br label %32

32:                                               ; preds = %27, %30
  %33 = phi i32 [ %31, %30 ], [ 4, %27 ]
  %34 = tail call i32 @cq_measure_si32(i32 noundef %33) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %34
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
