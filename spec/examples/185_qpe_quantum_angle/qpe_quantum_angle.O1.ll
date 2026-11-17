; ModuleID = 'qpe_quantum_angle.c'
source_filename = "qpe_quantum_angle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @qpe_quantum_angle(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = zext i32 %0 to i64
  %5 = alloca i8, i64 %4, align 16
  %6 = zext i32 %1 to i64
  %7 = alloca i8, i64 %6, align 16
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %11

9:                                                ; preds = %3
  %10 = zext nneg i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %5, i8 0, i64 %10, i1 false), !tbaa !6
  br label %11

11:                                               ; preds = %9, %3
  %12 = icmp sgt i32 %1, 0
  br i1 %12, label %13, label %15

13:                                               ; preds = %11
  %14 = zext nneg i32 %1 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %7, i8 0, i64 %14, i1 false), !tbaa !6
  br label %15

15:                                               ; preds = %13, %11
  %16 = icmp sgt i32 %0, 0
  br i1 %16, label %17, label %19

17:                                               ; preds = %15
  %18 = zext nneg i32 %0 to i64
  br label %23

19:                                               ; preds = %23, %15
  %20 = icmp sgt i32 %0, 0
  br i1 %20, label %21, label %36

21:                                               ; preds = %19
  %22 = zext nneg i32 %0 to i64
  br label %41

23:                                               ; preds = %17, %23
  %24 = phi i64 [ 0, %17 ], [ %32, %23 ]
  %25 = getelementptr inbounds i8, ptr %5, i64 %24
  %26 = load i8, ptr %25, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = getelementptr inbounds double, ptr %2, i64 %24
  %29 = load double, ptr %28, align 8, !tbaa !12
  %30 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef %29) #3
  %31 = zext i1 %30 to i8
  store i8 %31, ptr %25, align 1, !tbaa !6
  %32 = add nuw nsw i64 %24, 1
  %33 = icmp eq i64 %32, %18
  br i1 %33, label %19, label %23, !llvm.loop !14

34:                                               ; preds = %41
  %35 = sitofp i32 %49 to double
  br label %36

36:                                               ; preds = %34, %19
  %37 = phi double [ 0.000000e+00, %19 ], [ %35, %34 ]
  %38 = icmp sgt i32 %1, 0
  br i1 %38, label %39, label %52

39:                                               ; preds = %36
  %40 = zext nneg i32 %1 to i64
  br label %60

41:                                               ; preds = %21, %41
  %42 = phi i64 [ 0, %21 ], [ %50, %41 ]
  %43 = phi i32 [ 0, %21 ], [ %49, %41 ]
  %44 = getelementptr inbounds i8, ptr %5, i64 %42
  %45 = load i8, ptr %44, align 1, !tbaa !6, !range !10, !noundef !11
  %46 = zext nneg i8 %45 to i32
  %47 = trunc nuw nsw i64 %42 to i32
  %48 = shl nuw i32 %46, %47
  %49 = or i32 %48, %43
  %50 = add nuw nsw i64 %42, 1
  %51 = icmp eq i64 %50, %22
  br i1 %51, label %34, label %41, !llvm.loop !17

52:                                               ; preds = %60, %36
  %53 = icmp sgt i32 %1, 0
  br i1 %53, label %54, label %69

54:                                               ; preds = %52
  %55 = shl nuw i32 1, %0
  %56 = sitofp i32 %55 to double
  %57 = fdiv double 0x401921FB54442D18, %56
  %58 = fmul double %57, %37
  %59 = zext nneg i32 %1 to i64
  br label %75

60:                                               ; preds = %39, %60
  %61 = phi i64 [ 0, %39 ], [ %67, %60 ]
  %62 = getelementptr inbounds i8, ptr %7, i64 %61
  %63 = load i8, ptr %62, align 1, !tbaa !6, !range !10, !noundef !11
  %64 = trunc nuw i8 %63 to i1
  %65 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %64, double noundef 0x3FF921FB54442D18) #3
  %66 = zext i1 %65 to i8
  store i8 %66, ptr %62, align 1, !tbaa !6
  %67 = add nuw nsw i64 %61, 1
  %68 = icmp eq i64 %67, %40
  br i1 %68, label %52, label %60, !llvm.loop !18

69:                                               ; preds = %85, %52
  %70 = add i32 %1, -1
  %71 = icmp sgt i32 %1, 0
  br i1 %71, label %72, label %94

72:                                               ; preds = %69
  %73 = zext i32 %70 to i64
  %74 = sext i32 %70 to i64
  br label %88

75:                                               ; preds = %54, %85
  %76 = phi i64 [ 0, %54 ], [ %86, %85 ]
  %77 = getelementptr inbounds i8, ptr %7, i64 %76
  %78 = load i8, ptr %77, align 1, !tbaa !6, !range !10, !noundef !11
  %79 = trunc nuw i8 %78 to i1
  br i1 %79, label %80, label %85

80:                                               ; preds = %75
  %81 = trunc nuw nsw i64 %76 to i32
  %82 = shl nuw i32 1, %81
  %83 = sitofp i32 %82 to double
  %84 = fmul double %58, %83
  tail call void @cq_phi(double noundef %84) #4
  br label %85

