; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/softfloat/build/cqsf.O1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define half @cqsf_fdiv_f16(half noundef %0, half noundef %1) local_unnamed_addr #0 {
  %3 = bitcast half %0 to i16
  %4 = bitcast half %1 to i16
  %5 = tail call zeroext i16 @cqsfi_fdiv_f16(i16 noundef zeroext %3, i16 noundef zeroext %4) #3
  %6 = bitcast i16 %5 to half
  ret half %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal zeroext i16 @cqsfi_fdiv_f16(i16 noundef zeroext %0, i16 noundef zeroext %1) local_unnamed_addr #2 {
  %3 = lshr i16 %0, 10
  %4 = trunc nuw nsw i16 %3 to i8
  %5 = and i8 %4, 31
  %6 = and i16 %0, 1023
  %7 = lshr i16 %1, 10
  %8 = trunc nuw nsw i16 %7 to i8
  %9 = and i8 %8, 31
  %10 = and i16 %1, 1023
  %11 = xor i16 %1, %0
  %12 = icmp eq i8 %5, 31
  br i1 %12, label %13, label %19

13:                                               ; preds = %2
  %14 = icmp eq i16 %6, 0
  br i1 %14, label %15, label %123

15:                                               ; preds = %13
  %16 = icmp eq i8 %9, 31
  br i1 %16, label %17, label %140

17:                                               ; preds = %15
  %18 = icmp eq i16 %10, 0
  br i1 %18, label %145, label %123

19:                                               ; preds = %2
  switch i8 %9, label %37 [
    i8 31, label %20
    i8 0, label %22
  ]

20:                                               ; preds = %19
  %21 = icmp eq i16 %10, 0
  br i1 %21, label %143, label %123

22:                                               ; preds = %19
  %23 = icmp eq i16 %10, 0
  br i1 %23, label %24, label %28

24:                                               ; preds = %22
  %25 = and i16 %3, 31
  %26 = or i16 %25, %6
  %27 = icmp eq i16 %26, 0
  br i1 %27, label %145, label %140

28:                                               ; preds = %22
  %29 = zext nneg i16 %10 to i32
  %30 = tail call range(i32 16, 33) i32 @llvm.ctlz.i32(i32 %29, i1 true)
  %31 = add nuw nsw i32 %30, 235
  %32 = and i32 %31, 255
  %33 = shl nuw nsw i32 %29, %32
  %34 = trunc nuw nsw i32 %30 to i8
  %35 = sub nsw i8 22, %34
  %36 = trunc i32 %33 to i16
  br label %37

37:                                               ; preds = %28, %19
  %38 = phi i16 [ %36, %28 ], [ %10, %19 ]
  %39 = phi i8 [ %35, %28 ], [ %9, %19 ]
  %40 = icmp eq i8 %5, 0
  br i1 %40, label %41, label %52

41:                                               ; preds = %37
  %42 = icmp eq i16 %6, 0
  br i1 %42, label %143, label %43

43:                                               ; preds = %41
  %44 = zext nneg i16 %6 to i32
  %45 = tail call range(i32 16, 33) i32 @llvm.ctlz.i32(i32 %44, i1 true)
  %46 = add nuw nsw i32 %45, 235
  %47 = and i32 %46, 255
  %48 = shl nuw nsw i32 %44, %47
  %49 = trunc nuw nsw i32 %45 to i8
  %50 = sub nsw i8 22, %49
  %51 = trunc i32 %48 to i16
  br label %52

52:                                               ; preds = %43, %37
  %53 = phi i16 [ %6, %37 ], [ %51, %43 ]
  %54 = phi i8 [ %5, %37 ], [ %50, %43 ]
  %55 = sub nsw i8 %54, %39
  %56 = or i16 %53, 1024
  %57 = or i16 %38, 1024
  %58 = zext i16 %56 to i32
  %59 = zext i16 %57 to i32
  %60 = icmp ult i16 %56, %57
  %61 = select i1 %60, i8 13, i8 14
  %62 = add nsw i8 %61, %55
  %63 = select i1 %60, i32 15, i32 14
  %64 = shl nuw nsw i32 %58, %63
  %65 = udiv i32 %64, %59
  %66 = and i32 %65, 7
  %67 = icmp eq i32 %66, 0
  br i1 %67, label %68, label %74

