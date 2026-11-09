; ModuleID = 'examples/grover/grover.c'
source_filename = "examples/grover/grover.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @grover(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [16 x i8], align 16
  %4 = add i32 %0, -17
  %5 = icmp ult i32 %4, -16
  br i1 %5, label %109, label %6

6:                                                ; preds = %2
  %7 = shl nuw nsw i32 1, %0
  %8 = icmp ugt i32 %7, %1
  br i1 %8, label %9, label %109

9:                                                ; preds = %6
  %10 = uitofp nneg i32 %7 to double
  %11 = tail call double @llvm.sqrt.f64(double %10)
  %12 = fmul double %11, 0x3FE921FB54442D18
  %13 = tail call double @llvm.floor.f64(double %12)
  %14 = fptosi double %13 to i32
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  %15 = icmp sgt i32 %0, 0
  br i1 %15, label %16, label %27

16:                                               ; preds = %9
  %17 = zext nneg i32 %0 to i64
  br label %18

18:                                               ; preds = %18, %16
  %19 = phi i64 [ 0, %16 ], [ %25, %18 ]
  %20 = getelementptr inbounds i8, ptr %3, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef 0x3FF921FB54442D18) #7
  %24 = zext i1 %23 to i8
  store i8 %24, ptr %20, align 1, !tbaa !6
  %25 = add nuw nsw i64 %19, 1
  %26 = icmp eq i64 %25, %17
  br i1 %26, label %27, label %18, !llvm.loop !12

27:                                               ; preds = %18, %9
  %28 = icmp sgt i32 %14, 0
  br i1 %28, label %29, label %34

29:                                               ; preds = %27
  %30 = zext nneg i32 %0 to i64
  %31 = zext nneg i32 %0 to i64
  %32 = zext nneg i32 %0 to i64
  %33 = zext nneg i32 %0 to i64
  br label %38

34:                                               ; preds = %91, %27
  %35 = icmp sgt i32 %0, 0
  br i1 %35, label %36, label %94

36:                                               ; preds = %34
  %37 = zext nneg i32 %0 to i64
  br label %96

38:                                               ; preds = %29, %91
  %39 = phi i32 [ 0, %29 ], [ %92, %91 ]
  br i1 %15, label %40, label %51

40:                                               ; preds = %38, %40
  %41 = phi i64 [ %49, %40 ], [ 0, %38 ]
  %42 = phi i32 [ %48, %40 ], [ 0, %38 ]
  %43 = getelementptr inbounds i8, ptr %3, i64 %41
  %44 = load i8, ptr %43, align 1, !tbaa !6, !range !10, !noundef !11
  %45 = zext nneg i8 %44 to i32
  %46 = trunc nuw nsw i64 %41 to i32
  %47 = shl nuw nsw i32 %45, %46
  %48 = or i32 %47, %42
  %49 = add nuw nsw i64 %41, 1
  %50 = icmp eq i64 %49, %30
  br i1 %50, label %51, label %40, !llvm.loop !15

51:                                               ; preds = %40, %38
  %52 = phi i32 [ 0, %38 ], [ %48, %40 ]
  %53 = icmp eq i32 %52, %1
  br i1 %53, label %54, label %55

54:                                               ; preds = %51
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #6
  br label %55

55:                                               ; preds = %51, %54
  tail call void @__cq_invert_begin() #8
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !16
  br i1 %15, label %56, label %65

56:                                               ; preds = %55, %56
  %57 = phi i64 [ %63, %56 ], [ 0, %55 ]
  %58 = getelementptr inbounds i8, ptr %3, i64 %57
  %59 = load i8, ptr %58, align 1, !tbaa !6, !range !10, !noundef !11
  %60 = trunc nuw i8 %59 to i1
  %61 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %60, double noundef 0x3FF921FB54442D18) #7
  %62 = zext i1 %61 to i8
  store i8 %62, ptr %58, align 1, !tbaa !6
  %63 = add nuw nsw i64 %57, 1
  %64 = icmp eq i64 %63, %31
  br i1 %64, label %65, label %56, !llvm.loop !12

