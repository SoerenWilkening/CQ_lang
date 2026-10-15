; railwindow_accept_two_walks.ll — ACCEPT (bd 01po.19 S4): two rotation walks
; over one `_Bool` array (the one-store bank refuses the second writer).
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; Analytic reading of the pinned stream: the walk at Q mints h0..h3 = |0>
; (alloc_i1 of each classical cell), walk 1 applies Ry(.3+.1i) to cell i's ONE
; rail, walk 2 applies Ry(.5) to the SAME rail (a fresh cell read is a borrowed
; root, never a reseed), and the measure walk measures those four rails. No
; rail is freed or reverse-played (R5: a cell holds user data).
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 -- two rotation walks over one array (the one-store bank refuses the second
;      writer). Each cell is rotated twice in place; nothing is freed. */
;   int f(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3 + .1 * i);
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .5);
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free
; S4-LABEL: define {{.*}} @f(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %9)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail2, double 5.000000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail4)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %9)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail2, double 5.000000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail4)

; ModuleID = 'twowalk.c'
source_filename = "twowalk.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 3.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %21, %14 ], [ 0, %2 ]
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef 5.000000e-01) #5
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %16, align 1, !tbaa !6
  %21 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, 4
  br i1 %22, label %24, label %14, !llvm.loop !15

23:                                               ; preds = %24
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %33

24:                                               ; preds = %14, %24
  %25 = phi i64 [ %34, %24 ], [ 0, %14 ]
  %26 = phi i32 [ %33, %24 ], [ 0, %14 ]
  %27 = shl nsw i32 %26, 1
  %28 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %25
  %29 = load i8, ptr %28, align 1, !tbaa !6, !range !10, !noundef !11
  %30 = trunc nuw i8 %29 to i1
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %30) #4
  %32 = zext i1 %31 to i32
  %33 = or disjoint i32 %27, %32
  %34 = add nuw nsw i64 %25, 1
  %35 = icmp eq i64 %34, 4
  br i1 %35, label %23, label %24, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 3.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %21, %14 ], [ 0, %2 ]
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef 5.000000e-01) #5
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %16, align 1, !tbaa !6
  %21 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, 4
  br i1 %22, label %23, label %14, !llvm.loop !15

23:                                               ; preds = %14, %23
  %24 = phi i64 [ %33, %23 ], [ 0, %14 ]
  %25 = phi i32 [ %32, %23 ], [ 0, %14 ]
  %26 = shl nsw i32 %25, 1
  %27 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %24
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = trunc nuw i8 %28 to i1
  %30 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #4
  %31 = zext i1 %30 to i32
  %32 = or disjoint i32 %26, %31
  %33 = add nuw nsw i64 %24, 1
  %34 = icmp eq i64 %33, 4
  br i1 %34, label %35, label %23, !llvm.loop !16

35:                                               ; preds = %23
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %32
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
