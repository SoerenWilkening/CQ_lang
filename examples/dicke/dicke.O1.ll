; ModuleID = 'examples/dicke/dicke.c'
source_filename = "examples/dicke/dicke.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @dicke(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [31 x i8], align 16
  %4 = add i32 %0, -32
  %5 = icmp ult i32 %4, -31
  %6 = icmp slt i32 %1, 0
  %7 = or i1 %5, %6
  %8 = icmp sgt i32 %1, %0
  %9 = or i1 %8, %7
  br i1 %9, label %114, label %10

10:                                               ; preds = %2
  call void @llvm.lifetime.start.p0(i64 31, ptr nonnull %3) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(31) %3, i8 0, i64 31, i1 false)
  %11 = icmp sgt i32 %1, 0
  br i1 %11, label %12, label %24

12:                                               ; preds = %10
  %13 = sub nsw i32 %0, %1
  %14 = sext i32 %13 to i64
  %15 = getelementptr i8, ptr %3, i64 %14
  %16 = add nuw nsw i32 %0, 1
  %17 = sub nsw i32 %16, %1
  %18 = tail call i32 @llvm.smax.i32(i32 %0, i32 %17)
  %19 = add nuw i32 %18, %1
  %20 = xor i32 %0, -1
  %21 = add i32 %19, %20
  %22 = zext i32 %21 to i64
  %23 = add nuw nsw i64 %22, 1
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(1) %15, i8 1, i64 %23, i1 false), !tbaa !6
  br label %24

24:                                               ; preds = %12, %10
  %25 = getelementptr i8, ptr %3, i64 -2
  %26 = icmp sgt i32 %0, 1
  br i1 %26, label %27, label %29

27:                                               ; preds = %24
  %28 = zext nneg i32 %0 to i64
  br label %33

29:                                               ; preds = %97, %24
  %30 = icmp sgt i32 %0, 0
  br i1 %30, label %31, label %99

31:                                               ; preds = %29
  %32 = zext nneg i32 %0 to i64
  br label %101

33:                                               ; preds = %27, %97
  %34 = phi i64 [ %28, %27 ], [ %35, %97 ]
  %35 = add nsw i64 %34, -1
  %36 = trunc nuw nsw i64 %35 to i32
  %37 = tail call i32 @llvm.smin.i32(i32 %36, i32 %1)
  %38 = getelementptr i8, ptr %25, i64 %34
  %39 = load i8, ptr %38, align 1, !tbaa !6, !range !10, !noundef !11
  %40 = getelementptr inbounds i8, ptr %3, i64 %35
  %41 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %42 = icmp ne i8 %41, %39
  %43 = zext i1 %42 to i8
  store i8 %43, ptr %40, align 1, !tbaa !6
  br i1 %42, label %44, label %55

44:                                               ; preds = %33
  %45 = load i8, ptr %38, align 1, !tbaa !6, !range !10, !noundef !11
  %46 = trunc nuw i8 %45 to i1
  %47 = trunc nuw nsw i64 %34 to i32
  %48 = uitofp nneg i32 %47 to double
  %49 = fdiv double 1.000000e+00, %48
  %50 = tail call double @llvm.sqrt.f64(double %49)
  %51 = tail call double @llvm.acos.f64(double %50)
  %52 = fmul double %51, 2.000000e+00
  %53 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %46, double noundef %52) #7
  %54 = zext i1 %53 to i8
  store i8 %54, ptr %38, align 1, !tbaa !6
  br label %55

55:                                               ; preds = %44, %33
  %56 = load i8, ptr %38, align 1, !tbaa !6, !range !10, !noundef !11
  %57 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %58 = icmp ne i8 %57, %56
  %59 = zext i1 %58 to i8
  store i8 %59, ptr %40, align 1, !tbaa !6
  %60 = icmp slt i32 %37, 2
  br i1 %60, label %97, label %61

61:                                               ; preds = %55
  %62 = trunc nuw nsw i64 %34 to i32
  %63 = uitofp nneg i32 %62 to double
  %64 = add nuw i32 %37, 1
  %65 = zext i32 %64 to i64
  br label %66

