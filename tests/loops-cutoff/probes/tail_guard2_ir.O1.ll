; tests/loops-cutoff probe (CR rules 9, 14): stpcpy's word loop in the alignment loop's tail, with TWO pre-header guards, each with a quantum
; skip into the byte copy carrying its OWN pointers (the second one byte on). clang -O1 output of a stpcpy variant, the guards split by hand since
; -O1 merges them. The first guard's edge lies off the header's paths and off the second guard's, and must still read as an incoming.
; ModuleID = 'tail_guard2.c'
source_filename = "tail_guard2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [12 x i8] c"12.5e3 Ab,x\00", align 1

; Function Attrs: nounwind ssp uwtable
define range(i32 -128, 128) i32 @tg2_dst(i8 noundef signext %0, i8 noundef signext %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [64 x i8], align 16
  %5 = alloca [64 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %4) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %4, i8 0, i64 64, i1 false)
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %5) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %5, i8 0, i64 64, i1 false)
  %6 = getelementptr inbounds i8, ptr %5, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(11) %6, ptr noundef nonnull align 1 dereferenceable(11) @.str, i64 11, i1 false), !tbaa !6
  store i8 %0, ptr %4, align 16, !tbaa !6
  store i8 %1, ptr %5, align 16, !tbaa !6
  %7 = tail call signext i8 @cq_theta_c(i8 noundef signext %1, double noundef 3.000000e-01) #7
  store i8 %7, ptr %5, align 16, !tbaa !6
  call fastcc void @tg_copy(ptr noundef nonnull %4, ptr noundef nonnull %5)
  %8 = load i8, ptr %4, align 16, !tbaa !6
  %9 = call signext i8 @cq_measure_c(i8 noundef signext %8) #6
  %10 = sext i8 %9 to i32
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %4) #6
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #3

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define internal fastcc void @tg_copy(ptr noundef %0, ptr noundef %1) unnamed_addr #4 {
  %3 = ptrtoint ptr %1 to i64
  %4 = ptrtoint ptr %0 to i64
  %5 = xor i64 %3, %4
  %6 = and i64 %5, 7
  %7 = icmp eq i64 %6, 0
  br i1 %7, label %8, label %45

8:                                                ; preds = %2
  %9 = ptrtoint ptr %1 to i64
  %10 = and i64 %9, 7
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %23, label %12

12:                                               ; preds = %8, %17
  %13 = phi ptr [ %18, %17 ], [ %1, %8 ]
  %14 = phi ptr [ %19, %17 ], [ %0, %8 ]
  %15 = load i8, ptr %13, align 1, !tbaa !6
  store i8 %15, ptr %14, align 1, !tbaa !6
  %16 = icmp eq i8 %15, 0
  br i1 %16, label %57, label %17

17:                                               ; preds = %12
  %18 = getelementptr inbounds i8, ptr %13, i64 1
  %19 = getelementptr inbounds i8, ptr %14, i64 1
  %20 = ptrtoint ptr %18 to i64
  %21 = and i64 %20, 7
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %23, label %12, !llvm.loop !9

23:                                               ; preds = %17, %8
  %24 = phi ptr [ %0, %8 ], [ %19, %17 ]
  %25 = phi ptr [ %1, %8 ], [ %18, %17 ]
  %26 = load i64, ptr %25, align 8, !tbaa !12
  %27 = sub i64 72340172838076672, %26
  %28 = or i64 %27, %26
  %29 = and i64 %28, -9187201950435737472
  %30 = icmp ne i64 %29, -9187201950435737472
  %31 = and i64 %26, 255
  %32 = icmp eq i64 %31, 113
  %33 = or i1 %32, %30
  br i1 %30, label %45, label %g2

g2:
  %gd = getelementptr inbounds i8, ptr %24, i64 1
  %gs = getelementptr inbounds i8, ptr %25, i64 1
  br i1 %32, label %45, label %34

34:                                               ; preds = %g2, %34
  %35 = phi ptr [ %39, %34 ], [ %24, %g2 ]
  %36 = phi ptr [ %37, %34 ], [ %25, %g2 ]
  %37 = getelementptr inbounds i8, ptr %36, i64 8
  %38 = load i64, ptr %36, align 8, !tbaa !12
  %39 = getelementptr inbounds i8, ptr %35, i64 8
  store i64 %38, ptr %35, align 8, !tbaa !12
  %40 = load i64, ptr %37, align 8, !tbaa !12
  %41 = sub i64 72340172838076672, %40
  %42 = or i64 %41, %40
  %43 = and i64 %42, -9187201950435737472
  %44 = icmp eq i64 %43, -9187201950435737472
  br i1 %44, label %34, label %45, !llvm.loop !14

45:                                               ; preds = %34, %23, %2
  %46 = phi ptr [ %0, %2 ], [ %24, %23 ], [ %gd, %g2 ], [ %39, %34 ]
  %47 = phi ptr [ %1, %2 ], [ %25, %23 ], [ %gs, %g2 ], [ %37, %34 ]
  %48 = load i8, ptr %47, align 1, !tbaa !6
  store i8 %48, ptr %46, align 1, !tbaa !6
  %49 = icmp eq i8 %48, 0
  br i1 %49, label %57, label %50

50:                                               ; preds = %45, %50
  %51 = phi ptr [ %53, %50 ], [ %47, %45 ]
  %52 = phi ptr [ %54, %50 ], [ %46, %45 ]
  %53 = getelementptr inbounds i8, ptr %51, i64 1
  %54 = getelementptr inbounds i8, ptr %52, i64 1
  %55 = load i8, ptr %53, align 1, !tbaa !6
  store i8 %55, ptr %54, align 1, !tbaa !6
  %56 = icmp eq i8 %55, 0
  br i1 %56, label %57, label %50, !llvm.loop !15

57:                                               ; preds = %12, %50, %45
  ret void
}

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = !{!13, !13, i64 0}
!13 = !{!"long", !7, i64 0}
!14 = distinct !{!14, !10, !11}
!15 = distinct !{!15, !10, !11}
