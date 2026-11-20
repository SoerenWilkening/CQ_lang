; ModuleID = 'gmp/build/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.abs.i64(i64, i1 immarg) #0

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable
define range(i32 0, 2) i32 @__gmpz_congruent_2exp_p(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1, i64 noundef %2) local_unnamed_addr #1 {
  %4 = getelementptr inbounds i8, ptr %0, i64 4
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = sext i32 %5 to i64
  %7 = tail call i64 @llvm.abs.i64(i64 %6, i1 true)
  %8 = getelementptr inbounds i8, ptr %1, i64 4
  %9 = load i32, ptr %8, align 4, !tbaa !5
  %10 = sext i32 %9 to i64
  %11 = tail call i64 @llvm.abs.i64(i64 %10, i1 true)
  %12 = icmp ult i64 %7, %11
  br i1 %12, label %13, label %14

13:                                               ; preds = %3
  br label %14

14:                                               ; preds = %13, %3
  %15 = phi ptr [ %0, %13 ], [ %1, %3 ]
  %16 = phi i64 [ %11, %13 ], [ %7, %3 ]
  %17 = phi i64 [ %7, %13 ], [ %11, %3 ]
  %18 = phi ptr [ %1, %13 ], [ %0, %3 ]
  %19 = lshr i64 %2, 6
  %20 = and i64 %2, 63
  %21 = shl nsw i64 -1, %20
  %22 = xor i64 %21, -1
  %23 = getelementptr inbounds i8, ptr %18, i64 8
  %24 = load ptr, ptr %23, align 8, !tbaa !11
  %25 = getelementptr inbounds i8, ptr %15, i64 8
  %26 = load ptr, ptr %25, align 8, !tbaa !11
  %27 = icmp eq i64 %17, 0
  br i1 %27, label %54, label %28

28:                                               ; preds = %14
  %29 = xor i64 %10, %6
  %30 = icmp sgt i64 %29, -1
  br i1 %30, label %31, label %73

31:                                               ; preds = %28
  %32 = tail call i64 @llvm.umin.i64(i64 %17, i64 %19)
  br label %33

33:                                               ; preds = %36, %31
  %34 = phi i64 [ %32, %31 ], [ %37, %36 ]
  %35 = icmp slt i64 %34, 1
  br i1 %35, label %44, label %36

36:                                               ; preds = %33
  %37 = add nsw i64 %34, -1
  %38 = getelementptr inbounds i64, ptr %24, i64 %37
  %39 = load i64, ptr %38, align 8, !tbaa !12
  %40 = getelementptr inbounds i64, ptr %26, i64 %37
  %41 = load i64, ptr %40, align 8, !tbaa !12
  %42 = icmp eq i64 %39, %41
  br i1 %42, label %33, label %43, !llvm.loop !14

43:                                               ; preds = %36
  br i1 %35, label %44, label %130

44:                                               ; preds = %43, %33
  %45 = icmp ugt i64 %17, %19
  br i1 %45, label %46, label %54

46:                                               ; preds = %44
  %47 = getelementptr inbounds i64, ptr %24, i64 %19
  %48 = load i64, ptr %47, align 8, !tbaa !12
  %49 = getelementptr inbounds i64, ptr %26, i64 %19
  %50 = load i64, ptr %49, align 8, !tbaa !12
  %51 = sub i64 %48, %50
  %52 = and i64 %51, %22
  %53 = icmp eq i64 %52, 0
  br label %130

54:                                               ; preds = %44, %14
  %55 = icmp ugt i64 %16, %19
  br i1 %55, label %56, label %58

56:                                               ; preds = %54
  %57 = icmp ult i64 %17, %19
  br i1 %57, label %63, label %68

58:                                               ; preds = %54
  %59 = icmp eq i64 %11, %7
  br label %130

60:                                               ; preds = %63
  %61 = add nuw nsw i64 %64, 1
  %62 = icmp eq i64 %61, %19
  br i1 %62, label %68, label %63, !llvm.loop !17

63:                                               ; preds = %60, %56
  %64 = phi i64 [ %61, %60 ], [ %17, %56 ]
  %65 = getelementptr inbounds i64, ptr %24, i64 %64
  %66 = load i64, ptr %65, align 8, !tbaa !12
  %67 = icmp eq i64 %66, 0
  br i1 %67, label %60, label %130

68:                                               ; preds = %60, %56
  %69 = getelementptr inbounds i64, ptr %24, i64 %19
  %70 = load i64, ptr %69, align 8, !tbaa !12
  %71 = and i64 %70, %22
  %72 = icmp eq i64 %71, 0
  br label %130