68:                                               ; preds = %52
  %69 = and i32 %65, 65528
  %70 = mul nuw i32 %69, %59
  %71 = icmp ne i32 %70, %64
  %72 = zext i1 %71 to i32
  %73 = or disjoint i32 %65, %72
  br label %74

74:                                               ; preds = %68, %52
  %75 = phi i32 [ %65, %52 ], [ %73, %68 ]
  %76 = sext i8 %62 to i16
  %77 = and i32 %75, 65535
  %78 = icmp ugt i8 %62, 28
  br i1 %78, label %79, label %103

79:                                               ; preds = %74
  %80 = icmp slt i8 %62, 0
  br i1 %80, label %81, label %96

81:                                               ; preds = %79
  %82 = sub nsw i16 0, %76
  %83 = icmp ult i16 %82, 31
  br i1 %83, label %84, label %93

84:                                               ; preds = %81
  %85 = zext nneg i16 %82 to i32
  %86 = lshr i32 %77, %85
  %87 = sub nsw i32 0, %85
  %88 = and i32 %87, 31
  %89 = shl i32 %77, %88
  %90 = icmp ne i32 %89, 0
  %91 = zext i1 %90 to i32
  %92 = or i32 %86, %91
  br label %103

93:                                               ; preds = %81
  %94 = icmp ne i32 %77, 0
  %95 = zext i1 %94 to i32
  br label %103

96:                                               ; preds = %79
  %97 = icmp sgt i8 %62, 29
  %98 = icmp ugt i32 %77, 32759
  %99 = select i1 %97, i1 true, i1 %98
  br i1 %99, label %100, label %103

100:                                              ; preds = %96
  %101 = and i16 %11, -32768
  %102 = or disjoint i16 %101, 31744
  br label %145

103:                                              ; preds = %96, %93, %84, %74
  %104 = phi i32 [ %75, %74 ], [ %75, %96 ], [ %92, %84 ], [ %95, %93 ]
  %105 = phi i16 [ %76, %74 ], [ %76, %96 ], [ 0, %84 ], [ 0, %93 ]
  %106 = and i32 %104, 65528
  %107 = add nuw nsw i32 %106, 8
  %108 = lshr i32 %107, 4
  %109 = and i32 %104, 15
  %110 = icmp eq i32 %109, 8
  %111 = zext i1 %110 to i32
  %112 = xor i32 %111, -1
  %113 = and i32 %108, %112
  %114 = icmp eq i32 %113, 0
  %115 = zext i16 %105 to i32
  %116 = and i16 %11, -32768
  %117 = zext i16 %116 to i32
  %118 = shl nuw nsw i32 %115, 10
  %119 = select i1 %114, i32 0, i32 %118
  %120 = or disjoint i32 %113, %117
  %121 = add nuw nsw i32 %120, %119
  %122 = trunc i32 %121 to i16
  br label %145

123:                                              ; preds = %20, %17, %13
  %124 = zext i16 %0 to i32
  %125 = and i32 %124, 32256
  %126 = icmp eq i32 %125, 31744
  %127 = and i32 %124, 511
  %128 = icmp ne i32 %127, 0
  %129 = and i1 %126, %128
  br i1 %129, label %137, label %130

130:                                              ; preds = %123
  %131 = and i32 %124, 31744
  %132 = icmp ne i32 %131, 31744
  %133 = and i32 %124, 1023
  %134 = icmp eq i32 %133, 0
  %135 = or i1 %132, %134
  %136 = select i1 %135, i16 %1, i16 %0
  br label %137

137:                                              ; preds = %130, %123
  %138 = phi i16 [ %136, %130 ], [ %0, %123 ]
  %139 = or i16 %138, 512
  br label %145

140:                                              ; preds = %24, %15
  %141 = and i16 %11, -32768
  %142 = or disjoint i16 %141, 31744
  br label %145

143:                                              ; preds = %41, %20
  %144 = and i16 %11, -32768
  br label %145

145:                                              ; preds = %143, %140, %137, %103, %100, %24, %17
  %146 = phi i16 [ %139, %137 ], [ %142, %140 ], [ %144, %143 ], [ %122, %103 ], [ %102, %100 ], [ -512, %24 ], [ -512, %17 ]
  ret i16 %146
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
