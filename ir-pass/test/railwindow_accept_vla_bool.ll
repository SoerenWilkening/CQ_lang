; railwindow_accept_vla_bool.ll — ACCEPT (bd 01po.19 S4): a runtime-length
; `_Bool` VLA (an i8 VLA, which the one-store bank's i32-only VLA rule refuses).
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; Analytic reading: the classical init `q[i] = i & 1` stays classical memory;
; the walk at Q (guarded by n != 0) mints alloc_i1(cell) for every cell; two
; rotation walks then hit each cell's one rail and the measure walk reads them.
; Traced for n=3: alloc 0,1,0; Ry(.3) x3; Ry(.2) x3; measure h0,h1,h2.
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 -- runtime-length bool array (i8 VLA), two walks. */
;   int f(int n) {
;     bool q[n];
;     for (int i = 0; i < n; i++) q[i] = (i & 1);
;     for (int i = 0; i < n; i++) cq_theta(&q[i], .3);
;     for (int i = 0; i < n; i++) cq_theta(&q[i], .2);
;     int r = 0;
;     for (int i = 0; i < n; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(3); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free
; S4-LABEL: define {{.*}} @f(
; S4: %.rails = alloca i32, i64 %2, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %12)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double 3.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail2, double 2.000000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail4)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 3, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %10)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double 3.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail3 = load i32, ptr %cq.rail.addr2, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail3, double 2.000000e-01)
; S4: store i32 %.rail3, ptr %cq.rail.addr2, align 4
; S4: %.rail5 = load i32, ptr %cq.rail.addr4, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail5)

; ModuleID = 'vla.c'
source_filename = "vla.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = zext i32 %0 to i64
  %3 = alloca i8, i64 %2, align 16
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = zext nneg i32 %0 to i64
  br label %11

7:                                                ; preds = %11, %1
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %18

9:                                                ; preds = %7
  %10 = zext nneg i32 %0 to i64
  br label %22

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %16, %11 ]
  %13 = getelementptr inbounds i8, ptr %3, i64 %12
  %14 = trunc i64 %12 to i8
  %15 = and i8 %14, 1
  store i8 %15, ptr %13, align 1, !tbaa !6
  %16 = add nuw nsw i64 %12, 1
  %17 = icmp eq i64 %16, %6
  br i1 %17, label %7, label %11, !llvm.loop !10

18:                                               ; preds = %22, %7
  %19 = icmp sgt i32 %0, 0
  br i1 %19, label %20, label %31

20:                                               ; preds = %18
  %21 = zext nneg i32 %0 to i64
  br label %35

22:                                               ; preds = %9, %22
  %23 = phi i64 [ 0, %9 ], [ %29, %22 ]
  %24 = getelementptr inbounds i8, ptr %3, i64 %23
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !13, !noundef !14
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef 3.000000e-01) #3
  %28 = zext i1 %27 to i8
  store i8 %28, ptr %24, align 1, !tbaa !6
  %29 = add nuw nsw i64 %23, 1
  %30 = icmp eq i64 %29, %10
  br i1 %30, label %18, label %22, !llvm.loop !15

31:                                               ; preds = %35, %18
  %32 = icmp sgt i32 %0, 0
  br i1 %32, label %33, label %44

33:                                               ; preds = %31
  %34 = zext nneg i32 %0 to i64
  br label %46

35:                                               ; preds = %20, %35
  %36 = phi i64 [ 0, %20 ], [ %42, %35 ]
  %37 = getelementptr inbounds i8, ptr %3, i64 %36
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !13, !noundef !14
  %39 = trunc nuw i8 %38 to i1
  %40 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %39, double noundef 2.000000e-01) #3
  %41 = zext i1 %40 to i8
  store i8 %41, ptr %37, align 1, !tbaa !6
  %42 = add nuw nsw i64 %36, 1
  %43 = icmp eq i64 %42, %21
  br i1 %43, label %31, label %35, !llvm.loop !16

44:                                               ; preds = %46, %31
  %45 = phi i32 [ 0, %31 ], [ %55, %46 ]
  ret i32 %45

46:                                               ; preds = %33, %46
  %47 = phi i64 [ 0, %33 ], [ %56, %46 ]
  %48 = phi i32 [ 0, %33 ], [ %55, %46 ]
  %49 = shl nsw i32 %48, 1
  %50 = getelementptr inbounds i8, ptr %3, i64 %47
  %51 = load i8, ptr %50, align 1, !tbaa !6, !range !13, !noundef !14
  %52 = trunc nuw i8 %51 to i1
  %53 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %52) #4
  %54 = zext i1 %53 to i32
  %55 = or disjoint i32 %49, %54
  %56 = add nuw nsw i64 %47, 1
  %57 = icmp eq i64 %56, %34
  br i1 %57, label %44, label %46, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1)
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds i8, ptr %1, i64 %3
  %5 = trunc i64 %3 to i8
  %6 = and i8 %5, 1
  store i8 %6, ptr %4, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %9, label %2, !llvm.loop !10

9:                                                ; preds = %2, %9
  %10 = phi i64 [ %16, %9 ], [ 0, %2 ]
  %11 = getelementptr inbounds i8, ptr %1, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !13, !noundef !14
  %13 = trunc nuw i8 %12 to i1
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 3.000000e-01) #3
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %11, align 1, !tbaa !6
  %16 = add nuw nsw i64 %10, 1
  %17 = icmp eq i64 %16, 3
  br i1 %17, label %18, label %9, !llvm.loop !15

18:                                               ; preds = %9, %18
  %19 = phi i64 [ %25, %18 ], [ 0, %9 ]
  %20 = getelementptr inbounds i8, ptr %1, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !13, !noundef !14
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef 2.000000e-01) #3
  %24 = zext i1 %23 to i8
  store i8 %24, ptr %20, align 1, !tbaa !6
  %25 = add nuw nsw i64 %19, 1
  %26 = icmp eq i64 %25, 3
  br i1 %26, label %27, label %18, !llvm.loop !16

27:                                               ; preds = %18, %27
  %28 = phi i64 [ %37, %27 ], [ 0, %18 ]
  %29 = phi i32 [ %36, %27 ], [ 0, %18 ]
  %30 = shl nsw i32 %29, 1
  %31 = getelementptr inbounds i8, ptr %1, i64 %28
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !13, !noundef !14
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33) #4
  %35 = zext i1 %34 to i32
  %36 = or disjoint i32 %30, %35
  %37 = add nuw nsw i64 %28, 1
  %38 = icmp eq i64 %37, 3
  br i1 %38, label %39, label %27, !llvm.loop !17

39:                                               ; preds = %27
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1)
  ret i32 %36
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nomerge nounwind }
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