73:                                               ; preds = %86, %28
  %74 = phi i64 [ %87, %86 ], [ 0, %28 ]
  %75 = getelementptr inbounds i64, ptr %24, i64 %74
  %76 = load i64, ptr %75, align 8, !tbaa !12
  %77 = getelementptr inbounds i64, ptr %26, i64 %74
  %78 = load i64, ptr %77, align 8, !tbaa !12
  %79 = add i64 %78, %76
  %80 = icmp eq i64 %74, %19
  br i1 %80, label %81, label %84

81:                                               ; preds = %73
  %82 = and i64 %79, %22
  %83 = icmp eq i64 %82, 0
  br label %130

84:                                               ; preds = %73
  %85 = icmp eq i64 %79, 0
  br i1 %85, label %86, label %130

86:                                               ; preds = %84
  %87 = add nuw nsw i64 %74, 1
  %88 = icmp eq i64 %76, 0
  br i1 %88, label %73, label %89, !llvm.loop !18

89:                                               ; preds = %86
  %90 = icmp ult i64 %87, %17
  br i1 %90, label %91, label %107

91:                                               ; preds = %104, %89
  %92 = phi i64 [ %105, %104 ], [ %87, %89 ]
  %93 = getelementptr inbounds i64, ptr %24, i64 %92
  %94 = load i64, ptr %93, align 8, !tbaa !12
  %95 = getelementptr inbounds i64, ptr %26, i64 %92
  %96 = load i64, ptr %95, align 8, !tbaa !12
  %97 = xor i64 %96, %94
  %98 = icmp ult i64 %92, %19
  br i1 %98, label %102, label %99

99:                                               ; preds = %91
  %100 = or i64 %97, %21
  %101 = icmp eq i64 %100, -1
  br label %130

102:                                              ; preds = %91
  %103 = icmp eq i64 %97, -1
  br i1 %103, label %104, label %130

104:                                              ; preds = %102
  %105 = add nuw nsw i64 %92, 1
  %106 = icmp ult i64 %105, %17
  br i1 %106, label %91, label %107, !llvm.loop !19

107:                                              ; preds = %104, %89
  %108 = phi i64 [ %87, %89 ], [ %17, %104 ]
  %109 = icmp ult i64 %16, %19
  br i1 %109, label %130, label %110

110:                                              ; preds = %107
  %111 = icmp ult i64 %108, %19
  br i1 %111, label %115, label %120

112:                                              ; preds = %115
  %113 = add nuw nsw i64 %116, 1
  %114 = icmp ult i64 %113, %19
  br i1 %114, label %115, label %120, !llvm.loop !20

115:                                              ; preds = %112, %110
  %116 = phi i64 [ %113, %112 ], [ %108, %110 ]
  %117 = getelementptr inbounds i64, ptr %24, i64 %116
  %118 = load i64, ptr %117, align 8, !tbaa !12
  %119 = icmp eq i64 %118, -1
  br i1 %119, label %112, label %130

120:                                              ; preds = %112, %110
  %121 = icmp eq i64 %20, 0
  br i1 %121, label %130, label %122

122:                                              ; preds = %120
  %123 = icmp eq i64 %16, %19
  br i1 %123, label %130, label %124

124:                                              ; preds = %122
  %125 = getelementptr inbounds i64, ptr %24, i64 %19
  %126 = load i64, ptr %125, align 8, !tbaa !12
  %127 = sub i64 9223372036854775806, %126
  %128 = or i64 %127, %21
  %129 = icmp eq i64 %128, -1
  br label %130

130:                                              ; preds = %124, %122, %120, %115, %107, %102, %99, %84, %81, %68, %63, %58, %46, %43
  %131 = phi i1 [ %59, %58 ], [ %72, %68 ], [ %53, %46 ], [ %83, %81 ], [ %101, %99 ], [ %129, %124 ], [ false, %43 ], [ false, %107 ], [ true, %120 ], [ false, %122 ], [ false, %63 ], [ false, %115 ], [ false, %102 ], [ false, %84 ]
  %132 = zext i1 %131 to i32
  ret i32 %132
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #1 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{!6, !7, i64 4}
!6 = !{!"", !7, i64 0, !7, i64 4, !10, i64 8}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!"any pointer", !8, i64 0}
!11 = !{!6, !10, i64 8}
!12 = !{!13, !13, i64 0}
!13 = !{!"long", !8, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
!17 = distinct !{!17, !15, !16}
!18 = distinct !{!18, !15, !16}
!19 = distinct !{!19, !15, !16}
!20 = distinct !{!20, !15, !16}
