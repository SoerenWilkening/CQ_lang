; ModuleID = 'fibtmp/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.gmp_pi1_t = type { i64 }

@.str.14 = external hidden unnamed_addr constant [4 x i8], align 1
@.str.1.15 = external hidden unnamed_addr constant [5 x i8], align 1
@.str.2.18 = external hidden unnamed_addr constant [29 x i8], align 1
@.str.27 = external hidden unnamed_addr constant [10 x i8], align 1
@.str.1.28 = external hidden unnamed_addr constant [35 x i8], align 1
@.str.2.29 = external hidden unnamed_addr constant [12 x i8], align 1
@mpn_fft_table = external hidden unnamed_addr constant [2 x <{ i64, i64, i64, i64, i64, i64, [10 x i64] }>], align 16
@.str.4.30 = external hidden unnamed_addr constant [10 x i8], align 1
@.str.5 = external hidden unnamed_addr constant [8 x i8], align 1
@.str.6 = external hidden unnamed_addr constant [20 x i8], align 1
@.str.7 = external hidden unnamed_addr constant [12 x i8], align 1
@.str.189 = external hidden unnamed_addr constant [18 x i8], align 1
@.str.1.190 = external hidden unnamed_addr constant [12 x i8], align 1
@.str.269 = external hidden unnamed_addr constant [15 x i8], align 1
@.str.1.270 = external hidden unnamed_addr constant [8 x i8], align 1
@.str.2.271 = external hidden unnamed_addr constant [9 x i8], align 1
@__gmp_binvert_limb_table = external local_unnamed_addr constant [128 x i8], align 16
@.str.304 = external hidden unnamed_addr constant [14 x i8], align 1
@.str.1.305 = external hidden unnamed_addr constant [12 x i8], align 1
@.str.2.306 = external hidden unnamed_addr constant [8 x i8], align 1
@__stderrp = external local_unnamed_addr global ptr, align 8
@__gmp_allocate_func = external local_unnamed_addr global ptr, align 8
@__gmp_free_func = external local_unnamed_addr global ptr, align 8
@__gmpn_clz_tab = external local_unnamed_addr constant [129 x i8], align 16

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nofree nounwind
declare noundef i32 @fprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ...) local_unnamed_addr #3

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define noalias ptr @__gmp_tmp_reentrant_alloc(ptr nocapture noundef %0, i64 noundef %1) local_unnamed_addr #5 {
  %3 = add i64 %1, 16
  %4 = load ptr, ptr @__gmp_allocate_func, align 8, !tbaa !7
  %5 = tail call ptr %4(i64 noundef %3) #16
  %6 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 %3, ptr %6, align 8, !tbaa !11
  %7 = load ptr, ptr %0, align 8, !tbaa !7
  store ptr %7, ptr %5, align 8, !tbaa !14
  store ptr %5, ptr %0, align 8, !tbaa !7
  %8 = getelementptr inbounds i8, ptr %5, i64 16
  ret ptr %8
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_lshift(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #6 {
  %5 = getelementptr inbounds i64, ptr %1, i64 %2
  %6 = getelementptr inbounds i64, ptr %0, i64 %2
  %7 = sub i32 64, %3
  %8 = getelementptr inbounds i8, ptr %5, i64 -8
  %9 = load i64, ptr %8, align 8, !tbaa !15
  %10 = zext i32 %7 to i64
  %11 = zext nneg i32 %3 to i64
  %12 = add nsw i64 %2, -1
  %13 = shl i64 %9, %11
  %14 = icmp eq i64 %12, 0
  br i1 %14, label %28, label %15

15:                                               ; preds = %15, %4
  %16 = phi i64 [ %26, %15 ], [ %13, %4 ]
  %17 = phi i64 [ %25, %15 ], [ %12, %4 ]
  %18 = phi ptr [ %24, %15 ], [ %6, %4 ]
  %19 = phi ptr [ %20, %15 ], [ %8, %4 ]
  %20 = getelementptr inbounds i8, ptr %19, i64 -8
  %21 = load i64, ptr %20, align 8, !tbaa !15
  %22 = lshr i64 %21, %10
  %23 = or i64 %22, %16
  %24 = getelementptr inbounds i8, ptr %18, i64 -8
  store i64 %23, ptr %24, align 8, !tbaa !15
  %25 = add nsw i64 %17, -1
  %26 = shl i64 %21, %11
  %27 = icmp eq i64 %25, 0
  br i1 %27, label %28, label %15, !llvm.loop !16

28:                                               ; preds = %15, %4
  %29 = phi ptr [ %6, %4 ], [ %24, %15 ]
  %30 = phi i64 [ %13, %4 ], [ %26, %15 ]
  %31 = lshr i64 %9, %10
  %32 = getelementptr inbounds i8, ptr %29, i64 -8
  store i64 %30, ptr %32, align 8, !tbaa !15
  ret i64 %31
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define range(i64 0, 2) i64 @__gmpn_add_n(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, ptr nocapture noundef readonly %2, i64 noundef %3) local_unnamed_addr #6 {
  br label %5

5:                                                ; preds = %5, %4
  %6 = phi i64 [ %3, %4 ], [ %22, %5 ]
  %7 = phi ptr [ %2, %4 ], [ %13, %5 ]
  %8 = phi i64 [ 0, %4 ], [ %20, %5 ]
  %9 = phi ptr [ %1, %4 ], [ %11, %5 ]
  %10 = phi ptr [ %0, %4 ], [ %21, %5 ]
  %11 = getelementptr inbounds i8, ptr %9, i64 8
  %12 = load i64, ptr %9, align 8, !tbaa !15
  %13 = getelementptr inbounds i8, ptr %7, i64 8
  %14 = load i64, ptr %7, align 8, !tbaa !15
  %15 = add i64 %14, %12
  %16 = icmp ult i64 %15, %12
  %17 = add i64 %15, %8
  %18 = icmp ult i64 %17, %15
  %19 = or i1 %16, %18
  %20 = zext i1 %19 to i64
  %21 = getelementptr inbounds i8, ptr %10, i64 8
  store i64 %17, ptr %10, align 8, !tbaa !15
  %22 = add nsw i64 %6, -1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %24, label %5, !llvm.loop !19

24:                                               ; preds = %5
  ret i64 %20
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define range(i64 0, 2) i64 @__gmpn_sub_n(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, ptr nocapture noundef readonly %2, i64 noundef %3) local_unnamed_addr #6 {
  br label %5

5:                                                ; preds = %5, %4
  %6 = phi i64 [ %3, %4 ], [ %22, %5 ]
  %7 = phi ptr [ %2, %4 ], [ %13, %5 ]
  %8 = phi i64 [ 0, %4 ], [ %20, %5 ]
  %9 = phi ptr [ %1, %4 ], [ %11, %5 ]
  %10 = phi ptr [ %0, %4 ], [ %21, %5 ]
  %11 = getelementptr inbounds i8, ptr %9, i64 8
  %12 = load i64, ptr %9, align 8, !tbaa !15
  %13 = getelementptr inbounds i8, ptr %7, i64 8
  %14 = load i64, ptr %7, align 8, !tbaa !15
  %15 = sub i64 %12, %14
  %16 = icmp ugt i64 %14, %12
  %17 = sub i64 %15, %8
  %18 = icmp ugt i64 %8, %15
  %19 = or i1 %16, %18
  %20 = zext i1 %19 to i64
  %21 = getelementptr inbounds i8, ptr %10, i64 8
  store i64 %17, ptr %10, align 8, !tbaa !15
  %22 = add nsw i64 %6, -1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %24, label %5, !llvm.loop !20

24:                                               ; preds = %5
  ret i64 %20
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #5 {
  %6 = alloca [30 x i64], align 16
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = icmp sgt i64 %2, 29
  br i1 %11, label %13, label %12

12:                                               ; preds = %5
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) #16
  br label %480

13:                                               ; preds = %5
  %14 = icmp eq i64 %2, %4
  br i1 %14, label %15, label %16

15:                                               ; preds = %13
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %2) #16
  br label %480

16:                                               ; preds = %13
  %17 = icmp slt i64 %4, 30
  br i1 %17, label %18, label %110

18:                                               ; preds = %16
  %19 = icmp slt i64 %2, 501
  %20 = icmp eq i64 %4, 1
  %21 = or i1 %19, %20
  br i1 %21, label %22, label %23

22:                                               ; preds = %18
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) #16
  br label %480

23:                                               ; preds = %18
  call void @llvm.lifetime.start.p0(i64 240, ptr nonnull %6) #16
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef 500, ptr noundef %3, i64 noundef %4) #16
  %24 = getelementptr inbounds i8, ptr %0, i64 4000
  %25 = icmp eq i64 %4, 0
  br i1 %25, label %45, label %26

26:                                               ; preds = %23
  %27 = add nsw i64 %4, -1
  %28 = load i64, ptr %24, align 8, !tbaa !15
  %29 = icmp eq i64 %27, 0
  br i1 %29, label %42, label %30

30:                                               ; preds = %26
  %31 = getelementptr inbounds i8, ptr %0, i64 4008
  br label %32

32:                                               ; preds = %32, %30
  %33 = phi i64 [ %39, %32 ], [ %28, %30 ]
  %34 = phi ptr [ %38, %32 ], [ %31, %30 ]
  %35 = phi ptr [ %37, %32 ], [ %6, %30 ]
  %36 = phi i64 [ %40, %32 ], [ %27, %30 ]
  %37 = getelementptr inbounds i8, ptr %35, i64 8
  store i64 %33, ptr %35, align 8, !tbaa !15
  %38 = getelementptr inbounds i8, ptr %34, i64 8
  %39 = load i64, ptr %34, align 8, !tbaa !15
  %40 = add nsw i64 %36, -1
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %42, label %32, !llvm.loop !21

42:                                               ; preds = %32, %26
  %43 = phi i64 [ %28, %26 ], [ %39, %32 ]
  %44 = phi ptr [ %6, %26 ], [ %37, %32 ]
  store i64 %43, ptr %44, align 8, !tbaa !15
  br label %45

45:                                               ; preds = %42, %23
  %46 = add nsw i64 %2, -500
  %47 = getelementptr inbounds i8, ptr %1, i64 4000
  %48 = icmp sgt i64 %2, 1000
  br i1 %48, label %49, label %90

49:                                               ; preds = %45
  %50 = add nsw i64 %4, -1
  %51 = icmp eq i64 %50, 0
  br label %52

52:                                               ; preds = %86, %49
  %53 = phi ptr [ %47, %49 ], [ %88, %86 ]
  %54 = phi i64 [ %46, %49 ], [ %87, %86 ]
  %55 = phi ptr [ %24, %49 ], [ %68, %86 ]
  call void @__gmpn_mul_basecase(ptr noundef nonnull %55, ptr noundef nonnull %53, i64 noundef 500, ptr noundef %3, i64 noundef %4) #16
  %56 = call i64 @__gmpn_add_n(ptr noundef nonnull %55, ptr noundef nonnull %55, ptr noundef nonnull %6, i64 noundef %4) #16
  %57 = getelementptr inbounds i64, ptr %55, i64 %4
  %58 = load i64, ptr %57, align 8, !tbaa !15
  %59 = add i64 %58, %56
  store i64 %59, ptr %57, align 8, !tbaa !15
  %60 = icmp ult i64 %59, %56
  br i1 %60, label %61, label %67

61:                                               ; preds = %61, %52
  %62 = phi ptr [ %63, %61 ], [ %57, %52 ]
  %63 = getelementptr inbounds i8, ptr %62, i64 8
  %64 = load i64, ptr %63, align 8, !tbaa !15
  %65 = add i64 %64, 1
  store i64 %65, ptr %63, align 8, !tbaa !15
  %66 = icmp eq i64 %65, 0
  br i1 %66, label %61, label %67, !llvm.loop !22

67:                                               ; preds = %61, %52
  %68 = getelementptr inbounds i8, ptr %55, i64 4000
  br i1 %25, label %86, label %69

69:                                               ; preds = %67
  %70 = load i64, ptr %68, align 8, !tbaa !15
  br i1 %51, label %83, label %71

71:                                               ; preds = %69
  %72 = getelementptr inbounds i8, ptr %55, i64 4008
  br label %73

73:                                               ; preds = %73, %71
  %74 = phi i64 [ %80, %73 ], [ %70, %71 ]
  %75 = phi ptr [ %79, %73 ], [ %72, %71 ]
  %76 = phi ptr [ %78, %73 ], [ %6, %71 ]
  %77 = phi i64 [ %81, %73 ], [ %50, %71 ]
  %78 = getelementptr inbounds i8, ptr %76, i64 8
  store i64 %74, ptr %76, align 8, !tbaa !15
  %79 = getelementptr inbounds i8, ptr %75, i64 8
  %80 = load i64, ptr %75, align 8, !tbaa !15
  %81 = add nsw i64 %77, -1
  %82 = icmp eq i64 %81, 0
  br i1 %82, label %83, label %73, !llvm.loop !23

83:                                               ; preds = %73, %69
  %84 = phi i64 [ %70, %69 ], [ %80, %73 ]
  %85 = phi ptr [ %6, %69 ], [ %78, %73 ]
  store i64 %84, ptr %85, align 8, !tbaa !15
  br label %86

86:                                               ; preds = %83, %67
  %87 = add nsw i64 %54, -500
  %88 = getelementptr inbounds i8, ptr %53, i64 4000
  %89 = icmp sgt i64 %54, 1000
  br i1 %89, label %52, label %90, !llvm.loop !24

90:                                               ; preds = %86, %45
  %91 = phi ptr [ %24, %45 ], [ %68, %86 ]
  %92 = phi i64 [ %46, %45 ], [ %87, %86 ]
  %93 = phi ptr [ %47, %45 ], [ %88, %86 ]
  %94 = icmp sgt i64 %92, %4
  br i1 %94, label %95, label %96

95:                                               ; preds = %90
  call void @__gmpn_mul_basecase(ptr noundef nonnull %91, ptr noundef nonnull %93, i64 noundef %92, ptr noundef %3, i64 noundef %4) #16
  br label %97

96:                                               ; preds = %90
  call void @__gmpn_mul_basecase(ptr noundef nonnull %91, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %93, i64 noundef %92) #16
  br label %97

97:                                               ; preds = %96, %95
  %98 = call i64 @__gmpn_add_n(ptr noundef nonnull %91, ptr noundef nonnull %91, ptr noundef nonnull %6, i64 noundef %4) #16
  %99 = getelementptr inbounds i64, ptr %91, i64 %4
  %100 = load i64, ptr %99, align 8, !tbaa !15
  %101 = add i64 %100, %98
  store i64 %101, ptr %99, align 8, !tbaa !15
  %102 = icmp ult i64 %101, %98
  br i1 %102, label %103, label %109

103:                                              ; preds = %103, %97
  %104 = phi ptr [ %105, %103 ], [ %99, %97 ]
  %105 = getelementptr inbounds i8, ptr %104, i64 8
  %106 = load i64, ptr %105, align 8, !tbaa !15
  %107 = add i64 %106, 1
  store i64 %107, ptr %105, align 8, !tbaa !15
  %108 = icmp eq i64 %107, 0
  br i1 %108, label %103, label %109, !llvm.loop !25

109:                                              ; preds = %103, %97
  call void @llvm.lifetime.end.p0(i64 240, ptr nonnull %6) #16
  br label %480

110:                                              ; preds = %16
  %111 = icmp sgt i64 %4, 99
  br i1 %111, label %222, label %112

112:                                              ; preds = %110
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  store ptr null, ptr %7, align 8, !tbaa !7
  %113 = mul i64 %4, 36
  %114 = and i64 %113, -8
  %115 = add i64 %114, 1024
  %116 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %115) #16
  %117 = mul nuw nsw i64 %4, 3
  %118 = icmp sgt i64 %117, %2
  br i1 %118, label %208, label %119

119:                                              ; preds = %112
  %120 = shl nuw nsw i64 %4, 5
  %121 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %120) #16
  %122 = shl nuw nsw i64 %4, 1
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %122, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  %123 = getelementptr inbounds i64, ptr %0, i64 %122
  %124 = getelementptr inbounds i64, ptr %1, i64 %122
  %125 = sub nsw i64 %2, %122
  %126 = icmp slt i64 %125, %117
  br i1 %126, label %162, label %127

127:                                              ; preds = %119
  %128 = add nsw i64 %122, -1
  %129 = getelementptr inbounds i64, ptr %121, i64 %4
  br label %130

130:                                              ; preds = %157, %127
  %131 = phi i64 [ %125, %127 ], [ %160, %157 ]
  %132 = phi ptr [ %124, %127 ], [ %159, %157 ]
  %133 = phi ptr [ %123, %127 ], [ %158, %157 ]
  call void @__gmpn_toom42_mul(ptr noundef %121, ptr noundef %132, i64 noundef %122, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  %134 = call i64 @__gmpn_add_n(ptr noundef %133, ptr noundef %133, ptr noundef %121, i64 noundef %4) #16
  %135 = getelementptr inbounds i64, ptr %133, i64 %4
  %136 = load i64, ptr %129, align 8, !tbaa !15
  br label %137

137:                                              ; preds = %137, %130
  %138 = phi i64 [ %128, %130 ], [ %145, %137 ]
  %139 = phi ptr [ %135, %130 ], [ %143, %137 ]
  %140 = phi ptr [ %129, %130 ], [ %142, %137 ]
  %141 = phi i64 [ %136, %130 ], [ %144, %137 ]
  %142 = getelementptr inbounds i8, ptr %140, i64 8
  %143 = getelementptr inbounds i8, ptr %139, i64 8
  store i64 %141, ptr %139, align 8, !tbaa !15
  %144 = load i64, ptr %142, align 8, !tbaa !15
  %145 = add nsw i64 %138, -1
  %146 = icmp eq i64 %145, 0
  br i1 %146, label %147, label %137, !llvm.loop !26

147:                                              ; preds = %137
  store i64 %144, ptr %143, align 8, !tbaa !15
  %148 = load i64, ptr %135, align 8, !tbaa !15
  %149 = add i64 %148, %134
  store i64 %149, ptr %135, align 8, !tbaa !15
  %150 = icmp ult i64 %149, %134
  br i1 %150, label %151, label %157

151:                                              ; preds = %151, %147
  %152 = phi ptr [ %153, %151 ], [ %135, %147 ]
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = load i64, ptr %153, align 8, !tbaa !15
  %155 = add i64 %154, 1
  store i64 %155, ptr %153, align 8, !tbaa !15
  %156 = icmp eq i64 %155, 0
  br i1 %156, label %151, label %157, !llvm.loop !27

157:                                              ; preds = %151, %147
  %158 = getelementptr inbounds i64, ptr %133, i64 %122
  %159 = getelementptr inbounds i64, ptr %132, i64 %122
  %160 = sub nsw i64 %131, %122
  %161 = icmp slt i64 %160, %117
  br i1 %161, label %162, label %130, !llvm.loop !28

162:                                              ; preds = %157, %119
  %163 = phi ptr [ %123, %119 ], [ %158, %157 ]
  %164 = phi ptr [ %124, %119 ], [ %159, %157 ]
  %165 = phi i64 [ %125, %119 ], [ %160, %157 ]
  %166 = shl nsw i64 %165, 2
  %167 = mul nuw nsw i64 %4, 5
  %168 = icmp slt i64 %166, %167
  br i1 %168, label %169, label %170

169:                                              ; preds = %162
  call void @__gmpn_toom22_mul(ptr noundef %121, ptr noundef %164, i64 noundef %165, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  br label %175

170:                                              ; preds = %162
  %171 = mul nuw nsw i64 %4, 7
  %172 = icmp slt i64 %166, %171
  br i1 %172, label %173, label %174

173:                                              ; preds = %170
  call void @__gmpn_toom32_mul(ptr noundef %121, ptr noundef %164, i64 noundef %165, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  br label %175

174:                                              ; preds = %170
  call void @__gmpn_toom42_mul(ptr noundef %121, ptr noundef %164, i64 noundef %165, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  br label %175

175:                                              ; preds = %174, %173, %169
  %176 = call i64 @__gmpn_add_n(ptr noundef %163, ptr noundef %163, ptr noundef %121, i64 noundef %4) #16
  %177 = icmp eq i64 %165, 0
  br i1 %177, label %197, label %178

178:                                              ; preds = %175
  %179 = add nsw i64 %165, -1
  %180 = getelementptr inbounds i64, ptr %163, i64 %4
  %181 = getelementptr inbounds i64, ptr %121, i64 %4
  %182 = load i64, ptr %181, align 8, !tbaa !15
  %183 = icmp eq i64 %179, 0
  br i1 %183, label %194, label %184

184:                                              ; preds = %184, %178
  %185 = phi i64 [ %192, %184 ], [ %179, %178 ]
  %186 = phi ptr [ %190, %184 ], [ %180, %178 ]
  %187 = phi ptr [ %189, %184 ], [ %181, %178 ]
  %188 = phi i64 [ %191, %184 ], [ %182, %178 ]
  %189 = getelementptr inbounds i8, ptr %187, i64 8
  %190 = getelementptr inbounds i8, ptr %186, i64 8
  store i64 %188, ptr %186, align 8, !tbaa !15
  %191 = load i64, ptr %189, align 8, !tbaa !15
  %192 = add nsw i64 %185, -1
  %193 = icmp eq i64 %192, 0
  br i1 %193, label %194, label %184, !llvm.loop !29

194:                                              ; preds = %184, %178
  %195 = phi ptr [ %180, %178 ], [ %190, %184 ]
  %196 = phi i64 [ %182, %178 ], [ %191, %184 ]
  store i64 %196, ptr %195, align 8, !tbaa !15
  br label %197

197:                                              ; preds = %194, %175
  %198 = getelementptr inbounds i64, ptr %163, i64 %4
  %199 = load i64, ptr %198, align 8, !tbaa !15
  %200 = add i64 %199, %176
  store i64 %200, ptr %198, align 8, !tbaa !15
  %201 = icmp ult i64 %200, %176
  br i1 %201, label %202, label %218

202:                                              ; preds = %202, %197
  %203 = phi ptr [ %204, %202 ], [ %198, %197 ]
  %204 = getelementptr inbounds i8, ptr %203, i64 8
  %205 = load i64, ptr %204, align 8, !tbaa !15
  %206 = add i64 %205, 1
  store i64 %206, ptr %204, align 8, !tbaa !15
  %207 = icmp eq i64 %206, 0
  br i1 %207, label %202, label %218, !llvm.loop !30

208:                                              ; preds = %112
  %209 = shl nuw nsw i64 %2, 2
  %210 = mul nuw nsw i64 %4, 5
  %211 = icmp slt i64 %209, %210
  br i1 %211, label %212, label %213

212:                                              ; preds = %208
  call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  br label %218

213:                                              ; preds = %208
  %214 = mul nuw nsw i64 %4, 7
  %215 = icmp slt i64 %209, %214
  br i1 %215, label %216, label %217

216:                                              ; preds = %213
  call void @__gmpn_toom32_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  br label %218

217:                                              ; preds = %213
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %116) #16
  br label %218

218:                                              ; preds = %217, %216, %212, %202, %197
  %219 = phi i64 [ %2, %212 ], [ %2, %216 ], [ %2, %217 ], [ %165, %197 ], [ %165, %202 ]
  %220 = phi ptr [ %0, %212 ], [ %0, %216 ], [ %0, %217 ], [ %163, %197 ], [ %163, %202 ]
  %221 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %221) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  br label %480

222:                                              ; preds = %110
  %223 = add nuw nsw i64 %4, %2
  %224 = icmp ugt i64 %223, 5999
  br i1 %224, label %225, label %228

225:                                              ; preds = %222
  %226 = mul nuw nsw i64 %4, 3
  %227 = icmp sgt i64 %4, 999
  br i1 %227, label %386, label %228

228:                                              ; preds = %225, %222
  %229 = icmp sgt i64 %4, 299
  br i1 %229, label %230, label %235

230:                                              ; preds = %228
  %231 = mul nuw nsw i64 %2, 3
  %232 = add nuw nsw i64 %231, 12
  %233 = shl nsw i64 %4, 2
  %234 = icmp slt i64 %232, %233
  br i1 %234, label %366, label %235

235:                                              ; preds = %230, %228
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #16
  store ptr null, ptr %8, align 8, !tbaa !7
  %236 = shl i64 %4, 5
  %237 = add i64 %236, 512
  %238 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %237) #16
  %239 = shl nuw nsw i64 %2, 1
  %240 = mul nuw nsw i64 %4, 5
  %241 = icmp slt i64 %239, %240
  br i1 %241, label %338, label %242

242:                                              ; preds = %235
  %243 = mul i64 %4, 28
  %244 = and i64 %243, -8
  %245 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %244) #16
  %246 = icmp sgt i64 %4, 109
  %247 = shl nuw nsw i64 %4, 1
  br i1 %246, label %249, label %248

248:                                              ; preds = %242
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %247, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %250

249:                                              ; preds = %242
  call void @__gmpn_toom63_mul(ptr noundef %0, ptr noundef %1, i64 noundef %247, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %250

250:                                              ; preds = %249, %248
  %251 = shl nuw nsw i64 %4, 1
  %252 = getelementptr inbounds i64, ptr %0, i64 %251
  %253 = getelementptr inbounds i64, ptr %1, i64 %251
  %254 = sub nsw i64 %2, %251
  %255 = shl nsw i64 %254, 1
  %256 = icmp slt i64 %255, %240
  br i1 %256, label %296, label %257

257:                                              ; preds = %250
  %258 = add nsw i64 %251, -1
  %259 = getelementptr inbounds i64, ptr %245, i64 %4
  br label %260

260:                                              ; preds = %290, %257
  %261 = phi i64 [ %254, %257 ], [ %293, %290 ]
  %262 = phi ptr [ %253, %257 ], [ %292, %290 ]
  %263 = phi ptr [ %252, %257 ], [ %291, %290 ]
  br i1 %246, label %265, label %264

264:                                              ; preds = %260
  call void @__gmpn_toom42_mul(ptr noundef %245, ptr noundef nonnull %262, i64 noundef %251, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %266

265:                                              ; preds = %260
  call void @__gmpn_toom63_mul(ptr noundef %245, ptr noundef nonnull %262, i64 noundef %251, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %266

266:                                              ; preds = %265, %264
  %267 = call i64 @__gmpn_add_n(ptr noundef nonnull %263, ptr noundef nonnull %263, ptr noundef %245, i64 noundef %4) #16
  %268 = getelementptr inbounds i64, ptr %263, i64 %4
  %269 = load i64, ptr %259, align 8, !tbaa !15
  br label %270

270:                                              ; preds = %270, %266
  %271 = phi i64 [ %258, %266 ], [ %278, %270 ]
  %272 = phi ptr [ %268, %266 ], [ %276, %270 ]
  %273 = phi ptr [ %259, %266 ], [ %275, %270 ]
  %274 = phi i64 [ %269, %266 ], [ %277, %270 ]
  %275 = getelementptr inbounds i8, ptr %273, i64 8
  %276 = getelementptr inbounds i8, ptr %272, i64 8
  store i64 %274, ptr %272, align 8, !tbaa !15
  %277 = load i64, ptr %275, align 8, !tbaa !15
  %278 = add nsw i64 %271, -1
  %279 = icmp eq i64 %278, 0
  br i1 %279, label %280, label %270, !llvm.loop !31

280:                                              ; preds = %270
  store i64 %277, ptr %276, align 8, !tbaa !15
  %281 = load i64, ptr %268, align 8, !tbaa !15
  %282 = add i64 %281, %267
  store i64 %282, ptr %268, align 8, !tbaa !15
  %283 = icmp ult i64 %282, %267
  br i1 %283, label %284, label %290

284:                                              ; preds = %284, %280
  %285 = phi ptr [ %286, %284 ], [ %268, %280 ]
  %286 = getelementptr inbounds i8, ptr %285, i64 8
  %287 = load i64, ptr %286, align 8, !tbaa !15
  %288 = add i64 %287, 1
  store i64 %288, ptr %286, align 8, !tbaa !15
  %289 = icmp eq i64 %288, 0
  br i1 %289, label %284, label %290, !llvm.loop !32

290:                                              ; preds = %284, %280
  %291 = getelementptr inbounds i64, ptr %263, i64 %251
  %292 = getelementptr inbounds i64, ptr %262, i64 %251
  %293 = sub nsw i64 %261, %251
  %294 = shl nsw i64 %293, 1
  %295 = icmp slt i64 %294, %240
  br i1 %295, label %296, label %260, !llvm.loop !33

296:                                              ; preds = %290, %250
  %297 = phi ptr [ %252, %250 ], [ %291, %290 ]
  %298 = phi ptr [ %253, %250 ], [ %292, %290 ]
  %299 = phi i64 [ %254, %250 ], [ %293, %290 ]
  %300 = icmp slt i64 %299, %4
  br i1 %300, label %301, label %303

301:                                              ; preds = %296
  %302 = call i64 @__gmpn_mul(ptr noundef %245, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %298, i64 noundef %299)
  br label %305

303:                                              ; preds = %296
  %304 = call i64 @__gmpn_mul(ptr noundef %245, ptr noundef nonnull %298, i64 noundef %299, ptr noundef %3, i64 noundef %4)
  br label %305

305:                                              ; preds = %303, %301
  %306 = call i64 @__gmpn_add_n(ptr noundef nonnull %297, ptr noundef nonnull %297, ptr noundef %245, i64 noundef %4) #16
  %307 = icmp eq i64 %299, 0
  br i1 %307, label %327, label %308

308:                                              ; preds = %305
  %309 = add nsw i64 %299, -1
  %310 = getelementptr inbounds i64, ptr %297, i64 %4
  %311 = getelementptr inbounds i64, ptr %245, i64 %4
  %312 = load i64, ptr %311, align 8, !tbaa !15
  %313 = icmp eq i64 %309, 0
  br i1 %313, label %324, label %314

314:                                              ; preds = %314, %308
  %315 = phi i64 [ %322, %314 ], [ %309, %308 ]
  %316 = phi ptr [ %320, %314 ], [ %310, %308 ]
  %317 = phi ptr [ %319, %314 ], [ %311, %308 ]
  %318 = phi i64 [ %321, %314 ], [ %312, %308 ]
  %319 = getelementptr inbounds i8, ptr %317, i64 8
  %320 = getelementptr inbounds i8, ptr %316, i64 8
  store i64 %318, ptr %316, align 8, !tbaa !15
  %321 = load i64, ptr %319, align 8, !tbaa !15
  %322 = add nsw i64 %315, -1
  %323 = icmp eq i64 %322, 0
  br i1 %323, label %324, label %314, !llvm.loop !34

324:                                              ; preds = %314, %308
  %325 = phi ptr [ %310, %308 ], [ %320, %314 ]
  %326 = phi i64 [ %312, %308 ], [ %321, %314 ]
  store i64 %326, ptr %325, align 8, !tbaa !15
  br label %327

327:                                              ; preds = %324, %305
  %328 = getelementptr inbounds i64, ptr %297, i64 %4
  %329 = load i64, ptr %328, align 8, !tbaa !15
  %330 = add i64 %329, %306
  store i64 %330, ptr %328, align 8, !tbaa !15
  %331 = icmp ult i64 %330, %306
  br i1 %331, label %332, label %362

332:                                              ; preds = %332, %327
  %333 = phi ptr [ %334, %332 ], [ %328, %327 ]
  %334 = getelementptr inbounds i8, ptr %333, i64 8
  %335 = load i64, ptr %334, align 8, !tbaa !15
  %336 = add i64 %335, 1
  store i64 %336, ptr %334, align 8, !tbaa !15
  %337 = icmp eq i64 %336, 0
  br i1 %337, label %332, label %362, !llvm.loop !35

338:                                              ; preds = %235
  %339 = mul nuw nsw i64 %2, 6
  %340 = mul nuw nsw i64 %4, 7
  %341 = icmp slt i64 %339, %340
  br i1 %341, label %342, label %343

342:                                              ; preds = %338
  call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

343:                                              ; preds = %338
  %344 = mul nuw nsw i64 %4, 3
  %345 = icmp slt i64 %239, %344
  br i1 %345, label %346, label %347

346:                                              ; preds = %343
  call void @__gmpn_toom43_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

347:                                              ; preds = %343
  %348 = mul nuw nsw i64 %4, 11
  %349 = icmp slt i64 %339, %348
  br i1 %349, label %350, label %358

350:                                              ; preds = %347
  %351 = shl nsw i64 %2, 2
  %352 = icmp slt i64 %351, %340
  br i1 %352, label %353, label %357

353:                                              ; preds = %350
  %354 = icmp sgt i64 %4, 109
  br i1 %354, label %356, label %355

355:                                              ; preds = %353
  call void @__gmpn_toom32_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

356:                                              ; preds = %353
  call void @__gmpn_toom53_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

357:                                              ; preds = %350
  call void @__gmpn_toom53_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

358:                                              ; preds = %347
  %359 = icmp sgt i64 %4, 109
  br i1 %359, label %361, label %360

360:                                              ; preds = %358
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

361:                                              ; preds = %358
  call void @__gmpn_toom63_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #16
  br label %362

362:                                              ; preds = %361, %360, %357, %356, %355, %346, %342, %332, %327
  %363 = phi i64 [ %2, %342 ], [ %2, %346 ], [ %2, %356 ], [ %2, %355 ], [ %2, %357 ], [ %2, %361 ], [ %2, %360 ], [ %299, %327 ], [ %299, %332 ]
  %364 = phi ptr [ %0, %342 ], [ %0, %346 ], [ %0, %356 ], [ %0, %355 ], [ %0, %357 ], [ %0, %361 ], [ %0, %360 ], [ %297, %327 ], [ %297, %332 ]
  %365 = load ptr, ptr %8, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %365) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #16
  br label %480

366:                                              ; preds = %230
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9) #16
  store ptr null, ptr %9, align 8, !tbaa !7
  %367 = icmp sgt i64 %4, 349
  br i1 %367, label %372, label %368

368:                                              ; preds = %366
  %369 = mul i64 %2, 24
  %370 = add i64 %369, 512
  %371 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %370) #16
  call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %371) #16
  br label %384

372:                                              ; preds = %366
  %373 = icmp sgt i64 %4, 449
  br i1 %373, label %379, label %374

374:                                              ; preds = %372
  %375 = udiv i64 %223, 10
  %376 = mul i64 %375, 96
  %377 = add i64 %376, 3408
  %378 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %377) #16
  call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %378) #16
  br label %384

379:                                              ; preds = %372
  %380 = udiv i64 %223, 14
  %381 = mul i64 %380, 120
  %382 = add i64 %381, 3888
  %383 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %382) #16
  call void @__gmpn_toom8h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %383) #16
  br label %384

384:                                              ; preds = %379, %374, %368
  %385 = load ptr, ptr %9, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %385) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9) #16
  br label %480

386:                                              ; preds = %225
  %387 = shl nsw i64 %4, 3
  %388 = icmp sgt i64 %387, %2
  br i1 %388, label %479, label %389

389:                                              ; preds = %386
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10) #16
  store ptr null, ptr %10, align 8, !tbaa !7
  %390 = mul i64 %4, 36
  %391 = and i64 %390, -8
  %392 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %10, i64 noundef %391) #16
  call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %226, ptr noundef %3, i64 noundef %4) #16
  %393 = mul nuw nsw i64 %4, 7
  %394 = getelementptr inbounds i64, ptr %0, i64 %226
  %395 = getelementptr inbounds i64, ptr %1, i64 %226
  %396 = sub nsw i64 %2, %226
  %397 = shl nsw i64 %396, 1
  %398 = icmp slt i64 %397, %393
  br i1 %398, label %435, label %399

399:                                              ; preds = %389
  %400 = add nsw i64 %226, -1
  %401 = getelementptr inbounds i64, ptr %392, i64 %4
  br label %402

402:                                              ; preds = %429, %399
  %403 = phi i64 [ %396, %399 ], [ %432, %429 ]
  %404 = phi ptr [ %395, %399 ], [ %431, %429 ]
  %405 = phi ptr [ %394, %399 ], [ %430, %429 ]
  call void @__gmpn_nussbaumer_mul(ptr noundef %392, ptr noundef nonnull %404, i64 noundef %226, ptr noundef %3, i64 noundef %4) #16
  %406 = call i64 @__gmpn_add_n(ptr noundef nonnull %405, ptr noundef nonnull %405, ptr noundef %392, i64 noundef %4) #16
  %407 = getelementptr inbounds i64, ptr %405, i64 %4
  %408 = load i64, ptr %401, align 8, !tbaa !15
  br label %409

409:                                              ; preds = %409, %402
  %410 = phi i64 [ %400, %402 ], [ %417, %409 ]
  %411 = phi ptr [ %407, %402 ], [ %415, %409 ]
  %412 = phi ptr [ %401, %402 ], [ %414, %409 ]
  %413 = phi i64 [ %408, %402 ], [ %416, %409 ]
  %414 = getelementptr inbounds i8, ptr %412, i64 8
  %415 = getelementptr inbounds i8, ptr %411, i64 8
  store i64 %413, ptr %411, align 8, !tbaa !15
  %416 = load i64, ptr %414, align 8, !tbaa !15
  %417 = add nsw i64 %410, -1
  %418 = icmp eq i64 %417, 0
  br i1 %418, label %419, label %409, !llvm.loop !36

419:                                              ; preds = %409
  store i64 %416, ptr %415, align 8, !tbaa !15
  %420 = load i64, ptr %407, align 8, !tbaa !15
  %421 = add i64 %420, %406
  store i64 %421, ptr %407, align 8, !tbaa !15
  %422 = icmp ult i64 %421, %406
  br i1 %422, label %423, label %429

423:                                              ; preds = %423, %419
  %424 = phi ptr [ %425, %423 ], [ %407, %419 ]
  %425 = getelementptr inbounds i8, ptr %424, i64 8
  %426 = load i64, ptr %425, align 8, !tbaa !15
  %427 = add i64 %426, 1
  store i64 %427, ptr %425, align 8, !tbaa !15
  %428 = icmp eq i64 %427, 0
  br i1 %428, label %423, label %429, !llvm.loop !37

429:                                              ; preds = %423, %419
  %430 = getelementptr inbounds i64, ptr %405, i64 %226
  %431 = getelementptr inbounds i64, ptr %404, i64 %226
  %432 = sub nsw i64 %403, %226
  %433 = shl nsw i64 %432, 1
  %434 = icmp slt i64 %433, %393
  br i1 %434, label %435, label %402, !llvm.loop !38

435:                                              ; preds = %429, %389
  %436 = phi ptr [ %394, %389 ], [ %430, %429 ]
  %437 = phi ptr [ %395, %389 ], [ %431, %429 ]
  %438 = phi i64 [ %396, %389 ], [ %432, %429 ]
  %439 = icmp slt i64 %438, %4
  br i1 %439, label %440, label %442

440:                                              ; preds = %435
  %441 = call i64 @__gmpn_mul(ptr noundef %392, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %437, i64 noundef %438)
  br label %444

442:                                              ; preds = %435
  %443 = call i64 @__gmpn_mul(ptr noundef %392, ptr noundef nonnull %437, i64 noundef %438, ptr noundef %3, i64 noundef %4)
  br label %444

444:                                              ; preds = %442, %440
  %445 = call i64 @__gmpn_add_n(ptr noundef nonnull %436, ptr noundef nonnull %436, ptr noundef %392, i64 noundef %4) #16
  %446 = icmp eq i64 %438, 0
  br i1 %446, label %466, label %447

447:                                              ; preds = %444
  %448 = add nsw i64 %438, -1
  %449 = getelementptr inbounds i64, ptr %436, i64 %4
  %450 = getelementptr inbounds i64, ptr %392, i64 %4
  %451 = load i64, ptr %450, align 8, !tbaa !15
  %452 = icmp eq i64 %448, 0
  br i1 %452, label %463, label %453

453:                                              ; preds = %453, %447
  %454 = phi i64 [ %461, %453 ], [ %448, %447 ]
  %455 = phi ptr [ %459, %453 ], [ %449, %447 ]
  %456 = phi ptr [ %458, %453 ], [ %450, %447 ]
  %457 = phi i64 [ %460, %453 ], [ %451, %447 ]
  %458 = getelementptr inbounds i8, ptr %456, i64 8
  %459 = getelementptr inbounds i8, ptr %455, i64 8
  store i64 %457, ptr %455, align 8, !tbaa !15
  %460 = load i64, ptr %458, align 8, !tbaa !15
  %461 = add nsw i64 %454, -1
  %462 = icmp eq i64 %461, 0
  br i1 %462, label %463, label %453, !llvm.loop !39

463:                                              ; preds = %453, %447
  %464 = phi ptr [ %449, %447 ], [ %459, %453 ]
  %465 = phi i64 [ %451, %447 ], [ %460, %453 ]
  store i64 %465, ptr %464, align 8, !tbaa !15
  br label %466

466:                                              ; preds = %463, %444
  %467 = getelementptr inbounds i64, ptr %436, i64 %4
  %468 = load i64, ptr %467, align 8, !tbaa !15
  %469 = add i64 %468, %445
  store i64 %469, ptr %467, align 8, !tbaa !15
  %470 = icmp ult i64 %469, %445
  br i1 %470, label %471, label %477

471:                                              ; preds = %471, %466
  %472 = phi ptr [ %473, %471 ], [ %467, %466 ]
  %473 = getelementptr inbounds i8, ptr %472, i64 8
  %474 = load i64, ptr %473, align 8, !tbaa !15
  %475 = add i64 %474, 1
  store i64 %475, ptr %473, align 8, !tbaa !15
  %476 = icmp eq i64 %475, 0
  br i1 %476, label %471, label %477, !llvm.loop !40

477:                                              ; preds = %471, %466
  %478 = load ptr, ptr %10, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %478) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10) #16
  br label %480

479:                                              ; preds = %386
  tail call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) #16
  br label %480

480:                                              ; preds = %479, %477, %384, %362, %218, %109, %22, %15, %12
  %481 = phi i64 [ %2, %15 ], [ %2, %22 ], [ %92, %109 ], [ %438, %477 ], [ %2, %479 ], [ %2, %384 ], [ %363, %362 ], [ %219, %218 ], [ %2, %12 ]
  %482 = phi ptr [ %0, %15 ], [ %0, %22 ], [ %91, %109 ], [ %436, %477 ], [ %0, %479 ], [ %0, %384 ], [ %364, %362 ], [ %220, %218 ], [ %0, %12 ]
  %483 = add i64 %4, -1
  %484 = add i64 %483, %481
  %485 = getelementptr inbounds i64, ptr %482, i64 %484
  %486 = load i64, ptr %485, align 8, !tbaa !15
  ret i64 %486
}

; Function Attrs: nounwind ssp uwtable
define void @__gmp_tmp_reentrant_free(ptr noundef %0) local_unnamed_addr #5 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %10, label %3

3:                                                ; preds = %3, %1
  %4 = phi ptr [ %5, %3 ], [ %0, %1 ]
  %5 = load ptr, ptr %4, align 8, !tbaa !14
  %6 = load ptr, ptr @__gmp_free_func, align 8, !tbaa !7
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  %8 = load i64, ptr %7, align 8, !tbaa !11
  tail call void %6(ptr noundef nonnull %4, i64 noundef %8) #16
  %9 = icmp eq ptr %5, null
  br i1 %9, label %10, label %3, !llvm.loop !41

10:                                               ; preds = %3, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr nocapture noundef readonly %3, i64 noundef %4) local_unnamed_addr #5 {
  %6 = load i64, ptr %3, align 8, !tbaa !15
  %7 = tail call i64 @__gmpn_mul_1(ptr noundef %0, ptr noundef %1, i64 noundef %2, i64 noundef %6) #16
  %8 = getelementptr inbounds i64, ptr %0, i64 %2
  store i64 %7, ptr %8, align 8, !tbaa !15
  %9 = icmp sgt i64 %4, 1
  br i1 %9, label %10, label %21

10:                                               ; preds = %10, %5
  %11 = phi i64 [ %14, %10 ], [ %4, %5 ]
  %12 = phi ptr [ %15, %10 ], [ %3, %5 ]
  %13 = phi ptr [ %16, %10 ], [ %0, %5 ]
  %14 = add nsw i64 %11, -1
  %15 = getelementptr inbounds i8, ptr %12, i64 8
  %16 = getelementptr inbounds i8, ptr %13, i64 8
  %17 = load i64, ptr %15, align 8, !tbaa !15
  %18 = tail call i64 @__gmpn_addmul_1(ptr noundef nonnull %16, ptr noundef %1, i64 noundef %2, i64 noundef %17) #16
  %19 = getelementptr inbounds i64, ptr %16, i64 %2
  store i64 %18, ptr %19, align 8, !tbaa !15
  %20 = icmp sgt i64 %11, 2
  br i1 %20, label %10, label %21, !llvm.loop !42

21:                                               ; preds = %10, %5
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) local_unnamed_addr #5 {
  %5 = alloca [326 x i64], align 16
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = icmp sgt i64 %3, 29
  br i1 %10, label %12, label %11

11:                                               ; preds = %4
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3) #16
  br label %45

12:                                               ; preds = %4
  %13 = icmp sgt i64 %3, 99
  br i1 %13, label %15, label %14

14:                                               ; preds = %12
  call void @llvm.lifetime.start.p0(i64 2608, ptr nonnull %5) #16
  call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef nonnull %5) #16
  call void @llvm.lifetime.end.p0(i64 2608, ptr nonnull %5) #16
  br label %45

15:                                               ; preds = %12
  %16 = icmp sgt i64 %3, 299
  br i1 %16, label %22, label %17

17:                                               ; preds = %15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #16
  store ptr null, ptr %6, align 8, !tbaa !7
  %18 = mul i64 %3, 24
  %19 = add i64 %18, 512
  %20 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %19) #16
  call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %20) #16
  %21 = load ptr, ptr %6, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %21) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #16
  br label %45

22:                                               ; preds = %15
  %23 = icmp sgt i64 %3, 349
  br i1 %23, label %29, label %24

24:                                               ; preds = %22
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  store ptr null, ptr %7, align 8, !tbaa !7
  %25 = mul i64 %3, 24
  %26 = add i64 %25, 512
  %27 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %26) #16
  call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %27) #16
  %28 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %28) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  br label %45

29:                                               ; preds = %22
  %30 = icmp sgt i64 %3, 449
  br i1 %30, label %36, label %31

31:                                               ; preds = %29
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #16
  store ptr null, ptr %8, align 8, !tbaa !7
  %32 = shl i64 %3, 4
  %33 = add i64 %32, 3312
  %34 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %33) #16
  call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %34) #16
  %35 = load ptr, ptr %8, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %35) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #16
  br label %45

36:                                               ; preds = %29
  %37 = icmp sgt i64 %3, 2999
  br i1 %37, label %44, label %38

38:                                               ; preds = %36
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9) #16
  store ptr null, ptr %9, align 8, !tbaa !7
  %39 = mul nuw nsw i64 %3, 15
  %40 = and i64 %39, 9223372036854775800
  %41 = add nuw i64 %40, 3768
  %42 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %41) #16
  call void @__gmpn_toom8h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %42) #16
  %43 = load ptr, ptr %9, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %43) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9) #16
  br label %45

44:                                               ; preds = %36
  tail call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3) #16
  br label %45

45:                                               ; preds = %44, %38, %31, %24, %17, %14, %11
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  %8 = shl nsw i64 %4, 1
  %9 = icmp sgt i64 %8, %2
  %10 = add nsw i64 %2, 3
  %11 = ashr i64 %10, 2
  %12 = add nsw i64 %4, 1
  %13 = ashr i64 %12, 1
  %14 = select i1 %9, i64 %13, i64 %11
  %15 = mul nsw i64 %14, 3
  %16 = sub nsw i64 %2, %15
  %17 = sub i64 %4, %14
  store ptr null, ptr %7, align 8, !tbaa !7
  %18 = mul i64 %14, 48
  %19 = add i64 %18, 40
  %20 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %19) #16
  %21 = add nsw i64 %14, 1
  %22 = getelementptr inbounds i64, ptr %20, i64 %21
  %23 = getelementptr i64, ptr %22, i64 %21
  %24 = getelementptr i64, ptr %23, i64 %21
  %25 = getelementptr i64, ptr %24, i64 %21
  %26 = getelementptr inbounds i64, ptr %25, i64 %14
  %27 = call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef %20, ptr noundef %22, ptr noundef %1, i64 noundef %14, i64 noundef %16, ptr noundef %0) #16
  %28 = and i32 %27, 1
  %29 = getelementptr inbounds i64, ptr %1, i64 %15
  %30 = call i64 @__gmpn_lshift(ptr noundef %23, ptr noundef %29, i64 noundef %16, i32 noundef 1) #16
  %31 = shl nsw i64 %14, 1
  %32 = getelementptr inbounds i64, ptr %1, i64 %31
  %33 = call i64 @__gmpn_add_n(ptr noundef %23, ptr noundef %32, ptr noundef %23, i64 noundef %16) #16
  %34 = add i64 %33, %30
  %35 = icmp eq i64 %16, %14
  br i1 %35, label %95, label %36

36:                                               ; preds = %6
  %37 = getelementptr inbounds i64, ptr %23, i64 %16
  %38 = getelementptr inbounds i64, ptr %32, i64 %16
  %39 = sub nsw i64 %14, %16
  %40 = load i64, ptr %38, align 8, !tbaa !15
  %41 = add i64 %40, %34
  store i64 %41, ptr %37, align 8, !tbaa !15
  %42 = icmp ult i64 %41, %34
  br i1 %42, label %43, label %78

43:                                               ; preds = %36
  %44 = call i64 @llvm.smax.i64(i64 %39, i64 1)
  br label %45

45:                                               ; preds = %49, %43
  %46 = phi i64 [ %56, %49 ], [ 0, %43 ]
  %47 = phi i64 [ %54, %49 ], [ 1, %43 ]
  %48 = icmp eq i64 %47, %44
  br i1 %48, label %95, label %49

49:                                               ; preds = %45
  %50 = getelementptr inbounds i64, ptr %38, i64 %47
  %51 = load i64, ptr %50, align 8, !tbaa !15
  %52 = add i64 %51, 1
  %53 = getelementptr inbounds i64, ptr %37, i64 %47
  store i64 %52, ptr %53, align 8, !tbaa !15
  %54 = add nuw i64 %47, 1
  %55 = icmp eq i64 %52, 0
  %56 = add i64 %46, 1
  br i1 %55, label %45, label %57, !llvm.loop !43

57:                                               ; preds = %49
  %58 = icmp ne ptr %32, %23
  %59 = icmp slt i64 %54, %39
  %60 = select i1 %58, i1 %59, i1 false
  br i1 %60, label %61, label %95

61:                                               ; preds = %57
  %62 = shl i64 %2, 3
  %63 = add i64 %62, 32
  %64 = shl i64 %14, 3
  %65 = sub i64 %63, %64
  %66 = shl i64 %46, 3
  %67 = getelementptr i8, ptr %20, i64 %66
  %68 = getelementptr i8, ptr %67, i64 %65
  %69 = add i64 %62, 16
  %70 = sub i64 %69, %64
  %71 = getelementptr i8, ptr %1, i64 %66
  %72 = getelementptr i8, ptr %71, i64 %70
  %73 = shl i64 %14, 2
  %74 = add i64 %73, 2305843009213693950
  %75 = add i64 %46, %2
  %76 = sub i64 %74, %75
  %77 = shl i64 %76, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %68, ptr align 8 %72, i64 %77, i1 false), !tbaa !15
  br label %95

78:                                               ; preds = %36
  %79 = icmp ne ptr %32, %23
  %80 = icmp sgt i64 %39, 1
  %81 = and i1 %80, %79
  br i1 %81, label %82, label %95

82:                                               ; preds = %78
  %83 = shl i64 %2, 3
  %84 = add i64 %83, 24
  %85 = shl i64 %14, 3
  %86 = sub i64 %84, %85
  %87 = getelementptr i8, ptr %20, i64 %86
  %88 = add i64 %83, 8
  %89 = sub i64 %88, %85
  %90 = getelementptr i8, ptr %1, i64 %89
  %91 = xor i64 %2, -1
  %92 = shl i64 %14, 5
  %93 = shl i64 %91, 3
  %94 = add i64 %92, %93
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %87, ptr align 8 %90, i64 %94, i1 false), !tbaa !15
  br label %95

95:                                               ; preds = %82, %78, %61, %57, %45, %6
  %96 = phi i64 [ %34, %6 ], [ 0, %57 ], [ 0, %78 ], [ 0, %61 ], [ 0, %82 ], [ 1, %45 ]
  %97 = shl i64 %96, 1
  %98 = call i64 @__gmpn_lshift(ptr noundef %23, ptr noundef %23, i64 noundef %14, i32 noundef 1) #16
  %99 = add i64 %97, %98
  %100 = getelementptr inbounds i64, ptr %1, i64 %14
  %101 = call i64 @__gmpn_add_n(ptr noundef %23, ptr noundef %100, ptr noundef %23, i64 noundef %14) #16
  %102 = add i64 %99, %101
  %103 = shl i64 %102, 1
  %104 = call i64 @__gmpn_lshift(ptr noundef %23, ptr noundef %23, i64 noundef %14, i32 noundef 1) #16
  %105 = add i64 %103, %104
  %106 = call i64 @__gmpn_add_n(ptr noundef %23, ptr noundef %1, ptr noundef %23, i64 noundef %14) #16
  %107 = add i64 %105, %106
  %108 = getelementptr inbounds i64, ptr %23, i64 %14
  store i64 %107, ptr %108, align 8, !tbaa !15
  %109 = icmp eq i64 %17, %14
  %110 = getelementptr inbounds i64, ptr %3, i64 %14
  br i1 %109, label %111, label %131

111:                                              ; preds = %95
  %112 = call i64 @__gmpn_add_n(ptr noundef %24, ptr noundef %3, ptr noundef %110, i64 noundef %14) #16
  %113 = getelementptr inbounds i64, ptr %24, i64 %14
  store i64 %112, ptr %113, align 8, !tbaa !15
  br label %114

114:                                              ; preds = %117, %111
  %115 = phi i64 [ %14, %111 ], [ %118, %117 ]
  %116 = icmp sgt i64 %115, 0
  br i1 %116, label %117, label %129

117:                                              ; preds = %114
  %118 = add nsw i64 %115, -1
  %119 = getelementptr inbounds i64, ptr %3, i64 %118
  %120 = load i64, ptr %119, align 8, !tbaa !15
  %121 = getelementptr inbounds i64, ptr %110, i64 %118
  %122 = load i64, ptr %121, align 8, !tbaa !15
  %123 = icmp eq i64 %120, %122
  br i1 %123, label %114, label %124, !llvm.loop !44

124:                                              ; preds = %117
  %125 = icmp ugt i64 %120, %122
  br i1 %125, label %129, label %126

126:                                              ; preds = %124
  %127 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %110, ptr noundef %3, i64 noundef %14) #16
  %128 = xor i32 %28, 1
  br label %224

129:                                              ; preds = %124, %114
  %130 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %3, ptr noundef %110, i64 noundef %14) #16
  br label %224

131:                                              ; preds = %95
  %132 = icmp eq i64 %17, 0
  br i1 %132, label %146, label %133

133:                                              ; preds = %131
  %134 = call i64 @__gmpn_add_n(ptr noundef %24, ptr noundef %3, ptr noundef %110, i64 noundef %17) #16
  %135 = icmp eq i64 %134, 0
  br i1 %135, label %146, label %136

136:                                              ; preds = %139, %133
  %137 = phi i64 [ %143, %139 ], [ %17, %133 ]
  %138 = icmp slt i64 %137, %14
  br i1 %138, label %139, label %160

139:                                              ; preds = %136
  %140 = getelementptr inbounds i64, ptr %3, i64 %137
  %141 = load i64, ptr %140, align 8, !tbaa !15
  %142 = add i64 %141, 1
  %143 = add nsw i64 %137, 1
  %144 = getelementptr inbounds i64, ptr %24, i64 %137
  store i64 %142, ptr %144, align 8, !tbaa !15
  %145 = icmp eq i64 %142, 0
  br i1 %145, label %136, label %146, !llvm.loop !45

146:                                              ; preds = %139, %133, %131
  %147 = phi i64 [ %17, %133 ], [ 0, %131 ], [ %143, %139 ]
  %148 = icmp ne ptr %24, %3
  %149 = icmp slt i64 %147, %14
  %150 = select i1 %148, i1 %149, i1 false
  br i1 %150, label %151, label %160

151:                                              ; preds = %146
  %152 = mul i64 %14, 24
  %153 = shl i64 %147, 3
  %154 = getelementptr i8, ptr %20, i64 %152
  %155 = getelementptr i8, ptr %154, i64 %153
  %156 = getelementptr i8, ptr %155, i64 24
  %157 = getelementptr i8, ptr %3, i64 %153
  %158 = sub i64 %14, %147
  %159 = shl i64 %158, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %156, ptr align 8 %157, i64 %159, i1 false), !tbaa !15
  br label %160

160:                                              ; preds = %151, %146, %136
  %161 = phi i64 [ 0, %146 ], [ 0, %151 ], [ 1, %136 ]
  %162 = getelementptr inbounds i64, ptr %24, i64 %14
  store i64 %161, ptr %162, align 8, !tbaa !15
  %163 = getelementptr inbounds i64, ptr %3, i64 %17
  %164 = sub nsw i64 %14, %17
  br label %165

165:                                              ; preds = %165, %160
  %166 = phi i64 [ %164, %160 ], [ %167, %165 ]
  %167 = add nsw i64 %166, -1
  %168 = getelementptr inbounds i64, ptr %163, i64 %167
  %169 = load i64, ptr %168, align 8, !tbaa !15
  %170 = icmp ne i64 %169, 0
  %171 = icmp eq i64 %167, 0
  %172 = or i1 %170, %171
  br i1 %172, label %173, label %165, !llvm.loop !46

173:                                              ; preds = %165
  br i1 %170, label %196, label %174

174:                                              ; preds = %177, %173
  %175 = phi i64 [ %178, %177 ], [ %17, %173 ]
  %176 = icmp sgt i64 %175, 0
  br i1 %176, label %177, label %196

177:                                              ; preds = %174
  %178 = add nsw i64 %175, -1
  %179 = getelementptr inbounds i64, ptr %3, i64 %178
  %180 = load i64, ptr %179, align 8, !tbaa !15
  %181 = getelementptr inbounds i64, ptr %110, i64 %178
  %182 = load i64, ptr %181, align 8, !tbaa !15
  %183 = icmp eq i64 %180, %182
  br i1 %183, label %174, label %184, !llvm.loop !44

184:                                              ; preds = %177
  %185 = icmp ugt i64 %180, %182
  br i1 %185, label %196, label %186

186:                                              ; preds = %184
  %187 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %110, ptr noundef %3, i64 noundef %17) #16
  %188 = icmp eq i64 %164, 0
  br i1 %188, label %194, label %189

189:                                              ; preds = %186
  %190 = getelementptr i64, ptr %25, i64 %17
  %191 = shl i64 %14, 4
  %192 = shl i64 %4, 3
  %193 = sub i64 %191, %192
  call void @llvm.memset.p0.i64(ptr align 8 %190, i8 0, i64 %193, i1 false), !tbaa !15
  br label %194

194:                                              ; preds = %189, %186
  %195 = xor i32 %28, 1
  br label %224

196:                                              ; preds = %184, %174, %173
  br i1 %132, label %210, label %197

197:                                              ; preds = %196
  %198 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %3, ptr noundef %110, i64 noundef %17) #16
  %199 = icmp eq i64 %198, 0
  br i1 %199, label %210, label %200

200:                                              ; preds = %203, %197
  %201 = phi i64 [ %207, %203 ], [ %17, %197 ]
  %202 = icmp slt i64 %201, %14
  br i1 %202, label %203, label %224

203:                                              ; preds = %200
  %204 = getelementptr inbounds i64, ptr %3, i64 %201
  %205 = load i64, ptr %204, align 8, !tbaa !15
  %206 = add i64 %205, -1
  %207 = add nsw i64 %201, 1
  %208 = getelementptr inbounds i64, ptr %25, i64 %201
  store i64 %206, ptr %208, align 8, !tbaa !15
  %209 = icmp eq i64 %205, 0
  br i1 %209, label %200, label %210, !llvm.loop !47

210:                                              ; preds = %203, %197, %196
  %211 = phi i64 [ %17, %197 ], [ 0, %196 ], [ %207, %203 ]
  %212 = icmp ne ptr %25, %3
  %213 = icmp slt i64 %211, %14
  %214 = select i1 %212, i1 %213, i1 false
  br i1 %214, label %215, label %224

215:                                              ; preds = %210
  %216 = shl i64 %14, 5
  %217 = shl i64 %211, 3
  %218 = getelementptr i8, ptr %20, i64 %216
  %219 = getelementptr i8, ptr %218, i64 %217
  %220 = getelementptr i8, ptr %219, i64 32
  %221 = getelementptr i8, ptr %3, i64 %217
  %222 = sub i64 %14, %211
  %223 = shl i64 %222, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %220, ptr align 8 %221, i64 %223, i1 false), !tbaa !15
  br label %224

224:                                              ; preds = %215, %210, %200, %194, %129, %126
  %225 = phi i32 [ %128, %126 ], [ %28, %129 ], [ %195, %194 ], [ %28, %210 ], [ %28, %215 ], [ %28, %200 ]
  %226 = getelementptr inbounds i64, ptr %3, i64 %14
  %227 = icmp eq i64 %17, 0
  br i1 %227, label %241, label %228

228:                                              ; preds = %224
  %229 = call i64 @__gmpn_add_n(ptr noundef %26, ptr noundef %24, ptr noundef %226, i64 noundef %17) #16
  %230 = icmp eq i64 %229, 0
  br i1 %230, label %241, label %231

231:                                              ; preds = %234, %228
  %232 = phi i64 [ %238, %234 ], [ %17, %228 ]
  %233 = icmp sgt i64 %232, %14
  br i1 %233, label %253, label %234

234:                                              ; preds = %231
  %235 = getelementptr inbounds i64, ptr %24, i64 %232
  %236 = load i64, ptr %235, align 8, !tbaa !15
  %237 = add i64 %236, 1
  %238 = add nsw i64 %232, 1
  %239 = getelementptr inbounds i64, ptr %26, i64 %232
  store i64 %237, ptr %239, align 8, !tbaa !15
  %240 = icmp eq i64 %237, 0
  br i1 %240, label %231, label %241, !llvm.loop !45

241:                                              ; preds = %234, %228, %224
  %242 = phi i64 [ %17, %228 ], [ 0, %224 ], [ %238, %234 ]
  %243 = icmp ne ptr %26, %24
  %244 = icmp sle i64 %242, %14
  %245 = select i1 %243, i1 %244, i1 false
  br i1 %245, label %246, label %253

246:                                              ; preds = %246, %241
  %247 = phi i64 [ %251, %246 ], [ %242, %241 ]
  %248 = getelementptr inbounds i64, ptr %24, i64 %247
  %249 = load i64, ptr %248, align 8, !tbaa !15
  %250 = getelementptr inbounds i64, ptr %26, i64 %247
  store i64 %249, ptr %250, align 8, !tbaa !15
  %251 = add nsw i64 %247, 1
  %252 = icmp eq i64 %247, %14
  br i1 %252, label %253, label %246, !llvm.loop !48

253:                                              ; preds = %246, %241, %231
  call void @__gmpn_mul_n(ptr noundef %5, ptr noundef %22, ptr noundef %25, i64 noundef %14) #16
  %254 = getelementptr inbounds i64, ptr %22, i64 %14
  %255 = load i64, ptr %254, align 8, !tbaa !15
  %256 = icmp eq i64 %255, 0
  br i1 %256, label %260, label %257

257:                                              ; preds = %253
  %258 = getelementptr inbounds i64, ptr %5, i64 %14
  %259 = call i64 @__gmpn_add_n(ptr noundef %258, ptr noundef %258, ptr noundef %25, i64 noundef %14) #16
  br label %260

260:                                              ; preds = %257, %253
  %261 = phi i64 [ %259, %257 ], [ 0, %253 ]
  %262 = getelementptr inbounds i64, ptr %5, i64 %31
  store i64 %261, ptr %262, align 8, !tbaa !15
  %263 = getelementptr inbounds i8, ptr %262, i64 8
  call void @__gmpn_mul_n(ptr noundef nonnull %263, ptr noundef %23, ptr noundef %26, i64 noundef %21) #16
  %264 = icmp sgt i64 %16, %17
  %265 = shl nsw i64 %14, 5
  %266 = getelementptr inbounds i8, ptr %0, i64 %265
  br i1 %264, label %267, label %269

267:                                              ; preds = %260
  %268 = call i64 @__gmpn_mul(ptr noundef %266, ptr noundef %29, i64 noundef %16, ptr noundef %226, i64 noundef %17) #16
  br label %271

269:                                              ; preds = %260
  %270 = call i64 @__gmpn_mul(ptr noundef %266, ptr noundef %226, i64 noundef %17, ptr noundef %29, i64 noundef %16) #16
  br label %271

271:                                              ; preds = %269, %267
  %272 = shl nsw i64 %14, 5
  %273 = getelementptr inbounds i8, ptr %0, i64 %272
  %274 = load i64, ptr %273, align 8, !tbaa !15
  %275 = getelementptr inbounds i64, ptr %0, i64 %31
  call void @__gmpn_mul_n(ptr noundef %275, ptr noundef %20, ptr noundef %24, i64 noundef %14) #16
  %276 = getelementptr inbounds i64, ptr %20, i64 %14
  %277 = load i64, ptr %276, align 8, !tbaa !15
  switch i64 %277, label %287 [
    i64 1, label %278
    i64 2, label %281
    i64 3, label %284
  ]

278:                                              ; preds = %271
  %279 = getelementptr inbounds i64, ptr %275, i64 %14
  %280 = call i64 @__gmpn_add_n(ptr noundef %279, ptr noundef %279, ptr noundef %24, i64 noundef %14) #16
  br label %287

281:                                              ; preds = %271
  %282 = getelementptr inbounds i64, ptr %275, i64 %14
  %283 = call i64 @__gmpn_addmul_1(ptr noundef %282, ptr noundef %24, i64 noundef %14, i64 noundef 2) #16
  br label %287

284:                                              ; preds = %271
  %285 = getelementptr inbounds i64, ptr %275, i64 %14
  %286 = call i64 @__gmpn_addmul_1(ptr noundef %285, ptr noundef %24, i64 noundef %14, i64 noundef 3) #16
  br label %287

287:                                              ; preds = %284, %281, %278, %271
  %288 = phi i64 [ %280, %278 ], [ %283, %281 ], [ %286, %284 ], [ 0, %271 ]
  %289 = getelementptr inbounds i64, ptr %24, i64 %14
  %290 = load i64, ptr %289, align 8, !tbaa !15
  %291 = icmp eq i64 %290, 0
  br i1 %291, label %298, label %292

292:                                              ; preds = %287
  %293 = load i64, ptr %276, align 8, !tbaa !15
  %294 = getelementptr inbounds i64, ptr %275, i64 %14
  %295 = call i64 @__gmpn_add_n(ptr noundef %294, ptr noundef %294, ptr noundef %20, i64 noundef %14) #16
  %296 = add i64 %293, %288
  %297 = add i64 %296, %295
  br label %298

298:                                              ; preds = %292, %287
  %299 = phi i64 [ %297, %292 ], [ %288, %287 ]
  %300 = getelementptr inbounds i64, ptr %275, i64 %31
  store i64 %299, ptr %300, align 8, !tbaa !15
  call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %14) #16
  %301 = add nsw i64 %16, %17
  call void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef nonnull %263, ptr noundef %5, i64 noundef %14, i64 noundef %301, i32 noundef %225, i64 noundef %274) #16
  %302 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %302) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = ashr i64 %2, 1
  %8 = sub i64 %2, %7
  %9 = sub i64 %4, %8
  %10 = getelementptr inbounds i64, ptr %0, i64 %8
  %11 = and i64 %2, 1
  %12 = icmp eq i64 %11, 0
  br i1 %12, label %13, label %35

13:                                               ; preds = %6
  %14 = getelementptr inbounds i64, ptr %1, i64 %8
  br label %15

15:                                               ; preds = %18, %13
  %16 = phi i64 [ %8, %13 ], [ %19, %18 ]
  %17 = icmp sgt i64 %16, 0
  br i1 %17, label %18, label %28

18:                                               ; preds = %15
  %19 = add nsw i64 %16, -1
  %20 = getelementptr inbounds i64, ptr %1, i64 %19
  %21 = load i64, ptr %20, align 8, !tbaa !15
  %22 = getelementptr inbounds i64, ptr %14, i64 %19
  %23 = load i64, ptr %22, align 8, !tbaa !15
  %24 = icmp eq i64 %21, %23
  br i1 %24, label %15, label %25, !llvm.loop !49

25:                                               ; preds = %18
  %26 = icmp ugt i64 %21, %23
  %27 = select i1 %26, i32 1, i32 -1
  br label %28

28:                                               ; preds = %25, %15
  %29 = phi i32 [ %27, %25 ], [ 0, %15 ]
  %30 = icmp slt i32 %29, 0
  br i1 %30, label %31, label %33

31:                                               ; preds = %28
  %32 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %14, ptr noundef %1, i64 noundef %8) #16
  br label %65

33:                                               ; preds = %28
  %34 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %14, i64 noundef %8) #16
  br label %65

35:                                               ; preds = %6
  %36 = getelementptr inbounds i64, ptr %1, i64 %7
  %37 = load i64, ptr %36, align 8, !tbaa !15
  %38 = icmp eq i64 %37, 0
  br i1 %38, label %39, label %60

39:                                               ; preds = %35
  %40 = getelementptr inbounds i64, ptr %1, i64 %8
  br label %41

41:                                               ; preds = %44, %39
  %42 = phi i64 [ %7, %39 ], [ %45, %44 ]
  %43 = icmp sgt i64 %42, 0
  br i1 %43, label %44, label %54

44:                                               ; preds = %41
  %45 = add nsw i64 %42, -1
  %46 = getelementptr inbounds i64, ptr %1, i64 %45
  %47 = load i64, ptr %46, align 8, !tbaa !15
  %48 = getelementptr inbounds i64, ptr %40, i64 %45
  %49 = load i64, ptr %48, align 8, !tbaa !15
  %50 = icmp eq i64 %47, %49
  br i1 %50, label %41, label %51, !llvm.loop !49

51:                                               ; preds = %44
  %52 = icmp ugt i64 %47, %49
  %53 = select i1 %52, i32 1, i32 -1
  br label %54

54:                                               ; preds = %51, %41
  %55 = phi i32 [ %53, %51 ], [ 0, %41 ]
  %56 = icmp slt i32 %55, 0
  br i1 %56, label %57, label %60

57:                                               ; preds = %54
  %58 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %40, ptr noundef %1, i64 noundef %7) #16
  %59 = getelementptr inbounds i64, ptr %0, i64 %7
  store i64 0, ptr %59, align 8, !tbaa !15
  br label %65

60:                                               ; preds = %54, %35
  %61 = getelementptr inbounds i64, ptr %1, i64 %8
  %62 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %61, i64 noundef %7) #16
  %63 = sub i64 %37, %62
  %64 = getelementptr inbounds i64, ptr %0, i64 %7
  store i64 %63, ptr %64, align 8, !tbaa !15
  br label %65

65:                                               ; preds = %60, %57, %33, %31
  %66 = phi i32 [ 1, %31 ], [ 0, %33 ], [ 1, %57 ], [ 0, %60 ]
  %67 = icmp eq i64 %9, %8
  br i1 %67, label %68, label %87

68:                                               ; preds = %65
  %69 = getelementptr inbounds i64, ptr %3, i64 %8
  br label %70

70:                                               ; preds = %73, %68
  %71 = phi i64 [ %8, %68 ], [ %74, %73 ]
  %72 = icmp sgt i64 %71, 0
  br i1 %72, label %73, label %85

73:                                               ; preds = %70
  %74 = add nsw i64 %71, -1
  %75 = getelementptr inbounds i64, ptr %3, i64 %74
  %76 = load i64, ptr %75, align 8, !tbaa !15
  %77 = getelementptr inbounds i64, ptr %69, i64 %74
  %78 = load i64, ptr %77, align 8, !tbaa !15
  %79 = icmp eq i64 %76, %78
  br i1 %79, label %70, label %80, !llvm.loop !49

80:                                               ; preds = %73
  %81 = icmp ule i64 %76, %78
  br i1 %81, label %82, label %85

82:                                               ; preds = %80
  %83 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %69, ptr noundef %3, i64 noundef %8) #16
  %84 = xor i32 %66, 1
  br label %153

85:                                               ; preds = %80, %70
  %86 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %3, ptr noundef %69, i64 noundef %8) #16
  br label %153

87:                                               ; preds = %65
  %88 = getelementptr inbounds i64, ptr %3, i64 %9
  %89 = sub i64 %8, %9
  br label %90

90:                                               ; preds = %90, %87
  %91 = phi i64 [ %89, %87 ], [ %92, %90 ]
  %92 = add nsw i64 %91, -1
  %93 = getelementptr inbounds i64, ptr %88, i64 %92
  %94 = load i64, ptr %93, align 8, !tbaa !15
  %95 = icmp ne i64 %94, 0
  %96 = icmp eq i64 %92, 0
  %97 = or i1 %95, %96
  br i1 %97, label %98, label %90, !llvm.loop !50

98:                                               ; preds = %90
  br i1 %95, label %125, label %99

99:                                               ; preds = %98
  %100 = getelementptr inbounds i64, ptr %3, i64 %8
  br label %101

101:                                              ; preds = %104, %99
  %102 = phi i64 [ %9, %99 ], [ %105, %104 ]
  %103 = icmp sgt i64 %102, 0
  br i1 %103, label %104, label %114

104:                                              ; preds = %101
  %105 = add nsw i64 %102, -1
  %106 = getelementptr inbounds i64, ptr %3, i64 %105
  %107 = load i64, ptr %106, align 8, !tbaa !15
  %108 = getelementptr inbounds i64, ptr %100, i64 %105
  %109 = load i64, ptr %108, align 8, !tbaa !15
  %110 = icmp eq i64 %107, %109
  br i1 %110, label %101, label %111, !llvm.loop !49

111:                                              ; preds = %104
  %112 = icmp ugt i64 %107, %109
  %113 = select i1 %112, i32 1, i32 -1
  br label %114

114:                                              ; preds = %111, %101
  %115 = phi i32 [ %113, %111 ], [ 0, %101 ]
  %116 = icmp slt i32 %115, 0
  br i1 %116, label %117, label %125

117:                                              ; preds = %114
  %118 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %100, ptr noundef %3, i64 noundef %9) #16
  %119 = icmp eq i64 %89, 0
  br i1 %119, label %123, label %120

120:                                              ; preds = %117
  %121 = getelementptr i64, ptr %0, i64 %4
  %122 = shl nuw i64 %89, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %121, i8 0, i64 %122, i1 false), !tbaa !15
  br label %123

123:                                              ; preds = %120, %117
  %124 = xor i32 %66, 1
  br label %153

125:                                              ; preds = %114, %98
  %126 = icmp eq i64 %9, 0
  br i1 %126, label %141, label %127

127:                                              ; preds = %125
  %128 = getelementptr inbounds i64, ptr %3, i64 %8
  %129 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %3, ptr noundef %128, i64 noundef %9) #16
  %130 = icmp eq i64 %129, 0
  br i1 %130, label %141, label %131

131:                                              ; preds = %134, %127
  %132 = phi i64 [ %138, %134 ], [ %9, %127 ]
  %133 = icmp slt i64 %132, %8
  br i1 %133, label %134, label %153

134:                                              ; preds = %131
  %135 = getelementptr inbounds i64, ptr %3, i64 %132
  %136 = load i64, ptr %135, align 8, !tbaa !15
  %137 = add i64 %136, -1
  %138 = add nsw i64 %132, 1
  %139 = getelementptr inbounds i64, ptr %10, i64 %132
  store i64 %137, ptr %139, align 8, !tbaa !15
  %140 = icmp eq i64 %136, 0
  br i1 %140, label %131, label %141, !llvm.loop !51

141:                                              ; preds = %134, %127, %125
  %142 = phi i64 [ %9, %127 ], [ 0, %125 ], [ %138, %134 ]
  %143 = icmp ne ptr %10, %3
  %144 = icmp slt i64 %142, %8
  %145 = select i1 %143, i1 %144, i1 false
  br i1 %145, label %146, label %153

146:                                              ; preds = %146, %141
  %147 = phi i64 [ %151, %146 ], [ %142, %141 ]
  %148 = getelementptr inbounds i64, ptr %3, i64 %147
  %149 = load i64, ptr %148, align 8, !tbaa !15
  %150 = getelementptr inbounds i64, ptr %10, i64 %147
  store i64 %149, ptr %150, align 8, !tbaa !15
  %151 = add nsw i64 %147, 1
  %152 = icmp eq i64 %151, %8
  br i1 %152, label %153, label %146, !llvm.loop !52

153:                                              ; preds = %146, %141, %131, %123, %85, %82
  %154 = phi i32 [ %84, %82 ], [ %66, %85 ], [ %124, %123 ], [ %66, %141 ], [ %66, %146 ], [ %66, %131 ]
  %155 = icmp sgt i64 %8, 29
  br i1 %155, label %157, label %156

156:                                              ; preds = %153
  tail call void @__gmpn_mul_basecase(ptr noundef %5, ptr noundef %0, i64 noundef %8, ptr noundef %10, i64 noundef %8) #16
  br label %160

157:                                              ; preds = %153
  %158 = shl nsw i64 %8, 4
  %159 = getelementptr inbounds i8, ptr %5, i64 %158
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef %0, i64 noundef %8, ptr noundef nonnull %10, i64 noundef %8, ptr noundef nonnull %159)
  br label %160

160:                                              ; preds = %157, %156
  %161 = icmp sgt i64 %7, %9
  br i1 %161, label %162, label %180

162:                                              ; preds = %160
  %163 = icmp sgt i64 %9, 29
  br i1 %163, label %169, label %164

164:                                              ; preds = %162
  %165 = shl nsw i64 %8, 4
  %166 = getelementptr inbounds i8, ptr %0, i64 %165
  %167 = getelementptr inbounds i64, ptr %1, i64 %8
  %168 = getelementptr inbounds i64, ptr %3, i64 %8
  tail call void @__gmpn_mul_basecase(ptr noundef %166, ptr noundef %167, i64 noundef %7, ptr noundef %168, i64 noundef %9) #16
  br label %191

169:                                              ; preds = %162
  %170 = shl nsw i64 %7, 2
  %171 = mul nuw nsw i64 %9, 5
  %172 = icmp slt i64 %170, %171
  %173 = shl nsw i64 %8, 1
  %174 = getelementptr inbounds i64, ptr %0, i64 %173
  %175 = getelementptr inbounds i64, ptr %1, i64 %8
  %176 = getelementptr inbounds i64, ptr %3, i64 %8
  %177 = getelementptr inbounds i64, ptr %5, i64 %173
  br i1 %172, label %178, label %179

178:                                              ; preds = %169
  tail call void @__gmpn_toom22_mul(ptr noundef %174, ptr noundef %175, i64 noundef %7, ptr noundef %176, i64 noundef %9, ptr noundef %177)
  br label %191

179:                                              ; preds = %169
  tail call void @__gmpn_toom32_mul(ptr noundef %174, ptr noundef %175, i64 noundef %7, ptr noundef %176, i64 noundef %9, ptr noundef %177) #16
  br label %191

180:                                              ; preds = %160
  %181 = icmp sgt i64 %7, 29
  %182 = getelementptr inbounds i64, ptr %1, i64 %8
  %183 = getelementptr inbounds i64, ptr %3, i64 %8
  br i1 %181, label %187, label %184

184:                                              ; preds = %180
  %185 = shl nsw i64 %8, 4
  %186 = getelementptr inbounds i8, ptr %0, i64 %185
  tail call void @__gmpn_mul_basecase(ptr noundef %186, ptr noundef %182, i64 noundef %7, ptr noundef %183, i64 noundef %7) #16
  br label %191

187:                                              ; preds = %180
  %188 = shl nsw i64 %8, 1
  %189 = getelementptr inbounds i64, ptr %0, i64 %188
  %190 = getelementptr inbounds i64, ptr %5, i64 %188
  tail call void @__gmpn_toom22_mul(ptr noundef %189, ptr noundef %182, i64 noundef %7, ptr noundef %183, i64 noundef %7, ptr noundef %190)
  br label %191

191:                                              ; preds = %187, %184, %179, %178, %164
  br i1 %155, label %193, label %192

192:                                              ; preds = %191
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8) #16
  br label %196

193:                                              ; preds = %191
  %194 = shl nsw i64 %8, 4
  %195 = getelementptr inbounds i8, ptr %5, i64 %194
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %195)
  br label %196

196:                                              ; preds = %193, %192
  %197 = shl nsw i64 %8, 1
  %198 = getelementptr inbounds i64, ptr %0, i64 %197
  %199 = tail call i64 @__gmpn_add_n(ptr noundef %198, ptr noundef %10, ptr noundef %198, i64 noundef %8) #16
  %200 = tail call i64 @__gmpn_add_n(ptr noundef %10, ptr noundef %198, ptr noundef %0, i64 noundef %8) #16
  %201 = add i64 %200, %199
  %202 = sub i64 %7, %8
  %203 = add i64 %202, %9
  %204 = icmp eq i64 %203, 0
  br i1 %204, label %218, label %205

205:                                              ; preds = %196
  %206 = getelementptr inbounds i64, ptr %198, i64 %8
  %207 = tail call i64 @__gmpn_add_n(ptr noundef %198, ptr noundef %198, ptr noundef %206, i64 noundef %203) #16
  %208 = icmp eq i64 %207, 0
  br i1 %208, label %218, label %209

209:                                              ; preds = %212, %205
  %210 = phi i64 [ %216, %212 ], [ %203, %205 ]
  %211 = icmp slt i64 %210, %8
  br i1 %211, label %212, label %218

212:                                              ; preds = %209
  %213 = getelementptr inbounds i64, ptr %198, i64 %210
  %214 = load i64, ptr %213, align 8, !tbaa !15
  %215 = add i64 %214, 1
  %216 = add nsw i64 %210, 1
  store i64 %215, ptr %213, align 8, !tbaa !15
  %217 = icmp eq i64 %215, 0
  br i1 %217, label %209, label %218, !llvm.loop !53

218:                                              ; preds = %212, %209, %205, %196
  %219 = phi i64 [ 0, %205 ], [ 0, %196 ], [ 1, %209 ], [ 0, %212 ]
  %220 = add i64 %219, %199
  %221 = icmp eq i32 %154, 0
  br i1 %221, label %225, label %222

222:                                              ; preds = %218
  %223 = tail call i64 @__gmpn_add_n(ptr noundef %10, ptr noundef %10, ptr noundef %5, i64 noundef %197) #16
  %224 = add i64 %223, %220
  br label %232

225:                                              ; preds = %218
  %226 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %10, ptr noundef %5, i64 noundef %197) #16
  %227 = sub i64 %220, %226
  %228 = icmp eq i64 %227, -1
  br i1 %228, label %229, label %232, !prof !54

229:                                              ; preds = %225
  %230 = sub i64 %2, %7
  %231 = shl i64 %230, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %198, i8 0, i64 %231, i1 false), !tbaa !15
  br label %255

232:                                              ; preds = %225, %222
  %233 = phi i64 [ %224, %222 ], [ %227, %225 ]
  %234 = load i64, ptr %198, align 8, !tbaa !15
  %235 = add i64 %234, %201
  store i64 %235, ptr %198, align 8, !tbaa !15
  %236 = icmp ult i64 %235, %201
  br i1 %236, label %237, label %243

237:                                              ; preds = %237, %232
  %238 = phi ptr [ %239, %237 ], [ %198, %232 ]
  %239 = getelementptr inbounds i8, ptr %238, i64 8
  %240 = load i64, ptr %239, align 8, !tbaa !15
  %241 = add i64 %240, 1
  store i64 %241, ptr %239, align 8, !tbaa !15
  %242 = icmp eq i64 %241, 0
  br i1 %242, label %237, label %243, !llvm.loop !55

243:                                              ; preds = %237, %232
  %244 = mul i64 %8, 24
  %245 = getelementptr inbounds i8, ptr %0, i64 %244
  %246 = load i64, ptr %245, align 8, !tbaa !15
  %247 = add i64 %246, %233
  store i64 %247, ptr %245, align 8, !tbaa !15
  %248 = icmp ult i64 %247, %233
  br i1 %248, label %249, label %255

249:                                              ; preds = %249, %243
  %250 = phi ptr [ %251, %249 ], [ %245, %243 ]
  %251 = getelementptr inbounds i8, ptr %250, i64 8
  %252 = load i64, ptr %251, align 8, !tbaa !15
  %253 = add i64 %252, 1
  store i64 %253, ptr %251, align 8, !tbaa !15
  %254 = icmp eq i64 %253, 0
  br i1 %254, label %249, label %255, !llvm.loop !56

255:                                              ; preds = %249, %243, %229
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom32_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = shl nsw i64 %2, 1
  %8 = mul nsw i64 %4, 3
  %9 = icmp slt i64 %7, %8
  br i1 %9, label %13, label %10

10:                                               ; preds = %6
  %11 = add nsw i64 %2, 2
  %12 = udiv i64 %11, 3
  br label %16

13:                                               ; preds = %6
  %14 = add nsw i64 %4, 1
  %15 = ashr i64 %14, 1
  br label %16

16:                                               ; preds = %13, %10
  %17 = phi i64 [ %12, %10 ], [ %15, %13 ]
  %18 = shl nsw i64 %17, 1
  %19 = sub nsw i64 %2, %18
  %20 = sub i64 %4, %17
  %21 = getelementptr inbounds i64, ptr %1, i64 %18
  %22 = icmp eq i64 %19, 0
  br i1 %22, label %36, label %23

23:                                               ; preds = %16
  %24 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %1, ptr noundef %21, i64 noundef %19) #16
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %36, label %26

26:                                               ; preds = %29, %23
  %27 = phi i64 [ %33, %29 ], [ %19, %23 ]
  %28 = icmp slt i64 %27, %17
  br i1 %28, label %29, label %48

29:                                               ; preds = %26
  %30 = getelementptr inbounds i64, ptr %1, i64 %27
  %31 = load i64, ptr %30, align 8, !tbaa !15
  %32 = add i64 %31, 1
  %33 = add nsw i64 %27, 1
  %34 = getelementptr inbounds i64, ptr %0, i64 %27
  store i64 %32, ptr %34, align 8, !tbaa !15
  %35 = icmp eq i64 %32, 0
  br i1 %35, label %26, label %36, !llvm.loop !57

36:                                               ; preds = %29, %23, %16
  %37 = phi i64 [ %19, %23 ], [ 0, %16 ], [ %33, %29 ]
  %38 = icmp ne ptr %0, %1
  %39 = icmp slt i64 %37, %17
  %40 = select i1 %38, i1 %39, i1 false
  br i1 %40, label %41, label %48

41:                                               ; preds = %41, %36
  %42 = phi i64 [ %46, %41 ], [ %37, %36 ]
  %43 = getelementptr inbounds i64, ptr %1, i64 %42
  %44 = load i64, ptr %43, align 8, !tbaa !15
  %45 = getelementptr inbounds i64, ptr %0, i64 %42
  store i64 %44, ptr %45, align 8, !tbaa !15
  %46 = add nsw i64 %42, 1
  %47 = icmp eq i64 %46, %17
  br i1 %47, label %48, label %41, !llvm.loop !58

48:                                               ; preds = %41, %36, %26
  %49 = phi i1 [ true, %36 ], [ true, %41 ], [ false, %26 ]
  %50 = phi i64 [ 0, %36 ], [ 0, %41 ], [ 1, %26 ]
  br i1 %49, label %51, label %72

51:                                               ; preds = %48
  %52 = getelementptr inbounds i64, ptr %1, i64 %17
  br label %53

53:                                               ; preds = %56, %51
  %54 = phi i64 [ %17, %51 ], [ %57, %56 ]
  %55 = icmp sgt i64 %54, 0
  br i1 %55, label %56, label %66

56:                                               ; preds = %53
  %57 = add nsw i64 %54, -1
  %58 = getelementptr inbounds i64, ptr %0, i64 %57
  %59 = load i64, ptr %58, align 8, !tbaa !15
  %60 = getelementptr inbounds i64, ptr %52, i64 %57
  %61 = load i64, ptr %60, align 8, !tbaa !15
  %62 = icmp eq i64 %59, %61
  br i1 %62, label %53, label %63, !llvm.loop !59

63:                                               ; preds = %56
  %64 = icmp ugt i64 %59, %61
  %65 = select i1 %64, i32 1, i32 -1
  br label %66

66:                                               ; preds = %63, %53
  %67 = phi i32 [ %65, %63 ], [ 0, %53 ]
  %68 = icmp slt i32 %67, 0
  br i1 %68, label %69, label %72

69:                                               ; preds = %66
  %70 = getelementptr inbounds i64, ptr %0, i64 %18
  %71 = tail call i64 @__gmpn_sub_n(ptr noundef %70, ptr noundef %52, ptr noundef %0, i64 noundef %17) #16
  br label %77

72:                                               ; preds = %66, %48
  %73 = getelementptr inbounds i64, ptr %0, i64 %18
  %74 = getelementptr inbounds i64, ptr %1, i64 %17
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef %73, ptr noundef %0, ptr noundef %74, i64 noundef %17) #16
  %76 = sub i64 %50, %75
  br label %77

77:                                               ; preds = %72, %69
  %78 = phi i64 [ 0, %69 ], [ %76, %72 ]
  %79 = phi i32 [ 1, %69 ], [ 0, %72 ]
  %80 = getelementptr inbounds i64, ptr %1, i64 %17
  %81 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %80, i64 noundef %17) #16
  %82 = add i64 %81, %50
  %83 = icmp eq i64 %20, %17
  %84 = getelementptr inbounds i64, ptr %0, i64 %17
  %85 = getelementptr inbounds i64, ptr %3, i64 %17
  br i1 %83, label %86, label %111

86:                                               ; preds = %77
  %87 = tail call i64 @__gmpn_add_n(ptr noundef %84, ptr noundef %3, ptr noundef %85, i64 noundef %17) #16
  br label %88

88:                                               ; preds = %91, %86
  %89 = phi i64 [ %17, %86 ], [ %92, %91 ]
  %90 = icmp sgt i64 %89, 0
  br i1 %90, label %91, label %101

91:                                               ; preds = %88
  %92 = add nsw i64 %89, -1
  %93 = getelementptr inbounds i64, ptr %3, i64 %92
  %94 = load i64, ptr %93, align 8, !tbaa !15
  %95 = getelementptr inbounds i64, ptr %85, i64 %92
  %96 = load i64, ptr %95, align 8, !tbaa !15
  %97 = icmp eq i64 %94, %96
  br i1 %97, label %88, label %98, !llvm.loop !59

98:                                               ; preds = %91
  %99 = icmp ugt i64 %94, %96
  %100 = select i1 %99, i32 1, i32 -1
  br label %101

101:                                              ; preds = %98, %88
  %102 = phi i32 [ %100, %98 ], [ 0, %88 ]
  %103 = icmp slt i32 %102, 0
  %104 = mul i64 %17, 24
  %105 = getelementptr inbounds i8, ptr %0, i64 %104
  br i1 %103, label %106, label %109

106:                                              ; preds = %101
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %105, ptr noundef %85, ptr noundef %3, i64 noundef %17) #16
  %108 = xor i32 %79, 1
  br label %207

109:                                              ; preds = %101
  %110 = tail call i64 @__gmpn_sub_n(ptr noundef %105, ptr noundef %3, ptr noundef %85, i64 noundef %17) #16
  br label %207

111:                                              ; preds = %77
  %112 = icmp eq i64 %20, 0
  br i1 %112, label %126, label %113

113:                                              ; preds = %111
  %114 = tail call i64 @__gmpn_add_n(ptr noundef %84, ptr noundef %3, ptr noundef %85, i64 noundef %20) #16
  %115 = icmp eq i64 %114, 0
  br i1 %115, label %126, label %116

116:                                              ; preds = %119, %113
  %117 = phi i64 [ %123, %119 ], [ %20, %113 ]
  %118 = icmp slt i64 %117, %17
  br i1 %118, label %119, label %138

119:                                              ; preds = %116
  %120 = getelementptr inbounds i64, ptr %3, i64 %117
  %121 = load i64, ptr %120, align 8, !tbaa !15
  %122 = add i64 %121, 1
  %123 = add nsw i64 %117, 1
  %124 = getelementptr inbounds i64, ptr %84, i64 %117
  store i64 %122, ptr %124, align 8, !tbaa !15
  %125 = icmp eq i64 %122, 0
  br i1 %125, label %116, label %126, !llvm.loop !57

126:                                              ; preds = %119, %113, %111
  %127 = phi i64 [ %20, %113 ], [ 0, %111 ], [ %123, %119 ]
  %128 = icmp ne ptr %84, %3
  %129 = icmp slt i64 %127, %17
  %130 = select i1 %128, i1 %129, i1 false
  br i1 %130, label %131, label %138

131:                                              ; preds = %131, %126
  %132 = phi i64 [ %136, %131 ], [ %127, %126 ]
  %133 = getelementptr inbounds i64, ptr %3, i64 %132
  %134 = load i64, ptr %133, align 8, !tbaa !15
  %135 = getelementptr inbounds i64, ptr %84, i64 %132
  store i64 %134, ptr %135, align 8, !tbaa !15
  %136 = add nsw i64 %132, 1
  %137 = icmp eq i64 %136, %17
  br i1 %137, label %138, label %131, !llvm.loop !58

138:                                              ; preds = %131, %126, %116
  %139 = phi i64 [ 0, %126 ], [ 0, %131 ], [ 1, %116 ]
  %140 = getelementptr inbounds i64, ptr %3, i64 %20
  %141 = sub nsw i64 %17, %20
  br label %142

142:                                              ; preds = %142, %138
  %143 = phi i64 [ %141, %138 ], [ %144, %142 ]
  %144 = add nsw i64 %143, -1
  %145 = getelementptr inbounds i64, ptr %140, i64 %144
  %146 = load i64, ptr %145, align 8, !tbaa !15
  %147 = icmp ne i64 %146, 0
  %148 = icmp eq i64 %144, 0
  %149 = or i1 %147, %148
  br i1 %149, label %150, label %142, !llvm.loop !60

150:                                              ; preds = %142
  br i1 %147, label %179, label %151

151:                                              ; preds = %154, %150
  %152 = phi i64 [ %155, %154 ], [ %20, %150 ]
  %153 = icmp sgt i64 %152, 0
  br i1 %153, label %154, label %164

154:                                              ; preds = %151
  %155 = add nsw i64 %152, -1
  %156 = getelementptr inbounds i64, ptr %3, i64 %155
  %157 = load i64, ptr %156, align 8, !tbaa !15
  %158 = getelementptr inbounds i64, ptr %85, i64 %155
  %159 = load i64, ptr %158, align 8, !tbaa !15
  %160 = icmp eq i64 %157, %159
  br i1 %160, label %151, label %161, !llvm.loop !59

161:                                              ; preds = %154
  %162 = icmp ugt i64 %157, %159
  %163 = select i1 %162, i32 1, i32 -1
  br label %164

164:                                              ; preds = %161, %151
  %165 = phi i32 [ %163, %161 ], [ 0, %151 ]
  %166 = icmp slt i32 %165, 0
  br i1 %166, label %167, label %179

167:                                              ; preds = %164
  %168 = mul i64 %17, 24
  %169 = getelementptr inbounds i8, ptr %0, i64 %168
  %170 = tail call i64 @__gmpn_sub_n(ptr noundef %169, ptr noundef %85, ptr noundef %3, i64 noundef %20) #16
  %171 = icmp eq i64 %141, 0
  br i1 %171, label %177, label %172

172:                                              ; preds = %167
  %173 = getelementptr i64, ptr %169, i64 %20
  %174 = shl i64 %17, 4
  %175 = shl i64 %4, 3
  %176 = sub i64 %174, %175
  tail call void @llvm.memset.p0.i64(ptr align 8 %173, i8 0, i64 %176, i1 false), !tbaa !15
  br label %177

177:                                              ; preds = %172, %167
  %178 = xor i32 %79, 1
  br label %207

179:                                              ; preds = %164, %150
  %180 = mul i64 %17, 24
  %181 = getelementptr inbounds i8, ptr %0, i64 %180
  br i1 %112, label %195, label %182

182:                                              ; preds = %179
  %183 = tail call i64 @__gmpn_sub_n(ptr noundef %181, ptr noundef %3, ptr noundef %85, i64 noundef %20) #16
  %184 = icmp eq i64 %183, 0
  br i1 %184, label %195, label %185

185:                                              ; preds = %188, %182
  %186 = phi i64 [ %192, %188 ], [ %20, %182 ]
  %187 = icmp slt i64 %186, %17
  br i1 %187, label %188, label %207

188:                                              ; preds = %185
  %189 = getelementptr inbounds i64, ptr %3, i64 %186
  %190 = load i64, ptr %189, align 8, !tbaa !15
  %191 = add i64 %190, -1
  %192 = add nsw i64 %186, 1
  %193 = getelementptr inbounds i64, ptr %181, i64 %186
  store i64 %191, ptr %193, align 8, !tbaa !15
  %194 = icmp eq i64 %190, 0
  br i1 %194, label %185, label %195, !llvm.loop !61

195:                                              ; preds = %188, %182, %179
  %196 = phi i64 [ %20, %182 ], [ 0, %179 ], [ %192, %188 ]
  %197 = icmp ne ptr %181, %3
  %198 = icmp slt i64 %196, %17
  %199 = select i1 %197, i1 %198, i1 false
  br i1 %199, label %200, label %207

200:                                              ; preds = %200, %195
  %201 = phi i64 [ %205, %200 ], [ %196, %195 ]
  %202 = getelementptr inbounds i64, ptr %3, i64 %201
  %203 = load i64, ptr %202, align 8, !tbaa !15
  %204 = getelementptr inbounds i64, ptr %181, i64 %201
  store i64 %203, ptr %204, align 8, !tbaa !15
  %205 = add nsw i64 %201, 1
  %206 = icmp eq i64 %205, %17
  br i1 %206, label %207, label %200, !llvm.loop !62

207:                                              ; preds = %200, %195, %185, %177, %109, %106
  %208 = phi i64 [ %87, %106 ], [ %87, %109 ], [ %139, %177 ], [ %139, %195 ], [ %139, %200 ], [ %139, %185 ]
  %209 = phi i32 [ %108, %106 ], [ %79, %109 ], [ %178, %177 ], [ %79, %195 ], [ %79, %200 ], [ %79, %185 ]
  %210 = getelementptr inbounds i64, ptr %0, i64 %17
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef %0, ptr noundef %210, i64 noundef %17) #16
  switch i64 %82, label %214 [
    i64 1, label %211
    i64 0, label %217
  ]

211:                                              ; preds = %207
  %212 = getelementptr inbounds i64, ptr %5, i64 %17
  %213 = tail call i64 @__gmpn_add_n(ptr noundef %212, ptr noundef %212, ptr noundef %210, i64 noundef %17) #16
  br label %217

214:                                              ; preds = %207
  %215 = getelementptr inbounds i64, ptr %5, i64 %17
  %216 = tail call i64 @__gmpn_addmul_1(ptr noundef %215, ptr noundef %210, i64 noundef %17, i64 noundef 2) #16
  br label %217

217:                                              ; preds = %214, %211, %207
  %218 = phi i64 [ %213, %211 ], [ %216, %214 ], [ %82, %207 ]
  %219 = icmp eq i64 %208, 0
  br i1 %219, label %225, label %220

220:                                              ; preds = %217
  %221 = getelementptr inbounds i64, ptr %5, i64 %17
  %222 = tail call i64 @__gmpn_add_n(ptr noundef %221, ptr noundef %221, ptr noundef %0, i64 noundef %17) #16
  %223 = add i64 %218, %82
  %224 = add i64 %223, %222
  br label %225

225:                                              ; preds = %220, %217
  %226 = phi i64 [ %224, %220 ], [ %218, %217 ]
  %227 = getelementptr inbounds i64, ptr %5, i64 %18
  store i64 %226, ptr %227, align 8, !tbaa !15
  %228 = getelementptr inbounds i64, ptr %0, i64 %18
  %229 = mul nsw i64 %17, 3
  %230 = getelementptr inbounds i64, ptr %0, i64 %229
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %228, ptr noundef %230, i64 noundef %17) #16
  %231 = icmp eq i64 %78, 0
  br i1 %231, label %234, label %232

232:                                              ; preds = %225
  %233 = tail call i64 @__gmpn_add_n(ptr noundef %210, ptr noundef %210, ptr noundef %230, i64 noundef %17) #16
  br label %234

234:                                              ; preds = %232, %225
  %235 = phi i64 [ %233, %232 ], [ 0, %225 ]
  store i64 %235, ptr %228, align 8, !tbaa !15
  %236 = icmp eq i32 %209, 0
  %237 = or disjoint i64 %18, 1
  br i1 %236, label %240, label %238

238:                                              ; preds = %234
  %239 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %237) #16
  br label %242

240:                                              ; preds = %234
  %241 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %237) #16
  br label %242

242:                                              ; preds = %240, %238
  %243 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %237, i32 noundef 1) #16
  %244 = load i64, ptr %228, align 8, !tbaa !15
  %245 = getelementptr inbounds i64, ptr %5, i64 %17
  %246 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %228, ptr noundef %5, ptr noundef %245, i64 noundef %17) #16
  %247 = load i64, ptr %227, align 8, !tbaa !15
  %248 = add i64 %247, %246
  %249 = load i64, ptr %245, align 8, !tbaa !15
  %250 = add i64 %249, %248
  store i64 %250, ptr %245, align 8, !tbaa !15
  %251 = load i64, ptr %227, align 8, !tbaa !15
  %252 = add i64 %251, %246
  %253 = icmp ult i64 %250, %252
  br i1 %253, label %254, label %260

254:                                              ; preds = %254, %242
  %255 = phi ptr [ %256, %254 ], [ %245, %242 ]
  %256 = getelementptr inbounds i8, ptr %255, i64 8
  %257 = load i64, ptr %256, align 8, !tbaa !15
  %258 = add i64 %257, 1
  store i64 %258, ptr %256, align 8, !tbaa !15
  %259 = icmp eq i64 %258, 0
  br i1 %259, label %254, label %260, !llvm.loop !63

260:                                              ; preds = %254, %242
  br i1 %236, label %291, label %261

261:                                              ; preds = %260
  %262 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %17) #16
  %263 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %210, i64 noundef %17) #16
  %264 = load i64, ptr %228, align 8, !tbaa !15
  %265 = add i64 %264, %262
  store i64 %265, ptr %228, align 8, !tbaa !15
  %266 = icmp ult i64 %265, %262
  br i1 %266, label %267, label %278

267:                                              ; preds = %261
  %268 = tail call i64 @llvm.smax.i64(i64 %17, i64 1)
  br label %269

269:                                              ; preds = %272, %267
  %270 = phi i64 [ %276, %272 ], [ 1, %267 ]
  %271 = icmp eq i64 %270, %268
  br i1 %271, label %278, label %272

272:                                              ; preds = %269
  %273 = getelementptr inbounds i64, ptr %228, i64 %270
  %274 = load i64, ptr %273, align 8, !tbaa !15
  %275 = add i64 %274, 1
  store i64 %275, ptr %273, align 8, !tbaa !15
  %276 = add nuw nsw i64 %270, 1
  %277 = icmp eq i64 %275, 0
  br i1 %277, label %269, label %278, !llvm.loop !64

278:                                              ; preds = %272, %269, %261
  %279 = phi i64 [ 0, %261 ], [ 1, %269 ], [ 0, %272 ]
  %280 = add i64 %263, %244
  %281 = add i64 %280, %279
  %282 = load i64, ptr %245, align 8, !tbaa !15
  %283 = add i64 %282, %281
  store i64 %283, ptr %245, align 8, !tbaa !15
  %284 = icmp ult i64 %283, %281
  br i1 %284, label %285, label %321

285:                                              ; preds = %285, %278
  %286 = phi ptr [ %287, %285 ], [ %245, %278 ]
  %287 = getelementptr inbounds i8, ptr %286, i64 8
  %288 = load i64, ptr %287, align 8, !tbaa !15
  %289 = add i64 %288, 1
  store i64 %289, ptr %287, align 8, !tbaa !15
  %290 = icmp eq i64 %289, 0
  br i1 %290, label %285, label %321, !llvm.loop !65

291:                                              ; preds = %260
  %292 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %17) #16
  %293 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %210, i64 noundef %17) #16
  %294 = load i64, ptr %228, align 8, !tbaa !15
  %295 = sub i64 %294, %292
  store i64 %295, ptr %228, align 8, !tbaa !15
  %296 = icmp ult i64 %294, %292
  br i1 %296, label %297, label %308

297:                                              ; preds = %291
  %298 = tail call i64 @llvm.smax.i64(i64 %17, i64 1)
  br label %299

299:                                              ; preds = %302, %297
  %300 = phi i64 [ %306, %302 ], [ 1, %297 ]
  %301 = icmp eq i64 %300, %298
  br i1 %301, label %308, label %302

302:                                              ; preds = %299
  %303 = getelementptr inbounds i64, ptr %228, i64 %300
  %304 = load i64, ptr %303, align 8, !tbaa !15
  %305 = add i64 %304, -1
  store i64 %305, ptr %303, align 8, !tbaa !15
  %306 = add nuw nsw i64 %300, 1
  %307 = icmp eq i64 %304, 0
  br i1 %307, label %299, label %308, !llvm.loop !66

308:                                              ; preds = %302, %299, %291
  %309 = phi i64 [ 0, %291 ], [ 1, %299 ], [ 0, %302 ]
  %310 = add i64 %293, %244
  %311 = add i64 %310, %309
  %312 = load i64, ptr %245, align 8, !tbaa !15
  %313 = sub i64 %312, %311
  store i64 %313, ptr %245, align 8, !tbaa !15
  %314 = icmp ult i64 %312, %311
  br i1 %314, label %315, label %321

315:                                              ; preds = %315, %308
  %316 = phi ptr [ %317, %315 ], [ %245, %308 ]
  %317 = getelementptr inbounds i8, ptr %316, i64 8
  %318 = load i64, ptr %317, align 8, !tbaa !15
  %319 = add i64 %318, -1
  store i64 %319, ptr %317, align 8, !tbaa !15
  %320 = icmp eq i64 %318, 0
  br i1 %320, label %315, label %321, !llvm.loop !67

321:                                              ; preds = %315, %308, %285, %278
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %17) #16
  %322 = icmp sgt i64 %19, %20
  %323 = getelementptr inbounds i64, ptr %3, i64 %17
  br i1 %322, label %324, label %326

324:                                              ; preds = %321
  %325 = tail call i64 @__gmpn_mul(ptr noundef %230, ptr noundef %21, i64 noundef %19, ptr noundef %323, i64 noundef %20) #16
  br label %328

326:                                              ; preds = %321
  %327 = tail call i64 @__gmpn_mul(ptr noundef %230, ptr noundef %323, i64 noundef %20, ptr noundef %21, i64 noundef %19) #16
  br label %328

328:                                              ; preds = %326, %324
  %329 = tail call i64 @__gmpn_sub_n(ptr noundef %210, ptr noundef %210, ptr noundef %230, i64 noundef %17) #16
  %330 = load i64, ptr %227, align 8, !tbaa !15
  %331 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %0, i64 noundef %17) #16
  %332 = load i64, ptr %228, align 8, !tbaa !15
  %333 = sub i64 %332, %329
  store i64 %333, ptr %228, align 8, !tbaa !15
  %334 = icmp ult i64 %332, %329
  br i1 %334, label %335, label %346

335:                                              ; preds = %328
  %336 = tail call i64 @llvm.smax.i64(i64 %17, i64 1)
  br label %337

337:                                              ; preds = %340, %335
  %338 = phi i64 [ %344, %340 ], [ 1, %335 ]
  %339 = icmp eq i64 %338, %336
  br i1 %339, label %346, label %340

340:                                              ; preds = %337
  %341 = getelementptr inbounds i64, ptr %228, i64 %338
  %342 = load i64, ptr %341, align 8, !tbaa !15
  %343 = add i64 %342, -1
  store i64 %343, ptr %341, align 8, !tbaa !15
  %344 = add nuw nsw i64 %338, 1
  %345 = icmp eq i64 %342, 0
  br i1 %345, label %337, label %346, !llvm.loop !66

346:                                              ; preds = %340, %337, %328
  %347 = phi i64 [ 0, %328 ], [ 1, %337 ], [ 0, %340 ]
  %348 = add i64 %347, %331
  %349 = tail call i64 @__gmpn_sub_n(ptr noundef %230, ptr noundef nonnull %245, ptr noundef %210, i64 noundef %17) #16
  %350 = load i64, ptr %230, align 8, !tbaa !15
  %351 = sub i64 %350, %348
  store i64 %351, ptr %230, align 8, !tbaa !15
  %352 = icmp ult i64 %350, %348
  br i1 %352, label %353, label %364

353:                                              ; preds = %346
  %354 = tail call i64 @llvm.smax.i64(i64 %17, i64 1)
  br label %355

355:                                              ; preds = %358, %353
  %356 = phi i64 [ %362, %358 ], [ 1, %353 ]
  %357 = icmp eq i64 %356, %354
  br i1 %357, label %364, label %358

358:                                              ; preds = %355
  %359 = getelementptr inbounds i64, ptr %230, i64 %356
  %360 = load i64, ptr %359, align 8, !tbaa !15
  %361 = add i64 %360, -1
  store i64 %361, ptr %359, align 8, !tbaa !15
  %362 = add nuw nsw i64 %356, 1
  %363 = icmp eq i64 %360, 0
  br i1 %363, label %355, label %364, !llvm.loop !66

364:                                              ; preds = %358, %355, %346
  %365 = phi i64 [ 0, %346 ], [ -1, %355 ], [ 0, %358 ]
  %366 = icmp eq i64 %17, 0
  br i1 %366, label %379, label %367

367:                                              ; preds = %364
  %368 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %210, ptr noundef nonnull %210, ptr noundef %5, i64 noundef %17) #16
  %369 = icmp eq i64 %368, 0
  br i1 %369, label %379, label %370

370:                                              ; preds = %373, %367
  %371 = phi i64 [ %377, %373 ], [ %17, %367 ]
  %372 = icmp slt i64 %371, %229
  br i1 %372, label %373, label %379

373:                                              ; preds = %370
  %374 = getelementptr inbounds i64, ptr %210, i64 %371
  %375 = load i64, ptr %374, align 8, !tbaa !15
  %376 = add i64 %375, 1
  %377 = add nsw i64 %371, 1
  store i64 %376, ptr %374, align 8, !tbaa !15
  %378 = icmp eq i64 %376, 0
  br i1 %378, label %370, label %379, !llvm.loop !57

379:                                              ; preds = %373, %370, %367, %364
  %380 = phi i64 [ 0, %367 ], [ 0, %364 ], [ 1, %370 ], [ 0, %373 ]
  %381 = add nsw i64 %19, %20
  %382 = icmp sgt i64 %381, %17
  br i1 %382, label %383, label %416, !prof !68

383:                                              ; preds = %379
  %384 = shl nsw i64 %17, 5
  %385 = getelementptr inbounds i8, ptr %0, i64 %384
  %386 = sub nsw i64 %381, %17
  %387 = icmp eq i64 %386, 0
  br i1 %387, label %400, label %388

388:                                              ; preds = %383
  %389 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %385, i64 noundef %386) #16
  %390 = icmp eq i64 %389, 0
  br i1 %390, label %400, label %391

391:                                              ; preds = %394, %388
  %392 = phi i64 [ %398, %394 ], [ %386, %388 ]
  %393 = icmp slt i64 %392, %18
  br i1 %393, label %394, label %400

394:                                              ; preds = %391
  %395 = getelementptr inbounds i64, ptr %228, i64 %392
  %396 = load i64, ptr %395, align 8, !tbaa !15
  %397 = add i64 %396, -1
  %398 = add nsw i64 %392, 1
  store i64 %397, ptr %395, align 8, !tbaa !15
  %399 = icmp eq i64 %396, 0
  br i1 %399, label %391, label %400, !llvm.loop !61

400:                                              ; preds = %394, %391, %388, %383
  %401 = phi i64 [ 0, %388 ], [ 0, %383 ], [ -1, %391 ], [ 0, %394 ]
  %402 = add i64 %330, %329
  %403 = sub i64 %402, %349
  %404 = add i64 %403, %365
  %405 = add i64 %404, %380
  %406 = add i64 %405, %401
  %407 = load i64, ptr %385, align 8, !tbaa !15
  %408 = add i64 %407, %406
  store i64 %408, ptr %385, align 8, !tbaa !15
  %409 = icmp ult i64 %408, %406
  br i1 %409, label %410, label %416

410:                                              ; preds = %410, %400
  %411 = phi ptr [ %412, %410 ], [ %385, %400 ]
  %412 = getelementptr inbounds i8, ptr %411, i64 8
  %413 = load i64, ptr %412, align 8, !tbaa !15
  %414 = add i64 %413, 1
  store i64 %414, ptr %412, align 8, !tbaa !15
  %415 = icmp eq i64 %414, 0
  br i1 %415, label %410, label %416, !llvm.loop !69

416:                                              ; preds = %410, %400, %379
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom63_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = shl nsw i64 %4, 1
  %8 = icmp sgt i64 %7, %2
  %9 = select i1 %8, i64 %4, i64 %2
  %10 = select i1 %8, i64 3, i64 6
  %11 = add nsw i64 %9, -1
  %12 = udiv i64 %11, %10
  %13 = add nuw nsw i64 %12, 1
  %14 = mul nuw nsw i64 %13, 5
  %15 = sub nsw i64 %2, %14
  %16 = shl nuw nsw i64 %13, 1
  %17 = sub nsw i64 %4, %16
  %18 = getelementptr inbounds i64, ptr %0, i64 %14
  %19 = getelementptr inbounds i8, ptr %18, i64 16
  %20 = mul nuw nsw i64 %13, 3
  %21 = getelementptr inbounds i64, ptr %0, i64 %20
  %22 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %19, ptr noundef nonnull %21, i32 noundef 5, ptr noundef %1, i64 noundef %13, i64 noundef %15, i32 noundef 2, ptr noundef %0) #16
  %23 = getelementptr inbounds i64, ptr %3, i64 %13
  %24 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %23, i64 noundef %13, i32 noundef 2) #16
  %25 = getelementptr inbounds i64, ptr %0, i64 %13
  store i64 %24, ptr %25, align 8, !tbaa !15
  %26 = mul nuw nsw i64 %13, 6
  %27 = getelementptr inbounds i64, ptr %0, i64 %26
  %28 = getelementptr inbounds i8, ptr %27, i64 24
  %29 = getelementptr inbounds i64, ptr %3, i64 %16
  %30 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %28, ptr noundef nonnull %29, i64 noundef %17, i32 noundef 4) #16
  %31 = getelementptr inbounds i64, ptr %28, i64 %17
  store i64 %30, ptr %31, align 8, !tbaa !15
  %32 = icmp eq i64 %13, %17
  br i1 %32, label %33, label %38

33:                                               ; preds = %6
  %34 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %3, i64 noundef %13) #16
  %35 = getelementptr inbounds i64, ptr %28, i64 %13
  %36 = load i64, ptr %35, align 8, !tbaa !15
  %37 = add i64 %36, %34
  store i64 %37, ptr %35, align 8, !tbaa !15
  br label %69

38:                                               ; preds = %6
  %39 = add nsw i64 %17, 1
  %40 = icmp eq i64 %39, 0
  br i1 %40, label %54, label %41

41:                                               ; preds = %38
  %42 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef %3, ptr noundef nonnull %28, i64 noundef %39) #16
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %54, label %44

44:                                               ; preds = %47, %41
  %45 = phi i64 [ %51, %47 ], [ %39, %41 ]
  %46 = icmp sgt i64 %45, %12
  br i1 %46, label %66, label %47

47:                                               ; preds = %44
  %48 = getelementptr inbounds i64, ptr %3, i64 %45
  %49 = load i64, ptr %48, align 8, !tbaa !15
  %50 = add i64 %49, 1
  %51 = add nsw i64 %45, 1
  %52 = getelementptr inbounds i64, ptr %28, i64 %45
  store i64 %50, ptr %52, align 8, !tbaa !15
  %53 = icmp eq i64 %50, 0
  br i1 %53, label %44, label %54, !llvm.loop !70

54:                                               ; preds = %47, %41, %38
  %55 = phi i64 [ %39, %41 ], [ 0, %38 ], [ %51, %47 ]
  %56 = icmp ne ptr %28, %3
  %57 = icmp sle i64 %55, %12
  %58 = select i1 %56, i1 %57, i1 false
  br i1 %58, label %59, label %66

59:                                               ; preds = %59, %54
  %60 = phi i64 [ %64, %59 ], [ %55, %54 ]
  %61 = getelementptr inbounds i64, ptr %3, i64 %60
  %62 = load i64, ptr %61, align 8, !tbaa !15
  %63 = getelementptr inbounds i64, ptr %28, i64 %60
  store i64 %62, ptr %63, align 8, !tbaa !15
  %64 = add nsw i64 %60, 1
  %65 = icmp eq i64 %60, %12
  br i1 %65, label %66, label %59, !llvm.loop !71

66:                                               ; preds = %59, %54, %44
  %67 = phi i64 [ 0, %54 ], [ 0, %59 ], [ 1, %44 ]
  %68 = getelementptr inbounds i64, ptr %28, i64 %13
  store i64 %67, ptr %68, align 8, !tbaa !15
  br label %69

69:                                               ; preds = %66, %33
  %70 = shl nsw i64 %13, 5
  %71 = getelementptr inbounds i8, ptr %0, i64 %70
  %72 = getelementptr inbounds i8, ptr %71, i64 8
  %73 = add nuw nsw i64 %12, 2
  br label %74

74:                                               ; preds = %88, %69
  %75 = phi i64 [ %76, %88 ], [ %73, %69 ]
  %76 = add nsw i64 %75, -1
  %77 = getelementptr inbounds i64, ptr %28, i64 %76
  %78 = load i64, ptr %77, align 8, !tbaa !15
  %79 = getelementptr inbounds i64, ptr %0, i64 %76
  %80 = load i64, ptr %79, align 8, !tbaa !15
  %81 = icmp eq i64 %78, %80
  br i1 %81, label %88, label %82

82:                                               ; preds = %74
  %83 = icmp ugt i64 %78, %80
  br i1 %83, label %84, label %86

84:                                               ; preds = %82
  %85 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %75) #16
  br label %91

86:                                               ; preds = %82
  %87 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef %0, ptr noundef nonnull %28, i64 noundef %75) #16
  br label %91

88:                                               ; preds = %74
  %89 = getelementptr i64, ptr %71, i64 %75
  store i64 0, ptr %89, align 8, !tbaa !15
  %90 = icmp sgt i64 %75, 1
  br i1 %90, label %74, label %91, !llvm.loop !72

91:                                               ; preds = %88, %86, %84
  %92 = phi i32 [ 0, %84 ], [ -1, %86 ], [ 0, %88 ]
  %93 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %73) #16
  %94 = xor i32 %92, %22
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef nonnull %21, ptr noundef nonnull %72, i64 noundef %73) #16
  %95 = getelementptr inbounds i64, ptr %5, i64 %20
  %96 = getelementptr inbounds i8, ptr %95, i64 8
  tail call void @__gmpn_mul_n(ptr noundef nonnull %96, ptr noundef nonnull %19, ptr noundef nonnull %28, i64 noundef %73) #16
  %97 = or disjoint i64 %16, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %96, i64 noundef %97, ptr noundef %0, i32 noundef %94, i64 noundef %13, i32 noundef 2, i32 noundef 4) #16
  %98 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %19, ptr noundef nonnull %21, i32 noundef 5, ptr noundef %1, i64 noundef %13, i64 noundef %15, ptr noundef %0) #16
  %99 = getelementptr inbounds i64, ptr %5, i64 %26
  %100 = getelementptr inbounds i8, ptr %99, i64 16
  %101 = icmp eq i64 %17, 0
  br i1 %101, label %115, label %102

102:                                              ; preds = %91
  %103 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %100, ptr noundef %3, ptr noundef nonnull %29, i64 noundef %17) #16
  %104 = icmp eq i64 %103, 0
  br i1 %104, label %115, label %105

105:                                              ; preds = %108, %102
  %106 = phi i64 [ %112, %108 ], [ %17, %102 ]
  %107 = icmp sgt i64 %106, %12
  br i1 %107, label %127, label %108

108:                                              ; preds = %105
  %109 = getelementptr inbounds i64, ptr %3, i64 %106
  %110 = load i64, ptr %109, align 8, !tbaa !15
  %111 = add i64 %110, 1
  %112 = add nsw i64 %106, 1
  %113 = getelementptr inbounds i64, ptr %100, i64 %106
  store i64 %111, ptr %113, align 8, !tbaa !15
  %114 = icmp eq i64 %111, 0
  br i1 %114, label %105, label %115, !llvm.loop !70

115:                                              ; preds = %108, %102, %91
  %116 = phi i64 [ %17, %102 ], [ 0, %91 ], [ %112, %108 ]
  %117 = icmp ne ptr %100, %3
  %118 = icmp sle i64 %116, %12
  %119 = select i1 %117, i1 %118, i1 false
  br i1 %119, label %120, label %127

120:                                              ; preds = %120, %115
  %121 = phi i64 [ %125, %120 ], [ %116, %115 ]
  %122 = getelementptr inbounds i64, ptr %3, i64 %121
  %123 = load i64, ptr %122, align 8, !tbaa !15
  %124 = getelementptr inbounds i64, ptr %100, i64 %121
  store i64 %123, ptr %124, align 8, !tbaa !15
  %125 = add nsw i64 %121, 1
  %126 = icmp eq i64 %121, %12
  br i1 %126, label %127, label %120, !llvm.loop !71

127:                                              ; preds = %120, %115, %105
  %128 = phi i1 [ true, %115 ], [ true, %120 ], [ false, %105 ]
  %129 = phi i64 [ 0, %115 ], [ 0, %120 ], [ 1, %105 ]
  %130 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %100, ptr noundef nonnull %23, i64 noundef %13) #16
  %131 = add i64 %130, %129
  %132 = getelementptr inbounds i64, ptr %28, i64 %13
  store i64 %131, ptr %132, align 8, !tbaa !15
  br i1 %128, label %133, label %149

133:                                              ; preds = %136, %127
  %134 = phi i64 [ %137, %136 ], [ %13, %127 ]
  %135 = icmp sgt i64 %134, 0
  br i1 %135, label %136, label %149

136:                                              ; preds = %133
  %137 = add nsw i64 %134, -1
  %138 = getelementptr inbounds i64, ptr %100, i64 %137
  %139 = load i64, ptr %138, align 8, !tbaa !15
  %140 = getelementptr inbounds i64, ptr %23, i64 %137
  %141 = load i64, ptr %140, align 8, !tbaa !15
  %142 = icmp eq i64 %139, %141
  br i1 %142, label %133, label %143, !llvm.loop !73

143:                                              ; preds = %136
  %144 = icmp ugt i64 %139, %141
  br i1 %144, label %149, label %145

145:                                              ; preds = %143
  %146 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %23, ptr noundef nonnull %100, i64 noundef %13) #16
  %147 = getelementptr inbounds i64, ptr %72, i64 %13
  store i64 0, ptr %147, align 8, !tbaa !15
  %148 = xor i32 %98, -1
  br label %153

149:                                              ; preds = %143, %133, %127
  %150 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %100, ptr noundef nonnull %23, i64 noundef %13) #16
  %151 = sub i64 %129, %150
  %152 = getelementptr inbounds i64, ptr %72, i64 %13
  store i64 %151, ptr %152, align 8, !tbaa !15
  br label %153

153:                                              ; preds = %149, %145
  %154 = phi i32 [ %148, %145 ], [ %98, %149 ]
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef nonnull %21, ptr noundef nonnull %72, i64 noundef %73) #16
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef nonnull %19, ptr noundef nonnull %28, i64 noundef %73) #16
  tail call void @__gmpn_toom_couple_handling(ptr noundef %5, i64 noundef %97, ptr noundef %0, i32 noundef %154, i64 noundef %13, i32 noundef 0, i32 noundef 0) #16
  %155 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %19, ptr noundef nonnull %21, i32 noundef 5, ptr noundef %1, i64 noundef %13, i64 noundef %15, ptr noundef %0) #16
  %156 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %23, i64 noundef %13, i32 noundef 1) #16
  store i64 %156, ptr %25, align 8, !tbaa !15
  %157 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %28, ptr noundef nonnull %29, i64 noundef %17, i32 noundef 2) #16
  store i64 %157, ptr %31, align 8, !tbaa !15
  br i1 %32, label %158, label %162

158:                                              ; preds = %153
  %159 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %3, i64 noundef %13) #16
  %160 = load i64, ptr %132, align 8, !tbaa !15
  %161 = add i64 %160, %159
  br label %190

162:                                              ; preds = %153
  %163 = add nsw i64 %17, 1
  %164 = icmp eq i64 %163, 0
  br i1 %164, label %178, label %165

165:                                              ; preds = %162
  %166 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef %3, ptr noundef nonnull %28, i64 noundef %163) #16
  %167 = icmp eq i64 %166, 0
  br i1 %167, label %178, label %168

168:                                              ; preds = %171, %165
  %169 = phi i64 [ %175, %171 ], [ %163, %165 ]
  %170 = icmp sgt i64 %169, %12
  br i1 %170, label %190, label %171

171:                                              ; preds = %168
  %172 = getelementptr inbounds i64, ptr %3, i64 %169
  %173 = load i64, ptr %172, align 8, !tbaa !15
  %174 = add i64 %173, 1
  %175 = add nsw i64 %169, 1
  %176 = getelementptr inbounds i64, ptr %28, i64 %169
  store i64 %174, ptr %176, align 8, !tbaa !15
  %177 = icmp eq i64 %174, 0
  br i1 %177, label %168, label %178, !llvm.loop !70

178:                                              ; preds = %171, %165, %162
  %179 = phi i64 [ %163, %165 ], [ 0, %162 ], [ %175, %171 ]
  %180 = icmp ne ptr %28, %3
  %181 = icmp sle i64 %179, %12
  %182 = select i1 %180, i1 %181, i1 false
  br i1 %182, label %183, label %190

183:                                              ; preds = %183, %178
  %184 = phi i64 [ %188, %183 ], [ %179, %178 ]
  %185 = getelementptr inbounds i64, ptr %3, i64 %184
  %186 = load i64, ptr %185, align 8, !tbaa !15
  %187 = getelementptr inbounds i64, ptr %28, i64 %184
  store i64 %186, ptr %187, align 8, !tbaa !15
  %188 = add nsw i64 %184, 1
  %189 = icmp eq i64 %184, %12
  br i1 %189, label %190, label %183, !llvm.loop !71

190:                                              ; preds = %183, %178, %168, %158
  %191 = phi i64 [ %161, %158 ], [ 0, %178 ], [ 0, %183 ], [ 1, %168 ]
  store i64 %191, ptr %132, align 8, !tbaa !15
  br label %192

192:                                              ; preds = %206, %190
  %193 = phi i64 [ %194, %206 ], [ %73, %190 ]
  %194 = add nsw i64 %193, -1
  %195 = getelementptr inbounds i64, ptr %28, i64 %194
  %196 = load i64, ptr %195, align 8, !tbaa !15
  %197 = getelementptr inbounds i64, ptr %0, i64 %194
  %198 = load i64, ptr %197, align 8, !tbaa !15
  %199 = icmp eq i64 %196, %198
  br i1 %199, label %206, label %200

200:                                              ; preds = %192
  %201 = icmp ugt i64 %196, %198
  br i1 %201, label %202, label %204

202:                                              ; preds = %200
  %203 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %193) #16
  br label %209

204:                                              ; preds = %200
  %205 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef %0, ptr noundef nonnull %28, i64 noundef %193) #16
  br label %209

206:                                              ; preds = %192
  %207 = getelementptr i64, ptr %71, i64 %193
  store i64 0, ptr %207, align 8, !tbaa !15
  %208 = icmp sgt i64 %193, 1
  br i1 %208, label %192, label %209, !llvm.loop !72

209:                                              ; preds = %206, %204, %202
  %210 = phi i32 [ 0, %202 ], [ -1, %204 ], [ 0, %206 ]
  %211 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %73) #16
  %212 = xor i32 %210, %155
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef nonnull %21, ptr noundef nonnull %72, i64 noundef %73) #16
  tail call void @__gmpn_mul_n(ptr noundef nonnull %21, ptr noundef nonnull %19, ptr noundef nonnull %28, i64 noundef %73) #16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %21, i64 noundef %97, ptr noundef %0, i32 noundef %212, i64 noundef %13, i32 noundef 1, i32 noundef 2) #16
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %13) #16
  %213 = icmp sgt i64 %15, %17
  %214 = mul i64 %13, 56
  %215 = getelementptr inbounds i8, ptr %0, i64 %214
  %216 = getelementptr inbounds i64, ptr %1, i64 %14
  br i1 %213, label %217, label %219

217:                                              ; preds = %209
  %218 = tail call i64 @__gmpn_mul(ptr noundef %215, ptr noundef nonnull %216, i64 noundef %15, ptr noundef nonnull %29, i64 noundef %17) #16
  br label %221

219:                                              ; preds = %209
  %220 = tail call i64 @__gmpn_mul(ptr noundef %215, ptr noundef nonnull %29, i64 noundef %17, ptr noundef nonnull %216, i64 noundef %15) #16
  br label %221

221:                                              ; preds = %219, %217
  %222 = add nsw i64 %15, %17
  tail call void @__gmpn_toom_interpolate_8pts(ptr noundef %0, i64 noundef %13, ptr noundef nonnull %96, ptr noundef %5, i64 noundef %222, ptr noundef nonnull %100) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = add nsw i64 %2, 2
  %8 = udiv i64 %7, 3
  %9 = shl nuw nsw i64 %8, 1
  %10 = sub nsw i64 %2, %9
  %11 = sub nsw i64 %4, %9
  %12 = shl nsw i64 %8, 2
  %13 = getelementptr inbounds i64, ptr %5, i64 %12
  %14 = getelementptr inbounds i8, ptr %13, i64 32
  %15 = getelementptr inbounds i64, ptr %5, i64 %9
  %16 = getelementptr inbounds i8, ptr %15, i64 16
  %17 = getelementptr inbounds i64, ptr %0, i64 %8
  %18 = getelementptr inbounds i8, ptr %17, i64 8
  %19 = mul i64 %8, 24
  %20 = getelementptr inbounds i8, ptr %5, i64 %19
  %21 = getelementptr inbounds i8, ptr %20, i64 24
  %22 = getelementptr inbounds i64, ptr %0, i64 %9
  %23 = getelementptr inbounds i8, ptr %22, i64 16
  %24 = getelementptr inbounds i64, ptr %1, i64 %9
  %25 = icmp eq i64 %10, 0
  br i1 %25, label %39, label %26

26:                                               ; preds = %6
  %27 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %1, ptr noundef %24, i64 noundef %10) #16
  %28 = icmp eq i64 %27, 0
  br i1 %28, label %39, label %29

29:                                               ; preds = %32, %26
  %30 = phi i64 [ %36, %32 ], [ %10, %26 ]
  %31 = icmp slt i64 %30, %8
  br i1 %31, label %32, label %51

32:                                               ; preds = %29
  %33 = getelementptr inbounds i64, ptr %1, i64 %30
  %34 = load i64, ptr %33, align 8, !tbaa !15
  %35 = add i64 %34, 1
  %36 = add nsw i64 %30, 1
  %37 = getelementptr inbounds i64, ptr %5, i64 %30
  store i64 %35, ptr %37, align 8, !tbaa !15
  %38 = icmp eq i64 %35, 0
  br i1 %38, label %29, label %39, !llvm.loop !74

39:                                               ; preds = %32, %26, %6
  %40 = phi i64 [ %10, %26 ], [ 0, %6 ], [ %36, %32 ]
  %41 = icmp ne ptr %5, %1
  %42 = icmp slt i64 %40, %8
  %43 = select i1 %41, i1 %42, i1 false
  br i1 %43, label %44, label %51

44:                                               ; preds = %44, %39
  %45 = phi i64 [ %49, %44 ], [ %40, %39 ]
  %46 = getelementptr inbounds i64, ptr %1, i64 %45
  %47 = load i64, ptr %46, align 8, !tbaa !15
  %48 = getelementptr inbounds i64, ptr %5, i64 %45
  store i64 %47, ptr %48, align 8, !tbaa !15
  %49 = add nsw i64 %45, 1
  %50 = icmp eq i64 %49, %8
  br i1 %50, label %51, label %44, !llvm.loop !75

51:                                               ; preds = %44, %39, %29
  %52 = phi i1 [ true, %39 ], [ true, %44 ], [ false, %29 ]
  %53 = phi i64 [ 0, %39 ], [ 0, %44 ], [ 1, %29 ]
  %54 = getelementptr inbounds i64, ptr %1, i64 %8
  %55 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %14, ptr noundef %5, ptr noundef %54, i64 noundef %8) #16
  %56 = add i64 %55, %53
  %57 = getelementptr inbounds i64, ptr %14, i64 %8
  store i64 %56, ptr %57, align 8, !tbaa !15
  br i1 %52, label %58, label %76

58:                                               ; preds = %61, %51
  %59 = phi i64 [ %62, %61 ], [ %8, %51 ]
  %60 = icmp sgt i64 %59, 0
  br i1 %60, label %61, label %71

61:                                               ; preds = %58
  %62 = add nsw i64 %59, -1
  %63 = getelementptr inbounds i64, ptr %5, i64 %62
  %64 = load i64, ptr %63, align 8, !tbaa !15
  %65 = getelementptr inbounds i64, ptr %54, i64 %62
  %66 = load i64, ptr %65, align 8, !tbaa !15
  %67 = icmp eq i64 %64, %66
  br i1 %67, label %58, label %68, !llvm.loop !76

68:                                               ; preds = %61
  %69 = icmp ugt i64 %64, %66
  %70 = select i1 %69, i32 1, i32 -1
  br label %71

71:                                               ; preds = %68, %58
  %72 = phi i32 [ %70, %68 ], [ 0, %58 ]
  %73 = icmp slt i32 %72, 0
  br i1 %73, label %74, label %76

74:                                               ; preds = %71
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %16, ptr noundef %54, ptr noundef %5, i64 noundef %8) #16
  br label %79

76:                                               ; preds = %71, %51
  %77 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %16, ptr noundef %5, ptr noundef %54, i64 noundef %8) #16
  %78 = sub i64 %53, %77
  br label %79

79:                                               ; preds = %76, %74
  %80 = phi i64 [ %78, %76 ], [ 0, %74 ]
  %81 = phi i32 [ 0, %76 ], [ 1, %74 ]
  %82 = getelementptr inbounds i64, ptr %16, i64 %8
  store i64 %80, ptr %82, align 8, !tbaa !15
  %83 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %18, ptr noundef %24, ptr noundef nonnull %14, i64 noundef %10) #16
  %84 = icmp eq i64 %10, %8
  br i1 %84, label %126, label %85

85:                                               ; preds = %79
  %86 = getelementptr inbounds i64, ptr %18, i64 %10
  %87 = getelementptr inbounds i64, ptr %14, i64 %10
  %88 = sub nsw i64 %8, %10
  %89 = load i64, ptr %87, align 8, !tbaa !15
  %90 = add i64 %89, %83
  store i64 %90, ptr %86, align 8, !tbaa !15
  %91 = icmp ult i64 %90, %83
  br i1 %91, label %92, label %115

92:                                               ; preds = %85
  %93 = tail call i64 @llvm.smax.i64(i64 %88, i64 1)
  br label %94

94:                                               ; preds = %97, %92
  %95 = phi i64 [ %102, %97 ], [ 1, %92 ]
  %96 = icmp eq i64 %95, %93
  br i1 %96, label %126, label %97

97:                                               ; preds = %94
  %98 = getelementptr inbounds i64, ptr %87, i64 %95
  %99 = load i64, ptr %98, align 8, !tbaa !15
  %100 = add i64 %99, 1
  %101 = getelementptr inbounds i64, ptr %86, i64 %95
  store i64 %100, ptr %101, align 8, !tbaa !15
  %102 = add nuw i64 %95, 1
  %103 = icmp eq i64 %100, 0
  br i1 %103, label %94, label %104, !llvm.loop !77

104:                                              ; preds = %97
  %105 = icmp ne ptr %14, %18
  %106 = icmp slt i64 %102, %88
  %107 = select i1 %105, i1 %106, i1 false
  br i1 %107, label %108, label %126

108:                                              ; preds = %108, %104
  %109 = phi i64 [ %113, %108 ], [ %102, %104 ]
  %110 = getelementptr inbounds i64, ptr %87, i64 %109
  %111 = load i64, ptr %110, align 8, !tbaa !15
  %112 = getelementptr inbounds i64, ptr %86, i64 %109
  store i64 %111, ptr %112, align 8, !tbaa !15
  %113 = add nuw nsw i64 %109, 1
  %114 = icmp slt i64 %113, %88
  br i1 %114, label %108, label %126, !llvm.loop !78

115:                                              ; preds = %85
  %116 = icmp ne ptr %14, %18
  %117 = icmp sgt i64 %88, 1
  %118 = and i1 %116, %117
  br i1 %118, label %119, label %126

119:                                              ; preds = %119, %115
  %120 = phi i64 [ %124, %119 ], [ 1, %115 ]
  %121 = getelementptr inbounds i64, ptr %87, i64 %120
  %122 = load i64, ptr %121, align 8, !tbaa !15
  %123 = getelementptr inbounds i64, ptr %86, i64 %120
  store i64 %122, ptr %123, align 8, !tbaa !15
  %124 = add nuw nsw i64 %120, 1
  %125 = icmp eq i64 %124, %88
  br i1 %125, label %126, label %119, !llvm.loop !79

126:                                              ; preds = %119, %115, %108, %104, %94, %79
  %127 = phi i64 [ %83, %79 ], [ 0, %104 ], [ 0, %115 ], [ 0, %108 ], [ 1, %94 ], [ 0, %119 ]
  %128 = load i64, ptr %57, align 8, !tbaa !15
  %129 = add i64 %128, %127
  %130 = shl i64 %129, 1
  %131 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %18, ptr noundef nonnull %18, i64 noundef %8, i32 noundef 1) #16
  %132 = add i64 %130, %131
  %133 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %18, ptr noundef nonnull %18, ptr noundef %1, i64 noundef %8) #16
  %134 = sub i64 %132, %133
  %135 = getelementptr inbounds i64, ptr %18, i64 %8
  store i64 %134, ptr %135, align 8, !tbaa !15
  %136 = getelementptr inbounds i64, ptr %3, i64 %9
  %137 = icmp eq i64 %11, 0
  br i1 %137, label %151, label %138

138:                                              ; preds = %126
  %139 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %3, ptr noundef %136, i64 noundef %11) #16
  %140 = icmp eq i64 %139, 0
  br i1 %140, label %151, label %141

141:                                              ; preds = %144, %138
  %142 = phi i64 [ %148, %144 ], [ %11, %138 ]
  %143 = icmp slt i64 %142, %8
  br i1 %143, label %144, label %163

144:                                              ; preds = %141
  %145 = getelementptr inbounds i64, ptr %3, i64 %142
  %146 = load i64, ptr %145, align 8, !tbaa !15
  %147 = add i64 %146, 1
  %148 = add nsw i64 %142, 1
  %149 = getelementptr inbounds i64, ptr %5, i64 %142
  store i64 %147, ptr %149, align 8, !tbaa !15
  %150 = icmp eq i64 %147, 0
  br i1 %150, label %141, label %151, !llvm.loop !74

151:                                              ; preds = %144, %138, %126
  %152 = phi i64 [ %11, %138 ], [ 0, %126 ], [ %148, %144 ]
  %153 = icmp ne ptr %5, %3
  %154 = icmp slt i64 %152, %8
  %155 = select i1 %153, i1 %154, i1 false
  br i1 %155, label %156, label %163

156:                                              ; preds = %156, %151
  %157 = phi i64 [ %161, %156 ], [ %152, %151 ]
  %158 = getelementptr inbounds i64, ptr %3, i64 %157
  %159 = load i64, ptr %158, align 8, !tbaa !15
  %160 = getelementptr inbounds i64, ptr %5, i64 %157
  store i64 %159, ptr %160, align 8, !tbaa !15
  %161 = add nsw i64 %157, 1
  %162 = icmp eq i64 %161, %8
  br i1 %162, label %163, label %156, !llvm.loop !75

163:                                              ; preds = %156, %151, %141
  %164 = phi i1 [ true, %151 ], [ true, %156 ], [ false, %141 ]
  %165 = phi i64 [ 0, %151 ], [ 0, %156 ], [ 1, %141 ]
  %166 = getelementptr inbounds i64, ptr %3, i64 %8
  %167 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %5, ptr noundef %166, i64 noundef %8) #16
  %168 = add i64 %167, %165
  store i64 %168, ptr %17, align 8, !tbaa !15
  br i1 %164, label %169, label %185

169:                                              ; preds = %172, %163
  %170 = phi i64 [ %173, %172 ], [ %8, %163 ]
  %171 = icmp sgt i64 %170, 0
  br i1 %171, label %172, label %185

172:                                              ; preds = %169
  %173 = add nsw i64 %170, -1
  %174 = getelementptr inbounds i64, ptr %5, i64 %173
  %175 = load i64, ptr %174, align 8, !tbaa !15
  %176 = getelementptr inbounds i64, ptr %166, i64 %173
  %177 = load i64, ptr %176, align 8, !tbaa !15
  %178 = icmp eq i64 %175, %177
  br i1 %178, label %169, label %179, !llvm.loop !76

179:                                              ; preds = %172
  %180 = icmp ugt i64 %175, %177
  br i1 %180, label %185, label %181

181:                                              ; preds = %179
  %182 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %21, ptr noundef %166, ptr noundef %5, i64 noundef %8) #16
  %183 = getelementptr inbounds i64, ptr %21, i64 %8
  store i64 0, ptr %183, align 8, !tbaa !15
  %184 = xor i32 %81, 1
  br label %189

185:                                              ; preds = %179, %169, %163
  %186 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %21, ptr noundef %5, ptr noundef %166, i64 noundef %8) #16
  %187 = sub i64 %165, %186
  %188 = getelementptr inbounds i64, ptr %21, i64 %8
  store i64 %187, ptr %188, align 8, !tbaa !15
  br label %189

189:                                              ; preds = %185, %181
  %190 = phi i32 [ %184, %181 ], [ %81, %185 ]
  %191 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %23, ptr noundef %0, ptr noundef %136, i64 noundef %11) #16
  %192 = icmp eq i64 %11, %8
  br i1 %192, label %234, label %193

193:                                              ; preds = %189
  %194 = getelementptr inbounds i64, ptr %23, i64 %11
  %195 = getelementptr inbounds i64, ptr %0, i64 %11
  %196 = sub nsw i64 %8, %11
  %197 = load i64, ptr %195, align 8, !tbaa !15
  %198 = add i64 %197, %191
  store i64 %198, ptr %194, align 8, !tbaa !15
  %199 = icmp ult i64 %198, %191
  br i1 %199, label %200, label %223

200:                                              ; preds = %193
  %201 = tail call i64 @llvm.smax.i64(i64 %196, i64 1)
  br label %202

202:                                              ; preds = %205, %200
  %203 = phi i64 [ %210, %205 ], [ 1, %200 ]
  %204 = icmp eq i64 %203, %201
  br i1 %204, label %234, label %205

205:                                              ; preds = %202
  %206 = getelementptr inbounds i64, ptr %195, i64 %203
  %207 = load i64, ptr %206, align 8, !tbaa !15
  %208 = add i64 %207, 1
  %209 = getelementptr inbounds i64, ptr %194, i64 %203
  store i64 %208, ptr %209, align 8, !tbaa !15
  %210 = add nuw i64 %203, 1
  %211 = icmp eq i64 %208, 0
  br i1 %211, label %202, label %212, !llvm.loop !77

212:                                              ; preds = %205
  %213 = icmp ne ptr %23, %0
  %214 = icmp slt i64 %210, %196
  %215 = select i1 %213, i1 %214, i1 false
  br i1 %215, label %216, label %234

216:                                              ; preds = %216, %212
  %217 = phi i64 [ %221, %216 ], [ %210, %212 ]
  %218 = getelementptr inbounds i64, ptr %195, i64 %217
  %219 = load i64, ptr %218, align 8, !tbaa !15
  %220 = getelementptr inbounds i64, ptr %194, i64 %217
  store i64 %219, ptr %220, align 8, !tbaa !15
  %221 = add nuw nsw i64 %217, 1
  %222 = icmp slt i64 %221, %196
  br i1 %222, label %216, label %234, !llvm.loop !78

223:                                              ; preds = %193
  %224 = icmp ne ptr %23, %0
  %225 = icmp sgt i64 %196, 1
  %226 = and i1 %224, %225
  br i1 %226, label %227, label %234

227:                                              ; preds = %227, %223
  %228 = phi i64 [ %232, %227 ], [ 1, %223 ]
  %229 = getelementptr inbounds i64, ptr %195, i64 %228
  %230 = load i64, ptr %229, align 8, !tbaa !15
  %231 = getelementptr inbounds i64, ptr %194, i64 %228
  store i64 %230, ptr %231, align 8, !tbaa !15
  %232 = add nuw nsw i64 %228, 1
  %233 = icmp eq i64 %232, %196
  br i1 %233, label %234, label %227, !llvm.loop !79

234:                                              ; preds = %227, %223, %216, %212, %202, %189
  %235 = phi i64 [ %191, %189 ], [ 0, %212 ], [ 0, %223 ], [ 0, %216 ], [ 1, %202 ], [ 0, %227 ]
  %236 = load i64, ptr %17, align 8, !tbaa !15
  %237 = add i64 %236, %235
  %238 = shl i64 %237, 1
  %239 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %23, ptr noundef nonnull %23, i64 noundef %8, i32 noundef 1) #16
  %240 = add i64 %238, %239
  %241 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %23, ptr noundef nonnull %23, ptr noundef %3, i64 noundef %8) #16
  %242 = sub i64 %240, %241
  %243 = getelementptr inbounds i64, ptr %23, i64 %8
  store i64 %242, ptr %243, align 8, !tbaa !15
  store i64 0, ptr %15, align 8, !tbaa !15
  %244 = getelementptr inbounds i64, ptr %21, i64 %8
  %245 = load i64, ptr %244, align 8, !tbaa !15
  %246 = getelementptr inbounds i64, ptr %16, i64 %8
  %247 = load i64, ptr %246, align 8, !tbaa !15
  %248 = or i64 %247, %245
  %249 = add i64 %248, %8
  %250 = icmp ugt i64 %249, 99
  %251 = mul i64 %8, 40
  %252 = getelementptr inbounds i8, ptr %5, i64 %251
  %253 = getelementptr inbounds i8, ptr %252, i64 40
  br i1 %250, label %255, label %254

254:                                              ; preds = %234
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef nonnull %16, i64 noundef %249, ptr noundef nonnull %21, i64 noundef %249, ptr noundef nonnull %253) #16
  br label %256

255:                                              ; preds = %234
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef nonnull %16, i64 noundef %249, ptr noundef nonnull %21, i64 noundef %249, ptr noundef nonnull %253)
  br label %256

256:                                              ; preds = %255, %254
  %257 = add nuw nsw i64 %8, 1
  %258 = icmp ugt i64 %7, 296
  %259 = getelementptr inbounds i8, ptr %15, i64 8
  %260 = mul i64 %8, 40
  %261 = getelementptr inbounds i8, ptr %5, i64 %260
  %262 = getelementptr inbounds i8, ptr %261, i64 40
  br i1 %258, label %264, label %263

263:                                              ; preds = %256
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %259, ptr noundef nonnull %18, i64 noundef %257, ptr noundef nonnull %23, i64 noundef %257, ptr noundef nonnull %262) #16
  br label %265

264:                                              ; preds = %256
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %259, ptr noundef nonnull %18, i64 noundef %257, ptr noundef nonnull %23, i64 noundef %257, ptr noundef nonnull %262)
  br label %265

265:                                              ; preds = %264, %263
  %266 = icmp sgt i64 %2, %4
  br i1 %266, label %267, label %270

267:                                              ; preds = %265
  %268 = getelementptr inbounds i64, ptr %0, i64 %12
  %269 = tail call i64 @__gmpn_mul(ptr noundef %268, ptr noundef %24, i64 noundef %10, ptr noundef %136, i64 noundef %11) #16
  br label %278

270:                                              ; preds = %265
  %271 = icmp sgt i64 %10, 99
  %272 = getelementptr inbounds i64, ptr %0, i64 %12
  %273 = mul i64 %8, 40
  %274 = getelementptr inbounds i8, ptr %5, i64 %273
  %275 = getelementptr inbounds i8, ptr %274, i64 40
  br i1 %271, label %277, label %276

276:                                              ; preds = %270
  tail call void @__gmpn_toom22_mul(ptr noundef %272, ptr noundef %24, i64 noundef %10, ptr noundef %136, i64 noundef %10, ptr noundef nonnull %275) #16
  br label %278

277:                                              ; preds = %270
  tail call void @__gmpn_toom33_mul(ptr noundef %272, ptr noundef %24, i64 noundef %10, ptr noundef %136, i64 noundef %10, ptr noundef nonnull %275)
  br label %278

278:                                              ; preds = %277, %276, %267
  %279 = getelementptr inbounds i64, ptr %0, i64 %12
  %280 = load i64, ptr %279, align 8, !tbaa !15
  %281 = getelementptr inbounds i8, ptr %279, i64 8
  %282 = load i64, ptr %281, align 8, !tbaa !15
  %283 = mul i64 %8, 40
  %284 = getelementptr inbounds i8, ptr %5, i64 %283
  %285 = getelementptr inbounds i8, ptr %284, i64 40
  br i1 %258, label %287, label %286

286:                                              ; preds = %278
  tail call void @__gmpn_toom22_mul(ptr noundef %22, ptr noundef nonnull %14, i64 noundef %257, ptr noundef %0, i64 noundef %257, ptr noundef nonnull %285) #16
  br label %288

287:                                              ; preds = %278
  tail call void @__gmpn_toom33_mul(ptr noundef %22, ptr noundef nonnull %14, i64 noundef %257, ptr noundef %0, i64 noundef %257, ptr noundef nonnull %285)
  br label %288

288:                                              ; preds = %287, %286
  store i64 %282, ptr %281, align 8, !tbaa !15
  %289 = icmp ugt i64 %7, 299
  %290 = mul i64 %8, 40
  %291 = getelementptr inbounds i8, ptr %5, i64 %290
  %292 = getelementptr inbounds i8, ptr %291, i64 40
  br i1 %289, label %294, label %293

293:                                              ; preds = %288
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %292) #16
  br label %295

294:                                              ; preds = %288
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %292)
  br label %295

295:                                              ; preds = %294, %293
  %296 = getelementptr inbounds i8, ptr %15, i64 8
  %297 = add nsw i64 %10, %11
  tail call void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef nonnull %296, ptr noundef %5, i64 noundef %8, i64 noundef %297, i32 noundef %190, i64 noundef %280) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom43_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = mul nsw i64 %2, 3
  %8 = shl nsw i64 %4, 2
  %9 = icmp slt i64 %7, %8
  br i1 %9, label %13, label %10

10:                                               ; preds = %6
  %11 = add nsw i64 %2, -1
  %12 = ashr i64 %11, 2
  br label %16

13:                                               ; preds = %6
  %14 = add nsw i64 %4, -1
  %15 = udiv i64 %14, 3
  br label %16

16:                                               ; preds = %13, %10
  %17 = phi i64 [ %12, %10 ], [ %15, %13 ]
  %18 = add nsw i64 %17, 1
  %19 = mul nsw i64 %18, 3
  %20 = sub nsw i64 %2, %19
  %21 = shl nsw i64 %18, 1
  %22 = sub nsw i64 %4, %21
  %23 = getelementptr inbounds i64, ptr %0, i64 %19
  %24 = getelementptr inbounds i8, ptr %23, i64 24
  %25 = shl nsw i64 %18, 2
  %26 = getelementptr inbounds i64, ptr %5, i64 %25
  %27 = getelementptr inbounds i8, ptr %26, i64 32
  %28 = getelementptr inbounds i64, ptr %5, i64 %19
  %29 = getelementptr inbounds i8, ptr %28, i64 24
  %30 = tail call i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef nonnull %24, ptr noundef nonnull %27, ptr noundef %1, i64 noundef %18, i64 noundef %20, ptr noundef nonnull %29) #16
  %31 = and i32 %30, 2
  %32 = getelementptr inbounds i64, ptr %5, i64 %21
  %33 = getelementptr inbounds i8, ptr %32, i64 16
  %34 = getelementptr inbounds i64, ptr %3, i64 %18
  %35 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %33, ptr noundef %34, i64 noundef %18, i32 noundef 1) #16
  %36 = getelementptr inbounds i64, ptr %33, i64 %18
  store i64 %35, ptr %36, align 8, !tbaa !15
  %37 = getelementptr inbounds i64, ptr %3, i64 %21
  %38 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %37, i64 noundef %22, i32 noundef 2) #16
  %39 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %5, ptr noundef %3, i64 noundef %22) #16
  %40 = add i64 %39, %38
  %41 = icmp eq i64 %22, %18
  br i1 %41, label %83, label %42

42:                                               ; preds = %16
  %43 = getelementptr inbounds i64, ptr %5, i64 %22
  %44 = getelementptr inbounds i64, ptr %3, i64 %22
  %45 = sub nsw i64 %18, %22
  %46 = load i64, ptr %44, align 8, !tbaa !15
  %47 = add i64 %46, %40
  store i64 %47, ptr %43, align 8, !tbaa !15
  %48 = icmp ult i64 %47, %40
  br i1 %48, label %49, label %72

49:                                               ; preds = %42
  %50 = tail call i64 @llvm.smax.i64(i64 %45, i64 1)
  br label %51

51:                                               ; preds = %54, %49
  %52 = phi i64 [ %59, %54 ], [ 1, %49 ]
  %53 = icmp eq i64 %52, %50
  br i1 %53, label %83, label %54

54:                                               ; preds = %51
  %55 = getelementptr inbounds i64, ptr %44, i64 %52
  %56 = load i64, ptr %55, align 8, !tbaa !15
  %57 = add i64 %56, 1
  %58 = getelementptr inbounds i64, ptr %43, i64 %52
  store i64 %57, ptr %58, align 8, !tbaa !15
  %59 = add nuw i64 %52, 1
  %60 = icmp eq i64 %57, 0
  br i1 %60, label %51, label %61, !llvm.loop !80

61:                                               ; preds = %54
  %62 = icmp ne ptr %3, %5
  %63 = icmp slt i64 %59, %45
  %64 = select i1 %62, i1 %63, i1 false
  br i1 %64, label %65, label %83

65:                                               ; preds = %65, %61
  %66 = phi i64 [ %70, %65 ], [ %59, %61 ]
  %67 = getelementptr inbounds i64, ptr %44, i64 %66
  %68 = load i64, ptr %67, align 8, !tbaa !15
  %69 = getelementptr inbounds i64, ptr %43, i64 %66
  store i64 %68, ptr %69, align 8, !tbaa !15
  %70 = add nuw nsw i64 %66, 1
  %71 = icmp slt i64 %70, %45
  br i1 %71, label %65, label %83, !llvm.loop !81

72:                                               ; preds = %42
  %73 = icmp ne ptr %3, %5
  %74 = icmp sgt i64 %45, 1
  %75 = and i1 %73, %74
  br i1 %75, label %76, label %83

76:                                               ; preds = %76, %72
  %77 = phi i64 [ %81, %76 ], [ 1, %72 ]
  %78 = getelementptr inbounds i64, ptr %44, i64 %77
  %79 = load i64, ptr %78, align 8, !tbaa !15
  %80 = getelementptr inbounds i64, ptr %43, i64 %77
  store i64 %79, ptr %80, align 8, !tbaa !15
  %81 = add nuw nsw i64 %77, 1
  %82 = icmp eq i64 %81, %45
  br i1 %82, label %83, label %76, !llvm.loop !82

83:                                               ; preds = %76, %72, %65, %61, %51, %16
  %84 = phi i64 [ %40, %16 ], [ 0, %61 ], [ 0, %72 ], [ 0, %65 ], [ 1, %51 ], [ 0, %76 ]
  %85 = getelementptr inbounds i64, ptr %5, i64 %18
  store i64 %84, ptr %85, align 8, !tbaa !15
  %86 = getelementptr inbounds i64, ptr %0, i64 %21
  %87 = getelementptr inbounds i8, ptr %86, i64 16
  %88 = add nsw i64 %17, 2
  %89 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %87, ptr noundef %5, ptr noundef nonnull %33, i64 noundef %88) #16
  br label %90

90:                                               ; preds = %93, %83
  %91 = phi i64 [ %88, %83 ], [ %94, %93 ]
  %92 = icmp sgt i64 %91, 0
  br i1 %92, label %93, label %107

93:                                               ; preds = %90
  %94 = add nsw i64 %91, -1
  %95 = getelementptr inbounds i64, ptr %5, i64 %94
  %96 = load i64, ptr %95, align 8, !tbaa !15
  %97 = getelementptr inbounds i64, ptr %33, i64 %94
  %98 = load i64, ptr %97, align 8, !tbaa !15
  %99 = icmp eq i64 %96, %98
  br i1 %99, label %90, label %100, !llvm.loop !83

100:                                              ; preds = %93
  %101 = icmp ugt i64 %96, %98
  br i1 %101, label %107, label %102

102:                                              ; preds = %100
  %103 = getelementptr inbounds i64, ptr %0, i64 %18
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %104, ptr noundef nonnull %33, ptr noundef %5, i64 noundef %88) #16
  %106 = xor i32 %31, 2
  br label %111

107:                                              ; preds = %100, %90
  %108 = getelementptr inbounds i64, ptr %0, i64 %18
  %109 = getelementptr inbounds i8, ptr %108, i64 8
  %110 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %109, ptr noundef %5, ptr noundef nonnull %33, i64 noundef %88) #16
  br label %111

111:                                              ; preds = %107, %102
  %112 = phi i32 [ %106, %102 ], [ %31, %107 ]
  %113 = getelementptr inbounds i64, ptr %0, i64 %25
  %114 = getelementptr inbounds i8, ptr %113, i64 32
  %115 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %114, ptr noundef nonnull %29, ptr noundef %1, i64 noundef %18, i64 noundef %20, ptr noundef %5) #16
  %116 = and i32 %115, 1
  %117 = xor i32 %116, %112
  %118 = icmp eq i64 %22, 0
  br i1 %118, label %132, label %119

119:                                              ; preds = %111
  %120 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %33, ptr noundef %3, ptr noundef %37, i64 noundef %22) #16
  %121 = icmp eq i64 %120, 0
  br i1 %121, label %132, label %122

122:                                              ; preds = %125, %119
  %123 = phi i64 [ %129, %125 ], [ %22, %119 ]
  %124 = icmp sgt i64 %123, %17
  br i1 %124, label %144, label %125

125:                                              ; preds = %122
  %126 = getelementptr inbounds i64, ptr %3, i64 %123
  %127 = load i64, ptr %126, align 8, !tbaa !15
  %128 = add i64 %127, 1
  %129 = add nsw i64 %123, 1
  %130 = getelementptr inbounds i64, ptr %33, i64 %123
  store i64 %128, ptr %130, align 8, !tbaa !15
  %131 = icmp eq i64 %128, 0
  br i1 %131, label %122, label %132, !llvm.loop !84

132:                                              ; preds = %125, %119, %111
  %133 = phi i64 [ %22, %119 ], [ 0, %111 ], [ %129, %125 ]
  %134 = icmp ne ptr %33, %3
  %135 = icmp sle i64 %133, %17
  %136 = select i1 %134, i1 %135, i1 false
  br i1 %136, label %137, label %144

137:                                              ; preds = %137, %132
  %138 = phi i64 [ %142, %137 ], [ %133, %132 ]
  %139 = getelementptr inbounds i64, ptr %3, i64 %138
  %140 = load i64, ptr %139, align 8, !tbaa !15
  %141 = getelementptr inbounds i64, ptr %33, i64 %138
  store i64 %140, ptr %141, align 8, !tbaa !15
  %142 = add nsw i64 %138, 1
  %143 = icmp eq i64 %138, %17
  br i1 %143, label %144, label %137, !llvm.loop !85

144:                                              ; preds = %137, %132, %122
  %145 = phi i64 [ 0, %132 ], [ 0, %137 ], [ 1, %122 ]
  store i64 %145, ptr %36, align 8, !tbaa !15
  %146 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef nonnull %33, ptr noundef %34, i64 noundef %18) #16
  %147 = add i64 %146, %145
  %148 = getelementptr inbounds i64, ptr %0, i64 %18
  store i64 %147, ptr %148, align 8, !tbaa !15
  %149 = load i64, ptr %36, align 8, !tbaa !15
  %150 = icmp eq i64 %149, 0
  br i1 %150, label %151, label %166

151:                                              ; preds = %154, %144
  %152 = phi i64 [ %155, %154 ], [ %18, %144 ]
  %153 = icmp sgt i64 %152, 0
  br i1 %153, label %154, label %166

154:                                              ; preds = %151
  %155 = add nsw i64 %152, -1
  %156 = getelementptr inbounds i64, ptr %33, i64 %155
  %157 = load i64, ptr %156, align 8, !tbaa !15
  %158 = getelementptr inbounds i64, ptr %34, i64 %155
  %159 = load i64, ptr %158, align 8, !tbaa !15
  %160 = icmp eq i64 %157, %159
  br i1 %160, label %151, label %161, !llvm.loop !83

161:                                              ; preds = %154
  %162 = icmp ugt i64 %157, %159
  br i1 %162, label %166, label %163

163:                                              ; preds = %161
  %164 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %33, ptr noundef %34, ptr noundef nonnull %33, i64 noundef %18) #16
  %165 = xor i32 %117, 1
  br label %170

166:                                              ; preds = %161, %151, %144
  %167 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %33, ptr noundef nonnull %33, ptr noundef %34, i64 noundef %18) #16
  %168 = load i64, ptr %36, align 8, !tbaa !15
  %169 = sub i64 %168, %167
  store i64 %169, ptr %36, align 8, !tbaa !15
  br label %170

170:                                              ; preds = %166, %163
  %171 = phi i32 [ %165, %163 ], [ %117, %166 ]
  store i64 0, ptr %32, align 8, !tbaa !15
  %172 = getelementptr inbounds i64, ptr %29, i64 %18
  %173 = load i64, ptr %172, align 8, !tbaa !15
  %174 = load i64, ptr %36, align 8, !tbaa !15
  %175 = or i64 %174, %173
  %176 = add i64 %175, %18
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef nonnull %29, ptr noundef nonnull %33, i64 noundef %176) #16
  %177 = getelementptr inbounds i8, ptr %32, i64 8
  %178 = getelementptr inbounds i8, ptr %148, i64 8
  tail call void @__gmpn_mul_n(ptr noundef nonnull %177, ptr noundef nonnull %27, ptr noundef nonnull %178, i64 noundef %88) #16
  %179 = getelementptr inbounds i8, ptr %26, i64 16
  tail call void @__gmpn_mul_n(ptr noundef nonnull %179, ptr noundef nonnull %24, ptr noundef nonnull %87, i64 noundef %88) #16
  tail call void @__gmpn_mul_n(ptr noundef %86, ptr noundef nonnull %114, ptr noundef %0, i64 noundef %88) #16
  %180 = icmp sgt i64 %20, %22
  %181 = mul i64 %18, 40
  %182 = getelementptr inbounds i8, ptr %0, i64 %181
  %183 = getelementptr inbounds i64, ptr %1, i64 %19
  br i1 %180, label %184, label %186

184:                                              ; preds = %170
  %185 = tail call i64 @__gmpn_mul(ptr noundef %182, ptr noundef %183, i64 noundef %20, ptr noundef %37, i64 noundef %22) #16
  br label %188

186:                                              ; preds = %170
  %187 = tail call i64 @__gmpn_mul(ptr noundef %182, ptr noundef %37, i64 noundef %22, ptr noundef %183, i64 noundef %20) #16
  br label %188

188:                                              ; preds = %186, %184
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %18) #16
  %189 = add nsw i64 %22, %20
  tail call void @__gmpn_toom_interpolate_6pts(ptr noundef %0, i64 noundef %18, i32 noundef %171, ptr noundef %5, ptr noundef nonnull %177, ptr noundef nonnull %179, i64 noundef %189) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom53_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  %8 = mul nsw i64 %2, 3
  %9 = mul nsw i64 %4, 5
  %10 = icmp slt i64 %8, %9
  %11 = select i1 %10, i64 %4, i64 %2
  %12 = select i1 %10, i64 3, i64 5
  %13 = add nsw i64 %11, -1
  %14 = udiv i64 %13, %12
  %15 = add nuw nsw i64 %14, 1
  %16 = shl nsw i64 %15, 2
  %17 = sub nsw i64 %2, %16
  %18 = shl nuw nsw i64 %15, 1
  %19 = sub nsw i64 %4, %18
  store ptr null, ptr %7, align 8, !tbaa !7
  %20 = add nuw nsw i64 %14, 2
  %21 = mul i64 %20, 80
  %22 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %21) #16
  %23 = getelementptr inbounds i64, ptr %22, i64 %20
  %24 = getelementptr inbounds i64, ptr %23, i64 %20
  %25 = getelementptr inbounds i64, ptr %24, i64 %20
  %26 = getelementptr inbounds i64, ptr %25, i64 %20
  %27 = getelementptr inbounds i64, ptr %26, i64 %20
  %28 = getelementptr inbounds i64, ptr %27, i64 %20
  %29 = getelementptr inbounds i64, ptr %28, i64 %20
  %30 = getelementptr inbounds i64, ptr %29, i64 %20
  %31 = getelementptr inbounds i64, ptr %30, i64 %20
  %32 = call i32 @__gmpn_toom_eval_pm1(ptr noundef %22, ptr noundef nonnull %23, i32 noundef 4, ptr noundef %1, i64 noundef %15, i64 noundef %17, ptr noundef %0) #16
  %33 = and i32 %32, 2
  %34 = call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %24, ptr noundef nonnull %25, i32 noundef 4, ptr noundef %1, i64 noundef %15, i64 noundef %17, ptr noundef %0) #16
  %35 = and i32 %34, 1
  %36 = or disjoint i32 %35, %33
  %37 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef %1, i64 noundef %15, i32 noundef 1) #16
  %38 = getelementptr inbounds i64, ptr %1, i64 %15
  %39 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef nonnull %38, i64 noundef %15) #16
  %40 = add i64 %39, %37
  %41 = shl i64 %40, 1
  %42 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef nonnull %26, i64 noundef %15, i32 noundef 1) #16
  %43 = add i64 %41, %42
  %44 = getelementptr inbounds i64, ptr %1, i64 %18
  %45 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef nonnull %44, i64 noundef %15) #16
  %46 = add i64 %43, %45
  %47 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef nonnull %26, i64 noundef %15, i32 noundef 1) #16
  %48 = mul i64 %15, 24
  %49 = getelementptr inbounds i8, ptr %1, i64 %48
  %50 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef %49, i64 noundef %15) #16
  %51 = add i64 %50, %47
  %52 = shl i64 %46, 2
  %53 = shl i64 %51, 1
  %54 = add i64 %52, %53
  %55 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef nonnull %26, i64 noundef %15, i32 noundef 1) #16
  %56 = add i64 %54, %55
  %57 = getelementptr inbounds i64, ptr %1, i64 %16
  %58 = icmp eq i64 %17, 0
  br i1 %58, label %71, label %59

59:                                               ; preds = %6
  %60 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef nonnull %57, i64 noundef %17) #16
  %61 = icmp eq i64 %60, 0
  br i1 %61, label %71, label %62

62:                                               ; preds = %65, %59
  %63 = phi i64 [ %69, %65 ], [ %17, %59 ]
  %64 = icmp sgt i64 %63, %14
  br i1 %64, label %71, label %65

65:                                               ; preds = %62
  %66 = getelementptr inbounds i64, ptr %26, i64 %63
  %67 = load i64, ptr %66, align 8, !tbaa !15
  %68 = add i64 %67, 1
  %69 = add nsw i64 %63, 1
  store i64 %68, ptr %66, align 8, !tbaa !15
  %70 = icmp eq i64 %68, 0
  br i1 %70, label %62, label %71, !llvm.loop !86

71:                                               ; preds = %65, %62, %59, %6
  %72 = phi i64 [ 0, %59 ], [ 0, %6 ], [ 1, %62 ], [ 0, %65 ]
  %73 = add i64 %56, %72
  %74 = getelementptr inbounds i64, ptr %26, i64 %15
  store i64 %73, ptr %74, align 8, !tbaa !15
  %75 = getelementptr inbounds i64, ptr %3, i64 %18
  %76 = icmp eq i64 %19, 0
  br i1 %76, label %90, label %77

77:                                               ; preds = %71
  %78 = call i64 @__gmpn_add_n(ptr noundef nonnull %27, ptr noundef %3, ptr noundef nonnull %75, i64 noundef %19) #16
  %79 = icmp eq i64 %78, 0
  br i1 %79, label %90, label %80

80:                                               ; preds = %83, %77
  %81 = phi i64 [ %87, %83 ], [ %19, %77 ]
  %82 = icmp sgt i64 %81, %14
  br i1 %82, label %105, label %83

83:                                               ; preds = %80
  %84 = getelementptr inbounds i64, ptr %3, i64 %81
  %85 = load i64, ptr %84, align 8, !tbaa !15
  %86 = add i64 %85, 1
  %87 = add nsw i64 %81, 1
  %88 = getelementptr inbounds i64, ptr %27, i64 %81
  store i64 %86, ptr %88, align 8, !tbaa !15
  %89 = icmp eq i64 %86, 0
  br i1 %89, label %80, label %90, !llvm.loop !86

90:                                               ; preds = %83, %77, %71
  %91 = phi i64 [ %19, %77 ], [ 0, %71 ], [ %87, %83 ]
  %92 = icmp ne ptr %27, %3
  %93 = icmp sle i64 %91, %14
  %94 = select i1 %92, i1 %93, i1 false
  br i1 %94, label %95, label %105

95:                                               ; preds = %90
  %96 = mul i64 %14, 40
  %97 = shl i64 %91, 3
  %98 = getelementptr i8, ptr %22, i64 %96
  %99 = getelementptr i8, ptr %98, i64 %97
  %100 = getelementptr i8, ptr %99, i64 80
  %101 = getelementptr i8, ptr %3, i64 %97
  %102 = add nuw nsw i64 %14, 1
  %103 = sub i64 %102, %91
  %104 = shl nuw i64 %103, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %100, ptr align 8 %101, i64 %104, i1 false), !tbaa !15
  br label %105

105:                                              ; preds = %95, %90, %80
  %106 = phi i1 [ true, %90 ], [ true, %95 ], [ false, %80 ]
  %107 = phi i64 [ 0, %90 ], [ 0, %95 ], [ 1, %80 ]
  %108 = getelementptr inbounds i64, ptr %27, i64 %15
  store i64 %107, ptr %108, align 8, !tbaa !15
  br i1 %106, label %109, label %127

109:                                              ; preds = %105
  %110 = getelementptr inbounds i64, ptr %3, i64 %15
  br label %111

111:                                              ; preds = %114, %109
  %112 = phi i64 [ %15, %109 ], [ %115, %114 ]
  %113 = icmp sgt i64 %112, 0
  br i1 %113, label %114, label %127

114:                                              ; preds = %111
  %115 = add nsw i64 %112, -1
  %116 = getelementptr inbounds i64, ptr %27, i64 %115
  %117 = load i64, ptr %116, align 8, !tbaa !15
  %118 = getelementptr inbounds i64, ptr %110, i64 %115
  %119 = load i64, ptr %118, align 8, !tbaa !15
  %120 = icmp eq i64 %117, %119
  br i1 %120, label %111, label %121, !llvm.loop !87

121:                                              ; preds = %114
  %122 = icmp ugt i64 %117, %119
  br i1 %122, label %127, label %123

123:                                              ; preds = %121
  %124 = call i64 @__gmpn_sub_n(ptr noundef nonnull %28, ptr noundef nonnull %110, ptr noundef nonnull %27, i64 noundef %15) #16
  %125 = getelementptr inbounds i64, ptr %28, i64 %15
  store i64 0, ptr %125, align 8, !tbaa !15
  %126 = xor i32 %36, 2
  br label %132

127:                                              ; preds = %121, %111, %105
  %128 = getelementptr inbounds i64, ptr %3, i64 %15
  %129 = call i64 @__gmpn_sub_n(ptr noundef nonnull %28, ptr noundef nonnull %27, ptr noundef nonnull %128, i64 noundef %15) #16
  %130 = sub i64 %107, %129
  %131 = getelementptr inbounds i64, ptr %28, i64 %15
  store i64 %130, ptr %131, align 8, !tbaa !15
  br label %132

132:                                              ; preds = %127, %123
  %133 = phi i32 [ %126, %123 ], [ %36, %127 ]
  %134 = getelementptr inbounds i64, ptr %3, i64 %15
  %135 = call i64 @__gmpn_add_n(ptr noundef nonnull %27, ptr noundef nonnull %27, ptr noundef nonnull %134, i64 noundef %15) #16
  %136 = load i64, ptr %108, align 8, !tbaa !15
  %137 = add i64 %136, %135
  store i64 %137, ptr %108, align 8, !tbaa !15
  %138 = call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %75, i64 noundef %19, i32 noundef 2) #16
  br i1 %76, label %152, label %139

139:                                              ; preds = %132
  %140 = call i64 @__gmpn_add_n(ptr noundef nonnull %29, ptr noundef %3, ptr noundef %0, i64 noundef %19) #16
  %141 = icmp eq i64 %140, 0
  br i1 %141, label %152, label %142

142:                                              ; preds = %145, %139
  %143 = phi i64 [ %149, %145 ], [ %19, %139 ]
  %144 = icmp sgt i64 %143, %14
  br i1 %144, label %167, label %145

145:                                              ; preds = %142
  %146 = getelementptr inbounds i64, ptr %3, i64 %143
  %147 = load i64, ptr %146, align 8, !tbaa !15
  %148 = add i64 %147, 1
  %149 = add nsw i64 %143, 1
  %150 = getelementptr inbounds i64, ptr %29, i64 %143
  store i64 %148, ptr %150, align 8, !tbaa !15
  %151 = icmp eq i64 %148, 0
  br i1 %151, label %142, label %152, !llvm.loop !86

152:                                              ; preds = %145, %139, %132
  %153 = phi i64 [ %19, %139 ], [ 0, %132 ], [ %149, %145 ]
  %154 = icmp ne ptr %29, %3
  %155 = icmp sle i64 %153, %14
  %156 = select i1 %154, i1 %155, i1 false
  br i1 %156, label %157, label %167

157:                                              ; preds = %152
  %158 = mul i64 %14, 56
  %159 = shl i64 %153, 3
  %160 = getelementptr i8, ptr %22, i64 %158
  %161 = getelementptr i8, ptr %160, i64 %159
  %162 = getelementptr i8, ptr %161, i64 112
  %163 = getelementptr i8, ptr %3, i64 %159
  %164 = add nuw nsw i64 %14, 1
  %165 = sub i64 %164, %153
  %166 = shl nuw i64 %165, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %162, ptr align 8 %163, i64 %166, i1 false), !tbaa !15
  br label %167

167:                                              ; preds = %157, %152, %142
  %168 = phi i64 [ 0, %152 ], [ 0, %157 ], [ 1, %142 ]
  %169 = getelementptr inbounds i64, ptr %29, i64 %15
  store i64 %168, ptr %169, align 8, !tbaa !15
  %170 = getelementptr inbounds i64, ptr %29, i64 %19
  %171 = load i64, ptr %170, align 8, !tbaa !15
  %172 = add i64 %171, %138
  store i64 %172, ptr %170, align 8, !tbaa !15
  %173 = icmp ult i64 %172, %138
  br i1 %173, label %174, label %180

174:                                              ; preds = %174, %167
  %175 = phi ptr [ %176, %174 ], [ %170, %167 ]
  %176 = getelementptr inbounds i8, ptr %175, i64 8
  %177 = load i64, ptr %176, align 8, !tbaa !15
  %178 = add i64 %177, 1
  store i64 %178, ptr %176, align 8, !tbaa !15
  %179 = icmp eq i64 %178, 0
  br i1 %179, label %174, label %180, !llvm.loop !88

180:                                              ; preds = %174, %167
  %181 = call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %134, i64 noundef %15, i32 noundef 1) #16
  %182 = getelementptr inbounds i64, ptr %0, i64 %15
  store i64 %181, ptr %182, align 8, !tbaa !15
  br label %183

183:                                              ; preds = %186, %180
  %184 = phi i64 [ %20, %180 ], [ %187, %186 ]
  %185 = icmp sgt i64 %184, 0
  br i1 %185, label %186, label %198

186:                                              ; preds = %183
  %187 = add nsw i64 %184, -1
  %188 = getelementptr inbounds i64, ptr %29, i64 %187
  %189 = load i64, ptr %188, align 8, !tbaa !15
  %190 = getelementptr inbounds i64, ptr %0, i64 %187
  %191 = load i64, ptr %190, align 8, !tbaa !15
  %192 = icmp eq i64 %189, %191
  br i1 %192, label %183, label %193, !llvm.loop !87

193:                                              ; preds = %186
  %194 = icmp ugt i64 %189, %191
  br i1 %194, label %198, label %195

195:                                              ; preds = %193
  %196 = call i64 @__gmpn_sub_n(ptr noundef nonnull %30, ptr noundef %0, ptr noundef nonnull %29, i64 noundef %20) #16
  %197 = xor i32 %133, 1
  br label %200

198:                                              ; preds = %193, %183
  %199 = call i64 @__gmpn_sub_n(ptr noundef nonnull %30, ptr noundef nonnull %29, ptr noundef %0, i64 noundef %20) #16
  br label %200

200:                                              ; preds = %198, %195
  %201 = phi i32 [ %197, %195 ], [ %133, %198 ]
  %202 = call i64 @__gmpn_add_n(ptr noundef nonnull %29, ptr noundef nonnull %29, ptr noundef %0, i64 noundef %20) #16
  %203 = call i64 @__gmpn_lshift(ptr noundef nonnull %31, ptr noundef %3, i64 noundef %15, i32 noundef 1) #16
  %204 = call i64 @__gmpn_add_n(ptr noundef nonnull %31, ptr noundef nonnull %31, ptr noundef nonnull %134, i64 noundef %15) #16
  %205 = add i64 %204, %203
  %206 = shl i64 %205, 1
  %207 = call i64 @__gmpn_lshift(ptr noundef nonnull %31, ptr noundef nonnull %31, i64 noundef %15, i32 noundef 1) #16
  %208 = add i64 %206, %207
  br i1 %76, label %221, label %209

209:                                              ; preds = %200
  %210 = call i64 @__gmpn_add_n(ptr noundef nonnull %31, ptr noundef nonnull %31, ptr noundef nonnull %75, i64 noundef %19) #16
  %211 = icmp eq i64 %210, 0
  br i1 %211, label %221, label %212

212:                                              ; preds = %215, %209
  %213 = phi i64 [ %219, %215 ], [ %19, %209 ]
  %214 = icmp sgt i64 %213, %14
  br i1 %214, label %221, label %215

215:                                              ; preds = %212
  %216 = getelementptr inbounds i64, ptr %31, i64 %213
  %217 = load i64, ptr %216, align 8, !tbaa !15
  %218 = add i64 %217, 1
  %219 = add nsw i64 %213, 1
  store i64 %218, ptr %216, align 8, !tbaa !15
  %220 = icmp eq i64 %218, 0
  br i1 %220, label %212, label %221, !llvm.loop !86

221:                                              ; preds = %215, %212, %209, %200
  %222 = phi i64 [ 0, %209 ], [ 0, %200 ], [ 1, %212 ], [ 0, %215 ]
  %223 = add i64 %208, %222
  %224 = getelementptr inbounds i64, ptr %31, i64 %15
  store i64 %223, ptr %224, align 8, !tbaa !15
  call void @__gmpn_mul_n(ptr noundef %5, ptr noundef nonnull %24, ptr noundef nonnull %29, i64 noundef %20) #16
  %225 = getelementptr inbounds i64, ptr %5, i64 %18
  %226 = getelementptr inbounds i8, ptr %225, i64 8
  call void @__gmpn_mul_n(ptr noundef nonnull %226, ptr noundef nonnull %25, ptr noundef nonnull %30, i64 noundef %20) #16
  %227 = getelementptr inbounds i64, ptr %5, i64 %16
  %228 = getelementptr inbounds i8, ptr %227, i64 16
  call void @__gmpn_mul_n(ptr noundef nonnull %228, ptr noundef nonnull %26, ptr noundef nonnull %31, i64 noundef %20) #16
  %229 = mul nuw nsw i64 %15, 6
  %230 = getelementptr inbounds i64, ptr %5, i64 %229
  %231 = getelementptr inbounds i8, ptr %230, i64 24
  %232 = getelementptr inbounds i64, ptr %231, i64 %18
  store i64 0, ptr %232, align 8, !tbaa !15
  %233 = getelementptr inbounds i64, ptr %23, i64 %15
  %234 = load i64, ptr %233, align 8, !tbaa !15
  %235 = getelementptr inbounds i64, ptr %28, i64 %15
  %236 = load i64, ptr %235, align 8, !tbaa !15
  %237 = or i64 %236, %234
  %238 = icmp ne i64 %237, 0
  %239 = zext i1 %238 to i64
  %240 = add nuw nsw i64 %15, %239
  call void @__gmpn_mul_n(ptr noundef nonnull %231, ptr noundef nonnull %23, ptr noundef nonnull %28, i64 noundef %240) #16
  %241 = getelementptr inbounds i64, ptr %0, i64 %18
  %242 = getelementptr inbounds i64, ptr %241, i64 %18
  store i64 0, ptr %242, align 8, !tbaa !15
  %243 = getelementptr inbounds i64, ptr %22, i64 %15
  %244 = load i64, ptr %243, align 8, !tbaa !15
  %245 = load i64, ptr %108, align 8, !tbaa !15
  %246 = or i64 %245, %244
  %247 = icmp ne i64 %246, 0
  %248 = zext i1 %247 to i64
  %249 = add nuw nsw i64 %15, %248
  call void @__gmpn_mul_n(ptr noundef nonnull %241, ptr noundef %22, ptr noundef nonnull %27, i64 noundef %249) #16
  call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %15) #16
  %250 = icmp sgt i64 %17, %19
  %251 = getelementptr inbounds i64, ptr %0, i64 %229
  br i1 %250, label %252, label %254

252:                                              ; preds = %221
  %253 = call i64 @__gmpn_mul(ptr noundef nonnull %251, ptr noundef nonnull %57, i64 noundef %17, ptr noundef nonnull %75, i64 noundef %19) #16
  br label %256

254:                                              ; preds = %221
  %255 = call i64 @__gmpn_mul(ptr noundef nonnull %251, ptr noundef nonnull %75, i64 noundef %19, ptr noundef nonnull %57, i64 noundef %17) #16
  br label %256

256:                                              ; preds = %254, %252
  %257 = add nsw i64 %17, %19
  %258 = shl nsw i64 %15, 6
  %259 = getelementptr inbounds i8, ptr %5, i64 %258
  %260 = getelementptr inbounds i8, ptr %259, i64 32
  call void @__gmpn_toom_interpolate_7pts(ptr noundef %0, i64 noundef %15, i32 noundef %201, ptr noundef nonnull %226, ptr noundef nonnull %231, ptr noundef %5, ptr noundef nonnull %228, i64 noundef %257, ptr noundef nonnull %260) #16
  %261 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %261) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = add nsw i64 %2, 3
  %8 = ashr i64 %7, 2
  %9 = mul nsw i64 %8, 3
  %10 = sub nsw i64 %2, %9
  %11 = sub nsw i64 %4, %9
  %12 = getelementptr inbounds i64, ptr %0, i64 %8
  %13 = getelementptr inbounds i8, ptr %12, i64 8
  %14 = shl nsw i64 %8, 6
  %15 = getelementptr inbounds i8, ptr %5, i64 %14
  %16 = getelementptr inbounds i8, ptr %15, i64 40
  %17 = tail call i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef %0, ptr noundef nonnull %13, ptr noundef %1, i64 noundef %8, i64 noundef %10, ptr noundef nonnull %16) #16
  %18 = and i64 %7, -4
  %19 = getelementptr inbounds i64, ptr %0, i64 %18
  %20 = getelementptr inbounds i8, ptr %19, i64 16
  %21 = shl nsw i64 %8, 1
  %22 = getelementptr inbounds i64, ptr %0, i64 %21
  %23 = getelementptr inbounds i8, ptr %22, i64 16
  %24 = tail call i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef nonnull %20, ptr noundef nonnull %23, ptr noundef %3, i64 noundef %8, i64 noundef %11, ptr noundef nonnull %16) #16
  %25 = add nsw i64 %8, 1
  %26 = icmp sgt i64 %8, 98
  br i1 %26, label %28, label %27

27:                                               ; preds = %6
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %29

28:                                               ; preds = %6
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %29

29:                                               ; preds = %28, %27
  %30 = getelementptr inbounds i64, ptr %5, i64 %21
  %31 = getelementptr inbounds i8, ptr %30, i64 8
  br i1 %26, label %33, label %32

32:                                               ; preds = %29
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %31, ptr noundef nonnull %13, i64 noundef %25, ptr noundef nonnull %23, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %34

33:                                               ; preds = %29
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %31, ptr noundef nonnull %13, i64 noundef %25, ptr noundef nonnull %23, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %34

34:                                               ; preds = %33, %32
  %35 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %1, i64 noundef %8, i32 noundef 1) #16
  %36 = getelementptr inbounds i64, ptr %1, i64 %8
  %37 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %36, i64 noundef %8) #16
  %38 = add i64 %37, %35
  %39 = shl i64 %38, 1
  %40 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %8, i32 noundef 1) #16
  %41 = add i64 %39, %40
  %42 = getelementptr inbounds i64, ptr %1, i64 %21
  %43 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %42, i64 noundef %8) #16
  %44 = add i64 %41, %43
  %45 = shl i64 %44, 1
  %46 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %8, i32 noundef 1) #16
  %47 = add i64 %45, %46
  %48 = getelementptr inbounds i64, ptr %1, i64 %9
  %49 = icmp eq i64 %10, 0
  br i1 %49, label %62, label %50

50:                                               ; preds = %34
  %51 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %48, i64 noundef %10) #16
  %52 = icmp eq i64 %51, 0
  br i1 %52, label %62, label %53

53:                                               ; preds = %56, %50
  %54 = phi i64 [ %60, %56 ], [ %10, %50 ]
  %55 = icmp slt i64 %54, %8
  br i1 %55, label %56, label %62

56:                                               ; preds = %53
  %57 = getelementptr inbounds i64, ptr %0, i64 %54
  %58 = load i64, ptr %57, align 8, !tbaa !15
  %59 = add i64 %58, 1
  %60 = add nsw i64 %54, 1
  store i64 %59, ptr %57, align 8, !tbaa !15
  %61 = icmp eq i64 %59, 0
  br i1 %61, label %53, label %62, !llvm.loop !89

62:                                               ; preds = %56, %53, %50, %34
  %63 = phi i64 [ 0, %50 ], [ 0, %34 ], [ 1, %53 ], [ 0, %56 ]
  %64 = add i64 %47, %63
  store i64 %64, ptr %12, align 8, !tbaa !15
  %65 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %20, ptr noundef %3, i64 noundef %8, i32 noundef 1) #16
  %66 = getelementptr inbounds i64, ptr %3, i64 %8
  %67 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %20, ptr noundef nonnull %20, ptr noundef %66, i64 noundef %8) #16
  %68 = add i64 %67, %65
  %69 = shl i64 %68, 1
  %70 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %20, ptr noundef nonnull %20, i64 noundef %8, i32 noundef 1) #16
  %71 = add i64 %69, %70
  %72 = getelementptr inbounds i64, ptr %3, i64 %21
  %73 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %20, ptr noundef nonnull %20, ptr noundef %72, i64 noundef %8) #16
  %74 = add i64 %71, %73
  %75 = shl i64 %74, 1
  %76 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %20, ptr noundef nonnull %20, i64 noundef %8, i32 noundef 1) #16
  %77 = add i64 %75, %76
  %78 = getelementptr inbounds i64, ptr %3, i64 %9
  %79 = icmp eq i64 %11, 0
  br i1 %79, label %92, label %80

80:                                               ; preds = %62
  %81 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %20, ptr noundef nonnull %20, ptr noundef %78, i64 noundef %11) #16
  %82 = icmp eq i64 %81, 0
  br i1 %82, label %92, label %83

83:                                               ; preds = %86, %80
  %84 = phi i64 [ %90, %86 ], [ %11, %80 ]
  %85 = icmp slt i64 %84, %8
  br i1 %85, label %86, label %92

86:                                               ; preds = %83
  %87 = getelementptr inbounds i64, ptr %20, i64 %84
  %88 = load i64, ptr %87, align 8, !tbaa !15
  %89 = add i64 %88, 1
  %90 = add nsw i64 %84, 1
  store i64 %89, ptr %87, align 8, !tbaa !15
  %91 = icmp eq i64 %89, 0
  br i1 %91, label %83, label %92, !llvm.loop !89

92:                                               ; preds = %86, %83, %80, %62
  %93 = phi i64 [ 0, %80 ], [ 0, %62 ], [ 1, %83 ], [ 0, %86 ]
  %94 = add i64 %77, %93
  %95 = getelementptr inbounds i64, ptr %20, i64 %8
  store i64 %94, ptr %95, align 8, !tbaa !15
  %96 = getelementptr inbounds i64, ptr %5, i64 %18
  %97 = getelementptr inbounds i8, ptr %96, i64 16
  br i1 %26, label %99, label %98

98:                                               ; preds = %92
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %97, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %100

99:                                               ; preds = %92
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %97, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %100

100:                                              ; preds = %99, %98
  %101 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef %0, ptr noundef nonnull %13, ptr noundef %1, i64 noundef %8, i64 noundef %10, ptr noundef nonnull %16) #16
  %102 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %20, ptr noundef nonnull %23, ptr noundef %3, i64 noundef %8, i64 noundef %11, ptr noundef nonnull %16) #16
  %103 = mul nsw i64 %8, 6
  %104 = getelementptr inbounds i64, ptr %5, i64 %103
  %105 = getelementptr inbounds i8, ptr %104, i64 24
  %106 = getelementptr inbounds i64, ptr %105, i64 %21
  store i64 0, ptr %106, align 8, !tbaa !15
  %107 = getelementptr inbounds i64, ptr %23, i64 %8
  %108 = load i64, ptr %107, align 8, !tbaa !15
  %109 = getelementptr inbounds i64, ptr %13, i64 %8
  %110 = load i64, ptr %109, align 8, !tbaa !15
  %111 = or i64 %110, %108
  %112 = add i64 %111, %8
  %113 = icmp ugt i64 %112, 99
  br i1 %113, label %115, label %114

114:                                              ; preds = %100
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %105, ptr noundef nonnull %13, i64 noundef %112, ptr noundef nonnull %23, i64 noundef %112, ptr noundef nonnull %16) #16
  br label %116

115:                                              ; preds = %100
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %105, ptr noundef nonnull %13, i64 noundef %112, ptr noundef nonnull %23, i64 noundef %112, ptr noundef nonnull %16) #16
  br label %116

116:                                              ; preds = %115, %114
  br i1 %26, label %118, label %117

117:                                              ; preds = %116
  tail call void @__gmpn_toom22_mul(ptr noundef %22, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %119

118:                                              ; preds = %116
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %22, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #16
  br label %119

119:                                              ; preds = %118, %117
  %120 = icmp sgt i64 %8, 99
  br i1 %120, label %122, label %121

121:                                              ; preds = %119
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %16) #16
  br label %123

122:                                              ; preds = %119
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %16) #16
  br label %123

123:                                              ; preds = %122, %121
  %124 = icmp sgt i64 %2, %4
  br i1 %124, label %125, label %128

125:                                              ; preds = %123
  %126 = getelementptr inbounds i64, ptr %0, i64 %103
  %127 = tail call i64 @__gmpn_mul(ptr noundef %126, ptr noundef %48, i64 noundef %10, ptr noundef %78, i64 noundef %11) #16
  br label %133

128:                                              ; preds = %123
  %129 = icmp sgt i64 %10, 99
  %130 = getelementptr inbounds i64, ptr %0, i64 %103
  br i1 %129, label %132, label %131

131:                                              ; preds = %128
  tail call void @__gmpn_toom22_mul(ptr noundef %130, ptr noundef %48, i64 noundef %10, ptr noundef %78, i64 noundef %10, ptr noundef nonnull %16) #16
  br label %133

132:                                              ; preds = %128
  tail call void @__gmpn_toom33_mul(ptr noundef %130, ptr noundef %48, i64 noundef %10, ptr noundef %78, i64 noundef %10, ptr noundef nonnull %16) #16
  br label %133

133:                                              ; preds = %132, %131, %125
  %134 = xor i32 %24, %17
  %135 = and i32 %134, 1
  %136 = and i32 %101, 2
  %137 = or disjoint i32 %136, %135
  %138 = and i32 %102, 2
  %139 = xor i32 %137, %138
  %140 = getelementptr inbounds i64, ptr %5, i64 %21
  %141 = getelementptr inbounds i8, ptr %140, i64 8
  %142 = getelementptr inbounds i64, ptr %5, i64 %18
  %143 = getelementptr inbounds i8, ptr %142, i64 16
  %144 = add nsw i64 %10, %11
  tail call void @__gmpn_toom_interpolate_7pts(ptr noundef %0, i64 noundef %8, i32 noundef %139, ptr noundef nonnull %141, ptr noundef nonnull %105, ptr noundef %5, ptr noundef nonnull %143, i64 noundef %144, ptr noundef nonnull %16) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = mul nsw i64 %2, 17
  %8 = mul nsw i64 %4, 18
  %9 = icmp slt i64 %7, %8
  br i1 %9, label %10, label %17, !prof !68

10:                                               ; preds = %6
  %11 = add nsw i64 %2, -1
  %12 = udiv i64 %11, 6
  %13 = add nuw nsw i64 %12, 1
  %14 = mul nuw nsw i64 %13, 5
  %15 = sub nsw i64 %2, %14
  %16 = sub nsw i64 %4, %14
  br label %67

17:                                               ; preds = %6
  %18 = mul i64 %2, 90
  %19 = mul nsw i64 %4, 119
  %20 = icmp slt i64 %18, %19
  br i1 %20, label %33, label %21

21:                                               ; preds = %17
  %22 = mul i64 %2, 85
  %23 = mul nsw i64 %4, 126
  %24 = icmp slt i64 %22, %23
  br i1 %24, label %33, label %25

25:                                               ; preds = %21
  %26 = mul nsw i64 %2, 18
  %27 = mul nsw i64 %4, 34
  %28 = icmp slt i64 %26, %27
  br i1 %28, label %33, label %29

29:                                               ; preds = %25
  %30 = mul nsw i64 %4, 36
  %31 = icmp slt i64 %7, %30
  %32 = select i1 %31, i32 8, i32 9
  br label %33

33:                                               ; preds = %29, %25, %21, %17
  %34 = phi i32 [ 7, %17 ], [ 7, %21 ], [ 8, %25 ], [ %32, %29 ]
  %35 = phi i32 [ 6, %17 ], [ 5, %21 ], [ 5, %25 ], [ 4, %29 ]
  %36 = xor i32 %35, %34
  %37 = and i32 %36, 1
  %38 = zext nneg i32 %35 to i64
  %39 = mul nsw i64 %38, %2
  %40 = zext nneg i32 %34 to i64
  %41 = mul nsw i64 %40, %4
  %42 = icmp slt i64 %39, %41
  %43 = select i1 %42, i64 %4, i64 %2
  %44 = select i1 %42, i64 %38, i64 %40
  %45 = add nsw i64 %43, -1
  %46 = udiv i64 %45, %44
  %47 = add nuw nsw i64 %46, 1
  %48 = add nsw i32 %34, -1
  %49 = add nsw i32 %35, -1
  %50 = zext nneg i32 %48 to i64
  %51 = mul nsw i64 %47, %50
  %52 = sub nsw i64 %2, %51
  %53 = zext nneg i32 %49 to i64
  %54 = mul nsw i64 %47, %53
  %55 = sub nsw i64 %4, %54
  %56 = icmp eq i32 %37, 0
  br i1 %56, label %67, label %57

57:                                               ; preds = %33
  %58 = icmp slt i64 %52, 1
  br i1 %58, label %59, label %62, !prof !54

59:                                               ; preds = %57
  %60 = add nsw i32 %34, -2
  %61 = add nsw i64 %52, %47
  br label %67

62:                                               ; preds = %57
  %63 = icmp slt i64 %55, 1
  br i1 %63, label %64, label %67, !prof !54

64:                                               ; preds = %62
  %65 = add nsw i32 %35, -2
  %66 = add nsw i64 %55, %47
  br label %67

67:                                               ; preds = %64, %62, %59, %33, %10
  %68 = phi i64 [ %13, %10 ], [ %47, %59 ], [ %47, %64 ], [ %47, %62 ], [ %47, %33 ]
  %69 = phi i64 [ %15, %10 ], [ %61, %59 ], [ %52, %64 ], [ %52, %62 ], [ %52, %33 ]
  %70 = phi i64 [ %16, %10 ], [ %55, %59 ], [ %66, %64 ], [ %55, %62 ], [ %55, %33 ]
  %71 = phi i32 [ 5, %10 ], [ %60, %59 ], [ %48, %64 ], [ %48, %62 ], [ %48, %33 ]
  %72 = phi i32 [ 5, %10 ], [ %49, %59 ], [ %65, %64 ], [ %49, %62 ], [ %49, %33 ]
  %73 = phi i1 [ true, %10 ], [ true, %59 ], [ true, %64 ], [ false, %62 ], [ true, %33 ]
  %74 = phi i32 [ 0, %10 ], [ 0, %59 ], [ 0, %64 ], [ 1, %62 ], [ 0, %33 ]
  %75 = mul nsw i64 %68, 9
  %76 = getelementptr inbounds i64, ptr %0, i64 %75
  %77 = getelementptr inbounds i8, ptr %76, i64 16
  %78 = mul i64 %68, 56
  %79 = getelementptr inbounds i8, ptr %0, i64 %78
  %80 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, i32 noundef 1, ptr noundef %0) #16
  %81 = getelementptr inbounds i64, ptr %5, i64 %75
  %82 = getelementptr inbounds i8, ptr %81, i64 24
  %83 = shl nsw i64 %68, 6
  %84 = getelementptr inbounds i8, ptr %0, i64 %83
  %85 = getelementptr inbounds i8, ptr %84, i64 8
  %86 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, i32 noundef 1, ptr noundef %0) #16
  %87 = xor i32 %86, %80
  %88 = add nuw nsw i64 %68, 1
  %89 = icmp sgt i64 %68, 98
  br i1 %89, label %94, label %90

90:                                               ; preds = %67
  %91 = mul i64 %68, 80
  %92 = getelementptr inbounds i8, ptr %5, i64 %91
  %93 = getelementptr inbounds i8, ptr %92, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %93) #16
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %93) #16
  br label %107

94:                                               ; preds = %67
  %95 = icmp sgt i64 %68, 298
  br i1 %95, label %100, label %96

96:                                               ; preds = %94
  %97 = mul i64 %68, 80
  %98 = getelementptr inbounds i8, ptr %5, i64 %97
  %99 = getelementptr inbounds i8, ptr %98, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %99) #16
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %99) #16
  br label %107

100:                                              ; preds = %94
  %101 = icmp sgt i64 %68, 348
  %102 = mul i64 %68, 80
  %103 = getelementptr inbounds i8, ptr %5, i64 %102
  %104 = getelementptr inbounds i8, ptr %103, i64 32
  br i1 %101, label %106, label %105

105:                                              ; preds = %100
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %104) #16
  tail call void @__gmpn_toom44_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %104) #16
  br label %107

106:                                              ; preds = %100
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %104)
  tail call void @__gmpn_toom6h_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %104)
  br label %107

107:                                              ; preds = %106, %105, %96, %90
  %108 = shl nuw nsw i64 %68, 1
  %109 = or disjoint i64 %108, 1
  %110 = add nuw nsw i32 %74, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef %5, i64 noundef %109, ptr noundef %0, i32 noundef %87, i64 noundef %68, i32 noundef %110, i32 noundef %74) #16
  %111 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, ptr noundef %0) #16
  %112 = icmp eq i32 %72, 3
  br i1 %112, label %113, label %115, !prof !54

113:                                              ; preds = %107
  %114 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %82, ptr noundef nonnull %85, ptr noundef %3, i64 noundef %68, i64 noundef %70, ptr noundef %0) #16
  br label %117

115:                                              ; preds = %107
  %116 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, ptr noundef %0) #16
  br label %117

117:                                              ; preds = %115, %113
  %118 = phi i32 [ %114, %113 ], [ %116, %115 ]
  %119 = xor i32 %118, %111
  br i1 %89, label %127, label %120

120:                                              ; preds = %117
  %121 = mul i64 %68, 80
  %122 = getelementptr inbounds i8, ptr %5, i64 %121
  %123 = getelementptr inbounds i8, ptr %122, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %123) #16
  %124 = mul i64 %68, 24
  %125 = getelementptr inbounds i8, ptr %5, i64 %124
  %126 = getelementptr inbounds i8, ptr %125, i64 8
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %126, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %123) #16
  br label %143

127:                                              ; preds = %117
  %128 = icmp sgt i64 %68, 298
  %129 = mul i64 %68, 24
  %130 = getelementptr inbounds i8, ptr %5, i64 %129
  %131 = getelementptr inbounds i8, ptr %130, i64 8
  br i1 %128, label %136, label %132

132:                                              ; preds = %127
  %133 = mul i64 %68, 80
  %134 = getelementptr inbounds i8, ptr %5, i64 %133
  %135 = getelementptr inbounds i8, ptr %134, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %135) #16
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %131, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %135) #16
  br label %143

136:                                              ; preds = %127
  %137 = icmp sgt i64 %68, 348
  %138 = mul i64 %68, 80
  %139 = getelementptr inbounds i8, ptr %5, i64 %138
  %140 = getelementptr inbounds i8, ptr %139, i64 32
  br i1 %137, label %142, label %141

141:                                              ; preds = %136
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %140) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %131, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %140) #16
  br label %143

142:                                              ; preds = %136
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %140)
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %131, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %140)
  br label %143

143:                                              ; preds = %142, %141, %132, %120
  %144 = mul nuw nsw i64 %68, 3
  %145 = getelementptr inbounds i64, ptr %5, i64 %144
  %146 = getelementptr inbounds i8, ptr %145, i64 8
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %146, i64 noundef %109, ptr noundef %0, i32 noundef %119, i64 noundef %68, i32 noundef 0, i32 noundef 0) #16
  %147 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, i32 noundef 2, ptr noundef %0) #16
  %148 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, i32 noundef 2, ptr noundef %0) #16
  %149 = xor i32 %148, %147
  br i1 %89, label %157, label %150

150:                                              ; preds = %143
  %151 = mul i64 %68, 80
  %152 = getelementptr inbounds i8, ptr %5, i64 %151
  %153 = getelementptr inbounds i8, ptr %152, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %153) #16
  %154 = mul i64 %68, 48
  %155 = getelementptr inbounds i8, ptr %5, i64 %154
  %156 = getelementptr inbounds i8, ptr %155, i64 16
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %156, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %153) #16
  br label %173

157:                                              ; preds = %143
  %158 = icmp sgt i64 %68, 298
  %159 = mul i64 %68, 48
  %160 = getelementptr inbounds i8, ptr %5, i64 %159
  %161 = getelementptr inbounds i8, ptr %160, i64 16
  br i1 %158, label %166, label %162

162:                                              ; preds = %157
  %163 = mul i64 %68, 80
  %164 = getelementptr inbounds i8, ptr %5, i64 %163
  %165 = getelementptr inbounds i8, ptr %164, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %165) #16
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %161, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %165) #16
  br label %173

166:                                              ; preds = %157
  %167 = icmp sgt i64 %68, 348
  %168 = mul i64 %68, 80
  %169 = getelementptr inbounds i8, ptr %5, i64 %168
  %170 = getelementptr inbounds i8, ptr %169, i64 32
  br i1 %167, label %172, label %171

171:                                              ; preds = %166
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %170) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %161, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %170) #16
  br label %173

172:                                              ; preds = %166
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %170)
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %161, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %170)
  br label %173

173:                                              ; preds = %172, %171, %162, %150
  %174 = mul i64 %68, 48
  %175 = getelementptr inbounds i8, ptr %5, i64 %174
  %176 = getelementptr inbounds i8, ptr %175, i64 16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %176, i64 noundef %109, ptr noundef %0, i32 noundef %149, i64 noundef %68, i32 noundef 2, i32 noundef 4) #16
  %177 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, i32 noundef 2, ptr noundef %0) #16
  %178 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, i32 noundef 2, ptr noundef %0) #16
  %179 = xor i32 %178, %177
  br i1 %89, label %185, label %180

180:                                              ; preds = %173
  %181 = mul i64 %68, 80
  %182 = getelementptr inbounds i8, ptr %5, i64 %181
  %183 = getelementptr inbounds i8, ptr %182, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %183) #16
  %184 = getelementptr inbounds i64, ptr %0, i64 %144
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %184, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %183) #16
  br label %199

185:                                              ; preds = %173
  %186 = icmp sgt i64 %68, 298
  %187 = getelementptr inbounds i64, ptr %0, i64 %144
  br i1 %186, label %192, label %188

188:                                              ; preds = %185
  %189 = mul i64 %68, 80
  %190 = getelementptr inbounds i8, ptr %5, i64 %189
  %191 = getelementptr inbounds i8, ptr %190, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %191) #16
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %187, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %191) #16
  br label %199

192:                                              ; preds = %185
  %193 = icmp sgt i64 %68, 348
  %194 = mul i64 %68, 80
  %195 = getelementptr inbounds i8, ptr %5, i64 %194
  %196 = getelementptr inbounds i8, ptr %195, i64 32
  br i1 %193, label %198, label %197

197:                                              ; preds = %192
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %196) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %187, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %196) #16
  br label %199

198:                                              ; preds = %192
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %196)
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %187, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %196)
  br label %199

199:                                              ; preds = %198, %197, %188, %180
  %200 = getelementptr inbounds i64, ptr %0, i64 %144
  %201 = shl nuw nsw i32 %110, 1
  %202 = shl nuw nsw i32 %74, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %200, i64 noundef %109, ptr noundef %0, i32 noundef %179, i64 noundef %68, i32 noundef %201, i32 noundef %202) #16
  %203 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, ptr noundef %0) #16
  %204 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, ptr noundef %0) #16
  %205 = xor i32 %204, %203
  br i1 %89, label %210, label %206

206:                                              ; preds = %199
  %207 = mul i64 %68, 80
  %208 = getelementptr inbounds i8, ptr %5, i64 %207
  %209 = getelementptr inbounds i8, ptr %208, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %209) #16
  tail call void @__gmpn_toom22_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %209) #16
  br label %223

210:                                              ; preds = %199
  %211 = icmp sgt i64 %68, 298
  br i1 %211, label %216, label %212

212:                                              ; preds = %210
  %213 = mul i64 %68, 80
  %214 = getelementptr inbounds i8, ptr %5, i64 %213
  %215 = getelementptr inbounds i8, ptr %214, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %215) #16
  tail call void @__gmpn_toom33_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %215) #16
  br label %223

216:                                              ; preds = %210
  %217 = icmp sgt i64 %68, 348
  %218 = mul i64 %68, 80
  %219 = getelementptr inbounds i8, ptr %5, i64 %218
  %220 = getelementptr inbounds i8, ptr %219, i64 32
  br i1 %217, label %222, label %221

221:                                              ; preds = %216
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %220) #16
  tail call void @__gmpn_toom44_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %220) #16
  br label %223

222:                                              ; preds = %216
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %220)
  tail call void @__gmpn_toom6h_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %220)
  br label %223

223:                                              ; preds = %222, %221, %212, %206
  tail call void @__gmpn_toom_couple_handling(ptr noundef %79, i64 noundef %109, ptr noundef %0, i32 noundef %205, i64 noundef %68, i32 noundef 1, i32 noundef 2) #16
  %224 = icmp sgt i64 %68, 99
  br i1 %224, label %226, label %225

225:                                              ; preds = %223
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82) #16
  br label %233

226:                                              ; preds = %223
  %227 = icmp sgt i64 %68, 299
  br i1 %227, label %229, label %228

228:                                              ; preds = %226
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82) #16
  br label %233

229:                                              ; preds = %226
  %230 = icmp sgt i64 %68, 349
  br i1 %230, label %232, label %231

231:                                              ; preds = %229
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82) #16
  br label %233

232:                                              ; preds = %229
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82)
  br label %233

233:                                              ; preds = %232, %231, %228, %225
  br i1 %73, label %254, label %234, !prof !68

234:                                              ; preds = %233
  %235 = icmp sgt i64 %69, %70
  %236 = mul i64 %68, 88
  %237 = getelementptr inbounds i8, ptr %0, i64 %236
  br i1 %235, label %238, label %246

238:                                              ; preds = %234
  %239 = zext nneg i32 %71 to i64
  %240 = mul nsw i64 %68, %239
  %241 = getelementptr inbounds i64, ptr %1, i64 %240
  %242 = zext nneg i32 %72 to i64
  %243 = mul nsw i64 %68, %242
  %244 = getelementptr inbounds i64, ptr %3, i64 %243
  %245 = tail call i64 @__gmpn_mul(ptr noundef %237, ptr noundef %241, i64 noundef %69, ptr noundef %244, i64 noundef %70) #16
  br label %254

246:                                              ; preds = %234
  %247 = zext nneg i32 %72 to i64
  %248 = mul nsw i64 %68, %247
  %249 = getelementptr inbounds i64, ptr %3, i64 %248
  %250 = zext nneg i32 %71 to i64
  %251 = mul nsw i64 %68, %250
  %252 = getelementptr inbounds i64, ptr %1, i64 %251
  %253 = tail call i64 @__gmpn_mul(ptr noundef %237, ptr noundef %249, i64 noundef %70, ptr noundef %252, i64 noundef %69) #16
  br label %254

254:                                              ; preds = %246, %238, %233
  %255 = add nsw i64 %70, %69
  tail call void @__gmpn_toom_interpolate_12pts(ptr noundef %0, ptr noundef nonnull %176, ptr noundef nonnull %146, ptr noundef %5, i64 noundef %68, i64 noundef %255, i32 noundef %74, ptr noundef nonnull %82) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom8h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = icmp eq i64 %2, %4
  br i1 %7, label %13, label %8, !prof !68

8:                                                ; preds = %6
  %9 = mul nsw i64 %2, 10
  %10 = ashr i64 %4, 1
  %11 = mul nsw i64 %10, 21
  %12 = icmp slt i64 %9, %11
  br i1 %12, label %13, label %20

13:                                               ; preds = %8, %6
  %14 = add nsw i64 %2, -1
  %15 = ashr i64 %14, 3
  %16 = add nsw i64 %15, 1
  %17 = mul nsw i64 %16, 7
  %18 = sub nsw i64 %2, %17
  %19 = sub nsw i64 %4, %17
  br label %84

20:                                               ; preds = %8
  %21 = mul nsw i64 %2, 13
  %22 = shl nsw i64 %4, 4
  %23 = icmp slt i64 %21, %22
  br i1 %23, label %50, label %24

24:                                               ; preds = %20
  %25 = mul nsw i64 %10, 27
  %26 = icmp slt i64 %9, %25
  br i1 %26, label %50, label %27

27:                                               ; preds = %24
  %28 = mul nsw i64 %10, 33
  %29 = icmp slt i64 %9, %28
  br i1 %29, label %50, label %30

30:                                               ; preds = %27
  %31 = shl nsw i64 %2, 2
  %32 = mul nsw i64 %4, 7
  %33 = icmp slt i64 %31, %32
  br i1 %33, label %50, label %34

34:                                               ; preds = %30
  %35 = mul nsw i64 %2, 6
  %36 = mul nsw i64 %4, 13
  %37 = icmp slt i64 %35, %36
  br i1 %37, label %50, label %38

38:                                               ; preds = %34
  %39 = mul nsw i64 %4, 9
  %40 = icmp slt i64 %31, %39
  br i1 %40, label %50, label %41

41:                                               ; preds = %38
  %42 = mul nsw i64 %2, 7
  %43 = mul nsw i64 %4, 20
  %44 = icmp slt i64 %42, %43
  br i1 %44, label %50, label %45

45:                                               ; preds = %41
  %46 = mul nsw i64 %2, 9
  %47 = mul nsw i64 %4, 28
  %48 = icmp slt i64 %46, %47
  %49 = select i1 %48, i32 12, i32 13
  br label %50

50:                                               ; preds = %45, %41, %38, %34, %30, %27, %24, %20
  %51 = phi i32 [ 9, %20 ], [ 9, %24 ], [ 10, %27 ], [ 10, %30 ], [ 11, %34 ], [ 11, %38 ], [ 12, %41 ], [ %49, %45 ]
  %52 = phi i32 [ 8, %20 ], [ 7, %24 ], [ 7, %27 ], [ 6, %30 ], [ 6, %34 ], [ 5, %38 ], [ 5, %41 ], [ 4, %45 ]
  %53 = add nuw nsw i32 %52, %51
  %54 = and i32 %53, 1
  %55 = zext nneg i32 %52 to i64
  %56 = mul nsw i64 %55, %2
  %57 = zext nneg i32 %51 to i64
  %58 = mul nsw i64 %57, %4
  %59 = icmp slt i64 %56, %58
  %60 = select i1 %59, i64 %4, i64 %2
  %61 = select i1 %59, i64 %55, i64 %57
  %62 = add nsw i64 %60, -1
  %63 = udiv i64 %62, %61
  %64 = add nuw nsw i64 %63, 1
  %65 = add nsw i32 %51, -1
  %66 = add nsw i32 %52, -1
  %67 = zext nneg i32 %65 to i64
  %68 = mul nsw i64 %64, %67
  %69 = sub nsw i64 %2, %68
  %70 = zext nneg i32 %66 to i64
  %71 = mul nsw i64 %64, %70
  %72 = sub nsw i64 %4, %71
  %73 = icmp eq i32 %54, 0
  br i1 %73, label %84, label %74

74:                                               ; preds = %50
  %75 = icmp slt i64 %69, 1
  br i1 %75, label %76, label %79, !prof !54

76:                                               ; preds = %74
  %77 = add nsw i32 %51, -2
  %78 = add nsw i64 %69, %64
  br label %84

79:                                               ; preds = %74
  %80 = icmp slt i64 %72, 1
  br i1 %80, label %81, label %84, !prof !54

81:                                               ; preds = %79
  %82 = add nsw i32 %52, -2
  %83 = add nsw i64 %72, %64
  br label %84

84:                                               ; preds = %81, %79, %76, %50, %13
  %85 = phi i64 [ %16, %13 ], [ %64, %76 ], [ %64, %81 ], [ %64, %79 ], [ %64, %50 ]
  %86 = phi i64 [ %18, %13 ], [ %78, %76 ], [ %69, %81 ], [ %69, %79 ], [ %69, %50 ]
  %87 = phi i64 [ %19, %13 ], [ %72, %76 ], [ %83, %81 ], [ %72, %79 ], [ %72, %50 ]
  %88 = phi i32 [ 7, %13 ], [ %77, %76 ], [ %65, %81 ], [ %65, %79 ], [ %65, %50 ]
  %89 = phi i32 [ 7, %13 ], [ %66, %76 ], [ %82, %81 ], [ %66, %79 ], [ %66, %50 ]
  %90 = phi i1 [ true, %13 ], [ true, %76 ], [ true, %81 ], [ false, %79 ], [ true, %50 ]
  %91 = phi i32 [ 0, %13 ], [ 0, %76 ], [ 0, %81 ], [ 1, %79 ], [ 0, %50 ]
  %92 = mul nsw i64 %85, 13
  %93 = getelementptr inbounds i64, ptr %0, i64 %92
  %94 = getelementptr inbounds i8, ptr %93, i64 16
  %95 = mul i64 %85, 88
  %96 = getelementptr inbounds i8, ptr %0, i64 %95
  %97 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 3, ptr noundef %0) #16
  %98 = mul nsw i64 %85, 12
  %99 = getelementptr inbounds i64, ptr %5, i64 %98
  %100 = getelementptr inbounds i8, ptr %99, i64 32
  %101 = getelementptr inbounds i64, ptr %0, i64 %98
  %102 = getelementptr inbounds i8, ptr %101, i64 8
  %103 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 3, ptr noundef %0) #16
  %104 = xor i32 %103, %97
  %105 = add nsw i64 %85, 1
  %106 = icmp sgt i64 %85, 98
  br i1 %106, label %110, label %107

107:                                              ; preds = %84
  %108 = getelementptr inbounds i64, ptr %5, i64 %92
  %109 = getelementptr inbounds i8, ptr %108, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %109) #16
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %109) #16
  br label %121

110:                                              ; preds = %84
  %111 = icmp sgt i64 %85, 298
  br i1 %111, label %115, label %112

112:                                              ; preds = %110
  %113 = getelementptr inbounds i64, ptr %5, i64 %92
  %114 = getelementptr inbounds i8, ptr %113, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %114) #16
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %114) #16
  br label %121

115:                                              ; preds = %110
  %116 = icmp sgt i64 %85, 348
  %117 = getelementptr inbounds i64, ptr %5, i64 %92
  %118 = getelementptr inbounds i8, ptr %117, i64 40
  br i1 %116, label %120, label %119

119:                                              ; preds = %115
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %118) #16
  tail call void @__gmpn_toom44_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %118) #16
  br label %121

120:                                              ; preds = %115
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %118) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %118) #16
  br label %121

121:                                              ; preds = %120, %119, %112, %107
  %122 = shl nsw i64 %85, 1
  %123 = or disjoint i64 %122, 1
  %124 = add nuw nsw i32 %91, 1
  %125 = mul nuw nsw i32 %124, 3
  %126 = mul nuw nsw i32 %91, 3
  tail call void @__gmpn_toom_couple_handling(ptr noundef %5, i64 noundef %123, ptr noundef %0, i32 noundef %104, i64 noundef %85, i32 noundef %125, i32 noundef %126) #16
  %127 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 2, ptr noundef %0) #16
  %128 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 2, ptr noundef %0) #16
  %129 = xor i32 %128, %127
  br i1 %106, label %136, label %130

130:                                              ; preds = %121
  %131 = getelementptr inbounds i64, ptr %5, i64 %92
  %132 = getelementptr inbounds i8, ptr %131, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %132) #16
  %133 = mul i64 %85, 24
  %134 = getelementptr inbounds i8, ptr %5, i64 %133
  %135 = getelementptr inbounds i8, ptr %134, i64 8
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %135, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %132) #16
  br label %150

136:                                              ; preds = %121
  %137 = icmp sgt i64 %85, 298
  %138 = mul i64 %85, 24
  %139 = getelementptr inbounds i8, ptr %5, i64 %138
  %140 = getelementptr inbounds i8, ptr %139, i64 8
  br i1 %137, label %144, label %141

141:                                              ; preds = %136
  %142 = getelementptr inbounds i64, ptr %5, i64 %92
  %143 = getelementptr inbounds i8, ptr %142, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %143) #16
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %140, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %143) #16
  br label %150

144:                                              ; preds = %136
  %145 = icmp sgt i64 %85, 348
  %146 = getelementptr inbounds i64, ptr %5, i64 %92
  %147 = getelementptr inbounds i8, ptr %146, i64 40
  br i1 %145, label %149, label %148

148:                                              ; preds = %144
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %147) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %140, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %147) #16
  br label %150

149:                                              ; preds = %144
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %147) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %140, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %147) #16
  br label %150

150:                                              ; preds = %149, %148, %141, %130
  %151 = mul nsw i64 %85, 3
  %152 = getelementptr inbounds i64, ptr %5, i64 %151
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = shl nuw nsw i32 %124, 1
  %155 = shl nuw nsw i32 %91, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %153, i64 noundef %123, ptr noundef %0, i32 noundef %129, i64 noundef %85, i32 noundef %154, i32 noundef %155) #16
  %156 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, ptr noundef %0) #16
  %157 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, ptr noundef %0) #16
  %158 = xor i32 %157, %156
  br i1 %106, label %165, label %159

159:                                              ; preds = %150
  %160 = getelementptr inbounds i64, ptr %5, i64 %92
  %161 = getelementptr inbounds i8, ptr %160, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %161) #16
  %162 = mul i64 %85, 48
  %163 = getelementptr inbounds i8, ptr %5, i64 %162
  %164 = getelementptr inbounds i8, ptr %163, i64 16
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %164, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %161) #16
  br label %179

165:                                              ; preds = %150
  %166 = icmp sgt i64 %85, 298
  %167 = mul i64 %85, 48
  %168 = getelementptr inbounds i8, ptr %5, i64 %167
  %169 = getelementptr inbounds i8, ptr %168, i64 16
  br i1 %166, label %173, label %170

170:                                              ; preds = %165
  %171 = getelementptr inbounds i64, ptr %5, i64 %92
  %172 = getelementptr inbounds i8, ptr %171, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %172) #16
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %169, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %172) #16
  br label %179

173:                                              ; preds = %165
  %174 = icmp sgt i64 %85, 348
  %175 = getelementptr inbounds i64, ptr %5, i64 %92
  %176 = getelementptr inbounds i8, ptr %175, i64 40
  br i1 %174, label %178, label %177

177:                                              ; preds = %173
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %176) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %169, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %176) #16
  br label %179

178:                                              ; preds = %173
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %176) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %169, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %176) #16
  br label %179

179:                                              ; preds = %178, %177, %170, %159
  %180 = mul i64 %85, 48
  %181 = getelementptr inbounds i8, ptr %5, i64 %180
  %182 = getelementptr inbounds i8, ptr %181, i64 16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %182, i64 noundef %123, ptr noundef %0, i32 noundef %158, i64 noundef %85, i32 noundef 1, i32 noundef 2) #16
  %183 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 3, ptr noundef %0) #16
  %184 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 3, ptr noundef %0) #16
  %185 = xor i32 %184, %183
  br i1 %106, label %192, label %186

186:                                              ; preds = %179
  %187 = getelementptr inbounds i64, ptr %5, i64 %92
  %188 = getelementptr inbounds i8, ptr %187, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %188) #16
  %189 = mul i64 %85, 72
  %190 = getelementptr inbounds i8, ptr %5, i64 %189
  %191 = getelementptr inbounds i8, ptr %190, i64 24
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %191, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %188) #16
  br label %206

192:                                              ; preds = %179
  %193 = icmp sgt i64 %85, 298
  %194 = mul i64 %85, 72
  %195 = getelementptr inbounds i8, ptr %5, i64 %194
  %196 = getelementptr inbounds i8, ptr %195, i64 24
  br i1 %193, label %200, label %197

197:                                              ; preds = %192
  %198 = getelementptr inbounds i64, ptr %5, i64 %92
  %199 = getelementptr inbounds i8, ptr %198, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %199) #16
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %196, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %199) #16
  br label %206

200:                                              ; preds = %192
  %201 = icmp sgt i64 %85, 348
  %202 = getelementptr inbounds i64, ptr %5, i64 %92
  %203 = getelementptr inbounds i8, ptr %202, i64 40
  br i1 %201, label %205, label %204

204:                                              ; preds = %200
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %203) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %196, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %203) #16
  br label %206

205:                                              ; preds = %200
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %203) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %196, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %203) #16
  br label %206

206:                                              ; preds = %205, %204, %197, %186
  %207 = mul i64 %85, 72
  %208 = getelementptr inbounds i8, ptr %5, i64 %207
  %209 = getelementptr inbounds i8, ptr %208, i64 24
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %209, i64 noundef %123, ptr noundef %0, i32 noundef %185, i64 noundef %85, i32 noundef 3, i32 noundef 6) #16
  %210 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 1, ptr noundef %0) #16
  %211 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 1, ptr noundef %0) #16
  %212 = xor i32 %211, %210
  br i1 %106, label %217, label %213

213:                                              ; preds = %206
  %214 = getelementptr inbounds i64, ptr %5, i64 %92
  %215 = getelementptr inbounds i8, ptr %214, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %215) #16
  %216 = getelementptr inbounds i64, ptr %0, i64 %151
  tail call void @__gmpn_toom22_mul(ptr noundef %216, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %215) #16
  br label %229

217:                                              ; preds = %206
  %218 = icmp sgt i64 %85, 298
  %219 = getelementptr inbounds i64, ptr %0, i64 %151
  br i1 %218, label %223, label %220

220:                                              ; preds = %217
  %221 = getelementptr inbounds i64, ptr %5, i64 %92
  %222 = getelementptr inbounds i8, ptr %221, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %222) #16
  tail call void @__gmpn_toom33_mul(ptr noundef %219, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %222) #16
  br label %229

223:                                              ; preds = %217
  %224 = icmp sgt i64 %85, 348
  %225 = getelementptr inbounds i64, ptr %5, i64 %92
  %226 = getelementptr inbounds i8, ptr %225, i64 40
  br i1 %224, label %228, label %227

227:                                              ; preds = %223
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %226) #16
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %219, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %226) #16
  br label %229

228:                                              ; preds = %223
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %226) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %219, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %226) #16
  br label %229

229:                                              ; preds = %228, %227, %220, %213
  %230 = getelementptr inbounds i64, ptr %0, i64 %151
  tail call void @__gmpn_toom_couple_handling(ptr noundef %230, i64 noundef %123, ptr noundef %0, i32 noundef %212, i64 noundef %85, i32 noundef %124, i32 noundef %91) #16
  %231 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, ptr noundef %0) #16
  %232 = icmp eq i32 %89, 3
  br i1 %232, label %233, label %235, !prof !54

233:                                              ; preds = %229
  %234 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %100, ptr noundef nonnull %102, ptr noundef %3, i64 noundef %85, i64 noundef %87, ptr noundef %0) #16
  br label %237

235:                                              ; preds = %229
  %236 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, ptr noundef %0) #16
  br label %237

237:                                              ; preds = %235, %233
  %238 = phi i32 [ %234, %233 ], [ %236, %235 ]
  %239 = xor i32 %238, %231
  br i1 %106, label %245, label %240

240:                                              ; preds = %237
  %241 = getelementptr inbounds i64, ptr %5, i64 %92
  %242 = getelementptr inbounds i8, ptr %241, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %242) #16
  %243 = mul i64 %85, 56
  %244 = getelementptr inbounds i8, ptr %0, i64 %243
  tail call void @__gmpn_toom22_mul(ptr noundef %244, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %242) #16
  br label %258

245:                                              ; preds = %237
  %246 = icmp sgt i64 %85, 298
  %247 = mul i64 %85, 56
  %248 = getelementptr inbounds i8, ptr %0, i64 %247
  br i1 %246, label %252, label %249

249:                                              ; preds = %245
  %250 = getelementptr inbounds i64, ptr %5, i64 %92
  %251 = getelementptr inbounds i8, ptr %250, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %251) #16
  tail call void @__gmpn_toom33_mul(ptr noundef %248, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %251) #16
  br label %258

252:                                              ; preds = %245
  %253 = icmp sgt i64 %85, 348
  %254 = getelementptr inbounds i64, ptr %5, i64 %92
  %255 = getelementptr inbounds i8, ptr %254, i64 40
  br i1 %253, label %257, label %256

256:                                              ; preds = %252
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %255) #16
  tail call void @__gmpn_toom44_mul(ptr noundef %248, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %255) #16
  br label %258

257:                                              ; preds = %252
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %255) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef %248, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %255) #16
  br label %258

258:                                              ; preds = %257, %256, %249, %240
  %259 = mul i64 %85, 56
  %260 = getelementptr inbounds i8, ptr %0, i64 %259
  tail call void @__gmpn_toom_couple_handling(ptr noundef %260, i64 noundef %123, ptr noundef %0, i32 noundef %239, i64 noundef %85, i32 noundef 0, i32 noundef 0) #16
  %261 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 2, ptr noundef %0) #16
  %262 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 2, ptr noundef %0) #16
  %263 = xor i32 %262, %261
  br i1 %106, label %267, label %264

264:                                              ; preds = %258
  %265 = getelementptr inbounds i64, ptr %5, i64 %92
  %266 = getelementptr inbounds i8, ptr %265, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %266) #16
  tail call void @__gmpn_toom22_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %266) #16
  br label %278

267:                                              ; preds = %258
  %268 = icmp sgt i64 %85, 298
  br i1 %268, label %272, label %269

269:                                              ; preds = %267
  %270 = getelementptr inbounds i64, ptr %5, i64 %92
  %271 = getelementptr inbounds i8, ptr %270, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %271) #16
  tail call void @__gmpn_toom33_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %271) #16
  br label %278

272:                                              ; preds = %267
  %273 = icmp sgt i64 %85, 348
  %274 = getelementptr inbounds i64, ptr %5, i64 %92
  %275 = getelementptr inbounds i8, ptr %274, i64 40
  br i1 %273, label %277, label %276

276:                                              ; preds = %272
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %275) #16
  tail call void @__gmpn_toom44_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %275) #16
  br label %278

277:                                              ; preds = %272
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %275) #16
  tail call void @__gmpn_toom6h_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %275) #16
  br label %278

278:                                              ; preds = %277, %276, %269, %264
  tail call void @__gmpn_toom_couple_handling(ptr noundef %96, i64 noundef %123, ptr noundef %0, i32 noundef %263, i64 noundef %85, i32 noundef 2, i32 noundef 4) #16
  %279 = icmp sgt i64 %85, 99
  br i1 %279, label %281, label %280

280:                                              ; preds = %278
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #16
  br label %288

281:                                              ; preds = %278
  %282 = icmp sgt i64 %85, 299
  br i1 %282, label %284, label %283

283:                                              ; preds = %281
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #16
  br label %288

284:                                              ; preds = %281
  %285 = icmp sgt i64 %85, 349
  br i1 %285, label %287, label %286

286:                                              ; preds = %284
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #16
  br label %288

287:                                              ; preds = %284
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #16
  br label %288

288:                                              ; preds = %287, %286, %283, %280
  br i1 %90, label %309, label %289, !prof !68

289:                                              ; preds = %288
  %290 = icmp sgt i64 %86, %87
  %291 = mul i64 %85, 120
  %292 = getelementptr inbounds i8, ptr %0, i64 %291
  br i1 %290, label %293, label %301

293:                                              ; preds = %289
  %294 = zext nneg i32 %88 to i64
  %295 = mul nsw i64 %85, %294
  %296 = getelementptr inbounds i64, ptr %1, i64 %295
  %297 = zext nneg i32 %89 to i64
  %298 = mul nsw i64 %85, %297
  %299 = getelementptr inbounds i64, ptr %3, i64 %298
  %300 = tail call i64 @__gmpn_mul(ptr noundef %292, ptr noundef %296, i64 noundef %86, ptr noundef %299, i64 noundef %87) #16
  br label %309

301:                                              ; preds = %289
  %302 = zext nneg i32 %89 to i64
  %303 = mul nsw i64 %85, %302
  %304 = getelementptr inbounds i64, ptr %3, i64 %303
  %305 = zext nneg i32 %88 to i64
  %306 = mul nsw i64 %85, %305
  %307 = getelementptr inbounds i64, ptr %1, i64 %306
  %308 = tail call i64 @__gmpn_mul(ptr noundef %292, ptr noundef %304, i64 noundef %87, ptr noundef %307, i64 noundef %86) #16
  br label %309

309:                                              ; preds = %301, %293, %288
  %310 = add nsw i64 %87, %86
  tail call void @__gmpn_toom_interpolate_16pts(ptr noundef %0, ptr noundef nonnull %209, ptr noundef nonnull %182, ptr noundef nonnull %153, ptr noundef %5, i64 noundef %85, i64 noundef %310, i32 noundef %91, ptr noundef nonnull %100) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #5 {
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #16
  store ptr null, ptr %6, align 8, !tbaa !7
  %7 = icmp eq ptr %1, %3
  %8 = icmp eq i64 %2, %4
  %9 = and i1 %7, %8
  br i1 %9, label %10, label %20

10:                                               ; preds = %5
  %11 = shl nsw i64 %2, 1
  %12 = tail call i64 @__gmpn_sqrmod_bnm1_next_size(i64 noundef %11) #17
  %13 = ashr i64 %12, 1
  %14 = add nsw i64 %12, 3
  %15 = icmp slt i64 %13, %2
  %16 = select i1 %15, i64 %2, i64 0
  %17 = add nsw i64 %14, %16
  %18 = shl i64 %17, 3
  %19 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %18) #16
  call void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %12, ptr noundef %1, i64 noundef %2, ptr noundef %19) #16
  br label %32

20:                                               ; preds = %5
  %21 = add nsw i64 %4, %2
  %22 = tail call i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %21) #17
  %23 = ashr i64 %22, 1
  %24 = icmp slt i64 %23, %2
  %25 = icmp slt i64 %23, %4
  %26 = select i1 %25, i64 %22, i64 %23
  %27 = select i1 %24, i64 %26, i64 0
  %28 = add nsw i64 %22, 4
  %29 = add nsw i64 %28, %27
  %30 = shl i64 %29, 3
  %31 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %30) #16
  call void @__gmpn_mulmod_bnm1(ptr noundef %0, i64 noundef %22, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %31) #16
  br label %32

32:                                               ; preds = %20, %10
  %33 = load ptr, ptr %6, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %33) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #16
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_sqrmod_bnm1_next_size(i64 noundef %0) local_unnamed_addr #7 {
  %2 = icmp sgt i64 %0, 15
  br i1 %2, label %3, label %24

3:                                                ; preds = %1
  %4 = icmp sgt i64 %0, 60
  br i1 %4, label %8, label %5

5:                                                ; preds = %3
  %6 = add nuw nsw i64 %0, 1
  %7 = and i64 %6, 9223372036854775806
  br label %24

8:                                                ; preds = %3
  %9 = icmp sgt i64 %0, 120
  br i1 %9, label %13, label %10

10:                                               ; preds = %8
  %11 = add nuw nsw i64 %0, 3
  %12 = and i64 %11, 9223372036854775804
  br label %24

13:                                               ; preds = %8
  %14 = icmp ugt i64 %0, 718
  br i1 %14, label %18, label %15

15:                                               ; preds = %13
  %16 = add nuw nsw i64 %0, 7
  %17 = and i64 %16, 2040
  br label %24

18:                                               ; preds = %13
  %19 = add nuw nsw i64 %0, 1
  %20 = lshr i64 %19, 1
  %21 = tail call i32 @__gmpn_fft_best_k(i64 noundef %20, i32 noundef 1) #17
  %22 = tail call i64 @__gmpn_fft_next_size(i64 noundef %20, i32 noundef %21) #17
  %23 = shl nsw i64 %22, 1
  br label %24

24:                                               ; preds = %18, %15, %10, %5, %1
  %25 = phi i64 [ %23, %18 ], [ %17, %15 ], [ %12, %10 ], [ %7, %5 ], [ %0, %1 ]
  ret i64 %25
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4) local_unnamed_addr #5 {
  %6 = alloca ptr, align 8
  %7 = and i64 %1, 1
  %8 = icmp eq i64 %7, 0
  %9 = icmp sgt i64 %1, 15
  %10 = and i1 %9, %8
  br i1 %10, label %42, label %11

11:                                               ; preds = %5
  %12 = icmp slt i64 %3, %1
  br i1 %12, label %13, label %30, !prof !54

13:                                               ; preds = %11
  %14 = shl nsw i64 %3, 1
  %15 = icmp sgt i64 %14, %1
  br i1 %15, label %17, label %16, !prof !68

16:                                               ; preds = %13
  tail call void @__gmpn_sqr(ptr noundef %0, ptr noundef %2, i64 noundef %3) #16
  br label %286

17:                                               ; preds = %13
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %2, i64 noundef %3) #16
  %18 = getelementptr inbounds i64, ptr %4, i64 %1
  %19 = sub nsw i64 %14, %1
  %20 = tail call i64 @__gmpn_add(ptr noundef %0, ptr noundef %4, i64 noundef %1, ptr noundef %18, i64 noundef %19)
  %21 = load i64, ptr %0, align 8, !tbaa !15
  %22 = add i64 %21, %20
  store i64 %22, ptr %0, align 8, !tbaa !15
  %23 = icmp ult i64 %22, %20
  br i1 %23, label %24, label %286

24:                                               ; preds = %24, %17
  %25 = phi ptr [ %26, %24 ], [ %0, %17 ]
  %26 = getelementptr inbounds i8, ptr %25, i64 8
  %27 = load i64, ptr %26, align 8, !tbaa !15
  %28 = add i64 %27, 1
  store i64 %28, ptr %26, align 8, !tbaa !15
  %29 = icmp eq i64 %28, 0
  br i1 %29, label %24, label %286, !llvm.loop !90

30:                                               ; preds = %11
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %2, i64 noundef %1) #16
  %31 = getelementptr inbounds i64, ptr %4, i64 %1
  %32 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %4, ptr noundef %31, i64 noundef %1) #16
  %33 = load i64, ptr %0, align 8, !tbaa !15
  %34 = add i64 %33, %32
  store i64 %34, ptr %0, align 8, !tbaa !15
  %35 = icmp ult i64 %34, %32
  br i1 %35, label %36, label %286

36:                                               ; preds = %36, %30
  %37 = phi ptr [ %38, %36 ], [ %0, %30 ]
  %38 = getelementptr inbounds i8, ptr %37, i64 8
  %39 = load i64, ptr %38, align 8, !tbaa !15
  %40 = add i64 %39, 1
  store i64 %40, ptr %38, align 8, !tbaa !15
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %36, label %286, !llvm.loop !91

42:                                               ; preds = %5
  %43 = lshr exact i64 %1, 1
  %44 = icmp slt i64 %43, %3
  br i1 %44, label %45, label %129, !prof !68

45:                                               ; preds = %42
  %46 = getelementptr inbounds i64, ptr %4, i64 %43
  %47 = getelementptr inbounds i64, ptr %2, i64 %43
  %48 = sub nsw i64 %3, %43
  %49 = icmp eq i64 %48, 0
  br i1 %49, label %63, label %50

50:                                               ; preds = %45
  %51 = tail call i64 @__gmpn_add_n(ptr noundef %4, ptr noundef %2, ptr noundef nonnull %47, i64 noundef %48) #16
  %52 = icmp eq i64 %51, 0
  br i1 %52, label %63, label %53

53:                                               ; preds = %56, %50
  %54 = phi i64 [ %60, %56 ], [ %48, %50 ]
  %55 = icmp slt i64 %54, %43
  br i1 %55, label %56, label %75

56:                                               ; preds = %53
  %57 = getelementptr inbounds i64, ptr %2, i64 %54
  %58 = load i64, ptr %57, align 8, !tbaa !15
  %59 = add i64 %58, 1
  %60 = add nsw i64 %54, 1
  %61 = getelementptr inbounds i64, ptr %4, i64 %54
  store i64 %59, ptr %61, align 8, !tbaa !15
  %62 = icmp eq i64 %59, 0
  br i1 %62, label %53, label %63, !llvm.loop !92

63:                                               ; preds = %56, %50, %45
  %64 = phi i64 [ %48, %50 ], [ 0, %45 ], [ %60, %56 ]
  %65 = icmp ne ptr %4, %2
  %66 = icmp slt i64 %64, %43
  %67 = select i1 %65, i1 %66, i1 false
  br i1 %67, label %68, label %75

68:                                               ; preds = %68, %63
  %69 = phi i64 [ %73, %68 ], [ %64, %63 ]
  %70 = getelementptr inbounds i64, ptr %2, i64 %69
  %71 = load i64, ptr %70, align 8, !tbaa !15
  %72 = getelementptr inbounds i64, ptr %4, i64 %69
  store i64 %71, ptr %72, align 8, !tbaa !15
  %73 = add nsw i64 %69, 1
  %74 = icmp eq i64 %73, %43
  br i1 %74, label %75, label %68, !llvm.loop !93

75:                                               ; preds = %68, %63, %53
  %76 = phi i64 [ 0, %63 ], [ 0, %68 ], [ 1, %53 ]
  %77 = load i64, ptr %4, align 8, !tbaa !15
  %78 = add i64 %77, %76
  store i64 %78, ptr %4, align 8, !tbaa !15
  %79 = icmp ult i64 %78, %76
  br i1 %79, label %80, label %86

80:                                               ; preds = %80, %75
  %81 = phi ptr [ %82, %80 ], [ %4, %75 ]
  %82 = getelementptr inbounds i8, ptr %81, i64 8
  %83 = load i64, ptr %82, align 8, !tbaa !15
  %84 = add i64 %83, 1
  store i64 %84, ptr %82, align 8, !tbaa !15
  %85 = icmp eq i64 %84, 0
  br i1 %85, label %80, label %86, !llvm.loop !94

86:                                               ; preds = %80, %75
  tail call void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %43, ptr noundef %4, i64 noundef %43, ptr noundef nonnull %46)
  %87 = getelementptr inbounds i64, ptr %4, i64 %1
  %88 = getelementptr inbounds i8, ptr %87, i64 16
  br i1 %49, label %102, label %89

89:                                               ; preds = %86
  %90 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %88, ptr noundef %2, ptr noundef nonnull %47, i64 noundef %48) #16
  %91 = icmp eq i64 %90, 0
  br i1 %91, label %102, label %92

92:                                               ; preds = %95, %89
  %93 = phi i64 [ %99, %95 ], [ %48, %89 ]
  %94 = icmp slt i64 %93, %43
  br i1 %94, label %95, label %114

95:                                               ; preds = %92
  %96 = getelementptr inbounds i64, ptr %2, i64 %93
  %97 = load i64, ptr %96, align 8, !tbaa !15
  %98 = add i64 %97, -1
  %99 = add nsw i64 %93, 1
  %100 = getelementptr inbounds i64, ptr %88, i64 %93
  store i64 %98, ptr %100, align 8, !tbaa !15
  %101 = icmp eq i64 %97, 0
  br i1 %101, label %92, label %102, !llvm.loop !95

102:                                              ; preds = %95, %89, %86
  %103 = phi i64 [ %48, %89 ], [ 0, %86 ], [ %99, %95 ]
  %104 = icmp ne ptr %88, %2
  %105 = icmp slt i64 %103, %43
  %106 = select i1 %104, i1 %105, i1 false
  br i1 %106, label %107, label %114

107:                                              ; preds = %107, %102
  %108 = phi i64 [ %112, %107 ], [ %103, %102 ]
  %109 = getelementptr inbounds i64, ptr %2, i64 %108
  %110 = load i64, ptr %109, align 8, !tbaa !15
  %111 = getelementptr inbounds i64, ptr %88, i64 %108
  store i64 %110, ptr %111, align 8, !tbaa !15
  %112 = add nsw i64 %108, 1
  %113 = icmp eq i64 %112, %43
  br i1 %113, label %114, label %107, !llvm.loop !96

114:                                              ; preds = %107, %102, %92
  %115 = phi i64 [ 0, %102 ], [ 0, %107 ], [ 1, %92 ]
  %116 = getelementptr inbounds i64, ptr %88, i64 %43
  store i64 0, ptr %116, align 8, !tbaa !15
  %117 = load i64, ptr %88, align 8, !tbaa !15
  %118 = add i64 %117, %115
  store i64 %118, ptr %88, align 8, !tbaa !15
  %119 = icmp ult i64 %118, %115
  br i1 %119, label %120, label %126

120:                                              ; preds = %120, %114
  %121 = phi ptr [ %122, %120 ], [ %88, %114 ]
  %122 = getelementptr inbounds i8, ptr %121, i64 8
  %123 = load i64, ptr %122, align 8, !tbaa !15
  %124 = add i64 %123, 1
  store i64 %124, ptr %122, align 8, !tbaa !15
  %125 = icmp eq i64 %124, 0
  br i1 %125, label %120, label %126, !llvm.loop !97

126:                                              ; preds = %120, %114
  %127 = load i64, ptr %116, align 8, !tbaa !15
  %128 = add i64 %127, %43
  br label %130

129:                                              ; preds = %42
  tail call void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %43, ptr noundef %2, i64 noundef %3, ptr noundef %4)
  br label %130

130:                                              ; preds = %129, %126
  %131 = phi ptr [ %88, %126 ], [ %2, %129 ]
  %132 = phi i64 [ %128, %126 ], [ %3, %129 ]
  %133 = icmp ugt i64 %1, 598
  br i1 %133, label %134, label %149

134:                                              ; preds = %130
  %135 = tail call i32 @__gmpn_fft_best_k(i64 noundef %43, i32 noundef 1) #17
  %136 = shl nsw i32 -1, %135
  %137 = xor i32 %136, -1
  %138 = zext nneg i32 %137 to i64
  %139 = and i64 %43, %138
  %140 = icmp eq i64 %139, 0
  br i1 %140, label %149, label %141

141:                                              ; preds = %141, %134
  %142 = phi i32 [ %145, %141 ], [ %137, %134 ]
  %143 = phi i32 [ %144, %141 ], [ %135, %134 ]
  %144 = add nsw i32 %143, -1
  %145 = lshr i32 %142, 1
  %146 = zext nneg i32 %145 to i64
  %147 = and i64 %43, %146
  %148 = icmp eq i64 %147, 0
  br i1 %148, label %149, label %141, !llvm.loop !98

149:                                              ; preds = %141, %134, %130
  %150 = phi i32 [ 0, %130 ], [ %135, %134 ], [ %144, %141 ]
  %151 = icmp sgt i32 %150, 3
  br i1 %151, label %152, label %155

152:                                              ; preds = %149
  %153 = tail call i64 @__gmpn_mul_fft(ptr noundef %4, i64 noundef %43, ptr noundef %131, i64 noundef %132, ptr noundef %131, i64 noundef %132, i32 noundef %150) #16
  %154 = getelementptr inbounds i64, ptr %4, i64 %43
  store i64 %153, ptr %154, align 8, !tbaa !15
  br label %220

155:                                              ; preds = %149
  %156 = icmp eq ptr %131, %2
  br i1 %156, label %157, label %171, !prof !54

157:                                              ; preds = %155
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %2, i64 noundef %3) #16
  %158 = shl nsw i64 %3, 1
  %159 = sub nsw i64 %158, %43
  %160 = getelementptr inbounds i64, ptr %4, i64 %43
  %161 = tail call i64 @__gmpn_sub(ptr noundef %4, ptr noundef %4, i64 noundef %43, ptr noundef nonnull %160, i64 noundef %159)
  store i64 0, ptr %160, align 8, !tbaa !15
  %162 = load i64, ptr %4, align 8, !tbaa !15
  %163 = add i64 %162, %161
  store i64 %163, ptr %4, align 8, !tbaa !15
  %164 = icmp ult i64 %163, %161
  br i1 %164, label %165, label %220

165:                                              ; preds = %165, %157
  %166 = phi ptr [ %167, %165 ], [ %4, %157 ]
  %167 = getelementptr inbounds i8, ptr %166, i64 8
  %168 = load i64, ptr %167, align 8, !tbaa !15
  %169 = add i64 %168, 1
  store i64 %169, ptr %167, align 8, !tbaa !15
  %170 = icmp eq i64 %169, 0
  br i1 %170, label %165, label %220, !llvm.loop !99

171:                                              ; preds = %155
  %172 = getelementptr inbounds i64, ptr %131, i64 %43
  %173 = load i64, ptr %172, align 8, !tbaa !15
  %174 = icmp eq i64 %173, 0
  br i1 %174, label %178, label %175, !prof !68

175:                                              ; preds = %171
  store i64 1, ptr %4, align 8, !tbaa !15
  %176 = getelementptr i8, ptr %4, i64 8
  %177 = shl nuw i64 %1, 2
  tail call void @llvm.memset.p0.i64(ptr align 8 %176, i8 0, i64 %177, i1 false), !tbaa !15
  br label %220

178:                                              ; preds = %171
  %179 = icmp ugt i64 %1, 48
  br i1 %179, label %180, label %208

180:                                              ; preds = %178
  %181 = urem i64 %43, 3
  %182 = icmp eq i64 %181, 0
  br i1 %182, label %201, label %183

183:                                              ; preds = %180
  %184 = icmp ugt i64 %1, 100
  br i1 %184, label %185, label %208

185:                                              ; preds = %183
  %186 = urem i64 %43, 5
  %187 = icmp eq i64 %186, 0
  br i1 %187, label %201, label %188

188:                                              ; preds = %185
  %189 = urem i64 %43, 7
  %190 = icmp eq i64 %189, 0
  br i1 %190, label %201, label %191

191:                                              ; preds = %188
  %192 = icmp ugt i64 %1, 254
  br i1 %192, label %193, label %208

193:                                              ; preds = %191
  %194 = urem i64 %43, 13
  %195 = icmp eq i64 %194, 0
  br i1 %195, label %201, label %196

196:                                              ; preds = %193
  %197 = icmp ugt i64 %1, 510
  %198 = urem i64 %43, 17
  %199 = icmp eq i64 %198, 0
  %200 = and i1 %197, %199
  br i1 %200, label %201, label %208

201:                                              ; preds = %196, %193, %188, %185, %180
  %202 = phi i32 [ 3, %180 ], [ 5, %185 ], [ 7, %188 ], [ 13, %193 ], [ 17, %196 ]
  %203 = zext nneg i32 %202 to i64
  %204 = udiv i64 %43, %203
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #16
  store ptr null, ptr %6, align 8, !tbaa !7
  %205 = mul i64 %43, 24
  %206 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %205) #16
  call void @__gmpn_sqrmod_bknp1(ptr noundef %4, ptr noundef %131, i64 noundef %204, i32 noundef %202, ptr noundef %206) #16
  %207 = load ptr, ptr %6, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %207) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #16
  br label %220

208:                                              ; preds = %196, %191, %183, %178
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %131, i64 noundef %43) #16
  %209 = getelementptr inbounds i64, ptr %4, i64 %43
  %210 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef nonnull %209, i64 noundef %43) #16
  store i64 0, ptr %209, align 8, !tbaa !15
  %211 = load i64, ptr %4, align 8, !tbaa !15
  %212 = add i64 %211, %210
  store i64 %212, ptr %4, align 8, !tbaa !15
  %213 = icmp ult i64 %212, %210
  br i1 %213, label %214, label %220

214:                                              ; preds = %214, %208
  %215 = phi ptr [ %216, %214 ], [ %4, %208 ]
  %216 = getelementptr inbounds i8, ptr %215, i64 8
  %217 = load i64, ptr %216, align 8, !tbaa !15
  %218 = add i64 %217, 1
  store i64 %218, ptr %216, align 8, !tbaa !15
  %219 = icmp eq i64 %218, 0
  br i1 %219, label %214, label %220, !llvm.loop !100

220:                                              ; preds = %214, %208, %201, %175, %165, %157, %152
  %221 = getelementptr inbounds i64, ptr %4, i64 %43
  %222 = load i64, ptr %221, align 8, !tbaa !15
  %223 = call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %4, i64 noundef %43) #16
  %224 = add i64 %223, %222
  %225 = load i64, ptr %0, align 8, !tbaa !15
  %226 = and i64 %225, 1
  %227 = add i64 %224, %226
  %228 = call i64 @__gmpn_rshift(ptr noundef nonnull %0, ptr noundef nonnull %0, i64 noundef %43, i32 noundef 1) #16
  %229 = shl i64 %227, 63
  %230 = getelementptr i64, ptr %0, i64 %43
  %231 = getelementptr i8, ptr %230, i64 -8
  %232 = load i64, ptr %231, align 8, !tbaa !15
  %233 = or i64 %229, %232
  store i64 %233, ptr %231, align 8, !tbaa !15
  %234 = lshr i64 %227, 1
  %235 = load i64, ptr %0, align 8, !tbaa !15
  %236 = add i64 %235, %234
  store i64 %236, ptr %0, align 8, !tbaa !15
  %237 = icmp ult i64 %236, %234
  br i1 %237, label %238, label %244

238:                                              ; preds = %238, %220
  %239 = phi ptr [ %240, %238 ], [ %0, %220 ]
  %240 = getelementptr inbounds i8, ptr %239, i64 8
  %241 = load i64, ptr %240, align 8, !tbaa !15
  %242 = add i64 %241, 1
  store i64 %242, ptr %240, align 8, !tbaa !15
  %243 = icmp eq i64 %242, 0
  br i1 %243, label %238, label %244, !llvm.loop !101

244:                                              ; preds = %238, %220
  %245 = shl nsw i64 %3, 1
  %246 = icmp slt i64 %245, %1
  br i1 %246, label %247, label %273, !prof !54

247:                                              ; preds = %244
  %248 = sub nsw i64 %245, %43
  %249 = call i64 @__gmpn_sub_n(ptr noundef nonnull %230, ptr noundef nonnull %0, ptr noundef %4, i64 noundef %248) #16
  %250 = load i64, ptr %221, align 8, !tbaa !15
  %251 = getelementptr inbounds i64, ptr %4, i64 %245
  %252 = sub nsw i64 0, %43
  %253 = getelementptr inbounds i64, ptr %251, i64 %252
  %254 = getelementptr inbounds i64, ptr %0, i64 %245
  %255 = getelementptr inbounds i64, ptr %254, i64 %252
  %256 = sub nsw i64 %1, %245
  %257 = call fastcc i64 @mpn_sub_nc(ptr noundef nonnull %253, ptr noundef nonnull %255, ptr noundef nonnull %253, i64 noundef %256, i64 noundef %249)
  %258 = add i64 %257, %250
  %259 = load i64, ptr %0, align 8, !tbaa !15
  %260 = sub i64 %259, %258
  store i64 %260, ptr %0, align 8, !tbaa !15
  %261 = icmp ult i64 %259, %258
  br i1 %261, label %262, label %286

262:                                              ; preds = %247
  %263 = call i64 @llvm.smax.i64(i64 %245, i64 1)
  br label %264

264:                                              ; preds = %267, %262
  %265 = phi i64 [ %271, %267 ], [ 1, %262 ]
  %266 = icmp eq i64 %265, %263
  br i1 %266, label %286, label %267

267:                                              ; preds = %264
  %268 = getelementptr inbounds i64, ptr %0, i64 %265
  %269 = load i64, ptr %268, align 8, !tbaa !15
  %270 = add i64 %269, -1
  store i64 %270, ptr %268, align 8, !tbaa !15
  %271 = add nuw i64 %265, 1
  %272 = icmp eq i64 %269, 0
  br i1 %272, label %264, label %286, !llvm.loop !102

273:                                              ; preds = %244
  %274 = load i64, ptr %221, align 8, !tbaa !15
  %275 = call i64 @__gmpn_sub_n(ptr noundef nonnull %230, ptr noundef nonnull %0, ptr noundef %4, i64 noundef %43) #16
  %276 = add i64 %275, %274
  %277 = load i64, ptr %0, align 8, !tbaa !15
  %278 = sub i64 %277, %276
  store i64 %278, ptr %0, align 8, !tbaa !15
  %279 = icmp ult i64 %277, %276
  br i1 %279, label %280, label %286

280:                                              ; preds = %280, %273
  %281 = phi ptr [ %282, %280 ], [ %0, %273 ]
  %282 = getelementptr inbounds i8, ptr %281, i64 8
  %283 = load i64, ptr %282, align 8, !tbaa !15
  %284 = add i64 %283, -1
  store i64 %284, ptr %282, align 8, !tbaa !15
  %285 = icmp eq i64 %283, 0
  br i1 %285, label %280, label %286, !llvm.loop !103

286:                                              ; preds = %280, %273, %267, %264, %247, %36, %30, %24, %17, %16
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %0) local_unnamed_addr #7 {
  %2 = icmp sgt i64 %0, 15
  br i1 %2, label %3, label %24

3:                                                ; preds = %1
  %4 = icmp sgt i64 %0, 60
  br i1 %4, label %8, label %5

5:                                                ; preds = %3
  %6 = add nuw nsw i64 %0, 1
  %7 = and i64 %6, 9223372036854775806
  br label %24

8:                                                ; preds = %3
  %9 = icmp sgt i64 %0, 120
  br i1 %9, label %13, label %10

10:                                               ; preds = %8
  %11 = add nuw nsw i64 %0, 3
  %12 = and i64 %11, 9223372036854775804
  br label %24

13:                                               ; preds = %8
  %14 = icmp ugt i64 %0, 598
  br i1 %14, label %18, label %15

15:                                               ; preds = %13
  %16 = add nuw nsw i64 %0, 7
  %17 = and i64 %16, 2040
  br label %24

18:                                               ; preds = %13
  %19 = add nuw nsw i64 %0, 1
  %20 = lshr i64 %19, 1
  %21 = tail call i32 @__gmpn_fft_best_k(i64 noundef %20, i32 noundef 0) #17
  %22 = tail call i64 @__gmpn_fft_next_size(i64 noundef %20, i32 noundef %21) #17
  %23 = shl nsw i64 %22, 1
  br label %24

24:                                               ; preds = %18, %15, %10, %5, %1
  %25 = phi i64 [ %23, %18 ], [ %17, %15 ], [ %12, %10 ], [ %7, %5 ], [ %0, %1 ]
  ret i64 %25
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mulmod_bnm1(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, ptr noundef %6) local_unnamed_addr #5 {
  %8 = alloca ptr, align 8
  %9 = and i64 %1, 1
  %10 = icmp eq i64 %9, 0
  %11 = icmp sgt i64 %1, 15
  %12 = and i1 %11, %10
  br i1 %12, label %46, label %13

13:                                               ; preds = %7
  %14 = icmp slt i64 %5, %1
  br i1 %14, label %15, label %34, !prof !54

15:                                               ; preds = %13
  %16 = add nsw i64 %5, %3
  %17 = icmp sgt i64 %16, %1
  br i1 %17, label %20, label %18, !prof !68

18:                                               ; preds = %15
  %19 = tail call i64 @__gmpn_mul(ptr noundef %0, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5) #16
  br label %402

20:                                               ; preds = %15
  %21 = tail call i64 @__gmpn_mul(ptr noundef %6, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5) #16
  %22 = getelementptr inbounds i64, ptr %6, i64 %1
  %23 = sub nsw i64 %16, %1
  %24 = tail call i64 @__gmpn_add(ptr noundef %0, ptr noundef %6, i64 noundef %1, ptr noundef %22, i64 noundef %23)
  %25 = load i64, ptr %0, align 8, !tbaa !15
  %26 = add i64 %25, %24
  store i64 %26, ptr %0, align 8, !tbaa !15
  %27 = icmp ult i64 %26, %24
  br i1 %27, label %28, label %402

28:                                               ; preds = %28, %20
  %29 = phi ptr [ %30, %28 ], [ %0, %20 ]
  %30 = getelementptr inbounds i8, ptr %29, i64 8
  %31 = load i64, ptr %30, align 8, !tbaa !15
  %32 = add i64 %31, 1
  store i64 %32, ptr %30, align 8, !tbaa !15
  %33 = icmp eq i64 %32, 0
  br i1 %33, label %28, label %402, !llvm.loop !104

34:                                               ; preds = %13
  tail call void @__gmpn_mul_n(ptr noundef %6, ptr noundef %2, ptr noundef %4, i64 noundef %1) #16
  %35 = getelementptr inbounds i64, ptr %6, i64 %1
  %36 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %6, ptr noundef %35, i64 noundef %1) #16
  %37 = load i64, ptr %0, align 8, !tbaa !15
  %38 = add i64 %37, %36
  store i64 %38, ptr %0, align 8, !tbaa !15
  %39 = icmp ult i64 %38, %36
  br i1 %39, label %40, label %402

40:                                               ; preds = %40, %34
  %41 = phi ptr [ %42, %40 ], [ %0, %34 ]
  %42 = getelementptr inbounds i8, ptr %41, i64 8
  %43 = load i64, ptr %42, align 8, !tbaa !15
  %44 = add i64 %43, 1
  store i64 %44, ptr %42, align 8, !tbaa !15
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %40, label %402, !llvm.loop !105

46:                                               ; preds = %7
  %47 = lshr exact i64 %1, 1
  %48 = sub nsw i64 0, %47
  %49 = icmp slt i64 %47, %3
  br i1 %49, label %50, label %228, !prof !68

50:                                               ; preds = %46
  %51 = getelementptr inbounds i64, ptr %2, i64 %47
  %52 = sub nsw i64 %3, %47
  %53 = icmp eq i64 %52, 0
  br i1 %53, label %67, label %54

54:                                               ; preds = %50
  %55 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %2, ptr noundef nonnull %51, i64 noundef %52) #16
  %56 = icmp eq i64 %55, 0
  br i1 %56, label %67, label %57

57:                                               ; preds = %60, %54
  %58 = phi i64 [ %64, %60 ], [ %52, %54 ]
  %59 = icmp slt i64 %58, %47
  br i1 %59, label %60, label %79

60:                                               ; preds = %57
  %61 = getelementptr inbounds i64, ptr %2, i64 %58
  %62 = load i64, ptr %61, align 8, !tbaa !15
  %63 = add i64 %62, 1
  %64 = add nsw i64 %58, 1
  %65 = getelementptr inbounds i64, ptr %6, i64 %58
  store i64 %63, ptr %65, align 8, !tbaa !15
  %66 = icmp eq i64 %63, 0
  br i1 %66, label %57, label %67, !llvm.loop !106

67:                                               ; preds = %60, %54, %50
  %68 = phi i64 [ %52, %54 ], [ 0, %50 ], [ %64, %60 ]
  %69 = icmp ne ptr %6, %2
  %70 = icmp slt i64 %68, %47
  %71 = select i1 %69, i1 %70, i1 false
  br i1 %71, label %72, label %79

72:                                               ; preds = %72, %67
  %73 = phi i64 [ %77, %72 ], [ %68, %67 ]
  %74 = getelementptr inbounds i64, ptr %2, i64 %73
  %75 = load i64, ptr %74, align 8, !tbaa !15
  %76 = getelementptr inbounds i64, ptr %6, i64 %73
  store i64 %75, ptr %76, align 8, !tbaa !15
  %77 = add nsw i64 %73, 1
  %78 = icmp eq i64 %77, %47
  br i1 %78, label %79, label %72, !llvm.loop !107

79:                                               ; preds = %72, %67, %57
  %80 = phi i64 [ 0, %67 ], [ 0, %72 ], [ 1, %57 ]
  %81 = load i64, ptr %6, align 8, !tbaa !15
  %82 = add i64 %81, %80
  store i64 %82, ptr %6, align 8, !tbaa !15
  %83 = icmp ult i64 %82, %80
  br i1 %83, label %84, label %90

84:                                               ; preds = %84, %79
  %85 = phi ptr [ %86, %84 ], [ %6, %79 ]
  %86 = getelementptr inbounds i8, ptr %85, i64 8
  %87 = load i64, ptr %86, align 8, !tbaa !15
  %88 = add i64 %87, 1
  store i64 %88, ptr %86, align 8, !tbaa !15
  %89 = icmp eq i64 %88, 0
  br i1 %89, label %84, label %90, !llvm.loop !108

90:                                               ; preds = %84, %79
  %91 = getelementptr inbounds i64, ptr %6, i64 %47
  %92 = icmp slt i64 %47, %5
  br i1 %92, label %93, label %135, !prof !68

93:                                               ; preds = %90
  %94 = sub nsw i64 %5, %47
  %95 = icmp eq i64 %94, 0
  br i1 %95, label %110, label %96

96:                                               ; preds = %93
  %97 = getelementptr inbounds i64, ptr %4, i64 %47
  %98 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %91, ptr noundef %4, ptr noundef nonnull %97, i64 noundef %94) #16
  %99 = icmp eq i64 %98, 0
  br i1 %99, label %110, label %100

100:                                              ; preds = %103, %96
  %101 = phi i64 [ %107, %103 ], [ %94, %96 ]
  %102 = icmp slt i64 %101, %47
  br i1 %102, label %103, label %122

103:                                              ; preds = %100
  %104 = getelementptr inbounds i64, ptr %4, i64 %101
  %105 = load i64, ptr %104, align 8, !tbaa !15
  %106 = add i64 %105, 1
  %107 = add nsw i64 %101, 1
  %108 = getelementptr inbounds i64, ptr %91, i64 %101
  store i64 %106, ptr %108, align 8, !tbaa !15
  %109 = icmp eq i64 %106, 0
  br i1 %109, label %100, label %110, !llvm.loop !106

110:                                              ; preds = %103, %96, %93
  %111 = phi i64 [ %94, %96 ], [ 0, %93 ], [ %107, %103 ]
  %112 = icmp ne ptr %91, %4
  %113 = icmp slt i64 %111, %47
  %114 = select i1 %112, i1 %113, i1 false
  br i1 %114, label %115, label %122

115:                                              ; preds = %115, %110
  %116 = phi i64 [ %120, %115 ], [ %111, %110 ]
  %117 = getelementptr inbounds i64, ptr %4, i64 %116
  %118 = load i64, ptr %117, align 8, !tbaa !15
  %119 = getelementptr inbounds i64, ptr %91, i64 %116
  store i64 %118, ptr %119, align 8, !tbaa !15
  %120 = add nsw i64 %116, 1
  %121 = icmp eq i64 %120, %47
  br i1 %121, label %122, label %115, !llvm.loop !107

122:                                              ; preds = %115, %110, %100
  %123 = phi i64 [ 0, %110 ], [ 0, %115 ], [ 1, %100 ]
  %124 = load i64, ptr %91, align 8, !tbaa !15
  %125 = add i64 %124, %123
  store i64 %125, ptr %91, align 8, !tbaa !15
  %126 = icmp ult i64 %125, %123
  br i1 %126, label %127, label %133

127:                                              ; preds = %127, %122
  %128 = phi ptr [ %129, %127 ], [ %91, %122 ]
  %129 = getelementptr inbounds i8, ptr %128, i64 8
  %130 = load i64, ptr %129, align 8, !tbaa !15
  %131 = add i64 %130, 1
  store i64 %131, ptr %129, align 8, !tbaa !15
  %132 = icmp eq i64 %131, 0
  br i1 %132, label %127, label %133, !llvm.loop !109

133:                                              ; preds = %127, %122
  %134 = getelementptr inbounds i64, ptr %91, i64 %47
  br label %135

135:                                              ; preds = %133, %90
  %136 = phi ptr [ %134, %133 ], [ %91, %90 ]
  %137 = phi i64 [ %47, %133 ], [ %5, %90 ]
  %138 = phi ptr [ %91, %133 ], [ %4, %90 ]
  tail call void @__gmpn_mulmod_bnm1(ptr noundef %0, i64 noundef %47, ptr noundef %6, i64 noundef %47, ptr noundef %138, i64 noundef %137, ptr noundef %136)
  %139 = getelementptr inbounds i64, ptr %6, i64 %1
  %140 = getelementptr inbounds i8, ptr %139, i64 16
  br i1 %53, label %154, label %141

141:                                              ; preds = %135
  %142 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %140, ptr noundef %2, ptr noundef nonnull %51, i64 noundef %52) #16
  %143 = icmp eq i64 %142, 0
  br i1 %143, label %154, label %144

144:                                              ; preds = %147, %141
  %145 = phi i64 [ %151, %147 ], [ %52, %141 ]
  %146 = icmp slt i64 %145, %47
  br i1 %146, label %147, label %166

147:                                              ; preds = %144
  %148 = getelementptr inbounds i64, ptr %2, i64 %145
  %149 = load i64, ptr %148, align 8, !tbaa !15
  %150 = add i64 %149, -1
  %151 = add nsw i64 %145, 1
  %152 = getelementptr inbounds i64, ptr %140, i64 %145
  store i64 %150, ptr %152, align 8, !tbaa !15
  %153 = icmp eq i64 %149, 0
  br i1 %153, label %144, label %154, !llvm.loop !110

154:                                              ; preds = %147, %141, %135
  %155 = phi i64 [ %52, %141 ], [ 0, %135 ], [ %151, %147 ]
  %156 = icmp ne ptr %140, %2
  %157 = icmp slt i64 %155, %47
  %158 = select i1 %156, i1 %157, i1 false
  br i1 %158, label %159, label %166

159:                                              ; preds = %159, %154
  %160 = phi i64 [ %164, %159 ], [ %155, %154 ]
  %161 = getelementptr inbounds i64, ptr %2, i64 %160
  %162 = load i64, ptr %161, align 8, !tbaa !15
  %163 = getelementptr inbounds i64, ptr %140, i64 %160
  store i64 %162, ptr %163, align 8, !tbaa !15
  %164 = add nsw i64 %160, 1
  %165 = icmp eq i64 %164, %47
  br i1 %165, label %166, label %159, !llvm.loop !111

166:                                              ; preds = %159, %154, %144
  %167 = phi i64 [ 0, %154 ], [ 0, %159 ], [ 1, %144 ]
  %168 = getelementptr inbounds i64, ptr %140, i64 %47
  store i64 0, ptr %168, align 8, !tbaa !15
  %169 = load i64, ptr %140, align 8, !tbaa !15
  %170 = add i64 %169, %167
  store i64 %170, ptr %140, align 8, !tbaa !15
  %171 = icmp ult i64 %170, %167
  br i1 %171, label %172, label %178

172:                                              ; preds = %172, %166
  %173 = phi ptr [ %174, %172 ], [ %140, %166 ]
  %174 = getelementptr inbounds i8, ptr %173, i64 8
  %175 = load i64, ptr %174, align 8, !tbaa !15
  %176 = add i64 %175, 1
  store i64 %176, ptr %174, align 8, !tbaa !15
  %177 = icmp eq i64 %176, 0
  br i1 %177, label %172, label %178, !llvm.loop !112

178:                                              ; preds = %172, %166
  %179 = load i64, ptr %168, align 8, !tbaa !15
  %180 = add i64 %179, %47
  br i1 %92, label %181, label %229, !prof !68

181:                                              ; preds = %178
  %182 = getelementptr inbounds i8, ptr %168, i64 8
  %183 = sub nsw i64 %5, %47
  %184 = icmp eq i64 %183, 0
  br i1 %184, label %199, label %185

185:                                              ; preds = %181
  %186 = getelementptr inbounds i64, ptr %4, i64 %47
  %187 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %182, ptr noundef %4, ptr noundef nonnull %186, i64 noundef %183) #16
  %188 = icmp eq i64 %187, 0
  br i1 %188, label %199, label %189

189:                                              ; preds = %192, %185
  %190 = phi i64 [ %196, %192 ], [ %183, %185 ]
  %191 = icmp slt i64 %190, %47
  br i1 %191, label %192, label %211

192:                                              ; preds = %189
  %193 = getelementptr inbounds i64, ptr %4, i64 %190
  %194 = load i64, ptr %193, align 8, !tbaa !15
  %195 = add i64 %194, -1
  %196 = add nsw i64 %190, 1
  %197 = getelementptr inbounds i64, ptr %182, i64 %190
  store i64 %195, ptr %197, align 8, !tbaa !15
  %198 = icmp eq i64 %194, 0
  br i1 %198, label %189, label %199, !llvm.loop !110

199:                                              ; preds = %192, %185, %181
  %200 = phi i64 [ %183, %185 ], [ 0, %181 ], [ %196, %192 ]
  %201 = icmp ne ptr %182, %4
  %202 = icmp slt i64 %200, %47
  %203 = select i1 %201, i1 %202, i1 false
  br i1 %203, label %204, label %211

204:                                              ; preds = %204, %199
  %205 = phi i64 [ %209, %204 ], [ %200, %199 ]
  %206 = getelementptr inbounds i64, ptr %4, i64 %205
  %207 = load i64, ptr %206, align 8, !tbaa !15
  %208 = getelementptr inbounds i64, ptr %182, i64 %205
  store i64 %207, ptr %208, align 8, !tbaa !15
  %209 = add nsw i64 %205, 1
  %210 = icmp eq i64 %209, %47
  br i1 %210, label %211, label %204, !llvm.loop !111

211:                                              ; preds = %204, %199, %189
  %212 = phi i64 [ 0, %199 ], [ 0, %204 ], [ 1, %189 ]
  %213 = or disjoint i64 %1, 1
  %214 = getelementptr inbounds i64, ptr %140, i64 %213
  store i64 0, ptr %214, align 8, !tbaa !15
  %215 = load i64, ptr %182, align 8, !tbaa !15
  %216 = add i64 %215, %212
  store i64 %216, ptr %182, align 8, !tbaa !15
  %217 = icmp ult i64 %216, %212
  br i1 %217, label %218, label %224

218:                                              ; preds = %218, %211
  %219 = phi ptr [ %220, %218 ], [ %182, %211 ]
  %220 = getelementptr inbounds i8, ptr %219, i64 8
  %221 = load i64, ptr %220, align 8, !tbaa !15
  %222 = add i64 %221, 1
  store i64 %222, ptr %220, align 8, !tbaa !15
  %223 = icmp eq i64 %222, 0
  br i1 %223, label %218, label %224, !llvm.loop !113

224:                                              ; preds = %218, %211
  %225 = getelementptr inbounds i64, ptr %182, i64 %47
  %226 = load i64, ptr %225, align 8, !tbaa !15
  %227 = add i64 %226, %47
  br label %229

228:                                              ; preds = %46
  tail call void @__gmpn_mulmod_bnm1(ptr noundef %0, i64 noundef %47, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, ptr noundef %6)
  br label %229

229:                                              ; preds = %228, %224, %178
  %230 = phi ptr [ %140, %224 ], [ %140, %178 ], [ %2, %228 ]
  %231 = phi ptr [ %182, %224 ], [ %4, %178 ], [ %4, %228 ]
  %232 = phi i64 [ %180, %224 ], [ %180, %178 ], [ %3, %228 ]
  %233 = phi i64 [ %227, %224 ], [ %5, %178 ], [ %5, %228 ]
  %234 = icmp ugt i64 %1, 598
  br i1 %234, label %235, label %250

235:                                              ; preds = %229
  %236 = tail call i32 @__gmpn_fft_best_k(i64 noundef %47, i32 noundef 0) #17
  %237 = shl nsw i32 -1, %236
  %238 = xor i32 %237, -1
  %239 = zext nneg i32 %238 to i64
  %240 = and i64 %47, %239
  %241 = icmp eq i64 %240, 0
  br i1 %241, label %250, label %242

242:                                              ; preds = %242, %235
  %243 = phi i32 [ %246, %242 ], [ %238, %235 ]
  %244 = phi i32 [ %245, %242 ], [ %236, %235 ]
  %245 = add nsw i32 %244, -1
  %246 = lshr i32 %243, 1
  %247 = zext nneg i32 %246 to i64
  %248 = and i64 %47, %247
  %249 = icmp eq i64 %248, 0
  br i1 %249, label %250, label %242, !llvm.loop !114

250:                                              ; preds = %242, %235, %229
  %251 = phi i32 [ 0, %229 ], [ %236, %235 ], [ %245, %242 ]
  %252 = icmp sgt i32 %251, 3
  br i1 %252, label %253, label %256

253:                                              ; preds = %250
  %254 = tail call i64 @__gmpn_mul_fft(ptr noundef %6, i64 noundef %47, ptr noundef %230, i64 noundef %232, ptr noundef %231, i64 noundef %233, i32 noundef %251) #16
  %255 = getelementptr inbounds i64, ptr %6, i64 %47
  store i64 %254, ptr %255, align 8, !tbaa !15
  br label %335

256:                                              ; preds = %250
  %257 = icmp eq ptr %231, %4
  br i1 %257, label %258, label %276, !prof !54

258:                                              ; preds = %256
  %259 = tail call i64 @__gmpn_mul(ptr noundef %6, ptr noundef %230, i64 noundef %232, ptr noundef %231, i64 noundef %233) #16
  %260 = sub i64 %232, %47
  %261 = add i64 %260, %233
  %262 = icmp sgt i64 %261, %47
  %263 = sext i1 %262 to i64
  %264 = add i64 %261, %263
  %265 = getelementptr inbounds i64, ptr %6, i64 %47
  %266 = tail call i64 @__gmpn_sub(ptr noundef %6, ptr noundef %6, i64 noundef %47, ptr noundef nonnull %265, i64 noundef %264)
  store i64 0, ptr %265, align 8, !tbaa !15
  %267 = load i64, ptr %6, align 8, !tbaa !15
  %268 = add i64 %267, %266
  store i64 %268, ptr %6, align 8, !tbaa !15
  %269 = icmp ult i64 %268, %266
  br i1 %269, label %270, label %335

270:                                              ; preds = %270, %258
  %271 = phi ptr [ %272, %270 ], [ %6, %258 ]
  %272 = getelementptr inbounds i8, ptr %271, i64 8
  %273 = load i64, ptr %272, align 8, !tbaa !15
  %274 = add i64 %273, 1
  store i64 %274, ptr %272, align 8, !tbaa !15
  %275 = icmp eq i64 %274, 0
  br i1 %275, label %270, label %335, !llvm.loop !115

276:                                              ; preds = %256
  %277 = getelementptr inbounds i64, ptr %230, i64 %47
  %278 = load i64, ptr %277, align 8, !tbaa !15
  %279 = getelementptr inbounds i64, ptr %231, i64 %47
  %280 = load i64, ptr %279, align 8, !tbaa !15
  %281 = or i64 %280, %278
  %282 = icmp eq i64 %281, 0
  br i1 %282, label %290, label %283, !prof !68

283:                                              ; preds = %276
  %284 = icmp eq i64 %278, 0
  br i1 %284, label %288, label %285

285:                                              ; preds = %283
  %286 = tail call i64 @__gmpn_neg(ptr noundef %6, ptr noundef %231, i64 noundef %47)
  %287 = add i64 %286, %280
  br label %323

288:                                              ; preds = %283
  %289 = tail call i64 @__gmpn_neg(ptr noundef %6, ptr noundef %230, i64 noundef %47)
  br label %323

290:                                              ; preds = %276
  %291 = icmp ugt i64 %1, 32
  br i1 %291, label %292, label %320

292:                                              ; preds = %290
  %293 = urem i64 %47, 3
  %294 = icmp eq i64 %293, 0
  br i1 %294, label %313, label %295

295:                                              ; preds = %292
  %296 = icmp ugt i64 %1, 62
  br i1 %296, label %297, label %320

297:                                              ; preds = %295
  %298 = urem i64 %47, 5
  %299 = icmp eq i64 %298, 0
  br i1 %299, label %313, label %300

300:                                              ; preds = %297
  %301 = urem i64 %47, 7
  %302 = icmp eq i64 %301, 0
  br i1 %302, label %313, label %303

303:                                              ; preds = %300
  %304 = icmp ugt i64 %1, 126
  br i1 %304, label %305, label %320

305:                                              ; preds = %303
  %306 = urem i64 %47, 13
  %307 = icmp eq i64 %306, 0
  br i1 %307, label %313, label %308

308:                                              ; preds = %305
  %309 = icmp ugt i64 %1, 254
  %310 = urem i64 %47, 17
  %311 = icmp eq i64 %310, 0
  %312 = and i1 %309, %311
  br i1 %312, label %313, label %320

313:                                              ; preds = %308, %305, %300, %297, %292
  %314 = phi i32 [ 3, %292 ], [ 5, %297 ], [ 7, %300 ], [ 13, %305 ], [ 17, %308 ]
  %315 = zext nneg i32 %314 to i64
  %316 = udiv i64 %47, %315
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #16
  store ptr null, ptr %8, align 8, !tbaa !7
  %317 = shl i64 %1, 4
  %318 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %317) #16
  call void @__gmpn_mulmod_bknp1(ptr noundef %6, ptr noundef %230, ptr noundef %231, i64 noundef %316, i32 noundef %314, ptr noundef %318) #16
  %319 = load ptr, ptr %8, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %319) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #16
  br label %335

320:                                              ; preds = %308, %303, %295, %290
  tail call void @__gmpn_mul_n(ptr noundef %6, ptr noundef %230, ptr noundef %231, i64 noundef %47) #16
  %321 = getelementptr inbounds i64, ptr %6, i64 %47
  %322 = tail call i64 @__gmpn_sub_n(ptr noundef %6, ptr noundef %6, ptr noundef nonnull %321, i64 noundef %47) #16
  br label %323

323:                                              ; preds = %320, %288, %285
  %324 = phi i64 [ %287, %285 ], [ %289, %288 ], [ %322, %320 ]
  %325 = getelementptr inbounds i64, ptr %6, i64 %47
  store i64 0, ptr %325, align 8, !tbaa !15
  %326 = load i64, ptr %6, align 8, !tbaa !15
  %327 = add i64 %326, %324
  store i64 %327, ptr %6, align 8, !tbaa !15
  %328 = icmp ult i64 %327, %324
  br i1 %328, label %329, label %335

329:                                              ; preds = %329, %323
  %330 = phi ptr [ %331, %329 ], [ %6, %323 ]
  %331 = getelementptr inbounds i8, ptr %330, i64 8
  %332 = load i64, ptr %331, align 8, !tbaa !15
  %333 = add i64 %332, 1
  store i64 %333, ptr %331, align 8, !tbaa !15
  %334 = icmp eq i64 %333, 0
  br i1 %334, label %329, label %335, !llvm.loop !116

335:                                              ; preds = %329, %323, %313, %270, %258, %253
  %336 = getelementptr inbounds i64, ptr %6, i64 %47
  %337 = load i64, ptr %336, align 8, !tbaa !15
  %338 = call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %6, i64 noundef %47) #16
  %339 = add i64 %338, %337
  %340 = load i64, ptr %0, align 8, !tbaa !15
  %341 = and i64 %340, 1
  %342 = add i64 %339, %341
  %343 = call i64 @__gmpn_rshift(ptr noundef nonnull %0, ptr noundef nonnull %0, i64 noundef %47, i32 noundef 1) #16
  %344 = shl i64 %342, 63
  %345 = getelementptr i64, ptr %0, i64 %47
  %346 = getelementptr i8, ptr %345, i64 -8
  %347 = load i64, ptr %346, align 8, !tbaa !15
  %348 = or i64 %344, %347
  store i64 %348, ptr %346, align 8, !tbaa !15
  %349 = lshr i64 %342, 1
  %350 = load i64, ptr %0, align 8, !tbaa !15
  %351 = add i64 %350, %349
  store i64 %351, ptr %0, align 8, !tbaa !15
  %352 = icmp ult i64 %351, %349
  br i1 %352, label %353, label %359

353:                                              ; preds = %353, %335
  %354 = phi ptr [ %355, %353 ], [ %0, %335 ]
  %355 = getelementptr inbounds i8, ptr %354, i64 8
  %356 = load i64, ptr %355, align 8, !tbaa !15
  %357 = add i64 %356, 1
  store i64 %357, ptr %355, align 8, !tbaa !15
  %358 = icmp eq i64 %357, 0
  br i1 %358, label %353, label %359, !llvm.loop !117

359:                                              ; preds = %353, %335
  %360 = add nsw i64 %5, %3
  %361 = icmp slt i64 %360, %1
  br i1 %361, label %362, label %389, !prof !54

362:                                              ; preds = %359
  %363 = sub nsw i64 %360, %47
  %364 = call i64 @__gmpn_sub_n(ptr noundef nonnull %345, ptr noundef nonnull %0, ptr noundef %6, i64 noundef %363) #16
  %365 = load i64, ptr %336, align 8, !tbaa !15
  %366 = getelementptr inbounds i64, ptr %6, i64 %3
  %367 = getelementptr inbounds i64, ptr %366, i64 %5
  %368 = getelementptr inbounds i64, ptr %367, i64 %48
  %369 = getelementptr inbounds i64, ptr %0, i64 %3
  %370 = getelementptr inbounds i64, ptr %369, i64 %5
  %371 = getelementptr inbounds i64, ptr %370, i64 %48
  %372 = sub nsw i64 %1, %360
  %373 = call fastcc i64 @mpn_sub_nc.75(ptr noundef nonnull %368, ptr noundef nonnull %371, ptr noundef nonnull %368, i64 noundef %372, i64 noundef %364)
  %374 = add i64 %373, %365
  %375 = load i64, ptr %0, align 8, !tbaa !15
  %376 = sub i64 %375, %374
  store i64 %376, ptr %0, align 8, !tbaa !15
  %377 = icmp ult i64 %375, %374
  br i1 %377, label %378, label %402

378:                                              ; preds = %362
  %379 = call i64 @llvm.smax.i64(i64 %360, i64 1)
  br label %380

380:                                              ; preds = %383, %378
  %381 = phi i64 [ %387, %383 ], [ 1, %378 ]
  %382 = icmp eq i64 %381, %379
  br i1 %382, label %402, label %383

383:                                              ; preds = %380
  %384 = getelementptr inbounds i64, ptr %0, i64 %381
  %385 = load i64, ptr %384, align 8, !tbaa !15
  %386 = add i64 %385, -1
  store i64 %386, ptr %384, align 8, !tbaa !15
  %387 = add nuw i64 %381, 1
  %388 = icmp eq i64 %385, 0
  br i1 %388, label %380, label %402, !llvm.loop !118

389:                                              ; preds = %359
  %390 = load i64, ptr %336, align 8, !tbaa !15
  %391 = call i64 @__gmpn_sub_n(ptr noundef nonnull %345, ptr noundef nonnull %0, ptr noundef %6, i64 noundef %47) #16
  %392 = add i64 %391, %390
  %393 = load i64, ptr %0, align 8, !tbaa !15
  %394 = sub i64 %393, %392
  store i64 %394, ptr %0, align 8, !tbaa !15
  %395 = icmp ult i64 %393, %392
  br i1 %395, label %396, label %402

396:                                              ; preds = %396, %389
  %397 = phi ptr [ %398, %396 ], [ %0, %389 ]
  %398 = getelementptr inbounds i8, ptr %397, i64 8
  %399 = load i64, ptr %398, align 8, !tbaa !15
  %400 = add i64 %399, -1
  store i64 %400, ptr %398, align 8, !tbaa !15
  %401 = icmp eq i64 %399, 0
  br i1 %401, label %396, label %402, !llvm.loop !119

402:                                              ; preds = %396, %389, %383, %380, %362, %40, %34, %28, %20, %18
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_add(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #5 {
  %6 = icmp eq i64 %4, 0
  br i1 %6, label %20, label %7

7:                                                ; preds = %5
  %8 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %4) #16
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %20, label %10

10:                                               ; preds = %13, %7
  %11 = phi i64 [ %17, %13 ], [ %4, %7 ]
  %12 = icmp slt i64 %11, %2
  br i1 %12, label %13, label %32

13:                                               ; preds = %10
  %14 = getelementptr inbounds i64, ptr %1, i64 %11
  %15 = load i64, ptr %14, align 8, !tbaa !15
  %16 = add i64 %15, 1
  %17 = add nsw i64 %11, 1
  %18 = getelementptr inbounds i64, ptr %0, i64 %11
  store i64 %16, ptr %18, align 8, !tbaa !15
  %19 = icmp eq i64 %16, 0
  br i1 %19, label %10, label %20, !llvm.loop !120

20:                                               ; preds = %13, %7, %5
  %21 = phi i64 [ %4, %7 ], [ 0, %5 ], [ %17, %13 ]
  %22 = icmp ne ptr %0, %1
  %23 = icmp slt i64 %21, %2
  %24 = select i1 %22, i1 %23, i1 false
  br i1 %24, label %25, label %32

25:                                               ; preds = %25, %20
  %26 = phi i64 [ %30, %25 ], [ %21, %20 ]
  %27 = getelementptr inbounds i64, ptr %1, i64 %26
  %28 = load i64, ptr %27, align 8, !tbaa !15
  %29 = getelementptr inbounds i64, ptr %0, i64 %26
  store i64 %28, ptr %29, align 8, !tbaa !15
  %30 = add nsw i64 %26, 1
  %31 = icmp eq i64 %30, %2
  br i1 %31, label %32, label %25, !llvm.loop !121

32:                                               ; preds = %25, %20, %10
  %33 = phi i64 [ 0, %20 ], [ 0, %25 ], [ 1, %10 ]
  ret i64 %33
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @__gmpn_fft_best_k(i64 noundef %0, i32 noundef %1) local_unnamed_addr #8 {
  %3 = sext i32 %1 to i64
  %4 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %3, i64 0
  %5 = load i64, ptr %4, align 16, !tbaa !15
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %21, label %7

7:                                                ; preds = %14, %2
  %8 = phi i64 [ %15, %14 ], [ 0, %2 ]
  %9 = phi i64 [ %17, %14 ], [ %5, %2 ]
  %10 = icmp sgt i64 %9, %0
  br i1 %10, label %11, label %14

11:                                               ; preds = %7
  %12 = trunc nuw nsw i64 %8 to i32
  %13 = add nuw nsw i32 %12, 4
  br label %35

14:                                               ; preds = %7
  %15 = add nuw nsw i64 %8, 1
  %16 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %3, i64 %15
  %17 = load i64, ptr %16, align 8, !tbaa !15
  %18 = icmp eq i64 %17, 0
  br i1 %18, label %19, label %7, !llvm.loop !122

19:                                               ; preds = %14
  %20 = trunc nuw i64 %15 to i32
  br label %21

21:                                               ; preds = %19, %2
  %22 = phi i32 [ 0, %2 ], [ %20, %19 ]
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %31, label %24

24:                                               ; preds = %21
  %25 = add nsw i32 %22, -1
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %3, i64 %26
  %28 = load i64, ptr %27, align 8, !tbaa !15
  %29 = shl nsw i64 %28, 2
  %30 = icmp sgt i64 %29, %0
  br i1 %30, label %31, label %33

31:                                               ; preds = %24, %21
  %32 = add nuw nsw i32 %22, 4
  br label %35

33:                                               ; preds = %24
  %34 = add nuw nsw i32 %22, 5
  br label %35

35:                                               ; preds = %33, %31, %11
  %36 = phi i32 [ %13, %11 ], [ %32, %31 ], [ %34, %33 ]
  ret i32 %36
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_mul_fft(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, i32 noundef %6) local_unnamed_addr #5 {
  %8 = alloca ptr, align 8
  %9 = icmp eq ptr %2, %4
  %10 = icmp eq i64 %3, %5
  %11 = and i1 %9, %10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #16
  %12 = add nsw i64 %1, -1
  %13 = zext i32 %6 to i64
  %14 = ashr i64 %12, %13
  %15 = add nsw i64 %14, 1
  %16 = shl i64 %15, %13
  %17 = icmp eq i64 %16, %1
  br i1 %17, label %19, label %18, !prof !68

18:                                               ; preds = %7
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 934, ptr noundef nonnull @.str.1.28) #18
  unreachable

19:                                               ; preds = %7
  store ptr null, ptr %8, align 8, !tbaa !7
  %20 = shl nsw i64 %1, 6
  %21 = add nsw i32 %6, 1
  %22 = sext i32 %21 to i64
  %23 = shl nsw i64 %22, 3
  %24 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %23) #16
  %25 = shl i64 8, %13
  %26 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %25) #16
  %27 = icmp slt i32 %6, 0
  br i1 %27, label %39, label %28

28:                                               ; preds = %19
  %29 = add nuw i32 %6, 1
  %30 = zext i32 %29 to i64
  br label %31

31:                                               ; preds = %31, %28
  %32 = phi i64 [ 0, %28 ], [ %37, %31 ]
  %33 = phi ptr [ %26, %28 ], [ %36, %31 ]
  %34 = getelementptr inbounds ptr, ptr %24, i64 %32
  store ptr %33, ptr %34, align 8, !tbaa !7
  %35 = shl nuw i64 1, %32
  %36 = getelementptr inbounds i32, ptr %33, i64 %35
  %37 = add nuw nsw i64 %32, 1
  %38 = icmp eq i64 %37, %30
  br i1 %38, label %39, label %31, !llvm.loop !123

39:                                               ; preds = %31, %19
  %40 = load ptr, ptr %24, align 8, !tbaa !7
  store i32 0, ptr %40, align 4, !tbaa !124
  %41 = icmp slt i32 %6, 1
  br i1 %41, label %68, label %42

42:                                               ; preds = %39
  %43 = zext nneg i32 %21 to i64
  br label %44

44:                                               ; preds = %64, %42
  %45 = phi i64 [ 1, %42 ], [ %65, %64 ]
  %46 = phi i32 [ 1, %42 ], [ %66, %64 ]
  %47 = getelementptr inbounds ptr, ptr %24, i64 %45
  %48 = load ptr, ptr %47, align 8, !tbaa !7
  %49 = getelementptr i8, ptr %47, i64 -8
  %50 = load ptr, ptr %49, align 8, !tbaa !7
  %51 = sext i32 %46 to i64
  %52 = call i32 @llvm.umax.i32(i32 %46, i32 1)
  %53 = zext i32 %52 to i64
  br label %54

54:                                               ; preds = %54, %44
  %55 = phi i64 [ 0, %44 ], [ %62, %54 ]
  %56 = getelementptr inbounds i32, ptr %50, i64 %55
  %57 = load i32, ptr %56, align 4, !tbaa !124
  %58 = shl nsw i32 %57, 1
  %59 = getelementptr inbounds i32, ptr %48, i64 %55
  store i32 %58, ptr %59, align 4, !tbaa !124
  %60 = or disjoint i32 %58, 1
  %61 = getelementptr i32, ptr %59, i64 %51
  store i32 %60, ptr %61, align 4, !tbaa !124
  %62 = add nuw nsw i64 %55, 1
  %63 = icmp eq i64 %62, %53
  br i1 %63, label %64, label %54, !llvm.loop !126

64:                                               ; preds = %54
  %65 = add nuw nsw i64 %45, 1
  %66 = shl nsw i32 %46, 1
  %67 = icmp eq i64 %65, %43
  br i1 %67, label %68, label %44, !llvm.loop !127

68:                                               ; preds = %64, %39
  %69 = shl nuw i64 1, %13
  %70 = ashr i64 %20, %13
  %71 = add nsw i64 %70, -1
  %72 = sdiv i64 %71, 64
  %73 = add nsw i64 %72, 1
  %74 = icmp sgt i32 %6, 0
  br i1 %74, label %75, label %84

75:                                               ; preds = %75, %68
  %76 = phi i64 [ %78, %75 ], [ 64, %68 ]
  %77 = phi i32 [ %79, %75 ], [ %6, %68 ]
  %78 = lshr exact i64 %76, 1
  %79 = add nsw i32 %77, -1
  %80 = and i64 %76, 2
  %81 = icmp eq i64 %80, 0
  %82 = icmp sgt i32 %77, 1
  %83 = select i1 %81, i1 %82, i1 false
  br i1 %83, label %75, label %84, !llvm.loop !128

84:                                               ; preds = %75, %68
  %85 = phi i64 [ 64, %68 ], [ %78, %75 ]
  %86 = shl i64 %85, %13
  %87 = shl nsw i64 %70, 1
  %88 = sext i32 %6 to i64
  %89 = add nsw i64 %88, 2
  %90 = add i64 %89, %87
  %91 = sdiv i64 %90, %86
  %92 = add nsw i64 %91, 1
  %93 = mul nsw i64 %92, %86
  %94 = sdiv i64 %93, 64
  %95 = select i1 %11, i64 360, i64 300
  %96 = icmp slt i64 %94, %95
  br i1 %96, label %146, label %97

97:                                               ; preds = %84
  %98 = zext i1 %11 to i64
  %99 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %98, i64 0
  %100 = load i64, ptr %99, align 16, !tbaa !15
  %101 = icmp eq i64 %100, 0
  br label %102

102:                                              ; preds = %140, %97
  %103 = phi i64 [ %144, %140 ], [ %94, %97 ]
  %104 = phi i64 [ %145, %140 ], [ %93, %97 ]
  br i1 %101, label %119, label %105

105:                                              ; preds = %112, %102
  %106 = phi i64 [ %113, %112 ], [ 0, %102 ]
  %107 = phi i64 [ %115, %112 ], [ %100, %102 ]
  %108 = icmp sgt i64 %107, %103
  br i1 %108, label %109, label %112

109:                                              ; preds = %105
  %110 = trunc nuw nsw i64 %106 to i32
  %111 = add nuw nsw i32 %110, 4
  br label %133

112:                                              ; preds = %105
  %113 = add nuw nsw i64 %106, 1
  %114 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %98, i64 %113
  %115 = load i64, ptr %114, align 8, !tbaa !15
  %116 = icmp eq i64 %115, 0
  br i1 %116, label %117, label %105, !llvm.loop !122

117:                                              ; preds = %112
  %118 = trunc nuw i64 %113 to i32
  br label %119

119:                                              ; preds = %117, %102
  %120 = phi i32 [ 0, %102 ], [ %118, %117 ]
  %121 = icmp eq i32 %120, 0
  br i1 %121, label %129, label %122

122:                                              ; preds = %119
  %123 = add nsw i32 %120, -1
  %124 = sext i32 %123 to i64
  %125 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %98, i64 %124
  %126 = load i64, ptr %125, align 8, !tbaa !15
  %127 = shl nsw i64 %126, 2
  %128 = icmp sgt i64 %127, %103
  br i1 %128, label %129, label %131

129:                                              ; preds = %122, %119
  %130 = add nuw nsw i32 %120, 4
  br label %133

131:                                              ; preds = %122
  %132 = add nuw nsw i32 %120, 5
  br label %133

133:                                              ; preds = %131, %129, %109
  %134 = phi i32 [ %111, %109 ], [ %130, %129 ], [ %132, %131 ]
  %135 = zext nneg i32 %134 to i64
  %136 = shl nuw i64 1, %135
  %137 = add nsw i64 %136, -1
  %138 = and i64 %137, %103
  %139 = icmp eq i64 %138, 0
  br i1 %139, label %146, label %140

140:                                              ; preds = %133
  %141 = add i64 %103, -1
  %142 = add i64 %141, %136
  %143 = sub nsw i64 0, %136
  %144 = and i64 %142, %143
  %145 = shl nsw i64 %144, 6
  br label %102, !llvm.loop !129

146:                                              ; preds = %133, %84
  %147 = phi i64 [ %94, %84 ], [ %103, %133 ]
  %148 = phi i64 [ %93, %84 ], [ %104, %133 ]
  %149 = icmp slt i64 %147, %1
  br i1 %149, label %151, label %150, !prof !68

150:                                              ; preds = %146
  call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 972, ptr noundef nonnull @.str.2.29) #18
  unreachable

151:                                              ; preds = %146
  %152 = add nsw i64 %147, 1
  %153 = shl i64 %152, 4
  %154 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %153) #16
  %155 = ashr i64 %148, %13
  %156 = shl i64 %152, %13
  %157 = shl i64 %156, 3
  %158 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %157) #16
  %159 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %25) #16
  %160 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %25) #16
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %158, ptr noundef %159, i64 noundef %69, i64 noundef %147, ptr noundef %2, i64 noundef %3, i64 noundef %73, i64 noundef %155, ptr noundef %154)
  br i1 %11, label %161, label %168

161:                                              ; preds = %151
  %162 = add nuw i64 %69, 2305843009213693951
  %163 = mul i64 %73, %162
  %164 = add i64 %147, %163
  %165 = shl i64 %164, 3
  %166 = add i64 %165, 8
  %167 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %166) #16
  br label %170

168:                                              ; preds = %151
  %169 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %157) #16
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %169, ptr noundef %160, i64 noundef %69, i64 noundef %147, ptr noundef %4, i64 noundef %5, i64 noundef %73, i64 noundef %155, ptr noundef %154)
  br label %170

170:                                              ; preds = %168, %161
  %171 = phi ptr [ %167, %161 ], [ %169, %168 ]
  %172 = zext i1 %11 to i32
  %173 = call fastcc i64 @mpn_mul_fft_internal(ptr noundef %0, i64 noundef %1, i32 noundef %6, ptr noundef %159, ptr noundef %160, ptr noundef %171, i64 noundef %147, i64 noundef %73, i64 noundef %155, ptr noundef nonnull %24, ptr noundef %154, i32 noundef %172)
  %174 = load ptr, ptr %8, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %174) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #16
  ret i64 %173
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_sub(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #5 {
  %6 = icmp eq i64 %4, 0
  br i1 %6, label %20, label %7

7:                                                ; preds = %5
  %8 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %4) #16
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %20, label %10

10:                                               ; preds = %13, %7
  %11 = phi i64 [ %17, %13 ], [ %4, %7 ]
  %12 = icmp slt i64 %11, %2
  br i1 %12, label %13, label %32

13:                                               ; preds = %10
  %14 = getelementptr inbounds i64, ptr %1, i64 %11
  %15 = load i64, ptr %14, align 8, !tbaa !15
  %16 = add i64 %15, -1
  %17 = add nsw i64 %11, 1
  %18 = getelementptr inbounds i64, ptr %0, i64 %11
  store i64 %16, ptr %18, align 8, !tbaa !15
  %19 = icmp eq i64 %15, 0
  br i1 %19, label %10, label %20, !llvm.loop !130

20:                                               ; preds = %13, %7, %5
  %21 = phi i64 [ %4, %7 ], [ 0, %5 ], [ %17, %13 ]
  %22 = icmp ne ptr %0, %1
  %23 = icmp slt i64 %21, %2
  %24 = select i1 %22, i1 %23, i1 false
  br i1 %24, label %25, label %32

25:                                               ; preds = %25, %20
  %26 = phi i64 [ %30, %25 ], [ %21, %20 ]
  %27 = getelementptr inbounds i64, ptr %1, i64 %26
  %28 = load i64, ptr %27, align 8, !tbaa !15
  %29 = getelementptr inbounds i64, ptr %0, i64 %26
  store i64 %28, ptr %29, align 8, !tbaa !15
  %30 = add nsw i64 %26, 1
  %31 = icmp eq i64 %30, %2
  br i1 %31, label %32, label %25, !llvm.loop !131

32:                                               ; preds = %25, %20, %10
  %33 = phi i64 [ 0, %20 ], [ 0, %25 ], [ 1, %10 ]
  ret i64 %33
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_neg(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #5 {
  %4 = load i64, ptr %1, align 8, !tbaa !15
  %5 = icmp eq i64 %4, 0
  br i1 %5, label %6, label %17

6:                                                ; preds = %12, %3
  %7 = phi i64 [ %10, %12 ], [ %2, %3 ]
  %8 = phi ptr [ %13, %12 ], [ %1, %3 ]
  %9 = phi ptr [ %14, %12 ], [ %0, %3 ]
  store i64 0, ptr %9, align 8, !tbaa !15
  %10 = add nsw i64 %7, -1
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %28, label %12

12:                                               ; preds = %6
  %13 = getelementptr inbounds i8, ptr %8, i64 8
  %14 = getelementptr inbounds i8, ptr %9, i64 8
  %15 = load i64, ptr %13, align 8, !tbaa !15
  %16 = icmp eq i64 %15, 0
  br i1 %16, label %6, label %17, !llvm.loop !132

17:                                               ; preds = %12, %3
  %18 = phi ptr [ %0, %3 ], [ %14, %12 ]
  %19 = phi ptr [ %1, %3 ], [ %13, %12 ]
  %20 = phi i64 [ %2, %3 ], [ %10, %12 ]
  %21 = phi i64 [ %4, %3 ], [ %15, %12 ]
  %22 = sub i64 0, %21
  store i64 %22, ptr %18, align 8, !tbaa !15
  %23 = add nsw i64 %20, -1
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %28, label %25

25:                                               ; preds = %17
  %26 = getelementptr inbounds i8, ptr %18, i64 8
  %27 = getelementptr inbounds i8, ptr %19, i64 8
  tail call void @__gmpn_com(ptr noundef nonnull %26, ptr noundef nonnull %27, i64 noundef %23) #16
  br label %28

28:                                               ; preds = %25, %17, %6
  %29 = phi i64 [ 1, %25 ], [ 1, %17 ], [ 0, %6 ]
  ret i64 %29
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mulmod_bknp1(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i32 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = add i32 %4, -1
  %8 = zext i32 %7 to i64
  %9 = mul nsw i64 %8, %3
  %10 = shl nsw i64 %9, 1
  %11 = getelementptr inbounds i64, ptr %5, i64 %10
  tail call fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %11, ptr noundef %1, i64 noundef %3, i32 noundef %4)
  %12 = mul i64 %9, 24
  %13 = getelementptr inbounds i8, ptr %5, i64 %12
  tail call fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %13, ptr noundef %2, i64 noundef %3, i32 noundef %4)
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef %11, ptr noundef %13, i64 noundef %9) #16
  %14 = zext i32 %4 to i64
  %15 = mul nsw i64 %14, %3
  %16 = sub nsw i64 %10, %15
  %17 = icmp eq i64 %16, 0
  br i1 %17, label %31, label %18

18:                                               ; preds = %6
  %19 = getelementptr inbounds i64, ptr %5, i64 %15
  %20 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %19, i64 noundef %16) #16
  %21 = icmp eq i64 %20, 0
  br i1 %21, label %31, label %22

22:                                               ; preds = %25, %18
  %23 = phi i64 [ %29, %25 ], [ %16, %18 ]
  %24 = icmp slt i64 %23, %15
  br i1 %24, label %25, label %31

25:                                               ; preds = %22
  %26 = getelementptr inbounds i64, ptr %5, i64 %23
  %27 = load i64, ptr %26, align 8, !tbaa !15
  %28 = add i64 %27, -1
  %29 = add nsw i64 %23, 1
  store i64 %28, ptr %26, align 8, !tbaa !15
  %30 = icmp eq i64 %27, 0
  br i1 %30, label %22, label %31, !llvm.loop !133

31:                                               ; preds = %25, %22, %18, %6
  %32 = phi i64 [ 0, %18 ], [ 0, %6 ], [ 1, %22 ], [ 0, %25 ]
  %33 = getelementptr inbounds i64, ptr %5, i64 %15
  store i64 0, ptr %33, align 8, !tbaa !15
  %34 = load i64, ptr %5, align 8, !tbaa !15
  %35 = add i64 %34, %32
  store i64 %35, ptr %5, align 8, !tbaa !15
  %36 = icmp ult i64 %35, %32
  br i1 %36, label %37, label %43

37:                                               ; preds = %37, %31
  %38 = phi ptr [ %39, %37 ], [ %5, %31 ]
  %39 = getelementptr inbounds i8, ptr %38, i64 8
  %40 = load i64, ptr %39, align 8, !tbaa !15
  %41 = add i64 %40, 1
  store i64 %41, ptr %39, align 8, !tbaa !15
  %42 = icmp eq i64 %41, 0
  br i1 %42, label %37, label %43, !llvm.loop !134

43:                                               ; preds = %37, %31
  %44 = getelementptr inbounds i8, ptr %33, i64 8
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef nonnull %44, ptr noundef %1, i64 noundef %3, i32 noundef %4)
  %45 = getelementptr inbounds i64, ptr %44, i64 %3
  %46 = getelementptr inbounds i8, ptr %45, i64 8
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef nonnull %46, ptr noundef %2, i64 noundef %3, i32 noundef %4)
  %47 = shl i64 %3, 4
  %48 = getelementptr i8, ptr %44, i64 %47
  %49 = getelementptr i8, ptr %48, i64 16
  %50 = load i64, ptr %45, align 8, !tbaa !15
  %51 = getelementptr inbounds i64, ptr %46, i64 %3
  %52 = load i64, ptr %51, align 8, !tbaa !15
  %53 = or i64 %52, %50
  %54 = icmp eq i64 %53, 0
  br i1 %54, label %62, label %55, !prof !68

55:                                               ; preds = %43
  %56 = icmp eq i64 %50, 0
  br i1 %56, label %60, label %57

57:                                               ; preds = %55
  %58 = tail call i64 @__gmpn_neg(ptr noundef %49, ptr noundef nonnull %46, i64 noundef %3)
  %59 = add i64 %58, %52
  br label %82

60:                                               ; preds = %55
  %61 = tail call i64 @__gmpn_neg(ptr noundef %49, ptr noundef nonnull %44, i64 noundef %3)
  br label %82

62:                                               ; preds = %43
  %63 = icmp sgt i64 %3, 16
  br i1 %63, label %64, label %79

64:                                               ; preds = %62
  %65 = urem i64 %3, 3
  %66 = icmp eq i64 %65, 0
  br i1 %66, label %75, label %67

67:                                               ; preds = %64
  %68 = icmp sgt i64 %3, 31
  br i1 %68, label %69, label %79

69:                                               ; preds = %67
  %70 = urem i64 %3, 5
  %71 = icmp eq i64 %70, 0
  br i1 %71, label %75, label %72

72:                                               ; preds = %69
  %73 = urem i64 %3, 7
  %74 = icmp eq i64 %73, 0
  br i1 %74, label %75, label %79

75:                                               ; preds = %72, %69, %64
  %76 = phi i32 [ 3, %64 ], [ 5, %69 ], [ 7, %72 ]
  %77 = zext nneg i32 %76 to i64
  %78 = udiv i64 %3, %77
  tail call void @__gmpn_mulmod_bknp1(ptr noundef %49, ptr noundef nonnull %44, ptr noundef nonnull %46, i64 noundef %78, i32 noundef %76, ptr noundef %49)
  br label %94

79:                                               ; preds = %72, %67, %62
  tail call void @__gmpn_mul_n(ptr noundef %49, ptr noundef nonnull %44, ptr noundef nonnull %46, i64 noundef %3) #16
  %80 = getelementptr inbounds i64, ptr %49, i64 %3
  %81 = tail call i64 @__gmpn_sub_n(ptr noundef %49, ptr noundef %49, ptr noundef %80, i64 noundef %3) #16
  br label %82

82:                                               ; preds = %79, %60, %57
  %83 = phi i64 [ %59, %57 ], [ %61, %60 ], [ %81, %79 ]
  %84 = getelementptr inbounds i64, ptr %49, i64 %3
  store i64 0, ptr %84, align 8, !tbaa !15
  %85 = load i64, ptr %49, align 8, !tbaa !15
  %86 = add i64 %85, %83
  store i64 %86, ptr %49, align 8, !tbaa !15
  %87 = icmp ult i64 %86, %83
  br i1 %87, label %88, label %94

88:                                               ; preds = %88, %82
  %89 = phi ptr [ %90, %88 ], [ %49, %82 ]
  %90 = getelementptr inbounds i8, ptr %89, i64 8
  %91 = load i64, ptr %90, align 8, !tbaa !15
  %92 = add i64 %91, 1
  store i64 %92, ptr %90, align 8, !tbaa !15
  %93 = icmp eq i64 %92, 0
  br i1 %93, label %88, label %94, !llvm.loop !135

94:                                               ; preds = %88, %82, %75
  tail call fastcc void @_mpn_crt(ptr noundef %0, ptr noundef nonnull %5, ptr noundef %49, i64 noundef %3, i32 noundef %4, ptr noundef nonnull %44)
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_rshift(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #6 {
  %5 = sub i32 64, %3
  %6 = load i64, ptr %1, align 8, !tbaa !15
  %7 = zext i32 %5 to i64
  %8 = zext nneg i32 %3 to i64
  %9 = add nsw i64 %2, -1
  %10 = lshr i64 %6, %8
  %11 = icmp eq i64 %9, 0
  br i1 %11, label %25, label %12

12:                                               ; preds = %12, %4
  %13 = phi i64 [ %23, %12 ], [ %10, %4 ]
  %14 = phi i64 [ %22, %12 ], [ %9, %4 ]
  %15 = phi ptr [ %21, %12 ], [ %0, %4 ]
  %16 = phi ptr [ %17, %12 ], [ %1, %4 ]
  %17 = getelementptr inbounds i8, ptr %16, i64 8
  %18 = load i64, ptr %17, align 8, !tbaa !15
  %19 = shl i64 %18, %7
  %20 = or i64 %19, %13
  %21 = getelementptr inbounds i8, ptr %15, i64 8
  store i64 %20, ptr %15, align 8, !tbaa !15
  %22 = add nsw i64 %14, -1
  %23 = lshr i64 %18, %8
  %24 = icmp eq i64 %22, 0
  br i1 %24, label %25, label %12, !llvm.loop !136

25:                                               ; preds = %12, %4
  %26 = phi ptr [ %0, %4 ], [ %21, %12 ]
  %27 = phi i64 [ %10, %4 ], [ %23, %12 ]
  %28 = shl i64 %6, %7
  store i64 %27, ptr %26, align 8, !tbaa !15
  ret i64 %28
}

; Function Attrs: inlinehint nounwind ssp uwtable
define hidden fastcc i64 @mpn_sub_nc.75(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4) unnamed_addr #9 {
  %6 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) #16
  %7 = load i64, ptr %0, align 8, !tbaa !15
  %8 = sub i64 %7, %4
  store i64 %8, ptr %0, align 8, !tbaa !15
  %9 = icmp ult i64 %7, %4
  br i1 %9, label %10, label %21

10:                                               ; preds = %5
  %11 = tail call i64 @llvm.smax.i64(i64 %3, i64 1)
  br label %12

12:                                               ; preds = %15, %10
  %13 = phi i64 [ %19, %15 ], [ 1, %10 ]
  %14 = icmp eq i64 %13, %11
  br i1 %14, label %21, label %15

15:                                               ; preds = %12
  %16 = getelementptr inbounds i64, ptr %0, i64 %13
  %17 = load i64, ptr %16, align 8, !tbaa !15
  %18 = add i64 %17, -1
  store i64 %18, ptr %16, align 8, !tbaa !15
  %19 = add nuw i64 %13, 1
  %20 = icmp eq i64 %17, 0
  br i1 %20, label %12, label %21, !llvm.loop !118

21:                                               ; preds = %15, %12, %5
  %22 = phi i64 [ 0, %5 ], [ 1, %12 ], [ 0, %15 ]
  %23 = add i64 %22, %6
  ret i64 %23
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.smax.i64(i64, i64) #10

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %0, ptr noundef %1, i64 noundef %2, i32 noundef %3) unnamed_addr #5 {
  %5 = add i32 %3, -1
  %6 = zext i32 %5 to i64
  %7 = mul nsw i64 %6, %2
  %8 = getelementptr inbounds i64, ptr %0, i64 %7
  %9 = getelementptr inbounds i64, ptr %1, i64 %7
  %10 = getelementptr inbounds i64, ptr %9, i64 %2
  %11 = load i64, ptr %10, align 8, !tbaa !15
  store i64 0, ptr %8, align 8, !tbaa !15
  %12 = lshr i32 %5, 1
  %13 = sub i64 0, %2
  br label %14

14:                                               ; preds = %45, %4
  %15 = phi i32 [ %12, %4 ], [ %46, %45 ]
  %16 = phi ptr [ %9, %4 ], [ %33, %45 ]
  %17 = phi ptr [ %8, %4 ], [ %32, %45 ]
  %18 = getelementptr inbounds i64, ptr %17, i64 %13
  %19 = getelementptr inbounds i64, ptr %16, i64 %13
  %20 = tail call i64 @__gmpn_add_n(ptr noundef %18, ptr noundef %19, ptr noundef %9, i64 noundef %2) #16
  %21 = add i64 %20, %11
  %22 = load i64, ptr %17, align 8, !tbaa !15
  %23 = add i64 %22, %21
  store i64 %23, ptr %17, align 8, !tbaa !15
  %24 = icmp ult i64 %23, %21
  br i1 %24, label %25, label %31

25:                                               ; preds = %25, %14
  %26 = phi ptr [ %27, %25 ], [ %17, %14 ]
  %27 = getelementptr inbounds i8, ptr %26, i64 8
  %28 = load i64, ptr %27, align 8, !tbaa !15
  %29 = add i64 %28, 1
  store i64 %29, ptr %27, align 8, !tbaa !15
  %30 = icmp eq i64 %29, 0
  br i1 %30, label %25, label %31, !llvm.loop !137

31:                                               ; preds = %25, %14
  %32 = getelementptr inbounds i64, ptr %18, i64 %13
  %33 = getelementptr inbounds i64, ptr %19, i64 %13
  %34 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %32, ptr noundef %33, ptr noundef %9, i64 noundef %2) #16
  %35 = add i64 %34, %11
  %36 = load i64, ptr %18, align 8, !tbaa !15
  %37 = sub i64 %36, %35
  store i64 %37, ptr %18, align 8, !tbaa !15
  %38 = icmp ult i64 %36, %35
  br i1 %38, label %39, label %45

39:                                               ; preds = %39, %31
  %40 = phi ptr [ %41, %39 ], [ %18, %31 ]
  %41 = getelementptr inbounds i8, ptr %40, i64 8
  %42 = load i64, ptr %41, align 8, !tbaa !15
  %43 = add i64 %42, -1
  store i64 %43, ptr %41, align 8, !tbaa !15
  %44 = icmp eq i64 %42, 0
  br i1 %44, label %39, label %45, !llvm.loop !138

45:                                               ; preds = %39, %31
  %46 = add i32 %15, -1
  %47 = icmp eq i32 %46, 0
  br i1 %47, label %48, label %14, !llvm.loop !139

48:                                               ; preds = %45
  %49 = getelementptr inbounds i64, ptr %17, i64 %13
  %50 = getelementptr inbounds i64, ptr %49, i64 %13
  %51 = getelementptr inbounds i64, ptr %50, i64 %7
  %52 = load i64, ptr %51, align 8, !tbaa !15
  %53 = icmp eq i64 %52, 0
  br i1 %53, label %90, label %54

54:                                               ; preds = %84, %48
  %55 = phi i64 [ %88, %84 ], [ %52, %48 ]
  %56 = phi ptr [ %87, %84 ], [ %51, %48 ]
  store i64 0, ptr %56, align 8, !tbaa !15
  br label %57

57:                                               ; preds = %81, %54
  %58 = phi i32 [ %12, %54 ], [ %82, %81 ]
  %59 = phi ptr [ %56, %54 ], [ %71, %81 ]
  %60 = getelementptr inbounds i64, ptr %59, i64 %13
  %61 = load i64, ptr %60, align 8, !tbaa !15
  %62 = add i64 %61, %55
  store i64 %62, ptr %60, align 8, !tbaa !15
  %63 = icmp ult i64 %62, %55
  br i1 %63, label %64, label %70

64:                                               ; preds = %64, %57
  %65 = phi ptr [ %66, %64 ], [ %60, %57 ]
  %66 = getelementptr inbounds i8, ptr %65, i64 8
  %67 = load i64, ptr %66, align 8, !tbaa !15
  %68 = add i64 %67, 1
  store i64 %68, ptr %66, align 8, !tbaa !15
  %69 = icmp eq i64 %68, 0
  br i1 %69, label %64, label %70, !llvm.loop !140

70:                                               ; preds = %64, %57
  %71 = getelementptr inbounds i64, ptr %60, i64 %13
  %72 = load i64, ptr %71, align 8, !tbaa !15
  %73 = sub i64 %72, %55
  store i64 %73, ptr %71, align 8, !tbaa !15
  %74 = icmp ult i64 %72, %55
  br i1 %74, label %75, label %81

75:                                               ; preds = %75, %70
  %76 = phi ptr [ %77, %75 ], [ %71, %70 ]
  %77 = getelementptr inbounds i8, ptr %76, i64 8
  %78 = load i64, ptr %77, align 8, !tbaa !15
  %79 = add i64 %78, -1
  store i64 %79, ptr %77, align 8, !tbaa !15
  %80 = icmp eq i64 %78, 0
  br i1 %80, label %75, label %81, !llvm.loop !141

81:                                               ; preds = %75, %70
  %82 = add i32 %58, -1
  %83 = icmp eq i32 %82, 0
  br i1 %83, label %84, label %57, !llvm.loop !142

84:                                               ; preds = %81
  %85 = getelementptr inbounds i64, ptr %59, i64 %13
  %86 = getelementptr inbounds i64, ptr %85, i64 %13
  %87 = getelementptr inbounds i64, ptr %86, i64 %7
  %88 = load i64, ptr %87, align 8, !tbaa !15
  %89 = icmp eq i64 %88, 0
  br i1 %89, label %90, label %54, !llvm.loop !143

90:                                               ; preds = %84, %48
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @_mpn_modbnp1_kn(ptr noundef %0, ptr noundef %1, i64 noundef %2, i32 noundef %3) unnamed_addr #5 {
  %5 = lshr i32 %3, 1
  %6 = getelementptr inbounds i64, ptr %1, i64 %2
  %7 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %6, i64 noundef %2) #16
  %8 = shl nsw i64 %2, 4
  %9 = getelementptr inbounds i8, ptr %1, i64 %8
  %10 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %9, i64 noundef %2) #16
  %11 = sub i64 %10, %7
  %12 = add nsw i32 %5, -1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %26, label %14

14:                                               ; preds = %14, %4
  %15 = phi i32 [ %24, %14 ], [ %12, %4 ]
  %16 = phi i64 [ %23, %14 ], [ %11, %4 ]
  %17 = phi ptr [ %21, %14 ], [ %9, %4 ]
  %18 = getelementptr inbounds i64, ptr %17, i64 %2
  %19 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %0, ptr noundef %18, i64 noundef %2) #16
  %20 = sub i64 %16, %19
  %21 = getelementptr inbounds i8, ptr %17, i64 %8
  %22 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %21, i64 noundef %2) #16
  %23 = add i64 %22, %20
  %24 = add i32 %15, -1
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %26, label %14, !llvm.loop !144

26:                                               ; preds = %14, %4
  %27 = phi ptr [ %1, %4 ], [ %17, %14 ]
  %28 = phi i64 [ %11, %4 ], [ %23, %14 ]
  %29 = getelementptr inbounds i8, ptr %27, i64 %8
  %30 = getelementptr inbounds i64, ptr %29, i64 %2
  %31 = load i64, ptr %30, align 8, !tbaa !15
  %32 = add i64 %31, %28
  %33 = icmp sgt i64 %32, -1
  %34 = getelementptr inbounds i64, ptr %0, i64 %2
  br i1 %33, label %50, label %35

35:                                               ; preds = %26
  store i64 0, ptr %34, align 8, !tbaa !15
  %36 = sub i64 0, %32
  %37 = load i64, ptr %0, align 8, !tbaa !15
  %38 = sub i64 %37, %32
  store i64 %38, ptr %0, align 8, !tbaa !15
  %39 = icmp ult i64 %38, %36
  br i1 %39, label %40, label %46

40:                                               ; preds = %40, %35
  %41 = phi ptr [ %42, %40 ], [ %0, %35 ]
  %42 = getelementptr inbounds i8, ptr %41, i64 8
  %43 = load i64, ptr %42, align 8, !tbaa !15
  %44 = add i64 %43, 1
  store i64 %44, ptr %42, align 8, !tbaa !15
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %40, label %46, !llvm.loop !145

46:                                               ; preds = %40, %35
  %47 = load i64, ptr %34, align 8, !tbaa !15
  %48 = icmp eq i64 %47, 0
  br i1 %48, label %74, label %49, !prof !68

49:                                               ; preds = %46
  tail call fastcc void @_mpn_modbnp1_pn_ip(ptr noundef nonnull %0, i64 noundef %2, i64 noundef 1)
  br label %74

50:                                               ; preds = %26
  store i64 %32, ptr %34, align 8, !tbaa !15
  %51 = icmp eq i64 %32, 0
  br i1 %51, label %74, label %52

52:                                               ; preds = %50
  %53 = load i64, ptr %0, align 8, !tbaa !15
  %54 = sub i64 %53, %32
  store i64 %54, ptr %0, align 8, !tbaa !15
  %55 = icmp ult i64 %53, %32
  br i1 %55, label %56, label %62

56:                                               ; preds = %56, %52
  %57 = phi ptr [ %58, %56 ], [ %0, %52 ]
  %58 = getelementptr inbounds i8, ptr %57, i64 8
  %59 = load i64, ptr %58, align 8, !tbaa !15
  %60 = add i64 %59, -1
  store i64 %60, ptr %58, align 8, !tbaa !15
  %61 = icmp eq i64 %59, 0
  br i1 %61, label %56, label %62, !llvm.loop !146

62:                                               ; preds = %56, %52
  %63 = load i64, ptr %34, align 8, !tbaa !15
  store i64 0, ptr %34, align 8, !tbaa !15
  %64 = sub i64 %32, %63
  %65 = load i64, ptr %0, align 8, !tbaa !15
  %66 = add i64 %65, %64
  store i64 %66, ptr %0, align 8, !tbaa !15
  %67 = icmp ult i64 %66, %64
  br i1 %67, label %68, label %74

68:                                               ; preds = %68, %62
  %69 = phi ptr [ %70, %68 ], [ %0, %62 ]
  %70 = getelementptr inbounds i8, ptr %69, i64 8
  %71 = load i64, ptr %70, align 8, !tbaa !15
  %72 = add i64 %71, 1
  store i64 %72, ptr %70, align 8, !tbaa !15
  %73 = icmp eq i64 %72, 0
  br i1 %73, label %68, label %74, !llvm.loop !147

74:                                               ; preds = %68, %62, %50, %49, %46
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @_mpn_crt(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i32 noundef %4, ptr noundef %5) unnamed_addr #5 {
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef %5, ptr noundef %1, i64 noundef %3, i32 noundef %4)
  %7 = add nsw i64 %3, 1
  %8 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %2, ptr noundef %5, i64 noundef %7) #16
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %27, label %10

10:                                               ; preds = %6
  %11 = getelementptr inbounds i64, ptr %5, i64 %3
  %12 = load i64, ptr %11, align 8, !tbaa !15
  store i64 0, ptr %11, align 8, !tbaa !15
  %13 = sub i64 0, %12
  %14 = load i64, ptr %5, align 8, !tbaa !15
  %15 = sub i64 %14, %12
  store i64 %15, ptr %5, align 8, !tbaa !15
  %16 = icmp ult i64 %15, %13
  br i1 %16, label %17, label %23

17:                                               ; preds = %17, %10
  %18 = phi ptr [ %19, %17 ], [ %5, %10 ]
  %19 = getelementptr inbounds i8, ptr %18, i64 8
  %20 = load i64, ptr %19, align 8, !tbaa !15
  %21 = add i64 %20, 1
  store i64 %21, ptr %19, align 8, !tbaa !15
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %17, label %23, !llvm.loop !145

23:                                               ; preds = %17, %10
  %24 = load i64, ptr %11, align 8, !tbaa !15
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %27, label %26, !prof !68

26:                                               ; preds = %23
  tail call fastcc void @_mpn_modbnp1_pn_ip(ptr noundef nonnull %5, i64 noundef %3, i64 noundef 1)
  br label %27

27:                                               ; preds = %26, %23, %6
  %28 = tail call i64 @__gmpn_mod_34lsub1(ptr noundef %5, i64 noundef %7) #19
  %29 = add i32 %4, -3
  %30 = tail call i32 @llvm.fshl.i32(i32 %29, i32 %29, i32 31)
  switch i32 %30, label %41 [
    i32 0, label %43
    i32 1, label %31
    i32 2, label %33
    i32 5, label %36
  ], !prof !148

31:                                               ; preds = %27
  %32 = shl i64 %28, 1
  br label %43

33:                                               ; preds = %27
  %34 = srem i64 %3, 3
  %35 = shl i64 %28, %34
  br label %43

36:                                               ; preds = %27
  %37 = srem i64 %3, 3
  %38 = icmp eq i64 %37, 1
  %39 = select i1 %38, i64 3, i64 9
  %40 = mul i64 %28, %39
  br label %43

41:                                               ; preds = %27
  %42 = shl i64 %28, 3
  br label %43

43:                                               ; preds = %41, %36, %33, %31, %27
  %44 = phi i64 [ %32, %31 ], [ %35, %33 ], [ %40, %36 ], [ %42, %41 ], [ %28, %27 ]
  %45 = load i64, ptr %5, align 8, !tbaa !15
  %46 = add i64 %45, %44
  store i64 %46, ptr %5, align 8, !tbaa !15
  %47 = icmp ult i64 %46, %44
  br i1 %47, label %48, label %54

48:                                               ; preds = %48, %43
  %49 = phi ptr [ %50, %48 ], [ %5, %43 ]
  %50 = getelementptr inbounds i8, ptr %49, i64 8
  %51 = load i64, ptr %50, align 8, !tbaa !15
  %52 = add i64 %51, 1
  store i64 %52, ptr %50, align 8, !tbaa !15
  %53 = icmp eq i64 %52, 0
  br i1 %53, label %48, label %54, !llvm.loop !149

54:                                               ; preds = %48, %43
  %55 = getelementptr inbounds i64, ptr %5, i64 %3
  %56 = load i64, ptr %55, align 8, !tbaa !15
  %57 = add i64 %56, %44
  store i64 %57, ptr %55, align 8, !tbaa !15
  switch i32 %30, label %64 [
    i32 0, label %58
    i32 1, label %60
    i32 2, label %62
    i32 5, label %63
  ], !prof !148

58:                                               ; preds = %54
  %59 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 6148914691236517205, i64 noundef 0) #16
  br label %66

60:                                               ; preds = %54
  %61 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 3689348814741910323, i64 noundef 0) #16
  br label %66

62:                                               ; preds = %54
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 7) #16
  br label %66

63:                                               ; preds = %54
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 13) #16
  br label %66

64:                                               ; preds = %54
  %65 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 1085102592571150095, i64 noundef 0) #16
  br label %66

66:                                               ; preds = %64, %63, %62, %60, %58
  %67 = zext i32 %4 to i64
  %68 = mul nsw i64 %67, %3
  %69 = getelementptr inbounds i64, ptr %0, i64 %68
  %70 = getelementptr inbounds i64, ptr %1, i64 %68
  %71 = sub i64 0, %3
  %72 = getelementptr inbounds i64, ptr %69, i64 %71
  %73 = getelementptr inbounds i64, ptr %70, i64 %71
  %74 = tail call i64 @__gmpn_add_n(ptr noundef %72, ptr noundef %73, ptr noundef nonnull %5, i64 noundef %7) #16
  %75 = lshr i32 %4, 1
  br label %76

76:                                               ; preds = %111, %66
  %77 = phi i32 [ %75, %66 ], [ %112, %111 ]
  %78 = phi ptr [ %70, %66 ], [ %83, %111 ]
  %79 = phi ptr [ %69, %66 ], [ %82, %111 ]
  %80 = getelementptr inbounds i64, ptr %78, i64 %71
  %81 = getelementptr inbounds i64, ptr %79, i64 %71
  %82 = getelementptr inbounds i64, ptr %81, i64 %71
  %83 = getelementptr inbounds i64, ptr %80, i64 %71
  %84 = tail call i64 @__gmpn_sub_n(ptr noundef %82, ptr noundef %83, ptr noundef nonnull %5, i64 noundef %3) #16
  %85 = load i64, ptr %55, align 8, !tbaa !15
  %86 = add i64 %85, %84
  %87 = load i64, ptr %81, align 8, !tbaa !15
  %88 = sub i64 %87, %86
  store i64 %88, ptr %81, align 8, !tbaa !15
  %89 = icmp ult i64 %87, %86
  br i1 %89, label %90, label %96

90:                                               ; preds = %90, %76
  %91 = phi ptr [ %92, %90 ], [ %81, %76 ]
  %92 = getelementptr inbounds i8, ptr %91, i64 8
  %93 = load i64, ptr %92, align 8, !tbaa !15
  %94 = add i64 %93, -1
  store i64 %94, ptr %92, align 8, !tbaa !15
  %95 = icmp eq i64 %93, 0
  br i1 %95, label %90, label %96, !llvm.loop !150

96:                                               ; preds = %90, %76
  %97 = getelementptr inbounds i64, ptr %82, i64 %71
  %98 = getelementptr inbounds i64, ptr %83, i64 %71
  %99 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %97, ptr noundef %98, ptr noundef nonnull %5, i64 noundef %3) #16
  %100 = load i64, ptr %55, align 8, !tbaa !15
  %101 = add i64 %100, %99
  %102 = load i64, ptr %82, align 8, !tbaa !15
  %103 = add i64 %102, %101
  store i64 %103, ptr %82, align 8, !tbaa !15
  %104 = icmp ult i64 %103, %101
  br i1 %104, label %105, label %111

105:                                              ; preds = %105, %96
  %106 = phi ptr [ %107, %105 ], [ %82, %96 ]
  %107 = getelementptr inbounds i8, ptr %106, i64 8
  %108 = load i64, ptr %107, align 8, !tbaa !15
  %109 = add i64 %108, 1
  store i64 %109, ptr %107, align 8, !tbaa !15
  %110 = icmp eq i64 %109, 0
  br i1 %110, label %105, label %111, !llvm.loop !151

111:                                              ; preds = %105, %96
  %112 = add i32 %77, -1
  %113 = icmp eq i32 %112, 0
  br i1 %113, label %114, label %76, !llvm.loop !152

114:                                              ; preds = %111
  %115 = getelementptr inbounds i64, ptr %97, i64 %68
  %116 = load i64, ptr %115, align 8, !tbaa !15
  %117 = load i64, ptr %97, align 8, !tbaa !15
  %118 = sub i64 %117, %116
  store i64 %118, ptr %97, align 8, !tbaa !15
  %119 = icmp ult i64 %117, %116
  br i1 %119, label %120, label %126

120:                                              ; preds = %120, %114
  %121 = phi ptr [ %122, %120 ], [ %97, %114 ]
  %122 = getelementptr inbounds i8, ptr %121, i64 8
  %123 = load i64, ptr %122, align 8, !tbaa !15
  %124 = add i64 %123, -1
  store i64 %124, ptr %122, align 8, !tbaa !15
  %125 = icmp eq i64 %123, 0
  br i1 %125, label %120, label %126, !llvm.loop !146

126:                                              ; preds = %120, %114
  %127 = load i64, ptr %115, align 8, !tbaa !15
  store i64 0, ptr %115, align 8, !tbaa !15
  %128 = sub i64 %116, %127
  %129 = load i64, ptr %97, align 8, !tbaa !15
  %130 = add i64 %129, %128
  store i64 %130, ptr %97, align 8, !tbaa !15
  %131 = icmp ult i64 %130, %128
  br i1 %131, label %132, label %138

132:                                              ; preds = %132, %126
  %133 = phi ptr [ %134, %132 ], [ %97, %126 ]
  %134 = getelementptr inbounds i8, ptr %133, i64 8
  %135 = load i64, ptr %134, align 8, !tbaa !15
  %136 = add i64 %135, 1
  store i64 %136, ptr %134, align 8, !tbaa !15
  %137 = icmp eq i64 %136, 0
  br i1 %137, label %132, label %138, !llvm.loop !147

138:                                              ; preds = %132, %126
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define hidden fastcc void @_mpn_modbnp1_pn_ip(ptr nocapture noundef %0, i64 noundef %1, i64 noundef %2) unnamed_addr #6 {
  %4 = load i64, ptr %0, align 8, !tbaa !15
  %5 = sub i64 %4, %2
  store i64 %5, ptr %0, align 8, !tbaa !15
  %6 = icmp ult i64 %4, %2
  br i1 %6, label %7, label %13

7:                                                ; preds = %7, %3
  %8 = phi ptr [ %9, %7 ], [ %0, %3 ]
  %9 = getelementptr inbounds i8, ptr %8, i64 8
  %10 = load i64, ptr %9, align 8, !tbaa !15
  %11 = add i64 %10, -1
  store i64 %11, ptr %9, align 8, !tbaa !15
  %12 = icmp eq i64 %10, 0
  br i1 %12, label %7, label %13, !llvm.loop !146

13:                                               ; preds = %7, %3
  %14 = getelementptr inbounds i64, ptr %0, i64 %1
  %15 = load i64, ptr %14, align 8, !tbaa !15
  store i64 0, ptr %14, align 8, !tbaa !15
  %16 = sub i64 %2, %15
  %17 = load i64, ptr %0, align 8, !tbaa !15
  %18 = add i64 %17, %16
  store i64 %18, ptr %0, align 8, !tbaa !15
  %19 = icmp ult i64 %18, %16
  br i1 %19, label %20, label %26

20:                                               ; preds = %20, %13
  %21 = phi ptr [ %22, %20 ], [ %0, %13 ]
  %22 = getelementptr inbounds i8, ptr %21, i64 8
  %23 = load i64, ptr %22, align 8, !tbaa !15
  %24 = add i64 %23, 1
  store i64 %24, ptr %22, align 8, !tbaa !15
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %20, label %26, !llvm.loop !147

26:                                               ; preds = %20, %13
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable
define range(i64 0, 2251799813685241) i64 @__gmpn_mod_34lsub1(ptr nocapture noundef readonly %0, i64 noundef %1) local_unnamed_addr #11 {
  %3 = add nsw i64 %1, -3
  %4 = icmp sgt i64 %1, 2
  br i1 %4, label %5, label %34

5:                                                ; preds = %5, %2
  %6 = phi i64 [ %32, %5 ], [ %3, %2 ]
  %7 = phi ptr [ %31, %5 ], [ %0, %2 ]
  %8 = phi i64 [ %18, %5 ], [ 0, %2 ]
  %9 = phi i64 [ %24, %5 ], [ 0, %2 ]
  %10 = phi i64 [ %30, %5 ], [ 0, %2 ]
  %11 = phi i64 [ %15, %5 ], [ 0, %2 ]
  %12 = phi i64 [ %21, %5 ], [ 0, %2 ]
  %13 = phi i64 [ %27, %5 ], [ 0, %2 ]
  %14 = load i64, ptr %7, align 8, !tbaa !15
  %15 = add i64 %14, %11
  %16 = icmp ult i64 %15, %11
  %17 = zext i1 %16 to i64
  %18 = add i64 %8, %17
  %19 = getelementptr inbounds i8, ptr %7, i64 8
  %20 = load i64, ptr %19, align 8, !tbaa !15
  %21 = add i64 %20, %12
  %22 = icmp ult i64 %21, %12
  %23 = zext i1 %22 to i64
  %24 = add i64 %9, %23
  %25 = getelementptr inbounds i8, ptr %7, i64 16
  %26 = load i64, ptr %25, align 8, !tbaa !15
  %27 = add i64 %26, %13
  %28 = icmp ult i64 %27, %13
  %29 = zext i1 %28 to i64
  %30 = add i64 %10, %29
  %31 = getelementptr inbounds i8, ptr %7, i64 24
  %32 = add nsw i64 %6, -3
  %33 = icmp sgt i64 %6, 2
  br i1 %33, label %5, label %34, !llvm.loop !153

34:                                               ; preds = %5, %2
  %35 = phi i64 [ 0, %2 ], [ %27, %5 ]
  %36 = phi i64 [ 0, %2 ], [ %21, %5 ]
  %37 = phi i64 [ 0, %2 ], [ %15, %5 ]
  %38 = phi i64 [ 0, %2 ], [ %30, %5 ]
  %39 = phi i64 [ 0, %2 ], [ %24, %5 ]
  %40 = phi i64 [ 0, %2 ], [ %18, %5 ]
  %41 = phi i64 [ %1, %2 ], [ %6, %5 ]
  %42 = phi ptr [ %0, %2 ], [ %31, %5 ]
  %43 = phi i64 [ %3, %2 ], [ %32, %5 ]
  %44 = icmp eq i64 %41, 0
  br i1 %44, label %59, label %45

45:                                               ; preds = %34
  %46 = load i64, ptr %42, align 8, !tbaa !15
  %47 = add i64 %46, %37
  %48 = icmp ult i64 %47, %37
  %49 = zext i1 %48 to i64
  %50 = add i64 %40, %49
  %51 = icmp eq i64 %43, -2
  br i1 %51, label %59, label %52

52:                                               ; preds = %45
  %53 = getelementptr inbounds i8, ptr %42, i64 8
  %54 = load i64, ptr %53, align 8, !tbaa !15
  %55 = add i64 %54, %36
  %56 = icmp ult i64 %55, %36
  %57 = zext i1 %56 to i64
  %58 = add i64 %39, %57
  br label %59

59:                                               ; preds = %52, %45, %34
  %60 = phi i64 [ %55, %52 ], [ %36, %45 ], [ %36, %34 ]
  %61 = phi i64 [ %47, %52 ], [ %47, %45 ], [ %37, %34 ]
  %62 = phi i64 [ %58, %52 ], [ %39, %45 ], [ %39, %34 ]
  %63 = phi i64 [ %50, %52 ], [ %50, %45 ], [ %40, %34 ]
  %64 = and i64 %61, 281474976710655
  %65 = lshr i64 %61, 48
  %66 = shl i64 %60, 16
  %67 = and i64 %66, 281474976645120
  %68 = lshr i64 %60, 32
  %69 = shl i64 %35, 32
  %70 = and i64 %69, 281470681743360
  %71 = lshr i64 %35, 16
  %72 = shl i64 %63, 16
  %73 = and i64 %72, 281474976645120
  %74 = lshr i64 %63, 32
  %75 = shl i64 %62, 32
  %76 = and i64 %75, 281470681743360
  %77 = lshr i64 %62, 16
  %78 = and i64 %38, 281474976710655
  %79 = lshr i64 %38, 48
  %80 = add nuw nsw i64 %70, %71
  %81 = add nuw nsw i64 %80, %79
  %82 = add nuw nsw i64 %81, %78
  %83 = add nuw nsw i64 %82, %68
  %84 = add nuw nsw i64 %83, %65
  %85 = add nuw nsw i64 %84, %64
  %86 = add nuw nsw i64 %85, %67
  %87 = add nuw nsw i64 %86, %77
  %88 = add nuw nsw i64 %87, %76
  %89 = add nuw nsw i64 %88, %74
  %90 = add nuw nsw i64 %89, %73
  ret i64 %90
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #10

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i64 @__gmpn_bdiv_dbm1c(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3, i64 noundef %4) local_unnamed_addr #12 {
  %6 = icmp sgt i64 %2, 0
  br i1 %6, label %7, label %40

7:                                                ; preds = %5
  %8 = lshr i64 %3, 32
  %9 = and i64 %3, 4294967295
  br label %10

10:                                               ; preds = %10, %7
  %11 = phi i64 [ %4, %7 ], [ %37, %10 ]
  %12 = phi i64 [ 0, %7 ], [ %38, %10 ]
  %13 = getelementptr inbounds i64, ptr %1, i64 %12
  %14 = load i64, ptr %13, align 8, !tbaa !15
  %15 = lshr i64 %14, 32
  %16 = and i64 %14, 4294967295
  %17 = mul nuw i64 %16, %9
  %18 = mul nuw i64 %16, %8
  %19 = mul nuw i64 %15, %9
  %20 = mul nuw i64 %15, %8
  %21 = lshr i64 %17, 32
  %22 = add i64 %19, %18
  %23 = add i64 %22, %21
  %24 = icmp ult i64 %23, %19
  %25 = add nuw i64 %20, 4294967296
  %26 = select i1 %24, i64 %25, i64 %20
  %27 = lshr i64 %23, 32
  %28 = shl i64 %23, 32
  %29 = and i64 %17, 4294967295
  %30 = or disjoint i64 %28, %29
  %31 = icmp ult i64 %11, %30
  %32 = sext i1 %31 to i64
  %33 = sub i64 %11, %30
  %34 = getelementptr inbounds i64, ptr %0, i64 %12
  store i64 %33, ptr %34, align 8, !tbaa !15
  %35 = add i64 %26, %27
  %36 = sub i64 %33, %35
  %37 = add i64 %36, %32
  %38 = add nuw nsw i64 %12, 1
  %39 = icmp eq i64 %38, %2
  br i1 %39, label %40, label %10, !llvm.loop !154

40:                                               ; preds = %10, %5
  %41 = phi i64 [ %4, %5 ], [ %37, %10 ]
  ret i64 %41
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define void @__gmpn_divexact_1(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #12 {
  %5 = and i64 %3, 1
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %7, label %38

7:                                                ; preds = %4
  %8 = and i64 %3, 254
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %17, label %10, !prof !54

10:                                               ; preds = %7
  %11 = sub i64 0, %3
  %12 = and i64 %11, %3
  %13 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !155
  %15 = zext i8 %14 to i32
  %16 = add nsw i32 %15, -2
  br label %34

17:                                               ; preds = %23, %7
  %18 = phi i64 [ %20, %23 ], [ %3, %7 ]
  %19 = phi i32 [ %24, %23 ], [ 6, %7 ]
  %20 = lshr i64 %18, 8
  %21 = and i64 %18, 65280
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %23, label %26, !prof !54

23:                                               ; preds = %17
  %24 = add nuw nsw i32 %19, 8
  %25 = icmp ult i32 %19, 54
  br i1 %25, label %17, label %26, !llvm.loop !156

26:                                               ; preds = %23, %17
  %27 = phi i32 [ %19, %17 ], [ 62, %23 ]
  %28 = sub nsw i64 0, %20
  %29 = and i64 %20, %28
  %30 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %29
  %31 = load i8, ptr %30, align 1, !tbaa !155
  %32 = zext i8 %31 to i32
  %33 = add nuw nsw i32 %27, %32
  br label %34

34:                                               ; preds = %26, %10
  %35 = phi i32 [ %16, %10 ], [ %33, %26 ]
  %36 = zext nneg i32 %35 to i64
  %37 = lshr i64 %3, %36
  br label %38

38:                                               ; preds = %34, %4
  %39 = phi i32 [ %35, %34 ], [ 0, %4 ]
  %40 = phi i64 [ %37, %34 ], [ %3, %4 ]
  %41 = lshr i64 %40, 1
  %42 = and i64 %41, 127
  %43 = getelementptr inbounds [128 x i8], ptr @__gmp_binvert_limb_table, i64 0, i64 %42
  %44 = load i8, ptr %43, align 1, !tbaa !155
  %45 = zext i8 %44 to i64
  %46 = mul i64 %40, %45
  %47 = sub i64 2, %46
  %48 = mul i64 %47, %45
  %49 = mul i64 %48, %40
  %50 = sub i64 2, %49
  %51 = mul i64 %48, %50
  %52 = mul i64 %51, %40
  %53 = sub i64 2, %52
  %54 = mul i64 %51, %53
  %55 = icmp eq i32 %39, 0
  %56 = load i64, ptr %1, align 8, !tbaa !15
  br i1 %55, label %106, label %57

57:                                               ; preds = %38
  %58 = getelementptr i8, ptr %0, i64 -8
  %59 = icmp sgt i64 %2, 1
  br i1 %59, label %60, label %97

60:                                               ; preds = %57
  %61 = zext nneg i32 %39 to i64
  %62 = sub nsw i32 64, %39
  %63 = zext nneg i32 %62 to i64
  %64 = lshr i64 %40, 32
  %65 = and i64 %40, 4294967295
  br label %66

66:                                               ; preds = %66, %60
  %67 = phi i64 [ 1, %60 ], [ %95, %66 ]
  %68 = phi i64 [ 0, %60 ], [ %94, %66 ]
  %69 = phi i64 [ %56, %60 ], [ %71, %66 ]
  %70 = getelementptr inbounds i64, ptr %1, i64 %67
  %71 = load i64, ptr %70, align 8, !tbaa !15
  %72 = lshr i64 %69, %61
  %73 = shl i64 %71, %63
  %74 = or i64 %73, %72
  %75 = sub i64 %74, %68
  %76 = icmp ugt i64 %68, %74
  %77 = zext i1 %76 to i64
  %78 = mul i64 %75, %54
  %79 = getelementptr i64, ptr %58, i64 %67
  store i64 %78, ptr %79, align 8, !tbaa !15
  %80 = lshr i64 %78, 32
  %81 = and i64 %78, 4294967295
  %82 = mul nuw i64 %81, %65
  %83 = mul nuw i64 %81, %64
  %84 = mul nuw i64 %80, %65
  %85 = mul nuw i64 %80, %64
  %86 = lshr i64 %82, 32
  %87 = add i64 %84, %83
  %88 = add i64 %87, %86
  %89 = icmp ult i64 %88, %84
  %90 = add nuw i64 %85, 4294967296
  %91 = select i1 %89, i64 %90, i64 %85
  %92 = lshr i64 %88, 32
  %93 = add nuw nsw i64 %92, %77
  %94 = add i64 %93, %91
  %95 = add nuw nsw i64 %67, 1
  %96 = icmp eq i64 %95, %2
  br i1 %96, label %97, label %66, !llvm.loop !157

97:                                               ; preds = %66, %57
  %98 = phi i64 [ %56, %57 ], [ %71, %66 ]
  %99 = phi i64 [ 0, %57 ], [ %94, %66 ]
  %100 = zext nneg i32 %39 to i64
  %101 = lshr i64 %98, %100
  %102 = sub i64 %101, %99
  %103 = mul i64 %102, %54
  %104 = getelementptr i64, ptr %0, i64 %2
  %105 = getelementptr i8, ptr %104, i64 -8
  store i64 %103, ptr %105, align 8, !tbaa !15
  br label %140

106:                                              ; preds = %38
  %107 = mul i64 %56, %54
  store i64 %107, ptr %0, align 8, !tbaa !15
  %108 = icmp sgt i64 %2, 1
  br i1 %108, label %109, label %140

109:                                              ; preds = %106
  %110 = lshr i64 %40, 32
  %111 = and i64 %40, 4294967295
  br label %112

112:                                              ; preds = %112, %109
  %113 = phi i64 [ 1, %109 ], [ %138, %112 ]
  %114 = phi i64 [ 0, %109 ], [ %135, %112 ]
  %115 = phi i64 [ %107, %109 ], [ %136, %112 ]
  %116 = lshr i64 %115, 32
  %117 = and i64 %115, 4294967295
  %118 = mul nuw i64 %117, %111
  %119 = mul nuw i64 %117, %110
  %120 = mul nuw i64 %116, %111
  %121 = mul nuw i64 %116, %110
  %122 = lshr i64 %118, 32
  %123 = add i64 %120, %119
  %124 = add i64 %123, %122
  %125 = icmp ult i64 %124, %120
  %126 = add nuw i64 %121, 4294967296
  %127 = select i1 %125, i64 %126, i64 %121
  %128 = lshr i64 %124, 32
  %129 = add nuw nsw i64 %128, %114
  %130 = add i64 %129, %127
  %131 = getelementptr inbounds i64, ptr %1, i64 %113
  %132 = load i64, ptr %131, align 8, !tbaa !15
  %133 = sub i64 %132, %130
  %134 = icmp ugt i64 %130, %132
  %135 = zext i1 %134 to i64
  %136 = mul i64 %133, %54
  %137 = getelementptr inbounds i64, ptr %0, i64 %113
  store i64 %136, ptr %137, align 8, !tbaa !15
  %138 = add nuw nsw i64 %113, 1
  %139 = icmp eq i64 %138, %2
  br i1 %139, label %140, label %112, !llvm.loop !158

140:                                              ; preds = %112, %106, %97
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define void @__gmpn_com(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2) local_unnamed_addr #6 {
  br label %4

4:                                                ; preds = %4, %3
  %5 = phi ptr [ %1, %3 ], [ %8, %4 ]
  %6 = phi i64 [ %2, %3 ], [ %12, %4 ]
  %7 = phi ptr [ %0, %3 ], [ %11, %4 ]
  %8 = getelementptr inbounds i8, ptr %5, i64 8
  %9 = load i64, ptr %5, align 8, !tbaa !15
  %10 = xor i64 %9, -1
  %11 = getelementptr inbounds i8, ptr %7, i64 8
  store i64 %10, ptr %7, align 8, !tbaa !15
  %12 = add nsw i64 %6, -1
  %13 = icmp eq i64 %12, 0
  br i1 %13, label %14, label %4, !llvm.loop !159

14:                                               ; preds = %4
  ret void
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @__gmp_assert_fail(ptr noundef %0, i32 noundef %1, ptr noundef %2) local_unnamed_addr #13 {
  tail call void @__gmp_assert_header(ptr noundef %0, i32 noundef %1)
  %4 = load ptr, ptr @__stderrp, align 8, !tbaa !7
  %5 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %4, ptr noundef nonnull @.str.2.18, ptr noundef %2) #16
  tail call void @abort() #20
  unreachable
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #10

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_mul_fft_decompose(ptr noundef %0, ptr nocapture noundef writeonly %1, i64 noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, ptr noundef %8) unnamed_addr #5 {
  %10 = alloca ptr, align 8
  %11 = mul nsw i64 %6, %2
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10) #16
  store ptr null, ptr %10, align 8, !tbaa !7
  %12 = icmp slt i64 %11, %5
  br i1 %12, label %13, label %60

13:                                               ; preds = %9
  %14 = sub nsw i64 %5, %11
  %15 = add nsw i64 %11, 1
  %16 = shl i64 %15, 3
  %17 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %10, i64 noundef %16) #16
  %18 = getelementptr inbounds i64, ptr %17, i64 %11
  store i64 0, ptr %18, align 8, !tbaa !15
  %19 = icmp sgt i64 %14, %11
  br i1 %19, label %20, label %21, !prof !54

20:                                               ; preds = %13
  call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 747, ptr noundef nonnull @.str.4.30) #18
  unreachable

21:                                               ; preds = %13
  %22 = icmp eq i64 %14, 0
  br i1 %22, label %37, label %23

23:                                               ; preds = %21
  %24 = getelementptr inbounds i64, ptr %4, i64 %11
  %25 = call i64 @__gmpn_sub_n(ptr noundef %17, ptr noundef %4, ptr noundef %24, i64 noundef %14) #16
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %37, label %27

27:                                               ; preds = %30, %23
  %28 = phi i64 [ %34, %30 ], [ %14, %23 ]
  %29 = icmp slt i64 %28, %11
  br i1 %29, label %30, label %49

30:                                               ; preds = %27
  %31 = getelementptr inbounds i64, ptr %4, i64 %28
  %32 = load i64, ptr %31, align 8, !tbaa !15
  %33 = add i64 %32, -1
  %34 = add nsw i64 %28, 1
  %35 = getelementptr inbounds i64, ptr %17, i64 %28
  store i64 %33, ptr %35, align 8, !tbaa !15
  %36 = icmp eq i64 %32, 0
  br i1 %36, label %27, label %37, !llvm.loop !160

37:                                               ; preds = %30, %23, %21
  %38 = phi i64 [ %14, %23 ], [ 0, %21 ], [ %34, %30 ]
  %39 = icmp ne ptr %17, %4
  %40 = icmp slt i64 %38, %11
  %41 = select i1 %39, i1 %40, i1 false
  br i1 %41, label %42, label %49

42:                                               ; preds = %37
  %43 = shl i64 %38, 3
  %44 = getelementptr i8, ptr %17, i64 %43
  %45 = getelementptr i8, ptr %4, i64 %43
  %46 = mul i64 %6, %2
  %47 = sub i64 %46, %38
  %48 = shl i64 %47, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %44, ptr align 8 %45, i64 %48, i1 false), !tbaa !15
  br label %49

49:                                               ; preds = %42, %37, %27
  %50 = phi i64 [ 0, %37 ], [ 0, %42 ], [ 1, %27 ]
  %51 = load i64, ptr %17, align 8, !tbaa !15
  %52 = add i64 %51, %50
  store i64 %52, ptr %17, align 8, !tbaa !15
  %53 = icmp ult i64 %52, %50
  br i1 %53, label %54, label %60

54:                                               ; preds = %54, %49
  %55 = phi ptr [ %56, %54 ], [ %17, %49 ]
  %56 = getelementptr inbounds i8, ptr %55, i64 8
  %57 = load i64, ptr %56, align 8, !tbaa !15
  %58 = add i64 %57, 1
  store i64 %58, ptr %56, align 8, !tbaa !15
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %54, label %60, !llvm.loop !161

60:                                               ; preds = %54, %49, %9
  %61 = phi i64 [ %5, %9 ], [ %15, %49 ], [ %15, %54 ]
  %62 = phi ptr [ %4, %9 ], [ %17, %49 ], [ %17, %54 ]
  %63 = icmp sgt i64 %2, 0
  br i1 %63, label %64, label %119

64:                                               ; preds = %60
  %65 = icmp eq i64 %3, -1
  %66 = add nsw i64 %2, -1
  %67 = add nsw i64 %3, 1
  %68 = add i64 %3, 1
  %69 = shl i64 %3, 3
  %70 = add i64 %69, 8
  br label %71

71:                                               ; preds = %113, %64
  %72 = phi ptr [ %0, %64 ], [ %116, %113 ]
  %73 = phi ptr [ %62, %64 ], [ %115, %113 ]
  %74 = phi i64 [ %61, %64 ], [ %114, %113 ]
  %75 = phi i64 [ 0, %64 ], [ %117, %113 ]
  %76 = getelementptr inbounds ptr, ptr %1, i64 %75
  store ptr %72, ptr %76, align 8, !tbaa !7
  %77 = icmp sgt i64 %74, 0
  br i1 %77, label %78, label %111

78:                                               ; preds = %71
  %79 = icmp sge i64 %74, %6
  %80 = icmp slt i64 %75, %66
  %81 = select i1 %79, i1 %80, i1 false
  %82 = select i1 %81, i64 %6, i64 %74
  %83 = sub nsw i64 %74, %82
  %84 = icmp eq i64 %82, 0
  br i1 %84, label %102, label %85

85:                                               ; preds = %78
  %86 = add nsw i64 %82, -1
  %87 = load i64, ptr %73, align 8, !tbaa !15
  %88 = icmp eq i64 %86, 0
  br i1 %88, label %99, label %89

89:                                               ; preds = %89, %85
  %90 = phi i64 [ %97, %89 ], [ %86, %85 ]
  %91 = phi ptr [ %95, %89 ], [ %8, %85 ]
  %92 = phi ptr [ %94, %89 ], [ %73, %85 ]
  %93 = phi i64 [ %96, %89 ], [ %87, %85 ]
  %94 = getelementptr inbounds i8, ptr %92, i64 8
  %95 = getelementptr inbounds i8, ptr %91, i64 8
  store i64 %93, ptr %91, align 8, !tbaa !15
  %96 = load i64, ptr %94, align 8, !tbaa !15
  %97 = add nsw i64 %90, -1
  %98 = icmp eq i64 %97, 0
  br i1 %98, label %99, label %89, !llvm.loop !162

99:                                               ; preds = %89, %85
  %100 = phi ptr [ %8, %85 ], [ %95, %89 ]
  %101 = phi i64 [ %87, %85 ], [ %96, %89 ]
  store i64 %101, ptr %100, align 8, !tbaa !15
  br label %102

102:                                              ; preds = %99, %78
  %103 = icmp eq i64 %67, %82
  br i1 %103, label %108, label %104

104:                                              ; preds = %102
  %105 = sub i64 %67, %82
  %106 = getelementptr i64, ptr %8, i64 %82
  %107 = shl nuw i64 %105, 3
  call void @llvm.memset.p0.i64(ptr align 8 %106, i8 0, i64 %107, i1 false), !tbaa !15
  br label %108

108:                                              ; preds = %104, %102
  %109 = getelementptr inbounds i64, ptr %73, i64 %6
  %110 = mul nsw i64 %75, %7
  call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %72, ptr noundef %8, i64 noundef %110, i64 noundef %3)
  br label %113

111:                                              ; preds = %71
  br i1 %65, label %113, label %112

112:                                              ; preds = %111
  call void @llvm.memset.p0.i64(ptr align 8 %72, i8 0, i64 %70, i1 false), !tbaa !15
  br label %113

113:                                              ; preds = %112, %111, %108
  %114 = phi i64 [ %83, %108 ], [ %74, %111 ], [ %74, %112 ]
  %115 = phi ptr [ %109, %108 ], [ %73, %111 ], [ %73, %112 ]
  %116 = getelementptr i64, ptr %72, i64 %68
  %117 = add nuw nsw i64 %75, 1
  %118 = icmp eq i64 %117, %2
  br i1 %118, label %119, label %71, !llvm.loop !163

119:                                              ; preds = %113, %60
  %120 = phi i64 [ %61, %60 ], [ %114, %113 ]
  %121 = icmp eq i64 %120, 0
  br i1 %121, label %123, label %122, !prof !68

122:                                              ; preds = %119
  call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 811, ptr noundef nonnull @.str.5) #18
  unreachable

123:                                              ; preds = %119
  %124 = load ptr, ptr %10, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %124) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i64 @mpn_mul_fft_internal(ptr noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, ptr noundef %9, ptr noundef %10, i32 noundef %11) unnamed_addr #5 {
  %13 = alloca ptr, align 8
  %14 = zext nneg i32 %2 to i64
  %15 = shl nuw i64 1, %14
  %16 = sext i32 %2 to i64
  %17 = getelementptr inbounds ptr, ptr %9, i64 %16
  %18 = shl nsw i64 %8, 1
  tail call fastcc void @mpn_fft_fft(ptr noundef %3, i64 noundef %15, ptr noundef %17, i64 noundef %18, i64 noundef %6, i64 noundef 1, ptr noundef %10)
  %19 = icmp eq i32 %11, 0
  br i1 %19, label %20, label %21

20:                                               ; preds = %12
  tail call fastcc void @mpn_fft_fft(ptr noundef %4, i64 noundef %15, ptr noundef %17, i64 noundef %18, i64 noundef %6, i64 noundef 1, ptr noundef %10)
  br label %21

21:                                               ; preds = %20, %12
  %22 = phi ptr [ %4, %20 ], [ %3, %12 ]
  %23 = icmp eq ptr %22, %3
  %24 = zext i1 %23 to i32
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %13) #16
  store ptr null, ptr %13, align 8, !tbaa !7
  %25 = select i1 %23, i64 360, i64 300
  %26 = icmp sgt i64 %25, %6
  br i1 %26, label %259, label %27

27:                                               ; preds = %21
  %28 = zext i1 %23 to i64
  %29 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %28, i64 0
  %30 = load i64, ptr %29, align 16, !tbaa !15
  %31 = icmp eq i64 %30, 0
  br i1 %31, label %46, label %32

32:                                               ; preds = %39, %27
  %33 = phi i64 [ %40, %39 ], [ 0, %27 ]
  %34 = phi i64 [ %42, %39 ], [ %30, %27 ]
  %35 = icmp sgt i64 %34, %6
  br i1 %35, label %36, label %39

36:                                               ; preds = %32
  %37 = trunc nuw nsw i64 %33 to i32
  %38 = add nuw nsw i32 %37, 4
  br label %60

39:                                               ; preds = %32
  %40 = add nuw nsw i64 %33, 1
  %41 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %28, i64 %40
  %42 = load i64, ptr %41, align 8, !tbaa !15
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %44, label %32, !llvm.loop !122

44:                                               ; preds = %39
  %45 = trunc nuw i64 %40 to i32
  br label %46

46:                                               ; preds = %44, %27
  %47 = phi i32 [ 0, %27 ], [ %45, %44 ]
  %48 = icmp eq i32 %47, 0
  br i1 %48, label %56, label %49

49:                                               ; preds = %46
  %50 = add nsw i32 %47, -1
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %28, i64 %51
  %53 = load i64, ptr %52, align 8, !tbaa !15
  %54 = shl nsw i64 %53, 2
  %55 = icmp sgt i64 %54, %6
  br i1 %55, label %56, label %58

56:                                               ; preds = %49, %46
  %57 = add nuw nsw i32 %47, 4
  br label %60

58:                                               ; preds = %49
  %59 = add nuw nsw i32 %47, 5
  br label %60

60:                                               ; preds = %58, %56, %36
  %61 = phi i32 [ %38, %36 ], [ %57, %56 ], [ %59, %58 ]
  %62 = zext i32 %61 to i64
  %63 = shl nuw i64 1, %62
  %64 = add nsw i64 %63, -1
  %65 = and i64 %64, %6
  %66 = icmp eq i64 %65, 0
  br i1 %66, label %68, label %67, !prof !68

67:                                               ; preds = %60
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 492, ptr noundef nonnull @.str.6) #18
  unreachable

68:                                               ; preds = %60
  %69 = tail call i64 @llvm.smax.i64(i64 %63, i64 64)
  %70 = shl nsw i64 %6, 6
  %71 = lshr i64 %70, %62
  %72 = lshr i64 %6, %62
  %73 = shl nuw nsw i64 %71, 1
  %74 = sext i32 %61 to i64
  %75 = add nsw i64 %74, 2
  %76 = add nsw i64 %75, %73
  %77 = add nsw i64 %76, %69
  %78 = freeze i64 %77
  %79 = srem i64 %78, %69
  %80 = sub nsw i64 %78, %79
  %81 = sdiv i64 %80, 64
  %82 = icmp slt i64 %81, %25
  br i1 %82, label %127, label %83

83:                                               ; preds = %121, %68
  %84 = phi i64 [ %126, %121 ], [ %80, %68 ]
  %85 = phi i64 [ %125, %121 ], [ %81, %68 ]
  br i1 %31, label %100, label %86

86:                                               ; preds = %93, %83
  %87 = phi i64 [ %94, %93 ], [ 0, %83 ]
  %88 = phi i64 [ %96, %93 ], [ %30, %83 ]
  %89 = icmp sgt i64 %88, %85
  br i1 %89, label %90, label %93

90:                                               ; preds = %86
  %91 = trunc nuw nsw i64 %87 to i32
  %92 = add nuw nsw i32 %91, 4
  br label %114

93:                                               ; preds = %86
  %94 = add nuw nsw i64 %87, 1
  %95 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %28, i64 %94
  %96 = load i64, ptr %95, align 8, !tbaa !15
  %97 = icmp eq i64 %96, 0
  br i1 %97, label %98, label %86, !llvm.loop !122

98:                                               ; preds = %93
  %99 = trunc nuw i64 %94 to i32
  br label %100

100:                                              ; preds = %98, %83
  %101 = phi i32 [ 0, %83 ], [ %99, %98 ]
  %102 = icmp eq i32 %101, 0
  br i1 %102, label %110, label %103

103:                                              ; preds = %100
  %104 = add nsw i32 %101, -1
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %28, i64 %105
  %107 = load i64, ptr %106, align 8, !tbaa !15
  %108 = shl nsw i64 %107, 2
  %109 = icmp sgt i64 %108, %85
  br i1 %109, label %110, label %112

110:                                              ; preds = %103, %100
  %111 = add nuw nsw i32 %101, 4
  br label %114

112:                                              ; preds = %103
  %113 = add nuw nsw i32 %101, 5
  br label %114

114:                                              ; preds = %112, %110, %90
  %115 = phi i32 [ %92, %90 ], [ %111, %110 ], [ %113, %112 ]
  %116 = zext nneg i32 %115 to i64
  %117 = shl nuw i64 1, %116
  %118 = add nsw i64 %117, -1
  %119 = and i64 %118, %85
  %120 = icmp eq i64 %119, 0
  br i1 %120, label %127, label %121

121:                                              ; preds = %114
  %122 = add i64 %85, -1
  %123 = add i64 %122, %117
  %124 = sub nsw i64 0, %117
  %125 = and i64 %123, %124
  %126 = shl nsw i64 %125, 6
  br label %83, !llvm.loop !164

127:                                              ; preds = %114, %68
  %128 = phi i64 [ %80, %68 ], [ %84, %114 ]
  %129 = phi i64 [ %81, %68 ], [ %85, %114 ]
  %130 = icmp slt i64 %129, %6
  br i1 %130, label %132, label %131, !prof !68

131:                                              ; preds = %127
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 514, ptr noundef nonnull @.str.7) #18
  unreachable

132:                                              ; preds = %127
  %133 = ashr i64 %128, %62
  %134 = shl i64 8, %62
  %135 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %134) #16
  %136 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %134) #16
  %137 = add nsw i64 %129, 1
  %138 = shl nsw i64 %137, 1
  %139 = shl i64 %138, %62
  %140 = shl i64 %139, 3
  %141 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %140) #16
  %142 = shl i64 %137, 4
  %143 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %142) #16
  %144 = shl i64 %137, %62
  %145 = getelementptr inbounds i64, ptr %141, i64 %144
  %146 = add nsw i32 %61, 1
  %147 = sext i32 %146 to i64
  %148 = shl nsw i64 %147, 3
  %149 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %148) #16
  %150 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %134) #16
  %151 = icmp slt i32 %61, 0
  br i1 %151, label %163, label %152

152:                                              ; preds = %132
  %153 = add nuw i32 %61, 1
  %154 = zext i32 %153 to i64
  br label %155

155:                                              ; preds = %155, %152
  %156 = phi i64 [ 0, %152 ], [ %161, %155 ]
  %157 = phi ptr [ %150, %152 ], [ %160, %155 ]
  %158 = getelementptr inbounds ptr, ptr %149, i64 %156
  store ptr %157, ptr %158, align 8, !tbaa !7
  %159 = shl nuw i64 1, %156
  %160 = getelementptr inbounds i32, ptr %157, i64 %159
  %161 = add nuw nsw i64 %156, 1
  %162 = icmp eq i64 %161, %154
  br i1 %162, label %163, label %155, !llvm.loop !165

163:                                              ; preds = %155, %132
  %164 = load ptr, ptr %149, align 8, !tbaa !7
  store i32 0, ptr %164, align 4, !tbaa !124
  %165 = icmp slt i32 %61, 1
  br i1 %165, label %192, label %166

166:                                              ; preds = %163
  %167 = zext nneg i32 %146 to i64
  br label %168

168:                                              ; preds = %188, %166
  %169 = phi i64 [ 1, %166 ], [ %189, %188 ]
  %170 = phi i32 [ 1, %166 ], [ %190, %188 ]
  %171 = getelementptr inbounds ptr, ptr %149, i64 %169
  %172 = load ptr, ptr %171, align 8, !tbaa !7
  %173 = getelementptr i8, ptr %171, i64 -8
  %174 = load ptr, ptr %173, align 8, !tbaa !7
  %175 = sext i32 %170 to i64
  %176 = call i32 @llvm.umax.i32(i32 %170, i32 1)
  %177 = zext i32 %176 to i64
  br label %178

178:                                              ; preds = %178, %168
  %179 = phi i64 [ 0, %168 ], [ %186, %178 ]
  %180 = getelementptr inbounds i32, ptr %174, i64 %179
  %181 = load i32, ptr %180, align 4, !tbaa !124
  %182 = shl nsw i32 %181, 1
  %183 = getelementptr inbounds i32, ptr %172, i64 %179
  store i32 %182, ptr %183, align 4, !tbaa !124
  %184 = or disjoint i32 %182, 1
  %185 = getelementptr i32, ptr %183, i64 %175
  store i32 %184, ptr %185, align 4, !tbaa !124
  %186 = add nuw nsw i64 %179, 1
  %187 = icmp eq i64 %186, %177
  br i1 %187, label %188, label %178, !llvm.loop !126

188:                                              ; preds = %178
  %189 = add nuw nsw i64 %169, 1
  %190 = shl nsw i32 %170, 1
  %191 = icmp eq i64 %189, %167
  br i1 %191, label %192, label %168, !llvm.loop !127

192:                                              ; preds = %188, %163
  %193 = icmp eq i32 %2, 63
  br i1 %193, label %383, label %194

194:                                              ; preds = %192
  %195 = icmp eq i64 %6, 0
  %196 = shl nuw i64 %6, 3
  %197 = icmp eq i64 %6, 0
  %198 = shl nuw i64 %6, 3
  %199 = shl i64 %72, %62
  %200 = add nsw i64 %199, 1
  %201 = call i64 @llvm.smax.i64(i64 %15, i64 1)
  br label %202

202:                                              ; preds = %250, %194
  %203 = phi i64 [ 0, %194 ], [ %255, %250 ]
  %204 = phi ptr [ %3, %194 ], [ %256, %250 ]
  %205 = phi ptr [ %22, %194 ], [ %257, %250 ]
  %206 = load ptr, ptr %204, align 8, !tbaa !7
  %207 = getelementptr inbounds i64, ptr %206, i64 %6
  %208 = load i64, ptr %207, align 8, !tbaa !15
  %209 = icmp eq i64 %208, 0
  br i1 %209, label %225, label %210

210:                                              ; preds = %210, %202
  %211 = phi ptr [ %212, %210 ], [ %206, %202 ]
  %212 = getelementptr inbounds i8, ptr %211, i64 8
  %213 = load i64, ptr %211, align 8, !tbaa !15
  %214 = add i64 %213, -1
  store i64 %214, ptr %211, align 8, !tbaa !15
  %215 = icmp eq i64 %213, 0
  br i1 %215, label %210, label %216, !llvm.loop !166

216:                                              ; preds = %210
  %217 = load i64, ptr %207, align 8, !tbaa !15
  %218 = icmp ne i64 %217, 0
  %219 = or i1 %218, %195
  %220 = xor i1 %218, true
  %221 = zext i1 %220 to i64
  br i1 %219, label %223, label %222

222:                                              ; preds = %216
  call void @llvm.memset.p0.i64(ptr align 8 %206, i8 0, i64 %196, i1 false), !tbaa !15
  br label %223

223:                                              ; preds = %222, %216
  %224 = phi i64 [ 1, %222 ], [ %221, %216 ]
  store i64 %224, ptr %207, align 8, !tbaa !15
  br label %225

225:                                              ; preds = %223, %202
  br i1 %23, label %249, label %226

226:                                              ; preds = %225
  %227 = load ptr, ptr %205, align 8, !tbaa !7
  %228 = getelementptr inbounds i64, ptr %227, i64 %6
  %229 = load i64, ptr %228, align 8, !tbaa !15
  %230 = icmp eq i64 %229, 0
  br i1 %230, label %246, label %231

231:                                              ; preds = %231, %226
  %232 = phi ptr [ %233, %231 ], [ %227, %226 ]
  %233 = getelementptr inbounds i8, ptr %232, i64 8
  %234 = load i64, ptr %232, align 8, !tbaa !15
  %235 = add i64 %234, -1
  store i64 %235, ptr %232, align 8, !tbaa !15
  %236 = icmp eq i64 %234, 0
  br i1 %236, label %231, label %237, !llvm.loop !166

237:                                              ; preds = %231
  %238 = load i64, ptr %228, align 8, !tbaa !15
  %239 = icmp ne i64 %238, 0
  %240 = or i1 %239, %197
  %241 = xor i1 %239, true
  %242 = zext i1 %241 to i64
  br i1 %240, label %244, label %243

243:                                              ; preds = %237
  call void @llvm.memset.p0.i64(ptr align 8 %227, i8 0, i64 %198, i1 false), !tbaa !15
  br label %244

244:                                              ; preds = %243, %237
  %245 = phi i64 [ 1, %243 ], [ %242, %237 ]
  store i64 %245, ptr %228, align 8, !tbaa !15
  br label %246

246:                                              ; preds = %244, %226
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %141, ptr noundef %135, i64 noundef %63, i64 noundef %129, ptr noundef %206, i64 noundef %200, i64 noundef %72, i64 noundef %133, ptr noundef %143)
  br i1 %23, label %250, label %247

247:                                              ; preds = %246
  %248 = load ptr, ptr %205, align 8, !tbaa !7
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %145, ptr noundef %136, i64 noundef %63, i64 noundef %129, ptr noundef %248, i64 noundef %200, i64 noundef %72, i64 noundef %133, ptr noundef %143)
  br label %250

249:                                              ; preds = %225
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %141, ptr noundef %135, i64 noundef %63, i64 noundef %129, ptr noundef %206, i64 noundef %200, i64 noundef %72, i64 noundef %133, ptr noundef %143)
  br label %250

250:                                              ; preds = %249, %247, %246
  %251 = load ptr, ptr %204, align 8, !tbaa !7
  %252 = call fastcc i64 @mpn_mul_fft_internal(ptr noundef %251, i64 noundef %6, i32 noundef %61, ptr noundef %135, ptr noundef %136, ptr noundef %145, i64 noundef %129, i64 noundef %72, i64 noundef %133, ptr noundef nonnull %149, ptr noundef %143, i32 noundef %24)
  %253 = load ptr, ptr %204, align 8, !tbaa !7
  %254 = getelementptr inbounds i64, ptr %253, i64 %6
  store i64 %252, ptr %254, align 8, !tbaa !15
  %255 = add nuw nsw i64 %203, 1
  %256 = getelementptr inbounds i8, ptr %204, i64 8
  %257 = getelementptr inbounds i8, ptr %205, i64 8
  %258 = icmp eq i64 %255, %201
  br i1 %258, label %383, label %202, !llvm.loop !167

259:                                              ; preds = %21
  %260 = icmp sgt i64 %6, 16
  br i1 %260, label %261, label %314

261:                                              ; preds = %259
  %262 = urem i64 %6, 3
  %263 = icmp eq i64 %262, 0
  br i1 %263, label %282, label %264

264:                                              ; preds = %261
  %265 = icmp sgt i64 %6, 31
  br i1 %265, label %266, label %314

266:                                              ; preds = %264
  %267 = urem i64 %6, 5
  %268 = icmp eq i64 %267, 0
  br i1 %268, label %282, label %269

269:                                              ; preds = %266
  %270 = urem i64 %6, 7
  %271 = icmp eq i64 %270, 0
  br i1 %271, label %282, label %272

272:                                              ; preds = %269
  %273 = icmp sgt i64 %6, 63
  br i1 %273, label %274, label %314

274:                                              ; preds = %272
  %275 = urem i64 %6, 13
  %276 = icmp eq i64 %275, 0
  br i1 %276, label %282, label %277

277:                                              ; preds = %274
  %278 = icmp sgt i64 %6, 127
  %279 = urem i64 %6, 17
  %280 = icmp eq i64 %279, 0
  %281 = and i1 %278, %280
  br i1 %281, label %282, label %314

282:                                              ; preds = %277, %274, %269, %266, %261
  %283 = phi i32 [ 3, %261 ], [ 5, %266 ], [ 7, %269 ], [ 13, %274 ], [ 17, %277 ]
  %284 = zext nneg i32 %283 to i64
  %285 = udiv i64 %6, %284
  %286 = icmp eq i32 %2, 63
  br i1 %23, label %287, label %299

287:                                              ; preds = %282
  %288 = mul i64 %6, 24
  %289 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %288) #16
  br i1 %286, label %383, label %290

290:                                              ; preds = %287
  %291 = call i64 @llvm.smax.i64(i64 %15, i64 1)
  br label %292

292:                                              ; preds = %292, %290
  %293 = phi i64 [ 0, %290 ], [ %297, %292 ]
  %294 = phi ptr [ %3, %290 ], [ %295, %292 ]
  %295 = getelementptr inbounds i8, ptr %294, i64 8
  %296 = load ptr, ptr %294, align 8, !tbaa !7
  call void @__gmpn_sqrmod_bknp1(ptr noundef %296, ptr noundef %296, i64 noundef %285, i32 noundef %283, ptr noundef %289) #16
  %297 = add nuw nsw i64 %293, 1
  %298 = icmp eq i64 %297, %291
  br i1 %298, label %383, label %292, !llvm.loop !168

299:                                              ; preds = %282
  %300 = shl i64 %6, 5
  %301 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %300) #16
  br i1 %286, label %383, label %302

302:                                              ; preds = %299
  %303 = call i64 @llvm.smax.i64(i64 %15, i64 1)
  br label %304

304:                                              ; preds = %304, %302
  %305 = phi i64 [ 0, %302 ], [ %312, %304 ]
  %306 = phi ptr [ %3, %302 ], [ %308, %304 ]
  %307 = phi ptr [ %22, %302 ], [ %310, %304 ]
  %308 = getelementptr inbounds i8, ptr %306, i64 8
  %309 = load ptr, ptr %306, align 8, !tbaa !7
  %310 = getelementptr inbounds i8, ptr %307, i64 8
  %311 = load ptr, ptr %307, align 8, !tbaa !7
  call void @__gmpn_mulmod_bknp1(ptr noundef %309, ptr noundef %309, ptr noundef %311, i64 noundef %285, i32 noundef %283, ptr noundef %301) #16
  %312 = add nuw nsw i64 %305, 1
  %313 = icmp eq i64 %312, %303
  br i1 %313, label %383, label %304, !llvm.loop !169

314:                                              ; preds = %277, %272, %264, %259
  %315 = shl i64 %6, 4
  %316 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %315) #16
  %317 = getelementptr inbounds i64, ptr %316, i64 %6
  %318 = icmp eq i32 %2, 63
  br i1 %318, label %383, label %319

319:                                              ; preds = %314
  %320 = shl nsw i64 %6, 1
  %321 = call i64 @llvm.smax.i64(i64 %320, i64 1)
  %322 = call i64 @llvm.smax.i64(i64 %15, i64 1)
  br label %323

323:                                              ; preds = %380, %319
  %324 = phi i64 [ 0, %319 ], [ %381, %380 ]
  %325 = phi ptr [ %3, %319 ], [ %327, %380 ]
  %326 = phi ptr [ %22, %319 ], [ %329, %380 ]
  %327 = getelementptr inbounds i8, ptr %325, i64 8
  %328 = load ptr, ptr %325, align 8, !tbaa !7
  %329 = getelementptr inbounds i8, ptr %326, i64 8
  %330 = load ptr, ptr %326, align 8, !tbaa !7
  br i1 %23, label %331, label %332

331:                                              ; preds = %323
  call void @__gmpn_sqr(ptr noundef %316, ptr noundef %328, i64 noundef %6) #16
  br label %333

332:                                              ; preds = %323
  call void @__gmpn_mul_n(ptr noundef %316, ptr noundef %330, ptr noundef %328, i64 noundef %6) #16
  br label %333

333:                                              ; preds = %332, %331
  %334 = getelementptr inbounds i64, ptr %328, i64 %6
  %335 = load i64, ptr %334, align 8, !tbaa !15
  %336 = icmp eq i64 %335, 0
  br i1 %336, label %339, label %337

337:                                              ; preds = %333
  %338 = call i64 @__gmpn_add_n(ptr noundef %317, ptr noundef %317, ptr noundef %330, i64 noundef %6) #16
  br label %339

339:                                              ; preds = %337, %333
  %340 = phi i64 [ %338, %337 ], [ 0, %333 ]
  %341 = getelementptr inbounds i64, ptr %330, i64 %6
  %342 = load i64, ptr %341, align 8, !tbaa !15
  %343 = icmp eq i64 %342, 0
  br i1 %343, label %349, label %344

344:                                              ; preds = %339
  %345 = call i64 @__gmpn_add_n(ptr noundef %317, ptr noundef %317, ptr noundef %328, i64 noundef %6) #16
  %346 = load i64, ptr %334, align 8, !tbaa !15
  %347 = add i64 %345, %340
  %348 = add i64 %347, %346
  br label %349

349:                                              ; preds = %344, %339
  %350 = phi i64 [ %348, %344 ], [ %340, %339 ]
  %351 = icmp eq i64 %350, 0
  br i1 %351, label %369, label %352

352:                                              ; preds = %349
  %353 = load i64, ptr %316, align 8, !tbaa !15
  %354 = add i64 %353, %350
  store i64 %354, ptr %316, align 8, !tbaa !15
  %355 = icmp ult i64 %354, %350
  br i1 %355, label %356, label %365

356:                                              ; preds = %359, %352
  %357 = phi i64 [ %363, %359 ], [ 1, %352 ]
  %358 = icmp eq i64 %357, %321
  br i1 %358, label %365, label %359

359:                                              ; preds = %356
  %360 = getelementptr inbounds i64, ptr %316, i64 %357
  %361 = load i64, ptr %360, align 8, !tbaa !15
  %362 = add i64 %361, 1
  store i64 %362, ptr %360, align 8, !tbaa !15
  %363 = add nuw i64 %357, 1
  %364 = icmp eq i64 %362, 0
  br i1 %364, label %356, label %365, !llvm.loop !170

365:                                              ; preds = %359, %356, %352
  %366 = phi i64 [ 0, %352 ], [ 1, %356 ], [ 0, %359 ]
  %367 = load i64, ptr %316, align 8, !tbaa !15
  %368 = add i64 %367, %366
  store i64 %368, ptr %316, align 8, !tbaa !15
  br label %369

369:                                              ; preds = %365, %349
  %370 = call i64 @__gmpn_sub_n(ptr noundef %328, ptr noundef %316, ptr noundef %317, i64 noundef %6) #16
  store i64 0, ptr %334, align 8, !tbaa !15
  %371 = load i64, ptr %328, align 8, !tbaa !15
  %372 = add i64 %371, %370
  store i64 %372, ptr %328, align 8, !tbaa !15
  %373 = icmp ult i64 %372, %370
  br i1 %373, label %374, label %380

374:                                              ; preds = %374, %369
  %375 = phi ptr [ %376, %374 ], [ %328, %369 ]
  %376 = getelementptr inbounds i8, ptr %375, i64 8
  %377 = load i64, ptr %376, align 8, !tbaa !15
  %378 = add i64 %377, 1
  store i64 %378, ptr %376, align 8, !tbaa !15
  %379 = icmp eq i64 %378, 0
  br i1 %379, label %374, label %380, !llvm.loop !171

380:                                              ; preds = %374, %369
  %381 = add nuw nsw i64 %324, 1
  %382 = icmp eq i64 %381, %322
  br i1 %382, label %383, label %323, !llvm.loop !172

383:                                              ; preds = %380, %314, %304, %299, %292, %287, %250, %192
  %384 = load ptr, ptr %13, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %384) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %13) #16
  call fastcc void @mpn_fft_fftinv(ptr noundef %3, i64 noundef %15, i64 noundef %18, i64 noundef %6, ptr noundef %10)
  %385 = getelementptr inbounds i64, ptr %10, i64 %6
  %386 = getelementptr inbounds i8, ptr %385, i64 8
  store ptr %386, ptr %4, align 8, !tbaa !7
  %387 = load ptr, ptr %3, align 8, !tbaa !7
  %388 = shl i64 %6, 7
  %389 = sub i64 %388, %16
  call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef nonnull %386, ptr noundef %387, i64 noundef %389, i64 noundef %6)
  %390 = getelementptr inbounds i64, ptr %386, i64 %6
  %391 = load i64, ptr %390, align 8, !tbaa !15
  %392 = icmp eq i64 %391, 0
  br i1 %392, label %408, label %393

393:                                              ; preds = %393, %383
  %394 = phi ptr [ %395, %393 ], [ %386, %383 ]
  %395 = getelementptr inbounds i8, ptr %394, i64 8
  %396 = load i64, ptr %394, align 8, !tbaa !15
  %397 = add i64 %396, -1
  store i64 %397, ptr %394, align 8, !tbaa !15
  %398 = icmp eq i64 %396, 0
  br i1 %398, label %393, label %399, !llvm.loop !166

399:                                              ; preds = %393
  %400 = load i64, ptr %390, align 8, !tbaa !15
  %401 = icmp eq i64 %400, 0
  br i1 %401, label %402, label %406

402:                                              ; preds = %399
  %403 = icmp eq i64 %6, 0
  br i1 %403, label %406, label %404

404:                                              ; preds = %402
  %405 = shl nuw i64 %6, 3
  call void @llvm.memset.p0.i64(ptr nonnull align 8 %386, i8 0, i64 %405, i1 false), !tbaa !15
  br label %406

406:                                              ; preds = %404, %402, %399
  %407 = phi i64 [ 1, %404 ], [ 1, %402 ], [ 0, %399 ]
  store i64 %407, ptr %390, align 8, !tbaa !15
  br label %408

408:                                              ; preds = %406, %383
  %409 = icmp sgt i64 %15, 1
  br i1 %409, label %410, label %445

410:                                              ; preds = %408
  %411 = sub i64 %388, %16
  %412 = icmp eq i64 %6, 0
  %413 = shl nuw i64 %6, 3
  br label %414

414:                                              ; preds = %442, %410
  %415 = phi i64 [ 1, %410 ], [ %443, %442 ]
  %416 = getelementptr ptr, ptr %3, i64 %415
  %417 = getelementptr i8, ptr %416, i64 -8
  %418 = load ptr, ptr %417, align 8, !tbaa !7
  %419 = getelementptr inbounds ptr, ptr %4, i64 %415
  store ptr %418, ptr %419, align 8, !tbaa !7
  %420 = load ptr, ptr %416, align 8, !tbaa !7
  %421 = sub nsw i64 %415, %15
  %422 = mul i64 %421, %8
  %423 = add i64 %411, %422
  call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %418, ptr noundef %420, i64 noundef %423, i64 noundef %6)
  %424 = getelementptr inbounds i64, ptr %418, i64 %6
  %425 = load i64, ptr %424, align 8, !tbaa !15
  %426 = icmp eq i64 %425, 0
  br i1 %426, label %442, label %427

427:                                              ; preds = %427, %414
  %428 = phi ptr [ %429, %427 ], [ %418, %414 ]
  %429 = getelementptr inbounds i8, ptr %428, i64 8
  %430 = load i64, ptr %428, align 8, !tbaa !15
  %431 = add i64 %430, -1
  store i64 %431, ptr %428, align 8, !tbaa !15
  %432 = icmp eq i64 %430, 0
  br i1 %432, label %427, label %433, !llvm.loop !166

433:                                              ; preds = %427
  %434 = load i64, ptr %424, align 8, !tbaa !15
  %435 = icmp ne i64 %434, 0
  %436 = or i1 %435, %412
  %437 = xor i1 %435, true
  %438 = zext i1 %437 to i64
  br i1 %436, label %440, label %439

439:                                              ; preds = %433
  call void @llvm.memset.p0.i64(ptr align 8 %418, i8 0, i64 %413, i1 false), !tbaa !15
  br label %440

440:                                              ; preds = %439, %433
  %441 = phi i64 [ 1, %439 ], [ %438, %433 ]
  store i64 %441, ptr %424, align 8, !tbaa !15
  br label %442

442:                                              ; preds = %440, %414
  %443 = add nuw nsw i64 %415, 1
  %444 = icmp eq i64 %443, %15
  br i1 %444, label %445, label %414, !llvm.loop !173

445:                                              ; preds = %442, %408
  %446 = add nsw i64 %6, 1
  %447 = icmp eq i64 %446, 0
  br i1 %447, label %451, label %448

448:                                              ; preds = %445
  %449 = shl i64 %6, 3
  %450 = add i64 %449, 8
  call void @llvm.memset.p0.i64(ptr align 8 %10, i8 0, i64 %450, i1 false), !tbaa !15
  br label %451

451:                                              ; preds = %448, %445
  %452 = add nsw i64 %15, -1
  %453 = mul nsw i64 %452, %7
  %454 = add nsw i64 %453, %6
  %455 = add nsw i64 %454, 1
  %456 = icmp eq i64 %455, 0
  br i1 %456, label %459, label %457

457:                                              ; preds = %451
  %458 = shl nuw i64 %455, 3
  call void @llvm.memset.p0.i64(ptr align 8 %5, i8 0, i64 %458, i1 false), !tbaa !15
  br label %459

459:                                              ; preds = %457, %451
  %460 = icmp eq i32 %2, 63
  br i1 %460, label %547, label %461

461:                                              ; preds = %459
  %462 = shl nsw i64 %7, 4
  %463 = getelementptr inbounds i8, ptr %10, i64 %462
  br label %464

464:                                              ; preds = %541, %461
  %465 = phi i64 [ %452, %461 ], [ %543, %541 ]
  %466 = phi i64 [ %454, %461 ], [ %544, %541 ]
  %467 = phi i64 [ 0, %461 ], [ %542, %541 ]
  %468 = phi i64 [ %453, %461 ], [ %545, %541 ]
  %469 = getelementptr inbounds i64, ptr %5, i64 %468
  %470 = sub nsw i64 %15, %465
  %471 = and i64 %470, %452
  %472 = sub nsw i64 %455, %468
  %473 = getelementptr inbounds ptr, ptr %4, i64 %471
  br i1 %447, label %487, label %474

474:                                              ; preds = %464
  %475 = load ptr, ptr %473, align 8, !tbaa !7
  %476 = call i64 @__gmpn_add_n(ptr noundef %469, ptr noundef %469, ptr noundef %475, i64 noundef %446) #16
  %477 = icmp eq i64 %476, 0
  br i1 %477, label %487, label %478

478:                                              ; preds = %481, %474
  %479 = phi i64 [ %485, %481 ], [ %446, %474 ]
  %480 = icmp slt i64 %479, %472
  br i1 %480, label %481, label %487

481:                                              ; preds = %478
  %482 = getelementptr inbounds i64, ptr %469, i64 %479
  %483 = load i64, ptr %482, align 8, !tbaa !15
  %484 = add i64 %483, 1
  %485 = add nsw i64 %479, 1
  store i64 %484, ptr %482, align 8, !tbaa !15
  %486 = icmp eq i64 %484, 0
  br i1 %486, label %478, label %487, !llvm.loop !174

487:                                              ; preds = %481, %478, %474, %464
  %488 = phi i64 [ 0, %474 ], [ 0, %464 ], [ 1, %478 ], [ 0, %481 ]
  %489 = add i64 %488, %467
  %490 = add nuw nsw i64 %465, 1
  store i64 %490, ptr %463, align 8, !tbaa !15
  %491 = load ptr, ptr %473, align 8, !tbaa !7
  br label %492

492:                                              ; preds = %495, %487
  %493 = phi i64 [ %446, %487 ], [ %496, %495 ]
  %494 = icmp sgt i64 %493, 0
  br i1 %494, label %495, label %541

495:                                              ; preds = %492
  %496 = add nsw i64 %493, -1
  %497 = getelementptr inbounds i64, ptr %491, i64 %496
  %498 = load i64, ptr %497, align 8, !tbaa !15
  %499 = getelementptr inbounds i64, ptr %10, i64 %496
  %500 = load i64, ptr %499, align 8, !tbaa !15
  %501 = icmp eq i64 %498, %500
  br i1 %501, label %492, label %502, !llvm.loop !175

502:                                              ; preds = %495
  %503 = icmp ugt i64 %498, %500
  br i1 %503, label %504, label %541

504:                                              ; preds = %502
  %505 = load i64, ptr %469, align 8, !tbaa !15
  %506 = add i64 %505, -1
  store i64 %506, ptr %469, align 8, !tbaa !15
  %507 = icmp eq i64 %505, 0
  br i1 %507, label %508, label %519

508:                                              ; preds = %504
  %509 = call i64 @llvm.smax.i64(i64 %472, i64 1)
  br label %510

510:                                              ; preds = %513, %508
  %511 = phi i64 [ %517, %513 ], [ 1, %508 ]
  %512 = icmp eq i64 %511, %509
  br i1 %512, label %519, label %513

513:                                              ; preds = %510
  %514 = getelementptr inbounds i64, ptr %469, i64 %511
  %515 = load i64, ptr %514, align 8, !tbaa !15
  %516 = add i64 %515, -1
  store i64 %516, ptr %514, align 8, !tbaa !15
  %517 = add nuw i64 %511, 1
  %518 = icmp eq i64 %515, 0
  br i1 %518, label %510, label %519, !llvm.loop !176

519:                                              ; preds = %513, %510, %504
  %520 = phi i64 [ 0, %504 ], [ -1, %510 ], [ 0, %513 ]
  %521 = getelementptr inbounds i64, ptr %5, i64 %466
  %522 = load i64, ptr %521, align 8, !tbaa !15
  %523 = add i64 %522, -1
  store i64 %523, ptr %521, align 8, !tbaa !15
  %524 = icmp eq i64 %522, 0
  br i1 %524, label %525, label %537

525:                                              ; preds = %519
  %526 = sub nsw i64 %455, %466
  %527 = call i64 @llvm.smax.i64(i64 %526, i64 1)
  br label %528

528:                                              ; preds = %531, %525
  %529 = phi i64 [ %535, %531 ], [ 1, %525 ]
  %530 = icmp eq i64 %529, %527
  br i1 %530, label %537, label %531

531:                                              ; preds = %528
  %532 = getelementptr inbounds i64, ptr %521, i64 %529
  %533 = load i64, ptr %532, align 8, !tbaa !15
  %534 = add i64 %533, -1
  store i64 %534, ptr %532, align 8, !tbaa !15
  %535 = add nuw i64 %529, 1
  %536 = icmp eq i64 %533, 0
  br i1 %536, label %528, label %537, !llvm.loop !176

537:                                              ; preds = %531, %528, %519
  %538 = phi i64 [ 0, %519 ], [ -1, %528 ], [ 0, %531 ]
  %539 = add i64 %520, %489
  %540 = add i64 %539, %538
  br label %541

541:                                              ; preds = %537, %502, %492
  %542 = phi i64 [ %540, %537 ], [ %489, %502 ], [ %489, %492 ]
  %543 = add nsw i64 %465, -1
  %544 = sub nsw i64 %466, %7
  %545 = sub nsw i64 %468, %7
  %546 = icmp sgt i64 %465, 0
  br i1 %546, label %464, label %547, !llvm.loop !177

547:                                              ; preds = %541, %459
  %548 = phi i64 [ 0, %459 ], [ %542, %541 ]
  switch i64 %548, label %624 [
    i64 -1, label %549
    i64 1, label %588
  ]

549:                                              ; preds = %547
  %550 = getelementptr inbounds i64, ptr %5, i64 %455
  %551 = sub i64 0, %1
  %552 = getelementptr inbounds i64, ptr %550, i64 %551
  %553 = load i64, ptr %552, align 8, !tbaa !15
  %554 = add i64 %553, 1
  store i64 %554, ptr %552, align 8, !tbaa !15
  %555 = icmp eq i64 %554, 0
  br i1 %555, label %556, label %624

556:                                              ; preds = %549
  %557 = call i64 @llvm.smax.i64(i64 %1, i64 1)
  br label %558

558:                                              ; preds = %561, %556
  %559 = phi i64 [ %565, %561 ], [ 1, %556 ]
  %560 = icmp eq i64 %559, %557
  br i1 %560, label %567, label %561

561:                                              ; preds = %558
  %562 = getelementptr inbounds i64, ptr %552, i64 %559
  %563 = load i64, ptr %562, align 8, !tbaa !15
  %564 = add i64 %563, 1
  store i64 %564, ptr %562, align 8, !tbaa !15
  %565 = add nuw i64 %559, 1
  %566 = icmp eq i64 %564, 0
  br i1 %566, label %558, label %624, !llvm.loop !170

567:                                              ; preds = %558
  %568 = getelementptr inbounds i8, ptr %552, i64 -8
  %569 = load i64, ptr %568, align 8, !tbaa !15
  %570 = add i64 %569, -1
  store i64 %570, ptr %568, align 8, !tbaa !15
  %571 = icmp eq i64 %569, 0
  br i1 %571, label %572, label %584

572:                                              ; preds = %567
  %573 = call i64 @llvm.smax.i64(i64 %1, i64 0)
  %574 = add nuw nsw i64 %573, 1
  br label %575

575:                                              ; preds = %578, %572
  %576 = phi i64 [ %582, %578 ], [ 1, %572 ]
  %577 = icmp eq i64 %576, %574
  br i1 %577, label %584, label %578

578:                                              ; preds = %575
  %579 = getelementptr inbounds i64, ptr %568, i64 %576
  %580 = load i64, ptr %579, align 8, !tbaa !15
  %581 = add i64 %580, -1
  store i64 %581, ptr %579, align 8, !tbaa !15
  %582 = add nuw i64 %576, 1
  %583 = icmp eq i64 %580, 0
  br i1 %583, label %575, label %584, !llvm.loop !176

584:                                              ; preds = %578, %575, %567
  %585 = getelementptr inbounds i8, ptr %550, i64 -8
  %586 = load i64, ptr %585, align 8, !tbaa !15
  %587 = add i64 %586, -1
  store i64 %587, ptr %585, align 8, !tbaa !15
  br label %624

588:                                              ; preds = %547
  %589 = shl nsw i64 %1, 1
  %590 = icmp slt i64 %455, %589
  %591 = getelementptr inbounds i64, ptr %5, i64 %455
  br i1 %590, label %614, label %592

592:                                              ; preds = %588
  %593 = sub i64 0, %589
  %594 = getelementptr inbounds i64, ptr %591, i64 %593
  %595 = load i64, ptr %594, align 8, !tbaa !15
  %596 = call i64 @llvm.smax.i64(i64 %589, i64 1)
  br label %597

597:                                              ; preds = %611, %592
  %598 = phi i64 [ %600, %611 ], [ %595, %592 ]
  %599 = phi i64 [ %613, %611 ], [ 1, %592 ]
  %600 = add i64 %598, %599
  %601 = icmp ult i64 %600, %599
  br i1 %601, label %602, label %611

602:                                              ; preds = %605, %597
  %603 = phi i64 [ %609, %605 ], [ 1, %597 ]
  %604 = icmp ne i64 %603, %596
  br i1 %604, label %605, label %611

605:                                              ; preds = %602
  %606 = getelementptr inbounds i64, ptr %594, i64 %603
  %607 = load i64, ptr %606, align 8, !tbaa !15
  %608 = add i64 %607, 1
  store i64 %608, ptr %606, align 8, !tbaa !15
  %609 = add nuw i64 %603, 1
  %610 = icmp eq i64 %608, 0
  br i1 %610, label %602, label %611, !llvm.loop !170

611:                                              ; preds = %605, %602, %597
  %612 = phi i1 [ true, %597 ], [ %604, %602 ], [ %604, %605 ]
  %613 = phi i64 [ 0, %597 ], [ 0, %605 ], [ 1, %602 ]
  br i1 %612, label %623, label %597, !llvm.loop !178

614:                                              ; preds = %588
  %615 = sub i64 0, %1
  %616 = getelementptr inbounds i64, ptr %591, i64 %615
  br label %617

617:                                              ; preds = %617, %614
  %618 = phi ptr [ %616, %614 ], [ %619, %617 ]
  %619 = getelementptr inbounds i8, ptr %618, i64 8
  %620 = load i64, ptr %618, align 8, !tbaa !15
  %621 = add i64 %620, -1
  store i64 %621, ptr %618, align 8, !tbaa !15
  %622 = icmp eq i64 %620, 0
  br i1 %622, label %617, label %624, !llvm.loop !179

623:                                              ; preds = %611
  store i64 %600, ptr %594, align 8, !tbaa !15
  br label %624

624:                                              ; preds = %623, %617, %584, %561, %549, %547
  %625 = shl nsw i64 %1, 1
  %626 = sub nsw i64 %455, %625
  %627 = icmp sgt i64 %626, 0
  br i1 %627, label %628, label %671

628:                                              ; preds = %624
  %629 = getelementptr inbounds i64, ptr %5, i64 %625
  %630 = call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %5, ptr noundef %629, i64 noundef %626) #16
  %631 = getelementptr inbounds i64, ptr %0, i64 %626
  %632 = getelementptr inbounds i64, ptr %5, i64 %626
  %633 = sub nsw i64 %1, %626
  %634 = load i64, ptr %632, align 8, !tbaa !15
  %635 = add i64 %634, %630
  store i64 %635, ptr %631, align 8, !tbaa !15
  %636 = icmp ult i64 %635, %630
  br i1 %636, label %637, label %660

637:                                              ; preds = %628
  %638 = call i64 @llvm.smax.i64(i64 %633, i64 1)
  br label %639

639:                                              ; preds = %642, %637
  %640 = phi i64 [ %647, %642 ], [ 1, %637 ]
  %641 = icmp eq i64 %640, %638
  br i1 %641, label %691, label %642

642:                                              ; preds = %639
  %643 = getelementptr inbounds i64, ptr %632, i64 %640
  %644 = load i64, ptr %643, align 8, !tbaa !15
  %645 = add i64 %644, 1
  %646 = getelementptr inbounds i64, ptr %631, i64 %640
  store i64 %645, ptr %646, align 8, !tbaa !15
  %647 = add nuw i64 %640, 1
  %648 = icmp eq i64 %645, 0
  br i1 %648, label %639, label %649, !llvm.loop !170

649:                                              ; preds = %642
  %650 = icmp ne ptr %5, %0
  %651 = icmp slt i64 %647, %633
  %652 = select i1 %650, i1 %651, i1 false
  br i1 %652, label %653, label %691

653:                                              ; preds = %653, %649
  %654 = phi i64 [ %658, %653 ], [ %647, %649 ]
  %655 = getelementptr inbounds i64, ptr %632, i64 %654
  %656 = load i64, ptr %655, align 8, !tbaa !15
  %657 = getelementptr inbounds i64, ptr %631, i64 %654
  store i64 %656, ptr %657, align 8, !tbaa !15
  %658 = add nuw nsw i64 %654, 1
  %659 = icmp slt i64 %658, %633
  br i1 %659, label %653, label %691, !llvm.loop !180

660:                                              ; preds = %628
  %661 = icmp ne ptr %5, %0
  %662 = icmp sgt i64 %633, 1
  %663 = and i1 %661, %662
  br i1 %663, label %664, label %691

664:                                              ; preds = %664, %660
  %665 = phi i64 [ %669, %664 ], [ 1, %660 ]
  %666 = getelementptr inbounds i64, ptr %632, i64 %665
  %667 = load i64, ptr %666, align 8, !tbaa !15
  %668 = getelementptr inbounds i64, ptr %631, i64 %665
  store i64 %667, ptr %668, align 8, !tbaa !15
  %669 = add nuw nsw i64 %665, 1
  %670 = icmp eq i64 %669, %633
  br i1 %670, label %691, label %664, !llvm.loop !181

671:                                              ; preds = %624
  %672 = sub nsw i64 %455, %1
  %673 = icmp eq i64 %1, 0
  br i1 %673, label %691, label %674

674:                                              ; preds = %671
  %675 = add nsw i64 %1, -1
  %676 = load i64, ptr %5, align 8, !tbaa !15
  %677 = icmp eq i64 %675, 0
  br i1 %677, label %688, label %678

678:                                              ; preds = %678, %674
  %679 = phi i64 [ %686, %678 ], [ %675, %674 ]
  %680 = phi ptr [ %684, %678 ], [ %0, %674 ]
  %681 = phi ptr [ %683, %678 ], [ %5, %674 ]
  %682 = phi i64 [ %685, %678 ], [ %676, %674 ]
  %683 = getelementptr inbounds i8, ptr %681, i64 8
  %684 = getelementptr inbounds i8, ptr %680, i64 8
  store i64 %682, ptr %680, align 8, !tbaa !15
  %685 = load i64, ptr %683, align 8, !tbaa !15
  %686 = add nsw i64 %679, -1
  %687 = icmp eq i64 %686, 0
  br i1 %687, label %688, label %678, !llvm.loop !182

688:                                              ; preds = %678, %674
  %689 = phi ptr [ %0, %674 ], [ %684, %678 ]
  %690 = phi i64 [ %676, %674 ], [ %685, %678 ]
  store i64 %690, ptr %689, align 8, !tbaa !15
  br label %691

691:                                              ; preds = %688, %671, %664, %660, %653, %649, %639
  %692 = phi i64 [ 0, %688 ], [ 0, %671 ], [ 0, %649 ], [ 0, %660 ], [ 0, %653 ], [ 1, %639 ], [ 0, %664 ]
  %693 = phi i64 [ %672, %688 ], [ %672, %671 ], [ %1, %649 ], [ %1, %660 ], [ %1, %653 ], [ %1, %639 ], [ %1, %664 ]
  %694 = icmp eq i64 %693, 0
  br i1 %694, label %708, label %695

695:                                              ; preds = %691
  %696 = getelementptr inbounds i64, ptr %5, i64 %1
  %697 = call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %0, ptr noundef %696, i64 noundef %693) #16
  %698 = icmp eq i64 %697, 0
  br i1 %698, label %708, label %699

699:                                              ; preds = %702, %695
  %700 = phi i64 [ %706, %702 ], [ %693, %695 ]
  %701 = icmp slt i64 %700, %1
  br i1 %701, label %702, label %708

702:                                              ; preds = %699
  %703 = getelementptr inbounds i64, ptr %0, i64 %700
  %704 = load i64, ptr %703, align 8, !tbaa !15
  %705 = add i64 %704, -1
  %706 = add nsw i64 %700, 1
  store i64 %705, ptr %703, align 8, !tbaa !15
  %707 = icmp eq i64 %704, 0
  br i1 %707, label %699, label %708, !llvm.loop !160

708:                                              ; preds = %702, %699, %695, %691
  %709 = phi i64 [ 0, %695 ], [ 0, %691 ], [ -1, %699 ], [ 0, %702 ]
  %710 = add nsw i64 %709, %692
  %711 = icmp slt i64 %710, 0
  br i1 %711, label %712, label %727

712:                                              ; preds = %708
  %713 = load i64, ptr %0, align 8, !tbaa !15
  %714 = add i64 %713, 1
  store i64 %714, ptr %0, align 8, !tbaa !15
  %715 = icmp eq i64 %714, 0
  br i1 %715, label %716, label %727

716:                                              ; preds = %712
  %717 = call i64 @llvm.smax.i64(i64 %1, i64 1)
  br label %718

718:                                              ; preds = %721, %716
  %719 = phi i64 [ %725, %721 ], [ 1, %716 ]
  %720 = icmp eq i64 %719, %717
  br i1 %720, label %727, label %721

721:                                              ; preds = %718
  %722 = getelementptr inbounds i64, ptr %0, i64 %719
  %723 = load i64, ptr %722, align 8, !tbaa !15
  %724 = add i64 %723, 1
  store i64 %724, ptr %722, align 8, !tbaa !15
  %725 = add nuw i64 %719, 1
  %726 = icmp eq i64 %724, 0
  br i1 %726, label %718, label %727, !llvm.loop !170

727:                                              ; preds = %721, %718, %712, %708
  %728 = phi i64 [ %710, %708 ], [ 0, %712 ], [ 1, %718 ], [ 0, %721 ]
  ret i64 %728
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_fft_fft(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, ptr noundef %6) unnamed_addr #5 {
  %8 = icmp eq i64 %1, 2
  br i1 %8, label %9, label %67

9:                                                ; preds = %7
  %10 = add nsw i64 %4, 1
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %29, label %12

12:                                               ; preds = %9
  %13 = load ptr, ptr %0, align 8, !tbaa !7
  %14 = load i64, ptr %13, align 8, !tbaa !15
  %15 = icmp eq i64 %4, 0
  br i1 %15, label %26, label %16

16:                                               ; preds = %16, %12
  %17 = phi i64 [ %23, %16 ], [ %14, %12 ]
  %18 = phi ptr [ %21, %16 ], [ %13, %12 ]
  %19 = phi ptr [ %22, %16 ], [ %6, %12 ]
  %20 = phi i64 [ %24, %16 ], [ %4, %12 ]
  %21 = getelementptr inbounds i8, ptr %18, i64 8
  %22 = getelementptr inbounds i8, ptr %19, i64 8
  store i64 %17, ptr %19, align 8, !tbaa !15
  %23 = load i64, ptr %21, align 8, !tbaa !15
  %24 = add nsw i64 %20, -1
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %26, label %16, !llvm.loop !183

26:                                               ; preds = %16, %12
  %27 = phi i64 [ %14, %12 ], [ %23, %16 ]
  %28 = phi ptr [ %6, %12 ], [ %22, %16 ]
  store i64 %27, ptr %28, align 8, !tbaa !15
  br label %29

29:                                               ; preds = %26, %9
  %30 = load ptr, ptr %0, align 8, !tbaa !7
  %31 = getelementptr inbounds ptr, ptr %0, i64 %5
  %32 = load ptr, ptr %31, align 8, !tbaa !7
  %33 = tail call i64 @__gmpn_add_n(ptr noundef %30, ptr noundef %30, ptr noundef %32, i64 noundef %10) #16
  %34 = load ptr, ptr %31, align 8, !tbaa !7
  %35 = tail call i64 @__gmpn_sub_n(ptr noundef %34, ptr noundef %6, ptr noundef %34, i64 noundef %10) #16
  %36 = load ptr, ptr %0, align 8, !tbaa !7
  %37 = getelementptr inbounds i64, ptr %36, i64 %4
  %38 = load i64, ptr %37, align 8, !tbaa !15
  %39 = icmp ugt i64 %38, 1
  br i1 %39, label %40, label %51

40:                                               ; preds = %29
  store i64 1, ptr %37, align 8, !tbaa !15
  %41 = add i64 %38, -1
  %42 = load i64, ptr %36, align 8, !tbaa !15
  %43 = sub i64 %42, %41
  store i64 %43, ptr %36, align 8, !tbaa !15
  %44 = icmp ult i64 %42, %41
  br i1 %44, label %45, label %51

45:                                               ; preds = %45, %40
  %46 = phi ptr [ %47, %45 ], [ %36, %40 ]
  %47 = getelementptr inbounds i8, ptr %46, i64 8
  %48 = load i64, ptr %47, align 8, !tbaa !15
  %49 = add i64 %48, -1
  store i64 %49, ptr %47, align 8, !tbaa !15
  %50 = icmp eq i64 %48, 0
  br i1 %50, label %45, label %51, !llvm.loop !184

51:                                               ; preds = %45, %40, %29
  %52 = icmp eq i64 %35, 0
  br i1 %52, label %132, label %53

53:                                               ; preds = %51
  %54 = load ptr, ptr %31, align 8, !tbaa !7
  %55 = getelementptr inbounds i64, ptr %54, i64 %4
  %56 = load i64, ptr %55, align 8, !tbaa !15
  store i64 0, ptr %55, align 8, !tbaa !15
  %57 = sub i64 0, %56
  %58 = load i64, ptr %54, align 8, !tbaa !15
  %59 = sub i64 %58, %56
  store i64 %59, ptr %54, align 8, !tbaa !15
  %60 = icmp ult i64 %59, %57
  br i1 %60, label %61, label %132

61:                                               ; preds = %61, %53
  %62 = phi ptr [ %63, %61 ], [ %54, %53 ]
  %63 = getelementptr inbounds i8, ptr %62, i64 8
  %64 = load i64, ptr %63, align 8, !tbaa !15
  %65 = add i64 %64, 1
  store i64 %65, ptr %63, align 8, !tbaa !15
  %66 = icmp eq i64 %65, 0
  br i1 %66, label %61, label %132, !llvm.loop !185

67:                                               ; preds = %7
  %68 = ashr i64 %1, 1
  %69 = load ptr, ptr %2, align 8, !tbaa !7
  %70 = getelementptr inbounds i8, ptr %2, i64 -8
  %71 = shl nsw i64 %3, 1
  %72 = shl nsw i64 %5, 1
  tail call fastcc void @mpn_fft_fft(ptr noundef %0, i64 noundef %68, ptr noundef nonnull %70, i64 noundef %71, i64 noundef %4, i64 noundef %72, ptr noundef %6)
  %73 = getelementptr inbounds ptr, ptr %0, i64 %5
  tail call fastcc void @mpn_fft_fft(ptr noundef %73, i64 noundef %68, ptr noundef nonnull %70, i64 noundef %71, i64 noundef %4, i64 noundef %72, ptr noundef %6)
  %74 = icmp sgt i64 %68, 0
  br i1 %74, label %75, label %132

75:                                               ; preds = %67
  %76 = getelementptr inbounds i64, ptr %6, i64 %4
  br label %77

77:                                               ; preds = %127, %75
  %78 = phi ptr [ %69, %75 ], [ %129, %127 ]
  %79 = phi ptr [ %0, %75 ], [ %130, %127 ]
  %80 = phi i64 [ 0, %75 ], [ %128, %127 ]
  %81 = getelementptr inbounds ptr, ptr %79, i64 %5
  %82 = load ptr, ptr %81, align 8, !tbaa !7
  %83 = load i32, ptr %78, align 4, !tbaa !124
  %84 = sext i32 %83 to i64
  %85 = mul nsw i64 %84, %3
  tail call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %6, ptr noundef %82, i64 noundef %85, i64 noundef %4)
  %86 = load ptr, ptr %81, align 8, !tbaa !7
  %87 = load ptr, ptr %79, align 8, !tbaa !7
  %88 = getelementptr inbounds i64, ptr %87, i64 %4
  %89 = load i64, ptr %88, align 8, !tbaa !15
  %90 = load i64, ptr %76, align 8, !tbaa !15
  %91 = tail call i64 @__gmpn_sub_n(ptr noundef %86, ptr noundef %87, ptr noundef %6, i64 noundef %4) #16
  %92 = add i64 %90, %91
  %93 = sub i64 %89, %92
  %94 = sub i64 0, %93
  %95 = icmp slt i64 %93, 0
  %96 = select i1 %95, i64 %94, i64 0
  %97 = add i64 %96, %93
  %98 = getelementptr inbounds i64, ptr %86, i64 %4
  store i64 %97, ptr %98, align 8, !tbaa !15
  %99 = load i64, ptr %86, align 8, !tbaa !15
  %100 = add i64 %99, %96
  store i64 %100, ptr %86, align 8, !tbaa !15
  %101 = icmp ult i64 %100, %96
  br i1 %101, label %102, label %108

102:                                              ; preds = %102, %77
  %103 = phi ptr [ %104, %102 ], [ %86, %77 ]
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = load i64, ptr %104, align 8, !tbaa !15
  %106 = add i64 %105, 1
  store i64 %106, ptr %104, align 8, !tbaa !15
  %107 = icmp eq i64 %106, 0
  br i1 %107, label %102, label %108, !llvm.loop !186

108:                                              ; preds = %102, %77
  %109 = load ptr, ptr %79, align 8, !tbaa !7
  %110 = getelementptr inbounds i64, ptr %109, i64 %4
  %111 = load i64, ptr %110, align 8, !tbaa !15
  %112 = load i64, ptr %76, align 8, !tbaa !15
  %113 = add i64 %112, %111
  %114 = tail call i64 @__gmpn_add_n(ptr noundef %109, ptr noundef %109, ptr noundef %6, i64 noundef %4) #16
  %115 = add i64 %113, %114
  %116 = tail call i64 @llvm.usub.sat.i64(i64 %115, i64 1)
  %117 = sub i64 %115, %116
  store i64 %117, ptr %110, align 8, !tbaa !15
  %118 = load i64, ptr %109, align 8, !tbaa !15
  %119 = sub i64 %118, %116
  store i64 %119, ptr %109, align 8, !tbaa !15
  %120 = icmp ult i64 %118, %116
  br i1 %120, label %121, label %127

121:                                              ; preds = %121, %108
  %122 = phi ptr [ %123, %121 ], [ %109, %108 ]
  %123 = getelementptr inbounds i8, ptr %122, i64 8
  %124 = load i64, ptr %123, align 8, !tbaa !15
  %125 = add i64 %124, -1
  store i64 %125, ptr %123, align 8, !tbaa !15
  %126 = icmp eq i64 %124, 0
  br i1 %126, label %121, label %127, !llvm.loop !187

127:                                              ; preds = %121, %108
  %128 = add nuw nsw i64 %80, 1
  %129 = getelementptr inbounds i8, ptr %78, i64 8
  %130 = getelementptr inbounds ptr, ptr %79, i64 %72
  %131 = icmp eq i64 %128, %68
  br i1 %131, label %132, label %77, !llvm.loop !188

132:                                              ; preds = %127, %67, %61, %53, %51
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqrmod_bknp1(ptr noundef %0, ptr noundef %1, i64 noundef %2, i32 noundef %3, ptr noundef %4) local_unnamed_addr #5 {
  %6 = add i32 %3, -1
  %7 = zext i32 %6 to i64
  %8 = mul nsw i64 %7, %2
  %9 = shl nsw i64 %8, 1
  %10 = getelementptr inbounds i64, ptr %4, i64 %9
  tail call fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %10, ptr noundef %1, i64 noundef %2, i32 noundef %3)
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %10, i64 noundef %8) #16
  %11 = zext i32 %3 to i64
  %12 = mul nsw i64 %11, %2
  %13 = sub nsw i64 %9, %12
  %14 = icmp eq i64 %13, 0
  br i1 %14, label %28, label %15

15:                                               ; preds = %5
  %16 = getelementptr inbounds i64, ptr %4, i64 %12
  %17 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %16, i64 noundef %13) #16
  %18 = icmp eq i64 %17, 0
  br i1 %18, label %28, label %19

19:                                               ; preds = %22, %15
  %20 = phi i64 [ %26, %22 ], [ %13, %15 ]
  %21 = icmp slt i64 %20, %12
  br i1 %21, label %22, label %28

22:                                               ; preds = %19
  %23 = getelementptr inbounds i64, ptr %4, i64 %20
  %24 = load i64, ptr %23, align 8, !tbaa !15
  %25 = add i64 %24, -1
  %26 = add nsw i64 %20, 1
  store i64 %25, ptr %23, align 8, !tbaa !15
  %27 = icmp eq i64 %24, 0
  br i1 %27, label %19, label %28, !llvm.loop !133

28:                                               ; preds = %22, %19, %15, %5
  %29 = phi i64 [ 0, %15 ], [ 0, %5 ], [ 1, %19 ], [ 0, %22 ]
  %30 = getelementptr inbounds i64, ptr %4, i64 %12
  store i64 0, ptr %30, align 8, !tbaa !15
  %31 = load i64, ptr %4, align 8, !tbaa !15
  %32 = add i64 %31, %29
  store i64 %32, ptr %4, align 8, !tbaa !15
  %33 = icmp ult i64 %32, %29
  br i1 %33, label %34, label %40

34:                                               ; preds = %34, %28
  %35 = phi ptr [ %36, %34 ], [ %4, %28 ]
  %36 = getelementptr inbounds i8, ptr %35, i64 8
  %37 = load i64, ptr %36, align 8, !tbaa !15
  %38 = add i64 %37, 1
  store i64 %38, ptr %36, align 8, !tbaa !15
  %39 = icmp eq i64 %38, 0
  br i1 %39, label %34, label %40, !llvm.loop !134

40:                                               ; preds = %34, %28
  %41 = getelementptr inbounds i8, ptr %30, i64 8
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef nonnull %41, ptr noundef %1, i64 noundef %2, i32 noundef %3)
  %42 = getelementptr i64, ptr %41, i64 %2
  %43 = getelementptr i8, ptr %42, i64 8
  %44 = load i64, ptr %42, align 8, !tbaa !15
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %53, label %46, !prof !68

46:                                               ; preds = %40
  store i64 1, ptr %43, align 8, !tbaa !15
  %47 = shl nuw nsw i64 %11, 3
  %48 = add nuw nsw i64 %47, 8
  %49 = mul i64 %48, %2
  %50 = getelementptr i8, ptr %4, i64 %49
  %51 = getelementptr i8, ptr %50, i64 24
  %52 = shl nuw i64 %2, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %51, i8 0, i64 %52, i1 false), !tbaa !15
  br label %82

53:                                               ; preds = %40
  %54 = icmp sgt i64 %2, 24
  br i1 %54, label %55, label %70

55:                                               ; preds = %53
  %56 = urem i64 %2, 3
  %57 = icmp eq i64 %56, 0
  br i1 %57, label %66, label %58

58:                                               ; preds = %55
  %59 = icmp sgt i64 %2, 50
  br i1 %59, label %60, label %70

60:                                               ; preds = %58
  %61 = urem i64 %2, 5
  %62 = icmp eq i64 %61, 0
  br i1 %62, label %66, label %63

63:                                               ; preds = %60
  %64 = urem i64 %2, 7
  %65 = icmp eq i64 %64, 0
  br i1 %65, label %66, label %70

66:                                               ; preds = %63, %60, %55
  %67 = phi i32 [ 3, %55 ], [ 5, %60 ], [ 7, %63 ]
  %68 = zext nneg i32 %67 to i64
  %69 = udiv i64 %2, %68
  tail call void @__gmpn_sqrmod_bknp1(ptr noundef %43, ptr noundef nonnull %41, i64 noundef %69, i32 noundef %67, ptr noundef %43)
  br label %82

70:                                               ; preds = %63, %58, %53
  tail call void @__gmpn_sqr(ptr noundef %43, ptr noundef nonnull %41, i64 noundef %2) #16
  %71 = getelementptr inbounds i64, ptr %43, i64 %2
  %72 = tail call i64 @__gmpn_sub_n(ptr noundef %43, ptr noundef %43, ptr noundef %71, i64 noundef %2) #16
  store i64 0, ptr %71, align 8, !tbaa !15
  %73 = load i64, ptr %43, align 8, !tbaa !15
  %74 = add i64 %73, %72
  store i64 %74, ptr %43, align 8, !tbaa !15
  %75 = icmp ult i64 %74, %72
  br i1 %75, label %76, label %82

76:                                               ; preds = %76, %70
  %77 = phi ptr [ %78, %76 ], [ %43, %70 ]
  %78 = getelementptr inbounds i8, ptr %77, i64 8
  %79 = load i64, ptr %78, align 8, !tbaa !15
  %80 = add i64 %79, 1
  store i64 %80, ptr %78, align 8, !tbaa !15
  %81 = icmp eq i64 %80, 0
  br i1 %81, label %76, label %82, !llvm.loop !189

82:                                               ; preds = %76, %70, %66, %46
  tail call fastcc void @_mpn_crt(ptr noundef %0, ptr noundef nonnull %4, ptr noundef %43, i64 noundef %2, i32 noundef %3, ptr noundef nonnull %41)
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #5 {
  %4 = alloca [366 x i64], align 16
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = icmp sgt i64 %2, 49
  br i1 %8, label %10, label %9

9:                                                ; preds = %3
  tail call void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2) #16
  br label %36

10:                                               ; preds = %3
  %11 = icmp sgt i64 %2, 119
  br i1 %11, label %13, label %12

12:                                               ; preds = %10
  call void @llvm.lifetime.start.p0(i64 2928, ptr nonnull %4) #16
  call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef nonnull %4) #16
  call void @llvm.lifetime.end.p0(i64 2928, ptr nonnull %4) #16
  br label %36

13:                                               ; preds = %10
  %14 = icmp sgt i64 %2, 399
  br i1 %14, label %20, label %15

15:                                               ; preds = %13
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #16
  store ptr null, ptr %5, align 8, !tbaa !7
  %16 = mul i64 %2, 24
  %17 = add i64 %16, 512
  %18 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %5, i64 noundef %17) #16
  call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %18) #16
  %19 = load ptr, ptr %5, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %19) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #16
  br label %36

20:                                               ; preds = %13
  %21 = icmp sgt i64 %2, 449
  br i1 %21, label %27, label %22

22:                                               ; preds = %20
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #16
  store ptr null, ptr %6, align 8, !tbaa !7
  %23 = shl i64 %2, 4
  %24 = add i64 %23, 3312
  %25 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %24) #16
  call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %25) #16
  %26 = load ptr, ptr %6, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %26) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #16
  br label %36

27:                                               ; preds = %20
  %28 = icmp sgt i64 %2, 3599
  br i1 %28, label %35, label %29

29:                                               ; preds = %27
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  store ptr null, ptr %7, align 8, !tbaa !7
  %30 = mul nuw nsw i64 %2, 15
  %31 = and i64 %30, 9223372036854775800
  %32 = add nuw i64 %31, 3768
  %33 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %32) #16
  call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %33) #16
  %34 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %34) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  br label %36

35:                                               ; preds = %27
  tail call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %1, i64 noundef %2) #16
  br label %36

36:                                               ; preds = %35, %29, %22, %15, %12, %9
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_fft_fftinv(ptr noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, ptr noundef %4) unnamed_addr #5 {
  %6 = icmp eq i64 %1, 2
  br i1 %6, label %7, label %65

7:                                                ; preds = %5
  %8 = add nsw i64 %3, 1
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %27, label %10

10:                                               ; preds = %7
  %11 = load ptr, ptr %0, align 8, !tbaa !7
  %12 = load i64, ptr %11, align 8, !tbaa !15
  %13 = icmp eq i64 %3, 0
  br i1 %13, label %24, label %14

14:                                               ; preds = %14, %10
  %15 = phi i64 [ %21, %14 ], [ %12, %10 ]
  %16 = phi ptr [ %19, %14 ], [ %11, %10 ]
  %17 = phi ptr [ %20, %14 ], [ %4, %10 ]
  %18 = phi i64 [ %22, %14 ], [ %3, %10 ]
  %19 = getelementptr inbounds i8, ptr %16, i64 8
  %20 = getelementptr inbounds i8, ptr %17, i64 8
  store i64 %15, ptr %17, align 8, !tbaa !15
  %21 = load i64, ptr %19, align 8, !tbaa !15
  %22 = add nsw i64 %18, -1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %24, label %14, !llvm.loop !190

24:                                               ; preds = %14, %10
  %25 = phi i64 [ %12, %10 ], [ %21, %14 ]
  %26 = phi ptr [ %4, %10 ], [ %20, %14 ]
  store i64 %25, ptr %26, align 8, !tbaa !15
  br label %27

27:                                               ; preds = %24, %7
  %28 = load ptr, ptr %0, align 8, !tbaa !7
  %29 = getelementptr inbounds i8, ptr %0, i64 8
  %30 = load ptr, ptr %29, align 8, !tbaa !7
  %31 = tail call i64 @__gmpn_add_n(ptr noundef %28, ptr noundef %28, ptr noundef %30, i64 noundef %8) #16
  %32 = load ptr, ptr %29, align 8, !tbaa !7
  %33 = tail call i64 @__gmpn_sub_n(ptr noundef %32, ptr noundef %4, ptr noundef %32, i64 noundef %8) #16
  %34 = load ptr, ptr %0, align 8, !tbaa !7
  %35 = getelementptr inbounds i64, ptr %34, i64 %3
  %36 = load i64, ptr %35, align 8, !tbaa !15
  %37 = icmp ugt i64 %36, 1
  br i1 %37, label %38, label %49

38:                                               ; preds = %27
  store i64 1, ptr %35, align 8, !tbaa !15
  %39 = add i64 %36, -1
  %40 = load i64, ptr %34, align 8, !tbaa !15
  %41 = sub i64 %40, %39
  store i64 %41, ptr %34, align 8, !tbaa !15
  %42 = icmp ult i64 %40, %39
  br i1 %42, label %43, label %49

43:                                               ; preds = %43, %38
  %44 = phi ptr [ %45, %43 ], [ %34, %38 ]
  %45 = getelementptr inbounds i8, ptr %44, i64 8
  %46 = load i64, ptr %45, align 8, !tbaa !15
  %47 = add i64 %46, -1
  store i64 %47, ptr %45, align 8, !tbaa !15
  %48 = icmp eq i64 %46, 0
  br i1 %48, label %43, label %49, !llvm.loop !191

49:                                               ; preds = %43, %38, %27
  %50 = icmp eq i64 %33, 0
  br i1 %50, label %123, label %51

51:                                               ; preds = %49
  %52 = load ptr, ptr %29, align 8, !tbaa !7
  %53 = getelementptr inbounds i64, ptr %52, i64 %3
  %54 = load i64, ptr %53, align 8, !tbaa !15
  store i64 0, ptr %53, align 8, !tbaa !15
  %55 = sub i64 0, %54
  %56 = load i64, ptr %52, align 8, !tbaa !15
  %57 = sub i64 %56, %54
  store i64 %57, ptr %52, align 8, !tbaa !15
  %58 = icmp ult i64 %57, %55
  br i1 %58, label %59, label %123

59:                                               ; preds = %59, %51
  %60 = phi ptr [ %61, %59 ], [ %52, %51 ]
  %61 = getelementptr inbounds i8, ptr %60, i64 8
  %62 = load i64, ptr %61, align 8, !tbaa !15
  %63 = add i64 %62, 1
  store i64 %63, ptr %61, align 8, !tbaa !15
  %64 = icmp eq i64 %63, 0
  br i1 %64, label %59, label %123, !llvm.loop !192

65:                                               ; preds = %5
  %66 = ashr i64 %1, 1
  %67 = shl nsw i64 %2, 1
  tail call fastcc void @mpn_fft_fftinv(ptr noundef %0, i64 noundef %66, i64 noundef %67, i64 noundef %3, ptr noundef %4)
  %68 = getelementptr inbounds ptr, ptr %0, i64 %66
  tail call fastcc void @mpn_fft_fftinv(ptr noundef %68, i64 noundef %66, i64 noundef %67, i64 noundef %3, ptr noundef %4)
  %69 = icmp sgt i64 %66, 0
  br i1 %69, label %70, label %123

70:                                               ; preds = %65
  %71 = getelementptr inbounds i64, ptr %4, i64 %3
  br label %72

72:                                               ; preds = %119, %70
  %73 = phi ptr [ %0, %70 ], [ %121, %119 ]
  %74 = phi i64 [ 0, %70 ], [ %120, %119 ]
  %75 = getelementptr inbounds ptr, ptr %73, i64 %66
  %76 = load ptr, ptr %75, align 8, !tbaa !7
  %77 = mul nsw i64 %74, %2
  tail call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %4, ptr noundef %76, i64 noundef %77, i64 noundef %3)
  %78 = load ptr, ptr %75, align 8, !tbaa !7
  %79 = load ptr, ptr %73, align 8, !tbaa !7
  %80 = getelementptr inbounds i64, ptr %79, i64 %3
  %81 = load i64, ptr %80, align 8, !tbaa !15
  %82 = load i64, ptr %71, align 8, !tbaa !15
  %83 = tail call i64 @__gmpn_sub_n(ptr noundef %78, ptr noundef %79, ptr noundef %4, i64 noundef %3) #16
  %84 = add i64 %82, %83
  %85 = sub i64 %81, %84
  %86 = sub i64 0, %85
  %87 = icmp slt i64 %85, 0
  %88 = select i1 %87, i64 %86, i64 0
  %89 = add i64 %88, %85
  %90 = getelementptr inbounds i64, ptr %78, i64 %3
  store i64 %89, ptr %90, align 8, !tbaa !15
  %91 = load i64, ptr %78, align 8, !tbaa !15
  %92 = add i64 %91, %88
  store i64 %92, ptr %78, align 8, !tbaa !15
  %93 = icmp ult i64 %92, %88
  br i1 %93, label %94, label %100

94:                                               ; preds = %94, %72
  %95 = phi ptr [ %96, %94 ], [ %78, %72 ]
  %96 = getelementptr inbounds i8, ptr %95, i64 8
  %97 = load i64, ptr %96, align 8, !tbaa !15
  %98 = add i64 %97, 1
  store i64 %98, ptr %96, align 8, !tbaa !15
  %99 = icmp eq i64 %98, 0
  br i1 %99, label %94, label %100, !llvm.loop !186

100:                                              ; preds = %94, %72
  %101 = load ptr, ptr %73, align 8, !tbaa !7
  %102 = getelementptr inbounds i64, ptr %101, i64 %3
  %103 = load i64, ptr %102, align 8, !tbaa !15
  %104 = load i64, ptr %71, align 8, !tbaa !15
  %105 = add i64 %104, %103
  %106 = tail call i64 @__gmpn_add_n(ptr noundef %101, ptr noundef %101, ptr noundef %4, i64 noundef %3) #16
  %107 = add i64 %105, %106
  %108 = tail call i64 @llvm.usub.sat.i64(i64 %107, i64 1)
  %109 = sub i64 %107, %108
  store i64 %109, ptr %102, align 8, !tbaa !15
  %110 = load i64, ptr %101, align 8, !tbaa !15
  %111 = sub i64 %110, %108
  store i64 %111, ptr %101, align 8, !tbaa !15
  %112 = icmp ult i64 %110, %108
  br i1 %112, label %113, label %119

113:                                              ; preds = %113, %100
  %114 = phi ptr [ %115, %113 ], [ %101, %100 ]
  %115 = getelementptr inbounds i8, ptr %114, i64 8
  %116 = load i64, ptr %115, align 8, !tbaa !15
  %117 = add i64 %116, -1
  store i64 %117, ptr %115, align 8, !tbaa !15
  %118 = icmp eq i64 %116, 0
  br i1 %118, label %113, label %119, !llvm.loop !187

119:                                              ; preds = %113, %100
  %120 = add nuw nsw i64 %74, 1
  %121 = getelementptr inbounds i8, ptr %73, i64 8
  %122 = icmp eq i64 %120, %66
  br i1 %122, label %123, label %72, !llvm.loop !193

123:                                              ; preds = %119, %65, %59, %51, %49
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %0, ptr noundef %1, i64 noundef %2, i64 noundef %3) unnamed_addr #5 {
  %5 = trunc i64 %2 to i32
  %6 = and i32 %5, 63
  %7 = lshr i64 %2, 6
  %8 = icmp slt i64 %7, %3
  br i1 %8, label %89, label %9

9:                                                ; preds = %4
  %10 = sub nsw i64 %7, %3
  %11 = icmp eq i32 %6, 0
  br i1 %11, label %23, label %12

12:                                               ; preds = %9
  %13 = getelementptr inbounds i64, ptr %1, i64 %3
  %14 = sub nsw i64 0, %10
  %15 = getelementptr inbounds i64, ptr %13, i64 %14
  %16 = add nsw i64 %10, 1
  %17 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %15, i64 noundef %16, i32 noundef %6) #16
  %18 = getelementptr inbounds i64, ptr %0, i64 %10
  %19 = load i64, ptr %18, align 8, !tbaa !15
  %20 = sub nsw i64 %3, %10
  %21 = tail call i64 @__gmpn_lshiftc(ptr noundef nonnull %18, ptr noundef %1, i64 noundef %20, i32 noundef %6) #16
  %22 = add i64 %21, 1
  br label %60

23:                                               ; preds = %9
  %24 = icmp eq i64 %7, %3
  br i1 %24, label %45, label %25

25:                                               ; preds = %23
  %26 = add nsw i64 %10, -1
  %27 = getelementptr inbounds i64, ptr %1, i64 %3
  %28 = sub nsw i64 0, %10
  %29 = getelementptr inbounds i64, ptr %27, i64 %28
  %30 = load i64, ptr %29, align 8, !tbaa !15
  %31 = icmp eq i64 %26, 0
  br i1 %31, label %42, label %32

32:                                               ; preds = %32, %25
  %33 = phi ptr [ %37, %32 ], [ %29, %25 ]
  %34 = phi i64 [ %39, %32 ], [ %30, %25 ]
  %35 = phi ptr [ %38, %32 ], [ %0, %25 ]
  %36 = phi i64 [ %40, %32 ], [ %26, %25 ]
  %37 = getelementptr inbounds i8, ptr %33, i64 8
  %38 = getelementptr inbounds i8, ptr %35, i64 8
  store i64 %34, ptr %35, align 8, !tbaa !15
  %39 = load i64, ptr %37, align 8, !tbaa !15
  %40 = add nsw i64 %36, -1
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %42, label %32, !llvm.loop !194

42:                                               ; preds = %32, %25
  %43 = phi i64 [ %30, %25 ], [ %39, %32 ]
  %44 = phi ptr [ %0, %25 ], [ %38, %32 ]
  store i64 %43, ptr %44, align 8, !tbaa !15
  br label %45

45:                                               ; preds = %42, %23
  %46 = getelementptr inbounds i64, ptr %1, i64 %3
  %47 = load i64, ptr %46, align 8, !tbaa !15
  %48 = getelementptr inbounds i64, ptr %0, i64 %10
  %49 = sub nsw i64 %3, %10
  br label %50

50:                                               ; preds = %50, %45
  %51 = phi ptr [ %48, %45 ], [ %57, %50 ]
  %52 = phi ptr [ %1, %45 ], [ %54, %50 ]
  %53 = phi i64 [ %49, %45 ], [ %58, %50 ]
  %54 = getelementptr inbounds i8, ptr %52, i64 8
  %55 = load i64, ptr %52, align 8, !tbaa !15
  %56 = xor i64 %55, -1
  %57 = getelementptr inbounds i8, ptr %51, i64 8
  store i64 %56, ptr %51, align 8, !tbaa !15
  %58 = add nsw i64 %53, -1
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %60, label %50, !llvm.loop !195

60:                                               ; preds = %50, %12
  %61 = phi i64 [ %19, %12 ], [ %47, %50 ]
  %62 = phi i64 [ %22, %12 ], [ 1, %50 ]
  %63 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 0, ptr %63, align 8, !tbaa !15
  %64 = load i64, ptr %0, align 8, !tbaa !15
  %65 = add i64 %64, %62
  store i64 %65, ptr %0, align 8, !tbaa !15
  %66 = icmp ult i64 %65, %62
  br i1 %66, label %67, label %73

67:                                               ; preds = %67, %60
  %68 = phi ptr [ %69, %67 ], [ %0, %60 ]
  %69 = getelementptr inbounds i8, ptr %68, i64 8
  %70 = load i64, ptr %69, align 8, !tbaa !15
  %71 = add i64 %70, 1
  store i64 %71, ptr %69, align 8, !tbaa !15
  %72 = icmp eq i64 %71, 0
  br i1 %72, label %67, label %73, !llvm.loop !196

73:                                               ; preds = %67, %60
  %74 = add i64 %61, 1
  %75 = icmp eq i64 %74, 0
  %76 = zext i1 %75 to i64
  %77 = getelementptr inbounds i64, ptr %0, i64 %10
  %78 = getelementptr inbounds i64, ptr %77, i64 %76
  %79 = add i64 %74, %76
  %80 = load i64, ptr %78, align 8, !tbaa !15
  %81 = add i64 %80, %79
  store i64 %81, ptr %78, align 8, !tbaa !15
  %82 = icmp ult i64 %81, %79
  br i1 %82, label %83, label %210

83:                                               ; preds = %83, %73
  %84 = phi ptr [ %85, %83 ], [ %78, %73 ]
  %85 = getelementptr inbounds i8, ptr %84, i64 8
  %86 = load i64, ptr %85, align 8, !tbaa !15
  %87 = add i64 %86, 1
  store i64 %87, ptr %85, align 8, !tbaa !15
  %88 = icmp eq i64 %87, 0
  br i1 %88, label %83, label %210, !llvm.loop !197

89:                                               ; preds = %4
  %90 = icmp eq i32 %6, 0
  %91 = getelementptr inbounds i64, ptr %1, i64 %3
  %92 = sub nsw i64 0, %7
  %93 = getelementptr inbounds i64, ptr %91, i64 %92
  %94 = add nuw nsw i64 %7, 1
  br i1 %90, label %102, label %95

95:                                               ; preds = %89
  %96 = tail call i64 @__gmpn_lshiftc(ptr noundef %0, ptr noundef %93, i64 noundef %94, i32 noundef %6) #16
  %97 = getelementptr inbounds i64, ptr %0, i64 %7
  %98 = load i64, ptr %97, align 8, !tbaa !15
  %99 = xor i64 %98, -1
  %100 = sub nsw i64 %3, %7
  %101 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %97, ptr noundef %1, i64 noundef %100, i32 noundef %6) #16
  br label %134

102:                                              ; preds = %102, %89
  %103 = phi ptr [ %109, %102 ], [ %0, %89 ]
  %104 = phi ptr [ %106, %102 ], [ %93, %89 ]
  %105 = phi i64 [ %110, %102 ], [ %94, %89 ]
  %106 = getelementptr inbounds i8, ptr %104, i64 8
  %107 = load i64, ptr %104, align 8, !tbaa !15
  %108 = xor i64 %107, -1
  %109 = getelementptr inbounds i8, ptr %103, i64 8
  store i64 %108, ptr %103, align 8, !tbaa !15
  %110 = add nsw i64 %105, -1
  %111 = icmp eq i64 %110, 0
  br i1 %111, label %112, label %102, !llvm.loop !198

112:                                              ; preds = %102
  %113 = load i64, ptr %91, align 8, !tbaa !15
  %114 = icmp eq i64 %7, %3
  br i1 %114, label %134, label %115

115:                                              ; preds = %112
  %116 = xor i64 %7, -1
  %117 = add i64 %116, %3
  %118 = getelementptr inbounds i64, ptr %0, i64 %7
  %119 = load i64, ptr %1, align 8, !tbaa !15
  %120 = icmp eq i64 %117, 0
  br i1 %120, label %131, label %121

121:                                              ; preds = %121, %115
  %122 = phi i64 [ %129, %121 ], [ %117, %115 ]
  %123 = phi ptr [ %127, %121 ], [ %118, %115 ]
  %124 = phi ptr [ %126, %121 ], [ %1, %115 ]
  %125 = phi i64 [ %128, %121 ], [ %119, %115 ]
  %126 = getelementptr inbounds i8, ptr %124, i64 8
  %127 = getelementptr inbounds i8, ptr %123, i64 8
  store i64 %125, ptr %123, align 8, !tbaa !15
  %128 = load i64, ptr %126, align 8, !tbaa !15
  %129 = add nsw i64 %122, -1
  %130 = icmp eq i64 %129, 0
  br i1 %130, label %131, label %121, !llvm.loop !199

131:                                              ; preds = %121, %115
  %132 = phi ptr [ %118, %115 ], [ %127, %121 ]
  %133 = phi i64 [ %119, %115 ], [ %128, %121 ]
  store i64 %133, ptr %132, align 8, !tbaa !15
  br label %134

134:                                              ; preds = %131, %112, %95
  %135 = phi i64 [ %99, %95 ], [ %113, %131 ], [ %113, %112 ]
  %136 = phi i64 [ %101, %95 ], [ 0, %131 ], [ 0, %112 ]
  %137 = icmp ult i64 %2, 64
  br i1 %137, label %172, label %138

138:                                              ; preds = %134
  %139 = add i64 %136, -1
  %140 = icmp eq i64 %136, 0
  br i1 %140, label %141, label %156

141:                                              ; preds = %138
  %142 = load i64, ptr %0, align 8, !tbaa !15
  %143 = add i64 %142, 1
  store i64 %143, ptr %0, align 8, !tbaa !15
  %144 = icmp eq i64 %143, 0
  br i1 %144, label %145, label %156

145:                                              ; preds = %141
  %146 = tail call i64 @llvm.smax.i64(i64 %3, i64 1)
  br label %147

147:                                              ; preds = %150, %145
  %148 = phi i64 [ %154, %150 ], [ 1, %145 ]
  %149 = icmp eq i64 %148, %146
  br i1 %149, label %156, label %150

150:                                              ; preds = %147
  %151 = getelementptr inbounds i64, ptr %0, i64 %148
  %152 = load i64, ptr %151, align 8, !tbaa !15
  %153 = add i64 %152, 1
  store i64 %153, ptr %151, align 8, !tbaa !15
  %154 = add nuw i64 %148, 1
  %155 = icmp eq i64 %153, 0
  br i1 %155, label %147, label %156, !llvm.loop !170

156:                                              ; preds = %150, %147, %141, %138
  %157 = phi i64 [ %139, %138 ], [ 0, %141 ], [ 1, %147 ], [ 0, %150 ]
  %158 = load i64, ptr %0, align 8, !tbaa !15
  %159 = sub i64 %158, %157
  store i64 %159, ptr %0, align 8, !tbaa !15
  %160 = icmp ult i64 %158, %157
  br i1 %160, label %161, label %172

161:                                              ; preds = %156
  %162 = tail call i64 @llvm.smax.i64(i64 %7, i64 1)
  br label %163

163:                                              ; preds = %166, %161
  %164 = phi i64 [ %170, %166 ], [ 1, %161 ]
  %165 = icmp eq i64 %164, %162
  br i1 %165, label %172, label %166

166:                                              ; preds = %163
  %167 = getelementptr inbounds i64, ptr %0, i64 %164
  %168 = load i64, ptr %167, align 8, !tbaa !15
  %169 = add i64 %168, -1
  store i64 %169, ptr %167, align 8, !tbaa !15
  %170 = add nuw nsw i64 %164, 1
  %171 = icmp eq i64 %168, 0
  br i1 %171, label %163, label %172, !llvm.loop !176

172:                                              ; preds = %166, %163, %156, %134
  %173 = phi i64 [ %136, %134 ], [ 1, %156 ], [ 2, %163 ], [ 1, %166 ]
  %174 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 2, ptr %174, align 8, !tbaa !15
  %175 = getelementptr inbounds i64, ptr %0, i64 %7
  %176 = load i64, ptr %175, align 8, !tbaa !15
  %177 = sub i64 %176, %173
  store i64 %177, ptr %175, align 8, !tbaa !15
  %178 = icmp ult i64 %176, %173
  br i1 %178, label %179, label %185

179:                                              ; preds = %179, %172
  %180 = phi ptr [ %181, %179 ], [ %175, %172 ]
  %181 = getelementptr inbounds i8, ptr %180, i64 8
  %182 = load i64, ptr %181, align 8, !tbaa !15
  %183 = add i64 %182, -1
  store i64 %183, ptr %181, align 8, !tbaa !15
  %184 = icmp eq i64 %182, 0
  br i1 %184, label %179, label %185, !llvm.loop !200

185:                                              ; preds = %179, %172
  %186 = load i64, ptr %175, align 8, !tbaa !15
  %187 = sub i64 %186, %135
  store i64 %187, ptr %175, align 8, !tbaa !15
  %188 = icmp ult i64 %186, %135
  br i1 %188, label %189, label %195

189:                                              ; preds = %189, %185
  %190 = phi ptr [ %191, %189 ], [ %175, %185 ]
  %191 = getelementptr inbounds i8, ptr %190, i64 8
  %192 = load i64, ptr %191, align 8, !tbaa !15
  %193 = add i64 %192, -1
  store i64 %193, ptr %191, align 8, !tbaa !15
  %194 = icmp eq i64 %192, 0
  br i1 %194, label %189, label %195, !llvm.loop !201

195:                                              ; preds = %189, %185
  %196 = load i64, ptr %174, align 8, !tbaa !15
  %197 = add i64 %196, -2
  store i64 %197, ptr %174, align 8, !tbaa !15
  %198 = icmp eq i64 %197, 0
  br i1 %198, label %210, label %199, !prof !68

199:                                              ; preds = %195
  store i64 0, ptr %174, align 8, !tbaa !15
  %200 = sub i64 2, %196
  %201 = load i64, ptr %0, align 8, !tbaa !15
  %202 = add i64 %201, %200
  store i64 %202, ptr %0, align 8, !tbaa !15
  %203 = icmp ult i64 %202, %200
  br i1 %203, label %204, label %210

204:                                              ; preds = %204, %199
  %205 = phi ptr [ %206, %204 ], [ %0, %199 ]
  %206 = getelementptr inbounds i8, ptr %205, i64 8
  %207 = load i64, ptr %206, align 8, !tbaa !15
  %208 = add i64 %207, 1
  store i64 %208, ptr %206, align 8, !tbaa !15
  %209 = icmp eq i64 %208, 0
  br i1 %209, label %204, label %210, !llvm.loop !202

210:                                              ; preds = %204, %199, %195, %83, %73
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_lshiftc(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #6 {
  %5 = getelementptr inbounds i64, ptr %1, i64 %2
  %6 = getelementptr inbounds i64, ptr %0, i64 %2
  %7 = sub i32 64, %3
  %8 = getelementptr inbounds i8, ptr %5, i64 -8
  %9 = load i64, ptr %8, align 8, !tbaa !15
  %10 = zext i32 %7 to i64
  %11 = zext nneg i32 %3 to i64
  %12 = add nsw i64 %2, -1
  %13 = shl i64 %9, %11
  %14 = icmp eq i64 %12, 0
  br i1 %14, label %29, label %15

15:                                               ; preds = %15, %4
  %16 = phi i64 [ %27, %15 ], [ %13, %4 ]
  %17 = phi i64 [ %26, %15 ], [ %12, %4 ]
  %18 = phi ptr [ %25, %15 ], [ %6, %4 ]
  %19 = phi ptr [ %20, %15 ], [ %8, %4 ]
  %20 = getelementptr inbounds i8, ptr %19, i64 -8
  %21 = load i64, ptr %20, align 8, !tbaa !15
  %22 = lshr i64 %21, %10
  %23 = or i64 %22, %16
  %24 = xor i64 %23, -1
  %25 = getelementptr inbounds i8, ptr %18, i64 -8
  store i64 %24, ptr %25, align 8, !tbaa !15
  %26 = add nsw i64 %17, -1
  %27 = shl i64 %21, %11
  %28 = icmp eq i64 %26, 0
  br i1 %28, label %29, label %15, !llvm.loop !203

29:                                               ; preds = %15, %4
  %30 = phi ptr [ %6, %4 ], [ %25, %15 ]
  %31 = phi i64 [ %13, %4 ], [ %27, %15 ]
  %32 = lshr i64 %9, %10
  %33 = xor i64 %31, -1
  %34 = getelementptr inbounds i8, ptr %30, i64 -8
  store i64 %33, ptr %34, align 8, !tbaa !15
  ret i64 %32
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.usub.sat.i64(i64, i64) #10

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #5 {
  %4 = alloca [100 x i64], align 16
  %5 = icmp eq i64 %2, 1
  br i1 %5, label %6, label %25

6:                                                ; preds = %3
  %7 = load i64, ptr %1, align 8, !tbaa !15
  %8 = lshr i64 %7, 32
  %9 = and i64 %7, 4294967295
  %10 = mul nuw i64 %9, %9
  %11 = mul nuw i64 %9, %8
  %12 = mul nuw i64 %8, %8
  %13 = lshr i64 %10, 32
  %14 = shl i64 %11, 1
  %15 = add i64 %13, %14
  %16 = icmp ult i64 %15, %11
  %17 = add nuw i64 %12, 4294967296
  %18 = select i1 %16, i64 %17, i64 %12
  %19 = lshr i64 %15, 32
  %20 = add i64 %18, %19
  %21 = getelementptr inbounds i8, ptr %0, i64 8
  store i64 %20, ptr %21, align 8, !tbaa !15
  %22 = shl i64 %15, 32
  %23 = and i64 %10, 4294967295
  %24 = or disjoint i64 %22, %23
  store i64 %24, ptr %0, align 8, !tbaa !15
  br label %86

25:                                               ; preds = %3
  call void @llvm.lifetime.start.p0(i64 800, ptr nonnull %4) #16
  %26 = getelementptr inbounds i8, ptr %1, i64 8
  %27 = add nsw i64 %2, -1
  %28 = load i64, ptr %1, align 8, !tbaa !15
  %29 = call i64 @__gmpn_mul_1(ptr noundef nonnull %4, ptr noundef nonnull %26, i64 noundef %27, i64 noundef %28) #16
  %30 = getelementptr inbounds i64, ptr %4, i64 %27
  store i64 %29, ptr %30, align 8, !tbaa !15
  %31 = getelementptr i8, ptr %4, i64 -16
  %32 = getelementptr i64, ptr %4, i64 %2
  %33 = getelementptr i8, ptr %32, i64 -16
  %34 = icmp sgt i64 %2, 2
  br i1 %34, label %37, label %35

35:                                               ; preds = %37, %25
  %36 = icmp sgt i64 %2, 0
  br i1 %36, label %49, label %75

37:                                               ; preds = %37, %25
  %38 = phi i64 [ %47, %37 ], [ 2, %25 ]
  %39 = shl nsw i64 %38, 4
  %40 = getelementptr i8, ptr %31, i64 %39
  %41 = getelementptr inbounds i64, ptr %1, i64 %38
  %42 = sub nsw i64 %2, %38
  %43 = getelementptr i8, ptr %41, i64 -8
  %44 = load i64, ptr %43, align 8, !tbaa !15
  %45 = call i64 @__gmpn_addmul_1(ptr noundef nonnull %40, ptr noundef nonnull %41, i64 noundef %42, i64 noundef %44) #16
  %46 = getelementptr i64, ptr %33, i64 %38
  store i64 %45, ptr %46, align 8, !tbaa !15
  %47 = add nuw nsw i64 %38, 1
  %48 = icmp eq i64 %47, %2
  br i1 %48, label %35, label %37, !llvm.loop !204

49:                                               ; preds = %49, %35
  %50 = phi i64 [ %73, %49 ], [ 0, %35 ]
  %51 = getelementptr inbounds i64, ptr %1, i64 %50
  %52 = load i64, ptr %51, align 8, !tbaa !15
  %53 = lshr i64 %52, 32
  %54 = and i64 %52, 4294967295
  %55 = mul nuw i64 %54, %54
  %56 = mul nuw i64 %54, %53
  %57 = mul nuw i64 %53, %53
  %58 = lshr i64 %55, 32
  %59 = shl i64 %56, 1
  %60 = add i64 %58, %59
  %61 = icmp ult i64 %60, %56
  %62 = add nuw i64 %57, 4294967296
  %63 = select i1 %61, i64 %62, i64 %57
  %64 = lshr i64 %60, 32
  %65 = add i64 %63, %64
  %66 = shl nuw nsw i64 %50, 1
  %67 = or disjoint i64 %66, 1
  %68 = getelementptr inbounds i64, ptr %0, i64 %67
  store i64 %65, ptr %68, align 8, !tbaa !15
  %69 = shl i64 %60, 32
  %70 = and i64 %55, 4294967295
  %71 = or disjoint i64 %69, %70
  %72 = getelementptr inbounds i64, ptr %0, i64 %66
  store i64 %71, ptr %72, align 8, !tbaa !15
  %73 = add nuw nsw i64 %50, 1
  %74 = icmp eq i64 %73, %2
  br i1 %74, label %75, label %49, !llvm.loop !205

75:                                               ; preds = %49, %35
  %76 = shl nsw i64 %2, 1
  %77 = add nsw i64 %76, -2
  %78 = call i64 @__gmpn_lshift(ptr noundef nonnull %4, ptr noundef nonnull %4, i64 noundef %77, i32 noundef 1) #16
  %79 = getelementptr inbounds i8, ptr %0, i64 8
  %80 = call i64 @__gmpn_add_n(ptr noundef nonnull %79, ptr noundef nonnull %79, ptr noundef nonnull %4, i64 noundef %77) #16
  %81 = add i64 %80, %78
  %82 = getelementptr i64, ptr %0, i64 %76
  %83 = getelementptr i8, ptr %82, i64 -8
  %84 = load i64, ptr %83, align 8, !tbaa !15
  %85 = add i64 %81, %84
  store i64 %85, ptr %83, align 8, !tbaa !15
  call void @llvm.lifetime.end.p0(i64 800, ptr nonnull %4) #16
  br label %86

86:                                               ; preds = %75, %6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #5 {
  %5 = ashr i64 %2, 1
  %6 = sub nsw i64 %2, %5
  %7 = and i64 %2, 1
  %8 = icmp eq i64 %7, 0
  br i1 %8, label %9, label %27

9:                                                ; preds = %4
  %10 = getelementptr inbounds i64, ptr %1, i64 %6
  br label %11

11:                                               ; preds = %14, %9
  %12 = phi i64 [ %6, %9 ], [ %15, %14 ]
  %13 = icmp sgt i64 %12, 0
  br i1 %13, label %14, label %25

14:                                               ; preds = %11
  %15 = add nsw i64 %12, -1
  %16 = getelementptr inbounds i64, ptr %1, i64 %15
  %17 = load i64, ptr %16, align 8, !tbaa !15
  %18 = getelementptr inbounds i64, ptr %10, i64 %15
  %19 = load i64, ptr %18, align 8, !tbaa !15
  %20 = icmp eq i64 %17, %19
  br i1 %20, label %11, label %21, !llvm.loop !206

21:                                               ; preds = %14
  %22 = icmp ugt i64 %17, %19
  br i1 %22, label %25, label %23

23:                                               ; preds = %21
  %24 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %10, ptr noundef %1, i64 noundef %6) #16
  br label %53

25:                                               ; preds = %21, %11
  %26 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %10, i64 noundef %6) #16
  br label %53

27:                                               ; preds = %4
  %28 = getelementptr inbounds i64, ptr %1, i64 %5
  %29 = load i64, ptr %28, align 8, !tbaa !15
  %30 = icmp eq i64 %29, 0
  br i1 %30, label %31, label %48

31:                                               ; preds = %27
  %32 = getelementptr inbounds i64, ptr %1, i64 %6
  br label %33

33:                                               ; preds = %36, %31
  %34 = phi i64 [ %5, %31 ], [ %37, %36 ]
  %35 = icmp sgt i64 %34, 0
  br i1 %35, label %36, label %48

36:                                               ; preds = %33
  %37 = add nsw i64 %34, -1
  %38 = getelementptr inbounds i64, ptr %1, i64 %37
  %39 = load i64, ptr %38, align 8, !tbaa !15
  %40 = getelementptr inbounds i64, ptr %32, i64 %37
  %41 = load i64, ptr %40, align 8, !tbaa !15
  %42 = icmp eq i64 %39, %41
  br i1 %42, label %33, label %43, !llvm.loop !206

43:                                               ; preds = %36
  %44 = icmp ugt i64 %39, %41
  br i1 %44, label %48, label %45

45:                                               ; preds = %43
  %46 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %32, ptr noundef %1, i64 noundef %5) #16
  %47 = getelementptr inbounds i64, ptr %0, i64 %5
  store i64 0, ptr %47, align 8, !tbaa !15
  br label %53

48:                                               ; preds = %43, %33, %27
  %49 = getelementptr inbounds i64, ptr %1, i64 %6
  %50 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %49, i64 noundef %5) #16
  %51 = sub i64 %29, %50
  %52 = getelementptr inbounds i64, ptr %0, i64 %5
  store i64 %51, ptr %52, align 8, !tbaa !15
  br label %53

53:                                               ; preds = %48, %45, %25, %23
  %54 = icmp sgt i64 %6, 49
  br i1 %54, label %56, label %55

55:                                               ; preds = %53
  tail call void @__gmpn_sqr_basecase(ptr noundef %3, ptr noundef %0, i64 noundef %6) #16
  br label %59

56:                                               ; preds = %53
  %57 = shl nsw i64 %6, 4
  %58 = getelementptr inbounds i8, ptr %3, i64 %57
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef %0, i64 noundef %6, ptr noundef nonnull %58)
  br label %59

59:                                               ; preds = %56, %55
  %60 = icmp sgt i64 %5, 49
  %61 = getelementptr inbounds i64, ptr %1, i64 %6
  br i1 %60, label %65, label %62

62:                                               ; preds = %59
  %63 = shl nsw i64 %6, 4
  %64 = getelementptr inbounds i8, ptr %0, i64 %63
  tail call void @__gmpn_sqr_basecase(ptr noundef %64, ptr noundef %61, i64 noundef %5) #16
  br label %69

65:                                               ; preds = %59
  %66 = shl nsw i64 %6, 1
  %67 = getelementptr inbounds i64, ptr %0, i64 %66
  %68 = getelementptr inbounds i64, ptr %3, i64 %66
  tail call void @__gmpn_toom2_sqr(ptr noundef %67, ptr noundef %61, i64 noundef %5, ptr noundef %68)
  br label %69

69:                                               ; preds = %65, %62
  br i1 %54, label %71, label %70

70:                                               ; preds = %69
  tail call void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %6) #16
  br label %74

71:                                               ; preds = %69
  %72 = shl nsw i64 %6, 4
  %73 = getelementptr inbounds i8, ptr %3, i64 %72
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %6, ptr noundef nonnull %73)
  br label %74

74:                                               ; preds = %71, %70
  %75 = shl nsw i64 %6, 1
  %76 = getelementptr inbounds i64, ptr %0, i64 %75
  %77 = getelementptr inbounds i64, ptr %0, i64 %6
  %78 = tail call i64 @__gmpn_add_n(ptr noundef %76, ptr noundef %77, ptr noundef %76, i64 noundef %6) #16
  %79 = tail call i64 @__gmpn_add_n(ptr noundef %77, ptr noundef %76, ptr noundef %0, i64 noundef %6) #16
  %80 = add i64 %79, %78
  %81 = and i64 %2, -2
  %82 = sub nsw i64 %81, %6
  %83 = icmp eq i64 %82, 0
  br i1 %83, label %97, label %84

84:                                               ; preds = %74
  %85 = getelementptr inbounds i64, ptr %76, i64 %6
  %86 = tail call i64 @__gmpn_add_n(ptr noundef %76, ptr noundef %76, ptr noundef %85, i64 noundef %82) #16
  %87 = icmp eq i64 %86, 0
  br i1 %87, label %97, label %88

88:                                               ; preds = %91, %84
  %89 = phi i64 [ %95, %91 ], [ %82, %84 ]
  %90 = icmp slt i64 %89, %6
  br i1 %90, label %91, label %97

91:                                               ; preds = %88
  %92 = getelementptr inbounds i64, ptr %76, i64 %89
  %93 = load i64, ptr %92, align 8, !tbaa !15
  %94 = add i64 %93, 1
  %95 = add nsw i64 %89, 1
  store i64 %94, ptr %92, align 8, !tbaa !15
  %96 = icmp eq i64 %94, 0
  br i1 %96, label %88, label %97, !llvm.loop !207

97:                                               ; preds = %91, %88, %84, %74
  %98 = phi i64 [ 0, %84 ], [ 0, %74 ], [ 1, %88 ], [ 0, %91 ]
  %99 = add i64 %98, %78
  %100 = tail call i64 @__gmpn_sub_n(ptr noundef %77, ptr noundef %77, ptr noundef %3, i64 noundef %75) #16
  %101 = sub i64 %99, %100
  %102 = icmp ult i64 %101, 3
  br i1 %102, label %106, label %103, !prof !68

103:                                              ; preds = %97
  %104 = sub i64 %2, %5
  %105 = shl i64 %104, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %76, i8 0, i64 %105, i1 false), !tbaa !15
  br label %128

106:                                              ; preds = %97
  %107 = load i64, ptr %76, align 8, !tbaa !15
  %108 = add i64 %107, %80
  store i64 %108, ptr %76, align 8, !tbaa !15
  %109 = icmp ult i64 %108, %80
  br i1 %109, label %110, label %116

110:                                              ; preds = %110, %106
  %111 = phi ptr [ %112, %110 ], [ %76, %106 ]
  %112 = getelementptr inbounds i8, ptr %111, i64 8
  %113 = load i64, ptr %112, align 8, !tbaa !15
  %114 = add i64 %113, 1
  store i64 %114, ptr %112, align 8, !tbaa !15
  %115 = icmp eq i64 %114, 0
  br i1 %115, label %110, label %116, !llvm.loop !208

116:                                              ; preds = %110, %106
  %117 = mul i64 %6, 24
  %118 = getelementptr inbounds i8, ptr %0, i64 %117
  %119 = load i64, ptr %118, align 8, !tbaa !15
  %120 = add i64 %119, %101
  store i64 %120, ptr %118, align 8, !tbaa !15
  %121 = icmp ult i64 %120, %101
  br i1 %121, label %122, label %128

122:                                              ; preds = %122, %116
  %123 = phi ptr [ %124, %122 ], [ %118, %116 ]
  %124 = getelementptr inbounds i8, ptr %123, i64 8
  %125 = load i64, ptr %124, align 8, !tbaa !15
  %126 = add i64 %125, 1
  store i64 %126, ptr %124, align 8, !tbaa !15
  %127 = icmp eq i64 %126, 0
  br i1 %127, label %122, label %128, !llvm.loop !209

128:                                              ; preds = %122, %116, %103
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #5 {
  %5 = add nsw i64 %2, 2
  %6 = udiv i64 %5, 3
  %7 = shl nuw nsw i64 %6, 1
  %8 = sub nsw i64 %2, %7
  %9 = shl nsw i64 %6, 2
  %10 = getelementptr inbounds i64, ptr %3, i64 %9
  %11 = getelementptr inbounds i8, ptr %10, i64 32
  %12 = getelementptr inbounds i64, ptr %3, i64 %7
  %13 = getelementptr inbounds i8, ptr %12, i64 16
  %14 = getelementptr inbounds i64, ptr %0, i64 %6
  %15 = getelementptr inbounds i8, ptr %14, i64 8
  %16 = getelementptr inbounds i64, ptr %1, i64 %7
  %17 = icmp eq i64 %8, 0
  br i1 %17, label %31, label %18

18:                                               ; preds = %4
  %19 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %1, ptr noundef %16, i64 noundef %8) #16
  %20 = icmp eq i64 %19, 0
  br i1 %20, label %31, label %21

21:                                               ; preds = %24, %18
  %22 = phi i64 [ %28, %24 ], [ %8, %18 ]
  %23 = icmp slt i64 %22, %6
  br i1 %23, label %24, label %43

24:                                               ; preds = %21
  %25 = getelementptr inbounds i64, ptr %1, i64 %22
  %26 = load i64, ptr %25, align 8, !tbaa !15
  %27 = add i64 %26, 1
  %28 = add nsw i64 %22, 1
  %29 = getelementptr inbounds i64, ptr %3, i64 %22
  store i64 %27, ptr %29, align 8, !tbaa !15
  %30 = icmp eq i64 %27, 0
  br i1 %30, label %21, label %31, !llvm.loop !210

31:                                               ; preds = %24, %18, %4
  %32 = phi i64 [ %8, %18 ], [ 0, %4 ], [ %28, %24 ]
  %33 = icmp ne ptr %3, %1
  %34 = icmp slt i64 %32, %6
  %35 = select i1 %33, i1 %34, i1 false
  br i1 %35, label %36, label %43

36:                                               ; preds = %36, %31
  %37 = phi i64 [ %41, %36 ], [ %32, %31 ]
  %38 = getelementptr inbounds i64, ptr %1, i64 %37
  %39 = load i64, ptr %38, align 8, !tbaa !15
  %40 = getelementptr inbounds i64, ptr %3, i64 %37
  store i64 %39, ptr %40, align 8, !tbaa !15
  %41 = add nsw i64 %37, 1
  %42 = icmp eq i64 %41, %6
  br i1 %42, label %43, label %36, !llvm.loop !211

43:                                               ; preds = %36, %31, %21
  %44 = phi i1 [ true, %31 ], [ true, %36 ], [ false, %21 ]
  %45 = phi i64 [ 0, %31 ], [ 0, %36 ], [ 1, %21 ]
  %46 = getelementptr inbounds i64, ptr %1, i64 %6
  %47 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %11, ptr noundef %3, ptr noundef %46, i64 noundef %6) #16
  %48 = add i64 %47, %45
  %49 = getelementptr inbounds i64, ptr %11, i64 %6
  store i64 %48, ptr %49, align 8, !tbaa !15
  br i1 %44, label %50, label %68

50:                                               ; preds = %53, %43
  %51 = phi i64 [ %54, %53 ], [ %6, %43 ]
  %52 = icmp sgt i64 %51, 0
  br i1 %52, label %53, label %63

53:                                               ; preds = %50
  %54 = add nsw i64 %51, -1
  %55 = getelementptr inbounds i64, ptr %3, i64 %54
  %56 = load i64, ptr %55, align 8, !tbaa !15
  %57 = getelementptr inbounds i64, ptr %46, i64 %54
  %58 = load i64, ptr %57, align 8, !tbaa !15
  %59 = icmp eq i64 %56, %58
  br i1 %59, label %50, label %60, !llvm.loop !212

60:                                               ; preds = %53
  %61 = icmp ugt i64 %56, %58
  %62 = select i1 %61, i32 1, i32 -1
  br label %63

63:                                               ; preds = %60, %50
  %64 = phi i32 [ %62, %60 ], [ 0, %50 ]
  %65 = icmp slt i32 %64, 0
  br i1 %65, label %66, label %68

66:                                               ; preds = %63
  %67 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %13, ptr noundef %46, ptr noundef %3, i64 noundef %6) #16
  br label %71

68:                                               ; preds = %63, %43
  %69 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %13, ptr noundef %3, ptr noundef %46, i64 noundef %6) #16
  %70 = sub i64 %45, %69
  br label %71

71:                                               ; preds = %68, %66
  %72 = phi i64 [ %70, %68 ], [ 0, %66 ]
  %73 = getelementptr inbounds i64, ptr %13, i64 %6
  store i64 %72, ptr %73, align 8, !tbaa !15
  %74 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %15, ptr noundef %16, ptr noundef nonnull %11, i64 noundef %8) #16
  %75 = icmp eq i64 %8, %6
  br i1 %75, label %117, label %76

76:                                               ; preds = %71
  %77 = getelementptr inbounds i64, ptr %15, i64 %8
  %78 = getelementptr inbounds i64, ptr %11, i64 %8
  %79 = sub nsw i64 %6, %8
  %80 = load i64, ptr %78, align 8, !tbaa !15
  %81 = add i64 %80, %74
  store i64 %81, ptr %77, align 8, !tbaa !15
  %82 = icmp ult i64 %81, %74
  br i1 %82, label %83, label %106

83:                                               ; preds = %76
  %84 = tail call i64 @llvm.smax.i64(i64 %79, i64 1)
  br label %85

85:                                               ; preds = %88, %83
  %86 = phi i64 [ %93, %88 ], [ 1, %83 ]
  %87 = icmp eq i64 %86, %84
  br i1 %87, label %117, label %88

88:                                               ; preds = %85
  %89 = getelementptr inbounds i64, ptr %78, i64 %86
  %90 = load i64, ptr %89, align 8, !tbaa !15
  %91 = add i64 %90, 1
  %92 = getelementptr inbounds i64, ptr %77, i64 %86
  store i64 %91, ptr %92, align 8, !tbaa !15
  %93 = add nuw i64 %86, 1
  %94 = icmp eq i64 %91, 0
  br i1 %94, label %85, label %95, !llvm.loop !213

95:                                               ; preds = %88
  %96 = icmp ne ptr %11, %15
  %97 = icmp slt i64 %93, %79
  %98 = select i1 %96, i1 %97, i1 false
  br i1 %98, label %99, label %117

99:                                               ; preds = %99, %95
  %100 = phi i64 [ %104, %99 ], [ %93, %95 ]
  %101 = getelementptr inbounds i64, ptr %78, i64 %100
  %102 = load i64, ptr %101, align 8, !tbaa !15
  %103 = getelementptr inbounds i64, ptr %77, i64 %100
  store i64 %102, ptr %103, align 8, !tbaa !15
  %104 = add nuw nsw i64 %100, 1
  %105 = icmp slt i64 %104, %79
  br i1 %105, label %99, label %117, !llvm.loop !214

106:                                              ; preds = %76
  %107 = icmp ne ptr %11, %15
  %108 = icmp sgt i64 %79, 1
  %109 = and i1 %107, %108
  br i1 %109, label %110, label %117

110:                                              ; preds = %110, %106
  %111 = phi i64 [ %115, %110 ], [ 1, %106 ]
  %112 = getelementptr inbounds i64, ptr %78, i64 %111
  %113 = load i64, ptr %112, align 8, !tbaa !15
  %114 = getelementptr inbounds i64, ptr %77, i64 %111
  store i64 %113, ptr %114, align 8, !tbaa !15
  %115 = add nuw nsw i64 %111, 1
  %116 = icmp eq i64 %115, %79
  br i1 %116, label %117, label %110, !llvm.loop !215

117:                                              ; preds = %110, %106, %99, %95, %85, %71
  %118 = phi i64 [ %74, %71 ], [ 0, %95 ], [ 0, %106 ], [ 0, %99 ], [ 1, %85 ], [ 0, %110 ]
  %119 = load i64, ptr %49, align 8, !tbaa !15
  %120 = add i64 %119, %118
  %121 = shl i64 %120, 1
  %122 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %15, ptr noundef nonnull %15, i64 noundef %6, i32 noundef 1) #16
  %123 = add i64 %121, %122
  %124 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %15, ptr noundef nonnull %15, ptr noundef %1, i64 noundef %6) #16
  %125 = sub i64 %123, %124
  %126 = getelementptr inbounds i64, ptr %15, i64 %6
  store i64 %125, ptr %126, align 8, !tbaa !15
  store i64 0, ptr %12, align 8, !tbaa !15
  %127 = getelementptr inbounds i64, ptr %13, i64 %6
  %128 = load i64, ptr %127, align 8, !tbaa !15
  %129 = add i64 %128, %6
  %130 = icmp ugt i64 %129, 49
  br i1 %130, label %132, label %131

131:                                              ; preds = %117
  tail call void @__gmpn_sqr_basecase(ptr noundef %3, ptr noundef nonnull %13, i64 noundef %129) #16
  br label %139

132:                                              ; preds = %117
  %133 = icmp ugt i64 %129, 119
  %134 = mul i64 %6, 40
  %135 = getelementptr inbounds i8, ptr %3, i64 %134
  %136 = getelementptr inbounds i8, ptr %135, i64 40
  br i1 %133, label %138, label %137

137:                                              ; preds = %132
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef nonnull %13, i64 noundef %129, ptr noundef nonnull %136) #16
  br label %139

138:                                              ; preds = %132
  tail call void @__gmpn_toom3_sqr(ptr noundef %3, ptr noundef nonnull %13, i64 noundef %129, ptr noundef nonnull %136)
  br label %139

139:                                              ; preds = %138, %137, %131
  %140 = add nuw nsw i64 %6, 1
  %141 = icmp ugt i64 %5, 146
  br i1 %141, label %144, label %142

142:                                              ; preds = %139
  %143 = getelementptr inbounds i8, ptr %12, i64 8
  tail call void @__gmpn_sqr_basecase(ptr noundef nonnull %143, ptr noundef nonnull %15, i64 noundef %140) #16
  br label %152

144:                                              ; preds = %139
  %145 = icmp ugt i64 %5, 356
  %146 = getelementptr inbounds i8, ptr %12, i64 8
  %147 = mul i64 %6, 40
  %148 = getelementptr inbounds i8, ptr %3, i64 %147
  %149 = getelementptr inbounds i8, ptr %148, i64 40
  br i1 %145, label %151, label %150

150:                                              ; preds = %144
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %146, ptr noundef nonnull %15, i64 noundef %140, ptr noundef nonnull %149) #16
  br label %152

151:                                              ; preds = %144
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %146, ptr noundef nonnull %15, i64 noundef %140, ptr noundef nonnull %149)
  br label %152

152:                                              ; preds = %151, %150, %142
  %153 = icmp sgt i64 %8, 49
  br i1 %153, label %156, label %154

154:                                              ; preds = %152
  %155 = getelementptr inbounds i64, ptr %0, i64 %9
  tail call void @__gmpn_sqr_basecase(ptr noundef %155, ptr noundef %16, i64 noundef %8) #16
  br label %164

156:                                              ; preds = %152
  %157 = icmp sgt i64 %8, 119
  %158 = getelementptr inbounds i64, ptr %0, i64 %9
  %159 = mul i64 %6, 40
  %160 = getelementptr inbounds i8, ptr %3, i64 %159
  %161 = getelementptr inbounds i8, ptr %160, i64 40
  br i1 %157, label %163, label %162

162:                                              ; preds = %156
  tail call void @__gmpn_toom2_sqr(ptr noundef %158, ptr noundef %16, i64 noundef %8, ptr noundef nonnull %161) #16
  br label %164

163:                                              ; preds = %156
  tail call void @__gmpn_toom3_sqr(ptr noundef %158, ptr noundef %16, i64 noundef %8, ptr noundef nonnull %161)
  br label %164

164:                                              ; preds = %163, %162, %154
  %165 = getelementptr inbounds i64, ptr %0, i64 %9
  %166 = load i64, ptr %165, align 8, !tbaa !15
  %167 = getelementptr inbounds i8, ptr %165, i64 8
  %168 = load i64, ptr %167, align 8, !tbaa !15
  br i1 %141, label %171, label %169

169:                                              ; preds = %164
  %170 = getelementptr inbounds i64, ptr %0, i64 %7
  tail call void @__gmpn_sqr_basecase(ptr noundef %170, ptr noundef nonnull %11, i64 noundef %140) #16
  br label %179

171:                                              ; preds = %164
  %172 = icmp ugt i64 %5, 356
  %173 = getelementptr inbounds i64, ptr %0, i64 %7
  %174 = mul i64 %6, 40
  %175 = getelementptr inbounds i8, ptr %3, i64 %174
  %176 = getelementptr inbounds i8, ptr %175, i64 40
  br i1 %172, label %178, label %177

177:                                              ; preds = %171
  tail call void @__gmpn_toom2_sqr(ptr noundef %173, ptr noundef nonnull %11, i64 noundef %140, ptr noundef nonnull %176) #16
  br label %179

178:                                              ; preds = %171
  tail call void @__gmpn_toom3_sqr(ptr noundef %173, ptr noundef nonnull %11, i64 noundef %140, ptr noundef nonnull %176)
  br label %179

179:                                              ; preds = %178, %177, %169
  store i64 %168, ptr %167, align 8, !tbaa !15
  %180 = icmp ugt i64 %5, 149
  br i1 %180, label %182, label %181

181:                                              ; preds = %179
  tail call void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %6) #16
  br label %189

182:                                              ; preds = %179
  %183 = icmp ugt i64 %5, 359
  %184 = mul i64 %6, 40
  %185 = getelementptr inbounds i8, ptr %3, i64 %184
  %186 = getelementptr inbounds i8, ptr %185, i64 40
  br i1 %183, label %188, label %187

187:                                              ; preds = %182
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %6, ptr noundef nonnull %186) #16
  br label %189

188:                                              ; preds = %182
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %6, ptr noundef nonnull %186)
  br label %189

189:                                              ; preds = %188, %187, %181
  %190 = getelementptr inbounds i8, ptr %12, i64 8
  %191 = shl nsw i64 %8, 1
  tail call void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef nonnull %190, ptr noundef %3, i64 noundef %6, i64 noundef %191, i32 noundef 0, i64 noundef %166) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #5 {
  %5 = add nsw i64 %2, -1
  %6 = udiv i64 %5, 6
  %7 = add nuw nsw i64 %6, 1
  %8 = mul i64 %7, -5
  %9 = add i64 %8, %2
  %10 = mul nuw nsw i64 %7, 9
  %11 = getelementptr inbounds i64, ptr %0, i64 %10
  %12 = getelementptr inbounds i8, ptr %11, i64 16
  %13 = mul i64 %7, 56
  %14 = getelementptr inbounds i8, ptr %0, i64 %13
  %15 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 1, ptr noundef %0) #16
  %16 = add nuw nsw i64 %6, 2
  %17 = getelementptr inbounds i64, ptr %3, i64 %10
  %18 = getelementptr inbounds i8, ptr %17, i64 24
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #16
  %19 = shl nuw nsw i64 %7, 1
  %20 = or disjoint i64 %19, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef %3, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 0) #16
  %21 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #16
  %22 = mul nuw nsw i64 %7, 3
  %23 = getelementptr inbounds i64, ptr %3, i64 %22
  %24 = getelementptr inbounds i8, ptr %23, i64 8
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %24, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %24, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 0, i32 noundef 0) #16
  %25 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #16
  %26 = mul i64 %7, 48
  %27 = getelementptr inbounds i8, ptr %3, i64 %26
  %28 = getelementptr inbounds i8, ptr %27, i64 16
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %28, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %28, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 4) #16
  %29 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #16
  %30 = getelementptr inbounds i64, ptr %0, i64 %22
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %30, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %30, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 0) #16
  %31 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #16
  tail call void @__gmpn_toom_couple_handling(ptr noundef %14, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 2) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %18) #16
  %32 = shl nsw i64 %9, 1
  tail call void @__gmpn_toom_interpolate_12pts(ptr noundef %0, ptr noundef nonnull %28, ptr noundef nonnull %24, ptr noundef %3, i64 noundef %7, i64 noundef %32, i32 noundef 0, ptr noundef nonnull %18) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #5 {
  %5 = add nsw i64 %2, -1
  %6 = ashr i64 %5, 3
  %7 = add nsw i64 %6, 1
  %8 = mul nsw i64 %7, 7
  %9 = sub nsw i64 %2, %8
  %10 = mul i64 %7, 104
  %11 = getelementptr inbounds i8, ptr %0, i64 %10
  %12 = getelementptr inbounds i8, ptr %11, i64 16
  %13 = mul i64 %7, 88
  %14 = getelementptr inbounds i8, ptr %0, i64 %13
  %15 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 3, ptr noundef %0) #16
  %16 = add nsw i64 %6, 2
  %17 = icmp sgt i64 %6, 117
  br i1 %17, label %22, label %18

18:                                               ; preds = %4
  %19 = mul i64 %7, 96
  %20 = getelementptr inbounds i8, ptr %3, i64 %19
  %21 = getelementptr inbounds i8, ptr %20, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %21) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %21) #16
  br label %35

22:                                               ; preds = %4
  %23 = icmp sgt i64 %6, 397
  br i1 %23, label %28, label %24

24:                                               ; preds = %22
  %25 = mul i64 %7, 96
  %26 = getelementptr inbounds i8, ptr %3, i64 %25
  %27 = getelementptr inbounds i8, ptr %26, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %27) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %27) #16
  br label %35

28:                                               ; preds = %22
  %29 = icmp sgt i64 %6, 447
  %30 = mul i64 %7, 96
  %31 = getelementptr inbounds i8, ptr %3, i64 %30
  %32 = getelementptr inbounds i8, ptr %31, i64 32
  br i1 %29, label %34, label %33

33:                                               ; preds = %28
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %32) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %32) #16
  br label %35

34:                                               ; preds = %28
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %32)
  tail call void @__gmpn_toom8_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %32)
  br label %35

35:                                               ; preds = %34, %33, %24, %18
  %36 = shl nsw i64 %7, 1
  %37 = or disjoint i64 %36, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef %3, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 3, i32 noundef 0) #16
  %38 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #16
  br i1 %17, label %46, label %39

39:                                               ; preds = %35
  %40 = mul i64 %7, 96
  %41 = getelementptr inbounds i8, ptr %3, i64 %40
  %42 = getelementptr inbounds i8, ptr %41, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %42) #16
  %43 = mul i64 %7, 24
  %44 = getelementptr inbounds i8, ptr %3, i64 %43
  %45 = getelementptr inbounds i8, ptr %44, i64 8
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %45, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %42) #16
  br label %62

46:                                               ; preds = %35
  %47 = icmp sgt i64 %6, 397
  %48 = mul i64 %7, 24
  %49 = getelementptr inbounds i8, ptr %3, i64 %48
  %50 = getelementptr inbounds i8, ptr %49, i64 8
  br i1 %47, label %55, label %51

51:                                               ; preds = %46
  %52 = mul i64 %7, 96
  %53 = getelementptr inbounds i8, ptr %3, i64 %52
  %54 = getelementptr inbounds i8, ptr %53, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %54) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %50, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %54) #16
  br label %62

55:                                               ; preds = %46
  %56 = icmp sgt i64 %6, 447
  %57 = mul i64 %7, 96
  %58 = getelementptr inbounds i8, ptr %3, i64 %57
  %59 = getelementptr inbounds i8, ptr %58, i64 32
  br i1 %56, label %61, label %60

60:                                               ; preds = %55
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %59) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %50, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %59) #16
  br label %62

61:                                               ; preds = %55
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %59)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %50, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %59)
  br label %62

62:                                               ; preds = %61, %60, %51, %39
  %63 = mul nsw i64 %7, 3
  %64 = getelementptr inbounds i64, ptr %3, i64 %63
  %65 = getelementptr inbounds i8, ptr %64, i64 8
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %65, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 0) #16
  %66 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #16
  br i1 %17, label %74, label %67

67:                                               ; preds = %62
  %68 = mul i64 %7, 96
  %69 = getelementptr inbounds i8, ptr %3, i64 %68
  %70 = getelementptr inbounds i8, ptr %69, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %70) #16
  %71 = mul i64 %7, 48
  %72 = getelementptr inbounds i8, ptr %3, i64 %71
  %73 = getelementptr inbounds i8, ptr %72, i64 16
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %73, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %70) #16
  br label %90

74:                                               ; preds = %62
  %75 = icmp sgt i64 %6, 397
  %76 = mul i64 %7, 48
  %77 = getelementptr inbounds i8, ptr %3, i64 %76
  %78 = getelementptr inbounds i8, ptr %77, i64 16
  br i1 %75, label %83, label %79

79:                                               ; preds = %74
  %80 = mul i64 %7, 96
  %81 = getelementptr inbounds i8, ptr %3, i64 %80
  %82 = getelementptr inbounds i8, ptr %81, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %82) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %78, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %82) #16
  br label %90

83:                                               ; preds = %74
  %84 = icmp sgt i64 %6, 447
  %85 = mul i64 %7, 96
  %86 = getelementptr inbounds i8, ptr %3, i64 %85
  %87 = getelementptr inbounds i8, ptr %86, i64 32
  br i1 %84, label %89, label %88

88:                                               ; preds = %83
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %87) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %78, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %87) #16
  br label %90

89:                                               ; preds = %83
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %87)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %78, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %87)
  br label %90

90:                                               ; preds = %89, %88, %79, %67
  %91 = mul i64 %7, 48
  %92 = getelementptr inbounds i8, ptr %3, i64 %91
  %93 = getelementptr inbounds i8, ptr %92, i64 16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %93, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 2) #16
  %94 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 3, ptr noundef %0) #16
  br i1 %17, label %102, label %95

95:                                               ; preds = %90
  %96 = mul i64 %7, 96
  %97 = getelementptr inbounds i8, ptr %3, i64 %96
  %98 = getelementptr inbounds i8, ptr %97, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %98) #16
  %99 = mul i64 %7, 72
  %100 = getelementptr inbounds i8, ptr %3, i64 %99
  %101 = getelementptr inbounds i8, ptr %100, i64 24
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %101, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %98) #16
  br label %118

102:                                              ; preds = %90
  %103 = icmp sgt i64 %6, 397
  %104 = mul i64 %7, 72
  %105 = getelementptr inbounds i8, ptr %3, i64 %104
  %106 = getelementptr inbounds i8, ptr %105, i64 24
  br i1 %103, label %111, label %107

107:                                              ; preds = %102
  %108 = mul i64 %7, 96
  %109 = getelementptr inbounds i8, ptr %3, i64 %108
  %110 = getelementptr inbounds i8, ptr %109, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %110) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %106, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %110) #16
  br label %118

111:                                              ; preds = %102
  %112 = icmp sgt i64 %6, 447
  %113 = mul i64 %7, 96
  %114 = getelementptr inbounds i8, ptr %3, i64 %113
  %115 = getelementptr inbounds i8, ptr %114, i64 32
  br i1 %112, label %117, label %116

116:                                              ; preds = %111
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %115) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %106, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %115) #16
  br label %118

117:                                              ; preds = %111
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %115)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %106, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %115)
  br label %118

118:                                              ; preds = %117, %116, %107, %95
  %119 = mul i64 %7, 72
  %120 = getelementptr inbounds i8, ptr %3, i64 %119
  %121 = getelementptr inbounds i8, ptr %120, i64 24
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %121, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 3, i32 noundef 6) #16
  %122 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 1, ptr noundef %0) #16
  br i1 %17, label %128, label %123

123:                                              ; preds = %118
  %124 = mul i64 %7, 96
  %125 = getelementptr inbounds i8, ptr %3, i64 %124
  %126 = getelementptr inbounds i8, ptr %125, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %126) #16
  %127 = getelementptr inbounds i64, ptr %0, i64 %63
  tail call void @__gmpn_toom2_sqr(ptr noundef %127, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %126) #16
  br label %142

128:                                              ; preds = %118
  %129 = icmp sgt i64 %6, 397
  %130 = getelementptr inbounds i64, ptr %0, i64 %63
  br i1 %129, label %135, label %131

131:                                              ; preds = %128
  %132 = mul i64 %7, 96
  %133 = getelementptr inbounds i8, ptr %3, i64 %132
  %134 = getelementptr inbounds i8, ptr %133, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %134) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %130, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %134) #16
  br label %142

135:                                              ; preds = %128
  %136 = icmp sgt i64 %6, 447
  %137 = mul i64 %7, 96
  %138 = getelementptr inbounds i8, ptr %3, i64 %137
  %139 = getelementptr inbounds i8, ptr %138, i64 32
  br i1 %136, label %141, label %140

140:                                              ; preds = %135
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %139) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %130, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %139) #16
  br label %142

141:                                              ; preds = %135
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %139)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %130, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %139)
  br label %142

142:                                              ; preds = %141, %140, %131, %123
  %143 = getelementptr inbounds i64, ptr %0, i64 %63
  tail call void @__gmpn_toom_couple_handling(ptr noundef %143, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 0) #16
  %144 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #16
  br i1 %17, label %150, label %145

145:                                              ; preds = %142
  %146 = mul i64 %7, 96
  %147 = getelementptr inbounds i8, ptr %3, i64 %146
  %148 = getelementptr inbounds i8, ptr %147, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %148) #16
  %149 = getelementptr inbounds i64, ptr %0, i64 %8
  tail call void @__gmpn_toom2_sqr(ptr noundef %149, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %148) #16
  br label %164

150:                                              ; preds = %142
  %151 = icmp sgt i64 %6, 397
  %152 = getelementptr inbounds i64, ptr %0, i64 %8
  br i1 %151, label %157, label %153

153:                                              ; preds = %150
  %154 = mul i64 %7, 96
  %155 = getelementptr inbounds i8, ptr %3, i64 %154
  %156 = getelementptr inbounds i8, ptr %155, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %156) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %152, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %156) #16
  br label %164

157:                                              ; preds = %150
  %158 = icmp sgt i64 %6, 447
  %159 = mul i64 %7, 96
  %160 = getelementptr inbounds i8, ptr %3, i64 %159
  %161 = getelementptr inbounds i8, ptr %160, i64 32
  br i1 %158, label %163, label %162

162:                                              ; preds = %157
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %161) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %152, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %161) #16
  br label %164

163:                                              ; preds = %157
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %161)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %152, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %161)
  br label %164

164:                                              ; preds = %163, %162, %153, %145
  %165 = getelementptr inbounds i64, ptr %0, i64 %8
  tail call void @__gmpn_toom_couple_handling(ptr noundef %165, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 0, i32 noundef 0) #16
  %166 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #16
  br i1 %17, label %171, label %167

167:                                              ; preds = %164
  %168 = mul i64 %7, 96
  %169 = getelementptr inbounds i8, ptr %3, i64 %168
  %170 = getelementptr inbounds i8, ptr %169, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %170) #16
  tail call void @__gmpn_toom2_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %170) #16
  br label %184

171:                                              ; preds = %164
  %172 = icmp sgt i64 %6, 397
  br i1 %172, label %177, label %173

173:                                              ; preds = %171
  %174 = mul i64 %7, 96
  %175 = getelementptr inbounds i8, ptr %3, i64 %174
  %176 = getelementptr inbounds i8, ptr %175, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %176) #16
  tail call void @__gmpn_toom3_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %176) #16
  br label %184

177:                                              ; preds = %171
  %178 = icmp sgt i64 %6, 447
  %179 = mul i64 %7, 96
  %180 = getelementptr inbounds i8, ptr %3, i64 %179
  %181 = getelementptr inbounds i8, ptr %180, i64 32
  br i1 %178, label %183, label %182

182:                                              ; preds = %177
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %181) #16
  tail call void @__gmpn_toom6_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %181) #16
  br label %184

183:                                              ; preds = %177
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %181)
  tail call void @__gmpn_toom8_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %181)
  br label %184

184:                                              ; preds = %183, %182, %173, %167
  tail call void @__gmpn_toom_couple_handling(ptr noundef %14, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 4) #16
  %185 = icmp sgt i64 %6, 118
  br i1 %185, label %190, label %186

186:                                              ; preds = %184
  %187 = mul i64 %7, 96
  %188 = getelementptr inbounds i8, ptr %3, i64 %187
  %189 = getelementptr inbounds i8, ptr %188, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %189) #16
  br label %203

190:                                              ; preds = %184
  %191 = icmp sgt i64 %6, 398
  br i1 %191, label %196, label %192

192:                                              ; preds = %190
  %193 = mul i64 %7, 96
  %194 = getelementptr inbounds i8, ptr %3, i64 %193
  %195 = getelementptr inbounds i8, ptr %194, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %195) #16
  br label %203

196:                                              ; preds = %190
  %197 = icmp sgt i64 %6, 448
  %198 = mul i64 %7, 96
  %199 = getelementptr inbounds i8, ptr %3, i64 %198
  %200 = getelementptr inbounds i8, ptr %199, i64 32
  br i1 %197, label %202, label %201

201:                                              ; preds = %196
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %200) #16
  br label %203

202:                                              ; preds = %196
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %200)
  br label %203

203:                                              ; preds = %202, %201, %192, %186
  %204 = shl nsw i64 %9, 1
  %205 = mul i64 %7, 96
  %206 = getelementptr inbounds i8, ptr %3, i64 %205
  %207 = getelementptr inbounds i8, ptr %206, i64 32
  tail call void @__gmpn_toom_interpolate_16pts(ptr noundef %0, ptr noundef nonnull %121, ptr noundef nonnull %93, ptr noundef nonnull %65, ptr noundef %3, i64 noundef %7, i64 noundef %204, i32 noundef 0, ptr noundef nonnull %207) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_pm2rexp(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, i32 noundef %6, ptr noundef %7) local_unnamed_addr #5 {
  %9 = mul i32 %6, %2
  %10 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %3, i64 noundef %4, i32 noundef %9) #16
  %11 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %10, ptr %11, align 8, !tbaa !15
  %12 = getelementptr inbounds i64, ptr %3, i64 %4
  %13 = add i32 %2, -1
  %14 = mul i32 %13, %6
  %15 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %12, i64 noundef %4, i32 noundef %14) #16
  %16 = getelementptr inbounds i64, ptr %7, i64 %4
  store i64 %15, ptr %16, align 8, !tbaa !15
  %17 = and i32 %2, 1
  %18 = icmp eq i32 %17, 0
  %19 = icmp eq i64 %5, 0
  br i1 %18, label %45, label %20

20:                                               ; preds = %8
  br i1 %19, label %36, label %21

21:                                               ; preds = %20
  %22 = zext i32 %2 to i64
  %23 = mul nsw i64 %22, %4
  %24 = getelementptr inbounds i64, ptr %3, i64 %23
  %25 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %24, i64 noundef %5) #16
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %36, label %27

27:                                               ; preds = %30, %21
  %28 = phi i64 [ %34, %30 ], [ %5, %21 ]
  %29 = icmp sgt i64 %28, %4
  br i1 %29, label %36, label %30

30:                                               ; preds = %27
  %31 = getelementptr inbounds i64, ptr %7, i64 %28
  %32 = load i64, ptr %31, align 8, !tbaa !15
  %33 = add i64 %32, 1
  %34 = add nsw i64 %28, 1
  store i64 %33, ptr %31, align 8, !tbaa !15
  %35 = icmp eq i64 %33, 0
  br i1 %35, label %27, label %36, !llvm.loop !216

36:                                               ; preds = %30, %27, %21, %20
  %37 = zext i32 %13 to i64
  %38 = mul nsw i64 %37, %4
  %39 = getelementptr inbounds i64, ptr %3, i64 %38
  %40 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %39, i64 noundef %4, i32 noundef %6) #16
  %41 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %1, i64 noundef %4) #16
  %42 = add i64 %41, %40
  %43 = load i64, ptr %11, align 8, !tbaa !15
  %44 = add i64 %42, %43
  store i64 %44, ptr %11, align 8, !tbaa !15
  br label %61

45:                                               ; preds = %8
  br i1 %19, label %61, label %46

46:                                               ; preds = %45
  %47 = zext i32 %2 to i64
  %48 = mul nsw i64 %47, %4
  %49 = getelementptr inbounds i64, ptr %3, i64 %48
  %50 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %49, i64 noundef %5) #16
  %51 = icmp eq i64 %50, 0
  br i1 %51, label %61, label %52

52:                                               ; preds = %55, %46
  %53 = phi i64 [ %59, %55 ], [ %5, %46 ]
  %54 = icmp sgt i64 %53, %4
  br i1 %54, label %61, label %55

55:                                               ; preds = %52
  %56 = getelementptr inbounds i64, ptr %0, i64 %53
  %57 = load i64, ptr %56, align 8, !tbaa !15
  %58 = add i64 %57, 1
  %59 = add nsw i64 %53, 1
  store i64 %58, ptr %56, align 8, !tbaa !15
  %60 = icmp eq i64 %58, 0
  br i1 %60, label %52, label %61, !llvm.loop !216

61:                                               ; preds = %55, %52, %46, %45, %36
  %62 = icmp ugt i32 %13, 2
  br i1 %62, label %63, label %88

63:                                               ; preds = %63, %61
  %64 = phi i32 [ %86, %63 ], [ 2, %61 ]
  %65 = zext i32 %64 to i64
  %66 = mul nsw i64 %65, %4
  %67 = getelementptr inbounds i64, ptr %3, i64 %66
  %68 = sub i32 %2, %64
  %69 = mul i32 %68, %6
  %70 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %67, i64 noundef %4, i32 noundef %69) #16
  %71 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %1, i64 noundef %4) #16
  %72 = add i64 %71, %70
  %73 = load i64, ptr %11, align 8, !tbaa !15
  %74 = add i64 %72, %73
  store i64 %74, ptr %11, align 8, !tbaa !15
  %75 = or disjoint i32 %64, 1
  %76 = zext i32 %75 to i64
  %77 = mul nsw i64 %76, %4
  %78 = getelementptr inbounds i64, ptr %3, i64 %77
  %79 = sub i32 %2, %75
  %80 = mul i32 %79, %6
  %81 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %78, i64 noundef %4, i32 noundef %80) #16
  %82 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %4) #16
  %83 = add i64 %82, %81
  %84 = load i64, ptr %16, align 8, !tbaa !15
  %85 = add i64 %83, %84
  store i64 %85, ptr %16, align 8, !tbaa !15
  %86 = add i32 %64, 2
  %87 = icmp ult i32 %86, %13
  br i1 %87, label %63, label %88, !llvm.loop !217

88:                                               ; preds = %63, %61
  %89 = add nsw i64 %4, 1
  br label %90

90:                                               ; preds = %93, %88
  %91 = phi i64 [ %89, %88 ], [ %94, %93 ]
  %92 = icmp sgt i64 %91, 0
  br i1 %92, label %93, label %103

93:                                               ; preds = %90
  %94 = add nsw i64 %91, -1
  %95 = getelementptr inbounds i64, ptr %0, i64 %94
  %96 = load i64, ptr %95, align 8, !tbaa !15
  %97 = getelementptr inbounds i64, ptr %7, i64 %94
  %98 = load i64, ptr %97, align 8, !tbaa !15
  %99 = icmp eq i64 %96, %98
  br i1 %99, label %90, label %100, !llvm.loop !218

100:                                              ; preds = %93
  %101 = icmp ugt i64 %96, %98
  %102 = select i1 %101, i32 1, i32 -1
  br label %103

103:                                              ; preds = %100, %90
  %104 = phi i32 [ %102, %100 ], [ 0, %90 ]
  %105 = icmp slt i32 %104, 0
  br i1 %105, label %106, label %108

106:                                              ; preds = %103
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %7, ptr noundef %0, i64 noundef %89) #16
  br label %110

108:                                              ; preds = %103
  %109 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %7, i64 noundef %89) #16
  br label %110

110:                                              ; preds = %108, %106
  %111 = ashr i32 %104, 31
  %112 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %7, i64 noundef %89) #16
  ret i32 %111
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_couple_handling(ptr noundef %0, i64 noundef %1, ptr noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %5, i32 noundef %6) local_unnamed_addr #5 {
  %8 = icmp eq i32 %3, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %7
  %10 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %0, ptr noundef %2, i64 noundef %1) #16
  br label %13

11:                                               ; preds = %7
  %12 = tail call i64 @__gmpn_add_n(ptr noundef %2, ptr noundef %0, ptr noundef %2, i64 noundef %1) #16
  br label %13

13:                                               ; preds = %11, %9
  %14 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %1, i32 noundef 1) #16
  %15 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %0, ptr noundef %2, i64 noundef %1) #16
  %16 = icmp sgt i32 %5, 0
  br i1 %16, label %17, label %19

17:                                               ; preds = %13
  %18 = tail call i64 @__gmpn_rshift(ptr noundef %0, ptr noundef %0, i64 noundef %1, i32 noundef %5) #16
  br label %19

19:                                               ; preds = %17, %13
  %20 = icmp sgt i32 %6, 0
  br i1 %20, label %21, label %23

21:                                               ; preds = %19
  %22 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %1, i32 noundef %6) #16
  br label %23

23:                                               ; preds = %21, %19
  %24 = getelementptr inbounds i64, ptr %0, i64 %4
  %25 = sub nsw i64 %1, %4
  %26 = tail call i64 @__gmpn_add_n(ptr noundef %24, ptr noundef %24, ptr noundef %2, i64 noundef %25) #16
  %27 = getelementptr inbounds i64, ptr %0, i64 %1
  store i64 %26, ptr %27, align 8, !tbaa !15
  %28 = getelementptr inbounds i64, ptr %2, i64 %1
  %29 = sub i64 0, %4
  %30 = getelementptr inbounds i64, ptr %28, i64 %29
  %31 = load i64, ptr %30, align 8, !tbaa !15
  %32 = add i64 %31, %26
  store i64 %32, ptr %27, align 8, !tbaa !15
  %33 = icmp ult i64 %32, %26
  br i1 %33, label %34, label %57

34:                                               ; preds = %23
  %35 = tail call i64 @llvm.smax.i64(i64 %4, i64 1)
  br label %36

36:                                               ; preds = %39, %34
  %37 = phi i64 [ %44, %39 ], [ 1, %34 ]
  %38 = icmp eq i64 %37, %35
  br i1 %38, label %68, label %39

39:                                               ; preds = %36
  %40 = getelementptr inbounds i64, ptr %30, i64 %37
  %41 = load i64, ptr %40, align 8, !tbaa !15
  %42 = add i64 %41, 1
  %43 = getelementptr inbounds i64, ptr %27, i64 %37
  store i64 %42, ptr %43, align 8, !tbaa !15
  %44 = add nuw i64 %37, 1
  %45 = icmp eq i64 %42, 0
  br i1 %45, label %36, label %46, !llvm.loop !219

46:                                               ; preds = %39
  %47 = icmp ne ptr %30, %27
  %48 = icmp slt i64 %44, %4
  %49 = select i1 %47, i1 %48, i1 false
  br i1 %49, label %50, label %68

50:                                               ; preds = %50, %46
  %51 = phi i64 [ %55, %50 ], [ %44, %46 ]
  %52 = getelementptr inbounds i64, ptr %30, i64 %51
  %53 = load i64, ptr %52, align 8, !tbaa !15
  %54 = getelementptr inbounds i64, ptr %27, i64 %51
  store i64 %53, ptr %54, align 8, !tbaa !15
  %55 = add nuw nsw i64 %51, 1
  %56 = icmp slt i64 %55, %4
  br i1 %56, label %50, label %68, !llvm.loop !220

57:                                               ; preds = %23
  %58 = icmp ne ptr %30, %27
  %59 = icmp sgt i64 %4, 1
  %60 = and i1 %59, %58
  br i1 %60, label %61, label %68

61:                                               ; preds = %61, %57
  %62 = phi i64 [ %66, %61 ], [ 1, %57 ]
  %63 = getelementptr inbounds i64, ptr %30, i64 %62
  %64 = load i64, ptr %63, align 8, !tbaa !15
  %65 = getelementptr inbounds i64, ptr %27, i64 %62
  store i64 %64, ptr %65, align 8, !tbaa !15
  %66 = add nuw nsw i64 %62, 1
  %67 = icmp eq i64 %66, %4
  br i1 %67, label %68, label %61, !llvm.loop !221

68:                                               ; preds = %61, %57, %50, %46, %36
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @__gmpn_toom_eval_pm2(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, ptr noundef %6) local_unnamed_addr #5 {
  %8 = zext i32 %2 to i64
  %9 = mul nsw i64 %8, %4
  %10 = getelementptr inbounds i64, ptr %3, i64 %9
  %11 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %10, i64 noundef %5, i32 noundef 2) #16
  %12 = add i32 %2, -2
  %13 = zext i32 %12 to i64
  %14 = mul nsw i64 %13, %4
  %15 = getelementptr inbounds i64, ptr %3, i64 %14
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %15, i64 noundef %5) #16
  %17 = add i64 %16, %11
  %18 = icmp eq i64 %5, %4
  br i1 %18, label %60, label %19

19:                                               ; preds = %7
  %20 = getelementptr inbounds i64, ptr %0, i64 %5
  %21 = getelementptr inbounds i64, ptr %15, i64 %5
  %22 = sub nsw i64 %4, %5
  %23 = load i64, ptr %21, align 8, !tbaa !15
  %24 = add i64 %23, %17
  store i64 %24, ptr %20, align 8, !tbaa !15
  %25 = icmp ult i64 %24, %17
  br i1 %25, label %26, label %49

26:                                               ; preds = %19
  %27 = tail call i64 @llvm.smax.i64(i64 %22, i64 1)
  br label %28

28:                                               ; preds = %31, %26
  %29 = phi i64 [ %36, %31 ], [ 1, %26 ]
  %30 = icmp eq i64 %29, %27
  br i1 %30, label %60, label %31

31:                                               ; preds = %28
  %32 = getelementptr inbounds i64, ptr %21, i64 %29
  %33 = load i64, ptr %32, align 8, !tbaa !15
  %34 = add i64 %33, 1
  %35 = getelementptr inbounds i64, ptr %20, i64 %29
  store i64 %34, ptr %35, align 8, !tbaa !15
  %36 = add nuw i64 %29, 1
  %37 = icmp eq i64 %34, 0
  br i1 %37, label %28, label %38, !llvm.loop !222

38:                                               ; preds = %31
  %39 = icmp ne ptr %15, %0
  %40 = icmp slt i64 %36, %22
  %41 = select i1 %39, i1 %40, i1 false
  br i1 %41, label %42, label %60

42:                                               ; preds = %42, %38
  %43 = phi i64 [ %47, %42 ], [ %36, %38 ]
  %44 = getelementptr inbounds i64, ptr %21, i64 %43
  %45 = load i64, ptr %44, align 8, !tbaa !15
  %46 = getelementptr inbounds i64, ptr %20, i64 %43
  store i64 %45, ptr %46, align 8, !tbaa !15
  %47 = add nuw nsw i64 %43, 1
  %48 = icmp slt i64 %47, %22
  br i1 %48, label %42, label %60, !llvm.loop !223

49:                                               ; preds = %19
  %50 = icmp ne ptr %15, %0
  %51 = icmp sgt i64 %22, 1
  %52 = and i1 %50, %51
  br i1 %52, label %53, label %60

53:                                               ; preds = %53, %49
  %54 = phi i64 [ %58, %53 ], [ 1, %49 ]
  %55 = getelementptr inbounds i64, ptr %21, i64 %54
  %56 = load i64, ptr %55, align 8, !tbaa !15
  %57 = getelementptr inbounds i64, ptr %20, i64 %54
  store i64 %56, ptr %57, align 8, !tbaa !15
  %58 = add nuw nsw i64 %54, 1
  %59 = icmp eq i64 %58, %22
  br i1 %59, label %60, label %53, !llvm.loop !224

60:                                               ; preds = %53, %49, %42, %38, %28, %7
  %61 = phi i64 [ %17, %7 ], [ 0, %38 ], [ 0, %49 ], [ 0, %42 ], [ 1, %28 ], [ 0, %53 ]
  %62 = add i32 %2, -4
  %63 = icmp sgt i32 %62, -1
  br i1 %63, label %64, label %78

64:                                               ; preds = %60
  %65 = zext nneg i32 %62 to i64
  br label %66

66:                                               ; preds = %66, %64
  %67 = phi i64 [ %65, %64 ], [ %76, %66 ]
  %68 = phi i64 [ %61, %64 ], [ %75, %66 ]
  %69 = shl i64 %68, 2
  %70 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %4, i32 noundef 2) #16
  %71 = add i64 %70, %69
  %72 = mul nsw i64 %67, %4
  %73 = getelementptr inbounds i64, ptr %3, i64 %72
  %74 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %73, i64 noundef %4) #16
  %75 = add i64 %71, %74
  %76 = add nsw i64 %67, -2
  %77 = icmp sgt i64 %67, 1
  br i1 %77, label %66, label %78, !llvm.loop !225

78:                                               ; preds = %66, %60
  %79 = phi i64 [ %61, %60 ], [ %75, %66 ]
  %80 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %79, ptr %80, align 8, !tbaa !15
  %81 = add i32 %2, -1
  %82 = zext i32 %81 to i64
  %83 = mul nsw i64 %82, %4
  %84 = getelementptr inbounds i64, ptr %3, i64 %83
  %85 = tail call i64 @__gmpn_lshift(ptr noundef %6, ptr noundef %84, i64 noundef %4, i32 noundef 2) #16
  %86 = add i32 %2, -3
  %87 = zext i32 %86 to i64
  %88 = mul nsw i64 %87, %4
  %89 = getelementptr inbounds i64, ptr %3, i64 %88
  %90 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %89, i64 noundef %4) #16
  %91 = add i64 %90, %85
  %92 = add i32 %2, -5
  %93 = icmp sgt i32 %92, -1
  br i1 %93, label %94, label %108

94:                                               ; preds = %78
  %95 = zext nneg i32 %92 to i64
  br label %96

96:                                               ; preds = %96, %94
  %97 = phi i64 [ %95, %94 ], [ %106, %96 ]
  %98 = phi i64 [ %91, %94 ], [ %105, %96 ]
  %99 = shl i64 %98, 2
  %100 = tail call i64 @__gmpn_lshift(ptr noundef %6, ptr noundef %6, i64 noundef %4, i32 noundef 2) #16
  %101 = add i64 %100, %99
  %102 = mul nsw i64 %97, %4
  %103 = getelementptr inbounds i64, ptr %3, i64 %102
  %104 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %103, i64 noundef %4) #16
  %105 = add i64 %101, %104
  %106 = add nsw i64 %97, -2
  %107 = icmp sgt i64 %97, 1
  br i1 %107, label %96, label %108, !llvm.loop !226

108:                                              ; preds = %96, %78
  %109 = phi i64 [ %91, %78 ], [ %105, %96 ]
  %110 = getelementptr inbounds i64, ptr %6, i64 %4
  store i64 %109, ptr %110, align 8, !tbaa !15
  %111 = and i32 %81, 1
  %112 = icmp eq i32 %111, 0
  %113 = add nsw i64 %4, 1
  br i1 %112, label %116, label %114

114:                                              ; preds = %108
  %115 = tail call i64 @__gmpn_lshift(ptr noundef %6, ptr noundef %6, i64 noundef %113, i32 noundef 1) #16
  br label %118

116:                                              ; preds = %108
  %117 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %113, i32 noundef 1) #16
  br label %118

118:                                              ; preds = %116, %114
  %119 = add nsw i64 %4, 1
  br label %120

120:                                              ; preds = %123, %118
  %121 = phi i64 [ %119, %118 ], [ %124, %123 ]
  %122 = icmp sgt i64 %121, 0
  br i1 %122, label %123, label %133

123:                                              ; preds = %120
  %124 = add nsw i64 %121, -1
  %125 = getelementptr inbounds i64, ptr %0, i64 %124
  %126 = load i64, ptr %125, align 8, !tbaa !15
  %127 = getelementptr inbounds i64, ptr %6, i64 %124
  %128 = load i64, ptr %127, align 8, !tbaa !15
  %129 = icmp eq i64 %126, %128
  br i1 %129, label %120, label %130, !llvm.loop !227

130:                                              ; preds = %123
  %131 = icmp ugt i64 %126, %128
  %132 = select i1 %131, i32 1, i32 -1
  br label %133

133:                                              ; preds = %130, %120
  %134 = phi i32 [ %132, %130 ], [ 0, %120 ]
  %135 = icmp slt i32 %134, 0
  br i1 %135, label %136, label %138

136:                                              ; preds = %133
  %137 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %6, ptr noundef %0, i64 noundef %119) #16
  br label %140

138:                                              ; preds = %133
  %139 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %6, i64 noundef %119) #16
  br label %140

140:                                              ; preds = %138, %136
  %141 = ashr i32 %134, 31
  %142 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %6, i64 noundef %119) #16
  %143 = add nsw i32 %111, -1
  %144 = xor i32 %141, %143
  ret i32 %144
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_pm2exp(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, i32 noundef %6, ptr noundef %7) local_unnamed_addr #5 {
  %9 = shl nsw i64 %4, 4
  %10 = getelementptr inbounds i8, ptr %3, i64 %9
  %11 = shl i32 %6, 1
  %12 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %10, i64 noundef %4, i32 noundef %11) #16
  %13 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %12, ptr %13, align 8, !tbaa !15
  %14 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %3, ptr noundef %7, i64 noundef %4) #16
  %15 = load i64, ptr %13, align 8, !tbaa !15
  %16 = add i64 %15, %14
  store i64 %16, ptr %13, align 8, !tbaa !15
  %17 = icmp ugt i32 %2, 4
  br i1 %17, label %18, label %32

18:                                               ; preds = %18, %8
  %19 = phi i32 [ %30, %18 ], [ 4, %8 ]
  %20 = zext i32 %19 to i64
  %21 = mul nsw i64 %20, %4
  %22 = getelementptr inbounds i64, ptr %3, i64 %21
  %23 = mul i32 %19, %6
  %24 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %22, i64 noundef %4, i32 noundef %23) #16
  %25 = load i64, ptr %13, align 8, !tbaa !15
  %26 = add i64 %25, %24
  store i64 %26, ptr %13, align 8, !tbaa !15
  %27 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %7, i64 noundef %4) #16
  %28 = load i64, ptr %13, align 8, !tbaa !15
  %29 = add i64 %28, %27
  store i64 %29, ptr %13, align 8, !tbaa !15
  %30 = add i32 %19, 2
  %31 = icmp ult i32 %30, %2
  br i1 %31, label %18, label %32, !llvm.loop !228

32:                                               ; preds = %18, %8
  %33 = getelementptr inbounds i64, ptr %3, i64 %4
  %34 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %33, i64 noundef %4, i32 noundef %6) #16
  %35 = getelementptr inbounds i64, ptr %7, i64 %4
  store i64 %34, ptr %35, align 8, !tbaa !15
  %36 = icmp ugt i32 %2, 3
  br i1 %36, label %37, label %51

37:                                               ; preds = %37, %32
  %38 = phi i32 [ %49, %37 ], [ 3, %32 ]
  %39 = zext i32 %38 to i64
  %40 = mul nsw i64 %39, %4
  %41 = getelementptr inbounds i64, ptr %3, i64 %40
  %42 = mul i32 %38, %6
  %43 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %41, i64 noundef %4, i32 noundef %42) #16
  %44 = load i64, ptr %35, align 8, !tbaa !15
  %45 = add i64 %44, %43
  store i64 %45, ptr %35, align 8, !tbaa !15
  %46 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %4) #16
  %47 = load i64, ptr %35, align 8, !tbaa !15
  %48 = add i64 %47, %46
  store i64 %48, ptr %35, align 8, !tbaa !15
  %49 = add i32 %38, 2
  %50 = icmp ult i32 %49, %2
  br i1 %50, label %37, label %51, !llvm.loop !229

51:                                               ; preds = %37, %32
  %52 = zext i32 %2 to i64
  %53 = mul nsw i64 %52, %4
  %54 = getelementptr inbounds i64, ptr %3, i64 %53
  %55 = mul i32 %6, %2
  %56 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %54, i64 noundef %5, i32 noundef %55) #16
  %57 = getelementptr inbounds i64, ptr %1, i64 %5
  store i64 %56, ptr %57, align 8, !tbaa !15
  %58 = and i32 %2, 1
  %59 = icmp eq i32 %58, 0
  %60 = add nsw i64 %5, 1
  %61 = icmp eq i64 %60, 0
  br i1 %59, label %75, label %62

62:                                               ; preds = %51
  br i1 %61, label %88, label %63

63:                                               ; preds = %62
  %64 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %60) #16
  %65 = icmp eq i64 %64, 0
  br i1 %65, label %88, label %66

66:                                               ; preds = %69, %63
  %67 = phi i64 [ %73, %69 ], [ %60, %63 ]
  %68 = icmp sgt i64 %67, %4
  br i1 %68, label %88, label %69

69:                                               ; preds = %66
  %70 = getelementptr inbounds i64, ptr %7, i64 %67
  %71 = load i64, ptr %70, align 8, !tbaa !15
  %72 = add i64 %71, 1
  %73 = add nsw i64 %67, 1
  store i64 %72, ptr %70, align 8, !tbaa !15
  %74 = icmp eq i64 %72, 0
  br i1 %74, label %66, label %88, !llvm.loop !230

75:                                               ; preds = %51
  br i1 %61, label %88, label %76

76:                                               ; preds = %75
  %77 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %1, i64 noundef %60) #16
  %78 = icmp eq i64 %77, 0
  br i1 %78, label %88, label %79

79:                                               ; preds = %82, %76
  %80 = phi i64 [ %86, %82 ], [ %60, %76 ]
  %81 = icmp sgt i64 %80, %4
  br i1 %81, label %88, label %82

82:                                               ; preds = %79
  %83 = getelementptr inbounds i64, ptr %0, i64 %80
  %84 = load i64, ptr %83, align 8, !tbaa !15
  %85 = add i64 %84, 1
  %86 = add nsw i64 %80, 1
  store i64 %85, ptr %83, align 8, !tbaa !15
  %87 = icmp eq i64 %85, 0
  br i1 %87, label %79, label %88, !llvm.loop !230

88:                                               ; preds = %82, %79, %76, %75, %69, %66, %63, %62
  %89 = add nsw i64 %4, 1
  br label %90

90:                                               ; preds = %93, %88
  %91 = phi i64 [ %89, %88 ], [ %94, %93 ]
  %92 = icmp sgt i64 %91, 0
  br i1 %92, label %93, label %103

93:                                               ; preds = %90
  %94 = add nsw i64 %91, -1
  %95 = getelementptr inbounds i64, ptr %0, i64 %94
  %96 = load i64, ptr %95, align 8, !tbaa !15
  %97 = getelementptr inbounds i64, ptr %7, i64 %94
  %98 = load i64, ptr %97, align 8, !tbaa !15
  %99 = icmp eq i64 %96, %98
  br i1 %99, label %90, label %100, !llvm.loop !231

100:                                              ; preds = %93
  %101 = icmp ugt i64 %96, %98
  %102 = select i1 %101, i32 1, i32 -1
  br label %103

103:                                              ; preds = %100, %90
  %104 = phi i32 [ %102, %100 ], [ 0, %90 ]
  %105 = icmp slt i32 %104, 0
  br i1 %105, label %106, label %108

106:                                              ; preds = %103
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %7, ptr noundef %0, i64 noundef %89) #16
  br label %110

108:                                              ; preds = %103
  %109 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %7, i64 noundef %89) #16
  br label %110

110:                                              ; preds = %108, %106
  %111 = ashr i32 %104, 31
  %112 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %7, i64 noundef %89) #16
  ret i32 %111
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_pm1(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, ptr noundef %6) local_unnamed_addr #5 {
  %8 = shl nsw i64 %4, 4
  %9 = getelementptr inbounds i8, ptr %3, i64 %8
  %10 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %3, ptr noundef %9, i64 noundef %4) #16
  %11 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %10, ptr %11, align 8, !tbaa !15
  %12 = icmp ugt i32 %2, 4
  br i1 %12, label %13, label %35

13:                                               ; preds = %7
  %14 = icmp eq i64 %4, 0
  br label %15

15:                                               ; preds = %32, %13
  %16 = phi i32 [ 4, %13 ], [ %33, %32 ]
  br i1 %14, label %32, label %17

17:                                               ; preds = %15
  %18 = zext i32 %16 to i64
  %19 = mul nsw i64 %18, %4
  %20 = getelementptr inbounds i64, ptr %3, i64 %19
  %21 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %20, i64 noundef %4) #16
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %32, label %23

23:                                               ; preds = %26, %17
  %24 = phi i64 [ %30, %26 ], [ %4, %17 ]
  %25 = icmp sgt i64 %24, %4
  br i1 %25, label %32, label %26

26:                                               ; preds = %23
  %27 = getelementptr inbounds i64, ptr %0, i64 %24
  %28 = load i64, ptr %27, align 8, !tbaa !15
  %29 = add i64 %28, 1
  %30 = add nsw i64 %24, 1
  store i64 %29, ptr %27, align 8, !tbaa !15
  %31 = icmp eq i64 %29, 0
  br i1 %31, label %23, label %32, !llvm.loop !232

32:                                               ; preds = %26, %23, %17, %15
  %33 = add i32 %16, 2
  %34 = icmp ult i32 %33, %2
  br i1 %34, label %15, label %35, !llvm.loop !233

35:                                               ; preds = %32, %7
  %36 = getelementptr inbounds i64, ptr %3, i64 %4
  %37 = mul i64 %4, 24
  %38 = getelementptr inbounds i8, ptr %3, i64 %37
  %39 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %36, ptr noundef %38, i64 noundef %4) #16
  %40 = getelementptr inbounds i64, ptr %6, i64 %4
  store i64 %39, ptr %40, align 8, !tbaa !15
  %41 = icmp ugt i32 %2, 5
  br i1 %41, label %42, label %64

42:                                               ; preds = %35
  %43 = icmp eq i64 %4, 0
  br label %44

44:                                               ; preds = %61, %42
  %45 = phi i32 [ 5, %42 ], [ %62, %61 ]
  br i1 %43, label %61, label %46

46:                                               ; preds = %44
  %47 = zext i32 %45 to i64
  %48 = mul nsw i64 %47, %4
  %49 = getelementptr inbounds i64, ptr %3, i64 %48
  %50 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %49, i64 noundef %4) #16
  %51 = icmp eq i64 %50, 0
  br i1 %51, label %61, label %52

52:                                               ; preds = %55, %46
  %53 = phi i64 [ %59, %55 ], [ %4, %46 ]
  %54 = icmp sgt i64 %53, %4
  br i1 %54, label %61, label %55

55:                                               ; preds = %52
  %56 = getelementptr inbounds i64, ptr %6, i64 %53
  %57 = load i64, ptr %56, align 8, !tbaa !15
  %58 = add i64 %57, 1
  %59 = add nsw i64 %53, 1
  store i64 %58, ptr %56, align 8, !tbaa !15
  %60 = icmp eq i64 %58, 0
  br i1 %60, label %52, label %61, !llvm.loop !232

61:                                               ; preds = %55, %52, %46, %44
  %62 = add i32 %45, 2
  %63 = icmp ult i32 %62, %2
  br i1 %63, label %44, label %64, !llvm.loop !234

64:                                               ; preds = %61, %35
  %65 = and i32 %2, 1
  %66 = icmp eq i32 %65, 0
  %67 = icmp eq i64 %5, 0
  br i1 %66, label %84, label %68

68:                                               ; preds = %64
  br i1 %67, label %100, label %69

69:                                               ; preds = %68
  %70 = zext i32 %2 to i64
  %71 = mul nsw i64 %70, %4
  %72 = getelementptr inbounds i64, ptr %3, i64 %71
  %73 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %72, i64 noundef %5) #16
  %74 = icmp eq i64 %73, 0
  br i1 %74, label %100, label %75

75:                                               ; preds = %78, %69
  %76 = phi i64 [ %82, %78 ], [ %5, %69 ]
  %77 = icmp sgt i64 %76, %4
  br i1 %77, label %100, label %78

78:                                               ; preds = %75
  %79 = getelementptr inbounds i64, ptr %6, i64 %76
  %80 = load i64, ptr %79, align 8, !tbaa !15
  %81 = add i64 %80, 1
  %82 = add nsw i64 %76, 1
  store i64 %81, ptr %79, align 8, !tbaa !15
  %83 = icmp eq i64 %81, 0
  br i1 %83, label %75, label %100, !llvm.loop !232

84:                                               ; preds = %64
  br i1 %67, label %100, label %85

85:                                               ; preds = %84
  %86 = zext i32 %2 to i64
  %87 = mul nsw i64 %86, %4
  %88 = getelementptr inbounds i64, ptr %3, i64 %87
  %89 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %88, i64 noundef %5) #16
  %90 = icmp eq i64 %89, 0
  br i1 %90, label %100, label %91

91:                                               ; preds = %94, %85
  %92 = phi i64 [ %98, %94 ], [ %5, %85 ]
  %93 = icmp sgt i64 %92, %4
  br i1 %93, label %100, label %94

94:                                               ; preds = %91
  %95 = getelementptr inbounds i64, ptr %0, i64 %92
  %96 = load i64, ptr %95, align 8, !tbaa !15
  %97 = add i64 %96, 1
  %98 = add nsw i64 %92, 1
  store i64 %97, ptr %95, align 8, !tbaa !15
  %99 = icmp eq i64 %97, 0
  br i1 %99, label %91, label %100, !llvm.loop !232

100:                                              ; preds = %94, %91, %85, %84, %78, %75, %69, %68
  %101 = add nsw i64 %4, 1
  br label %102

102:                                              ; preds = %105, %100
  %103 = phi i64 [ %101, %100 ], [ %106, %105 ]
  %104 = icmp sgt i64 %103, 0
  br i1 %104, label %105, label %115

105:                                              ; preds = %102
  %106 = add nsw i64 %103, -1
  %107 = getelementptr inbounds i64, ptr %0, i64 %106
  %108 = load i64, ptr %107, align 8, !tbaa !15
  %109 = getelementptr inbounds i64, ptr %6, i64 %106
  %110 = load i64, ptr %109, align 8, !tbaa !15
  %111 = icmp eq i64 %108, %110
  br i1 %111, label %102, label %112, !llvm.loop !235

112:                                              ; preds = %105
  %113 = icmp ugt i64 %108, %110
  %114 = select i1 %113, i32 1, i32 -1
  br label %115

115:                                              ; preds = %112, %102
  %116 = phi i32 [ %114, %112 ], [ 0, %102 ]
  %117 = icmp slt i32 %116, 0
  br i1 %117, label %118, label %120

118:                                              ; preds = %115
  %119 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %6, ptr noundef %0, i64 noundef %101) #16
  br label %122

120:                                              ; preds = %115
  %121 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %6, i64 noundef %101) #16
  br label %122

122:                                              ; preds = %120, %118
  %123 = ashr i32 %116, 31
  %124 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %6, i64 noundef %101) #16
  ret i32 %123
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_16pts(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i64 noundef %5, i64 noundef %6, i32 noundef %7, ptr noundef %8) local_unnamed_addr #5 {
  %10 = mul nsw i64 %5, 3
  %11 = add nsw i64 %10, 1
  %12 = icmp eq i32 %7, 0
  br i1 %12, label %163, label %13

13:                                               ; preds = %9
  %14 = mul i64 %5, 56
  %15 = getelementptr inbounds i8, ptr %0, i64 %14
  %16 = mul i64 %5, 120
  %17 = getelementptr inbounds i8, ptr %0, i64 %16
  %18 = tail call i64 @__gmpn_sub_n(ptr noundef %15, ptr noundef %15, ptr noundef %17, i64 noundef %6) #16
  %19 = getelementptr inbounds i64, ptr %15, i64 %6
  %20 = load i64, ptr %19, align 8, !tbaa !15
  %21 = sub i64 %20, %18
  store i64 %21, ptr %19, align 8, !tbaa !15
  %22 = icmp ult i64 %20, %18
  br i1 %22, label %23, label %29

23:                                               ; preds = %23, %13
  %24 = phi ptr [ %25, %23 ], [ %19, %13 ]
  %25 = getelementptr inbounds i8, ptr %24, i64 8
  %26 = load i64, ptr %25, align 8, !tbaa !15
  %27 = add i64 %26, -1
  store i64 %27, ptr %25, align 8, !tbaa !15
  %28 = icmp eq i64 %26, 0
  br i1 %28, label %23, label %29, !llvm.loop !236

29:                                               ; preds = %23, %13
  %30 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %17, i64 noundef %6, i32 noundef 14) #16
  %31 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %8, i64 noundef %6) #16
  %32 = getelementptr inbounds i64, ptr %2, i64 %6
  %33 = add i64 %31, %30
  %34 = load i64, ptr %32, align 8, !tbaa !15
  %35 = sub i64 %34, %33
  store i64 %35, ptr %32, align 8, !tbaa !15
  %36 = icmp ult i64 %34, %33
  br i1 %36, label %37, label %43

37:                                               ; preds = %37, %29
  %38 = phi ptr [ %39, %37 ], [ %32, %29 ]
  %39 = getelementptr inbounds i8, ptr %38, i64 8
  %40 = load i64, ptr %39, align 8, !tbaa !15
  %41 = add i64 %40, -1
  store i64 %41, ptr %39, align 8, !tbaa !15
  %42 = icmp eq i64 %40, 0
  br i1 %42, label %37, label %43, !llvm.loop !237

43:                                               ; preds = %37, %29
  %44 = getelementptr inbounds i64, ptr %0, i64 %10
  %45 = load i64, ptr %17, align 8, !tbaa !15
  %46 = lshr i64 %45, 2
  %47 = load i64, ptr %44, align 8, !tbaa !15
  %48 = sub i64 %47, %46
  store i64 %48, ptr %44, align 8, !tbaa !15
  %49 = load i64, ptr %17, align 8, !tbaa !15
  %50 = lshr i64 %49, 2
  %51 = icmp ult i64 %47, %50
  br i1 %51, label %52, label %58

52:                                               ; preds = %52, %43
  %53 = phi ptr [ %54, %52 ], [ %44, %43 ]
  %54 = getelementptr inbounds i8, ptr %53, i64 8
  %55 = load i64, ptr %54, align 8, !tbaa !15
  %56 = add i64 %55, -1
  store i64 %56, ptr %54, align 8, !tbaa !15
  %57 = icmp eq i64 %55, 0
  br i1 %57, label %52, label %58, !llvm.loop !238

58:                                               ; preds = %52, %43
  %59 = getelementptr inbounds i8, ptr %17, i64 8
  %60 = add nsw i64 %6, -1
  %61 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %59, i64 noundef %60, i32 noundef 62) #16
  %62 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %44, ptr noundef nonnull %44, ptr noundef %8, i64 noundef %60) #16
  %63 = getelementptr inbounds i64, ptr %44, i64 %6
  %64 = getelementptr inbounds i8, ptr %63, i64 -8
  %65 = add i64 %62, %61
  %66 = load i64, ptr %64, align 8, !tbaa !15
  %67 = sub i64 %66, %65
  store i64 %67, ptr %64, align 8, !tbaa !15
  %68 = icmp ult i64 %66, %65
  br i1 %68, label %69, label %75

69:                                               ; preds = %69, %58
  %70 = phi ptr [ %71, %69 ], [ %64, %58 ]
  %71 = getelementptr inbounds i8, ptr %70, i64 8
  %72 = load i64, ptr %71, align 8, !tbaa !15
  %73 = add i64 %72, -1
  store i64 %73, ptr %71, align 8, !tbaa !15
  %74 = icmp eq i64 %72, 0
  br i1 %74, label %69, label %75, !llvm.loop !239

75:                                               ; preds = %69, %58
  %76 = mul i64 %5, 88
  %77 = getelementptr inbounds i8, ptr %0, i64 %76
  %78 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %17, i64 noundef %6, i32 noundef 28) #16
  %79 = tail call i64 @__gmpn_sub_n(ptr noundef %77, ptr noundef %77, ptr noundef %8, i64 noundef %6) #16
  %80 = getelementptr inbounds i64, ptr %77, i64 %6
  %81 = add i64 %79, %78
  %82 = load i64, ptr %80, align 8, !tbaa !15
  %83 = sub i64 %82, %81
  store i64 %83, ptr %80, align 8, !tbaa !15
  %84 = icmp ult i64 %82, %81
  br i1 %84, label %85, label %91

85:                                               ; preds = %85, %75
  %86 = phi ptr [ %87, %85 ], [ %80, %75 ]
  %87 = getelementptr inbounds i8, ptr %86, i64 8
  %88 = load i64, ptr %87, align 8, !tbaa !15
  %89 = add i64 %88, -1
  store i64 %89, ptr %87, align 8, !tbaa !15
  %90 = icmp eq i64 %88, 0
  br i1 %90, label %85, label %91, !llvm.loop !240

91:                                               ; preds = %85, %75
  %92 = load i64, ptr %17, align 8, !tbaa !15
  %93 = lshr i64 %92, 4
  %94 = load i64, ptr %3, align 8, !tbaa !15
  %95 = sub i64 %94, %93
  store i64 %95, ptr %3, align 8, !tbaa !15
  %96 = load i64, ptr %17, align 8, !tbaa !15
  %97 = lshr i64 %96, 4
  %98 = icmp ult i64 %94, %97
  br i1 %98, label %99, label %105

99:                                               ; preds = %99, %91
  %100 = phi ptr [ %101, %99 ], [ %3, %91 ]
  %101 = getelementptr inbounds i8, ptr %100, i64 8
  %102 = load i64, ptr %101, align 8, !tbaa !15
  %103 = add i64 %102, -1
  store i64 %103, ptr %101, align 8, !tbaa !15
  %104 = icmp eq i64 %102, 0
  br i1 %104, label %99, label %105, !llvm.loop !241

105:                                              ; preds = %99, %91
  %106 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %59, i64 noundef %60, i32 noundef 60) #16
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %3, ptr noundef nonnull %3, ptr noundef %8, i64 noundef %60) #16
  %108 = getelementptr inbounds i64, ptr %3, i64 %6
  %109 = getelementptr inbounds i8, ptr %108, i64 -8
  %110 = add i64 %107, %106
  %111 = load i64, ptr %109, align 8, !tbaa !15
  %112 = sub i64 %111, %110
  store i64 %112, ptr %109, align 8, !tbaa !15
  %113 = icmp ult i64 %111, %110
  br i1 %113, label %114, label %120

114:                                              ; preds = %114, %105
  %115 = phi ptr [ %116, %114 ], [ %109, %105 ]
  %116 = getelementptr inbounds i8, ptr %115, i64 8
  %117 = load i64, ptr %116, align 8, !tbaa !15
  %118 = add i64 %117, -1
  store i64 %118, ptr %116, align 8, !tbaa !15
  %119 = icmp eq i64 %117, 0
  br i1 %119, label %114, label %120, !llvm.loop !242

120:                                              ; preds = %114, %105
  %121 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %17, i64 noundef %6, i32 noundef 42) #16
  %122 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %8, i64 noundef %6) #16
  %123 = getelementptr inbounds i64, ptr %1, i64 %6
  %124 = add i64 %122, %121
  %125 = load i64, ptr %123, align 8, !tbaa !15
  %126 = sub i64 %125, %124
  store i64 %126, ptr %123, align 8, !tbaa !15
  %127 = icmp ult i64 %125, %124
  br i1 %127, label %128, label %134

128:                                              ; preds = %128, %120
  %129 = phi ptr [ %130, %128 ], [ %123, %120 ]
  %130 = getelementptr inbounds i8, ptr %129, i64 8
  %131 = load i64, ptr %130, align 8, !tbaa !15
  %132 = add i64 %131, -1
  store i64 %132, ptr %130, align 8, !tbaa !15
  %133 = icmp eq i64 %131, 0
  br i1 %133, label %128, label %134, !llvm.loop !243

134:                                              ; preds = %128, %120
  %135 = load i64, ptr %17, align 8, !tbaa !15
  %136 = lshr i64 %135, 6
  %137 = load i64, ptr %4, align 8, !tbaa !15
  %138 = sub i64 %137, %136
  store i64 %138, ptr %4, align 8, !tbaa !15
  %139 = load i64, ptr %17, align 8, !tbaa !15
  %140 = lshr i64 %139, 6
  %141 = icmp ult i64 %137, %140
  br i1 %141, label %142, label %148

142:                                              ; preds = %142, %134
  %143 = phi ptr [ %144, %142 ], [ %4, %134 ]
  %144 = getelementptr inbounds i8, ptr %143, i64 8
  %145 = load i64, ptr %144, align 8, !tbaa !15
  %146 = add i64 %145, -1
  store i64 %146, ptr %144, align 8, !tbaa !15
  %147 = icmp eq i64 %145, 0
  br i1 %147, label %142, label %148, !llvm.loop !244

148:                                              ; preds = %142, %134
  %149 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %59, i64 noundef %60, i32 noundef 58) #16
  %150 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %4, ptr noundef nonnull %4, ptr noundef %8, i64 noundef %60) #16
  %151 = getelementptr inbounds i64, ptr %4, i64 %6
  %152 = getelementptr inbounds i8, ptr %151, i64 -8
  %153 = add i64 %150, %149
  %154 = load i64, ptr %152, align 8, !tbaa !15
  %155 = sub i64 %154, %153
  store i64 %155, ptr %152, align 8, !tbaa !15
  %156 = icmp ult i64 %154, %153
  br i1 %156, label %157, label %163

157:                                              ; preds = %157, %148
  %158 = phi ptr [ %159, %157 ], [ %152, %148 ]
  %159 = getelementptr inbounds i8, ptr %158, i64 8
  %160 = load i64, ptr %159, align 8, !tbaa !15
  %161 = add i64 %160, -1
  store i64 %161, ptr %159, align 8, !tbaa !15
  %162 = icmp eq i64 %160, 0
  br i1 %162, label %157, label %163, !llvm.loop !245

163:                                              ; preds = %157, %148, %9
  %164 = getelementptr inbounds i64, ptr %3, i64 %5
  %165 = shl nsw i64 %5, 1
  %166 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %0, i64 noundef %165, i32 noundef 28) #16
  %167 = tail call i64 @__gmpn_sub_n(ptr noundef %164, ptr noundef %164, ptr noundef %8, i64 noundef %165) #16
  %168 = getelementptr inbounds i64, ptr %3, i64 %10
  %169 = load i64, ptr %168, align 8, !tbaa !15
  %170 = add i64 %167, %166
  %171 = sub i64 %169, %170
  store i64 %171, ptr %168, align 8, !tbaa !15
  %172 = mul i64 %5, 88
  %173 = getelementptr inbounds i8, ptr %0, i64 %172
  %174 = getelementptr inbounds i64, ptr %173, i64 %5
  %175 = load i64, ptr %0, align 8, !tbaa !15
  %176 = lshr i64 %175, 4
  %177 = load i64, ptr %174, align 8, !tbaa !15
  %178 = sub i64 %177, %176
  store i64 %178, ptr %174, align 8, !tbaa !15
  %179 = load i64, ptr %0, align 8, !tbaa !15
  %180 = lshr i64 %179, 4
  %181 = icmp ult i64 %177, %180
  br i1 %181, label %182, label %188

182:                                              ; preds = %182, %163
  %183 = phi ptr [ %184, %182 ], [ %174, %163 ]
  %184 = getelementptr inbounds i8, ptr %183, i64 8
  %185 = load i64, ptr %184, align 8, !tbaa !15
  %186 = add i64 %185, -1
  store i64 %186, ptr %184, align 8, !tbaa !15
  %187 = icmp eq i64 %185, 0
  br i1 %187, label %182, label %188, !llvm.loop !246

188:                                              ; preds = %182, %163
  %189 = getelementptr inbounds i8, ptr %0, i64 8
  %190 = add nsw i64 %165, -1
  %191 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %189, i64 noundef %190, i32 noundef 60) #16
  %192 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %174, ptr noundef nonnull %174, ptr noundef %8, i64 noundef %190) #16
  %193 = getelementptr inbounds i64, ptr %174, i64 %165
  %194 = getelementptr inbounds i8, ptr %193, i64 -8
  %195 = add i64 %192, %191
  %196 = load i64, ptr %194, align 8, !tbaa !15
  %197 = sub i64 %196, %195
  store i64 %197, ptr %194, align 8, !tbaa !15
  %198 = icmp ult i64 %196, %195
  br i1 %198, label %199, label %205

199:                                              ; preds = %199, %188
  %200 = phi ptr [ %201, %199 ], [ %194, %188 ]
  %201 = getelementptr inbounds i8, ptr %200, i64 8
  %202 = load i64, ptr %201, align 8, !tbaa !15
  %203 = add i64 %202, -1
  store i64 %203, ptr %201, align 8, !tbaa !15
  %204 = icmp eq i64 %202, 0
  br i1 %204, label %199, label %205, !llvm.loop !247

205:                                              ; preds = %199, %188
  %206 = tail call i64 @__gmpn_sub_n(ptr noundef %8, ptr noundef %3, ptr noundef nonnull %173, i64 noundef %11) #16
  %207 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef %3, i64 noundef %11) #16
  %208 = getelementptr inbounds i64, ptr %0, i64 %10
  %209 = getelementptr inbounds i64, ptr %208, i64 %5
  %210 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %0, i64 noundef %165, i32 noundef 14) #16
  %211 = tail call i64 @__gmpn_sub_n(ptr noundef %209, ptr noundef %209, ptr noundef %3, i64 noundef %165) #16
  %212 = getelementptr inbounds i64, ptr %208, i64 %10
  %213 = load i64, ptr %212, align 8, !tbaa !15
  %214 = add i64 %211, %210
  %215 = sub i64 %213, %214
  store i64 %215, ptr %212, align 8, !tbaa !15
  %216 = getelementptr inbounds i64, ptr %2, i64 %5
  %217 = load i64, ptr %0, align 8, !tbaa !15
  %218 = lshr i64 %217, 2
  %219 = load i64, ptr %216, align 8, !tbaa !15
  %220 = sub i64 %219, %218
  store i64 %220, ptr %216, align 8, !tbaa !15
  %221 = load i64, ptr %0, align 8, !tbaa !15
  %222 = lshr i64 %221, 2
  %223 = icmp ult i64 %219, %222
  br i1 %223, label %224, label %230

224:                                              ; preds = %224, %205
  %225 = phi ptr [ %226, %224 ], [ %216, %205 ]
  %226 = getelementptr inbounds i8, ptr %225, i64 8
  %227 = load i64, ptr %226, align 8, !tbaa !15
  %228 = add i64 %227, -1
  store i64 %228, ptr %226, align 8, !tbaa !15
  %229 = icmp eq i64 %227, 0
  br i1 %229, label %224, label %230, !llvm.loop !248

230:                                              ; preds = %224, %205
  %231 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef nonnull %189, i64 noundef %190, i32 noundef 62) #16
  %232 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %216, ptr noundef nonnull %216, ptr noundef %3, i64 noundef %190) #16
  %233 = getelementptr inbounds i64, ptr %216, i64 %165
  %234 = getelementptr inbounds i8, ptr %233, i64 -8
  %235 = add i64 %232, %231
  %236 = load i64, ptr %234, align 8, !tbaa !15
  %237 = sub i64 %236, %235
  store i64 %237, ptr %234, align 8, !tbaa !15
  %238 = icmp ult i64 %236, %235
  br i1 %238, label %239, label %245

239:                                              ; preds = %239, %230
  %240 = phi ptr [ %241, %239 ], [ %234, %230 ]
  %241 = getelementptr inbounds i8, ptr %240, i64 8
  %242 = load i64, ptr %241, align 8, !tbaa !15
  %243 = add i64 %242, -1
  store i64 %243, ptr %241, align 8, !tbaa !15
  %244 = icmp eq i64 %242, 0
  br i1 %244, label %239, label %245, !llvm.loop !249

245:                                              ; preds = %239, %230
  %246 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %2, ptr noundef nonnull %208, i64 noundef %11) #16
  %247 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %208, ptr noundef nonnull %208, ptr noundef %2, i64 noundef %11) #16
  %248 = getelementptr inbounds i64, ptr %4, i64 %5
  %249 = tail call i64 @__gmpn_lshift(ptr noundef %2, ptr noundef %0, i64 noundef %165, i32 noundef 42) #16
  %250 = tail call i64 @__gmpn_sub_n(ptr noundef %248, ptr noundef %248, ptr noundef %2, i64 noundef %165) #16
  %251 = getelementptr inbounds i64, ptr %4, i64 %10
  %252 = load i64, ptr %251, align 8, !tbaa !15
  %253 = add i64 %250, %249
  %254 = sub i64 %252, %253
  store i64 %254, ptr %251, align 8, !tbaa !15
  %255 = getelementptr inbounds i64, ptr %1, i64 %5
  %256 = load i64, ptr %0, align 8, !tbaa !15
  %257 = lshr i64 %256, 6
  %258 = load i64, ptr %255, align 8, !tbaa !15
  %259 = sub i64 %258, %257
  store i64 %259, ptr %255, align 8, !tbaa !15
  %260 = load i64, ptr %0, align 8, !tbaa !15
  %261 = lshr i64 %260, 6
  %262 = icmp ult i64 %258, %261
  br i1 %262, label %263, label %269

263:                                              ; preds = %263, %245
  %264 = phi ptr [ %265, %263 ], [ %255, %245 ]
  %265 = getelementptr inbounds i8, ptr %264, i64 8
  %266 = load i64, ptr %265, align 8, !tbaa !15
  %267 = add i64 %266, -1
  store i64 %267, ptr %265, align 8, !tbaa !15
  %268 = icmp eq i64 %266, 0
  br i1 %268, label %263, label %269, !llvm.loop !250

269:                                              ; preds = %263, %245
  %270 = tail call i64 @__gmpn_lshift(ptr noundef %2, ptr noundef nonnull %189, i64 noundef %190, i32 noundef 58) #16
  %271 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %255, ptr noundef nonnull %255, ptr noundef %2, i64 noundef %190) #16
  %272 = getelementptr inbounds i64, ptr %255, i64 %165
  %273 = getelementptr inbounds i8, ptr %272, i64 -8
  %274 = add i64 %271, %270
  %275 = load i64, ptr %273, align 8, !tbaa !15
  %276 = sub i64 %275, %274
  store i64 %276, ptr %273, align 8, !tbaa !15
  %277 = icmp ult i64 %275, %274
  br i1 %277, label %278, label %284

278:                                              ; preds = %278, %269
  %279 = phi ptr [ %280, %278 ], [ %273, %269 ]
  %280 = getelementptr inbounds i8, ptr %279, i64 8
  %281 = load i64, ptr %280, align 8, !tbaa !15
  %282 = add i64 %281, -1
  store i64 %282, ptr %280, align 8, !tbaa !15
  %283 = icmp eq i64 %281, 0
  br i1 %283, label %278, label %284, !llvm.loop !251

284:                                              ; preds = %278, %269
  %285 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %4, ptr noundef %1, i64 noundef %11) #16
  %286 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %4, i64 noundef %11) #16
  %287 = mul i64 %5, 56
  %288 = getelementptr inbounds i8, ptr %0, i64 %287
  %289 = getelementptr inbounds i64, ptr %288, i64 %5
  %290 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %289, ptr noundef nonnull %289, ptr noundef nonnull %0, i64 noundef %165) #16
  %291 = getelementptr inbounds i64, ptr %288, i64 %10
  %292 = load i64, ptr %291, align 8, !tbaa !15
  %293 = sub i64 %292, %290
  store i64 %293, ptr %291, align 8, !tbaa !15
  %294 = tail call i64 @__gmpn_submul_1(ptr noundef %8, ptr noundef nonnull %208, i64 noundef %11, i64 noundef 1028) #16
  %295 = tail call i64 @__gmpn_submul_1(ptr noundef %2, ptr noundef %8, i64 noundef %11, i64 noundef 1300) #16
  %296 = tail call i64 @__gmpn_submul_1(ptr noundef %2, ptr noundef nonnull %208, i64 noundef %11, i64 noundef 1052688) #16
  tail call void @__gmpn_divexact_1(ptr noundef %2, ptr noundef %2, i64 noundef %11, i64 noundef 48070897875) #16
  %297 = tail call i64 @__gmpn_submul_1(ptr noundef %8, ptr noundef %2, i64 noundef %11, i64 noundef 12567555) #16
  tail call void @__gmpn_divexact_1(ptr noundef %8, ptr noundef %8, i64 noundef %11, i64 noundef 181440) #16
  %298 = getelementptr inbounds i64, ptr %8, i64 %10
  %299 = load i64, ptr %298, align 8, !tbaa !15
  %300 = icmp ult i64 %299, 144115188075855872
  br i1 %300, label %303, label %301

301:                                              ; preds = %284
  %302 = or i64 %299, -288230376151711744
  store i64 %302, ptr %298, align 8, !tbaa !15
  br label %303

303:                                              ; preds = %301, %284
  %304 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %208, ptr noundef %2, i64 noundef %11, i64 noundef 4095) #16
  %305 = tail call i64 @__gmpn_addmul_1(ptr noundef nonnull %208, ptr noundef %8, i64 noundef %11, i64 noundef 240) #16
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %208, ptr noundef nonnull %208, i64 noundef %11, i64 noundef 1020) #16
  %306 = load i64, ptr %212, align 8, !tbaa !15
  %307 = icmp ult i64 %306, 2305843009213693952
  br i1 %307, label %310, label %308

308:                                              ; preds = %303
  %309 = or i64 %306, -4611686018427387904
  store i64 %309, ptr %212, align 8, !tbaa !15
  br label %310

310:                                              ; preds = %308, %303
  %311 = tail call i64 @__gmpn_lshift(ptr noundef %4, ptr noundef %288, i64 noundef %11, i32 noundef 7) #16
  %312 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %4, i64 noundef %11) #16
  %313 = tail call i64 @__gmpn_lshift(ptr noundef %4, ptr noundef %288, i64 noundef %11, i32 noundef 13) #16
  %314 = tail call i64 @__gmpn_sub_n(ptr noundef %173, ptr noundef %173, ptr noundef %4, i64 noundef %11) #16
  %315 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %173, ptr noundef %3, i64 noundef %11, i64 noundef 400) #16
  %316 = tail call i64 @__gmpn_lshift(ptr noundef %4, ptr noundef %288, i64 noundef %11, i32 noundef 19) #16
  %317 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %4, i64 noundef %11) #16
  %318 = tail call i64 @__gmpn_submul_1(ptr noundef %1, ptr noundef nonnull %173, i64 noundef %11, i64 noundef 1428) #16
  %319 = tail call i64 @__gmpn_submul_1(ptr noundef %1, ptr noundef %3, i64 noundef %11, i64 noundef 112896) #16
  tail call void @__gmpn_divexact_1(ptr noundef %1, ptr noundef %1, i64 noundef %11, i64 noundef 46591793325) #16
  %320 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %173, ptr noundef %1, i64 noundef %11, i64 noundef 15181425) #16
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %173, ptr noundef nonnull %173, i64 noundef %11, i64 noundef 680400) #16
  %321 = tail call i64 @__gmpn_submul_1(ptr noundef %3, ptr noundef %1, i64 noundef %11, i64 noundef 3969) #16
  %322 = tail call i64 @__gmpn_submul_1(ptr noundef %3, ptr noundef nonnull %173, i64 noundef %11, i64 noundef 900) #16
  tail call void @__gmpn_divexact_1(ptr noundef %3, ptr noundef %3, i64 noundef %11, i64 noundef 144) #16
  %323 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef %1, i64 noundef %11) #16
  %324 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef %3, i64 noundef %11) #16
  %325 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef nonnull %173, i64 noundef %11) #16
  %326 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %208, ptr noundef nonnull %173, ptr noundef nonnull %208, i64 noundef %11) #16
  %327 = tail call i64 @__gmpn_rshift(ptr noundef nonnull %208, ptr noundef nonnull %208, i64 noundef %11, i32 noundef 1) #16
  %328 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef nonnull %208, i64 noundef %11) #16
  %329 = tail call i64 @__gmpn_sub_n(ptr noundef %8, ptr noundef %3, ptr noundef %8, i64 noundef %11) #16
  %330 = tail call i64 @__gmpn_rshift(ptr noundef %8, ptr noundef %8, i64 noundef %11, i32 noundef 1) #16
  %331 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %8, i64 noundef %11) #16
  %332 = tail call i64 @__gmpn_add_n(ptr noundef %2, ptr noundef %1, ptr noundef %2, i64 noundef %11) #16
  %333 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %11, i32 noundef 1) #16
  %334 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %11) #16
  %335 = getelementptr inbounds i64, ptr %0, i64 %5
  %336 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %335, ptr noundef nonnull %335, ptr noundef %2, i64 noundef %5) #16
  %337 = getelementptr inbounds i64, ptr %0, i64 %165
  %338 = load i64, ptr %216, align 8, !tbaa !15
  %339 = add i64 %338, %336
  store i64 %339, ptr %337, align 8, !tbaa !15
  %340 = icmp ult i64 %339, %336
  br i1 %340, label %341, label %364

341:                                              ; preds = %310
  %342 = tail call i64 @llvm.smax.i64(i64 %5, i64 1)
  br label %343

343:                                              ; preds = %346, %341
  %344 = phi i64 [ %351, %346 ], [ 1, %341 ]
  %345 = icmp eq i64 %344, %342
  br i1 %345, label %375, label %346

346:                                              ; preds = %343
  %347 = getelementptr inbounds i64, ptr %216, i64 %344
  %348 = load i64, ptr %347, align 8, !tbaa !15
  %349 = add i64 %348, 1
  %350 = getelementptr inbounds i64, ptr %337, i64 %344
  store i64 %349, ptr %350, align 8, !tbaa !15
  %351 = add nuw i64 %344, 1
  %352 = icmp eq i64 %349, 0
  br i1 %352, label %343, label %353, !llvm.loop !252

353:                                              ; preds = %346
  %354 = icmp ne ptr %216, %337
  %355 = icmp slt i64 %351, %5
  %356 = select i1 %354, i1 %355, i1 false
  br i1 %356, label %357, label %375

357:                                              ; preds = %357, %353
  %358 = phi i64 [ %362, %357 ], [ %351, %353 ]
  %359 = getelementptr inbounds i64, ptr %216, i64 %358
  %360 = load i64, ptr %359, align 8, !tbaa !15
  %361 = getelementptr inbounds i64, ptr %337, i64 %358
  store i64 %360, ptr %361, align 8, !tbaa !15
  %362 = add nuw nsw i64 %358, 1
  %363 = icmp slt i64 %362, %5
  br i1 %363, label %357, label %375, !llvm.loop !253

364:                                              ; preds = %310
  %365 = icmp ne ptr %216, %337
  %366 = icmp sgt i64 %5, 1
  %367 = and i1 %366, %365
  br i1 %367, label %368, label %375

368:                                              ; preds = %368, %364
  %369 = phi i64 [ %373, %368 ], [ 1, %364 ]
  %370 = getelementptr inbounds i64, ptr %216, i64 %369
  %371 = load i64, ptr %370, align 8, !tbaa !15
  %372 = getelementptr inbounds i64, ptr %337, i64 %369
  store i64 %371, ptr %372, align 8, !tbaa !15
  %373 = add nuw nsw i64 %369, 1
  %374 = icmp eq i64 %373, %5
  br i1 %374, label %375, label %368, !llvm.loop !254

375:                                              ; preds = %368, %364, %357, %353, %343
  %376 = phi i64 [ 0, %353 ], [ 0, %364 ], [ 0, %357 ], [ 1, %343 ], [ 0, %368 ]
  %377 = getelementptr inbounds i64, ptr %2, i64 %165
  %378 = load i64, ptr %377, align 8, !tbaa !15
  %379 = add i64 %378, %376
  store i64 %379, ptr %377, align 8, !tbaa !15
  %380 = icmp ult i64 %379, %376
  br i1 %380, label %381, label %387

381:                                              ; preds = %381, %375
  %382 = phi ptr [ %383, %381 ], [ %377, %375 ]
  %383 = getelementptr inbounds i8, ptr %382, i64 8
  %384 = load i64, ptr %383, align 8, !tbaa !15
  %385 = add i64 %384, 1
  store i64 %385, ptr %383, align 8, !tbaa !15
  %386 = icmp eq i64 %385, 0
  br i1 %386, label %381, label %387, !llvm.loop !255

387:                                              ; preds = %381, %375
  %388 = getelementptr inbounds i64, ptr %2, i64 %10
  %389 = load i64, ptr %388, align 8, !tbaa !15
  %390 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %208, ptr noundef nonnull %208, ptr noundef nonnull %377, i64 noundef %5) #16
  %391 = shl nsw i64 %5, 5
  %392 = getelementptr inbounds i8, ptr %0, i64 %391
  %393 = add i64 %390, %389
  %394 = load i64, ptr %392, align 8, !tbaa !15
  %395 = add i64 %394, %393
  store i64 %395, ptr %392, align 8, !tbaa !15
  %396 = icmp ult i64 %395, %393
  br i1 %396, label %397, label %403

397:                                              ; preds = %397, %387
  %398 = phi ptr [ %399, %397 ], [ %392, %387 ]
  %399 = getelementptr inbounds i8, ptr %398, i64 8
  %400 = load i64, ptr %399, align 8, !tbaa !15
  %401 = add i64 %400, 1
  store i64 %401, ptr %399, align 8, !tbaa !15
  %402 = icmp eq i64 %401, 0
  br i1 %402, label %397, label %403, !llvm.loop !256

403:                                              ; preds = %397, %387
  %404 = mul i64 %5, 40
  %405 = getelementptr inbounds i8, ptr %0, i64 %404
  %406 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %405, ptr noundef nonnull %405, ptr noundef %8, i64 noundef %5) #16
  %407 = mul i64 %5, 48
  %408 = getelementptr inbounds i8, ptr %0, i64 %407
  %409 = load i64, ptr %408, align 8, !tbaa !15
  %410 = add i64 %409, %406
  store i64 %410, ptr %408, align 8, !tbaa !15
  %411 = getelementptr inbounds i64, ptr %8, i64 %5
  %412 = load i64, ptr %411, align 8, !tbaa !15
  %413 = add i64 %412, %410
  store i64 %413, ptr %408, align 8, !tbaa !15
  %414 = icmp ult i64 %413, %410
  br i1 %414, label %415, label %438

415:                                              ; preds = %403
  %416 = tail call i64 @llvm.smax.i64(i64 %5, i64 1)
  br label %417

417:                                              ; preds = %420, %415
  %418 = phi i64 [ %425, %420 ], [ 1, %415 ]
  %419 = icmp eq i64 %418, %416
  br i1 %419, label %449, label %420

420:                                              ; preds = %417
  %421 = getelementptr inbounds i64, ptr %411, i64 %418
  %422 = load i64, ptr %421, align 8, !tbaa !15
  %423 = add i64 %422, 1
  %424 = getelementptr inbounds i64, ptr %408, i64 %418
  store i64 %423, ptr %424, align 8, !tbaa !15
  %425 = add nuw i64 %418, 1
  %426 = icmp eq i64 %423, 0
  br i1 %426, label %417, label %427, !llvm.loop !252

427:                                              ; preds = %420
  %428 = icmp ne ptr %411, %408
  %429 = icmp slt i64 %425, %5
  %430 = select i1 %428, i1 %429, i1 false
  br i1 %430, label %431, label %449

431:                                              ; preds = %431, %427
  %432 = phi i64 [ %436, %431 ], [ %425, %427 ]
  %433 = getelementptr inbounds i64, ptr %411, i64 %432
  %434 = load i64, ptr %433, align 8, !tbaa !15
  %435 = getelementptr inbounds i64, ptr %408, i64 %432
  store i64 %434, ptr %435, align 8, !tbaa !15
  %436 = add nuw nsw i64 %432, 1
  %437 = icmp slt i64 %436, %5
  br i1 %437, label %431, label %449, !llvm.loop !253

438:                                              ; preds = %403
  %439 = icmp ne ptr %411, %408
  %440 = icmp sgt i64 %5, 1
  %441 = and i1 %440, %439
  br i1 %441, label %442, label %449

442:                                              ; preds = %442, %438
  %443 = phi i64 [ %447, %442 ], [ 1, %438 ]
  %444 = getelementptr inbounds i64, ptr %411, i64 %443
  %445 = load i64, ptr %444, align 8, !tbaa !15
  %446 = getelementptr inbounds i64, ptr %408, i64 %443
  store i64 %445, ptr %446, align 8, !tbaa !15
  %447 = add nuw nsw i64 %443, 1
  %448 = icmp eq i64 %447, %5
  br i1 %448, label %449, label %442, !llvm.loop !254

449:                                              ; preds = %442, %438, %431, %427, %417
  %450 = phi i64 [ 0, %427 ], [ 0, %438 ], [ 0, %431 ], [ 1, %417 ], [ 0, %442 ]
  %451 = getelementptr inbounds i64, ptr %8, i64 %165
  %452 = load i64, ptr %451, align 8, !tbaa !15
  %453 = add i64 %452, %450
  store i64 %453, ptr %451, align 8, !tbaa !15
  %454 = icmp ult i64 %453, %450
  br i1 %454, label %455, label %461

455:                                              ; preds = %455, %449
  %456 = phi ptr [ %457, %455 ], [ %451, %449 ]
  %457 = getelementptr inbounds i8, ptr %456, i64 8
  %458 = load i64, ptr %457, align 8, !tbaa !15
  %459 = add i64 %458, 1
  store i64 %459, ptr %457, align 8, !tbaa !15
  %460 = icmp eq i64 %459, 0
  br i1 %460, label %455, label %461, !llvm.loop !257

461:                                              ; preds = %455, %449
  %462 = load i64, ptr %298, align 8, !tbaa !15
  %463 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef nonnull %451, i64 noundef %5) #16
  %464 = shl nsw i64 %5, 6
  %465 = getelementptr inbounds i8, ptr %0, i64 %464
  %466 = add i64 %463, %462
  %467 = load i64, ptr %465, align 8, !tbaa !15
  %468 = add i64 %467, %466
  store i64 %468, ptr %465, align 8, !tbaa !15
  %469 = icmp ult i64 %468, %466
  br i1 %469, label %470, label %476

470:                                              ; preds = %470, %461
  %471 = phi ptr [ %472, %470 ], [ %465, %461 ]
  %472 = getelementptr inbounds i8, ptr %471, i64 8
  %473 = load i64, ptr %472, align 8, !tbaa !15
  %474 = add i64 %473, 1
  store i64 %474, ptr %472, align 8, !tbaa !15
  %475 = icmp eq i64 %474, 0
  br i1 %475, label %470, label %476, !llvm.loop !258

476:                                              ; preds = %470, %461
  %477 = mul i64 %5, 72
  %478 = getelementptr inbounds i8, ptr %0, i64 %477
  %479 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %478, ptr noundef nonnull %478, ptr noundef %3, i64 noundef %5) #16
  %480 = mul i64 %5, 80
  %481 = getelementptr inbounds i8, ptr %0, i64 %480
  %482 = load i64, ptr %481, align 8, !tbaa !15
  %483 = add i64 %482, %479
  store i64 %483, ptr %481, align 8, !tbaa !15
  %484 = load i64, ptr %164, align 8, !tbaa !15
  %485 = add i64 %484, %483
  store i64 %485, ptr %481, align 8, !tbaa !15
  %486 = icmp ult i64 %485, %483
  br i1 %486, label %487, label %510

487:                                              ; preds = %476
  %488 = tail call i64 @llvm.smax.i64(i64 %5, i64 1)
  br label %489

489:                                              ; preds = %492, %487
  %490 = phi i64 [ %497, %492 ], [ 1, %487 ]
  %491 = icmp eq i64 %490, %488
  br i1 %491, label %521, label %492

492:                                              ; preds = %489
  %493 = getelementptr inbounds i64, ptr %164, i64 %490
  %494 = load i64, ptr %493, align 8, !tbaa !15
  %495 = add i64 %494, 1
  %496 = getelementptr inbounds i64, ptr %481, i64 %490
  store i64 %495, ptr %496, align 8, !tbaa !15
  %497 = add nuw i64 %490, 1
  %498 = icmp eq i64 %495, 0
  br i1 %498, label %489, label %499, !llvm.loop !252

499:                                              ; preds = %492
  %500 = icmp ne ptr %164, %481
  %501 = icmp slt i64 %497, %5
  %502 = select i1 %500, i1 %501, i1 false
  br i1 %502, label %503, label %521

503:                                              ; preds = %503, %499
  %504 = phi i64 [ %508, %503 ], [ %497, %499 ]
  %505 = getelementptr inbounds i64, ptr %164, i64 %504
  %506 = load i64, ptr %505, align 8, !tbaa !15
  %507 = getelementptr inbounds i64, ptr %481, i64 %504
  store i64 %506, ptr %507, align 8, !tbaa !15
  %508 = add nuw nsw i64 %504, 1
  %509 = icmp slt i64 %508, %5
  br i1 %509, label %503, label %521, !llvm.loop !253

510:                                              ; preds = %476
  %511 = icmp ne ptr %164, %481
  %512 = icmp sgt i64 %5, 1
  %513 = and i1 %512, %511
  br i1 %513, label %514, label %521

514:                                              ; preds = %514, %510
  %515 = phi i64 [ %519, %514 ], [ 1, %510 ]
  %516 = getelementptr inbounds i64, ptr %164, i64 %515
  %517 = load i64, ptr %516, align 8, !tbaa !15
  %518 = getelementptr inbounds i64, ptr %481, i64 %515
  store i64 %517, ptr %518, align 8, !tbaa !15
  %519 = add nuw nsw i64 %515, 1
  %520 = icmp eq i64 %519, %5
  br i1 %520, label %521, label %514, !llvm.loop !254

521:                                              ; preds = %514, %510, %503, %499, %489
  %522 = phi i64 [ 0, %499 ], [ 0, %510 ], [ 0, %503 ], [ 1, %489 ], [ 0, %514 ]
  %523 = getelementptr inbounds i64, ptr %3, i64 %165
  %524 = load i64, ptr %523, align 8, !tbaa !15
  %525 = add i64 %524, %522
  store i64 %525, ptr %523, align 8, !tbaa !15
  %526 = icmp ult i64 %525, %522
  br i1 %526, label %527, label %533

527:                                              ; preds = %527, %521
  %528 = phi ptr [ %529, %527 ], [ %523, %521 ]
  %529 = getelementptr inbounds i8, ptr %528, i64 8
  %530 = load i64, ptr %529, align 8, !tbaa !15
  %531 = add i64 %530, 1
  store i64 %531, ptr %529, align 8, !tbaa !15
  %532 = icmp eq i64 %531, 0
  br i1 %532, label %527, label %533, !llvm.loop !259

533:                                              ; preds = %527, %521
  %534 = load i64, ptr %168, align 8, !tbaa !15
  %535 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef nonnull %523, i64 noundef %5) #16
  %536 = mul i64 %5, 96
  %537 = getelementptr inbounds i8, ptr %0, i64 %536
  %538 = add i64 %535, %534
  %539 = load i64, ptr %537, align 8, !tbaa !15
  %540 = add i64 %539, %538
  store i64 %540, ptr %537, align 8, !tbaa !15
  %541 = icmp ult i64 %540, %538
  br i1 %541, label %542, label %548

542:                                              ; preds = %542, %533
  %543 = phi ptr [ %544, %542 ], [ %537, %533 ]
  %544 = getelementptr inbounds i8, ptr %543, i64 8
  %545 = load i64, ptr %544, align 8, !tbaa !15
  %546 = add i64 %545, 1
  store i64 %546, ptr %544, align 8, !tbaa !15
  %547 = icmp eq i64 %546, 0
  br i1 %547, label %542, label %548, !llvm.loop !260

548:                                              ; preds = %542, %533
  %549 = mul i64 %5, 104
  %550 = getelementptr inbounds i8, ptr %0, i64 %549
  %551 = tail call i64 @__gmpn_add_n(ptr noundef %550, ptr noundef %550, ptr noundef %1, i64 noundef %5) #16
  %552 = mul i64 %5, 112
  %553 = getelementptr inbounds i8, ptr %0, i64 %552
  %554 = load i64, ptr %553, align 8, !tbaa !15
  %555 = add i64 %554, %551
  store i64 %555, ptr %553, align 8, !tbaa !15
  %556 = load i64, ptr %255, align 8, !tbaa !15
  %557 = add i64 %556, %555
  store i64 %557, ptr %553, align 8, !tbaa !15
  %558 = icmp ult i64 %557, %555
  br i1 %12, label %630, label %559

559:                                              ; preds = %548
  br i1 %558, label %560, label %583

560:                                              ; preds = %559
  %561 = tail call i64 @llvm.smax.i64(i64 %5, i64 1)
  br label %562

562:                                              ; preds = %565, %560
  %563 = phi i64 [ %570, %565 ], [ 1, %560 ]
  %564 = icmp eq i64 %563, %561
  br i1 %564, label %594, label %565

565:                                              ; preds = %562
  %566 = getelementptr inbounds i64, ptr %255, i64 %563
  %567 = load i64, ptr %566, align 8, !tbaa !15
  %568 = add i64 %567, 1
  %569 = getelementptr inbounds i64, ptr %553, i64 %563
  store i64 %568, ptr %569, align 8, !tbaa !15
  %570 = add nuw i64 %563, 1
  %571 = icmp eq i64 %568, 0
  br i1 %571, label %562, label %572, !llvm.loop !252

572:                                              ; preds = %565
  %573 = icmp ne ptr %255, %553
  %574 = icmp slt i64 %570, %5
  %575 = select i1 %573, i1 %574, i1 false
  br i1 %575, label %576, label %594

576:                                              ; preds = %576, %572
  %577 = phi i64 [ %581, %576 ], [ %570, %572 ]
  %578 = getelementptr inbounds i64, ptr %255, i64 %577
  %579 = load i64, ptr %578, align 8, !tbaa !15
  %580 = getelementptr inbounds i64, ptr %553, i64 %577
  store i64 %579, ptr %580, align 8, !tbaa !15
  %581 = add nuw nsw i64 %577, 1
  %582 = icmp slt i64 %581, %5
  br i1 %582, label %576, label %594, !llvm.loop !253

583:                                              ; preds = %559
  %584 = icmp ne ptr %255, %553
  %585 = icmp sgt i64 %5, 1
  %586 = and i1 %585, %584
  br i1 %586, label %587, label %594

587:                                              ; preds = %587, %583
  %588 = phi i64 [ %592, %587 ], [ 1, %583 ]
  %589 = getelementptr inbounds i64, ptr %255, i64 %588
  %590 = load i64, ptr %589, align 8, !tbaa !15
  %591 = getelementptr inbounds i64, ptr %553, i64 %588
  store i64 %590, ptr %591, align 8, !tbaa !15
  %592 = add nuw nsw i64 %588, 1
  %593 = icmp eq i64 %592, %5
  br i1 %593, label %594, label %587, !llvm.loop !254

594:                                              ; preds = %587, %583, %576, %572, %562
  %595 = phi i64 [ 0, %572 ], [ 0, %583 ], [ 0, %576 ], [ 1, %562 ], [ 0, %587 ]
  %596 = getelementptr inbounds i64, ptr %1, i64 %165
  %597 = load i64, ptr %596, align 8, !tbaa !15
  %598 = add i64 %597, %595
  store i64 %598, ptr %596, align 8, !tbaa !15
  %599 = icmp ult i64 %598, %595
  br i1 %599, label %600, label %606

600:                                              ; preds = %600, %594
  %601 = phi ptr [ %602, %600 ], [ %596, %594 ]
  %602 = getelementptr inbounds i8, ptr %601, i64 8
  %603 = load i64, ptr %602, align 8, !tbaa !15
  %604 = add i64 %603, 1
  store i64 %604, ptr %602, align 8, !tbaa !15
  %605 = icmp eq i64 %604, 0
  br i1 %605, label %600, label %606, !llvm.loop !261

606:                                              ; preds = %600, %594
  %607 = icmp sgt i64 %6, %5
  br i1 %607, label %608, label %626, !prof !68

608:                                              ; preds = %606
  %609 = getelementptr inbounds i64, ptr %1, i64 %10
  %610 = load i64, ptr %609, align 8, !tbaa !15
  %611 = mul i64 %5, 120
  %612 = getelementptr inbounds i8, ptr %0, i64 %611
  %613 = tail call i64 @__gmpn_add_n(ptr noundef %612, ptr noundef %612, ptr noundef nonnull %596, i64 noundef %5) #16
  %614 = shl nsw i64 %5, 7
  %615 = getelementptr inbounds i8, ptr %0, i64 %614
  %616 = add i64 %613, %610
  %617 = load i64, ptr %615, align 8, !tbaa !15
  %618 = add i64 %617, %616
  store i64 %618, ptr %615, align 8, !tbaa !15
  %619 = icmp ult i64 %618, %616
  br i1 %619, label %620, label %665

620:                                              ; preds = %620, %608
  %621 = phi ptr [ %622, %620 ], [ %615, %608 ]
  %622 = getelementptr inbounds i8, ptr %621, i64 8
  %623 = load i64, ptr %622, align 8, !tbaa !15
  %624 = add i64 %623, 1
  store i64 %624, ptr %622, align 8, !tbaa !15
  %625 = icmp eq i64 %624, 0
  br i1 %625, label %620, label %665, !llvm.loop !262

626:                                              ; preds = %606
  %627 = mul i64 %5, 120
  %628 = getelementptr inbounds i8, ptr %0, i64 %627
  %629 = tail call i64 @__gmpn_add_n(ptr noundef %628, ptr noundef %628, ptr noundef nonnull %596, i64 noundef %6) #16
  br label %665

630:                                              ; preds = %548
  br i1 %558, label %631, label %654

631:                                              ; preds = %630
  %632 = tail call i64 @llvm.smax.i64(i64 %6, i64 1)
  br label %633

633:                                              ; preds = %636, %631
  %634 = phi i64 [ %641, %636 ], [ 1, %631 ]
  %635 = icmp eq i64 %634, %632
  br i1 %635, label %665, label %636

636:                                              ; preds = %633
  %637 = getelementptr inbounds i64, ptr %255, i64 %634
  %638 = load i64, ptr %637, align 8, !tbaa !15
  %639 = add i64 %638, 1
  %640 = getelementptr inbounds i64, ptr %553, i64 %634
  store i64 %639, ptr %640, align 8, !tbaa !15
  %641 = add nuw i64 %634, 1
  %642 = icmp eq i64 %639, 0
  br i1 %642, label %633, label %643, !llvm.loop !252

643:                                              ; preds = %636
  %644 = icmp ne ptr %255, %553
  %645 = icmp slt i64 %641, %6
  %646 = select i1 %644, i1 %645, i1 false
  br i1 %646, label %647, label %665

647:                                              ; preds = %647, %643
  %648 = phi i64 [ %652, %647 ], [ %641, %643 ]
  %649 = getelementptr inbounds i64, ptr %255, i64 %648
  %650 = load i64, ptr %649, align 8, !tbaa !15
  %651 = getelementptr inbounds i64, ptr %553, i64 %648
  store i64 %650, ptr %651, align 8, !tbaa !15
  %652 = add nuw nsw i64 %648, 1
  %653 = icmp slt i64 %652, %6
  br i1 %653, label %647, label %665, !llvm.loop !253

654:                                              ; preds = %630
  %655 = icmp ne ptr %255, %553
  %656 = icmp sgt i64 %6, 1
  %657 = and i1 %656, %655
  br i1 %657, label %658, label %665

658:                                              ; preds = %658, %654
  %659 = phi i64 [ %663, %658 ], [ 1, %654 ]
  %660 = getelementptr inbounds i64, ptr %255, i64 %659
  %661 = load i64, ptr %660, align 8, !tbaa !15
  %662 = getelementptr inbounds i64, ptr %553, i64 %659
  store i64 %661, ptr %662, align 8, !tbaa !15
  %663 = add nuw nsw i64 %659, 1
  %664 = icmp eq i64 %663, %6
  br i1 %664, label %665, label %658, !llvm.loop !254

665:                                              ; preds = %658, %654, %647, %643, %633, %626, %620, %608
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_submul_1(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #6 {
  %5 = lshr i64 %3, 32
  %6 = and i64 %3, 4294967295
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %39, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %41, %7 ]
  %10 = phi ptr [ %1, %4 ], [ %12, %7 ]
  %11 = phi ptr [ %0, %4 ], [ %40, %7 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 8
  %13 = load i64, ptr %10, align 8, !tbaa !15
  %14 = lshr i64 %13, 32
  %15 = and i64 %13, 4294967295
  %16 = mul nuw i64 %15, %6
  %17 = mul nuw i64 %15, %5
  %18 = mul nuw i64 %14, %6
  %19 = mul nuw i64 %14, %5
  %20 = lshr i64 %16, 32
  %21 = add i64 %18, %17
  %22 = add i64 %21, %20
  %23 = icmp ult i64 %22, %18
  %24 = add nuw i64 %19, 4294967296
  %25 = select i1 %23, i64 %24, i64 %19
  %26 = lshr i64 %22, 32
  %27 = add i64 %25, %26
  %28 = shl i64 %22, 32
  %29 = and i64 %16, 4294967295
  %30 = or disjoint i64 %28, %29
  %31 = load i64, ptr %11, align 8, !tbaa !15
  %32 = sub i64 %31, %30
  %33 = icmp ult i64 %31, %30
  %34 = zext i1 %33 to i64
  %35 = add i64 %27, %34
  %36 = sub i64 %32, %8
  %37 = icmp ult i64 %32, %8
  %38 = zext i1 %37 to i64
  %39 = add i64 %35, %38
  %40 = getelementptr inbounds i8, ptr %11, i64 8
  store i64 %36, ptr %11, align 8, !tbaa !15
  %41 = add nsw i64 %9, -1
  %42 = icmp eq i64 %41, 0
  br i1 %42, label %43, label %7, !llvm.loop !263

43:                                               ; preds = %7
  ret i64 %39
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_addmul_1(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #6 {
  %5 = lshr i64 %3, 32
  %6 = and i64 %3, 4294967295
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %39, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %41, %7 ]
  %10 = phi ptr [ %1, %4 ], [ %12, %7 ]
  %11 = phi ptr [ %0, %4 ], [ %40, %7 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 8
  %13 = load i64, ptr %10, align 8, !tbaa !15
  %14 = lshr i64 %13, 32
  %15 = and i64 %13, 4294967295
  %16 = mul nuw i64 %15, %6
  %17 = mul nuw i64 %15, %5
  %18 = mul nuw i64 %14, %6
  %19 = mul nuw i64 %14, %5
  %20 = lshr i64 %16, 32
  %21 = add i64 %18, %17
  %22 = add i64 %21, %20
  %23 = icmp ult i64 %22, %18
  %24 = add nuw i64 %19, 4294967296
  %25 = select i1 %23, i64 %24, i64 %19
  %26 = lshr i64 %22, 32
  %27 = add i64 %25, %26
  %28 = shl i64 %22, 32
  %29 = and i64 %16, 4294967295
  %30 = load i64, ptr %11, align 8, !tbaa !15
  %31 = add i64 %29, %30
  %32 = add i64 %31, %28
  %33 = icmp ugt i64 %30, %32
  %34 = zext i1 %33 to i64
  %35 = add i64 %27, %34
  %36 = add i64 %32, %8
  %37 = icmp ugt i64 %32, %36
  %38 = zext i1 %37 to i64
  %39 = add i64 %35, %38
  %40 = getelementptr inbounds i8, ptr %11, i64 8
  store i64 %36, ptr %11, align 8, !tbaa !15
  %41 = add nsw i64 %9, -1
  %42 = icmp eq i64 %41, 0
  br i1 %42, label %43, label %7, !llvm.loop !264

43:                                               ; preds = %7
  ret i64 %39
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_12pts(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, i32 noundef %6, ptr noundef %7) local_unnamed_addr #5 {
  %9 = mul nsw i64 %4, 3
  %10 = add nsw i64 %9, 1
  %11 = icmp eq i32 %6, 0
  br i1 %11, label %117, label %12

12:                                               ; preds = %8
  %13 = mul i64 %4, 88
  %14 = getelementptr inbounds i8, ptr %0, i64 %13
  %15 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %14, i64 noundef %5) #16
  %16 = getelementptr inbounds i64, ptr %2, i64 %5
  %17 = load i64, ptr %16, align 8, !tbaa !15
  %18 = sub i64 %17, %15
  store i64 %18, ptr %16, align 8, !tbaa !15
  %19 = icmp ult i64 %17, %15
  br i1 %19, label %20, label %26

20:                                               ; preds = %20, %12
  %21 = phi ptr [ %22, %20 ], [ %16, %12 ]
  %22 = getelementptr inbounds i8, ptr %21, i64 8
  %23 = load i64, ptr %22, align 8, !tbaa !15
  %24 = add i64 %23, -1
  store i64 %24, ptr %22, align 8, !tbaa !15
  %25 = icmp eq i64 %23, 0
  br i1 %25, label %20, label %26, !llvm.loop !265

26:                                               ; preds = %20, %12
  %27 = mul i64 %4, 56
  %28 = getelementptr inbounds i8, ptr %0, i64 %27
  %29 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %14, i64 noundef %5, i32 noundef 10) #16
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef %28, ptr noundef %28, ptr noundef %7, i64 noundef %5) #16
  %31 = getelementptr inbounds i64, ptr %28, i64 %5
  %32 = add i64 %30, %29
  %33 = load i64, ptr %31, align 8, !tbaa !15
  %34 = sub i64 %33, %32
  store i64 %34, ptr %31, align 8, !tbaa !15
  %35 = icmp ult i64 %33, %32
  br i1 %35, label %36, label %42

36:                                               ; preds = %36, %26
  %37 = phi ptr [ %38, %36 ], [ %31, %26 ]
  %38 = getelementptr inbounds i8, ptr %37, i64 8
  %39 = load i64, ptr %38, align 8, !tbaa !15
  %40 = add i64 %39, -1
  store i64 %40, ptr %38, align 8, !tbaa !15
  %41 = icmp eq i64 %39, 0
  br i1 %41, label %36, label %42, !llvm.loop !266

42:                                               ; preds = %36, %26
  %43 = load i64, ptr %14, align 8, !tbaa !15
  %44 = lshr i64 %43, 2
  %45 = load i64, ptr %3, align 8, !tbaa !15
  %46 = sub i64 %45, %44
  store i64 %46, ptr %3, align 8, !tbaa !15
  %47 = load i64, ptr %14, align 8, !tbaa !15
  %48 = lshr i64 %47, 2
  %49 = icmp ult i64 %45, %48
  br i1 %49, label %50, label %56

50:                                               ; preds = %50, %42
  %51 = phi ptr [ %52, %50 ], [ %3, %42 ]
  %52 = getelementptr inbounds i8, ptr %51, i64 8
  %53 = load i64, ptr %52, align 8, !tbaa !15
  %54 = add i64 %53, -1
  store i64 %54, ptr %52, align 8, !tbaa !15
  %55 = icmp eq i64 %53, 0
  br i1 %55, label %50, label %56, !llvm.loop !267

56:                                               ; preds = %50, %42
  %57 = getelementptr inbounds i8, ptr %14, i64 8
  %58 = add nsw i64 %5, -1
  %59 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %57, i64 noundef %58, i32 noundef 62) #16
  %60 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %3, ptr noundef nonnull %3, ptr noundef %7, i64 noundef %58) #16
  %61 = getelementptr inbounds i64, ptr %3, i64 %5
  %62 = getelementptr inbounds i8, ptr %61, i64 -8
  %63 = add i64 %60, %59
  %64 = load i64, ptr %62, align 8, !tbaa !15
  %65 = sub i64 %64, %63
  store i64 %65, ptr %62, align 8, !tbaa !15
  %66 = icmp ult i64 %64, %63
  br i1 %66, label %67, label %73

67:                                               ; preds = %67, %56
  %68 = phi ptr [ %69, %67 ], [ %62, %56 ]
  %69 = getelementptr inbounds i8, ptr %68, i64 8
  %70 = load i64, ptr %69, align 8, !tbaa !15
  %71 = add i64 %70, -1
  store i64 %71, ptr %69, align 8, !tbaa !15
  %72 = icmp eq i64 %70, 0
  br i1 %72, label %67, label %73, !llvm.loop !268

73:                                               ; preds = %67, %56
  %74 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %14, i64 noundef %5, i32 noundef 20) #16
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %7, i64 noundef %5) #16
  %76 = getelementptr inbounds i64, ptr %1, i64 %5
  %77 = add i64 %75, %74
  %78 = load i64, ptr %76, align 8, !tbaa !15
  %79 = sub i64 %78, %77
  store i64 %79, ptr %76, align 8, !tbaa !15
  %80 = icmp ult i64 %78, %77
  br i1 %80, label %81, label %87

81:                                               ; preds = %81, %73
  %82 = phi ptr [ %83, %81 ], [ %76, %73 ]
  %83 = getelementptr inbounds i8, ptr %82, i64 8
  %84 = load i64, ptr %83, align 8, !tbaa !15
  %85 = add i64 %84, -1
  store i64 %85, ptr %83, align 8, !tbaa !15
  %86 = icmp eq i64 %84, 0
  br i1 %86, label %81, label %87, !llvm.loop !269

87:                                               ; preds = %81, %73
  %88 = getelementptr inbounds i64, ptr %0, i64 %9
  %89 = load i64, ptr %14, align 8, !tbaa !15
  %90 = lshr i64 %89, 4
  %91 = load i64, ptr %88, align 8, !tbaa !15
  %92 = sub i64 %91, %90
  store i64 %92, ptr %88, align 8, !tbaa !15
  %93 = load i64, ptr %14, align 8, !tbaa !15
  %94 = lshr i64 %93, 4
  %95 = icmp ult i64 %91, %94
  br i1 %95, label %96, label %102

96:                                               ; preds = %96, %87
  %97 = phi ptr [ %98, %96 ], [ %88, %87 ]
  %98 = getelementptr inbounds i8, ptr %97, i64 8
  %99 = load i64, ptr %98, align 8, !tbaa !15
  %100 = add i64 %99, -1
  store i64 %100, ptr %98, align 8, !tbaa !15
  %101 = icmp eq i64 %99, 0
  br i1 %101, label %96, label %102, !llvm.loop !270

102:                                              ; preds = %96, %87
  %103 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %57, i64 noundef %58, i32 noundef 60) #16
  %104 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %88, ptr noundef nonnull %88, ptr noundef %7, i64 noundef %58) #16
  %105 = getelementptr inbounds i64, ptr %88, i64 %5
  %106 = getelementptr inbounds i8, ptr %105, i64 -8
  %107 = add i64 %104, %103
  %108 = load i64, ptr %106, align 8, !tbaa !15
  %109 = sub i64 %108, %107
  store i64 %109, ptr %106, align 8, !tbaa !15
  %110 = icmp ult i64 %108, %107
  br i1 %110, label %111, label %117

111:                                              ; preds = %111, %102
  %112 = phi ptr [ %113, %111 ], [ %106, %102 ]
  %113 = getelementptr inbounds i8, ptr %112, i64 8
  %114 = load i64, ptr %113, align 8, !tbaa !15
  %115 = add i64 %114, -1
  store i64 %115, ptr %113, align 8, !tbaa !15
  %116 = icmp eq i64 %114, 0
  br i1 %116, label %111, label %117, !llvm.loop !271

117:                                              ; preds = %111, %102, %8
  %118 = getelementptr inbounds i64, ptr %0, i64 %9
  %119 = getelementptr inbounds i64, ptr %118, i64 %4
  %120 = shl nsw i64 %4, 1
  %121 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %0, i64 noundef %120, i32 noundef 20) #16
  %122 = tail call i64 @__gmpn_sub_n(ptr noundef %119, ptr noundef %119, ptr noundef %7, i64 noundef %120) #16
  %123 = getelementptr inbounds i64, ptr %118, i64 %9
  %124 = load i64, ptr %123, align 8, !tbaa !15
  %125 = add i64 %122, %121
  %126 = sub i64 %124, %125
  store i64 %126, ptr %123, align 8, !tbaa !15
  %127 = getelementptr inbounds i64, ptr %1, i64 %4
  %128 = load i64, ptr %0, align 8, !tbaa !15
  %129 = lshr i64 %128, 4
  %130 = load i64, ptr %127, align 8, !tbaa !15
  %131 = sub i64 %130, %129
  store i64 %131, ptr %127, align 8, !tbaa !15
  %132 = load i64, ptr %0, align 8, !tbaa !15
  %133 = lshr i64 %132, 4
  %134 = icmp ult i64 %130, %133
  br i1 %134, label %135, label %141

135:                                              ; preds = %135, %117
  %136 = phi ptr [ %137, %135 ], [ %127, %117 ]
  %137 = getelementptr inbounds i8, ptr %136, i64 8
  %138 = load i64, ptr %137, align 8, !tbaa !15
  %139 = add i64 %138, -1
  store i64 %139, ptr %137, align 8, !tbaa !15
  %140 = icmp eq i64 %138, 0
  br i1 %140, label %135, label %141, !llvm.loop !272

141:                                              ; preds = %135, %117
  %142 = getelementptr inbounds i8, ptr %0, i64 8
  %143 = add nsw i64 %120, -1
  %144 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %142, i64 noundef %143, i32 noundef 60) #16
  %145 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %127, ptr noundef nonnull %127, ptr noundef %7, i64 noundef %143) #16
  %146 = getelementptr inbounds i64, ptr %127, i64 %120
  %147 = getelementptr inbounds i8, ptr %146, i64 -8
  %148 = add i64 %145, %144
  %149 = load i64, ptr %147, align 8, !tbaa !15
  %150 = sub i64 %149, %148
  store i64 %150, ptr %147, align 8, !tbaa !15
  %151 = icmp ult i64 %149, %148
  br i1 %151, label %152, label %158

152:                                              ; preds = %152, %141
  %153 = phi ptr [ %154, %152 ], [ %147, %141 ]
  %154 = getelementptr inbounds i8, ptr %153, i64 8
  %155 = load i64, ptr %154, align 8, !tbaa !15
  %156 = add i64 %155, -1
  store i64 %156, ptr %154, align 8, !tbaa !15
  %157 = icmp eq i64 %155, 0
  br i1 %157, label %152, label %158, !llvm.loop !273

158:                                              ; preds = %152, %141
  %159 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %1, ptr noundef nonnull %118, i64 noundef %10) #16
  %160 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %118, ptr noundef nonnull %118, ptr noundef %1, i64 noundef %10) #16
  %161 = getelementptr inbounds i64, ptr %3, i64 %4
  %162 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef nonnull %0, i64 noundef %120, i32 noundef 10) #16
  %163 = tail call i64 @__gmpn_sub_n(ptr noundef %161, ptr noundef %161, ptr noundef %1, i64 noundef %120) #16
  %164 = getelementptr inbounds i64, ptr %3, i64 %9
  %165 = load i64, ptr %164, align 8, !tbaa !15
  %166 = add i64 %163, %162
  %167 = sub i64 %165, %166
  store i64 %167, ptr %164, align 8, !tbaa !15
  %168 = mul i64 %4, 56
  %169 = getelementptr inbounds i8, ptr %0, i64 %168
  %170 = getelementptr inbounds i64, ptr %169, i64 %4
  %171 = load i64, ptr %0, align 8, !tbaa !15
  %172 = lshr i64 %171, 2
  %173 = load i64, ptr %170, align 8, !tbaa !15
  %174 = sub i64 %173, %172
  store i64 %174, ptr %170, align 8, !tbaa !15
  %175 = load i64, ptr %0, align 8, !tbaa !15
  %176 = lshr i64 %175, 2
  %177 = icmp ult i64 %173, %176
  br i1 %177, label %178, label %184

178:                                              ; preds = %178, %158
  %179 = phi ptr [ %180, %178 ], [ %170, %158 ]
  %180 = getelementptr inbounds i8, ptr %179, i64 8
  %181 = load i64, ptr %180, align 8, !tbaa !15
  %182 = add i64 %181, -1
  store i64 %182, ptr %180, align 8, !tbaa !15
  %183 = icmp eq i64 %181, 0
  br i1 %183, label %178, label %184, !llvm.loop !274

184:                                              ; preds = %178, %158
  %185 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef nonnull %142, i64 noundef %143, i32 noundef 62) #16
  %186 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %170, ptr noundef nonnull %170, ptr noundef %1, i64 noundef %143) #16
  %187 = getelementptr inbounds i64, ptr %170, i64 %120
  %188 = getelementptr inbounds i8, ptr %187, i64 -8
  %189 = add i64 %186, %185
  %190 = load i64, ptr %188, align 8, !tbaa !15
  %191 = sub i64 %190, %189
  store i64 %191, ptr %188, align 8, !tbaa !15
  %192 = icmp ult i64 %190, %189
  br i1 %192, label %193, label %199

193:                                              ; preds = %193, %184
  %194 = phi ptr [ %195, %193 ], [ %188, %184 ]
  %195 = getelementptr inbounds i8, ptr %194, i64 8
  %196 = load i64, ptr %195, align 8, !tbaa !15
  %197 = add i64 %196, -1
  store i64 %197, ptr %195, align 8, !tbaa !15
  %198 = icmp eq i64 %196, 0
  br i1 %198, label %193, label %199, !llvm.loop !275

199:                                              ; preds = %193, %184
  %200 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %3, ptr noundef nonnull %169, i64 noundef %10) #16
  %201 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef %3, i64 noundef %10) #16
  %202 = getelementptr inbounds i64, ptr %2, i64 %4
  %203 = tail call i64 @__gmpn_sub_n(ptr noundef %202, ptr noundef %202, ptr noundef nonnull %0, i64 noundef %120) #16
  %204 = getelementptr inbounds i64, ptr %2, i64 %9
  %205 = load i64, ptr %204, align 8, !tbaa !15
  %206 = sub i64 %205, %203
  store i64 %206, ptr %204, align 8, !tbaa !15
  %207 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %118, ptr noundef %1, i64 noundef %10, i64 noundef 257) #16
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %118, ptr noundef nonnull %118, i64 noundef %10, i64 noundef 11340) #16
  %208 = load i64, ptr %123, align 8, !tbaa !15
  %209 = icmp ult i64 %208, 2305843009213693952
  br i1 %209, label %212, label %210

210:                                              ; preds = %199
  %211 = or i64 %208, -4611686018427387904
  store i64 %211, ptr %123, align 8, !tbaa !15
  br label %212

212:                                              ; preds = %210, %199
  %213 = tail call i64 @__gmpn_addmul_1(ptr noundef %1, ptr noundef nonnull %118, i64 noundef %10, i64 noundef 60) #16
  %214 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %1, ptr noundef %1, i64 noundef %10, i64 noundef 72340172838076673, i64 noundef 0) #16
  %215 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %2, i64 noundef %10, i32 noundef 5) #16
  %216 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef %3, i64 noundef %10) #16
  %217 = tail call i64 @__gmpn_submul_1(ptr noundef %7, ptr noundef nonnull %169, i64 noundef %10, i64 noundef 100) #16
  %218 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %2, i64 noundef %10, i32 noundef 9) #16
  %219 = tail call i64 @__gmpn_sub_n(ptr noundef %7, ptr noundef %7, ptr noundef %3, i64 noundef %10) #16
  tail call void @__gmpn_divexact_1(ptr noundef %7, ptr noundef %7, i64 noundef %10, i64 noundef 42525) #16
  %220 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %169, ptr noundef %7, i64 noundef %10, i64 noundef 225) #16
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %169, ptr noundef nonnull %169, i64 noundef %10, i64 noundef 36) #16
  %221 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef nonnull %169, i64 noundef %10) #16
  %222 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %118, ptr noundef nonnull %169, ptr noundef nonnull %118, i64 noundef %10) #16
  %223 = tail call i64 @__gmpn_rshift(ptr noundef nonnull %118, ptr noundef nonnull %118, i64 noundef %10, i32 noundef 1) #16
  %224 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef nonnull %118, i64 noundef %10) #16
  %225 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %7, i64 noundef %10) #16
  %226 = tail call i64 @__gmpn_rshift(ptr noundef %1, ptr noundef %1, i64 noundef %10, i32 noundef 1) #16
  %227 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %7, i64 noundef %10) #16
  %228 = tail call i64 @__gmpn_sub_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %10) #16
  %229 = getelementptr inbounds i64, ptr %0, i64 %4
  %230 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %229, ptr noundef nonnull %229, ptr noundef %1, i64 noundef %4) #16
  %231 = getelementptr inbounds i64, ptr %0, i64 %120
  %232 = load i64, ptr %127, align 8, !tbaa !15
  %233 = add i64 %232, %230
  store i64 %233, ptr %231, align 8, !tbaa !15
  %234 = icmp ult i64 %233, %230
  br i1 %234, label %235, label %258

235:                                              ; preds = %212
  %236 = tail call i64 @llvm.smax.i64(i64 %4, i64 1)
  br label %237

237:                                              ; preds = %240, %235
  %238 = phi i64 [ %245, %240 ], [ 1, %235 ]
  %239 = icmp eq i64 %238, %236
  br i1 %239, label %269, label %240

240:                                              ; preds = %237
  %241 = getelementptr inbounds i64, ptr %127, i64 %238
  %242 = load i64, ptr %241, align 8, !tbaa !15
  %243 = add i64 %242, 1
  %244 = getelementptr inbounds i64, ptr %231, i64 %238
  store i64 %243, ptr %244, align 8, !tbaa !15
  %245 = add nuw i64 %238, 1
  %246 = icmp eq i64 %243, 0
  br i1 %246, label %237, label %247, !llvm.loop !276

247:                                              ; preds = %240
  %248 = icmp ne ptr %127, %231
  %249 = icmp slt i64 %245, %4
  %250 = select i1 %248, i1 %249, i1 false
  br i1 %250, label %251, label %269

251:                                              ; preds = %251, %247
  %252 = phi i64 [ %256, %251 ], [ %245, %247 ]
  %253 = getelementptr inbounds i64, ptr %127, i64 %252
  %254 = load i64, ptr %253, align 8, !tbaa !15
  %255 = getelementptr inbounds i64, ptr %231, i64 %252
  store i64 %254, ptr %255, align 8, !tbaa !15
  %256 = add nuw nsw i64 %252, 1
  %257 = icmp slt i64 %256, %4
  br i1 %257, label %251, label %269, !llvm.loop !277

258:                                              ; preds = %212
  %259 = icmp ne ptr %127, %231
  %260 = icmp sgt i64 %4, 1
  %261 = and i1 %260, %259
  br i1 %261, label %262, label %269

262:                                              ; preds = %262, %258
  %263 = phi i64 [ %267, %262 ], [ 1, %258 ]
  %264 = getelementptr inbounds i64, ptr %127, i64 %263
  %265 = load i64, ptr %264, align 8, !tbaa !15
  %266 = getelementptr inbounds i64, ptr %231, i64 %263
  store i64 %265, ptr %266, align 8, !tbaa !15
  %267 = add nuw nsw i64 %263, 1
  %268 = icmp eq i64 %267, %4
  br i1 %268, label %269, label %262, !llvm.loop !278

269:                                              ; preds = %262, %258, %251, %247, %237
  %270 = phi i64 [ 0, %247 ], [ 0, %258 ], [ 0, %251 ], [ 1, %237 ], [ 0, %262 ]
  %271 = getelementptr inbounds i64, ptr %1, i64 %120
  %272 = load i64, ptr %271, align 8, !tbaa !15
  %273 = add i64 %272, %270
  store i64 %273, ptr %271, align 8, !tbaa !15
  %274 = icmp ult i64 %273, %270
  br i1 %274, label %275, label %281

275:                                              ; preds = %275, %269
  %276 = phi ptr [ %277, %275 ], [ %271, %269 ]
  %277 = getelementptr inbounds i8, ptr %276, i64 8
  %278 = load i64, ptr %277, align 8, !tbaa !15
  %279 = add i64 %278, 1
  store i64 %279, ptr %277, align 8, !tbaa !15
  %280 = icmp eq i64 %279, 0
  br i1 %280, label %275, label %281, !llvm.loop !279

281:                                              ; preds = %275, %269
  %282 = getelementptr inbounds i64, ptr %1, i64 %9
  %283 = load i64, ptr %282, align 8, !tbaa !15
  %284 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %118, ptr noundef nonnull %118, ptr noundef nonnull %271, i64 noundef %4) #16
  %285 = add i64 %284, %283
  %286 = load i64, ptr %119, align 8, !tbaa !15
  %287 = add i64 %286, %285
  store i64 %287, ptr %119, align 8, !tbaa !15
  %288 = icmp ult i64 %287, %285
  br i1 %288, label %289, label %295

289:                                              ; preds = %289, %281
  %290 = phi ptr [ %291, %289 ], [ %119, %281 ]
  %291 = getelementptr inbounds i8, ptr %290, i64 8
  %292 = load i64, ptr %291, align 8, !tbaa !15
  %293 = add i64 %292, 1
  store i64 %293, ptr %291, align 8, !tbaa !15
  %294 = icmp eq i64 %293, 0
  br i1 %294, label %289, label %295, !llvm.loop !280

295:                                              ; preds = %289, %281
  %296 = mul i64 %4, 40
  %297 = getelementptr inbounds i8, ptr %0, i64 %296
  %298 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %297, ptr noundef nonnull %297, ptr noundef %2, i64 noundef %4) #16
  %299 = mul i64 %4, 48
  %300 = getelementptr inbounds i8, ptr %0, i64 %299
  %301 = load i64, ptr %300, align 8, !tbaa !15
  %302 = add i64 %301, %298
  store i64 %302, ptr %300, align 8, !tbaa !15
  %303 = load i64, ptr %202, align 8, !tbaa !15
  %304 = add i64 %303, %302
  store i64 %304, ptr %300, align 8, !tbaa !15
  %305 = icmp ult i64 %304, %302
  br i1 %305, label %306, label %329

306:                                              ; preds = %295
  %307 = tail call i64 @llvm.smax.i64(i64 %4, i64 1)
  br label %308

308:                                              ; preds = %311, %306
  %309 = phi i64 [ %316, %311 ], [ 1, %306 ]
  %310 = icmp eq i64 %309, %307
  br i1 %310, label %340, label %311

311:                                              ; preds = %308
  %312 = getelementptr inbounds i64, ptr %202, i64 %309
  %313 = load i64, ptr %312, align 8, !tbaa !15
  %314 = add i64 %313, 1
  %315 = getelementptr inbounds i64, ptr %300, i64 %309
  store i64 %314, ptr %315, align 8, !tbaa !15
  %316 = add nuw i64 %309, 1
  %317 = icmp eq i64 %314, 0
  br i1 %317, label %308, label %318, !llvm.loop !276

318:                                              ; preds = %311
  %319 = icmp ne ptr %202, %300
  %320 = icmp slt i64 %316, %4
  %321 = select i1 %319, i1 %320, i1 false
  br i1 %321, label %322, label %340

322:                                              ; preds = %322, %318
  %323 = phi i64 [ %327, %322 ], [ %316, %318 ]
  %324 = getelementptr inbounds i64, ptr %202, i64 %323
  %325 = load i64, ptr %324, align 8, !tbaa !15
  %326 = getelementptr inbounds i64, ptr %300, i64 %323
  store i64 %325, ptr %326, align 8, !tbaa !15
  %327 = add nuw nsw i64 %323, 1
  %328 = icmp slt i64 %327, %4
  br i1 %328, label %322, label %340, !llvm.loop !277

329:                                              ; preds = %295
  %330 = icmp ne ptr %202, %300
  %331 = icmp sgt i64 %4, 1
  %332 = and i1 %331, %330
  br i1 %332, label %333, label %340

333:                                              ; preds = %333, %329
  %334 = phi i64 [ %338, %333 ], [ 1, %329 ]
  %335 = getelementptr inbounds i64, ptr %202, i64 %334
  %336 = load i64, ptr %335, align 8, !tbaa !15
  %337 = getelementptr inbounds i64, ptr %300, i64 %334
  store i64 %336, ptr %337, align 8, !tbaa !15
  %338 = add nuw nsw i64 %334, 1
  %339 = icmp eq i64 %338, %4
  br i1 %339, label %340, label %333, !llvm.loop !278

340:                                              ; preds = %333, %329, %322, %318, %308
  %341 = phi i64 [ 0, %318 ], [ 0, %329 ], [ 0, %322 ], [ 1, %308 ], [ 0, %333 ]
  %342 = getelementptr inbounds i64, ptr %2, i64 %120
  %343 = load i64, ptr %342, align 8, !tbaa !15
  %344 = add i64 %343, %341
  store i64 %344, ptr %342, align 8, !tbaa !15
  %345 = icmp ult i64 %344, %341
  br i1 %345, label %346, label %352

346:                                              ; preds = %346, %340
  %347 = phi ptr [ %348, %346 ], [ %342, %340 ]
  %348 = getelementptr inbounds i8, ptr %347, i64 8
  %349 = load i64, ptr %348, align 8, !tbaa !15
  %350 = add i64 %349, 1
  store i64 %350, ptr %348, align 8, !tbaa !15
  %351 = icmp eq i64 %350, 0
  br i1 %351, label %346, label %352, !llvm.loop !281

352:                                              ; preds = %346, %340
  %353 = load i64, ptr %204, align 8, !tbaa !15
  %354 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef nonnull %342, i64 noundef %4) #16
  %355 = shl nsw i64 %4, 6
  %356 = getelementptr inbounds i8, ptr %0, i64 %355
  %357 = add i64 %354, %353
  %358 = load i64, ptr %356, align 8, !tbaa !15
  %359 = add i64 %358, %357
  store i64 %359, ptr %356, align 8, !tbaa !15
  %360 = icmp ult i64 %359, %357
  br i1 %360, label %361, label %367

361:                                              ; preds = %361, %352
  %362 = phi ptr [ %363, %361 ], [ %356, %352 ]
  %363 = getelementptr inbounds i8, ptr %362, i64 8
  %364 = load i64, ptr %363, align 8, !tbaa !15
  %365 = add i64 %364, 1
  store i64 %365, ptr %363, align 8, !tbaa !15
  %366 = icmp eq i64 %365, 0
  br i1 %366, label %361, label %367, !llvm.loop !282

367:                                              ; preds = %361, %352
  %368 = mul i64 %4, 72
  %369 = getelementptr inbounds i8, ptr %0, i64 %368
  %370 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %369, ptr noundef nonnull %369, ptr noundef %7, i64 noundef %4) #16
  %371 = mul i64 %4, 80
  %372 = getelementptr inbounds i8, ptr %0, i64 %371
  %373 = load i64, ptr %372, align 8, !tbaa !15
  %374 = add i64 %373, %370
  store i64 %374, ptr %372, align 8, !tbaa !15
  %375 = getelementptr inbounds i64, ptr %7, i64 %4
  %376 = load i64, ptr %375, align 8, !tbaa !15
  %377 = add i64 %376, %374
  store i64 %377, ptr %372, align 8, !tbaa !15
  %378 = icmp ult i64 %377, %374
  br i1 %11, label %450, label %379

379:                                              ; preds = %367
  br i1 %378, label %380, label %403

380:                                              ; preds = %379
  %381 = tail call i64 @llvm.smax.i64(i64 %4, i64 1)
  br label %382

382:                                              ; preds = %385, %380
  %383 = phi i64 [ %390, %385 ], [ 1, %380 ]
  %384 = icmp eq i64 %383, %381
  br i1 %384, label %414, label %385

385:                                              ; preds = %382
  %386 = getelementptr inbounds i64, ptr %375, i64 %383
  %387 = load i64, ptr %386, align 8, !tbaa !15
  %388 = add i64 %387, 1
  %389 = getelementptr inbounds i64, ptr %372, i64 %383
  store i64 %388, ptr %389, align 8, !tbaa !15
  %390 = add nuw i64 %383, 1
  %391 = icmp eq i64 %388, 0
  br i1 %391, label %382, label %392, !llvm.loop !276

392:                                              ; preds = %385
  %393 = icmp ne ptr %375, %372
  %394 = icmp slt i64 %390, %4
  %395 = select i1 %393, i1 %394, i1 false
  br i1 %395, label %396, label %414

396:                                              ; preds = %396, %392
  %397 = phi i64 [ %401, %396 ], [ %390, %392 ]
  %398 = getelementptr inbounds i64, ptr %375, i64 %397
  %399 = load i64, ptr %398, align 8, !tbaa !15
  %400 = getelementptr inbounds i64, ptr %372, i64 %397
  store i64 %399, ptr %400, align 8, !tbaa !15
  %401 = add nuw nsw i64 %397, 1
  %402 = icmp slt i64 %401, %4
  br i1 %402, label %396, label %414, !llvm.loop !277

403:                                              ; preds = %379
  %404 = icmp ne ptr %375, %372
  %405 = icmp sgt i64 %4, 1
  %406 = and i1 %405, %404
  br i1 %406, label %407, label %414

407:                                              ; preds = %407, %403
  %408 = phi i64 [ %412, %407 ], [ 1, %403 ]
  %409 = getelementptr inbounds i64, ptr %375, i64 %408
  %410 = load i64, ptr %409, align 8, !tbaa !15
  %411 = getelementptr inbounds i64, ptr %372, i64 %408
  store i64 %410, ptr %411, align 8, !tbaa !15
  %412 = add nuw nsw i64 %408, 1
  %413 = icmp eq i64 %412, %4
  br i1 %413, label %414, label %407, !llvm.loop !278

414:                                              ; preds = %407, %403, %396, %392, %382
  %415 = phi i64 [ 0, %392 ], [ 0, %403 ], [ 0, %396 ], [ 1, %382 ], [ 0, %407 ]
  %416 = getelementptr inbounds i64, ptr %7, i64 %120
  %417 = load i64, ptr %416, align 8, !tbaa !15
  %418 = add i64 %417, %415
  store i64 %418, ptr %416, align 8, !tbaa !15
  %419 = icmp ult i64 %418, %415
  br i1 %419, label %420, label %426

420:                                              ; preds = %420, %414
  %421 = phi ptr [ %422, %420 ], [ %416, %414 ]
  %422 = getelementptr inbounds i8, ptr %421, i64 8
  %423 = load i64, ptr %422, align 8, !tbaa !15
  %424 = add i64 %423, 1
  store i64 %424, ptr %422, align 8, !tbaa !15
  %425 = icmp eq i64 %424, 0
  br i1 %425, label %420, label %426, !llvm.loop !283

426:                                              ; preds = %420, %414
  %427 = icmp sgt i64 %5, %4
  br i1 %427, label %428, label %446, !prof !68

428:                                              ; preds = %426
  %429 = getelementptr inbounds i64, ptr %7, i64 %9
  %430 = load i64, ptr %429, align 8, !tbaa !15
  %431 = mul i64 %4, 88
  %432 = getelementptr inbounds i8, ptr %0, i64 %431
  %433 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %432, ptr noundef nonnull %432, ptr noundef nonnull %416, i64 noundef %4) #16
  %434 = mul i64 %4, 96
  %435 = getelementptr inbounds i8, ptr %0, i64 %434
  %436 = add i64 %433, %430
  %437 = load i64, ptr %435, align 8, !tbaa !15
  %438 = add i64 %437, %436
  store i64 %438, ptr %435, align 8, !tbaa !15
  %439 = icmp ult i64 %438, %436
  br i1 %439, label %440, label %485

440:                                              ; preds = %440, %428
  %441 = phi ptr [ %442, %440 ], [ %435, %428 ]
  %442 = getelementptr inbounds i8, ptr %441, i64 8
  %443 = load i64, ptr %442, align 8, !tbaa !15
  %444 = add i64 %443, 1
  store i64 %444, ptr %442, align 8, !tbaa !15
  %445 = icmp eq i64 %444, 0
  br i1 %445, label %440, label %485, !llvm.loop !284

446:                                              ; preds = %426
  %447 = mul i64 %4, 88
  %448 = getelementptr inbounds i8, ptr %0, i64 %447
  %449 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %448, ptr noundef nonnull %448, ptr noundef nonnull %416, i64 noundef %5) #16
  br label %485

450:                                              ; preds = %367
  br i1 %378, label %451, label %474

451:                                              ; preds = %450
  %452 = tail call i64 @llvm.smax.i64(i64 %5, i64 1)
  br label %453

453:                                              ; preds = %456, %451
  %454 = phi i64 [ %461, %456 ], [ 1, %451 ]
  %455 = icmp eq i64 %454, %452
  br i1 %455, label %485, label %456

456:                                              ; preds = %453
  %457 = getelementptr inbounds i64, ptr %375, i64 %454
  %458 = load i64, ptr %457, align 8, !tbaa !15
  %459 = add i64 %458, 1
  %460 = getelementptr inbounds i64, ptr %372, i64 %454
  store i64 %459, ptr %460, align 8, !tbaa !15
  %461 = add nuw i64 %454, 1
  %462 = icmp eq i64 %459, 0
  br i1 %462, label %453, label %463, !llvm.loop !276

463:                                              ; preds = %456
  %464 = icmp ne ptr %375, %372
  %465 = icmp slt i64 %461, %5
  %466 = select i1 %464, i1 %465, i1 false
  br i1 %466, label %467, label %485

467:                                              ; preds = %467, %463
  %468 = phi i64 [ %472, %467 ], [ %461, %463 ]
  %469 = getelementptr inbounds i64, ptr %375, i64 %468
  %470 = load i64, ptr %469, align 8, !tbaa !15
  %471 = getelementptr inbounds i64, ptr %372, i64 %468
  store i64 %470, ptr %471, align 8, !tbaa !15
  %472 = add nuw nsw i64 %468, 1
  %473 = icmp slt i64 %472, %5
  br i1 %473, label %467, label %485, !llvm.loop !277

474:                                              ; preds = %450
  %475 = icmp ne ptr %375, %372
  %476 = icmp sgt i64 %5, 1
  %477 = and i1 %476, %475
  br i1 %477, label %478, label %485

478:                                              ; preds = %478, %474
  %479 = phi i64 [ %483, %478 ], [ 1, %474 ]
  %480 = getelementptr inbounds i64, ptr %375, i64 %479
  %481 = load i64, ptr %480, align 8, !tbaa !15
  %482 = getelementptr inbounds i64, ptr %372, i64 %479
  store i64 %481, ptr %482, align 8, !tbaa !15
  %483 = add nuw nsw i64 %479, 1
  %484 = icmp eq i64 %483, %5
  br i1 %484, label %485, label %478, !llvm.loop !278

485:                                              ; preds = %478, %474, %467, %463, %453, %446, %440, %428
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, i32 noundef %5, i64 noundef %6) local_unnamed_addr #5 {
  %8 = shl nsw i64 %3, 1
  %9 = or disjoint i64 %8, 1
  %10 = getelementptr inbounds i64, ptr %0, i64 %3
  %11 = getelementptr inbounds i64, ptr %10, i64 %3
  %12 = getelementptr inbounds i64, ptr %11, i64 %3
  %13 = getelementptr inbounds i64, ptr %12, i64 %3
  %14 = icmp eq i32 %5, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %7
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %9) #16
  br label %19

17:                                               ; preds = %7
  %18 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %9) #16
  br label %19

19:                                               ; preds = %17, %15
  %20 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %1, ptr noundef %1, i64 noundef %9, i64 noundef 6148914691236517205, i64 noundef 0) #16
  br i1 %14, label %23, label %21

21:                                               ; preds = %19
  %22 = tail call i64 @__gmpn_add_n(ptr noundef %2, ptr noundef %11, ptr noundef %2, i64 noundef %9) #16
  br label %25

23:                                               ; preds = %19
  %24 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %11, ptr noundef %2, i64 noundef %9) #16
  br label %25

25:                                               ; preds = %23, %21
  %26 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %9, i32 noundef 1) #16
  %27 = tail call i64 @__gmpn_sub_n(ptr noundef %11, ptr noundef %11, ptr noundef %0, i64 noundef %8) #16
  %28 = load i64, ptr %13, align 8, !tbaa !15
  %29 = sub i64 %28, %27
  store i64 %29, ptr %13, align 8, !tbaa !15
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %11, i64 noundef %9) #16
  %31 = tail call i64 @__gmpn_rshift(ptr noundef %1, ptr noundef %1, i64 noundef %9, i32 noundef 1) #16
  %32 = tail call i64 @__gmpn_sub_n(ptr noundef %11, ptr noundef %11, ptr noundef %2, i64 noundef %9) #16
  %33 = tail call i64 @__gmpn_add_n(ptr noundef %10, ptr noundef %10, ptr noundef %2, i64 noundef %9) #16
  %34 = getelementptr inbounds i8, ptr %12, i64 8
  %35 = load i64, ptr %34, align 8, !tbaa !15
  %36 = add i64 %35, %33
  store i64 %36, ptr %34, align 8, !tbaa !15
  %37 = icmp ult i64 %36, %33
  br i1 %37, label %38, label %44

38:                                               ; preds = %38, %25
  %39 = phi ptr [ %40, %38 ], [ %34, %25 ]
  %40 = getelementptr inbounds i8, ptr %39, i64 8
  %41 = load i64, ptr %40, align 8, !tbaa !15
  %42 = add i64 %41, 1
  store i64 %42, ptr %40, align 8, !tbaa !15
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %38, label %44, !llvm.loop !285

44:                                               ; preds = %38, %25
  %45 = load i64, ptr %13, align 8, !tbaa !15
  store i64 %6, ptr %13, align 8, !tbaa !15
  %46 = tail call i64 @__gmpn_lshift(ptr noundef %2, ptr noundef nonnull %13, i64 noundef %4, i32 noundef 1) #16
  %47 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %4) #16
  %48 = getelementptr inbounds i64, ptr %1, i64 %4
  %49 = add i64 %47, %46
  %50 = load i64, ptr %48, align 8, !tbaa !15
  %51 = sub i64 %50, %49
  store i64 %51, ptr %48, align 8, !tbaa !15
  %52 = icmp ult i64 %50, %49
  br i1 %52, label %53, label %59

53:                                               ; preds = %53, %44
  %54 = phi ptr [ %55, %53 ], [ %48, %44 ]
  %55 = getelementptr inbounds i8, ptr %54, i64 8
  %56 = load i64, ptr %55, align 8, !tbaa !15
  %57 = add i64 %56, -1
  store i64 %57, ptr %55, align 8, !tbaa !15
  %58 = icmp eq i64 %56, 0
  br i1 %58, label %53, label %59, !llvm.loop !286

59:                                               ; preds = %53, %44
  %60 = add nsw i64 %3, 1
  %61 = icmp slt i64 %60, %4
  %62 = getelementptr inbounds i64, ptr %1, i64 %3
  br i1 %61, label %63, label %75, !prof !68

63:                                               ; preds = %59
  %64 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %13, ptr noundef nonnull %13, ptr noundef %62, i64 noundef %60) #16
  %65 = getelementptr inbounds i64, ptr %12, i64 %9
  %66 = load i64, ptr %65, align 8, !tbaa !15
  %67 = add i64 %66, %64
  store i64 %67, ptr %65, align 8, !tbaa !15
  %68 = icmp ult i64 %67, %64
  br i1 %68, label %69, label %77

69:                                               ; preds = %69, %63
  %70 = phi ptr [ %71, %69 ], [ %65, %63 ]
  %71 = getelementptr inbounds i8, ptr %70, i64 8
  %72 = load i64, ptr %71, align 8, !tbaa !15
  %73 = add i64 %72, 1
  store i64 %73, ptr %71, align 8, !tbaa !15
  %74 = icmp eq i64 %73, 0
  br i1 %74, label %69, label %77, !llvm.loop !287

75:                                               ; preds = %59
  %76 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %13, ptr noundef nonnull %13, ptr noundef %62, i64 noundef %4) #16
  br label %77

77:                                               ; preds = %75, %69, %63
  %78 = tail call i64 @__gmpn_sub_n(ptr noundef %11, ptr noundef %11, ptr noundef nonnull %13, i64 noundef %4) #16
  %79 = load i64, ptr %13, align 8, !tbaa !15
  store i64 %45, ptr %13, align 8, !tbaa !15
  %80 = getelementptr inbounds i64, ptr %11, i64 %4
  %81 = load i64, ptr %80, align 8, !tbaa !15
  %82 = sub i64 %81, %78
  store i64 %82, ptr %80, align 8, !tbaa !15
  %83 = icmp ult i64 %81, %78
  br i1 %83, label %84, label %90

84:                                               ; preds = %84, %77
  %85 = phi ptr [ %86, %84 ], [ %80, %77 ]
  %86 = getelementptr inbounds i8, ptr %85, i64 8
  %87 = load i64, ptr %86, align 8, !tbaa !15
  %88 = add i64 %87, -1
  store i64 %88, ptr %86, align 8, !tbaa !15
  %89 = icmp eq i64 %87, 0
  br i1 %89, label %84, label %90, !llvm.loop !288

90:                                               ; preds = %84, %77
  %91 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %10, ptr noundef %1, i64 noundef %3) #16
  %92 = load i64, ptr %11, align 8, !tbaa !15
  %93 = sub i64 %92, %91
  store i64 %93, ptr %11, align 8, !tbaa !15
  %94 = icmp ult i64 %92, %91
  br i1 %94, label %95, label %101

95:                                               ; preds = %95, %90
  %96 = phi ptr [ %97, %95 ], [ %11, %90 ]
  %97 = getelementptr inbounds i8, ptr %96, i64 8
  %98 = load i64, ptr %97, align 8, !tbaa !15
  %99 = add i64 %98, -1
  store i64 %99, ptr %97, align 8, !tbaa !15
  %100 = icmp eq i64 %98, 0
  br i1 %100, label %95, label %101, !llvm.loop !289

101:                                              ; preds = %95, %90
  %102 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %12, ptr noundef nonnull %12, ptr noundef %1, i64 noundef %3) #16
  %103 = load i64, ptr %13, align 8, !tbaa !15
  %104 = add i64 %103, %102
  %105 = add i64 %104, %79
  store i64 %105, ptr %13, align 8, !tbaa !15
  %106 = icmp ult i64 %105, %79
  br i1 %106, label %107, label %113

107:                                              ; preds = %107, %101
  %108 = phi ptr [ %109, %107 ], [ %13, %101 ]
  %109 = getelementptr inbounds i8, ptr %108, i64 8
  %110 = load i64, ptr %109, align 8, !tbaa !15
  %111 = add i64 %110, 1
  store i64 %111, ptr %109, align 8, !tbaa !15
  %112 = icmp eq i64 %111, 0
  br i1 %112, label %107, label %113, !llvm.loop !290

113:                                              ; preds = %107, %101
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_mul_1(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #6 {
  %5 = lshr i64 %3, 32
  %6 = and i64 %3, 4294967295
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %34, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %36, %7 ]
  %10 = phi ptr [ %1, %4 ], [ %12, %7 ]
  %11 = phi ptr [ %0, %4 ], [ %35, %7 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 8
  %13 = load i64, ptr %10, align 8, !tbaa !15
  %14 = lshr i64 %13, 32
  %15 = and i64 %13, 4294967295
  %16 = mul nuw i64 %15, %6
  %17 = mul nuw i64 %15, %5
  %18 = mul nuw i64 %14, %6
  %19 = mul nuw i64 %14, %5
  %20 = lshr i64 %16, 32
  %21 = add i64 %18, %17
  %22 = add i64 %21, %20
  %23 = icmp ult i64 %22, %18
  %24 = add nuw i64 %19, 4294967296
  %25 = select i1 %23, i64 %24, i64 %19
  %26 = lshr i64 %22, 32
  %27 = add i64 %25, %26
  %28 = shl i64 %22, 32
  %29 = and i64 %16, 4294967295
  %30 = add i64 %29, %8
  %31 = add i64 %30, %28
  %32 = icmp ult i64 %31, %8
  %33 = zext i1 %32 to i64
  %34 = add i64 %27, %33
  %35 = getelementptr inbounds i8, ptr %11, i64 8
  store i64 %31, ptr %11, align 8, !tbaa !15
  %36 = add nsw i64 %9, -1
  %37 = icmp eq i64 %36, 0
  br i1 %37, label %38, label %7, !llvm.loop !291

38:                                               ; preds = %7
  ret i64 %34
}

; Function Attrs: nofree nounwind ssp uwtable
define void @__gmp_assert_header(ptr noundef %0, i32 noundef %1) local_unnamed_addr #14 {
  %3 = icmp eq ptr %0, null
  br i1 %3, label %14, label %4

4:                                                ; preds = %2
  %5 = load i8, ptr %0, align 1, !tbaa !155
  %6 = icmp eq i8 %5, 0
  br i1 %6, label %14, label %7

7:                                                ; preds = %4
  %8 = load ptr, ptr @__stderrp, align 8, !tbaa !7
  %9 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %8, ptr noundef nonnull @.str.14, ptr noundef nonnull %0) #16
  %10 = icmp eq i32 %1, -1
  br i1 %10, label %14, label %11

11:                                               ; preds = %7
  %12 = load ptr, ptr @__stderrp, align 8, !tbaa !7
  %13 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %12, ptr noundef nonnull @.str.1.15, i32 noundef %1) #16
  br label %14

14:                                               ; preds = %11, %7, %4, %2
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_fft_next_size(i64 noundef %0, i32 noundef %1) local_unnamed_addr #8 {
  %3 = add nsw i64 %0, -1
  %4 = zext i32 %1 to i64
  %5 = ashr i64 %3, %4
  %6 = add nsw i64 %5, 1
  %7 = shl i64 %6, %4
  ret i64 %7
}

; Function Attrs: inlinehint nounwind ssp uwtable
define hidden fastcc i64 @mpn_sub_nc(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4) unnamed_addr #9 {
  %6 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) #16
  %7 = load i64, ptr %0, align 8, !tbaa !15
  %8 = sub i64 %7, %4
  store i64 %8, ptr %0, align 8, !tbaa !15
  %9 = icmp ult i64 %7, %4
  br i1 %9, label %10, label %21

10:                                               ; preds = %5
  %11 = tail call i64 @llvm.smax.i64(i64 %3, i64 1)
  br label %12

12:                                               ; preds = %15, %10
  %13 = phi i64 [ %19, %15 ], [ 1, %10 ]
  %14 = icmp eq i64 %13, %11
  br i1 %14, label %21, label %15

15:                                               ; preds = %12
  %16 = getelementptr inbounds i64, ptr %0, i64 %13
  %17 = load i64, ptr %16, align 8, !tbaa !15
  %18 = add i64 %17, -1
  store i64 %18, ptr %16, align 8, !tbaa !15
  %19 = add nuw i64 %13, 1
  %20 = icmp eq i64 %17, 0
  br i1 %20, label %12, label %21, !llvm.loop !102

21:                                               ; preds = %15, %12, %5
  %22 = phi i64 [ 0, %5 ], [ 1, %12 ], [ 0, %15 ]
  %23 = add i64 %22, %6
  ret i64 %23
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = shl nsw i64 %3, 4
  %8 = getelementptr inbounds i8, ptr %2, i64 %7
  %9 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %2, ptr noundef %8, i64 noundef %3) #16
  %10 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 %9, ptr %10, align 8, !tbaa !15
  %11 = getelementptr inbounds i64, ptr %2, i64 %3
  %12 = icmp eq i64 %4, 0
  br i1 %12, label %28, label %13

13:                                               ; preds = %6
  %14 = mul i64 %3, 24
  %15 = getelementptr inbounds i8, ptr %2, i64 %14
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %11, ptr noundef %15, i64 noundef %4) #16
  %17 = icmp eq i64 %16, 0
  br i1 %17, label %28, label %18

18:                                               ; preds = %21, %13
  %19 = phi i64 [ %25, %21 ], [ %4, %13 ]
  %20 = icmp slt i64 %19, %3
  br i1 %20, label %21, label %40

21:                                               ; preds = %18
  %22 = getelementptr inbounds i64, ptr %11, i64 %19
  %23 = load i64, ptr %22, align 8, !tbaa !15
  %24 = add i64 %23, 1
  %25 = add nsw i64 %19, 1
  %26 = getelementptr inbounds i64, ptr %5, i64 %19
  store i64 %24, ptr %26, align 8, !tbaa !15
  %27 = icmp eq i64 %24, 0
  br i1 %27, label %18, label %28, !llvm.loop !292

28:                                               ; preds = %21, %13, %6
  %29 = phi i64 [ %4, %13 ], [ 0, %6 ], [ %25, %21 ]
  %30 = icmp ne ptr %11, %5
  %31 = icmp slt i64 %29, %3
  %32 = select i1 %30, i1 %31, i1 false
  br i1 %32, label %33, label %40

33:                                               ; preds = %33, %28
  %34 = phi i64 [ %38, %33 ], [ %29, %28 ]
  %35 = getelementptr inbounds i64, ptr %11, i64 %34
  %36 = load i64, ptr %35, align 8, !tbaa !15
  %37 = getelementptr inbounds i64, ptr %5, i64 %34
  store i64 %36, ptr %37, align 8, !tbaa !15
  %38 = add nsw i64 %34, 1
  %39 = icmp eq i64 %38, %3
  br i1 %39, label %40, label %33, !llvm.loop !293

40:                                               ; preds = %33, %28, %18
  %41 = phi i64 [ 0, %28 ], [ 0, %33 ], [ 1, %18 ]
  %42 = getelementptr inbounds i64, ptr %5, i64 %3
  store i64 %41, ptr %42, align 8, !tbaa !15
  %43 = add nsw i64 %3, 1
  br label %44

44:                                               ; preds = %47, %40
  %45 = phi i64 [ %43, %40 ], [ %48, %47 ]
  %46 = icmp sgt i64 %45, 0
  br i1 %46, label %47, label %57

47:                                               ; preds = %44
  %48 = add nsw i64 %45, -1
  %49 = getelementptr inbounds i64, ptr %0, i64 %48
  %50 = load i64, ptr %49, align 8, !tbaa !15
  %51 = getelementptr inbounds i64, ptr %5, i64 %48
  %52 = load i64, ptr %51, align 8, !tbaa !15
  %53 = icmp eq i64 %50, %52
  br i1 %53, label %44, label %54, !llvm.loop !294

54:                                               ; preds = %47
  %55 = icmp ugt i64 %50, %52
  %56 = select i1 %55, i32 1, i32 -1
  br label %57

57:                                               ; preds = %54, %44
  %58 = phi i32 [ %56, %54 ], [ 0, %44 ]
  %59 = icmp slt i32 %58, 0
  br i1 %59, label %60, label %62

60:                                               ; preds = %57
  %61 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %5, ptr noundef %0, i64 noundef %43) #16
  br label %64

62:                                               ; preds = %57
  %63 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %5, i64 noundef %43) #16
  br label %64

64:                                               ; preds = %62, %60
  %65 = ashr i32 %58, 31
  %66 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %5, i64 noundef %43) #16
  ret i32 %65
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = shl nsw i64 %3, 4
  %8 = getelementptr inbounds i8, ptr %2, i64 %7
  %9 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %8, i64 noundef %3, i32 noundef 2) #16
  %10 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %5, ptr noundef %2, i64 noundef %3) #16
  %11 = add i64 %10, %9
  %12 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 %11, ptr %12, align 8, !tbaa !15
  %13 = mul i64 %3, 24
  %14 = getelementptr inbounds i8, ptr %2, i64 %13
  %15 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %14, i64 noundef %4, i32 noundef 2) #16
  %16 = getelementptr inbounds i64, ptr %5, i64 %4
  store i64 %15, ptr %16, align 8, !tbaa !15
  %17 = icmp slt i64 %4, %3
  %18 = getelementptr inbounds i64, ptr %2, i64 %3
  br i1 %17, label %19, label %50

19:                                               ; preds = %6
  %20 = add nsw i64 %4, 1
  %21 = icmp eq i64 %20, 0
  br i1 %21, label %35, label %22

22:                                               ; preds = %19
  %23 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %18, ptr noundef %5, i64 noundef %20) #16
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %35, label %25

25:                                               ; preds = %28, %22
  %26 = phi i64 [ %32, %28 ], [ %20, %22 ]
  %27 = icmp eq i64 %26, %3
  br i1 %27, label %47, label %28

28:                                               ; preds = %25
  %29 = getelementptr inbounds i64, ptr %18, i64 %26
  %30 = load i64, ptr %29, align 8, !tbaa !15
  %31 = add i64 %30, 1
  %32 = add i64 %26, 1
  %33 = getelementptr inbounds i64, ptr %5, i64 %26
  store i64 %31, ptr %33, align 8, !tbaa !15
  %34 = icmp eq i64 %31, 0
  br i1 %34, label %25, label %35, !llvm.loop !295

35:                                               ; preds = %28, %22, %19
  %36 = phi i64 [ %20, %22 ], [ 0, %19 ], [ %32, %28 ]
  %37 = icmp ne ptr %18, %5
  %38 = icmp slt i64 %36, %3
  %39 = and i1 %37, %38
  br i1 %39, label %40, label %47

40:                                               ; preds = %40, %35
  %41 = phi i64 [ %45, %40 ], [ %36, %35 ]
  %42 = getelementptr inbounds i64, ptr %18, i64 %41
  %43 = load i64, ptr %42, align 8, !tbaa !15
  %44 = getelementptr inbounds i64, ptr %5, i64 %41
  store i64 %43, ptr %44, align 8, !tbaa !15
  %45 = add nsw i64 %41, 1
  %46 = icmp eq i64 %45, %3
  br i1 %46, label %47, label %40, !llvm.loop !296

47:                                               ; preds = %40, %35, %25
  %48 = phi i64 [ 0, %35 ], [ 0, %40 ], [ 1, %25 ]
  %49 = getelementptr inbounds i64, ptr %5, i64 %3
  store i64 %48, ptr %49, align 8, !tbaa !15
  br label %55

50:                                               ; preds = %6
  %51 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %18, ptr noundef %5, i64 noundef %3) #16
  %52 = getelementptr inbounds i64, ptr %5, i64 %3
  %53 = load i64, ptr %52, align 8, !tbaa !15
  %54 = add i64 %53, %51
  store i64 %54, ptr %52, align 8, !tbaa !15
  br label %55

55:                                               ; preds = %50, %47
  %56 = add nsw i64 %3, 1
  %57 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %5, i64 noundef %56, i32 noundef 1) #16
  br label %58

58:                                               ; preds = %61, %55
  %59 = phi i64 [ %56, %55 ], [ %62, %61 ]
  %60 = icmp sgt i64 %59, 0
  br i1 %60, label %61, label %71

61:                                               ; preds = %58
  %62 = add nsw i64 %59, -1
  %63 = getelementptr inbounds i64, ptr %0, i64 %62
  %64 = load i64, ptr %63, align 8, !tbaa !15
  %65 = getelementptr inbounds i64, ptr %5, i64 %62
  %66 = load i64, ptr %65, align 8, !tbaa !15
  %67 = icmp eq i64 %64, %66
  br i1 %67, label %58, label %68, !llvm.loop !297

68:                                               ; preds = %61
  %69 = icmp ugt i64 %64, %66
  %70 = select i1 %69, i32 1, i32 -1
  br label %71

71:                                               ; preds = %68, %58
  %72 = phi i32 [ %70, %68 ], [ 0, %58 ]
  %73 = icmp slt i32 %72, 0
  br i1 %73, label %74, label %76

74:                                               ; preds = %71
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %5, ptr noundef %0, i64 noundef %56) #16
  br label %78

76:                                               ; preds = %71
  %77 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %5, i64 noundef %56) #16
  br label %78

78:                                               ; preds = %76, %74
  %79 = ashr i32 %72, 31
  %80 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %5, i64 noundef %56) #16
  ret i32 %79
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_7pts(ptr noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6, i64 noundef %7, ptr noundef %8) local_unnamed_addr #5 {
  %10 = shl nsw i64 %1, 1
  %11 = or disjoint i64 %10, 1
  %12 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %5, i64 noundef %11) #16
  %13 = and i32 %2, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %9
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %3, ptr noundef %5, i64 noundef %11) #16
  br label %19

17:                                               ; preds = %9
  %18 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %5, ptr noundef %3, i64 noundef %11) #16
  br label %19

19:                                               ; preds = %17, %15
  %20 = tail call i64 @__gmpn_rshift(ptr noundef %3, ptr noundef %3, i64 noundef %11, i32 noundef 1) #16
  %21 = icmp eq i64 %1, 0
  br i1 %21, label %36, label %22

22:                                               ; preds = %19
  %23 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %10) #16
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %36, label %25

25:                                               ; preds = %22
  %26 = or disjoint i64 %10, 1
  br label %27

27:                                               ; preds = %30, %25
  %28 = phi i64 [ %34, %30 ], [ %10, %25 ]
  %29 = icmp eq i64 %28, %26
  br i1 %29, label %36, label %30

30:                                               ; preds = %27
  %31 = getelementptr inbounds i64, ptr %5, i64 %28
  %32 = load i64, ptr %31, align 8, !tbaa !15
  %33 = add i64 %32, -1
  %34 = add i64 %28, 1
  store i64 %33, ptr %31, align 8, !tbaa !15
  %35 = icmp eq i64 %32, 0
  br i1 %35, label %27, label %36, !llvm.loop !298

36:                                               ; preds = %30, %27, %22, %19
  %37 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %3, i64 noundef %11) #16
  %38 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %11, i32 noundef 2) #16
  %39 = mul i64 %1, 48
  %40 = getelementptr inbounds i8, ptr %0, i64 %39
  %41 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %40, i64 noundef %7, i32 noundef 4) #16
  %42 = getelementptr inbounds i64, ptr %8, i64 %7
  store i64 %41, ptr %42, align 8, !tbaa !15
  %43 = add nsw i64 %7, 1
  %44 = icmp eq i64 %43, 0
  br i1 %44, label %57, label %45

45:                                               ; preds = %36
  %46 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %8, i64 noundef %43) #16
  %47 = icmp eq i64 %46, 0
  br i1 %47, label %57, label %48

48:                                               ; preds = %51, %45
  %49 = phi i64 [ %55, %51 ], [ %43, %45 ]
  %50 = icmp sgt i64 %49, %10
  br i1 %50, label %57, label %51

51:                                               ; preds = %48
  %52 = getelementptr inbounds i64, ptr %5, i64 %49
  %53 = load i64, ptr %52, align 8, !tbaa !15
  %54 = add i64 %53, -1
  %55 = add nsw i64 %49, 1
  store i64 %54, ptr %52, align 8, !tbaa !15
  %56 = icmp eq i64 %53, 0
  br i1 %56, label %48, label %57, !llvm.loop !298

57:                                               ; preds = %51, %48, %45, %36
  %58 = and i32 %2, 2
  %59 = icmp eq i32 %58, 0
  %60 = getelementptr inbounds i64, ptr %0, i64 %10
  br i1 %59, label %63, label %61

61:                                               ; preds = %57
  %62 = tail call i64 @__gmpn_add_n(ptr noundef %4, ptr noundef %4, ptr noundef %60, i64 noundef %11) #16
  br label %65

63:                                               ; preds = %57
  %64 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %60, ptr noundef %4, i64 noundef %11) #16
  br label %65

65:                                               ; preds = %63, %61
  %66 = tail call i64 @__gmpn_rshift(ptr noundef %4, ptr noundef %4, i64 noundef %11, i32 noundef 1) #16
  %67 = getelementptr inbounds i64, ptr %0, i64 %10
  %68 = tail call i64 @__gmpn_sub_n(ptr noundef %67, ptr noundef %67, ptr noundef %4, i64 noundef %11) #16
  %69 = tail call i64 @__gmpn_submul_1(ptr noundef %6, ptr noundef %67, i64 noundef %11, i64 noundef 65) #16
  %70 = icmp eq i64 %7, 0
  br i1 %70, label %83, label %71

71:                                               ; preds = %65
  %72 = tail call i64 @__gmpn_sub_n(ptr noundef %67, ptr noundef %67, ptr noundef %40, i64 noundef %7) #16
  %73 = icmp eq i64 %72, 0
  br i1 %73, label %83, label %74

74:                                               ; preds = %77, %71
  %75 = phi i64 [ %81, %77 ], [ %7, %71 ]
  %76 = icmp sgt i64 %75, %10
  br i1 %76, label %83, label %77

77:                                               ; preds = %74
  %78 = getelementptr inbounds i64, ptr %67, i64 %75
  %79 = load i64, ptr %78, align 8, !tbaa !15
  %80 = add i64 %79, -1
  %81 = add nsw i64 %75, 1
  store i64 %80, ptr %78, align 8, !tbaa !15
  %82 = icmp eq i64 %79, 0
  br i1 %82, label %74, label %83, !llvm.loop !298

83:                                               ; preds = %77, %74, %71, %65
  br i1 %21, label %98, label %84

84:                                               ; preds = %83
  %85 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %67, ptr noundef nonnull %67, ptr noundef %0, i64 noundef %10) #16
  %86 = icmp eq i64 %85, 0
  br i1 %86, label %98, label %87

87:                                               ; preds = %84
  %88 = or disjoint i64 %10, 1
  br label %89

89:                                               ; preds = %92, %87
  %90 = phi i64 [ %96, %92 ], [ %10, %87 ]
  %91 = icmp eq i64 %90, %88
  br i1 %91, label %98, label %92

92:                                               ; preds = %89
  %93 = getelementptr inbounds i64, ptr %67, i64 %90
  %94 = load i64, ptr %93, align 8, !tbaa !15
  %95 = add i64 %94, -1
  %96 = add i64 %90, 1
  store i64 %95, ptr %93, align 8, !tbaa !15
  %97 = icmp eq i64 %94, 0
  br i1 %97, label %89, label %98, !llvm.loop !298

98:                                               ; preds = %92, %89, %84, %83
  %99 = tail call i64 @__gmpn_addmul_1(ptr noundef %6, ptr noundef %67, i64 noundef %11, i64 noundef 45) #16
  %100 = tail call i64 @__gmpn_rshift(ptr noundef %6, ptr noundef %6, i64 noundef %11, i32 noundef 1) #16
  %101 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %67, i64 noundef %11) #16
  %102 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %5, ptr noundef %5, i64 noundef %11, i64 noundef 6148914691236517205, i64 noundef 0) #16
  %103 = tail call i64 @__gmpn_sub_n(ptr noundef %67, ptr noundef %67, ptr noundef %5, i64 noundef %11) #16
  %104 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %6, ptr noundef %3, i64 noundef %11) #16
  %105 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %4, i64 noundef %11, i32 noundef 3) #16
  %106 = tail call i64 @__gmpn_sub_n(ptr noundef %6, ptr noundef %6, ptr noundef %8, i64 noundef %11) #16
  tail call void @__gmpn_divexact_1(ptr noundef %6, ptr noundef %6, i64 noundef %11, i64 noundef 9) #16
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %6, i64 noundef %11) #16
  %108 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %3, ptr noundef %3, i64 noundef %11, i64 noundef 1229782938247303441, i64 noundef 0) #16
  %109 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %3, ptr noundef %6, i64 noundef %11) #16
  %110 = tail call i64 @__gmpn_rshift(ptr noundef %3, ptr noundef %3, i64 noundef %11, i32 noundef 1) #16
  %111 = tail call i64 @__gmpn_sub_n(ptr noundef %6, ptr noundef %6, ptr noundef %3, i64 noundef %11) #16
  %112 = getelementptr inbounds i64, ptr %0, i64 %1
  %113 = tail call i64 @__gmpn_add_n(ptr noundef %112, ptr noundef %112, ptr noundef %3, i64 noundef %11) #16
  %114 = getelementptr inbounds i64, ptr %67, i64 %1
  %115 = getelementptr inbounds i8, ptr %114, i64 8
  %116 = load i64, ptr %115, align 8, !tbaa !15
  %117 = add i64 %116, %113
  store i64 %117, ptr %115, align 8, !tbaa !15
  %118 = icmp ult i64 %117, %113
  br i1 %118, label %119, label %125

119:                                              ; preds = %119, %98
  %120 = phi ptr [ %121, %119 ], [ %115, %98 ]
  %121 = getelementptr inbounds i8, ptr %120, i64 8
  %122 = load i64, ptr %121, align 8, !tbaa !15
  %123 = add i64 %122, 1
  store i64 %123, ptr %121, align 8, !tbaa !15
  %124 = icmp eq i64 %123, 0
  br i1 %124, label %119, label %125, !llvm.loop !299

125:                                              ; preds = %119, %98
  %126 = mul i64 %1, 24
  %127 = getelementptr inbounds i8, ptr %0, i64 %126
  %128 = tail call i64 @__gmpn_add_n(ptr noundef %127, ptr noundef %127, ptr noundef %4, i64 noundef %1) #16
  %129 = getelementptr inbounds i64, ptr %4, i64 %1
  %130 = getelementptr inbounds i64, ptr %67, i64 %10
  %131 = load i64, ptr %130, align 8, !tbaa !15
  %132 = add i64 %131, %128
  %133 = load i64, ptr %129, align 8, !tbaa !15
  %134 = add i64 %133, %132
  store i64 %134, ptr %129, align 8, !tbaa !15
  %135 = load i64, ptr %130, align 8, !tbaa !15
  %136 = add i64 %135, %128
  %137 = icmp ult i64 %134, %136
  br i1 %137, label %138, label %144

138:                                              ; preds = %138, %125
  %139 = phi ptr [ %140, %138 ], [ %129, %125 ]
  %140 = getelementptr inbounds i8, ptr %139, i64 8
  %141 = load i64, ptr %140, align 8, !tbaa !15
  %142 = add i64 %141, 1
  store i64 %142, ptr %140, align 8, !tbaa !15
  %143 = icmp eq i64 %142, 0
  br i1 %143, label %138, label %144, !llvm.loop !300

144:                                              ; preds = %138, %125
  %145 = shl nsw i64 %1, 5
  %146 = getelementptr inbounds i8, ptr %0, i64 %145
  %147 = tail call i64 @__gmpn_add_n(ptr noundef %146, ptr noundef nonnull %129, ptr noundef %5, i64 noundef %1) #16
  %148 = getelementptr inbounds i64, ptr %5, i64 %1
  %149 = getelementptr inbounds i64, ptr %4, i64 %10
  %150 = load i64, ptr %149, align 8, !tbaa !15
  %151 = add i64 %150, %147
  %152 = load i64, ptr %148, align 8, !tbaa !15
  %153 = add i64 %152, %151
  store i64 %153, ptr %148, align 8, !tbaa !15
  %154 = load i64, ptr %149, align 8, !tbaa !15
  %155 = add i64 %154, %147
  %156 = icmp ult i64 %153, %155
  br i1 %156, label %157, label %163

157:                                              ; preds = %157, %144
  %158 = phi ptr [ %159, %157 ], [ %148, %144 ]
  %159 = getelementptr inbounds i8, ptr %158, i64 8
  %160 = load i64, ptr %159, align 8, !tbaa !15
  %161 = add i64 %160, 1
  store i64 %161, ptr %159, align 8, !tbaa !15
  %162 = icmp eq i64 %161, 0
  br i1 %162, label %157, label %163, !llvm.loop !301

163:                                              ; preds = %157, %144
  %164 = mul i64 %1, 40
  %165 = getelementptr inbounds i8, ptr %0, i64 %164
  %166 = tail call i64 @__gmpn_add_n(ptr noundef %165, ptr noundef nonnull %148, ptr noundef %6, i64 noundef %1) #16
  %167 = getelementptr inbounds i64, ptr %6, i64 %1
  %168 = getelementptr inbounds i64, ptr %5, i64 %10
  %169 = load i64, ptr %168, align 8, !tbaa !15
  %170 = add i64 %169, %166
  %171 = load i64, ptr %167, align 8, !tbaa !15
  %172 = add i64 %171, %170
  store i64 %172, ptr %167, align 8, !tbaa !15
  %173 = load i64, ptr %168, align 8, !tbaa !15
  %174 = add i64 %173, %166
  %175 = icmp ult i64 %172, %174
  br i1 %175, label %176, label %182

176:                                              ; preds = %176, %163
  %177 = phi ptr [ %178, %176 ], [ %167, %163 ]
  %178 = getelementptr inbounds i8, ptr %177, i64 8
  %179 = load i64, ptr %178, align 8, !tbaa !15
  %180 = add i64 %179, 1
  store i64 %180, ptr %178, align 8, !tbaa !15
  %181 = icmp eq i64 %180, 0
  br i1 %181, label %176, label %182, !llvm.loop !302

182:                                              ; preds = %176, %163
  %183 = add nsw i64 %1, 1
  %184 = icmp slt i64 %183, %7
  br i1 %184, label %185, label %199

185:                                              ; preds = %182
  %186 = tail call i64 @__gmpn_add_n(ptr noundef %40, ptr noundef %40, ptr noundef nonnull %167, i64 noundef %183) #16
  %187 = mul i64 %1, 56
  %188 = getelementptr inbounds i8, ptr %0, i64 %187
  %189 = getelementptr inbounds i8, ptr %188, i64 8
  %190 = load i64, ptr %189, align 8, !tbaa !15
  %191 = add i64 %190, %186
  store i64 %191, ptr %189, align 8, !tbaa !15
  %192 = icmp ult i64 %191, %186
  br i1 %192, label %193, label %201

193:                                              ; preds = %193, %185
  %194 = phi ptr [ %195, %193 ], [ %189, %185 ]
  %195 = getelementptr inbounds i8, ptr %194, i64 8
  %196 = load i64, ptr %195, align 8, !tbaa !15
  %197 = add i64 %196, 1
  store i64 %197, ptr %195, align 8, !tbaa !15
  %198 = icmp eq i64 %197, 0
  br i1 %198, label %193, label %201, !llvm.loop !303

199:                                              ; preds = %182
  %200 = tail call i64 @__gmpn_add_n(ptr noundef %40, ptr noundef %40, ptr noundef nonnull %167, i64 noundef %7) #16
  br label %201

201:                                              ; preds = %199, %193, %185
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_6pts(ptr noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, i64 noundef %6) local_unnamed_addr #5 {
  %8 = and i32 %2, 2
  %9 = icmp eq i32 %8, 0
  %10 = shl nsw i64 %1, 1
  %11 = or disjoint i64 %10, 1
  br i1 %9, label %14, label %12

12:                                               ; preds = %7
  %13 = tail call i64 @__gmpn_add_n(ptr noundef %4, ptr noundef %5, ptr noundef %4, i64 noundef %11) #16
  br label %16

14:                                               ; preds = %7
  %15 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %5, ptr noundef %4, i64 noundef %11) #16
  br label %16

16:                                               ; preds = %14, %12
  %17 = shl nsw i64 %1, 1
  %18 = or disjoint i64 %17, 1
  %19 = tail call i64 @__gmpn_rshift(ptr noundef %4, ptr noundef %4, i64 noundef %18, i32 noundef 2) #16
  %20 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %17) #16
  %21 = getelementptr inbounds i64, ptr %5, i64 %17
  %22 = load i64, ptr %21, align 8, !tbaa !15
  %23 = sub i64 %22, %20
  store i64 %23, ptr %21, align 8, !tbaa !15
  %24 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %18, i32 noundef 1) #16
  %25 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %4, i64 noundef %18) #16
  %26 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %18, i32 noundef 1) #16
  %27 = and i32 %2, 1
  %28 = icmp eq i32 %27, 0
  %29 = getelementptr inbounds i64, ptr %0, i64 %17
  br i1 %28, label %32, label %30

30:                                               ; preds = %16
  %31 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %29, ptr noundef %3, i64 noundef %18) #16
  br label %34

32:                                               ; preds = %16
  %33 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %29, ptr noundef %3, i64 noundef %18) #16
  br label %34

34:                                               ; preds = %32, %30
  %35 = tail call i64 @__gmpn_rshift(ptr noundef %3, ptr noundef %3, i64 noundef %18, i32 noundef 1) #16
  %36 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %3, i64 noundef %18) #16
  %37 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %4, ptr noundef %4, i64 noundef %18, i64 noundef 6148914691236517205, i64 noundef 0) #16
  %38 = getelementptr inbounds i64, ptr %0, i64 %17
  %39 = tail call i64 @__gmpn_sub_n(ptr noundef %38, ptr noundef %38, ptr noundef %3, i64 noundef %18) #16
  %40 = tail call i64 @__gmpn_sub_n(ptr noundef %38, ptr noundef %38, ptr noundef %0, i64 noundef %17) #16
  %41 = getelementptr inbounds i64, ptr %38, i64 %17
  %42 = load i64, ptr %41, align 8, !tbaa !15
  %43 = sub i64 %42, %40
  store i64 %43, ptr %41, align 8, !tbaa !15
  %44 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %38, i64 noundef %18) #16
  %45 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %5, ptr noundef %5, i64 noundef %18, i64 noundef 6148914691236517205, i64 noundef 0) #16
  %46 = getelementptr inbounds i64, ptr %0, i64 %1
  %47 = tail call i64 @__gmpn_add_n(ptr noundef %46, ptr noundef %46, ptr noundef %3, i64 noundef %18) #16
  %48 = mul i64 %1, 24
  %49 = getelementptr inbounds i8, ptr %0, i64 %48
  %50 = getelementptr inbounds i8, ptr %49, i64 8
  %51 = load i64, ptr %50, align 8, !tbaa !15
  %52 = add i64 %51, %47
  store i64 %52, ptr %50, align 8, !tbaa !15
  %53 = icmp ult i64 %52, %47
  br i1 %53, label %54, label %60

54:                                               ; preds = %54, %34
  %55 = phi ptr [ %56, %54 ], [ %50, %34 ]
  %56 = getelementptr inbounds i8, ptr %55, i64 8
  %57 = load i64, ptr %56, align 8, !tbaa !15
  %58 = add i64 %57, 1
  store i64 %58, ptr %56, align 8, !tbaa !15
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %54, label %60, !llvm.loop !304

60:                                               ; preds = %54, %34
  %61 = mul i64 %1, 40
  %62 = getelementptr inbounds i8, ptr %0, i64 %61
  %63 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %62, i64 noundef %6, i32 noundef 2) #16
  %64 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %3, i64 noundef %6) #16
  %65 = getelementptr inbounds i64, ptr %4, i64 %6
  %66 = add i64 %64, %63
  %67 = load i64, ptr %65, align 8, !tbaa !15
  %68 = sub i64 %67, %66
  store i64 %68, ptr %65, align 8, !tbaa !15
  %69 = icmp ult i64 %67, %66
  br i1 %69, label %70, label %76

70:                                               ; preds = %70, %60
  %71 = phi ptr [ %72, %70 ], [ %65, %60 ]
  %72 = getelementptr inbounds i8, ptr %71, i64 8
  %73 = load i64, ptr %72, align 8, !tbaa !15
  %74 = add i64 %73, -1
  store i64 %74, ptr %72, align 8, !tbaa !15
  %75 = icmp eq i64 %73, 0
  br i1 %75, label %70, label %76, !llvm.loop !305

76:                                               ; preds = %70, %60
  %77 = tail call i64 @__gmpn_sub_n(ptr noundef %46, ptr noundef %46, ptr noundef %4, i64 noundef %1) #16
  %78 = load i64, ptr %38, align 8, !tbaa !15
  %79 = sub i64 %78, %77
  store i64 %79, ptr %38, align 8, !tbaa !15
  %80 = icmp ult i64 %78, %77
  br i1 %80, label %81, label %87

81:                                               ; preds = %81, %76
  %82 = phi ptr [ %83, %81 ], [ %38, %76 ]
  %83 = getelementptr inbounds i8, ptr %82, i64 8
  %84 = load i64, ptr %83, align 8, !tbaa !15
  %85 = add i64 %84, -1
  store i64 %85, ptr %83, align 8, !tbaa !15
  %86 = icmp eq i64 %84, 0
  br i1 %86, label %81, label %87, !llvm.loop !306

87:                                               ; preds = %81, %76
  %88 = load i64, ptr %41, align 8, !tbaa !15
  %89 = tail call i64 @__gmpn_add_n(ptr noundef %49, ptr noundef %49, ptr noundef %4, i64 noundef %1) #16
  %90 = add i64 %89, %88
  %91 = getelementptr inbounds i64, ptr %4, i64 %17
  %92 = load i64, ptr %91, align 8, !tbaa !15
  %93 = shl nsw i64 %1, 5
  %94 = getelementptr inbounds i8, ptr %0, i64 %93
  %95 = getelementptr inbounds i64, ptr %4, i64 %1
  %96 = tail call i64 @__gmpn_add_n(ptr noundef %94, ptr noundef %5, ptr noundef %95, i64 noundef %1) #16
  %97 = getelementptr inbounds i64, ptr %5, i64 %1
  %98 = add i64 %96, %92
  %99 = load i64, ptr %97, align 8, !tbaa !15
  %100 = add i64 %99, %98
  store i64 %100, ptr %97, align 8, !tbaa !15
  %101 = icmp ult i64 %100, %98
  br i1 %101, label %102, label %108

102:                                              ; preds = %102, %87
  %103 = phi ptr [ %104, %102 ], [ %97, %87 ]
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = load i64, ptr %104, align 8, !tbaa !15
  %106 = add i64 %105, 1
  store i64 %106, ptr %104, align 8, !tbaa !15
  %107 = icmp eq i64 %106, 0
  br i1 %107, label %102, label %108, !llvm.loop !307

108:                                              ; preds = %102, %87
  %109 = icmp sgt i64 %6, %1
  br i1 %109, label %110, label %114, !prof !68

110:                                              ; preds = %108
  %111 = load i64, ptr %21, align 8, !tbaa !15
  %112 = tail call i64 @__gmpn_add_n(ptr noundef %62, ptr noundef %62, ptr noundef nonnull %97, i64 noundef %1) #16
  %113 = add i64 %112, %111
  br label %116

114:                                              ; preds = %108
  %115 = tail call i64 @__gmpn_add_n(ptr noundef %62, ptr noundef %62, ptr noundef nonnull %97, i64 noundef %6) #16
  br label %116

116:                                              ; preds = %114, %110
  %117 = phi i64 [ %113, %110 ], [ %115, %114 ]
  %118 = add nsw i64 %6, %1
  %119 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %38, ptr noundef nonnull %38, ptr noundef %94, i64 noundef %118) #16
  %120 = getelementptr i64, ptr %62, i64 %6
  %121 = getelementptr i8, ptr %120, i64 -8
  %122 = load i64, ptr %121, align 8, !tbaa !15
  store i64 1, ptr %121, align 8, !tbaa !15
  br i1 %109, label %123, label %168, !prof !68

123:                                              ; preds = %116
  %124 = icmp ugt i64 %90, %117
  %125 = load i64, ptr %94, align 8, !tbaa !15
  br i1 %124, label %126, label %136

126:                                              ; preds = %123
  %127 = sub i64 %90, %117
  %128 = add i64 %125, %127
  store i64 %128, ptr %94, align 8, !tbaa !15
  %129 = icmp ult i64 %128, %127
  br i1 %129, label %130, label %146

130:                                              ; preds = %130, %126
  %131 = phi ptr [ %132, %130 ], [ %94, %126 ]
  %132 = getelementptr inbounds i8, ptr %131, i64 8
  %133 = load i64, ptr %132, align 8, !tbaa !15
  %134 = add i64 %133, 1
  store i64 %134, ptr %132, align 8, !tbaa !15
  %135 = icmp eq i64 %134, 0
  br i1 %135, label %130, label %146, !llvm.loop !308

136:                                              ; preds = %123
  %137 = sub i64 %117, %90
  %138 = sub i64 %125, %137
  store i64 %138, ptr %94, align 8, !tbaa !15
  %139 = icmp ult i64 %125, %137
  br i1 %139, label %140, label %146

140:                                              ; preds = %140, %136
  %141 = phi ptr [ %142, %140 ], [ %94, %136 ]
  %142 = getelementptr inbounds i8, ptr %141, i64 8
  %143 = load i64, ptr %142, align 8, !tbaa !15
  %144 = add i64 %143, -1
  store i64 %144, ptr %142, align 8, !tbaa !15
  %145 = icmp eq i64 %143, 0
  br i1 %145, label %140, label %146, !llvm.loop !309

146:                                              ; preds = %140, %136, %130, %126
  %147 = getelementptr inbounds i64, ptr %49, i64 %6
  %148 = load i64, ptr %147, align 8, !tbaa !15
  %149 = sub i64 %148, %119
  store i64 %149, ptr %147, align 8, !tbaa !15
  %150 = icmp ult i64 %148, %119
  br i1 %150, label %151, label %157

151:                                              ; preds = %151, %146
  %152 = phi ptr [ %153, %151 ], [ %147, %146 ]
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = load i64, ptr %153, align 8, !tbaa !15
  %155 = add i64 %154, -1
  store i64 %155, ptr %153, align 8, !tbaa !15
  %156 = icmp eq i64 %154, 0
  br i1 %156, label %151, label %157, !llvm.loop !310

157:                                              ; preds = %151, %146
  %158 = getelementptr inbounds i64, ptr %62, i64 %1
  %159 = load i64, ptr %158, align 8, !tbaa !15
  %160 = add i64 %159, %117
  store i64 %160, ptr %158, align 8, !tbaa !15
  %161 = icmp ult i64 %160, %117
  br i1 %161, label %162, label %190

162:                                              ; preds = %162, %157
  %163 = phi ptr [ %164, %162 ], [ %158, %157 ]
  %164 = getelementptr inbounds i8, ptr %163, i64 8
  %165 = load i64, ptr %164, align 8, !tbaa !15
  %166 = add i64 %165, 1
  store i64 %166, ptr %164, align 8, !tbaa !15
  %167 = icmp eq i64 %166, 0
  br i1 %167, label %162, label %190, !llvm.loop !311

168:                                              ; preds = %116
  %169 = load i64, ptr %94, align 8, !tbaa !15
  %170 = add i64 %169, %90
  store i64 %170, ptr %94, align 8, !tbaa !15
  %171 = icmp ult i64 %170, %90
  br i1 %171, label %172, label %178

172:                                              ; preds = %172, %168
  %173 = phi ptr [ %174, %172 ], [ %94, %168 ]
  %174 = getelementptr inbounds i8, ptr %173, i64 8
  %175 = load i64, ptr %174, align 8, !tbaa !15
  %176 = add i64 %175, 1
  store i64 %176, ptr %174, align 8, !tbaa !15
  %177 = icmp eq i64 %176, 0
  br i1 %177, label %172, label %178, !llvm.loop !312

178:                                              ; preds = %172, %168
  %179 = getelementptr inbounds i64, ptr %49, i64 %6
  %180 = add i64 %119, %117
  %181 = load i64, ptr %179, align 8, !tbaa !15
  %182 = sub i64 %181, %180
  store i64 %182, ptr %179, align 8, !tbaa !15
  %183 = icmp ult i64 %181, %180
  br i1 %183, label %184, label %190

184:                                              ; preds = %184, %178
  %185 = phi ptr [ %186, %184 ], [ %179, %178 ]
  %186 = getelementptr inbounds i8, ptr %185, i64 8
  %187 = load i64, ptr %186, align 8, !tbaa !15
  %188 = add i64 %187, -1
  store i64 %188, ptr %186, align 8, !tbaa !15
  %189 = icmp eq i64 %187, 0
  br i1 %189, label %184, label %190, !llvm.loop !313

190:                                              ; preds = %184, %178, %162, %157
  %191 = add i64 %122, -1
  %192 = load i64, ptr %121, align 8, !tbaa !15
  %193 = add i64 %191, %192
  store i64 %193, ptr %121, align 8, !tbaa !15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_8pts(ptr noundef %0, i64 noundef %1, ptr noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = mul nsw i64 %1, 3
  %8 = getelementptr inbounds i64, ptr %0, i64 %7
  %9 = mul i64 %1, 56
  %10 = getelementptr inbounds i8, ptr %0, i64 %9
  %11 = getelementptr inbounds i64, ptr %2, i64 %1
  %12 = load i64, ptr %0, align 8, !tbaa !15
  %13 = lshr i64 %12, 4
  %14 = load i64, ptr %11, align 8, !tbaa !15
  %15 = sub i64 %14, %13
  store i64 %15, ptr %11, align 8, !tbaa !15
  %16 = load i64, ptr %0, align 8, !tbaa !15
  %17 = lshr i64 %16, 4
  %18 = icmp ult i64 %14, %17
  br i1 %18, label %19, label %25

19:                                               ; preds = %19, %6
  %20 = phi ptr [ %21, %19 ], [ %11, %6 ]
  %21 = getelementptr inbounds i8, ptr %20, i64 8
  %22 = load i64, ptr %21, align 8, !tbaa !15
  %23 = add i64 %22, -1
  store i64 %23, ptr %21, align 8, !tbaa !15
  %24 = icmp eq i64 %22, 0
  br i1 %24, label %19, label %25, !llvm.loop !314

25:                                               ; preds = %19, %6
  %26 = getelementptr inbounds i8, ptr %0, i64 8
  %27 = shl nsw i64 %1, 1
  %28 = add nsw i64 %27, -1
  %29 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %26, i64 noundef %28, i32 noundef 60) #16
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %11, ptr noundef nonnull %11, ptr noundef %5, i64 noundef %28) #16
  %31 = getelementptr inbounds i64, ptr %11, i64 %27
  %32 = getelementptr inbounds i8, ptr %31, i64 -8
  %33 = add i64 %30, %29
  %34 = load i64, ptr %32, align 8, !tbaa !15
  %35 = sub i64 %34, %33
  store i64 %35, ptr %32, align 8, !tbaa !15
  %36 = icmp ult i64 %34, %33
  br i1 %36, label %37, label %43

37:                                               ; preds = %37, %25
  %38 = phi ptr [ %39, %37 ], [ %32, %25 ]
  %39 = getelementptr inbounds i8, ptr %38, i64 8
  %40 = load i64, ptr %39, align 8, !tbaa !15
  %41 = add i64 %40, -1
  store i64 %41, ptr %39, align 8, !tbaa !15
  %42 = icmp eq i64 %40, 0
  br i1 %42, label %37, label %43, !llvm.loop !315

43:                                               ; preds = %37, %25
  %44 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %10, i64 noundef %4, i32 noundef 12) #16
  %45 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %5, i64 noundef %4) #16
  %46 = getelementptr inbounds i64, ptr %2, i64 %4
  %47 = add i64 %45, %44
  %48 = load i64, ptr %46, align 8, !tbaa !15
  %49 = sub i64 %48, %47
  store i64 %49, ptr %46, align 8, !tbaa !15
  %50 = icmp ult i64 %48, %47
  br i1 %50, label %51, label %57

51:                                               ; preds = %51, %43
  %52 = phi ptr [ %53, %51 ], [ %46, %43 ]
  %53 = getelementptr inbounds i8, ptr %52, i64 8
  %54 = load i64, ptr %53, align 8, !tbaa !15
  %55 = add i64 %54, -1
  store i64 %55, ptr %53, align 8, !tbaa !15
  %56 = icmp eq i64 %54, 0
  br i1 %56, label %51, label %57, !llvm.loop !316

57:                                               ; preds = %51, %43
  %58 = getelementptr inbounds i64, ptr %8, i64 %1
  %59 = load i64, ptr %0, align 8, !tbaa !15
  %60 = lshr i64 %59, 2
  %61 = load i64, ptr %58, align 8, !tbaa !15
  %62 = sub i64 %61, %60
  store i64 %62, ptr %58, align 8, !tbaa !15
  %63 = load i64, ptr %0, align 8, !tbaa !15
  %64 = lshr i64 %63, 2
  %65 = icmp ult i64 %61, %64
  br i1 %65, label %66, label %72

66:                                               ; preds = %66, %57
  %67 = phi ptr [ %68, %66 ], [ %58, %57 ]
  %68 = getelementptr inbounds i8, ptr %67, i64 8
  %69 = load i64, ptr %68, align 8, !tbaa !15
  %70 = add i64 %69, -1
  store i64 %70, ptr %68, align 8, !tbaa !15
  %71 = icmp eq i64 %69, 0
  br i1 %71, label %66, label %72, !llvm.loop !317

72:                                               ; preds = %66, %57
  %73 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %26, i64 noundef %28, i32 noundef 62) #16
  %74 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %58, ptr noundef nonnull %58, ptr noundef %5, i64 noundef %28) #16
  %75 = getelementptr inbounds i64, ptr %58, i64 %27
  %76 = getelementptr inbounds i8, ptr %75, i64 -8
  %77 = add i64 %74, %73
  %78 = load i64, ptr %76, align 8, !tbaa !15
  %79 = sub i64 %78, %77
  store i64 %79, ptr %76, align 8, !tbaa !15
  %80 = icmp ult i64 %78, %77
  br i1 %80, label %81, label %87

81:                                               ; preds = %81, %72
  %82 = phi ptr [ %83, %81 ], [ %76, %72 ]
  %83 = getelementptr inbounds i8, ptr %82, i64 8
  %84 = load i64, ptr %83, align 8, !tbaa !15
  %85 = add i64 %84, -1
  store i64 %85, ptr %83, align 8, !tbaa !15
  %86 = icmp eq i64 %84, 0
  br i1 %86, label %81, label %87, !llvm.loop !318

87:                                               ; preds = %81, %72
  %88 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %10, i64 noundef %4, i32 noundef 6) #16
  %89 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef %5, i64 noundef %4) #16
  %90 = getelementptr inbounds i64, ptr %8, i64 %4
  %91 = add i64 %89, %88
  %92 = load i64, ptr %90, align 8, !tbaa !15
  %93 = sub i64 %92, %91
  store i64 %93, ptr %90, align 8, !tbaa !15
  %94 = icmp ult i64 %92, %91
  br i1 %94, label %95, label %101

95:                                               ; preds = %95, %87
  %96 = phi ptr [ %97, %95 ], [ %90, %87 ]
  %97 = getelementptr inbounds i8, ptr %96, i64 8
  %98 = load i64, ptr %97, align 8, !tbaa !15
  %99 = add i64 %98, -1
  store i64 %99, ptr %97, align 8, !tbaa !15
  %100 = icmp eq i64 %98, 0
  br i1 %100, label %95, label %101, !llvm.loop !319

101:                                              ; preds = %95, %87
  %102 = getelementptr inbounds i64, ptr %3, i64 %1
  %103 = tail call i64 @__gmpn_sub_n(ptr noundef %102, ptr noundef %102, ptr noundef nonnull %0, i64 noundef %27) #16
  %104 = getelementptr inbounds i64, ptr %3, i64 %7
  %105 = load i64, ptr %104, align 8, !tbaa !15
  %106 = sub i64 %105, %103
  store i64 %106, ptr %104, align 8, !tbaa !15
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef nonnull %10, i64 noundef %4) #16
  %108 = getelementptr inbounds i64, ptr %3, i64 %4
  %109 = load i64, ptr %108, align 8, !tbaa !15
  %110 = sub i64 %109, %107
  store i64 %110, ptr %108, align 8, !tbaa !15
  %111 = icmp ult i64 %109, %107
  br i1 %111, label %112, label %118

112:                                              ; preds = %112, %101
  %113 = phi ptr [ %114, %112 ], [ %108, %101 ]
  %114 = getelementptr inbounds i8, ptr %113, i64 8
  %115 = load i64, ptr %114, align 8, !tbaa !15
  %116 = add i64 %115, -1
  store i64 %116, ptr %114, align 8, !tbaa !15
  %117 = icmp eq i64 %115, 0
  br i1 %117, label %112, label %118, !llvm.loop !320

118:                                              ; preds = %112, %101
  %119 = add nsw i64 %7, 1
  %120 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef nonnull %8, i64 noundef %119) #16
  %121 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %119, i32 noundef 2) #16
  %122 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef %3, i64 noundef %119) #16
  %123 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef nonnull %8, i64 noundef %119) #16
  tail call void @__gmpn_divexact_1(ptr noundef %2, ptr noundef %2, i64 noundef %119, i64 noundef 45) #16
  %124 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %8, ptr noundef nonnull %8, i64 noundef %119, i64 noundef 6148914691236517205, i64 noundef 0) #16
  %125 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %2, i64 noundef %119, i32 noundef 2) #16
  %126 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef %5, i64 noundef %119) #16
  %127 = getelementptr inbounds i64, ptr %0, i64 %1
  %128 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %127, ptr noundef nonnull %127, ptr noundef %3, i64 noundef %1) #16
  %129 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %127, ptr noundef nonnull %127, ptr noundef nonnull %8, i64 noundef %1) #16
  %130 = sub i64 %128, %129
  %131 = icmp sgt i64 %130, 0
  br i1 %131, label %132, label %138

132:                                              ; preds = %132, %118
  %133 = phi ptr [ %134, %132 ], [ %102, %118 ]
  %134 = getelementptr inbounds i8, ptr %133, i64 8
  %135 = load i64, ptr %133, align 8, !tbaa !15
  %136 = add i64 %135, 1
  store i64 %136, ptr %133, align 8, !tbaa !15
  %137 = icmp eq i64 %136, 0
  br i1 %137, label %132, label %138, !llvm.loop !321

138:                                              ; preds = %132, %118
  %139 = phi i64 [ %130, %118 ], [ 0, %132 ]
  %140 = getelementptr inbounds i64, ptr %0, i64 %27
  %141 = sub nsw i64 0, %139
  %142 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %140, ptr noundef %102, ptr noundef nonnull %58, i64 noundef %1) #16
  %143 = load i64, ptr %140, align 8, !tbaa !15
  %144 = add i64 %143, %139
  store i64 %144, ptr %140, align 8, !tbaa !15
  %145 = icmp ult i64 %143, %141
  br i1 %145, label %146, label %157

146:                                              ; preds = %138
  %147 = tail call i64 @llvm.smax.i64(i64 %1, i64 1)
  br label %148

148:                                              ; preds = %151, %146
  %149 = phi i64 [ %155, %151 ], [ 1, %146 ]
  %150 = icmp eq i64 %149, %147
  br i1 %150, label %157, label %151

151:                                              ; preds = %148
  %152 = getelementptr inbounds i64, ptr %140, i64 %149
  %153 = load i64, ptr %152, align 8, !tbaa !15
  %154 = add i64 %153, -1
  store i64 %154, ptr %152, align 8, !tbaa !15
  %155 = add nuw i64 %149, 1
  %156 = icmp eq i64 %153, 0
  br i1 %156, label %148, label %157, !llvm.loop !322

157:                                              ; preds = %151, %148, %138
  %158 = phi i64 [ 0, %138 ], [ 1, %148 ], [ 0, %151 ]
  %159 = getelementptr inbounds i64, ptr %3, i64 %27
  %160 = add i64 %158, %142
  %161 = load i64, ptr %159, align 8, !tbaa !15
  %162 = sub i64 %161, %160
  store i64 %162, ptr %159, align 8, !tbaa !15
  %163 = icmp ult i64 %161, %160
  br i1 %163, label %164, label %170

164:                                              ; preds = %164, %157
  %165 = phi ptr [ %166, %164 ], [ %159, %157 ]
  %166 = getelementptr inbounds i8, ptr %165, i64 8
  %167 = load i64, ptr %166, align 8, !tbaa !15
  %168 = add i64 %167, -1
  store i64 %168, ptr %166, align 8, !tbaa !15
  %169 = icmp eq i64 %167, 0
  br i1 %169, label %164, label %170, !llvm.loop !323

170:                                              ; preds = %164, %157
  %171 = add nsw i64 %1, 1
  %172 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef nonnull %159, i64 noundef %171) #16
  %173 = getelementptr inbounds i64, ptr %8, i64 %27
  %174 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef %2, i64 noundef %1) #16
  %175 = getelementptr inbounds i64, ptr %8, i64 %7
  %176 = load i64, ptr %175, align 8, !tbaa !15
  %177 = add i64 %176, %174
  store i64 %177, ptr %175, align 8, !tbaa !15
  %178 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef nonnull %173, i64 noundef %171) #16
  %179 = sub i64 %172, %178
  %180 = icmp slt i64 %179, 0
  br i1 %180, label %181, label %187, !prof !54

181:                                              ; preds = %181, %170
  %182 = phi ptr [ %183, %181 ], [ %58, %170 ]
  %183 = getelementptr inbounds i8, ptr %182, i64 8
  %184 = load i64, ptr %183, align 8, !tbaa !15
  %185 = add i64 %184, -1
  store i64 %185, ptr %183, align 8, !tbaa !15
  %186 = icmp eq i64 %184, 0
  br i1 %186, label %181, label %198, !llvm.loop !324

187:                                              ; preds = %170
  %188 = getelementptr inbounds i8, ptr %58, i64 8
  %189 = load i64, ptr %188, align 8, !tbaa !15
  %190 = add i64 %189, %179
  store i64 %190, ptr %188, align 8, !tbaa !15
  %191 = icmp ult i64 %190, %179
  br i1 %191, label %192, label %198

192:                                              ; preds = %192, %187
  %193 = phi ptr [ %194, %192 ], [ %188, %187 ]
  %194 = getelementptr inbounds i8, ptr %193, i64 8
  %195 = load i64, ptr %194, align 8, !tbaa !15
  %196 = add i64 %195, 1
  store i64 %196, ptr %194, align 8, !tbaa !15
  %197 = icmp eq i64 %196, 0
  br i1 %197, label %192, label %198, !llvm.loop !325

198:                                              ; preds = %192, %187, %181
  %199 = shl nsw i64 %1, 5
  %200 = getelementptr inbounds i8, ptr %0, i64 %199
  %201 = or disjoint i64 %27, 1
  %202 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %200, ptr noundef nonnull %58, ptr noundef nonnull %11, i64 noundef %201) #16
  %203 = mul i64 %1, 48
  %204 = getelementptr inbounds i8, ptr %0, i64 %203
  %205 = load i64, ptr %204, align 8, !tbaa !15
  %206 = load i64, ptr %11, align 8, !tbaa !15
  %207 = add i64 %206, %205
  store i64 %207, ptr %204, align 8, !tbaa !15
  %208 = icmp ult i64 %207, %205
  br i1 %208, label %209, label %232

209:                                              ; preds = %198
  %210 = tail call i64 @llvm.smax.i64(i64 %1, i64 1)
  br label %211

211:                                              ; preds = %214, %209
  %212 = phi i64 [ %219, %214 ], [ 1, %209 ]
  %213 = icmp eq i64 %212, %210
  br i1 %213, label %243, label %214

214:                                              ; preds = %211
  %215 = getelementptr inbounds i64, ptr %11, i64 %212
  %216 = load i64, ptr %215, align 8, !tbaa !15
  %217 = add i64 %216, 1
  %218 = getelementptr inbounds i64, ptr %204, i64 %212
  store i64 %217, ptr %218, align 8, !tbaa !15
  %219 = add nuw i64 %212, 1
  %220 = icmp eq i64 %217, 0
  br i1 %220, label %211, label %221, !llvm.loop !326

221:                                              ; preds = %214
  %222 = icmp ne ptr %11, %204
  %223 = icmp slt i64 %219, %1
  %224 = select i1 %222, i1 %223, i1 false
  br i1 %224, label %225, label %243

225:                                              ; preds = %225, %221
  %226 = phi i64 [ %230, %225 ], [ %219, %221 ]
  %227 = getelementptr inbounds i64, ptr %11, i64 %226
  %228 = load i64, ptr %227, align 8, !tbaa !15
  %229 = getelementptr inbounds i64, ptr %204, i64 %226
  store i64 %228, ptr %229, align 8, !tbaa !15
  %230 = add nuw nsw i64 %226, 1
  %231 = icmp slt i64 %230, %1
  br i1 %231, label %225, label %243, !llvm.loop !327

232:                                              ; preds = %198
  %233 = icmp ne ptr %11, %204
  %234 = icmp sgt i64 %1, 1
  %235 = and i1 %234, %233
  br i1 %235, label %236, label %243

236:                                              ; preds = %236, %232
  %237 = phi i64 [ %241, %236 ], [ 1, %232 ]
  %238 = getelementptr inbounds i64, ptr %11, i64 %237
  %239 = load i64, ptr %238, align 8, !tbaa !15
  %240 = getelementptr inbounds i64, ptr %204, i64 %237
  store i64 %239, ptr %240, align 8, !tbaa !15
  %241 = add nuw nsw i64 %237, 1
  %242 = icmp eq i64 %241, %1
  br i1 %242, label %243, label %236, !llvm.loop !328

243:                                              ; preds = %236, %232, %225, %221, %211
  %244 = phi i64 [ 0, %221 ], [ 0, %232 ], [ 0, %225 ], [ 1, %211 ], [ 0, %236 ]
  %245 = getelementptr inbounds i64, ptr %2, i64 %27
  %246 = load i64, ptr %245, align 8, !tbaa !15
  %247 = add i64 %246, %244
  store i64 %247, ptr %245, align 8, !tbaa !15
  %248 = icmp ult i64 %247, %244
  br i1 %248, label %249, label %255

249:                                              ; preds = %249, %243
  %250 = phi ptr [ %251, %249 ], [ %245, %243 ]
  %251 = getelementptr inbounds i8, ptr %250, i64 8
  %252 = load i64, ptr %251, align 8, !tbaa !15
  %253 = add i64 %252, 1
  store i64 %253, ptr %251, align 8, !tbaa !15
  %254 = icmp eq i64 %253, 0
  br i1 %254, label %249, label %255, !llvm.loop !329

255:                                              ; preds = %249, %243
  %256 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %10, ptr noundef nonnull %10, ptr noundef nonnull %245, i64 noundef %1) #16
  %257 = icmp eq i64 %4, %1
  br i1 %257, label %275, label %258, !prof !54

258:                                              ; preds = %255
  %259 = shl nsw i64 %1, 6
  %260 = getelementptr inbounds i8, ptr %0, i64 %259
  %261 = getelementptr inbounds i64, ptr %2, i64 %7
  %262 = load i64, ptr %261, align 8, !tbaa !15
  %263 = add i64 %262, %256
  %264 = load i64, ptr %260, align 8, !tbaa !15
  %265 = add i64 %264, %263
  store i64 %265, ptr %260, align 8, !tbaa !15
  %266 = load i64, ptr %261, align 8, !tbaa !15
  %267 = add i64 %266, %256
  %268 = icmp ult i64 %265, %267
  br i1 %268, label %269, label %275

269:                                              ; preds = %269, %258
  %270 = phi ptr [ %271, %269 ], [ %260, %258 ]
  %271 = getelementptr inbounds i8, ptr %270, i64 8
  %272 = load i64, ptr %271, align 8, !tbaa !15
  %273 = add i64 %272, 1
  store i64 %273, ptr %271, align 8, !tbaa !15
  %274 = icmp eq i64 %273, 0
  br i1 %274, label %269, label %275, !llvm.loop !330

275:                                              ; preds = %269, %258, %255
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.smin.i64(i64, i64) #10

; Function Attrs: nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_divrem_1(ptr nocapture noundef writeonly %0, i64 noundef %1, ptr nocapture noundef readonly %2, i64 noundef %3, i64 noundef %4) local_unnamed_addr #15 {
  %6 = add nsw i64 %3, %1
  %7 = icmp eq i64 %6, 0
  br i1 %7, label %387, label %8

8:                                                ; preds = %5
  %9 = getelementptr i64, ptr %0, i64 %6
  %10 = getelementptr i8, ptr %9, i64 -8
  %11 = icmp sgt i64 %4, -1
  %12 = icmp eq i64 %3, 0
  br i1 %11, label %159, label %13

13:                                               ; preds = %8
  br i1 %12, label %24, label %14

14:                                               ; preds = %13
  %15 = getelementptr i64, ptr %2, i64 %3
  %16 = getelementptr i8, ptr %15, i64 -8
  %17 = load i64, ptr %16, align 8, !tbaa !15
  %18 = icmp uge i64 %17, %4
  %19 = zext i1 %18 to i64
  %20 = getelementptr i8, ptr %9, i64 -16
  store i64 %19, ptr %10, align 8, !tbaa !15
  %21 = select i1 %18, i64 %4, i64 0
  %22 = sub i64 %17, %21
  %23 = add nsw i64 %3, -2
  br label %24

24:                                               ; preds = %14, %13
  %25 = phi i64 [ %22, %14 ], [ 0, %13 ]
  %26 = phi i64 [ %23, %14 ], [ -1, %13 ]
  %27 = phi ptr [ %20, %14 ], [ %10, %13 ]
  %28 = lshr i64 %4, 32
  %29 = and i64 %4, 4294967295
  %30 = xor i64 %4, -1
  %31 = udiv i64 %30, %28
  %32 = mul nuw i64 %31, %28
  %33 = urem i64 %30, %28
  %34 = mul nuw i64 %31, %29
  %35 = shl i64 %33, 32
  %36 = or disjoint i64 %35, 4294967295
  %37 = icmp ult i64 %36, %34
  br i1 %37, label %38, label %47

38:                                               ; preds = %24
  %39 = add nsw i64 %31, -1
  %40 = add i64 %36, %4
  %41 = icmp uge i64 %40, %4
  %42 = icmp ult i64 %40, %34
  %43 = and i1 %41, %42
  br i1 %43, label %44, label %47

44:                                               ; preds = %38
  %45 = add nsw i64 %31, -2
  %46 = add i64 %40, %4
  br label %47

47:                                               ; preds = %44, %38, %24
  %48 = phi i64 [ %46, %44 ], [ %40, %38 ], [ %36, %24 ]
  %49 = phi i64 [ %45, %44 ], [ %39, %38 ], [ %31, %24 ]
  %50 = sub i64 %48, %34
  %51 = udiv i64 %50, %28
  %52 = mul i64 %51, %28
  %53 = urem i64 %50, %28
  %54 = mul i64 %51, %29
  %55 = shl i64 %53, 32
  %56 = or disjoint i64 %55, 4294967295
  %57 = icmp ult i64 %56, %54
  br i1 %57, label %58, label %65

58:                                               ; preds = %47
  %59 = add i64 %56, %4
  %60 = icmp uge i64 %59, %4
  %61 = icmp ult i64 %59, %54
  %62 = and i1 %60, %61
  %63 = select i1 %62, i64 -2, i64 -1
  %64 = add nsw i64 %63, %51
  br label %65

65:                                               ; preds = %58, %47
  %66 = phi i64 [ %51, %47 ], [ %64, %58 ]
  %67 = shl i64 %49, 32
  %68 = or i64 %66, %67
  %69 = icmp sgt i64 %26, -1
  br i1 %69, label %70, label %73

70:                                               ; preds = %65
  %71 = lshr i64 %68, 32
  %72 = and i64 %66, 4294967295
  br label %80

73:                                               ; preds = %120, %65
  %74 = phi i64 [ %25, %65 ], [ %121, %120 ]
  %75 = phi ptr [ %27, %65 ], [ %123, %120 ]
  %76 = icmp sgt i64 %1, 0
  br i1 %76, label %77, label %387

77:                                               ; preds = %73
  %78 = lshr i64 %68, 32
  %79 = and i64 %66, 4294967295
  br label %126

80:                                               ; preds = %120, %70
  %81 = phi ptr [ %27, %70 ], [ %123, %120 ]
  %82 = phi i64 [ %26, %70 ], [ %124, %120 ]
  %83 = phi i64 [ %25, %70 ], [ %121, %120 ]
  %84 = lshr i64 %83, 32
  %85 = mul nuw i64 %84, %72
  %86 = and i64 %83, 4294967295
  %87 = mul nuw i64 %86, %71
  %88 = add i64 %85, %87
  %89 = mul nuw i64 %86, %72
  %90 = lshr i64 %89, 32
  %91 = add i64 %88, %90
  %92 = shl i64 %91, 32
  %93 = and i64 %89, 4294967295
  %94 = or disjoint i64 %92, %93
  %95 = icmp ult i64 %91, %85
  %96 = mul nuw i64 %84, %71
  %97 = add nuw i64 %96, 4294967296
  %98 = select i1 %95, i64 %97, i64 %96
  %99 = lshr i64 %91, 32
  %100 = add i64 %98, %99
  %101 = getelementptr inbounds i64, ptr %2, i64 %82
  %102 = load i64, ptr %101, align 8, !tbaa !15
  %103 = add i64 %102, %94
  %104 = add i64 %83, 1
  %105 = add i64 %104, %100
  %106 = icmp ult i64 %103, %94
  %107 = zext i1 %106 to i64
  %108 = add i64 %105, %107
  %109 = mul i64 %108, %4
  %110 = sub i64 %102, %109
  %111 = icmp ugt i64 %110, %103
  %112 = sext i1 %111 to i64
  %113 = add i64 %108, %112
  %114 = select i1 %111, i64 %4, i64 0
  %115 = add i64 %114, %110
  %116 = icmp ult i64 %115, %4
  br i1 %116, label %120, label %117, !prof !68

117:                                              ; preds = %80
  %118 = sub i64 %115, %4
  %119 = add i64 %113, 1
  br label %120

120:                                              ; preds = %117, %80
  %121 = phi i64 [ %118, %117 ], [ %115, %80 ]
  %122 = phi i64 [ %119, %117 ], [ %113, %80 ]
  store i64 %122, ptr %81, align 8, !tbaa !15
  %123 = getelementptr inbounds i8, ptr %81, i64 -8
  %124 = add nsw i64 %82, -1
  %125 = icmp sgt i64 %82, 0
  br i1 %125, label %80, label %73, !llvm.loop !331

126:                                              ; preds = %126, %77
  %127 = phi ptr [ %75, %77 ], [ %157, %126 ]
  %128 = phi i64 [ %1, %77 ], [ %130, %126 ]
  %129 = phi i64 [ %74, %77 ], [ %156, %126 ]
  %130 = add nsw i64 %128, -1
  %131 = lshr i64 %129, 32
  %132 = and i64 %129, 4294967295
  %133 = mul nuw i64 %132, %79
  %134 = mul nuw i64 %132, %78
  %135 = mul nuw i64 %131, %79
  %136 = mul nuw i64 %131, %78
  %137 = lshr i64 %133, 32
  %138 = add i64 %135, %134
  %139 = add i64 %138, %137
  %140 = icmp ult i64 %139, %135
  %141 = add nuw i64 %136, 4294967296
  %142 = select i1 %140, i64 %141, i64 %136
  %143 = lshr i64 %139, 32
  %144 = shl i64 %139, 32
  %145 = and i64 %133, 4294967295
  %146 = or disjoint i64 %144, %145
  %147 = add i64 %129, 1
  %148 = add i64 %147, %143
  %149 = add i64 %148, %142
  %150 = mul i64 %149, %4
  %151 = sub i64 0, %150
  %152 = icmp ult i64 %146, %151
  %153 = sext i1 %152 to i64
  %154 = add i64 %149, %153
  %155 = select i1 %152, i64 %4, i64 0
  %156 = sub i64 %155, %150
  store i64 %154, ptr %127, align 8, !tbaa !15
  %157 = getelementptr inbounds i8, ptr %127, i64 -8
  %158 = icmp sgt i64 %128, 1
  br i1 %158, label %126, label %387, !llvm.loop !332

159:                                              ; preds = %8
  br i1 %12, label %170, label %160

160:                                              ; preds = %159
  %161 = getelementptr i64, ptr %2, i64 %3
  %162 = getelementptr i8, ptr %161, i64 -8
  %163 = load i64, ptr %162, align 8, !tbaa !15
  %164 = icmp ult i64 %163, %4
  br i1 %164, label %165, label %170

165:                                              ; preds = %160
  store i64 0, ptr %10, align 8, !tbaa !15
  %166 = icmp eq i64 %6, 1
  br i1 %166, label %387, label %167

167:                                              ; preds = %165
  %168 = getelementptr i8, ptr %9, i64 -16
  %169 = add nsw i64 %3, -1
  br label %170

170:                                              ; preds = %167, %160, %159
  %171 = phi i64 [ %163, %167 ], [ 0, %160 ], [ 0, %159 ]
  %172 = phi i64 [ %169, %167 ], [ %3, %160 ], [ 0, %159 ]
  %173 = phi ptr [ %168, %167 ], [ %10, %160 ], [ %10, %159 ]
  br label %174

174:                                              ; preds = %179, %170
  %175 = phi i64 [ 56, %170 ], [ %180, %179 ]
  %176 = shl i64 255, %175
  %177 = and i64 %176, %4
  %178 = icmp eq i64 %177, 0
  br i1 %178, label %179, label %182

179:                                              ; preds = %174
  %180 = add nsw i64 %175, -8
  %181 = icmp eq i64 %180, 0
  br i1 %181, label %182, label %174, !llvm.loop !333

182:                                              ; preds = %179, %174
  %183 = phi i64 [ %175, %174 ], [ 0, %179 ]
  %184 = or disjoint i64 %183, 1
  %185 = lshr i64 %4, %184
  %186 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %185
  %187 = load i8, ptr %186, align 1, !tbaa !155
  %188 = zext i8 %187 to i64
  %189 = add i64 %184, %188
  %190 = sub i64 65, %189
  %191 = and i64 %190, 4294967295
  %192 = shl i64 %4, %191
  %193 = shl i64 %171, %191
  %194 = lshr i64 %192, 32
  %195 = and i64 %192, 4294967295
  %196 = xor i64 %192, -1
  %197 = udiv i64 %196, %194
  %198 = mul i64 %194, %197
  %199 = urem i64 %196, %194
  %200 = mul i64 %195, %197
  %201 = shl i64 %199, 32
  %202 = or disjoint i64 %201, 4294967295
  %203 = icmp ult i64 %202, %200
  br i1 %203, label %204, label %213

204:                                              ; preds = %182
  %205 = add i64 %197, -1
  %206 = add i64 %202, %192
  %207 = icmp uge i64 %206, %192
  %208 = icmp ult i64 %206, %200
  %209 = and i1 %207, %208
  br i1 %209, label %210, label %213

210:                                              ; preds = %204
  %211 = add i64 %197, -2
  %212 = add i64 %206, %192
  br label %213

213:                                              ; preds = %210, %204, %182
  %214 = phi i64 [ %212, %210 ], [ %206, %204 ], [ %202, %182 ]
  %215 = phi i64 [ %211, %210 ], [ %205, %204 ], [ %197, %182 ]
  %216 = sub i64 %214, %200
  %217 = udiv i64 %216, %194
  %218 = mul i64 %217, %194
  %219 = urem i64 %216, %194
  %220 = mul i64 %217, %195
  %221 = shl i64 %219, 32
  %222 = or disjoint i64 %221, 4294967295
  %223 = icmp ult i64 %222, %220
  br i1 %223, label %224, label %231

224:                                              ; preds = %213
  %225 = add i64 %222, %192
  %226 = icmp uge i64 %225, %192
  %227 = icmp ult i64 %225, %220
  %228 = and i1 %226, %227
  %229 = select i1 %228, i64 -2, i64 -1
  %230 = add i64 %229, %217
  br label %231

231:                                              ; preds = %224, %213
  %232 = phi i64 [ %217, %213 ], [ %230, %224 ]
  %233 = shl i64 %215, 32
  %234 = or i64 %232, %233
  %235 = icmp eq i64 %172, 0
  br i1 %235, label %344, label %236

236:                                              ; preds = %231
  %237 = getelementptr i64, ptr %2, i64 %172
  %238 = getelementptr i8, ptr %237, i64 -8
  %239 = load i64, ptr %238, align 8, !tbaa !15
  %240 = add i64 %189, 4294967295
  %241 = and i64 %240, 4294967295
  %242 = lshr i64 %239, %241
  %243 = or i64 %242, %193
  %244 = icmp sgt i64 %172, 1
  br i1 %244, label %245, label %299

245:                                              ; preds = %236
  %246 = add nsw i64 %172, -2
  %247 = lshr i64 %234, 32
  %248 = and i64 %232, 4294967295
  br label %249

249:                                              ; preds = %293, %245
  %250 = phi ptr [ %173, %245 ], [ %296, %293 ]
  %251 = phi i64 [ %246, %245 ], [ %297, %293 ]
  %252 = phi i64 [ %239, %245 ], [ %255, %293 ]
  %253 = phi i64 [ %243, %245 ], [ %294, %293 ]
  %254 = getelementptr inbounds i64, ptr %2, i64 %251
  %255 = load i64, ptr %254, align 8, !tbaa !15
  %256 = lshr i64 %253, 32
  %257 = mul nuw i64 %256, %248
  %258 = and i64 %253, 4294967295
  %259 = mul nuw i64 %258, %247
  %260 = add i64 %257, %259
  %261 = mul nuw i64 %258, %248
  %262 = lshr i64 %261, 32
  %263 = add i64 %260, %262
  %264 = shl i64 %263, 32
  %265 = and i64 %261, 4294967295
  %266 = or disjoint i64 %264, %265
  %267 = icmp ult i64 %263, %257
  %268 = mul nuw i64 %256, %247
  %269 = add nuw i64 %268, 4294967296
  %270 = select i1 %267, i64 %269, i64 %268
  %271 = lshr i64 %263, 32
  %272 = add i64 %270, %271
  %273 = lshr i64 %255, %241
  %274 = shl i64 %252, %191
  %275 = or i64 %273, %274
  %276 = add i64 %275, %266
  %277 = add i64 %253, 1
  %278 = add i64 %277, %272
  %279 = icmp ult i64 %276, %266
  %280 = zext i1 %279 to i64
  %281 = add i64 %278, %280
  %282 = mul i64 %281, %192
  %283 = sub i64 %275, %282
  %284 = icmp ugt i64 %283, %276
  %285 = sext i1 %284 to i64
  %286 = add i64 %281, %285
  %287 = select i1 %284, i64 %192, i64 0
  %288 = add i64 %287, %283
  %289 = icmp ult i64 %288, %192
  br i1 %289, label %293, label %290, !prof !68

290:                                              ; preds = %249
  %291 = sub i64 %288, %192
  %292 = add i64 %286, 1
  br label %293

293:                                              ; preds = %290, %249
  %294 = phi i64 [ %291, %290 ], [ %288, %249 ]
  %295 = phi i64 [ %292, %290 ], [ %286, %249 ]
  store i64 %295, ptr %250, align 8, !tbaa !15
  %296 = getelementptr inbounds i8, ptr %250, i64 -8
  %297 = add nsw i64 %251, -1
  %298 = icmp sgt i64 %251, 0
  br i1 %298, label %249, label %299, !llvm.loop !334

299:                                              ; preds = %293, %236
  %300 = phi i64 [ %243, %236 ], [ %294, %293 ]
  %301 = phi i64 [ %239, %236 ], [ %255, %293 ]
  %302 = phi ptr [ %173, %236 ], [ %296, %293 ]
  %303 = shl i64 %301, %191
  %304 = lshr i64 %300, 32
  %305 = and i64 %232, 4294967295
  %306 = mul nuw i64 %304, %305
  %307 = and i64 %300, 4294967295
  %308 = lshr i64 %234, 32
  %309 = mul nuw i64 %307, %308
  %310 = add i64 %306, %309
  %311 = mul nuw i64 %307, %305
  %312 = lshr i64 %311, 32
  %313 = add i64 %310, %312
  %314 = shl i64 %313, 32
  %315 = and i64 %311, 4294967295
  %316 = or disjoint i64 %314, %315
  %317 = icmp ult i64 %313, %306
  %318 = mul nuw i64 %304, %308
  %319 = add nuw i64 %318, 4294967296
  %320 = select i1 %317, i64 %319, i64 %318
  %321 = lshr i64 %313, 32
  %322 = add i64 %320, %321
  %323 = add i64 %316, %303
  %324 = add i64 %300, 1
  %325 = add i64 %324, %322
  %326 = icmp ult i64 %323, %316
  %327 = zext i1 %326 to i64
  %328 = add i64 %325, %327
  %329 = mul i64 %328, %192
  %330 = sub i64 %303, %329
  %331 = icmp ugt i64 %330, %323
  %332 = sext i1 %331 to i64
  %333 = add i64 %328, %332
  %334 = select i1 %331, i64 %192, i64 0
  %335 = add i64 %334, %330
  %336 = icmp ult i64 %335, %192
  br i1 %336, label %340, label %337, !prof !68

337:                                              ; preds = %299
  %338 = sub i64 %335, %192
  %339 = add i64 %333, 1
  br label %340

340:                                              ; preds = %337, %299
  %341 = phi i64 [ %339, %337 ], [ %333, %299 ]
  %342 = phi i64 [ %338, %337 ], [ %335, %299 ]
  store i64 %341, ptr %302, align 8, !tbaa !15
  %343 = getelementptr inbounds i8, ptr %302, i64 -8
  br label %344

344:                                              ; preds = %340, %231
  %345 = phi i64 [ %342, %340 ], [ %193, %231 ]
  %346 = phi ptr [ %343, %340 ], [ %173, %231 ]
  %347 = icmp sgt i64 %1, 0
  br i1 %347, label %348, label %384

348:                                              ; preds = %344
  %349 = lshr i64 %234, 32
  %350 = and i64 %232, 4294967295
  br label %351

351:                                              ; preds = %351, %348
  %352 = phi ptr [ %346, %348 ], [ %382, %351 ]
  %353 = phi i64 [ %1, %348 ], [ %355, %351 ]
  %354 = phi i64 [ %345, %348 ], [ %381, %351 ]
  %355 = add nsw i64 %353, -1
  %356 = lshr i64 %354, 32
  %357 = and i64 %354, 4294967295
  %358 = mul nuw i64 %357, %350
  %359 = mul nuw i64 %357, %349
  %360 = mul nuw i64 %356, %350
  %361 = mul nuw i64 %356, %349
  %362 = lshr i64 %358, 32
  %363 = add i64 %360, %359
  %364 = add i64 %363, %362
  %365 = icmp ult i64 %364, %360
  %366 = add nuw i64 %361, 4294967296
  %367 = select i1 %365, i64 %366, i64 %361
  %368 = lshr i64 %364, 32
  %369 = shl i64 %364, 32
  %370 = and i64 %358, 4294967295
  %371 = or disjoint i64 %369, %370
  %372 = add i64 %354, 1
  %373 = add i64 %372, %368
  %374 = add i64 %373, %367
  %375 = mul i64 %374, %192
  %376 = sub i64 0, %375
  %377 = icmp ult i64 %371, %376
  %378 = sext i1 %377 to i64
  %379 = add i64 %374, %378
  %380 = select i1 %377, i64 %192, i64 0
  %381 = sub i64 %380, %375
  store i64 %379, ptr %352, align 8, !tbaa !15
  %382 = getelementptr inbounds i8, ptr %352, i64 -8
  %383 = icmp sgt i64 %353, 1
  br i1 %383, label %351, label %384, !llvm.loop !335

384:                                              ; preds = %351, %344
  %385 = phi i64 [ %345, %344 ], [ %381, %351 ]
  %386 = lshr i64 %385, %191
  br label %387

387:                                              ; preds = %384, %165, %126, %73, %5
  %388 = phi i64 [ 0, %5 ], [ %386, %384 ], [ %163, %165 ], [ %74, %73 ], [ %156, %126 ]
  ret i64 %388
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define range(i64 0, 2) i64 @__gmpn_divrem_2(ptr nocapture noundef writeonly %0, i64 noundef %1, ptr nocapture noundef %2, i64 noundef %3, ptr nocapture noundef readonly %4) local_unnamed_addr #6 {
  %6 = getelementptr i64, ptr %2, i64 %3
  %7 = getelementptr i8, ptr %6, i64 -16
  %8 = getelementptr inbounds i8, ptr %4, i64 8
  %9 = load i64, ptr %8, align 8, !tbaa !15
  %10 = load i64, ptr %4, align 8, !tbaa !15
  %11 = getelementptr i8, ptr %6, i64 -8
  %12 = load i64, ptr %11, align 8, !tbaa !15
  %13 = load i64, ptr %7, align 8, !tbaa !15
  %14 = icmp ult i64 %12, %9
  br i1 %14, label %24, label %15

15:                                               ; preds = %5
  %16 = icmp ule i64 %12, %9
  %17 = icmp ult i64 %13, %10
  %18 = select i1 %16, i1 %17, i1 false
  br i1 %18, label %24, label %19

19:                                               ; preds = %15
  %20 = sub i64 %13, %10
  %21 = sub i64 %12, %9
  %22 = sext i1 %17 to i64
  %23 = add i64 %21, %22
  br label %24

24:                                               ; preds = %19, %15, %5
  %25 = phi i64 [ %20, %19 ], [ %13, %5 ], [ %13, %15 ]
  %26 = phi i64 [ %23, %19 ], [ %12, %5 ], [ %12, %15 ]
  %27 = phi i64 [ 1, %19 ], [ 0, %5 ], [ 0, %15 ]
  %28 = lshr i64 %9, 32
  %29 = and i64 %9, 4294967295
  %30 = xor i64 %9, -1
  %31 = udiv i64 %30, %28
  %32 = mul i64 %31, %28
  %33 = urem i64 %30, %28
  %34 = mul i64 %31, %29
  %35 = shl i64 %33, 32
  %36 = or disjoint i64 %35, 4294967295
  %37 = icmp ult i64 %36, %34
  br i1 %37, label %38, label %47

38:                                               ; preds = %24
  %39 = add i64 %31, -1
  %40 = add i64 %36, %9
  %41 = icmp uge i64 %40, %9
  %42 = icmp ult i64 %40, %34
  %43 = and i1 %41, %42
  br i1 %43, label %44, label %47

44:                                               ; preds = %38
  %45 = add i64 %31, -2
  %46 = add i64 %40, %9
  br label %47

47:                                               ; preds = %44, %38, %24
  %48 = phi i64 [ %46, %44 ], [ %40, %38 ], [ %36, %24 ]
  %49 = phi i64 [ %45, %44 ], [ %39, %38 ], [ %31, %24 ]
  %50 = sub i64 %48, %34
  %51 = udiv i64 %50, %28
  %52 = mul i64 %51, %28
  %53 = urem i64 %50, %28
  %54 = mul i64 %51, %29
  %55 = shl i64 %53, 32
  %56 = or disjoint i64 %55, 4294967295
  %57 = icmp ult i64 %56, %54
  br i1 %57, label %58, label %65

58:                                               ; preds = %47
  %59 = add i64 %56, %9
  %60 = icmp uge i64 %59, %9
  %61 = icmp ult i64 %59, %54
  %62 = and i1 %60, %61
  %63 = select i1 %62, i64 -2, i64 -1
  %64 = add i64 %63, %51
  br label %65

65:                                               ; preds = %58, %47
  %66 = phi i64 [ %51, %47 ], [ %64, %58 ]
  %67 = shl i64 %49, 32
  %68 = or i64 %66, %67
  %69 = mul i64 %68, %9
  %70 = add i64 %69, %10
  %71 = icmp ult i64 %70, %10
  br i1 %71, label %72, label %80

72:                                               ; preds = %65
  %73 = add i64 %68, -1
  %74 = icmp uge i64 %70, %9
  %75 = sext i1 %74 to i64
  %76 = add i64 %73, %75
  %77 = select i1 %74, i64 %9, i64 0
  %78 = add i64 %9, %77
  %79 = sub i64 %70, %78
  br label %80

80:                                               ; preds = %72, %65
  %81 = phi i64 [ %79, %72 ], [ %70, %65 ]
  %82 = phi i64 [ %76, %72 ], [ %68, %65 ]
  %83 = lshr i64 %10, 32
  %84 = lshr i64 %82, 32
  %85 = and i64 %10, 4294967295
  %86 = and i64 %82, 4294967295
  %87 = mul nuw i64 %86, %85
  %88 = mul nuw i64 %84, %85
  %89 = mul nuw i64 %86, %83
  %90 = mul nuw i64 %84, %83
  %91 = lshr i64 %87, 32
  %92 = add i64 %89, %88
  %93 = add i64 %92, %91
  %94 = icmp ult i64 %93, %89
  %95 = add nuw i64 %90, 4294967296
  %96 = select i1 %94, i64 %95, i64 %90
  %97 = lshr i64 %93, 32
  %98 = add i64 %96, %97
  %99 = shl i64 %93, 32
  %100 = and i64 %87, 4294967295
  %101 = or disjoint i64 %99, %100
  %102 = add i64 %98, %81
  %103 = icmp ult i64 %102, %98
  br i1 %103, label %104, label %113

104:                                              ; preds = %80
  %105 = add i64 %82, -1
  %106 = icmp ult i64 %102, %9
  br i1 %106, label %113, label %107, !prof !68

107:                                              ; preds = %104
  %108 = icmp ule i64 %102, %9
  %109 = icmp ult i64 %101, %10
  %110 = select i1 %108, i1 %109, i1 false
  %111 = add i64 %82, -2
  %112 = select i1 %110, i64 %105, i64 %111
  br label %113

113:                                              ; preds = %107, %104, %80
  %114 = phi i64 [ %105, %104 ], [ %82, %80 ], [ %112, %107 ]
  %115 = getelementptr inbounds i64, ptr %0, i64 %1
  %116 = icmp sgt i64 %3, 2
  br i1 %116, label %117, label %208

117:                                              ; preds = %113
  %118 = add nsw i64 %3, -3
  %119 = lshr i64 %114, 32
  %120 = and i64 %114, 4294967295
  br label %121

121:                                              ; preds = %201, %117
  %122 = phi ptr [ %7, %117 ], [ %126, %201 ]
  %123 = phi i64 [ %118, %117 ], [ %206, %201 ]
  %124 = phi i64 [ %26, %117 ], [ %204, %201 ]
  %125 = phi i64 [ %25, %117 ], [ %203, %201 ]
  %126 = getelementptr inbounds i8, ptr %122, i64 -8
  %127 = load i64, ptr %126, align 8, !tbaa !15
  %128 = lshr i64 %124, 32
  %129 = and i64 %124, 4294967295
  %130 = mul nuw i64 %129, %120
  %131 = mul nuw i64 %129, %119
  %132 = mul nuw i64 %128, %120
  %133 = mul nuw i64 %128, %119
  %134 = lshr i64 %130, 32
  %135 = add i64 %132, %131
  %136 = add i64 %135, %134
  %137 = icmp ult i64 %136, %132
  %138 = add nuw i64 %133, 4294967296
  %139 = select i1 %137, i64 %138, i64 %133
  %140 = lshr i64 %136, 32
  %141 = shl i64 %136, 32
  %142 = and i64 %130, 4294967295
  %143 = or disjoint i64 %141, %142
  %144 = add i64 %143, %125
  %145 = icmp ult i64 %144, %143
  %146 = zext i1 %145 to i64
  %147 = add i64 %140, %124
  %148 = add i64 %147, %139
  %149 = add i64 %148, %146
  %150 = sub i64 %127, %10
  %151 = xor i64 %149, -1
  %152 = mul i64 %9, %151
  %153 = icmp ult i64 %127, %10
  %154 = sext i1 %153 to i64
  %155 = lshr i64 %149, 32
  %156 = and i64 %149, 4294967295
  %157 = mul nuw i64 %156, %85
  %158 = mul nuw i64 %155, %85
  %159 = mul nuw i64 %156, %83
  %160 = mul nuw i64 %155, %83
  %161 = lshr i64 %157, 32
  %162 = add i64 %159, %158
  %163 = add i64 %162, %161
  %164 = icmp ult i64 %163, %159
  %165 = add nuw i64 %160, 4294967296
  %166 = select i1 %164, i64 %165, i64 %160
  %167 = lshr i64 %163, 32
  %168 = shl i64 %163, 32
  %169 = and i64 %157, 4294967295
  %170 = or disjoint i64 %168, %169
  %171 = sub i64 %150, %170
  %172 = icmp ult i64 %150, %170
  %173 = sext i1 %172 to i64
  %174 = add i64 %152, %125
  %175 = add i64 %167, %166
  %176 = sub i64 %174, %175
  %177 = add i64 %176, %154
  %178 = add i64 %177, %173
  %179 = add i64 %149, 1
  %180 = icmp uge i64 %178, %144
  %181 = sext i1 %180 to i64
  %182 = add i64 %179, %181
  %183 = select i1 %180, i64 %10, i64 0
  %184 = add i64 %183, %171
  %185 = select i1 %180, i64 %9, i64 0
  %186 = add i64 %185, %178
  %187 = icmp ult i64 %184, %171
  %188 = zext i1 %187 to i64
  %189 = add i64 %186, %188
  %190 = icmp ult i64 %189, %9
  br i1 %190, label %201, label %191, !prof !68

191:                                              ; preds = %121
  %192 = icmp ule i64 %189, %9
  %193 = icmp ult i64 %184, %10
  %194 = select i1 %192, i1 %193, i1 false
  br i1 %194, label %201, label %195

195:                                              ; preds = %191
  %196 = add i64 %182, 1
  %197 = sub i64 %184, %10
  %198 = sext i1 %193 to i64
  %199 = sub i64 %198, %9
  %200 = add i64 %199, %189
  br label %201

201:                                              ; preds = %195, %191, %121
  %202 = phi i64 [ %196, %195 ], [ %182, %121 ], [ %182, %191 ]
  %203 = phi i64 [ %197, %195 ], [ %184, %121 ], [ %184, %191 ]
  %204 = phi i64 [ %200, %195 ], [ %189, %121 ], [ %189, %191 ]
  %205 = getelementptr inbounds i64, ptr %115, i64 %123
  store i64 %202, ptr %205, align 8, !tbaa !15
  %206 = add nsw i64 %123, -1
  %207 = icmp sgt i64 %123, 0
  br i1 %207, label %121, label %208, !llvm.loop !336

208:                                              ; preds = %201, %113
  %209 = phi i64 [ %25, %113 ], [ %203, %201 ]
  %210 = phi i64 [ %26, %113 ], [ %204, %201 ]
  %211 = phi ptr [ %7, %113 ], [ %2, %201 ]
  %212 = icmp eq i64 %1, 0
  br i1 %212, label %302, label %213, !prof !68

213:                                              ; preds = %208
  %214 = icmp sgt i64 %1, 0
  br i1 %214, label %215, label %302

215:                                              ; preds = %213
  %216 = lshr i64 %114, 32
  %217 = and i64 %114, 4294967295
  %218 = sub i64 0, %10
  %219 = icmp ne i64 %10, 0
  %220 = sext i1 %219 to i64
  br label %221

221:                                              ; preds = %296, %215
  %222 = phi i64 [ %1, %215 ], [ %225, %296 ]
  %223 = phi i64 [ %210, %215 ], [ %299, %296 ]
  %224 = phi i64 [ %209, %215 ], [ %298, %296 ]
  %225 = add nsw i64 %222, -1
  %226 = lshr i64 %223, 32
  %227 = and i64 %223, 4294967295
  %228 = mul nuw i64 %227, %217
  %229 = mul nuw i64 %227, %216
  %230 = mul nuw i64 %226, %217
  %231 = mul nuw i64 %226, %216
  %232 = lshr i64 %228, 32
  %233 = add i64 %230, %229
  %234 = add i64 %233, %232
  %235 = icmp ult i64 %234, %230
  %236 = add nuw i64 %231, 4294967296
  %237 = select i1 %235, i64 %236, i64 %231
  %238 = lshr i64 %234, 32
  %239 = shl i64 %234, 32
  %240 = and i64 %228, 4294967295
  %241 = or disjoint i64 %239, %240
  %242 = add i64 %241, %224
  %243 = icmp ult i64 %242, %241
  %244 = zext i1 %243 to i64
  %245 = add i64 %238, %223
  %246 = add i64 %245, %237
  %247 = add i64 %246, %244
  %248 = xor i64 %247, -1
  %249 = mul i64 %9, %248
  %250 = lshr i64 %247, 32
  %251 = and i64 %247, 4294967295
  %252 = mul nuw i64 %251, %85
  %253 = mul nuw i64 %250, %85
  %254 = mul nuw i64 %251, %83
  %255 = mul nuw i64 %250, %83
  %256 = lshr i64 %252, 32
  %257 = add i64 %254, %253
  %258 = add i64 %257, %256
  %259 = icmp ult i64 %258, %254
  %260 = add nuw i64 %255, 4294967296
  %261 = select i1 %259, i64 %260, i64 %255
  %262 = lshr i64 %258, 32
  %263 = shl i64 %258, 32
  %264 = and i64 %252, 4294967295
  %265 = or disjoint i64 %263, %264
  %266 = sub i64 %218, %265
  %267 = icmp ugt i64 %265, %218
  %268 = sext i1 %267 to i64
  %269 = add i64 %224, %220
  %270 = add i64 %269, %249
  %271 = add i64 %262, %261
  %272 = sub i64 %270, %271
  %273 = add i64 %272, %268
  %274 = add i64 %247, 1
  %275 = icmp uge i64 %273, %242
  %276 = sext i1 %275 to i64
  %277 = add i64 %274, %276
  %278 = select i1 %275, i64 %10, i64 0
  %279 = add i64 %278, %266
  %280 = select i1 %275, i64 %9, i64 0
  %281 = add i64 %280, %273
  %282 = icmp ult i64 %279, %266
  %283 = zext i1 %282 to i64
  %284 = add i64 %281, %283
  %285 = icmp ult i64 %284, %9
  br i1 %285, label %296, label %286, !prof !68

286:                                              ; preds = %221
  %287 = icmp ule i64 %284, %9
  %288 = icmp ult i64 %279, %10
  %289 = select i1 %287, i1 %288, i1 false
  br i1 %289, label %296, label %290

290:                                              ; preds = %286
  %291 = add i64 %277, 1
  %292 = sub i64 %279, %10
  %293 = sext i1 %288 to i64
  %294 = sub i64 %293, %9
  %295 = add i64 %294, %284
  br label %296

296:                                              ; preds = %290, %286, %221
  %297 = phi i64 [ %291, %290 ], [ %277, %221 ], [ %277, %286 ]
  %298 = phi i64 [ %292, %290 ], [ %279, %221 ], [ %279, %286 ]
  %299 = phi i64 [ %295, %290 ], [ %284, %221 ], [ %284, %286 ]
  %300 = getelementptr inbounds i64, ptr %0, i64 %225
  store i64 %297, ptr %300, align 8, !tbaa !15
  %301 = icmp sgt i64 %222, 1
  br i1 %301, label %221, label %302, !llvm.loop !337

302:                                              ; preds = %296, %213, %208
  %303 = phi i64 [ %209, %208 ], [ %209, %213 ], [ %298, %296 ]
  %304 = phi i64 [ %210, %208 ], [ %210, %213 ], [ %299, %296 ]
  %305 = getelementptr inbounds i8, ptr %211, i64 8
  store i64 %304, ptr %305, align 8, !tbaa !15
  store i64 %303, ptr %211, align 8, !tbaa !15
  ret i64 %27
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_sbpi1_div_qr(ptr nocapture noundef writeonly %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5) local_unnamed_addr #5 {
  %7 = getelementptr inbounds i64, ptr %1, i64 %2
  %8 = sub i64 0, %4
  %9 = getelementptr inbounds i64, ptr %7, i64 %8
  br label %10

10:                                               ; preds = %13, %6
  %11 = phi i64 [ %4, %6 ], [ %14, %13 ]
  %12 = icmp sgt i64 %11, 0
  br i1 %12, label %13, label %22

13:                                               ; preds = %10
  %14 = add nsw i64 %11, -1
  %15 = getelementptr inbounds i64, ptr %9, i64 %14
  %16 = load i64, ptr %15, align 8, !tbaa !15
  %17 = getelementptr inbounds i64, ptr %3, i64 %14
  %18 = load i64, ptr %17, align 8, !tbaa !15
  %19 = icmp eq i64 %16, %18
  br i1 %19, label %10, label %20, !llvm.loop !338

20:                                               ; preds = %13
  %21 = icmp ugt i64 %16, %18
  br label %22

22:                                               ; preds = %20, %10
  %23 = phi i1 [ %21, %20 ], [ true, %10 ]
  br i1 %23, label %24, label %26

24:                                               ; preds = %22
  %25 = tail call i64 @__gmpn_sub_n(ptr noundef %9, ptr noundef %9, ptr noundef %3, i64 noundef %4) #16
  br label %26

26:                                               ; preds = %24, %22
  %27 = sub nsw i64 %2, %4
  %28 = add nsw i64 %4, -2
  %29 = add nsw i64 %4, -1
  %30 = getelementptr inbounds i64, ptr %3, i64 %29
  %31 = load i64, ptr %30, align 8, !tbaa !15
  %32 = getelementptr inbounds i64, ptr %3, i64 %28
  %33 = load i64, ptr %32, align 8, !tbaa !15
  %34 = getelementptr inbounds i8, ptr %7, i64 -16
  %35 = getelementptr inbounds i8, ptr %7, i64 -8
  %36 = load i64, ptr %35, align 8, !tbaa !15
  %37 = icmp sgt i64 %27, 0
  br i1 %37, label %38, label %158

38:                                               ; preds = %26
  %39 = getelementptr inbounds i64, ptr %0, i64 %27
  %40 = lshr i64 %5, 32
  %41 = and i64 %5, 4294967295
  %42 = lshr i64 %33, 32
  %43 = and i64 %33, 4294967295
  %44 = sub i64 2, %4
  %45 = sub i64 2, %4
  br label %46

46:                                               ; preds = %152, %38
  %47 = phi ptr [ %39, %38 ], [ %155, %152 ]
  %48 = phi ptr [ %34, %38 ], [ %51, %152 ]
  %49 = phi i64 [ %27, %38 ], [ %156, %152 ]
  %50 = phi i64 [ %36, %38 ], [ %154, %152 ]
  %51 = getelementptr inbounds i8, ptr %48, i64 -8
  %52 = icmp eq i64 %50, %31
  br i1 %52, label %53, label %60, !prof !54

53:                                               ; preds = %46
  %54 = load i64, ptr %48, align 8, !tbaa !15
  %55 = icmp eq i64 %54, %33
  br i1 %55, label %56, label %60

56:                                               ; preds = %53
  %57 = getelementptr inbounds i64, ptr %51, i64 %45
  %58 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %57, ptr noundef %3, i64 noundef %4, i64 noundef -1) #16
  %59 = load i64, ptr %48, align 8, !tbaa !15
  br label %152

60:                                               ; preds = %53, %46
  %61 = lshr i64 %50, 32
  %62 = and i64 %50, 4294967295
  %63 = mul nuw i64 %62, %41
  %64 = mul nuw i64 %62, %40
  %65 = mul nuw i64 %61, %41
  %66 = mul nuw i64 %61, %40
  %67 = lshr i64 %63, 32
  %68 = add i64 %65, %64
  %69 = add i64 %68, %67
  %70 = icmp ult i64 %69, %65
  %71 = add nuw i64 %66, 4294967296
  %72 = select i1 %70, i64 %71, i64 %66
  %73 = lshr i64 %69, 32
  %74 = shl i64 %69, 32
  %75 = and i64 %63, 4294967295
  %76 = or disjoint i64 %74, %75
  %77 = load i64, ptr %48, align 8, !tbaa !15
  %78 = add i64 %77, %76
  %79 = icmp ult i64 %78, %76
  %80 = zext i1 %79 to i64
  %81 = add i64 %73, %50
  %82 = add i64 %81, %72
  %83 = add i64 %82, %80
  %84 = load i64, ptr %51, align 8, !tbaa !15
  %85 = sub i64 %84, %33
  %86 = xor i64 %83, -1
  %87 = mul i64 %31, %86
  %88 = icmp ult i64 %84, %33
  %89 = sext i1 %88 to i64
  %90 = lshr i64 %83, 32
  %91 = and i64 %83, 4294967295
  %92 = mul nuw i64 %91, %43
  %93 = mul nuw i64 %90, %43
  %94 = mul nuw i64 %91, %42
  %95 = mul nuw i64 %90, %42
  %96 = lshr i64 %92, 32
  %97 = add i64 %94, %93
  %98 = add i64 %97, %96
  %99 = icmp ult i64 %98, %94
  %100 = add nuw i64 %95, 4294967296
  %101 = select i1 %99, i64 %100, i64 %95
  %102 = lshr i64 %98, 32
  %103 = shl i64 %98, 32
  %104 = and i64 %92, 4294967295
  %105 = or disjoint i64 %103, %104
  %106 = sub i64 %85, %105
  %107 = icmp ult i64 %85, %105
  %108 = sext i1 %107 to i64
  %109 = add i64 %77, %89
  %110 = add i64 %109, %87
  %111 = add i64 %102, %101
  %112 = sub i64 %110, %111
  %113 = add i64 %112, %108
  %114 = add i64 %83, 1
  %115 = icmp uge i64 %113, %78
  %116 = sext i1 %115 to i64
  %117 = add i64 %114, %116
  %118 = select i1 %115, i64 %33, i64 0
  %119 = add i64 %118, %106
  %120 = select i1 %115, i64 %31, i64 0
  %121 = add i64 %120, %113
  %122 = icmp ult i64 %119, %106
  %123 = zext i1 %122 to i64
  %124 = add i64 %121, %123
  %125 = icmp ult i64 %124, %31
  br i1 %125, label %136, label %126, !prof !68

126:                                              ; preds = %60
  %127 = icmp ule i64 %124, %31
  %128 = icmp ult i64 %119, %33
  %129 = select i1 %127, i1 %128, i1 false
  br i1 %129, label %136, label %130

130:                                              ; preds = %126
  %131 = add i64 %117, 1
  %132 = sub i64 %119, %33
  %133 = sext i1 %128 to i64
  %134 = sub i64 %133, %31
  %135 = add i64 %134, %124
  br label %136

136:                                              ; preds = %130, %126, %60
  %137 = phi i64 [ %131, %130 ], [ %117, %60 ], [ %117, %126 ]
  %138 = phi i64 [ %132, %130 ], [ %119, %60 ], [ %119, %126 ]
  %139 = phi i64 [ %135, %130 ], [ %124, %60 ], [ %124, %126 ]
  %140 = getelementptr inbounds i64, ptr %51, i64 %44
  %141 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %140, ptr noundef %3, i64 noundef %28, i64 noundef %137) #16
  %142 = icmp ult i64 %138, %141
  %143 = zext i1 %142 to i64
  %144 = sub i64 %138, %141
  %145 = icmp ult i64 %139, %143
  %146 = sub i64 %139, %143
  store i64 %144, ptr %51, align 8, !tbaa !15
  br i1 %145, label %147, label %152, !prof !54

147:                                              ; preds = %136
  %148 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %140, ptr noundef nonnull %140, ptr noundef %3, i64 noundef %29) #16
  %149 = add i64 %146, %31
  %150 = add i64 %149, %148
  %151 = add i64 %137, -1
  br label %152

152:                                              ; preds = %147, %136, %56
  %153 = phi i64 [ -1, %56 ], [ %151, %147 ], [ %137, %136 ]
  %154 = phi i64 [ %59, %56 ], [ %150, %147 ], [ %146, %136 ]
  %155 = getelementptr inbounds i8, ptr %47, i64 -8
  store i64 %153, ptr %155, align 8, !tbaa !15
  %156 = add nsw i64 %49, -1
  %157 = icmp sgt i64 %49, 1
  br i1 %157, label %46, label %158, !llvm.loop !339

158:                                              ; preds = %152, %26
  %159 = phi i64 [ %36, %26 ], [ %154, %152 ]
  %160 = phi ptr [ %34, %26 ], [ %51, %152 ]
  %161 = zext i1 %23 to i64
  %162 = getelementptr inbounds i8, ptr %160, i64 8
  store i64 %159, ptr %162, align 8, !tbaa !15
  ret i64 %161
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #10

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_invertappr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #5 {
  %5 = icmp sgt i64 %2, 199
  br i1 %5, label %8, label %6

6:                                                ; preds = %4
  %7 = tail call fastcc i64 @mpn_bc_invertappr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3)
  br label %10

8:                                                ; preds = %4
  %9 = tail call i64 @__gmpn_ni_invertappr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3)
  br label %10

10:                                               ; preds = %8, %6
  %11 = phi i64 [ %9, %8 ], [ %7, %6 ]
  ret i64 %11
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc range(i64 0, 2) i64 @mpn_bc_invertappr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) unnamed_addr #5 {
  %5 = icmp eq i64 %2, 1
  br i1 %5, label %9, label %6

6:                                                ; preds = %4
  %7 = shl nuw i64 %2, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %3, i8 -1, i64 %7, i1 false), !tbaa !15
  %8 = getelementptr inbounds i64, ptr %3, i64 %2
  br label %52

9:                                                ; preds = %4
  %10 = load i64, ptr %1, align 8, !tbaa !15
  %11 = lshr i64 %10, 32
  %12 = and i64 %10, 4294967295
  %13 = xor i64 %10, -1
  %14 = udiv i64 %13, %11
  %15 = mul i64 %14, %11
  %16 = urem i64 %13, %11
  %17 = mul i64 %14, %12
  %18 = shl i64 %16, 32
  %19 = or disjoint i64 %18, 4294967295
  %20 = icmp ult i64 %19, %17
  br i1 %20, label %21, label %30

21:                                               ; preds = %9
  %22 = add i64 %14, -1
  %23 = add i64 %19, %10
  %24 = icmp uge i64 %23, %10
  %25 = icmp ult i64 %23, %17
  %26 = and i1 %24, %25
  br i1 %26, label %27, label %30

27:                                               ; preds = %21
  %28 = add i64 %14, -2
  %29 = add i64 %23, %10
  br label %30

30:                                               ; preds = %27, %21, %9
  %31 = phi i64 [ %29, %27 ], [ %23, %21 ], [ %19, %9 ]
  %32 = phi i64 [ %28, %27 ], [ %22, %21 ], [ %14, %9 ]
  %33 = sub i64 %31, %17
  %34 = udiv i64 %33, %11
  %35 = mul i64 %34, %11
  %36 = urem i64 %33, %11
  %37 = mul i64 %34, %12
  %38 = shl i64 %36, 32
  %39 = or disjoint i64 %38, 4294967295
  %40 = icmp ult i64 %39, %37
  br i1 %40, label %41, label %48

41:                                               ; preds = %30
  %42 = add i64 %39, %10
  %43 = icmp uge i64 %42, %10
  %44 = icmp ult i64 %42, %37
  %45 = and i1 %43, %44
  %46 = select i1 %45, i64 -2, i64 -1
  %47 = add i64 %46, %34
  br label %48

48:                                               ; preds = %41, %30
  %49 = phi i64 [ %34, %30 ], [ %47, %41 ]
  %50 = shl i64 %32, 32
  %51 = or i64 %49, %50
  store i64 %51, ptr %0, align 8, !tbaa !15
  br label %167

52:                                               ; preds = %52, %6
  %53 = phi i64 [ %2, %6 ], [ %60, %52 ]
  %54 = phi ptr [ %1, %6 ], [ %56, %52 ]
  %55 = phi ptr [ %8, %6 ], [ %59, %52 ]
  %56 = getelementptr inbounds i8, ptr %54, i64 8
  %57 = load i64, ptr %54, align 8, !tbaa !15
  %58 = xor i64 %57, -1
  %59 = getelementptr inbounds i8, ptr %55, i64 8
  store i64 %58, ptr %55, align 8, !tbaa !15
  %60 = add nsw i64 %53, -1
  %61 = icmp eq i64 %60, 0
  br i1 %61, label %62, label %52, !llvm.loop !340

62:                                               ; preds = %52
  %63 = icmp eq i64 %2, 2
  br i1 %63, label %64, label %66

64:                                               ; preds = %62
  %65 = tail call i64 @__gmpn_divrem_2(ptr noundef %0, i64 noundef 0, ptr noundef %3, i64 noundef 4, ptr noundef %1) #16
  br label %167

66:                                               ; preds = %62
  %67 = getelementptr i64, ptr %1, i64 %2
  %68 = getelementptr i8, ptr %67, i64 -8
  %69 = load i64, ptr %68, align 8, !tbaa !15
  %70 = lshr i64 %69, 32
  %71 = and i64 %69, 4294967295
  %72 = xor i64 %69, -1
  %73 = udiv i64 %72, %70
  %74 = mul i64 %73, %70
  %75 = urem i64 %72, %70
  %76 = mul i64 %73, %71
  %77 = shl i64 %75, 32
  %78 = or disjoint i64 %77, 4294967295
  %79 = icmp ult i64 %78, %76
  br i1 %79, label %80, label %89

80:                                               ; preds = %66
  %81 = add i64 %73, -1
  %82 = add i64 %78, %69
  %83 = icmp uge i64 %82, %69
  %84 = icmp ult i64 %82, %76
  %85 = and i1 %83, %84
  br i1 %85, label %86, label %89

86:                                               ; preds = %80
  %87 = add i64 %73, -2
  %88 = add i64 %82, %69
  br label %89

89:                                               ; preds = %86, %80, %66
  %90 = phi i64 [ %87, %86 ], [ %81, %80 ], [ %73, %66 ]
  %91 = phi i64 [ %88, %86 ], [ %82, %80 ], [ %78, %66 ]
  %92 = sub i64 %91, %76
  %93 = udiv i64 %92, %70
  %94 = mul i64 %93, %70
  %95 = urem i64 %92, %70
  %96 = mul i64 %93, %71
  %97 = shl i64 %95, 32
  %98 = or disjoint i64 %97, 4294967295
  %99 = icmp ult i64 %98, %96
  br i1 %99, label %100, label %107

100:                                              ; preds = %89
  %101 = add i64 %98, %69
  %102 = icmp uge i64 %101, %69
  %103 = icmp ult i64 %101, %96
  %104 = and i1 %102, %103
  %105 = select i1 %104, i64 -2, i64 -1
  %106 = add i64 %105, %93
  br label %107

107:                                              ; preds = %100, %89
  %108 = phi i64 [ %93, %89 ], [ %106, %100 ]
  %109 = shl i64 %90, 32
  %110 = or i64 %108, %109
  %111 = mul i64 %110, %69
  %112 = getelementptr i8, ptr %67, i64 -16
  %113 = load i64, ptr %112, align 8, !tbaa !15
  %114 = add i64 %111, %113
  %115 = icmp ult i64 %114, %113
  br i1 %115, label %116, label %124

116:                                              ; preds = %107
  %117 = add i64 %110, -1
  %118 = icmp uge i64 %114, %69
  %119 = sext i1 %118 to i64
  %120 = add i64 %117, %119
  %121 = select i1 %118, i64 %69, i64 0
  %122 = add i64 %69, %121
  %123 = sub i64 %114, %122
  br label %124

124:                                              ; preds = %116, %107
  %125 = phi i64 [ %123, %116 ], [ %114, %107 ]
  %126 = phi i64 [ %120, %116 ], [ %110, %107 ]
  %127 = lshr i64 %113, 32
  %128 = lshr i64 %126, 32
  %129 = and i64 %113, 4294967295
  %130 = and i64 %126, 4294967295
  %131 = mul nuw i64 %130, %129
  %132 = mul nuw i64 %128, %129
  %133 = mul nuw i64 %130, %127
  %134 = mul nuw i64 %128, %127
  %135 = lshr i64 %131, 32
  %136 = add i64 %133, %132
  %137 = add i64 %136, %135
  %138 = icmp ult i64 %137, %133
  %139 = add nuw i64 %134, 4294967296
  %140 = select i1 %138, i64 %139, i64 %134
  %141 = lshr i64 %137, 32
  %142 = add i64 %140, %141
  %143 = shl i64 %137, 32
  %144 = and i64 %131, 4294967295
  %145 = or disjoint i64 %143, %144
  %146 = add i64 %142, %125
  %147 = icmp ult i64 %146, %142
  br i1 %147, label %148, label %157

148:                                              ; preds = %124
  %149 = add i64 %126, -1
  %150 = icmp ult i64 %146, %69
  br i1 %150, label %157, label %151, !prof !68

151:                                              ; preds = %148
  %152 = icmp ule i64 %146, %69
  %153 = icmp ult i64 %145, %113
  %154 = select i1 %152, i1 %153, i1 false
  %155 = add i64 %126, -2
  %156 = select i1 %154, i64 %149, i64 %155
  br label %157

157:                                              ; preds = %151, %148, %124
  %158 = phi i64 [ %149, %148 ], [ %126, %124 ], [ %156, %151 ]
  %159 = shl nsw i64 %2, 1
  %160 = tail call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %0, ptr noundef %3, i64 noundef %159, ptr noundef %1, i64 noundef %2, i64 noundef %158) #16
  br label %161

161:                                              ; preds = %161, %157
  %162 = phi ptr [ %0, %157 ], [ %163, %161 ]
  %163 = getelementptr inbounds i8, ptr %162, i64 8
  %164 = load i64, ptr %162, align 8, !tbaa !15
  %165 = add i64 %164, -1
  store i64 %165, ptr %162, align 8, !tbaa !15
  %166 = icmp eq i64 %164, 0
  br i1 %166, label %161, label %167, !llvm.loop !341

167:                                              ; preds = %161, %64, %48
  %168 = phi i64 [ 0, %64 ], [ 0, %48 ], [ 1, %161 ]
  ret i64 %168
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_ni_invertappr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #5 {
  %5 = alloca [40 x i64], align 16
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 320, ptr nonnull %5) #16
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #16
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi ptr [ %5, %4 ], [ %12, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %11, %7 ]
  store i64 %9, ptr %8, align 8, !tbaa !15
  %10 = ashr i64 %9, 1
  %11 = add nsw i64 %10, 1
  %12 = getelementptr inbounds i8, ptr %8, i64 8
  %13 = icmp sgt i64 %10, 198
  br i1 %13, label %7, label %14, !llvm.loop !342

14:                                               ; preds = %7
  %15 = getelementptr inbounds i64, ptr %1, i64 %2
  %16 = getelementptr inbounds i64, ptr %0, i64 %2
  %17 = xor i64 %10, -1
  %18 = getelementptr inbounds i64, ptr %16, i64 %17
  %19 = getelementptr inbounds i64, ptr %15, i64 %17
  %20 = tail call fastcc i64 @mpn_bc_invertappr(ptr noundef %18, ptr noundef %19, i64 noundef %11, ptr noundef %3)
  store ptr null, ptr %6, align 8, !tbaa !7
  %21 = add nsw i64 %2, 1
  %22 = tail call i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %21) #17
  %23 = ashr i64 %2, 1
  %24 = ashr i64 %22, 1
  %25 = icmp slt i64 %24, %2
  %26 = icmp sgt i64 %24, %23
  %27 = select i1 %26, i64 %24, i64 %22
  %28 = select i1 %25, i64 %27, i64 0
  %29 = add nsw i64 %22, 4
  %30 = add nsw i64 %29, %28
  %31 = shl i64 %30, 3
  %32 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %31) #16
  br label %33

33:                                               ; preds = %279, %14
  %34 = phi ptr [ %12, %14 ], [ %36, %279 ]
  %35 = phi i64 [ %11, %14 ], [ %37, %279 ]
  %36 = getelementptr inbounds i8, ptr %34, i64 -8
  %37 = load i64, ptr %36, align 8, !tbaa !15
  %38 = add nsw i64 %37, 1
  %39 = call i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %38) #17
  %40 = add nsw i64 %37, %35
  %41 = icmp sgt i64 %39, %40
  %42 = getelementptr inbounds i64, ptr %3, i64 %35
  br i1 %41, label %43, label %52

43:                                               ; preds = %33
  %44 = sub i64 0, %37
  %45 = getelementptr inbounds i64, ptr %15, i64 %44
  %46 = sub i64 0, %35
  %47 = getelementptr inbounds i64, ptr %16, i64 %46
  %48 = call i64 @__gmpn_mul(ptr noundef %3, ptr noundef %45, i64 noundef %37, ptr noundef %47, i64 noundef %35) #16
  %49 = sub i64 %37, %35
  %50 = add i64 %49, 1
  %51 = call i64 @__gmpn_add_n(ptr noundef %42, ptr noundef %42, ptr noundef %45, i64 noundef %50) #16
  br label %108

52:                                               ; preds = %33
  %53 = sub i64 0, %35
  %54 = sub i64 0, %37
  %55 = getelementptr inbounds i64, ptr %15, i64 %54
  %56 = getelementptr inbounds i64, ptr %16, i64 %53
  call void @__gmpn_mulmod_bnm1(ptr noundef %3, i64 noundef %39, ptr noundef %55, i64 noundef %37, ptr noundef %56, i64 noundef %35, ptr noundef %32) #16
  %57 = sub nsw i64 %39, %35
  %58 = call i64 @__gmpn_add_n(ptr noundef %42, ptr noundef %42, ptr noundef %55, i64 noundef %57) #16
  %59 = sub nsw i64 %37, %57
  %60 = sub i64 0, %59
  %61 = getelementptr inbounds i64, ptr %15, i64 %60
  %62 = call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %3, ptr noundef %61, i64 noundef %59) #16
  %63 = load i64, ptr %3, align 8, !tbaa !15
  %64 = add i64 %63, %58
  store i64 %64, ptr %3, align 8, !tbaa !15
  %65 = icmp ult i64 %64, %58
  br i1 %65, label %66, label %77

66:                                               ; preds = %52
  %67 = call i64 @llvm.smax.i64(i64 %59, i64 1)
  br label %68

68:                                               ; preds = %71, %66
  %69 = phi i64 [ %75, %71 ], [ 1, %66 ]
  %70 = icmp eq i64 %69, %67
  br i1 %70, label %77, label %71

71:                                               ; preds = %68
  %72 = getelementptr inbounds i64, ptr %3, i64 %69
  %73 = load i64, ptr %72, align 8, !tbaa !15
  %74 = add i64 %73, 1
  store i64 %74, ptr %72, align 8, !tbaa !15
  %75 = add nuw i64 %69, 1
  %76 = icmp eq i64 %74, 0
  br i1 %76, label %68, label %77, !llvm.loop !343

77:                                               ; preds = %71, %68, %52
  %78 = phi i64 [ 0, %52 ], [ 1, %68 ], [ 0, %71 ]
  %79 = getelementptr inbounds i64, ptr %3, i64 %39
  store i64 1, ptr %79, align 8, !tbaa !15
  %80 = getelementptr inbounds i64, ptr %42, i64 %37
  %81 = sub i64 0, %39
  %82 = getelementptr inbounds i64, ptr %80, i64 %81
  %83 = add i64 %78, %62
  %84 = sub i64 1, %83
  %85 = load i64, ptr %82, align 8, !tbaa !15
  %86 = sub i64 %85, %84
  store i64 %86, ptr %82, align 8, !tbaa !15
  %87 = icmp ult i64 %85, %84
  br i1 %87, label %88, label %94

88:                                               ; preds = %88, %77
  %89 = phi ptr [ %90, %88 ], [ %82, %77 ]
  %90 = getelementptr inbounds i8, ptr %89, i64 8
  %91 = load i64, ptr %90, align 8, !tbaa !15
  %92 = add i64 %91, -1
  store i64 %92, ptr %90, align 8, !tbaa !15
  %93 = icmp eq i64 %91, 0
  br i1 %93, label %88, label %94, !llvm.loop !344

94:                                               ; preds = %88, %77
  %95 = load i64, ptr %79, align 8, !tbaa !15
  %96 = load i64, ptr %3, align 8, !tbaa !15
  %97 = add i64 %95, -1
  %98 = add i64 %97, %96
  store i64 %98, ptr %3, align 8, !tbaa !15
  %99 = load i64, ptr %79, align 8, !tbaa !15
  %100 = sub i64 1, %99
  %101 = icmp ult i64 %96, %100
  br i1 %101, label %102, label %108

102:                                              ; preds = %102, %94
  %103 = phi ptr [ %104, %102 ], [ %3, %94 ]
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = load i64, ptr %104, align 8, !tbaa !15
  %106 = add i64 %105, -1
  store i64 %106, ptr %104, align 8, !tbaa !15
  %107 = icmp eq i64 %105, 0
  br i1 %107, label %102, label %108, !llvm.loop !345

108:                                              ; preds = %102, %94, %43
  %109 = phi i64 [ 1, %43 ], [ 0, %94 ], [ 0, %102 ]
  %110 = getelementptr inbounds i64, ptr %3, i64 %37
  %111 = load i64, ptr %110, align 8, !tbaa !15
  %112 = icmp ult i64 %111, 2
  br i1 %112, label %113, label %193

113:                                              ; preds = %108
  %114 = add nuw nsw i64 %111, 1
  %115 = icmp eq i64 %111, 0
  br i1 %115, label %124, label %116

116:                                              ; preds = %113
  %117 = sub i64 0, %37
  %118 = getelementptr inbounds i64, ptr %15, i64 %117
  %119 = call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %118, i64 noundef %37) #16
  %120 = icmp eq i64 %119, 0
  br i1 %120, label %121, label %124

121:                                              ; preds = %116
  %122 = call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %118, i64 noundef %37) #16
  %123 = or disjoint i64 %111, 2
  br label %124

124:                                              ; preds = %121, %116, %113
  %125 = phi i64 [ %114, %116 ], [ %123, %121 ], [ %114, %113 ]
  %126 = sub i64 0, %37
  %127 = getelementptr inbounds i64, ptr %15, i64 %126
  br label %128

128:                                              ; preds = %131, %124
  %129 = phi i64 [ %37, %124 ], [ %132, %131 ]
  %130 = icmp sgt i64 %129, 0
  br i1 %130, label %131, label %143

131:                                              ; preds = %128
  %132 = add nsw i64 %129, -1
  %133 = getelementptr inbounds i64, ptr %3, i64 %132
  %134 = load i64, ptr %133, align 8, !tbaa !15
  %135 = getelementptr inbounds i64, ptr %127, i64 %132
  %136 = load i64, ptr %135, align 8, !tbaa !15
  %137 = icmp eq i64 %134, %136
  br i1 %137, label %128, label %138, !llvm.loop !346

138:                                              ; preds = %131
  %139 = icmp ugt i64 %134, %136
  br i1 %139, label %140, label %143

140:                                              ; preds = %138
  %141 = call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %127, i64 noundef %37) #16
  %142 = add nuw nsw i64 %125, 1
  br label %143

143:                                              ; preds = %140, %138, %128
  %144 = phi i64 [ %142, %140 ], [ %125, %138 ], [ %125, %128 ]
  %145 = shl nsw i64 %37, 4
  %146 = getelementptr inbounds i8, ptr %3, i64 %145
  %147 = sub i64 0, %35
  %148 = getelementptr inbounds i64, ptr %146, i64 %147
  %149 = getelementptr inbounds i64, ptr %15, i64 %147
  %150 = getelementptr inbounds i64, ptr %110, i64 %147
  %151 = sub nsw i64 %37, %35
  br label %152

152:                                              ; preds = %155, %143
  %153 = phi i64 [ %151, %143 ], [ %156, %155 ]
  %154 = icmp sgt i64 %153, 0
  br i1 %154, label %155, label %164

155:                                              ; preds = %152
  %156 = add nsw i64 %153, -1
  %157 = getelementptr inbounds i64, ptr %3, i64 %156
  %158 = load i64, ptr %157, align 8, !tbaa !15
  %159 = getelementptr inbounds i64, ptr %127, i64 %156
  %160 = load i64, ptr %159, align 8, !tbaa !15
  %161 = icmp eq i64 %158, %160
  br i1 %161, label %152, label %162, !llvm.loop !346

162:                                              ; preds = %155
  %163 = icmp ugt i64 %158, %160
  br label %164

164:                                              ; preds = %162, %152
  %165 = phi i1 [ %163, %162 ], [ false, %152 ]
  %166 = zext i1 %165 to i64
  %167 = call i64 @__gmpn_sub_n(ptr noundef %148, ptr noundef %149, ptr noundef nonnull %150, i64 noundef %35) #16
  %168 = load i64, ptr %148, align 8, !tbaa !15
  %169 = sub i64 %168, %166
  store i64 %169, ptr %148, align 8, !tbaa !15
  %170 = icmp ult i64 %168, %166
  br i1 %170, label %171, label %182

171:                                              ; preds = %164
  %172 = call i64 @llvm.smax.i64(i64 %35, i64 1)
  br label %173

173:                                              ; preds = %176, %171
  %174 = phi i64 [ %180, %176 ], [ 1, %171 ]
  %175 = icmp eq i64 %174, %172
  br i1 %175, label %182, label %176

176:                                              ; preds = %173
  %177 = getelementptr inbounds i64, ptr %148, i64 %174
  %178 = load i64, ptr %177, align 8, !tbaa !15
  %179 = add i64 %178, -1
  store i64 %179, ptr %177, align 8, !tbaa !15
  %180 = add nuw i64 %174, 1
  %181 = icmp eq i64 %178, 0
  br i1 %181, label %173, label %182, !llvm.loop !347

182:                                              ; preds = %176, %173, %164
  %183 = getelementptr inbounds i64, ptr %16, i64 %147
  %184 = load i64, ptr %183, align 8, !tbaa !15
  %185 = sub i64 %184, %144
  store i64 %185, ptr %183, align 8, !tbaa !15
  %186 = icmp ult i64 %184, %144
  br i1 %186, label %187, label %235

187:                                              ; preds = %187, %182
  %188 = phi ptr [ %189, %187 ], [ %183, %182 ]
  %189 = getelementptr inbounds i8, ptr %188, i64 8
  %190 = load i64, ptr %189, align 8, !tbaa !15
  %191 = add i64 %190, -1
  store i64 %191, ptr %189, align 8, !tbaa !15
  %192 = icmp eq i64 %190, 0
  br i1 %192, label %187, label %235, !llvm.loop !348

193:                                              ; preds = %108
  %194 = load i64, ptr %3, align 8, !tbaa !15
  %195 = sub i64 %194, %109
  store i64 %195, ptr %3, align 8, !tbaa !15
  %196 = icmp ult i64 %194, %109
  br i1 %196, label %197, label %203

197:                                              ; preds = %197, %193
  %198 = phi ptr [ %199, %197 ], [ %3, %193 ]
  %199 = getelementptr inbounds i8, ptr %198, i64 8
  %200 = load i64, ptr %199, align 8, !tbaa !15
  %201 = add i64 %200, -1
  store i64 %201, ptr %199, align 8, !tbaa !15
  %202 = icmp eq i64 %200, 0
  br i1 %202, label %197, label %203, !llvm.loop !349

203:                                              ; preds = %197, %193
  %204 = load i64, ptr %110, align 8, !tbaa !15
  %205 = icmp eq i64 %204, -1
  br i1 %205, label %219, label %206

206:                                              ; preds = %203
  %207 = sub i64 0, %35
  %208 = getelementptr inbounds i64, ptr %16, i64 %207
  br label %209

209:                                              ; preds = %209, %206
  %210 = phi ptr [ %208, %206 ], [ %211, %209 ]
  %211 = getelementptr inbounds i8, ptr %210, i64 8
  %212 = load i64, ptr %210, align 8, !tbaa !15
  %213 = add i64 %212, 1
  store i64 %213, ptr %210, align 8, !tbaa !15
  %214 = icmp eq i64 %213, 0
  br i1 %214, label %209, label %215, !llvm.loop !350

215:                                              ; preds = %209
  %216 = sub i64 0, %37
  %217 = getelementptr inbounds i64, ptr %15, i64 %216
  %218 = call i64 @__gmpn_add_n(ptr noundef nonnull %3, ptr noundef nonnull %3, ptr noundef %217, i64 noundef %37) #16
  br label %219

219:                                              ; preds = %215, %203
  %220 = shl nsw i64 %37, 4
  %221 = getelementptr inbounds i8, ptr %3, i64 %220
  %222 = sub i64 0, %35
  %223 = getelementptr inbounds i64, ptr %221, i64 %222
  %224 = getelementptr inbounds i64, ptr %110, i64 %222
  br label %225

225:                                              ; preds = %225, %219
  %226 = phi ptr [ %223, %219 ], [ %232, %225 ]
  %227 = phi ptr [ %224, %219 ], [ %229, %225 ]
  %228 = phi i64 [ %35, %219 ], [ %233, %225 ]
  %229 = getelementptr inbounds i8, ptr %227, i64 8
  %230 = load i64, ptr %227, align 8, !tbaa !15
  %231 = xor i64 %230, -1
  %232 = getelementptr inbounds i8, ptr %226, i64 8
  store i64 %231, ptr %226, align 8, !tbaa !15
  %233 = add nsw i64 %228, -1
  %234 = icmp eq i64 %233, 0
  br i1 %234, label %235, label %225, !llvm.loop !351

235:                                              ; preds = %225, %187, %182
  %236 = shl nsw i64 %37, 4
  %237 = getelementptr inbounds i8, ptr %3, i64 %236
  %238 = sub i64 0, %35
  %239 = getelementptr inbounds i64, ptr %237, i64 %238
  %240 = getelementptr inbounds i64, ptr %16, i64 %238
  call void @__gmpn_mul_n(ptr noundef %3, ptr noundef %239, ptr noundef %240, i64 noundef %35) #16
  %241 = getelementptr inbounds i64, ptr %3, i64 %35
  %242 = shl nsw i64 %35, 1
  %243 = sub nsw i64 %242, %37
  %244 = call i64 @__gmpn_add_n(ptr noundef %241, ptr noundef %241, ptr noundef %239, i64 noundef %243) #16
  %245 = sub i64 0, %37
  %246 = getelementptr inbounds i64, ptr %16, i64 %245
  %247 = mul i64 %35, 24
  %248 = getelementptr inbounds i8, ptr %3, i64 %247
  %249 = getelementptr inbounds i64, ptr %248, i64 %245
  %250 = getelementptr inbounds i64, ptr %110, i64 %35
  %251 = sub nsw i64 %37, %35
  %252 = call i64 @__gmpn_add_n(ptr noundef %246, ptr noundef %249, ptr noundef nonnull %250, i64 noundef %251) #16
  %253 = load i64, ptr %246, align 8, !tbaa !15
  %254 = add i64 %253, %244
  store i64 %254, ptr %246, align 8, !tbaa !15
  %255 = icmp ult i64 %254, %244
  br i1 %255, label %256, label %267

256:                                              ; preds = %235
  %257 = call i64 @llvm.smax.i64(i64 %251, i64 1)
  br label %258

258:                                              ; preds = %261, %256
  %259 = phi i64 [ %265, %261 ], [ 1, %256 ]
  %260 = icmp eq i64 %259, %257
  br i1 %260, label %267, label %261

261:                                              ; preds = %258
  %262 = getelementptr inbounds i64, ptr %246, i64 %259
  %263 = load i64, ptr %262, align 8, !tbaa !15
  %264 = add i64 %263, 1
  store i64 %264, ptr %262, align 8, !tbaa !15
  %265 = add nuw i64 %259, 1
  %266 = icmp eq i64 %264, 0
  br i1 %266, label %258, label %267, !llvm.loop !343

267:                                              ; preds = %261, %258, %235
  %268 = phi i64 [ 0, %235 ], [ 1, %258 ], [ 0, %261 ]
  %269 = add i64 %268, %252
  %270 = load i64, ptr %240, align 8, !tbaa !15
  %271 = add i64 %270, %269
  store i64 %271, ptr %240, align 8, !tbaa !15
  %272 = icmp ult i64 %271, %269
  br i1 %272, label %273, label %279

273:                                              ; preds = %273, %267
  %274 = phi ptr [ %275, %273 ], [ %240, %267 ]
  %275 = getelementptr inbounds i8, ptr %274, i64 8
  %276 = load i64, ptr %275, align 8, !tbaa !15
  %277 = add i64 %276, 1
  store i64 %277, ptr %275, align 8, !tbaa !15
  %278 = icmp eq i64 %277, 0
  br i1 %278, label %273, label %279, !llvm.loop !352

279:                                              ; preds = %273, %267
  %280 = icmp eq ptr %36, %5
  br i1 %280, label %281, label %33, !llvm.loop !353

281:                                              ; preds = %279
  %282 = xor i64 %37, -1
  %283 = getelementptr i64, ptr %248, i64 %282
  %284 = load i64, ptr %283, align 8, !tbaa !15
  %285 = icmp ugt i64 %284, -8
  %286 = zext i1 %285 to i64
  %287 = load ptr, ptr %6, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %287) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #16
  call void @llvm.lifetime.end.p0(i64 320, ptr nonnull %5) #16
  ret i64 %286
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_sbpi1_divappr_q(ptr nocapture noundef writeonly %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5) local_unnamed_addr #5 {
  %7 = getelementptr inbounds i64, ptr %1, i64 %2
  %8 = sub i64 %2, %4
  %9 = add i64 %8, 1
  %10 = icmp slt i64 %9, %4
  %11 = sub nsw i64 %4, %9
  %12 = tail call i64 @llvm.smin.i64(i64 %9, i64 %4)
  %13 = select i1 %10, i64 %11, i64 0
  %14 = getelementptr inbounds i64, ptr %3, i64 %13
  %15 = sub i64 0, %12
  %16 = getelementptr inbounds i64, ptr %7, i64 %15
  br label %17

17:                                               ; preds = %20, %6
  %18 = phi i64 [ %12, %6 ], [ %21, %20 ]
  %19 = icmp sgt i64 %18, 0
  br i1 %19, label %20, label %29

20:                                               ; preds = %17
  %21 = add nsw i64 %18, -1
  %22 = getelementptr inbounds i64, ptr %16, i64 %21
  %23 = load i64, ptr %22, align 8, !tbaa !15
  %24 = getelementptr inbounds i64, ptr %14, i64 %21
  %25 = load i64, ptr %24, align 8, !tbaa !15
  %26 = icmp eq i64 %23, %25
  br i1 %26, label %17, label %27, !llvm.loop !354

27:                                               ; preds = %20
  %28 = icmp ugt i64 %23, %25
  br label %29

29:                                               ; preds = %27, %17
  %30 = phi i1 [ %28, %27 ], [ true, %17 ]
  br i1 %30, label %31, label %33

31:                                               ; preds = %29
  %32 = tail call i64 @__gmpn_sub_n(ptr noundef %16, ptr noundef %16, ptr noundef %14, i64 noundef %12) #16
  br label %33

33:                                               ; preds = %31, %29
  %34 = getelementptr inbounds i64, ptr %0, i64 %8
  %35 = add nsw i64 %12, -2
  %36 = add nsw i64 %12, -1
  %37 = getelementptr inbounds i64, ptr %14, i64 %36
  %38 = load i64, ptr %37, align 8, !tbaa !15
  %39 = getelementptr inbounds i64, ptr %14, i64 %35
  %40 = load i64, ptr %39, align 8, !tbaa !15
  %41 = getelementptr inbounds i8, ptr %7, i64 -16
  %42 = getelementptr inbounds i8, ptr %7, i64 -8
  %43 = load i64, ptr %42, align 8, !tbaa !15
  %44 = sub nsw i64 %8, %12
  %45 = icmp sgt i64 %44, -1
  br i1 %45, label %46, label %165

46:                                               ; preds = %33
  %47 = lshr i64 %5, 32
  %48 = and i64 %5, 4294967295
  %49 = lshr i64 %40, 32
  %50 = and i64 %40, 4294967295
  %51 = sub i64 2, %12
  %52 = sub i64 2, %12
  br label %53

53:                                               ; preds = %159, %46
  %54 = phi ptr [ %34, %46 ], [ %162, %159 ]
  %55 = phi ptr [ %41, %46 ], [ %58, %159 ]
  %56 = phi i64 [ %44, %46 ], [ %163, %159 ]
  %57 = phi i64 [ %43, %46 ], [ %161, %159 ]
  %58 = getelementptr inbounds i8, ptr %55, i64 -8
  %59 = icmp eq i64 %57, %38
  br i1 %59, label %60, label %67, !prof !54

60:                                               ; preds = %53
  %61 = load i64, ptr %55, align 8, !tbaa !15
  %62 = icmp eq i64 %61, %40
  br i1 %62, label %63, label %67

63:                                               ; preds = %60
  %64 = getelementptr inbounds i64, ptr %58, i64 %52
  %65 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %64, ptr noundef %14, i64 noundef %12, i64 noundef -1) #16
  %66 = load i64, ptr %55, align 8, !tbaa !15
  br label %159

67:                                               ; preds = %60, %53
  %68 = lshr i64 %57, 32
  %69 = and i64 %57, 4294967295
  %70 = mul nuw i64 %69, %48
  %71 = mul nuw i64 %69, %47
  %72 = mul nuw i64 %68, %48
  %73 = mul nuw i64 %68, %47
  %74 = lshr i64 %70, 32
  %75 = add i64 %72, %71
  %76 = add i64 %75, %74
  %77 = icmp ult i64 %76, %72
  %78 = add nuw i64 %73, 4294967296
  %79 = select i1 %77, i64 %78, i64 %73
  %80 = lshr i64 %76, 32
  %81 = shl i64 %76, 32
  %82 = and i64 %70, 4294967295
  %83 = or disjoint i64 %81, %82
  %84 = load i64, ptr %55, align 8, !tbaa !15
  %85 = add i64 %84, %83
  %86 = icmp ult i64 %85, %83
  %87 = zext i1 %86 to i64
  %88 = add i64 %80, %57
  %89 = add i64 %88, %79
  %90 = add i64 %89, %87
  %91 = load i64, ptr %58, align 8, !tbaa !15
  %92 = sub i64 %91, %40
  %93 = xor i64 %90, -1
  %94 = mul i64 %38, %93
  %95 = icmp ult i64 %91, %40
  %96 = sext i1 %95 to i64
  %97 = lshr i64 %90, 32
  %98 = and i64 %90, 4294967295
  %99 = mul nuw i64 %98, %50
  %100 = mul nuw i64 %97, %50
  %101 = mul nuw i64 %98, %49
  %102 = mul nuw i64 %97, %49
  %103 = lshr i64 %99, 32
  %104 = add i64 %101, %100
  %105 = add i64 %104, %103
  %106 = icmp ult i64 %105, %101
  %107 = add nuw i64 %102, 4294967296
  %108 = select i1 %106, i64 %107, i64 %102
  %109 = lshr i64 %105, 32
  %110 = shl i64 %105, 32
  %111 = and i64 %99, 4294967295
  %112 = or disjoint i64 %110, %111
  %113 = sub i64 %92, %112
  %114 = icmp ult i64 %92, %112
  %115 = sext i1 %114 to i64
  %116 = add i64 %84, %96
  %117 = add i64 %116, %94
  %118 = add i64 %109, %108
  %119 = sub i64 %117, %118
  %120 = add i64 %119, %115
  %121 = add i64 %90, 1
  %122 = icmp uge i64 %120, %85
  %123 = sext i1 %122 to i64
  %124 = add i64 %121, %123
  %125 = select i1 %122, i64 %40, i64 0
  %126 = add i64 %125, %113
  %127 = select i1 %122, i64 %38, i64 0
  %128 = add i64 %127, %120
  %129 = icmp ult i64 %126, %113
  %130 = zext i1 %129 to i64
  %131 = add i64 %128, %130
  %132 = icmp ult i64 %131, %38
  br i1 %132, label %143, label %133, !prof !68

133:                                              ; preds = %67
  %134 = icmp ule i64 %131, %38
  %135 = icmp ult i64 %126, %40
  %136 = select i1 %134, i1 %135, i1 false
  br i1 %136, label %143, label %137

137:                                              ; preds = %133
  %138 = add i64 %124, 1
  %139 = sub i64 %126, %40
  %140 = sext i1 %135 to i64
  %141 = sub i64 %140, %38
  %142 = add i64 %141, %131
  br label %143

143:                                              ; preds = %137, %133, %67
  %144 = phi i64 [ %138, %137 ], [ %124, %67 ], [ %124, %133 ]
  %145 = phi i64 [ %139, %137 ], [ %126, %67 ], [ %126, %133 ]
  %146 = phi i64 [ %142, %137 ], [ %131, %67 ], [ %131, %133 ]
  %147 = getelementptr inbounds i64, ptr %58, i64 %51
  %148 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %147, ptr noundef %14, i64 noundef %35, i64 noundef %144) #16
  %149 = icmp ult i64 %145, %148
  %150 = zext i1 %149 to i64
  %151 = sub i64 %145, %148
  %152 = icmp ult i64 %146, %150
  %153 = sub i64 %146, %150
  store i64 %151, ptr %58, align 8, !tbaa !15
  br i1 %152, label %154, label %159, !prof !54

154:                                              ; preds = %143
  %155 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %147, ptr noundef nonnull %147, ptr noundef %14, i64 noundef %36) #16
  %156 = add i64 %153, %38
  %157 = add i64 %156, %155
  %158 = add i64 %144, -1
  br label %159

159:                                              ; preds = %154, %143, %63
  %160 = phi i64 [ -1, %63 ], [ %158, %154 ], [ %144, %143 ]
  %161 = phi i64 [ %66, %63 ], [ %157, %154 ], [ %153, %143 ]
  %162 = getelementptr inbounds i8, ptr %54, i64 -8
  store i64 %160, ptr %162, align 8, !tbaa !15
  %163 = add nsw i64 %56, -1
  %164 = icmp sgt i64 %56, 0
  br i1 %164, label %53, label %165, !llvm.loop !355

165:                                              ; preds = %159, %33
  %166 = phi i64 [ %43, %33 ], [ %161, %159 ]
  %167 = phi ptr [ %41, %33 ], [ %58, %159 ]
  %168 = phi ptr [ %34, %33 ], [ %162, %159 ]
  %169 = icmp sgt i64 %12, 1
  br i1 %169, label %170, label %420

170:                                              ; preds = %165
  %171 = icmp eq i64 %12, 2
  br i1 %171, label %303, label %172

172:                                              ; preds = %170
  %173 = lshr i64 %5, 32
  %174 = and i64 %5, 4294967295
  %175 = lshr i64 %40, 32
  %176 = and i64 %40, 4294967295
  %177 = shl i64 %12, 3
  %178 = sub i64 8, %177
  %179 = getelementptr i8, ptr %167, i64 %178
  br label %180

180:                                              ; preds = %295, %172
  %181 = phi ptr [ %168, %172 ], [ %299, %295 ]
  %182 = phi ptr [ %167, %172 ], [ %187, %295 ]
  %183 = phi ptr [ %14, %172 ], [ %301, %295 ]
  %184 = phi i64 [ %35, %172 ], [ %300, %295 ]
  %185 = phi i64 [ %166, %172 ], [ %298, %295 ]
  %186 = phi i64 [ -1, %172 ], [ %296, %295 ]
  %187 = getelementptr inbounds i8, ptr %182, i64 -8
  %188 = and i64 %186, %38
  %189 = icmp ult i64 %185, %188
  br i1 %189, label %203, label %190, !prof !68

190:                                              ; preds = %180
  %191 = add nuw nsw i64 %184, 2
  %192 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %179, ptr noundef %183, i64 noundef %191, i64 noundef -1) #16
  %193 = icmp eq i64 %185, %192
  br i1 %193, label %199, label %194, !prof !68

194:                                              ; preds = %190
  %195 = and i64 %192, %186
  %196 = icmp ult i64 %185, %195
  br i1 %196, label %197, label %199

197:                                              ; preds = %194
  %198 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %179, ptr noundef nonnull %179, ptr noundef %183, i64 noundef %191) #16
  br label %199

199:                                              ; preds = %197, %194, %190
  %200 = phi i64 [ %186, %197 ], [ %186, %190 ], [ 0, %194 ]
  %201 = phi i64 [ -2, %197 ], [ -1, %190 ], [ -1, %194 ]
  %202 = load i64, ptr %182, align 8, !tbaa !15
  br label %295

203:                                              ; preds = %180
  %204 = lshr i64 %185, 32
  %205 = and i64 %185, 4294967295
  %206 = mul nuw i64 %205, %174
  %207 = mul nuw i64 %205, %173
  %208 = mul nuw i64 %204, %174
  %209 = mul nuw i64 %204, %173
  %210 = lshr i64 %206, 32
  %211 = add i64 %208, %207
  %212 = add i64 %211, %210
  %213 = icmp ult i64 %212, %208
  %214 = add nuw i64 %209, 4294967296
  %215 = select i1 %213, i64 %214, i64 %209
  %216 = lshr i64 %212, 32
  %217 = shl i64 %212, 32
  %218 = and i64 %206, 4294967295
  %219 = or disjoint i64 %217, %218
  %220 = load i64, ptr %182, align 8, !tbaa !15
  %221 = add i64 %220, %219
  %222 = icmp ult i64 %221, %219
  %223 = zext i1 %222 to i64
  %224 = add i64 %216, %185
  %225 = add i64 %224, %215
  %226 = add i64 %225, %223
  %227 = load i64, ptr %187, align 8, !tbaa !15
  %228 = sub i64 %227, %40
  %229 = xor i64 %226, -1
  %230 = mul i64 %38, %229
  %231 = icmp ult i64 %227, %40
  %232 = sext i1 %231 to i64
  %233 = lshr i64 %226, 32
  %234 = and i64 %226, 4294967295
  %235 = mul nuw i64 %234, %176
  %236 = mul nuw i64 %233, %176
  %237 = mul nuw i64 %234, %175
  %238 = mul nuw i64 %233, %175
  %239 = lshr i64 %235, 32
  %240 = add i64 %237, %236
  %241 = add i64 %240, %239
  %242 = icmp ult i64 %241, %237
  %243 = add nuw i64 %238, 4294967296
  %244 = select i1 %242, i64 %243, i64 %238
  %245 = lshr i64 %241, 32
  %246 = shl i64 %241, 32
  %247 = and i64 %235, 4294967295
  %248 = or disjoint i64 %246, %247
  %249 = sub i64 %228, %248
  %250 = icmp ult i64 %228, %248
  %251 = sext i1 %250 to i64
  %252 = add i64 %220, %232
  %253 = add i64 %252, %230
  %254 = add i64 %245, %244
  %255 = sub i64 %253, %254
  %256 = add i64 %255, %251
  %257 = add i64 %226, 1
  %258 = icmp uge i64 %256, %221
  %259 = sext i1 %258 to i64
  %260 = add i64 %257, %259
  %261 = select i1 %258, i64 %40, i64 0
  %262 = add i64 %261, %249
  %263 = select i1 %258, i64 %38, i64 0
  %264 = add i64 %263, %256
  %265 = icmp ult i64 %262, %249
  %266 = zext i1 %265 to i64
  %267 = add i64 %264, %266
  %268 = icmp ult i64 %267, %38
  br i1 %268, label %279, label %269, !prof !68

269:                                              ; preds = %203
  %270 = icmp ule i64 %267, %38
  %271 = icmp ult i64 %262, %40
  %272 = select i1 %270, i1 %271, i1 false
  br i1 %272, label %279, label %273

273:                                              ; preds = %269
  %274 = add i64 %260, 1
  %275 = sub i64 %262, %40
  %276 = sext i1 %271 to i64
  %277 = sub i64 %276, %38
  %278 = add i64 %277, %267
  br label %279

279:                                              ; preds = %273, %269, %203
  %280 = phi i64 [ %274, %273 ], [ %260, %203 ], [ %260, %269 ]
  %281 = phi i64 [ %275, %273 ], [ %262, %203 ], [ %262, %269 ]
  %282 = phi i64 [ %278, %273 ], [ %267, %203 ], [ %267, %269 ]
  %283 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %179, ptr noundef %183, i64 noundef %184, i64 noundef %280) #16
  %284 = icmp ult i64 %281, %283
  %285 = zext i1 %284 to i64
  %286 = sub i64 %281, %283
  %287 = icmp ult i64 %282, %285
  %288 = sub i64 %282, %285
  store i64 %286, ptr %187, align 8, !tbaa !15
  br i1 %287, label %289, label %295, !prof !54

289:                                              ; preds = %279
  %290 = add nuw nsw i64 %184, 1
  %291 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %179, ptr noundef nonnull %179, ptr noundef %183, i64 noundef %290) #16
  %292 = add i64 %288, %38
  %293 = add i64 %292, %291
  %294 = add i64 %280, -1
  br label %295

295:                                              ; preds = %289, %279, %199
  %296 = phi i64 [ %200, %199 ], [ %186, %289 ], [ %186, %279 ]
  %297 = phi i64 [ %201, %199 ], [ %294, %289 ], [ %280, %279 ]
  %298 = phi i64 [ %202, %199 ], [ %293, %289 ], [ %288, %279 ]
  %299 = getelementptr inbounds i8, ptr %181, i64 -8
  store i64 %297, ptr %299, align 8, !tbaa !15
  %300 = add nsw i64 %184, -1
  %301 = getelementptr inbounds i8, ptr %183, i64 8
  %302 = icmp sgt i64 %184, 1
  br i1 %302, label %180, label %303, !llvm.loop !356

303:                                              ; preds = %295, %170
  %304 = phi i64 [ -1, %170 ], [ %296, %295 ]
  %305 = phi i64 [ %166, %170 ], [ %298, %295 ]
  %306 = phi ptr [ %14, %170 ], [ %301, %295 ]
  %307 = phi ptr [ %167, %170 ], [ %187, %295 ]
  %308 = phi ptr [ %168, %170 ], [ %299, %295 ]
  %309 = getelementptr inbounds i8, ptr %307, i64 -8
  %310 = and i64 %304, %38
  %311 = icmp ult i64 %305, %310
  br i1 %311, label %332, label %312, !prof !68

312:                                              ; preds = %303
  %313 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %309, ptr noundef %306, i64 noundef 2, i64 noundef -1) #16
  %314 = icmp eq i64 %305, %313
  br i1 %314, label %329, label %315, !prof !68

315:                                              ; preds = %312
  %316 = and i64 %313, %304
  %317 = icmp ult i64 %305, %316
  br i1 %317, label %318, label %329

318:                                              ; preds = %315
  %319 = load i64, ptr %309, align 8, !tbaa !15
  %320 = load i64, ptr %306, align 8, !tbaa !15
  %321 = add i64 %320, %319
  %322 = load i64, ptr %307, align 8, !tbaa !15
  %323 = getelementptr inbounds i8, ptr %306, i64 8
  %324 = load i64, ptr %323, align 8, !tbaa !15
  %325 = add i64 %324, %322
  %326 = icmp ult i64 %321, %319
  %327 = zext i1 %326 to i64
  %328 = add i64 %325, %327
  store i64 %328, ptr %307, align 8, !tbaa !15
  store i64 %321, ptr %309, align 8, !tbaa !15
  br label %329

329:                                              ; preds = %318, %315, %312
  %330 = phi i64 [ -2, %318 ], [ -1, %312 ], [ -1, %315 ]
  %331 = load i64, ptr %307, align 8, !tbaa !15
  br label %416

332:                                              ; preds = %303
  %333 = lshr i64 %305, 32
  %334 = lshr i64 %5, 32
  %335 = and i64 %305, 4294967295
  %336 = and i64 %5, 4294967295
  %337 = mul nuw i64 %335, %336
  %338 = mul nuw i64 %335, %334
  %339 = mul nuw i64 %333, %336
  %340 = mul nuw i64 %333, %334
  %341 = lshr i64 %337, 32
  %342 = add i64 %339, %338
  %343 = add i64 %342, %341
  %344 = icmp ult i64 %343, %339
  %345 = add nuw i64 %340, 4294967296
  %346 = select i1 %344, i64 %345, i64 %340
  %347 = lshr i64 %343, 32
  %348 = shl i64 %343, 32
  %349 = and i64 %337, 4294967295
  %350 = or disjoint i64 %348, %349
  %351 = load i64, ptr %307, align 8, !tbaa !15
  %352 = add i64 %351, %350
  %353 = icmp ult i64 %352, %350
  %354 = zext i1 %353 to i64
  %355 = add i64 %347, %305
  %356 = add i64 %355, %346
  %357 = add i64 %356, %354
  %358 = load i64, ptr %309, align 8, !tbaa !15
  %359 = sub i64 %358, %40
  %360 = xor i64 %357, -1
  %361 = mul i64 %38, %360
  %362 = icmp ult i64 %358, %40
  %363 = sext i1 %362 to i64
  %364 = lshr i64 %40, 32
  %365 = lshr i64 %357, 32
  %366 = and i64 %40, 4294967295
  %367 = and i64 %357, 4294967295
  %368 = mul nuw i64 %367, %366
  %369 = mul nuw i64 %365, %366
  %370 = mul nuw i64 %367, %364
  %371 = mul nuw i64 %365, %364
  %372 = lshr i64 %368, 32
  %373 = add i64 %370, %369
  %374 = add i64 %373, %372
  %375 = icmp ult i64 %374, %370
  %376 = add nuw i64 %371, 4294967296
  %377 = select i1 %375, i64 %376, i64 %371
  %378 = lshr i64 %374, 32
  %379 = shl i64 %374, 32
  %380 = and i64 %368, 4294967295
  %381 = or disjoint i64 %379, %380
  %382 = sub i64 %359, %381
  %383 = icmp ult i64 %359, %381
  %384 = sext i1 %383 to i64
  %385 = add i64 %351, %363
  %386 = add i64 %385, %361
  %387 = add i64 %378, %377
  %388 = sub i64 %386, %387
  %389 = add i64 %388, %384
  %390 = add i64 %357, 1
  %391 = icmp uge i64 %389, %352
  %392 = sext i1 %391 to i64
  %393 = add i64 %390, %392
  %394 = select i1 %391, i64 %40, i64 0
  %395 = add i64 %394, %382
  %396 = select i1 %391, i64 %38, i64 0
  %397 = add i64 %396, %389
  %398 = icmp ult i64 %395, %382
  %399 = zext i1 %398 to i64
  %400 = add i64 %397, %399
  %401 = icmp ult i64 %400, %38
  br i1 %401, label %412, label %402, !prof !68

402:                                              ; preds = %332
  %403 = icmp ule i64 %400, %38
  %404 = icmp ult i64 %395, %40
  %405 = select i1 %403, i1 %404, i1 false
  br i1 %405, label %412, label %406

406:                                              ; preds = %402
  %407 = add i64 %393, 1
  %408 = sub i64 %395, %40
  %409 = sext i1 %404 to i64
  %410 = sub i64 %409, %38
  %411 = add i64 %410, %400
  br label %412

412:                                              ; preds = %406, %402, %332
  %413 = phi i64 [ %407, %406 ], [ %393, %332 ], [ %393, %402 ]
  %414 = phi i64 [ %408, %406 ], [ %395, %332 ], [ %395, %402 ]
  %415 = phi i64 [ %411, %406 ], [ %400, %332 ], [ %400, %402 ]
  store i64 %415, ptr %307, align 8, !tbaa !15
  store i64 %414, ptr %309, align 8, !tbaa !15
  br label %416

416:                                              ; preds = %412, %329
  %417 = phi i64 [ %330, %329 ], [ %413, %412 ]
  %418 = phi i64 [ %331, %329 ], [ %415, %412 ]
  %419 = getelementptr inbounds i8, ptr %308, i64 -8
  store i64 %417, ptr %419, align 8, !tbaa !15
  br label %420

420:                                              ; preds = %416, %165
  %421 = phi i64 [ %418, %416 ], [ %166, %165 ]
  %422 = phi ptr [ %309, %416 ], [ %167, %165 ]
  %423 = getelementptr inbounds i8, ptr %422, i64 8
  %424 = load i64, ptr %423, align 8, !tbaa !15
  %425 = icmp eq i64 %424, %421
  br i1 %425, label %427, label %426, !prof !68

426:                                              ; preds = %420
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.189, i32 noundef 195, ptr noundef nonnull @.str.1.190) #18
  unreachable

427:                                              ; preds = %420
  %428 = zext i1 %30 to i64
  ret i64 %428
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_dcpi1_div_qr_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = ashr i64 %3, 1
  %8 = sub nsw i64 %3, %7
  %9 = icmp sgt i64 %8, 59
  %10 = getelementptr inbounds i64, ptr %0, i64 %7
  %11 = and i64 %3, -2
  %12 = getelementptr inbounds i64, ptr %1, i64 %11
  br i1 %9, label %18, label %13

13:                                               ; preds = %6
  %14 = shl nsw i64 %8, 1
  %15 = getelementptr inbounds i64, ptr %2, i64 %7
  %16 = load i64, ptr %4, align 8, !tbaa !357
  %17 = tail call i64 @__gmpn_sbpi1_div_qr(ptr noundef %10, ptr noundef %12, i64 noundef %14, ptr noundef %15, i64 noundef %8, i64 noundef %16) #16
  br label %21

18:                                               ; preds = %6
  %19 = getelementptr inbounds i64, ptr %2, i64 %7
  %20 = tail call i64 @__gmpn_dcpi1_div_qr_n(ptr noundef %10, ptr noundef %12, ptr noundef %19, i64 noundef %8, ptr noundef %4, ptr noundef %5)
  br label %21

21:                                               ; preds = %18, %13
  %22 = phi i64 [ %20, %18 ], [ %17, %13 ]
  %23 = getelementptr inbounds i64, ptr %0, i64 %7
  %24 = tail call i64 @__gmpn_mul(ptr noundef %5, ptr noundef %23, i64 noundef %8, ptr noundef %2, i64 noundef %7) #16
  %25 = getelementptr inbounds i64, ptr %1, i64 %7
  %26 = tail call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %25, ptr noundef %5, i64 noundef %3) #16
  %27 = icmp eq i64 %22, 0
  br i1 %27, label %32, label %28

28:                                               ; preds = %21
  %29 = getelementptr inbounds i64, ptr %1, i64 %3
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef %29, ptr noundef %29, ptr noundef %2, i64 noundef %7) #16
  %31 = add i64 %30, %26
  br label %32

32:                                               ; preds = %28, %21
  %33 = phi i64 [ %31, %28 ], [ %26, %21 ]
  %34 = icmp eq i64 %33, 0
  br i1 %34, label %58, label %35

35:                                               ; preds = %32
  %36 = tail call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %37

37:                                               ; preds = %52, %35
  %38 = phi i64 [ %22, %35 ], [ %54, %52 ]
  %39 = phi i64 [ %33, %35 ], [ %56, %52 ]
  %40 = load i64, ptr %23, align 8, !tbaa !15
  %41 = add i64 %40, -1
  store i64 %41, ptr %23, align 8, !tbaa !15
  %42 = icmp eq i64 %40, 0
  br i1 %42, label %43, label %52

43:                                               ; preds = %46, %37
  %44 = phi i64 [ %50, %46 ], [ 1, %37 ]
  %45 = icmp eq i64 %44, %36
  br i1 %45, label %52, label %46

46:                                               ; preds = %43
  %47 = getelementptr inbounds i64, ptr %23, i64 %44
  %48 = load i64, ptr %47, align 8, !tbaa !15
  %49 = add i64 %48, -1
  store i64 %49, ptr %47, align 8, !tbaa !15
  %50 = add nuw i64 %44, 1
  %51 = icmp eq i64 %48, 0
  br i1 %51, label %43, label %52, !llvm.loop !359

52:                                               ; preds = %46, %43, %37
  %53 = phi i64 [ 0, %37 ], [ -1, %43 ], [ 0, %46 ]
  %54 = add i64 %53, %38
  %55 = tail call i64 @__gmpn_add_n(ptr noundef %25, ptr noundef %25, ptr noundef %2, i64 noundef %3) #16
  %56 = sub i64 %39, %55
  %57 = icmp eq i64 %56, 0
  br i1 %57, label %58, label %37, !llvm.loop !360

58:                                               ; preds = %52, %32
  %59 = phi i64 [ %22, %32 ], [ %54, %52 ]
  %60 = icmp sgt i64 %7, 59
  %61 = getelementptr inbounds i64, ptr %1, i64 %8
  br i1 %60, label %67, label %62

62:                                               ; preds = %58
  %63 = and i64 %3, -2
  %64 = getelementptr inbounds i64, ptr %2, i64 %8
  %65 = load i64, ptr %4, align 8, !tbaa !357
  %66 = tail call i64 @__gmpn_sbpi1_div_qr(ptr noundef %0, ptr noundef %61, i64 noundef %63, ptr noundef %64, i64 noundef %7, i64 noundef %65) #16
  br label %70

67:                                               ; preds = %58
  %68 = getelementptr inbounds i64, ptr %2, i64 %8
  %69 = tail call i64 @__gmpn_dcpi1_div_qr_n(ptr noundef %0, ptr noundef %61, ptr noundef %68, i64 noundef %7, ptr noundef %4, ptr noundef %5)
  br label %70

70:                                               ; preds = %67, %62
  %71 = phi i64 [ %69, %67 ], [ %66, %62 ]
  %72 = tail call i64 @__gmpn_mul(ptr noundef %5, ptr noundef %2, i64 noundef %8, ptr noundef %0, i64 noundef %7) #16
  %73 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %5, i64 noundef %3) #16
  %74 = icmp eq i64 %71, 0
  br i1 %74, label %78, label %75

75:                                               ; preds = %70
  %76 = tail call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %25, ptr noundef %2, i64 noundef %8) #16
  %77 = add i64 %76, %73
  br label %78

78:                                               ; preds = %75, %70
  %79 = phi i64 [ %77, %75 ], [ %73, %70 ]
  %80 = icmp eq i64 %79, 0
  br i1 %80, label %101, label %81

81:                                               ; preds = %78
  %82 = tail call i64 @llvm.smax.i64(i64 %7, i64 1)
  br label %83

83:                                               ; preds = %97, %81
  %84 = phi i64 [ %79, %81 ], [ %99, %97 ]
  %85 = load i64, ptr %0, align 8, !tbaa !15
  %86 = add i64 %85, -1
  store i64 %86, ptr %0, align 8, !tbaa !15
  %87 = icmp eq i64 %85, 0
  br i1 %87, label %88, label %97

88:                                               ; preds = %91, %83
  %89 = phi i64 [ %95, %91 ], [ 1, %83 ]
  %90 = icmp eq i64 %89, %82
  br i1 %90, label %97, label %91

91:                                               ; preds = %88
  %92 = getelementptr inbounds i64, ptr %0, i64 %89
  %93 = load i64, ptr %92, align 8, !tbaa !15
  %94 = add i64 %93, -1
  store i64 %94, ptr %92, align 8, !tbaa !15
  %95 = add nuw nsw i64 %89, 1
  %96 = icmp eq i64 %93, 0
  br i1 %96, label %88, label %97, !llvm.loop !359

97:                                               ; preds = %91, %88, %83
  %98 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %3) #16
  %99 = sub i64 %84, %98
  %100 = icmp eq i64 %99, 0
  br i1 %100, label %101, label %83, !llvm.loop !361

101:                                              ; preds = %97, %78
  ret i64 %59
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_dcpi1_divappr_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  store ptr null, ptr %7, align 8, !tbaa !7
  %8 = sub nsw i64 %2, %4
  %9 = getelementptr inbounds i64, ptr %0, i64 %8
  %10 = getelementptr inbounds i64, ptr %1, i64 %2
  %11 = getelementptr inbounds i64, ptr %3, i64 %4
  %12 = icmp slt i64 %8, %4
  br i1 %12, label %280, label %13

13:                                               ; preds = %6
  %14 = add nsw i64 %8, 1
  br label %15

15:                                               ; preds = %15, %13
  %16 = phi i64 [ %14, %13 ], [ %17, %15 ]
  %17 = sub nsw i64 %16, %4
  %18 = icmp sgt i64 %17, %4
  br i1 %18, label %15, label %19, !llvm.loop !362

19:                                               ; preds = %15
  %20 = sub i64 0, %17
  %21 = getelementptr inbounds i64, ptr %9, i64 %20
  %22 = getelementptr inbounds i64, ptr %10, i64 %20
  %23 = shl i64 %4, 3
  %24 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %23) #16
  switch i64 %17, label %174 [
    i64 1, label %25
    i64 2, label %170
  ]

25:                                               ; preds = %19
  %26 = sub i64 0, %4
  %27 = getelementptr inbounds i64, ptr %22, i64 %26
  %28 = getelementptr inbounds i8, ptr %27, i64 8
  br label %29

29:                                               ; preds = %32, %25
  %30 = phi i64 [ %4, %25 ], [ %33, %32 ]
  %31 = icmp sgt i64 %30, 0
  br i1 %31, label %32, label %41

32:                                               ; preds = %29
  %33 = add nsw i64 %30, -1
  %34 = getelementptr i64, ptr %27, i64 %30
  %35 = load i64, ptr %34, align 8, !tbaa !15
  %36 = getelementptr inbounds i64, ptr %3, i64 %33
  %37 = load i64, ptr %36, align 8, !tbaa !15
  %38 = icmp eq i64 %35, %37
  br i1 %38, label %29, label %39, !llvm.loop !363

39:                                               ; preds = %32
  %40 = icmp ugt i64 %35, %37
  br label %41

41:                                               ; preds = %39, %29
  %42 = phi i1 [ %40, %39 ], [ true, %29 ]
  %43 = zext i1 %42 to i64
  br i1 %42, label %44, label %46

44:                                               ; preds = %41
  %45 = call i64 @__gmpn_sub_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %3, i64 noundef %4) #16
  br label %46

46:                                               ; preds = %44, %41
  %47 = load i64, ptr %22, align 8, !tbaa !15
  %48 = getelementptr inbounds i8, ptr %22, i64 -8
  %49 = load i64, ptr %48, align 8, !tbaa !15
  %50 = getelementptr inbounds i8, ptr %22, i64 -16
  %51 = load i64, ptr %50, align 8, !tbaa !15
  %52 = getelementptr inbounds i8, ptr %11, i64 -8
  %53 = load i64, ptr %52, align 8, !tbaa !15
  %54 = getelementptr inbounds i8, ptr %11, i64 -16
  %55 = load i64, ptr %54, align 8, !tbaa !15
  %56 = icmp eq i64 %47, %53
  br i1 %56, label %57, label %61, !prof !54

57:                                               ; preds = %46
  %58 = icmp eq i64 %49, %55
  br i1 %58, label %59, label %61

59:                                               ; preds = %57
  %60 = call i64 @__gmpn_submul_1(ptr noundef nonnull %27, ptr noundef %3, i64 noundef %4, i64 noundef -1) #16
  br label %167

61:                                               ; preds = %57, %46
  %62 = load i64, ptr %5, align 8, !tbaa !357
  %63 = lshr i64 %47, 32
  %64 = lshr i64 %62, 32
  %65 = and i64 %47, 4294967295
  %66 = and i64 %62, 4294967295
  %67 = mul nuw i64 %66, %65
  %68 = mul nuw i64 %64, %65
  %69 = mul nuw i64 %66, %63
  %70 = mul nuw i64 %64, %63
  %71 = lshr i64 %67, 32
  %72 = add i64 %69, %68
  %73 = add i64 %72, %71
  %74 = icmp ult i64 %73, %69
  %75 = add nuw i64 %70, 4294967296
  %76 = select i1 %74, i64 %75, i64 %70
  %77 = lshr i64 %73, 32
  %78 = shl i64 %73, 32
  %79 = and i64 %67, 4294967295
  %80 = or disjoint i64 %78, %79
  %81 = add i64 %80, %49
  %82 = icmp ult i64 %81, %80
  %83 = zext i1 %82 to i64
  %84 = add i64 %77, %47
  %85 = add i64 %84, %76
  %86 = add i64 %85, %83
  %87 = sub i64 %51, %55
  %88 = xor i64 %86, -1
  %89 = mul i64 %53, %88
  %90 = icmp ult i64 %51, %55
  %91 = sext i1 %90 to i64
  %92 = lshr i64 %55, 32
  %93 = lshr i64 %86, 32
  %94 = and i64 %55, 4294967295
  %95 = and i64 %86, 4294967295
  %96 = mul nuw i64 %95, %94
  %97 = mul nuw i64 %93, %94
  %98 = mul nuw i64 %95, %92
  %99 = mul nuw i64 %93, %92
  %100 = lshr i64 %96, 32
  %101 = add i64 %98, %97
  %102 = add i64 %101, %100
  %103 = icmp ult i64 %102, %98
  %104 = add nuw i64 %99, 4294967296
  %105 = select i1 %103, i64 %104, i64 %99
  %106 = lshr i64 %102, 32
  %107 = shl i64 %102, 32
  %108 = and i64 %96, 4294967295
  %109 = or disjoint i64 %107, %108
  %110 = sub i64 %87, %109
  %111 = icmp ult i64 %87, %109
  %112 = sext i1 %111 to i64
  %113 = add i64 %49, %91
  %114 = add i64 %113, %89
  %115 = add i64 %106, %105
  %116 = sub i64 %114, %115
  %117 = add i64 %116, %112
  %118 = add i64 %86, 1
  %119 = icmp uge i64 %117, %81
  %120 = sext i1 %119 to i64
  %121 = add i64 %118, %120
  %122 = select i1 %119, i64 %55, i64 0
  %123 = add i64 %122, %110
  %124 = select i1 %119, i64 %53, i64 0
  %125 = add i64 %124, %117
  %126 = icmp ult i64 %123, %110
  %127 = zext i1 %126 to i64
  %128 = add i64 %125, %127
  %129 = icmp ult i64 %128, %53
  br i1 %129, label %140, label %130, !prof !68

130:                                              ; preds = %61
  %131 = icmp ule i64 %128, %53
  %132 = icmp ult i64 %123, %55
  %133 = select i1 %131, i1 %132, i1 false
  br i1 %133, label %140, label %134

134:                                              ; preds = %130
  %135 = add i64 %121, 1
  %136 = sub i64 %123, %55
  %137 = sext i1 %132 to i64
  %138 = sub i64 %137, %53
  %139 = add i64 %138, %128
  br label %140

140:                                              ; preds = %134, %130, %61
  %141 = phi i64 [ %136, %134 ], [ %123, %61 ], [ %123, %130 ]
  %142 = phi i64 [ %139, %134 ], [ %128, %61 ], [ %128, %130 ]
  %143 = phi i64 [ %135, %134 ], [ %121, %61 ], [ %121, %130 ]
  %144 = icmp sgt i64 %4, 2
  br i1 %144, label %145, label %162

145:                                              ; preds = %140
  %146 = add nsw i64 %4, -2
  %147 = call i64 @__gmpn_submul_1(ptr noundef nonnull %27, ptr noundef %3, i64 noundef %146, i64 noundef %143) #16
  %148 = icmp ult i64 %141, %147
  %149 = zext i1 %148 to i64
  %150 = sub i64 %141, %147
  %151 = icmp ult i64 %142, %149
  %152 = sub i64 %142, %149
  store i64 %150, ptr %50, align 8, !tbaa !15
  br i1 %151, label %153, label %163, !prof !54

153:                                              ; preds = %145
  %154 = add nsw i64 %4, -1
  %155 = call i64 @__gmpn_add_n(ptr noundef nonnull %27, ptr noundef nonnull %27, ptr noundef %3, i64 noundef %154) #16
  %156 = add i64 %152, %53
  %157 = add i64 %156, %155
  %158 = icmp eq i64 %143, 0
  %159 = sext i1 %158 to i64
  %160 = add nsw i64 %159, %43
  %161 = add i64 %143, -1
  br label %163

162:                                              ; preds = %140
  store i64 %141, ptr %50, align 8, !tbaa !15
  br label %163

163:                                              ; preds = %162, %153, %145
  %164 = phi i64 [ %142, %162 ], [ %157, %153 ], [ %152, %145 ]
  %165 = phi i64 [ %143, %162 ], [ %161, %153 ], [ %143, %145 ]
  %166 = phi i64 [ %43, %162 ], [ %160, %153 ], [ %43, %145 ]
  store i64 %164, ptr %48, align 8, !tbaa !15
  br label %167

167:                                              ; preds = %163, %59
  %168 = phi i64 [ -1, %59 ], [ %165, %163 ]
  %169 = phi i64 [ %43, %59 ], [ %166, %163 ]
  store i64 %168, ptr %21, align 8, !tbaa !15
  br label %230

170:                                              ; preds = %19
  %171 = getelementptr inbounds i8, ptr %22, i64 -16
  %172 = getelementptr inbounds i8, ptr %11, i64 -16
  %173 = call i64 @__gmpn_divrem_2(ptr noundef nonnull %21, i64 noundef 0, ptr noundef nonnull %171, i64 noundef 4, ptr noundef nonnull %172) #16
  br label %185

174:                                              ; preds = %19
  %175 = icmp sgt i64 %17, 59
  %176 = getelementptr inbounds i64, ptr %22, i64 %20
  br i1 %175, label %182, label %177

177:                                              ; preds = %174
  %178 = shl nsw i64 %17, 1
  %179 = getelementptr inbounds i64, ptr %11, i64 %20
  %180 = load i64, ptr %5, align 8, !tbaa !357
  %181 = call i64 @__gmpn_sbpi1_div_qr(ptr noundef %21, ptr noundef %176, i64 noundef %178, ptr noundef %179, i64 noundef %17, i64 noundef %180) #16
  br label %185

182:                                              ; preds = %174
  %183 = getelementptr inbounds i64, ptr %11, i64 %20
  %184 = call i64 @__gmpn_dcpi1_div_qr_n(ptr noundef nonnull %21, ptr noundef nonnull %176, ptr noundef nonnull %183, i64 noundef %17, ptr noundef %5, ptr noundef %24) #16
  br label %185

185:                                              ; preds = %182, %177, %170
  %186 = phi i64 [ %173, %170 ], [ %184, %182 ], [ %181, %177 ]
  %187 = icmp eq i64 %17, %4
  br i1 %187, label %230, label %188

188:                                              ; preds = %185
  %189 = sub nsw i64 %4, %17
  %190 = icmp sgt i64 %17, %189
  br i1 %190, label %191, label %193

191:                                              ; preds = %188
  %192 = call i64 @__gmpn_mul(ptr noundef %24, ptr noundef %21, i64 noundef %17, ptr noundef %3, i64 noundef %189) #16
  br label %195

193:                                              ; preds = %188
  %194 = call i64 @__gmpn_mul(ptr noundef %24, ptr noundef %3, i64 noundef %189, ptr noundef %21, i64 noundef %17) #16
  br label %195

195:                                              ; preds = %193, %191
  %196 = sub i64 0, %4
  %197 = getelementptr inbounds i64, ptr %22, i64 %196
  %198 = call i64 @__gmpn_sub_n(ptr noundef %197, ptr noundef %197, ptr noundef %24, i64 noundef %4) #16
  %199 = icmp eq i64 %186, 0
  br i1 %199, label %204, label %200

200:                                              ; preds = %195
  %201 = getelementptr inbounds i64, ptr %197, i64 %17
  %202 = call i64 @__gmpn_sub_n(ptr noundef %201, ptr noundef %201, ptr noundef %3, i64 noundef %189) #16
  %203 = add i64 %202, %198
  br label %204

204:                                              ; preds = %200, %195
  %205 = phi i64 [ %203, %200 ], [ %198, %195 ]
  %206 = icmp eq i64 %205, 0
  br i1 %206, label %230, label %207

207:                                              ; preds = %204
  %208 = call i64 @llvm.smax.i64(i64 %17, i64 1)
  br label %209

209:                                              ; preds = %224, %207
  %210 = phi i64 [ %186, %207 ], [ %226, %224 ]
  %211 = phi i64 [ %205, %207 ], [ %228, %224 ]
  %212 = load i64, ptr %21, align 8, !tbaa !15
  %213 = add i64 %212, -1
  store i64 %213, ptr %21, align 8, !tbaa !15
  %214 = icmp eq i64 %212, 0
  br i1 %214, label %215, label %224

215:                                              ; preds = %218, %209
  %216 = phi i64 [ %222, %218 ], [ 1, %209 ]
  %217 = icmp eq i64 %216, %208
  br i1 %217, label %224, label %218

218:                                              ; preds = %215
  %219 = getelementptr inbounds i64, ptr %21, i64 %216
  %220 = load i64, ptr %219, align 8, !tbaa !15
  %221 = add i64 %220, -1
  store i64 %221, ptr %219, align 8, !tbaa !15
  %222 = add nuw i64 %216, 1
  %223 = icmp eq i64 %220, 0
  br i1 %223, label %215, label %224, !llvm.loop !364

224:                                              ; preds = %218, %215, %209
  %225 = phi i64 [ 0, %209 ], [ -1, %215 ], [ 0, %218 ]
  %226 = add i64 %225, %210
  %227 = call i64 @__gmpn_add_n(ptr noundef %197, ptr noundef %197, ptr noundef %3, i64 noundef %4) #16
  %228 = sub i64 %211, %227
  %229 = icmp eq i64 %228, 0
  br i1 %229, label %230, label %209, !llvm.loop !365

230:                                              ; preds = %224, %204, %185, %167
  %231 = phi i64 [ %169, %167 ], [ %186, %185 ], [ %186, %204 ], [ %226, %224 ]
  %232 = add i64 %8, 1
  %233 = sub i64 %232, %17
  %234 = icmp sgt i64 %233, %4
  br i1 %234, label %235, label %247

235:                                              ; preds = %230
  %236 = sub i64 0, %4
  br label %237

237:                                              ; preds = %237, %235
  %238 = phi ptr [ %21, %235 ], [ %241, %237 ]
  %239 = phi ptr [ %22, %235 ], [ %242, %237 ]
  %240 = phi i64 [ %233, %235 ], [ %245, %237 ]
  %241 = getelementptr inbounds i64, ptr %238, i64 %236
  %242 = getelementptr inbounds i64, ptr %239, i64 %236
  %243 = getelementptr inbounds i64, ptr %242, i64 %236
  %244 = call i64 @__gmpn_dcpi1_div_qr_n(ptr noundef %241, ptr noundef %243, ptr noundef %3, i64 noundef %4, ptr noundef %5, ptr noundef %24) #16
  %245 = sub nsw i64 %240, %4
  %246 = icmp sgt i64 %245, %4
  br i1 %246, label %237, label %247, !llvm.loop !366

247:                                              ; preds = %237, %230
  %248 = phi i64 [ %233, %230 ], [ %245, %237 ]
  %249 = phi ptr [ %22, %230 ], [ %242, %237 ]
  %250 = phi ptr [ %21, %230 ], [ %241, %237 ]
  %251 = sub i64 1, %248
  %252 = getelementptr inbounds i64, ptr %250, i64 %251
  %253 = sub i64 0, %4
  %254 = getelementptr inbounds i64, ptr %249, i64 %253
  %255 = load i64, ptr %250, align 8, !tbaa !15
  %256 = getelementptr inbounds i64, ptr %254, i64 %253
  %257 = call fastcc i64 @mpn_dcpi1_divappr_q_n(ptr noundef nonnull %252, ptr noundef %256, ptr noundef %3, i64 noundef %4, ptr noundef %5, ptr noundef %24)
  %258 = icmp eq i64 %248, 1
  br i1 %258, label %279, label %259

259:                                              ; preds = %247
  %260 = add nsw i64 %248, -2
  %261 = getelementptr inbounds i8, ptr %252, i64 8
  %262 = load i64, ptr %261, align 8, !tbaa !15
  %263 = icmp eq i64 %260, 0
  br i1 %263, label %276, label %264

264:                                              ; preds = %259
  %265 = getelementptr inbounds i8, ptr %252, i64 16
  br label %266

266:                                              ; preds = %266, %264
  %267 = phi i64 [ %274, %266 ], [ %260, %264 ]
  %268 = phi ptr [ %271, %266 ], [ %252, %264 ]
  %269 = phi ptr [ %272, %266 ], [ %265, %264 ]
  %270 = phi i64 [ %273, %266 ], [ %262, %264 ]
  %271 = getelementptr inbounds i8, ptr %268, i64 8
  store i64 %270, ptr %268, align 8, !tbaa !15
  %272 = getelementptr inbounds i8, ptr %269, i64 8
  %273 = load i64, ptr %269, align 8, !tbaa !15
  %274 = add nsw i64 %267, -1
  %275 = icmp eq i64 %274, 0
  br i1 %275, label %276, label %266, !llvm.loop !367

276:                                              ; preds = %266, %259
  %277 = phi ptr [ %252, %259 ], [ %271, %266 ]
  %278 = phi i64 [ %262, %259 ], [ %273, %266 ]
  store i64 %278, ptr %277, align 8, !tbaa !15
  br label %279

279:                                              ; preds = %276, %247
  store i64 %255, ptr %250, align 8, !tbaa !15
  br label %323

280:                                              ; preds = %6
  %281 = sub i64 0, %8
  %282 = getelementptr inbounds i64, ptr %10, i64 %281
  %283 = add nsw i64 %8, 1
  %284 = shl i64 %283, 3
  %285 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %284) #16
  %286 = icmp sgt i64 %8, 199
  %287 = xor i64 %8, -1
  %288 = getelementptr inbounds i64, ptr %11, i64 %287
  br i1 %286, label %295, label %289

289:                                              ; preds = %280
  %290 = getelementptr inbounds i64, ptr %282, i64 %281
  %291 = getelementptr inbounds i8, ptr %290, i64 -16
  %292 = shl nsw i64 %283, 1
  %293 = load i64, ptr %5, align 8, !tbaa !357
  %294 = call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %285, ptr noundef nonnull %291, i64 noundef %292, ptr noundef %288, i64 noundef %283, i64 noundef %293) #16
  br label %300

295:                                              ; preds = %280
  %296 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %284) #16
  %297 = getelementptr inbounds i64, ptr %282, i64 %281
  %298 = getelementptr inbounds i8, ptr %297, i64 -16
  %299 = call fastcc i64 @mpn_dcpi1_divappr_q_n(ptr noundef %285, ptr noundef nonnull %298, ptr noundef nonnull %288, i64 noundef %283, ptr noundef %5, ptr noundef %296)
  br label %300

300:                                              ; preds = %295, %289
  %301 = phi i64 [ %299, %295 ], [ %294, %289 ]
  %302 = icmp eq i64 %2, %4
  br i1 %302, label %323, label %303

303:                                              ; preds = %300
  %304 = add nsw i64 %8, -1
  %305 = getelementptr inbounds i8, ptr %285, i64 8
  %306 = load i64, ptr %305, align 8, !tbaa !15
  %307 = icmp eq i64 %304, 0
  br i1 %307, label %320, label %308

308:                                              ; preds = %303
  %309 = getelementptr inbounds i8, ptr %285, i64 16
  br label %310

310:                                              ; preds = %310, %308
  %311 = phi i64 [ %318, %310 ], [ %304, %308 ]
  %312 = phi ptr [ %315, %310 ], [ %0, %308 ]
  %313 = phi ptr [ %316, %310 ], [ %309, %308 ]
  %314 = phi i64 [ %317, %310 ], [ %306, %308 ]
  %315 = getelementptr inbounds i8, ptr %312, i64 8
  store i64 %314, ptr %312, align 8, !tbaa !15
  %316 = getelementptr inbounds i8, ptr %313, i64 8
  %317 = load i64, ptr %313, align 8, !tbaa !15
  %318 = add nsw i64 %311, -1
  %319 = icmp eq i64 %318, 0
  br i1 %319, label %320, label %310, !llvm.loop !368

320:                                              ; preds = %310, %303
  %321 = phi ptr [ %0, %303 ], [ %315, %310 ]
  %322 = phi i64 [ %306, %303 ], [ %317, %310 ]
  store i64 %322, ptr %321, align 8, !tbaa !15
  br label %323

323:                                              ; preds = %320, %300, %279
  %324 = phi i64 [ %231, %279 ], [ %301, %320 ], [ %301, %300 ]
  %325 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %325) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret i64 %324
}

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_mu_divappr_q_itch(i64 noundef %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #7 {
  %4 = sub nsw i64 %0, %1
  %5 = add nsw i64 %4, 1
  %6 = tail call i64 @llvm.smin.i64(i64 %5, i64 %1)
  %7 = icmp eq i32 %2, 0
  br i1 %7, label %8, label %23

8:                                                ; preds = %3
  %9 = icmp sgt i64 %4, %1
  br i1 %9, label %10, label %16

10:                                               ; preds = %8
  %11 = add nsw i64 %4, -1
  %12 = sdiv i64 %11, %6
  %13 = add nsw i64 %12, 1
  %14 = sdiv i64 %11, %13
  %15 = add nsw i64 %14, 1
  br label %29

16:                                               ; preds = %8
  %17 = mul nsw i64 %4, 3
  %18 = icmp sgt i64 %17, %6
  br i1 %18, label %19, label %29

19:                                               ; preds = %16
  %20 = add nsw i64 %4, -1
  %21 = sdiv i64 %20, 2
  %22 = add nsw i64 %21, 1
  br label %29

23:                                               ; preds = %3
  %24 = tail call i64 @llvm.smin.i64(i64 %6, i64 %4)
  %25 = add nsw i64 %24, -1
  %26 = sext i32 %2 to i64
  %27 = sdiv i64 %25, %26
  %28 = add nsw i64 %27, 1
  br label %29

29:                                               ; preds = %23, %19, %16, %10
  %30 = phi i64 [ %28, %23 ], [ %15, %10 ], [ %22, %19 ], [ %4, %16 ]
  %31 = add nsw i64 %6, 1
  %32 = tail call i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %31) #17
  %33 = ashr i64 %32, 1
  %34 = icmp slt i64 %33, %6
  %35 = icmp slt i64 %33, %30
  %36 = select i1 %35, i64 %32, i64 %33
  %37 = select i1 %34, i64 %36, i64 0
  %38 = shl i64 %30, 1
  %39 = add i64 %30, 4
  %40 = add i64 %39, %38
  %41 = shl i64 %32, 1
  %42 = add i64 %6, 4
  %43 = add i64 %42, %41
  %44 = add i64 %43, %37
  %45 = tail call i64 @llvm.smax.i64(i64 %44, i64 %40)
  %46 = add nsw i64 %45, %30
  ret i64 %46
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_mu_divappr_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = sub nsw i64 %2, %4
  %8 = add nsw i64 %7, 1
  %9 = icmp slt i64 %8, %4
  br i1 %9, label %10, label %15

10:                                               ; preds = %6
  %11 = sub nsw i64 %4, %8
  %12 = getelementptr inbounds i64, ptr %1, i64 %11
  %13 = sub nsw i64 %2, %11
  %14 = getelementptr inbounds i64, ptr %3, i64 %11
  br label %15

15:                                               ; preds = %10, %6
  %16 = phi i64 [ %8, %10 ], [ %4, %6 ]
  %17 = phi ptr [ %14, %10 ], [ %3, %6 ]
  %18 = phi i64 [ %13, %10 ], [ %2, %6 ]
  %19 = phi ptr [ %12, %10 ], [ %1, %6 ]
  %20 = icmp sgt i64 %7, %16
  br i1 %20, label %21, label %27

21:                                               ; preds = %15
  %22 = add nsw i64 %7, -1
  %23 = sdiv i64 %22, %16
  %24 = add nsw i64 %23, 1
  %25 = sdiv i64 %22, %24
  %26 = add nsw i64 %25, 1
  br label %34

27:                                               ; preds = %15
  %28 = mul nsw i64 %7, 3
  %29 = icmp sgt i64 %28, %16
  br i1 %29, label %30, label %34

30:                                               ; preds = %27
  %31 = add nsw i64 %7, -1
  %32 = sdiv i64 %31, 2
  %33 = add nsw i64 %32, 1
  br label %34

34:                                               ; preds = %30, %27, %21
  %35 = phi i64 [ %26, %21 ], [ %33, %30 ], [ %7, %27 ]
  %36 = getelementptr inbounds i64, ptr %5, i64 %35
  %37 = getelementptr inbounds i8, ptr %36, i64 8
  %38 = icmp eq i64 %16, %35
  br i1 %38, label %39, label %80

39:                                               ; preds = %34
  %40 = icmp eq i64 %35, 0
  br i1 %40, label %151, label %41

41:                                               ; preds = %39
  %42 = add nsw i64 %35, -1
  %43 = getelementptr inbounds i8, ptr %36, i64 16
  %44 = load i64, ptr %17, align 8, !tbaa !15
  %45 = icmp eq i64 %42, 0
  br i1 %45, label %56, label %46

46:                                               ; preds = %46, %41
  %47 = phi i64 [ %54, %46 ], [ %42, %41 ]
  %48 = phi ptr [ %52, %46 ], [ %43, %41 ]
  %49 = phi ptr [ %51, %46 ], [ %17, %41 ]
  %50 = phi i64 [ %53, %46 ], [ %44, %41 ]
  %51 = getelementptr inbounds i8, ptr %49, i64 8
  %52 = getelementptr inbounds i8, ptr %48, i64 8
  store i64 %50, ptr %48, align 8, !tbaa !15
  %53 = load i64, ptr %51, align 8, !tbaa !15
  %54 = add nsw i64 %47, -1
  %55 = icmp eq i64 %54, 0
  br i1 %55, label %56, label %46, !llvm.loop !369

56:                                               ; preds = %46, %41
  %57 = phi ptr [ %43, %41 ], [ %52, %46 ]
  %58 = phi i64 [ %44, %41 ], [ %53, %46 ]
  store i64 %58, ptr %57, align 8, !tbaa !15
  store i64 1, ptr %37, align 8, !tbaa !15
  %59 = add nsw i64 %35, 1
  %60 = getelementptr inbounds i64, ptr %37, i64 %35
  %61 = getelementptr inbounds i8, ptr %60, i64 8
  %62 = tail call i64 @__gmpn_invertappr(ptr noundef %5, ptr noundef nonnull %37, i64 noundef %59, ptr noundef nonnull %61) #16
  %63 = getelementptr inbounds i8, ptr %5, i64 8
  %64 = load i64, ptr %63, align 8, !tbaa !15
  br i1 %45, label %77, label %65

65:                                               ; preds = %56
  %66 = getelementptr inbounds i8, ptr %5, i64 16
  br label %67

67:                                               ; preds = %67, %65
  %68 = phi i64 [ %75, %67 ], [ %42, %65 ]
  %69 = phi ptr [ %72, %67 ], [ %5, %65 ]
  %70 = phi ptr [ %73, %67 ], [ %66, %65 ]
  %71 = phi i64 [ %74, %67 ], [ %64, %65 ]
  %72 = getelementptr inbounds i8, ptr %69, i64 8
  store i64 %71, ptr %69, align 8, !tbaa !15
  %73 = getelementptr inbounds i8, ptr %70, i64 8
  %74 = load i64, ptr %70, align 8, !tbaa !15
  %75 = add nsw i64 %68, -1
  %76 = icmp eq i64 %75, 0
  br i1 %76, label %77, label %67, !llvm.loop !370

77:                                               ; preds = %67, %56
  %78 = phi ptr [ %5, %56 ], [ %72, %67 ]
  %79 = phi i64 [ %64, %56 ], [ %74, %67 ]
  store i64 %79, ptr %78, align 8, !tbaa !15
  br label %155

80:                                               ; preds = %34
  %81 = getelementptr inbounds i64, ptr %17, i64 %16
  %82 = add nsw i64 %35, 1
  %83 = xor i64 %35, -1
  %84 = getelementptr inbounds i64, ptr %81, i64 %83
  %85 = load i64, ptr %84, align 8, !tbaa !15
  %86 = add i64 %85, 1
  store i64 %86, ptr %37, align 8, !tbaa !15
  %87 = icmp eq i64 %86, 0
  br i1 %87, label %88, label %111

88:                                               ; preds = %80
  %89 = tail call i64 @llvm.smax.i64(i64 %82, i64 1)
  br label %90

90:                                               ; preds = %93, %88
  %91 = phi i64 [ %98, %93 ], [ 1, %88 ]
  %92 = icmp eq i64 %91, %89
  br i1 %92, label %122, label %93

93:                                               ; preds = %90
  %94 = getelementptr inbounds i64, ptr %84, i64 %91
  %95 = load i64, ptr %94, align 8, !tbaa !15
  %96 = add i64 %95, 1
  %97 = getelementptr inbounds i64, ptr %37, i64 %91
  store i64 %96, ptr %97, align 8, !tbaa !15
  %98 = add nuw i64 %91, 1
  %99 = icmp eq i64 %96, 0
  br i1 %99, label %90, label %100, !llvm.loop !371

100:                                              ; preds = %93
  %101 = icmp ne ptr %84, %37
  %102 = icmp sle i64 %98, %35
  %103 = select i1 %101, i1 %102, i1 false
  br i1 %103, label %104, label %126

104:                                              ; preds = %104, %100
  %105 = phi i64 [ %109, %104 ], [ %98, %100 ]
  %106 = getelementptr inbounds i64, ptr %84, i64 %105
  %107 = load i64, ptr %106, align 8, !tbaa !15
  %108 = getelementptr inbounds i64, ptr %37, i64 %105
  store i64 %107, ptr %108, align 8, !tbaa !15
  %109 = add nuw nsw i64 %105, 1
  %110 = icmp slt i64 %105, %35
  br i1 %110, label %104, label %126, !llvm.loop !372

111:                                              ; preds = %80
  %112 = icmp ne ptr %84, %37
  %113 = icmp sgt i64 %35, 0
  %114 = and i1 %113, %112
  br i1 %114, label %115, label %126

115:                                              ; preds = %115, %111
  %116 = phi i64 [ %120, %115 ], [ 1, %111 ]
  %117 = getelementptr inbounds i64, ptr %84, i64 %116
  %118 = load i64, ptr %117, align 8, !tbaa !15
  %119 = getelementptr inbounds i64, ptr %37, i64 %116
  store i64 %118, ptr %119, align 8, !tbaa !15
  %120 = add nuw nsw i64 %116, 1
  %121 = icmp eq i64 %116, %35
  br i1 %121, label %126, label %115, !llvm.loop !373

122:                                              ; preds = %90
  %123 = icmp eq i64 %35, 0
  br i1 %123, label %155, label %124

124:                                              ; preds = %122
  %125 = shl nuw i64 %35, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %5, i8 0, i64 %125, i1 false), !tbaa !15
  br label %155

126:                                              ; preds = %115, %111, %104, %100
  %127 = getelementptr inbounds i64, ptr %37, i64 %35
  %128 = getelementptr inbounds i8, ptr %127, i64 8
  %129 = tail call i64 @__gmpn_invertappr(ptr noundef %5, ptr noundef nonnull %37, i64 noundef %82, ptr noundef nonnull %128) #16
  %130 = icmp eq i64 %35, 0
  br i1 %130, label %155, label %131

131:                                              ; preds = %126
  %132 = add nsw i64 %35, -1
  %133 = getelementptr inbounds i8, ptr %5, i64 8
  %134 = load i64, ptr %133, align 8, !tbaa !15
  %135 = icmp eq i64 %132, 0
  br i1 %135, label %148, label %136

136:                                              ; preds = %131
  %137 = getelementptr inbounds i8, ptr %5, i64 16
  br label %138

138:                                              ; preds = %138, %136
  %139 = phi i64 [ %146, %138 ], [ %132, %136 ]
  %140 = phi ptr [ %143, %138 ], [ %5, %136 ]
  %141 = phi ptr [ %144, %138 ], [ %137, %136 ]
  %142 = phi i64 [ %145, %138 ], [ %134, %136 ]
  %143 = getelementptr inbounds i8, ptr %140, i64 8
  store i64 %142, ptr %140, align 8, !tbaa !15
  %144 = getelementptr inbounds i8, ptr %141, i64 8
  %145 = load i64, ptr %141, align 8, !tbaa !15
  %146 = add nsw i64 %139, -1
  %147 = icmp eq i64 %146, 0
  br i1 %147, label %148, label %138, !llvm.loop !374

148:                                              ; preds = %138, %131
  %149 = phi ptr [ %5, %131 ], [ %143, %138 ]
  %150 = phi i64 [ %134, %131 ], [ %145, %138 ]
  store i64 %150, ptr %149, align 8, !tbaa !15
  br label %155

151:                                              ; preds = %39
  store i64 1, ptr %37, align 8, !tbaa !15
  %152 = getelementptr inbounds i64, ptr %37, i64 %35
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = tail call i64 @__gmpn_invertappr(ptr noundef %5, ptr noundef nonnull %37, i64 noundef 1, ptr noundef nonnull %153) #16
  br label %155

155:                                              ; preds = %151, %148, %126, %124, %122, %77
  %156 = sub i64 %18, %16
  %157 = getelementptr inbounds i64, ptr %19, i64 %156
  %158 = getelementptr inbounds i64, ptr %0, i64 %156
  br label %159

159:                                              ; preds = %162, %155
  %160 = phi i64 [ %16, %155 ], [ %163, %162 ]
  %161 = icmp sgt i64 %160, 0
  br i1 %161, label %162, label %171

162:                                              ; preds = %159
  %163 = add nsw i64 %160, -1
  %164 = getelementptr inbounds i64, ptr %157, i64 %163
  %165 = load i64, ptr %164, align 8, !tbaa !15
  %166 = getelementptr inbounds i64, ptr %17, i64 %163
  %167 = load i64, ptr %166, align 8, !tbaa !15
  %168 = icmp eq i64 %165, %167
  br i1 %168, label %159, label %169, !llvm.loop !375

169:                                              ; preds = %162
  %170 = icmp ugt i64 %165, %167
  br label %171

171:                                              ; preds = %169, %159
  %172 = phi i1 [ %170, %169 ], [ true, %159 ]
  %173 = zext i1 %172 to i64
  br i1 %172, label %174, label %176

174:                                              ; preds = %171
  %175 = tail call i64 @__gmpn_sub_n(ptr noundef %36, ptr noundef %157, ptr noundef %17, i64 noundef %16) #16
  br label %195

176:                                              ; preds = %171
  %177 = icmp eq i64 %16, 0
  br i1 %177, label %195, label %178

178:                                              ; preds = %176
  %179 = add nsw i64 %16, -1
  %180 = load i64, ptr %157, align 8, !tbaa !15
  %181 = icmp eq i64 %179, 0
  br i1 %181, label %192, label %182

182:                                              ; preds = %182, %178
  %183 = phi i64 [ %190, %182 ], [ %179, %178 ]
  %184 = phi ptr [ %188, %182 ], [ %36, %178 ]
  %185 = phi ptr [ %187, %182 ], [ %157, %178 ]
  %186 = phi i64 [ %189, %182 ], [ %180, %178 ]
  %187 = getelementptr inbounds i8, ptr %185, i64 8
  %188 = getelementptr inbounds i8, ptr %184, i64 8
  store i64 %186, ptr %184, align 8, !tbaa !15
  %189 = load i64, ptr %187, align 8, !tbaa !15
  %190 = add nsw i64 %183, -1
  %191 = icmp eq i64 %190, 0
  br i1 %191, label %192, label %182, !llvm.loop !376

192:                                              ; preds = %182, %178
  %193 = phi ptr [ %36, %178 ], [ %188, %182 ]
  %194 = phi i64 [ %180, %178 ], [ %189, %182 ]
  store i64 %194, ptr %193, align 8, !tbaa !15
  br label %195

195:                                              ; preds = %192, %176, %174
  %196 = icmp eq i64 %156, 0
  br i1 %196, label %393, label %197, !prof !54

197:                                              ; preds = %195
  %198 = getelementptr inbounds i64, ptr %36, i64 %16
  %199 = add nsw i64 %16, 1
  %200 = getelementptr inbounds i64, ptr %198, i64 %16
  %201 = icmp eq i64 %16, 0
  %202 = add nsw i64 %16, -1
  %203 = icmp eq i64 %202, 0
  br label %204

204:                                              ; preds = %369, %197
  %205 = phi i64 [ %156, %197 ], [ %224, %369 ]
  %206 = phi i64 [ %35, %197 ], [ %212, %369 ]
  %207 = phi ptr [ %5, %197 ], [ %214, %369 ]
  %208 = phi ptr [ %157, %197 ], [ %216, %369 ]
  %209 = phi ptr [ %158, %197 ], [ %217, %369 ]
  %210 = icmp slt i64 %205, %206
  %211 = sub nsw i64 %206, %205
  %212 = tail call i64 @llvm.smin.i64(i64 %205, i64 %206)
  %213 = select i1 %210, i64 %211, i64 0
  %214 = getelementptr inbounds i64, ptr %207, i64 %213
  %215 = sub i64 0, %212
  %216 = getelementptr inbounds i64, ptr %208, i64 %215
  %217 = getelementptr inbounds i64, ptr %209, i64 %215
  %218 = getelementptr inbounds i64, ptr %198, i64 %215
  tail call void @__gmpn_mul_n(ptr noundef %198, ptr noundef %218, ptr noundef %214, i64 noundef %212) #16
  %219 = getelementptr inbounds i64, ptr %198, i64 %212
  %220 = tail call i64 @__gmpn_add_n(ptr noundef %217, ptr noundef %219, ptr noundef %218, i64 noundef %212) #16
  %221 = icmp eq i64 %220, 0
  br i1 %221, label %223, label %222, !prof !68

222:                                              ; preds = %204
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.269, i32 noundef 208, ptr noundef nonnull @.str.1.270) #18
  unreachable

223:                                              ; preds = %204
  %224 = sub nsw i64 %205, %212
  %225 = icmp eq i64 %224, 0
  br i1 %225, label %370, label %226

226:                                              ; preds = %223
  %227 = icmp sgt i64 %212, 31
  br i1 %227, label %230, label %228

228:                                              ; preds = %226
  %229 = tail call i64 @__gmpn_mul(ptr noundef %198, ptr noundef %17, i64 noundef %16, ptr noundef %217, i64 noundef %212) #16
  br label %287

230:                                              ; preds = %226
  %231 = tail call i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %199) #17
  %232 = getelementptr inbounds i64, ptr %198, i64 %231
  tail call void @__gmpn_mulmod_bnm1(ptr noundef %198, i64 noundef %231, ptr noundef %17, i64 noundef %16, ptr noundef nonnull %217, i64 noundef %212, ptr noundef %232) #16
  %233 = add nsw i64 %212, %16
  %234 = sub i64 %233, %231
  %235 = icmp sgt i64 %234, 0
  br i1 %235, label %236, label %287

236:                                              ; preds = %230
  %237 = sub nsw i64 0, %234
  %238 = getelementptr inbounds i64, ptr %198, i64 %237
  %239 = tail call i64 @__gmpn_sub_n(ptr noundef %198, ptr noundef %198, ptr noundef nonnull %238, i64 noundef %234) #16
  %240 = getelementptr inbounds i64, ptr %198, i64 %234
  %241 = load i64, ptr %240, align 8, !tbaa !15
  %242 = sub i64 %241, %239
  store i64 %242, ptr %240, align 8, !tbaa !15
  %243 = icmp ult i64 %241, %239
  br i1 %243, label %244, label %256

244:                                              ; preds = %236
  %245 = sub nsw i64 %231, %234
  %246 = tail call i64 @llvm.smax.i64(i64 %245, i64 1)
  br label %247

247:                                              ; preds = %250, %244
  %248 = phi i64 [ %254, %250 ], [ 1, %244 ]
  %249 = icmp eq i64 %248, %246
  br i1 %249, label %256, label %250

250:                                              ; preds = %247
  %251 = getelementptr inbounds i64, ptr %240, i64 %248
  %252 = load i64, ptr %251, align 8, !tbaa !15
  %253 = add i64 %252, -1
  store i64 %253, ptr %251, align 8, !tbaa !15
  %254 = add nuw i64 %248, 1
  %255 = icmp eq i64 %252, 0
  br i1 %255, label %247, label %256, !llvm.loop !377

256:                                              ; preds = %250, %247, %236
  %257 = phi i64 [ 0, %236 ], [ 1, %247 ], [ 0, %250 ]
  %258 = sub nsw i64 %231, %16
  br label %259

259:                                              ; preds = %262, %256
  %260 = phi i64 [ %258, %256 ], [ %263, %262 ]
  %261 = icmp sgt i64 %260, 0
  br i1 %261, label %262, label %272

262:                                              ; preds = %259
  %263 = add nsw i64 %260, -1
  %264 = getelementptr inbounds i64, ptr %218, i64 %263
  %265 = load i64, ptr %264, align 8, !tbaa !15
  %266 = getelementptr inbounds i64, ptr %200, i64 %263
  %267 = load i64, ptr %266, align 8, !tbaa !15
  %268 = icmp eq i64 %265, %267
  br i1 %268, label %259, label %269, !llvm.loop !375

269:                                              ; preds = %262
  %270 = icmp ule i64 %265, %267
  %271 = zext i1 %270 to i64
  br label %272

272:                                              ; preds = %269, %259
  %273 = phi i64 [ %271, %269 ], [ 0, %259 ]
  %274 = icmp ugt i64 %257, %273
  br i1 %274, label %275, label %276, !prof !54

275:                                              ; preds = %272
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.269, i32 noundef 230, ptr noundef nonnull @.str.2.271) #18
  unreachable

276:                                              ; preds = %272
  %277 = sub nsw i64 %273, %257
  %278 = load i64, ptr %198, align 8, !tbaa !15
  %279 = add i64 %278, %277
  store i64 %279, ptr %198, align 8, !tbaa !15
  %280 = icmp ult i64 %279, %277
  br i1 %280, label %281, label %287

281:                                              ; preds = %281, %276
  %282 = phi ptr [ %283, %281 ], [ %198, %276 ]
  %283 = getelementptr inbounds i8, ptr %282, i64 8
  %284 = load i64, ptr %283, align 8, !tbaa !15
  %285 = add i64 %284, 1
  store i64 %285, ptr %283, align 8, !tbaa !15
  %286 = icmp eq i64 %285, 0
  br i1 %286, label %281, label %287, !llvm.loop !378

287:                                              ; preds = %281, %276, %230, %228
  %288 = sub nsw i64 %16, %212
  %289 = getelementptr inbounds i64, ptr %36, i64 %288
  %290 = load i64, ptr %289, align 8, !tbaa !15
  %291 = load i64, ptr %200, align 8, !tbaa !15
  %292 = icmp eq i64 %212, %16
  br i1 %292, label %328, label %293

293:                                              ; preds = %287
  %294 = tail call i64 @__gmpn_sub_n(ptr noundef %198, ptr noundef %216, ptr noundef %198, i64 noundef %212) #16
  %295 = tail call i64 @__gmpn_sub_n(ptr noundef %219, ptr noundef %36, ptr noundef %219, i64 noundef %288) #16
  %296 = load i64, ptr %219, align 8, !tbaa !15
  %297 = sub i64 %296, %294
  store i64 %297, ptr %219, align 8, !tbaa !15
  %298 = icmp ult i64 %296, %294
  br i1 %298, label %299, label %310

299:                                              ; preds = %293
  %300 = tail call i64 @llvm.smax.i64(i64 %288, i64 1)
  br label %301

301:                                              ; preds = %304, %299
  %302 = phi i64 [ %308, %304 ], [ 1, %299 ]
  %303 = icmp eq i64 %302, %300
  br i1 %303, label %310, label %304

304:                                              ; preds = %301
  %305 = getelementptr inbounds i64, ptr %219, i64 %302
  %306 = load i64, ptr %305, align 8, !tbaa !15
  %307 = add i64 %306, -1
  store i64 %307, ptr %305, align 8, !tbaa !15
  %308 = add nuw i64 %302, 1
  %309 = icmp eq i64 %306, 0
  br i1 %309, label %301, label %310, !llvm.loop !377

310:                                              ; preds = %304, %301, %293
  %311 = phi i64 [ 0, %293 ], [ 1, %301 ], [ 0, %304 ]
  %312 = add i64 %311, %295
  br i1 %201, label %330, label %313

313:                                              ; preds = %310
  %314 = load i64, ptr %198, align 8, !tbaa !15
  br i1 %203, label %325, label %315

315:                                              ; preds = %315, %313
  %316 = phi i64 [ %323, %315 ], [ %202, %313 ]
  %317 = phi ptr [ %321, %315 ], [ %36, %313 ]
  %318 = phi ptr [ %320, %315 ], [ %198, %313 ]
  %319 = phi i64 [ %322, %315 ], [ %314, %313 ]
  %320 = getelementptr inbounds i8, ptr %318, i64 8
  %321 = getelementptr inbounds i8, ptr %317, i64 8
  store i64 %319, ptr %317, align 8, !tbaa !15
  %322 = load i64, ptr %320, align 8, !tbaa !15
  %323 = add nsw i64 %316, -1
  %324 = icmp eq i64 %323, 0
  br i1 %324, label %325, label %315, !llvm.loop !379

325:                                              ; preds = %315, %313
  %326 = phi ptr [ %36, %313 ], [ %321, %315 ]
  %327 = phi i64 [ %314, %313 ], [ %322, %315 ]
  store i64 %327, ptr %326, align 8, !tbaa !15
  br label %330

328:                                              ; preds = %287
  %329 = tail call i64 @__gmpn_sub_n(ptr noundef %36, ptr noundef %216, ptr noundef %198, i64 noundef %212) #16
  br label %330

330:                                              ; preds = %328, %325, %310
  %331 = phi i64 [ %312, %325 ], [ %312, %310 ], [ %329, %328 ]
  %332 = add i64 %291, %331
  %333 = sub i64 %290, %332
  %334 = icmp eq i64 %333, 0
  br i1 %334, label %347, label %335

335:                                              ; preds = %343, %330
  %336 = phi i64 [ %345, %343 ], [ %333, %330 ]
  br label %337

337:                                              ; preds = %337, %335
  %338 = phi ptr [ %339, %337 ], [ %217, %335 ]
  %339 = getelementptr inbounds i8, ptr %338, i64 8
  %340 = load i64, ptr %338, align 8, !tbaa !15
  %341 = add i64 %340, 1
  store i64 %341, ptr %338, align 8, !tbaa !15
  %342 = icmp eq i64 %341, 0
  br i1 %342, label %337, label %343, !llvm.loop !380

343:                                              ; preds = %337
  %344 = tail call i64 @__gmpn_sub_n(ptr noundef %36, ptr noundef %36, ptr noundef %17, i64 noundef %16) #16
  %345 = sub i64 %336, %344
  %346 = icmp eq i64 %345, 0
  br i1 %346, label %347, label %335, !llvm.loop !381

347:                                              ; preds = %343, %330
  br label %348

348:                                              ; preds = %351, %347
  %349 = phi i64 [ %352, %351 ], [ %16, %347 ]
  %350 = icmp sgt i64 %349, 0
  br i1 %350, label %351, label %360

351:                                              ; preds = %348
  %352 = add nsw i64 %349, -1
  %353 = getelementptr inbounds i64, ptr %36, i64 %352
  %354 = load i64, ptr %353, align 8, !tbaa !15
  %355 = getelementptr inbounds i64, ptr %17, i64 %352
  %356 = load i64, ptr %355, align 8, !tbaa !15
  %357 = icmp eq i64 %354, %356
  br i1 %357, label %348, label %358, !llvm.loop !375

358:                                              ; preds = %351
  %359 = icmp ugt i64 %354, %356
  br i1 %359, label %360, label %369

360:                                              ; preds = %358, %348
  br label %361

361:                                              ; preds = %361, %360
  %362 = phi ptr [ %363, %361 ], [ %217, %360 ]
  %363 = getelementptr inbounds i8, ptr %362, i64 8
  %364 = load i64, ptr %362, align 8, !tbaa !15
  %365 = add i64 %364, 1
  store i64 %365, ptr %362, align 8, !tbaa !15
  %366 = icmp eq i64 %365, 0
  br i1 %366, label %361, label %367, !llvm.loop !382

367:                                              ; preds = %361
  %368 = tail call i64 @__gmpn_sub_n(ptr noundef %36, ptr noundef %36, ptr noundef %17, i64 noundef %16) #16
  br label %369

369:                                              ; preds = %367, %358
  br label %204, !llvm.loop !383

370:                                              ; preds = %223
  %371 = load i64, ptr %217, align 8, !tbaa !15
  %372 = add i64 %371, 3
  store i64 %372, ptr %217, align 8, !tbaa !15
  %373 = icmp ugt i64 %371, -4
  br i1 %373, label %374, label %385

374:                                              ; preds = %370
  %375 = tail call i64 @llvm.smax.i64(i64 %156, i64 1)
  br label %376

376:                                              ; preds = %379, %374
  %377 = phi i64 [ %383, %379 ], [ 1, %374 ]
  %378 = icmp eq i64 %377, %375
  br i1 %378, label %385, label %379

379:                                              ; preds = %376
  %380 = getelementptr inbounds i64, ptr %217, i64 %377
  %381 = load i64, ptr %380, align 8, !tbaa !15
  %382 = add i64 %381, 1
  store i64 %382, ptr %380, align 8, !tbaa !15
  %383 = add nuw i64 %377, 1
  %384 = icmp eq i64 %382, 0
  br i1 %384, label %376, label %385, !llvm.loop !371

385:                                              ; preds = %379, %376, %370
  %386 = phi i1 [ false, %370 ], [ %378, %376 ], [ false, %379 ]
  %387 = and i1 %172, %386
  %388 = select i1 %386, i64 1, i64 %173
  br i1 %387, label %389, label %393

389:                                              ; preds = %385
  %390 = icmp sgt i64 %156, 0
  br i1 %390, label %391, label %393

391:                                              ; preds = %389
  %392 = shl i64 %156, 3
  tail call void @llvm.memset.p0.i64(ptr nonnull align 8 %217, i8 -1, i64 %392, i1 false), !tbaa !15
  br label %393

393:                                              ; preds = %391, %389, %385, %195
  %394 = phi i64 [ %173, %195 ], [ %388, %385 ], [ %173, %389 ], [ %173, %391 ]
  ret i64 %394
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i64 @mpn_dcpi1_divappr_q_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4, ptr noundef %5) unnamed_addr #5 {
  %7 = ashr i64 %3, 1
  %8 = sub nsw i64 %3, %7
  %9 = icmp sgt i64 %8, 59
  %10 = getelementptr inbounds i64, ptr %0, i64 %7
  %11 = and i64 %3, -2
  %12 = getelementptr inbounds i64, ptr %1, i64 %11
  br i1 %9, label %18, label %13

13:                                               ; preds = %6
  %14 = shl nsw i64 %8, 1
  %15 = getelementptr inbounds i64, ptr %2, i64 %7
  %16 = load i64, ptr %4, align 8, !tbaa !357
  %17 = tail call i64 @__gmpn_sbpi1_div_qr(ptr noundef %10, ptr noundef %12, i64 noundef %14, ptr noundef %15, i64 noundef %8, i64 noundef %16) #16
  br label %21

18:                                               ; preds = %6
  %19 = getelementptr inbounds i64, ptr %2, i64 %7
  %20 = tail call i64 @__gmpn_dcpi1_div_qr_n(ptr noundef %10, ptr noundef %12, ptr noundef %19, i64 noundef %8, ptr noundef %4, ptr noundef %5) #16
  br label %21

21:                                               ; preds = %18, %13
  %22 = phi i64 [ %20, %18 ], [ %17, %13 ]
  %23 = getelementptr inbounds i64, ptr %0, i64 %7
  %24 = tail call i64 @__gmpn_mul(ptr noundef %5, ptr noundef %23, i64 noundef %8, ptr noundef %2, i64 noundef %7) #16
  %25 = getelementptr inbounds i64, ptr %1, i64 %7
  %26 = tail call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %25, ptr noundef %5, i64 noundef %3) #16
  %27 = icmp eq i64 %22, 0
  br i1 %27, label %32, label %28

28:                                               ; preds = %21
  %29 = getelementptr inbounds i64, ptr %1, i64 %3
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef %29, ptr noundef %29, ptr noundef %2, i64 noundef %7) #16
  %31 = add i64 %30, %26
  br label %32

32:                                               ; preds = %28, %21
  %33 = phi i64 [ %31, %28 ], [ %26, %21 ]
  %34 = icmp eq i64 %33, 0
  br i1 %34, label %58, label %35

35:                                               ; preds = %32
  %36 = tail call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %37

37:                                               ; preds = %52, %35
  %38 = phi i64 [ %22, %35 ], [ %54, %52 ]
  %39 = phi i64 [ %33, %35 ], [ %56, %52 ]
  %40 = load i64, ptr %23, align 8, !tbaa !15
  %41 = add i64 %40, -1
  store i64 %41, ptr %23, align 8, !tbaa !15
  %42 = icmp eq i64 %40, 0
  br i1 %42, label %43, label %52

43:                                               ; preds = %46, %37
  %44 = phi i64 [ %50, %46 ], [ 1, %37 ]
  %45 = icmp eq i64 %44, %36
  br i1 %45, label %52, label %46

46:                                               ; preds = %43
  %47 = getelementptr inbounds i64, ptr %23, i64 %44
  %48 = load i64, ptr %47, align 8, !tbaa !15
  %49 = add i64 %48, -1
  store i64 %49, ptr %47, align 8, !tbaa !15
  %50 = add nuw i64 %44, 1
  %51 = icmp eq i64 %48, 0
  br i1 %51, label %43, label %52, !llvm.loop !364

52:                                               ; preds = %46, %43, %37
  %53 = phi i64 [ 0, %37 ], [ -1, %43 ], [ 0, %46 ]
  %54 = add i64 %53, %38
  %55 = tail call i64 @__gmpn_add_n(ptr noundef %25, ptr noundef %25, ptr noundef %2, i64 noundef %3) #16
  %56 = sub i64 %39, %55
  %57 = icmp eq i64 %56, 0
  br i1 %57, label %58, label %37, !llvm.loop !384

58:                                               ; preds = %52, %32
  %59 = phi i64 [ %22, %32 ], [ %54, %52 ]
  %60 = icmp sgt i64 %7, 199
  %61 = getelementptr inbounds i64, ptr %1, i64 %8
  br i1 %60, label %67, label %62

62:                                               ; preds = %58
  %63 = and i64 %3, -2
  %64 = getelementptr inbounds i64, ptr %2, i64 %8
  %65 = load i64, ptr %4, align 8, !tbaa !357
  %66 = tail call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %0, ptr noundef %61, i64 noundef %63, ptr noundef %64, i64 noundef %7, i64 noundef %65) #16
  br label %70

67:                                               ; preds = %58
  %68 = getelementptr inbounds i64, ptr %2, i64 %8
  %69 = tail call fastcc i64 @mpn_dcpi1_divappr_q_n(ptr noundef %0, ptr noundef %61, ptr noundef %68, i64 noundef %7, ptr noundef %4, ptr noundef %5)
  br label %70

70:                                               ; preds = %67, %62
  %71 = phi i64 [ %69, %67 ], [ %66, %62 ]
  %72 = icmp eq i64 %71, 0
  br i1 %72, label %77, label %73, !prof !68

73:                                               ; preds = %70
  %74 = icmp sgt i64 %7, 0
  br i1 %74, label %75, label %77

75:                                               ; preds = %73
  %76 = shl nuw i64 %7, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %0, i8 -1, i64 %76, i1 false), !tbaa !15
  br label %77

77:                                               ; preds = %75, %73, %70
  ret i64 %59
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_div_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = alloca %struct.gmp_pi1_t, align 8
  %8 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #16
  store ptr null, ptr %8, align 8, !tbaa !7
  %9 = add nsw i64 %4, -1
  %10 = getelementptr inbounds i64, ptr %3, i64 %9
  %11 = load i64, ptr %10, align 8, !tbaa !15
  %12 = icmp eq i64 %4, 1
  br i1 %12, label %13, label %15

13:                                               ; preds = %6
  %14 = tail call i64 @__gmpn_divrem_1(ptr noundef %0, i64 noundef 0, ptr noundef %1, i64 noundef %2, i64 noundef %11) #16
  br label %1031

15:                                               ; preds = %6
  %16 = sub nsw i64 %2, %4
  %17 = add nsw i64 %16, 1
  %18 = add nsw i64 %16, 6
  %19 = icmp slt i64 %18, %4
  br i1 %19, label %488, label %20

20:                                               ; preds = %15
  %21 = icmp sgt i64 %11, -1
  br i1 %21, label %22, label %261, !prof !68

22:                                               ; preds = %27, %20
  %23 = phi i64 [ %28, %27 ], [ 56, %20 ]
  %24 = shl i64 255, %23
  %25 = and i64 %24, %11
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %27, label %30

27:                                               ; preds = %22
  %28 = add nsw i64 %23, -8
  %29 = icmp eq i64 %28, 0
  br i1 %29, label %30, label %22, !llvm.loop !385

30:                                               ; preds = %27, %22
  %31 = phi i64 [ %23, %22 ], [ 0, %27 ]
  %32 = or disjoint i64 %31, 1
  %33 = lshr i64 %11, %32
  %34 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %33
  %35 = load i8, ptr %34, align 1, !tbaa !155
  %36 = zext i8 %35 to i64
  %37 = add i64 %32, %36
  %38 = trunc i64 %37 to i32
  %39 = sub i32 65, %38
  %40 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %1, i64 noundef %2, i32 noundef %39) #16
  %41 = getelementptr inbounds i64, ptr %5, i64 %2
  store i64 %40, ptr %41, align 8, !tbaa !15
  %42 = icmp ne i64 %40, 0
  %43 = zext i1 %42 to i64
  %44 = add nsw i64 %43, %2
  %45 = shl i64 %4, 3
  %46 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %45) #16
  %47 = call i64 @__gmpn_lshift(ptr noundef %46, ptr noundef %3, i64 noundef %4, i32 noundef %39) #16
  %48 = icmp eq i64 %4, 2
  br i1 %48, label %49, label %51

49:                                               ; preds = %30
  %50 = call i64 @__gmpn_divrem_2(ptr noundef %0, i64 noundef 0, ptr noundef %5, i64 noundef %44, ptr noundef %46) #16
  br label %258

51:                                               ; preds = %30
  %52 = icmp sgt i64 %4, 199
  %53 = sub nsw i64 %44, %4
  %54 = icmp sgt i64 %53, 199
  %55 = select i1 %52, i1 %54, i1 false
  br i1 %55, label %150, label %56

56:                                               ; preds = %51
  %57 = getelementptr inbounds i64, ptr %46, i64 %9
  %58 = load i64, ptr %57, align 8, !tbaa !15
  %59 = lshr i64 %58, 32
  %60 = and i64 %58, 4294967295
  %61 = xor i64 %58, -1
  %62 = udiv i64 %61, %59
  %63 = mul i64 %62, %59
  %64 = urem i64 %61, %59
  %65 = mul i64 %62, %60
  %66 = shl i64 %64, 32
  %67 = or disjoint i64 %66, 4294967295
  %68 = icmp ult i64 %67, %65
  br i1 %68, label %69, label %78

69:                                               ; preds = %56
  %70 = add i64 %62, -1
  %71 = add i64 %67, %58
  %72 = icmp uge i64 %71, %58
  %73 = icmp ult i64 %71, %65
  %74 = and i1 %72, %73
  br i1 %74, label %75, label %78

75:                                               ; preds = %69
  %76 = add i64 %62, -2
  %77 = add i64 %71, %58
  br label %78

78:                                               ; preds = %75, %69, %56
  %79 = phi i64 [ %77, %75 ], [ %71, %69 ], [ %67, %56 ]
  %80 = phi i64 [ %76, %75 ], [ %70, %69 ], [ %62, %56 ]
  %81 = sub i64 %79, %65
  %82 = udiv i64 %81, %59
  %83 = mul i64 %82, %59
  %84 = urem i64 %81, %59
  %85 = mul i64 %82, %60
  %86 = shl i64 %84, 32
  %87 = or disjoint i64 %86, 4294967295
  %88 = icmp ult i64 %87, %85
  br i1 %88, label %89, label %96

89:                                               ; preds = %78
  %90 = add i64 %87, %58
  %91 = icmp uge i64 %90, %58
  %92 = icmp ult i64 %90, %85
  %93 = and i1 %91, %92
  %94 = select i1 %93, i64 -2, i64 -1
  %95 = add i64 %94, %82
  br label %96

96:                                               ; preds = %89, %78
  %97 = phi i64 [ %82, %78 ], [ %95, %89 ]
  %98 = shl i64 %80, 32
  %99 = or i64 %97, %98
  %100 = mul i64 %99, %58
  %101 = getelementptr i64, ptr %46, i64 %4
  %102 = getelementptr i8, ptr %101, i64 -16
  %103 = load i64, ptr %102, align 8, !tbaa !15
  %104 = add i64 %100, %103
  %105 = icmp ult i64 %104, %103
  br i1 %105, label %106, label %114

106:                                              ; preds = %96
  %107 = add i64 %99, -1
  %108 = icmp uge i64 %104, %58
  %109 = sext i1 %108 to i64
  %110 = add i64 %107, %109
  %111 = select i1 %108, i64 %58, i64 0
  %112 = add i64 %58, %111
  %113 = sub i64 %104, %112
  br label %114

114:                                              ; preds = %106, %96
  %115 = phi i64 [ %113, %106 ], [ %104, %96 ]
  %116 = phi i64 [ %110, %106 ], [ %99, %96 ]
  %117 = lshr i64 %103, 32
  %118 = lshr i64 %116, 32
  %119 = and i64 %103, 4294967295
  %120 = and i64 %116, 4294967295
  %121 = mul nuw i64 %120, %119
  %122 = mul nuw i64 %118, %119
  %123 = mul nuw i64 %120, %117
  %124 = mul nuw i64 %118, %117
  %125 = lshr i64 %121, 32
  %126 = add i64 %123, %122
  %127 = add i64 %126, %125
  %128 = icmp ult i64 %127, %123
  %129 = add nuw i64 %124, 4294967296
  %130 = select i1 %128, i64 %129, i64 %124
  %131 = lshr i64 %127, 32
  %132 = add i64 %130, %131
  %133 = shl i64 %127, 32
  %134 = and i64 %121, 4294967295
  %135 = or disjoint i64 %133, %134
  %136 = add i64 %132, %115
  %137 = icmp ult i64 %136, %132
  br i1 %137, label %138, label %147

138:                                              ; preds = %114
  %139 = add i64 %116, -1
  %140 = icmp ult i64 %136, %58
  br i1 %140, label %147, label %141, !prof !68

141:                                              ; preds = %138
  %142 = icmp ule i64 %136, %58
  %143 = icmp ult i64 %135, %103
  %144 = select i1 %142, i1 %143, i1 false
  %145 = add i64 %116, -2
  %146 = select i1 %144, i64 %139, i64 %145
  br label %147

147:                                              ; preds = %141, %138, %114
  %148 = phi i64 [ %139, %138 ], [ %116, %114 ], [ %146, %141 ]
  store i64 %148, ptr %7, align 8, !tbaa !357
  %149 = call i64 @__gmpn_sbpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %44, ptr noundef %46, i64 noundef %4, i64 noundef %148) #16
  br label %258

150:                                              ; preds = %51
  %151 = icmp sgt i64 %2, 3999
  br i1 %151, label %152, label %159

152:                                              ; preds = %150
  %153 = uitofp nneg i64 %4 to double
  %154 = uitofp nneg i64 %2 to double
  %155 = fmul double %154, 2.000000e+02
  %156 = call double @llvm.fmuladd.f64(double %153, double 3.600000e+03, double %155)
  %157 = fmul double %154, %153
  %158 = fcmp ogt double %156, %157
  br i1 %158, label %159, label %253

159:                                              ; preds = %152, %150
  %160 = getelementptr inbounds i64, ptr %46, i64 %9
  %161 = load i64, ptr %160, align 8, !tbaa !15
  %162 = lshr i64 %161, 32
  %163 = and i64 %161, 4294967295
  %164 = xor i64 %161, -1
  %165 = udiv i64 %164, %162
  %166 = mul i64 %165, %162
  %167 = urem i64 %164, %162
  %168 = mul i64 %165, %163
  %169 = shl i64 %167, 32
  %170 = or disjoint i64 %169, 4294967295
  %171 = icmp ult i64 %170, %168
  br i1 %171, label %172, label %181

172:                                              ; preds = %159
  %173 = add i64 %165, -1
  %174 = add i64 %170, %161
  %175 = icmp uge i64 %174, %161
  %176 = icmp ult i64 %174, %168
  %177 = and i1 %175, %176
  br i1 %177, label %178, label %181

178:                                              ; preds = %172
  %179 = add i64 %165, -2
  %180 = add i64 %174, %161
  br label %181

181:                                              ; preds = %178, %172, %159
  %182 = phi i64 [ %180, %178 ], [ %174, %172 ], [ %170, %159 ]
  %183 = phi i64 [ %179, %178 ], [ %173, %172 ], [ %165, %159 ]
  %184 = sub i64 %182, %168
  %185 = udiv i64 %184, %162
  %186 = mul i64 %185, %162
  %187 = urem i64 %184, %162
  %188 = mul i64 %185, %163
  %189 = shl i64 %187, 32
  %190 = or disjoint i64 %189, 4294967295
  %191 = icmp ult i64 %190, %188
  br i1 %191, label %192, label %199

192:                                              ; preds = %181
  %193 = add i64 %190, %161
  %194 = icmp uge i64 %193, %161
  %195 = icmp ult i64 %193, %188
  %196 = and i1 %194, %195
  %197 = select i1 %196, i64 -2, i64 -1
  %198 = add i64 %197, %185
  br label %199

199:                                              ; preds = %192, %181
  %200 = phi i64 [ %185, %181 ], [ %198, %192 ]
  %201 = shl i64 %183, 32
  %202 = or i64 %200, %201
  %203 = mul i64 %202, %161
  %204 = getelementptr i64, ptr %46, i64 %4
  %205 = getelementptr i8, ptr %204, i64 -16
  %206 = load i64, ptr %205, align 8, !tbaa !15
  %207 = add i64 %203, %206
  %208 = icmp ult i64 %207, %206
  br i1 %208, label %209, label %217

209:                                              ; preds = %199
  %210 = add i64 %202, -1
  %211 = icmp uge i64 %207, %161
  %212 = sext i1 %211 to i64
  %213 = add i64 %210, %212
  %214 = select i1 %211, i64 %161, i64 0
  %215 = add i64 %161, %214
  %216 = sub i64 %207, %215
  br label %217

217:                                              ; preds = %209, %199
  %218 = phi i64 [ %216, %209 ], [ %207, %199 ]
  %219 = phi i64 [ %213, %209 ], [ %202, %199 ]
  %220 = lshr i64 %206, 32
  %221 = lshr i64 %219, 32
  %222 = and i64 %206, 4294967295
  %223 = and i64 %219, 4294967295
  %224 = mul nuw i64 %223, %222
  %225 = mul nuw i64 %221, %222
  %226 = mul nuw i64 %223, %220
  %227 = mul nuw i64 %221, %220
  %228 = lshr i64 %224, 32
  %229 = add i64 %226, %225
  %230 = add i64 %229, %228
  %231 = icmp ult i64 %230, %226
  %232 = add nuw i64 %227, 4294967296
  %233 = select i1 %231, i64 %232, i64 %227
  %234 = lshr i64 %230, 32
  %235 = add i64 %233, %234
  %236 = shl i64 %230, 32
  %237 = and i64 %224, 4294967295
  %238 = or disjoint i64 %236, %237
  %239 = add i64 %235, %218
  %240 = icmp ult i64 %239, %235
  br i1 %240, label %241, label %250

241:                                              ; preds = %217
  %242 = add i64 %219, -1
  %243 = icmp ult i64 %239, %161
  br i1 %243, label %250, label %244, !prof !68

244:                                              ; preds = %241
  %245 = icmp ule i64 %239, %161
  %246 = icmp ult i64 %238, %206
  %247 = select i1 %245, i1 %246, i1 false
  %248 = add i64 %219, -2
  %249 = select i1 %247, i64 %242, i64 %248
  br label %250

250:                                              ; preds = %244, %241, %217
  %251 = phi i64 [ %242, %241 ], [ %219, %217 ], [ %249, %244 ]
  store i64 %251, ptr %7, align 8, !tbaa !357
  %252 = call i64 @__gmpn_dcpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %44, ptr noundef %46, i64 noundef %4, ptr noundef nonnull %7) #16
  br label %258

253:                                              ; preds = %152
  %254 = call i64 @__gmpn_mu_div_q_itch(i64 noundef %44, i64 noundef %4, i32 noundef 0) #17
  %255 = shl i64 %254, 3
  %256 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %255) #16
  %257 = call i64 @__gmpn_mu_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %44, ptr noundef %46, i64 noundef %4, ptr noundef %256) #16
  br label %258

258:                                              ; preds = %253, %250, %147, %49
  %259 = phi i64 [ %50, %49 ], [ %252, %250 ], [ %257, %253 ], [ %149, %147 ]
  %260 = icmp eq i64 %40, 0
  br i1 %260, label %1026, label %1029

261:                                              ; preds = %20
  %262 = icmp ne ptr %5, %1
  %263 = icmp ne i64 %2, 0
  %264 = and i1 %263, %262
  br i1 %264, label %265, label %282

265:                                              ; preds = %261
  %266 = add nsw i64 %2, -1
  %267 = load i64, ptr %1, align 8, !tbaa !15
  %268 = icmp eq i64 %266, 0
  br i1 %268, label %279, label %269

269:                                              ; preds = %269, %265
  %270 = phi i64 [ %276, %269 ], [ %267, %265 ]
  %271 = phi ptr [ %274, %269 ], [ %1, %265 ]
  %272 = phi ptr [ %275, %269 ], [ %5, %265 ]
  %273 = phi i64 [ %277, %269 ], [ %266, %265 ]
  %274 = getelementptr inbounds i8, ptr %271, i64 8
  %275 = getelementptr inbounds i8, ptr %272, i64 8
  store i64 %270, ptr %272, align 8, !tbaa !15
  %276 = load i64, ptr %274, align 8, !tbaa !15
  %277 = add nsw i64 %273, -1
  %278 = icmp eq i64 %277, 0
  br i1 %278, label %279, label %269, !llvm.loop !386

279:                                              ; preds = %269, %265
  %280 = phi i64 [ %267, %265 ], [ %276, %269 ]
  %281 = phi ptr [ %5, %265 ], [ %275, %269 ]
  store i64 %280, ptr %281, align 8, !tbaa !15
  br label %282

282:                                              ; preds = %279, %261
  %283 = icmp eq i64 %4, 2
  br i1 %283, label %284, label %286

284:                                              ; preds = %282
  %285 = tail call i64 @__gmpn_divrem_2(ptr noundef %0, i64 noundef 0, ptr noundef %5, i64 noundef %2, ptr noundef %3) #16
  br label %1026

286:                                              ; preds = %282
  %287 = icmp sgt i64 %4, 199
  %288 = icmp sgt i64 %16, 199
  %289 = and i1 %287, %288
  br i1 %289, label %382, label %290

290:                                              ; preds = %286
  %291 = lshr i64 %11, 32
  %292 = and i64 %11, 4294967295
  %293 = xor i64 %11, -1
  %294 = udiv i64 %293, %291
  %295 = mul nuw i64 %294, %291
  %296 = urem i64 %293, %291
  %297 = mul nuw i64 %294, %292
  %298 = shl i64 %296, 32
  %299 = or disjoint i64 %298, 4294967295
  %300 = icmp ult i64 %299, %297
  br i1 %300, label %301, label %310

301:                                              ; preds = %290
  %302 = add nsw i64 %294, -1
  %303 = add i64 %299, %11
  %304 = icmp uge i64 %303, %11
  %305 = icmp ult i64 %303, %297
  %306 = and i1 %304, %305
  br i1 %306, label %307, label %310

307:                                              ; preds = %301
  %308 = add nsw i64 %294, -2
  %309 = add i64 %303, %11
  br label %310

310:                                              ; preds = %307, %301, %290
  %311 = phi i64 [ %309, %307 ], [ %303, %301 ], [ %299, %290 ]
  %312 = phi i64 [ %308, %307 ], [ %302, %301 ], [ %294, %290 ]
  %313 = sub i64 %311, %297
  %314 = udiv i64 %313, %291
  %315 = mul i64 %314, %291
  %316 = urem i64 %313, %291
  %317 = mul i64 %314, %292
  %318 = shl i64 %316, 32
  %319 = or disjoint i64 %318, 4294967295
  %320 = icmp ult i64 %319, %317
  br i1 %320, label %321, label %328

321:                                              ; preds = %310
  %322 = add i64 %319, %11
  %323 = icmp uge i64 %322, %11
  %324 = icmp ult i64 %322, %317
  %325 = and i1 %323, %324
  %326 = select i1 %325, i64 -2, i64 -1
  %327 = add nsw i64 %326, %314
  br label %328

328:                                              ; preds = %321, %310
  %329 = phi i64 [ %314, %310 ], [ %327, %321 ]
  %330 = shl i64 %312, 32
  %331 = or i64 %329, %330
  %332 = mul i64 %331, %11
  %333 = getelementptr i64, ptr %3, i64 %4
  %334 = getelementptr i8, ptr %333, i64 -16
  %335 = load i64, ptr %334, align 8, !tbaa !15
  %336 = add i64 %332, %335
  %337 = icmp ult i64 %336, %335
  br i1 %337, label %338, label %346

338:                                              ; preds = %328
  %339 = add i64 %331, -1
  %340 = icmp uge i64 %336, %11
  %341 = sext i1 %340 to i64
  %342 = add i64 %339, %341
  %343 = select i1 %340, i64 %11, i64 0
  %344 = add i64 %11, %343
  %345 = sub i64 %336, %344
  br label %346

346:                                              ; preds = %338, %328
  %347 = phi i64 [ %345, %338 ], [ %336, %328 ]
  %348 = phi i64 [ %342, %338 ], [ %331, %328 ]
  %349 = lshr i64 %335, 32
  %350 = lshr i64 %348, 32
  %351 = and i64 %335, 4294967295
  %352 = and i64 %348, 4294967295
  %353 = mul nuw i64 %352, %351
  %354 = mul nuw i64 %350, %351
  %355 = mul nuw i64 %352, %349
  %356 = mul nuw i64 %350, %349
  %357 = lshr i64 %353, 32
  %358 = add i64 %355, %354
  %359 = add i64 %358, %357
  %360 = icmp ult i64 %359, %355
  %361 = add nuw i64 %356, 4294967296
  %362 = select i1 %360, i64 %361, i64 %356
  %363 = lshr i64 %359, 32
  %364 = add i64 %362, %363
  %365 = shl i64 %359, 32
  %366 = and i64 %353, 4294967295
  %367 = or disjoint i64 %365, %366
  %368 = add i64 %364, %347
  %369 = icmp ult i64 %368, %364
  br i1 %369, label %370, label %379

370:                                              ; preds = %346
  %371 = add i64 %348, -1
  %372 = icmp ult i64 %368, %11
  br i1 %372, label %379, label %373, !prof !68

373:                                              ; preds = %370
  %374 = icmp ule i64 %368, %11
  %375 = icmp ult i64 %367, %335
  %376 = select i1 %374, i1 %375, i1 false
  %377 = add i64 %348, -2
  %378 = select i1 %376, i64 %371, i64 %377
  br label %379

379:                                              ; preds = %373, %370, %346
  %380 = phi i64 [ %371, %370 ], [ %348, %346 ], [ %378, %373 ]
  store i64 %380, ptr %7, align 8, !tbaa !357
  %381 = tail call i64 @__gmpn_sbpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %380) #16
  br label %1026

382:                                              ; preds = %286
  %383 = icmp sgt i64 %2, 3999
  br i1 %383, label %384, label %391

384:                                              ; preds = %382
  %385 = uitofp nneg i64 %4 to double
  %386 = uitofp nneg i64 %2 to double
  %387 = fmul double %386, 2.000000e+02
  %388 = tail call double @llvm.fmuladd.f64(double %385, double 3.600000e+03, double %387)
  %389 = fmul double %386, %385
  %390 = fcmp ogt double %388, %389
  br i1 %390, label %391, label %483

391:                                              ; preds = %384, %382
  %392 = lshr i64 %11, 32
  %393 = and i64 %11, 4294967295
  %394 = xor i64 %11, -1
  %395 = udiv i64 %394, %392
  %396 = mul nuw i64 %395, %392
  %397 = urem i64 %394, %392
  %398 = mul nuw i64 %395, %393
  %399 = shl i64 %397, 32
  %400 = or disjoint i64 %399, 4294967295
  %401 = icmp ult i64 %400, %398
  br i1 %401, label %402, label %411

402:                                              ; preds = %391
  %403 = add nsw i64 %395, -1
  %404 = add i64 %400, %11
  %405 = icmp uge i64 %404, %11
  %406 = icmp ult i64 %404, %398
  %407 = and i1 %405, %406
  br i1 %407, label %408, label %411

408:                                              ; preds = %402
  %409 = add nsw i64 %395, -2
  %410 = add i64 %404, %11
  br label %411

411:                                              ; preds = %408, %402, %391
  %412 = phi i64 [ %410, %408 ], [ %404, %402 ], [ %400, %391 ]
  %413 = phi i64 [ %409, %408 ], [ %403, %402 ], [ %395, %391 ]
  %414 = sub i64 %412, %398
  %415 = udiv i64 %414, %392
  %416 = mul i64 %415, %392
  %417 = urem i64 %414, %392
  %418 = mul i64 %415, %393
  %419 = shl i64 %417, 32
  %420 = or disjoint i64 %419, 4294967295
  %421 = icmp ult i64 %420, %418
  br i1 %421, label %422, label %429

422:                                              ; preds = %411
  %423 = add i64 %420, %11
  %424 = icmp uge i64 %423, %11
  %425 = icmp ult i64 %423, %418
  %426 = and i1 %424, %425
  %427 = select i1 %426, i64 -2, i64 -1
  %428 = add nsw i64 %427, %415
  br label %429

429:                                              ; preds = %422, %411
  %430 = phi i64 [ %415, %411 ], [ %428, %422 ]
  %431 = shl i64 %413, 32
  %432 = or i64 %430, %431
  %433 = mul i64 %432, %11
  %434 = getelementptr i64, ptr %3, i64 %4
  %435 = getelementptr i8, ptr %434, i64 -16
  %436 = load i64, ptr %435, align 8, !tbaa !15
  %437 = add i64 %433, %436
  %438 = icmp ult i64 %437, %436
  br i1 %438, label %439, label %447

439:                                              ; preds = %429
  %440 = add i64 %432, -1
  %441 = icmp uge i64 %437, %11
  %442 = sext i1 %441 to i64
  %443 = add i64 %440, %442
  %444 = select i1 %441, i64 %11, i64 0
  %445 = add i64 %11, %444
  %446 = sub i64 %437, %445
  br label %447

447:                                              ; preds = %439, %429
  %448 = phi i64 [ %446, %439 ], [ %437, %429 ]
  %449 = phi i64 [ %443, %439 ], [ %432, %429 ]
  %450 = lshr i64 %436, 32
  %451 = lshr i64 %449, 32
  %452 = and i64 %436, 4294967295
  %453 = and i64 %449, 4294967295
  %454 = mul nuw i64 %453, %452
  %455 = mul nuw i64 %451, %452
  %456 = mul nuw i64 %453, %450
  %457 = mul nuw i64 %451, %450
  %458 = lshr i64 %454, 32
  %459 = add i64 %456, %455
  %460 = add i64 %459, %458
  %461 = icmp ult i64 %460, %456
  %462 = add nuw i64 %457, 4294967296
  %463 = select i1 %461, i64 %462, i64 %457
  %464 = lshr i64 %460, 32
  %465 = add i64 %463, %464
  %466 = shl i64 %460, 32
  %467 = and i64 %454, 4294967295
  %468 = or disjoint i64 %466, %467
  %469 = add i64 %465, %448
  %470 = icmp ult i64 %469, %465
  br i1 %470, label %471, label %480

471:                                              ; preds = %447
  %472 = add i64 %449, -1
  %473 = icmp ult i64 %469, %11
  br i1 %473, label %480, label %474, !prof !68

474:                                              ; preds = %471
  %475 = icmp ule i64 %469, %11
  %476 = icmp ult i64 %468, %436
  %477 = select i1 %475, i1 %476, i1 false
  %478 = add i64 %449, -2
  %479 = select i1 %477, i64 %472, i64 %478
  br label %480

480:                                              ; preds = %474, %471, %447
  %481 = phi i64 [ %472, %471 ], [ %449, %447 ], [ %479, %474 ]
  store i64 %481, ptr %7, align 8, !tbaa !357
  %482 = call i64 @__gmpn_dcpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %7) #16
  br label %1026

483:                                              ; preds = %384
  %484 = tail call i64 @__gmpn_mu_div_q_itch(i64 noundef %2, i64 noundef %4, i32 noundef 0) #17
  %485 = shl i64 %484, 3
  %486 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %485) #16
  %487 = call i64 @__gmpn_mu_div_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %486) #16
  br label %1026

488:                                              ; preds = %15
  %489 = add nsw i64 %16, 2
  %490 = shl i64 %489, 3
  %491 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %490) #16
  %492 = shl nsw i64 %17, 1
  %493 = or disjoint i64 %492, 1
  %494 = icmp eq ptr %5, %1
  br i1 %494, label %495, label %499

495:                                              ; preds = %488
  %496 = shl i64 %17, 4
  %497 = add i64 %496, 16
  %498 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %497) #16
  br label %499

499:                                              ; preds = %495, %488
  %500 = phi ptr [ %498, %495 ], [ %5, %488 ]
  %501 = icmp sgt i64 %11, -1
  br i1 %501, label %502, label %752, !prof !68

502:                                              ; preds = %507, %499
  %503 = phi i64 [ %508, %507 ], [ 56, %499 ]
  %504 = shl i64 255, %503
  %505 = and i64 %504, %11
  %506 = icmp eq i64 %505, 0
  br i1 %506, label %507, label %510

507:                                              ; preds = %502
  %508 = add nsw i64 %503, -8
  %509 = icmp eq i64 %508, 0
  br i1 %509, label %510, label %502, !llvm.loop !387

510:                                              ; preds = %507, %502
  %511 = phi i64 [ %503, %502 ], [ 0, %507 ]
  %512 = or disjoint i64 %511, 1
  %513 = lshr i64 %11, %512
  %514 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %513
  %515 = load i8, ptr %514, align 1, !tbaa !155
  %516 = zext i8 %515 to i64
  %517 = add i64 %512, %516
  %518 = trunc i64 %517 to i32
  %519 = sub i32 65, %518
  %520 = getelementptr inbounds i64, ptr %1, i64 %2
  %521 = sub nsw i64 0, %493
  %522 = getelementptr inbounds i64, ptr %520, i64 %521
  %523 = call i64 @__gmpn_lshift(ptr noundef %500, ptr noundef nonnull %522, i64 noundef %493, i32 noundef %519) #16
  %524 = getelementptr inbounds i64, ptr %500, i64 %493
  store i64 %523, ptr %524, align 8, !tbaa !15
  %525 = icmp ne i64 %523, 0
  %526 = zext i1 %525 to i64
  %527 = add nsw i64 %493, %526
  %528 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %490) #16
  %529 = getelementptr inbounds i64, ptr %3, i64 %4
  %530 = sub nsw i64 -2, %16
  %531 = getelementptr inbounds i64, ptr %529, i64 %530
  %532 = call i64 @__gmpn_lshift(ptr noundef %528, ptr noundef %531, i64 noundef %489, i32 noundef %519) #16
  %533 = sub i64 %4, %16
  %534 = getelementptr i64, ptr %3, i64 %533
  %535 = getelementptr i8, ptr %534, i64 -24
  %536 = load i64, ptr %535, align 8, !tbaa !15
  %537 = add i64 %517, 4294967295
  %538 = and i64 %537, 4294967295
  %539 = lshr i64 %536, %538
  %540 = load i64, ptr %528, align 8, !tbaa !15
  %541 = or i64 %540, %539
  store i64 %541, ptr %528, align 8, !tbaa !15
  %542 = icmp eq i64 %16, 0
  br i1 %542, label %543, label %545

543:                                              ; preds = %510
  %544 = call i64 @__gmpn_divrem_2(ptr noundef %491, i64 noundef 0, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528) #16
  br label %740

545:                                              ; preds = %510
  %546 = icmp sgt i64 %16, 197
  br i1 %546, label %640, label %547

547:                                              ; preds = %545
  %548 = getelementptr inbounds i64, ptr %528, i64 %17
  %549 = load i64, ptr %548, align 8, !tbaa !15
  %550 = lshr i64 %549, 32
  %551 = and i64 %549, 4294967295
  %552 = xor i64 %549, -1
  %553 = udiv i64 %552, %550
  %554 = mul i64 %553, %550
  %555 = urem i64 %552, %550
  %556 = mul i64 %553, %551
  %557 = shl i64 %555, 32
  %558 = or disjoint i64 %557, 4294967295
  %559 = icmp ult i64 %558, %556
  br i1 %559, label %560, label %569

560:                                              ; preds = %547
  %561 = add i64 %553, -1
  %562 = add i64 %558, %549
  %563 = icmp uge i64 %562, %549
  %564 = icmp ult i64 %562, %556
  %565 = and i1 %563, %564
  br i1 %565, label %566, label %569

566:                                              ; preds = %560
  %567 = add i64 %553, -2
  %568 = add i64 %562, %549
  br label %569

569:                                              ; preds = %566, %560, %547
  %570 = phi i64 [ %568, %566 ], [ %562, %560 ], [ %558, %547 ]
  %571 = phi i64 [ %567, %566 ], [ %561, %560 ], [ %553, %547 ]
  %572 = sub i64 %570, %556
  %573 = udiv i64 %572, %550
  %574 = mul i64 %573, %550
  %575 = urem i64 %572, %550
  %576 = mul i64 %573, %551
  %577 = shl i64 %575, 32
  %578 = or disjoint i64 %577, 4294967295
  %579 = icmp ult i64 %578, %576
  br i1 %579, label %580, label %587

580:                                              ; preds = %569
  %581 = add i64 %578, %549
  %582 = icmp uge i64 %581, %549
  %583 = icmp ult i64 %581, %576
  %584 = and i1 %582, %583
  %585 = select i1 %584, i64 -2, i64 -1
  %586 = add i64 %585, %573
  br label %587

587:                                              ; preds = %580, %569
  %588 = phi i64 [ %573, %569 ], [ %586, %580 ]
  %589 = shl i64 %571, 32
  %590 = or i64 %588, %589
  %591 = mul i64 %590, %549
  %592 = getelementptr inbounds i64, ptr %528, i64 %16
  %593 = load i64, ptr %592, align 8, !tbaa !15
  %594 = add i64 %591, %593
  %595 = icmp ult i64 %594, %593
  br i1 %595, label %596, label %604

596:                                              ; preds = %587
  %597 = add i64 %590, -1
  %598 = icmp uge i64 %594, %549
  %599 = sext i1 %598 to i64
  %600 = add i64 %597, %599
  %601 = select i1 %598, i64 %549, i64 0
  %602 = add i64 %549, %601
  %603 = sub i64 %594, %602
  br label %604

604:                                              ; preds = %596, %587
  %605 = phi i64 [ %603, %596 ], [ %594, %587 ]
  %606 = phi i64 [ %600, %596 ], [ %590, %587 ]
  %607 = lshr i64 %593, 32
  %608 = lshr i64 %606, 32
  %609 = and i64 %593, 4294967295
  %610 = and i64 %606, 4294967295
  %611 = mul nuw i64 %610, %609
  %612 = mul nuw i64 %608, %609
  %613 = mul nuw i64 %610, %607
  %614 = mul nuw i64 %608, %607
  %615 = lshr i64 %611, 32
  %616 = add i64 %613, %612
  %617 = add i64 %616, %615
  %618 = icmp ult i64 %617, %613
  %619 = add nuw i64 %614, 4294967296
  %620 = select i1 %618, i64 %619, i64 %614
  %621 = lshr i64 %617, 32
  %622 = add i64 %620, %621
  %623 = shl i64 %617, 32
  %624 = and i64 %611, 4294967295
  %625 = or disjoint i64 %623, %624
  %626 = add i64 %622, %605
  %627 = icmp ult i64 %626, %622
  br i1 %627, label %628, label %637

628:                                              ; preds = %604
  %629 = add i64 %606, -1
  %630 = icmp ult i64 %626, %549
  br i1 %630, label %637, label %631, !prof !68

631:                                              ; preds = %628
  %632 = icmp ule i64 %626, %549
  %633 = icmp ult i64 %625, %593
  %634 = select i1 %632, i1 %633, i1 false
  %635 = add i64 %606, -2
  %636 = select i1 %634, i64 %629, i64 %635
  br label %637

637:                                              ; preds = %631, %628, %604
  %638 = phi i64 [ %629, %628 ], [ %606, %604 ], [ %636, %631 ]
  store i64 %638, ptr %7, align 8, !tbaa !357
  %639 = call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528, i64 noundef %489, i64 noundef %638) #16
  br label %740

640:                                              ; preds = %545
  %641 = icmp sgt i64 %16, 1997
  br i1 %641, label %735, label %642

642:                                              ; preds = %640
  %643 = getelementptr inbounds i64, ptr %528, i64 %17
  %644 = load i64, ptr %643, align 8, !tbaa !15
  %645 = lshr i64 %644, 32
  %646 = and i64 %644, 4294967295
  %647 = xor i64 %644, -1
  %648 = udiv i64 %647, %645
  %649 = mul i64 %648, %645
  %650 = urem i64 %647, %645
  %651 = mul i64 %648, %646
  %652 = shl i64 %650, 32
  %653 = or disjoint i64 %652, 4294967295
  %654 = icmp ult i64 %653, %651
  br i1 %654, label %655, label %664

655:                                              ; preds = %642
  %656 = add i64 %648, -1
  %657 = add i64 %653, %644
  %658 = icmp uge i64 %657, %644
  %659 = icmp ult i64 %657, %651
  %660 = and i1 %658, %659
  br i1 %660, label %661, label %664

661:                                              ; preds = %655
  %662 = add i64 %648, -2
  %663 = add i64 %657, %644
  br label %664

664:                                              ; preds = %661, %655, %642
  %665 = phi i64 [ %662, %661 ], [ %656, %655 ], [ %648, %642 ]
  %666 = phi i64 [ %663, %661 ], [ %657, %655 ], [ %653, %642 ]
  %667 = sub i64 %666, %651
  %668 = udiv i64 %667, %645
  %669 = mul i64 %668, %645
  %670 = urem i64 %667, %645
  %671 = mul i64 %668, %646
  %672 = shl i64 %670, 32
  %673 = or disjoint i64 %672, 4294967295
  %674 = icmp ult i64 %673, %671
  br i1 %674, label %675, label %682

675:                                              ; preds = %664
  %676 = add i64 %673, %644
  %677 = icmp uge i64 %676, %644
  %678 = icmp ult i64 %676, %671
  %679 = and i1 %677, %678
  %680 = select i1 %679, i64 -2, i64 -1
  %681 = add i64 %680, %668
  br label %682

682:                                              ; preds = %675, %664
  %683 = phi i64 [ %668, %664 ], [ %681, %675 ]
  %684 = shl i64 %665, 32
  %685 = or i64 %683, %684
  %686 = mul i64 %685, %644
  %687 = getelementptr inbounds i64, ptr %528, i64 %16
  %688 = load i64, ptr %687, align 8, !tbaa !15
  %689 = add i64 %686, %688
  %690 = icmp ult i64 %689, %688
  br i1 %690, label %691, label %699

691:                                              ; preds = %682
  %692 = add i64 %685, -1
  %693 = icmp uge i64 %689, %644
  %694 = sext i1 %693 to i64
  %695 = add i64 %692, %694
  %696 = select i1 %693, i64 %644, i64 0
  %697 = add i64 %644, %696
  %698 = sub i64 %689, %697
  br label %699

699:                                              ; preds = %691, %682
  %700 = phi i64 [ %695, %691 ], [ %685, %682 ]
  %701 = phi i64 [ %698, %691 ], [ %689, %682 ]
  %702 = lshr i64 %688, 32
  %703 = lshr i64 %700, 32
  %704 = and i64 %688, 4294967295
  %705 = and i64 %700, 4294967295
  %706 = mul nuw i64 %705, %704
  %707 = mul nuw i64 %703, %704
  %708 = mul nuw i64 %705, %702
  %709 = mul nuw i64 %703, %702
  %710 = lshr i64 %706, 32
  %711 = add i64 %708, %707
  %712 = add i64 %711, %710
  %713 = icmp ult i64 %712, %708
  %714 = add nuw i64 %709, 4294967296
  %715 = select i1 %713, i64 %714, i64 %709
  %716 = lshr i64 %712, 32
  %717 = add i64 %715, %716
  %718 = shl i64 %712, 32
  %719 = and i64 %706, 4294967295
  %720 = or disjoint i64 %718, %719
  %721 = add i64 %717, %701
  %722 = icmp ult i64 %721, %717
  br i1 %722, label %723, label %732

723:                                              ; preds = %699
  %724 = add i64 %700, -1
  %725 = icmp ult i64 %721, %644
  br i1 %725, label %732, label %726, !prof !68

726:                                              ; preds = %723
  %727 = icmp ule i64 %721, %644
  %728 = icmp ult i64 %720, %688
  %729 = select i1 %727, i1 %728, i1 false
  %730 = add i64 %700, -2
  %731 = select i1 %729, i64 %724, i64 %730
  br label %732

732:                                              ; preds = %726, %723, %699
  %733 = phi i64 [ %724, %723 ], [ %700, %699 ], [ %731, %726 ]
  store i64 %733, ptr %7, align 8, !tbaa !357
  %734 = call i64 @__gmpn_dcpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528, i64 noundef %489, ptr noundef nonnull %7) #16
  br label %740

735:                                              ; preds = %640
  %736 = call i64 @__gmpn_mu_divappr_q_itch(i64 noundef %527, i64 noundef %489, i32 noundef 0) #17
  %737 = shl i64 %736, 3
  %738 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %737) #16
  %739 = call i64 @__gmpn_mu_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528, i64 noundef %489, ptr noundef %738) #16
  br label %740

740:                                              ; preds = %735, %732, %637, %543
  %741 = phi i64 [ %544, %543 ], [ %739, %735 ], [ %734, %732 ], [ %639, %637 ]
  %742 = icmp eq i64 %523, 0
  br i1 %742, label %743, label %745

743:                                              ; preds = %740
  %744 = getelementptr inbounds i64, ptr %491, i64 %17
  store i64 %741, ptr %744, align 8, !tbaa !15
  br label %971

745:                                              ; preds = %740
  %746 = icmp eq i64 %741, 0
  br i1 %746, label %971, label %747, !prof !68

747:                                              ; preds = %745
  %748 = sub nsw i64 %527, %489
  %749 = icmp sgt i64 %748, 0
  br i1 %749, label %750, label %971

750:                                              ; preds = %747
  %751 = shl nuw i64 %748, 3
  call void @llvm.memset.p0.i64(ptr align 8 %491, i8 -1, i64 %751, i1 false), !tbaa !15
  br label %971

752:                                              ; preds = %499
  %753 = getelementptr inbounds i64, ptr %1, i64 %2
  %754 = sub nsw i64 0, %493
  %755 = getelementptr inbounds i64, ptr %753, i64 %754
  %756 = load i64, ptr %755, align 8, !tbaa !15
  %757 = icmp eq i64 %17, 0
  br i1 %757, label %768, label %758

758:                                              ; preds = %758, %752
  %759 = phi i64 [ %766, %758 ], [ %492, %752 ]
  %760 = phi ptr [ %764, %758 ], [ %500, %752 ]
  %761 = phi ptr [ %763, %758 ], [ %755, %752 ]
  %762 = phi i64 [ %765, %758 ], [ %756, %752 ]
  %763 = getelementptr inbounds i8, ptr %761, i64 8
  %764 = getelementptr inbounds i8, ptr %760, i64 8
  store i64 %762, ptr %760, align 8, !tbaa !15
  %765 = load i64, ptr %763, align 8, !tbaa !15
  %766 = add nsw i64 %759, -1
  %767 = icmp eq i64 %766, 0
  br i1 %767, label %768, label %758, !llvm.loop !388

768:                                              ; preds = %758, %752
  %769 = phi ptr [ %500, %752 ], [ %764, %758 ]
  %770 = phi i64 [ %756, %752 ], [ %765, %758 ]
  store i64 %770, ptr %769, align 8, !tbaa !15
  %771 = getelementptr inbounds i64, ptr %3, i64 %4
  %772 = sub nsw i64 -2, %16
  %773 = getelementptr inbounds i64, ptr %771, i64 %772
  %774 = icmp eq i64 %16, 0
  br i1 %774, label %775, label %777

775:                                              ; preds = %768
  %776 = call i64 @__gmpn_divrem_2(ptr noundef %491, i64 noundef 0, ptr noundef %500, i64 noundef %493, ptr noundef nonnull %773) #16
  br label %968

777:                                              ; preds = %768
  %778 = icmp sgt i64 %16, 197
  br i1 %778, label %870, label %779

779:                                              ; preds = %777
  %780 = lshr i64 %11, 32
  %781 = and i64 %11, 4294967295
  %782 = xor i64 %11, -1
  %783 = udiv i64 %782, %780
  %784 = mul nuw i64 %783, %780
  %785 = urem i64 %782, %780
  %786 = mul nuw i64 %783, %781
  %787 = shl i64 %785, 32
  %788 = or disjoint i64 %787, 4294967295
  %789 = icmp ult i64 %788, %786
  br i1 %789, label %790, label %799

790:                                              ; preds = %779
  %791 = add nsw i64 %783, -1
  %792 = add i64 %788, %11
  %793 = icmp uge i64 %792, %11
  %794 = icmp ult i64 %792, %786
  %795 = and i1 %793, %794
  br i1 %795, label %796, label %799

796:                                              ; preds = %790
  %797 = add nsw i64 %783, -2
  %798 = add i64 %792, %11
  br label %799

799:                                              ; preds = %796, %790, %779
  %800 = phi i64 [ %797, %796 ], [ %791, %790 ], [ %783, %779 ]
  %801 = phi i64 [ %798, %796 ], [ %792, %790 ], [ %788, %779 ]
  %802 = sub i64 %801, %786
  %803 = udiv i64 %802, %780
  %804 = mul i64 %803, %780
  %805 = urem i64 %802, %780
  %806 = mul i64 %803, %781
  %807 = shl i64 %805, 32
  %808 = or disjoint i64 %807, 4294967295
  %809 = icmp ult i64 %808, %806
  br i1 %809, label %810, label %817

810:                                              ; preds = %799
  %811 = add i64 %808, %11
  %812 = icmp uge i64 %811, %11
  %813 = icmp ult i64 %811, %806
  %814 = and i1 %812, %813
  %815 = select i1 %814, i64 -2, i64 -1
  %816 = add nsw i64 %815, %803
  br label %817

817:                                              ; preds = %810, %799
  %818 = phi i64 [ %803, %799 ], [ %816, %810 ]
  %819 = shl i64 %800, 32
  %820 = or i64 %818, %819
  %821 = mul i64 %820, %11
  %822 = getelementptr inbounds i8, ptr %771, i64 -16
  %823 = load i64, ptr %822, align 8, !tbaa !15
  %824 = add i64 %821, %823
  %825 = icmp ult i64 %824, %823
  br i1 %825, label %826, label %834

826:                                              ; preds = %817
  %827 = add i64 %820, -1
  %828 = icmp uge i64 %824, %11
  %829 = sext i1 %828 to i64
  %830 = add i64 %827, %829
  %831 = select i1 %828, i64 %11, i64 0
  %832 = add i64 %11, %831
  %833 = sub i64 %824, %832
  br label %834

834:                                              ; preds = %826, %817
  %835 = phi i64 [ %830, %826 ], [ %820, %817 ]
  %836 = phi i64 [ %833, %826 ], [ %824, %817 ]
  %837 = lshr i64 %823, 32
  %838 = lshr i64 %835, 32
  %839 = and i64 %823, 4294967295
  %840 = and i64 %835, 4294967295
  %841 = mul nuw i64 %840, %839
  %842 = mul nuw i64 %838, %839
  %843 = mul nuw i64 %840, %837
  %844 = mul nuw i64 %838, %837
  %845 = lshr i64 %841, 32
  %846 = add i64 %843, %842
  %847 = add i64 %846, %845
  %848 = icmp ult i64 %847, %843
  %849 = add nuw i64 %844, 4294967296
  %850 = select i1 %848, i64 %849, i64 %844
  %851 = lshr i64 %847, 32
  %852 = add i64 %850, %851
  %853 = shl i64 %847, 32
  %854 = and i64 %841, 4294967295
  %855 = or disjoint i64 %853, %854
  %856 = add i64 %852, %836
  %857 = icmp ult i64 %856, %852
  br i1 %857, label %858, label %867

858:                                              ; preds = %834
  %859 = add i64 %835, -1
  %860 = icmp ult i64 %856, %11
  br i1 %860, label %867, label %861, !prof !68

861:                                              ; preds = %858
  %862 = icmp ule i64 %856, %11
  %863 = icmp ult i64 %855, %823
  %864 = select i1 %862, i1 %863, i1 false
  %865 = add i64 %835, -2
  %866 = select i1 %864, i64 %859, i64 %865
  br label %867

867:                                              ; preds = %861, %858, %834
  %868 = phi i64 [ %859, %858 ], [ %835, %834 ], [ %866, %861 ]
  store i64 %868, ptr %7, align 8, !tbaa !357
  %869 = call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %493, ptr noundef %773, i64 noundef %489, i64 noundef %868) #16
  br label %968

870:                                              ; preds = %777
  %871 = icmp sgt i64 %16, 1997
  br i1 %871, label %963, label %872

872:                                              ; preds = %870
  %873 = lshr i64 %11, 32
  %874 = and i64 %11, 4294967295
  %875 = xor i64 %11, -1
  %876 = udiv i64 %875, %873
  %877 = mul nuw i64 %876, %873
  %878 = urem i64 %875, %873
  %879 = mul nuw i64 %876, %874
  %880 = shl i64 %878, 32
  %881 = or disjoint i64 %880, 4294967295
  %882 = icmp ult i64 %881, %879
  br i1 %882, label %883, label %892

883:                                              ; preds = %872
  %884 = add nsw i64 %876, -1
  %885 = add i64 %881, %11
  %886 = icmp uge i64 %885, %11
  %887 = icmp ult i64 %885, %879
  %888 = and i1 %886, %887
  br i1 %888, label %889, label %892

889:                                              ; preds = %883
  %890 = add nsw i64 %876, -2
  %891 = add i64 %885, %11
  br label %892

892:                                              ; preds = %889, %883, %872
  %893 = phi i64 [ %890, %889 ], [ %884, %883 ], [ %876, %872 ]
  %894 = phi i64 [ %891, %889 ], [ %885, %883 ], [ %881, %872 ]
  %895 = sub i64 %894, %879
  %896 = udiv i64 %895, %873
  %897 = mul i64 %896, %873
  %898 = urem i64 %895, %873
  %899 = mul i64 %896, %874
  %900 = shl i64 %898, 32
  %901 = or disjoint i64 %900, 4294967295
  %902 = icmp ult i64 %901, %899
  br i1 %902, label %903, label %910

903:                                              ; preds = %892
  %904 = add i64 %901, %11
  %905 = icmp uge i64 %904, %11
  %906 = icmp ult i64 %904, %899
  %907 = and i1 %905, %906
  %908 = select i1 %907, i64 -2, i64 -1
  %909 = add nsw i64 %908, %896
  br label %910

910:                                              ; preds = %903, %892
  %911 = phi i64 [ %896, %892 ], [ %909, %903 ]
  %912 = shl i64 %893, 32
  %913 = or i64 %911, %912
  %914 = mul i64 %913, %11
  %915 = getelementptr inbounds i8, ptr %771, i64 -16
  %916 = load i64, ptr %915, align 8, !tbaa !15
  %917 = add i64 %914, %916
  %918 = icmp ult i64 %917, %916
  br i1 %918, label %919, label %927

919:                                              ; preds = %910
  %920 = add i64 %913, -1
  %921 = icmp uge i64 %917, %11
  %922 = sext i1 %921 to i64
  %923 = add i64 %920, %922
  %924 = select i1 %921, i64 %11, i64 0
  %925 = add i64 %11, %924
  %926 = sub i64 %917, %925
  br label %927

927:                                              ; preds = %919, %910
  %928 = phi i64 [ %923, %919 ], [ %913, %910 ]
  %929 = phi i64 [ %926, %919 ], [ %917, %910 ]
  %930 = lshr i64 %916, 32
  %931 = lshr i64 %928, 32
  %932 = and i64 %916, 4294967295
  %933 = and i64 %928, 4294967295
  %934 = mul nuw i64 %933, %932
  %935 = mul nuw i64 %931, %932
  %936 = mul nuw i64 %933, %930
  %937 = mul nuw i64 %931, %930
  %938 = lshr i64 %934, 32
  %939 = add i64 %936, %935
  %940 = add i64 %939, %938
  %941 = icmp ult i64 %940, %936
  %942 = add nuw i64 %937, 4294967296
  %943 = select i1 %941, i64 %942, i64 %937
  %944 = lshr i64 %940, 32
  %945 = add i64 %943, %944
  %946 = shl i64 %940, 32
  %947 = and i64 %934, 4294967295
  %948 = or disjoint i64 %946, %947
  %949 = add i64 %945, %929
  %950 = icmp ult i64 %949, %945
  br i1 %950, label %951, label %960

951:                                              ; preds = %927
  %952 = add i64 %928, -1
  %953 = icmp ult i64 %949, %11
  br i1 %953, label %960, label %954, !prof !68

954:                                              ; preds = %951
  %955 = icmp ule i64 %949, %11
  %956 = icmp ult i64 %948, %916
  %957 = select i1 %955, i1 %956, i1 false
  %958 = add i64 %928, -2
  %959 = select i1 %957, i64 %952, i64 %958
  br label %960

960:                                              ; preds = %954, %951, %927
  %961 = phi i64 [ %952, %951 ], [ %928, %927 ], [ %959, %954 ]
  store i64 %961, ptr %7, align 8, !tbaa !357
  %962 = call i64 @__gmpn_dcpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %493, ptr noundef nonnull %773, i64 noundef %489, ptr noundef nonnull %7) #16
  br label %968

963:                                              ; preds = %870
  %964 = call i64 @__gmpn_mu_divappr_q_itch(i64 noundef %493, i64 noundef %489, i32 noundef 0) #17
  %965 = shl i64 %964, 3
  %966 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %965) #16
  %967 = call i64 @__gmpn_mu_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %493, ptr noundef nonnull %773, i64 noundef %489, ptr noundef %966) #16
  br label %968

968:                                              ; preds = %963, %960, %867, %775
  %969 = phi i64 [ %776, %775 ], [ %967, %963 ], [ %962, %960 ], [ %869, %867 ]
  %970 = getelementptr inbounds i64, ptr %491, i64 %17
  store i64 %969, ptr %970, align 8, !tbaa !15
  br label %971

971:                                              ; preds = %968, %750, %747, %745, %743
  %972 = icmp eq i64 %17, 0
  br i1 %972, label %992, label %973

973:                                              ; preds = %971
  %974 = getelementptr inbounds i8, ptr %491, i64 8
  %975 = load i64, ptr %974, align 8, !tbaa !15
  %976 = icmp eq i64 %16, 0
  br i1 %976, label %989, label %977

977:                                              ; preds = %973
  %978 = getelementptr inbounds i8, ptr %491, i64 16
  br label %979

979:                                              ; preds = %979, %977
  %980 = phi i64 [ %987, %979 ], [ %16, %977 ]
  %981 = phi ptr [ %984, %979 ], [ %0, %977 ]
  %982 = phi ptr [ %985, %979 ], [ %978, %977 ]
  %983 = phi i64 [ %986, %979 ], [ %975, %977 ]
  %984 = getelementptr inbounds i8, ptr %981, i64 8
  store i64 %983, ptr %981, align 8, !tbaa !15
  %985 = getelementptr inbounds i8, ptr %982, i64 8
  %986 = load i64, ptr %982, align 8, !tbaa !15
  %987 = add nsw i64 %980, -1
  %988 = icmp eq i64 %987, 0
  br i1 %988, label %989, label %979, !llvm.loop !389

989:                                              ; preds = %979, %973
  %990 = phi ptr [ %0, %973 ], [ %984, %979 ]
  %991 = phi i64 [ %975, %973 ], [ %986, %979 ]
  store i64 %991, ptr %990, align 8, !tbaa !15
  br label %992

992:                                              ; preds = %989, %971
  %993 = load i64, ptr %491, align 8, !tbaa !15
  %994 = icmp ult i64 %993, 5
  br i1 %994, label %995, label %1029

995:                                              ; preds = %992
  %996 = add i64 %2, 1
  %997 = shl i64 %996, 3
  %998 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %997) #16
  %999 = getelementptr inbounds i8, ptr %491, i64 8
  %1000 = call i64 @__gmpn_mul(ptr noundef %998, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %999, i64 noundef %17) #16
  %1001 = getelementptr inbounds i64, ptr %998, i64 %2
  %1002 = load i64, ptr %1001, align 8, !tbaa !15
  %1003 = icmp eq i64 %1002, 0
  %1004 = sext i1 %1003 to i64
  %1005 = add i64 %996, %1004
  %1006 = icmp sgt i64 %1005, %2
  br i1 %1006, label %1019, label %1007

1007:                                             ; preds = %1010, %995
  %1008 = phi i64 [ %1011, %1010 ], [ %2, %995 ]
  %1009 = icmp sgt i64 %1008, 0
  br i1 %1009, label %1010, label %1029

1010:                                             ; preds = %1007
  %1011 = add nsw i64 %1008, -1
  %1012 = getelementptr inbounds i64, ptr %1, i64 %1011
  %1013 = load i64, ptr %1012, align 8, !tbaa !15
  %1014 = getelementptr inbounds i64, ptr %998, i64 %1011
  %1015 = load i64, ptr %1014, align 8, !tbaa !15
  %1016 = icmp eq i64 %1013, %1015
  br i1 %1016, label %1007, label %1017, !llvm.loop !390

1017:                                             ; preds = %1010
  %1018 = icmp ugt i64 %1013, %1015
  br i1 %1018, label %1029, label %1019

1019:                                             ; preds = %1017, %995
  br label %1020

1020:                                             ; preds = %1020, %1019
  %1021 = phi ptr [ %1022, %1020 ], [ %0, %1019 ]
  %1022 = getelementptr inbounds i8, ptr %1021, i64 8
  %1023 = load i64, ptr %1021, align 8, !tbaa !15
  %1024 = add i64 %1023, -1
  store i64 %1024, ptr %1021, align 8, !tbaa !15
  %1025 = icmp eq i64 %1023, 0
  br i1 %1025, label %1020, label %1029, !llvm.loop !391

1026:                                             ; preds = %483, %480, %379, %284, %258
  %1027 = phi i64 [ %259, %258 ], [ %285, %284 ], [ %482, %480 ], [ %487, %483 ], [ %381, %379 ]
  %1028 = getelementptr inbounds i64, ptr %0, i64 %16
  store i64 %1027, ptr %1028, align 8, !tbaa !15
  br label %1029

1029:                                             ; preds = %1026, %1020, %1017, %1007, %992, %258
  %1030 = load ptr, ptr %8, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %1030) #16
  br label %1031

1031:                                             ; preds = %1029, %13
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_sbpi1_div_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5) local_unnamed_addr #5 {
  %7 = getelementptr inbounds i64, ptr %1, i64 %2
  %8 = sub i64 %2, %4
  %9 = add i64 %8, 1
  %10 = icmp slt i64 %9, %4
  %11 = sub nsw i64 %4, %9
  %12 = tail call i64 @llvm.smin.i64(i64 %9, i64 %4)
  %13 = select i1 %10, i64 %11, i64 0
  %14 = getelementptr inbounds i64, ptr %3, i64 %13
  %15 = sub i64 0, %12
  %16 = getelementptr inbounds i64, ptr %7, i64 %15
  br label %17

17:                                               ; preds = %20, %6
  %18 = phi i64 [ %12, %6 ], [ %21, %20 ]
  %19 = icmp sgt i64 %18, 0
  br i1 %19, label %20, label %29

20:                                               ; preds = %17
  %21 = add nsw i64 %18, -1
  %22 = getelementptr inbounds i64, ptr %16, i64 %21
  %23 = load i64, ptr %22, align 8, !tbaa !15
  %24 = getelementptr inbounds i64, ptr %14, i64 %21
  %25 = load i64, ptr %24, align 8, !tbaa !15
  %26 = icmp eq i64 %23, %25
  br i1 %26, label %17, label %27, !llvm.loop !392

27:                                               ; preds = %20
  %28 = icmp ugt i64 %23, %25
  br label %29

29:                                               ; preds = %27, %17
  %30 = phi i1 [ %28, %27 ], [ true, %17 ]
  %31 = zext i1 %30 to i64
  br i1 %30, label %32, label %34

32:                                               ; preds = %29
  %33 = tail call i64 @__gmpn_sub_n(ptr noundef %16, ptr noundef %16, ptr noundef %14, i64 noundef %12) #16
  br label %34

34:                                               ; preds = %32, %29
  %35 = getelementptr inbounds i64, ptr %0, i64 %8
  %36 = add nsw i64 %12, -2
  %37 = add nsw i64 %12, -1
  %38 = getelementptr inbounds i64, ptr %14, i64 %37
  %39 = load i64, ptr %38, align 8, !tbaa !15
  %40 = getelementptr inbounds i64, ptr %14, i64 %36
  %41 = load i64, ptr %40, align 8, !tbaa !15
  %42 = getelementptr inbounds i8, ptr %7, i64 -16
  %43 = getelementptr inbounds i8, ptr %7, i64 -8
  %44 = load i64, ptr %43, align 8, !tbaa !15
  %45 = sub nsw i64 %8, %12
  %46 = icmp sgt i64 %45, -1
  br i1 %46, label %47, label %166

47:                                               ; preds = %34
  %48 = lshr i64 %5, 32
  %49 = and i64 %5, 4294967295
  %50 = lshr i64 %41, 32
  %51 = and i64 %41, 4294967295
  %52 = sub i64 2, %12
  %53 = sub i64 2, %12
  br label %54

54:                                               ; preds = %160, %47
  %55 = phi ptr [ %35, %47 ], [ %163, %160 ]
  %56 = phi ptr [ %42, %47 ], [ %59, %160 ]
  %57 = phi i64 [ %45, %47 ], [ %164, %160 ]
  %58 = phi i64 [ %44, %47 ], [ %162, %160 ]
  %59 = getelementptr inbounds i8, ptr %56, i64 -8
  %60 = icmp eq i64 %58, %39
  br i1 %60, label %61, label %68, !prof !54

61:                                               ; preds = %54
  %62 = load i64, ptr %56, align 8, !tbaa !15
  %63 = icmp eq i64 %62, %41
  br i1 %63, label %64, label %68

64:                                               ; preds = %61
  %65 = getelementptr inbounds i64, ptr %59, i64 %53
  %66 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %65, ptr noundef %14, i64 noundef %12, i64 noundef -1) #16
  %67 = load i64, ptr %56, align 8, !tbaa !15
  br label %160

68:                                               ; preds = %61, %54
  %69 = lshr i64 %58, 32
  %70 = and i64 %58, 4294967295
  %71 = mul nuw i64 %70, %49
  %72 = mul nuw i64 %70, %48
  %73 = mul nuw i64 %69, %49
  %74 = mul nuw i64 %69, %48
  %75 = lshr i64 %71, 32
  %76 = add i64 %73, %72
  %77 = add i64 %76, %75
  %78 = icmp ult i64 %77, %73
  %79 = add nuw i64 %74, 4294967296
  %80 = select i1 %78, i64 %79, i64 %74
  %81 = lshr i64 %77, 32
  %82 = shl i64 %77, 32
  %83 = and i64 %71, 4294967295
  %84 = or disjoint i64 %82, %83
  %85 = load i64, ptr %56, align 8, !tbaa !15
  %86 = add i64 %85, %84
  %87 = icmp ult i64 %86, %84
  %88 = zext i1 %87 to i64
  %89 = add i64 %81, %58
  %90 = add i64 %89, %80
  %91 = add i64 %90, %88
  %92 = load i64, ptr %59, align 8, !tbaa !15
  %93 = sub i64 %92, %41
  %94 = xor i64 %91, -1
  %95 = mul i64 %39, %94
  %96 = icmp ult i64 %92, %41
  %97 = sext i1 %96 to i64
  %98 = lshr i64 %91, 32
  %99 = and i64 %91, 4294967295
  %100 = mul nuw i64 %99, %51
  %101 = mul nuw i64 %98, %51
  %102 = mul nuw i64 %99, %50
  %103 = mul nuw i64 %98, %50
  %104 = lshr i64 %100, 32
  %105 = add i64 %102, %101
  %106 = add i64 %105, %104
  %107 = icmp ult i64 %106, %102
  %108 = add nuw i64 %103, 4294967296
  %109 = select i1 %107, i64 %108, i64 %103
  %110 = lshr i64 %106, 32
  %111 = shl i64 %106, 32
  %112 = and i64 %100, 4294967295
  %113 = or disjoint i64 %111, %112
  %114 = sub i64 %93, %113
  %115 = icmp ult i64 %93, %113
  %116 = sext i1 %115 to i64
  %117 = add i64 %85, %97
  %118 = add i64 %117, %95
  %119 = add i64 %110, %109
  %120 = sub i64 %118, %119
  %121 = add i64 %120, %116
  %122 = add i64 %91, 1
  %123 = icmp uge i64 %121, %86
  %124 = sext i1 %123 to i64
  %125 = add i64 %122, %124
  %126 = select i1 %123, i64 %41, i64 0
  %127 = add i64 %126, %114
  %128 = select i1 %123, i64 %39, i64 0
  %129 = add i64 %128, %121
  %130 = icmp ult i64 %127, %114
  %131 = zext i1 %130 to i64
  %132 = add i64 %129, %131
  %133 = icmp ult i64 %132, %39
  br i1 %133, label %144, label %134, !prof !68

134:                                              ; preds = %68
  %135 = icmp ule i64 %132, %39
  %136 = icmp ult i64 %127, %41
  %137 = select i1 %135, i1 %136, i1 false
  br i1 %137, label %144, label %138

138:                                              ; preds = %134
  %139 = add i64 %125, 1
  %140 = sub i64 %127, %41
  %141 = sext i1 %136 to i64
  %142 = sub i64 %141, %39
  %143 = add i64 %142, %132
  br label %144

144:                                              ; preds = %138, %134, %68
  %145 = phi i64 [ %139, %138 ], [ %125, %68 ], [ %125, %134 ]
  %146 = phi i64 [ %140, %138 ], [ %127, %68 ], [ %127, %134 ]
  %147 = phi i64 [ %143, %138 ], [ %132, %68 ], [ %132, %134 ]
  %148 = getelementptr inbounds i64, ptr %59, i64 %52
  %149 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %148, ptr noundef %14, i64 noundef %36, i64 noundef %145) #16
  %150 = icmp ult i64 %146, %149
  %151 = zext i1 %150 to i64
  %152 = sub i64 %146, %149
  %153 = icmp ult i64 %147, %151
  %154 = sub i64 %147, %151
  store i64 %152, ptr %59, align 8, !tbaa !15
  br i1 %153, label %155, label %160, !prof !54

155:                                              ; preds = %144
  %156 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %148, ptr noundef nonnull %148, ptr noundef %14, i64 noundef %37) #16
  %157 = add i64 %154, %39
  %158 = add i64 %157, %156
  %159 = add i64 %145, -1
  br label %160

160:                                              ; preds = %155, %144, %64
  %161 = phi i64 [ -1, %64 ], [ %159, %155 ], [ %145, %144 ]
  %162 = phi i64 [ %67, %64 ], [ %158, %155 ], [ %154, %144 ]
  %163 = getelementptr inbounds i8, ptr %55, i64 -8
  store i64 %161, ptr %163, align 8, !tbaa !15
  %164 = add nsw i64 %57, -1
  %165 = icmp sgt i64 %57, 0
  br i1 %165, label %54, label %166, !llvm.loop !393

166:                                              ; preds = %160, %34
  %167 = phi i64 [ %44, %34 ], [ %162, %160 ]
  %168 = phi ptr [ %42, %34 ], [ %59, %160 ]
  %169 = phi ptr [ %35, %34 ], [ %163, %160 ]
  %170 = icmp sgt i64 %12, 1
  br i1 %170, label %171, label %423

171:                                              ; preds = %166
  %172 = icmp eq i64 %12, 2
  br i1 %172, label %304, label %173

173:                                              ; preds = %171
  %174 = lshr i64 %5, 32
  %175 = and i64 %5, 4294967295
  %176 = lshr i64 %41, 32
  %177 = and i64 %41, 4294967295
  %178 = shl i64 %12, 3
  %179 = sub i64 8, %178
  %180 = getelementptr i8, ptr %168, i64 %179
  br label %181

181:                                              ; preds = %296, %173
  %182 = phi ptr [ %169, %173 ], [ %300, %296 ]
  %183 = phi ptr [ %168, %173 ], [ %188, %296 ]
  %184 = phi ptr [ %14, %173 ], [ %302, %296 ]
  %185 = phi i64 [ %36, %173 ], [ %301, %296 ]
  %186 = phi i64 [ %167, %173 ], [ %299, %296 ]
  %187 = phi i64 [ -1, %173 ], [ %297, %296 ]
  %188 = getelementptr inbounds i8, ptr %183, i64 -8
  %189 = and i64 %187, %39
  %190 = icmp ult i64 %186, %189
  br i1 %190, label %204, label %191, !prof !68

191:                                              ; preds = %181
  %192 = add nuw nsw i64 %185, 2
  %193 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %180, ptr noundef %184, i64 noundef %192, i64 noundef -1) #16
  %194 = icmp eq i64 %186, %193
  br i1 %194, label %200, label %195, !prof !68

195:                                              ; preds = %191
  %196 = and i64 %193, %187
  %197 = icmp ult i64 %186, %196
  br i1 %197, label %198, label %200

198:                                              ; preds = %195
  %199 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %180, ptr noundef nonnull %180, ptr noundef %184, i64 noundef %192) #16
  br label %200

200:                                              ; preds = %198, %195, %191
  %201 = phi i64 [ %187, %198 ], [ %187, %191 ], [ 0, %195 ]
  %202 = phi i64 [ -2, %198 ], [ -1, %191 ], [ -1, %195 ]
  %203 = load i64, ptr %183, align 8, !tbaa !15
  br label %296

204:                                              ; preds = %181
  %205 = lshr i64 %186, 32
  %206 = and i64 %186, 4294967295
  %207 = mul nuw i64 %206, %175
  %208 = mul nuw i64 %206, %174
  %209 = mul nuw i64 %205, %175
  %210 = mul nuw i64 %205, %174
  %211 = lshr i64 %207, 32
  %212 = add i64 %209, %208
  %213 = add i64 %212, %211
  %214 = icmp ult i64 %213, %209
  %215 = add nuw i64 %210, 4294967296
  %216 = select i1 %214, i64 %215, i64 %210
  %217 = lshr i64 %213, 32
  %218 = shl i64 %213, 32
  %219 = and i64 %207, 4294967295
  %220 = or disjoint i64 %218, %219
  %221 = load i64, ptr %183, align 8, !tbaa !15
  %222 = add i64 %221, %220
  %223 = icmp ult i64 %222, %220
  %224 = zext i1 %223 to i64
  %225 = add i64 %217, %186
  %226 = add i64 %225, %216
  %227 = add i64 %226, %224
  %228 = load i64, ptr %188, align 8, !tbaa !15
  %229 = sub i64 %228, %41
  %230 = xor i64 %227, -1
  %231 = mul i64 %39, %230
  %232 = icmp ult i64 %228, %41
  %233 = sext i1 %232 to i64
  %234 = lshr i64 %227, 32
  %235 = and i64 %227, 4294967295
  %236 = mul nuw i64 %235, %177
  %237 = mul nuw i64 %234, %177
  %238 = mul nuw i64 %235, %176
  %239 = mul nuw i64 %234, %176
  %240 = lshr i64 %236, 32
  %241 = add i64 %238, %237
  %242 = add i64 %241, %240
  %243 = icmp ult i64 %242, %238
  %244 = add nuw i64 %239, 4294967296
  %245 = select i1 %243, i64 %244, i64 %239
  %246 = lshr i64 %242, 32
  %247 = shl i64 %242, 32
  %248 = and i64 %236, 4294967295
  %249 = or disjoint i64 %247, %248
  %250 = sub i64 %229, %249
  %251 = icmp ult i64 %229, %249
  %252 = sext i1 %251 to i64
  %253 = add i64 %221, %233
  %254 = add i64 %253, %231
  %255 = add i64 %246, %245
  %256 = sub i64 %254, %255
  %257 = add i64 %256, %252
  %258 = add i64 %227, 1
  %259 = icmp uge i64 %257, %222
  %260 = sext i1 %259 to i64
  %261 = add i64 %258, %260
  %262 = select i1 %259, i64 %41, i64 0
  %263 = add i64 %262, %250
  %264 = select i1 %259, i64 %39, i64 0
  %265 = add i64 %264, %257
  %266 = icmp ult i64 %263, %250
  %267 = zext i1 %266 to i64
  %268 = add i64 %265, %267
  %269 = icmp ult i64 %268, %39
  br i1 %269, label %280, label %270, !prof !68

270:                                              ; preds = %204
  %271 = icmp ule i64 %268, %39
  %272 = icmp ult i64 %263, %41
  %273 = select i1 %271, i1 %272, i1 false
  br i1 %273, label %280, label %274

274:                                              ; preds = %270
  %275 = add i64 %261, 1
  %276 = sub i64 %263, %41
  %277 = sext i1 %272 to i64
  %278 = sub i64 %277, %39
  %279 = add i64 %278, %268
  br label %280

280:                                              ; preds = %274, %270, %204
  %281 = phi i64 [ %275, %274 ], [ %261, %204 ], [ %261, %270 ]
  %282 = phi i64 [ %276, %274 ], [ %263, %204 ], [ %263, %270 ]
  %283 = phi i64 [ %279, %274 ], [ %268, %204 ], [ %268, %270 ]
  %284 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %180, ptr noundef %184, i64 noundef %185, i64 noundef %281) #16
  %285 = icmp ult i64 %282, %284
  %286 = zext i1 %285 to i64
  %287 = sub i64 %282, %284
  %288 = icmp ult i64 %283, %286
  %289 = sub i64 %283, %286
  store i64 %287, ptr %188, align 8, !tbaa !15
  br i1 %288, label %290, label %296, !prof !54

290:                                              ; preds = %280
  %291 = add nuw nsw i64 %185, 1
  %292 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %180, ptr noundef nonnull %180, ptr noundef %184, i64 noundef %291) #16
  %293 = add i64 %289, %39
  %294 = add i64 %293, %292
  %295 = add i64 %281, -1
  br label %296

296:                                              ; preds = %290, %280, %200
  %297 = phi i64 [ %201, %200 ], [ %187, %290 ], [ %187, %280 ]
  %298 = phi i64 [ %202, %200 ], [ %295, %290 ], [ %281, %280 ]
  %299 = phi i64 [ %203, %200 ], [ %294, %290 ], [ %289, %280 ]
  %300 = getelementptr inbounds i8, ptr %182, i64 -8
  store i64 %298, ptr %300, align 8, !tbaa !15
  %301 = add nsw i64 %185, -1
  %302 = getelementptr inbounds i8, ptr %184, i64 8
  %303 = icmp sgt i64 %185, 1
  br i1 %303, label %181, label %304, !llvm.loop !394

304:                                              ; preds = %296, %171
  %305 = phi i64 [ -1, %171 ], [ %297, %296 ]
  %306 = phi i64 [ %167, %171 ], [ %299, %296 ]
  %307 = phi ptr [ %14, %171 ], [ %302, %296 ]
  %308 = phi ptr [ %168, %171 ], [ %188, %296 ]
  %309 = phi ptr [ %169, %171 ], [ %300, %296 ]
  %310 = getelementptr inbounds i8, ptr %308, i64 -8
  %311 = and i64 %305, %39
  %312 = icmp ult i64 %306, %311
  br i1 %312, label %334, label %313, !prof !68

313:                                              ; preds = %304
  %314 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %310, ptr noundef %307, i64 noundef 2, i64 noundef -1) #16
  %315 = icmp eq i64 %306, %314
  br i1 %315, label %330, label %316, !prof !68

316:                                              ; preds = %313
  %317 = and i64 %314, %305
  %318 = icmp ult i64 %306, %317
  br i1 %318, label %319, label %330

319:                                              ; preds = %316
  %320 = load i64, ptr %310, align 8, !tbaa !15
  %321 = load i64, ptr %307, align 8, !tbaa !15
  %322 = add i64 %321, %320
  %323 = load i64, ptr %308, align 8, !tbaa !15
  %324 = getelementptr inbounds i8, ptr %307, i64 8
  %325 = load i64, ptr %324, align 8, !tbaa !15
  %326 = add i64 %325, %323
  %327 = icmp ult i64 %322, %320
  %328 = zext i1 %327 to i64
  %329 = add i64 %326, %328
  store i64 %329, ptr %308, align 8, !tbaa !15
  store i64 %322, ptr %310, align 8, !tbaa !15
  br label %330

330:                                              ; preds = %319, %316, %313
  %331 = phi i64 [ %305, %319 ], [ %305, %313 ], [ 0, %316 ]
  %332 = phi i64 [ -2, %319 ], [ -1, %313 ], [ -1, %316 ]
  %333 = load i64, ptr %308, align 8, !tbaa !15
  br label %418

334:                                              ; preds = %304
  %335 = lshr i64 %306, 32
  %336 = lshr i64 %5, 32
  %337 = and i64 %306, 4294967295
  %338 = and i64 %5, 4294967295
  %339 = mul nuw i64 %337, %338
  %340 = mul nuw i64 %337, %336
  %341 = mul nuw i64 %335, %338
  %342 = mul nuw i64 %335, %336
  %343 = lshr i64 %339, 32
  %344 = add i64 %341, %340
  %345 = add i64 %344, %343
  %346 = icmp ult i64 %345, %341
  %347 = add nuw i64 %342, 4294967296
  %348 = select i1 %346, i64 %347, i64 %342
  %349 = lshr i64 %345, 32
  %350 = shl i64 %345, 32
  %351 = and i64 %339, 4294967295
  %352 = or disjoint i64 %350, %351
  %353 = load i64, ptr %308, align 8, !tbaa !15
  %354 = add i64 %353, %352
  %355 = icmp ult i64 %354, %352
  %356 = zext i1 %355 to i64
  %357 = add i64 %349, %306
  %358 = add i64 %357, %348
  %359 = add i64 %358, %356
  %360 = load i64, ptr %310, align 8, !tbaa !15
  %361 = sub i64 %360, %41
  %362 = xor i64 %359, -1
  %363 = mul i64 %39, %362
  %364 = icmp ult i64 %360, %41
  %365 = sext i1 %364 to i64
  %366 = lshr i64 %41, 32
  %367 = lshr i64 %359, 32
  %368 = and i64 %41, 4294967295
  %369 = and i64 %359, 4294967295
  %370 = mul nuw i64 %369, %368
  %371 = mul nuw i64 %367, %368
  %372 = mul nuw i64 %369, %366
  %373 = mul nuw i64 %367, %366
  %374 = lshr i64 %370, 32
  %375 = add i64 %372, %371
  %376 = add i64 %375, %374
  %377 = icmp ult i64 %376, %372
  %378 = add nuw i64 %373, 4294967296
  %379 = select i1 %377, i64 %378, i64 %373
  %380 = lshr i64 %376, 32
  %381 = shl i64 %376, 32
  %382 = and i64 %370, 4294967295
  %383 = or disjoint i64 %381, %382
  %384 = sub i64 %361, %383
  %385 = icmp ult i64 %361, %383
  %386 = sext i1 %385 to i64
  %387 = add i64 %353, %365
  %388 = add i64 %387, %363
  %389 = add i64 %380, %379
  %390 = sub i64 %388, %389
  %391 = add i64 %390, %386
  %392 = add i64 %359, 1
  %393 = icmp uge i64 %391, %354
  %394 = sext i1 %393 to i64
  %395 = add i64 %392, %394
  %396 = select i1 %393, i64 %41, i64 0
  %397 = add i64 %396, %384
  %398 = select i1 %393, i64 %39, i64 0
  %399 = add i64 %398, %391
  %400 = icmp ult i64 %397, %384
  %401 = zext i1 %400 to i64
  %402 = add i64 %399, %401
  %403 = icmp ult i64 %402, %39
  br i1 %403, label %414, label %404, !prof !68

404:                                              ; preds = %334
  %405 = icmp ule i64 %402, %39
  %406 = icmp ult i64 %397, %41
  %407 = select i1 %405, i1 %406, i1 false
  br i1 %407, label %414, label %408

408:                                              ; preds = %404
  %409 = add i64 %395, 1
  %410 = sub i64 %397, %41
  %411 = sext i1 %406 to i64
  %412 = sub i64 %411, %39
  %413 = add i64 %412, %402
  br label %414

414:                                              ; preds = %408, %404, %334
  %415 = phi i64 [ %409, %408 ], [ %395, %334 ], [ %395, %404 ]
  %416 = phi i64 [ %410, %408 ], [ %397, %334 ], [ %397, %404 ]
  %417 = phi i64 [ %413, %408 ], [ %402, %334 ], [ %402, %404 ]
  store i64 %416, ptr %310, align 8, !tbaa !15
  store i64 %417, ptr %308, align 8, !tbaa !15
  br label %418

418:                                              ; preds = %414, %330
  %419 = phi i64 [ %331, %330 ], [ %305, %414 ]
  %420 = phi i64 [ %332, %330 ], [ %415, %414 ]
  %421 = phi i64 [ %333, %330 ], [ %417, %414 ]
  %422 = getelementptr inbounds i8, ptr %309, i64 -8
  store i64 %420, ptr %422, align 8, !tbaa !15
  br label %423

423:                                              ; preds = %418, %166
  %424 = phi i64 [ %419, %418 ], [ -1, %166 ]
  %425 = phi i64 [ %421, %418 ], [ %167, %166 ]
  %426 = phi ptr [ %310, %418 ], [ %168, %166 ]
  %427 = phi ptr [ %422, %418 ], [ %169, %166 ]
  %428 = getelementptr inbounds i8, ptr %426, i64 8
  %429 = load i64, ptr %428, align 8, !tbaa !15
  %430 = icmp eq i64 %429, %425
  br i1 %430, label %432, label %431, !prof !68

431:                                              ; preds = %423
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.304, i32 noundef 197, ptr noundef nonnull @.str.1.305) #18
  unreachable

432:                                              ; preds = %423
  %433 = getelementptr inbounds i8, ptr %426, i64 16
  %434 = and i64 %424, %4
  %435 = icmp ult i64 %425, %434
  br i1 %435, label %436, label %573, !prof !54

436:                                              ; preds = %432
  %437 = icmp sgt i64 %4, 2
  br i1 %437, label %438, label %494

438:                                              ; preds = %436
  %439 = load i64, ptr %426, align 8, !tbaa !15
  %440 = icmp slt i64 %8, 2
  br i1 %440, label %486, label %441

441:                                              ; preds = %438
  %442 = add nsw i64 %12, -3
  br label %443

443:                                              ; preds = %481, %441
  %444 = phi i1 [ %485, %481 ], [ %440, %441 ]
  %445 = phi i64 [ %483, %481 ], [ %439, %441 ]
  %446 = phi i64 [ %482, %481 ], [ %425, %441 ]
  %447 = phi i64 [ %484, %481 ], [ %442, %441 ]
  %448 = getelementptr inbounds i64, ptr %427, i64 %447
  %449 = load i64, ptr %448, align 8, !tbaa !15
  %450 = sub nsw i64 %12, %447
  %451 = sub i64 0, %450
  %452 = getelementptr inbounds i64, ptr %433, i64 %451
  %453 = add nsw i64 %450, -2
  %454 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %452, ptr noundef %14, i64 noundef %453, i64 noundef %449) #16
  %455 = icmp ult i64 %445, %454
  br i1 %455, label %456, label %481

456:                                              ; preds = %443
  %457 = icmp eq i64 %446, 0
  br i1 %457, label %458, label %479

458:                                              ; preds = %456
  %459 = load i64, ptr %427, align 8, !tbaa !15
  %460 = add i64 %459, -1
  store i64 %460, ptr %427, align 8, !tbaa !15
  %461 = icmp eq i64 %459, 0
  br i1 %461, label %462, label %473

462:                                              ; preds = %458
  %463 = tail call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %464

464:                                              ; preds = %467, %462
  %465 = phi i64 [ %471, %467 ], [ 1, %462 ]
  %466 = icmp ne i64 %465, %463
  br i1 %466, label %467, label %473

467:                                              ; preds = %464
  %468 = getelementptr inbounds i64, ptr %427, i64 %465
  %469 = load i64, ptr %468, align 8, !tbaa !15
  %470 = add i64 %469, -1
  store i64 %470, ptr %468, align 8, !tbaa !15
  %471 = add nuw i64 %465, 1
  %472 = icmp eq i64 %469, 0
  br i1 %472, label %464, label %473, !llvm.loop !395

473:                                              ; preds = %467, %464, %458
  %474 = phi i1 [ true, %458 ], [ %466, %464 ], [ %466, %467 ]
  %475 = phi i64 [ 0, %458 ], [ 0, %467 ], [ -1, %464 ]
  br i1 %474, label %477, label %476, !prof !68

476:                                              ; preds = %473
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.304, i32 noundef 248, ptr noundef nonnull @.str.2.306) #18
  unreachable

477:                                              ; preds = %473
  %478 = add nsw i64 %475, %31
  br label %490

479:                                              ; preds = %456
  %480 = add i64 %446, -1
  br label %481

481:                                              ; preds = %479, %443
  %482 = phi i64 [ %480, %479 ], [ %446, %443 ]
  %483 = sub i64 %445, %454
  %484 = add nsw i64 %447, -1
  %485 = icmp slt i64 %447, 1
  br i1 %485, label %486, label %443, !llvm.loop !396

486:                                              ; preds = %481, %438
  %487 = phi i64 [ %425, %438 ], [ %482, %481 ]
  %488 = phi i64 [ %439, %438 ], [ %483, %481 ]
  %489 = phi i1 [ %440, %438 ], [ %485, %481 ]
  store i64 %488, ptr %426, align 8, !tbaa !15
  br label %490

490:                                              ; preds = %486, %477
  %491 = phi i64 [ %446, %477 ], [ %487, %486 ]
  %492 = phi i1 [ %444, %477 ], [ %489, %486 ]
  %493 = phi i64 [ %478, %477 ], [ undef, %486 ]
  br i1 %492, label %494, label %570

494:                                              ; preds = %490, %436
  %495 = phi i64 [ %493, %490 ], [ undef, %436 ]
  %496 = phi i64 [ %491, %490 ], [ %425, %436 ]
  br i1 %10, label %497, label %570

497:                                              ; preds = %494
  br i1 %30, label %498, label %526

498:                                              ; preds = %497
  %499 = getelementptr inbounds i64, ptr %1, i64 %8
  %500 = tail call i64 @__gmpn_sub_n(ptr noundef %499, ptr noundef %499, ptr noundef %3, i64 noundef %11) #16
  %501 = icmp eq i64 %500, 0
  br i1 %501, label %526, label %502

502:                                              ; preds = %498
  %503 = icmp eq i64 %496, 0
  br i1 %503, label %504, label %524

504:                                              ; preds = %502
  %505 = icmp eq i64 %2, %4
  br i1 %505, label %521, label %506

506:                                              ; preds = %504
  %507 = load i64, ptr %427, align 8, !tbaa !15
  %508 = add i64 %507, -1
  store i64 %508, ptr %427, align 8, !tbaa !15
  %509 = icmp eq i64 %507, 0
  br i1 %509, label %510, label %521

510:                                              ; preds = %506
  %511 = tail call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %512

512:                                              ; preds = %515, %510
  %513 = phi i64 [ %519, %515 ], [ 1, %510 ]
  %514 = icmp eq i64 %513, %511
  br i1 %514, label %521, label %515

515:                                              ; preds = %512
  %516 = getelementptr inbounds i64, ptr %427, i64 %513
  %517 = load i64, ptr %516, align 8, !tbaa !15
  %518 = add i64 %517, -1
  store i64 %518, ptr %516, align 8, !tbaa !15
  %519 = add nuw i64 %513, 1
  %520 = icmp eq i64 %517, 0
  br i1 %520, label %512, label %521, !llvm.loop !395

521:                                              ; preds = %515, %512, %506, %504
  %522 = phi i64 [ %500, %504 ], [ 0, %506 ], [ 1, %512 ], [ 0, %515 ]
  %523 = sub i64 %31, %522
  br label %570

524:                                              ; preds = %502
  %525 = add i64 %496, -1
  br label %526

526:                                              ; preds = %524, %498, %497
  %527 = phi i64 [ %525, %524 ], [ %496, %498 ], [ %496, %497 ]
  %528 = icmp eq i64 %2, %4
  br i1 %528, label %570, label %529

529:                                              ; preds = %526
  %530 = sub nsw i64 %4, %8
  %531 = icmp sgt i64 %530, 1
  br i1 %531, label %532, label %570

532:                                              ; preds = %529
  %533 = add nsw i64 %530, -2
  %534 = getelementptr inbounds i64, ptr %1, i64 %8
  br label %535

535:                                              ; preds = %566, %532
  %536 = phi i64 [ %527, %532 ], [ %567, %566 ]
  %537 = phi i64 [ %533, %532 ], [ %568, %566 ]
  %538 = getelementptr inbounds i64, ptr %1, i64 %537
  %539 = getelementptr inbounds i64, ptr %3, i64 %537
  %540 = load i64, ptr %539, align 8, !tbaa !15
  %541 = tail call i64 @__gmpn_submul_1(ptr noundef %538, ptr noundef %427, i64 noundef %8, i64 noundef %540) #16
  %542 = getelementptr inbounds i64, ptr %534, i64 %537
  %543 = xor i64 %537, -1
  %544 = add i64 %530, %543
  %545 = tail call i64 @__gmpn_sub_1(ptr noundef %542, ptr noundef %542, i64 noundef %544, i64 noundef %541)
  %546 = icmp eq i64 %545, 0
  br i1 %546, label %566, label %547

547:                                              ; preds = %535
  %548 = icmp eq i64 %536, 0
  br i1 %548, label %549, label %564

549:                                              ; preds = %547
  %550 = load i64, ptr %427, align 8, !tbaa !15
  %551 = add i64 %550, -1
  store i64 %551, ptr %427, align 8, !tbaa !15
  %552 = icmp eq i64 %550, 0
  br i1 %552, label %553, label %570

553:                                              ; preds = %549
  %554 = tail call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %555

555:                                              ; preds = %558, %553
  %556 = phi i64 [ %562, %558 ], [ 1, %553 ]
  %557 = icmp eq i64 %556, %554
  br i1 %557, label %570, label %558

558:                                              ; preds = %555
  %559 = getelementptr inbounds i64, ptr %427, i64 %556
  %560 = load i64, ptr %559, align 8, !tbaa !15
  %561 = add i64 %560, -1
  store i64 %561, ptr %559, align 8, !tbaa !15
  %562 = add nuw i64 %556, 1
  %563 = icmp eq i64 %560, 0
  br i1 %563, label %555, label %570, !llvm.loop !395

564:                                              ; preds = %547
  %565 = add i64 %536, -1
  br label %566

566:                                              ; preds = %564, %535
  %567 = phi i64 [ %565, %564 ], [ %536, %535 ]
  %568 = add nsw i64 %537, -1
  %569 = icmp sgt i64 %537, 0
  br i1 %569, label %535, label %570, !llvm.loop !397

570:                                              ; preds = %566, %558, %555, %549, %529, %526, %521, %494, %490
  %571 = phi i64 [ %523, %521 ], [ %493, %490 ], [ %31, %526 ], [ %495, %494 ], [ %31, %549 ], [ %495, %529 ], [ %31, %558 ], [ %31, %555 ], [ %495, %566 ]
  %572 = phi i1 [ false, %521 ], [ false, %490 ], [ false, %526 ], [ true, %494 ], [ false, %549 ], [ true, %529 ], [ false, %558 ], [ false, %555 ], [ true, %566 ]
  br i1 %572, label %573, label %574

573:                                              ; preds = %570, %432
  br label %574

574:                                              ; preds = %573, %570
  %575 = phi i64 [ %31, %573 ], [ %571, %570 ]
  ret i64 %575
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_dcpi1_div_q(ptr noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  store ptr null, ptr %7, align 8, !tbaa !7
  %8 = add nsw i64 %2, 1
  %9 = shl i64 %8, 3
  %10 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %9) #16
  %11 = icmp eq i64 %2, 0
  br i1 %11, label %30, label %12

12:                                               ; preds = %6
  %13 = add nsw i64 %2, -1
  %14 = getelementptr inbounds i8, ptr %10, i64 8
  %15 = load i64, ptr %1, align 8, !tbaa !15
  %16 = icmp eq i64 %13, 0
  br i1 %16, label %27, label %17

17:                                               ; preds = %17, %12
  %18 = phi i64 [ %25, %17 ], [ %13, %12 ]
  %19 = phi ptr [ %23, %17 ], [ %14, %12 ]
  %20 = phi ptr [ %22, %17 ], [ %1, %12 ]
  %21 = phi i64 [ %24, %17 ], [ %15, %12 ]
  %22 = getelementptr inbounds i8, ptr %20, i64 8
  %23 = getelementptr inbounds i8, ptr %19, i64 8
  store i64 %21, ptr %19, align 8, !tbaa !15
  %24 = load i64, ptr %22, align 8, !tbaa !15
  %25 = add nsw i64 %18, -1
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %27, label %17, !llvm.loop !398

27:                                               ; preds = %17, %12
  %28 = phi ptr [ %14, %12 ], [ %23, %17 ]
  %29 = phi i64 [ %15, %12 ], [ %24, %17 ]
  store i64 %29, ptr %28, align 8, !tbaa !15
  br label %30

30:                                               ; preds = %27, %6
  store i64 0, ptr %10, align 8, !tbaa !15
  %31 = sub nsw i64 %2, %4
  %32 = shl i64 %31, 3
  %33 = add i64 %32, 8
  %34 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %33) #16
  %35 = call i64 @__gmpn_dcpi1_divappr_q(ptr noundef %34, ptr noundef nonnull %10, i64 noundef %8, ptr noundef %3, i64 noundef %4, ptr noundef %5) #16
  %36 = load i64, ptr %34, align 8, !tbaa !15
  %37 = icmp eq i64 %36, 0
  br i1 %37, label %38, label %132

38:                                               ; preds = %30
  %39 = icmp sgt i64 %31, %4
  %40 = getelementptr inbounds i8, ptr %34, i64 8
  br i1 %39, label %41, label %43

41:                                               ; preds = %38
  %42 = call i64 @__gmpn_mul(ptr noundef nonnull %10, ptr noundef nonnull %40, i64 noundef %31, ptr noundef %3, i64 noundef %4) #16
  br label %45

43:                                               ; preds = %38
  %44 = call i64 @__gmpn_mul(ptr noundef nonnull %10, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %40, i64 noundef %31) #16
  br label %45

45:                                               ; preds = %43, %41
  %46 = icmp eq i64 %35, 0
  br i1 %46, label %51, label %47

47:                                               ; preds = %45
  %48 = getelementptr inbounds i64, ptr %10, i64 %31
  %49 = call i64 @__gmpn_add_n(ptr noundef nonnull %48, ptr noundef nonnull %48, ptr noundef %3, i64 noundef %4) #16
  %50 = icmp eq i64 %49, 0
  br i1 %50, label %51, label %64

51:                                               ; preds = %47, %45
  br label %52

52:                                               ; preds = %55, %51
  %53 = phi i64 [ %56, %55 ], [ %2, %51 ]
  %54 = icmp sgt i64 %53, 0
  br i1 %54, label %55, label %110

55:                                               ; preds = %52
  %56 = add nsw i64 %53, -1
  %57 = getelementptr inbounds i64, ptr %10, i64 %56
  %58 = load i64, ptr %57, align 8, !tbaa !15
  %59 = getelementptr inbounds i64, ptr %1, i64 %56
  %60 = load i64, ptr %59, align 8, !tbaa !15
  %61 = icmp eq i64 %58, %60
  br i1 %61, label %52, label %62, !llvm.loop !399

62:                                               ; preds = %55
  %63 = icmp ugt i64 %58, %60
  br i1 %63, label %64, label %110

64:                                               ; preds = %62, %47
  %65 = getelementptr inbounds i8, ptr %34, i64 8
  %66 = load i64, ptr %65, align 8, !tbaa !15
  %67 = add i64 %66, -1
  store i64 %67, ptr %0, align 8, !tbaa !15
  %68 = icmp eq i64 %66, 0
  br i1 %68, label %69, label %97

69:                                               ; preds = %64
  %70 = call i64 @llvm.smax.i64(i64 %31, i64 1)
  br label %71

71:                                               ; preds = %75, %69
  %72 = phi i64 [ %82, %75 ], [ 0, %69 ]
  %73 = phi i64 [ %80, %75 ], [ 1, %69 ]
  %74 = icmp eq i64 %73, %70
  br i1 %74, label %107, label %75

75:                                               ; preds = %71
  %76 = getelementptr inbounds i64, ptr %65, i64 %73
  %77 = load i64, ptr %76, align 8, !tbaa !15
  %78 = add i64 %77, -1
  %79 = getelementptr inbounds i64, ptr %0, i64 %73
  store i64 %78, ptr %79, align 8, !tbaa !15
  %80 = add nuw i64 %73, 1
  %81 = icmp eq i64 %77, 0
  %82 = add i64 %72, 1
  br i1 %81, label %71, label %83, !llvm.loop !400

83:                                               ; preds = %75
  %84 = icmp ne ptr %65, %0
  %85 = icmp slt i64 %80, %31
  %86 = select i1 %84, i1 %85, i1 false
  br i1 %86, label %87, label %107

87:                                               ; preds = %83
  %88 = shl i64 %72, 3
  %89 = getelementptr i8, ptr %0, i64 %88
  %90 = getelementptr i8, ptr %89, i64 16
  %91 = getelementptr i8, ptr %34, i64 %88
  %92 = getelementptr i8, ptr %91, i64 24
  %93 = add i64 %2, 2305843009213693950
  %94 = add i64 %72, %4
  %95 = sub i64 %93, %94
  %96 = shl i64 %95, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %90, ptr align 8 %92, i64 %96, i1 false), !tbaa !15
  br label %107

97:                                               ; preds = %64
  %98 = icmp ne ptr %65, %0
  %99 = icmp sgt i64 %31, 1
  %100 = and i1 %99, %98
  br i1 %100, label %101, label %107

101:                                              ; preds = %97
  %102 = getelementptr i8, ptr %0, i64 8
  %103 = getelementptr i8, ptr %34, i64 16
  %104 = xor i64 %4, -1
  %105 = add i64 %104, %2
  %106 = shl nuw i64 %105, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %102, ptr align 8 %103, i64 %106, i1 false), !tbaa !15
  br label %107

107:                                              ; preds = %101, %97, %87, %83, %71
  %108 = phi i64 [ 0, %83 ], [ 0, %97 ], [ 0, %87 ], [ 0, %101 ], [ -1, %71 ]
  %109 = add i64 %108, %35
  br label %154

110:                                              ; preds = %62, %52
  %111 = icmp eq i64 %2, %4
  br i1 %111, label %154, label %112

112:                                              ; preds = %110
  %113 = add nsw i64 %31, -1
  %114 = getelementptr inbounds i8, ptr %34, i64 8
  %115 = load i64, ptr %114, align 8, !tbaa !15
  %116 = icmp eq i64 %113, 0
  br i1 %116, label %129, label %117

117:                                              ; preds = %112
  %118 = getelementptr inbounds i8, ptr %34, i64 16
  br label %119

119:                                              ; preds = %119, %117
  %120 = phi i64 [ %127, %119 ], [ %113, %117 ]
  %121 = phi ptr [ %124, %119 ], [ %0, %117 ]
  %122 = phi ptr [ %125, %119 ], [ %118, %117 ]
  %123 = phi i64 [ %126, %119 ], [ %115, %117 ]
  %124 = getelementptr inbounds i8, ptr %121, i64 8
  store i64 %123, ptr %121, align 8, !tbaa !15
  %125 = getelementptr inbounds i8, ptr %122, i64 8
  %126 = load i64, ptr %122, align 8, !tbaa !15
  %127 = add nsw i64 %120, -1
  %128 = icmp eq i64 %127, 0
  br i1 %128, label %129, label %119, !llvm.loop !401

129:                                              ; preds = %119, %112
  %130 = phi ptr [ %0, %112 ], [ %124, %119 ]
  %131 = phi i64 [ %115, %112 ], [ %126, %119 ]
  store i64 %131, ptr %130, align 8, !tbaa !15
  br label %154

132:                                              ; preds = %30
  %133 = icmp eq i64 %2, %4
  br i1 %133, label %154, label %134

134:                                              ; preds = %132
  %135 = add nsw i64 %31, -1
  %136 = getelementptr inbounds i8, ptr %34, i64 8
  %137 = load i64, ptr %136, align 8, !tbaa !15
  %138 = icmp eq i64 %135, 0
  br i1 %138, label %151, label %139

139:                                              ; preds = %134
  %140 = getelementptr inbounds i8, ptr %34, i64 16
  br label %141

141:                                              ; preds = %141, %139
  %142 = phi i64 [ %149, %141 ], [ %135, %139 ]
  %143 = phi ptr [ %146, %141 ], [ %0, %139 ]
  %144 = phi ptr [ %147, %141 ], [ %140, %139 ]
  %145 = phi i64 [ %148, %141 ], [ %137, %139 ]
  %146 = getelementptr inbounds i8, ptr %143, i64 8
  store i64 %145, ptr %143, align 8, !tbaa !15
  %147 = getelementptr inbounds i8, ptr %144, i64 8
  %148 = load i64, ptr %144, align 8, !tbaa !15
  %149 = add nsw i64 %142, -1
  %150 = icmp eq i64 %149, 0
  br i1 %150, label %151, label %141, !llvm.loop !402

151:                                              ; preds = %141, %134
  %152 = phi ptr [ %0, %134 ], [ %146, %141 ]
  %153 = phi i64 [ %137, %134 ], [ %148, %141 ]
  store i64 %153, ptr %152, align 8, !tbaa !15
  br label %154

154:                                              ; preds = %151, %132, %129, %110, %107
  %155 = phi i64 [ %35, %151 ], [ %35, %132 ], [ %109, %107 ], [ %35, %129 ], [ %35, %110 ]
  %156 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %156) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret i64 %155
}

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_mu_div_q_itch(i64 noundef %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #7 {
  %4 = sub nsw i64 %0, %1
  %5 = icmp slt i64 %4, %1
  br i1 %5, label %9, label %6

6:                                                ; preds = %3
  %7 = add nsw i64 %0, 1
  %8 = tail call i64 @__gmpn_mu_divappr_q_itch(i64 noundef %7, i64 noundef %1, i32 noundef %2) #17
  br label %14

9:                                                ; preds = %3
  %10 = shl nsw i64 %4, 1
  %11 = add nsw i64 %10, 2
  %12 = add nsw i64 %4, 1
  %13 = tail call i64 @__gmpn_mu_divappr_q_itch(i64 noundef %11, i64 noundef %12, i32 noundef %2) #17
  br label %14

14:                                               ; preds = %9, %6
  %15 = phi i64 [ %8, %6 ], [ %13, %9 ]
  ret i64 %15
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_mu_div_q(ptr noundef writeonly %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #5 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  store ptr null, ptr %7, align 8, !tbaa !7
  %8 = sub nsw i64 %2, %4
  %9 = add nsw i64 %8, 1
  %10 = shl i64 %9, 3
  %11 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %10) #16
  %12 = icmp slt i64 %8, %4
  br i1 %12, label %178, label %13

13:                                               ; preds = %6
  %14 = add nsw i64 %2, 1
  %15 = shl i64 %14, 3
  %16 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %15) #16
  %17 = icmp eq i64 %2, 0
  br i1 %17, label %36, label %18

18:                                               ; preds = %13
  %19 = add nsw i64 %2, -1
  %20 = getelementptr inbounds i8, ptr %16, i64 8
  %21 = load i64, ptr %1, align 8, !tbaa !15
  %22 = icmp eq i64 %19, 0
  br i1 %22, label %33, label %23

23:                                               ; preds = %23, %18
  %24 = phi ptr [ %29, %23 ], [ %20, %18 ]
  %25 = phi ptr [ %28, %23 ], [ %1, %18 ]
  %26 = phi i64 [ %30, %23 ], [ %21, %18 ]
  %27 = phi i64 [ %31, %23 ], [ %19, %18 ]
  %28 = getelementptr inbounds i8, ptr %25, i64 8
  %29 = getelementptr inbounds i8, ptr %24, i64 8
  store i64 %26, ptr %24, align 8, !tbaa !15
  %30 = load i64, ptr %28, align 8, !tbaa !15
  %31 = add nsw i64 %27, -1
  %32 = icmp eq i64 %31, 0
  br i1 %32, label %33, label %23, !llvm.loop !403

33:                                               ; preds = %23, %18
  %34 = phi ptr [ %20, %18 ], [ %29, %23 ]
  %35 = phi i64 [ %21, %18 ], [ %30, %23 ]
  store i64 %35, ptr %34, align 8, !tbaa !15
  br label %36

36:                                               ; preds = %33, %13
  store i64 0, ptr %16, align 8, !tbaa !15
  %37 = getelementptr inbounds i8, ptr %16, i64 8
  %38 = getelementptr inbounds i64, ptr %37, i64 %2
  %39 = sub i64 0, %4
  %40 = getelementptr inbounds i64, ptr %38, i64 %39
  br label %41

41:                                               ; preds = %44, %36
  %42 = phi i64 [ %4, %36 ], [ %45, %44 ]
  %43 = icmp sgt i64 %42, 0
  br i1 %43, label %44, label %53

44:                                               ; preds = %41
  %45 = add nsw i64 %42, -1
  %46 = getelementptr inbounds i64, ptr %40, i64 %45
  %47 = load i64, ptr %46, align 8, !tbaa !15
  %48 = getelementptr inbounds i64, ptr %3, i64 %45
  %49 = load i64, ptr %48, align 8, !tbaa !15
  %50 = icmp eq i64 %47, %49
  br i1 %50, label %41, label %51, !llvm.loop !404

51:                                               ; preds = %44
  %52 = icmp ugt i64 %47, %49
  br label %53

53:                                               ; preds = %51, %41
  %54 = phi i1 [ %52, %51 ], [ true, %41 ]
  %55 = zext i1 %54 to i64
  br i1 %54, label %56, label %58

56:                                               ; preds = %53
  %57 = call i64 @__gmpn_sub_n(ptr noundef nonnull %40, ptr noundef nonnull %40, ptr noundef %3, i64 noundef %4) #16
  br label %58

58:                                               ; preds = %56, %53
  %59 = call i64 @__gmpn_mu_divappr_q(ptr noundef %11, ptr noundef nonnull %16, i64 noundef %14, ptr noundef %3, i64 noundef %4, ptr noundef %5) #16
  %60 = icmp eq i64 %59, 0
  br i1 %60, label %67, label %61, !prof !68

61:                                               ; preds = %58
  %62 = icmp slt i64 %8, 0
  br i1 %62, label %67, label %63

63:                                               ; preds = %61
  %64 = add i64 %2, 1
  %65 = sub i64 %64, %4
  %66 = shl nuw i64 %65, 3
  call void @llvm.memset.p0.i64(ptr align 8 %11, i8 -1, i64 %66, i1 false), !tbaa !15
  br label %67

67:                                               ; preds = %63, %61, %58
  %68 = load i64, ptr %11, align 8, !tbaa !15
  %69 = icmp ugt i64 %68, 4
  br i1 %69, label %70, label %92

70:                                               ; preds = %67
  %71 = icmp eq i64 %2, %4
  br i1 %71, label %301, label %72

72:                                               ; preds = %70
  %73 = add nsw i64 %8, -1
  %74 = getelementptr inbounds i8, ptr %11, i64 8
  %75 = load i64, ptr %74, align 8, !tbaa !15
  %76 = icmp eq i64 %73, 0
  br i1 %76, label %89, label %77

77:                                               ; preds = %72
  %78 = getelementptr inbounds i8, ptr %11, i64 16
  br label %79

79:                                               ; preds = %79, %77
  %80 = phi i64 [ %87, %79 ], [ %73, %77 ]
  %81 = phi ptr [ %84, %79 ], [ %0, %77 ]
  %82 = phi ptr [ %85, %79 ], [ %78, %77 ]
  %83 = phi i64 [ %86, %79 ], [ %75, %77 ]
  %84 = getelementptr inbounds i8, ptr %81, i64 8
  store i64 %83, ptr %81, align 8, !tbaa !15
  %85 = getelementptr inbounds i8, ptr %82, i64 8
  %86 = load i64, ptr %82, align 8, !tbaa !15
  %87 = add nsw i64 %80, -1
  %88 = icmp eq i64 %87, 0
  br i1 %88, label %89, label %79, !llvm.loop !405

89:                                               ; preds = %79, %72
  %90 = phi ptr [ %0, %72 ], [ %84, %79 ]
  %91 = phi i64 [ %75, %72 ], [ %86, %79 ]
  store i64 %91, ptr %90, align 8, !tbaa !15
  br label %301

92:                                               ; preds = %67
  %93 = getelementptr inbounds i8, ptr %11, i64 8
  %94 = call i64 @__gmpn_mul(ptr noundef nonnull %16, ptr noundef nonnull %93, i64 noundef %8, ptr noundef %3, i64 noundef %4) #16
  br i1 %54, label %95, label %99

95:                                               ; preds = %92
  %96 = getelementptr inbounds i64, ptr %16, i64 %8
  %97 = call i64 @__gmpn_add_n(ptr noundef nonnull %96, ptr noundef nonnull %96, ptr noundef %3, i64 noundef %4) #16
  %98 = icmp eq i64 %97, 0
  br i1 %98, label %99, label %112

99:                                               ; preds = %95, %92
  br label %100

100:                                              ; preds = %103, %99
  %101 = phi i64 [ %104, %103 ], [ %2, %99 ]
  %102 = icmp sgt i64 %101, 0
  br i1 %102, label %103, label %157

103:                                              ; preds = %100
  %104 = add nsw i64 %101, -1
  %105 = getelementptr inbounds i64, ptr %16, i64 %104
  %106 = load i64, ptr %105, align 8, !tbaa !15
  %107 = getelementptr inbounds i64, ptr %1, i64 %104
  %108 = load i64, ptr %107, align 8, !tbaa !15
  %109 = icmp eq i64 %106, %108
  br i1 %109, label %100, label %110, !llvm.loop !404

110:                                              ; preds = %103
  %111 = icmp ugt i64 %106, %108
  br i1 %111, label %112, label %157

112:                                              ; preds = %110, %95
  %113 = load i64, ptr %93, align 8, !tbaa !15
  %114 = add i64 %113, -1
  store i64 %114, ptr %0, align 8, !tbaa !15
  %115 = icmp eq i64 %113, 0
  br i1 %115, label %116, label %144

116:                                              ; preds = %112
  %117 = call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %118

118:                                              ; preds = %122, %116
  %119 = phi i64 [ %129, %122 ], [ 0, %116 ]
  %120 = phi i64 [ %127, %122 ], [ 1, %116 ]
  %121 = icmp eq i64 %120, %117
  br i1 %121, label %154, label %122

122:                                              ; preds = %118
  %123 = getelementptr inbounds i64, ptr %93, i64 %120
  %124 = load i64, ptr %123, align 8, !tbaa !15
  %125 = add i64 %124, -1
  %126 = getelementptr inbounds i64, ptr %0, i64 %120
  store i64 %125, ptr %126, align 8, !tbaa !15
  %127 = add nuw i64 %120, 1
  %128 = icmp eq i64 %124, 0
  %129 = add i64 %119, 1
  br i1 %128, label %118, label %130, !llvm.loop !406

130:                                              ; preds = %122
  %131 = icmp ne ptr %93, %0
  %132 = icmp slt i64 %127, %8
  %133 = select i1 %131, i1 %132, i1 false
  br i1 %133, label %134, label %154

134:                                              ; preds = %130
  %135 = shl i64 %119, 3
  %136 = getelementptr i8, ptr %0, i64 %135
  %137 = getelementptr i8, ptr %136, i64 16
  %138 = getelementptr i8, ptr %11, i64 %135
  %139 = getelementptr i8, ptr %138, i64 24
  %140 = add i64 %2, 2305843009213693950
  %141 = add i64 %119, %4
  %142 = sub i64 %140, %141
  %143 = shl i64 %142, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %137, ptr align 8 %139, i64 %143, i1 false), !tbaa !15
  br label %154

144:                                              ; preds = %112
  %145 = icmp ne ptr %93, %0
  %146 = icmp sgt i64 %8, 1
  %147 = and i1 %146, %145
  br i1 %147, label %148, label %154

148:                                              ; preds = %144
  %149 = getelementptr i8, ptr %0, i64 8
  %150 = getelementptr i8, ptr %11, i64 16
  %151 = xor i64 %4, -1
  %152 = add i64 %151, %2
  %153 = shl nuw i64 %152, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %149, ptr align 8 %150, i64 %153, i1 false), !tbaa !15
  br label %154

154:                                              ; preds = %148, %144, %134, %130, %118
  %155 = phi i64 [ 0, %130 ], [ 0, %144 ], [ 0, %134 ], [ 0, %148 ], [ -1, %118 ]
  %156 = add nsw i64 %155, %55
  br label %301

157:                                              ; preds = %110, %100
  %158 = icmp eq i64 %2, %4
  br i1 %158, label %301, label %159

159:                                              ; preds = %157
  %160 = add nsw i64 %8, -1
  %161 = load i64, ptr %93, align 8, !tbaa !15
  %162 = icmp eq i64 %160, 0
  br i1 %162, label %175, label %163

163:                                              ; preds = %159
  %164 = getelementptr inbounds i8, ptr %11, i64 16
  br label %165

165:                                              ; preds = %165, %163
  %166 = phi i64 [ %173, %165 ], [ %160, %163 ]
  %167 = phi ptr [ %170, %165 ], [ %0, %163 ]
  %168 = phi ptr [ %171, %165 ], [ %164, %163 ]
  %169 = phi i64 [ %172, %165 ], [ %161, %163 ]
  %170 = getelementptr inbounds i8, ptr %167, i64 8
  store i64 %169, ptr %167, align 8, !tbaa !15
  %171 = getelementptr inbounds i8, ptr %168, i64 8
  %172 = load i64, ptr %168, align 8, !tbaa !15
  %173 = add nsw i64 %166, -1
  %174 = icmp eq i64 %173, 0
  br i1 %174, label %175, label %165, !llvm.loop !407

175:                                              ; preds = %165, %159
  %176 = phi ptr [ %0, %159 ], [ %170, %165 ]
  %177 = phi i64 [ %161, %159 ], [ %172, %165 ]
  store i64 %177, ptr %176, align 8, !tbaa !15
  br label %301

178:                                              ; preds = %6
  %179 = getelementptr inbounds i64, ptr %1, i64 %2
  %180 = shl nsw i64 %8, 1
  %181 = add nsw i64 %180, 2
  %182 = sub nuw nsw i64 -2, %180
  %183 = getelementptr inbounds i64, ptr %179, i64 %182
  %184 = getelementptr inbounds i64, ptr %3, i64 %4
  %185 = xor i64 %8, -1
  %186 = getelementptr inbounds i64, ptr %184, i64 %185
  %187 = call i64 @__gmpn_mu_divappr_q(ptr noundef %11, ptr noundef %183, i64 noundef %181, ptr noundef %186, i64 noundef %9, ptr noundef %5) #16
  %188 = load i64, ptr %11, align 8, !tbaa !15
  %189 = icmp ugt i64 %188, 6
  br i1 %189, label %190, label %212

190:                                              ; preds = %178
  %191 = icmp eq i64 %2, %4
  br i1 %191, label %301, label %192

192:                                              ; preds = %190
  %193 = add nsw i64 %8, -1
  %194 = getelementptr inbounds i8, ptr %11, i64 8
  %195 = load i64, ptr %194, align 8, !tbaa !15
  %196 = icmp eq i64 %193, 0
  br i1 %196, label %209, label %197

197:                                              ; preds = %192
  %198 = getelementptr inbounds i8, ptr %11, i64 16
  br label %199

199:                                              ; preds = %199, %197
  %200 = phi i64 [ %207, %199 ], [ %193, %197 ]
  %201 = phi ptr [ %204, %199 ], [ %0, %197 ]
  %202 = phi ptr [ %205, %199 ], [ %198, %197 ]
  %203 = phi i64 [ %206, %199 ], [ %195, %197 ]
  %204 = getelementptr inbounds i8, ptr %201, i64 8
  store i64 %203, ptr %201, align 8, !tbaa !15
  %205 = getelementptr inbounds i8, ptr %202, i64 8
  %206 = load i64, ptr %202, align 8, !tbaa !15
  %207 = add nsw i64 %200, -1
  %208 = icmp eq i64 %207, 0
  br i1 %208, label %209, label %199, !llvm.loop !408

209:                                              ; preds = %199, %192
  %210 = phi ptr [ %0, %192 ], [ %204, %199 ]
  %211 = phi i64 [ %195, %192 ], [ %206, %199 ]
  store i64 %211, ptr %210, align 8, !tbaa !15
  br label %301

212:                                              ; preds = %178
  %213 = shl i64 %2, 3
  %214 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %213) #16
  %215 = getelementptr inbounds i8, ptr %11, i64 8
  %216 = call i64 @__gmpn_mul(ptr noundef %214, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %215, i64 noundef %8) #16
  %217 = icmp eq i64 %187, 0
  br i1 %217, label %222, label %218

218:                                              ; preds = %212
  %219 = getelementptr inbounds i64, ptr %214, i64 %8
  %220 = call i64 @__gmpn_add_n(ptr noundef %219, ptr noundef %219, ptr noundef %3, i64 noundef %4) #16
  %221 = icmp eq i64 %220, 0
  br i1 %221, label %222, label %235

222:                                              ; preds = %218, %212
  br label %223

223:                                              ; preds = %226, %222
  %224 = phi i64 [ %227, %226 ], [ %2, %222 ]
  %225 = icmp sgt i64 %224, 0
  br i1 %225, label %226, label %280

226:                                              ; preds = %223
  %227 = add nsw i64 %224, -1
  %228 = getelementptr inbounds i64, ptr %214, i64 %227
  %229 = load i64, ptr %228, align 8, !tbaa !15
  %230 = getelementptr inbounds i64, ptr %1, i64 %227
  %231 = load i64, ptr %230, align 8, !tbaa !15
  %232 = icmp eq i64 %229, %231
  br i1 %232, label %223, label %233, !llvm.loop !404

233:                                              ; preds = %226
  %234 = icmp ugt i64 %229, %231
  br i1 %234, label %235, label %280

235:                                              ; preds = %233, %218
  %236 = load i64, ptr %215, align 8, !tbaa !15
  %237 = add i64 %236, -1
  store i64 %237, ptr %0, align 8, !tbaa !15
  %238 = icmp eq i64 %236, 0
  br i1 %238, label %239, label %267

239:                                              ; preds = %235
  %240 = call i64 @llvm.smax.i64(i64 %8, i64 1)
  br label %241

241:                                              ; preds = %245, %239
  %242 = phi i64 [ %252, %245 ], [ 0, %239 ]
  %243 = phi i64 [ %250, %245 ], [ 1, %239 ]
  %244 = icmp eq i64 %243, %240
  br i1 %244, label %277, label %245

245:                                              ; preds = %241
  %246 = getelementptr inbounds i64, ptr %215, i64 %243
  %247 = load i64, ptr %246, align 8, !tbaa !15
  %248 = add i64 %247, -1
  %249 = getelementptr inbounds i64, ptr %0, i64 %243
  store i64 %248, ptr %249, align 8, !tbaa !15
  %250 = add nuw i64 %243, 1
  %251 = icmp eq i64 %247, 0
  %252 = add i64 %242, 1
  br i1 %251, label %241, label %253, !llvm.loop !406

253:                                              ; preds = %245
  %254 = icmp ne ptr %215, %0
  %255 = icmp slt i64 %250, %8
  %256 = select i1 %254, i1 %255, i1 false
  br i1 %256, label %257, label %277

257:                                              ; preds = %253
  %258 = shl i64 %242, 3
  %259 = getelementptr i8, ptr %0, i64 %258
  %260 = getelementptr i8, ptr %259, i64 16
  %261 = getelementptr i8, ptr %11, i64 %258
  %262 = getelementptr i8, ptr %261, i64 24
  %263 = add i64 %2, 2305843009213693950
  %264 = add i64 %242, %4
  %265 = sub i64 %263, %264
  %266 = shl i64 %265, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %260, ptr align 8 %262, i64 %266, i1 false), !tbaa !15
  br label %277

267:                                              ; preds = %235
  %268 = icmp ne ptr %215, %0
  %269 = icmp sgt i64 %8, 1
  %270 = and i1 %269, %268
  br i1 %270, label %271, label %277

271:                                              ; preds = %267
  %272 = getelementptr i8, ptr %0, i64 8
  %273 = getelementptr i8, ptr %11, i64 16
  %274 = xor i64 %4, -1
  %275 = add i64 %274, %2
  %276 = shl nuw i64 %275, 3
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %272, ptr align 8 %273, i64 %276, i1 false), !tbaa !15
  br label %277

277:                                              ; preds = %271, %267, %257, %253, %241
  %278 = phi i64 [ 0, %253 ], [ 0, %267 ], [ 0, %257 ], [ 0, %271 ], [ -1, %241 ]
  %279 = add i64 %278, %187
  br label %301

280:                                              ; preds = %233, %223
  %281 = icmp eq i64 %2, %4
  br i1 %281, label %301, label %282

282:                                              ; preds = %280
  %283 = add nsw i64 %8, -1
  %284 = load i64, ptr %215, align 8, !tbaa !15
  %285 = icmp eq i64 %283, 0
  br i1 %285, label %298, label %286

286:                                              ; preds = %282
  %287 = getelementptr inbounds i8, ptr %11, i64 16
  br label %288

288:                                              ; preds = %288, %286
  %289 = phi i64 [ %296, %288 ], [ %283, %286 ]
  %290 = phi ptr [ %293, %288 ], [ %0, %286 ]
  %291 = phi ptr [ %294, %288 ], [ %287, %286 ]
  %292 = phi i64 [ %295, %288 ], [ %284, %286 ]
  %293 = getelementptr inbounds i8, ptr %290, i64 8
  store i64 %292, ptr %290, align 8, !tbaa !15
  %294 = getelementptr inbounds i8, ptr %291, i64 8
  %295 = load i64, ptr %291, align 8, !tbaa !15
  %296 = add nsw i64 %289, -1
  %297 = icmp eq i64 %296, 0
  br i1 %297, label %298, label %288, !llvm.loop !409

298:                                              ; preds = %288, %282
  %299 = phi ptr [ %0, %282 ], [ %293, %288 ]
  %300 = phi i64 [ %284, %282 ], [ %295, %288 ]
  store i64 %300, ptr %299, align 8, !tbaa !15
  br label %301

301:                                              ; preds = %298, %280, %277, %209, %190, %175, %157, %154, %89, %70
  %302 = phi i64 [ %55, %89 ], [ %55, %70 ], [ %187, %209 ], [ %187, %190 ], [ %156, %154 ], [ %55, %175 ], [ %55, %157 ], [ %279, %277 ], [ %187, %298 ], [ %187, %280 ]
  %303 = load ptr, ptr %7, align 8, !tbaa !7
  call void @__gmp_tmp_reentrant_free(ptr noundef %303) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret i64 %302
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define range(i64 0, 2) i64 @__gmpn_sub_1(ptr noundef writeonly %0, ptr noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #12 {
  %5 = load i64, ptr %1, align 8, !tbaa !15
  %6 = sub i64 %5, %3
  store i64 %6, ptr %0, align 8, !tbaa !15
  %7 = icmp ult i64 %5, %3
  br i1 %7, label %8, label %31

8:                                                ; preds = %4
  %9 = tail call i64 @llvm.smax.i64(i64 %2, i64 1)
  br label %10

10:                                               ; preds = %13, %8
  %11 = phi i64 [ %18, %13 ], [ 1, %8 ]
  %12 = icmp eq i64 %11, %9
  br i1 %12, label %42, label %13

13:                                               ; preds = %10
  %14 = getelementptr inbounds i64, ptr %1, i64 %11
  %15 = load i64, ptr %14, align 8, !tbaa !15
  %16 = add i64 %15, -1
  %17 = getelementptr inbounds i64, ptr %0, i64 %11
  store i64 %16, ptr %17, align 8, !tbaa !15
  %18 = add nuw i64 %11, 1
  %19 = icmp eq i64 %15, 0
  br i1 %19, label %10, label %20, !llvm.loop !410

20:                                               ; preds = %13
  %21 = icmp ne ptr %1, %0
  %22 = icmp slt i64 %18, %2
  %23 = select i1 %21, i1 %22, i1 false
  br i1 %23, label %24, label %42

24:                                               ; preds = %24, %20
  %25 = phi i64 [ %29, %24 ], [ %18, %20 ]
  %26 = getelementptr inbounds i64, ptr %1, i64 %25
  %27 = load i64, ptr %26, align 8, !tbaa !15
  %28 = getelementptr inbounds i64, ptr %0, i64 %25
  store i64 %27, ptr %28, align 8, !tbaa !15
  %29 = add nuw nsw i64 %25, 1
  %30 = icmp slt i64 %29, %2
  br i1 %30, label %24, label %42, !llvm.loop !411

31:                                               ; preds = %4
  %32 = icmp ne ptr %1, %0
  %33 = icmp sgt i64 %2, 1
  %34 = and i1 %32, %33
  br i1 %34, label %35, label %42

35:                                               ; preds = %35, %31
  %36 = phi i64 [ %40, %35 ], [ 1, %31 ]
  %37 = getelementptr inbounds i64, ptr %1, i64 %36
  %38 = load i64, ptr %37, align 8, !tbaa !15
  %39 = getelementptr inbounds i64, ptr %0, i64 %36
  store i64 %38, ptr %39, align 8, !tbaa !15
  %40 = add nuw nsw i64 %36, 1
  %41 = icmp eq i64 %40, %2
  br i1 %41, label %42, label %35, !llvm.loop !412

42:                                               ; preds = %35, %31, %24, %20, %10
  %43 = phi i64 [ 0, %20 ], [ 0, %31 ], [ 0, %24 ], [ 1, %10 ], [ 0, %35 ]
  ret i64 %43
}

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #4 = { cold noreturn nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #5 = { nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #6 = { nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #7 = { mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #8 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #9 = { inlinehint nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #10 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #11 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #12 = { nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #13 = { noreturn nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #14 = { nofree nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #15 = { nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #16 = { nounwind }
attributes #17 = { nounwind willreturn memory(none) }
attributes #18 = { noreturn nounwind }
attributes #19 = { nounwind willreturn memory(read) }
attributes #20 = { cold noreturn nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{!8, !8, i64 0}
!8 = !{!"any pointer", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!12, !13, i64 8}
!12 = !{!"tmp_reentrant_t", !8, i64 0, !13, i64 8}
!13 = !{!"long", !9, i64 0}
!14 = !{!12, !8, i64 0}
!15 = !{!13, !13, i64 0}
!16 = distinct !{!16, !17, !18}
!17 = !{!"llvm.loop.mustprogress"}
!18 = !{!"llvm.loop.unroll.disable"}
!19 = distinct !{!19, !17, !18}
!20 = distinct !{!20, !17, !18}
!21 = distinct !{!21, !17, !18}
!22 = distinct !{!22, !17, !18}
!23 = distinct !{!23, !17, !18}
!24 = distinct !{!24, !17, !18}
!25 = distinct !{!25, !17, !18}
!26 = distinct !{!26, !17, !18}
!27 = distinct !{!27, !17, !18}
!28 = distinct !{!28, !17, !18}
!29 = distinct !{!29, !17, !18}
!30 = distinct !{!30, !17, !18}
!31 = distinct !{!31, !17, !18}
!32 = distinct !{!32, !17, !18}
!33 = distinct !{!33, !17, !18}
!34 = distinct !{!34, !17, !18}
!35 = distinct !{!35, !17, !18}
!36 = distinct !{!36, !17, !18}
!37 = distinct !{!37, !17, !18}
!38 = distinct !{!38, !17, !18}
!39 = distinct !{!39, !17, !18}
!40 = distinct !{!40, !17, !18}
!41 = distinct !{!41, !17, !18}
!42 = distinct !{!42, !17, !18}
!43 = distinct !{!43, !17, !18}
!44 = distinct !{!44, !17, !18}
!45 = distinct !{!45, !17, !18}
!46 = distinct !{!46, !17, !18}
!47 = distinct !{!47, !17, !18}
!48 = distinct !{!48, !17, !18}
!49 = distinct !{!49, !17, !18}
!50 = distinct !{!50, !17, !18}
!51 = distinct !{!51, !17, !18}
!52 = distinct !{!52, !17, !18}
!53 = distinct !{!53, !17, !18}
!54 = !{!"branch_weights", !"expected", i32 1, i32 2000}
!55 = distinct !{!55, !17, !18}
!56 = distinct !{!56, !17, !18}
!57 = distinct !{!57, !17, !18}
!58 = distinct !{!58, !17, !18}
!59 = distinct !{!59, !17, !18}
!60 = distinct !{!60, !17, !18}
!61 = distinct !{!61, !17, !18}
!62 = distinct !{!62, !17, !18}
!63 = distinct !{!63, !17, !18}
!64 = distinct !{!64, !17, !18}
!65 = distinct !{!65, !17, !18}
!66 = distinct !{!66, !17, !18}
!67 = distinct !{!67, !17, !18}
!68 = !{!"branch_weights", !"expected", i32 2000, i32 1}
!69 = distinct !{!69, !17, !18}
!70 = distinct !{!70, !17, !18}
!71 = distinct !{!71, !17, !18}
!72 = distinct !{!72, !17, !18}
!73 = distinct !{!73, !17, !18}
!74 = distinct !{!74, !17, !18}
!75 = distinct !{!75, !17, !18}
!76 = distinct !{!76, !17, !18}
!77 = distinct !{!77, !17, !18}
!78 = distinct !{!78, !17, !18}
!79 = distinct !{!79, !17, !18}
!80 = distinct !{!80, !17, !18}
!81 = distinct !{!81, !17, !18}
!82 = distinct !{!82, !17, !18}
!83 = distinct !{!83, !17, !18}
!84 = distinct !{!84, !17, !18}
!85 = distinct !{!85, !17, !18}
!86 = distinct !{!86, !17, !18}
!87 = distinct !{!87, !17, !18}
!88 = distinct !{!88, !17, !18}
!89 = distinct !{!89, !17, !18}
!90 = distinct !{!90, !17, !18}
!91 = distinct !{!91, !17, !18}
!92 = distinct !{!92, !17, !18}
!93 = distinct !{!93, !17, !18}
!94 = distinct !{!94, !17, !18}
!95 = distinct !{!95, !17, !18}
!96 = distinct !{!96, !17, !18}
!97 = distinct !{!97, !17, !18}
!98 = distinct !{!98, !17, !18}
!99 = distinct !{!99, !17, !18}
!100 = distinct !{!100, !17, !18}
!101 = distinct !{!101, !17, !18}
!102 = distinct !{!102, !17, !18}
!103 = distinct !{!103, !17, !18}
!104 = distinct !{!104, !17, !18}
!105 = distinct !{!105, !17, !18}
!106 = distinct !{!106, !17, !18}
!107 = distinct !{!107, !17, !18}
!108 = distinct !{!108, !17, !18}
!109 = distinct !{!109, !17, !18}
!110 = distinct !{!110, !17, !18}
!111 = distinct !{!111, !17, !18}
!112 = distinct !{!112, !17, !18}
!113 = distinct !{!113, !17, !18}
!114 = distinct !{!114, !17, !18}
!115 = distinct !{!115, !17, !18}
!116 = distinct !{!116, !17, !18}
!117 = distinct !{!117, !17, !18}
!118 = distinct !{!118, !17, !18}
!119 = distinct !{!119, !17, !18}
!120 = distinct !{!120, !17, !18}
!121 = distinct !{!121, !17, !18}
!122 = distinct !{!122, !17, !18}
!123 = distinct !{!123, !17, !18}
!124 = !{!125, !125, i64 0}
!125 = !{!"int", !9, i64 0}
!126 = distinct !{!126, !17, !18}
!127 = distinct !{!127, !17, !18}
!128 = distinct !{!128, !17, !18}
!129 = distinct !{!129, !18}
!130 = distinct !{!130, !17, !18}
!131 = distinct !{!131, !17, !18}
!132 = distinct !{!132, !17, !18}
!133 = distinct !{!133, !17, !18}
!134 = distinct !{!134, !17, !18}
!135 = distinct !{!135, !17, !18}
!136 = distinct !{!136, !17, !18}
!137 = distinct !{!137, !17, !18}
!138 = distinct !{!138, !17, !18}
!139 = distinct !{!139, !17, !18}
!140 = distinct !{!140, !17, !18}
!141 = distinct !{!141, !17, !18}
!142 = distinct !{!142, !17, !18}
!143 = distinct !{!143, !17, !18}
!144 = distinct !{!144, !18}
!145 = distinct !{!145, !17, !18}
!146 = distinct !{!146, !17, !18}
!147 = distinct !{!147, !17, !18}
!148 = !{!"branch_weights", i32 0, i32 -382854991, i32 1955078, i32 977, i32 0}
!149 = distinct !{!149, !17, !18}
!150 = distinct !{!150, !17, !18}
!151 = distinct !{!151, !17, !18}
!152 = distinct !{!152, !17, !18}
!153 = distinct !{!153, !17, !18}
!154 = distinct !{!154, !17, !18}
!155 = !{!9, !9, i64 0}
!156 = distinct !{!156, !17, !18}
!157 = distinct !{!157, !17, !18}
!158 = distinct !{!158, !17, !18}
!159 = distinct !{!159, !17, !18}
!160 = distinct !{!160, !17, !18}
!161 = distinct !{!161, !17, !18}
!162 = distinct !{!162, !17, !18}
!163 = distinct !{!163, !17, !18}
!164 = distinct !{!164, !18}
!165 = distinct !{!165, !17, !18}
!166 = distinct !{!166, !17, !18}
!167 = distinct !{!167, !17, !18}
!168 = distinct !{!168, !17, !18}
!169 = distinct !{!169, !17, !18}
!170 = distinct !{!170, !17, !18}
!171 = distinct !{!171, !17, !18}
!172 = distinct !{!172, !17, !18}
!173 = distinct !{!173, !17, !18}
!174 = distinct !{!174, !17, !18}
!175 = distinct !{!175, !17, !18}
!176 = distinct !{!176, !17, !18}
!177 = distinct !{!177, !17, !18}
!178 = distinct !{!178, !17, !18}
!179 = distinct !{!179, !17, !18}
!180 = distinct !{!180, !17, !18}
!181 = distinct !{!181, !17, !18}
!182 = distinct !{!182, !17, !18}
!183 = distinct !{!183, !17, !18}
!184 = distinct !{!184, !17, !18}
!185 = distinct !{!185, !17, !18}
!186 = distinct !{!186, !17, !18}
!187 = distinct !{!187, !17, !18}
!188 = distinct !{!188, !17, !18}
!189 = distinct !{!189, !17, !18}
!190 = distinct !{!190, !17, !18}
!191 = distinct !{!191, !17, !18}
!192 = distinct !{!192, !17, !18}
!193 = distinct !{!193, !17, !18}
!194 = distinct !{!194, !17, !18}
!195 = distinct !{!195, !17, !18}
!196 = distinct !{!196, !17, !18}
!197 = distinct !{!197, !17, !18}
!198 = distinct !{!198, !17, !18}
!199 = distinct !{!199, !17, !18}
!200 = distinct !{!200, !17, !18}
!201 = distinct !{!201, !17, !18}
!202 = distinct !{!202, !17, !18}
!203 = distinct !{!203, !17, !18}
!204 = distinct !{!204, !17, !18}
!205 = distinct !{!205, !17, !18}
!206 = distinct !{!206, !17, !18}
!207 = distinct !{!207, !17, !18}
!208 = distinct !{!208, !17, !18}
!209 = distinct !{!209, !17, !18}
!210 = distinct !{!210, !17, !18}
!211 = distinct !{!211, !17, !18}
!212 = distinct !{!212, !17, !18}
!213 = distinct !{!213, !17, !18}
!214 = distinct !{!214, !17, !18}
!215 = distinct !{!215, !17, !18}
!216 = distinct !{!216, !17, !18}
!217 = distinct !{!217, !17, !18}
!218 = distinct !{!218, !17, !18}
!219 = distinct !{!219, !17, !18}
!220 = distinct !{!220, !17, !18}
!221 = distinct !{!221, !17, !18}
!222 = distinct !{!222, !17, !18}
!223 = distinct !{!223, !17, !18}
!224 = distinct !{!224, !17, !18}
!225 = distinct !{!225, !17, !18}
!226 = distinct !{!226, !17, !18}
!227 = distinct !{!227, !17, !18}
!228 = distinct !{!228, !17, !18}
!229 = distinct !{!229, !17, !18}
!230 = distinct !{!230, !17, !18}
!231 = distinct !{!231, !17, !18}
!232 = distinct !{!232, !17, !18}
!233 = distinct !{!233, !17, !18}
!234 = distinct !{!234, !17, !18}
!235 = distinct !{!235, !17, !18}
!236 = distinct !{!236, !17, !18}
!237 = distinct !{!237, !17, !18}
!238 = distinct !{!238, !17, !18}
!239 = distinct !{!239, !17, !18}
!240 = distinct !{!240, !17, !18}
!241 = distinct !{!241, !17, !18}
!242 = distinct !{!242, !17, !18}
!243 = distinct !{!243, !17, !18}
!244 = distinct !{!244, !17, !18}
!245 = distinct !{!245, !17, !18}
!246 = distinct !{!246, !17, !18}
!247 = distinct !{!247, !17, !18}
!248 = distinct !{!248, !17, !18}
!249 = distinct !{!249, !17, !18}
!250 = distinct !{!250, !17, !18}
!251 = distinct !{!251, !17, !18}
!252 = distinct !{!252, !17, !18}
!253 = distinct !{!253, !17, !18}
!254 = distinct !{!254, !17, !18}
!255 = distinct !{!255, !17, !18}
!256 = distinct !{!256, !17, !18}
!257 = distinct !{!257, !17, !18}
!258 = distinct !{!258, !17, !18}
!259 = distinct !{!259, !17, !18}
!260 = distinct !{!260, !17, !18}
!261 = distinct !{!261, !17, !18}
!262 = distinct !{!262, !17, !18}
!263 = distinct !{!263, !17, !18}
!264 = distinct !{!264, !17, !18}
!265 = distinct !{!265, !17, !18}
!266 = distinct !{!266, !17, !18}
!267 = distinct !{!267, !17, !18}
!268 = distinct !{!268, !17, !18}
!269 = distinct !{!269, !17, !18}
!270 = distinct !{!270, !17, !18}
!271 = distinct !{!271, !17, !18}
!272 = distinct !{!272, !17, !18}
!273 = distinct !{!273, !17, !18}
!274 = distinct !{!274, !17, !18}
!275 = distinct !{!275, !17, !18}
!276 = distinct !{!276, !17, !18}
!277 = distinct !{!277, !17, !18}
!278 = distinct !{!278, !17, !18}
!279 = distinct !{!279, !17, !18}
!280 = distinct !{!280, !17, !18}
!281 = distinct !{!281, !17, !18}
!282 = distinct !{!282, !17, !18}
!283 = distinct !{!283, !17, !18}
!284 = distinct !{!284, !17, !18}
!285 = distinct !{!285, !17, !18}
!286 = distinct !{!286, !17, !18}
!287 = distinct !{!287, !17, !18}
!288 = distinct !{!288, !17, !18}
!289 = distinct !{!289, !17, !18}
!290 = distinct !{!290, !17, !18}
!291 = distinct !{!291, !17, !18}
!292 = distinct !{!292, !17, !18}
!293 = distinct !{!293, !17, !18}
!294 = distinct !{!294, !17, !18}
!295 = distinct !{!295, !17, !18}
!296 = distinct !{!296, !17, !18}
!297 = distinct !{!297, !17, !18}
!298 = distinct !{!298, !17, !18}
!299 = distinct !{!299, !17, !18}
!300 = distinct !{!300, !17, !18}
!301 = distinct !{!301, !17, !18}
!302 = distinct !{!302, !17, !18}
!303 = distinct !{!303, !17, !18}
!304 = distinct !{!304, !17, !18}
!305 = distinct !{!305, !17, !18}
!306 = distinct !{!306, !17, !18}
!307 = distinct !{!307, !17, !18}
!308 = distinct !{!308, !17, !18}
!309 = distinct !{!309, !17, !18}
!310 = distinct !{!310, !17, !18}
!311 = distinct !{!311, !17, !18}
!312 = distinct !{!312, !17, !18}
!313 = distinct !{!313, !17, !18}
!314 = distinct !{!314, !17, !18}
!315 = distinct !{!315, !17, !18}
!316 = distinct !{!316, !17, !18}
!317 = distinct !{!317, !17, !18}
!318 = distinct !{!318, !17, !18}
!319 = distinct !{!319, !17, !18}
!320 = distinct !{!320, !17, !18}
!321 = distinct !{!321, !17, !18}
!322 = distinct !{!322, !17, !18}
!323 = distinct !{!323, !17, !18}
!324 = distinct !{!324, !17, !18}
!325 = distinct !{!325, !17, !18}
!326 = distinct !{!326, !17, !18}
!327 = distinct !{!327, !17, !18}
!328 = distinct !{!328, !17, !18}
!329 = distinct !{!329, !17, !18}
!330 = distinct !{!330, !17, !18}
!331 = distinct !{!331, !17, !18}
!332 = distinct !{!332, !17, !18}
!333 = distinct !{!333, !17, !18}
!334 = distinct !{!334, !17, !18}
!335 = distinct !{!335, !17, !18}
!336 = distinct !{!336, !17, !18}
!337 = distinct !{!337, !17, !18}
!338 = distinct !{!338, !17, !18}
!339 = distinct !{!339, !17, !18}
!340 = distinct !{!340, !17, !18}
!341 = distinct !{!341, !17, !18}
!342 = distinct !{!342, !17, !18}
!343 = distinct !{!343, !17, !18}
!344 = distinct !{!344, !17, !18}
!345 = distinct !{!345, !17, !18}
!346 = distinct !{!346, !17, !18}
!347 = distinct !{!347, !17, !18}
!348 = distinct !{!348, !17, !18}
!349 = distinct !{!349, !17, !18}
!350 = distinct !{!350, !17, !18}
!351 = distinct !{!351, !17, !18}
!352 = distinct !{!352, !17, !18}
!353 = distinct !{!353, !18}
!354 = distinct !{!354, !17, !18}
!355 = distinct !{!355, !17, !18}
!356 = distinct !{!356, !17, !18}
!357 = !{!358, !13, i64 0}
!358 = !{!"", !13, i64 0}
!359 = distinct !{!359, !17, !18}
!360 = distinct !{!360, !17, !18}
!361 = distinct !{!361, !17, !18}
!362 = distinct !{!362, !17, !18}
!363 = distinct !{!363, !17, !18}
!364 = distinct !{!364, !17, !18}
!365 = distinct !{!365, !17, !18}
!366 = distinct !{!366, !17, !18}
!367 = distinct !{!367, !17, !18}
!368 = distinct !{!368, !17, !18}
!369 = distinct !{!369, !17, !18}
!370 = distinct !{!370, !17, !18}
!371 = distinct !{!371, !17, !18}
!372 = distinct !{!372, !17, !18}
!373 = distinct !{!373, !17, !18}
!374 = distinct !{!374, !17, !18}
!375 = distinct !{!375, !17, !18}
!376 = distinct !{!376, !17, !18}
!377 = distinct !{!377, !17, !18}
!378 = distinct !{!378, !17, !18}
!379 = distinct !{!379, !17, !18}
!380 = distinct !{!380, !17, !18}
!381 = distinct !{!381, !17, !18}
!382 = distinct !{!382, !17, !18}
!383 = distinct !{!383, !18}
!384 = distinct !{!384, !17, !18}
!385 = distinct !{!385, !17, !18}
!386 = distinct !{!386, !17, !18}
!387 = distinct !{!387, !17, !18}
!388 = distinct !{!388, !17, !18}
!389 = distinct !{!389, !17, !18}
!390 = distinct !{!390, !17, !18}
!391 = distinct !{!391, !17, !18}
!392 = distinct !{!392, !17, !18}
!393 = distinct !{!393, !17, !18}
!394 = distinct !{!394, !17, !18}
!395 = distinct !{!395, !17, !18}
!396 = distinct !{!396, !17, !18}
!397 = distinct !{!397, !17, !18}
!398 = distinct !{!398, !17, !18}
!399 = distinct !{!399, !17, !18}
!400 = distinct !{!400, !17, !18}
!401 = distinct !{!401, !17, !18}
!402 = distinct !{!402, !17, !18}
!403 = distinct !{!403, !17, !18}
!404 = distinct !{!404, !17, !18}
!405 = distinct !{!405, !17, !18}
!406 = distinct !{!406, !17, !18}
!407 = distinct !{!407, !17, !18}
!408 = distinct !{!408, !17, !18}
!409 = distinct !{!409, !17, !18}
!410 = distinct !{!410, !17, !18}
!411 = distinct !{!411, !17, !18}
!412 = distinct !{!412, !17, !18}
