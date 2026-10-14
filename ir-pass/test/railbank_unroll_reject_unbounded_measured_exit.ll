; DECLINE (bd `test_C_libtooling-01po.19`, review round 1 item 3): the max-trip
; admission's own fence. A measured early exit whose loop has NO constant max trip
; (`for (unsigned i = 0; !cq_measure(q[i & 3]); i++)`) cannot be unrolled; the trial
; fails and the array keeps its rail-bank decline. A gap (the rolled lowering), not a
; physics limit.
;
; SOURCE (clang -O1, verbatim below):
;   /* early exit on a measured cell with NO constant max trip (i grows without bound,
;      the index wraps with i & 3): the stage cannot unroll it and the array keeps its
;      rail-bank decline. */
;   int main(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .5);
;     for (int i = 1; i < 4; i++) q[i] ^= q[i - 1];
;     int n = 0;
;     for (unsigned i = 0; !cq_measure(q[i & 3]); i++) n++;
;     return n;
;   }
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='scalarized'
; CHECK: CQ_RAILBANK_UNROLL_DBG: @main array {{.*}}left for its owner
; CHECK: cq rail bank: array is written from more than one store site

; ModuleID = 'exit_unbounded.c'
source_filename = "exit_unbounded.c"
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
  br label %17

13:                                               ; preds = %17
  %14 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #3
  br i1 %16, label %26, label %28

17:                                               ; preds = %11, %17
  %18 = phi i8 [ %12, %11 ], [ %23, %17 ]
  %19 = phi i64 [ 1, %11 ], [ %24, %17 ]
  %20 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = icmp ne i8 %21, %18
  %23 = zext i1 %22 to i8
  store i8 %23, ptr %20, align 1, !tbaa !6
  %24 = add nuw nsw i64 %19, 1
  %25 = icmp eq i64 %24, 4
  br i1 %25, label %13, label %17, !llvm.loop !15

26:                                               ; preds = %28, %13
  %27 = phi i32 [ 0, %13 ], [ %30, %28 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %27

28:                                               ; preds = %13, %28
  %29 = phi i32 [ %30, %28 ], [ 0, %13 ]
  %30 = add nuw i32 %29, 1
  %31 = and i32 %30, 3
  %32 = zext nneg i32 %31 to i64
  %33 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %35) #3
  br i1 %36, label %26, label %28, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

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