85:                                               ; preds = %80, %75
  %86 = add nuw nsw i64 %76, 1
  %87 = icmp eq i64 %86, %59
  br i1 %87, label %69, label %75, !llvm.loop !19

88:                                               ; preds = %72, %121
  %89 = phi i64 [ %73, %72 ], [ %124, %121 ]
  %90 = icmp slt i64 %89, %74
  br i1 %90, label %91, label %98

91:                                               ; preds = %88
  %92 = getelementptr inbounds i8, ptr %7, i64 %89
  %93 = trunc nuw nsw i64 %89 to i32
  br label %102

94:                                               ; preds = %121, %69
  %95 = icmp sgt i32 %1, 0
  br i1 %95, label %96, label %126

96:                                               ; preds = %94
  %97 = zext nneg i32 %1 to i64
  br label %131

98:                                               ; preds = %116, %88
  %99 = getelementptr inbounds i8, ptr %7, i64 %89
  %100 = load i8, ptr %99, align 1, !tbaa !6, !range !10, !noundef !11
  %101 = trunc nuw i8 %100 to i1
  br i1 %101, label %120, label %121

102:                                              ; preds = %91, %116
  %103 = phi i32 [ %70, %91 ], [ %117, %116 ]
  %104 = zext nneg i32 %103 to i64
  %105 = getelementptr inbounds i8, ptr %7, i64 %104
  %106 = load i8, ptr %105, align 1, !tbaa !6, !range !10, !noundef !11
  %107 = trunc nuw i8 %106 to i1
  br i1 %107, label %108, label %116

108:                                              ; preds = %102
  %109 = load i8, ptr %92, align 1, !tbaa !6, !range !10, !noundef !11
  %110 = trunc nuw i8 %109 to i1
  br i1 %110, label %111, label %116

111:                                              ; preds = %108
  %112 = sub nsw i32 %103, %93
  %113 = shl nuw i32 1, %112
  %114 = sitofp i32 %113 to double
  %115 = fdiv double 0xC00921FB54442D18, %114
  tail call void @cq_phi(double noundef %115) #4
  br label %116

116:                                              ; preds = %102, %108, %111
  %117 = add nsw i32 %103, -1
  %118 = sext i32 %117 to i64
  %119 = icmp slt i64 %89, %118
  br i1 %119, label %102, label %98, !llvm.loop !20

120:                                              ; preds = %98
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #4
  br label %121

121:                                              ; preds = %120, %98
  %122 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %101, double noundef 0x3FF921FB54442D18) #3
  %123 = zext i1 %122 to i8
  store i8 %123, ptr %99, align 1, !tbaa !6
  %124 = add nsw i64 %89, -1
  %125 = icmp sgt i64 %89, 0
  br i1 %125, label %88, label %94, !llvm.loop !21

126:                                              ; preds = %131, %94
  %127 = phi i32 [ 0, %94 ], [ %142, %131 ]
  %128 = icmp sgt i32 %0, 0
  br i1 %128, label %129, label %145

129:                                              ; preds = %126
  %130 = zext nneg i32 %0 to i64
  br label %147

131:                                              ; preds = %96, %131
  %132 = phi i64 [ 0, %96 ], [ %143, %131 ]
  %133 = phi i32 [ 0, %96 ], [ %142, %131 ]
  %134 = getelementptr inbounds i8, ptr %7, i64 %132
  %135 = load i8, ptr %134, align 1, !tbaa !6, !range !10, !noundef !11
  %136 = trunc nuw i8 %135 to i1
  %137 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %136) #4
  %138 = zext i1 %137 to i32
  %139 = trunc i64 %132 to i32
  %140 = sub i32 %70, %139
  %141 = shl nuw i32 %138, %140
  %142 = or i32 %141, %133
  %143 = add nuw nsw i64 %132, 1
  %144 = icmp eq i64 %143, %97
  br i1 %144, label %126, label %131, !llvm.loop !22

145:                                              ; preds = %147, %126
  %146 = phi i32 [ %127, %126 ], [ %158, %147 ]
  ret i32 %146

147:                                              ; preds = %129, %147
  %148 = phi i64 [ 0, %129 ], [ %159, %147 ]
  %149 = phi i32 [ %127, %129 ], [ %158, %147 ]
  %150 = getelementptr inbounds i8, ptr %5, i64 %148
  %151 = load i8, ptr %150, align 1, !tbaa !6, !range !10, !noundef !11
  %152 = trunc nuw i8 %151 to i1
  %153 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %152) #4
  %154 = zext i1 %153 to i32
  %155 = trunc i64 %148 to i32
  %156 = add i32 %155, %1
  %157 = shl nuw i32 %154, %156
  %158 = or i32 %157, %149
  %159 = add nuw nsw i64 %148, 1
  %160 = icmp eq i64 %159, %130
  br i1 %160, label %145, label %147, !llvm.loop !23
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = !{!13, !13, i64 0}
!13 = !{!"double", !8, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
!17 = distinct !{!17, !15, !16}
!18 = distinct !{!18, !15, !16}
!19 = distinct !{!19, !15, !16}
!20 = distinct !{!20, !15, !16}
!21 = distinct !{!21, !15, !16}
!22 = distinct !{!22, !15, !16}
!23 = distinct !{!23, !15, !16}