65:                                               ; preds = %56, %55
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !17
  tail call void @__cq_invert_end() #8
  br i1 %15, label %66, label %77

66:                                               ; preds = %65, %66
  %67 = phi i64 [ %75, %66 ], [ 0, %65 ]
  %68 = phi i32 [ %74, %66 ], [ 0, %65 ]
  %69 = getelementptr inbounds i8, ptr %3, i64 %67
  %70 = load i8, ptr %69, align 1, !tbaa !6, !range !10, !noundef !11
  %71 = zext nneg i8 %70 to i32
  %72 = trunc nuw nsw i64 %67 to i32
  %73 = shl nuw nsw i32 %71, %72
  %74 = or i32 %73, %68
  %75 = add nuw nsw i64 %67, 1
  %76 = icmp eq i64 %75, %32
  br i1 %76, label %77, label %66, !llvm.loop !15

77:                                               ; preds = %66, %65
  %78 = phi i32 [ 0, %65 ], [ %74, %66 ]
  %79 = icmp eq i32 %78, 0
  br i1 %79, label %81, label %80

80:                                               ; preds = %77
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #6
  br label %81

81:                                               ; preds = %80, %77
  br i1 %15, label %82, label %91

82:                                               ; preds = %81, %82
  %83 = phi i64 [ %89, %82 ], [ 0, %81 ]
  %84 = getelementptr inbounds i8, ptr %3, i64 %83
  %85 = load i8, ptr %84, align 1, !tbaa !6, !range !10, !noundef !11
  %86 = trunc nuw i8 %85 to i1
  %87 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %86, double noundef 0x3FF921FB54442D18) #7
  %88 = zext i1 %87 to i8
  store i8 %88, ptr %84, align 1, !tbaa !6
  %89 = add nuw nsw i64 %83, 1
  %90 = icmp eq i64 %89, %33
  br i1 %90, label %91, label %82, !llvm.loop !12

91:                                               ; preds = %82, %81
  %92 = add nuw nsw i32 %39, 1
  %93 = icmp eq i32 %92, %14
  br i1 %93, label %34, label %38, !llvm.loop !18

94:                                               ; preds = %96, %34
  %95 = phi i32 [ 0, %34 ], [ %106, %96 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #6
  br label %109

96:                                               ; preds = %36, %96
  %97 = phi i64 [ 0, %36 ], [ %107, %96 ]
  %98 = phi i32 [ 0, %36 ], [ %106, %96 ]
  %99 = getelementptr inbounds [16 x i8], ptr %3, i64 0, i64 %97
  %100 = load i8, ptr %99, align 1, !tbaa !6, !range !10, !noundef !11
  %101 = trunc nuw i8 %100 to i1
  %102 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %101) #6
  %103 = zext i1 %102 to i32
  %104 = trunc nuw nsw i64 %97 to i32
  %105 = shl nuw nsw i32 %103, %104
  %106 = or i32 %105, %98
  %107 = add nuw nsw i64 %97, 1
  %108 = icmp eq i64 %107, %37
  br i1 %108, label %94, label %96, !llvm.loop !19

109:                                              ; preds = %2, %6, %94
  %110 = phi i32 [ %95, %94 ], [ -1, %6 ], [ -1, %2 ]
  ret i32 %110
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare void @cq_phi(double noundef) local_unnamed_addr #4

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #5

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define i32 @grover_3() local_unnamed_addr #0 {
  %1 = tail call i32 @grover(i32 noundef 3, i32 noundef 5)
  ret i32 %1
}

; Function Attrs: nounwind ssp uwtable
define i32 @grover_4() local_unnamed_addr #0 {
  %1 = tail call i32 @grover(i32 noundef 4, i32 noundef 11)
  ret i32 %1
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }
attributes #8 = { noduplicate nounwind }

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
!16 = !{i64 2148328530}
!17 = !{i64 2148328586}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
