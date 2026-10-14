; DECLINE (bd `test_C_libtooling-01po.19`): the stage's own size fence.
;
; Two store sites over `bool b[300]` with constant trip 300 > kMaxUnrollTrip (256): the
; stage refuses to unroll, its trial fails, and the module reaches the rail-bank verdict
; byte-untouched (`left for its owner`, never `scalarized`). The decline is a gap (code
; growth bound), not a physics limit; RETIREMENT TRIGGER: the rolled multi-site lowering.
;
; SOURCE (clang -O1, verbatim below):
;   /* two store sites, constant trip 300 > kMaxUnrollTrip (256): the stage refuses to
;      unroll and the array keeps its rail-bank decline. */
;   int main(void) {
;     bool b[300] = {0};
;     for (int i = 0; i < 300; ++i) cq_theta(&b[i], .5);
;     for (int i = 0; i < 300; ++i) cq_theta(&b[299 - i], .25);
;     int s = 0;
;     for (int i = 0; i < 300; ++i) s += cq_measure(b[i]);
;     return s;
;   }
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='scalarized'
; CHECK: CQ_RAILBANK_UNROLL_DBG: @main array {{.*}}left for its owner
; CHECK: cq rail bank: array is written from more than one store site

; ModuleID = 'cap.c'
source_filename = "cap.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [300 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 300, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(300) %1, i8 0, i64 300, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [300 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #5
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 300
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2, %11
  %12 = phi i64 [ %19, %11 ], [ 0, %2 ]
  %13 = sub nuw nsw i64 299, %12
  %14 = getelementptr inbounds [300 x i8], ptr %1, i64 0, i64 %13
  %15 = load i8, ptr %14, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = trunc nuw i8 %15 to i1
  %17 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %16, double noundef 2.500000e-01) #5
  %18 = zext i1 %17 to i8
  store i8 %18, ptr %14, align 1, !tbaa !6
  %19 = add nuw nsw i64 %12, 1
  %20 = icmp eq i64 %19, 300
  br i1 %20, label %22, label %11, !llvm.loop !15

21:                                               ; preds = %22
  call void @llvm.lifetime.end.p0(i64 300, ptr nonnull %1) #4
  ret i32 %30

22:                                               ; preds = %11, %22
  %23 = phi i64 [ %31, %22 ], [ 0, %11 ]
  %24 = phi i32 [ %30, %22 ], [ 0, %11 ]
  %25 = getelementptr inbounds [300 x i8], ptr %1, i64 0, i64 %23
  %26 = load i8, ptr %25, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %27) #4
  %29 = zext i1 %28 to i32
  %30 = add nuw nsw i32 %24, %29
  %31 = add nuw nsw i64 %23, 1
  %32 = icmp eq i64 %31, 300
  br i1 %32, label %21, label %22, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