66:                                               ; preds = %90, %61
  %67 = phi i64 [ 2, %61 ], [ %95, %90 ]
  %68 = sub nsw i64 %35, %67
  %69 = getelementptr inbounds i8, ptr %3, i64 %68
  %70 = load i8, ptr %69, align 1, !tbaa !6, !range !10, !noundef !11
  %71 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %72 = icmp ne i8 %71, %70
  %73 = zext i1 %72 to i8
  store i8 %73, ptr %40, align 1, !tbaa !6
  br i1 %72, label %74, label %90

74:                                               ; preds = %66
  %75 = sub nsw i64 %34, %67
  %76 = getelementptr inbounds i8, ptr %3, i64 %75
  %77 = load i8, ptr %76, align 1, !tbaa !6, !range !10, !noundef !11
  %78 = trunc nuw i8 %77 to i1
  br i1 %78, label %79, label %90

79:                                               ; preds = %74
  %80 = load i8, ptr %69, align 1, !tbaa !6, !range !10, !noundef !11
  %81 = trunc nuw i8 %80 to i1
  %82 = trunc nuw nsw i64 %67 to i32
  %83 = uitofp nneg i32 %82 to double
  %84 = fdiv double %83, %63
  %85 = tail call double @llvm.sqrt.f64(double %84)
  %86 = tail call double @llvm.acos.f64(double %85)
  %87 = fmul double %86, 2.000000e+00
  %88 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %81, double noundef %87) #7
  %89 = zext i1 %88 to i8
  store i8 %89, ptr %69, align 1, !tbaa !6
  br label %90

90:                                               ; preds = %79, %74, %66
  %91 = load i8, ptr %69, align 1, !tbaa !6, !range !10, !noundef !11
  %92 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %93 = icmp ne i8 %92, %91
  %94 = zext i1 %93 to i8
  store i8 %94, ptr %40, align 1, !tbaa !6
  %95 = add nuw nsw i64 %67, 1
  %96 = icmp eq i64 %95, %65
  br i1 %96, label %97, label %66, !llvm.loop !12

97:                                               ; preds = %90, %55
  %98 = icmp sgt i64 %34, 2
  br i1 %98, label %33, label %29, !llvm.loop !15

99:                                               ; preds = %101, %29
  %100 = phi i32 [ 0, %29 ], [ %111, %101 ]
  call void @llvm.lifetime.end.p0(i64 31, ptr nonnull %3) #6
  br label %114

101:                                              ; preds = %31, %101
  %102 = phi i64 [ 0, %31 ], [ %112, %101 ]
  %103 = phi i32 [ 0, %31 ], [ %111, %101 ]
  %104 = getelementptr inbounds [31 x i8], ptr %3, i64 0, i64 %102
  %105 = load i8, ptr %104, align 1, !tbaa !6, !range !10, !noundef !11
  %106 = trunc nuw i8 %105 to i1
  %107 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %106) #6
  %108 = zext i1 %107 to i32
  %109 = trunc nuw nsw i64 %102 to i32
  %110 = shl nuw nsw i32 %108, %109
  %111 = or i32 %110, %103
  %112 = add nuw nsw i64 %102, 1
  %113 = icmp eq i64 %112, %32
  br i1 %113, label %99, label %101, !llvm.loop !16

114:                                              ; preds = %2, %99
  %115 = phi i32 [ %100, %99 ], [ -1, %2 ]
  ret i32 %115
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @dicke_3_1() local_unnamed_addr #0 {
  %1 = tail call i32 @dicke(i32 noundef 3, i32 noundef 1)
  ret i32 %1
}

; Function Attrs: nounwind ssp uwtable
define i32 @dicke_3_2() local_unnamed_addr #0 {
  %1 = tail call i32 @dicke(i32 noundef 3, i32 noundef 2)
  ret i32 %1
}

; Function Attrs: nounwind ssp uwtable
define i32 @dicke_4_1() local_unnamed_addr #0 {
  %1 = tail call i32 @dicke(i32 noundef 4, i32 noundef 1)
  ret i32 %1
}

; Function Attrs: nounwind ssp uwtable
define i32 @dicke_4_2() local_unnamed_addr #0 {
  %1 = tail call i32 @dicke(i32 noundef 4, i32 noundef 2)
  ret i32 %1
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.acos.f64(double) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
