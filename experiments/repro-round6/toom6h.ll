; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/experiments/gmp/build/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

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
@__gmp_binvert_limb_table = external local_unnamed_addr constant [128 x i8], align 16
@__stderrp = external local_unnamed_addr global ptr, align 8
@__gmp_allocate_func = external local_unnamed_addr global ptr, align 8
@__gmp_free_func = external local_unnamed_addr global ptr, align 8
@__gmpn_clz_tab = external local_unnamed_addr constant [129 x i8], align 16

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.usub.sat.i64(i64, i64) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom53_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #15
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
  store ptr null, ptr %7, align 8, !tbaa !5
  %20 = add nuw nsw i64 %14, 2
  %21 = mul i64 %20, 80
  %22 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %21) #15
  %23 = getelementptr inbounds i64, ptr %22, i64 %20
  %24 = getelementptr inbounds i64, ptr %23, i64 %20
  %25 = getelementptr inbounds i64, ptr %24, i64 %20
  %26 = getelementptr inbounds i64, ptr %25, i64 %20
  %27 = getelementptr inbounds i64, ptr %26, i64 %20
  %28 = getelementptr inbounds i64, ptr %27, i64 %20
  %29 = getelementptr inbounds i64, ptr %28, i64 %20
  %30 = getelementptr inbounds i64, ptr %29, i64 %20
  %31 = getelementptr inbounds i64, ptr %30, i64 %20
  %32 = call i32 @__gmpn_toom_eval_pm1(ptr noundef %22, ptr noundef nonnull %23, i32 noundef 4, ptr noundef %1, i64 noundef %15, i64 noundef %17, ptr noundef %0) #15
  %33 = and i32 %32, 2
  %34 = call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %24, ptr noundef nonnull %25, i32 noundef 4, ptr noundef %1, i64 noundef %15, i64 noundef %17, ptr noundef %0) #15
  %35 = and i32 %34, 1
  %36 = or disjoint i32 %35, %33
  %37 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef %1, i64 noundef %15, i32 noundef 1) #15
  %38 = getelementptr inbounds i64, ptr %1, i64 %15
  %39 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef nonnull %38, i64 noundef %15) #15
  %40 = add i64 %39, %37
  %41 = shl i64 %40, 1
  %42 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef nonnull %26, i64 noundef %15, i32 noundef 1) #15
  %43 = add i64 %41, %42
  %44 = getelementptr inbounds i64, ptr %1, i64 %18
  %45 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef nonnull %44, i64 noundef %15) #15
  %46 = add i64 %43, %45
  %47 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef nonnull %26, i64 noundef %15, i32 noundef 1) #15
  %48 = mul i64 %15, 24
  %49 = getelementptr inbounds i8, ptr %1, i64 %48
  %50 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef %49, i64 noundef %15) #15
  %51 = add i64 %50, %47
  %52 = shl i64 %46, 2
  %53 = shl i64 %51, 1
  %54 = add i64 %52, %53
  %55 = call i64 @__gmpn_lshift(ptr noundef nonnull %26, ptr noundef nonnull %26, i64 noundef %15, i32 noundef 1) #15
  %56 = add i64 %54, %55
  %57 = getelementptr inbounds i64, ptr %1, i64 %16
  %58 = icmp eq i64 %17, 0
  br i1 %58, label %71, label %59

59:                                               ; preds = %6
  %60 = call i64 @__gmpn_add_n(ptr noundef nonnull %26, ptr noundef nonnull %26, ptr noundef nonnull %57, i64 noundef %17) #15
  %61 = icmp eq i64 %60, 0
  br i1 %61, label %71, label %62

62:                                               ; preds = %65, %59
  %63 = phi i64 [ %69, %65 ], [ %17, %59 ]
  %64 = icmp sgt i64 %63, %14
  br i1 %64, label %71, label %65

65:                                               ; preds = %62
  %66 = getelementptr inbounds i64, ptr %26, i64 %63
  %67 = load i64, ptr %66, align 8, !tbaa !9
  %68 = add i64 %67, 1
  %69 = add nsw i64 %63, 1
  store i64 %68, ptr %66, align 8, !tbaa !9
  %70 = icmp eq i64 %68, 0
  br i1 %70, label %62, label %71, !llvm.loop !11

71:                                               ; preds = %65, %62, %59, %6
  %72 = phi i64 [ 0, %59 ], [ 0, %6 ], [ 1, %62 ], [ 0, %65 ]
  %73 = add i64 %56, %72
  %74 = getelementptr inbounds i64, ptr %26, i64 %15
  store i64 %73, ptr %74, align 8, !tbaa !9
  %75 = getelementptr inbounds i64, ptr %3, i64 %18
  %76 = icmp eq i64 %19, 0
  br i1 %76, label %90, label %77

77:                                               ; preds = %71
  %78 = call i64 @__gmpn_add_n(ptr noundef nonnull %27, ptr noundef %3, ptr noundef nonnull %75, i64 noundef %19) #15
  %79 = icmp eq i64 %78, 0
  br i1 %79, label %90, label %80

80:                                               ; preds = %83, %77
  %81 = phi i64 [ %87, %83 ], [ %19, %77 ]
  %82 = icmp sgt i64 %81, %14
  br i1 %82, label %105, label %83

83:                                               ; preds = %80
  %84 = getelementptr inbounds i64, ptr %3, i64 %81
  %85 = load i64, ptr %84, align 8, !tbaa !9
  %86 = add i64 %85, 1
  %87 = add nsw i64 %81, 1
  %88 = getelementptr inbounds i64, ptr %27, i64 %81
  store i64 %86, ptr %88, align 8, !tbaa !9
  %89 = icmp eq i64 %86, 0
  br i1 %89, label %80, label %90, !llvm.loop !11

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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %100, ptr align 8 %101, i64 %104, i1 false), !tbaa !9
  br label %105

105:                                              ; preds = %95, %90, %80
  %106 = phi i1 [ true, %90 ], [ true, %95 ], [ false, %80 ]
  %107 = phi i64 [ 0, %90 ], [ 0, %95 ], [ 1, %80 ]
  %108 = getelementptr inbounds i64, ptr %27, i64 %15
  store i64 %107, ptr %108, align 8, !tbaa !9
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
  %117 = load i64, ptr %116, align 8, !tbaa !9
  %118 = getelementptr inbounds i64, ptr %110, i64 %115
  %119 = load i64, ptr %118, align 8, !tbaa !9
  %120 = icmp eq i64 %117, %119
  br i1 %120, label %111, label %121, !llvm.loop !14

121:                                              ; preds = %114
  %122 = icmp ugt i64 %117, %119
  br i1 %122, label %127, label %123

123:                                              ; preds = %121
  %124 = call i64 @__gmpn_sub_n(ptr noundef nonnull %28, ptr noundef nonnull %110, ptr noundef nonnull %27, i64 noundef %15) #15
  %125 = getelementptr inbounds i64, ptr %28, i64 %15
  store i64 0, ptr %125, align 8, !tbaa !9
  %126 = xor i32 %36, 2
  br label %132

127:                                              ; preds = %121, %111, %105
  %128 = getelementptr inbounds i64, ptr %3, i64 %15
  %129 = call i64 @__gmpn_sub_n(ptr noundef nonnull %28, ptr noundef nonnull %27, ptr noundef nonnull %128, i64 noundef %15) #15
  %130 = sub i64 %107, %129
  %131 = getelementptr inbounds i64, ptr %28, i64 %15
  store i64 %130, ptr %131, align 8, !tbaa !9
  br label %132

132:                                              ; preds = %127, %123
  %133 = phi i32 [ %126, %123 ], [ %36, %127 ]
  %134 = getelementptr inbounds i64, ptr %3, i64 %15
  %135 = call i64 @__gmpn_add_n(ptr noundef nonnull %27, ptr noundef nonnull %27, ptr noundef nonnull %134, i64 noundef %15) #15
  %136 = load i64, ptr %108, align 8, !tbaa !9
  %137 = add i64 %136, %135
  store i64 %137, ptr %108, align 8, !tbaa !9
  %138 = call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %75, i64 noundef %19, i32 noundef 2) #15
  br i1 %76, label %152, label %139

139:                                              ; preds = %132
  %140 = call i64 @__gmpn_add_n(ptr noundef nonnull %29, ptr noundef %3, ptr noundef %0, i64 noundef %19) #15
  %141 = icmp eq i64 %140, 0
  br i1 %141, label %152, label %142

142:                                              ; preds = %145, %139
  %143 = phi i64 [ %149, %145 ], [ %19, %139 ]
  %144 = icmp sgt i64 %143, %14
  br i1 %144, label %167, label %145

145:                                              ; preds = %142
  %146 = getelementptr inbounds i64, ptr %3, i64 %143
  %147 = load i64, ptr %146, align 8, !tbaa !9
  %148 = add i64 %147, 1
  %149 = add nsw i64 %143, 1
  %150 = getelementptr inbounds i64, ptr %29, i64 %143
  store i64 %148, ptr %150, align 8, !tbaa !9
  %151 = icmp eq i64 %148, 0
  br i1 %151, label %142, label %152, !llvm.loop !11

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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %162, ptr align 8 %163, i64 %166, i1 false), !tbaa !9
  br label %167

167:                                              ; preds = %157, %152, %142
  %168 = phi i64 [ 0, %152 ], [ 0, %157 ], [ 1, %142 ]
  %169 = getelementptr inbounds i64, ptr %29, i64 %15
  store i64 %168, ptr %169, align 8, !tbaa !9
  %170 = getelementptr inbounds i64, ptr %29, i64 %19
  %171 = load i64, ptr %170, align 8, !tbaa !9
  %172 = add i64 %171, %138
  store i64 %172, ptr %170, align 8, !tbaa !9
  %173 = icmp ult i64 %172, %138
  br i1 %173, label %174, label %180

174:                                              ; preds = %174, %167
  %175 = phi ptr [ %176, %174 ], [ %170, %167 ]
  %176 = getelementptr inbounds i8, ptr %175, i64 8
  %177 = load i64, ptr %176, align 8, !tbaa !9
  %178 = add i64 %177, 1
  store i64 %178, ptr %176, align 8, !tbaa !9
  %179 = icmp eq i64 %178, 0
  br i1 %179, label %174, label %180, !llvm.loop !15

180:                                              ; preds = %174, %167
  %181 = call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %134, i64 noundef %15, i32 noundef 1) #15
  %182 = getelementptr inbounds i64, ptr %0, i64 %15
  store i64 %181, ptr %182, align 8, !tbaa !9
  br label %183

183:                                              ; preds = %186, %180
  %184 = phi i64 [ %20, %180 ], [ %187, %186 ]
  %185 = icmp sgt i64 %184, 0
  br i1 %185, label %186, label %198

186:                                              ; preds = %183
  %187 = add nsw i64 %184, -1
  %188 = getelementptr inbounds i64, ptr %29, i64 %187
  %189 = load i64, ptr %188, align 8, !tbaa !9
  %190 = getelementptr inbounds i64, ptr %0, i64 %187
  %191 = load i64, ptr %190, align 8, !tbaa !9
  %192 = icmp eq i64 %189, %191
  br i1 %192, label %183, label %193, !llvm.loop !14

193:                                              ; preds = %186
  %194 = icmp ugt i64 %189, %191
  br i1 %194, label %198, label %195

195:                                              ; preds = %193
  %196 = call i64 @__gmpn_sub_n(ptr noundef nonnull %30, ptr noundef %0, ptr noundef nonnull %29, i64 noundef %20) #15
  %197 = xor i32 %133, 1
  br label %200

198:                                              ; preds = %193, %183
  %199 = call i64 @__gmpn_sub_n(ptr noundef nonnull %30, ptr noundef nonnull %29, ptr noundef %0, i64 noundef %20) #15
  br label %200

200:                                              ; preds = %198, %195
  %201 = phi i32 [ %197, %195 ], [ %133, %198 ]
  %202 = call i64 @__gmpn_add_n(ptr noundef nonnull %29, ptr noundef nonnull %29, ptr noundef %0, i64 noundef %20) #15
  %203 = call i64 @__gmpn_lshift(ptr noundef nonnull %31, ptr noundef %3, i64 noundef %15, i32 noundef 1) #15
  %204 = call i64 @__gmpn_add_n(ptr noundef nonnull %31, ptr noundef nonnull %31, ptr noundef nonnull %134, i64 noundef %15) #15
  %205 = add i64 %204, %203
  %206 = shl i64 %205, 1
  %207 = call i64 @__gmpn_lshift(ptr noundef nonnull %31, ptr noundef nonnull %31, i64 noundef %15, i32 noundef 1) #15
  %208 = add i64 %206, %207
  br i1 %76, label %221, label %209

209:                                              ; preds = %200
  %210 = call i64 @__gmpn_add_n(ptr noundef nonnull %31, ptr noundef nonnull %31, ptr noundef nonnull %75, i64 noundef %19) #15
  %211 = icmp eq i64 %210, 0
  br i1 %211, label %221, label %212

212:                                              ; preds = %215, %209
  %213 = phi i64 [ %219, %215 ], [ %19, %209 ]
  %214 = icmp sgt i64 %213, %14
  br i1 %214, label %221, label %215

215:                                              ; preds = %212
  %216 = getelementptr inbounds i64, ptr %31, i64 %213
  %217 = load i64, ptr %216, align 8, !tbaa !9
  %218 = add i64 %217, 1
  %219 = add nsw i64 %213, 1
  store i64 %218, ptr %216, align 8, !tbaa !9
  %220 = icmp eq i64 %218, 0
  br i1 %220, label %212, label %221, !llvm.loop !11

221:                                              ; preds = %215, %212, %209, %200
  %222 = phi i64 [ 0, %209 ], [ 0, %200 ], [ 1, %212 ], [ 0, %215 ]
  %223 = add i64 %208, %222
  %224 = getelementptr inbounds i64, ptr %31, i64 %15
  store i64 %223, ptr %224, align 8, !tbaa !9
  call void @__gmpn_mul_n(ptr noundef %5, ptr noundef nonnull %24, ptr noundef nonnull %29, i64 noundef %20) #15
  %225 = getelementptr inbounds i64, ptr %5, i64 %18
  %226 = getelementptr inbounds i8, ptr %225, i64 8
  call void @__gmpn_mul_n(ptr noundef nonnull %226, ptr noundef nonnull %25, ptr noundef nonnull %30, i64 noundef %20) #15
  %227 = getelementptr inbounds i64, ptr %5, i64 %16
  %228 = getelementptr inbounds i8, ptr %227, i64 16
  call void @__gmpn_mul_n(ptr noundef nonnull %228, ptr noundef nonnull %26, ptr noundef nonnull %31, i64 noundef %20) #15
  %229 = mul nuw nsw i64 %15, 6
  %230 = getelementptr inbounds i64, ptr %5, i64 %229
  %231 = getelementptr inbounds i8, ptr %230, i64 24
  %232 = getelementptr inbounds i64, ptr %231, i64 %18
  store i64 0, ptr %232, align 8, !tbaa !9
  %233 = getelementptr inbounds i64, ptr %23, i64 %15
  %234 = load i64, ptr %233, align 8, !tbaa !9
  %235 = getelementptr inbounds i64, ptr %28, i64 %15
  %236 = load i64, ptr %235, align 8, !tbaa !9
  %237 = or i64 %236, %234
  %238 = icmp ne i64 %237, 0
  %239 = zext i1 %238 to i64
  %240 = add nuw nsw i64 %15, %239
  call void @__gmpn_mul_n(ptr noundef nonnull %231, ptr noundef nonnull %23, ptr noundef nonnull %28, i64 noundef %240) #15
  %241 = getelementptr inbounds i64, ptr %0, i64 %18
  %242 = getelementptr inbounds i64, ptr %241, i64 %18
  store i64 0, ptr %242, align 8, !tbaa !9
  %243 = getelementptr inbounds i64, ptr %22, i64 %15
  %244 = load i64, ptr %243, align 8, !tbaa !9
  %245 = load i64, ptr %108, align 8, !tbaa !9
  %246 = or i64 %245, %244
  %247 = icmp ne i64 %246, 0
  %248 = zext i1 %247 to i64
  %249 = add nuw nsw i64 %15, %248
  call void @__gmpn_mul_n(ptr noundef nonnull %241, ptr noundef %22, ptr noundef nonnull %27, i64 noundef %249) #15
  call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %15) #15
  %250 = icmp sgt i64 %17, %19
  %251 = getelementptr inbounds i64, ptr %0, i64 %229
  br i1 %250, label %252, label %254

252:                                              ; preds = %221
  %253 = call i64 @__gmpn_mul(ptr noundef nonnull %251, ptr noundef nonnull %57, i64 noundef %17, ptr noundef nonnull %75, i64 noundef %19) #15
  br label %256

254:                                              ; preds = %221
  %255 = call i64 @__gmpn_mul(ptr noundef nonnull %251, ptr noundef nonnull %75, i64 noundef %19, ptr noundef nonnull %57, i64 noundef %17) #15
  br label %256

256:                                              ; preds = %254, %252
  %257 = add nsw i64 %17, %19
  %258 = shl nsw i64 %15, 6
  %259 = getelementptr inbounds i8, ptr %5, i64 %258
  %260 = getelementptr inbounds i8, ptr %259, i64 32
  call void @__gmpn_toom_interpolate_7pts(ptr noundef %0, i64 noundef %15, i32 noundef %201, ptr noundef nonnull %226, ptr noundef nonnull %231, ptr noundef %5, ptr noundef nonnull %228, i64 noundef %257, ptr noundef nonnull %260) #15
  %261 = load ptr, ptr %7, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %261) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #15
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #4

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = shl nsw i64 %3, 4
  %8 = getelementptr inbounds i8, ptr %2, i64 %7
  %9 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %2, ptr noundef %8, i64 noundef %3) #15
  %10 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 %9, ptr %10, align 8, !tbaa !9
  %11 = getelementptr inbounds i64, ptr %2, i64 %3
  %12 = icmp eq i64 %4, 0
  br i1 %12, label %28, label %13

13:                                               ; preds = %6
  %14 = mul i64 %3, 24
  %15 = getelementptr inbounds i8, ptr %2, i64 %14
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %11, ptr noundef %15, i64 noundef %4) #15
  %17 = icmp eq i64 %16, 0
  br i1 %17, label %28, label %18

18:                                               ; preds = %21, %13
  %19 = phi i64 [ %25, %21 ], [ %4, %13 ]
  %20 = icmp slt i64 %19, %3
  br i1 %20, label %21, label %40

21:                                               ; preds = %18
  %22 = getelementptr inbounds i64, ptr %11, i64 %19
  %23 = load i64, ptr %22, align 8, !tbaa !9
  %24 = add i64 %23, 1
  %25 = add nsw i64 %19, 1
  %26 = getelementptr inbounds i64, ptr %5, i64 %19
  store i64 %24, ptr %26, align 8, !tbaa !9
  %27 = icmp eq i64 %24, 0
  br i1 %27, label %18, label %28, !llvm.loop !16

28:                                               ; preds = %21, %13, %6
  %29 = phi i64 [ %4, %13 ], [ 0, %6 ], [ %25, %21 ]
  %30 = icmp ne ptr %11, %5
  %31 = icmp slt i64 %29, %3
  %32 = select i1 %30, i1 %31, i1 false
  br i1 %32, label %33, label %40

33:                                               ; preds = %33, %28
  %34 = phi i64 [ %38, %33 ], [ %29, %28 ]
  %35 = getelementptr inbounds i64, ptr %11, i64 %34
  %36 = load i64, ptr %35, align 8, !tbaa !9
  %37 = getelementptr inbounds i64, ptr %5, i64 %34
  store i64 %36, ptr %37, align 8, !tbaa !9
  %38 = add nsw i64 %34, 1
  %39 = icmp eq i64 %38, %3
  br i1 %39, label %40, label %33, !llvm.loop !17

40:                                               ; preds = %33, %28, %18
  %41 = phi i64 [ 0, %28 ], [ 0, %33 ], [ 1, %18 ]
  %42 = getelementptr inbounds i64, ptr %5, i64 %3
  store i64 %41, ptr %42, align 8, !tbaa !9
  %43 = add nsw i64 %3, 1
  br label %44

44:                                               ; preds = %47, %40
  %45 = phi i64 [ %43, %40 ], [ %48, %47 ]
  %46 = icmp sgt i64 %45, 0
  br i1 %46, label %47, label %57

47:                                               ; preds = %44
  %48 = add nsw i64 %45, -1
  %49 = getelementptr inbounds i64, ptr %0, i64 %48
  %50 = load i64, ptr %49, align 8, !tbaa !9
  %51 = getelementptr inbounds i64, ptr %5, i64 %48
  %52 = load i64, ptr %51, align 8, !tbaa !9
  %53 = icmp eq i64 %50, %52
  br i1 %53, label %44, label %54, !llvm.loop !18

54:                                               ; preds = %47
  %55 = icmp ugt i64 %50, %52
  %56 = select i1 %55, i32 1, i32 -1
  br label %57

57:                                               ; preds = %54, %44
  %58 = phi i32 [ %56, %54 ], [ 0, %44 ]
  %59 = icmp slt i32 %58, 0
  br i1 %59, label %60, label %62

60:                                               ; preds = %57
  %61 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %5, ptr noundef %0, i64 noundef %43) #15
  br label %64

62:                                               ; preds = %57
  %63 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %5, i64 noundef %43) #15
  br label %64

64:                                               ; preds = %62, %60
  %65 = ashr i32 %58, 31
  %66 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %5, i64 noundef %43) #15
  ret i32 %65
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom32_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
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
  %24 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %1, ptr noundef %21, i64 noundef %19) #15
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %36, label %26

26:                                               ; preds = %29, %23
  %27 = phi i64 [ %33, %29 ], [ %19, %23 ]
  %28 = icmp slt i64 %27, %17
  br i1 %28, label %29, label %48

29:                                               ; preds = %26
  %30 = getelementptr inbounds i64, ptr %1, i64 %27
  %31 = load i64, ptr %30, align 8, !tbaa !9
  %32 = add i64 %31, 1
  %33 = add nsw i64 %27, 1
  %34 = getelementptr inbounds i64, ptr %0, i64 %27
  store i64 %32, ptr %34, align 8, !tbaa !9
  %35 = icmp eq i64 %32, 0
  br i1 %35, label %26, label %36, !llvm.loop !19

36:                                               ; preds = %29, %23, %16
  %37 = phi i64 [ %19, %23 ], [ 0, %16 ], [ %33, %29 ]
  %38 = icmp ne ptr %0, %1
  %39 = icmp slt i64 %37, %17
  %40 = select i1 %38, i1 %39, i1 false
  br i1 %40, label %41, label %48

41:                                               ; preds = %41, %36
  %42 = phi i64 [ %46, %41 ], [ %37, %36 ]
  %43 = getelementptr inbounds i64, ptr %1, i64 %42
  %44 = load i64, ptr %43, align 8, !tbaa !9
  %45 = getelementptr inbounds i64, ptr %0, i64 %42
  store i64 %44, ptr %45, align 8, !tbaa !9
  %46 = add nsw i64 %42, 1
  %47 = icmp eq i64 %46, %17
  br i1 %47, label %48, label %41, !llvm.loop !20

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
  %59 = load i64, ptr %58, align 8, !tbaa !9
  %60 = getelementptr inbounds i64, ptr %52, i64 %57
  %61 = load i64, ptr %60, align 8, !tbaa !9
  %62 = icmp eq i64 %59, %61
  br i1 %62, label %53, label %63, !llvm.loop !21

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
  %71 = tail call i64 @__gmpn_sub_n(ptr noundef %70, ptr noundef %52, ptr noundef %0, i64 noundef %17) #15
  br label %77

72:                                               ; preds = %66, %48
  %73 = getelementptr inbounds i64, ptr %0, i64 %18
  %74 = getelementptr inbounds i64, ptr %1, i64 %17
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef %73, ptr noundef %0, ptr noundef %74, i64 noundef %17) #15
  %76 = sub i64 %50, %75
  br label %77

77:                                               ; preds = %72, %69
  %78 = phi i64 [ 0, %69 ], [ %76, %72 ]
  %79 = phi i32 [ 1, %69 ], [ 0, %72 ]
  %80 = getelementptr inbounds i64, ptr %1, i64 %17
  %81 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %80, i64 noundef %17) #15
  %82 = add i64 %81, %50
  %83 = icmp eq i64 %20, %17
  %84 = getelementptr inbounds i64, ptr %0, i64 %17
  %85 = getelementptr inbounds i64, ptr %3, i64 %17
  br i1 %83, label %86, label %111

86:                                               ; preds = %77
  %87 = tail call i64 @__gmpn_add_n(ptr noundef %84, ptr noundef %3, ptr noundef %85, i64 noundef %17) #15
  br label %88

88:                                               ; preds = %91, %86
  %89 = phi i64 [ %17, %86 ], [ %92, %91 ]
  %90 = icmp sgt i64 %89, 0
  br i1 %90, label %91, label %101

91:                                               ; preds = %88
  %92 = add nsw i64 %89, -1
  %93 = getelementptr inbounds i64, ptr %3, i64 %92
  %94 = load i64, ptr %93, align 8, !tbaa !9
  %95 = getelementptr inbounds i64, ptr %85, i64 %92
  %96 = load i64, ptr %95, align 8, !tbaa !9
  %97 = icmp eq i64 %94, %96
  br i1 %97, label %88, label %98, !llvm.loop !21

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
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %105, ptr noundef %85, ptr noundef %3, i64 noundef %17) #15
  %108 = xor i32 %79, 1
  br label %207

109:                                              ; preds = %101
  %110 = tail call i64 @__gmpn_sub_n(ptr noundef %105, ptr noundef %3, ptr noundef %85, i64 noundef %17) #15
  br label %207

111:                                              ; preds = %77
  %112 = icmp eq i64 %20, 0
  br i1 %112, label %126, label %113

113:                                              ; preds = %111
  %114 = tail call i64 @__gmpn_add_n(ptr noundef %84, ptr noundef %3, ptr noundef %85, i64 noundef %20) #15
  %115 = icmp eq i64 %114, 0
  br i1 %115, label %126, label %116

116:                                              ; preds = %119, %113
  %117 = phi i64 [ %123, %119 ], [ %20, %113 ]
  %118 = icmp slt i64 %117, %17
  br i1 %118, label %119, label %138

119:                                              ; preds = %116
  %120 = getelementptr inbounds i64, ptr %3, i64 %117
  %121 = load i64, ptr %120, align 8, !tbaa !9
  %122 = add i64 %121, 1
  %123 = add nsw i64 %117, 1
  %124 = getelementptr inbounds i64, ptr %84, i64 %117
  store i64 %122, ptr %124, align 8, !tbaa !9
  %125 = icmp eq i64 %122, 0
  br i1 %125, label %116, label %126, !llvm.loop !19

126:                                              ; preds = %119, %113, %111
  %127 = phi i64 [ %20, %113 ], [ 0, %111 ], [ %123, %119 ]
  %128 = icmp ne ptr %84, %3
  %129 = icmp slt i64 %127, %17
  %130 = select i1 %128, i1 %129, i1 false
  br i1 %130, label %131, label %138

131:                                              ; preds = %131, %126
  %132 = phi i64 [ %136, %131 ], [ %127, %126 ]
  %133 = getelementptr inbounds i64, ptr %3, i64 %132
  %134 = load i64, ptr %133, align 8, !tbaa !9
  %135 = getelementptr inbounds i64, ptr %84, i64 %132
  store i64 %134, ptr %135, align 8, !tbaa !9
  %136 = add nsw i64 %132, 1
  %137 = icmp eq i64 %136, %17
  br i1 %137, label %138, label %131, !llvm.loop !20

138:                                              ; preds = %131, %126, %116
  %139 = phi i64 [ 0, %126 ], [ 0, %131 ], [ 1, %116 ]
  %140 = getelementptr inbounds i64, ptr %3, i64 %20
  %141 = sub nsw i64 %17, %20
  br label %142

142:                                              ; preds = %142, %138
  %143 = phi i64 [ %141, %138 ], [ %144, %142 ]
  %144 = add nsw i64 %143, -1
  %145 = getelementptr inbounds i64, ptr %140, i64 %144
  %146 = load i64, ptr %145, align 8, !tbaa !9
  %147 = icmp ne i64 %146, 0
  %148 = icmp eq i64 %144, 0
  %149 = or i1 %147, %148
  br i1 %149, label %150, label %142, !llvm.loop !22

150:                                              ; preds = %142
  br i1 %147, label %179, label %151

151:                                              ; preds = %154, %150
  %152 = phi i64 [ %155, %154 ], [ %20, %150 ]
  %153 = icmp sgt i64 %152, 0
  br i1 %153, label %154, label %164

154:                                              ; preds = %151
  %155 = add nsw i64 %152, -1
  %156 = getelementptr inbounds i64, ptr %3, i64 %155
  %157 = load i64, ptr %156, align 8, !tbaa !9
  %158 = getelementptr inbounds i64, ptr %85, i64 %155
  %159 = load i64, ptr %158, align 8, !tbaa !9
  %160 = icmp eq i64 %157, %159
  br i1 %160, label %151, label %161, !llvm.loop !21

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
  %170 = tail call i64 @__gmpn_sub_n(ptr noundef %169, ptr noundef %85, ptr noundef %3, i64 noundef %20) #15
  %171 = icmp eq i64 %141, 0
  br i1 %171, label %177, label %172

172:                                              ; preds = %167
  %173 = getelementptr i64, ptr %169, i64 %20
  %174 = shl i64 %17, 4
  %175 = shl i64 %4, 3
  %176 = sub i64 %174, %175
  tail call void @llvm.memset.p0.i64(ptr align 8 %173, i8 0, i64 %176, i1 false), !tbaa !9
  br label %177

177:                                              ; preds = %172, %167
  %178 = xor i32 %79, 1
  br label %207

179:                                              ; preds = %164, %150
  %180 = mul i64 %17, 24
  %181 = getelementptr inbounds i8, ptr %0, i64 %180
  br i1 %112, label %195, label %182

182:                                              ; preds = %179
  %183 = tail call i64 @__gmpn_sub_n(ptr noundef %181, ptr noundef %3, ptr noundef %85, i64 noundef %20) #15
  %184 = icmp eq i64 %183, 0
  br i1 %184, label %195, label %185

185:                                              ; preds = %188, %182
  %186 = phi i64 [ %192, %188 ], [ %20, %182 ]
  %187 = icmp slt i64 %186, %17
  br i1 %187, label %188, label %207

188:                                              ; preds = %185
  %189 = getelementptr inbounds i64, ptr %3, i64 %186
  %190 = load i64, ptr %189, align 8, !tbaa !9
  %191 = add i64 %190, -1
  %192 = add nsw i64 %186, 1
  %193 = getelementptr inbounds i64, ptr %181, i64 %186
  store i64 %191, ptr %193, align 8, !tbaa !9
  %194 = icmp eq i64 %190, 0
  br i1 %194, label %185, label %195, !llvm.loop !23

195:                                              ; preds = %188, %182, %179
  %196 = phi i64 [ %20, %182 ], [ 0, %179 ], [ %192, %188 ]
  %197 = icmp ne ptr %181, %3
  %198 = icmp slt i64 %196, %17
  %199 = select i1 %197, i1 %198, i1 false
  br i1 %199, label %200, label %207

200:                                              ; preds = %200, %195
  %201 = phi i64 [ %205, %200 ], [ %196, %195 ]
  %202 = getelementptr inbounds i64, ptr %3, i64 %201
  %203 = load i64, ptr %202, align 8, !tbaa !9
  %204 = getelementptr inbounds i64, ptr %181, i64 %201
  store i64 %203, ptr %204, align 8, !tbaa !9
  %205 = add nsw i64 %201, 1
  %206 = icmp eq i64 %205, %17
  br i1 %206, label %207, label %200, !llvm.loop !24

207:                                              ; preds = %200, %195, %185, %177, %109, %106
  %208 = phi i64 [ %87, %106 ], [ %87, %109 ], [ %139, %177 ], [ %139, %195 ], [ %139, %200 ], [ %139, %185 ]
  %209 = phi i32 [ %108, %106 ], [ %79, %109 ], [ %178, %177 ], [ %79, %195 ], [ %79, %200 ], [ %79, %185 ]
  %210 = getelementptr inbounds i64, ptr %0, i64 %17
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef %0, ptr noundef %210, i64 noundef %17) #15
  switch i64 %82, label %214 [
    i64 1, label %211
    i64 0, label %217
  ]

211:                                              ; preds = %207
  %212 = getelementptr inbounds i64, ptr %5, i64 %17
  %213 = tail call i64 @__gmpn_add_n(ptr noundef %212, ptr noundef %212, ptr noundef %210, i64 noundef %17) #15
  br label %217

214:                                              ; preds = %207
  %215 = getelementptr inbounds i64, ptr %5, i64 %17
  %216 = tail call i64 @__gmpn_addmul_1(ptr noundef %215, ptr noundef %210, i64 noundef %17, i64 noundef 2) #15
  br label %217

217:                                              ; preds = %214, %211, %207
  %218 = phi i64 [ %213, %211 ], [ %216, %214 ], [ %82, %207 ]
  %219 = icmp eq i64 %208, 0
  br i1 %219, label %225, label %220

220:                                              ; preds = %217
  %221 = getelementptr inbounds i64, ptr %5, i64 %17
  %222 = tail call i64 @__gmpn_add_n(ptr noundef %221, ptr noundef %221, ptr noundef %0, i64 noundef %17) #15
  %223 = add i64 %218, %82
  %224 = add i64 %223, %222
  br label %225

225:                                              ; preds = %220, %217
  %226 = phi i64 [ %224, %220 ], [ %218, %217 ]
  %227 = getelementptr inbounds i64, ptr %5, i64 %18
  store i64 %226, ptr %227, align 8, !tbaa !9
  %228 = getelementptr inbounds i64, ptr %0, i64 %18
  %229 = mul nsw i64 %17, 3
  %230 = getelementptr inbounds i64, ptr %0, i64 %229
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %228, ptr noundef %230, i64 noundef %17) #15
  %231 = icmp eq i64 %78, 0
  br i1 %231, label %234, label %232

232:                                              ; preds = %225
  %233 = tail call i64 @__gmpn_add_n(ptr noundef %210, ptr noundef %210, ptr noundef %230, i64 noundef %17) #15
  br label %234

234:                                              ; preds = %232, %225
  %235 = phi i64 [ %233, %232 ], [ 0, %225 ]
  store i64 %235, ptr %228, align 8, !tbaa !9
  %236 = icmp eq i32 %209, 0
  %237 = or disjoint i64 %18, 1
  br i1 %236, label %240, label %238

238:                                              ; preds = %234
  %239 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %237) #15
  br label %242

240:                                              ; preds = %234
  %241 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %237) #15
  br label %242

242:                                              ; preds = %240, %238
  %243 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %237, i32 noundef 1) #15
  %244 = load i64, ptr %228, align 8, !tbaa !9
  %245 = getelementptr inbounds i64, ptr %5, i64 %17
  %246 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %228, ptr noundef %5, ptr noundef %245, i64 noundef %17) #15
  %247 = load i64, ptr %227, align 8, !tbaa !9
  %248 = add i64 %247, %246
  %249 = load i64, ptr %245, align 8, !tbaa !9
  %250 = add i64 %249, %248
  store i64 %250, ptr %245, align 8, !tbaa !9
  %251 = load i64, ptr %227, align 8, !tbaa !9
  %252 = add i64 %251, %246
  %253 = icmp ult i64 %250, %252
  br i1 %253, label %254, label %260

254:                                              ; preds = %254, %242
  %255 = phi ptr [ %256, %254 ], [ %245, %242 ]
  %256 = getelementptr inbounds i8, ptr %255, i64 8
  %257 = load i64, ptr %256, align 8, !tbaa !9
  %258 = add i64 %257, 1
  store i64 %258, ptr %256, align 8, !tbaa !9
  %259 = icmp eq i64 %258, 0
  br i1 %259, label %254, label %260, !llvm.loop !25

260:                                              ; preds = %254, %242
  br i1 %236, label %291, label %261

261:                                              ; preds = %260
  %262 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %17) #15
  %263 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %210, i64 noundef %17) #15
  %264 = load i64, ptr %228, align 8, !tbaa !9
  %265 = add i64 %264, %262
  store i64 %265, ptr %228, align 8, !tbaa !9
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
  %274 = load i64, ptr %273, align 8, !tbaa !9
  %275 = add i64 %274, 1
  store i64 %275, ptr %273, align 8, !tbaa !9
  %276 = add nuw nsw i64 %270, 1
  %277 = icmp eq i64 %275, 0
  br i1 %277, label %269, label %278, !llvm.loop !26

278:                                              ; preds = %272, %269, %261
  %279 = phi i64 [ 0, %261 ], [ 1, %269 ], [ 0, %272 ]
  %280 = add i64 %263, %244
  %281 = add i64 %280, %279
  %282 = load i64, ptr %245, align 8, !tbaa !9
  %283 = add i64 %282, %281
  store i64 %283, ptr %245, align 8, !tbaa !9
  %284 = icmp ult i64 %283, %281
  br i1 %284, label %285, label %321

285:                                              ; preds = %285, %278
  %286 = phi ptr [ %287, %285 ], [ %245, %278 ]
  %287 = getelementptr inbounds i8, ptr %286, i64 8
  %288 = load i64, ptr %287, align 8, !tbaa !9
  %289 = add i64 %288, 1
  store i64 %289, ptr %287, align 8, !tbaa !9
  %290 = icmp eq i64 %289, 0
  br i1 %290, label %285, label %321, !llvm.loop !27

291:                                              ; preds = %260
  %292 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %17) #15
  %293 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %210, i64 noundef %17) #15
  %294 = load i64, ptr %228, align 8, !tbaa !9
  %295 = sub i64 %294, %292
  store i64 %295, ptr %228, align 8, !tbaa !9
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
  %304 = load i64, ptr %303, align 8, !tbaa !9
  %305 = add i64 %304, -1
  store i64 %305, ptr %303, align 8, !tbaa !9
  %306 = add nuw nsw i64 %300, 1
  %307 = icmp eq i64 %304, 0
  br i1 %307, label %299, label %308, !llvm.loop !28

308:                                              ; preds = %302, %299, %291
  %309 = phi i64 [ 0, %291 ], [ 1, %299 ], [ 0, %302 ]
  %310 = add i64 %293, %244
  %311 = add i64 %310, %309
  %312 = load i64, ptr %245, align 8, !tbaa !9
  %313 = sub i64 %312, %311
  store i64 %313, ptr %245, align 8, !tbaa !9
  %314 = icmp ult i64 %312, %311
  br i1 %314, label %315, label %321

315:                                              ; preds = %315, %308
  %316 = phi ptr [ %317, %315 ], [ %245, %308 ]
  %317 = getelementptr inbounds i8, ptr %316, i64 8
  %318 = load i64, ptr %317, align 8, !tbaa !9
  %319 = add i64 %318, -1
  store i64 %319, ptr %317, align 8, !tbaa !9
  %320 = icmp eq i64 %318, 0
  br i1 %320, label %315, label %321, !llvm.loop !29

321:                                              ; preds = %315, %308, %285, %278
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %17) #15
  %322 = icmp sgt i64 %19, %20
  %323 = getelementptr inbounds i64, ptr %3, i64 %17
  br i1 %322, label %324, label %326

324:                                              ; preds = %321
  %325 = tail call i64 @__gmpn_mul(ptr noundef %230, ptr noundef %21, i64 noundef %19, ptr noundef %323, i64 noundef %20) #15
  br label %328

326:                                              ; preds = %321
  %327 = tail call i64 @__gmpn_mul(ptr noundef %230, ptr noundef %323, i64 noundef %20, ptr noundef %21, i64 noundef %19) #15
  br label %328

328:                                              ; preds = %326, %324
  %329 = tail call i64 @__gmpn_sub_n(ptr noundef %210, ptr noundef %210, ptr noundef %230, i64 noundef %17) #15
  %330 = load i64, ptr %227, align 8, !tbaa !9
  %331 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %0, i64 noundef %17) #15
  %332 = load i64, ptr %228, align 8, !tbaa !9
  %333 = sub i64 %332, %329
  store i64 %333, ptr %228, align 8, !tbaa !9
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
  %342 = load i64, ptr %341, align 8, !tbaa !9
  %343 = add i64 %342, -1
  store i64 %343, ptr %341, align 8, !tbaa !9
  %344 = add nuw nsw i64 %338, 1
  %345 = icmp eq i64 %342, 0
  br i1 %345, label %337, label %346, !llvm.loop !28

346:                                              ; preds = %340, %337, %328
  %347 = phi i64 [ 0, %328 ], [ 1, %337 ], [ 0, %340 ]
  %348 = add i64 %347, %331
  %349 = tail call i64 @__gmpn_sub_n(ptr noundef %230, ptr noundef nonnull %245, ptr noundef %210, i64 noundef %17) #15
  %350 = load i64, ptr %230, align 8, !tbaa !9
  %351 = sub i64 %350, %348
  store i64 %351, ptr %230, align 8, !tbaa !9
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
  %360 = load i64, ptr %359, align 8, !tbaa !9
  %361 = add i64 %360, -1
  store i64 %361, ptr %359, align 8, !tbaa !9
  %362 = add nuw nsw i64 %356, 1
  %363 = icmp eq i64 %360, 0
  br i1 %363, label %355, label %364, !llvm.loop !28

364:                                              ; preds = %358, %355, %346
  %365 = phi i64 [ 0, %346 ], [ -1, %355 ], [ 0, %358 ]
  %366 = icmp eq i64 %17, 0
  br i1 %366, label %379, label %367

367:                                              ; preds = %364
  %368 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %210, ptr noundef nonnull %210, ptr noundef %5, i64 noundef %17) #15
  %369 = icmp eq i64 %368, 0
  br i1 %369, label %379, label %370

370:                                              ; preds = %373, %367
  %371 = phi i64 [ %377, %373 ], [ %17, %367 ]
  %372 = icmp slt i64 %371, %229
  br i1 %372, label %373, label %379

373:                                              ; preds = %370
  %374 = getelementptr inbounds i64, ptr %210, i64 %371
  %375 = load i64, ptr %374, align 8, !tbaa !9
  %376 = add i64 %375, 1
  %377 = add nsw i64 %371, 1
  store i64 %376, ptr %374, align 8, !tbaa !9
  %378 = icmp eq i64 %376, 0
  br i1 %378, label %370, label %379, !llvm.loop !19

379:                                              ; preds = %373, %370, %367, %364
  %380 = phi i64 [ 0, %367 ], [ 0, %364 ], [ 1, %370 ], [ 0, %373 ]
  %381 = add nsw i64 %19, %20
  %382 = icmp sgt i64 %381, %17
  br i1 %382, label %383, label %416, !prof !30

383:                                              ; preds = %379
  %384 = shl nsw i64 %17, 5
  %385 = getelementptr inbounds i8, ptr %0, i64 %384
  %386 = sub nsw i64 %381, %17
  %387 = icmp eq i64 %386, 0
  br i1 %387, label %400, label %388

388:                                              ; preds = %383
  %389 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %228, ptr noundef nonnull %228, ptr noundef %385, i64 noundef %386) #15
  %390 = icmp eq i64 %389, 0
  br i1 %390, label %400, label %391

391:                                              ; preds = %394, %388
  %392 = phi i64 [ %398, %394 ], [ %386, %388 ]
  %393 = icmp slt i64 %392, %18
  br i1 %393, label %394, label %400

394:                                              ; preds = %391
  %395 = getelementptr inbounds i64, ptr %228, i64 %392
  %396 = load i64, ptr %395, align 8, !tbaa !9
  %397 = add i64 %396, -1
  %398 = add nsw i64 %392, 1
  store i64 %397, ptr %395, align 8, !tbaa !9
  %399 = icmp eq i64 %396, 0
  br i1 %399, label %391, label %400, !llvm.loop !23

400:                                              ; preds = %394, %391, %388, %383
  %401 = phi i64 [ 0, %388 ], [ 0, %383 ], [ -1, %391 ], [ 0, %394 ]
  %402 = add i64 %330, %329
  %403 = sub i64 %402, %349
  %404 = add i64 %403, %365
  %405 = add i64 %404, %380
  %406 = add i64 %405, %401
  %407 = load i64, ptr %385, align 8, !tbaa !9
  %408 = add i64 %407, %406
  store i64 %408, ptr %385, align 8, !tbaa !9
  %409 = icmp ult i64 %408, %406
  br i1 %409, label %410, label %416

410:                                              ; preds = %410, %400
  %411 = phi ptr [ %412, %410 ], [ %385, %400 ]
  %412 = getelementptr inbounds i8, ptr %411, i64 8
  %413 = load i64, ptr %412, align 8, !tbaa !9
  %414 = add i64 %413, 1
  store i64 %414, ptr %412, align 8, !tbaa !9
  %415 = icmp eq i64 %414, 0
  br i1 %415, label %410, label %416, !llvm.loop !31

416:                                              ; preds = %410, %400, %379
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.smax.i64(i64, i64) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #1

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
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
  %17 = tail call i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef %0, ptr noundef nonnull %13, ptr noundef %1, i64 noundef %8, i64 noundef %10, ptr noundef nonnull %16) #15
  %18 = and i64 %7, -4
  %19 = getelementptr inbounds i64, ptr %0, i64 %18
  %20 = getelementptr inbounds i8, ptr %19, i64 16
  %21 = shl nsw i64 %8, 1
  %22 = getelementptr inbounds i64, ptr %0, i64 %21
  %23 = getelementptr inbounds i8, ptr %22, i64 16
  %24 = tail call i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef nonnull %20, ptr noundef nonnull %23, ptr noundef %3, i64 noundef %8, i64 noundef %11, ptr noundef nonnull %16) #15
  %25 = add nsw i64 %8, 1
  %26 = icmp sgt i64 %8, 98
  br i1 %26, label %28, label %27

27:                                               ; preds = %6
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %29

28:                                               ; preds = %6
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %29

29:                                               ; preds = %28, %27
  %30 = getelementptr inbounds i64, ptr %5, i64 %21
  %31 = getelementptr inbounds i8, ptr %30, i64 8
  br i1 %26, label %33, label %32

32:                                               ; preds = %29
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %31, ptr noundef nonnull %13, i64 noundef %25, ptr noundef nonnull %23, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %34

33:                                               ; preds = %29
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %31, ptr noundef nonnull %13, i64 noundef %25, ptr noundef nonnull %23, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %34

34:                                               ; preds = %33, %32
  %35 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %1, i64 noundef %8, i32 noundef 1) #15
  %36 = getelementptr inbounds i64, ptr %1, i64 %8
  %37 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %36, i64 noundef %8) #15
  %38 = add i64 %37, %35
  %39 = shl i64 %38, 1
  %40 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %8, i32 noundef 1) #15
  %41 = add i64 %39, %40
  %42 = getelementptr inbounds i64, ptr %1, i64 %21
  %43 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %42, i64 noundef %8) #15
  %44 = add i64 %41, %43
  %45 = shl i64 %44, 1
  %46 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %8, i32 noundef 1) #15
  %47 = add i64 %45, %46
  %48 = getelementptr inbounds i64, ptr %1, i64 %9
  %49 = icmp eq i64 %10, 0
  br i1 %49, label %62, label %50

50:                                               ; preds = %34
  %51 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %48, i64 noundef %10) #15
  %52 = icmp eq i64 %51, 0
  br i1 %52, label %62, label %53

53:                                               ; preds = %56, %50
  %54 = phi i64 [ %60, %56 ], [ %10, %50 ]
  %55 = icmp slt i64 %54, %8
  br i1 %55, label %56, label %62

56:                                               ; preds = %53
  %57 = getelementptr inbounds i64, ptr %0, i64 %54
  %58 = load i64, ptr %57, align 8, !tbaa !9
  %59 = add i64 %58, 1
  %60 = add nsw i64 %54, 1
  store i64 %59, ptr %57, align 8, !tbaa !9
  %61 = icmp eq i64 %59, 0
  br i1 %61, label %53, label %62, !llvm.loop !32

62:                                               ; preds = %56, %53, %50, %34
  %63 = phi i64 [ 0, %50 ], [ 0, %34 ], [ 1, %53 ], [ 0, %56 ]
  %64 = add i64 %47, %63
  store i64 %64, ptr %12, align 8, !tbaa !9
  %65 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %20, ptr noundef %3, i64 noundef %8, i32 noundef 1) #15
  %66 = getelementptr inbounds i64, ptr %3, i64 %8
  %67 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %20, ptr noundef nonnull %20, ptr noundef %66, i64 noundef %8) #15
  %68 = add i64 %67, %65
  %69 = shl i64 %68, 1
  %70 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %20, ptr noundef nonnull %20, i64 noundef %8, i32 noundef 1) #15
  %71 = add i64 %69, %70
  %72 = getelementptr inbounds i64, ptr %3, i64 %21
  %73 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %20, ptr noundef nonnull %20, ptr noundef %72, i64 noundef %8) #15
  %74 = add i64 %71, %73
  %75 = shl i64 %74, 1
  %76 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %20, ptr noundef nonnull %20, i64 noundef %8, i32 noundef 1) #15
  %77 = add i64 %75, %76
  %78 = getelementptr inbounds i64, ptr %3, i64 %9
  %79 = icmp eq i64 %11, 0
  br i1 %79, label %92, label %80

80:                                               ; preds = %62
  %81 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %20, ptr noundef nonnull %20, ptr noundef %78, i64 noundef %11) #15
  %82 = icmp eq i64 %81, 0
  br i1 %82, label %92, label %83

83:                                               ; preds = %86, %80
  %84 = phi i64 [ %90, %86 ], [ %11, %80 ]
  %85 = icmp slt i64 %84, %8
  br i1 %85, label %86, label %92

86:                                               ; preds = %83
  %87 = getelementptr inbounds i64, ptr %20, i64 %84
  %88 = load i64, ptr %87, align 8, !tbaa !9
  %89 = add i64 %88, 1
  %90 = add nsw i64 %84, 1
  store i64 %89, ptr %87, align 8, !tbaa !9
  %91 = icmp eq i64 %89, 0
  br i1 %91, label %83, label %92, !llvm.loop !32

92:                                               ; preds = %86, %83, %80, %62
  %93 = phi i64 [ 0, %80 ], [ 0, %62 ], [ 1, %83 ], [ 0, %86 ]
  %94 = add i64 %77, %93
  %95 = getelementptr inbounds i64, ptr %20, i64 %8
  store i64 %94, ptr %95, align 8, !tbaa !9
  %96 = getelementptr inbounds i64, ptr %5, i64 %18
  %97 = getelementptr inbounds i8, ptr %96, i64 16
  br i1 %26, label %99, label %98

98:                                               ; preds = %92
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %97, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %100

99:                                               ; preds = %92
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %97, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %100

100:                                              ; preds = %99, %98
  %101 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef %0, ptr noundef nonnull %13, ptr noundef %1, i64 noundef %8, i64 noundef %10, ptr noundef nonnull %16) #15
  %102 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %20, ptr noundef nonnull %23, ptr noundef %3, i64 noundef %8, i64 noundef %11, ptr noundef nonnull %16) #15
  %103 = mul nsw i64 %8, 6
  %104 = getelementptr inbounds i64, ptr %5, i64 %103
  %105 = getelementptr inbounds i8, ptr %104, i64 24
  %106 = getelementptr inbounds i64, ptr %105, i64 %21
  store i64 0, ptr %106, align 8, !tbaa !9
  %107 = getelementptr inbounds i64, ptr %23, i64 %8
  %108 = load i64, ptr %107, align 8, !tbaa !9
  %109 = getelementptr inbounds i64, ptr %13, i64 %8
  %110 = load i64, ptr %109, align 8, !tbaa !9
  %111 = or i64 %110, %108
  %112 = add i64 %111, %8
  %113 = icmp ugt i64 %112, 99
  br i1 %113, label %115, label %114

114:                                              ; preds = %100
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %105, ptr noundef nonnull %13, i64 noundef %112, ptr noundef nonnull %23, i64 noundef %112, ptr noundef nonnull %16) #15
  br label %116

115:                                              ; preds = %100
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %105, ptr noundef nonnull %13, i64 noundef %112, ptr noundef nonnull %23, i64 noundef %112, ptr noundef nonnull %16) #15
  br label %116

116:                                              ; preds = %115, %114
  br i1 %26, label %118, label %117

117:                                              ; preds = %116
  tail call void @__gmpn_toom22_mul(ptr noundef %22, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %119

118:                                              ; preds = %116
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %22, ptr noundef %0, i64 noundef %25, ptr noundef nonnull %20, i64 noundef %25, ptr noundef nonnull %16) #15
  br label %119

119:                                              ; preds = %118, %117
  %120 = icmp sgt i64 %8, 99
  br i1 %120, label %122, label %121

121:                                              ; preds = %119
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %16) #15
  br label %123

122:                                              ; preds = %119
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %16) #15
  br label %123

123:                                              ; preds = %122, %121
  %124 = icmp sgt i64 %2, %4
  br i1 %124, label %125, label %128

125:                                              ; preds = %123
  %126 = getelementptr inbounds i64, ptr %0, i64 %103
  %127 = tail call i64 @__gmpn_mul(ptr noundef %126, ptr noundef %48, i64 noundef %10, ptr noundef %78, i64 noundef %11) #15
  br label %133

128:                                              ; preds = %123
  %129 = icmp sgt i64 %10, 99
  %130 = getelementptr inbounds i64, ptr %0, i64 %103
  br i1 %129, label %132, label %131

131:                                              ; preds = %128
  tail call void @__gmpn_toom22_mul(ptr noundef %130, ptr noundef %48, i64 noundef %10, ptr noundef %78, i64 noundef %10, ptr noundef nonnull %16) #15
  br label %133

132:                                              ; preds = %128
  tail call void @__gmpn_toom33_mul(ptr noundef %130, ptr noundef %48, i64 noundef %10, ptr noundef %78, i64 noundef %10, ptr noundef nonnull %16) #15
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
  tail call void @__gmpn_toom_interpolate_7pts(ptr noundef %0, i64 noundef %8, i32 noundef %139, ptr noundef nonnull %141, ptr noundef nonnull %105, ptr noundef %5, ptr noundef nonnull %143, i64 noundef %144, ptr noundef nonnull %16) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #3 {
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
  %17 = load i64, ptr %16, align 8, !tbaa !9
  %18 = getelementptr inbounds i64, ptr %10, i64 %15
  %19 = load i64, ptr %18, align 8, !tbaa !9
  %20 = icmp eq i64 %17, %19
  br i1 %20, label %11, label %21, !llvm.loop !33

21:                                               ; preds = %14
  %22 = icmp ugt i64 %17, %19
  br i1 %22, label %25, label %23

23:                                               ; preds = %21
  %24 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %10, ptr noundef %1, i64 noundef %6) #15
  br label %53

25:                                               ; preds = %21, %11
  %26 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %10, i64 noundef %6) #15
  br label %53

27:                                               ; preds = %4
  %28 = getelementptr inbounds i64, ptr %1, i64 %5
  %29 = load i64, ptr %28, align 8, !tbaa !9
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
  %39 = load i64, ptr %38, align 8, !tbaa !9
  %40 = getelementptr inbounds i64, ptr %32, i64 %37
  %41 = load i64, ptr %40, align 8, !tbaa !9
  %42 = icmp eq i64 %39, %41
  br i1 %42, label %33, label %43, !llvm.loop !33

43:                                               ; preds = %36
  %44 = icmp ugt i64 %39, %41
  br i1 %44, label %48, label %45

45:                                               ; preds = %43
  %46 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %32, ptr noundef %1, i64 noundef %5) #15
  %47 = getelementptr inbounds i64, ptr %0, i64 %5
  store i64 0, ptr %47, align 8, !tbaa !9
  br label %53

48:                                               ; preds = %43, %33, %27
  %49 = getelementptr inbounds i64, ptr %1, i64 %6
  %50 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %49, i64 noundef %5) #15
  %51 = sub i64 %29, %50
  %52 = getelementptr inbounds i64, ptr %0, i64 %5
  store i64 %51, ptr %52, align 8, !tbaa !9
  br label %53

53:                                               ; preds = %48, %45, %25, %23
  %54 = icmp sgt i64 %6, 49
  br i1 %54, label %56, label %55

55:                                               ; preds = %53
  tail call void @__gmpn_sqr_basecase(ptr noundef %3, ptr noundef %0, i64 noundef %6) #15
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
  tail call void @__gmpn_sqr_basecase(ptr noundef %64, ptr noundef %61, i64 noundef %5) #15
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
  tail call void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %6) #15
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
  %78 = tail call i64 @__gmpn_add_n(ptr noundef %76, ptr noundef %77, ptr noundef %76, i64 noundef %6) #15
  %79 = tail call i64 @__gmpn_add_n(ptr noundef %77, ptr noundef %76, ptr noundef %0, i64 noundef %6) #15
  %80 = add i64 %79, %78
  %81 = and i64 %2, -2
  %82 = sub nsw i64 %81, %6
  %83 = icmp eq i64 %82, 0
  br i1 %83, label %97, label %84

84:                                               ; preds = %74
  %85 = getelementptr inbounds i64, ptr %76, i64 %6
  %86 = tail call i64 @__gmpn_add_n(ptr noundef %76, ptr noundef %76, ptr noundef %85, i64 noundef %82) #15
  %87 = icmp eq i64 %86, 0
  br i1 %87, label %97, label %88

88:                                               ; preds = %91, %84
  %89 = phi i64 [ %95, %91 ], [ %82, %84 ]
  %90 = icmp slt i64 %89, %6
  br i1 %90, label %91, label %97

91:                                               ; preds = %88
  %92 = getelementptr inbounds i64, ptr %76, i64 %89
  %93 = load i64, ptr %92, align 8, !tbaa !9
  %94 = add i64 %93, 1
  %95 = add nsw i64 %89, 1
  store i64 %94, ptr %92, align 8, !tbaa !9
  %96 = icmp eq i64 %94, 0
  br i1 %96, label %88, label %97, !llvm.loop !34

97:                                               ; preds = %91, %88, %84, %74
  %98 = phi i64 [ 0, %84 ], [ 0, %74 ], [ 1, %88 ], [ 0, %91 ]
  %99 = add i64 %98, %78
  %100 = tail call i64 @__gmpn_sub_n(ptr noundef %77, ptr noundef %77, ptr noundef %3, i64 noundef %75) #15
  %101 = sub i64 %99, %100
  %102 = icmp ult i64 %101, 3
  br i1 %102, label %106, label %103, !prof !30

103:                                              ; preds = %97
  %104 = sub i64 %2, %5
  %105 = shl i64 %104, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %76, i8 0, i64 %105, i1 false), !tbaa !9
  br label %128

106:                                              ; preds = %97
  %107 = load i64, ptr %76, align 8, !tbaa !9
  %108 = add i64 %107, %80
  store i64 %108, ptr %76, align 8, !tbaa !9
  %109 = icmp ult i64 %108, %80
  br i1 %109, label %110, label %116

110:                                              ; preds = %110, %106
  %111 = phi ptr [ %112, %110 ], [ %76, %106 ]
  %112 = getelementptr inbounds i8, ptr %111, i64 8
  %113 = load i64, ptr %112, align 8, !tbaa !9
  %114 = add i64 %113, 1
  store i64 %114, ptr %112, align 8, !tbaa !9
  %115 = icmp eq i64 %114, 0
  br i1 %115, label %110, label %116, !llvm.loop !35

116:                                              ; preds = %110, %106
  %117 = mul i64 %6, 24
  %118 = getelementptr inbounds i8, ptr %0, i64 %117
  %119 = load i64, ptr %118, align 8, !tbaa !9
  %120 = add i64 %119, %101
  store i64 %120, ptr %118, align 8, !tbaa !9
  %121 = icmp ult i64 %120, %101
  br i1 %121, label %122, label %128

122:                                              ; preds = %122, %116
  %123 = phi ptr [ %124, %122 ], [ %118, %116 ]
  %124 = getelementptr inbounds i8, ptr %123, i64 8
  %125 = load i64, ptr %124, align 8, !tbaa !9
  %126 = add i64 %125, 1
  store i64 %126, ptr %124, align 8, !tbaa !9
  %127 = icmp eq i64 %126, 0
  br i1 %127, label %122, label %128, !llvm.loop !36

128:                                              ; preds = %122, %116, %103
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define range(i64 0, 2) i64 @__gmpn_sub_n(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, ptr nocapture noundef readonly %2, i64 noundef %3) local_unnamed_addr #5 {
  br label %5

5:                                                ; preds = %5, %4
  %6 = phi i64 [ %3, %4 ], [ %22, %5 ]
  %7 = phi ptr [ %2, %4 ], [ %13, %5 ]
  %8 = phi i64 [ 0, %4 ], [ %20, %5 ]
  %9 = phi ptr [ %1, %4 ], [ %11, %5 ]
  %10 = phi ptr [ %0, %4 ], [ %21, %5 ]
  %11 = getelementptr inbounds i8, ptr %9, i64 8
  %12 = load i64, ptr %9, align 8, !tbaa !9
  %13 = getelementptr inbounds i8, ptr %7, i64 8
  %14 = load i64, ptr %7, align 8, !tbaa !9
  %15 = sub i64 %12, %14
  %16 = icmp ugt i64 %14, %12
  %17 = sub i64 %15, %8
  %18 = icmp ugt i64 %8, %15
  %19 = or i1 %16, %18
  %20 = zext i1 %19 to i64
  %21 = getelementptr inbounds i8, ptr %10, i64 8
  store i64 %17, ptr %10, align 8, !tbaa !9
  %22 = add nsw i64 %6, -1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %24, label %5, !llvm.loop !37

24:                                               ; preds = %5
  ret i64 %20
}

; Function Attrs: nofree nounwind ssp uwtable
define void @__gmp_assert_header(ptr noundef %0, i32 noundef %1) local_unnamed_addr #6 {
  %3 = icmp eq ptr %0, null
  br i1 %3, label %14, label %4

4:                                                ; preds = %2
  %5 = load i8, ptr %0, align 1, !tbaa !38
  %6 = icmp eq i8 %5, 0
  br i1 %6, label %14, label %7

7:                                                ; preds = %4
  %8 = load ptr, ptr @__stderrp, align 8, !tbaa !5
  %9 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %8, ptr noundef nonnull @.str.14, ptr noundef nonnull %0) #15
  %10 = icmp eq i32 %1, -1
  br i1 %10, label %14, label %11

11:                                               ; preds = %7
  %12 = load ptr, ptr @__stderrp, align 8, !tbaa !5
  %13 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %12, ptr noundef nonnull @.str.1.15, i32 noundef %1) #15
  br label %14

14:                                               ; preds = %11, %7, %4, %2
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @fprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ...) local_unnamed_addr #7

; Function Attrs: noreturn nounwind ssp uwtable
define void @__gmp_assert_fail(ptr noundef %0, i32 noundef %1, ptr noundef %2) local_unnamed_addr #8 {
  tail call void @__gmp_assert_header(ptr noundef %0, i32 noundef %1)
  %4 = load ptr, ptr @__stderrp, align 8, !tbaa !5
  %5 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %4, ptr noundef nonnull @.str.2.18, ptr noundef %2) #15
  tail call void @abort() #16
  unreachable
}

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #9

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_couple_handling(ptr noundef %0, i64 noundef %1, ptr noundef %2, i32 noundef %3, i64 noundef %4, i32 noundef %5, i32 noundef %6) local_unnamed_addr #3 {
  %8 = icmp eq i32 %3, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %7
  %10 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %0, ptr noundef %2, i64 noundef %1) #15
  br label %13

11:                                               ; preds = %7
  %12 = tail call i64 @__gmpn_add_n(ptr noundef %2, ptr noundef %0, ptr noundef %2, i64 noundef %1) #15
  br label %13

13:                                               ; preds = %11, %9
  %14 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %1, i32 noundef 1) #15
  %15 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %0, ptr noundef %2, i64 noundef %1) #15
  %16 = icmp sgt i32 %5, 0
  br i1 %16, label %17, label %19

17:                                               ; preds = %13
  %18 = tail call i64 @__gmpn_rshift(ptr noundef %0, ptr noundef %0, i64 noundef %1, i32 noundef %5) #15
  br label %19

19:                                               ; preds = %17, %13
  %20 = icmp sgt i32 %6, 0
  br i1 %20, label %21, label %23

21:                                               ; preds = %19
  %22 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %1, i32 noundef %6) #15
  br label %23

23:                                               ; preds = %21, %19
  %24 = getelementptr inbounds i64, ptr %0, i64 %4
  %25 = sub nsw i64 %1, %4
  %26 = tail call i64 @__gmpn_add_n(ptr noundef %24, ptr noundef %24, ptr noundef %2, i64 noundef %25) #15
  %27 = getelementptr inbounds i64, ptr %0, i64 %1
  store i64 %26, ptr %27, align 8, !tbaa !9
  %28 = getelementptr inbounds i64, ptr %2, i64 %1
  %29 = sub i64 0, %4
  %30 = getelementptr inbounds i64, ptr %28, i64 %29
  %31 = load i64, ptr %30, align 8, !tbaa !9
  %32 = add i64 %31, %26
  store i64 %32, ptr %27, align 8, !tbaa !9
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
  %41 = load i64, ptr %40, align 8, !tbaa !9
  %42 = add i64 %41, 1
  %43 = getelementptr inbounds i64, ptr %27, i64 %37
  store i64 %42, ptr %43, align 8, !tbaa !9
  %44 = add nuw i64 %37, 1
  %45 = icmp eq i64 %42, 0
  br i1 %45, label %36, label %46, !llvm.loop !39

46:                                               ; preds = %39
  %47 = icmp ne ptr %30, %27
  %48 = icmp slt i64 %44, %4
  %49 = select i1 %47, i1 %48, i1 false
  br i1 %49, label %50, label %68

50:                                               ; preds = %50, %46
  %51 = phi i64 [ %55, %50 ], [ %44, %46 ]
  %52 = getelementptr inbounds i64, ptr %30, i64 %51
  %53 = load i64, ptr %52, align 8, !tbaa !9
  %54 = getelementptr inbounds i64, ptr %27, i64 %51
  store i64 %53, ptr %54, align 8, !tbaa !9
  %55 = add nuw nsw i64 %51, 1
  %56 = icmp slt i64 %55, %4
  br i1 %56, label %50, label %68, !llvm.loop !40

57:                                               ; preds = %23
  %58 = icmp ne ptr %30, %27
  %59 = icmp sgt i64 %4, 1
  %60 = and i1 %59, %58
  br i1 %60, label %61, label %68

61:                                               ; preds = %61, %57
  %62 = phi i64 [ %66, %61 ], [ 1, %57 ]
  %63 = getelementptr inbounds i64, ptr %30, i64 %62
  %64 = load i64, ptr %63, align 8, !tbaa !9
  %65 = getelementptr inbounds i64, ptr %27, i64 %62
  store i64 %64, ptr %65, align 8, !tbaa !9
  %66 = add nuw nsw i64 %62, 1
  %67 = icmp eq i64 %66, %4
  br i1 %67, label %68, label %61, !llvm.loop !41

68:                                               ; preds = %61, %57, %50, %46, %36
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_addmul_1(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #5 {
  %5 = lshr i64 %3, 32
  %6 = and i64 %3, 4294967295
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %39, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %41, %7 ]
  %10 = phi ptr [ %1, %4 ], [ %12, %7 ]
  %11 = phi ptr [ %0, %4 ], [ %40, %7 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 8
  %13 = load i64, ptr %10, align 8, !tbaa !9
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
  %30 = load i64, ptr %11, align 8, !tbaa !9
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
  store i64 %36, ptr %11, align 8, !tbaa !9
  %41 = add nsw i64 %9, -1
  %42 = icmp eq i64 %41, 0
  br i1 %42, label %43, label %7, !llvm.loop !42

43:                                               ; preds = %7
  ret i64 %39
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_pm2exp(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, i32 noundef %6, ptr noundef %7) local_unnamed_addr #3 {
  %9 = shl nsw i64 %4, 4
  %10 = getelementptr inbounds i8, ptr %3, i64 %9
  %11 = shl i32 %6, 1
  %12 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %10, i64 noundef %4, i32 noundef %11) #15
  %13 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %12, ptr %13, align 8, !tbaa !9
  %14 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %3, ptr noundef %7, i64 noundef %4) #15
  %15 = load i64, ptr %13, align 8, !tbaa !9
  %16 = add i64 %15, %14
  store i64 %16, ptr %13, align 8, !tbaa !9
  %17 = icmp ugt i32 %2, 4
  br i1 %17, label %18, label %32

18:                                               ; preds = %18, %8
  %19 = phi i32 [ %30, %18 ], [ 4, %8 ]
  %20 = zext i32 %19 to i64
  %21 = mul nsw i64 %20, %4
  %22 = getelementptr inbounds i64, ptr %3, i64 %21
  %23 = mul i32 %19, %6
  %24 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %22, i64 noundef %4, i32 noundef %23) #15
  %25 = load i64, ptr %13, align 8, !tbaa !9
  %26 = add i64 %25, %24
  store i64 %26, ptr %13, align 8, !tbaa !9
  %27 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %7, i64 noundef %4) #15
  %28 = load i64, ptr %13, align 8, !tbaa !9
  %29 = add i64 %28, %27
  store i64 %29, ptr %13, align 8, !tbaa !9
  %30 = add i32 %19, 2
  %31 = icmp ult i32 %30, %2
  br i1 %31, label %18, label %32, !llvm.loop !43

32:                                               ; preds = %18, %8
  %33 = getelementptr inbounds i64, ptr %3, i64 %4
  %34 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %33, i64 noundef %4, i32 noundef %6) #15
  %35 = getelementptr inbounds i64, ptr %7, i64 %4
  store i64 %34, ptr %35, align 8, !tbaa !9
  %36 = icmp ugt i32 %2, 3
  br i1 %36, label %37, label %51

37:                                               ; preds = %37, %32
  %38 = phi i32 [ %49, %37 ], [ 3, %32 ]
  %39 = zext i32 %38 to i64
  %40 = mul nsw i64 %39, %4
  %41 = getelementptr inbounds i64, ptr %3, i64 %40
  %42 = mul i32 %38, %6
  %43 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %41, i64 noundef %4, i32 noundef %42) #15
  %44 = load i64, ptr %35, align 8, !tbaa !9
  %45 = add i64 %44, %43
  store i64 %45, ptr %35, align 8, !tbaa !9
  %46 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %4) #15
  %47 = load i64, ptr %35, align 8, !tbaa !9
  %48 = add i64 %47, %46
  store i64 %48, ptr %35, align 8, !tbaa !9
  %49 = add i32 %38, 2
  %50 = icmp ult i32 %49, %2
  br i1 %50, label %37, label %51, !llvm.loop !44

51:                                               ; preds = %37, %32
  %52 = zext i32 %2 to i64
  %53 = mul nsw i64 %52, %4
  %54 = getelementptr inbounds i64, ptr %3, i64 %53
  %55 = mul i32 %6, %2
  %56 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %54, i64 noundef %5, i32 noundef %55) #15
  %57 = getelementptr inbounds i64, ptr %1, i64 %5
  store i64 %56, ptr %57, align 8, !tbaa !9
  %58 = and i32 %2, 1
  %59 = icmp eq i32 %58, 0
  %60 = add nsw i64 %5, 1
  %61 = icmp eq i64 %60, 0
  br i1 %59, label %75, label %62

62:                                               ; preds = %51
  br i1 %61, label %88, label %63

63:                                               ; preds = %62
  %64 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %60) #15
  %65 = icmp eq i64 %64, 0
  br i1 %65, label %88, label %66

66:                                               ; preds = %69, %63
  %67 = phi i64 [ %73, %69 ], [ %60, %63 ]
  %68 = icmp sgt i64 %67, %4
  br i1 %68, label %88, label %69

69:                                               ; preds = %66
  %70 = getelementptr inbounds i64, ptr %7, i64 %67
  %71 = load i64, ptr %70, align 8, !tbaa !9
  %72 = add i64 %71, 1
  %73 = add nsw i64 %67, 1
  store i64 %72, ptr %70, align 8, !tbaa !9
  %74 = icmp eq i64 %72, 0
  br i1 %74, label %66, label %88, !llvm.loop !45

75:                                               ; preds = %51
  br i1 %61, label %88, label %76

76:                                               ; preds = %75
  %77 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %1, i64 noundef %60) #15
  %78 = icmp eq i64 %77, 0
  br i1 %78, label %88, label %79

79:                                               ; preds = %82, %76
  %80 = phi i64 [ %86, %82 ], [ %60, %76 ]
  %81 = icmp sgt i64 %80, %4
  br i1 %81, label %88, label %82

82:                                               ; preds = %79
  %83 = getelementptr inbounds i64, ptr %0, i64 %80
  %84 = load i64, ptr %83, align 8, !tbaa !9
  %85 = add i64 %84, 1
  %86 = add nsw i64 %80, 1
  store i64 %85, ptr %83, align 8, !tbaa !9
  %87 = icmp eq i64 %85, 0
  br i1 %87, label %79, label %88, !llvm.loop !45

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
  %96 = load i64, ptr %95, align 8, !tbaa !9
  %97 = getelementptr inbounds i64, ptr %7, i64 %94
  %98 = load i64, ptr %97, align 8, !tbaa !9
  %99 = icmp eq i64 %96, %98
  br i1 %99, label %90, label %100, !llvm.loop !46

100:                                              ; preds = %93
  %101 = icmp ugt i64 %96, %98
  %102 = select i1 %101, i32 1, i32 -1
  br label %103

103:                                              ; preds = %100, %90
  %104 = phi i32 [ %102, %100 ], [ 0, %90 ]
  %105 = icmp slt i32 %104, 0
  br i1 %105, label %106, label %108

106:                                              ; preds = %103
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %7, ptr noundef %0, i64 noundef %89) #15
  br label %110

108:                                              ; preds = %103
  %109 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %7, i64 noundef %89) #15
  br label %110

110:                                              ; preds = %108, %106
  %111 = ashr i32 %104, 31
  %112 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %7, i64 noundef %89) #15
  ret i32 %111
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @__gmpn_fft_best_k(i64 noundef %0, i32 noundef %1) local_unnamed_addr #10 {
  %3 = sext i32 %1 to i64
  %4 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %3, i64 0
  %5 = load i64, ptr %4, align 16, !tbaa !9
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
  %17 = load i64, ptr %16, align 8, !tbaa !9
  %18 = icmp eq i64 %17, 0
  br i1 %18, label %19, label %7, !llvm.loop !47

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
  %28 = load i64, ptr %27, align 8, !tbaa !9
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

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_fft_next_size(i64 noundef %0, i32 noundef %1) local_unnamed_addr #10 {
  %3 = add nsw i64 %0, -1
  %4 = zext i32 %1 to i64
  %5 = ashr i64 %3, %4
  %6 = add nsw i64 %5, 1
  %7 = shl i64 %6, %4
  ret i64 %7
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_mul_fft(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, i32 noundef %6) local_unnamed_addr #3 {
  %8 = alloca ptr, align 8
  %9 = icmp eq ptr %2, %4
  %10 = icmp eq i64 %3, %5
  %11 = and i1 %9, %10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #15
  %12 = add nsw i64 %1, -1
  %13 = zext i32 %6 to i64
  %14 = ashr i64 %12, %13
  %15 = add nsw i64 %14, 1
  %16 = shl i64 %15, %13
  %17 = icmp eq i64 %16, %1
  br i1 %17, label %19, label %18, !prof !30

18:                                               ; preds = %7
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 934, ptr noundef nonnull @.str.1.28) #17
  unreachable

19:                                               ; preds = %7
  store ptr null, ptr %8, align 8, !tbaa !5
  %20 = shl nsw i64 %1, 6
  %21 = add nsw i32 %6, 1
  %22 = sext i32 %21 to i64
  %23 = shl nsw i64 %22, 3
  %24 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %23) #15
  %25 = shl i64 8, %13
  %26 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %25) #15
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
  store ptr %33, ptr %34, align 8, !tbaa !5
  %35 = shl nuw i64 1, %32
  %36 = getelementptr inbounds i32, ptr %33, i64 %35
  %37 = add nuw nsw i64 %32, 1
  %38 = icmp eq i64 %37, %30
  br i1 %38, label %39, label %31, !llvm.loop !48

39:                                               ; preds = %31, %19
  %40 = load ptr, ptr %24, align 8, !tbaa !5
  store i32 0, ptr %40, align 4, !tbaa !49
  %41 = icmp slt i32 %6, 1
  br i1 %41, label %68, label %42

42:                                               ; preds = %39
  %43 = zext nneg i32 %21 to i64
  br label %44

44:                                               ; preds = %64, %42
  %45 = phi i64 [ 1, %42 ], [ %65, %64 ]
  %46 = phi i32 [ 1, %42 ], [ %66, %64 ]
  %47 = getelementptr inbounds ptr, ptr %24, i64 %45
  %48 = load ptr, ptr %47, align 8, !tbaa !5
  %49 = getelementptr i8, ptr %47, i64 -8
  %50 = load ptr, ptr %49, align 8, !tbaa !5
  %51 = sext i32 %46 to i64
  %52 = call i32 @llvm.umax.i32(i32 %46, i32 1)
  %53 = zext i32 %52 to i64
  br label %54

54:                                               ; preds = %54, %44
  %55 = phi i64 [ 0, %44 ], [ %62, %54 ]
  %56 = getelementptr inbounds i32, ptr %50, i64 %55
  %57 = load i32, ptr %56, align 4, !tbaa !49
  %58 = shl nsw i32 %57, 1
  %59 = getelementptr inbounds i32, ptr %48, i64 %55
  store i32 %58, ptr %59, align 4, !tbaa !49
  %60 = or disjoint i32 %58, 1
  %61 = getelementptr i32, ptr %59, i64 %51
  store i32 %60, ptr %61, align 4, !tbaa !49
  %62 = add nuw nsw i64 %55, 1
  %63 = icmp eq i64 %62, %53
  br i1 %63, label %64, label %54, !llvm.loop !51

64:                                               ; preds = %54
  %65 = add nuw nsw i64 %45, 1
  %66 = shl nsw i32 %46, 1
  %67 = icmp eq i64 %65, %43
  br i1 %67, label %68, label %44, !llvm.loop !52

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
  br i1 %83, label %75, label %84, !llvm.loop !53

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
  %100 = load i64, ptr %99, align 16, !tbaa !9
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
  %115 = load i64, ptr %114, align 8, !tbaa !9
  %116 = icmp eq i64 %115, 0
  br i1 %116, label %117, label %105, !llvm.loop !47

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
  %126 = load i64, ptr %125, align 8, !tbaa !9
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
  br label %102, !llvm.loop !54

146:                                              ; preds = %133, %84
  %147 = phi i64 [ %94, %84 ], [ %103, %133 ]
  %148 = phi i64 [ %93, %84 ], [ %104, %133 ]
  %149 = icmp slt i64 %147, %1
  br i1 %149, label %151, label %150, !prof !30

150:                                              ; preds = %146
  call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 972, ptr noundef nonnull @.str.2.29) #17
  unreachable

151:                                              ; preds = %146
  %152 = add nsw i64 %147, 1
  %153 = shl i64 %152, 4
  %154 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %153) #15
  %155 = ashr i64 %148, %13
  %156 = shl i64 %152, %13
  %157 = shl i64 %156, 3
  %158 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %157) #15
  %159 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %25) #15
  %160 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %25) #15
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %158, ptr noundef %159, i64 noundef %69, i64 noundef %147, ptr noundef %2, i64 noundef %3, i64 noundef %73, i64 noundef %155, ptr noundef %154)
  br i1 %11, label %161, label %168

161:                                              ; preds = %151
  %162 = add nuw i64 %69, 2305843009213693951
  %163 = mul i64 %73, %162
  %164 = add i64 %147, %163
  %165 = shl i64 %164, 3
  %166 = add i64 %165, 8
  %167 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %166) #15
  br label %170

168:                                              ; preds = %151
  %169 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %157) #15
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %169, ptr noundef %160, i64 noundef %69, i64 noundef %147, ptr noundef %4, i64 noundef %5, i64 noundef %73, i64 noundef %155, ptr noundef %154)
  br label %170

170:                                              ; preds = %168, %161
  %171 = phi ptr [ %167, %161 ], [ %169, %168 ]
  %172 = zext i1 %11 to i32
  %173 = call fastcc i64 @mpn_mul_fft_internal(ptr noundef %0, i64 noundef %1, i32 noundef %6, ptr noundef %159, ptr noundef %160, ptr noundef %171, i64 noundef %147, i64 noundef %73, i64 noundef %155, ptr noundef nonnull %24, ptr noundef %154, i32 noundef %172)
  %174 = load ptr, ptr %8, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %174) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #15
  ret i64 %173
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_mul_fft_decompose(ptr noundef %0, ptr nocapture noundef writeonly %1, i64 noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, ptr noundef %8) unnamed_addr #3 {
  %10 = alloca ptr, align 8
  %11 = mul nsw i64 %6, %2
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10) #15
  store ptr null, ptr %10, align 8, !tbaa !5
  %12 = icmp slt i64 %11, %5
  br i1 %12, label %13, label %60

13:                                               ; preds = %9
  %14 = sub nsw i64 %5, %11
  %15 = add nsw i64 %11, 1
  %16 = shl i64 %15, 3
  %17 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %10, i64 noundef %16) #15
  %18 = getelementptr inbounds i64, ptr %17, i64 %11
  store i64 0, ptr %18, align 8, !tbaa !9
  %19 = icmp sgt i64 %14, %11
  br i1 %19, label %20, label %21, !prof !55

20:                                               ; preds = %13
  call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 747, ptr noundef nonnull @.str.4.30) #17
  unreachable

21:                                               ; preds = %13
  %22 = icmp eq i64 %14, 0
  br i1 %22, label %37, label %23

23:                                               ; preds = %21
  %24 = getelementptr inbounds i64, ptr %4, i64 %11
  %25 = call i64 @__gmpn_sub_n(ptr noundef %17, ptr noundef %4, ptr noundef %24, i64 noundef %14) #15
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %37, label %27

27:                                               ; preds = %30, %23
  %28 = phi i64 [ %34, %30 ], [ %14, %23 ]
  %29 = icmp slt i64 %28, %11
  br i1 %29, label %30, label %49

30:                                               ; preds = %27
  %31 = getelementptr inbounds i64, ptr %4, i64 %28
  %32 = load i64, ptr %31, align 8, !tbaa !9
  %33 = add i64 %32, -1
  %34 = add nsw i64 %28, 1
  %35 = getelementptr inbounds i64, ptr %17, i64 %28
  store i64 %33, ptr %35, align 8, !tbaa !9
  %36 = icmp eq i64 %32, 0
  br i1 %36, label %27, label %37, !llvm.loop !56

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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %44, ptr align 8 %45, i64 %48, i1 false), !tbaa !9
  br label %49

49:                                               ; preds = %42, %37, %27
  %50 = phi i64 [ 0, %37 ], [ 0, %42 ], [ 1, %27 ]
  %51 = load i64, ptr %17, align 8, !tbaa !9
  %52 = add i64 %51, %50
  store i64 %52, ptr %17, align 8, !tbaa !9
  %53 = icmp ult i64 %52, %50
  br i1 %53, label %54, label %60

54:                                               ; preds = %54, %49
  %55 = phi ptr [ %56, %54 ], [ %17, %49 ]
  %56 = getelementptr inbounds i8, ptr %55, i64 8
  %57 = load i64, ptr %56, align 8, !tbaa !9
  %58 = add i64 %57, 1
  store i64 %58, ptr %56, align 8, !tbaa !9
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %54, label %60, !llvm.loop !57

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
  store ptr %72, ptr %76, align 8, !tbaa !5
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
  %87 = load i64, ptr %73, align 8, !tbaa !9
  %88 = icmp eq i64 %86, 0
  br i1 %88, label %99, label %89

89:                                               ; preds = %89, %85
  %90 = phi i64 [ %97, %89 ], [ %86, %85 ]
  %91 = phi ptr [ %95, %89 ], [ %8, %85 ]
  %92 = phi ptr [ %94, %89 ], [ %73, %85 ]
  %93 = phi i64 [ %96, %89 ], [ %87, %85 ]
  %94 = getelementptr inbounds i8, ptr %92, i64 8
  %95 = getelementptr inbounds i8, ptr %91, i64 8
  store i64 %93, ptr %91, align 8, !tbaa !9
  %96 = load i64, ptr %94, align 8, !tbaa !9
  %97 = add nsw i64 %90, -1
  %98 = icmp eq i64 %97, 0
  br i1 %98, label %99, label %89, !llvm.loop !58

99:                                               ; preds = %89, %85
  %100 = phi ptr [ %8, %85 ], [ %95, %89 ]
  %101 = phi i64 [ %87, %85 ], [ %96, %89 ]
  store i64 %101, ptr %100, align 8, !tbaa !9
  br label %102

102:                                              ; preds = %99, %78
  %103 = icmp eq i64 %67, %82
  br i1 %103, label %108, label %104

104:                                              ; preds = %102
  %105 = sub i64 %67, %82
  %106 = getelementptr i64, ptr %8, i64 %82
  %107 = shl nuw i64 %105, 3
  call void @llvm.memset.p0.i64(ptr align 8 %106, i8 0, i64 %107, i1 false), !tbaa !9
  br label %108

108:                                              ; preds = %104, %102
  %109 = getelementptr inbounds i64, ptr %73, i64 %6
  %110 = mul nsw i64 %75, %7
  call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %72, ptr noundef %8, i64 noundef %110, i64 noundef %3)
  br label %113

111:                                              ; preds = %71
  br i1 %65, label %113, label %112

112:                                              ; preds = %111
  call void @llvm.memset.p0.i64(ptr align 8 %72, i8 0, i64 %70, i1 false), !tbaa !9
  br label %113

113:                                              ; preds = %112, %111, %108
  %114 = phi i64 [ %83, %108 ], [ %74, %111 ], [ %74, %112 ]
  %115 = phi ptr [ %109, %108 ], [ %73, %111 ], [ %73, %112 ]
  %116 = getelementptr i64, ptr %72, i64 %68
  %117 = add nuw nsw i64 %75, 1
  %118 = icmp eq i64 %117, %2
  br i1 %118, label %119, label %71, !llvm.loop !59

119:                                              ; preds = %113, %60
  %120 = phi i64 [ %61, %60 ], [ %114, %113 ]
  %121 = icmp eq i64 %120, 0
  br i1 %121, label %123, label %122, !prof !30

122:                                              ; preds = %119
  call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 811, ptr noundef nonnull @.str.5) #17
  unreachable

123:                                              ; preds = %119
  %124 = load ptr, ptr %10, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %124) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i64 @mpn_mul_fft_internal(ptr noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, ptr noundef %9, ptr noundef %10, i32 noundef %11) unnamed_addr #3 {
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
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %13) #15
  store ptr null, ptr %13, align 8, !tbaa !5
  %25 = select i1 %23, i64 360, i64 300
  %26 = icmp sgt i64 %25, %6
  br i1 %26, label %259, label %27

27:                                               ; preds = %21
  %28 = zext i1 %23 to i64
  %29 = getelementptr inbounds [2 x [16 x i64]], ptr @mpn_fft_table, i64 0, i64 %28, i64 0
  %30 = load i64, ptr %29, align 16, !tbaa !9
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
  %42 = load i64, ptr %41, align 8, !tbaa !9
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %44, label %32, !llvm.loop !47

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
  %53 = load i64, ptr %52, align 8, !tbaa !9
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
  br i1 %66, label %68, label %67, !prof !30

67:                                               ; preds = %60
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 492, ptr noundef nonnull @.str.6) #17
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
  %96 = load i64, ptr %95, align 8, !tbaa !9
  %97 = icmp eq i64 %96, 0
  br i1 %97, label %98, label %86, !llvm.loop !47

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
  %107 = load i64, ptr %106, align 8, !tbaa !9
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
  br label %83, !llvm.loop !60

127:                                              ; preds = %114, %68
  %128 = phi i64 [ %80, %68 ], [ %84, %114 ]
  %129 = phi i64 [ %81, %68 ], [ %85, %114 ]
  %130 = icmp slt i64 %129, %6
  br i1 %130, label %132, label %131, !prof !30

131:                                              ; preds = %127
  tail call void @__gmp_assert_fail(ptr noundef nonnull @.str.27, i32 noundef 514, ptr noundef nonnull @.str.7) #17
  unreachable

132:                                              ; preds = %127
  %133 = ashr i64 %128, %62
  %134 = shl i64 8, %62
  %135 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %134) #15
  %136 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %134) #15
  %137 = add nsw i64 %129, 1
  %138 = shl nsw i64 %137, 1
  %139 = shl i64 %138, %62
  %140 = shl i64 %139, 3
  %141 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %140) #15
  %142 = shl i64 %137, 4
  %143 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %142) #15
  %144 = shl i64 %137, %62
  %145 = getelementptr inbounds i64, ptr %141, i64 %144
  %146 = add nsw i32 %61, 1
  %147 = sext i32 %146 to i64
  %148 = shl nsw i64 %147, 3
  %149 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %148) #15
  %150 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %134) #15
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
  store ptr %157, ptr %158, align 8, !tbaa !5
  %159 = shl nuw i64 1, %156
  %160 = getelementptr inbounds i32, ptr %157, i64 %159
  %161 = add nuw nsw i64 %156, 1
  %162 = icmp eq i64 %161, %154
  br i1 %162, label %163, label %155, !llvm.loop !61

163:                                              ; preds = %155, %132
  %164 = load ptr, ptr %149, align 8, !tbaa !5
  store i32 0, ptr %164, align 4, !tbaa !49
  %165 = icmp slt i32 %61, 1
  br i1 %165, label %192, label %166

166:                                              ; preds = %163
  %167 = zext nneg i32 %146 to i64
  br label %168

168:                                              ; preds = %188, %166
  %169 = phi i64 [ 1, %166 ], [ %189, %188 ]
  %170 = phi i32 [ 1, %166 ], [ %190, %188 ]
  %171 = getelementptr inbounds ptr, ptr %149, i64 %169
  %172 = load ptr, ptr %171, align 8, !tbaa !5
  %173 = getelementptr i8, ptr %171, i64 -8
  %174 = load ptr, ptr %173, align 8, !tbaa !5
  %175 = sext i32 %170 to i64
  %176 = call i32 @llvm.umax.i32(i32 %170, i32 1)
  %177 = zext i32 %176 to i64
  br label %178

178:                                              ; preds = %178, %168
  %179 = phi i64 [ 0, %168 ], [ %186, %178 ]
  %180 = getelementptr inbounds i32, ptr %174, i64 %179
  %181 = load i32, ptr %180, align 4, !tbaa !49
  %182 = shl nsw i32 %181, 1
  %183 = getelementptr inbounds i32, ptr %172, i64 %179
  store i32 %182, ptr %183, align 4, !tbaa !49
  %184 = or disjoint i32 %182, 1
  %185 = getelementptr i32, ptr %183, i64 %175
  store i32 %184, ptr %185, align 4, !tbaa !49
  %186 = add nuw nsw i64 %179, 1
  %187 = icmp eq i64 %186, %177
  br i1 %187, label %188, label %178, !llvm.loop !51

188:                                              ; preds = %178
  %189 = add nuw nsw i64 %169, 1
  %190 = shl nsw i32 %170, 1
  %191 = icmp eq i64 %189, %167
  br i1 %191, label %192, label %168, !llvm.loop !52

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
  %206 = load ptr, ptr %204, align 8, !tbaa !5
  %207 = getelementptr inbounds i64, ptr %206, i64 %6
  %208 = load i64, ptr %207, align 8, !tbaa !9
  %209 = icmp eq i64 %208, 0
  br i1 %209, label %225, label %210

210:                                              ; preds = %210, %202
  %211 = phi ptr [ %212, %210 ], [ %206, %202 ]
  %212 = getelementptr inbounds i8, ptr %211, i64 8
  %213 = load i64, ptr %211, align 8, !tbaa !9
  %214 = add i64 %213, -1
  store i64 %214, ptr %211, align 8, !tbaa !9
  %215 = icmp eq i64 %213, 0
  br i1 %215, label %210, label %216, !llvm.loop !62

216:                                              ; preds = %210
  %217 = load i64, ptr %207, align 8, !tbaa !9
  %218 = icmp ne i64 %217, 0
  %219 = or i1 %218, %195
  %220 = xor i1 %218, true
  %221 = zext i1 %220 to i64
  br i1 %219, label %223, label %222

222:                                              ; preds = %216
  call void @llvm.memset.p0.i64(ptr align 8 %206, i8 0, i64 %196, i1 false), !tbaa !9
  br label %223

223:                                              ; preds = %222, %216
  %224 = phi i64 [ 1, %222 ], [ %221, %216 ]
  store i64 %224, ptr %207, align 8, !tbaa !9
  br label %225

225:                                              ; preds = %223, %202
  br i1 %23, label %249, label %226

226:                                              ; preds = %225
  %227 = load ptr, ptr %205, align 8, !tbaa !5
  %228 = getelementptr inbounds i64, ptr %227, i64 %6
  %229 = load i64, ptr %228, align 8, !tbaa !9
  %230 = icmp eq i64 %229, 0
  br i1 %230, label %246, label %231

231:                                              ; preds = %231, %226
  %232 = phi ptr [ %233, %231 ], [ %227, %226 ]
  %233 = getelementptr inbounds i8, ptr %232, i64 8
  %234 = load i64, ptr %232, align 8, !tbaa !9
  %235 = add i64 %234, -1
  store i64 %235, ptr %232, align 8, !tbaa !9
  %236 = icmp eq i64 %234, 0
  br i1 %236, label %231, label %237, !llvm.loop !62

237:                                              ; preds = %231
  %238 = load i64, ptr %228, align 8, !tbaa !9
  %239 = icmp ne i64 %238, 0
  %240 = or i1 %239, %197
  %241 = xor i1 %239, true
  %242 = zext i1 %241 to i64
  br i1 %240, label %244, label %243

243:                                              ; preds = %237
  call void @llvm.memset.p0.i64(ptr align 8 %227, i8 0, i64 %198, i1 false), !tbaa !9
  br label %244

244:                                              ; preds = %243, %237
  %245 = phi i64 [ 1, %243 ], [ %242, %237 ]
  store i64 %245, ptr %228, align 8, !tbaa !9
  br label %246

246:                                              ; preds = %244, %226
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %141, ptr noundef %135, i64 noundef %63, i64 noundef %129, ptr noundef %206, i64 noundef %200, i64 noundef %72, i64 noundef %133, ptr noundef %143)
  br i1 %23, label %250, label %247

247:                                              ; preds = %246
  %248 = load ptr, ptr %205, align 8, !tbaa !5
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %145, ptr noundef %136, i64 noundef %63, i64 noundef %129, ptr noundef %248, i64 noundef %200, i64 noundef %72, i64 noundef %133, ptr noundef %143)
  br label %250

249:                                              ; preds = %225
  call fastcc void @mpn_mul_fft_decompose(ptr noundef %141, ptr noundef %135, i64 noundef %63, i64 noundef %129, ptr noundef %206, i64 noundef %200, i64 noundef %72, i64 noundef %133, ptr noundef %143)
  br label %250

250:                                              ; preds = %249, %247, %246
  %251 = load ptr, ptr %204, align 8, !tbaa !5
  %252 = call fastcc i64 @mpn_mul_fft_internal(ptr noundef %251, i64 noundef %6, i32 noundef %61, ptr noundef %135, ptr noundef %136, ptr noundef %145, i64 noundef %129, i64 noundef %72, i64 noundef %133, ptr noundef nonnull %149, ptr noundef %143, i32 noundef %24)
  %253 = load ptr, ptr %204, align 8, !tbaa !5
  %254 = getelementptr inbounds i64, ptr %253, i64 %6
  store i64 %252, ptr %254, align 8, !tbaa !9
  %255 = add nuw nsw i64 %203, 1
  %256 = getelementptr inbounds i8, ptr %204, i64 8
  %257 = getelementptr inbounds i8, ptr %205, i64 8
  %258 = icmp eq i64 %255, %201
  br i1 %258, label %383, label %202, !llvm.loop !63

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
  %289 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %288) #15
  br i1 %286, label %383, label %290

290:                                              ; preds = %287
  %291 = call i64 @llvm.smax.i64(i64 %15, i64 1)
  br label %292

292:                                              ; preds = %292, %290
  %293 = phi i64 [ 0, %290 ], [ %297, %292 ]
  %294 = phi ptr [ %3, %290 ], [ %295, %292 ]
  %295 = getelementptr inbounds i8, ptr %294, i64 8
  %296 = load ptr, ptr %294, align 8, !tbaa !5
  call void @__gmpn_sqrmod_bknp1(ptr noundef %296, ptr noundef %296, i64 noundef %285, i32 noundef %283, ptr noundef %289) #15
  %297 = add nuw nsw i64 %293, 1
  %298 = icmp eq i64 %297, %291
  br i1 %298, label %383, label %292, !llvm.loop !64

299:                                              ; preds = %282
  %300 = shl i64 %6, 5
  %301 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %300) #15
  br i1 %286, label %383, label %302

302:                                              ; preds = %299
  %303 = call i64 @llvm.smax.i64(i64 %15, i64 1)
  br label %304

304:                                              ; preds = %304, %302
  %305 = phi i64 [ 0, %302 ], [ %312, %304 ]
  %306 = phi ptr [ %3, %302 ], [ %308, %304 ]
  %307 = phi ptr [ %22, %302 ], [ %310, %304 ]
  %308 = getelementptr inbounds i8, ptr %306, i64 8
  %309 = load ptr, ptr %306, align 8, !tbaa !5
  %310 = getelementptr inbounds i8, ptr %307, i64 8
  %311 = load ptr, ptr %307, align 8, !tbaa !5
  call void @__gmpn_mulmod_bknp1(ptr noundef %309, ptr noundef %309, ptr noundef %311, i64 noundef %285, i32 noundef %283, ptr noundef %301) #15
  %312 = add nuw nsw i64 %305, 1
  %313 = icmp eq i64 %312, %303
  br i1 %313, label %383, label %304, !llvm.loop !65

314:                                              ; preds = %277, %272, %264, %259
  %315 = shl i64 %6, 4
  %316 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %13, i64 noundef %315) #15
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
  %328 = load ptr, ptr %325, align 8, !tbaa !5
  %329 = getelementptr inbounds i8, ptr %326, i64 8
  %330 = load ptr, ptr %326, align 8, !tbaa !5
  br i1 %23, label %331, label %332

331:                                              ; preds = %323
  call void @__gmpn_sqr(ptr noundef %316, ptr noundef %328, i64 noundef %6) #15
  br label %333

332:                                              ; preds = %323
  call void @__gmpn_mul_n(ptr noundef %316, ptr noundef %330, ptr noundef %328, i64 noundef %6) #15
  br label %333

333:                                              ; preds = %332, %331
  %334 = getelementptr inbounds i64, ptr %328, i64 %6
  %335 = load i64, ptr %334, align 8, !tbaa !9
  %336 = icmp eq i64 %335, 0
  br i1 %336, label %339, label %337

337:                                              ; preds = %333
  %338 = call i64 @__gmpn_add_n(ptr noundef %317, ptr noundef %317, ptr noundef %330, i64 noundef %6) #15
  br label %339

339:                                              ; preds = %337, %333
  %340 = phi i64 [ %338, %337 ], [ 0, %333 ]
  %341 = getelementptr inbounds i64, ptr %330, i64 %6
  %342 = load i64, ptr %341, align 8, !tbaa !9
  %343 = icmp eq i64 %342, 0
  br i1 %343, label %349, label %344

344:                                              ; preds = %339
  %345 = call i64 @__gmpn_add_n(ptr noundef %317, ptr noundef %317, ptr noundef %328, i64 noundef %6) #15
  %346 = load i64, ptr %334, align 8, !tbaa !9
  %347 = add i64 %345, %340
  %348 = add i64 %347, %346
  br label %349

349:                                              ; preds = %344, %339
  %350 = phi i64 [ %348, %344 ], [ %340, %339 ]
  %351 = icmp eq i64 %350, 0
  br i1 %351, label %369, label %352

352:                                              ; preds = %349
  %353 = load i64, ptr %316, align 8, !tbaa !9
  %354 = add i64 %353, %350
  store i64 %354, ptr %316, align 8, !tbaa !9
  %355 = icmp ult i64 %354, %350
  br i1 %355, label %356, label %365

356:                                              ; preds = %359, %352
  %357 = phi i64 [ %363, %359 ], [ 1, %352 ]
  %358 = icmp eq i64 %357, %321
  br i1 %358, label %365, label %359

359:                                              ; preds = %356
  %360 = getelementptr inbounds i64, ptr %316, i64 %357
  %361 = load i64, ptr %360, align 8, !tbaa !9
  %362 = add i64 %361, 1
  store i64 %362, ptr %360, align 8, !tbaa !9
  %363 = add nuw i64 %357, 1
  %364 = icmp eq i64 %362, 0
  br i1 %364, label %356, label %365, !llvm.loop !66

365:                                              ; preds = %359, %356, %352
  %366 = phi i64 [ 0, %352 ], [ 1, %356 ], [ 0, %359 ]
  %367 = load i64, ptr %316, align 8, !tbaa !9
  %368 = add i64 %367, %366
  store i64 %368, ptr %316, align 8, !tbaa !9
  br label %369

369:                                              ; preds = %365, %349
  %370 = call i64 @__gmpn_sub_n(ptr noundef %328, ptr noundef %316, ptr noundef %317, i64 noundef %6) #15
  store i64 0, ptr %334, align 8, !tbaa !9
  %371 = load i64, ptr %328, align 8, !tbaa !9
  %372 = add i64 %371, %370
  store i64 %372, ptr %328, align 8, !tbaa !9
  %373 = icmp ult i64 %372, %370
  br i1 %373, label %374, label %380

374:                                              ; preds = %374, %369
  %375 = phi ptr [ %376, %374 ], [ %328, %369 ]
  %376 = getelementptr inbounds i8, ptr %375, i64 8
  %377 = load i64, ptr %376, align 8, !tbaa !9
  %378 = add i64 %377, 1
  store i64 %378, ptr %376, align 8, !tbaa !9
  %379 = icmp eq i64 %378, 0
  br i1 %379, label %374, label %380, !llvm.loop !67

380:                                              ; preds = %374, %369
  %381 = add nuw nsw i64 %324, 1
  %382 = icmp eq i64 %381, %322
  br i1 %382, label %383, label %323, !llvm.loop !68

383:                                              ; preds = %380, %314, %304, %299, %292, %287, %250, %192
  %384 = load ptr, ptr %13, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %384) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %13) #15
  call fastcc void @mpn_fft_fftinv(ptr noundef %3, i64 noundef %15, i64 noundef %18, i64 noundef %6, ptr noundef %10)
  %385 = getelementptr inbounds i64, ptr %10, i64 %6
  %386 = getelementptr inbounds i8, ptr %385, i64 8
  store ptr %386, ptr %4, align 8, !tbaa !5
  %387 = load ptr, ptr %3, align 8, !tbaa !5
  %388 = shl i64 %6, 7
  %389 = sub i64 %388, %16
  call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef nonnull %386, ptr noundef %387, i64 noundef %389, i64 noundef %6)
  %390 = getelementptr inbounds i64, ptr %386, i64 %6
  %391 = load i64, ptr %390, align 8, !tbaa !9
  %392 = icmp eq i64 %391, 0
  br i1 %392, label %408, label %393

393:                                              ; preds = %393, %383
  %394 = phi ptr [ %395, %393 ], [ %386, %383 ]
  %395 = getelementptr inbounds i8, ptr %394, i64 8
  %396 = load i64, ptr %394, align 8, !tbaa !9
  %397 = add i64 %396, -1
  store i64 %397, ptr %394, align 8, !tbaa !9
  %398 = icmp eq i64 %396, 0
  br i1 %398, label %393, label %399, !llvm.loop !62

399:                                              ; preds = %393
  %400 = load i64, ptr %390, align 8, !tbaa !9
  %401 = icmp eq i64 %400, 0
  br i1 %401, label %402, label %406

402:                                              ; preds = %399
  %403 = icmp eq i64 %6, 0
  br i1 %403, label %406, label %404

404:                                              ; preds = %402
  %405 = shl nuw i64 %6, 3
  call void @llvm.memset.p0.i64(ptr nonnull align 8 %386, i8 0, i64 %405, i1 false), !tbaa !9
  br label %406

406:                                              ; preds = %404, %402, %399
  %407 = phi i64 [ 1, %404 ], [ 1, %402 ], [ 0, %399 ]
  store i64 %407, ptr %390, align 8, !tbaa !9
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
  %418 = load ptr, ptr %417, align 8, !tbaa !5
  %419 = getelementptr inbounds ptr, ptr %4, i64 %415
  store ptr %418, ptr %419, align 8, !tbaa !5
  %420 = load ptr, ptr %416, align 8, !tbaa !5
  %421 = sub nsw i64 %415, %15
  %422 = mul i64 %421, %8
  %423 = add i64 %411, %422
  call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %418, ptr noundef %420, i64 noundef %423, i64 noundef %6)
  %424 = getelementptr inbounds i64, ptr %418, i64 %6
  %425 = load i64, ptr %424, align 8, !tbaa !9
  %426 = icmp eq i64 %425, 0
  br i1 %426, label %442, label %427

427:                                              ; preds = %427, %414
  %428 = phi ptr [ %429, %427 ], [ %418, %414 ]
  %429 = getelementptr inbounds i8, ptr %428, i64 8
  %430 = load i64, ptr %428, align 8, !tbaa !9
  %431 = add i64 %430, -1
  store i64 %431, ptr %428, align 8, !tbaa !9
  %432 = icmp eq i64 %430, 0
  br i1 %432, label %427, label %433, !llvm.loop !62

433:                                              ; preds = %427
  %434 = load i64, ptr %424, align 8, !tbaa !9
  %435 = icmp ne i64 %434, 0
  %436 = or i1 %435, %412
  %437 = xor i1 %435, true
  %438 = zext i1 %437 to i64
  br i1 %436, label %440, label %439

439:                                              ; preds = %433
  call void @llvm.memset.p0.i64(ptr align 8 %418, i8 0, i64 %413, i1 false), !tbaa !9
  br label %440

440:                                              ; preds = %439, %433
  %441 = phi i64 [ 1, %439 ], [ %438, %433 ]
  store i64 %441, ptr %424, align 8, !tbaa !9
  br label %442

442:                                              ; preds = %440, %414
  %443 = add nuw nsw i64 %415, 1
  %444 = icmp eq i64 %443, %15
  br i1 %444, label %445, label %414, !llvm.loop !69

445:                                              ; preds = %442, %408
  %446 = add nsw i64 %6, 1
  %447 = icmp eq i64 %446, 0
  br i1 %447, label %451, label %448

448:                                              ; preds = %445
  %449 = shl i64 %6, 3
  %450 = add i64 %449, 8
  call void @llvm.memset.p0.i64(ptr align 8 %10, i8 0, i64 %450, i1 false), !tbaa !9
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
  call void @llvm.memset.p0.i64(ptr align 8 %5, i8 0, i64 %458, i1 false), !tbaa !9
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
  %475 = load ptr, ptr %473, align 8, !tbaa !5
  %476 = call i64 @__gmpn_add_n(ptr noundef %469, ptr noundef %469, ptr noundef %475, i64 noundef %446) #15
  %477 = icmp eq i64 %476, 0
  br i1 %477, label %487, label %478

478:                                              ; preds = %481, %474
  %479 = phi i64 [ %485, %481 ], [ %446, %474 ]
  %480 = icmp slt i64 %479, %472
  br i1 %480, label %481, label %487

481:                                              ; preds = %478
  %482 = getelementptr inbounds i64, ptr %469, i64 %479
  %483 = load i64, ptr %482, align 8, !tbaa !9
  %484 = add i64 %483, 1
  %485 = add nsw i64 %479, 1
  store i64 %484, ptr %482, align 8, !tbaa !9
  %486 = icmp eq i64 %484, 0
  br i1 %486, label %478, label %487, !llvm.loop !70

487:                                              ; preds = %481, %478, %474, %464
  %488 = phi i64 [ 0, %474 ], [ 0, %464 ], [ 1, %478 ], [ 0, %481 ]
  %489 = add i64 %488, %467
  %490 = add nuw nsw i64 %465, 1
  store i64 %490, ptr %463, align 8, !tbaa !9
  %491 = load ptr, ptr %473, align 8, !tbaa !5
  br label %492

492:                                              ; preds = %495, %487
  %493 = phi i64 [ %446, %487 ], [ %496, %495 ]
  %494 = icmp sgt i64 %493, 0
  br i1 %494, label %495, label %541

495:                                              ; preds = %492
  %496 = add nsw i64 %493, -1
  %497 = getelementptr inbounds i64, ptr %491, i64 %496
  %498 = load i64, ptr %497, align 8, !tbaa !9
  %499 = getelementptr inbounds i64, ptr %10, i64 %496
  %500 = load i64, ptr %499, align 8, !tbaa !9
  %501 = icmp eq i64 %498, %500
  br i1 %501, label %492, label %502, !llvm.loop !71

502:                                              ; preds = %495
  %503 = icmp ugt i64 %498, %500
  br i1 %503, label %504, label %541

504:                                              ; preds = %502
  %505 = load i64, ptr %469, align 8, !tbaa !9
  %506 = add i64 %505, -1
  store i64 %506, ptr %469, align 8, !tbaa !9
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
  %515 = load i64, ptr %514, align 8, !tbaa !9
  %516 = add i64 %515, -1
  store i64 %516, ptr %514, align 8, !tbaa !9
  %517 = add nuw i64 %511, 1
  %518 = icmp eq i64 %515, 0
  br i1 %518, label %510, label %519, !llvm.loop !72

519:                                              ; preds = %513, %510, %504
  %520 = phi i64 [ 0, %504 ], [ -1, %510 ], [ 0, %513 ]
  %521 = getelementptr inbounds i64, ptr %5, i64 %466
  %522 = load i64, ptr %521, align 8, !tbaa !9
  %523 = add i64 %522, -1
  store i64 %523, ptr %521, align 8, !tbaa !9
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
  %533 = load i64, ptr %532, align 8, !tbaa !9
  %534 = add i64 %533, -1
  store i64 %534, ptr %532, align 8, !tbaa !9
  %535 = add nuw i64 %529, 1
  %536 = icmp eq i64 %533, 0
  br i1 %536, label %528, label %537, !llvm.loop !72

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
  br i1 %546, label %464, label %547, !llvm.loop !73

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
  %553 = load i64, ptr %552, align 8, !tbaa !9
  %554 = add i64 %553, 1
  store i64 %554, ptr %552, align 8, !tbaa !9
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
  %563 = load i64, ptr %562, align 8, !tbaa !9
  %564 = add i64 %563, 1
  store i64 %564, ptr %562, align 8, !tbaa !9
  %565 = add nuw i64 %559, 1
  %566 = icmp eq i64 %564, 0
  br i1 %566, label %558, label %624, !llvm.loop !66

567:                                              ; preds = %558
  %568 = getelementptr inbounds i8, ptr %552, i64 -8
  %569 = load i64, ptr %568, align 8, !tbaa !9
  %570 = add i64 %569, -1
  store i64 %570, ptr %568, align 8, !tbaa !9
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
  %580 = load i64, ptr %579, align 8, !tbaa !9
  %581 = add i64 %580, -1
  store i64 %581, ptr %579, align 8, !tbaa !9
  %582 = add nuw i64 %576, 1
  %583 = icmp eq i64 %580, 0
  br i1 %583, label %575, label %584, !llvm.loop !72

584:                                              ; preds = %578, %575, %567
  %585 = getelementptr inbounds i8, ptr %550, i64 -8
  %586 = load i64, ptr %585, align 8, !tbaa !9
  %587 = add i64 %586, -1
  store i64 %587, ptr %585, align 8, !tbaa !9
  br label %624

588:                                              ; preds = %547
  %589 = shl nsw i64 %1, 1
  %590 = icmp slt i64 %455, %589
  %591 = getelementptr inbounds i64, ptr %5, i64 %455
  br i1 %590, label %614, label %592

592:                                              ; preds = %588
  %593 = sub i64 0, %589
  %594 = getelementptr inbounds i64, ptr %591, i64 %593
  %595 = load i64, ptr %594, align 8, !tbaa !9
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
  %607 = load i64, ptr %606, align 8, !tbaa !9
  %608 = add i64 %607, 1
  store i64 %608, ptr %606, align 8, !tbaa !9
  %609 = add nuw i64 %603, 1
  %610 = icmp eq i64 %608, 0
  br i1 %610, label %602, label %611, !llvm.loop !66

611:                                              ; preds = %605, %602, %597
  %612 = phi i1 [ true, %597 ], [ %604, %602 ], [ %604, %605 ]
  %613 = phi i64 [ 0, %597 ], [ 0, %605 ], [ 1, %602 ]
  br i1 %612, label %623, label %597, !llvm.loop !74

614:                                              ; preds = %588
  %615 = sub i64 0, %1
  %616 = getelementptr inbounds i64, ptr %591, i64 %615
  br label %617

617:                                              ; preds = %617, %614
  %618 = phi ptr [ %616, %614 ], [ %619, %617 ]
  %619 = getelementptr inbounds i8, ptr %618, i64 8
  %620 = load i64, ptr %618, align 8, !tbaa !9
  %621 = add i64 %620, -1
  store i64 %621, ptr %618, align 8, !tbaa !9
  %622 = icmp eq i64 %620, 0
  br i1 %622, label %617, label %624, !llvm.loop !75

623:                                              ; preds = %611
  store i64 %600, ptr %594, align 8, !tbaa !9
  br label %624

624:                                              ; preds = %623, %617, %584, %561, %549, %547
  %625 = shl nsw i64 %1, 1
  %626 = sub nsw i64 %455, %625
  %627 = icmp sgt i64 %626, 0
  br i1 %627, label %628, label %671

628:                                              ; preds = %624
  %629 = getelementptr inbounds i64, ptr %5, i64 %625
  %630 = call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %5, ptr noundef %629, i64 noundef %626) #15
  %631 = getelementptr inbounds i64, ptr %0, i64 %626
  %632 = getelementptr inbounds i64, ptr %5, i64 %626
  %633 = sub nsw i64 %1, %626
  %634 = load i64, ptr %632, align 8, !tbaa !9
  %635 = add i64 %634, %630
  store i64 %635, ptr %631, align 8, !tbaa !9
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
  %644 = load i64, ptr %643, align 8, !tbaa !9
  %645 = add i64 %644, 1
  %646 = getelementptr inbounds i64, ptr %631, i64 %640
  store i64 %645, ptr %646, align 8, !tbaa !9
  %647 = add nuw i64 %640, 1
  %648 = icmp eq i64 %645, 0
  br i1 %648, label %639, label %649, !llvm.loop !66

649:                                              ; preds = %642
  %650 = icmp ne ptr %5, %0
  %651 = icmp slt i64 %647, %633
  %652 = select i1 %650, i1 %651, i1 false
  br i1 %652, label %653, label %691

653:                                              ; preds = %653, %649
  %654 = phi i64 [ %658, %653 ], [ %647, %649 ]
  %655 = getelementptr inbounds i64, ptr %632, i64 %654
  %656 = load i64, ptr %655, align 8, !tbaa !9
  %657 = getelementptr inbounds i64, ptr %631, i64 %654
  store i64 %656, ptr %657, align 8, !tbaa !9
  %658 = add nuw nsw i64 %654, 1
  %659 = icmp slt i64 %658, %633
  br i1 %659, label %653, label %691, !llvm.loop !76

660:                                              ; preds = %628
  %661 = icmp ne ptr %5, %0
  %662 = icmp sgt i64 %633, 1
  %663 = and i1 %661, %662
  br i1 %663, label %664, label %691

664:                                              ; preds = %664, %660
  %665 = phi i64 [ %669, %664 ], [ 1, %660 ]
  %666 = getelementptr inbounds i64, ptr %632, i64 %665
  %667 = load i64, ptr %666, align 8, !tbaa !9
  %668 = getelementptr inbounds i64, ptr %631, i64 %665
  store i64 %667, ptr %668, align 8, !tbaa !9
  %669 = add nuw nsw i64 %665, 1
  %670 = icmp eq i64 %669, %633
  br i1 %670, label %691, label %664, !llvm.loop !77

671:                                              ; preds = %624
  %672 = sub nsw i64 %455, %1
  %673 = icmp eq i64 %1, 0
  br i1 %673, label %691, label %674

674:                                              ; preds = %671
  %675 = add nsw i64 %1, -1
  %676 = load i64, ptr %5, align 8, !tbaa !9
  %677 = icmp eq i64 %675, 0
  br i1 %677, label %688, label %678

678:                                              ; preds = %678, %674
  %679 = phi i64 [ %686, %678 ], [ %675, %674 ]
  %680 = phi ptr [ %684, %678 ], [ %0, %674 ]
  %681 = phi ptr [ %683, %678 ], [ %5, %674 ]
  %682 = phi i64 [ %685, %678 ], [ %676, %674 ]
  %683 = getelementptr inbounds i8, ptr %681, i64 8
  %684 = getelementptr inbounds i8, ptr %680, i64 8
  store i64 %682, ptr %680, align 8, !tbaa !9
  %685 = load i64, ptr %683, align 8, !tbaa !9
  %686 = add nsw i64 %679, -1
  %687 = icmp eq i64 %686, 0
  br i1 %687, label %688, label %678, !llvm.loop !78

688:                                              ; preds = %678, %674
  %689 = phi ptr [ %0, %674 ], [ %684, %678 ]
  %690 = phi i64 [ %676, %674 ], [ %685, %678 ]
  store i64 %690, ptr %689, align 8, !tbaa !9
  br label %691

691:                                              ; preds = %688, %671, %664, %660, %653, %649, %639
  %692 = phi i64 [ 0, %688 ], [ 0, %671 ], [ 0, %649 ], [ 0, %660 ], [ 0, %653 ], [ 1, %639 ], [ 0, %664 ]
  %693 = phi i64 [ %672, %688 ], [ %672, %671 ], [ %1, %649 ], [ %1, %660 ], [ %1, %653 ], [ %1, %639 ], [ %1, %664 ]
  %694 = icmp eq i64 %693, 0
  br i1 %694, label %708, label %695

695:                                              ; preds = %691
  %696 = getelementptr inbounds i64, ptr %5, i64 %1
  %697 = call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %0, ptr noundef %696, i64 noundef %693) #15
  %698 = icmp eq i64 %697, 0
  br i1 %698, label %708, label %699

699:                                              ; preds = %702, %695
  %700 = phi i64 [ %706, %702 ], [ %693, %695 ]
  %701 = icmp slt i64 %700, %1
  br i1 %701, label %702, label %708

702:                                              ; preds = %699
  %703 = getelementptr inbounds i64, ptr %0, i64 %700
  %704 = load i64, ptr %703, align 8, !tbaa !9
  %705 = add i64 %704, -1
  %706 = add nsw i64 %700, 1
  store i64 %705, ptr %703, align 8, !tbaa !9
  %707 = icmp eq i64 %704, 0
  br i1 %707, label %699, label %708, !llvm.loop !56

708:                                              ; preds = %702, %699, %695, %691
  %709 = phi i64 [ 0, %695 ], [ 0, %691 ], [ -1, %699 ], [ 0, %702 ]
  %710 = add nsw i64 %709, %692
  %711 = icmp slt i64 %710, 0
  br i1 %711, label %712, label %727

712:                                              ; preds = %708
  %713 = load i64, ptr %0, align 8, !tbaa !9
  %714 = add i64 %713, 1
  store i64 %714, ptr %0, align 8, !tbaa !9
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
  %723 = load i64, ptr %722, align 8, !tbaa !9
  %724 = add i64 %723, 1
  store i64 %724, ptr %722, align 8, !tbaa !9
  %725 = add nuw i64 %719, 1
  %726 = icmp eq i64 %724, 0
  br i1 %726, label %718, label %727, !llvm.loop !66

727:                                              ; preds = %721, %718, %712, %708
  %728 = phi i64 [ %710, %708 ], [ 0, %712 ], [ 1, %718 ], [ 0, %721 ]
  ret i64 %728
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_fft_fft(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, ptr noundef %6) unnamed_addr #3 {
  %8 = icmp eq i64 %1, 2
  br i1 %8, label %9, label %67

9:                                                ; preds = %7
  %10 = add nsw i64 %4, 1
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %29, label %12

12:                                               ; preds = %9
  %13 = load ptr, ptr %0, align 8, !tbaa !5
  %14 = load i64, ptr %13, align 8, !tbaa !9
  %15 = icmp eq i64 %4, 0
  br i1 %15, label %26, label %16

16:                                               ; preds = %16, %12
  %17 = phi i64 [ %23, %16 ], [ %14, %12 ]
  %18 = phi ptr [ %21, %16 ], [ %13, %12 ]
  %19 = phi ptr [ %22, %16 ], [ %6, %12 ]
  %20 = phi i64 [ %24, %16 ], [ %4, %12 ]
  %21 = getelementptr inbounds i8, ptr %18, i64 8
  %22 = getelementptr inbounds i8, ptr %19, i64 8
  store i64 %17, ptr %19, align 8, !tbaa !9
  %23 = load i64, ptr %21, align 8, !tbaa !9
  %24 = add nsw i64 %20, -1
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %26, label %16, !llvm.loop !79

26:                                               ; preds = %16, %12
  %27 = phi i64 [ %14, %12 ], [ %23, %16 ]
  %28 = phi ptr [ %6, %12 ], [ %22, %16 ]
  store i64 %27, ptr %28, align 8, !tbaa !9
  br label %29

29:                                               ; preds = %26, %9
  %30 = load ptr, ptr %0, align 8, !tbaa !5
  %31 = getelementptr inbounds ptr, ptr %0, i64 %5
  %32 = load ptr, ptr %31, align 8, !tbaa !5
  %33 = tail call i64 @__gmpn_add_n(ptr noundef %30, ptr noundef %30, ptr noundef %32, i64 noundef %10) #15
  %34 = load ptr, ptr %31, align 8, !tbaa !5
  %35 = tail call i64 @__gmpn_sub_n(ptr noundef %34, ptr noundef %6, ptr noundef %34, i64 noundef %10) #15
  %36 = load ptr, ptr %0, align 8, !tbaa !5
  %37 = getelementptr inbounds i64, ptr %36, i64 %4
  %38 = load i64, ptr %37, align 8, !tbaa !9
  %39 = icmp ugt i64 %38, 1
  br i1 %39, label %40, label %51

40:                                               ; preds = %29
  store i64 1, ptr %37, align 8, !tbaa !9
  %41 = add i64 %38, -1
  %42 = load i64, ptr %36, align 8, !tbaa !9
  %43 = sub i64 %42, %41
  store i64 %43, ptr %36, align 8, !tbaa !9
  %44 = icmp ult i64 %42, %41
  br i1 %44, label %45, label %51

45:                                               ; preds = %45, %40
  %46 = phi ptr [ %47, %45 ], [ %36, %40 ]
  %47 = getelementptr inbounds i8, ptr %46, i64 8
  %48 = load i64, ptr %47, align 8, !tbaa !9
  %49 = add i64 %48, -1
  store i64 %49, ptr %47, align 8, !tbaa !9
  %50 = icmp eq i64 %48, 0
  br i1 %50, label %45, label %51, !llvm.loop !80

51:                                               ; preds = %45, %40, %29
  %52 = icmp eq i64 %35, 0
  br i1 %52, label %132, label %53

53:                                               ; preds = %51
  %54 = load ptr, ptr %31, align 8, !tbaa !5
  %55 = getelementptr inbounds i64, ptr %54, i64 %4
  %56 = load i64, ptr %55, align 8, !tbaa !9
  store i64 0, ptr %55, align 8, !tbaa !9
  %57 = sub i64 0, %56
  %58 = load i64, ptr %54, align 8, !tbaa !9
  %59 = sub i64 %58, %56
  store i64 %59, ptr %54, align 8, !tbaa !9
  %60 = icmp ult i64 %59, %57
  br i1 %60, label %61, label %132

61:                                               ; preds = %61, %53
  %62 = phi ptr [ %63, %61 ], [ %54, %53 ]
  %63 = getelementptr inbounds i8, ptr %62, i64 8
  %64 = load i64, ptr %63, align 8, !tbaa !9
  %65 = add i64 %64, 1
  store i64 %65, ptr %63, align 8, !tbaa !9
  %66 = icmp eq i64 %65, 0
  br i1 %66, label %61, label %132, !llvm.loop !81

67:                                               ; preds = %7
  %68 = ashr i64 %1, 1
  %69 = load ptr, ptr %2, align 8, !tbaa !5
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
  %82 = load ptr, ptr %81, align 8, !tbaa !5
  %83 = load i32, ptr %78, align 4, !tbaa !49
  %84 = sext i32 %83 to i64
  %85 = mul nsw i64 %84, %3
  tail call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %6, ptr noundef %82, i64 noundef %85, i64 noundef %4)
  %86 = load ptr, ptr %81, align 8, !tbaa !5
  %87 = load ptr, ptr %79, align 8, !tbaa !5
  %88 = getelementptr inbounds i64, ptr %87, i64 %4
  %89 = load i64, ptr %88, align 8, !tbaa !9
  %90 = load i64, ptr %76, align 8, !tbaa !9
  %91 = tail call i64 @__gmpn_sub_n(ptr noundef %86, ptr noundef %87, ptr noundef %6, i64 noundef %4) #15
  %92 = add i64 %90, %91
  %93 = sub i64 %89, %92
  %94 = sub i64 0, %93
  %95 = icmp slt i64 %93, 0
  %96 = select i1 %95, i64 %94, i64 0
  %97 = add i64 %96, %93
  %98 = getelementptr inbounds i64, ptr %86, i64 %4
  store i64 %97, ptr %98, align 8, !tbaa !9
  %99 = load i64, ptr %86, align 8, !tbaa !9
  %100 = add i64 %99, %96
  store i64 %100, ptr %86, align 8, !tbaa !9
  %101 = icmp ult i64 %100, %96
  br i1 %101, label %102, label %108

102:                                              ; preds = %102, %77
  %103 = phi ptr [ %104, %102 ], [ %86, %77 ]
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = load i64, ptr %104, align 8, !tbaa !9
  %106 = add i64 %105, 1
  store i64 %106, ptr %104, align 8, !tbaa !9
  %107 = icmp eq i64 %106, 0
  br i1 %107, label %102, label %108, !llvm.loop !82

108:                                              ; preds = %102, %77
  %109 = load ptr, ptr %79, align 8, !tbaa !5
  %110 = getelementptr inbounds i64, ptr %109, i64 %4
  %111 = load i64, ptr %110, align 8, !tbaa !9
  %112 = load i64, ptr %76, align 8, !tbaa !9
  %113 = add i64 %112, %111
  %114 = tail call i64 @__gmpn_add_n(ptr noundef %109, ptr noundef %109, ptr noundef %6, i64 noundef %4) #15
  %115 = add i64 %113, %114
  %116 = tail call i64 @llvm.usub.sat.i64(i64 %115, i64 1)
  %117 = sub i64 %115, %116
  store i64 %117, ptr %110, align 8, !tbaa !9
  %118 = load i64, ptr %109, align 8, !tbaa !9
  %119 = sub i64 %118, %116
  store i64 %119, ptr %109, align 8, !tbaa !9
  %120 = icmp ult i64 %118, %116
  br i1 %120, label %121, label %127

121:                                              ; preds = %121, %108
  %122 = phi ptr [ %123, %121 ], [ %109, %108 ]
  %123 = getelementptr inbounds i8, ptr %122, i64 8
  %124 = load i64, ptr %123, align 8, !tbaa !9
  %125 = add i64 %124, -1
  store i64 %125, ptr %123, align 8, !tbaa !9
  %126 = icmp eq i64 %124, 0
  br i1 %126, label %121, label %127, !llvm.loop !83

127:                                              ; preds = %121, %108
  %128 = add nuw nsw i64 %80, 1
  %129 = getelementptr inbounds i8, ptr %78, i64 8
  %130 = getelementptr inbounds ptr, ptr %79, i64 %72
  %131 = icmp eq i64 %128, %68
  br i1 %131, label %132, label %77, !llvm.loop !84

132:                                              ; preds = %127, %67, %61, %53, %51
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_fft_fftinv(ptr noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, ptr noundef %4) unnamed_addr #3 {
  %6 = icmp eq i64 %1, 2
  br i1 %6, label %7, label %65

7:                                                ; preds = %5
  %8 = add nsw i64 %3, 1
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %27, label %10

10:                                               ; preds = %7
  %11 = load ptr, ptr %0, align 8, !tbaa !5
  %12 = load i64, ptr %11, align 8, !tbaa !9
  %13 = icmp eq i64 %3, 0
  br i1 %13, label %24, label %14

14:                                               ; preds = %14, %10
  %15 = phi i64 [ %21, %14 ], [ %12, %10 ]
  %16 = phi ptr [ %19, %14 ], [ %11, %10 ]
  %17 = phi ptr [ %20, %14 ], [ %4, %10 ]
  %18 = phi i64 [ %22, %14 ], [ %3, %10 ]
  %19 = getelementptr inbounds i8, ptr %16, i64 8
  %20 = getelementptr inbounds i8, ptr %17, i64 8
  store i64 %15, ptr %17, align 8, !tbaa !9
  %21 = load i64, ptr %19, align 8, !tbaa !9
  %22 = add nsw i64 %18, -1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %24, label %14, !llvm.loop !85

24:                                               ; preds = %14, %10
  %25 = phi i64 [ %12, %10 ], [ %21, %14 ]
  %26 = phi ptr [ %4, %10 ], [ %20, %14 ]
  store i64 %25, ptr %26, align 8, !tbaa !9
  br label %27

27:                                               ; preds = %24, %7
  %28 = load ptr, ptr %0, align 8, !tbaa !5
  %29 = getelementptr inbounds i8, ptr %0, i64 8
  %30 = load ptr, ptr %29, align 8, !tbaa !5
  %31 = tail call i64 @__gmpn_add_n(ptr noundef %28, ptr noundef %28, ptr noundef %30, i64 noundef %8) #15
  %32 = load ptr, ptr %29, align 8, !tbaa !5
  %33 = tail call i64 @__gmpn_sub_n(ptr noundef %32, ptr noundef %4, ptr noundef %32, i64 noundef %8) #15
  %34 = load ptr, ptr %0, align 8, !tbaa !5
  %35 = getelementptr inbounds i64, ptr %34, i64 %3
  %36 = load i64, ptr %35, align 8, !tbaa !9
  %37 = icmp ugt i64 %36, 1
  br i1 %37, label %38, label %49

38:                                               ; preds = %27
  store i64 1, ptr %35, align 8, !tbaa !9
  %39 = add i64 %36, -1
  %40 = load i64, ptr %34, align 8, !tbaa !9
  %41 = sub i64 %40, %39
  store i64 %41, ptr %34, align 8, !tbaa !9
  %42 = icmp ult i64 %40, %39
  br i1 %42, label %43, label %49

43:                                               ; preds = %43, %38
  %44 = phi ptr [ %45, %43 ], [ %34, %38 ]
  %45 = getelementptr inbounds i8, ptr %44, i64 8
  %46 = load i64, ptr %45, align 8, !tbaa !9
  %47 = add i64 %46, -1
  store i64 %47, ptr %45, align 8, !tbaa !9
  %48 = icmp eq i64 %46, 0
  br i1 %48, label %43, label %49, !llvm.loop !86

49:                                               ; preds = %43, %38, %27
  %50 = icmp eq i64 %33, 0
  br i1 %50, label %123, label %51

51:                                               ; preds = %49
  %52 = load ptr, ptr %29, align 8, !tbaa !5
  %53 = getelementptr inbounds i64, ptr %52, i64 %3
  %54 = load i64, ptr %53, align 8, !tbaa !9
  store i64 0, ptr %53, align 8, !tbaa !9
  %55 = sub i64 0, %54
  %56 = load i64, ptr %52, align 8, !tbaa !9
  %57 = sub i64 %56, %54
  store i64 %57, ptr %52, align 8, !tbaa !9
  %58 = icmp ult i64 %57, %55
  br i1 %58, label %59, label %123

59:                                               ; preds = %59, %51
  %60 = phi ptr [ %61, %59 ], [ %52, %51 ]
  %61 = getelementptr inbounds i8, ptr %60, i64 8
  %62 = load i64, ptr %61, align 8, !tbaa !9
  %63 = add i64 %62, 1
  store i64 %63, ptr %61, align 8, !tbaa !9
  %64 = icmp eq i64 %63, 0
  br i1 %64, label %59, label %123, !llvm.loop !87

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
  %76 = load ptr, ptr %75, align 8, !tbaa !5
  %77 = mul nsw i64 %74, %2
  tail call fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %4, ptr noundef %76, i64 noundef %77, i64 noundef %3)
  %78 = load ptr, ptr %75, align 8, !tbaa !5
  %79 = load ptr, ptr %73, align 8, !tbaa !5
  %80 = getelementptr inbounds i64, ptr %79, i64 %3
  %81 = load i64, ptr %80, align 8, !tbaa !9
  %82 = load i64, ptr %71, align 8, !tbaa !9
  %83 = tail call i64 @__gmpn_sub_n(ptr noundef %78, ptr noundef %79, ptr noundef %4, i64 noundef %3) #15
  %84 = add i64 %82, %83
  %85 = sub i64 %81, %84
  %86 = sub i64 0, %85
  %87 = icmp slt i64 %85, 0
  %88 = select i1 %87, i64 %86, i64 0
  %89 = add i64 %88, %85
  %90 = getelementptr inbounds i64, ptr %78, i64 %3
  store i64 %89, ptr %90, align 8, !tbaa !9
  %91 = load i64, ptr %78, align 8, !tbaa !9
  %92 = add i64 %91, %88
  store i64 %92, ptr %78, align 8, !tbaa !9
  %93 = icmp ult i64 %92, %88
  br i1 %93, label %94, label %100

94:                                               ; preds = %94, %72
  %95 = phi ptr [ %96, %94 ], [ %78, %72 ]
  %96 = getelementptr inbounds i8, ptr %95, i64 8
  %97 = load i64, ptr %96, align 8, !tbaa !9
  %98 = add i64 %97, 1
  store i64 %98, ptr %96, align 8, !tbaa !9
  %99 = icmp eq i64 %98, 0
  br i1 %99, label %94, label %100, !llvm.loop !82

100:                                              ; preds = %94, %72
  %101 = load ptr, ptr %73, align 8, !tbaa !5
  %102 = getelementptr inbounds i64, ptr %101, i64 %3
  %103 = load i64, ptr %102, align 8, !tbaa !9
  %104 = load i64, ptr %71, align 8, !tbaa !9
  %105 = add i64 %104, %103
  %106 = tail call i64 @__gmpn_add_n(ptr noundef %101, ptr noundef %101, ptr noundef %4, i64 noundef %3) #15
  %107 = add i64 %105, %106
  %108 = tail call i64 @llvm.usub.sat.i64(i64 %107, i64 1)
  %109 = sub i64 %107, %108
  store i64 %109, ptr %102, align 8, !tbaa !9
  %110 = load i64, ptr %101, align 8, !tbaa !9
  %111 = sub i64 %110, %108
  store i64 %111, ptr %101, align 8, !tbaa !9
  %112 = icmp ult i64 %110, %108
  br i1 %112, label %113, label %119

113:                                              ; preds = %113, %100
  %114 = phi ptr [ %115, %113 ], [ %101, %100 ]
  %115 = getelementptr inbounds i8, ptr %114, i64 8
  %116 = load i64, ptr %115, align 8, !tbaa !9
  %117 = add i64 %116, -1
  store i64 %117, ptr %115, align 8, !tbaa !9
  %118 = icmp eq i64 %116, 0
  br i1 %118, label %113, label %119, !llvm.loop !83

119:                                              ; preds = %113, %100
  %120 = add nuw nsw i64 %74, 1
  %121 = getelementptr inbounds i8, ptr %73, i64 8
  %122 = icmp eq i64 %120, %66
  br i1 %122, label %123, label %72, !llvm.loop !88

123:                                              ; preds = %119, %65, %59, %51, %49
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_fft_mul_2exp_modF(ptr noundef %0, ptr noundef %1, i64 noundef %2, i64 noundef %3) unnamed_addr #3 {
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
  %17 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %15, i64 noundef %16, i32 noundef %6) #15
  %18 = getelementptr inbounds i64, ptr %0, i64 %10
  %19 = load i64, ptr %18, align 8, !tbaa !9
  %20 = sub nsw i64 %3, %10
  %21 = tail call i64 @__gmpn_lshiftc(ptr noundef nonnull %18, ptr noundef %1, i64 noundef %20, i32 noundef %6) #15
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
  %30 = load i64, ptr %29, align 8, !tbaa !9
  %31 = icmp eq i64 %26, 0
  br i1 %31, label %42, label %32

32:                                               ; preds = %32, %25
  %33 = phi ptr [ %37, %32 ], [ %29, %25 ]
  %34 = phi i64 [ %39, %32 ], [ %30, %25 ]
  %35 = phi ptr [ %38, %32 ], [ %0, %25 ]
  %36 = phi i64 [ %40, %32 ], [ %26, %25 ]
  %37 = getelementptr inbounds i8, ptr %33, i64 8
  %38 = getelementptr inbounds i8, ptr %35, i64 8
  store i64 %34, ptr %35, align 8, !tbaa !9
  %39 = load i64, ptr %37, align 8, !tbaa !9
  %40 = add nsw i64 %36, -1
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %42, label %32, !llvm.loop !89

42:                                               ; preds = %32, %25
  %43 = phi i64 [ %30, %25 ], [ %39, %32 ]
  %44 = phi ptr [ %0, %25 ], [ %38, %32 ]
  store i64 %43, ptr %44, align 8, !tbaa !9
  br label %45

45:                                               ; preds = %42, %23
  %46 = getelementptr inbounds i64, ptr %1, i64 %3
  %47 = load i64, ptr %46, align 8, !tbaa !9
  %48 = getelementptr inbounds i64, ptr %0, i64 %10
  %49 = sub nsw i64 %3, %10
  br label %50

50:                                               ; preds = %50, %45
  %51 = phi ptr [ %48, %45 ], [ %57, %50 ]
  %52 = phi ptr [ %1, %45 ], [ %54, %50 ]
  %53 = phi i64 [ %49, %45 ], [ %58, %50 ]
  %54 = getelementptr inbounds i8, ptr %52, i64 8
  %55 = load i64, ptr %52, align 8, !tbaa !9
  %56 = xor i64 %55, -1
  %57 = getelementptr inbounds i8, ptr %51, i64 8
  store i64 %56, ptr %51, align 8, !tbaa !9
  %58 = add nsw i64 %53, -1
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %60, label %50, !llvm.loop !90

60:                                               ; preds = %50, %12
  %61 = phi i64 [ %19, %12 ], [ %47, %50 ]
  %62 = phi i64 [ %22, %12 ], [ 1, %50 ]
  %63 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 0, ptr %63, align 8, !tbaa !9
  %64 = load i64, ptr %0, align 8, !tbaa !9
  %65 = add i64 %64, %62
  store i64 %65, ptr %0, align 8, !tbaa !9
  %66 = icmp ult i64 %65, %62
  br i1 %66, label %67, label %73

67:                                               ; preds = %67, %60
  %68 = phi ptr [ %69, %67 ], [ %0, %60 ]
  %69 = getelementptr inbounds i8, ptr %68, i64 8
  %70 = load i64, ptr %69, align 8, !tbaa !9
  %71 = add i64 %70, 1
  store i64 %71, ptr %69, align 8, !tbaa !9
  %72 = icmp eq i64 %71, 0
  br i1 %72, label %67, label %73, !llvm.loop !91

73:                                               ; preds = %67, %60
  %74 = add i64 %61, 1
  %75 = icmp eq i64 %74, 0
  %76 = zext i1 %75 to i64
  %77 = getelementptr inbounds i64, ptr %0, i64 %10
  %78 = getelementptr inbounds i64, ptr %77, i64 %76
  %79 = add i64 %74, %76
  %80 = load i64, ptr %78, align 8, !tbaa !9
  %81 = add i64 %80, %79
  store i64 %81, ptr %78, align 8, !tbaa !9
  %82 = icmp ult i64 %81, %79
  br i1 %82, label %83, label %210

83:                                               ; preds = %83, %73
  %84 = phi ptr [ %85, %83 ], [ %78, %73 ]
  %85 = getelementptr inbounds i8, ptr %84, i64 8
  %86 = load i64, ptr %85, align 8, !tbaa !9
  %87 = add i64 %86, 1
  store i64 %87, ptr %85, align 8, !tbaa !9
  %88 = icmp eq i64 %87, 0
  br i1 %88, label %83, label %210, !llvm.loop !92

89:                                               ; preds = %4
  %90 = icmp eq i32 %6, 0
  %91 = getelementptr inbounds i64, ptr %1, i64 %3
  %92 = sub nsw i64 0, %7
  %93 = getelementptr inbounds i64, ptr %91, i64 %92
  %94 = add nuw nsw i64 %7, 1
  br i1 %90, label %102, label %95

95:                                               ; preds = %89
  %96 = tail call i64 @__gmpn_lshiftc(ptr noundef %0, ptr noundef %93, i64 noundef %94, i32 noundef %6) #15
  %97 = getelementptr inbounds i64, ptr %0, i64 %7
  %98 = load i64, ptr %97, align 8, !tbaa !9
  %99 = xor i64 %98, -1
  %100 = sub nsw i64 %3, %7
  %101 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %97, ptr noundef %1, i64 noundef %100, i32 noundef %6) #15
  br label %134

102:                                              ; preds = %102, %89
  %103 = phi ptr [ %109, %102 ], [ %0, %89 ]
  %104 = phi ptr [ %106, %102 ], [ %93, %89 ]
  %105 = phi i64 [ %110, %102 ], [ %94, %89 ]
  %106 = getelementptr inbounds i8, ptr %104, i64 8
  %107 = load i64, ptr %104, align 8, !tbaa !9
  %108 = xor i64 %107, -1
  %109 = getelementptr inbounds i8, ptr %103, i64 8
  store i64 %108, ptr %103, align 8, !tbaa !9
  %110 = add nsw i64 %105, -1
  %111 = icmp eq i64 %110, 0
  br i1 %111, label %112, label %102, !llvm.loop !93

112:                                              ; preds = %102
  %113 = load i64, ptr %91, align 8, !tbaa !9
  %114 = icmp eq i64 %7, %3
  br i1 %114, label %134, label %115

115:                                              ; preds = %112
  %116 = xor i64 %7, -1
  %117 = add i64 %116, %3
  %118 = getelementptr inbounds i64, ptr %0, i64 %7
  %119 = load i64, ptr %1, align 8, !tbaa !9
  %120 = icmp eq i64 %117, 0
  br i1 %120, label %131, label %121

121:                                              ; preds = %121, %115
  %122 = phi i64 [ %129, %121 ], [ %117, %115 ]
  %123 = phi ptr [ %127, %121 ], [ %118, %115 ]
  %124 = phi ptr [ %126, %121 ], [ %1, %115 ]
  %125 = phi i64 [ %128, %121 ], [ %119, %115 ]
  %126 = getelementptr inbounds i8, ptr %124, i64 8
  %127 = getelementptr inbounds i8, ptr %123, i64 8
  store i64 %125, ptr %123, align 8, !tbaa !9
  %128 = load i64, ptr %126, align 8, !tbaa !9
  %129 = add nsw i64 %122, -1
  %130 = icmp eq i64 %129, 0
  br i1 %130, label %131, label %121, !llvm.loop !94

131:                                              ; preds = %121, %115
  %132 = phi ptr [ %118, %115 ], [ %127, %121 ]
  %133 = phi i64 [ %119, %115 ], [ %128, %121 ]
  store i64 %133, ptr %132, align 8, !tbaa !9
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
  %142 = load i64, ptr %0, align 8, !tbaa !9
  %143 = add i64 %142, 1
  store i64 %143, ptr %0, align 8, !tbaa !9
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
  %152 = load i64, ptr %151, align 8, !tbaa !9
  %153 = add i64 %152, 1
  store i64 %153, ptr %151, align 8, !tbaa !9
  %154 = add nuw i64 %148, 1
  %155 = icmp eq i64 %153, 0
  br i1 %155, label %147, label %156, !llvm.loop !66

156:                                              ; preds = %150, %147, %141, %138
  %157 = phi i64 [ %139, %138 ], [ 0, %141 ], [ 1, %147 ], [ 0, %150 ]
  %158 = load i64, ptr %0, align 8, !tbaa !9
  %159 = sub i64 %158, %157
  store i64 %159, ptr %0, align 8, !tbaa !9
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
  %168 = load i64, ptr %167, align 8, !tbaa !9
  %169 = add i64 %168, -1
  store i64 %169, ptr %167, align 8, !tbaa !9
  %170 = add nuw nsw i64 %164, 1
  %171 = icmp eq i64 %168, 0
  br i1 %171, label %163, label %172, !llvm.loop !72

172:                                              ; preds = %166, %163, %156, %134
  %173 = phi i64 [ %136, %134 ], [ 1, %156 ], [ 2, %163 ], [ 1, %166 ]
  %174 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 2, ptr %174, align 8, !tbaa !9
  %175 = getelementptr inbounds i64, ptr %0, i64 %7
  %176 = load i64, ptr %175, align 8, !tbaa !9
  %177 = sub i64 %176, %173
  store i64 %177, ptr %175, align 8, !tbaa !9
  %178 = icmp ult i64 %176, %173
  br i1 %178, label %179, label %185

179:                                              ; preds = %179, %172
  %180 = phi ptr [ %181, %179 ], [ %175, %172 ]
  %181 = getelementptr inbounds i8, ptr %180, i64 8
  %182 = load i64, ptr %181, align 8, !tbaa !9
  %183 = add i64 %182, -1
  store i64 %183, ptr %181, align 8, !tbaa !9
  %184 = icmp eq i64 %182, 0
  br i1 %184, label %179, label %185, !llvm.loop !95

185:                                              ; preds = %179, %172
  %186 = load i64, ptr %175, align 8, !tbaa !9
  %187 = sub i64 %186, %135
  store i64 %187, ptr %175, align 8, !tbaa !9
  %188 = icmp ult i64 %186, %135
  br i1 %188, label %189, label %195

189:                                              ; preds = %189, %185
  %190 = phi ptr [ %191, %189 ], [ %175, %185 ]
  %191 = getelementptr inbounds i8, ptr %190, i64 8
  %192 = load i64, ptr %191, align 8, !tbaa !9
  %193 = add i64 %192, -1
  store i64 %193, ptr %191, align 8, !tbaa !9
  %194 = icmp eq i64 %192, 0
  br i1 %194, label %189, label %195, !llvm.loop !96

195:                                              ; preds = %189, %185
  %196 = load i64, ptr %174, align 8, !tbaa !9
  %197 = add i64 %196, -2
  store i64 %197, ptr %174, align 8, !tbaa !9
  %198 = icmp eq i64 %197, 0
  br i1 %198, label %210, label %199, !prof !30

199:                                              ; preds = %195
  store i64 0, ptr %174, align 8, !tbaa !9
  %200 = sub i64 2, %196
  %201 = load i64, ptr %0, align 8, !tbaa !9
  %202 = add i64 %201, %200
  store i64 %202, ptr %0, align 8, !tbaa !9
  %203 = icmp ult i64 %202, %200
  br i1 %203, label %204, label %210

204:                                              ; preds = %204, %199
  %205 = phi ptr [ %206, %204 ], [ %0, %199 ]
  %206 = getelementptr inbounds i8, ptr %205, i64 8
  %207 = load i64, ptr %206, align 8, !tbaa !9
  %208 = add i64 %207, 1
  store i64 %208, ptr %206, align 8, !tbaa !9
  %209 = icmp eq i64 %208, 0
  br i1 %209, label %204, label %210, !llvm.loop !97

210:                                              ; preds = %204, %199, %195, %83, %73
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #3 {
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #15
  store ptr null, ptr %6, align 8, !tbaa !5
  %7 = icmp eq ptr %1, %3
  %8 = icmp eq i64 %2, %4
  %9 = and i1 %7, %8
  br i1 %9, label %10, label %20

10:                                               ; preds = %5
  %11 = shl nsw i64 %2, 1
  %12 = tail call i64 @__gmpn_sqrmod_bnm1_next_size(i64 noundef %11) #18
  %13 = ashr i64 %12, 1
  %14 = add nsw i64 %12, 3
  %15 = icmp slt i64 %13, %2
  %16 = select i1 %15, i64 %2, i64 0
  %17 = add nsw i64 %14, %16
  %18 = shl i64 %17, 3
  %19 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %18) #15
  call void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %12, ptr noundef %1, i64 noundef %2, ptr noundef %19) #15
  br label %32

20:                                               ; preds = %5
  %21 = add nsw i64 %4, %2
  %22 = tail call i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %21) #18
  %23 = ashr i64 %22, 1
  %24 = icmp slt i64 %23, %2
  %25 = icmp slt i64 %23, %4
  %26 = select i1 %25, i64 %22, i64 %23
  %27 = select i1 %24, i64 %26, i64 0
  %28 = add nsw i64 %22, 4
  %29 = add nsw i64 %28, %27
  %30 = shl i64 %29, 3
  %31 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %30) #15
  call void @__gmpn_mulmod_bnm1(ptr noundef %0, i64 noundef %22, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %31) #15
  br label %32

32:                                               ; preds = %20, %10
  %33 = load ptr, ptr %6, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %33) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4) local_unnamed_addr #3 {
  %6 = alloca ptr, align 8
  %7 = and i64 %1, 1
  %8 = icmp eq i64 %7, 0
  %9 = icmp sgt i64 %1, 15
  %10 = and i1 %9, %8
  br i1 %10, label %42, label %11

11:                                               ; preds = %5
  %12 = icmp slt i64 %3, %1
  br i1 %12, label %13, label %30, !prof !55

13:                                               ; preds = %11
  %14 = shl nsw i64 %3, 1
  %15 = icmp sgt i64 %14, %1
  br i1 %15, label %17, label %16, !prof !30

16:                                               ; preds = %13
  tail call void @__gmpn_sqr(ptr noundef %0, ptr noundef %2, i64 noundef %3) #15
  br label %286

17:                                               ; preds = %13
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %2, i64 noundef %3) #15
  %18 = getelementptr inbounds i64, ptr %4, i64 %1
  %19 = sub nsw i64 %14, %1
  %20 = tail call i64 @__gmpn_add(ptr noundef %0, ptr noundef %4, i64 noundef %1, ptr noundef %18, i64 noundef %19)
  %21 = load i64, ptr %0, align 8, !tbaa !9
  %22 = add i64 %21, %20
  store i64 %22, ptr %0, align 8, !tbaa !9
  %23 = icmp ult i64 %22, %20
  br i1 %23, label %24, label %286

24:                                               ; preds = %24, %17
  %25 = phi ptr [ %26, %24 ], [ %0, %17 ]
  %26 = getelementptr inbounds i8, ptr %25, i64 8
  %27 = load i64, ptr %26, align 8, !tbaa !9
  %28 = add i64 %27, 1
  store i64 %28, ptr %26, align 8, !tbaa !9
  %29 = icmp eq i64 %28, 0
  br i1 %29, label %24, label %286, !llvm.loop !98

30:                                               ; preds = %11
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %2, i64 noundef %1) #15
  %31 = getelementptr inbounds i64, ptr %4, i64 %1
  %32 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %4, ptr noundef %31, i64 noundef %1) #15
  %33 = load i64, ptr %0, align 8, !tbaa !9
  %34 = add i64 %33, %32
  store i64 %34, ptr %0, align 8, !tbaa !9
  %35 = icmp ult i64 %34, %32
  br i1 %35, label %36, label %286

36:                                               ; preds = %36, %30
  %37 = phi ptr [ %38, %36 ], [ %0, %30 ]
  %38 = getelementptr inbounds i8, ptr %37, i64 8
  %39 = load i64, ptr %38, align 8, !tbaa !9
  %40 = add i64 %39, 1
  store i64 %40, ptr %38, align 8, !tbaa !9
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %36, label %286, !llvm.loop !99

42:                                               ; preds = %5
  %43 = lshr exact i64 %1, 1
  %44 = icmp slt i64 %43, %3
  br i1 %44, label %45, label %129, !prof !30

45:                                               ; preds = %42
  %46 = getelementptr inbounds i64, ptr %4, i64 %43
  %47 = getelementptr inbounds i64, ptr %2, i64 %43
  %48 = sub nsw i64 %3, %43
  %49 = icmp eq i64 %48, 0
  br i1 %49, label %63, label %50

50:                                               ; preds = %45
  %51 = tail call i64 @__gmpn_add_n(ptr noundef %4, ptr noundef %2, ptr noundef nonnull %47, i64 noundef %48) #15
  %52 = icmp eq i64 %51, 0
  br i1 %52, label %63, label %53

53:                                               ; preds = %56, %50
  %54 = phi i64 [ %60, %56 ], [ %48, %50 ]
  %55 = icmp slt i64 %54, %43
  br i1 %55, label %56, label %75

56:                                               ; preds = %53
  %57 = getelementptr inbounds i64, ptr %2, i64 %54
  %58 = load i64, ptr %57, align 8, !tbaa !9
  %59 = add i64 %58, 1
  %60 = add nsw i64 %54, 1
  %61 = getelementptr inbounds i64, ptr %4, i64 %54
  store i64 %59, ptr %61, align 8, !tbaa !9
  %62 = icmp eq i64 %59, 0
  br i1 %62, label %53, label %63, !llvm.loop !100

63:                                               ; preds = %56, %50, %45
  %64 = phi i64 [ %48, %50 ], [ 0, %45 ], [ %60, %56 ]
  %65 = icmp ne ptr %4, %2
  %66 = icmp slt i64 %64, %43
  %67 = select i1 %65, i1 %66, i1 false
  br i1 %67, label %68, label %75

68:                                               ; preds = %68, %63
  %69 = phi i64 [ %73, %68 ], [ %64, %63 ]
  %70 = getelementptr inbounds i64, ptr %2, i64 %69
  %71 = load i64, ptr %70, align 8, !tbaa !9
  %72 = getelementptr inbounds i64, ptr %4, i64 %69
  store i64 %71, ptr %72, align 8, !tbaa !9
  %73 = add nsw i64 %69, 1
  %74 = icmp eq i64 %73, %43
  br i1 %74, label %75, label %68, !llvm.loop !101

75:                                               ; preds = %68, %63, %53
  %76 = phi i64 [ 0, %63 ], [ 0, %68 ], [ 1, %53 ]
  %77 = load i64, ptr %4, align 8, !tbaa !9
  %78 = add i64 %77, %76
  store i64 %78, ptr %4, align 8, !tbaa !9
  %79 = icmp ult i64 %78, %76
  br i1 %79, label %80, label %86

80:                                               ; preds = %80, %75
  %81 = phi ptr [ %82, %80 ], [ %4, %75 ]
  %82 = getelementptr inbounds i8, ptr %81, i64 8
  %83 = load i64, ptr %82, align 8, !tbaa !9
  %84 = add i64 %83, 1
  store i64 %84, ptr %82, align 8, !tbaa !9
  %85 = icmp eq i64 %84, 0
  br i1 %85, label %80, label %86, !llvm.loop !102

86:                                               ; preds = %80, %75
  tail call void @__gmpn_sqrmod_bnm1(ptr noundef %0, i64 noundef %43, ptr noundef %4, i64 noundef %43, ptr noundef nonnull %46)
  %87 = getelementptr inbounds i64, ptr %4, i64 %1
  %88 = getelementptr inbounds i8, ptr %87, i64 16
  br i1 %49, label %102, label %89

89:                                               ; preds = %86
  %90 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %88, ptr noundef %2, ptr noundef nonnull %47, i64 noundef %48) #15
  %91 = icmp eq i64 %90, 0
  br i1 %91, label %102, label %92

92:                                               ; preds = %95, %89
  %93 = phi i64 [ %99, %95 ], [ %48, %89 ]
  %94 = icmp slt i64 %93, %43
  br i1 %94, label %95, label %114

95:                                               ; preds = %92
  %96 = getelementptr inbounds i64, ptr %2, i64 %93
  %97 = load i64, ptr %96, align 8, !tbaa !9
  %98 = add i64 %97, -1
  %99 = add nsw i64 %93, 1
  %100 = getelementptr inbounds i64, ptr %88, i64 %93
  store i64 %98, ptr %100, align 8, !tbaa !9
  %101 = icmp eq i64 %97, 0
  br i1 %101, label %92, label %102, !llvm.loop !103

102:                                              ; preds = %95, %89, %86
  %103 = phi i64 [ %48, %89 ], [ 0, %86 ], [ %99, %95 ]
  %104 = icmp ne ptr %88, %2
  %105 = icmp slt i64 %103, %43
  %106 = select i1 %104, i1 %105, i1 false
  br i1 %106, label %107, label %114

107:                                              ; preds = %107, %102
  %108 = phi i64 [ %112, %107 ], [ %103, %102 ]
  %109 = getelementptr inbounds i64, ptr %2, i64 %108
  %110 = load i64, ptr %109, align 8, !tbaa !9
  %111 = getelementptr inbounds i64, ptr %88, i64 %108
  store i64 %110, ptr %111, align 8, !tbaa !9
  %112 = add nsw i64 %108, 1
  %113 = icmp eq i64 %112, %43
  br i1 %113, label %114, label %107, !llvm.loop !104

114:                                              ; preds = %107, %102, %92
  %115 = phi i64 [ 0, %102 ], [ 0, %107 ], [ 1, %92 ]
  %116 = getelementptr inbounds i64, ptr %88, i64 %43
  store i64 0, ptr %116, align 8, !tbaa !9
  %117 = load i64, ptr %88, align 8, !tbaa !9
  %118 = add i64 %117, %115
  store i64 %118, ptr %88, align 8, !tbaa !9
  %119 = icmp ult i64 %118, %115
  br i1 %119, label %120, label %126

120:                                              ; preds = %120, %114
  %121 = phi ptr [ %122, %120 ], [ %88, %114 ]
  %122 = getelementptr inbounds i8, ptr %121, i64 8
  %123 = load i64, ptr %122, align 8, !tbaa !9
  %124 = add i64 %123, 1
  store i64 %124, ptr %122, align 8, !tbaa !9
  %125 = icmp eq i64 %124, 0
  br i1 %125, label %120, label %126, !llvm.loop !105

126:                                              ; preds = %120, %114
  %127 = load i64, ptr %116, align 8, !tbaa !9
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
  %135 = tail call i32 @__gmpn_fft_best_k(i64 noundef %43, i32 noundef 1) #18
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
  br i1 %148, label %149, label %141, !llvm.loop !106

149:                                              ; preds = %141, %134, %130
  %150 = phi i32 [ 0, %130 ], [ %135, %134 ], [ %144, %141 ]
  %151 = icmp sgt i32 %150, 3
  br i1 %151, label %152, label %155

152:                                              ; preds = %149
  %153 = tail call i64 @__gmpn_mul_fft(ptr noundef %4, i64 noundef %43, ptr noundef %131, i64 noundef %132, ptr noundef %131, i64 noundef %132, i32 noundef %150) #15
  %154 = getelementptr inbounds i64, ptr %4, i64 %43
  store i64 %153, ptr %154, align 8, !tbaa !9
  br label %220

155:                                              ; preds = %149
  %156 = icmp eq ptr %131, %2
  br i1 %156, label %157, label %171, !prof !55

157:                                              ; preds = %155
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %2, i64 noundef %3) #15
  %158 = shl nsw i64 %3, 1
  %159 = sub nsw i64 %158, %43
  %160 = getelementptr inbounds i64, ptr %4, i64 %43
  %161 = tail call i64 @__gmpn_sub(ptr noundef %4, ptr noundef %4, i64 noundef %43, ptr noundef nonnull %160, i64 noundef %159)
  store i64 0, ptr %160, align 8, !tbaa !9
  %162 = load i64, ptr %4, align 8, !tbaa !9
  %163 = add i64 %162, %161
  store i64 %163, ptr %4, align 8, !tbaa !9
  %164 = icmp ult i64 %163, %161
  br i1 %164, label %165, label %220

165:                                              ; preds = %165, %157
  %166 = phi ptr [ %167, %165 ], [ %4, %157 ]
  %167 = getelementptr inbounds i8, ptr %166, i64 8
  %168 = load i64, ptr %167, align 8, !tbaa !9
  %169 = add i64 %168, 1
  store i64 %169, ptr %167, align 8, !tbaa !9
  %170 = icmp eq i64 %169, 0
  br i1 %170, label %165, label %220, !llvm.loop !107

171:                                              ; preds = %155
  %172 = getelementptr inbounds i64, ptr %131, i64 %43
  %173 = load i64, ptr %172, align 8, !tbaa !9
  %174 = icmp eq i64 %173, 0
  br i1 %174, label %178, label %175, !prof !30

175:                                              ; preds = %171
  store i64 1, ptr %4, align 8, !tbaa !9
  %176 = getelementptr i8, ptr %4, i64 8
  %177 = shl nuw i64 %1, 2
  tail call void @llvm.memset.p0.i64(ptr align 8 %176, i8 0, i64 %177, i1 false), !tbaa !9
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
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #15
  store ptr null, ptr %6, align 8, !tbaa !5
  %205 = mul i64 %43, 24
  %206 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %205) #15
  call void @__gmpn_sqrmod_bknp1(ptr noundef %4, ptr noundef %131, i64 noundef %204, i32 noundef %202, ptr noundef %206) #15
  %207 = load ptr, ptr %6, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %207) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #15
  br label %220

208:                                              ; preds = %196, %191, %183, %178
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %131, i64 noundef %43) #15
  %209 = getelementptr inbounds i64, ptr %4, i64 %43
  %210 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef nonnull %209, i64 noundef %43) #15
  store i64 0, ptr %209, align 8, !tbaa !9
  %211 = load i64, ptr %4, align 8, !tbaa !9
  %212 = add i64 %211, %210
  store i64 %212, ptr %4, align 8, !tbaa !9
  %213 = icmp ult i64 %212, %210
  br i1 %213, label %214, label %220

214:                                              ; preds = %214, %208
  %215 = phi ptr [ %216, %214 ], [ %4, %208 ]
  %216 = getelementptr inbounds i8, ptr %215, i64 8
  %217 = load i64, ptr %216, align 8, !tbaa !9
  %218 = add i64 %217, 1
  store i64 %218, ptr %216, align 8, !tbaa !9
  %219 = icmp eq i64 %218, 0
  br i1 %219, label %214, label %220, !llvm.loop !108

220:                                              ; preds = %214, %208, %201, %175, %165, %157, %152
  %221 = getelementptr inbounds i64, ptr %4, i64 %43
  %222 = load i64, ptr %221, align 8, !tbaa !9
  %223 = call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %4, i64 noundef %43) #15
  %224 = add i64 %223, %222
  %225 = load i64, ptr %0, align 8, !tbaa !9
  %226 = and i64 %225, 1
  %227 = add i64 %224, %226
  %228 = call i64 @__gmpn_rshift(ptr noundef nonnull %0, ptr noundef nonnull %0, i64 noundef %43, i32 noundef 1) #15
  %229 = shl i64 %227, 63
  %230 = getelementptr i64, ptr %0, i64 %43
  %231 = getelementptr i8, ptr %230, i64 -8
  %232 = load i64, ptr %231, align 8, !tbaa !9
  %233 = or i64 %229, %232
  store i64 %233, ptr %231, align 8, !tbaa !9
  %234 = lshr i64 %227, 1
  %235 = load i64, ptr %0, align 8, !tbaa !9
  %236 = add i64 %235, %234
  store i64 %236, ptr %0, align 8, !tbaa !9
  %237 = icmp ult i64 %236, %234
  br i1 %237, label %238, label %244

238:                                              ; preds = %238, %220
  %239 = phi ptr [ %240, %238 ], [ %0, %220 ]
  %240 = getelementptr inbounds i8, ptr %239, i64 8
  %241 = load i64, ptr %240, align 8, !tbaa !9
  %242 = add i64 %241, 1
  store i64 %242, ptr %240, align 8, !tbaa !9
  %243 = icmp eq i64 %242, 0
  br i1 %243, label %238, label %244, !llvm.loop !109

244:                                              ; preds = %238, %220
  %245 = shl nsw i64 %3, 1
  %246 = icmp slt i64 %245, %1
  br i1 %246, label %247, label %273, !prof !55

247:                                              ; preds = %244
  %248 = sub nsw i64 %245, %43
  %249 = call i64 @__gmpn_sub_n(ptr noundef nonnull %230, ptr noundef nonnull %0, ptr noundef %4, i64 noundef %248) #15
  %250 = load i64, ptr %221, align 8, !tbaa !9
  %251 = getelementptr inbounds i64, ptr %4, i64 %245
  %252 = sub nsw i64 0, %43
  %253 = getelementptr inbounds i64, ptr %251, i64 %252
  %254 = getelementptr inbounds i64, ptr %0, i64 %245
  %255 = getelementptr inbounds i64, ptr %254, i64 %252
  %256 = sub nsw i64 %1, %245
  %257 = call fastcc i64 @mpn_sub_nc(ptr noundef nonnull %253, ptr noundef nonnull %255, ptr noundef nonnull %253, i64 noundef %256, i64 noundef %249)
  %258 = add i64 %257, %250
  %259 = load i64, ptr %0, align 8, !tbaa !9
  %260 = sub i64 %259, %258
  store i64 %260, ptr %0, align 8, !tbaa !9
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
  %269 = load i64, ptr %268, align 8, !tbaa !9
  %270 = add i64 %269, -1
  store i64 %270, ptr %268, align 8, !tbaa !9
  %271 = add nuw i64 %265, 1
  %272 = icmp eq i64 %269, 0
  br i1 %272, label %264, label %286, !llvm.loop !110

273:                                              ; preds = %244
  %274 = load i64, ptr %221, align 8, !tbaa !9
  %275 = call i64 @__gmpn_sub_n(ptr noundef nonnull %230, ptr noundef nonnull %0, ptr noundef %4, i64 noundef %43) #15
  %276 = add i64 %275, %274
  %277 = load i64, ptr %0, align 8, !tbaa !9
  %278 = sub i64 %277, %276
  store i64 %278, ptr %0, align 8, !tbaa !9
  %279 = icmp ult i64 %277, %276
  br i1 %279, label %280, label %286

280:                                              ; preds = %280, %273
  %281 = phi ptr [ %282, %280 ], [ %0, %273 ]
  %282 = getelementptr inbounds i8, ptr %281, i64 8
  %283 = load i64, ptr %282, align 8, !tbaa !9
  %284 = add i64 %283, -1
  store i64 %284, ptr %282, align 8, !tbaa !9
  %285 = icmp eq i64 %283, 0
  br i1 %285, label %280, label %286, !llvm.loop !111

286:                                              ; preds = %280, %273, %267, %264, %247, %36, %30, %24, %17, %16
  ret void
}

; Function Attrs: inlinehint nounwind ssp uwtable
define hidden fastcc i64 @mpn_sub_nc(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4) unnamed_addr #11 {
  %6 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) #15
  %7 = load i64, ptr %0, align 8, !tbaa !9
  %8 = sub i64 %7, %4
  store i64 %8, ptr %0, align 8, !tbaa !9
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
  %17 = load i64, ptr %16, align 8, !tbaa !9
  %18 = add i64 %17, -1
  store i64 %18, ptr %16, align 8, !tbaa !9
  %19 = add nuw i64 %13, 1
  %20 = icmp eq i64 %17, 0
  br i1 %20, label %12, label %21, !llvm.loop !110

21:                                               ; preds = %15, %12, %5
  %22 = phi i64 [ 0, %5 ], [ 1, %12 ], [ 0, %15 ]
  %23 = add i64 %22, %6
  ret i64 %23
}

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_sqrmod_bnm1_next_size(i64 noundef %0) local_unnamed_addr #12 {
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
  %21 = tail call i32 @__gmpn_fft_best_k(i64 noundef %20, i32 noundef 1) #18
  %22 = tail call i64 @__gmpn_fft_next_size(i64 noundef %20, i32 noundef %21) #18
  %23 = shl nsw i64 %22, 1
  br label %24

24:                                               ; preds = %18, %15, %10, %5, %1
  %25 = phi i64 [ %23, %18 ], [ %17, %15 ], [ %12, %10 ], [ %7, %5 ], [ %0, %1 ]
  ret i64 %25
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define void @__gmpn_divexact_1(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #13 {
  %5 = and i64 %3, 1
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %7, label %38

7:                                                ; preds = %4
  %8 = and i64 %3, 254
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %17, label %10, !prof !55

10:                                               ; preds = %7
  %11 = sub i64 0, %3
  %12 = and i64 %11, %3
  %13 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !38
  %15 = zext i8 %14 to i32
  %16 = add nsw i32 %15, -2
  br label %34

17:                                               ; preds = %23, %7
  %18 = phi i64 [ %20, %23 ], [ %3, %7 ]
  %19 = phi i32 [ %24, %23 ], [ 6, %7 ]
  %20 = lshr i64 %18, 8
  %21 = and i64 %18, 65280
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %23, label %26, !prof !55

23:                                               ; preds = %17
  %24 = add nuw nsw i32 %19, 8
  %25 = icmp ult i32 %19, 54
  br i1 %25, label %17, label %26, !llvm.loop !112

26:                                               ; preds = %23, %17
  %27 = phi i32 [ %19, %17 ], [ 62, %23 ]
  %28 = sub nsw i64 0, %20
  %29 = and i64 %20, %28
  %30 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %29
  %31 = load i8, ptr %30, align 1, !tbaa !38
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
  %44 = load i8, ptr %43, align 1, !tbaa !38
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
  %56 = load i64, ptr %1, align 8, !tbaa !9
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
  %71 = load i64, ptr %70, align 8, !tbaa !9
  %72 = lshr i64 %69, %61
  %73 = shl i64 %71, %63
  %74 = or i64 %73, %72
  %75 = sub i64 %74, %68
  %76 = icmp ugt i64 %68, %74
  %77 = zext i1 %76 to i64
  %78 = mul i64 %75, %54
  %79 = getelementptr i64, ptr %58, i64 %67
  store i64 %78, ptr %79, align 8, !tbaa !9
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
  br i1 %96, label %97, label %66, !llvm.loop !113

97:                                               ; preds = %66, %57
  %98 = phi i64 [ %56, %57 ], [ %71, %66 ]
  %99 = phi i64 [ 0, %57 ], [ %94, %66 ]
  %100 = zext nneg i32 %39 to i64
  %101 = lshr i64 %98, %100
  %102 = sub i64 %101, %99
  %103 = mul i64 %102, %54
  %104 = getelementptr i64, ptr %0, i64 %2
  %105 = getelementptr i8, ptr %104, i64 -8
  store i64 %103, ptr %105, align 8, !tbaa !9
  br label %140

106:                                              ; preds = %38
  %107 = mul i64 %56, %54
  store i64 %107, ptr %0, align 8, !tbaa !9
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
  %132 = load i64, ptr %131, align 8, !tbaa !9
  %133 = sub i64 %132, %130
  %134 = icmp ugt i64 %130, %132
  %135 = zext i1 %134 to i64
  %136 = mul i64 %133, %54
  %137 = getelementptr inbounds i64, ptr %0, i64 %113
  store i64 %136, ptr %137, align 8, !tbaa !9
  %138 = add nuw nsw i64 %113, 1
  %139 = icmp eq i64 %138, %2
  br i1 %139, label %140, label %112, !llvm.loop !114

140:                                              ; preds = %112, %106, %97
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_lshift(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #5 {
  %5 = getelementptr inbounds i64, ptr %1, i64 %2
  %6 = getelementptr inbounds i64, ptr %0, i64 %2
  %7 = sub i32 64, %3
  %8 = getelementptr inbounds i8, ptr %5, i64 -8
  %9 = load i64, ptr %8, align 8, !tbaa !9
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
  %21 = load i64, ptr %20, align 8, !tbaa !9
  %22 = lshr i64 %21, %10
  %23 = or i64 %22, %16
  %24 = getelementptr inbounds i8, ptr %18, i64 -8
  store i64 %23, ptr %24, align 8, !tbaa !9
  %25 = add nsw i64 %17, -1
  %26 = shl i64 %21, %11
  %27 = icmp eq i64 %25, 0
  br i1 %27, label %28, label %15, !llvm.loop !115

28:                                               ; preds = %15, %4
  %29 = phi ptr [ %6, %4 ], [ %24, %15 ]
  %30 = phi i64 [ %13, %4 ], [ %26, %15 ]
  %31 = lshr i64 %9, %10
  %32 = getelementptr inbounds i8, ptr %29, i64 -8
  store i64 %30, ptr %32, align 8, !tbaa !9
  ret i64 %31
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) local_unnamed_addr #3 {
  %5 = alloca [326 x i64], align 16
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = icmp sgt i64 %3, 29
  br i1 %10, label %12, label %11

11:                                               ; preds = %4
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3) #15
  br label %45

12:                                               ; preds = %4
  %13 = icmp sgt i64 %3, 99
  br i1 %13, label %15, label %14

14:                                               ; preds = %12
  call void @llvm.lifetime.start.p0(i64 2608, ptr nonnull %5) #15
  call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef nonnull %5) #15
  call void @llvm.lifetime.end.p0(i64 2608, ptr nonnull %5) #15
  br label %45

15:                                               ; preds = %12
  %16 = icmp sgt i64 %3, 299
  br i1 %16, label %22, label %17

17:                                               ; preds = %15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #15
  store ptr null, ptr %6, align 8, !tbaa !5
  %18 = mul i64 %3, 24
  %19 = add i64 %18, 512
  %20 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %19) #15
  call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %20) #15
  %21 = load ptr, ptr %6, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %21) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #15
  br label %45

22:                                               ; preds = %15
  %23 = icmp sgt i64 %3, 349
  br i1 %23, label %29, label %24

24:                                               ; preds = %22
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #15
  store ptr null, ptr %7, align 8, !tbaa !5
  %25 = mul i64 %3, 24
  %26 = add i64 %25, 512
  %27 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %26) #15
  call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %27) #15
  %28 = load ptr, ptr %7, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %28) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #15
  br label %45

29:                                               ; preds = %22
  %30 = icmp sgt i64 %3, 449
  br i1 %30, label %36, label %31

31:                                               ; preds = %29
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #15
  store ptr null, ptr %8, align 8, !tbaa !5
  %32 = shl i64 %3, 4
  %33 = add i64 %32, 3312
  %34 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %33) #15
  call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %34) #15
  %35 = load ptr, ptr %8, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %35) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #15
  br label %45

36:                                               ; preds = %29
  %37 = icmp sgt i64 %3, 2999
  br i1 %37, label %44, label %38

38:                                               ; preds = %36
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9) #15
  store ptr null, ptr %9, align 8, !tbaa !5
  %39 = mul nuw nsw i64 %3, 15
  %40 = and i64 %39, 9223372036854775800
  %41 = add nuw i64 %40, 3768
  %42 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %41) #15
  call void @__gmpn_toom8h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3, ptr noundef %42) #15
  %43 = load ptr, ptr %9, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %43) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9) #15
  br label %45

44:                                               ; preds = %36
  tail call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %3, ptr noundef %2, i64 noundef %3) #15
  br label %45

45:                                               ; preds = %44, %38, %31, %24, %17, %14, %11
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mulmod_bnm1(ptr noundef %0, i64 noundef %1, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, ptr noundef %6) local_unnamed_addr #3 {
  %8 = alloca ptr, align 8
  %9 = and i64 %1, 1
  %10 = icmp eq i64 %9, 0
  %11 = icmp sgt i64 %1, 15
  %12 = and i1 %11, %10
  br i1 %12, label %46, label %13

13:                                               ; preds = %7
  %14 = icmp slt i64 %5, %1
  br i1 %14, label %15, label %34, !prof !55

15:                                               ; preds = %13
  %16 = add nsw i64 %5, %3
  %17 = icmp sgt i64 %16, %1
  br i1 %17, label %20, label %18, !prof !30

18:                                               ; preds = %15
  %19 = tail call i64 @__gmpn_mul(ptr noundef %0, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5) #15
  br label %402

20:                                               ; preds = %15
  %21 = tail call i64 @__gmpn_mul(ptr noundef %6, ptr noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5) #15
  %22 = getelementptr inbounds i64, ptr %6, i64 %1
  %23 = sub nsw i64 %16, %1
  %24 = tail call i64 @__gmpn_add(ptr noundef %0, ptr noundef %6, i64 noundef %1, ptr noundef %22, i64 noundef %23)
  %25 = load i64, ptr %0, align 8, !tbaa !9
  %26 = add i64 %25, %24
  store i64 %26, ptr %0, align 8, !tbaa !9
  %27 = icmp ult i64 %26, %24
  br i1 %27, label %28, label %402

28:                                               ; preds = %28, %20
  %29 = phi ptr [ %30, %28 ], [ %0, %20 ]
  %30 = getelementptr inbounds i8, ptr %29, i64 8
  %31 = load i64, ptr %30, align 8, !tbaa !9
  %32 = add i64 %31, 1
  store i64 %32, ptr %30, align 8, !tbaa !9
  %33 = icmp eq i64 %32, 0
  br i1 %33, label %28, label %402, !llvm.loop !116

34:                                               ; preds = %13
  tail call void @__gmpn_mul_n(ptr noundef %6, ptr noundef %2, ptr noundef %4, i64 noundef %1) #15
  %35 = getelementptr inbounds i64, ptr %6, i64 %1
  %36 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %6, ptr noundef %35, i64 noundef %1) #15
  %37 = load i64, ptr %0, align 8, !tbaa !9
  %38 = add i64 %37, %36
  store i64 %38, ptr %0, align 8, !tbaa !9
  %39 = icmp ult i64 %38, %36
  br i1 %39, label %40, label %402

40:                                               ; preds = %40, %34
  %41 = phi ptr [ %42, %40 ], [ %0, %34 ]
  %42 = getelementptr inbounds i8, ptr %41, i64 8
  %43 = load i64, ptr %42, align 8, !tbaa !9
  %44 = add i64 %43, 1
  store i64 %44, ptr %42, align 8, !tbaa !9
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %40, label %402, !llvm.loop !117

46:                                               ; preds = %7
  %47 = lshr exact i64 %1, 1
  %48 = sub nsw i64 0, %47
  %49 = icmp slt i64 %47, %3
  br i1 %49, label %50, label %228, !prof !30

50:                                               ; preds = %46
  %51 = getelementptr inbounds i64, ptr %2, i64 %47
  %52 = sub nsw i64 %3, %47
  %53 = icmp eq i64 %52, 0
  br i1 %53, label %67, label %54

54:                                               ; preds = %50
  %55 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %2, ptr noundef nonnull %51, i64 noundef %52) #15
  %56 = icmp eq i64 %55, 0
  br i1 %56, label %67, label %57

57:                                               ; preds = %60, %54
  %58 = phi i64 [ %64, %60 ], [ %52, %54 ]
  %59 = icmp slt i64 %58, %47
  br i1 %59, label %60, label %79

60:                                               ; preds = %57
  %61 = getelementptr inbounds i64, ptr %2, i64 %58
  %62 = load i64, ptr %61, align 8, !tbaa !9
  %63 = add i64 %62, 1
  %64 = add nsw i64 %58, 1
  %65 = getelementptr inbounds i64, ptr %6, i64 %58
  store i64 %63, ptr %65, align 8, !tbaa !9
  %66 = icmp eq i64 %63, 0
  br i1 %66, label %57, label %67, !llvm.loop !118

67:                                               ; preds = %60, %54, %50
  %68 = phi i64 [ %52, %54 ], [ 0, %50 ], [ %64, %60 ]
  %69 = icmp ne ptr %6, %2
  %70 = icmp slt i64 %68, %47
  %71 = select i1 %69, i1 %70, i1 false
  br i1 %71, label %72, label %79

72:                                               ; preds = %72, %67
  %73 = phi i64 [ %77, %72 ], [ %68, %67 ]
  %74 = getelementptr inbounds i64, ptr %2, i64 %73
  %75 = load i64, ptr %74, align 8, !tbaa !9
  %76 = getelementptr inbounds i64, ptr %6, i64 %73
  store i64 %75, ptr %76, align 8, !tbaa !9
  %77 = add nsw i64 %73, 1
  %78 = icmp eq i64 %77, %47
  br i1 %78, label %79, label %72, !llvm.loop !119

79:                                               ; preds = %72, %67, %57
  %80 = phi i64 [ 0, %67 ], [ 0, %72 ], [ 1, %57 ]
  %81 = load i64, ptr %6, align 8, !tbaa !9
  %82 = add i64 %81, %80
  store i64 %82, ptr %6, align 8, !tbaa !9
  %83 = icmp ult i64 %82, %80
  br i1 %83, label %84, label %90

84:                                               ; preds = %84, %79
  %85 = phi ptr [ %86, %84 ], [ %6, %79 ]
  %86 = getelementptr inbounds i8, ptr %85, i64 8
  %87 = load i64, ptr %86, align 8, !tbaa !9
  %88 = add i64 %87, 1
  store i64 %88, ptr %86, align 8, !tbaa !9
  %89 = icmp eq i64 %88, 0
  br i1 %89, label %84, label %90, !llvm.loop !120

90:                                               ; preds = %84, %79
  %91 = getelementptr inbounds i64, ptr %6, i64 %47
  %92 = icmp slt i64 %47, %5
  br i1 %92, label %93, label %135, !prof !30

93:                                               ; preds = %90
  %94 = sub nsw i64 %5, %47
  %95 = icmp eq i64 %94, 0
  br i1 %95, label %110, label %96

96:                                               ; preds = %93
  %97 = getelementptr inbounds i64, ptr %4, i64 %47
  %98 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %91, ptr noundef %4, ptr noundef nonnull %97, i64 noundef %94) #15
  %99 = icmp eq i64 %98, 0
  br i1 %99, label %110, label %100

100:                                              ; preds = %103, %96
  %101 = phi i64 [ %107, %103 ], [ %94, %96 ]
  %102 = icmp slt i64 %101, %47
  br i1 %102, label %103, label %122

103:                                              ; preds = %100
  %104 = getelementptr inbounds i64, ptr %4, i64 %101
  %105 = load i64, ptr %104, align 8, !tbaa !9
  %106 = add i64 %105, 1
  %107 = add nsw i64 %101, 1
  %108 = getelementptr inbounds i64, ptr %91, i64 %101
  store i64 %106, ptr %108, align 8, !tbaa !9
  %109 = icmp eq i64 %106, 0
  br i1 %109, label %100, label %110, !llvm.loop !118

110:                                              ; preds = %103, %96, %93
  %111 = phi i64 [ %94, %96 ], [ 0, %93 ], [ %107, %103 ]
  %112 = icmp ne ptr %91, %4
  %113 = icmp slt i64 %111, %47
  %114 = select i1 %112, i1 %113, i1 false
  br i1 %114, label %115, label %122

115:                                              ; preds = %115, %110
  %116 = phi i64 [ %120, %115 ], [ %111, %110 ]
  %117 = getelementptr inbounds i64, ptr %4, i64 %116
  %118 = load i64, ptr %117, align 8, !tbaa !9
  %119 = getelementptr inbounds i64, ptr %91, i64 %116
  store i64 %118, ptr %119, align 8, !tbaa !9
  %120 = add nsw i64 %116, 1
  %121 = icmp eq i64 %120, %47
  br i1 %121, label %122, label %115, !llvm.loop !119

122:                                              ; preds = %115, %110, %100
  %123 = phi i64 [ 0, %110 ], [ 0, %115 ], [ 1, %100 ]
  %124 = load i64, ptr %91, align 8, !tbaa !9
  %125 = add i64 %124, %123
  store i64 %125, ptr %91, align 8, !tbaa !9
  %126 = icmp ult i64 %125, %123
  br i1 %126, label %127, label %133

127:                                              ; preds = %127, %122
  %128 = phi ptr [ %129, %127 ], [ %91, %122 ]
  %129 = getelementptr inbounds i8, ptr %128, i64 8
  %130 = load i64, ptr %129, align 8, !tbaa !9
  %131 = add i64 %130, 1
  store i64 %131, ptr %129, align 8, !tbaa !9
  %132 = icmp eq i64 %131, 0
  br i1 %132, label %127, label %133, !llvm.loop !121

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
  %142 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %140, ptr noundef %2, ptr noundef nonnull %51, i64 noundef %52) #15
  %143 = icmp eq i64 %142, 0
  br i1 %143, label %154, label %144

144:                                              ; preds = %147, %141
  %145 = phi i64 [ %151, %147 ], [ %52, %141 ]
  %146 = icmp slt i64 %145, %47
  br i1 %146, label %147, label %166

147:                                              ; preds = %144
  %148 = getelementptr inbounds i64, ptr %2, i64 %145
  %149 = load i64, ptr %148, align 8, !tbaa !9
  %150 = add i64 %149, -1
  %151 = add nsw i64 %145, 1
  %152 = getelementptr inbounds i64, ptr %140, i64 %145
  store i64 %150, ptr %152, align 8, !tbaa !9
  %153 = icmp eq i64 %149, 0
  br i1 %153, label %144, label %154, !llvm.loop !122

154:                                              ; preds = %147, %141, %135
  %155 = phi i64 [ %52, %141 ], [ 0, %135 ], [ %151, %147 ]
  %156 = icmp ne ptr %140, %2
  %157 = icmp slt i64 %155, %47
  %158 = select i1 %156, i1 %157, i1 false
  br i1 %158, label %159, label %166

159:                                              ; preds = %159, %154
  %160 = phi i64 [ %164, %159 ], [ %155, %154 ]
  %161 = getelementptr inbounds i64, ptr %2, i64 %160
  %162 = load i64, ptr %161, align 8, !tbaa !9
  %163 = getelementptr inbounds i64, ptr %140, i64 %160
  store i64 %162, ptr %163, align 8, !tbaa !9
  %164 = add nsw i64 %160, 1
  %165 = icmp eq i64 %164, %47
  br i1 %165, label %166, label %159, !llvm.loop !123

166:                                              ; preds = %159, %154, %144
  %167 = phi i64 [ 0, %154 ], [ 0, %159 ], [ 1, %144 ]
  %168 = getelementptr inbounds i64, ptr %140, i64 %47
  store i64 0, ptr %168, align 8, !tbaa !9
  %169 = load i64, ptr %140, align 8, !tbaa !9
  %170 = add i64 %169, %167
  store i64 %170, ptr %140, align 8, !tbaa !9
  %171 = icmp ult i64 %170, %167
  br i1 %171, label %172, label %178

172:                                              ; preds = %172, %166
  %173 = phi ptr [ %174, %172 ], [ %140, %166 ]
  %174 = getelementptr inbounds i8, ptr %173, i64 8
  %175 = load i64, ptr %174, align 8, !tbaa !9
  %176 = add i64 %175, 1
  store i64 %176, ptr %174, align 8, !tbaa !9
  %177 = icmp eq i64 %176, 0
  br i1 %177, label %172, label %178, !llvm.loop !124

178:                                              ; preds = %172, %166
  %179 = load i64, ptr %168, align 8, !tbaa !9
  %180 = add i64 %179, %47
  br i1 %92, label %181, label %229, !prof !30

181:                                              ; preds = %178
  %182 = getelementptr inbounds i8, ptr %168, i64 8
  %183 = sub nsw i64 %5, %47
  %184 = icmp eq i64 %183, 0
  br i1 %184, label %199, label %185

185:                                              ; preds = %181
  %186 = getelementptr inbounds i64, ptr %4, i64 %47
  %187 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %182, ptr noundef %4, ptr noundef nonnull %186, i64 noundef %183) #15
  %188 = icmp eq i64 %187, 0
  br i1 %188, label %199, label %189

189:                                              ; preds = %192, %185
  %190 = phi i64 [ %196, %192 ], [ %183, %185 ]
  %191 = icmp slt i64 %190, %47
  br i1 %191, label %192, label %211

192:                                              ; preds = %189
  %193 = getelementptr inbounds i64, ptr %4, i64 %190
  %194 = load i64, ptr %193, align 8, !tbaa !9
  %195 = add i64 %194, -1
  %196 = add nsw i64 %190, 1
  %197 = getelementptr inbounds i64, ptr %182, i64 %190
  store i64 %195, ptr %197, align 8, !tbaa !9
  %198 = icmp eq i64 %194, 0
  br i1 %198, label %189, label %199, !llvm.loop !122

199:                                              ; preds = %192, %185, %181
  %200 = phi i64 [ %183, %185 ], [ 0, %181 ], [ %196, %192 ]
  %201 = icmp ne ptr %182, %4
  %202 = icmp slt i64 %200, %47
  %203 = select i1 %201, i1 %202, i1 false
  br i1 %203, label %204, label %211

204:                                              ; preds = %204, %199
  %205 = phi i64 [ %209, %204 ], [ %200, %199 ]
  %206 = getelementptr inbounds i64, ptr %4, i64 %205
  %207 = load i64, ptr %206, align 8, !tbaa !9
  %208 = getelementptr inbounds i64, ptr %182, i64 %205
  store i64 %207, ptr %208, align 8, !tbaa !9
  %209 = add nsw i64 %205, 1
  %210 = icmp eq i64 %209, %47
  br i1 %210, label %211, label %204, !llvm.loop !123

211:                                              ; preds = %204, %199, %189
  %212 = phi i64 [ 0, %199 ], [ 0, %204 ], [ 1, %189 ]
  %213 = or disjoint i64 %1, 1
  %214 = getelementptr inbounds i64, ptr %140, i64 %213
  store i64 0, ptr %214, align 8, !tbaa !9
  %215 = load i64, ptr %182, align 8, !tbaa !9
  %216 = add i64 %215, %212
  store i64 %216, ptr %182, align 8, !tbaa !9
  %217 = icmp ult i64 %216, %212
  br i1 %217, label %218, label %224

218:                                              ; preds = %218, %211
  %219 = phi ptr [ %220, %218 ], [ %182, %211 ]
  %220 = getelementptr inbounds i8, ptr %219, i64 8
  %221 = load i64, ptr %220, align 8, !tbaa !9
  %222 = add i64 %221, 1
  store i64 %222, ptr %220, align 8, !tbaa !9
  %223 = icmp eq i64 %222, 0
  br i1 %223, label %218, label %224, !llvm.loop !125

224:                                              ; preds = %218, %211
  %225 = getelementptr inbounds i64, ptr %182, i64 %47
  %226 = load i64, ptr %225, align 8, !tbaa !9
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
  %236 = tail call i32 @__gmpn_fft_best_k(i64 noundef %47, i32 noundef 0) #18
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
  br i1 %249, label %250, label %242, !llvm.loop !126

250:                                              ; preds = %242, %235, %229
  %251 = phi i32 [ 0, %229 ], [ %236, %235 ], [ %245, %242 ]
  %252 = icmp sgt i32 %251, 3
  br i1 %252, label %253, label %256

253:                                              ; preds = %250
  %254 = tail call i64 @__gmpn_mul_fft(ptr noundef %6, i64 noundef %47, ptr noundef %230, i64 noundef %232, ptr noundef %231, i64 noundef %233, i32 noundef %251) #15
  %255 = getelementptr inbounds i64, ptr %6, i64 %47
  store i64 %254, ptr %255, align 8, !tbaa !9
  br label %335

256:                                              ; preds = %250
  %257 = icmp eq ptr %231, %4
  br i1 %257, label %258, label %276, !prof !55

258:                                              ; preds = %256
  %259 = tail call i64 @__gmpn_mul(ptr noundef %6, ptr noundef %230, i64 noundef %232, ptr noundef %231, i64 noundef %233) #15
  %260 = sub i64 %232, %47
  %261 = add i64 %260, %233
  %262 = icmp sgt i64 %261, %47
  %263 = sext i1 %262 to i64
  %264 = add i64 %261, %263
  %265 = getelementptr inbounds i64, ptr %6, i64 %47
  %266 = tail call i64 @__gmpn_sub(ptr noundef %6, ptr noundef %6, i64 noundef %47, ptr noundef nonnull %265, i64 noundef %264)
  store i64 0, ptr %265, align 8, !tbaa !9
  %267 = load i64, ptr %6, align 8, !tbaa !9
  %268 = add i64 %267, %266
  store i64 %268, ptr %6, align 8, !tbaa !9
  %269 = icmp ult i64 %268, %266
  br i1 %269, label %270, label %335

270:                                              ; preds = %270, %258
  %271 = phi ptr [ %272, %270 ], [ %6, %258 ]
  %272 = getelementptr inbounds i8, ptr %271, i64 8
  %273 = load i64, ptr %272, align 8, !tbaa !9
  %274 = add i64 %273, 1
  store i64 %274, ptr %272, align 8, !tbaa !9
  %275 = icmp eq i64 %274, 0
  br i1 %275, label %270, label %335, !llvm.loop !127

276:                                              ; preds = %256
  %277 = getelementptr inbounds i64, ptr %230, i64 %47
  %278 = load i64, ptr %277, align 8, !tbaa !9
  %279 = getelementptr inbounds i64, ptr %231, i64 %47
  %280 = load i64, ptr %279, align 8, !tbaa !9
  %281 = or i64 %280, %278
  %282 = icmp eq i64 %281, 0
  br i1 %282, label %290, label %283, !prof !30

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
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #15
  store ptr null, ptr %8, align 8, !tbaa !5
  %317 = shl i64 %1, 4
  %318 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %317) #15
  call void @__gmpn_mulmod_bknp1(ptr noundef %6, ptr noundef %230, ptr noundef %231, i64 noundef %316, i32 noundef %314, ptr noundef %318) #15
  %319 = load ptr, ptr %8, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %319) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #15
  br label %335

320:                                              ; preds = %308, %303, %295, %290
  tail call void @__gmpn_mul_n(ptr noundef %6, ptr noundef %230, ptr noundef %231, i64 noundef %47) #15
  %321 = getelementptr inbounds i64, ptr %6, i64 %47
  %322 = tail call i64 @__gmpn_sub_n(ptr noundef %6, ptr noundef %6, ptr noundef nonnull %321, i64 noundef %47) #15
  br label %323

323:                                              ; preds = %320, %288, %285
  %324 = phi i64 [ %287, %285 ], [ %289, %288 ], [ %322, %320 ]
  %325 = getelementptr inbounds i64, ptr %6, i64 %47
  store i64 0, ptr %325, align 8, !tbaa !9
  %326 = load i64, ptr %6, align 8, !tbaa !9
  %327 = add i64 %326, %324
  store i64 %327, ptr %6, align 8, !tbaa !9
  %328 = icmp ult i64 %327, %324
  br i1 %328, label %329, label %335

329:                                              ; preds = %329, %323
  %330 = phi ptr [ %331, %329 ], [ %6, %323 ]
  %331 = getelementptr inbounds i8, ptr %330, i64 8
  %332 = load i64, ptr %331, align 8, !tbaa !9
  %333 = add i64 %332, 1
  store i64 %333, ptr %331, align 8, !tbaa !9
  %334 = icmp eq i64 %333, 0
  br i1 %334, label %329, label %335, !llvm.loop !128

335:                                              ; preds = %329, %323, %313, %270, %258, %253
  %336 = getelementptr inbounds i64, ptr %6, i64 %47
  %337 = load i64, ptr %336, align 8, !tbaa !9
  %338 = call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %6, i64 noundef %47) #15
  %339 = add i64 %338, %337
  %340 = load i64, ptr %0, align 8, !tbaa !9
  %341 = and i64 %340, 1
  %342 = add i64 %339, %341
  %343 = call i64 @__gmpn_rshift(ptr noundef nonnull %0, ptr noundef nonnull %0, i64 noundef %47, i32 noundef 1) #15
  %344 = shl i64 %342, 63
  %345 = getelementptr i64, ptr %0, i64 %47
  %346 = getelementptr i8, ptr %345, i64 -8
  %347 = load i64, ptr %346, align 8, !tbaa !9
  %348 = or i64 %344, %347
  store i64 %348, ptr %346, align 8, !tbaa !9
  %349 = lshr i64 %342, 1
  %350 = load i64, ptr %0, align 8, !tbaa !9
  %351 = add i64 %350, %349
  store i64 %351, ptr %0, align 8, !tbaa !9
  %352 = icmp ult i64 %351, %349
  br i1 %352, label %353, label %359

353:                                              ; preds = %353, %335
  %354 = phi ptr [ %355, %353 ], [ %0, %335 ]
  %355 = getelementptr inbounds i8, ptr %354, i64 8
  %356 = load i64, ptr %355, align 8, !tbaa !9
  %357 = add i64 %356, 1
  store i64 %357, ptr %355, align 8, !tbaa !9
  %358 = icmp eq i64 %357, 0
  br i1 %358, label %353, label %359, !llvm.loop !129

359:                                              ; preds = %353, %335
  %360 = add nsw i64 %5, %3
  %361 = icmp slt i64 %360, %1
  br i1 %361, label %362, label %389, !prof !55

362:                                              ; preds = %359
  %363 = sub nsw i64 %360, %47
  %364 = call i64 @__gmpn_sub_n(ptr noundef nonnull %345, ptr noundef nonnull %0, ptr noundef %6, i64 noundef %363) #15
  %365 = load i64, ptr %336, align 8, !tbaa !9
  %366 = getelementptr inbounds i64, ptr %6, i64 %3
  %367 = getelementptr inbounds i64, ptr %366, i64 %5
  %368 = getelementptr inbounds i64, ptr %367, i64 %48
  %369 = getelementptr inbounds i64, ptr %0, i64 %3
  %370 = getelementptr inbounds i64, ptr %369, i64 %5
  %371 = getelementptr inbounds i64, ptr %370, i64 %48
  %372 = sub nsw i64 %1, %360
  %373 = call fastcc i64 @mpn_sub_nc.75(ptr noundef nonnull %368, ptr noundef nonnull %371, ptr noundef nonnull %368, i64 noundef %372, i64 noundef %364)
  %374 = add i64 %373, %365
  %375 = load i64, ptr %0, align 8, !tbaa !9
  %376 = sub i64 %375, %374
  store i64 %376, ptr %0, align 8, !tbaa !9
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
  %385 = load i64, ptr %384, align 8, !tbaa !9
  %386 = add i64 %385, -1
  store i64 %386, ptr %384, align 8, !tbaa !9
  %387 = add nuw i64 %381, 1
  %388 = icmp eq i64 %385, 0
  br i1 %388, label %380, label %402, !llvm.loop !130

389:                                              ; preds = %359
  %390 = load i64, ptr %336, align 8, !tbaa !9
  %391 = call i64 @__gmpn_sub_n(ptr noundef nonnull %345, ptr noundef nonnull %0, ptr noundef %6, i64 noundef %47) #15
  %392 = add i64 %391, %390
  %393 = load i64, ptr %0, align 8, !tbaa !9
  %394 = sub i64 %393, %392
  store i64 %394, ptr %0, align 8, !tbaa !9
  %395 = icmp ult i64 %393, %392
  br i1 %395, label %396, label %402

396:                                              ; preds = %396, %389
  %397 = phi ptr [ %398, %396 ], [ %0, %389 ]
  %398 = getelementptr inbounds i8, ptr %397, i64 8
  %399 = load i64, ptr %398, align 8, !tbaa !9
  %400 = add i64 %399, -1
  store i64 %400, ptr %398, align 8, !tbaa !9
  %401 = icmp eq i64 %399, 0
  br i1 %401, label %396, label %402, !llvm.loop !131

402:                                              ; preds = %396, %389, %383, %380, %362, %40, %34, %28, %20, %18
  ret void
}

; Function Attrs: inlinehint nounwind ssp uwtable
define hidden fastcc i64 @mpn_sub_nc.75(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4) unnamed_addr #11 {
  %6 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) #15
  %7 = load i64, ptr %0, align 8, !tbaa !9
  %8 = sub i64 %7, %4
  store i64 %8, ptr %0, align 8, !tbaa !9
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
  %17 = load i64, ptr %16, align 8, !tbaa !9
  %18 = add i64 %17, -1
  store i64 %18, ptr %16, align 8, !tbaa !9
  %19 = add nuw i64 %13, 1
  %20 = icmp eq i64 %17, 0
  br i1 %20, label %12, label %21, !llvm.loop !130

21:                                               ; preds = %15, %12, %5
  %22 = phi i64 [ 0, %5 ], [ 1, %12 ], [ 0, %15 ]
  %23 = add i64 %22, %6
  ret i64 %23
}

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define i64 @__gmpn_mulmod_bnm1_next_size(i64 noundef %0) local_unnamed_addr #12 {
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
  %21 = tail call i32 @__gmpn_fft_best_k(i64 noundef %20, i32 noundef 0) #18
  %22 = tail call i64 @__gmpn_fft_next_size(i64 noundef %20, i32 noundef %21) #18
  %23 = shl nsw i64 %22, 1
  br label %24

24:                                               ; preds = %18, %15, %10, %5, %1
  %25 = phi i64 [ %23, %18 ], [ %17, %15 ], [ %12, %10 ], [ %7, %5 ], [ %0, %1 ]
  ret i64 %25
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_pm1(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, ptr noundef %6) local_unnamed_addr #3 {
  %8 = shl nsw i64 %4, 4
  %9 = getelementptr inbounds i8, ptr %3, i64 %8
  %10 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %3, ptr noundef %9, i64 noundef %4) #15
  %11 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %10, ptr %11, align 8, !tbaa !9
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
  %21 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %20, i64 noundef %4) #15
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %32, label %23

23:                                               ; preds = %26, %17
  %24 = phi i64 [ %30, %26 ], [ %4, %17 ]
  %25 = icmp sgt i64 %24, %4
  br i1 %25, label %32, label %26

26:                                               ; preds = %23
  %27 = getelementptr inbounds i64, ptr %0, i64 %24
  %28 = load i64, ptr %27, align 8, !tbaa !9
  %29 = add i64 %28, 1
  %30 = add nsw i64 %24, 1
  store i64 %29, ptr %27, align 8, !tbaa !9
  %31 = icmp eq i64 %29, 0
  br i1 %31, label %23, label %32, !llvm.loop !132

32:                                               ; preds = %26, %23, %17, %15
  %33 = add i32 %16, 2
  %34 = icmp ult i32 %33, %2
  br i1 %34, label %15, label %35, !llvm.loop !133

35:                                               ; preds = %32, %7
  %36 = getelementptr inbounds i64, ptr %3, i64 %4
  %37 = mul i64 %4, 24
  %38 = getelementptr inbounds i8, ptr %3, i64 %37
  %39 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %36, ptr noundef %38, i64 noundef %4) #15
  %40 = getelementptr inbounds i64, ptr %6, i64 %4
  store i64 %39, ptr %40, align 8, !tbaa !9
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
  %50 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %49, i64 noundef %4) #15
  %51 = icmp eq i64 %50, 0
  br i1 %51, label %61, label %52

52:                                               ; preds = %55, %46
  %53 = phi i64 [ %59, %55 ], [ %4, %46 ]
  %54 = icmp sgt i64 %53, %4
  br i1 %54, label %61, label %55

55:                                               ; preds = %52
  %56 = getelementptr inbounds i64, ptr %6, i64 %53
  %57 = load i64, ptr %56, align 8, !tbaa !9
  %58 = add i64 %57, 1
  %59 = add nsw i64 %53, 1
  store i64 %58, ptr %56, align 8, !tbaa !9
  %60 = icmp eq i64 %58, 0
  br i1 %60, label %52, label %61, !llvm.loop !132

61:                                               ; preds = %55, %52, %46, %44
  %62 = add i32 %45, 2
  %63 = icmp ult i32 %62, %2
  br i1 %63, label %44, label %64, !llvm.loop !134

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
  %73 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %72, i64 noundef %5) #15
  %74 = icmp eq i64 %73, 0
  br i1 %74, label %100, label %75

75:                                               ; preds = %78, %69
  %76 = phi i64 [ %82, %78 ], [ %5, %69 ]
  %77 = icmp sgt i64 %76, %4
  br i1 %77, label %100, label %78

78:                                               ; preds = %75
  %79 = getelementptr inbounds i64, ptr %6, i64 %76
  %80 = load i64, ptr %79, align 8, !tbaa !9
  %81 = add i64 %80, 1
  %82 = add nsw i64 %76, 1
  store i64 %81, ptr %79, align 8, !tbaa !9
  %83 = icmp eq i64 %81, 0
  br i1 %83, label %75, label %100, !llvm.loop !132

84:                                               ; preds = %64
  br i1 %67, label %100, label %85

85:                                               ; preds = %84
  %86 = zext i32 %2 to i64
  %87 = mul nsw i64 %86, %4
  %88 = getelementptr inbounds i64, ptr %3, i64 %87
  %89 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %88, i64 noundef %5) #15
  %90 = icmp eq i64 %89, 0
  br i1 %90, label %100, label %91

91:                                               ; preds = %94, %85
  %92 = phi i64 [ %98, %94 ], [ %5, %85 ]
  %93 = icmp sgt i64 %92, %4
  br i1 %93, label %100, label %94

94:                                               ; preds = %91
  %95 = getelementptr inbounds i64, ptr %0, i64 %92
  %96 = load i64, ptr %95, align 8, !tbaa !9
  %97 = add i64 %96, 1
  %98 = add nsw i64 %92, 1
  store i64 %97, ptr %95, align 8, !tbaa !9
  %99 = icmp eq i64 %97, 0
  br i1 %99, label %91, label %100, !llvm.loop !132

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
  %108 = load i64, ptr %107, align 8, !tbaa !9
  %109 = getelementptr inbounds i64, ptr %6, i64 %106
  %110 = load i64, ptr %109, align 8, !tbaa !9
  %111 = icmp eq i64 %108, %110
  br i1 %111, label %102, label %112, !llvm.loop !135

112:                                              ; preds = %105
  %113 = icmp ugt i64 %108, %110
  %114 = select i1 %113, i32 1, i32 -1
  br label %115

115:                                              ; preds = %112, %102
  %116 = phi i32 [ %114, %112 ], [ 0, %102 ]
  %117 = icmp slt i32 %116, 0
  br i1 %117, label %118, label %120

118:                                              ; preds = %115
  %119 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %6, ptr noundef %0, i64 noundef %101) #15
  br label %122

120:                                              ; preds = %115
  %121 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %6, i64 noundef %101) #15
  br label %122

122:                                              ; preds = %120, %118
  %123 = ashr i32 %116, 31
  %124 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %6, i64 noundef %101) #15
  ret i32 %123
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_add(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #3 {
  %6 = icmp eq i64 %4, 0
  br i1 %6, label %20, label %7

7:                                                ; preds = %5
  %8 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %4) #15
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %20, label %10

10:                                               ; preds = %13, %7
  %11 = phi i64 [ %17, %13 ], [ %4, %7 ]
  %12 = icmp slt i64 %11, %2
  br i1 %12, label %13, label %32

13:                                               ; preds = %10
  %14 = getelementptr inbounds i64, ptr %1, i64 %11
  %15 = load i64, ptr %14, align 8, !tbaa !9
  %16 = add i64 %15, 1
  %17 = add nsw i64 %11, 1
  %18 = getelementptr inbounds i64, ptr %0, i64 %11
  store i64 %16, ptr %18, align 8, !tbaa !9
  %19 = icmp eq i64 %16, 0
  br i1 %19, label %10, label %20, !llvm.loop !136

20:                                               ; preds = %13, %7, %5
  %21 = phi i64 [ %4, %7 ], [ 0, %5 ], [ %17, %13 ]
  %22 = icmp ne ptr %0, %1
  %23 = icmp slt i64 %21, %2
  %24 = select i1 %22, i1 %23, i1 false
  br i1 %24, label %25, label %32

25:                                               ; preds = %25, %20
  %26 = phi i64 [ %30, %25 ], [ %21, %20 ]
  %27 = getelementptr inbounds i64, ptr %1, i64 %26
  %28 = load i64, ptr %27, align 8, !tbaa !9
  %29 = getelementptr inbounds i64, ptr %0, i64 %26
  store i64 %28, ptr %29, align 8, !tbaa !9
  %30 = add nsw i64 %26, 1
  %31 = icmp eq i64 %30, %2
  br i1 %31, label %32, label %25, !llvm.loop !137

32:                                               ; preds = %25, %20, %10
  %33 = phi i64 [ 0, %20 ], [ 0, %25 ], [ 1, %10 ]
  ret i64 %33
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define void @__gmpn_com(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2) local_unnamed_addr #5 {
  br label %4

4:                                                ; preds = %4, %3
  %5 = phi ptr [ %1, %3 ], [ %8, %4 ]
  %6 = phi i64 [ %2, %3 ], [ %12, %4 ]
  %7 = phi ptr [ %0, %3 ], [ %11, %4 ]
  %8 = getelementptr inbounds i8, ptr %5, i64 8
  %9 = load i64, ptr %5, align 8, !tbaa !9
  %10 = xor i64 %9, -1
  %11 = getelementptr inbounds i8, ptr %7, i64 8
  store i64 %10, ptr %7, align 8, !tbaa !9
  %12 = add nsw i64 %6, -1
  %13 = icmp eq i64 %12, 0
  br i1 %13, label %14, label %4, !llvm.loop !138

14:                                               ; preds = %4
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_7pts(ptr noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6, i64 noundef %7, ptr noundef %8) local_unnamed_addr #3 {
  %10 = shl nsw i64 %1, 1
  %11 = or disjoint i64 %10, 1
  %12 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %5, i64 noundef %11) #15
  %13 = and i32 %2, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %9
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %3, ptr noundef %5, i64 noundef %11) #15
  br label %19

17:                                               ; preds = %9
  %18 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %5, ptr noundef %3, i64 noundef %11) #15
  br label %19

19:                                               ; preds = %17, %15
  %20 = tail call i64 @__gmpn_rshift(ptr noundef %3, ptr noundef %3, i64 noundef %11, i32 noundef 1) #15
  %21 = icmp eq i64 %1, 0
  br i1 %21, label %36, label %22

22:                                               ; preds = %19
  %23 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %10) #15
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
  %32 = load i64, ptr %31, align 8, !tbaa !9
  %33 = add i64 %32, -1
  %34 = add i64 %28, 1
  store i64 %33, ptr %31, align 8, !tbaa !9
  %35 = icmp eq i64 %32, 0
  br i1 %35, label %27, label %36, !llvm.loop !139

36:                                               ; preds = %30, %27, %22, %19
  %37 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %3, i64 noundef %11) #15
  %38 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %11, i32 noundef 2) #15
  %39 = mul i64 %1, 48
  %40 = getelementptr inbounds i8, ptr %0, i64 %39
  %41 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %40, i64 noundef %7, i32 noundef 4) #15
  %42 = getelementptr inbounds i64, ptr %8, i64 %7
  store i64 %41, ptr %42, align 8, !tbaa !9
  %43 = add nsw i64 %7, 1
  %44 = icmp eq i64 %43, 0
  br i1 %44, label %57, label %45

45:                                               ; preds = %36
  %46 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %8, i64 noundef %43) #15
  %47 = icmp eq i64 %46, 0
  br i1 %47, label %57, label %48

48:                                               ; preds = %51, %45
  %49 = phi i64 [ %55, %51 ], [ %43, %45 ]
  %50 = icmp sgt i64 %49, %10
  br i1 %50, label %57, label %51

51:                                               ; preds = %48
  %52 = getelementptr inbounds i64, ptr %5, i64 %49
  %53 = load i64, ptr %52, align 8, !tbaa !9
  %54 = add i64 %53, -1
  %55 = add nsw i64 %49, 1
  store i64 %54, ptr %52, align 8, !tbaa !9
  %56 = icmp eq i64 %53, 0
  br i1 %56, label %48, label %57, !llvm.loop !139

57:                                               ; preds = %51, %48, %45, %36
  %58 = and i32 %2, 2
  %59 = icmp eq i32 %58, 0
  %60 = getelementptr inbounds i64, ptr %0, i64 %10
  br i1 %59, label %63, label %61

61:                                               ; preds = %57
  %62 = tail call i64 @__gmpn_add_n(ptr noundef %4, ptr noundef %4, ptr noundef %60, i64 noundef %11) #15
  br label %65

63:                                               ; preds = %57
  %64 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %60, ptr noundef %4, i64 noundef %11) #15
  br label %65

65:                                               ; preds = %63, %61
  %66 = tail call i64 @__gmpn_rshift(ptr noundef %4, ptr noundef %4, i64 noundef %11, i32 noundef 1) #15
  %67 = getelementptr inbounds i64, ptr %0, i64 %10
  %68 = tail call i64 @__gmpn_sub_n(ptr noundef %67, ptr noundef %67, ptr noundef %4, i64 noundef %11) #15
  %69 = tail call i64 @__gmpn_submul_1(ptr noundef %6, ptr noundef %67, i64 noundef %11, i64 noundef 65) #15
  %70 = icmp eq i64 %7, 0
  br i1 %70, label %83, label %71

71:                                               ; preds = %65
  %72 = tail call i64 @__gmpn_sub_n(ptr noundef %67, ptr noundef %67, ptr noundef %40, i64 noundef %7) #15
  %73 = icmp eq i64 %72, 0
  br i1 %73, label %83, label %74

74:                                               ; preds = %77, %71
  %75 = phi i64 [ %81, %77 ], [ %7, %71 ]
  %76 = icmp sgt i64 %75, %10
  br i1 %76, label %83, label %77

77:                                               ; preds = %74
  %78 = getelementptr inbounds i64, ptr %67, i64 %75
  %79 = load i64, ptr %78, align 8, !tbaa !9
  %80 = add i64 %79, -1
  %81 = add nsw i64 %75, 1
  store i64 %80, ptr %78, align 8, !tbaa !9
  %82 = icmp eq i64 %79, 0
  br i1 %82, label %74, label %83, !llvm.loop !139

83:                                               ; preds = %77, %74, %71, %65
  br i1 %21, label %98, label %84

84:                                               ; preds = %83
  %85 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %67, ptr noundef nonnull %67, ptr noundef %0, i64 noundef %10) #15
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
  %94 = load i64, ptr %93, align 8, !tbaa !9
  %95 = add i64 %94, -1
  %96 = add i64 %90, 1
  store i64 %95, ptr %93, align 8, !tbaa !9
  %97 = icmp eq i64 %94, 0
  br i1 %97, label %89, label %98, !llvm.loop !139

98:                                               ; preds = %92, %89, %84, %83
  %99 = tail call i64 @__gmpn_addmul_1(ptr noundef %6, ptr noundef %67, i64 noundef %11, i64 noundef 45) #15
  %100 = tail call i64 @__gmpn_rshift(ptr noundef %6, ptr noundef %6, i64 noundef %11, i32 noundef 1) #15
  %101 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %67, i64 noundef %11) #15
  %102 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %5, ptr noundef %5, i64 noundef %11, i64 noundef 6148914691236517205, i64 noundef 0) #15
  %103 = tail call i64 @__gmpn_sub_n(ptr noundef %67, ptr noundef %67, ptr noundef %5, i64 noundef %11) #15
  %104 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %6, ptr noundef %3, i64 noundef %11) #15
  %105 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %4, i64 noundef %11, i32 noundef 3) #15
  %106 = tail call i64 @__gmpn_sub_n(ptr noundef %6, ptr noundef %6, ptr noundef %8, i64 noundef %11) #15
  tail call void @__gmpn_divexact_1(ptr noundef %6, ptr noundef %6, i64 noundef %11, i64 noundef 9) #15
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %6, i64 noundef %11) #15
  %108 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %3, ptr noundef %3, i64 noundef %11, i64 noundef 1229782938247303441, i64 noundef 0) #15
  %109 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %3, ptr noundef %6, i64 noundef %11) #15
  %110 = tail call i64 @__gmpn_rshift(ptr noundef %3, ptr noundef %3, i64 noundef %11, i32 noundef 1) #15
  %111 = tail call i64 @__gmpn_sub_n(ptr noundef %6, ptr noundef %6, ptr noundef %3, i64 noundef %11) #15
  %112 = getelementptr inbounds i64, ptr %0, i64 %1
  %113 = tail call i64 @__gmpn_add_n(ptr noundef %112, ptr noundef %112, ptr noundef %3, i64 noundef %11) #15
  %114 = getelementptr inbounds i64, ptr %67, i64 %1
  %115 = getelementptr inbounds i8, ptr %114, i64 8
  %116 = load i64, ptr %115, align 8, !tbaa !9
  %117 = add i64 %116, %113
  store i64 %117, ptr %115, align 8, !tbaa !9
  %118 = icmp ult i64 %117, %113
  br i1 %118, label %119, label %125

119:                                              ; preds = %119, %98
  %120 = phi ptr [ %121, %119 ], [ %115, %98 ]
  %121 = getelementptr inbounds i8, ptr %120, i64 8
  %122 = load i64, ptr %121, align 8, !tbaa !9
  %123 = add i64 %122, 1
  store i64 %123, ptr %121, align 8, !tbaa !9
  %124 = icmp eq i64 %123, 0
  br i1 %124, label %119, label %125, !llvm.loop !140

125:                                              ; preds = %119, %98
  %126 = mul i64 %1, 24
  %127 = getelementptr inbounds i8, ptr %0, i64 %126
  %128 = tail call i64 @__gmpn_add_n(ptr noundef %127, ptr noundef %127, ptr noundef %4, i64 noundef %1) #15
  %129 = getelementptr inbounds i64, ptr %4, i64 %1
  %130 = getelementptr inbounds i64, ptr %67, i64 %10
  %131 = load i64, ptr %130, align 8, !tbaa !9
  %132 = add i64 %131, %128
  %133 = load i64, ptr %129, align 8, !tbaa !9
  %134 = add i64 %133, %132
  store i64 %134, ptr %129, align 8, !tbaa !9
  %135 = load i64, ptr %130, align 8, !tbaa !9
  %136 = add i64 %135, %128
  %137 = icmp ult i64 %134, %136
  br i1 %137, label %138, label %144

138:                                              ; preds = %138, %125
  %139 = phi ptr [ %140, %138 ], [ %129, %125 ]
  %140 = getelementptr inbounds i8, ptr %139, i64 8
  %141 = load i64, ptr %140, align 8, !tbaa !9
  %142 = add i64 %141, 1
  store i64 %142, ptr %140, align 8, !tbaa !9
  %143 = icmp eq i64 %142, 0
  br i1 %143, label %138, label %144, !llvm.loop !141

144:                                              ; preds = %138, %125
  %145 = shl nsw i64 %1, 5
  %146 = getelementptr inbounds i8, ptr %0, i64 %145
  %147 = tail call i64 @__gmpn_add_n(ptr noundef %146, ptr noundef nonnull %129, ptr noundef %5, i64 noundef %1) #15
  %148 = getelementptr inbounds i64, ptr %5, i64 %1
  %149 = getelementptr inbounds i64, ptr %4, i64 %10
  %150 = load i64, ptr %149, align 8, !tbaa !9
  %151 = add i64 %150, %147
  %152 = load i64, ptr %148, align 8, !tbaa !9
  %153 = add i64 %152, %151
  store i64 %153, ptr %148, align 8, !tbaa !9
  %154 = load i64, ptr %149, align 8, !tbaa !9
  %155 = add i64 %154, %147
  %156 = icmp ult i64 %153, %155
  br i1 %156, label %157, label %163

157:                                              ; preds = %157, %144
  %158 = phi ptr [ %159, %157 ], [ %148, %144 ]
  %159 = getelementptr inbounds i8, ptr %158, i64 8
  %160 = load i64, ptr %159, align 8, !tbaa !9
  %161 = add i64 %160, 1
  store i64 %161, ptr %159, align 8, !tbaa !9
  %162 = icmp eq i64 %161, 0
  br i1 %162, label %157, label %163, !llvm.loop !142

163:                                              ; preds = %157, %144
  %164 = mul i64 %1, 40
  %165 = getelementptr inbounds i8, ptr %0, i64 %164
  %166 = tail call i64 @__gmpn_add_n(ptr noundef %165, ptr noundef nonnull %148, ptr noundef %6, i64 noundef %1) #15
  %167 = getelementptr inbounds i64, ptr %6, i64 %1
  %168 = getelementptr inbounds i64, ptr %5, i64 %10
  %169 = load i64, ptr %168, align 8, !tbaa !9
  %170 = add i64 %169, %166
  %171 = load i64, ptr %167, align 8, !tbaa !9
  %172 = add i64 %171, %170
  store i64 %172, ptr %167, align 8, !tbaa !9
  %173 = load i64, ptr %168, align 8, !tbaa !9
  %174 = add i64 %173, %166
  %175 = icmp ult i64 %172, %174
  br i1 %175, label %176, label %182

176:                                              ; preds = %176, %163
  %177 = phi ptr [ %178, %176 ], [ %167, %163 ]
  %178 = getelementptr inbounds i8, ptr %177, i64 8
  %179 = load i64, ptr %178, align 8, !tbaa !9
  %180 = add i64 %179, 1
  store i64 %180, ptr %178, align 8, !tbaa !9
  %181 = icmp eq i64 %180, 0
  br i1 %181, label %176, label %182, !llvm.loop !143

182:                                              ; preds = %176, %163
  %183 = add nsw i64 %1, 1
  %184 = icmp slt i64 %183, %7
  br i1 %184, label %185, label %199

185:                                              ; preds = %182
  %186 = tail call i64 @__gmpn_add_n(ptr noundef %40, ptr noundef %40, ptr noundef nonnull %167, i64 noundef %183) #15
  %187 = mul i64 %1, 56
  %188 = getelementptr inbounds i8, ptr %0, i64 %187
  %189 = getelementptr inbounds i8, ptr %188, i64 8
  %190 = load i64, ptr %189, align 8, !tbaa !9
  %191 = add i64 %190, %186
  store i64 %191, ptr %189, align 8, !tbaa !9
  %192 = icmp ult i64 %191, %186
  br i1 %192, label %193, label %201

193:                                              ; preds = %193, %185
  %194 = phi ptr [ %195, %193 ], [ %189, %185 ]
  %195 = getelementptr inbounds i8, ptr %194, i64 8
  %196 = load i64, ptr %195, align 8, !tbaa !9
  %197 = add i64 %196, 1
  store i64 %197, ptr %195, align 8, !tbaa !9
  %198 = icmp eq i64 %197, 0
  br i1 %198, label %193, label %201, !llvm.loop !144

199:                                              ; preds = %182
  %200 = tail call i64 @__gmpn_add_n(ptr noundef %40, ptr noundef %40, ptr noundef nonnull %167, i64 noundef %7) #15
  br label %201

201:                                              ; preds = %199, %193, %185
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_submul_1(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #5 {
  %5 = lshr i64 %3, 32
  %6 = and i64 %3, 4294967295
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %39, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %41, %7 ]
  %10 = phi ptr [ %1, %4 ], [ %12, %7 ]
  %11 = phi ptr [ %0, %4 ], [ %40, %7 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 8
  %13 = load i64, ptr %10, align 8, !tbaa !9
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
  %31 = load i64, ptr %11, align 8, !tbaa !9
  %32 = sub i64 %31, %30
  %33 = icmp ult i64 %31, %30
  %34 = zext i1 %33 to i64
  %35 = add i64 %27, %34
  %36 = sub i64 %32, %8
  %37 = icmp ult i64 %32, %8
  %38 = zext i1 %37 to i64
  %39 = add i64 %35, %38
  %40 = getelementptr inbounds i8, ptr %11, i64 8
  store i64 %36, ptr %11, align 8, !tbaa !9
  %41 = add nsw i64 %9, -1
  %42 = icmp eq i64 %41, 0
  br i1 %42, label %43, label %7, !llvm.loop !145

43:                                               ; preds = %7
  ret i64 %39
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_sub(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #3 {
  %6 = icmp eq i64 %4, 0
  br i1 %6, label %20, label %7

7:                                                ; preds = %5
  %8 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %4) #15
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %20, label %10

10:                                               ; preds = %13, %7
  %11 = phi i64 [ %17, %13 ], [ %4, %7 ]
  %12 = icmp slt i64 %11, %2
  br i1 %12, label %13, label %32

13:                                               ; preds = %10
  %14 = getelementptr inbounds i64, ptr %1, i64 %11
  %15 = load i64, ptr %14, align 8, !tbaa !9
  %16 = add i64 %15, -1
  %17 = add nsw i64 %11, 1
  %18 = getelementptr inbounds i64, ptr %0, i64 %11
  store i64 %16, ptr %18, align 8, !tbaa !9
  %19 = icmp eq i64 %15, 0
  br i1 %19, label %10, label %20, !llvm.loop !146

20:                                               ; preds = %13, %7, %5
  %21 = phi i64 [ %4, %7 ], [ 0, %5 ], [ %17, %13 ]
  %22 = icmp ne ptr %0, %1
  %23 = icmp slt i64 %21, %2
  %24 = select i1 %22, i1 %23, i1 false
  br i1 %24, label %25, label %32

25:                                               ; preds = %25, %20
  %26 = phi i64 [ %30, %25 ], [ %21, %20 ]
  %27 = getelementptr inbounds i64, ptr %1, i64 %26
  %28 = load i64, ptr %27, align 8, !tbaa !9
  %29 = getelementptr inbounds i64, ptr %0, i64 %26
  store i64 %28, ptr %29, align 8, !tbaa !9
  %30 = add nsw i64 %26, 1
  %31 = icmp eq i64 %30, %2
  br i1 %31, label %32, label %25, !llvm.loop !147

32:                                               ; preds = %25, %20, %10
  %33 = phi i64 [ 0, %20 ], [ 0, %25 ], [ 1, %10 ]
  ret i64 %33
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #15
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
  store ptr null, ptr %7, align 8, !tbaa !5
  %18 = mul i64 %14, 48
  %19 = add i64 %18, 40
  %20 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %19) #15
  %21 = add nsw i64 %14, 1
  %22 = getelementptr inbounds i64, ptr %20, i64 %21
  %23 = getelementptr i64, ptr %22, i64 %21
  %24 = getelementptr i64, ptr %23, i64 %21
  %25 = getelementptr i64, ptr %24, i64 %21
  %26 = getelementptr inbounds i64, ptr %25, i64 %14
  %27 = call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef %20, ptr noundef %22, ptr noundef %1, i64 noundef %14, i64 noundef %16, ptr noundef %0) #15
  %28 = and i32 %27, 1
  %29 = getelementptr inbounds i64, ptr %1, i64 %15
  %30 = call i64 @__gmpn_lshift(ptr noundef %23, ptr noundef %29, i64 noundef %16, i32 noundef 1) #15
  %31 = shl nsw i64 %14, 1
  %32 = getelementptr inbounds i64, ptr %1, i64 %31
  %33 = call i64 @__gmpn_add_n(ptr noundef %23, ptr noundef %32, ptr noundef %23, i64 noundef %16) #15
  %34 = add i64 %33, %30
  %35 = icmp eq i64 %16, %14
  br i1 %35, label %95, label %36

36:                                               ; preds = %6
  %37 = getelementptr inbounds i64, ptr %23, i64 %16
  %38 = getelementptr inbounds i64, ptr %32, i64 %16
  %39 = sub nsw i64 %14, %16
  %40 = load i64, ptr %38, align 8, !tbaa !9
  %41 = add i64 %40, %34
  store i64 %41, ptr %37, align 8, !tbaa !9
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
  %51 = load i64, ptr %50, align 8, !tbaa !9
  %52 = add i64 %51, 1
  %53 = getelementptr inbounds i64, ptr %37, i64 %47
  store i64 %52, ptr %53, align 8, !tbaa !9
  %54 = add nuw i64 %47, 1
  %55 = icmp eq i64 %52, 0
  %56 = add i64 %46, 1
  br i1 %55, label %45, label %57, !llvm.loop !148

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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %68, ptr align 8 %72, i64 %77, i1 false), !tbaa !9
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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %87, ptr align 8 %90, i64 %94, i1 false), !tbaa !9
  br label %95

95:                                               ; preds = %82, %78, %61, %57, %45, %6
  %96 = phi i64 [ %34, %6 ], [ 0, %57 ], [ 0, %78 ], [ 0, %61 ], [ 0, %82 ], [ 1, %45 ]
  %97 = shl i64 %96, 1
  %98 = call i64 @__gmpn_lshift(ptr noundef %23, ptr noundef %23, i64 noundef %14, i32 noundef 1) #15
  %99 = add i64 %97, %98
  %100 = getelementptr inbounds i64, ptr %1, i64 %14
  %101 = call i64 @__gmpn_add_n(ptr noundef %23, ptr noundef %100, ptr noundef %23, i64 noundef %14) #15
  %102 = add i64 %99, %101
  %103 = shl i64 %102, 1
  %104 = call i64 @__gmpn_lshift(ptr noundef %23, ptr noundef %23, i64 noundef %14, i32 noundef 1) #15
  %105 = add i64 %103, %104
  %106 = call i64 @__gmpn_add_n(ptr noundef %23, ptr noundef %1, ptr noundef %23, i64 noundef %14) #15
  %107 = add i64 %105, %106
  %108 = getelementptr inbounds i64, ptr %23, i64 %14
  store i64 %107, ptr %108, align 8, !tbaa !9
  %109 = icmp eq i64 %17, %14
  %110 = getelementptr inbounds i64, ptr %3, i64 %14
  br i1 %109, label %111, label %131

111:                                              ; preds = %95
  %112 = call i64 @__gmpn_add_n(ptr noundef %24, ptr noundef %3, ptr noundef %110, i64 noundef %14) #15
  %113 = getelementptr inbounds i64, ptr %24, i64 %14
  store i64 %112, ptr %113, align 8, !tbaa !9
  br label %114

114:                                              ; preds = %117, %111
  %115 = phi i64 [ %14, %111 ], [ %118, %117 ]
  %116 = icmp sgt i64 %115, 0
  br i1 %116, label %117, label %129

117:                                              ; preds = %114
  %118 = add nsw i64 %115, -1
  %119 = getelementptr inbounds i64, ptr %3, i64 %118
  %120 = load i64, ptr %119, align 8, !tbaa !9
  %121 = getelementptr inbounds i64, ptr %110, i64 %118
  %122 = load i64, ptr %121, align 8, !tbaa !9
  %123 = icmp eq i64 %120, %122
  br i1 %123, label %114, label %124, !llvm.loop !149

124:                                              ; preds = %117
  %125 = icmp ugt i64 %120, %122
  br i1 %125, label %129, label %126

126:                                              ; preds = %124
  %127 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %110, ptr noundef %3, i64 noundef %14) #15
  %128 = xor i32 %28, 1
  br label %224

129:                                              ; preds = %124, %114
  %130 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %3, ptr noundef %110, i64 noundef %14) #15
  br label %224

131:                                              ; preds = %95
  %132 = icmp eq i64 %17, 0
  br i1 %132, label %146, label %133

133:                                              ; preds = %131
  %134 = call i64 @__gmpn_add_n(ptr noundef %24, ptr noundef %3, ptr noundef %110, i64 noundef %17) #15
  %135 = icmp eq i64 %134, 0
  br i1 %135, label %146, label %136

136:                                              ; preds = %139, %133
  %137 = phi i64 [ %143, %139 ], [ %17, %133 ]
  %138 = icmp slt i64 %137, %14
  br i1 %138, label %139, label %160

139:                                              ; preds = %136
  %140 = getelementptr inbounds i64, ptr %3, i64 %137
  %141 = load i64, ptr %140, align 8, !tbaa !9
  %142 = add i64 %141, 1
  %143 = add nsw i64 %137, 1
  %144 = getelementptr inbounds i64, ptr %24, i64 %137
  store i64 %142, ptr %144, align 8, !tbaa !9
  %145 = icmp eq i64 %142, 0
  br i1 %145, label %136, label %146, !llvm.loop !150

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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %156, ptr align 8 %157, i64 %159, i1 false), !tbaa !9
  br label %160

160:                                              ; preds = %151, %146, %136
  %161 = phi i64 [ 0, %146 ], [ 0, %151 ], [ 1, %136 ]
  %162 = getelementptr inbounds i64, ptr %24, i64 %14
  store i64 %161, ptr %162, align 8, !tbaa !9
  %163 = getelementptr inbounds i64, ptr %3, i64 %17
  %164 = sub nsw i64 %14, %17
  br label %165

165:                                              ; preds = %165, %160
  %166 = phi i64 [ %164, %160 ], [ %167, %165 ]
  %167 = add nsw i64 %166, -1
  %168 = getelementptr inbounds i64, ptr %163, i64 %167
  %169 = load i64, ptr %168, align 8, !tbaa !9
  %170 = icmp ne i64 %169, 0
  %171 = icmp eq i64 %167, 0
  %172 = or i1 %170, %171
  br i1 %172, label %173, label %165, !llvm.loop !151

173:                                              ; preds = %165
  br i1 %170, label %196, label %174

174:                                              ; preds = %177, %173
  %175 = phi i64 [ %178, %177 ], [ %17, %173 ]
  %176 = icmp sgt i64 %175, 0
  br i1 %176, label %177, label %196

177:                                              ; preds = %174
  %178 = add nsw i64 %175, -1
  %179 = getelementptr inbounds i64, ptr %3, i64 %178
  %180 = load i64, ptr %179, align 8, !tbaa !9
  %181 = getelementptr inbounds i64, ptr %110, i64 %178
  %182 = load i64, ptr %181, align 8, !tbaa !9
  %183 = icmp eq i64 %180, %182
  br i1 %183, label %174, label %184, !llvm.loop !149

184:                                              ; preds = %177
  %185 = icmp ugt i64 %180, %182
  br i1 %185, label %196, label %186

186:                                              ; preds = %184
  %187 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %110, ptr noundef %3, i64 noundef %17) #15
  %188 = icmp eq i64 %164, 0
  br i1 %188, label %194, label %189

189:                                              ; preds = %186
  %190 = getelementptr i64, ptr %25, i64 %17
  %191 = shl i64 %14, 4
  %192 = shl i64 %4, 3
  %193 = sub i64 %191, %192
  call void @llvm.memset.p0.i64(ptr align 8 %190, i8 0, i64 %193, i1 false), !tbaa !9
  br label %194

194:                                              ; preds = %189, %186
  %195 = xor i32 %28, 1
  br label %224

196:                                              ; preds = %184, %174, %173
  br i1 %132, label %210, label %197

197:                                              ; preds = %196
  %198 = call i64 @__gmpn_sub_n(ptr noundef %25, ptr noundef %3, ptr noundef %110, i64 noundef %17) #15
  %199 = icmp eq i64 %198, 0
  br i1 %199, label %210, label %200

200:                                              ; preds = %203, %197
  %201 = phi i64 [ %207, %203 ], [ %17, %197 ]
  %202 = icmp slt i64 %201, %14
  br i1 %202, label %203, label %224

203:                                              ; preds = %200
  %204 = getelementptr inbounds i64, ptr %3, i64 %201
  %205 = load i64, ptr %204, align 8, !tbaa !9
  %206 = add i64 %205, -1
  %207 = add nsw i64 %201, 1
  %208 = getelementptr inbounds i64, ptr %25, i64 %201
  store i64 %206, ptr %208, align 8, !tbaa !9
  %209 = icmp eq i64 %205, 0
  br i1 %209, label %200, label %210, !llvm.loop !152

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
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %220, ptr align 8 %221, i64 %223, i1 false), !tbaa !9
  br label %224

224:                                              ; preds = %215, %210, %200, %194, %129, %126
  %225 = phi i32 [ %128, %126 ], [ %28, %129 ], [ %195, %194 ], [ %28, %210 ], [ %28, %215 ], [ %28, %200 ]
  %226 = getelementptr inbounds i64, ptr %3, i64 %14
  %227 = icmp eq i64 %17, 0
  br i1 %227, label %241, label %228

228:                                              ; preds = %224
  %229 = call i64 @__gmpn_add_n(ptr noundef %26, ptr noundef %24, ptr noundef %226, i64 noundef %17) #15
  %230 = icmp eq i64 %229, 0
  br i1 %230, label %241, label %231

231:                                              ; preds = %234, %228
  %232 = phi i64 [ %238, %234 ], [ %17, %228 ]
  %233 = icmp sgt i64 %232, %14
  br i1 %233, label %253, label %234

234:                                              ; preds = %231
  %235 = getelementptr inbounds i64, ptr %24, i64 %232
  %236 = load i64, ptr %235, align 8, !tbaa !9
  %237 = add i64 %236, 1
  %238 = add nsw i64 %232, 1
  %239 = getelementptr inbounds i64, ptr %26, i64 %232
  store i64 %237, ptr %239, align 8, !tbaa !9
  %240 = icmp eq i64 %237, 0
  br i1 %240, label %231, label %241, !llvm.loop !150

241:                                              ; preds = %234, %228, %224
  %242 = phi i64 [ %17, %228 ], [ 0, %224 ], [ %238, %234 ]
  %243 = icmp ne ptr %26, %24
  %244 = icmp sle i64 %242, %14
  %245 = select i1 %243, i1 %244, i1 false
  br i1 %245, label %246, label %253

246:                                              ; preds = %246, %241
  %247 = phi i64 [ %251, %246 ], [ %242, %241 ]
  %248 = getelementptr inbounds i64, ptr %24, i64 %247
  %249 = load i64, ptr %248, align 8, !tbaa !9
  %250 = getelementptr inbounds i64, ptr %26, i64 %247
  store i64 %249, ptr %250, align 8, !tbaa !9
  %251 = add nsw i64 %247, 1
  %252 = icmp eq i64 %247, %14
  br i1 %252, label %253, label %246, !llvm.loop !153

253:                                              ; preds = %246, %241, %231
  call void @__gmpn_mul_n(ptr noundef %5, ptr noundef %22, ptr noundef %25, i64 noundef %14) #15
  %254 = getelementptr inbounds i64, ptr %22, i64 %14
  %255 = load i64, ptr %254, align 8, !tbaa !9
  %256 = icmp eq i64 %255, 0
  br i1 %256, label %260, label %257

257:                                              ; preds = %253
  %258 = getelementptr inbounds i64, ptr %5, i64 %14
  %259 = call i64 @__gmpn_add_n(ptr noundef %258, ptr noundef %258, ptr noundef %25, i64 noundef %14) #15
  br label %260

260:                                              ; preds = %257, %253
  %261 = phi i64 [ %259, %257 ], [ 0, %253 ]
  %262 = getelementptr inbounds i64, ptr %5, i64 %31
  store i64 %261, ptr %262, align 8, !tbaa !9
  %263 = getelementptr inbounds i8, ptr %262, i64 8
  call void @__gmpn_mul_n(ptr noundef nonnull %263, ptr noundef %23, ptr noundef %26, i64 noundef %21) #15
  %264 = icmp sgt i64 %16, %17
  %265 = shl nsw i64 %14, 5
  %266 = getelementptr inbounds i8, ptr %0, i64 %265
  br i1 %264, label %267, label %269

267:                                              ; preds = %260
  %268 = call i64 @__gmpn_mul(ptr noundef %266, ptr noundef %29, i64 noundef %16, ptr noundef %226, i64 noundef %17) #15
  br label %271

269:                                              ; preds = %260
  %270 = call i64 @__gmpn_mul(ptr noundef %266, ptr noundef %226, i64 noundef %17, ptr noundef %29, i64 noundef %16) #15
  br label %271

271:                                              ; preds = %269, %267
  %272 = shl nsw i64 %14, 5
  %273 = getelementptr inbounds i8, ptr %0, i64 %272
  %274 = load i64, ptr %273, align 8, !tbaa !9
  %275 = getelementptr inbounds i64, ptr %0, i64 %31
  call void @__gmpn_mul_n(ptr noundef %275, ptr noundef %20, ptr noundef %24, i64 noundef %14) #15
  %276 = getelementptr inbounds i64, ptr %20, i64 %14
  %277 = load i64, ptr %276, align 8, !tbaa !9
  switch i64 %277, label %287 [
    i64 1, label %278
    i64 2, label %281
    i64 3, label %284
  ]

278:                                              ; preds = %271
  %279 = getelementptr inbounds i64, ptr %275, i64 %14
  %280 = call i64 @__gmpn_add_n(ptr noundef %279, ptr noundef %279, ptr noundef %24, i64 noundef %14) #15
  br label %287

281:                                              ; preds = %271
  %282 = getelementptr inbounds i64, ptr %275, i64 %14
  %283 = call i64 @__gmpn_addmul_1(ptr noundef %282, ptr noundef %24, i64 noundef %14, i64 noundef 2) #15
  br label %287

284:                                              ; preds = %271
  %285 = getelementptr inbounds i64, ptr %275, i64 %14
  %286 = call i64 @__gmpn_addmul_1(ptr noundef %285, ptr noundef %24, i64 noundef %14, i64 noundef 3) #15
  br label %287

287:                                              ; preds = %284, %281, %278, %271
  %288 = phi i64 [ %280, %278 ], [ %283, %281 ], [ %286, %284 ], [ 0, %271 ]
  %289 = getelementptr inbounds i64, ptr %24, i64 %14
  %290 = load i64, ptr %289, align 8, !tbaa !9
  %291 = icmp eq i64 %290, 0
  br i1 %291, label %298, label %292

292:                                              ; preds = %287
  %293 = load i64, ptr %276, align 8, !tbaa !9
  %294 = getelementptr inbounds i64, ptr %275, i64 %14
  %295 = call i64 @__gmpn_add_n(ptr noundef %294, ptr noundef %294, ptr noundef %20, i64 noundef %14) #15
  %296 = add i64 %293, %288
  %297 = add i64 %296, %295
  br label %298

298:                                              ; preds = %292, %287
  %299 = phi i64 [ %297, %292 ], [ %288, %287 ]
  %300 = getelementptr inbounds i64, ptr %275, i64 %31
  store i64 %299, ptr %300, align 8, !tbaa !9
  call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %14) #15
  %301 = add nsw i64 %16, %17
  call void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef nonnull %263, ptr noundef %5, i64 noundef %14, i64 noundef %301, i32 noundef %225, i64 noundef %274) #15
  %302 = load ptr, ptr %7, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %302) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #3 {
  %4 = alloca [100 x i64], align 16
  %5 = icmp eq i64 %2, 1
  br i1 %5, label %6, label %25

6:                                                ; preds = %3
  %7 = load i64, ptr %1, align 8, !tbaa !9
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
  store i64 %20, ptr %21, align 8, !tbaa !9
  %22 = shl i64 %15, 32
  %23 = and i64 %10, 4294967295
  %24 = or disjoint i64 %22, %23
  store i64 %24, ptr %0, align 8, !tbaa !9
  br label %86

25:                                               ; preds = %3
  call void @llvm.lifetime.start.p0(i64 800, ptr nonnull %4) #15
  %26 = getelementptr inbounds i8, ptr %1, i64 8
  %27 = add nsw i64 %2, -1
  %28 = load i64, ptr %1, align 8, !tbaa !9
  %29 = call i64 @__gmpn_mul_1(ptr noundef nonnull %4, ptr noundef nonnull %26, i64 noundef %27, i64 noundef %28) #15
  %30 = getelementptr inbounds i64, ptr %4, i64 %27
  store i64 %29, ptr %30, align 8, !tbaa !9
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
  %44 = load i64, ptr %43, align 8, !tbaa !9
  %45 = call i64 @__gmpn_addmul_1(ptr noundef nonnull %40, ptr noundef nonnull %41, i64 noundef %42, i64 noundef %44) #15
  %46 = getelementptr i64, ptr %33, i64 %38
  store i64 %45, ptr %46, align 8, !tbaa !9
  %47 = add nuw nsw i64 %38, 1
  %48 = icmp eq i64 %47, %2
  br i1 %48, label %35, label %37, !llvm.loop !154

49:                                               ; preds = %49, %35
  %50 = phi i64 [ %73, %49 ], [ 0, %35 ]
  %51 = getelementptr inbounds i64, ptr %1, i64 %50
  %52 = load i64, ptr %51, align 8, !tbaa !9
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
  store i64 %65, ptr %68, align 8, !tbaa !9
  %69 = shl i64 %60, 32
  %70 = and i64 %55, 4294967295
  %71 = or disjoint i64 %69, %70
  %72 = getelementptr inbounds i64, ptr %0, i64 %66
  store i64 %71, ptr %72, align 8, !tbaa !9
  %73 = add nuw nsw i64 %50, 1
  %74 = icmp eq i64 %73, %2
  br i1 %74, label %75, label %49, !llvm.loop !155

75:                                               ; preds = %49, %35
  %76 = shl nsw i64 %2, 1
  %77 = add nsw i64 %76, -2
  %78 = call i64 @__gmpn_lshift(ptr noundef nonnull %4, ptr noundef nonnull %4, i64 noundef %77, i32 noundef 1) #15
  %79 = getelementptr inbounds i8, ptr %0, i64 8
  %80 = call i64 @__gmpn_add_n(ptr noundef nonnull %79, ptr noundef nonnull %79, ptr noundef nonnull %4, i64 noundef %77) #15
  %81 = add i64 %80, %78
  %82 = getelementptr i64, ptr %0, i64 %76
  %83 = getelementptr i8, ptr %82, i64 -8
  %84 = load i64, ptr %83, align 8, !tbaa !9
  %85 = add i64 %81, %84
  store i64 %85, ptr %83, align 8, !tbaa !9
  call void @llvm.lifetime.end.p0(i64 800, ptr nonnull %4) #15
  br label %86

86:                                               ; preds = %75, %6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_16pts(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, i64 noundef %5, i64 noundef %6, i32 noundef %7, ptr noundef %8) local_unnamed_addr #3 {
  %10 = mul nsw i64 %5, 3
  %11 = add nsw i64 %10, 1
  %12 = icmp eq i32 %7, 0
  br i1 %12, label %163, label %13

13:                                               ; preds = %9
  %14 = mul i64 %5, 56
  %15 = getelementptr inbounds i8, ptr %0, i64 %14
  %16 = mul i64 %5, 120
  %17 = getelementptr inbounds i8, ptr %0, i64 %16
  %18 = tail call i64 @__gmpn_sub_n(ptr noundef %15, ptr noundef %15, ptr noundef %17, i64 noundef %6) #15
  %19 = getelementptr inbounds i64, ptr %15, i64 %6
  %20 = load i64, ptr %19, align 8, !tbaa !9
  %21 = sub i64 %20, %18
  store i64 %21, ptr %19, align 8, !tbaa !9
  %22 = icmp ult i64 %20, %18
  br i1 %22, label %23, label %29

23:                                               ; preds = %23, %13
  %24 = phi ptr [ %25, %23 ], [ %19, %13 ]
  %25 = getelementptr inbounds i8, ptr %24, i64 8
  %26 = load i64, ptr %25, align 8, !tbaa !9
  %27 = add i64 %26, -1
  store i64 %27, ptr %25, align 8, !tbaa !9
  %28 = icmp eq i64 %26, 0
  br i1 %28, label %23, label %29, !llvm.loop !156

29:                                               ; preds = %23, %13
  %30 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %17, i64 noundef %6, i32 noundef 14) #15
  %31 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %8, i64 noundef %6) #15
  %32 = getelementptr inbounds i64, ptr %2, i64 %6
  %33 = add i64 %31, %30
  %34 = load i64, ptr %32, align 8, !tbaa !9
  %35 = sub i64 %34, %33
  store i64 %35, ptr %32, align 8, !tbaa !9
  %36 = icmp ult i64 %34, %33
  br i1 %36, label %37, label %43

37:                                               ; preds = %37, %29
  %38 = phi ptr [ %39, %37 ], [ %32, %29 ]
  %39 = getelementptr inbounds i8, ptr %38, i64 8
  %40 = load i64, ptr %39, align 8, !tbaa !9
  %41 = add i64 %40, -1
  store i64 %41, ptr %39, align 8, !tbaa !9
  %42 = icmp eq i64 %40, 0
  br i1 %42, label %37, label %43, !llvm.loop !157

43:                                               ; preds = %37, %29
  %44 = getelementptr inbounds i64, ptr %0, i64 %10
  %45 = load i64, ptr %17, align 8, !tbaa !9
  %46 = lshr i64 %45, 2
  %47 = load i64, ptr %44, align 8, !tbaa !9
  %48 = sub i64 %47, %46
  store i64 %48, ptr %44, align 8, !tbaa !9
  %49 = load i64, ptr %17, align 8, !tbaa !9
  %50 = lshr i64 %49, 2
  %51 = icmp ult i64 %47, %50
  br i1 %51, label %52, label %58

52:                                               ; preds = %52, %43
  %53 = phi ptr [ %54, %52 ], [ %44, %43 ]
  %54 = getelementptr inbounds i8, ptr %53, i64 8
  %55 = load i64, ptr %54, align 8, !tbaa !9
  %56 = add i64 %55, -1
  store i64 %56, ptr %54, align 8, !tbaa !9
  %57 = icmp eq i64 %55, 0
  br i1 %57, label %52, label %58, !llvm.loop !158

58:                                               ; preds = %52, %43
  %59 = getelementptr inbounds i8, ptr %17, i64 8
  %60 = add nsw i64 %6, -1
  %61 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %59, i64 noundef %60, i32 noundef 62) #15
  %62 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %44, ptr noundef nonnull %44, ptr noundef %8, i64 noundef %60) #15
  %63 = getelementptr inbounds i64, ptr %44, i64 %6
  %64 = getelementptr inbounds i8, ptr %63, i64 -8
  %65 = add i64 %62, %61
  %66 = load i64, ptr %64, align 8, !tbaa !9
  %67 = sub i64 %66, %65
  store i64 %67, ptr %64, align 8, !tbaa !9
  %68 = icmp ult i64 %66, %65
  br i1 %68, label %69, label %75

69:                                               ; preds = %69, %58
  %70 = phi ptr [ %71, %69 ], [ %64, %58 ]
  %71 = getelementptr inbounds i8, ptr %70, i64 8
  %72 = load i64, ptr %71, align 8, !tbaa !9
  %73 = add i64 %72, -1
  store i64 %73, ptr %71, align 8, !tbaa !9
  %74 = icmp eq i64 %72, 0
  br i1 %74, label %69, label %75, !llvm.loop !159

75:                                               ; preds = %69, %58
  %76 = mul i64 %5, 88
  %77 = getelementptr inbounds i8, ptr %0, i64 %76
  %78 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %17, i64 noundef %6, i32 noundef 28) #15
  %79 = tail call i64 @__gmpn_sub_n(ptr noundef %77, ptr noundef %77, ptr noundef %8, i64 noundef %6) #15
  %80 = getelementptr inbounds i64, ptr %77, i64 %6
  %81 = add i64 %79, %78
  %82 = load i64, ptr %80, align 8, !tbaa !9
  %83 = sub i64 %82, %81
  store i64 %83, ptr %80, align 8, !tbaa !9
  %84 = icmp ult i64 %82, %81
  br i1 %84, label %85, label %91

85:                                               ; preds = %85, %75
  %86 = phi ptr [ %87, %85 ], [ %80, %75 ]
  %87 = getelementptr inbounds i8, ptr %86, i64 8
  %88 = load i64, ptr %87, align 8, !tbaa !9
  %89 = add i64 %88, -1
  store i64 %89, ptr %87, align 8, !tbaa !9
  %90 = icmp eq i64 %88, 0
  br i1 %90, label %85, label %91, !llvm.loop !160

91:                                               ; preds = %85, %75
  %92 = load i64, ptr %17, align 8, !tbaa !9
  %93 = lshr i64 %92, 4
  %94 = load i64, ptr %3, align 8, !tbaa !9
  %95 = sub i64 %94, %93
  store i64 %95, ptr %3, align 8, !tbaa !9
  %96 = load i64, ptr %17, align 8, !tbaa !9
  %97 = lshr i64 %96, 4
  %98 = icmp ult i64 %94, %97
  br i1 %98, label %99, label %105

99:                                               ; preds = %99, %91
  %100 = phi ptr [ %101, %99 ], [ %3, %91 ]
  %101 = getelementptr inbounds i8, ptr %100, i64 8
  %102 = load i64, ptr %101, align 8, !tbaa !9
  %103 = add i64 %102, -1
  store i64 %103, ptr %101, align 8, !tbaa !9
  %104 = icmp eq i64 %102, 0
  br i1 %104, label %99, label %105, !llvm.loop !161

105:                                              ; preds = %99, %91
  %106 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %59, i64 noundef %60, i32 noundef 60) #15
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %3, ptr noundef nonnull %3, ptr noundef %8, i64 noundef %60) #15
  %108 = getelementptr inbounds i64, ptr %3, i64 %6
  %109 = getelementptr inbounds i8, ptr %108, i64 -8
  %110 = add i64 %107, %106
  %111 = load i64, ptr %109, align 8, !tbaa !9
  %112 = sub i64 %111, %110
  store i64 %112, ptr %109, align 8, !tbaa !9
  %113 = icmp ult i64 %111, %110
  br i1 %113, label %114, label %120

114:                                              ; preds = %114, %105
  %115 = phi ptr [ %116, %114 ], [ %109, %105 ]
  %116 = getelementptr inbounds i8, ptr %115, i64 8
  %117 = load i64, ptr %116, align 8, !tbaa !9
  %118 = add i64 %117, -1
  store i64 %118, ptr %116, align 8, !tbaa !9
  %119 = icmp eq i64 %117, 0
  br i1 %119, label %114, label %120, !llvm.loop !162

120:                                              ; preds = %114, %105
  %121 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %17, i64 noundef %6, i32 noundef 42) #15
  %122 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %8, i64 noundef %6) #15
  %123 = getelementptr inbounds i64, ptr %1, i64 %6
  %124 = add i64 %122, %121
  %125 = load i64, ptr %123, align 8, !tbaa !9
  %126 = sub i64 %125, %124
  store i64 %126, ptr %123, align 8, !tbaa !9
  %127 = icmp ult i64 %125, %124
  br i1 %127, label %128, label %134

128:                                              ; preds = %128, %120
  %129 = phi ptr [ %130, %128 ], [ %123, %120 ]
  %130 = getelementptr inbounds i8, ptr %129, i64 8
  %131 = load i64, ptr %130, align 8, !tbaa !9
  %132 = add i64 %131, -1
  store i64 %132, ptr %130, align 8, !tbaa !9
  %133 = icmp eq i64 %131, 0
  br i1 %133, label %128, label %134, !llvm.loop !163

134:                                              ; preds = %128, %120
  %135 = load i64, ptr %17, align 8, !tbaa !9
  %136 = lshr i64 %135, 6
  %137 = load i64, ptr %4, align 8, !tbaa !9
  %138 = sub i64 %137, %136
  store i64 %138, ptr %4, align 8, !tbaa !9
  %139 = load i64, ptr %17, align 8, !tbaa !9
  %140 = lshr i64 %139, 6
  %141 = icmp ult i64 %137, %140
  br i1 %141, label %142, label %148

142:                                              ; preds = %142, %134
  %143 = phi ptr [ %144, %142 ], [ %4, %134 ]
  %144 = getelementptr inbounds i8, ptr %143, i64 8
  %145 = load i64, ptr %144, align 8, !tbaa !9
  %146 = add i64 %145, -1
  store i64 %146, ptr %144, align 8, !tbaa !9
  %147 = icmp eq i64 %145, 0
  br i1 %147, label %142, label %148, !llvm.loop !164

148:                                              ; preds = %142, %134
  %149 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %59, i64 noundef %60, i32 noundef 58) #15
  %150 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %4, ptr noundef nonnull %4, ptr noundef %8, i64 noundef %60) #15
  %151 = getelementptr inbounds i64, ptr %4, i64 %6
  %152 = getelementptr inbounds i8, ptr %151, i64 -8
  %153 = add i64 %150, %149
  %154 = load i64, ptr %152, align 8, !tbaa !9
  %155 = sub i64 %154, %153
  store i64 %155, ptr %152, align 8, !tbaa !9
  %156 = icmp ult i64 %154, %153
  br i1 %156, label %157, label %163

157:                                              ; preds = %157, %148
  %158 = phi ptr [ %159, %157 ], [ %152, %148 ]
  %159 = getelementptr inbounds i8, ptr %158, i64 8
  %160 = load i64, ptr %159, align 8, !tbaa !9
  %161 = add i64 %160, -1
  store i64 %161, ptr %159, align 8, !tbaa !9
  %162 = icmp eq i64 %160, 0
  br i1 %162, label %157, label %163, !llvm.loop !165

163:                                              ; preds = %157, %148, %9
  %164 = getelementptr inbounds i64, ptr %3, i64 %5
  %165 = shl nsw i64 %5, 1
  %166 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef %0, i64 noundef %165, i32 noundef 28) #15
  %167 = tail call i64 @__gmpn_sub_n(ptr noundef %164, ptr noundef %164, ptr noundef %8, i64 noundef %165) #15
  %168 = getelementptr inbounds i64, ptr %3, i64 %10
  %169 = load i64, ptr %168, align 8, !tbaa !9
  %170 = add i64 %167, %166
  %171 = sub i64 %169, %170
  store i64 %171, ptr %168, align 8, !tbaa !9
  %172 = mul i64 %5, 88
  %173 = getelementptr inbounds i8, ptr %0, i64 %172
  %174 = getelementptr inbounds i64, ptr %173, i64 %5
  %175 = load i64, ptr %0, align 8, !tbaa !9
  %176 = lshr i64 %175, 4
  %177 = load i64, ptr %174, align 8, !tbaa !9
  %178 = sub i64 %177, %176
  store i64 %178, ptr %174, align 8, !tbaa !9
  %179 = load i64, ptr %0, align 8, !tbaa !9
  %180 = lshr i64 %179, 4
  %181 = icmp ult i64 %177, %180
  br i1 %181, label %182, label %188

182:                                              ; preds = %182, %163
  %183 = phi ptr [ %184, %182 ], [ %174, %163 ]
  %184 = getelementptr inbounds i8, ptr %183, i64 8
  %185 = load i64, ptr %184, align 8, !tbaa !9
  %186 = add i64 %185, -1
  store i64 %186, ptr %184, align 8, !tbaa !9
  %187 = icmp eq i64 %185, 0
  br i1 %187, label %182, label %188, !llvm.loop !166

188:                                              ; preds = %182, %163
  %189 = getelementptr inbounds i8, ptr %0, i64 8
  %190 = add nsw i64 %165, -1
  %191 = tail call i64 @__gmpn_lshift(ptr noundef %8, ptr noundef nonnull %189, i64 noundef %190, i32 noundef 60) #15
  %192 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %174, ptr noundef nonnull %174, ptr noundef %8, i64 noundef %190) #15
  %193 = getelementptr inbounds i64, ptr %174, i64 %165
  %194 = getelementptr inbounds i8, ptr %193, i64 -8
  %195 = add i64 %192, %191
  %196 = load i64, ptr %194, align 8, !tbaa !9
  %197 = sub i64 %196, %195
  store i64 %197, ptr %194, align 8, !tbaa !9
  %198 = icmp ult i64 %196, %195
  br i1 %198, label %199, label %205

199:                                              ; preds = %199, %188
  %200 = phi ptr [ %201, %199 ], [ %194, %188 ]
  %201 = getelementptr inbounds i8, ptr %200, i64 8
  %202 = load i64, ptr %201, align 8, !tbaa !9
  %203 = add i64 %202, -1
  store i64 %203, ptr %201, align 8, !tbaa !9
  %204 = icmp eq i64 %202, 0
  br i1 %204, label %199, label %205, !llvm.loop !167

205:                                              ; preds = %199, %188
  %206 = tail call i64 @__gmpn_sub_n(ptr noundef %8, ptr noundef %3, ptr noundef nonnull %173, i64 noundef %11) #15
  %207 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef %3, i64 noundef %11) #15
  %208 = getelementptr inbounds i64, ptr %0, i64 %10
  %209 = getelementptr inbounds i64, ptr %208, i64 %5
  %210 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %0, i64 noundef %165, i32 noundef 14) #15
  %211 = tail call i64 @__gmpn_sub_n(ptr noundef %209, ptr noundef %209, ptr noundef %3, i64 noundef %165) #15
  %212 = getelementptr inbounds i64, ptr %208, i64 %10
  %213 = load i64, ptr %212, align 8, !tbaa !9
  %214 = add i64 %211, %210
  %215 = sub i64 %213, %214
  store i64 %215, ptr %212, align 8, !tbaa !9
  %216 = getelementptr inbounds i64, ptr %2, i64 %5
  %217 = load i64, ptr %0, align 8, !tbaa !9
  %218 = lshr i64 %217, 2
  %219 = load i64, ptr %216, align 8, !tbaa !9
  %220 = sub i64 %219, %218
  store i64 %220, ptr %216, align 8, !tbaa !9
  %221 = load i64, ptr %0, align 8, !tbaa !9
  %222 = lshr i64 %221, 2
  %223 = icmp ult i64 %219, %222
  br i1 %223, label %224, label %230

224:                                              ; preds = %224, %205
  %225 = phi ptr [ %226, %224 ], [ %216, %205 ]
  %226 = getelementptr inbounds i8, ptr %225, i64 8
  %227 = load i64, ptr %226, align 8, !tbaa !9
  %228 = add i64 %227, -1
  store i64 %228, ptr %226, align 8, !tbaa !9
  %229 = icmp eq i64 %227, 0
  br i1 %229, label %224, label %230, !llvm.loop !168

230:                                              ; preds = %224, %205
  %231 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef nonnull %189, i64 noundef %190, i32 noundef 62) #15
  %232 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %216, ptr noundef nonnull %216, ptr noundef %3, i64 noundef %190) #15
  %233 = getelementptr inbounds i64, ptr %216, i64 %165
  %234 = getelementptr inbounds i8, ptr %233, i64 -8
  %235 = add i64 %232, %231
  %236 = load i64, ptr %234, align 8, !tbaa !9
  %237 = sub i64 %236, %235
  store i64 %237, ptr %234, align 8, !tbaa !9
  %238 = icmp ult i64 %236, %235
  br i1 %238, label %239, label %245

239:                                              ; preds = %239, %230
  %240 = phi ptr [ %241, %239 ], [ %234, %230 ]
  %241 = getelementptr inbounds i8, ptr %240, i64 8
  %242 = load i64, ptr %241, align 8, !tbaa !9
  %243 = add i64 %242, -1
  store i64 %243, ptr %241, align 8, !tbaa !9
  %244 = icmp eq i64 %242, 0
  br i1 %244, label %239, label %245, !llvm.loop !169

245:                                              ; preds = %239, %230
  %246 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %2, ptr noundef nonnull %208, i64 noundef %11) #15
  %247 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %208, ptr noundef nonnull %208, ptr noundef %2, i64 noundef %11) #15
  %248 = getelementptr inbounds i64, ptr %4, i64 %5
  %249 = tail call i64 @__gmpn_lshift(ptr noundef %2, ptr noundef %0, i64 noundef %165, i32 noundef 42) #15
  %250 = tail call i64 @__gmpn_sub_n(ptr noundef %248, ptr noundef %248, ptr noundef %2, i64 noundef %165) #15
  %251 = getelementptr inbounds i64, ptr %4, i64 %10
  %252 = load i64, ptr %251, align 8, !tbaa !9
  %253 = add i64 %250, %249
  %254 = sub i64 %252, %253
  store i64 %254, ptr %251, align 8, !tbaa !9
  %255 = getelementptr inbounds i64, ptr %1, i64 %5
  %256 = load i64, ptr %0, align 8, !tbaa !9
  %257 = lshr i64 %256, 6
  %258 = load i64, ptr %255, align 8, !tbaa !9
  %259 = sub i64 %258, %257
  store i64 %259, ptr %255, align 8, !tbaa !9
  %260 = load i64, ptr %0, align 8, !tbaa !9
  %261 = lshr i64 %260, 6
  %262 = icmp ult i64 %258, %261
  br i1 %262, label %263, label %269

263:                                              ; preds = %263, %245
  %264 = phi ptr [ %265, %263 ], [ %255, %245 ]
  %265 = getelementptr inbounds i8, ptr %264, i64 8
  %266 = load i64, ptr %265, align 8, !tbaa !9
  %267 = add i64 %266, -1
  store i64 %267, ptr %265, align 8, !tbaa !9
  %268 = icmp eq i64 %266, 0
  br i1 %268, label %263, label %269, !llvm.loop !170

269:                                              ; preds = %263, %245
  %270 = tail call i64 @__gmpn_lshift(ptr noundef %2, ptr noundef nonnull %189, i64 noundef %190, i32 noundef 58) #15
  %271 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %255, ptr noundef nonnull %255, ptr noundef %2, i64 noundef %190) #15
  %272 = getelementptr inbounds i64, ptr %255, i64 %165
  %273 = getelementptr inbounds i8, ptr %272, i64 -8
  %274 = add i64 %271, %270
  %275 = load i64, ptr %273, align 8, !tbaa !9
  %276 = sub i64 %275, %274
  store i64 %276, ptr %273, align 8, !tbaa !9
  %277 = icmp ult i64 %275, %274
  br i1 %277, label %278, label %284

278:                                              ; preds = %278, %269
  %279 = phi ptr [ %280, %278 ], [ %273, %269 ]
  %280 = getelementptr inbounds i8, ptr %279, i64 8
  %281 = load i64, ptr %280, align 8, !tbaa !9
  %282 = add i64 %281, -1
  store i64 %282, ptr %280, align 8, !tbaa !9
  %283 = icmp eq i64 %281, 0
  br i1 %283, label %278, label %284, !llvm.loop !171

284:                                              ; preds = %278, %269
  %285 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %4, ptr noundef %1, i64 noundef %11) #15
  %286 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %4, i64 noundef %11) #15
  %287 = mul i64 %5, 56
  %288 = getelementptr inbounds i8, ptr %0, i64 %287
  %289 = getelementptr inbounds i64, ptr %288, i64 %5
  %290 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %289, ptr noundef nonnull %289, ptr noundef nonnull %0, i64 noundef %165) #15
  %291 = getelementptr inbounds i64, ptr %288, i64 %10
  %292 = load i64, ptr %291, align 8, !tbaa !9
  %293 = sub i64 %292, %290
  store i64 %293, ptr %291, align 8, !tbaa !9
  %294 = tail call i64 @__gmpn_submul_1(ptr noundef %8, ptr noundef nonnull %208, i64 noundef %11, i64 noundef 1028) #15
  %295 = tail call i64 @__gmpn_submul_1(ptr noundef %2, ptr noundef %8, i64 noundef %11, i64 noundef 1300) #15
  %296 = tail call i64 @__gmpn_submul_1(ptr noundef %2, ptr noundef nonnull %208, i64 noundef %11, i64 noundef 1052688) #15
  tail call void @__gmpn_divexact_1(ptr noundef %2, ptr noundef %2, i64 noundef %11, i64 noundef 48070897875) #15
  %297 = tail call i64 @__gmpn_submul_1(ptr noundef %8, ptr noundef %2, i64 noundef %11, i64 noundef 12567555) #15
  tail call void @__gmpn_divexact_1(ptr noundef %8, ptr noundef %8, i64 noundef %11, i64 noundef 181440) #15
  %298 = getelementptr inbounds i64, ptr %8, i64 %10
  %299 = load i64, ptr %298, align 8, !tbaa !9
  %300 = icmp ult i64 %299, 144115188075855872
  br i1 %300, label %303, label %301

301:                                              ; preds = %284
  %302 = or i64 %299, -288230376151711744
  store i64 %302, ptr %298, align 8, !tbaa !9
  br label %303

303:                                              ; preds = %301, %284
  %304 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %208, ptr noundef %2, i64 noundef %11, i64 noundef 4095) #15
  %305 = tail call i64 @__gmpn_addmul_1(ptr noundef nonnull %208, ptr noundef %8, i64 noundef %11, i64 noundef 240) #15
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %208, ptr noundef nonnull %208, i64 noundef %11, i64 noundef 1020) #15
  %306 = load i64, ptr %212, align 8, !tbaa !9
  %307 = icmp ult i64 %306, 2305843009213693952
  br i1 %307, label %310, label %308

308:                                              ; preds = %303
  %309 = or i64 %306, -4611686018427387904
  store i64 %309, ptr %212, align 8, !tbaa !9
  br label %310

310:                                              ; preds = %308, %303
  %311 = tail call i64 @__gmpn_lshift(ptr noundef %4, ptr noundef %288, i64 noundef %11, i32 noundef 7) #15
  %312 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %4, i64 noundef %11) #15
  %313 = tail call i64 @__gmpn_lshift(ptr noundef %4, ptr noundef %288, i64 noundef %11, i32 noundef 13) #15
  %314 = tail call i64 @__gmpn_sub_n(ptr noundef %173, ptr noundef %173, ptr noundef %4, i64 noundef %11) #15
  %315 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %173, ptr noundef %3, i64 noundef %11, i64 noundef 400) #15
  %316 = tail call i64 @__gmpn_lshift(ptr noundef %4, ptr noundef %288, i64 noundef %11, i32 noundef 19) #15
  %317 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %4, i64 noundef %11) #15
  %318 = tail call i64 @__gmpn_submul_1(ptr noundef %1, ptr noundef nonnull %173, i64 noundef %11, i64 noundef 1428) #15
  %319 = tail call i64 @__gmpn_submul_1(ptr noundef %1, ptr noundef %3, i64 noundef %11, i64 noundef 112896) #15
  tail call void @__gmpn_divexact_1(ptr noundef %1, ptr noundef %1, i64 noundef %11, i64 noundef 46591793325) #15
  %320 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %173, ptr noundef %1, i64 noundef %11, i64 noundef 15181425) #15
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %173, ptr noundef nonnull %173, i64 noundef %11, i64 noundef 680400) #15
  %321 = tail call i64 @__gmpn_submul_1(ptr noundef %3, ptr noundef %1, i64 noundef %11, i64 noundef 3969) #15
  %322 = tail call i64 @__gmpn_submul_1(ptr noundef %3, ptr noundef nonnull %173, i64 noundef %11, i64 noundef 900) #15
  tail call void @__gmpn_divexact_1(ptr noundef %3, ptr noundef %3, i64 noundef %11, i64 noundef 144) #15
  %323 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef %1, i64 noundef %11) #15
  %324 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef %3, i64 noundef %11) #15
  %325 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef nonnull %173, i64 noundef %11) #15
  %326 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %208, ptr noundef nonnull %173, ptr noundef nonnull %208, i64 noundef %11) #15
  %327 = tail call i64 @__gmpn_rshift(ptr noundef nonnull %208, ptr noundef nonnull %208, i64 noundef %11, i32 noundef 1) #15
  %328 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef nonnull %208, i64 noundef %11) #15
  %329 = tail call i64 @__gmpn_sub_n(ptr noundef %8, ptr noundef %3, ptr noundef %8, i64 noundef %11) #15
  %330 = tail call i64 @__gmpn_rshift(ptr noundef %8, ptr noundef %8, i64 noundef %11, i32 noundef 1) #15
  %331 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef %8, i64 noundef %11) #15
  %332 = tail call i64 @__gmpn_add_n(ptr noundef %2, ptr noundef %1, ptr noundef %2, i64 noundef %11) #15
  %333 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %11, i32 noundef 1) #15
  %334 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %11) #15
  %335 = getelementptr inbounds i64, ptr %0, i64 %5
  %336 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %335, ptr noundef nonnull %335, ptr noundef %2, i64 noundef %5) #15
  %337 = getelementptr inbounds i64, ptr %0, i64 %165
  %338 = load i64, ptr %216, align 8, !tbaa !9
  %339 = add i64 %338, %336
  store i64 %339, ptr %337, align 8, !tbaa !9
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
  %348 = load i64, ptr %347, align 8, !tbaa !9
  %349 = add i64 %348, 1
  %350 = getelementptr inbounds i64, ptr %337, i64 %344
  store i64 %349, ptr %350, align 8, !tbaa !9
  %351 = add nuw i64 %344, 1
  %352 = icmp eq i64 %349, 0
  br i1 %352, label %343, label %353, !llvm.loop !172

353:                                              ; preds = %346
  %354 = icmp ne ptr %216, %337
  %355 = icmp slt i64 %351, %5
  %356 = select i1 %354, i1 %355, i1 false
  br i1 %356, label %357, label %375

357:                                              ; preds = %357, %353
  %358 = phi i64 [ %362, %357 ], [ %351, %353 ]
  %359 = getelementptr inbounds i64, ptr %216, i64 %358
  %360 = load i64, ptr %359, align 8, !tbaa !9
  %361 = getelementptr inbounds i64, ptr %337, i64 %358
  store i64 %360, ptr %361, align 8, !tbaa !9
  %362 = add nuw nsw i64 %358, 1
  %363 = icmp slt i64 %362, %5
  br i1 %363, label %357, label %375, !llvm.loop !173

364:                                              ; preds = %310
  %365 = icmp ne ptr %216, %337
  %366 = icmp sgt i64 %5, 1
  %367 = and i1 %366, %365
  br i1 %367, label %368, label %375

368:                                              ; preds = %368, %364
  %369 = phi i64 [ %373, %368 ], [ 1, %364 ]
  %370 = getelementptr inbounds i64, ptr %216, i64 %369
  %371 = load i64, ptr %370, align 8, !tbaa !9
  %372 = getelementptr inbounds i64, ptr %337, i64 %369
  store i64 %371, ptr %372, align 8, !tbaa !9
  %373 = add nuw nsw i64 %369, 1
  %374 = icmp eq i64 %373, %5
  br i1 %374, label %375, label %368, !llvm.loop !174

375:                                              ; preds = %368, %364, %357, %353, %343
  %376 = phi i64 [ 0, %353 ], [ 0, %364 ], [ 0, %357 ], [ 1, %343 ], [ 0, %368 ]
  %377 = getelementptr inbounds i64, ptr %2, i64 %165
  %378 = load i64, ptr %377, align 8, !tbaa !9
  %379 = add i64 %378, %376
  store i64 %379, ptr %377, align 8, !tbaa !9
  %380 = icmp ult i64 %379, %376
  br i1 %380, label %381, label %387

381:                                              ; preds = %381, %375
  %382 = phi ptr [ %383, %381 ], [ %377, %375 ]
  %383 = getelementptr inbounds i8, ptr %382, i64 8
  %384 = load i64, ptr %383, align 8, !tbaa !9
  %385 = add i64 %384, 1
  store i64 %385, ptr %383, align 8, !tbaa !9
  %386 = icmp eq i64 %385, 0
  br i1 %386, label %381, label %387, !llvm.loop !175

387:                                              ; preds = %381, %375
  %388 = getelementptr inbounds i64, ptr %2, i64 %10
  %389 = load i64, ptr %388, align 8, !tbaa !9
  %390 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %208, ptr noundef nonnull %208, ptr noundef nonnull %377, i64 noundef %5) #15
  %391 = shl nsw i64 %5, 5
  %392 = getelementptr inbounds i8, ptr %0, i64 %391
  %393 = add i64 %390, %389
  %394 = load i64, ptr %392, align 8, !tbaa !9
  %395 = add i64 %394, %393
  store i64 %395, ptr %392, align 8, !tbaa !9
  %396 = icmp ult i64 %395, %393
  br i1 %396, label %397, label %403

397:                                              ; preds = %397, %387
  %398 = phi ptr [ %399, %397 ], [ %392, %387 ]
  %399 = getelementptr inbounds i8, ptr %398, i64 8
  %400 = load i64, ptr %399, align 8, !tbaa !9
  %401 = add i64 %400, 1
  store i64 %401, ptr %399, align 8, !tbaa !9
  %402 = icmp eq i64 %401, 0
  br i1 %402, label %397, label %403, !llvm.loop !176

403:                                              ; preds = %397, %387
  %404 = mul i64 %5, 40
  %405 = getelementptr inbounds i8, ptr %0, i64 %404
  %406 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %405, ptr noundef nonnull %405, ptr noundef %8, i64 noundef %5) #15
  %407 = mul i64 %5, 48
  %408 = getelementptr inbounds i8, ptr %0, i64 %407
  %409 = load i64, ptr %408, align 8, !tbaa !9
  %410 = add i64 %409, %406
  store i64 %410, ptr %408, align 8, !tbaa !9
  %411 = getelementptr inbounds i64, ptr %8, i64 %5
  %412 = load i64, ptr %411, align 8, !tbaa !9
  %413 = add i64 %412, %410
  store i64 %413, ptr %408, align 8, !tbaa !9
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
  %422 = load i64, ptr %421, align 8, !tbaa !9
  %423 = add i64 %422, 1
  %424 = getelementptr inbounds i64, ptr %408, i64 %418
  store i64 %423, ptr %424, align 8, !tbaa !9
  %425 = add nuw i64 %418, 1
  %426 = icmp eq i64 %423, 0
  br i1 %426, label %417, label %427, !llvm.loop !172

427:                                              ; preds = %420
  %428 = icmp ne ptr %411, %408
  %429 = icmp slt i64 %425, %5
  %430 = select i1 %428, i1 %429, i1 false
  br i1 %430, label %431, label %449

431:                                              ; preds = %431, %427
  %432 = phi i64 [ %436, %431 ], [ %425, %427 ]
  %433 = getelementptr inbounds i64, ptr %411, i64 %432
  %434 = load i64, ptr %433, align 8, !tbaa !9
  %435 = getelementptr inbounds i64, ptr %408, i64 %432
  store i64 %434, ptr %435, align 8, !tbaa !9
  %436 = add nuw nsw i64 %432, 1
  %437 = icmp slt i64 %436, %5
  br i1 %437, label %431, label %449, !llvm.loop !173

438:                                              ; preds = %403
  %439 = icmp ne ptr %411, %408
  %440 = icmp sgt i64 %5, 1
  %441 = and i1 %440, %439
  br i1 %441, label %442, label %449

442:                                              ; preds = %442, %438
  %443 = phi i64 [ %447, %442 ], [ 1, %438 ]
  %444 = getelementptr inbounds i64, ptr %411, i64 %443
  %445 = load i64, ptr %444, align 8, !tbaa !9
  %446 = getelementptr inbounds i64, ptr %408, i64 %443
  store i64 %445, ptr %446, align 8, !tbaa !9
  %447 = add nuw nsw i64 %443, 1
  %448 = icmp eq i64 %447, %5
  br i1 %448, label %449, label %442, !llvm.loop !174

449:                                              ; preds = %442, %438, %431, %427, %417
  %450 = phi i64 [ 0, %427 ], [ 0, %438 ], [ 0, %431 ], [ 1, %417 ], [ 0, %442 ]
  %451 = getelementptr inbounds i64, ptr %8, i64 %165
  %452 = load i64, ptr %451, align 8, !tbaa !9
  %453 = add i64 %452, %450
  store i64 %453, ptr %451, align 8, !tbaa !9
  %454 = icmp ult i64 %453, %450
  br i1 %454, label %455, label %461

455:                                              ; preds = %455, %449
  %456 = phi ptr [ %457, %455 ], [ %451, %449 ]
  %457 = getelementptr inbounds i8, ptr %456, i64 8
  %458 = load i64, ptr %457, align 8, !tbaa !9
  %459 = add i64 %458, 1
  store i64 %459, ptr %457, align 8, !tbaa !9
  %460 = icmp eq i64 %459, 0
  br i1 %460, label %455, label %461, !llvm.loop !177

461:                                              ; preds = %455, %449
  %462 = load i64, ptr %298, align 8, !tbaa !9
  %463 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %288, ptr noundef nonnull %288, ptr noundef nonnull %451, i64 noundef %5) #15
  %464 = shl nsw i64 %5, 6
  %465 = getelementptr inbounds i8, ptr %0, i64 %464
  %466 = add i64 %463, %462
  %467 = load i64, ptr %465, align 8, !tbaa !9
  %468 = add i64 %467, %466
  store i64 %468, ptr %465, align 8, !tbaa !9
  %469 = icmp ult i64 %468, %466
  br i1 %469, label %470, label %476

470:                                              ; preds = %470, %461
  %471 = phi ptr [ %472, %470 ], [ %465, %461 ]
  %472 = getelementptr inbounds i8, ptr %471, i64 8
  %473 = load i64, ptr %472, align 8, !tbaa !9
  %474 = add i64 %473, 1
  store i64 %474, ptr %472, align 8, !tbaa !9
  %475 = icmp eq i64 %474, 0
  br i1 %475, label %470, label %476, !llvm.loop !178

476:                                              ; preds = %470, %461
  %477 = mul i64 %5, 72
  %478 = getelementptr inbounds i8, ptr %0, i64 %477
  %479 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %478, ptr noundef nonnull %478, ptr noundef %3, i64 noundef %5) #15
  %480 = mul i64 %5, 80
  %481 = getelementptr inbounds i8, ptr %0, i64 %480
  %482 = load i64, ptr %481, align 8, !tbaa !9
  %483 = add i64 %482, %479
  store i64 %483, ptr %481, align 8, !tbaa !9
  %484 = load i64, ptr %164, align 8, !tbaa !9
  %485 = add i64 %484, %483
  store i64 %485, ptr %481, align 8, !tbaa !9
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
  %494 = load i64, ptr %493, align 8, !tbaa !9
  %495 = add i64 %494, 1
  %496 = getelementptr inbounds i64, ptr %481, i64 %490
  store i64 %495, ptr %496, align 8, !tbaa !9
  %497 = add nuw i64 %490, 1
  %498 = icmp eq i64 %495, 0
  br i1 %498, label %489, label %499, !llvm.loop !172

499:                                              ; preds = %492
  %500 = icmp ne ptr %164, %481
  %501 = icmp slt i64 %497, %5
  %502 = select i1 %500, i1 %501, i1 false
  br i1 %502, label %503, label %521

503:                                              ; preds = %503, %499
  %504 = phi i64 [ %508, %503 ], [ %497, %499 ]
  %505 = getelementptr inbounds i64, ptr %164, i64 %504
  %506 = load i64, ptr %505, align 8, !tbaa !9
  %507 = getelementptr inbounds i64, ptr %481, i64 %504
  store i64 %506, ptr %507, align 8, !tbaa !9
  %508 = add nuw nsw i64 %504, 1
  %509 = icmp slt i64 %508, %5
  br i1 %509, label %503, label %521, !llvm.loop !173

510:                                              ; preds = %476
  %511 = icmp ne ptr %164, %481
  %512 = icmp sgt i64 %5, 1
  %513 = and i1 %512, %511
  br i1 %513, label %514, label %521

514:                                              ; preds = %514, %510
  %515 = phi i64 [ %519, %514 ], [ 1, %510 ]
  %516 = getelementptr inbounds i64, ptr %164, i64 %515
  %517 = load i64, ptr %516, align 8, !tbaa !9
  %518 = getelementptr inbounds i64, ptr %481, i64 %515
  store i64 %517, ptr %518, align 8, !tbaa !9
  %519 = add nuw nsw i64 %515, 1
  %520 = icmp eq i64 %519, %5
  br i1 %520, label %521, label %514, !llvm.loop !174

521:                                              ; preds = %514, %510, %503, %499, %489
  %522 = phi i64 [ 0, %499 ], [ 0, %510 ], [ 0, %503 ], [ 1, %489 ], [ 0, %514 ]
  %523 = getelementptr inbounds i64, ptr %3, i64 %165
  %524 = load i64, ptr %523, align 8, !tbaa !9
  %525 = add i64 %524, %522
  store i64 %525, ptr %523, align 8, !tbaa !9
  %526 = icmp ult i64 %525, %522
  br i1 %526, label %527, label %533

527:                                              ; preds = %527, %521
  %528 = phi ptr [ %529, %527 ], [ %523, %521 ]
  %529 = getelementptr inbounds i8, ptr %528, i64 8
  %530 = load i64, ptr %529, align 8, !tbaa !9
  %531 = add i64 %530, 1
  store i64 %531, ptr %529, align 8, !tbaa !9
  %532 = icmp eq i64 %531, 0
  br i1 %532, label %527, label %533, !llvm.loop !179

533:                                              ; preds = %527, %521
  %534 = load i64, ptr %168, align 8, !tbaa !9
  %535 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef nonnull %523, i64 noundef %5) #15
  %536 = mul i64 %5, 96
  %537 = getelementptr inbounds i8, ptr %0, i64 %536
  %538 = add i64 %535, %534
  %539 = load i64, ptr %537, align 8, !tbaa !9
  %540 = add i64 %539, %538
  store i64 %540, ptr %537, align 8, !tbaa !9
  %541 = icmp ult i64 %540, %538
  br i1 %541, label %542, label %548

542:                                              ; preds = %542, %533
  %543 = phi ptr [ %544, %542 ], [ %537, %533 ]
  %544 = getelementptr inbounds i8, ptr %543, i64 8
  %545 = load i64, ptr %544, align 8, !tbaa !9
  %546 = add i64 %545, 1
  store i64 %546, ptr %544, align 8, !tbaa !9
  %547 = icmp eq i64 %546, 0
  br i1 %547, label %542, label %548, !llvm.loop !180

548:                                              ; preds = %542, %533
  %549 = mul i64 %5, 104
  %550 = getelementptr inbounds i8, ptr %0, i64 %549
  %551 = tail call i64 @__gmpn_add_n(ptr noundef %550, ptr noundef %550, ptr noundef %1, i64 noundef %5) #15
  %552 = mul i64 %5, 112
  %553 = getelementptr inbounds i8, ptr %0, i64 %552
  %554 = load i64, ptr %553, align 8, !tbaa !9
  %555 = add i64 %554, %551
  store i64 %555, ptr %553, align 8, !tbaa !9
  %556 = load i64, ptr %255, align 8, !tbaa !9
  %557 = add i64 %556, %555
  store i64 %557, ptr %553, align 8, !tbaa !9
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
  %567 = load i64, ptr %566, align 8, !tbaa !9
  %568 = add i64 %567, 1
  %569 = getelementptr inbounds i64, ptr %553, i64 %563
  store i64 %568, ptr %569, align 8, !tbaa !9
  %570 = add nuw i64 %563, 1
  %571 = icmp eq i64 %568, 0
  br i1 %571, label %562, label %572, !llvm.loop !172

572:                                              ; preds = %565
  %573 = icmp ne ptr %255, %553
  %574 = icmp slt i64 %570, %5
  %575 = select i1 %573, i1 %574, i1 false
  br i1 %575, label %576, label %594

576:                                              ; preds = %576, %572
  %577 = phi i64 [ %581, %576 ], [ %570, %572 ]
  %578 = getelementptr inbounds i64, ptr %255, i64 %577
  %579 = load i64, ptr %578, align 8, !tbaa !9
  %580 = getelementptr inbounds i64, ptr %553, i64 %577
  store i64 %579, ptr %580, align 8, !tbaa !9
  %581 = add nuw nsw i64 %577, 1
  %582 = icmp slt i64 %581, %5
  br i1 %582, label %576, label %594, !llvm.loop !173

583:                                              ; preds = %559
  %584 = icmp ne ptr %255, %553
  %585 = icmp sgt i64 %5, 1
  %586 = and i1 %585, %584
  br i1 %586, label %587, label %594

587:                                              ; preds = %587, %583
  %588 = phi i64 [ %592, %587 ], [ 1, %583 ]
  %589 = getelementptr inbounds i64, ptr %255, i64 %588
  %590 = load i64, ptr %589, align 8, !tbaa !9
  %591 = getelementptr inbounds i64, ptr %553, i64 %588
  store i64 %590, ptr %591, align 8, !tbaa !9
  %592 = add nuw nsw i64 %588, 1
  %593 = icmp eq i64 %592, %5
  br i1 %593, label %594, label %587, !llvm.loop !174

594:                                              ; preds = %587, %583, %576, %572, %562
  %595 = phi i64 [ 0, %572 ], [ 0, %583 ], [ 0, %576 ], [ 1, %562 ], [ 0, %587 ]
  %596 = getelementptr inbounds i64, ptr %1, i64 %165
  %597 = load i64, ptr %596, align 8, !tbaa !9
  %598 = add i64 %597, %595
  store i64 %598, ptr %596, align 8, !tbaa !9
  %599 = icmp ult i64 %598, %595
  br i1 %599, label %600, label %606

600:                                              ; preds = %600, %594
  %601 = phi ptr [ %602, %600 ], [ %596, %594 ]
  %602 = getelementptr inbounds i8, ptr %601, i64 8
  %603 = load i64, ptr %602, align 8, !tbaa !9
  %604 = add i64 %603, 1
  store i64 %604, ptr %602, align 8, !tbaa !9
  %605 = icmp eq i64 %604, 0
  br i1 %605, label %600, label %606, !llvm.loop !181

606:                                              ; preds = %600, %594
  %607 = icmp sgt i64 %6, %5
  br i1 %607, label %608, label %626, !prof !30

608:                                              ; preds = %606
  %609 = getelementptr inbounds i64, ptr %1, i64 %10
  %610 = load i64, ptr %609, align 8, !tbaa !9
  %611 = mul i64 %5, 120
  %612 = getelementptr inbounds i8, ptr %0, i64 %611
  %613 = tail call i64 @__gmpn_add_n(ptr noundef %612, ptr noundef %612, ptr noundef nonnull %596, i64 noundef %5) #15
  %614 = shl nsw i64 %5, 7
  %615 = getelementptr inbounds i8, ptr %0, i64 %614
  %616 = add i64 %613, %610
  %617 = load i64, ptr %615, align 8, !tbaa !9
  %618 = add i64 %617, %616
  store i64 %618, ptr %615, align 8, !tbaa !9
  %619 = icmp ult i64 %618, %616
  br i1 %619, label %620, label %665

620:                                              ; preds = %620, %608
  %621 = phi ptr [ %622, %620 ], [ %615, %608 ]
  %622 = getelementptr inbounds i8, ptr %621, i64 8
  %623 = load i64, ptr %622, align 8, !tbaa !9
  %624 = add i64 %623, 1
  store i64 %624, ptr %622, align 8, !tbaa !9
  %625 = icmp eq i64 %624, 0
  br i1 %625, label %620, label %665, !llvm.loop !182

626:                                              ; preds = %606
  %627 = mul i64 %5, 120
  %628 = getelementptr inbounds i8, ptr %0, i64 %627
  %629 = tail call i64 @__gmpn_add_n(ptr noundef %628, ptr noundef %628, ptr noundef nonnull %596, i64 noundef %6) #15
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
  %638 = load i64, ptr %637, align 8, !tbaa !9
  %639 = add i64 %638, 1
  %640 = getelementptr inbounds i64, ptr %553, i64 %634
  store i64 %639, ptr %640, align 8, !tbaa !9
  %641 = add nuw i64 %634, 1
  %642 = icmp eq i64 %639, 0
  br i1 %642, label %633, label %643, !llvm.loop !172

643:                                              ; preds = %636
  %644 = icmp ne ptr %255, %553
  %645 = icmp slt i64 %641, %6
  %646 = select i1 %644, i1 %645, i1 false
  br i1 %646, label %647, label %665

647:                                              ; preds = %647, %643
  %648 = phi i64 [ %652, %647 ], [ %641, %643 ]
  %649 = getelementptr inbounds i64, ptr %255, i64 %648
  %650 = load i64, ptr %649, align 8, !tbaa !9
  %651 = getelementptr inbounds i64, ptr %553, i64 %648
  store i64 %650, ptr %651, align 8, !tbaa !9
  %652 = add nuw nsw i64 %648, 1
  %653 = icmp slt i64 %652, %6
  br i1 %653, label %647, label %665, !llvm.loop !173

654:                                              ; preds = %630
  %655 = icmp ne ptr %255, %553
  %656 = icmp sgt i64 %6, 1
  %657 = and i1 %656, %655
  br i1 %657, label %658, label %665

658:                                              ; preds = %658, %654
  %659 = phi i64 [ %663, %658 ], [ 1, %654 ]
  %660 = getelementptr inbounds i64, ptr %255, i64 %659
  %661 = load i64, ptr %660, align 8, !tbaa !9
  %662 = getelementptr inbounds i64, ptr %553, i64 %659
  store i64 %661, ptr %662, align 8, !tbaa !9
  %663 = add nuw nsw i64 %659, 1
  %664 = icmp eq i64 %663, %6
  br i1 %664, label %665, label %658, !llvm.loop !174

665:                                              ; preds = %658, %654, %647, %643, %633, %626, %620, %608
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mulmod_bknp1(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i32 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = add i32 %4, -1
  %8 = zext i32 %7 to i64
  %9 = mul nsw i64 %8, %3
  %10 = shl nsw i64 %9, 1
  %11 = getelementptr inbounds i64, ptr %5, i64 %10
  tail call fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %11, ptr noundef %1, i64 noundef %3, i32 noundef %4)
  %12 = mul i64 %9, 24
  %13 = getelementptr inbounds i8, ptr %5, i64 %12
  tail call fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %13, ptr noundef %2, i64 noundef %3, i32 noundef %4)
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef %11, ptr noundef %13, i64 noundef %9) #15
  %14 = zext i32 %4 to i64
  %15 = mul nsw i64 %14, %3
  %16 = sub nsw i64 %10, %15
  %17 = icmp eq i64 %16, 0
  br i1 %17, label %31, label %18

18:                                               ; preds = %6
  %19 = getelementptr inbounds i64, ptr %5, i64 %15
  %20 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %19, i64 noundef %16) #15
  %21 = icmp eq i64 %20, 0
  br i1 %21, label %31, label %22

22:                                               ; preds = %25, %18
  %23 = phi i64 [ %29, %25 ], [ %16, %18 ]
  %24 = icmp slt i64 %23, %15
  br i1 %24, label %25, label %31

25:                                               ; preds = %22
  %26 = getelementptr inbounds i64, ptr %5, i64 %23
  %27 = load i64, ptr %26, align 8, !tbaa !9
  %28 = add i64 %27, -1
  %29 = add nsw i64 %23, 1
  store i64 %28, ptr %26, align 8, !tbaa !9
  %30 = icmp eq i64 %27, 0
  br i1 %30, label %22, label %31, !llvm.loop !183

31:                                               ; preds = %25, %22, %18, %6
  %32 = phi i64 [ 0, %18 ], [ 0, %6 ], [ 1, %22 ], [ 0, %25 ]
  %33 = getelementptr inbounds i64, ptr %5, i64 %15
  store i64 0, ptr %33, align 8, !tbaa !9
  %34 = load i64, ptr %5, align 8, !tbaa !9
  %35 = add i64 %34, %32
  store i64 %35, ptr %5, align 8, !tbaa !9
  %36 = icmp ult i64 %35, %32
  br i1 %36, label %37, label %43

37:                                               ; preds = %37, %31
  %38 = phi ptr [ %39, %37 ], [ %5, %31 ]
  %39 = getelementptr inbounds i8, ptr %38, i64 8
  %40 = load i64, ptr %39, align 8, !tbaa !9
  %41 = add i64 %40, 1
  store i64 %41, ptr %39, align 8, !tbaa !9
  %42 = icmp eq i64 %41, 0
  br i1 %42, label %37, label %43, !llvm.loop !184

43:                                               ; preds = %37, %31
  %44 = getelementptr inbounds i8, ptr %33, i64 8
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef nonnull %44, ptr noundef %1, i64 noundef %3, i32 noundef %4)
  %45 = getelementptr inbounds i64, ptr %44, i64 %3
  %46 = getelementptr inbounds i8, ptr %45, i64 8
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef nonnull %46, ptr noundef %2, i64 noundef %3, i32 noundef %4)
  %47 = shl i64 %3, 4
  %48 = getelementptr i8, ptr %44, i64 %47
  %49 = getelementptr i8, ptr %48, i64 16
  %50 = load i64, ptr %45, align 8, !tbaa !9
  %51 = getelementptr inbounds i64, ptr %46, i64 %3
  %52 = load i64, ptr %51, align 8, !tbaa !9
  %53 = or i64 %52, %50
  %54 = icmp eq i64 %53, 0
  br i1 %54, label %62, label %55, !prof !30

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
  tail call void @__gmpn_mul_n(ptr noundef %49, ptr noundef nonnull %44, ptr noundef nonnull %46, i64 noundef %3) #15
  %80 = getelementptr inbounds i64, ptr %49, i64 %3
  %81 = tail call i64 @__gmpn_sub_n(ptr noundef %49, ptr noundef %49, ptr noundef %80, i64 noundef %3) #15
  br label %82

82:                                               ; preds = %79, %60, %57
  %83 = phi i64 [ %59, %57 ], [ %61, %60 ], [ %81, %79 ]
  %84 = getelementptr inbounds i64, ptr %49, i64 %3
  store i64 0, ptr %84, align 8, !tbaa !9
  %85 = load i64, ptr %49, align 8, !tbaa !9
  %86 = add i64 %85, %83
  store i64 %86, ptr %49, align 8, !tbaa !9
  %87 = icmp ult i64 %86, %83
  br i1 %87, label %88, label %94

88:                                               ; preds = %88, %82
  %89 = phi ptr [ %90, %88 ], [ %49, %82 ]
  %90 = getelementptr inbounds i8, ptr %89, i64 8
  %91 = load i64, ptr %90, align 8, !tbaa !9
  %92 = add i64 %91, 1
  store i64 %92, ptr %90, align 8, !tbaa !9
  %93 = icmp eq i64 %92, 0
  br i1 %93, label %88, label %94, !llvm.loop !185

94:                                               ; preds = %88, %82, %75
  tail call fastcc void @_mpn_crt(ptr noundef %0, ptr noundef nonnull %5, ptr noundef %49, i64 noundef %3, i32 noundef %4, ptr noundef nonnull %44)
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %0, ptr noundef %1, i64 noundef %2, i32 noundef %3) unnamed_addr #3 {
  %5 = add i32 %3, -1
  %6 = zext i32 %5 to i64
  %7 = mul nsw i64 %6, %2
  %8 = getelementptr inbounds i64, ptr %0, i64 %7
  %9 = getelementptr inbounds i64, ptr %1, i64 %7
  %10 = getelementptr inbounds i64, ptr %9, i64 %2
  %11 = load i64, ptr %10, align 8, !tbaa !9
  store i64 0, ptr %8, align 8, !tbaa !9
  %12 = lshr i32 %5, 1
  %13 = sub i64 0, %2
  br label %14

14:                                               ; preds = %45, %4
  %15 = phi i32 [ %12, %4 ], [ %46, %45 ]
  %16 = phi ptr [ %9, %4 ], [ %33, %45 ]
  %17 = phi ptr [ %8, %4 ], [ %32, %45 ]
  %18 = getelementptr inbounds i64, ptr %17, i64 %13
  %19 = getelementptr inbounds i64, ptr %16, i64 %13
  %20 = tail call i64 @__gmpn_add_n(ptr noundef %18, ptr noundef %19, ptr noundef %9, i64 noundef %2) #15
  %21 = add i64 %20, %11
  %22 = load i64, ptr %17, align 8, !tbaa !9
  %23 = add i64 %22, %21
  store i64 %23, ptr %17, align 8, !tbaa !9
  %24 = icmp ult i64 %23, %21
  br i1 %24, label %25, label %31

25:                                               ; preds = %25, %14
  %26 = phi ptr [ %27, %25 ], [ %17, %14 ]
  %27 = getelementptr inbounds i8, ptr %26, i64 8
  %28 = load i64, ptr %27, align 8, !tbaa !9
  %29 = add i64 %28, 1
  store i64 %29, ptr %27, align 8, !tbaa !9
  %30 = icmp eq i64 %29, 0
  br i1 %30, label %25, label %31, !llvm.loop !186

31:                                               ; preds = %25, %14
  %32 = getelementptr inbounds i64, ptr %18, i64 %13
  %33 = getelementptr inbounds i64, ptr %19, i64 %13
  %34 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %32, ptr noundef %33, ptr noundef %9, i64 noundef %2) #15
  %35 = add i64 %34, %11
  %36 = load i64, ptr %18, align 8, !tbaa !9
  %37 = sub i64 %36, %35
  store i64 %37, ptr %18, align 8, !tbaa !9
  %38 = icmp ult i64 %36, %35
  br i1 %38, label %39, label %45

39:                                               ; preds = %39, %31
  %40 = phi ptr [ %41, %39 ], [ %18, %31 ]
  %41 = getelementptr inbounds i8, ptr %40, i64 8
  %42 = load i64, ptr %41, align 8, !tbaa !9
  %43 = add i64 %42, -1
  store i64 %43, ptr %41, align 8, !tbaa !9
  %44 = icmp eq i64 %42, 0
  br i1 %44, label %39, label %45, !llvm.loop !187

45:                                               ; preds = %39, %31
  %46 = add i32 %15, -1
  %47 = icmp eq i32 %46, 0
  br i1 %47, label %48, label %14, !llvm.loop !188

48:                                               ; preds = %45
  %49 = getelementptr inbounds i64, ptr %17, i64 %13
  %50 = getelementptr inbounds i64, ptr %49, i64 %13
  %51 = getelementptr inbounds i64, ptr %50, i64 %7
  %52 = load i64, ptr %51, align 8, !tbaa !9
  %53 = icmp eq i64 %52, 0
  br i1 %53, label %90, label %54

54:                                               ; preds = %84, %48
  %55 = phi i64 [ %88, %84 ], [ %52, %48 ]
  %56 = phi ptr [ %87, %84 ], [ %51, %48 ]
  store i64 0, ptr %56, align 8, !tbaa !9
  br label %57

57:                                               ; preds = %81, %54
  %58 = phi i32 [ %12, %54 ], [ %82, %81 ]
  %59 = phi ptr [ %56, %54 ], [ %71, %81 ]
  %60 = getelementptr inbounds i64, ptr %59, i64 %13
  %61 = load i64, ptr %60, align 8, !tbaa !9
  %62 = add i64 %61, %55
  store i64 %62, ptr %60, align 8, !tbaa !9
  %63 = icmp ult i64 %62, %55
  br i1 %63, label %64, label %70

64:                                               ; preds = %64, %57
  %65 = phi ptr [ %66, %64 ], [ %60, %57 ]
  %66 = getelementptr inbounds i8, ptr %65, i64 8
  %67 = load i64, ptr %66, align 8, !tbaa !9
  %68 = add i64 %67, 1
  store i64 %68, ptr %66, align 8, !tbaa !9
  %69 = icmp eq i64 %68, 0
  br i1 %69, label %64, label %70, !llvm.loop !189

70:                                               ; preds = %64, %57
  %71 = getelementptr inbounds i64, ptr %60, i64 %13
  %72 = load i64, ptr %71, align 8, !tbaa !9
  %73 = sub i64 %72, %55
  store i64 %73, ptr %71, align 8, !tbaa !9
  %74 = icmp ult i64 %72, %55
  br i1 %74, label %75, label %81

75:                                               ; preds = %75, %70
  %76 = phi ptr [ %77, %75 ], [ %71, %70 ]
  %77 = getelementptr inbounds i8, ptr %76, i64 8
  %78 = load i64, ptr %77, align 8, !tbaa !9
  %79 = add i64 %78, -1
  store i64 %79, ptr %77, align 8, !tbaa !9
  %80 = icmp eq i64 %78, 0
  br i1 %80, label %75, label %81, !llvm.loop !190

81:                                               ; preds = %75, %70
  %82 = add i32 %58, -1
  %83 = icmp eq i32 %82, 0
  br i1 %83, label %84, label %57, !llvm.loop !191

84:                                               ; preds = %81
  %85 = getelementptr inbounds i64, ptr %59, i64 %13
  %86 = getelementptr inbounds i64, ptr %85, i64 %13
  %87 = getelementptr inbounds i64, ptr %86, i64 %7
  %88 = load i64, ptr %87, align 8, !tbaa !9
  %89 = icmp eq i64 %88, 0
  br i1 %89, label %90, label %54, !llvm.loop !192

90:                                               ; preds = %84, %48
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @_mpn_modbnp1_kn(ptr noundef %0, ptr noundef %1, i64 noundef %2, i32 noundef %3) unnamed_addr #3 {
  %5 = lshr i32 %3, 1
  %6 = getelementptr inbounds i64, ptr %1, i64 %2
  %7 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %6, i64 noundef %2) #15
  %8 = shl nsw i64 %2, 4
  %9 = getelementptr inbounds i8, ptr %1, i64 %8
  %10 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %9, i64 noundef %2) #15
  %11 = sub i64 %10, %7
  %12 = add nsw i32 %5, -1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %26, label %14

14:                                               ; preds = %14, %4
  %15 = phi i32 [ %24, %14 ], [ %12, %4 ]
  %16 = phi i64 [ %23, %14 ], [ %11, %4 ]
  %17 = phi ptr [ %21, %14 ], [ %9, %4 ]
  %18 = getelementptr inbounds i64, ptr %17, i64 %2
  %19 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %0, ptr noundef %18, i64 noundef %2) #15
  %20 = sub i64 %16, %19
  %21 = getelementptr inbounds i8, ptr %17, i64 %8
  %22 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %21, i64 noundef %2) #15
  %23 = add i64 %22, %20
  %24 = add i32 %15, -1
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %26, label %14, !llvm.loop !193

26:                                               ; preds = %14, %4
  %27 = phi ptr [ %1, %4 ], [ %17, %14 ]
  %28 = phi i64 [ %11, %4 ], [ %23, %14 ]
  %29 = getelementptr inbounds i8, ptr %27, i64 %8
  %30 = getelementptr inbounds i64, ptr %29, i64 %2
  %31 = load i64, ptr %30, align 8, !tbaa !9
  %32 = add i64 %31, %28
  %33 = icmp sgt i64 %32, -1
  %34 = getelementptr inbounds i64, ptr %0, i64 %2
  br i1 %33, label %50, label %35

35:                                               ; preds = %26
  store i64 0, ptr %34, align 8, !tbaa !9
  %36 = sub i64 0, %32
  %37 = load i64, ptr %0, align 8, !tbaa !9
  %38 = sub i64 %37, %32
  store i64 %38, ptr %0, align 8, !tbaa !9
  %39 = icmp ult i64 %38, %36
  br i1 %39, label %40, label %46

40:                                               ; preds = %40, %35
  %41 = phi ptr [ %42, %40 ], [ %0, %35 ]
  %42 = getelementptr inbounds i8, ptr %41, i64 8
  %43 = load i64, ptr %42, align 8, !tbaa !9
  %44 = add i64 %43, 1
  store i64 %44, ptr %42, align 8, !tbaa !9
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %40, label %46, !llvm.loop !194

46:                                               ; preds = %40, %35
  %47 = load i64, ptr %34, align 8, !tbaa !9
  %48 = icmp eq i64 %47, 0
  br i1 %48, label %74, label %49, !prof !30

49:                                               ; preds = %46
  tail call fastcc void @_mpn_modbnp1_pn_ip(ptr noundef nonnull %0, i64 noundef %2, i64 noundef 1)
  br label %74

50:                                               ; preds = %26
  store i64 %32, ptr %34, align 8, !tbaa !9
  %51 = icmp eq i64 %32, 0
  br i1 %51, label %74, label %52

52:                                               ; preds = %50
  %53 = load i64, ptr %0, align 8, !tbaa !9
  %54 = sub i64 %53, %32
  store i64 %54, ptr %0, align 8, !tbaa !9
  %55 = icmp ult i64 %53, %32
  br i1 %55, label %56, label %62

56:                                               ; preds = %56, %52
  %57 = phi ptr [ %58, %56 ], [ %0, %52 ]
  %58 = getelementptr inbounds i8, ptr %57, i64 8
  %59 = load i64, ptr %58, align 8, !tbaa !9
  %60 = add i64 %59, -1
  store i64 %60, ptr %58, align 8, !tbaa !9
  %61 = icmp eq i64 %59, 0
  br i1 %61, label %56, label %62, !llvm.loop !195

62:                                               ; preds = %56, %52
  %63 = load i64, ptr %34, align 8, !tbaa !9
  store i64 0, ptr %34, align 8, !tbaa !9
  %64 = sub i64 %32, %63
  %65 = load i64, ptr %0, align 8, !tbaa !9
  %66 = add i64 %65, %64
  store i64 %66, ptr %0, align 8, !tbaa !9
  %67 = icmp ult i64 %66, %64
  br i1 %67, label %68, label %74

68:                                               ; preds = %68, %62
  %69 = phi ptr [ %70, %68 ], [ %0, %62 ]
  %70 = getelementptr inbounds i8, ptr %69, i64 8
  %71 = load i64, ptr %70, align 8, !tbaa !9
  %72 = add i64 %71, 1
  store i64 %72, ptr %70, align 8, !tbaa !9
  %73 = icmp eq i64 %72, 0
  br i1 %73, label %68, label %74, !llvm.loop !196

74:                                               ; preds = %68, %62, %50, %49, %46
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @_mpn_crt(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i32 noundef %4, ptr noundef %5) unnamed_addr #3 {
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef %5, ptr noundef %1, i64 noundef %3, i32 noundef %4)
  %7 = add nsw i64 %3, 1
  %8 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %2, ptr noundef %5, i64 noundef %7) #15
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %27, label %10

10:                                               ; preds = %6
  %11 = getelementptr inbounds i64, ptr %5, i64 %3
  %12 = load i64, ptr %11, align 8, !tbaa !9
  store i64 0, ptr %11, align 8, !tbaa !9
  %13 = sub i64 0, %12
  %14 = load i64, ptr %5, align 8, !tbaa !9
  %15 = sub i64 %14, %12
  store i64 %15, ptr %5, align 8, !tbaa !9
  %16 = icmp ult i64 %15, %13
  br i1 %16, label %17, label %23

17:                                               ; preds = %17, %10
  %18 = phi ptr [ %19, %17 ], [ %5, %10 ]
  %19 = getelementptr inbounds i8, ptr %18, i64 8
  %20 = load i64, ptr %19, align 8, !tbaa !9
  %21 = add i64 %20, 1
  store i64 %21, ptr %19, align 8, !tbaa !9
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %17, label %23, !llvm.loop !194

23:                                               ; preds = %17, %10
  %24 = load i64, ptr %11, align 8, !tbaa !9
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %27, label %26, !prof !30

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
  ], !prof !197

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
  %45 = load i64, ptr %5, align 8, !tbaa !9
  %46 = add i64 %45, %44
  store i64 %46, ptr %5, align 8, !tbaa !9
  %47 = icmp ult i64 %46, %44
  br i1 %47, label %48, label %54

48:                                               ; preds = %48, %43
  %49 = phi ptr [ %50, %48 ], [ %5, %43 ]
  %50 = getelementptr inbounds i8, ptr %49, i64 8
  %51 = load i64, ptr %50, align 8, !tbaa !9
  %52 = add i64 %51, 1
  store i64 %52, ptr %50, align 8, !tbaa !9
  %53 = icmp eq i64 %52, 0
  br i1 %53, label %48, label %54, !llvm.loop !198

54:                                               ; preds = %48, %43
  %55 = getelementptr inbounds i64, ptr %5, i64 %3
  %56 = load i64, ptr %55, align 8, !tbaa !9
  %57 = add i64 %56, %44
  store i64 %57, ptr %55, align 8, !tbaa !9
  switch i32 %30, label %64 [
    i32 0, label %58
    i32 1, label %60
    i32 2, label %62
    i32 5, label %63
  ], !prof !197

58:                                               ; preds = %54
  %59 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 6148914691236517205, i64 noundef 0) #15
  br label %66

60:                                               ; preds = %54
  %61 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 3689348814741910323, i64 noundef 0) #15
  br label %66

62:                                               ; preds = %54
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 7) #15
  br label %66

63:                                               ; preds = %54
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 13) #15
  br label %66

64:                                               ; preds = %54
  %65 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %5, ptr noundef nonnull %5, i64 noundef %7, i64 noundef 1085102592571150095, i64 noundef 0) #15
  br label %66

66:                                               ; preds = %64, %63, %62, %60, %58
  %67 = zext i32 %4 to i64
  %68 = mul nsw i64 %67, %3
  %69 = getelementptr inbounds i64, ptr %0, i64 %68
  %70 = getelementptr inbounds i64, ptr %1, i64 %68
  %71 = sub i64 0, %3
  %72 = getelementptr inbounds i64, ptr %69, i64 %71
  %73 = getelementptr inbounds i64, ptr %70, i64 %71
  %74 = tail call i64 @__gmpn_add_n(ptr noundef %72, ptr noundef %73, ptr noundef nonnull %5, i64 noundef %7) #15
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
  %84 = tail call i64 @__gmpn_sub_n(ptr noundef %82, ptr noundef %83, ptr noundef nonnull %5, i64 noundef %3) #15
  %85 = load i64, ptr %55, align 8, !tbaa !9
  %86 = add i64 %85, %84
  %87 = load i64, ptr %81, align 8, !tbaa !9
  %88 = sub i64 %87, %86
  store i64 %88, ptr %81, align 8, !tbaa !9
  %89 = icmp ult i64 %87, %86
  br i1 %89, label %90, label %96

90:                                               ; preds = %90, %76
  %91 = phi ptr [ %92, %90 ], [ %81, %76 ]
  %92 = getelementptr inbounds i8, ptr %91, i64 8
  %93 = load i64, ptr %92, align 8, !tbaa !9
  %94 = add i64 %93, -1
  store i64 %94, ptr %92, align 8, !tbaa !9
  %95 = icmp eq i64 %93, 0
  br i1 %95, label %90, label %96, !llvm.loop !199

96:                                               ; preds = %90, %76
  %97 = getelementptr inbounds i64, ptr %82, i64 %71
  %98 = getelementptr inbounds i64, ptr %83, i64 %71
  %99 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %97, ptr noundef %98, ptr noundef nonnull %5, i64 noundef %3) #15
  %100 = load i64, ptr %55, align 8, !tbaa !9
  %101 = add i64 %100, %99
  %102 = load i64, ptr %82, align 8, !tbaa !9
  %103 = add i64 %102, %101
  store i64 %103, ptr %82, align 8, !tbaa !9
  %104 = icmp ult i64 %103, %101
  br i1 %104, label %105, label %111

105:                                              ; preds = %105, %96
  %106 = phi ptr [ %107, %105 ], [ %82, %96 ]
  %107 = getelementptr inbounds i8, ptr %106, i64 8
  %108 = load i64, ptr %107, align 8, !tbaa !9
  %109 = add i64 %108, 1
  store i64 %109, ptr %107, align 8, !tbaa !9
  %110 = icmp eq i64 %109, 0
  br i1 %110, label %105, label %111, !llvm.loop !200

111:                                              ; preds = %105, %96
  %112 = add i32 %77, -1
  %113 = icmp eq i32 %112, 0
  br i1 %113, label %114, label %76, !llvm.loop !201

114:                                              ; preds = %111
  %115 = getelementptr inbounds i64, ptr %97, i64 %68
  %116 = load i64, ptr %115, align 8, !tbaa !9
  %117 = load i64, ptr %97, align 8, !tbaa !9
  %118 = sub i64 %117, %116
  store i64 %118, ptr %97, align 8, !tbaa !9
  %119 = icmp ult i64 %117, %116
  br i1 %119, label %120, label %126

120:                                              ; preds = %120, %114
  %121 = phi ptr [ %122, %120 ], [ %97, %114 ]
  %122 = getelementptr inbounds i8, ptr %121, i64 8
  %123 = load i64, ptr %122, align 8, !tbaa !9
  %124 = add i64 %123, -1
  store i64 %124, ptr %122, align 8, !tbaa !9
  %125 = icmp eq i64 %123, 0
  br i1 %125, label %120, label %126, !llvm.loop !195

126:                                              ; preds = %120, %114
  %127 = load i64, ptr %115, align 8, !tbaa !9
  store i64 0, ptr %115, align 8, !tbaa !9
  %128 = sub i64 %116, %127
  %129 = load i64, ptr %97, align 8, !tbaa !9
  %130 = add i64 %129, %128
  store i64 %130, ptr %97, align 8, !tbaa !9
  %131 = icmp ult i64 %130, %128
  br i1 %131, label %132, label %138

132:                                              ; preds = %132, %126
  %133 = phi ptr [ %134, %132 ], [ %97, %126 ]
  %134 = getelementptr inbounds i8, ptr %133, i64 8
  %135 = load i64, ptr %134, align 8, !tbaa !9
  %136 = add i64 %135, 1
  store i64 %136, ptr %134, align 8, !tbaa !9
  %137 = icmp eq i64 %136, 0
  br i1 %137, label %132, label %138, !llvm.loop !196

138:                                              ; preds = %132, %126
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define hidden fastcc void @_mpn_modbnp1_pn_ip(ptr nocapture noundef %0, i64 noundef %1, i64 noundef %2) unnamed_addr #5 {
  %4 = load i64, ptr %0, align 8, !tbaa !9
  %5 = sub i64 %4, %2
  store i64 %5, ptr %0, align 8, !tbaa !9
  %6 = icmp ult i64 %4, %2
  br i1 %6, label %7, label %13

7:                                                ; preds = %7, %3
  %8 = phi ptr [ %9, %7 ], [ %0, %3 ]
  %9 = getelementptr inbounds i8, ptr %8, i64 8
  %10 = load i64, ptr %9, align 8, !tbaa !9
  %11 = add i64 %10, -1
  store i64 %11, ptr %9, align 8, !tbaa !9
  %12 = icmp eq i64 %10, 0
  br i1 %12, label %7, label %13, !llvm.loop !195

13:                                               ; preds = %7, %3
  %14 = getelementptr inbounds i64, ptr %0, i64 %1
  %15 = load i64, ptr %14, align 8, !tbaa !9
  store i64 0, ptr %14, align 8, !tbaa !9
  %16 = sub i64 %2, %15
  %17 = load i64, ptr %0, align 8, !tbaa !9
  %18 = add i64 %17, %16
  store i64 %18, ptr %0, align 8, !tbaa !9
  %19 = icmp ult i64 %18, %16
  br i1 %19, label %20, label %26

20:                                               ; preds = %20, %13
  %21 = phi ptr [ %22, %20 ], [ %0, %13 ]
  %22 = getelementptr inbounds i8, ptr %21, i64 8
  %23 = load i64, ptr %22, align 8, !tbaa !9
  %24 = add i64 %23, 1
  store i64 %24, ptr %22, align 8, !tbaa !9
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %20, label %26, !llvm.loop !196

26:                                               ; preds = %20, %13
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #1

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqrmod_bknp1(ptr noundef %0, ptr noundef %1, i64 noundef %2, i32 noundef %3, ptr noundef %4) local_unnamed_addr #3 {
  %6 = add i32 %3, -1
  %7 = zext i32 %6 to i64
  %8 = mul nsw i64 %7, %2
  %9 = shl nsw i64 %8, 1
  %10 = getelementptr inbounds i64, ptr %4, i64 %9
  tail call fastcc void @_mpn_modbknp1dbnp1_n(ptr noundef %10, ptr noundef %1, i64 noundef %2, i32 noundef %3)
  tail call void @__gmpn_sqr(ptr noundef %4, ptr noundef %10, i64 noundef %8) #15
  %11 = zext i32 %3 to i64
  %12 = mul nsw i64 %11, %2
  %13 = sub nsw i64 %9, %12
  %14 = icmp eq i64 %13, 0
  br i1 %14, label %28, label %15

15:                                               ; preds = %5
  %16 = getelementptr inbounds i64, ptr %4, i64 %12
  %17 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %16, i64 noundef %13) #15
  %18 = icmp eq i64 %17, 0
  br i1 %18, label %28, label %19

19:                                               ; preds = %22, %15
  %20 = phi i64 [ %26, %22 ], [ %13, %15 ]
  %21 = icmp slt i64 %20, %12
  br i1 %21, label %22, label %28

22:                                               ; preds = %19
  %23 = getelementptr inbounds i64, ptr %4, i64 %20
  %24 = load i64, ptr %23, align 8, !tbaa !9
  %25 = add i64 %24, -1
  %26 = add nsw i64 %20, 1
  store i64 %25, ptr %23, align 8, !tbaa !9
  %27 = icmp eq i64 %24, 0
  br i1 %27, label %19, label %28, !llvm.loop !183

28:                                               ; preds = %22, %19, %15, %5
  %29 = phi i64 [ 0, %15 ], [ 0, %5 ], [ 1, %19 ], [ 0, %22 ]
  %30 = getelementptr inbounds i64, ptr %4, i64 %12
  store i64 0, ptr %30, align 8, !tbaa !9
  %31 = load i64, ptr %4, align 8, !tbaa !9
  %32 = add i64 %31, %29
  store i64 %32, ptr %4, align 8, !tbaa !9
  %33 = icmp ult i64 %32, %29
  br i1 %33, label %34, label %40

34:                                               ; preds = %34, %28
  %35 = phi ptr [ %36, %34 ], [ %4, %28 ]
  %36 = getelementptr inbounds i8, ptr %35, i64 8
  %37 = load i64, ptr %36, align 8, !tbaa !9
  %38 = add i64 %37, 1
  store i64 %38, ptr %36, align 8, !tbaa !9
  %39 = icmp eq i64 %38, 0
  br i1 %39, label %34, label %40, !llvm.loop !184

40:                                               ; preds = %34, %28
  %41 = getelementptr inbounds i8, ptr %30, i64 8
  tail call fastcc void @_mpn_modbnp1_kn(ptr noundef nonnull %41, ptr noundef %1, i64 noundef %2, i32 noundef %3)
  %42 = getelementptr i64, ptr %41, i64 %2
  %43 = getelementptr i8, ptr %42, i64 8
  %44 = load i64, ptr %42, align 8, !tbaa !9
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %53, label %46, !prof !30

46:                                               ; preds = %40
  store i64 1, ptr %43, align 8, !tbaa !9
  %47 = shl nuw nsw i64 %11, 3
  %48 = add nuw nsw i64 %47, 8
  %49 = mul i64 %48, %2
  %50 = getelementptr i8, ptr %4, i64 %49
  %51 = getelementptr i8, ptr %50, i64 24
  %52 = shl nuw i64 %2, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %51, i8 0, i64 %52, i1 false), !tbaa !9
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
  tail call void @__gmpn_sqr(ptr noundef %43, ptr noundef nonnull %41, i64 noundef %2) #15
  %71 = getelementptr inbounds i64, ptr %43, i64 %2
  %72 = tail call i64 @__gmpn_sub_n(ptr noundef %43, ptr noundef %43, ptr noundef %71, i64 noundef %2) #15
  store i64 0, ptr %71, align 8, !tbaa !9
  %73 = load i64, ptr %43, align 8, !tbaa !9
  %74 = add i64 %73, %72
  store i64 %74, ptr %43, align 8, !tbaa !9
  %75 = icmp ult i64 %74, %72
  br i1 %75, label %76, label %82

76:                                               ; preds = %76, %70
  %77 = phi ptr [ %78, %76 ], [ %43, %70 ]
  %78 = getelementptr inbounds i8, ptr %77, i64 8
  %79 = load i64, ptr %78, align 8, !tbaa !9
  %80 = add i64 %79, 1
  store i64 %80, ptr %78, align 8, !tbaa !9
  %81 = icmp eq i64 %80, 0
  br i1 %81, label %76, label %82, !llvm.loop !202

82:                                               ; preds = %76, %70, %66, %46
  tail call fastcc void @_mpn_crt(ptr noundef %0, ptr noundef nonnull %4, ptr noundef %43, i64 noundef %2, i32 noundef %3, ptr noundef nonnull %41)
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define range(i64 0, 2) i64 @__gmpn_add_n(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, ptr nocapture noundef readonly %2, i64 noundef %3) local_unnamed_addr #5 {
  br label %5

5:                                                ; preds = %5, %4
  %6 = phi i64 [ %3, %4 ], [ %22, %5 ]
  %7 = phi ptr [ %2, %4 ], [ %13, %5 ]
  %8 = phi i64 [ 0, %4 ], [ %20, %5 ]
  %9 = phi ptr [ %1, %4 ], [ %11, %5 ]
  %10 = phi ptr [ %0, %4 ], [ %21, %5 ]
  %11 = getelementptr inbounds i8, ptr %9, i64 8
  %12 = load i64, ptr %9, align 8, !tbaa !9
  %13 = getelementptr inbounds i8, ptr %7, i64 8
  %14 = load i64, ptr %7, align 8, !tbaa !9
  %15 = add i64 %14, %12
  %16 = icmp ult i64 %15, %12
  %17 = add i64 %15, %8
  %18 = icmp ult i64 %17, %15
  %19 = or i1 %16, %18
  %20 = zext i1 %19 to i64
  %21 = getelementptr inbounds i8, ptr %10, i64 8
  store i64 %17, ptr %10, align 8, !tbaa !9
  %22 = add nsw i64 %6, -1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %24, label %5, !llvm.loop !203

24:                                               ; preds = %5
  ret i64 %20
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_12pts(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, i32 noundef %6, ptr noundef %7) local_unnamed_addr #3 {
  %9 = mul nsw i64 %4, 3
  %10 = add nsw i64 %9, 1
  %11 = icmp eq i32 %6, 0
  br i1 %11, label %117, label %12

12:                                               ; preds = %8
  %13 = mul i64 %4, 88
  %14 = getelementptr inbounds i8, ptr %0, i64 %13
  %15 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %14, i64 noundef %5) #15
  %16 = getelementptr inbounds i64, ptr %2, i64 %5
  %17 = load i64, ptr %16, align 8, !tbaa !9
  %18 = sub i64 %17, %15
  store i64 %18, ptr %16, align 8, !tbaa !9
  %19 = icmp ult i64 %17, %15
  br i1 %19, label %20, label %26

20:                                               ; preds = %20, %12
  %21 = phi ptr [ %22, %20 ], [ %16, %12 ]
  %22 = getelementptr inbounds i8, ptr %21, i64 8
  %23 = load i64, ptr %22, align 8, !tbaa !9
  %24 = add i64 %23, -1
  store i64 %24, ptr %22, align 8, !tbaa !9
  %25 = icmp eq i64 %23, 0
  br i1 %25, label %20, label %26, !llvm.loop !204

26:                                               ; preds = %20, %12
  %27 = mul i64 %4, 56
  %28 = getelementptr inbounds i8, ptr %0, i64 %27
  %29 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %14, i64 noundef %5, i32 noundef 10) #15
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef %28, ptr noundef %28, ptr noundef %7, i64 noundef %5) #15
  %31 = getelementptr inbounds i64, ptr %28, i64 %5
  %32 = add i64 %30, %29
  %33 = load i64, ptr %31, align 8, !tbaa !9
  %34 = sub i64 %33, %32
  store i64 %34, ptr %31, align 8, !tbaa !9
  %35 = icmp ult i64 %33, %32
  br i1 %35, label %36, label %42

36:                                               ; preds = %36, %26
  %37 = phi ptr [ %38, %36 ], [ %31, %26 ]
  %38 = getelementptr inbounds i8, ptr %37, i64 8
  %39 = load i64, ptr %38, align 8, !tbaa !9
  %40 = add i64 %39, -1
  store i64 %40, ptr %38, align 8, !tbaa !9
  %41 = icmp eq i64 %39, 0
  br i1 %41, label %36, label %42, !llvm.loop !205

42:                                               ; preds = %36, %26
  %43 = load i64, ptr %14, align 8, !tbaa !9
  %44 = lshr i64 %43, 2
  %45 = load i64, ptr %3, align 8, !tbaa !9
  %46 = sub i64 %45, %44
  store i64 %46, ptr %3, align 8, !tbaa !9
  %47 = load i64, ptr %14, align 8, !tbaa !9
  %48 = lshr i64 %47, 2
  %49 = icmp ult i64 %45, %48
  br i1 %49, label %50, label %56

50:                                               ; preds = %50, %42
  %51 = phi ptr [ %52, %50 ], [ %3, %42 ]
  %52 = getelementptr inbounds i8, ptr %51, i64 8
  %53 = load i64, ptr %52, align 8, !tbaa !9
  %54 = add i64 %53, -1
  store i64 %54, ptr %52, align 8, !tbaa !9
  %55 = icmp eq i64 %53, 0
  br i1 %55, label %50, label %56, !llvm.loop !206

56:                                               ; preds = %50, %42
  %57 = getelementptr inbounds i8, ptr %14, i64 8
  %58 = add nsw i64 %5, -1
  %59 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %57, i64 noundef %58, i32 noundef 62) #15
  %60 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %3, ptr noundef nonnull %3, ptr noundef %7, i64 noundef %58) #15
  %61 = getelementptr inbounds i64, ptr %3, i64 %5
  %62 = getelementptr inbounds i8, ptr %61, i64 -8
  %63 = add i64 %60, %59
  %64 = load i64, ptr %62, align 8, !tbaa !9
  %65 = sub i64 %64, %63
  store i64 %65, ptr %62, align 8, !tbaa !9
  %66 = icmp ult i64 %64, %63
  br i1 %66, label %67, label %73

67:                                               ; preds = %67, %56
  %68 = phi ptr [ %69, %67 ], [ %62, %56 ]
  %69 = getelementptr inbounds i8, ptr %68, i64 8
  %70 = load i64, ptr %69, align 8, !tbaa !9
  %71 = add i64 %70, -1
  store i64 %71, ptr %69, align 8, !tbaa !9
  %72 = icmp eq i64 %70, 0
  br i1 %72, label %67, label %73, !llvm.loop !207

73:                                               ; preds = %67, %56
  %74 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %14, i64 noundef %5, i32 noundef 20) #15
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %7, i64 noundef %5) #15
  %76 = getelementptr inbounds i64, ptr %1, i64 %5
  %77 = add i64 %75, %74
  %78 = load i64, ptr %76, align 8, !tbaa !9
  %79 = sub i64 %78, %77
  store i64 %79, ptr %76, align 8, !tbaa !9
  %80 = icmp ult i64 %78, %77
  br i1 %80, label %81, label %87

81:                                               ; preds = %81, %73
  %82 = phi ptr [ %83, %81 ], [ %76, %73 ]
  %83 = getelementptr inbounds i8, ptr %82, i64 8
  %84 = load i64, ptr %83, align 8, !tbaa !9
  %85 = add i64 %84, -1
  store i64 %85, ptr %83, align 8, !tbaa !9
  %86 = icmp eq i64 %84, 0
  br i1 %86, label %81, label %87, !llvm.loop !208

87:                                               ; preds = %81, %73
  %88 = getelementptr inbounds i64, ptr %0, i64 %9
  %89 = load i64, ptr %14, align 8, !tbaa !9
  %90 = lshr i64 %89, 4
  %91 = load i64, ptr %88, align 8, !tbaa !9
  %92 = sub i64 %91, %90
  store i64 %92, ptr %88, align 8, !tbaa !9
  %93 = load i64, ptr %14, align 8, !tbaa !9
  %94 = lshr i64 %93, 4
  %95 = icmp ult i64 %91, %94
  br i1 %95, label %96, label %102

96:                                               ; preds = %96, %87
  %97 = phi ptr [ %98, %96 ], [ %88, %87 ]
  %98 = getelementptr inbounds i8, ptr %97, i64 8
  %99 = load i64, ptr %98, align 8, !tbaa !9
  %100 = add i64 %99, -1
  store i64 %100, ptr %98, align 8, !tbaa !9
  %101 = icmp eq i64 %99, 0
  br i1 %101, label %96, label %102, !llvm.loop !209

102:                                              ; preds = %96, %87
  %103 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %57, i64 noundef %58, i32 noundef 60) #15
  %104 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %88, ptr noundef nonnull %88, ptr noundef %7, i64 noundef %58) #15
  %105 = getelementptr inbounds i64, ptr %88, i64 %5
  %106 = getelementptr inbounds i8, ptr %105, i64 -8
  %107 = add i64 %104, %103
  %108 = load i64, ptr %106, align 8, !tbaa !9
  %109 = sub i64 %108, %107
  store i64 %109, ptr %106, align 8, !tbaa !9
  %110 = icmp ult i64 %108, %107
  br i1 %110, label %111, label %117

111:                                              ; preds = %111, %102
  %112 = phi ptr [ %113, %111 ], [ %106, %102 ]
  %113 = getelementptr inbounds i8, ptr %112, i64 8
  %114 = load i64, ptr %113, align 8, !tbaa !9
  %115 = add i64 %114, -1
  store i64 %115, ptr %113, align 8, !tbaa !9
  %116 = icmp eq i64 %114, 0
  br i1 %116, label %111, label %117, !llvm.loop !210

117:                                              ; preds = %111, %102, %8
  %118 = getelementptr inbounds i64, ptr %0, i64 %9
  %119 = getelementptr inbounds i64, ptr %118, i64 %4
  %120 = shl nsw i64 %4, 1
  %121 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %0, i64 noundef %120, i32 noundef 20) #15
  %122 = tail call i64 @__gmpn_sub_n(ptr noundef %119, ptr noundef %119, ptr noundef %7, i64 noundef %120) #15
  %123 = getelementptr inbounds i64, ptr %118, i64 %9
  %124 = load i64, ptr %123, align 8, !tbaa !9
  %125 = add i64 %122, %121
  %126 = sub i64 %124, %125
  store i64 %126, ptr %123, align 8, !tbaa !9
  %127 = getelementptr inbounds i64, ptr %1, i64 %4
  %128 = load i64, ptr %0, align 8, !tbaa !9
  %129 = lshr i64 %128, 4
  %130 = load i64, ptr %127, align 8, !tbaa !9
  %131 = sub i64 %130, %129
  store i64 %131, ptr %127, align 8, !tbaa !9
  %132 = load i64, ptr %0, align 8, !tbaa !9
  %133 = lshr i64 %132, 4
  %134 = icmp ult i64 %130, %133
  br i1 %134, label %135, label %141

135:                                              ; preds = %135, %117
  %136 = phi ptr [ %137, %135 ], [ %127, %117 ]
  %137 = getelementptr inbounds i8, ptr %136, i64 8
  %138 = load i64, ptr %137, align 8, !tbaa !9
  %139 = add i64 %138, -1
  store i64 %139, ptr %137, align 8, !tbaa !9
  %140 = icmp eq i64 %138, 0
  br i1 %140, label %135, label %141, !llvm.loop !211

141:                                              ; preds = %135, %117
  %142 = getelementptr inbounds i8, ptr %0, i64 8
  %143 = add nsw i64 %120, -1
  %144 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef nonnull %142, i64 noundef %143, i32 noundef 60) #15
  %145 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %127, ptr noundef nonnull %127, ptr noundef %7, i64 noundef %143) #15
  %146 = getelementptr inbounds i64, ptr %127, i64 %120
  %147 = getelementptr inbounds i8, ptr %146, i64 -8
  %148 = add i64 %145, %144
  %149 = load i64, ptr %147, align 8, !tbaa !9
  %150 = sub i64 %149, %148
  store i64 %150, ptr %147, align 8, !tbaa !9
  %151 = icmp ult i64 %149, %148
  br i1 %151, label %152, label %158

152:                                              ; preds = %152, %141
  %153 = phi ptr [ %154, %152 ], [ %147, %141 ]
  %154 = getelementptr inbounds i8, ptr %153, i64 8
  %155 = load i64, ptr %154, align 8, !tbaa !9
  %156 = add i64 %155, -1
  store i64 %156, ptr %154, align 8, !tbaa !9
  %157 = icmp eq i64 %155, 0
  br i1 %157, label %152, label %158, !llvm.loop !212

158:                                              ; preds = %152, %141
  %159 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %1, ptr noundef nonnull %118, i64 noundef %10) #15
  %160 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %118, ptr noundef nonnull %118, ptr noundef %1, i64 noundef %10) #15
  %161 = getelementptr inbounds i64, ptr %3, i64 %4
  %162 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef nonnull %0, i64 noundef %120, i32 noundef 10) #15
  %163 = tail call i64 @__gmpn_sub_n(ptr noundef %161, ptr noundef %161, ptr noundef %1, i64 noundef %120) #15
  %164 = getelementptr inbounds i64, ptr %3, i64 %9
  %165 = load i64, ptr %164, align 8, !tbaa !9
  %166 = add i64 %163, %162
  %167 = sub i64 %165, %166
  store i64 %167, ptr %164, align 8, !tbaa !9
  %168 = mul i64 %4, 56
  %169 = getelementptr inbounds i8, ptr %0, i64 %168
  %170 = getelementptr inbounds i64, ptr %169, i64 %4
  %171 = load i64, ptr %0, align 8, !tbaa !9
  %172 = lshr i64 %171, 2
  %173 = load i64, ptr %170, align 8, !tbaa !9
  %174 = sub i64 %173, %172
  store i64 %174, ptr %170, align 8, !tbaa !9
  %175 = load i64, ptr %0, align 8, !tbaa !9
  %176 = lshr i64 %175, 2
  %177 = icmp ult i64 %173, %176
  br i1 %177, label %178, label %184

178:                                              ; preds = %178, %158
  %179 = phi ptr [ %180, %178 ], [ %170, %158 ]
  %180 = getelementptr inbounds i8, ptr %179, i64 8
  %181 = load i64, ptr %180, align 8, !tbaa !9
  %182 = add i64 %181, -1
  store i64 %182, ptr %180, align 8, !tbaa !9
  %183 = icmp eq i64 %181, 0
  br i1 %183, label %178, label %184, !llvm.loop !213

184:                                              ; preds = %178, %158
  %185 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef nonnull %142, i64 noundef %143, i32 noundef 62) #15
  %186 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %170, ptr noundef nonnull %170, ptr noundef %1, i64 noundef %143) #15
  %187 = getelementptr inbounds i64, ptr %170, i64 %120
  %188 = getelementptr inbounds i8, ptr %187, i64 -8
  %189 = add i64 %186, %185
  %190 = load i64, ptr %188, align 8, !tbaa !9
  %191 = sub i64 %190, %189
  store i64 %191, ptr %188, align 8, !tbaa !9
  %192 = icmp ult i64 %190, %189
  br i1 %192, label %193, label %199

193:                                              ; preds = %193, %184
  %194 = phi ptr [ %195, %193 ], [ %188, %184 ]
  %195 = getelementptr inbounds i8, ptr %194, i64 8
  %196 = load i64, ptr %195, align 8, !tbaa !9
  %197 = add i64 %196, -1
  store i64 %197, ptr %195, align 8, !tbaa !9
  %198 = icmp eq i64 %196, 0
  br i1 %198, label %193, label %199, !llvm.loop !214

199:                                              ; preds = %193, %184
  %200 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %3, ptr noundef nonnull %169, i64 noundef %10) #15
  %201 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef %3, i64 noundef %10) #15
  %202 = getelementptr inbounds i64, ptr %2, i64 %4
  %203 = tail call i64 @__gmpn_sub_n(ptr noundef %202, ptr noundef %202, ptr noundef nonnull %0, i64 noundef %120) #15
  %204 = getelementptr inbounds i64, ptr %2, i64 %9
  %205 = load i64, ptr %204, align 8, !tbaa !9
  %206 = sub i64 %205, %203
  store i64 %206, ptr %204, align 8, !tbaa !9
  %207 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %118, ptr noundef %1, i64 noundef %10, i64 noundef 257) #15
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %118, ptr noundef nonnull %118, i64 noundef %10, i64 noundef 11340) #15
  %208 = load i64, ptr %123, align 8, !tbaa !9
  %209 = icmp ult i64 %208, 2305843009213693952
  br i1 %209, label %212, label %210

210:                                              ; preds = %199
  %211 = or i64 %208, -4611686018427387904
  store i64 %211, ptr %123, align 8, !tbaa !9
  br label %212

212:                                              ; preds = %210, %199
  %213 = tail call i64 @__gmpn_addmul_1(ptr noundef %1, ptr noundef nonnull %118, i64 noundef %10, i64 noundef 60) #15
  %214 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %1, ptr noundef %1, i64 noundef %10, i64 noundef 72340172838076673, i64 noundef 0) #15
  %215 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %2, i64 noundef %10, i32 noundef 5) #15
  %216 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef %3, i64 noundef %10) #15
  %217 = tail call i64 @__gmpn_submul_1(ptr noundef %7, ptr noundef nonnull %169, i64 noundef %10, i64 noundef 100) #15
  %218 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %2, i64 noundef %10, i32 noundef 9) #15
  %219 = tail call i64 @__gmpn_sub_n(ptr noundef %7, ptr noundef %7, ptr noundef %3, i64 noundef %10) #15
  tail call void @__gmpn_divexact_1(ptr noundef %7, ptr noundef %7, i64 noundef %10, i64 noundef 42525) #15
  %220 = tail call i64 @__gmpn_submul_1(ptr noundef nonnull %169, ptr noundef %7, i64 noundef %10, i64 noundef 225) #15
  tail call void @__gmpn_divexact_1(ptr noundef nonnull %169, ptr noundef nonnull %169, i64 noundef %10, i64 noundef 36) #15
  %221 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef nonnull %169, i64 noundef %10) #15
  %222 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %118, ptr noundef nonnull %169, ptr noundef nonnull %118, i64 noundef %10) #15
  %223 = tail call i64 @__gmpn_rshift(ptr noundef nonnull %118, ptr noundef nonnull %118, i64 noundef %10, i32 noundef 1) #15
  %224 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef nonnull %118, i64 noundef %10) #15
  %225 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %7, i64 noundef %10) #15
  %226 = tail call i64 @__gmpn_rshift(ptr noundef %1, ptr noundef %1, i64 noundef %10, i32 noundef 1) #15
  %227 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %7, i64 noundef %10) #15
  %228 = tail call i64 @__gmpn_sub_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %10) #15
  %229 = getelementptr inbounds i64, ptr %0, i64 %4
  %230 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %229, ptr noundef nonnull %229, ptr noundef %1, i64 noundef %4) #15
  %231 = getelementptr inbounds i64, ptr %0, i64 %120
  %232 = load i64, ptr %127, align 8, !tbaa !9
  %233 = add i64 %232, %230
  store i64 %233, ptr %231, align 8, !tbaa !9
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
  %242 = load i64, ptr %241, align 8, !tbaa !9
  %243 = add i64 %242, 1
  %244 = getelementptr inbounds i64, ptr %231, i64 %238
  store i64 %243, ptr %244, align 8, !tbaa !9
  %245 = add nuw i64 %238, 1
  %246 = icmp eq i64 %243, 0
  br i1 %246, label %237, label %247, !llvm.loop !215

247:                                              ; preds = %240
  %248 = icmp ne ptr %127, %231
  %249 = icmp slt i64 %245, %4
  %250 = select i1 %248, i1 %249, i1 false
  br i1 %250, label %251, label %269

251:                                              ; preds = %251, %247
  %252 = phi i64 [ %256, %251 ], [ %245, %247 ]
  %253 = getelementptr inbounds i64, ptr %127, i64 %252
  %254 = load i64, ptr %253, align 8, !tbaa !9
  %255 = getelementptr inbounds i64, ptr %231, i64 %252
  store i64 %254, ptr %255, align 8, !tbaa !9
  %256 = add nuw nsw i64 %252, 1
  %257 = icmp slt i64 %256, %4
  br i1 %257, label %251, label %269, !llvm.loop !216

258:                                              ; preds = %212
  %259 = icmp ne ptr %127, %231
  %260 = icmp sgt i64 %4, 1
  %261 = and i1 %260, %259
  br i1 %261, label %262, label %269

262:                                              ; preds = %262, %258
  %263 = phi i64 [ %267, %262 ], [ 1, %258 ]
  %264 = getelementptr inbounds i64, ptr %127, i64 %263
  %265 = load i64, ptr %264, align 8, !tbaa !9
  %266 = getelementptr inbounds i64, ptr %231, i64 %263
  store i64 %265, ptr %266, align 8, !tbaa !9
  %267 = add nuw nsw i64 %263, 1
  %268 = icmp eq i64 %267, %4
  br i1 %268, label %269, label %262, !llvm.loop !217

269:                                              ; preds = %262, %258, %251, %247, %237
  %270 = phi i64 [ 0, %247 ], [ 0, %258 ], [ 0, %251 ], [ 1, %237 ], [ 0, %262 ]
  %271 = getelementptr inbounds i64, ptr %1, i64 %120
  %272 = load i64, ptr %271, align 8, !tbaa !9
  %273 = add i64 %272, %270
  store i64 %273, ptr %271, align 8, !tbaa !9
  %274 = icmp ult i64 %273, %270
  br i1 %274, label %275, label %281

275:                                              ; preds = %275, %269
  %276 = phi ptr [ %277, %275 ], [ %271, %269 ]
  %277 = getelementptr inbounds i8, ptr %276, i64 8
  %278 = load i64, ptr %277, align 8, !tbaa !9
  %279 = add i64 %278, 1
  store i64 %279, ptr %277, align 8, !tbaa !9
  %280 = icmp eq i64 %279, 0
  br i1 %280, label %275, label %281, !llvm.loop !218

281:                                              ; preds = %275, %269
  %282 = getelementptr inbounds i64, ptr %1, i64 %9
  %283 = load i64, ptr %282, align 8, !tbaa !9
  %284 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %118, ptr noundef nonnull %118, ptr noundef nonnull %271, i64 noundef %4) #15
  %285 = add i64 %284, %283
  %286 = load i64, ptr %119, align 8, !tbaa !9
  %287 = add i64 %286, %285
  store i64 %287, ptr %119, align 8, !tbaa !9
  %288 = icmp ult i64 %287, %285
  br i1 %288, label %289, label %295

289:                                              ; preds = %289, %281
  %290 = phi ptr [ %291, %289 ], [ %119, %281 ]
  %291 = getelementptr inbounds i8, ptr %290, i64 8
  %292 = load i64, ptr %291, align 8, !tbaa !9
  %293 = add i64 %292, 1
  store i64 %293, ptr %291, align 8, !tbaa !9
  %294 = icmp eq i64 %293, 0
  br i1 %294, label %289, label %295, !llvm.loop !219

295:                                              ; preds = %289, %281
  %296 = mul i64 %4, 40
  %297 = getelementptr inbounds i8, ptr %0, i64 %296
  %298 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %297, ptr noundef nonnull %297, ptr noundef %2, i64 noundef %4) #15
  %299 = mul i64 %4, 48
  %300 = getelementptr inbounds i8, ptr %0, i64 %299
  %301 = load i64, ptr %300, align 8, !tbaa !9
  %302 = add i64 %301, %298
  store i64 %302, ptr %300, align 8, !tbaa !9
  %303 = load i64, ptr %202, align 8, !tbaa !9
  %304 = add i64 %303, %302
  store i64 %304, ptr %300, align 8, !tbaa !9
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
  %313 = load i64, ptr %312, align 8, !tbaa !9
  %314 = add i64 %313, 1
  %315 = getelementptr inbounds i64, ptr %300, i64 %309
  store i64 %314, ptr %315, align 8, !tbaa !9
  %316 = add nuw i64 %309, 1
  %317 = icmp eq i64 %314, 0
  br i1 %317, label %308, label %318, !llvm.loop !215

318:                                              ; preds = %311
  %319 = icmp ne ptr %202, %300
  %320 = icmp slt i64 %316, %4
  %321 = select i1 %319, i1 %320, i1 false
  br i1 %321, label %322, label %340

322:                                              ; preds = %322, %318
  %323 = phi i64 [ %327, %322 ], [ %316, %318 ]
  %324 = getelementptr inbounds i64, ptr %202, i64 %323
  %325 = load i64, ptr %324, align 8, !tbaa !9
  %326 = getelementptr inbounds i64, ptr %300, i64 %323
  store i64 %325, ptr %326, align 8, !tbaa !9
  %327 = add nuw nsw i64 %323, 1
  %328 = icmp slt i64 %327, %4
  br i1 %328, label %322, label %340, !llvm.loop !216

329:                                              ; preds = %295
  %330 = icmp ne ptr %202, %300
  %331 = icmp sgt i64 %4, 1
  %332 = and i1 %331, %330
  br i1 %332, label %333, label %340

333:                                              ; preds = %333, %329
  %334 = phi i64 [ %338, %333 ], [ 1, %329 ]
  %335 = getelementptr inbounds i64, ptr %202, i64 %334
  %336 = load i64, ptr %335, align 8, !tbaa !9
  %337 = getelementptr inbounds i64, ptr %300, i64 %334
  store i64 %336, ptr %337, align 8, !tbaa !9
  %338 = add nuw nsw i64 %334, 1
  %339 = icmp eq i64 %338, %4
  br i1 %339, label %340, label %333, !llvm.loop !217

340:                                              ; preds = %333, %329, %322, %318, %308
  %341 = phi i64 [ 0, %318 ], [ 0, %329 ], [ 0, %322 ], [ 1, %308 ], [ 0, %333 ]
  %342 = getelementptr inbounds i64, ptr %2, i64 %120
  %343 = load i64, ptr %342, align 8, !tbaa !9
  %344 = add i64 %343, %341
  store i64 %344, ptr %342, align 8, !tbaa !9
  %345 = icmp ult i64 %344, %341
  br i1 %345, label %346, label %352

346:                                              ; preds = %346, %340
  %347 = phi ptr [ %348, %346 ], [ %342, %340 ]
  %348 = getelementptr inbounds i8, ptr %347, i64 8
  %349 = load i64, ptr %348, align 8, !tbaa !9
  %350 = add i64 %349, 1
  store i64 %350, ptr %348, align 8, !tbaa !9
  %351 = icmp eq i64 %350, 0
  br i1 %351, label %346, label %352, !llvm.loop !220

352:                                              ; preds = %346, %340
  %353 = load i64, ptr %204, align 8, !tbaa !9
  %354 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %169, ptr noundef nonnull %169, ptr noundef nonnull %342, i64 noundef %4) #15
  %355 = shl nsw i64 %4, 6
  %356 = getelementptr inbounds i8, ptr %0, i64 %355
  %357 = add i64 %354, %353
  %358 = load i64, ptr %356, align 8, !tbaa !9
  %359 = add i64 %358, %357
  store i64 %359, ptr %356, align 8, !tbaa !9
  %360 = icmp ult i64 %359, %357
  br i1 %360, label %361, label %367

361:                                              ; preds = %361, %352
  %362 = phi ptr [ %363, %361 ], [ %356, %352 ]
  %363 = getelementptr inbounds i8, ptr %362, i64 8
  %364 = load i64, ptr %363, align 8, !tbaa !9
  %365 = add i64 %364, 1
  store i64 %365, ptr %363, align 8, !tbaa !9
  %366 = icmp eq i64 %365, 0
  br i1 %366, label %361, label %367, !llvm.loop !221

367:                                              ; preds = %361, %352
  %368 = mul i64 %4, 72
  %369 = getelementptr inbounds i8, ptr %0, i64 %368
  %370 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %369, ptr noundef nonnull %369, ptr noundef %7, i64 noundef %4) #15
  %371 = mul i64 %4, 80
  %372 = getelementptr inbounds i8, ptr %0, i64 %371
  %373 = load i64, ptr %372, align 8, !tbaa !9
  %374 = add i64 %373, %370
  store i64 %374, ptr %372, align 8, !tbaa !9
  %375 = getelementptr inbounds i64, ptr %7, i64 %4
  %376 = load i64, ptr %375, align 8, !tbaa !9
  %377 = add i64 %376, %374
  store i64 %377, ptr %372, align 8, !tbaa !9
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
  %387 = load i64, ptr %386, align 8, !tbaa !9
  %388 = add i64 %387, 1
  %389 = getelementptr inbounds i64, ptr %372, i64 %383
  store i64 %388, ptr %389, align 8, !tbaa !9
  %390 = add nuw i64 %383, 1
  %391 = icmp eq i64 %388, 0
  br i1 %391, label %382, label %392, !llvm.loop !215

392:                                              ; preds = %385
  %393 = icmp ne ptr %375, %372
  %394 = icmp slt i64 %390, %4
  %395 = select i1 %393, i1 %394, i1 false
  br i1 %395, label %396, label %414

396:                                              ; preds = %396, %392
  %397 = phi i64 [ %401, %396 ], [ %390, %392 ]
  %398 = getelementptr inbounds i64, ptr %375, i64 %397
  %399 = load i64, ptr %398, align 8, !tbaa !9
  %400 = getelementptr inbounds i64, ptr %372, i64 %397
  store i64 %399, ptr %400, align 8, !tbaa !9
  %401 = add nuw nsw i64 %397, 1
  %402 = icmp slt i64 %401, %4
  br i1 %402, label %396, label %414, !llvm.loop !216

403:                                              ; preds = %379
  %404 = icmp ne ptr %375, %372
  %405 = icmp sgt i64 %4, 1
  %406 = and i1 %405, %404
  br i1 %406, label %407, label %414

407:                                              ; preds = %407, %403
  %408 = phi i64 [ %412, %407 ], [ 1, %403 ]
  %409 = getelementptr inbounds i64, ptr %375, i64 %408
  %410 = load i64, ptr %409, align 8, !tbaa !9
  %411 = getelementptr inbounds i64, ptr %372, i64 %408
  store i64 %410, ptr %411, align 8, !tbaa !9
  %412 = add nuw nsw i64 %408, 1
  %413 = icmp eq i64 %412, %4
  br i1 %413, label %414, label %407, !llvm.loop !217

414:                                              ; preds = %407, %403, %396, %392, %382
  %415 = phi i64 [ 0, %392 ], [ 0, %403 ], [ 0, %396 ], [ 1, %382 ], [ 0, %407 ]
  %416 = getelementptr inbounds i64, ptr %7, i64 %120
  %417 = load i64, ptr %416, align 8, !tbaa !9
  %418 = add i64 %417, %415
  store i64 %418, ptr %416, align 8, !tbaa !9
  %419 = icmp ult i64 %418, %415
  br i1 %419, label %420, label %426

420:                                              ; preds = %420, %414
  %421 = phi ptr [ %422, %420 ], [ %416, %414 ]
  %422 = getelementptr inbounds i8, ptr %421, i64 8
  %423 = load i64, ptr %422, align 8, !tbaa !9
  %424 = add i64 %423, 1
  store i64 %424, ptr %422, align 8, !tbaa !9
  %425 = icmp eq i64 %424, 0
  br i1 %425, label %420, label %426, !llvm.loop !222

426:                                              ; preds = %420, %414
  %427 = icmp sgt i64 %5, %4
  br i1 %427, label %428, label %446, !prof !30

428:                                              ; preds = %426
  %429 = getelementptr inbounds i64, ptr %7, i64 %9
  %430 = load i64, ptr %429, align 8, !tbaa !9
  %431 = mul i64 %4, 88
  %432 = getelementptr inbounds i8, ptr %0, i64 %431
  %433 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %432, ptr noundef nonnull %432, ptr noundef nonnull %416, i64 noundef %4) #15
  %434 = mul i64 %4, 96
  %435 = getelementptr inbounds i8, ptr %0, i64 %434
  %436 = add i64 %433, %430
  %437 = load i64, ptr %435, align 8, !tbaa !9
  %438 = add i64 %437, %436
  store i64 %438, ptr %435, align 8, !tbaa !9
  %439 = icmp ult i64 %438, %436
  br i1 %439, label %440, label %485

440:                                              ; preds = %440, %428
  %441 = phi ptr [ %442, %440 ], [ %435, %428 ]
  %442 = getelementptr inbounds i8, ptr %441, i64 8
  %443 = load i64, ptr %442, align 8, !tbaa !9
  %444 = add i64 %443, 1
  store i64 %444, ptr %442, align 8, !tbaa !9
  %445 = icmp eq i64 %444, 0
  br i1 %445, label %440, label %485, !llvm.loop !223

446:                                              ; preds = %426
  %447 = mul i64 %4, 88
  %448 = getelementptr inbounds i8, ptr %0, i64 %447
  %449 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %448, ptr noundef nonnull %448, ptr noundef nonnull %416, i64 noundef %5) #15
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
  %458 = load i64, ptr %457, align 8, !tbaa !9
  %459 = add i64 %458, 1
  %460 = getelementptr inbounds i64, ptr %372, i64 %454
  store i64 %459, ptr %460, align 8, !tbaa !9
  %461 = add nuw i64 %454, 1
  %462 = icmp eq i64 %459, 0
  br i1 %462, label %453, label %463, !llvm.loop !215

463:                                              ; preds = %456
  %464 = icmp ne ptr %375, %372
  %465 = icmp slt i64 %461, %5
  %466 = select i1 %464, i1 %465, i1 false
  br i1 %466, label %467, label %485

467:                                              ; preds = %467, %463
  %468 = phi i64 [ %472, %467 ], [ %461, %463 ]
  %469 = getelementptr inbounds i64, ptr %375, i64 %468
  %470 = load i64, ptr %469, align 8, !tbaa !9
  %471 = getelementptr inbounds i64, ptr %372, i64 %468
  store i64 %470, ptr %471, align 8, !tbaa !9
  %472 = add nuw nsw i64 %468, 1
  %473 = icmp slt i64 %472, %5
  br i1 %473, label %467, label %485, !llvm.loop !216

474:                                              ; preds = %450
  %475 = icmp ne ptr %375, %372
  %476 = icmp sgt i64 %5, 1
  %477 = and i1 %476, %475
  br i1 %477, label %478, label %485

478:                                              ; preds = %478, %474
  %479 = phi i64 [ %483, %478 ], [ 1, %474 ]
  %480 = getelementptr inbounds i64, ptr %375, i64 %479
  %481 = load i64, ptr %480, align 8, !tbaa !9
  %482 = getelementptr inbounds i64, ptr %372, i64 %479
  store i64 %481, ptr %482, align 8, !tbaa !9
  %483 = add nuw nsw i64 %479, 1
  %484 = icmp eq i64 %483, %5
  br i1 %484, label %485, label %478, !llvm.loop !217

485:                                              ; preds = %478, %474, %467, %463, %453, %446, %440, %428
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_mul_1(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #5 {
  %5 = lshr i64 %3, 32
  %6 = and i64 %3, 4294967295
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %34, %7 ]
  %9 = phi i64 [ %2, %4 ], [ %36, %7 ]
  %10 = phi ptr [ %1, %4 ], [ %12, %7 ]
  %11 = phi ptr [ %0, %4 ], [ %35, %7 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 8
  %13 = load i64, ptr %10, align 8, !tbaa !9
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
  store i64 %31, ptr %11, align 8, !tbaa !9
  %36 = add nsw i64 %9, -1
  %37 = icmp eq i64 %36, 0
  br i1 %37, label %38, label %7, !llvm.loop !224

38:                                               ; preds = %7
  ret i64 %34
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom8h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = icmp eq i64 %2, %4
  br i1 %7, label %13, label %8, !prof !30

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
  br i1 %75, label %76, label %79, !prof !55

76:                                               ; preds = %74
  %77 = add nsw i32 %51, -2
  %78 = add nsw i64 %69, %64
  br label %84

79:                                               ; preds = %74
  %80 = icmp slt i64 %72, 1
  br i1 %80, label %81, label %84, !prof !55

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
  %97 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 3, ptr noundef %0) #15
  %98 = mul nsw i64 %85, 12
  %99 = getelementptr inbounds i64, ptr %5, i64 %98
  %100 = getelementptr inbounds i8, ptr %99, i64 32
  %101 = getelementptr inbounds i64, ptr %0, i64 %98
  %102 = getelementptr inbounds i8, ptr %101, i64 8
  %103 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 3, ptr noundef %0) #15
  %104 = xor i32 %103, %97
  %105 = add nsw i64 %85, 1
  %106 = icmp sgt i64 %85, 98
  br i1 %106, label %110, label %107

107:                                              ; preds = %84
  %108 = getelementptr inbounds i64, ptr %5, i64 %92
  %109 = getelementptr inbounds i8, ptr %108, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %109) #15
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %109) #15
  br label %121

110:                                              ; preds = %84
  %111 = icmp sgt i64 %85, 298
  br i1 %111, label %115, label %112

112:                                              ; preds = %110
  %113 = getelementptr inbounds i64, ptr %5, i64 %92
  %114 = getelementptr inbounds i8, ptr %113, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %114) #15
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %114) #15
  br label %121

115:                                              ; preds = %110
  %116 = icmp sgt i64 %85, 348
  %117 = getelementptr inbounds i64, ptr %5, i64 %92
  %118 = getelementptr inbounds i8, ptr %117, i64 40
  br i1 %116, label %120, label %119

119:                                              ; preds = %115
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %118) #15
  tail call void @__gmpn_toom44_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %118) #15
  br label %121

120:                                              ; preds = %115
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %118) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef %5, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %118) #15
  br label %121

121:                                              ; preds = %120, %119, %112, %107
  %122 = shl nsw i64 %85, 1
  %123 = or disjoint i64 %122, 1
  %124 = add nuw nsw i32 %91, 1
  %125 = mul nuw nsw i32 %124, 3
  %126 = mul nuw nsw i32 %91, 3
  tail call void @__gmpn_toom_couple_handling(ptr noundef %5, i64 noundef %123, ptr noundef %0, i32 noundef %104, i64 noundef %85, i32 noundef %125, i32 noundef %126) #15
  %127 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 2, ptr noundef %0) #15
  %128 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 2, ptr noundef %0) #15
  %129 = xor i32 %128, %127
  br i1 %106, label %136, label %130

130:                                              ; preds = %121
  %131 = getelementptr inbounds i64, ptr %5, i64 %92
  %132 = getelementptr inbounds i8, ptr %131, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %132) #15
  %133 = mul i64 %85, 24
  %134 = getelementptr inbounds i8, ptr %5, i64 %133
  %135 = getelementptr inbounds i8, ptr %134, i64 8
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %135, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %132) #15
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
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %143) #15
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %140, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %143) #15
  br label %150

144:                                              ; preds = %136
  %145 = icmp sgt i64 %85, 348
  %146 = getelementptr inbounds i64, ptr %5, i64 %92
  %147 = getelementptr inbounds i8, ptr %146, i64 40
  br i1 %145, label %149, label %148

148:                                              ; preds = %144
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %147) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %140, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %147) #15
  br label %150

149:                                              ; preds = %144
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %147) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %140, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %147) #15
  br label %150

150:                                              ; preds = %149, %148, %141, %130
  %151 = mul nsw i64 %85, 3
  %152 = getelementptr inbounds i64, ptr %5, i64 %151
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = shl nuw nsw i32 %124, 1
  %155 = shl nuw nsw i32 %91, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %153, i64 noundef %123, ptr noundef %0, i32 noundef %129, i64 noundef %85, i32 noundef %154, i32 noundef %155) #15
  %156 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, ptr noundef %0) #15
  %157 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, ptr noundef %0) #15
  %158 = xor i32 %157, %156
  br i1 %106, label %165, label %159

159:                                              ; preds = %150
  %160 = getelementptr inbounds i64, ptr %5, i64 %92
  %161 = getelementptr inbounds i8, ptr %160, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %161) #15
  %162 = mul i64 %85, 48
  %163 = getelementptr inbounds i8, ptr %5, i64 %162
  %164 = getelementptr inbounds i8, ptr %163, i64 16
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %164, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %161) #15
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
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %172) #15
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %169, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %172) #15
  br label %179

173:                                              ; preds = %165
  %174 = icmp sgt i64 %85, 348
  %175 = getelementptr inbounds i64, ptr %5, i64 %92
  %176 = getelementptr inbounds i8, ptr %175, i64 40
  br i1 %174, label %178, label %177

177:                                              ; preds = %173
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %176) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %169, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %176) #15
  br label %179

178:                                              ; preds = %173
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %176) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %169, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %176) #15
  br label %179

179:                                              ; preds = %178, %177, %170, %159
  %180 = mul i64 %85, 48
  %181 = getelementptr inbounds i8, ptr %5, i64 %180
  %182 = getelementptr inbounds i8, ptr %181, i64 16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %182, i64 noundef %123, ptr noundef %0, i32 noundef %158, i64 noundef %85, i32 noundef 1, i32 noundef 2) #15
  %183 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 3, ptr noundef %0) #15
  %184 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 3, ptr noundef %0) #15
  %185 = xor i32 %184, %183
  br i1 %106, label %192, label %186

186:                                              ; preds = %179
  %187 = getelementptr inbounds i64, ptr %5, i64 %92
  %188 = getelementptr inbounds i8, ptr %187, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %188) #15
  %189 = mul i64 %85, 72
  %190 = getelementptr inbounds i8, ptr %5, i64 %189
  %191 = getelementptr inbounds i8, ptr %190, i64 24
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %191, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %188) #15
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
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %199) #15
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %196, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %199) #15
  br label %206

200:                                              ; preds = %192
  %201 = icmp sgt i64 %85, 348
  %202 = getelementptr inbounds i64, ptr %5, i64 %92
  %203 = getelementptr inbounds i8, ptr %202, i64 40
  br i1 %201, label %205, label %204

204:                                              ; preds = %200
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %203) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %196, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %203) #15
  br label %206

205:                                              ; preds = %200
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %203) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %196, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %203) #15
  br label %206

206:                                              ; preds = %205, %204, %197, %186
  %207 = mul i64 %85, 72
  %208 = getelementptr inbounds i8, ptr %5, i64 %207
  %209 = getelementptr inbounds i8, ptr %208, i64 24
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %209, i64 noundef %123, ptr noundef %0, i32 noundef %185, i64 noundef %85, i32 noundef 3, i32 noundef 6) #15
  %210 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 1, ptr noundef %0) #15
  %211 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 1, ptr noundef %0) #15
  %212 = xor i32 %211, %210
  br i1 %106, label %217, label %213

213:                                              ; preds = %206
  %214 = getelementptr inbounds i64, ptr %5, i64 %92
  %215 = getelementptr inbounds i8, ptr %214, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %215) #15
  %216 = getelementptr inbounds i64, ptr %0, i64 %151
  tail call void @__gmpn_toom22_mul(ptr noundef %216, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %215) #15
  br label %229

217:                                              ; preds = %206
  %218 = icmp sgt i64 %85, 298
  %219 = getelementptr inbounds i64, ptr %0, i64 %151
  br i1 %218, label %223, label %220

220:                                              ; preds = %217
  %221 = getelementptr inbounds i64, ptr %5, i64 %92
  %222 = getelementptr inbounds i8, ptr %221, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %222) #15
  tail call void @__gmpn_toom33_mul(ptr noundef %219, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %222) #15
  br label %229

223:                                              ; preds = %217
  %224 = icmp sgt i64 %85, 348
  %225 = getelementptr inbounds i64, ptr %5, i64 %92
  %226 = getelementptr inbounds i8, ptr %225, i64 40
  br i1 %224, label %228, label %227

227:                                              ; preds = %223
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %226) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %219, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %226) #15
  br label %229

228:                                              ; preds = %223
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %226) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %219, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %226) #15
  br label %229

229:                                              ; preds = %228, %227, %220, %213
  %230 = getelementptr inbounds i64, ptr %0, i64 %151
  tail call void @__gmpn_toom_couple_handling(ptr noundef %230, i64 noundef %123, ptr noundef %0, i32 noundef %212, i64 noundef %85, i32 noundef %124, i32 noundef %91) #15
  %231 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, ptr noundef %0) #15
  %232 = icmp eq i32 %89, 3
  br i1 %232, label %233, label %235, !prof !55

233:                                              ; preds = %229
  %234 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %100, ptr noundef nonnull %102, ptr noundef %3, i64 noundef %85, i64 noundef %87, ptr noundef %0) #15
  br label %237

235:                                              ; preds = %229
  %236 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, ptr noundef %0) #15
  br label %237

237:                                              ; preds = %235, %233
  %238 = phi i32 [ %234, %233 ], [ %236, %235 ]
  %239 = xor i32 %238, %231
  br i1 %106, label %245, label %240

240:                                              ; preds = %237
  %241 = getelementptr inbounds i64, ptr %5, i64 %92
  %242 = getelementptr inbounds i8, ptr %241, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %242) #15
  %243 = mul i64 %85, 56
  %244 = getelementptr inbounds i8, ptr %0, i64 %243
  tail call void @__gmpn_toom22_mul(ptr noundef %244, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %242) #15
  br label %258

245:                                              ; preds = %237
  %246 = icmp sgt i64 %85, 298
  %247 = mul i64 %85, 56
  %248 = getelementptr inbounds i8, ptr %0, i64 %247
  br i1 %246, label %252, label %249

249:                                              ; preds = %245
  %250 = getelementptr inbounds i64, ptr %5, i64 %92
  %251 = getelementptr inbounds i8, ptr %250, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %251) #15
  tail call void @__gmpn_toom33_mul(ptr noundef %248, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %251) #15
  br label %258

252:                                              ; preds = %245
  %253 = icmp sgt i64 %85, 348
  %254 = getelementptr inbounds i64, ptr %5, i64 %92
  %255 = getelementptr inbounds i8, ptr %254, i64 40
  br i1 %253, label %257, label %256

256:                                              ; preds = %252
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %255) #15
  tail call void @__gmpn_toom44_mul(ptr noundef %248, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %255) #15
  br label %258

257:                                              ; preds = %252
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %255) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef %248, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %255) #15
  br label %258

258:                                              ; preds = %257, %256, %249, %240
  %259 = mul i64 %85, 56
  %260 = getelementptr inbounds i8, ptr %0, i64 %259
  tail call void @__gmpn_toom_couple_handling(ptr noundef %260, i64 noundef %123, ptr noundef %0, i32 noundef %239, i64 noundef %85, i32 noundef 0, i32 noundef 0) #15
  %261 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %94, ptr noundef %96, i32 noundef %88, ptr noundef %1, i64 noundef %85, i64 noundef %86, i32 noundef 2, ptr noundef %0) #15
  %262 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %100, ptr noundef nonnull %102, i32 noundef %89, ptr noundef %3, i64 noundef %85, i64 noundef %87, i32 noundef 2, ptr noundef %0) #15
  %263 = xor i32 %262, %261
  br i1 %106, label %267, label %264

264:                                              ; preds = %258
  %265 = getelementptr inbounds i64, ptr %5, i64 %92
  %266 = getelementptr inbounds i8, ptr %265, i64 40
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %266) #15
  tail call void @__gmpn_toom22_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %266) #15
  br label %278

267:                                              ; preds = %258
  %268 = icmp sgt i64 %85, 298
  br i1 %268, label %272, label %269

269:                                              ; preds = %267
  %270 = getelementptr inbounds i64, ptr %5, i64 %92
  %271 = getelementptr inbounds i8, ptr %270, i64 40
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %271) #15
  tail call void @__gmpn_toom33_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %271) #15
  br label %278

272:                                              ; preds = %267
  %273 = icmp sgt i64 %85, 348
  %274 = getelementptr inbounds i64, ptr %5, i64 %92
  %275 = getelementptr inbounds i8, ptr %274, i64 40
  br i1 %273, label %277, label %276

276:                                              ; preds = %272
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %275) #15
  tail call void @__gmpn_toom44_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %275) #15
  br label %278

277:                                              ; preds = %272
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %96, i64 noundef %105, ptr noundef nonnull %102, i64 noundef %105, ptr noundef nonnull %275) #15
  tail call void @__gmpn_toom6h_mul(ptr noundef %96, ptr noundef nonnull %94, i64 noundef %105, ptr noundef nonnull %100, i64 noundef %105, ptr noundef nonnull %275) #15
  br label %278

278:                                              ; preds = %277, %276, %269, %264
  tail call void @__gmpn_toom_couple_handling(ptr noundef %96, i64 noundef %123, ptr noundef %0, i32 noundef %263, i64 noundef %85, i32 noundef 2, i32 noundef 4) #15
  %279 = icmp sgt i64 %85, 99
  br i1 %279, label %281, label %280

280:                                              ; preds = %278
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #15
  br label %288

281:                                              ; preds = %278
  %282 = icmp sgt i64 %85, 299
  br i1 %282, label %284, label %283

283:                                              ; preds = %281
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #15
  br label %288

284:                                              ; preds = %281
  %285 = icmp sgt i64 %85, 349
  br i1 %285, label %287, label %286

286:                                              ; preds = %284
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #15
  br label %288

287:                                              ; preds = %284
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %85, ptr noundef %3, i64 noundef %85, ptr noundef nonnull %100) #15
  br label %288

288:                                              ; preds = %287, %286, %283, %280
  br i1 %90, label %309, label %289, !prof !30

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
  %300 = tail call i64 @__gmpn_mul(ptr noundef %292, ptr noundef %296, i64 noundef %86, ptr noundef %299, i64 noundef %87) #15
  br label %309

301:                                              ; preds = %289
  %302 = zext nneg i32 %89 to i64
  %303 = mul nsw i64 %85, %302
  %304 = getelementptr inbounds i64, ptr %3, i64 %303
  %305 = zext nneg i32 %88 to i64
  %306 = mul nsw i64 %85, %305
  %307 = getelementptr inbounds i64, ptr %1, i64 %306
  %308 = tail call i64 @__gmpn_mul(ptr noundef %292, ptr noundef %304, i64 noundef %87, ptr noundef %307, i64 noundef %86) #15
  br label %309

309:                                              ; preds = %301, %293, %288
  %310 = add nsw i64 %87, %86
  tail call void @__gmpn_toom_interpolate_16pts(ptr noundef %0, ptr noundef nonnull %209, ptr noundef nonnull %182, ptr noundef nonnull %153, ptr noundef %5, i64 noundef %85, i64 noundef %310, i32 noundef %91, ptr noundef nonnull %100) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #3 {
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
  %19 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %1, ptr noundef %16, i64 noundef %8) #15
  %20 = icmp eq i64 %19, 0
  br i1 %20, label %31, label %21

21:                                               ; preds = %24, %18
  %22 = phi i64 [ %28, %24 ], [ %8, %18 ]
  %23 = icmp slt i64 %22, %6
  br i1 %23, label %24, label %43

24:                                               ; preds = %21
  %25 = getelementptr inbounds i64, ptr %1, i64 %22
  %26 = load i64, ptr %25, align 8, !tbaa !9
  %27 = add i64 %26, 1
  %28 = add nsw i64 %22, 1
  %29 = getelementptr inbounds i64, ptr %3, i64 %22
  store i64 %27, ptr %29, align 8, !tbaa !9
  %30 = icmp eq i64 %27, 0
  br i1 %30, label %21, label %31, !llvm.loop !225

31:                                               ; preds = %24, %18, %4
  %32 = phi i64 [ %8, %18 ], [ 0, %4 ], [ %28, %24 ]
  %33 = icmp ne ptr %3, %1
  %34 = icmp slt i64 %32, %6
  %35 = select i1 %33, i1 %34, i1 false
  br i1 %35, label %36, label %43

36:                                               ; preds = %36, %31
  %37 = phi i64 [ %41, %36 ], [ %32, %31 ]
  %38 = getelementptr inbounds i64, ptr %1, i64 %37
  %39 = load i64, ptr %38, align 8, !tbaa !9
  %40 = getelementptr inbounds i64, ptr %3, i64 %37
  store i64 %39, ptr %40, align 8, !tbaa !9
  %41 = add nsw i64 %37, 1
  %42 = icmp eq i64 %41, %6
  br i1 %42, label %43, label %36, !llvm.loop !226

43:                                               ; preds = %36, %31, %21
  %44 = phi i1 [ true, %31 ], [ true, %36 ], [ false, %21 ]
  %45 = phi i64 [ 0, %31 ], [ 0, %36 ], [ 1, %21 ]
  %46 = getelementptr inbounds i64, ptr %1, i64 %6
  %47 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %11, ptr noundef %3, ptr noundef %46, i64 noundef %6) #15
  %48 = add i64 %47, %45
  %49 = getelementptr inbounds i64, ptr %11, i64 %6
  store i64 %48, ptr %49, align 8, !tbaa !9
  br i1 %44, label %50, label %68

50:                                               ; preds = %53, %43
  %51 = phi i64 [ %54, %53 ], [ %6, %43 ]
  %52 = icmp sgt i64 %51, 0
  br i1 %52, label %53, label %63

53:                                               ; preds = %50
  %54 = add nsw i64 %51, -1
  %55 = getelementptr inbounds i64, ptr %3, i64 %54
  %56 = load i64, ptr %55, align 8, !tbaa !9
  %57 = getelementptr inbounds i64, ptr %46, i64 %54
  %58 = load i64, ptr %57, align 8, !tbaa !9
  %59 = icmp eq i64 %56, %58
  br i1 %59, label %50, label %60, !llvm.loop !227

60:                                               ; preds = %53
  %61 = icmp ugt i64 %56, %58
  %62 = select i1 %61, i32 1, i32 -1
  br label %63

63:                                               ; preds = %60, %50
  %64 = phi i32 [ %62, %60 ], [ 0, %50 ]
  %65 = icmp slt i32 %64, 0
  br i1 %65, label %66, label %68

66:                                               ; preds = %63
  %67 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %13, ptr noundef %46, ptr noundef %3, i64 noundef %6) #15
  br label %71

68:                                               ; preds = %63, %43
  %69 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %13, ptr noundef %3, ptr noundef %46, i64 noundef %6) #15
  %70 = sub i64 %45, %69
  br label %71

71:                                               ; preds = %68, %66
  %72 = phi i64 [ %70, %68 ], [ 0, %66 ]
  %73 = getelementptr inbounds i64, ptr %13, i64 %6
  store i64 %72, ptr %73, align 8, !tbaa !9
  %74 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %15, ptr noundef %16, ptr noundef nonnull %11, i64 noundef %8) #15
  %75 = icmp eq i64 %8, %6
  br i1 %75, label %117, label %76

76:                                               ; preds = %71
  %77 = getelementptr inbounds i64, ptr %15, i64 %8
  %78 = getelementptr inbounds i64, ptr %11, i64 %8
  %79 = sub nsw i64 %6, %8
  %80 = load i64, ptr %78, align 8, !tbaa !9
  %81 = add i64 %80, %74
  store i64 %81, ptr %77, align 8, !tbaa !9
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
  %90 = load i64, ptr %89, align 8, !tbaa !9
  %91 = add i64 %90, 1
  %92 = getelementptr inbounds i64, ptr %77, i64 %86
  store i64 %91, ptr %92, align 8, !tbaa !9
  %93 = add nuw i64 %86, 1
  %94 = icmp eq i64 %91, 0
  br i1 %94, label %85, label %95, !llvm.loop !228

95:                                               ; preds = %88
  %96 = icmp ne ptr %11, %15
  %97 = icmp slt i64 %93, %79
  %98 = select i1 %96, i1 %97, i1 false
  br i1 %98, label %99, label %117

99:                                               ; preds = %99, %95
  %100 = phi i64 [ %104, %99 ], [ %93, %95 ]
  %101 = getelementptr inbounds i64, ptr %78, i64 %100
  %102 = load i64, ptr %101, align 8, !tbaa !9
  %103 = getelementptr inbounds i64, ptr %77, i64 %100
  store i64 %102, ptr %103, align 8, !tbaa !9
  %104 = add nuw nsw i64 %100, 1
  %105 = icmp slt i64 %104, %79
  br i1 %105, label %99, label %117, !llvm.loop !229

106:                                              ; preds = %76
  %107 = icmp ne ptr %11, %15
  %108 = icmp sgt i64 %79, 1
  %109 = and i1 %107, %108
  br i1 %109, label %110, label %117

110:                                              ; preds = %110, %106
  %111 = phi i64 [ %115, %110 ], [ 1, %106 ]
  %112 = getelementptr inbounds i64, ptr %78, i64 %111
  %113 = load i64, ptr %112, align 8, !tbaa !9
  %114 = getelementptr inbounds i64, ptr %77, i64 %111
  store i64 %113, ptr %114, align 8, !tbaa !9
  %115 = add nuw nsw i64 %111, 1
  %116 = icmp eq i64 %115, %79
  br i1 %116, label %117, label %110, !llvm.loop !230

117:                                              ; preds = %110, %106, %99, %95, %85, %71
  %118 = phi i64 [ %74, %71 ], [ 0, %95 ], [ 0, %106 ], [ 0, %99 ], [ 1, %85 ], [ 0, %110 ]
  %119 = load i64, ptr %49, align 8, !tbaa !9
  %120 = add i64 %119, %118
  %121 = shl i64 %120, 1
  %122 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %15, ptr noundef nonnull %15, i64 noundef %6, i32 noundef 1) #15
  %123 = add i64 %121, %122
  %124 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %15, ptr noundef nonnull %15, ptr noundef %1, i64 noundef %6) #15
  %125 = sub i64 %123, %124
  %126 = getelementptr inbounds i64, ptr %15, i64 %6
  store i64 %125, ptr %126, align 8, !tbaa !9
  store i64 0, ptr %12, align 8, !tbaa !9
  %127 = getelementptr inbounds i64, ptr %13, i64 %6
  %128 = load i64, ptr %127, align 8, !tbaa !9
  %129 = add i64 %128, %6
  %130 = icmp ugt i64 %129, 49
  br i1 %130, label %132, label %131

131:                                              ; preds = %117
  tail call void @__gmpn_sqr_basecase(ptr noundef %3, ptr noundef nonnull %13, i64 noundef %129) #15
  br label %139

132:                                              ; preds = %117
  %133 = icmp ugt i64 %129, 119
  %134 = mul i64 %6, 40
  %135 = getelementptr inbounds i8, ptr %3, i64 %134
  %136 = getelementptr inbounds i8, ptr %135, i64 40
  br i1 %133, label %138, label %137

137:                                              ; preds = %132
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef nonnull %13, i64 noundef %129, ptr noundef nonnull %136) #15
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
  tail call void @__gmpn_sqr_basecase(ptr noundef nonnull %143, ptr noundef nonnull %15, i64 noundef %140) #15
  br label %152

144:                                              ; preds = %139
  %145 = icmp ugt i64 %5, 356
  %146 = getelementptr inbounds i8, ptr %12, i64 8
  %147 = mul i64 %6, 40
  %148 = getelementptr inbounds i8, ptr %3, i64 %147
  %149 = getelementptr inbounds i8, ptr %148, i64 40
  br i1 %145, label %151, label %150

150:                                              ; preds = %144
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %146, ptr noundef nonnull %15, i64 noundef %140, ptr noundef nonnull %149) #15
  br label %152

151:                                              ; preds = %144
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %146, ptr noundef nonnull %15, i64 noundef %140, ptr noundef nonnull %149)
  br label %152

152:                                              ; preds = %151, %150, %142
  %153 = icmp sgt i64 %8, 49
  br i1 %153, label %156, label %154

154:                                              ; preds = %152
  %155 = getelementptr inbounds i64, ptr %0, i64 %9
  tail call void @__gmpn_sqr_basecase(ptr noundef %155, ptr noundef %16, i64 noundef %8) #15
  br label %164

156:                                              ; preds = %152
  %157 = icmp sgt i64 %8, 119
  %158 = getelementptr inbounds i64, ptr %0, i64 %9
  %159 = mul i64 %6, 40
  %160 = getelementptr inbounds i8, ptr %3, i64 %159
  %161 = getelementptr inbounds i8, ptr %160, i64 40
  br i1 %157, label %163, label %162

162:                                              ; preds = %156
  tail call void @__gmpn_toom2_sqr(ptr noundef %158, ptr noundef %16, i64 noundef %8, ptr noundef nonnull %161) #15
  br label %164

163:                                              ; preds = %156
  tail call void @__gmpn_toom3_sqr(ptr noundef %158, ptr noundef %16, i64 noundef %8, ptr noundef nonnull %161)
  br label %164

164:                                              ; preds = %163, %162, %154
  %165 = getelementptr inbounds i64, ptr %0, i64 %9
  %166 = load i64, ptr %165, align 8, !tbaa !9
  %167 = getelementptr inbounds i8, ptr %165, i64 8
  %168 = load i64, ptr %167, align 8, !tbaa !9
  br i1 %141, label %171, label %169

169:                                              ; preds = %164
  %170 = getelementptr inbounds i64, ptr %0, i64 %7
  tail call void @__gmpn_sqr_basecase(ptr noundef %170, ptr noundef nonnull %11, i64 noundef %140) #15
  br label %179

171:                                              ; preds = %164
  %172 = icmp ugt i64 %5, 356
  %173 = getelementptr inbounds i64, ptr %0, i64 %7
  %174 = mul i64 %6, 40
  %175 = getelementptr inbounds i8, ptr %3, i64 %174
  %176 = getelementptr inbounds i8, ptr %175, i64 40
  br i1 %172, label %178, label %177

177:                                              ; preds = %171
  tail call void @__gmpn_toom2_sqr(ptr noundef %173, ptr noundef nonnull %11, i64 noundef %140, ptr noundef nonnull %176) #15
  br label %179

178:                                              ; preds = %171
  tail call void @__gmpn_toom3_sqr(ptr noundef %173, ptr noundef nonnull %11, i64 noundef %140, ptr noundef nonnull %176)
  br label %179

179:                                              ; preds = %178, %177, %169
  store i64 %168, ptr %167, align 8, !tbaa !9
  %180 = icmp ugt i64 %5, 149
  br i1 %180, label %182, label %181

181:                                              ; preds = %179
  tail call void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %6) #15
  br label %189

182:                                              ; preds = %179
  %183 = icmp ugt i64 %5, 359
  %184 = mul i64 %6, 40
  %185 = getelementptr inbounds i8, ptr %3, i64 %184
  %186 = getelementptr inbounds i8, ptr %185, i64 40
  br i1 %183, label %188, label %187

187:                                              ; preds = %182
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %6, ptr noundef nonnull %186) #15
  br label %189

188:                                              ; preds = %182
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %6, ptr noundef nonnull %186)
  br label %189

189:                                              ; preds = %188, %187, %181
  %190 = getelementptr inbounds i8, ptr %12, i64 8
  %191 = shl nsw i64 %8, 1
  tail call void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef nonnull %190, ptr noundef %3, i64 noundef %6, i64 noundef %191, i32 noundef 0, i64 noundef %166) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
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
  %21 = load i64, ptr %20, align 8, !tbaa !9
  %22 = getelementptr inbounds i64, ptr %14, i64 %19
  %23 = load i64, ptr %22, align 8, !tbaa !9
  %24 = icmp eq i64 %21, %23
  br i1 %24, label %15, label %25, !llvm.loop !231

25:                                               ; preds = %18
  %26 = icmp ugt i64 %21, %23
  %27 = select i1 %26, i32 1, i32 -1
  br label %28

28:                                               ; preds = %25, %15
  %29 = phi i32 [ %27, %25 ], [ 0, %15 ]
  %30 = icmp slt i32 %29, 0
  br i1 %30, label %31, label %33

31:                                               ; preds = %28
  %32 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %14, ptr noundef %1, i64 noundef %8) #15
  br label %65

33:                                               ; preds = %28
  %34 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %14, i64 noundef %8) #15
  br label %65

35:                                               ; preds = %6
  %36 = getelementptr inbounds i64, ptr %1, i64 %7
  %37 = load i64, ptr %36, align 8, !tbaa !9
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
  %47 = load i64, ptr %46, align 8, !tbaa !9
  %48 = getelementptr inbounds i64, ptr %40, i64 %45
  %49 = load i64, ptr %48, align 8, !tbaa !9
  %50 = icmp eq i64 %47, %49
  br i1 %50, label %41, label %51, !llvm.loop !231

51:                                               ; preds = %44
  %52 = icmp ugt i64 %47, %49
  %53 = select i1 %52, i32 1, i32 -1
  br label %54

54:                                               ; preds = %51, %41
  %55 = phi i32 [ %53, %51 ], [ 0, %41 ]
  %56 = icmp slt i32 %55, 0
  br i1 %56, label %57, label %60

57:                                               ; preds = %54
  %58 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %40, ptr noundef %1, i64 noundef %7) #15
  %59 = getelementptr inbounds i64, ptr %0, i64 %7
  store i64 0, ptr %59, align 8, !tbaa !9
  br label %65

60:                                               ; preds = %54, %35
  %61 = getelementptr inbounds i64, ptr %1, i64 %8
  %62 = tail call i64 @__gmpn_sub_n(ptr noundef %0, ptr noundef %1, ptr noundef %61, i64 noundef %7) #15
  %63 = sub i64 %37, %62
  %64 = getelementptr inbounds i64, ptr %0, i64 %7
  store i64 %63, ptr %64, align 8, !tbaa !9
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
  %76 = load i64, ptr %75, align 8, !tbaa !9
  %77 = getelementptr inbounds i64, ptr %69, i64 %74
  %78 = load i64, ptr %77, align 8, !tbaa !9
  %79 = icmp eq i64 %76, %78
  br i1 %79, label %70, label %80, !llvm.loop !231

80:                                               ; preds = %73
  %81 = icmp ule i64 %76, %78
  br i1 %81, label %82, label %85

82:                                               ; preds = %80
  %83 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %69, ptr noundef %3, i64 noundef %8) #15
  %84 = xor i32 %66, 1
  br label %153

85:                                               ; preds = %80, %70
  %86 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %3, ptr noundef %69, i64 noundef %8) #15
  br label %153

87:                                               ; preds = %65
  %88 = getelementptr inbounds i64, ptr %3, i64 %9
  %89 = sub i64 %8, %9
  br label %90

90:                                               ; preds = %90, %87
  %91 = phi i64 [ %89, %87 ], [ %92, %90 ]
  %92 = add nsw i64 %91, -1
  %93 = getelementptr inbounds i64, ptr %88, i64 %92
  %94 = load i64, ptr %93, align 8, !tbaa !9
  %95 = icmp ne i64 %94, 0
  %96 = icmp eq i64 %92, 0
  %97 = or i1 %95, %96
  br i1 %97, label %98, label %90, !llvm.loop !232

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
  %107 = load i64, ptr %106, align 8, !tbaa !9
  %108 = getelementptr inbounds i64, ptr %100, i64 %105
  %109 = load i64, ptr %108, align 8, !tbaa !9
  %110 = icmp eq i64 %107, %109
  br i1 %110, label %101, label %111, !llvm.loop !231

111:                                              ; preds = %104
  %112 = icmp ugt i64 %107, %109
  %113 = select i1 %112, i32 1, i32 -1
  br label %114

114:                                              ; preds = %111, %101
  %115 = phi i32 [ %113, %111 ], [ 0, %101 ]
  %116 = icmp slt i32 %115, 0
  br i1 %116, label %117, label %125

117:                                              ; preds = %114
  %118 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %100, ptr noundef %3, i64 noundef %9) #15
  %119 = icmp eq i64 %89, 0
  br i1 %119, label %123, label %120

120:                                              ; preds = %117
  %121 = getelementptr i64, ptr %0, i64 %4
  %122 = shl nuw i64 %89, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %121, i8 0, i64 %122, i1 false), !tbaa !9
  br label %123

123:                                              ; preds = %120, %117
  %124 = xor i32 %66, 1
  br label %153

125:                                              ; preds = %114, %98
  %126 = icmp eq i64 %9, 0
  br i1 %126, label %141, label %127

127:                                              ; preds = %125
  %128 = getelementptr inbounds i64, ptr %3, i64 %8
  %129 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %3, ptr noundef %128, i64 noundef %9) #15
  %130 = icmp eq i64 %129, 0
  br i1 %130, label %141, label %131

131:                                              ; preds = %134, %127
  %132 = phi i64 [ %138, %134 ], [ %9, %127 ]
  %133 = icmp slt i64 %132, %8
  br i1 %133, label %134, label %153

134:                                              ; preds = %131
  %135 = getelementptr inbounds i64, ptr %3, i64 %132
  %136 = load i64, ptr %135, align 8, !tbaa !9
  %137 = add i64 %136, -1
  %138 = add nsw i64 %132, 1
  %139 = getelementptr inbounds i64, ptr %10, i64 %132
  store i64 %137, ptr %139, align 8, !tbaa !9
  %140 = icmp eq i64 %136, 0
  br i1 %140, label %131, label %141, !llvm.loop !233

141:                                              ; preds = %134, %127, %125
  %142 = phi i64 [ %9, %127 ], [ 0, %125 ], [ %138, %134 ]
  %143 = icmp ne ptr %10, %3
  %144 = icmp slt i64 %142, %8
  %145 = select i1 %143, i1 %144, i1 false
  br i1 %145, label %146, label %153

146:                                              ; preds = %146, %141
  %147 = phi i64 [ %151, %146 ], [ %142, %141 ]
  %148 = getelementptr inbounds i64, ptr %3, i64 %147
  %149 = load i64, ptr %148, align 8, !tbaa !9
  %150 = getelementptr inbounds i64, ptr %10, i64 %147
  store i64 %149, ptr %150, align 8, !tbaa !9
  %151 = add nsw i64 %147, 1
  %152 = icmp eq i64 %151, %8
  br i1 %152, label %153, label %146, !llvm.loop !234

153:                                              ; preds = %146, %141, %131, %123, %85, %82
  %154 = phi i32 [ %84, %82 ], [ %66, %85 ], [ %124, %123 ], [ %66, %141 ], [ %66, %146 ], [ %66, %131 ]
  %155 = icmp sgt i64 %8, 29
  br i1 %155, label %157, label %156

156:                                              ; preds = %153
  tail call void @__gmpn_mul_basecase(ptr noundef %5, ptr noundef %0, i64 noundef %8, ptr noundef %10, i64 noundef %8) #15
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
  tail call void @__gmpn_mul_basecase(ptr noundef %166, ptr noundef %167, i64 noundef %7, ptr noundef %168, i64 noundef %9) #15
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
  tail call void @__gmpn_toom32_mul(ptr noundef %174, ptr noundef %175, i64 noundef %7, ptr noundef %176, i64 noundef %9, ptr noundef %177) #15
  br label %191

180:                                              ; preds = %160
  %181 = icmp sgt i64 %7, 29
  %182 = getelementptr inbounds i64, ptr %1, i64 %8
  %183 = getelementptr inbounds i64, ptr %3, i64 %8
  br i1 %181, label %187, label %184

184:                                              ; preds = %180
  %185 = shl nsw i64 %8, 4
  %186 = getelementptr inbounds i8, ptr %0, i64 %185
  tail call void @__gmpn_mul_basecase(ptr noundef %186, ptr noundef %182, i64 noundef %7, ptr noundef %183, i64 noundef %7) #15
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
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8) #15
  br label %196

193:                                              ; preds = %191
  %194 = shl nsw i64 %8, 4
  %195 = getelementptr inbounds i8, ptr %5, i64 %194
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %195)
  br label %196

196:                                              ; preds = %193, %192
  %197 = shl nsw i64 %8, 1
  %198 = getelementptr inbounds i64, ptr %0, i64 %197
  %199 = tail call i64 @__gmpn_add_n(ptr noundef %198, ptr noundef %10, ptr noundef %198, i64 noundef %8) #15
  %200 = tail call i64 @__gmpn_add_n(ptr noundef %10, ptr noundef %198, ptr noundef %0, i64 noundef %8) #15
  %201 = add i64 %200, %199
  %202 = sub i64 %7, %8
  %203 = add i64 %202, %9
  %204 = icmp eq i64 %203, 0
  br i1 %204, label %218, label %205

205:                                              ; preds = %196
  %206 = getelementptr inbounds i64, ptr %198, i64 %8
  %207 = tail call i64 @__gmpn_add_n(ptr noundef %198, ptr noundef %198, ptr noundef %206, i64 noundef %203) #15
  %208 = icmp eq i64 %207, 0
  br i1 %208, label %218, label %209

209:                                              ; preds = %212, %205
  %210 = phi i64 [ %216, %212 ], [ %203, %205 ]
  %211 = icmp slt i64 %210, %8
  br i1 %211, label %212, label %218

212:                                              ; preds = %209
  %213 = getelementptr inbounds i64, ptr %198, i64 %210
  %214 = load i64, ptr %213, align 8, !tbaa !9
  %215 = add i64 %214, 1
  %216 = add nsw i64 %210, 1
  store i64 %215, ptr %213, align 8, !tbaa !9
  %217 = icmp eq i64 %215, 0
  br i1 %217, label %209, label %218, !llvm.loop !235

218:                                              ; preds = %212, %209, %205, %196
  %219 = phi i64 [ 0, %205 ], [ 0, %196 ], [ 1, %209 ], [ 0, %212 ]
  %220 = add i64 %219, %199
  %221 = icmp eq i32 %154, 0
  br i1 %221, label %225, label %222

222:                                              ; preds = %218
  %223 = tail call i64 @__gmpn_add_n(ptr noundef %10, ptr noundef %10, ptr noundef %5, i64 noundef %197) #15
  %224 = add i64 %223, %220
  br label %232

225:                                              ; preds = %218
  %226 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %10, ptr noundef %5, i64 noundef %197) #15
  %227 = sub i64 %220, %226
  %228 = icmp eq i64 %227, -1
  br i1 %228, label %229, label %232, !prof !55

229:                                              ; preds = %225
  %230 = sub i64 %2, %7
  %231 = shl i64 %230, 3
  tail call void @llvm.memset.p0.i64(ptr align 8 %198, i8 0, i64 %231, i1 false), !tbaa !9
  br label %255

232:                                              ; preds = %225, %222
  %233 = phi i64 [ %224, %222 ], [ %227, %225 ]
  %234 = load i64, ptr %198, align 8, !tbaa !9
  %235 = add i64 %234, %201
  store i64 %235, ptr %198, align 8, !tbaa !9
  %236 = icmp ult i64 %235, %201
  br i1 %236, label %237, label %243

237:                                              ; preds = %237, %232
  %238 = phi ptr [ %239, %237 ], [ %198, %232 ]
  %239 = getelementptr inbounds i8, ptr %238, i64 8
  %240 = load i64, ptr %239, align 8, !tbaa !9
  %241 = add i64 %240, 1
  store i64 %241, ptr %239, align 8, !tbaa !9
  %242 = icmp eq i64 %241, 0
  br i1 %242, label %237, label %243, !llvm.loop !236

243:                                              ; preds = %237, %232
  %244 = mul i64 %8, 24
  %245 = getelementptr inbounds i8, ptr %0, i64 %244
  %246 = load i64, ptr %245, align 8, !tbaa !9
  %247 = add i64 %246, %233
  store i64 %247, ptr %245, align 8, !tbaa !9
  %248 = icmp ult i64 %247, %233
  br i1 %248, label %249, label %255

249:                                              ; preds = %249, %243
  %250 = phi ptr [ %251, %249 ], [ %245, %243 ]
  %251 = getelementptr inbounds i8, ptr %250, i64 8
  %252 = load i64, ptr %251, align 8, !tbaa !9
  %253 = add i64 %252, 1
  store i64 %253, ptr %251, align 8, !tbaa !9
  %254 = icmp eq i64 %253, 0
  br i1 %254, label %249, label %255, !llvm.loop !237

255:                                              ; preds = %249, %243, %229
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_8pts(ptr noundef %0, i64 noundef %1, ptr noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = mul nsw i64 %1, 3
  %8 = getelementptr inbounds i64, ptr %0, i64 %7
  %9 = mul i64 %1, 56
  %10 = getelementptr inbounds i8, ptr %0, i64 %9
  %11 = getelementptr inbounds i64, ptr %2, i64 %1
  %12 = load i64, ptr %0, align 8, !tbaa !9
  %13 = lshr i64 %12, 4
  %14 = load i64, ptr %11, align 8, !tbaa !9
  %15 = sub i64 %14, %13
  store i64 %15, ptr %11, align 8, !tbaa !9
  %16 = load i64, ptr %0, align 8, !tbaa !9
  %17 = lshr i64 %16, 4
  %18 = icmp ult i64 %14, %17
  br i1 %18, label %19, label %25

19:                                               ; preds = %19, %6
  %20 = phi ptr [ %21, %19 ], [ %11, %6 ]
  %21 = getelementptr inbounds i8, ptr %20, i64 8
  %22 = load i64, ptr %21, align 8, !tbaa !9
  %23 = add i64 %22, -1
  store i64 %23, ptr %21, align 8, !tbaa !9
  %24 = icmp eq i64 %22, 0
  br i1 %24, label %19, label %25, !llvm.loop !238

25:                                               ; preds = %19, %6
  %26 = getelementptr inbounds i8, ptr %0, i64 8
  %27 = shl nsw i64 %1, 1
  %28 = add nsw i64 %27, -1
  %29 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %26, i64 noundef %28, i32 noundef 60) #15
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %11, ptr noundef nonnull %11, ptr noundef %5, i64 noundef %28) #15
  %31 = getelementptr inbounds i64, ptr %11, i64 %27
  %32 = getelementptr inbounds i8, ptr %31, i64 -8
  %33 = add i64 %30, %29
  %34 = load i64, ptr %32, align 8, !tbaa !9
  %35 = sub i64 %34, %33
  store i64 %35, ptr %32, align 8, !tbaa !9
  %36 = icmp ult i64 %34, %33
  br i1 %36, label %37, label %43

37:                                               ; preds = %37, %25
  %38 = phi ptr [ %39, %37 ], [ %32, %25 ]
  %39 = getelementptr inbounds i8, ptr %38, i64 8
  %40 = load i64, ptr %39, align 8, !tbaa !9
  %41 = add i64 %40, -1
  store i64 %41, ptr %39, align 8, !tbaa !9
  %42 = icmp eq i64 %40, 0
  br i1 %42, label %37, label %43, !llvm.loop !239

43:                                               ; preds = %37, %25
  %44 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %10, i64 noundef %4, i32 noundef 12) #15
  %45 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef %5, i64 noundef %4) #15
  %46 = getelementptr inbounds i64, ptr %2, i64 %4
  %47 = add i64 %45, %44
  %48 = load i64, ptr %46, align 8, !tbaa !9
  %49 = sub i64 %48, %47
  store i64 %49, ptr %46, align 8, !tbaa !9
  %50 = icmp ult i64 %48, %47
  br i1 %50, label %51, label %57

51:                                               ; preds = %51, %43
  %52 = phi ptr [ %53, %51 ], [ %46, %43 ]
  %53 = getelementptr inbounds i8, ptr %52, i64 8
  %54 = load i64, ptr %53, align 8, !tbaa !9
  %55 = add i64 %54, -1
  store i64 %55, ptr %53, align 8, !tbaa !9
  %56 = icmp eq i64 %54, 0
  br i1 %56, label %51, label %57, !llvm.loop !240

57:                                               ; preds = %51, %43
  %58 = getelementptr inbounds i64, ptr %8, i64 %1
  %59 = load i64, ptr %0, align 8, !tbaa !9
  %60 = lshr i64 %59, 2
  %61 = load i64, ptr %58, align 8, !tbaa !9
  %62 = sub i64 %61, %60
  store i64 %62, ptr %58, align 8, !tbaa !9
  %63 = load i64, ptr %0, align 8, !tbaa !9
  %64 = lshr i64 %63, 2
  %65 = icmp ult i64 %61, %64
  br i1 %65, label %66, label %72

66:                                               ; preds = %66, %57
  %67 = phi ptr [ %68, %66 ], [ %58, %57 ]
  %68 = getelementptr inbounds i8, ptr %67, i64 8
  %69 = load i64, ptr %68, align 8, !tbaa !9
  %70 = add i64 %69, -1
  store i64 %70, ptr %68, align 8, !tbaa !9
  %71 = icmp eq i64 %69, 0
  br i1 %71, label %66, label %72, !llvm.loop !241

72:                                               ; preds = %66, %57
  %73 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %26, i64 noundef %28, i32 noundef 62) #15
  %74 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %58, ptr noundef nonnull %58, ptr noundef %5, i64 noundef %28) #15
  %75 = getelementptr inbounds i64, ptr %58, i64 %27
  %76 = getelementptr inbounds i8, ptr %75, i64 -8
  %77 = add i64 %74, %73
  %78 = load i64, ptr %76, align 8, !tbaa !9
  %79 = sub i64 %78, %77
  store i64 %79, ptr %76, align 8, !tbaa !9
  %80 = icmp ult i64 %78, %77
  br i1 %80, label %81, label %87

81:                                               ; preds = %81, %72
  %82 = phi ptr [ %83, %81 ], [ %76, %72 ]
  %83 = getelementptr inbounds i8, ptr %82, i64 8
  %84 = load i64, ptr %83, align 8, !tbaa !9
  %85 = add i64 %84, -1
  store i64 %85, ptr %83, align 8, !tbaa !9
  %86 = icmp eq i64 %84, 0
  br i1 %86, label %81, label %87, !llvm.loop !242

87:                                               ; preds = %81, %72
  %88 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef nonnull %10, i64 noundef %4, i32 noundef 6) #15
  %89 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef %5, i64 noundef %4) #15
  %90 = getelementptr inbounds i64, ptr %8, i64 %4
  %91 = add i64 %89, %88
  %92 = load i64, ptr %90, align 8, !tbaa !9
  %93 = sub i64 %92, %91
  store i64 %93, ptr %90, align 8, !tbaa !9
  %94 = icmp ult i64 %92, %91
  br i1 %94, label %95, label %101

95:                                               ; preds = %95, %87
  %96 = phi ptr [ %97, %95 ], [ %90, %87 ]
  %97 = getelementptr inbounds i8, ptr %96, i64 8
  %98 = load i64, ptr %97, align 8, !tbaa !9
  %99 = add i64 %98, -1
  store i64 %99, ptr %97, align 8, !tbaa !9
  %100 = icmp eq i64 %98, 0
  br i1 %100, label %95, label %101, !llvm.loop !243

101:                                              ; preds = %95, %87
  %102 = getelementptr inbounds i64, ptr %3, i64 %1
  %103 = tail call i64 @__gmpn_sub_n(ptr noundef %102, ptr noundef %102, ptr noundef nonnull %0, i64 noundef %27) #15
  %104 = getelementptr inbounds i64, ptr %3, i64 %7
  %105 = load i64, ptr %104, align 8, !tbaa !9
  %106 = sub i64 %105, %103
  store i64 %106, ptr %104, align 8, !tbaa !9
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %3, ptr noundef nonnull %10, i64 noundef %4) #15
  %108 = getelementptr inbounds i64, ptr %3, i64 %4
  %109 = load i64, ptr %108, align 8, !tbaa !9
  %110 = sub i64 %109, %107
  store i64 %110, ptr %108, align 8, !tbaa !9
  %111 = icmp ult i64 %109, %107
  br i1 %111, label %112, label %118

112:                                              ; preds = %112, %101
  %113 = phi ptr [ %114, %112 ], [ %108, %101 ]
  %114 = getelementptr inbounds i8, ptr %113, i64 8
  %115 = load i64, ptr %114, align 8, !tbaa !9
  %116 = add i64 %115, -1
  store i64 %116, ptr %114, align 8, !tbaa !9
  %117 = icmp eq i64 %115, 0
  br i1 %117, label %112, label %118, !llvm.loop !244

118:                                              ; preds = %112, %101
  %119 = add nsw i64 %7, 1
  %120 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef nonnull %8, i64 noundef %119) #15
  %121 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %119, i32 noundef 2) #15
  %122 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef %3, i64 noundef %119) #15
  %123 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %2, ptr noundef nonnull %8, i64 noundef %119) #15
  tail call void @__gmpn_divexact_1(ptr noundef %2, ptr noundef %2, i64 noundef %119, i64 noundef 45) #15
  %124 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef nonnull %8, ptr noundef nonnull %8, i64 noundef %119, i64 noundef 6148914691236517205, i64 noundef 0) #15
  %125 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %2, i64 noundef %119, i32 noundef 2) #15
  %126 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef %5, i64 noundef %119) #15
  %127 = getelementptr inbounds i64, ptr %0, i64 %1
  %128 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %127, ptr noundef nonnull %127, ptr noundef %3, i64 noundef %1) #15
  %129 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %127, ptr noundef nonnull %127, ptr noundef nonnull %8, i64 noundef %1) #15
  %130 = sub i64 %128, %129
  %131 = icmp sgt i64 %130, 0
  br i1 %131, label %132, label %138

132:                                              ; preds = %132, %118
  %133 = phi ptr [ %134, %132 ], [ %102, %118 ]
  %134 = getelementptr inbounds i8, ptr %133, i64 8
  %135 = load i64, ptr %133, align 8, !tbaa !9
  %136 = add i64 %135, 1
  store i64 %136, ptr %133, align 8, !tbaa !9
  %137 = icmp eq i64 %136, 0
  br i1 %137, label %132, label %138, !llvm.loop !245

138:                                              ; preds = %132, %118
  %139 = phi i64 [ %130, %118 ], [ 0, %132 ]
  %140 = getelementptr inbounds i64, ptr %0, i64 %27
  %141 = sub nsw i64 0, %139
  %142 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %140, ptr noundef %102, ptr noundef nonnull %58, i64 noundef %1) #15
  %143 = load i64, ptr %140, align 8, !tbaa !9
  %144 = add i64 %143, %139
  store i64 %144, ptr %140, align 8, !tbaa !9
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
  %153 = load i64, ptr %152, align 8, !tbaa !9
  %154 = add i64 %153, -1
  store i64 %154, ptr %152, align 8, !tbaa !9
  %155 = add nuw i64 %149, 1
  %156 = icmp eq i64 %153, 0
  br i1 %156, label %148, label %157, !llvm.loop !246

157:                                              ; preds = %151, %148, %138
  %158 = phi i64 [ 0, %138 ], [ 1, %148 ], [ 0, %151 ]
  %159 = getelementptr inbounds i64, ptr %3, i64 %27
  %160 = add i64 %158, %142
  %161 = load i64, ptr %159, align 8, !tbaa !9
  %162 = sub i64 %161, %160
  store i64 %162, ptr %159, align 8, !tbaa !9
  %163 = icmp ult i64 %161, %160
  br i1 %163, label %164, label %170

164:                                              ; preds = %164, %157
  %165 = phi ptr [ %166, %164 ], [ %159, %157 ]
  %166 = getelementptr inbounds i8, ptr %165, i64 8
  %167 = load i64, ptr %166, align 8, !tbaa !9
  %168 = add i64 %167, -1
  store i64 %168, ptr %166, align 8, !tbaa !9
  %169 = icmp eq i64 %167, 0
  br i1 %169, label %164, label %170, !llvm.loop !247

170:                                              ; preds = %164, %157
  %171 = add nsw i64 %1, 1
  %172 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef nonnull %159, i64 noundef %171) #15
  %173 = getelementptr inbounds i64, ptr %8, i64 %27
  %174 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %173, ptr noundef nonnull %173, ptr noundef %2, i64 noundef %1) #15
  %175 = getelementptr inbounds i64, ptr %8, i64 %7
  %176 = load i64, ptr %175, align 8, !tbaa !9
  %177 = add i64 %176, %174
  store i64 %177, ptr %175, align 8, !tbaa !9
  %178 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %8, ptr noundef nonnull %8, ptr noundef nonnull %173, i64 noundef %171) #15
  %179 = sub i64 %172, %178
  %180 = icmp slt i64 %179, 0
  br i1 %180, label %181, label %187, !prof !55

181:                                              ; preds = %181, %170
  %182 = phi ptr [ %183, %181 ], [ %58, %170 ]
  %183 = getelementptr inbounds i8, ptr %182, i64 8
  %184 = load i64, ptr %183, align 8, !tbaa !9
  %185 = add i64 %184, -1
  store i64 %185, ptr %183, align 8, !tbaa !9
  %186 = icmp eq i64 %184, 0
  br i1 %186, label %181, label %198, !llvm.loop !248

187:                                              ; preds = %170
  %188 = getelementptr inbounds i8, ptr %58, i64 8
  %189 = load i64, ptr %188, align 8, !tbaa !9
  %190 = add i64 %189, %179
  store i64 %190, ptr %188, align 8, !tbaa !9
  %191 = icmp ult i64 %190, %179
  br i1 %191, label %192, label %198

192:                                              ; preds = %192, %187
  %193 = phi ptr [ %194, %192 ], [ %188, %187 ]
  %194 = getelementptr inbounds i8, ptr %193, i64 8
  %195 = load i64, ptr %194, align 8, !tbaa !9
  %196 = add i64 %195, 1
  store i64 %196, ptr %194, align 8, !tbaa !9
  %197 = icmp eq i64 %196, 0
  br i1 %197, label %192, label %198, !llvm.loop !249

198:                                              ; preds = %192, %187, %181
  %199 = shl nsw i64 %1, 5
  %200 = getelementptr inbounds i8, ptr %0, i64 %199
  %201 = or disjoint i64 %27, 1
  %202 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %200, ptr noundef nonnull %58, ptr noundef nonnull %11, i64 noundef %201) #15
  %203 = mul i64 %1, 48
  %204 = getelementptr inbounds i8, ptr %0, i64 %203
  %205 = load i64, ptr %204, align 8, !tbaa !9
  %206 = load i64, ptr %11, align 8, !tbaa !9
  %207 = add i64 %206, %205
  store i64 %207, ptr %204, align 8, !tbaa !9
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
  %216 = load i64, ptr %215, align 8, !tbaa !9
  %217 = add i64 %216, 1
  %218 = getelementptr inbounds i64, ptr %204, i64 %212
  store i64 %217, ptr %218, align 8, !tbaa !9
  %219 = add nuw i64 %212, 1
  %220 = icmp eq i64 %217, 0
  br i1 %220, label %211, label %221, !llvm.loop !250

221:                                              ; preds = %214
  %222 = icmp ne ptr %11, %204
  %223 = icmp slt i64 %219, %1
  %224 = select i1 %222, i1 %223, i1 false
  br i1 %224, label %225, label %243

225:                                              ; preds = %225, %221
  %226 = phi i64 [ %230, %225 ], [ %219, %221 ]
  %227 = getelementptr inbounds i64, ptr %11, i64 %226
  %228 = load i64, ptr %227, align 8, !tbaa !9
  %229 = getelementptr inbounds i64, ptr %204, i64 %226
  store i64 %228, ptr %229, align 8, !tbaa !9
  %230 = add nuw nsw i64 %226, 1
  %231 = icmp slt i64 %230, %1
  br i1 %231, label %225, label %243, !llvm.loop !251

232:                                              ; preds = %198
  %233 = icmp ne ptr %11, %204
  %234 = icmp sgt i64 %1, 1
  %235 = and i1 %234, %233
  br i1 %235, label %236, label %243

236:                                              ; preds = %236, %232
  %237 = phi i64 [ %241, %236 ], [ 1, %232 ]
  %238 = getelementptr inbounds i64, ptr %11, i64 %237
  %239 = load i64, ptr %238, align 8, !tbaa !9
  %240 = getelementptr inbounds i64, ptr %204, i64 %237
  store i64 %239, ptr %240, align 8, !tbaa !9
  %241 = add nuw nsw i64 %237, 1
  %242 = icmp eq i64 %241, %1
  br i1 %242, label %243, label %236, !llvm.loop !252

243:                                              ; preds = %236, %232, %225, %221, %211
  %244 = phi i64 [ 0, %221 ], [ 0, %232 ], [ 0, %225 ], [ 1, %211 ], [ 0, %236 ]
  %245 = getelementptr inbounds i64, ptr %2, i64 %27
  %246 = load i64, ptr %245, align 8, !tbaa !9
  %247 = add i64 %246, %244
  store i64 %247, ptr %245, align 8, !tbaa !9
  %248 = icmp ult i64 %247, %244
  br i1 %248, label %249, label %255

249:                                              ; preds = %249, %243
  %250 = phi ptr [ %251, %249 ], [ %245, %243 ]
  %251 = getelementptr inbounds i8, ptr %250, i64 8
  %252 = load i64, ptr %251, align 8, !tbaa !9
  %253 = add i64 %252, 1
  store i64 %253, ptr %251, align 8, !tbaa !9
  %254 = icmp eq i64 %253, 0
  br i1 %254, label %249, label %255, !llvm.loop !253

255:                                              ; preds = %249, %243
  %256 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %10, ptr noundef nonnull %10, ptr noundef nonnull %245, i64 noundef %1) #15
  %257 = icmp eq i64 %4, %1
  br i1 %257, label %275, label %258, !prof !55

258:                                              ; preds = %255
  %259 = shl nsw i64 %1, 6
  %260 = getelementptr inbounds i8, ptr %0, i64 %259
  %261 = getelementptr inbounds i64, ptr %2, i64 %7
  %262 = load i64, ptr %261, align 8, !tbaa !9
  %263 = add i64 %262, %256
  %264 = load i64, ptr %260, align 8, !tbaa !9
  %265 = add i64 %264, %263
  store i64 %265, ptr %260, align 8, !tbaa !9
  %266 = load i64, ptr %261, align 8, !tbaa !9
  %267 = add i64 %266, %256
  %268 = icmp ult i64 %265, %267
  br i1 %268, label %269, label %275

269:                                              ; preds = %269, %258
  %270 = phi ptr [ %271, %269 ], [ %260, %258 ]
  %271 = getelementptr inbounds i8, ptr %270, i64 8
  %272 = load i64, ptr %271, align 8, !tbaa !9
  %273 = add i64 %272, 1
  store i64 %273, ptr %271, align 8, !tbaa !9
  %274 = icmp eq i64 %273, 0
  br i1 %274, label %269, label %275, !llvm.loop !254

275:                                              ; preds = %269, %258, %255
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_6pts(ptr noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, i64 noundef %6) local_unnamed_addr #3 {
  %8 = and i32 %2, 2
  %9 = icmp eq i32 %8, 0
  %10 = shl nsw i64 %1, 1
  %11 = or disjoint i64 %10, 1
  br i1 %9, label %14, label %12

12:                                               ; preds = %7
  %13 = tail call i64 @__gmpn_add_n(ptr noundef %4, ptr noundef %5, ptr noundef %4, i64 noundef %11) #15
  br label %16

14:                                               ; preds = %7
  %15 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %5, ptr noundef %4, i64 noundef %11) #15
  br label %16

16:                                               ; preds = %14, %12
  %17 = shl nsw i64 %1, 1
  %18 = or disjoint i64 %17, 1
  %19 = tail call i64 @__gmpn_rshift(ptr noundef %4, ptr noundef %4, i64 noundef %18, i32 noundef 2) #15
  %20 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %0, i64 noundef %17) #15
  %21 = getelementptr inbounds i64, ptr %5, i64 %17
  %22 = load i64, ptr %21, align 8, !tbaa !9
  %23 = sub i64 %22, %20
  store i64 %23, ptr %21, align 8, !tbaa !9
  %24 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %18, i32 noundef 1) #15
  %25 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %4, i64 noundef %18) #15
  %26 = tail call i64 @__gmpn_rshift(ptr noundef %5, ptr noundef %5, i64 noundef %18, i32 noundef 1) #15
  %27 = and i32 %2, 1
  %28 = icmp eq i32 %27, 0
  %29 = getelementptr inbounds i64, ptr %0, i64 %17
  br i1 %28, label %32, label %30

30:                                               ; preds = %16
  %31 = tail call i64 @__gmpn_add_n(ptr noundef %3, ptr noundef %29, ptr noundef %3, i64 noundef %18) #15
  br label %34

32:                                               ; preds = %16
  %33 = tail call i64 @__gmpn_sub_n(ptr noundef %3, ptr noundef %29, ptr noundef %3, i64 noundef %18) #15
  br label %34

34:                                               ; preds = %32, %30
  %35 = tail call i64 @__gmpn_rshift(ptr noundef %3, ptr noundef %3, i64 noundef %18, i32 noundef 1) #15
  %36 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %3, i64 noundef %18) #15
  %37 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %4, ptr noundef %4, i64 noundef %18, i64 noundef 6148914691236517205, i64 noundef 0) #15
  %38 = getelementptr inbounds i64, ptr %0, i64 %17
  %39 = tail call i64 @__gmpn_sub_n(ptr noundef %38, ptr noundef %38, ptr noundef %3, i64 noundef %18) #15
  %40 = tail call i64 @__gmpn_sub_n(ptr noundef %38, ptr noundef %38, ptr noundef %0, i64 noundef %17) #15
  %41 = getelementptr inbounds i64, ptr %38, i64 %17
  %42 = load i64, ptr %41, align 8, !tbaa !9
  %43 = sub i64 %42, %40
  store i64 %43, ptr %41, align 8, !tbaa !9
  %44 = tail call i64 @__gmpn_sub_n(ptr noundef %5, ptr noundef %5, ptr noundef %38, i64 noundef %18) #15
  %45 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %5, ptr noundef %5, i64 noundef %18, i64 noundef 6148914691236517205, i64 noundef 0) #15
  %46 = getelementptr inbounds i64, ptr %0, i64 %1
  %47 = tail call i64 @__gmpn_add_n(ptr noundef %46, ptr noundef %46, ptr noundef %3, i64 noundef %18) #15
  %48 = mul i64 %1, 24
  %49 = getelementptr inbounds i8, ptr %0, i64 %48
  %50 = getelementptr inbounds i8, ptr %49, i64 8
  %51 = load i64, ptr %50, align 8, !tbaa !9
  %52 = add i64 %51, %47
  store i64 %52, ptr %50, align 8, !tbaa !9
  %53 = icmp ult i64 %52, %47
  br i1 %53, label %54, label %60

54:                                               ; preds = %54, %34
  %55 = phi ptr [ %56, %54 ], [ %50, %34 ]
  %56 = getelementptr inbounds i8, ptr %55, i64 8
  %57 = load i64, ptr %56, align 8, !tbaa !9
  %58 = add i64 %57, 1
  store i64 %58, ptr %56, align 8, !tbaa !9
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %54, label %60, !llvm.loop !255

60:                                               ; preds = %54, %34
  %61 = mul i64 %1, 40
  %62 = getelementptr inbounds i8, ptr %0, i64 %61
  %63 = tail call i64 @__gmpn_lshift(ptr noundef %3, ptr noundef %62, i64 noundef %6, i32 noundef 2) #15
  %64 = tail call i64 @__gmpn_sub_n(ptr noundef %4, ptr noundef %4, ptr noundef %3, i64 noundef %6) #15
  %65 = getelementptr inbounds i64, ptr %4, i64 %6
  %66 = add i64 %64, %63
  %67 = load i64, ptr %65, align 8, !tbaa !9
  %68 = sub i64 %67, %66
  store i64 %68, ptr %65, align 8, !tbaa !9
  %69 = icmp ult i64 %67, %66
  br i1 %69, label %70, label %76

70:                                               ; preds = %70, %60
  %71 = phi ptr [ %72, %70 ], [ %65, %60 ]
  %72 = getelementptr inbounds i8, ptr %71, i64 8
  %73 = load i64, ptr %72, align 8, !tbaa !9
  %74 = add i64 %73, -1
  store i64 %74, ptr %72, align 8, !tbaa !9
  %75 = icmp eq i64 %73, 0
  br i1 %75, label %70, label %76, !llvm.loop !256

76:                                               ; preds = %70, %60
  %77 = tail call i64 @__gmpn_sub_n(ptr noundef %46, ptr noundef %46, ptr noundef %4, i64 noundef %1) #15
  %78 = load i64, ptr %38, align 8, !tbaa !9
  %79 = sub i64 %78, %77
  store i64 %79, ptr %38, align 8, !tbaa !9
  %80 = icmp ult i64 %78, %77
  br i1 %80, label %81, label %87

81:                                               ; preds = %81, %76
  %82 = phi ptr [ %83, %81 ], [ %38, %76 ]
  %83 = getelementptr inbounds i8, ptr %82, i64 8
  %84 = load i64, ptr %83, align 8, !tbaa !9
  %85 = add i64 %84, -1
  store i64 %85, ptr %83, align 8, !tbaa !9
  %86 = icmp eq i64 %84, 0
  br i1 %86, label %81, label %87, !llvm.loop !257

87:                                               ; preds = %81, %76
  %88 = load i64, ptr %41, align 8, !tbaa !9
  %89 = tail call i64 @__gmpn_add_n(ptr noundef %49, ptr noundef %49, ptr noundef %4, i64 noundef %1) #15
  %90 = add i64 %89, %88
  %91 = getelementptr inbounds i64, ptr %4, i64 %17
  %92 = load i64, ptr %91, align 8, !tbaa !9
  %93 = shl nsw i64 %1, 5
  %94 = getelementptr inbounds i8, ptr %0, i64 %93
  %95 = getelementptr inbounds i64, ptr %4, i64 %1
  %96 = tail call i64 @__gmpn_add_n(ptr noundef %94, ptr noundef %5, ptr noundef %95, i64 noundef %1) #15
  %97 = getelementptr inbounds i64, ptr %5, i64 %1
  %98 = add i64 %96, %92
  %99 = load i64, ptr %97, align 8, !tbaa !9
  %100 = add i64 %99, %98
  store i64 %100, ptr %97, align 8, !tbaa !9
  %101 = icmp ult i64 %100, %98
  br i1 %101, label %102, label %108

102:                                              ; preds = %102, %87
  %103 = phi ptr [ %104, %102 ], [ %97, %87 ]
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = load i64, ptr %104, align 8, !tbaa !9
  %106 = add i64 %105, 1
  store i64 %106, ptr %104, align 8, !tbaa !9
  %107 = icmp eq i64 %106, 0
  br i1 %107, label %102, label %108, !llvm.loop !258

108:                                              ; preds = %102, %87
  %109 = icmp sgt i64 %6, %1
  br i1 %109, label %110, label %114, !prof !30

110:                                              ; preds = %108
  %111 = load i64, ptr %21, align 8, !tbaa !9
  %112 = tail call i64 @__gmpn_add_n(ptr noundef %62, ptr noundef %62, ptr noundef nonnull %97, i64 noundef %1) #15
  %113 = add i64 %112, %111
  br label %116

114:                                              ; preds = %108
  %115 = tail call i64 @__gmpn_add_n(ptr noundef %62, ptr noundef %62, ptr noundef nonnull %97, i64 noundef %6) #15
  br label %116

116:                                              ; preds = %114, %110
  %117 = phi i64 [ %113, %110 ], [ %115, %114 ]
  %118 = add nsw i64 %6, %1
  %119 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %38, ptr noundef nonnull %38, ptr noundef %94, i64 noundef %118) #15
  %120 = getelementptr i64, ptr %62, i64 %6
  %121 = getelementptr i8, ptr %120, i64 -8
  %122 = load i64, ptr %121, align 8, !tbaa !9
  store i64 1, ptr %121, align 8, !tbaa !9
  br i1 %109, label %123, label %168, !prof !30

123:                                              ; preds = %116
  %124 = icmp ugt i64 %90, %117
  %125 = load i64, ptr %94, align 8, !tbaa !9
  br i1 %124, label %126, label %136

126:                                              ; preds = %123
  %127 = sub i64 %90, %117
  %128 = add i64 %125, %127
  store i64 %128, ptr %94, align 8, !tbaa !9
  %129 = icmp ult i64 %128, %127
  br i1 %129, label %130, label %146

130:                                              ; preds = %130, %126
  %131 = phi ptr [ %132, %130 ], [ %94, %126 ]
  %132 = getelementptr inbounds i8, ptr %131, i64 8
  %133 = load i64, ptr %132, align 8, !tbaa !9
  %134 = add i64 %133, 1
  store i64 %134, ptr %132, align 8, !tbaa !9
  %135 = icmp eq i64 %134, 0
  br i1 %135, label %130, label %146, !llvm.loop !259

136:                                              ; preds = %123
  %137 = sub i64 %117, %90
  %138 = sub i64 %125, %137
  store i64 %138, ptr %94, align 8, !tbaa !9
  %139 = icmp ult i64 %125, %137
  br i1 %139, label %140, label %146

140:                                              ; preds = %140, %136
  %141 = phi ptr [ %142, %140 ], [ %94, %136 ]
  %142 = getelementptr inbounds i8, ptr %141, i64 8
  %143 = load i64, ptr %142, align 8, !tbaa !9
  %144 = add i64 %143, -1
  store i64 %144, ptr %142, align 8, !tbaa !9
  %145 = icmp eq i64 %143, 0
  br i1 %145, label %140, label %146, !llvm.loop !260

146:                                              ; preds = %140, %136, %130, %126
  %147 = getelementptr inbounds i64, ptr %49, i64 %6
  %148 = load i64, ptr %147, align 8, !tbaa !9
  %149 = sub i64 %148, %119
  store i64 %149, ptr %147, align 8, !tbaa !9
  %150 = icmp ult i64 %148, %119
  br i1 %150, label %151, label %157

151:                                              ; preds = %151, %146
  %152 = phi ptr [ %153, %151 ], [ %147, %146 ]
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = load i64, ptr %153, align 8, !tbaa !9
  %155 = add i64 %154, -1
  store i64 %155, ptr %153, align 8, !tbaa !9
  %156 = icmp eq i64 %154, 0
  br i1 %156, label %151, label %157, !llvm.loop !261

157:                                              ; preds = %151, %146
  %158 = getelementptr inbounds i64, ptr %62, i64 %1
  %159 = load i64, ptr %158, align 8, !tbaa !9
  %160 = add i64 %159, %117
  store i64 %160, ptr %158, align 8, !tbaa !9
  %161 = icmp ult i64 %160, %117
  br i1 %161, label %162, label %190

162:                                              ; preds = %162, %157
  %163 = phi ptr [ %164, %162 ], [ %158, %157 ]
  %164 = getelementptr inbounds i8, ptr %163, i64 8
  %165 = load i64, ptr %164, align 8, !tbaa !9
  %166 = add i64 %165, 1
  store i64 %166, ptr %164, align 8, !tbaa !9
  %167 = icmp eq i64 %166, 0
  br i1 %167, label %162, label %190, !llvm.loop !262

168:                                              ; preds = %116
  %169 = load i64, ptr %94, align 8, !tbaa !9
  %170 = add i64 %169, %90
  store i64 %170, ptr %94, align 8, !tbaa !9
  %171 = icmp ult i64 %170, %90
  br i1 %171, label %172, label %178

172:                                              ; preds = %172, %168
  %173 = phi ptr [ %174, %172 ], [ %94, %168 ]
  %174 = getelementptr inbounds i8, ptr %173, i64 8
  %175 = load i64, ptr %174, align 8, !tbaa !9
  %176 = add i64 %175, 1
  store i64 %176, ptr %174, align 8, !tbaa !9
  %177 = icmp eq i64 %176, 0
  br i1 %177, label %172, label %178, !llvm.loop !263

178:                                              ; preds = %172, %168
  %179 = getelementptr inbounds i64, ptr %49, i64 %6
  %180 = add i64 %119, %117
  %181 = load i64, ptr %179, align 8, !tbaa !9
  %182 = sub i64 %181, %180
  store i64 %182, ptr %179, align 8, !tbaa !9
  %183 = icmp ult i64 %181, %180
  br i1 %183, label %184, label %190

184:                                              ; preds = %184, %178
  %185 = phi ptr [ %186, %184 ], [ %179, %178 ]
  %186 = getelementptr inbounds i8, ptr %185, i64 8
  %187 = load i64, ptr %186, align 8, !tbaa !9
  %188 = add i64 %187, -1
  store i64 %188, ptr %186, align 8, !tbaa !9
  %189 = icmp eq i64 %187, 0
  br i1 %189, label %184, label %190, !llvm.loop !264

190:                                              ; preds = %184, %178, %162, %157
  %191 = add i64 %122, -1
  %192 = load i64, ptr %121, align 8, !tbaa !9
  %193 = add i64 %191, %192
  store i64 %193, ptr %121, align 8, !tbaa !9
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, i32 noundef %5, i64 noundef %6) local_unnamed_addr #3 {
  %8 = shl nsw i64 %3, 1
  %9 = or disjoint i64 %8, 1
  %10 = getelementptr inbounds i64, ptr %0, i64 %3
  %11 = getelementptr inbounds i64, ptr %10, i64 %3
  %12 = getelementptr inbounds i64, ptr %11, i64 %3
  %13 = getelementptr inbounds i64, ptr %12, i64 %3
  %14 = icmp eq i32 %5, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %7
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %9) #15
  br label %19

17:                                               ; preds = %7
  %18 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %9) #15
  br label %19

19:                                               ; preds = %17, %15
  %20 = tail call i64 @__gmpn_bdiv_dbm1c(ptr noundef %1, ptr noundef %1, i64 noundef %9, i64 noundef 6148914691236517205, i64 noundef 0) #15
  br i1 %14, label %23, label %21

21:                                               ; preds = %19
  %22 = tail call i64 @__gmpn_add_n(ptr noundef %2, ptr noundef %11, ptr noundef %2, i64 noundef %9) #15
  br label %25

23:                                               ; preds = %19
  %24 = tail call i64 @__gmpn_sub_n(ptr noundef %2, ptr noundef %11, ptr noundef %2, i64 noundef %9) #15
  br label %25

25:                                               ; preds = %23, %21
  %26 = tail call i64 @__gmpn_rshift(ptr noundef %2, ptr noundef %2, i64 noundef %9, i32 noundef 1) #15
  %27 = tail call i64 @__gmpn_sub_n(ptr noundef %11, ptr noundef %11, ptr noundef %0, i64 noundef %8) #15
  %28 = load i64, ptr %13, align 8, !tbaa !9
  %29 = sub i64 %28, %27
  store i64 %29, ptr %13, align 8, !tbaa !9
  %30 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %11, i64 noundef %9) #15
  %31 = tail call i64 @__gmpn_rshift(ptr noundef %1, ptr noundef %1, i64 noundef %9, i32 noundef 1) #15
  %32 = tail call i64 @__gmpn_sub_n(ptr noundef %11, ptr noundef %11, ptr noundef %2, i64 noundef %9) #15
  %33 = tail call i64 @__gmpn_add_n(ptr noundef %10, ptr noundef %10, ptr noundef %2, i64 noundef %9) #15
  %34 = getelementptr inbounds i8, ptr %12, i64 8
  %35 = load i64, ptr %34, align 8, !tbaa !9
  %36 = add i64 %35, %33
  store i64 %36, ptr %34, align 8, !tbaa !9
  %37 = icmp ult i64 %36, %33
  br i1 %37, label %38, label %44

38:                                               ; preds = %38, %25
  %39 = phi ptr [ %40, %38 ], [ %34, %25 ]
  %40 = getelementptr inbounds i8, ptr %39, i64 8
  %41 = load i64, ptr %40, align 8, !tbaa !9
  %42 = add i64 %41, 1
  store i64 %42, ptr %40, align 8, !tbaa !9
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %38, label %44, !llvm.loop !265

44:                                               ; preds = %38, %25
  %45 = load i64, ptr %13, align 8, !tbaa !9
  store i64 %6, ptr %13, align 8, !tbaa !9
  %46 = tail call i64 @__gmpn_lshift(ptr noundef %2, ptr noundef nonnull %13, i64 noundef %4, i32 noundef 1) #15
  %47 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %1, ptr noundef %2, i64 noundef %4) #15
  %48 = getelementptr inbounds i64, ptr %1, i64 %4
  %49 = add i64 %47, %46
  %50 = load i64, ptr %48, align 8, !tbaa !9
  %51 = sub i64 %50, %49
  store i64 %51, ptr %48, align 8, !tbaa !9
  %52 = icmp ult i64 %50, %49
  br i1 %52, label %53, label %59

53:                                               ; preds = %53, %44
  %54 = phi ptr [ %55, %53 ], [ %48, %44 ]
  %55 = getelementptr inbounds i8, ptr %54, i64 8
  %56 = load i64, ptr %55, align 8, !tbaa !9
  %57 = add i64 %56, -1
  store i64 %57, ptr %55, align 8, !tbaa !9
  %58 = icmp eq i64 %56, 0
  br i1 %58, label %53, label %59, !llvm.loop !266

59:                                               ; preds = %53, %44
  %60 = add nsw i64 %3, 1
  %61 = icmp slt i64 %60, %4
  %62 = getelementptr inbounds i64, ptr %1, i64 %3
  br i1 %61, label %63, label %75, !prof !30

63:                                               ; preds = %59
  %64 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %13, ptr noundef nonnull %13, ptr noundef %62, i64 noundef %60) #15
  %65 = getelementptr inbounds i64, ptr %12, i64 %9
  %66 = load i64, ptr %65, align 8, !tbaa !9
  %67 = add i64 %66, %64
  store i64 %67, ptr %65, align 8, !tbaa !9
  %68 = icmp ult i64 %67, %64
  br i1 %68, label %69, label %77

69:                                               ; preds = %69, %63
  %70 = phi ptr [ %71, %69 ], [ %65, %63 ]
  %71 = getelementptr inbounds i8, ptr %70, i64 8
  %72 = load i64, ptr %71, align 8, !tbaa !9
  %73 = add i64 %72, 1
  store i64 %73, ptr %71, align 8, !tbaa !9
  %74 = icmp eq i64 %73, 0
  br i1 %74, label %69, label %77, !llvm.loop !267

75:                                               ; preds = %59
  %76 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %13, ptr noundef nonnull %13, ptr noundef %62, i64 noundef %4) #15
  br label %77

77:                                               ; preds = %75, %69, %63
  %78 = tail call i64 @__gmpn_sub_n(ptr noundef %11, ptr noundef %11, ptr noundef nonnull %13, i64 noundef %4) #15
  %79 = load i64, ptr %13, align 8, !tbaa !9
  store i64 %45, ptr %13, align 8, !tbaa !9
  %80 = getelementptr inbounds i64, ptr %11, i64 %4
  %81 = load i64, ptr %80, align 8, !tbaa !9
  %82 = sub i64 %81, %78
  store i64 %82, ptr %80, align 8, !tbaa !9
  %83 = icmp ult i64 %81, %78
  br i1 %83, label %84, label %90

84:                                               ; preds = %84, %77
  %85 = phi ptr [ %86, %84 ], [ %80, %77 ]
  %86 = getelementptr inbounds i8, ptr %85, i64 8
  %87 = load i64, ptr %86, align 8, !tbaa !9
  %88 = add i64 %87, -1
  store i64 %88, ptr %86, align 8, !tbaa !9
  %89 = icmp eq i64 %87, 0
  br i1 %89, label %84, label %90, !llvm.loop !268

90:                                               ; preds = %84, %77
  %91 = tail call i64 @__gmpn_sub_n(ptr noundef %10, ptr noundef %10, ptr noundef %1, i64 noundef %3) #15
  %92 = load i64, ptr %11, align 8, !tbaa !9
  %93 = sub i64 %92, %91
  store i64 %93, ptr %11, align 8, !tbaa !9
  %94 = icmp ult i64 %92, %91
  br i1 %94, label %95, label %101

95:                                               ; preds = %95, %90
  %96 = phi ptr [ %97, %95 ], [ %11, %90 ]
  %97 = getelementptr inbounds i8, ptr %96, i64 8
  %98 = load i64, ptr %97, align 8, !tbaa !9
  %99 = add i64 %98, -1
  store i64 %99, ptr %97, align 8, !tbaa !9
  %100 = icmp eq i64 %98, 0
  br i1 %100, label %95, label %101, !llvm.loop !269

101:                                              ; preds = %95, %90
  %102 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %12, ptr noundef nonnull %12, ptr noundef %1, i64 noundef %3) #15
  %103 = load i64, ptr %13, align 8, !tbaa !9
  %104 = add i64 %103, %102
  %105 = add i64 %104, %79
  store i64 %105, ptr %13, align 8, !tbaa !9
  %106 = icmp ult i64 %105, %79
  br i1 %106, label %107, label %113

107:                                              ; preds = %107, %101
  %108 = phi ptr [ %109, %107 ], [ %13, %101 ]
  %109 = getelementptr inbounds i8, ptr %108, i64 8
  %110 = load i64, ptr %109, align 8, !tbaa !9
  %111 = add i64 %110, 1
  store i64 %111, ptr %109, align 8, !tbaa !9
  %112 = icmp eq i64 %111, 0
  br i1 %112, label %107, label %113, !llvm.loop !270

113:                                              ; preds = %107, %101
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable
define range(i64 0, 2251799813685241) i64 @__gmpn_mod_34lsub1(ptr nocapture noundef readonly %0, i64 noundef %1) local_unnamed_addr #14 {
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
  %14 = load i64, ptr %7, align 8, !tbaa !9
  %15 = add i64 %14, %11
  %16 = icmp ult i64 %15, %11
  %17 = zext i1 %16 to i64
  %18 = add i64 %8, %17
  %19 = getelementptr inbounds i8, ptr %7, i64 8
  %20 = load i64, ptr %19, align 8, !tbaa !9
  %21 = add i64 %20, %12
  %22 = icmp ult i64 %21, %12
  %23 = zext i1 %22 to i64
  %24 = add i64 %9, %23
  %25 = getelementptr inbounds i8, ptr %7, i64 16
  %26 = load i64, ptr %25, align 8, !tbaa !9
  %27 = add i64 %26, %13
  %28 = icmp ult i64 %27, %13
  %29 = zext i1 %28 to i64
  %30 = add i64 %10, %29
  %31 = getelementptr inbounds i8, ptr %7, i64 24
  %32 = add nsw i64 %6, -3
  %33 = icmp sgt i64 %6, 2
  br i1 %33, label %5, label %34, !llvm.loop !271

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
  %46 = load i64, ptr %42, align 8, !tbaa !9
  %47 = add i64 %46, %37
  %48 = icmp ult i64 %47, %37
  %49 = zext i1 %48 to i64
  %50 = add i64 %40, %49
  %51 = icmp eq i64 %43, -2
  br i1 %51, label %59, label %52

52:                                               ; preds = %45
  %53 = getelementptr inbounds i8, ptr %42, i64 8
  %54 = load i64, ptr %53, align 8, !tbaa !9
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

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr nocapture noundef readonly %3, i64 noundef %4) local_unnamed_addr #3 {
  %6 = load i64, ptr %3, align 8, !tbaa !9
  %7 = tail call i64 @__gmpn_mul_1(ptr noundef %0, ptr noundef %1, i64 noundef %2, i64 noundef %6) #15
  %8 = getelementptr inbounds i64, ptr %0, i64 %2
  store i64 %7, ptr %8, align 8, !tbaa !9
  %9 = icmp sgt i64 %4, 1
  br i1 %9, label %10, label %21

10:                                               ; preds = %10, %5
  %11 = phi i64 [ %14, %10 ], [ %4, %5 ]
  %12 = phi ptr [ %15, %10 ], [ %3, %5 ]
  %13 = phi ptr [ %16, %10 ], [ %0, %5 ]
  %14 = add nsw i64 %11, -1
  %15 = getelementptr inbounds i8, ptr %12, i64 8
  %16 = getelementptr inbounds i8, ptr %13, i64 8
  %17 = load i64, ptr %15, align 8, !tbaa !9
  %18 = tail call i64 @__gmpn_addmul_1(ptr noundef nonnull %16, ptr noundef %1, i64 noundef %2, i64 noundef %17) #15
  %19 = getelementptr inbounds i64, ptr %16, i64 %2
  store i64 %18, ptr %19, align 8, !tbaa !9
  %20 = icmp sgt i64 %11, 2
  br i1 %20, label %10, label %21, !llvm.loop !272

21:                                               ; preds = %10, %5
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom43_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
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
  %30 = tail call i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef nonnull %24, ptr noundef nonnull %27, ptr noundef %1, i64 noundef %18, i64 noundef %20, ptr noundef nonnull %29) #15
  %31 = and i32 %30, 2
  %32 = getelementptr inbounds i64, ptr %5, i64 %21
  %33 = getelementptr inbounds i8, ptr %32, i64 16
  %34 = getelementptr inbounds i64, ptr %3, i64 %18
  %35 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %33, ptr noundef %34, i64 noundef %18, i32 noundef 1) #15
  %36 = getelementptr inbounds i64, ptr %33, i64 %18
  store i64 %35, ptr %36, align 8, !tbaa !9
  %37 = getelementptr inbounds i64, ptr %3, i64 %21
  %38 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %37, i64 noundef %22, i32 noundef 2) #15
  %39 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %5, ptr noundef %3, i64 noundef %22) #15
  %40 = add i64 %39, %38
  %41 = icmp eq i64 %22, %18
  br i1 %41, label %83, label %42

42:                                               ; preds = %16
  %43 = getelementptr inbounds i64, ptr %5, i64 %22
  %44 = getelementptr inbounds i64, ptr %3, i64 %22
  %45 = sub nsw i64 %18, %22
  %46 = load i64, ptr %44, align 8, !tbaa !9
  %47 = add i64 %46, %40
  store i64 %47, ptr %43, align 8, !tbaa !9
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
  %56 = load i64, ptr %55, align 8, !tbaa !9
  %57 = add i64 %56, 1
  %58 = getelementptr inbounds i64, ptr %43, i64 %52
  store i64 %57, ptr %58, align 8, !tbaa !9
  %59 = add nuw i64 %52, 1
  %60 = icmp eq i64 %57, 0
  br i1 %60, label %51, label %61, !llvm.loop !273

61:                                               ; preds = %54
  %62 = icmp ne ptr %3, %5
  %63 = icmp slt i64 %59, %45
  %64 = select i1 %62, i1 %63, i1 false
  br i1 %64, label %65, label %83

65:                                               ; preds = %65, %61
  %66 = phi i64 [ %70, %65 ], [ %59, %61 ]
  %67 = getelementptr inbounds i64, ptr %44, i64 %66
  %68 = load i64, ptr %67, align 8, !tbaa !9
  %69 = getelementptr inbounds i64, ptr %43, i64 %66
  store i64 %68, ptr %69, align 8, !tbaa !9
  %70 = add nuw nsw i64 %66, 1
  %71 = icmp slt i64 %70, %45
  br i1 %71, label %65, label %83, !llvm.loop !274

72:                                               ; preds = %42
  %73 = icmp ne ptr %3, %5
  %74 = icmp sgt i64 %45, 1
  %75 = and i1 %73, %74
  br i1 %75, label %76, label %83

76:                                               ; preds = %76, %72
  %77 = phi i64 [ %81, %76 ], [ 1, %72 ]
  %78 = getelementptr inbounds i64, ptr %44, i64 %77
  %79 = load i64, ptr %78, align 8, !tbaa !9
  %80 = getelementptr inbounds i64, ptr %43, i64 %77
  store i64 %79, ptr %80, align 8, !tbaa !9
  %81 = add nuw nsw i64 %77, 1
  %82 = icmp eq i64 %81, %45
  br i1 %82, label %83, label %76, !llvm.loop !275

83:                                               ; preds = %76, %72, %65, %61, %51, %16
  %84 = phi i64 [ %40, %16 ], [ 0, %61 ], [ 0, %72 ], [ 0, %65 ], [ 1, %51 ], [ 0, %76 ]
  %85 = getelementptr inbounds i64, ptr %5, i64 %18
  store i64 %84, ptr %85, align 8, !tbaa !9
  %86 = getelementptr inbounds i64, ptr %0, i64 %21
  %87 = getelementptr inbounds i8, ptr %86, i64 16
  %88 = add nsw i64 %17, 2
  %89 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %87, ptr noundef %5, ptr noundef nonnull %33, i64 noundef %88) #15
  br label %90

90:                                               ; preds = %93, %83
  %91 = phi i64 [ %88, %83 ], [ %94, %93 ]
  %92 = icmp sgt i64 %91, 0
  br i1 %92, label %93, label %107

93:                                               ; preds = %90
  %94 = add nsw i64 %91, -1
  %95 = getelementptr inbounds i64, ptr %5, i64 %94
  %96 = load i64, ptr %95, align 8, !tbaa !9
  %97 = getelementptr inbounds i64, ptr %33, i64 %94
  %98 = load i64, ptr %97, align 8, !tbaa !9
  %99 = icmp eq i64 %96, %98
  br i1 %99, label %90, label %100, !llvm.loop !276

100:                                              ; preds = %93
  %101 = icmp ugt i64 %96, %98
  br i1 %101, label %107, label %102

102:                                              ; preds = %100
  %103 = getelementptr inbounds i64, ptr %0, i64 %18
  %104 = getelementptr inbounds i8, ptr %103, i64 8
  %105 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %104, ptr noundef nonnull %33, ptr noundef %5, i64 noundef %88) #15
  %106 = xor i32 %31, 2
  br label %111

107:                                              ; preds = %100, %90
  %108 = getelementptr inbounds i64, ptr %0, i64 %18
  %109 = getelementptr inbounds i8, ptr %108, i64 8
  %110 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %109, ptr noundef %5, ptr noundef nonnull %33, i64 noundef %88) #15
  br label %111

111:                                              ; preds = %107, %102
  %112 = phi i32 [ %106, %102 ], [ %31, %107 ]
  %113 = getelementptr inbounds i64, ptr %0, i64 %25
  %114 = getelementptr inbounds i8, ptr %113, i64 32
  %115 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %114, ptr noundef nonnull %29, ptr noundef %1, i64 noundef %18, i64 noundef %20, ptr noundef %5) #15
  %116 = and i32 %115, 1
  %117 = xor i32 %116, %112
  %118 = icmp eq i64 %22, 0
  br i1 %118, label %132, label %119

119:                                              ; preds = %111
  %120 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %33, ptr noundef %3, ptr noundef %37, i64 noundef %22) #15
  %121 = icmp eq i64 %120, 0
  br i1 %121, label %132, label %122

122:                                              ; preds = %125, %119
  %123 = phi i64 [ %129, %125 ], [ %22, %119 ]
  %124 = icmp sgt i64 %123, %17
  br i1 %124, label %144, label %125

125:                                              ; preds = %122
  %126 = getelementptr inbounds i64, ptr %3, i64 %123
  %127 = load i64, ptr %126, align 8, !tbaa !9
  %128 = add i64 %127, 1
  %129 = add nsw i64 %123, 1
  %130 = getelementptr inbounds i64, ptr %33, i64 %123
  store i64 %128, ptr %130, align 8, !tbaa !9
  %131 = icmp eq i64 %128, 0
  br i1 %131, label %122, label %132, !llvm.loop !277

132:                                              ; preds = %125, %119, %111
  %133 = phi i64 [ %22, %119 ], [ 0, %111 ], [ %129, %125 ]
  %134 = icmp ne ptr %33, %3
  %135 = icmp sle i64 %133, %17
  %136 = select i1 %134, i1 %135, i1 false
  br i1 %136, label %137, label %144

137:                                              ; preds = %137, %132
  %138 = phi i64 [ %142, %137 ], [ %133, %132 ]
  %139 = getelementptr inbounds i64, ptr %3, i64 %138
  %140 = load i64, ptr %139, align 8, !tbaa !9
  %141 = getelementptr inbounds i64, ptr %33, i64 %138
  store i64 %140, ptr %141, align 8, !tbaa !9
  %142 = add nsw i64 %138, 1
  %143 = icmp eq i64 %138, %17
  br i1 %143, label %144, label %137, !llvm.loop !278

144:                                              ; preds = %137, %132, %122
  %145 = phi i64 [ 0, %132 ], [ 0, %137 ], [ 1, %122 ]
  store i64 %145, ptr %36, align 8, !tbaa !9
  %146 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef nonnull %33, ptr noundef %34, i64 noundef %18) #15
  %147 = add i64 %146, %145
  %148 = getelementptr inbounds i64, ptr %0, i64 %18
  store i64 %147, ptr %148, align 8, !tbaa !9
  %149 = load i64, ptr %36, align 8, !tbaa !9
  %150 = icmp eq i64 %149, 0
  br i1 %150, label %151, label %166

151:                                              ; preds = %154, %144
  %152 = phi i64 [ %155, %154 ], [ %18, %144 ]
  %153 = icmp sgt i64 %152, 0
  br i1 %153, label %154, label %166

154:                                              ; preds = %151
  %155 = add nsw i64 %152, -1
  %156 = getelementptr inbounds i64, ptr %33, i64 %155
  %157 = load i64, ptr %156, align 8, !tbaa !9
  %158 = getelementptr inbounds i64, ptr %34, i64 %155
  %159 = load i64, ptr %158, align 8, !tbaa !9
  %160 = icmp eq i64 %157, %159
  br i1 %160, label %151, label %161, !llvm.loop !276

161:                                              ; preds = %154
  %162 = icmp ugt i64 %157, %159
  br i1 %162, label %166, label %163

163:                                              ; preds = %161
  %164 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %33, ptr noundef %34, ptr noundef nonnull %33, i64 noundef %18) #15
  %165 = xor i32 %117, 1
  br label %170

166:                                              ; preds = %161, %151, %144
  %167 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %33, ptr noundef nonnull %33, ptr noundef %34, i64 noundef %18) #15
  %168 = load i64, ptr %36, align 8, !tbaa !9
  %169 = sub i64 %168, %167
  store i64 %169, ptr %36, align 8, !tbaa !9
  br label %170

170:                                              ; preds = %166, %163
  %171 = phi i32 [ %165, %163 ], [ %117, %166 ]
  store i64 0, ptr %32, align 8, !tbaa !9
  %172 = getelementptr inbounds i64, ptr %29, i64 %18
  %173 = load i64, ptr %172, align 8, !tbaa !9
  %174 = load i64, ptr %36, align 8, !tbaa !9
  %175 = or i64 %174, %173
  %176 = add i64 %175, %18
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef nonnull %29, ptr noundef nonnull %33, i64 noundef %176) #15
  %177 = getelementptr inbounds i8, ptr %32, i64 8
  %178 = getelementptr inbounds i8, ptr %148, i64 8
  tail call void @__gmpn_mul_n(ptr noundef nonnull %177, ptr noundef nonnull %27, ptr noundef nonnull %178, i64 noundef %88) #15
  %179 = getelementptr inbounds i8, ptr %26, i64 16
  tail call void @__gmpn_mul_n(ptr noundef nonnull %179, ptr noundef nonnull %24, ptr noundef nonnull %87, i64 noundef %88) #15
  tail call void @__gmpn_mul_n(ptr noundef %86, ptr noundef nonnull %114, ptr noundef %0, i64 noundef %88) #15
  %180 = icmp sgt i64 %20, %22
  %181 = mul i64 %18, 40
  %182 = getelementptr inbounds i8, ptr %0, i64 %181
  %183 = getelementptr inbounds i64, ptr %1, i64 %19
  br i1 %180, label %184, label %186

184:                                              ; preds = %170
  %185 = tail call i64 @__gmpn_mul(ptr noundef %182, ptr noundef %183, i64 noundef %20, ptr noundef %37, i64 noundef %22) #15
  br label %188

186:                                              ; preds = %170
  %187 = tail call i64 @__gmpn_mul(ptr noundef %182, ptr noundef %37, i64 noundef %22, ptr noundef %183, i64 noundef %20) #15
  br label %188

188:                                              ; preds = %186, %184
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %18) #15
  %189 = add nsw i64 %22, %20
  tail call void @__gmpn_toom_interpolate_6pts(ptr noundef %0, i64 noundef %18, i32 noundef %171, ptr noundef %5, ptr noundef nonnull %177, ptr noundef nonnull %179, i64 noundef %189) #15
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_rshift(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #5 {
  %5 = sub i32 64, %3
  %6 = load i64, ptr %1, align 8, !tbaa !9
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
  %18 = load i64, ptr %17, align 8, !tbaa !9
  %19 = shl i64 %18, %7
  %20 = or i64 %19, %13
  %21 = getelementptr inbounds i8, ptr %15, i64 8
  store i64 %20, ptr %15, align 8, !tbaa !9
  %22 = add nsw i64 %14, -1
  %23 = lshr i64 %18, %8
  %24 = icmp eq i64 %22, 0
  br i1 %24, label %25, label %12, !llvm.loop !279

25:                                               ; preds = %12, %4
  %26 = phi ptr [ %0, %4 ], [ %21, %12 ]
  %27 = phi i64 [ %10, %4 ], [ %23, %12 ]
  %28 = shl i64 %6, %7
  store i64 %27, ptr %26, align 8, !tbaa !9
  ret i64 %28
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #3 {
  %4 = alloca [366 x i64], align 16
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = icmp sgt i64 %2, 49
  br i1 %8, label %10, label %9

9:                                                ; preds = %3
  tail call void @__gmpn_sqr_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2) #15
  br label %36

10:                                               ; preds = %3
  %11 = icmp sgt i64 %2, 119
  br i1 %11, label %13, label %12

12:                                               ; preds = %10
  call void @llvm.lifetime.start.p0(i64 2928, ptr nonnull %4) #15
  call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef nonnull %4) #15
  call void @llvm.lifetime.end.p0(i64 2928, ptr nonnull %4) #15
  br label %36

13:                                               ; preds = %10
  %14 = icmp sgt i64 %2, 399
  br i1 %14, label %20, label %15

15:                                               ; preds = %13
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #15
  store ptr null, ptr %5, align 8, !tbaa !5
  %16 = mul i64 %2, 24
  %17 = add i64 %16, 512
  %18 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %5, i64 noundef %17) #15
  call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %18) #15
  %19 = load ptr, ptr %5, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %19) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #15
  br label %36

20:                                               ; preds = %13
  %21 = icmp sgt i64 %2, 449
  br i1 %21, label %27, label %22

22:                                               ; preds = %20
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #15
  store ptr null, ptr %6, align 8, !tbaa !5
  %23 = shl i64 %2, 4
  %24 = add i64 %23, 3312
  %25 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %6, i64 noundef %24) #15
  call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %25) #15
  %26 = load ptr, ptr %6, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %26) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #15
  br label %36

27:                                               ; preds = %20
  %28 = icmp sgt i64 %2, 3599
  br i1 %28, label %35, label %29

29:                                               ; preds = %27
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #15
  store ptr null, ptr %7, align 8, !tbaa !5
  %30 = mul nuw nsw i64 %2, 15
  %31 = and i64 %30, 9223372036854775800
  %32 = add nuw i64 %31, 3768
  %33 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %32) #15
  call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %33) #15
  %34 = load ptr, ptr %7, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %34) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #15
  br label %36

35:                                               ; preds = %27
  tail call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %1, i64 noundef %2) #15
  br label %36

36:                                               ; preds = %35, %29, %22, %15, %12, %9
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @__gmpn_toom_eval_pm2(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, ptr noundef %6) local_unnamed_addr #3 {
  %8 = zext i32 %2 to i64
  %9 = mul nsw i64 %8, %4
  %10 = getelementptr inbounds i64, ptr %3, i64 %9
  %11 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %10, i64 noundef %5, i32 noundef 2) #15
  %12 = add i32 %2, -2
  %13 = zext i32 %12 to i64
  %14 = mul nsw i64 %13, %4
  %15 = getelementptr inbounds i64, ptr %3, i64 %14
  %16 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %15, i64 noundef %5) #15
  %17 = add i64 %16, %11
  %18 = icmp eq i64 %5, %4
  br i1 %18, label %60, label %19

19:                                               ; preds = %7
  %20 = getelementptr inbounds i64, ptr %0, i64 %5
  %21 = getelementptr inbounds i64, ptr %15, i64 %5
  %22 = sub nsw i64 %4, %5
  %23 = load i64, ptr %21, align 8, !tbaa !9
  %24 = add i64 %23, %17
  store i64 %24, ptr %20, align 8, !tbaa !9
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
  %33 = load i64, ptr %32, align 8, !tbaa !9
  %34 = add i64 %33, 1
  %35 = getelementptr inbounds i64, ptr %20, i64 %29
  store i64 %34, ptr %35, align 8, !tbaa !9
  %36 = add nuw i64 %29, 1
  %37 = icmp eq i64 %34, 0
  br i1 %37, label %28, label %38, !llvm.loop !280

38:                                               ; preds = %31
  %39 = icmp ne ptr %15, %0
  %40 = icmp slt i64 %36, %22
  %41 = select i1 %39, i1 %40, i1 false
  br i1 %41, label %42, label %60

42:                                               ; preds = %42, %38
  %43 = phi i64 [ %47, %42 ], [ %36, %38 ]
  %44 = getelementptr inbounds i64, ptr %21, i64 %43
  %45 = load i64, ptr %44, align 8, !tbaa !9
  %46 = getelementptr inbounds i64, ptr %20, i64 %43
  store i64 %45, ptr %46, align 8, !tbaa !9
  %47 = add nuw nsw i64 %43, 1
  %48 = icmp slt i64 %47, %22
  br i1 %48, label %42, label %60, !llvm.loop !281

49:                                               ; preds = %19
  %50 = icmp ne ptr %15, %0
  %51 = icmp sgt i64 %22, 1
  %52 = and i1 %50, %51
  br i1 %52, label %53, label %60

53:                                               ; preds = %53, %49
  %54 = phi i64 [ %58, %53 ], [ 1, %49 ]
  %55 = getelementptr inbounds i64, ptr %21, i64 %54
  %56 = load i64, ptr %55, align 8, !tbaa !9
  %57 = getelementptr inbounds i64, ptr %20, i64 %54
  store i64 %56, ptr %57, align 8, !tbaa !9
  %58 = add nuw nsw i64 %54, 1
  %59 = icmp eq i64 %58, %22
  br i1 %59, label %60, label %53, !llvm.loop !282

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
  %70 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %4, i32 noundef 2) #15
  %71 = add i64 %70, %69
  %72 = mul nsw i64 %67, %4
  %73 = getelementptr inbounds i64, ptr %3, i64 %72
  %74 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %73, i64 noundef %4) #15
  %75 = add i64 %71, %74
  %76 = add nsw i64 %67, -2
  %77 = icmp sgt i64 %67, 1
  br i1 %77, label %66, label %78, !llvm.loop !283

78:                                               ; preds = %66, %60
  %79 = phi i64 [ %61, %60 ], [ %75, %66 ]
  %80 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %79, ptr %80, align 8, !tbaa !9
  %81 = add i32 %2, -1
  %82 = zext i32 %81 to i64
  %83 = mul nsw i64 %82, %4
  %84 = getelementptr inbounds i64, ptr %3, i64 %83
  %85 = tail call i64 @__gmpn_lshift(ptr noundef %6, ptr noundef %84, i64 noundef %4, i32 noundef 2) #15
  %86 = add i32 %2, -3
  %87 = zext i32 %86 to i64
  %88 = mul nsw i64 %87, %4
  %89 = getelementptr inbounds i64, ptr %3, i64 %88
  %90 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %89, i64 noundef %4) #15
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
  %100 = tail call i64 @__gmpn_lshift(ptr noundef %6, ptr noundef %6, i64 noundef %4, i32 noundef 2) #15
  %101 = add i64 %100, %99
  %102 = mul nsw i64 %97, %4
  %103 = getelementptr inbounds i64, ptr %3, i64 %102
  %104 = tail call i64 @__gmpn_add_n(ptr noundef %6, ptr noundef %6, ptr noundef %103, i64 noundef %4) #15
  %105 = add i64 %101, %104
  %106 = add nsw i64 %97, -2
  %107 = icmp sgt i64 %97, 1
  br i1 %107, label %96, label %108, !llvm.loop !284

108:                                              ; preds = %96, %78
  %109 = phi i64 [ %91, %78 ], [ %105, %96 ]
  %110 = getelementptr inbounds i64, ptr %6, i64 %4
  store i64 %109, ptr %110, align 8, !tbaa !9
  %111 = and i32 %81, 1
  %112 = icmp eq i32 %111, 0
  %113 = add nsw i64 %4, 1
  br i1 %112, label %116, label %114

114:                                              ; preds = %108
  %115 = tail call i64 @__gmpn_lshift(ptr noundef %6, ptr noundef %6, i64 noundef %113, i32 noundef 1) #15
  br label %118

116:                                              ; preds = %108
  %117 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %0, i64 noundef %113, i32 noundef 1) #15
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
  %126 = load i64, ptr %125, align 8, !tbaa !9
  %127 = getelementptr inbounds i64, ptr %6, i64 %124
  %128 = load i64, ptr %127, align 8, !tbaa !9
  %129 = icmp eq i64 %126, %128
  br i1 %129, label %120, label %130, !llvm.loop !285

130:                                              ; preds = %123
  %131 = icmp ugt i64 %126, %128
  %132 = select i1 %131, i32 1, i32 -1
  br label %133

133:                                              ; preds = %130, %120
  %134 = phi i32 [ %132, %130 ], [ 0, %120 ]
  %135 = icmp slt i32 %134, 0
  br i1 %135, label %136, label %138

136:                                              ; preds = %133
  %137 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %6, ptr noundef %0, i64 noundef %119) #15
  br label %140

138:                                              ; preds = %133
  %139 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %6, i64 noundef %119) #15
  br label %140

140:                                              ; preds = %138, %136
  %141 = ashr i32 %134, 31
  %142 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %6, i64 noundef %119) #15
  %143 = add nsw i32 %111, -1
  %144 = xor i32 %141, %143
  ret i32 %144
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define i64 @__gmpn_lshiftc(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #5 {
  %5 = getelementptr inbounds i64, ptr %1, i64 %2
  %6 = getelementptr inbounds i64, ptr %0, i64 %2
  %7 = sub i32 64, %3
  %8 = getelementptr inbounds i8, ptr %5, i64 -8
  %9 = load i64, ptr %8, align 8, !tbaa !9
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
  %21 = load i64, ptr %20, align 8, !tbaa !9
  %22 = lshr i64 %21, %10
  %23 = or i64 %22, %16
  %24 = xor i64 %23, -1
  %25 = getelementptr inbounds i8, ptr %18, i64 -8
  store i64 %24, ptr %25, align 8, !tbaa !9
  %26 = add nsw i64 %17, -1
  %27 = shl i64 %21, %11
  %28 = icmp eq i64 %26, 0
  br i1 %28, label %29, label %15, !llvm.loop !286

29:                                               ; preds = %15, %4
  %30 = phi ptr [ %6, %4 ], [ %25, %15 ]
  %31 = phi i64 [ %13, %4 ], [ %27, %15 ]
  %32 = lshr i64 %9, %10
  %33 = xor i64 %31, -1
  %34 = getelementptr inbounds i8, ptr %30, i64 -8
  store i64 %33, ptr %34, align 8, !tbaa !9
  ret i64 %32
}

; Function Attrs: nounwind ssp uwtable
define i64 @__gmpn_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #3 {
  %6 = alloca [30 x i64], align 16
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = icmp sgt i64 %2, 29
  br i1 %11, label %13, label %12

12:                                               ; preds = %5
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) #15
  br label %480

13:                                               ; preds = %5
  %14 = icmp eq i64 %2, %4
  br i1 %14, label %15, label %16

15:                                               ; preds = %13
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %2) #15
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
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) #15
  br label %480

23:                                               ; preds = %18
  call void @llvm.lifetime.start.p0(i64 240, ptr nonnull %6) #15
  tail call void @__gmpn_mul_basecase(ptr noundef %0, ptr noundef %1, i64 noundef 500, ptr noundef %3, i64 noundef %4) #15
  %24 = getelementptr inbounds i8, ptr %0, i64 4000
  %25 = icmp eq i64 %4, 0
  br i1 %25, label %45, label %26

26:                                               ; preds = %23
  %27 = add nsw i64 %4, -1
  %28 = load i64, ptr %24, align 8, !tbaa !9
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
  store i64 %33, ptr %35, align 8, !tbaa !9
  %38 = getelementptr inbounds i8, ptr %34, i64 8
  %39 = load i64, ptr %34, align 8, !tbaa !9
  %40 = add nsw i64 %36, -1
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %42, label %32, !llvm.loop !287

42:                                               ; preds = %32, %26
  %43 = phi i64 [ %28, %26 ], [ %39, %32 ]
  %44 = phi ptr [ %6, %26 ], [ %37, %32 ]
  store i64 %43, ptr %44, align 8, !tbaa !9
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
  call void @__gmpn_mul_basecase(ptr noundef nonnull %55, ptr noundef nonnull %53, i64 noundef 500, ptr noundef %3, i64 noundef %4) #15
  %56 = call i64 @__gmpn_add_n(ptr noundef nonnull %55, ptr noundef nonnull %55, ptr noundef nonnull %6, i64 noundef %4) #15
  %57 = getelementptr inbounds i64, ptr %55, i64 %4
  %58 = load i64, ptr %57, align 8, !tbaa !9
  %59 = add i64 %58, %56
  store i64 %59, ptr %57, align 8, !tbaa !9
  %60 = icmp ult i64 %59, %56
  br i1 %60, label %61, label %67

61:                                               ; preds = %61, %52
  %62 = phi ptr [ %63, %61 ], [ %57, %52 ]
  %63 = getelementptr inbounds i8, ptr %62, i64 8
  %64 = load i64, ptr %63, align 8, !tbaa !9
  %65 = add i64 %64, 1
  store i64 %65, ptr %63, align 8, !tbaa !9
  %66 = icmp eq i64 %65, 0
  br i1 %66, label %61, label %67, !llvm.loop !288

67:                                               ; preds = %61, %52
  %68 = getelementptr inbounds i8, ptr %55, i64 4000
  br i1 %25, label %86, label %69

69:                                               ; preds = %67
  %70 = load i64, ptr %68, align 8, !tbaa !9
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
  store i64 %74, ptr %76, align 8, !tbaa !9
  %79 = getelementptr inbounds i8, ptr %75, i64 8
  %80 = load i64, ptr %75, align 8, !tbaa !9
  %81 = add nsw i64 %77, -1
  %82 = icmp eq i64 %81, 0
  br i1 %82, label %83, label %73, !llvm.loop !289

83:                                               ; preds = %73, %69
  %84 = phi i64 [ %70, %69 ], [ %80, %73 ]
  %85 = phi ptr [ %6, %69 ], [ %78, %73 ]
  store i64 %84, ptr %85, align 8, !tbaa !9
  br label %86

86:                                               ; preds = %83, %67
  %87 = add nsw i64 %54, -500
  %88 = getelementptr inbounds i8, ptr %53, i64 4000
  %89 = icmp sgt i64 %54, 1000
  br i1 %89, label %52, label %90, !llvm.loop !290

90:                                               ; preds = %86, %45
  %91 = phi ptr [ %24, %45 ], [ %68, %86 ]
  %92 = phi i64 [ %46, %45 ], [ %87, %86 ]
  %93 = phi ptr [ %47, %45 ], [ %88, %86 ]
  %94 = icmp sgt i64 %92, %4
  br i1 %94, label %95, label %96

95:                                               ; preds = %90
  call void @__gmpn_mul_basecase(ptr noundef nonnull %91, ptr noundef nonnull %93, i64 noundef %92, ptr noundef %3, i64 noundef %4) #15
  br label %97

96:                                               ; preds = %90
  call void @__gmpn_mul_basecase(ptr noundef nonnull %91, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %93, i64 noundef %92) #15
  br label %97

97:                                               ; preds = %96, %95
  %98 = call i64 @__gmpn_add_n(ptr noundef nonnull %91, ptr noundef nonnull %91, ptr noundef nonnull %6, i64 noundef %4) #15
  %99 = getelementptr inbounds i64, ptr %91, i64 %4
  %100 = load i64, ptr %99, align 8, !tbaa !9
  %101 = add i64 %100, %98
  store i64 %101, ptr %99, align 8, !tbaa !9
  %102 = icmp ult i64 %101, %98
  br i1 %102, label %103, label %109

103:                                              ; preds = %103, %97
  %104 = phi ptr [ %105, %103 ], [ %99, %97 ]
  %105 = getelementptr inbounds i8, ptr %104, i64 8
  %106 = load i64, ptr %105, align 8, !tbaa !9
  %107 = add i64 %106, 1
  store i64 %107, ptr %105, align 8, !tbaa !9
  %108 = icmp eq i64 %107, 0
  br i1 %108, label %103, label %109, !llvm.loop !291

109:                                              ; preds = %103, %97
  call void @llvm.lifetime.end.p0(i64 240, ptr nonnull %6) #15
  br label %480

110:                                              ; preds = %16
  %111 = icmp sgt i64 %4, 99
  br i1 %111, label %222, label %112

112:                                              ; preds = %110
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #15
  store ptr null, ptr %7, align 8, !tbaa !5
  %113 = mul i64 %4, 36
  %114 = and i64 %113, -8
  %115 = add i64 %114, 1024
  %116 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %115) #15
  %117 = mul nuw nsw i64 %4, 3
  %118 = icmp sgt i64 %117, %2
  br i1 %118, label %208, label %119

119:                                              ; preds = %112
  %120 = shl nuw nsw i64 %4, 5
  %121 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %7, i64 noundef %120) #15
  %122 = shl nuw nsw i64 %4, 1
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %122, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
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
  call void @__gmpn_toom42_mul(ptr noundef %121, ptr noundef %132, i64 noundef %122, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  %134 = call i64 @__gmpn_add_n(ptr noundef %133, ptr noundef %133, ptr noundef %121, i64 noundef %4) #15
  %135 = getelementptr inbounds i64, ptr %133, i64 %4
  %136 = load i64, ptr %129, align 8, !tbaa !9
  br label %137

137:                                              ; preds = %137, %130
  %138 = phi i64 [ %128, %130 ], [ %145, %137 ]
  %139 = phi ptr [ %135, %130 ], [ %143, %137 ]
  %140 = phi ptr [ %129, %130 ], [ %142, %137 ]
  %141 = phi i64 [ %136, %130 ], [ %144, %137 ]
  %142 = getelementptr inbounds i8, ptr %140, i64 8
  %143 = getelementptr inbounds i8, ptr %139, i64 8
  store i64 %141, ptr %139, align 8, !tbaa !9
  %144 = load i64, ptr %142, align 8, !tbaa !9
  %145 = add nsw i64 %138, -1
  %146 = icmp eq i64 %145, 0
  br i1 %146, label %147, label %137, !llvm.loop !292

147:                                              ; preds = %137
  store i64 %144, ptr %143, align 8, !tbaa !9
  %148 = load i64, ptr %135, align 8, !tbaa !9
  %149 = add i64 %148, %134
  store i64 %149, ptr %135, align 8, !tbaa !9
  %150 = icmp ult i64 %149, %134
  br i1 %150, label %151, label %157

151:                                              ; preds = %151, %147
  %152 = phi ptr [ %153, %151 ], [ %135, %147 ]
  %153 = getelementptr inbounds i8, ptr %152, i64 8
  %154 = load i64, ptr %153, align 8, !tbaa !9
  %155 = add i64 %154, 1
  store i64 %155, ptr %153, align 8, !tbaa !9
  %156 = icmp eq i64 %155, 0
  br i1 %156, label %151, label %157, !llvm.loop !293

157:                                              ; preds = %151, %147
  %158 = getelementptr inbounds i64, ptr %133, i64 %122
  %159 = getelementptr inbounds i64, ptr %132, i64 %122
  %160 = sub nsw i64 %131, %122
  %161 = icmp slt i64 %160, %117
  br i1 %161, label %162, label %130, !llvm.loop !294

162:                                              ; preds = %157, %119
  %163 = phi ptr [ %123, %119 ], [ %158, %157 ]
  %164 = phi ptr [ %124, %119 ], [ %159, %157 ]
  %165 = phi i64 [ %125, %119 ], [ %160, %157 ]
  %166 = shl nsw i64 %165, 2
  %167 = mul nuw nsw i64 %4, 5
  %168 = icmp slt i64 %166, %167
  br i1 %168, label %169, label %170

169:                                              ; preds = %162
  call void @__gmpn_toom22_mul(ptr noundef %121, ptr noundef %164, i64 noundef %165, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  br label %175

170:                                              ; preds = %162
  %171 = mul nuw nsw i64 %4, 7
  %172 = icmp slt i64 %166, %171
  br i1 %172, label %173, label %174

173:                                              ; preds = %170
  call void @__gmpn_toom32_mul(ptr noundef %121, ptr noundef %164, i64 noundef %165, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  br label %175

174:                                              ; preds = %170
  call void @__gmpn_toom42_mul(ptr noundef %121, ptr noundef %164, i64 noundef %165, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  br label %175

175:                                              ; preds = %174, %173, %169
  %176 = call i64 @__gmpn_add_n(ptr noundef %163, ptr noundef %163, ptr noundef %121, i64 noundef %4) #15
  %177 = icmp eq i64 %165, 0
  br i1 %177, label %197, label %178

178:                                              ; preds = %175
  %179 = add nsw i64 %165, -1
  %180 = getelementptr inbounds i64, ptr %163, i64 %4
  %181 = getelementptr inbounds i64, ptr %121, i64 %4
  %182 = load i64, ptr %181, align 8, !tbaa !9
  %183 = icmp eq i64 %179, 0
  br i1 %183, label %194, label %184

184:                                              ; preds = %184, %178
  %185 = phi i64 [ %192, %184 ], [ %179, %178 ]
  %186 = phi ptr [ %190, %184 ], [ %180, %178 ]
  %187 = phi ptr [ %189, %184 ], [ %181, %178 ]
  %188 = phi i64 [ %191, %184 ], [ %182, %178 ]
  %189 = getelementptr inbounds i8, ptr %187, i64 8
  %190 = getelementptr inbounds i8, ptr %186, i64 8
  store i64 %188, ptr %186, align 8, !tbaa !9
  %191 = load i64, ptr %189, align 8, !tbaa !9
  %192 = add nsw i64 %185, -1
  %193 = icmp eq i64 %192, 0
  br i1 %193, label %194, label %184, !llvm.loop !295

194:                                              ; preds = %184, %178
  %195 = phi ptr [ %180, %178 ], [ %190, %184 ]
  %196 = phi i64 [ %182, %178 ], [ %191, %184 ]
  store i64 %196, ptr %195, align 8, !tbaa !9
  br label %197

197:                                              ; preds = %194, %175
  %198 = getelementptr inbounds i64, ptr %163, i64 %4
  %199 = load i64, ptr %198, align 8, !tbaa !9
  %200 = add i64 %199, %176
  store i64 %200, ptr %198, align 8, !tbaa !9
  %201 = icmp ult i64 %200, %176
  br i1 %201, label %202, label %218

202:                                              ; preds = %202, %197
  %203 = phi ptr [ %204, %202 ], [ %198, %197 ]
  %204 = getelementptr inbounds i8, ptr %203, i64 8
  %205 = load i64, ptr %204, align 8, !tbaa !9
  %206 = add i64 %205, 1
  store i64 %206, ptr %204, align 8, !tbaa !9
  %207 = icmp eq i64 %206, 0
  br i1 %207, label %202, label %218, !llvm.loop !296

208:                                              ; preds = %112
  %209 = shl nuw nsw i64 %2, 2
  %210 = mul nuw nsw i64 %4, 5
  %211 = icmp slt i64 %209, %210
  br i1 %211, label %212, label %213

212:                                              ; preds = %208
  call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  br label %218

213:                                              ; preds = %208
  %214 = mul nuw nsw i64 %4, 7
  %215 = icmp slt i64 %209, %214
  br i1 %215, label %216, label %217

216:                                              ; preds = %213
  call void @__gmpn_toom32_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  br label %218

217:                                              ; preds = %213
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %116) #15
  br label %218

218:                                              ; preds = %217, %216, %212, %202, %197
  %219 = phi i64 [ %2, %212 ], [ %2, %216 ], [ %2, %217 ], [ %165, %197 ], [ %165, %202 ]
  %220 = phi ptr [ %0, %212 ], [ %0, %216 ], [ %0, %217 ], [ %163, %197 ], [ %163, %202 ]
  %221 = load ptr, ptr %7, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %221) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #15
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
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #15
  store ptr null, ptr %8, align 8, !tbaa !5
  %236 = shl i64 %4, 5
  %237 = add i64 %236, 512
  %238 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %237) #15
  %239 = shl nuw nsw i64 %2, 1
  %240 = mul nuw nsw i64 %4, 5
  %241 = icmp slt i64 %239, %240
  br i1 %241, label %338, label %242

242:                                              ; preds = %235
  %243 = mul i64 %4, 28
  %244 = and i64 %243, -8
  %245 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %244) #15
  %246 = icmp sgt i64 %4, 109
  %247 = shl nuw nsw i64 %4, 1
  br i1 %246, label %249, label %248

248:                                              ; preds = %242
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %247, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %250

249:                                              ; preds = %242
  call void @__gmpn_toom63_mul(ptr noundef %0, ptr noundef %1, i64 noundef %247, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
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
  call void @__gmpn_toom42_mul(ptr noundef %245, ptr noundef nonnull %262, i64 noundef %251, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %266

265:                                              ; preds = %260
  call void @__gmpn_toom63_mul(ptr noundef %245, ptr noundef nonnull %262, i64 noundef %251, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %266

266:                                              ; preds = %265, %264
  %267 = call i64 @__gmpn_add_n(ptr noundef nonnull %263, ptr noundef nonnull %263, ptr noundef %245, i64 noundef %4) #15
  %268 = getelementptr inbounds i64, ptr %263, i64 %4
  %269 = load i64, ptr %259, align 8, !tbaa !9
  br label %270

270:                                              ; preds = %270, %266
  %271 = phi i64 [ %258, %266 ], [ %278, %270 ]
  %272 = phi ptr [ %268, %266 ], [ %276, %270 ]
  %273 = phi ptr [ %259, %266 ], [ %275, %270 ]
  %274 = phi i64 [ %269, %266 ], [ %277, %270 ]
  %275 = getelementptr inbounds i8, ptr %273, i64 8
  %276 = getelementptr inbounds i8, ptr %272, i64 8
  store i64 %274, ptr %272, align 8, !tbaa !9
  %277 = load i64, ptr %275, align 8, !tbaa !9
  %278 = add nsw i64 %271, -1
  %279 = icmp eq i64 %278, 0
  br i1 %279, label %280, label %270, !llvm.loop !297

280:                                              ; preds = %270
  store i64 %277, ptr %276, align 8, !tbaa !9
  %281 = load i64, ptr %268, align 8, !tbaa !9
  %282 = add i64 %281, %267
  store i64 %282, ptr %268, align 8, !tbaa !9
  %283 = icmp ult i64 %282, %267
  br i1 %283, label %284, label %290

284:                                              ; preds = %284, %280
  %285 = phi ptr [ %286, %284 ], [ %268, %280 ]
  %286 = getelementptr inbounds i8, ptr %285, i64 8
  %287 = load i64, ptr %286, align 8, !tbaa !9
  %288 = add i64 %287, 1
  store i64 %288, ptr %286, align 8, !tbaa !9
  %289 = icmp eq i64 %288, 0
  br i1 %289, label %284, label %290, !llvm.loop !298

290:                                              ; preds = %284, %280
  %291 = getelementptr inbounds i64, ptr %263, i64 %251
  %292 = getelementptr inbounds i64, ptr %262, i64 %251
  %293 = sub nsw i64 %261, %251
  %294 = shl nsw i64 %293, 1
  %295 = icmp slt i64 %294, %240
  br i1 %295, label %296, label %260, !llvm.loop !299

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
  %306 = call i64 @__gmpn_add_n(ptr noundef nonnull %297, ptr noundef nonnull %297, ptr noundef %245, i64 noundef %4) #15
  %307 = icmp eq i64 %299, 0
  br i1 %307, label %327, label %308

308:                                              ; preds = %305
  %309 = add nsw i64 %299, -1
  %310 = getelementptr inbounds i64, ptr %297, i64 %4
  %311 = getelementptr inbounds i64, ptr %245, i64 %4
  %312 = load i64, ptr %311, align 8, !tbaa !9
  %313 = icmp eq i64 %309, 0
  br i1 %313, label %324, label %314

314:                                              ; preds = %314, %308
  %315 = phi i64 [ %322, %314 ], [ %309, %308 ]
  %316 = phi ptr [ %320, %314 ], [ %310, %308 ]
  %317 = phi ptr [ %319, %314 ], [ %311, %308 ]
  %318 = phi i64 [ %321, %314 ], [ %312, %308 ]
  %319 = getelementptr inbounds i8, ptr %317, i64 8
  %320 = getelementptr inbounds i8, ptr %316, i64 8
  store i64 %318, ptr %316, align 8, !tbaa !9
  %321 = load i64, ptr %319, align 8, !tbaa !9
  %322 = add nsw i64 %315, -1
  %323 = icmp eq i64 %322, 0
  br i1 %323, label %324, label %314, !llvm.loop !300

324:                                              ; preds = %314, %308
  %325 = phi ptr [ %310, %308 ], [ %320, %314 ]
  %326 = phi i64 [ %312, %308 ], [ %321, %314 ]
  store i64 %326, ptr %325, align 8, !tbaa !9
  br label %327

327:                                              ; preds = %324, %305
  %328 = getelementptr inbounds i64, ptr %297, i64 %4
  %329 = load i64, ptr %328, align 8, !tbaa !9
  %330 = add i64 %329, %306
  store i64 %330, ptr %328, align 8, !tbaa !9
  %331 = icmp ult i64 %330, %306
  br i1 %331, label %332, label %362

332:                                              ; preds = %332, %327
  %333 = phi ptr [ %334, %332 ], [ %328, %327 ]
  %334 = getelementptr inbounds i8, ptr %333, i64 8
  %335 = load i64, ptr %334, align 8, !tbaa !9
  %336 = add i64 %335, 1
  store i64 %336, ptr %334, align 8, !tbaa !9
  %337 = icmp eq i64 %336, 0
  br i1 %337, label %332, label %362, !llvm.loop !301

338:                                              ; preds = %235
  %339 = mul nuw nsw i64 %2, 6
  %340 = mul nuw nsw i64 %4, 7
  %341 = icmp slt i64 %339, %340
  br i1 %341, label %342, label %343

342:                                              ; preds = %338
  call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %362

343:                                              ; preds = %338
  %344 = mul nuw nsw i64 %4, 3
  %345 = icmp slt i64 %239, %344
  br i1 %345, label %346, label %347

346:                                              ; preds = %343
  call void @__gmpn_toom43_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
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
  call void @__gmpn_toom32_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %362

356:                                              ; preds = %353
  call void @__gmpn_toom53_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %362

357:                                              ; preds = %350
  call void @__gmpn_toom53_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %362

358:                                              ; preds = %347
  %359 = icmp sgt i64 %4, 109
  br i1 %359, label %361, label %360

360:                                              ; preds = %358
  call void @__gmpn_toom42_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %362

361:                                              ; preds = %358
  call void @__gmpn_toom63_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %238) #15
  br label %362

362:                                              ; preds = %361, %360, %357, %356, %355, %346, %342, %332, %327
  %363 = phi i64 [ %2, %342 ], [ %2, %346 ], [ %2, %356 ], [ %2, %355 ], [ %2, %357 ], [ %2, %361 ], [ %2, %360 ], [ %299, %327 ], [ %299, %332 ]
  %364 = phi ptr [ %0, %342 ], [ %0, %346 ], [ %0, %356 ], [ %0, %355 ], [ %0, %357 ], [ %0, %361 ], [ %0, %360 ], [ %297, %327 ], [ %297, %332 ]
  %365 = load ptr, ptr %8, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %365) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #15
  br label %480

366:                                              ; preds = %230
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9) #15
  store ptr null, ptr %9, align 8, !tbaa !5
  %367 = icmp sgt i64 %4, 349
  br i1 %367, label %372, label %368

368:                                              ; preds = %366
  %369 = mul i64 %2, 24
  %370 = add i64 %369, 512
  %371 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %370) #15
  call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %371) #15
  br label %384

372:                                              ; preds = %366
  %373 = icmp sgt i64 %4, 449
  br i1 %373, label %379, label %374

374:                                              ; preds = %372
  %375 = udiv i64 %223, 10
  %376 = mul i64 %375, 96
  %377 = add i64 %376, 3408
  %378 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %377) #15
  call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %378) #15
  br label %384

379:                                              ; preds = %372
  %380 = udiv i64 %223, 14
  %381 = mul i64 %380, 120
  %382 = add i64 %381, 3888
  %383 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %9, i64 noundef %382) #15
  call void @__gmpn_toom8h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %383) #15
  br label %384

384:                                              ; preds = %379, %374, %368
  %385 = load ptr, ptr %9, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %385) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9) #15
  br label %480

386:                                              ; preds = %225
  %387 = shl nsw i64 %4, 3
  %388 = icmp sgt i64 %387, %2
  br i1 %388, label %479, label %389

389:                                              ; preds = %386
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10) #15
  store ptr null, ptr %10, align 8, !tbaa !5
  %390 = mul i64 %4, 36
  %391 = and i64 %390, -8
  %392 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %10, i64 noundef %391) #15
  call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %226, ptr noundef %3, i64 noundef %4) #15
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
  call void @__gmpn_nussbaumer_mul(ptr noundef %392, ptr noundef nonnull %404, i64 noundef %226, ptr noundef %3, i64 noundef %4) #15
  %406 = call i64 @__gmpn_add_n(ptr noundef nonnull %405, ptr noundef nonnull %405, ptr noundef %392, i64 noundef %4) #15
  %407 = getelementptr inbounds i64, ptr %405, i64 %4
  %408 = load i64, ptr %401, align 8, !tbaa !9
  br label %409

409:                                              ; preds = %409, %402
  %410 = phi i64 [ %400, %402 ], [ %417, %409 ]
  %411 = phi ptr [ %407, %402 ], [ %415, %409 ]
  %412 = phi ptr [ %401, %402 ], [ %414, %409 ]
  %413 = phi i64 [ %408, %402 ], [ %416, %409 ]
  %414 = getelementptr inbounds i8, ptr %412, i64 8
  %415 = getelementptr inbounds i8, ptr %411, i64 8
  store i64 %413, ptr %411, align 8, !tbaa !9
  %416 = load i64, ptr %414, align 8, !tbaa !9
  %417 = add nsw i64 %410, -1
  %418 = icmp eq i64 %417, 0
  br i1 %418, label %419, label %409, !llvm.loop !302

419:                                              ; preds = %409
  store i64 %416, ptr %415, align 8, !tbaa !9
  %420 = load i64, ptr %407, align 8, !tbaa !9
  %421 = add i64 %420, %406
  store i64 %421, ptr %407, align 8, !tbaa !9
  %422 = icmp ult i64 %421, %406
  br i1 %422, label %423, label %429

423:                                              ; preds = %423, %419
  %424 = phi ptr [ %425, %423 ], [ %407, %419 ]
  %425 = getelementptr inbounds i8, ptr %424, i64 8
  %426 = load i64, ptr %425, align 8, !tbaa !9
  %427 = add i64 %426, 1
  store i64 %427, ptr %425, align 8, !tbaa !9
  %428 = icmp eq i64 %427, 0
  br i1 %428, label %423, label %429, !llvm.loop !303

429:                                              ; preds = %423, %419
  %430 = getelementptr inbounds i64, ptr %405, i64 %226
  %431 = getelementptr inbounds i64, ptr %404, i64 %226
  %432 = sub nsw i64 %403, %226
  %433 = shl nsw i64 %432, 1
  %434 = icmp slt i64 %433, %393
  br i1 %434, label %435, label %402, !llvm.loop !304

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
  %445 = call i64 @__gmpn_add_n(ptr noundef nonnull %436, ptr noundef nonnull %436, ptr noundef %392, i64 noundef %4) #15
  %446 = icmp eq i64 %438, 0
  br i1 %446, label %466, label %447

447:                                              ; preds = %444
  %448 = add nsw i64 %438, -1
  %449 = getelementptr inbounds i64, ptr %436, i64 %4
  %450 = getelementptr inbounds i64, ptr %392, i64 %4
  %451 = load i64, ptr %450, align 8, !tbaa !9
  %452 = icmp eq i64 %448, 0
  br i1 %452, label %463, label %453

453:                                              ; preds = %453, %447
  %454 = phi i64 [ %461, %453 ], [ %448, %447 ]
  %455 = phi ptr [ %459, %453 ], [ %449, %447 ]
  %456 = phi ptr [ %458, %453 ], [ %450, %447 ]
  %457 = phi i64 [ %460, %453 ], [ %451, %447 ]
  %458 = getelementptr inbounds i8, ptr %456, i64 8
  %459 = getelementptr inbounds i8, ptr %455, i64 8
  store i64 %457, ptr %455, align 8, !tbaa !9
  %460 = load i64, ptr %458, align 8, !tbaa !9
  %461 = add nsw i64 %454, -1
  %462 = icmp eq i64 %461, 0
  br i1 %462, label %463, label %453, !llvm.loop !305

463:                                              ; preds = %453, %447
  %464 = phi ptr [ %449, %447 ], [ %459, %453 ]
  %465 = phi i64 [ %451, %447 ], [ %460, %453 ]
  store i64 %465, ptr %464, align 8, !tbaa !9
  br label %466

466:                                              ; preds = %463, %444
  %467 = getelementptr inbounds i64, ptr %436, i64 %4
  %468 = load i64, ptr %467, align 8, !tbaa !9
  %469 = add i64 %468, %445
  store i64 %469, ptr %467, align 8, !tbaa !9
  %470 = icmp ult i64 %469, %445
  br i1 %470, label %471, label %477

471:                                              ; preds = %471, %466
  %472 = phi ptr [ %473, %471 ], [ %467, %466 ]
  %473 = getelementptr inbounds i8, ptr %472, i64 8
  %474 = load i64, ptr %473, align 8, !tbaa !9
  %475 = add i64 %474, 1
  store i64 %475, ptr %473, align 8, !tbaa !9
  %476 = icmp eq i64 %475, 0
  br i1 %476, label %471, label %477, !llvm.loop !306

477:                                              ; preds = %471, %466
  %478 = load ptr, ptr %10, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %478) #15
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10) #15
  br label %480

479:                                              ; preds = %386
  tail call void @__gmpn_nussbaumer_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4) #15
  br label %480

480:                                              ; preds = %479, %477, %384, %362, %218, %109, %22, %15, %12
  %481 = phi i64 [ %2, %15 ], [ %2, %22 ], [ %92, %109 ], [ %438, %477 ], [ %2, %479 ], [ %2, %384 ], [ %363, %362 ], [ %219, %218 ], [ %2, %12 ]
  %482 = phi ptr [ %0, %15 ], [ %0, %22 ], [ %91, %109 ], [ %436, %477 ], [ %0, %479 ], [ %0, %384 ], [ %364, %362 ], [ %220, %218 ], [ %0, %12 ]
  %483 = add i64 %4, -1
  %484 = add i64 %483, %481
  %485 = getelementptr inbounds i64, ptr %482, i64 %484
  %486 = load i64, ptr %485, align 8, !tbaa !9
  ret i64 %486
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
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
  %27 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %1, ptr noundef %24, i64 noundef %10) #15
  %28 = icmp eq i64 %27, 0
  br i1 %28, label %39, label %29

29:                                               ; preds = %32, %26
  %30 = phi i64 [ %36, %32 ], [ %10, %26 ]
  %31 = icmp slt i64 %30, %8
  br i1 %31, label %32, label %51

32:                                               ; preds = %29
  %33 = getelementptr inbounds i64, ptr %1, i64 %30
  %34 = load i64, ptr %33, align 8, !tbaa !9
  %35 = add i64 %34, 1
  %36 = add nsw i64 %30, 1
  %37 = getelementptr inbounds i64, ptr %5, i64 %30
  store i64 %35, ptr %37, align 8, !tbaa !9
  %38 = icmp eq i64 %35, 0
  br i1 %38, label %29, label %39, !llvm.loop !307

39:                                               ; preds = %32, %26, %6
  %40 = phi i64 [ %10, %26 ], [ 0, %6 ], [ %36, %32 ]
  %41 = icmp ne ptr %5, %1
  %42 = icmp slt i64 %40, %8
  %43 = select i1 %41, i1 %42, i1 false
  br i1 %43, label %44, label %51

44:                                               ; preds = %44, %39
  %45 = phi i64 [ %49, %44 ], [ %40, %39 ]
  %46 = getelementptr inbounds i64, ptr %1, i64 %45
  %47 = load i64, ptr %46, align 8, !tbaa !9
  %48 = getelementptr inbounds i64, ptr %5, i64 %45
  store i64 %47, ptr %48, align 8, !tbaa !9
  %49 = add nsw i64 %45, 1
  %50 = icmp eq i64 %49, %8
  br i1 %50, label %51, label %44, !llvm.loop !308

51:                                               ; preds = %44, %39, %29
  %52 = phi i1 [ true, %39 ], [ true, %44 ], [ false, %29 ]
  %53 = phi i64 [ 0, %39 ], [ 0, %44 ], [ 1, %29 ]
  %54 = getelementptr inbounds i64, ptr %1, i64 %8
  %55 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %14, ptr noundef %5, ptr noundef %54, i64 noundef %8) #15
  %56 = add i64 %55, %53
  %57 = getelementptr inbounds i64, ptr %14, i64 %8
  store i64 %56, ptr %57, align 8, !tbaa !9
  br i1 %52, label %58, label %76

58:                                               ; preds = %61, %51
  %59 = phi i64 [ %62, %61 ], [ %8, %51 ]
  %60 = icmp sgt i64 %59, 0
  br i1 %60, label %61, label %71

61:                                               ; preds = %58
  %62 = add nsw i64 %59, -1
  %63 = getelementptr inbounds i64, ptr %5, i64 %62
  %64 = load i64, ptr %63, align 8, !tbaa !9
  %65 = getelementptr inbounds i64, ptr %54, i64 %62
  %66 = load i64, ptr %65, align 8, !tbaa !9
  %67 = icmp eq i64 %64, %66
  br i1 %67, label %58, label %68, !llvm.loop !309

68:                                               ; preds = %61
  %69 = icmp ugt i64 %64, %66
  %70 = select i1 %69, i32 1, i32 -1
  br label %71

71:                                               ; preds = %68, %58
  %72 = phi i32 [ %70, %68 ], [ 0, %58 ]
  %73 = icmp slt i32 %72, 0
  br i1 %73, label %74, label %76

74:                                               ; preds = %71
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %16, ptr noundef %54, ptr noundef %5, i64 noundef %8) #15
  br label %79

76:                                               ; preds = %71, %51
  %77 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %16, ptr noundef %5, ptr noundef %54, i64 noundef %8) #15
  %78 = sub i64 %53, %77
  br label %79

79:                                               ; preds = %76, %74
  %80 = phi i64 [ %78, %76 ], [ 0, %74 ]
  %81 = phi i32 [ 0, %76 ], [ 1, %74 ]
  %82 = getelementptr inbounds i64, ptr %16, i64 %8
  store i64 %80, ptr %82, align 8, !tbaa !9
  %83 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %18, ptr noundef %24, ptr noundef nonnull %14, i64 noundef %10) #15
  %84 = icmp eq i64 %10, %8
  br i1 %84, label %126, label %85

85:                                               ; preds = %79
  %86 = getelementptr inbounds i64, ptr %18, i64 %10
  %87 = getelementptr inbounds i64, ptr %14, i64 %10
  %88 = sub nsw i64 %8, %10
  %89 = load i64, ptr %87, align 8, !tbaa !9
  %90 = add i64 %89, %83
  store i64 %90, ptr %86, align 8, !tbaa !9
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
  %99 = load i64, ptr %98, align 8, !tbaa !9
  %100 = add i64 %99, 1
  %101 = getelementptr inbounds i64, ptr %86, i64 %95
  store i64 %100, ptr %101, align 8, !tbaa !9
  %102 = add nuw i64 %95, 1
  %103 = icmp eq i64 %100, 0
  br i1 %103, label %94, label %104, !llvm.loop !310

104:                                              ; preds = %97
  %105 = icmp ne ptr %14, %18
  %106 = icmp slt i64 %102, %88
  %107 = select i1 %105, i1 %106, i1 false
  br i1 %107, label %108, label %126

108:                                              ; preds = %108, %104
  %109 = phi i64 [ %113, %108 ], [ %102, %104 ]
  %110 = getelementptr inbounds i64, ptr %87, i64 %109
  %111 = load i64, ptr %110, align 8, !tbaa !9
  %112 = getelementptr inbounds i64, ptr %86, i64 %109
  store i64 %111, ptr %112, align 8, !tbaa !9
  %113 = add nuw nsw i64 %109, 1
  %114 = icmp slt i64 %113, %88
  br i1 %114, label %108, label %126, !llvm.loop !311

115:                                              ; preds = %85
  %116 = icmp ne ptr %14, %18
  %117 = icmp sgt i64 %88, 1
  %118 = and i1 %116, %117
  br i1 %118, label %119, label %126

119:                                              ; preds = %119, %115
  %120 = phi i64 [ %124, %119 ], [ 1, %115 ]
  %121 = getelementptr inbounds i64, ptr %87, i64 %120
  %122 = load i64, ptr %121, align 8, !tbaa !9
  %123 = getelementptr inbounds i64, ptr %86, i64 %120
  store i64 %122, ptr %123, align 8, !tbaa !9
  %124 = add nuw nsw i64 %120, 1
  %125 = icmp eq i64 %124, %88
  br i1 %125, label %126, label %119, !llvm.loop !312

126:                                              ; preds = %119, %115, %108, %104, %94, %79
  %127 = phi i64 [ %83, %79 ], [ 0, %104 ], [ 0, %115 ], [ 0, %108 ], [ 1, %94 ], [ 0, %119 ]
  %128 = load i64, ptr %57, align 8, !tbaa !9
  %129 = add i64 %128, %127
  %130 = shl i64 %129, 1
  %131 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %18, ptr noundef nonnull %18, i64 noundef %8, i32 noundef 1) #15
  %132 = add i64 %130, %131
  %133 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %18, ptr noundef nonnull %18, ptr noundef %1, i64 noundef %8) #15
  %134 = sub i64 %132, %133
  %135 = getelementptr inbounds i64, ptr %18, i64 %8
  store i64 %134, ptr %135, align 8, !tbaa !9
  %136 = getelementptr inbounds i64, ptr %3, i64 %9
  %137 = icmp eq i64 %11, 0
  br i1 %137, label %151, label %138

138:                                              ; preds = %126
  %139 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %3, ptr noundef %136, i64 noundef %11) #15
  %140 = icmp eq i64 %139, 0
  br i1 %140, label %151, label %141

141:                                              ; preds = %144, %138
  %142 = phi i64 [ %148, %144 ], [ %11, %138 ]
  %143 = icmp slt i64 %142, %8
  br i1 %143, label %144, label %163

144:                                              ; preds = %141
  %145 = getelementptr inbounds i64, ptr %3, i64 %142
  %146 = load i64, ptr %145, align 8, !tbaa !9
  %147 = add i64 %146, 1
  %148 = add nsw i64 %142, 1
  %149 = getelementptr inbounds i64, ptr %5, i64 %142
  store i64 %147, ptr %149, align 8, !tbaa !9
  %150 = icmp eq i64 %147, 0
  br i1 %150, label %141, label %151, !llvm.loop !307

151:                                              ; preds = %144, %138, %126
  %152 = phi i64 [ %11, %138 ], [ 0, %126 ], [ %148, %144 ]
  %153 = icmp ne ptr %5, %3
  %154 = icmp slt i64 %152, %8
  %155 = select i1 %153, i1 %154, i1 false
  br i1 %155, label %156, label %163

156:                                              ; preds = %156, %151
  %157 = phi i64 [ %161, %156 ], [ %152, %151 ]
  %158 = getelementptr inbounds i64, ptr %3, i64 %157
  %159 = load i64, ptr %158, align 8, !tbaa !9
  %160 = getelementptr inbounds i64, ptr %5, i64 %157
  store i64 %159, ptr %160, align 8, !tbaa !9
  %161 = add nsw i64 %157, 1
  %162 = icmp eq i64 %161, %8
  br i1 %162, label %163, label %156, !llvm.loop !308

163:                                              ; preds = %156, %151, %141
  %164 = phi i1 [ true, %151 ], [ true, %156 ], [ false, %141 ]
  %165 = phi i64 [ 0, %151 ], [ 0, %156 ], [ 1, %141 ]
  %166 = getelementptr inbounds i64, ptr %3, i64 %8
  %167 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %5, ptr noundef %166, i64 noundef %8) #15
  %168 = add i64 %167, %165
  store i64 %168, ptr %17, align 8, !tbaa !9
  br i1 %164, label %169, label %185

169:                                              ; preds = %172, %163
  %170 = phi i64 [ %173, %172 ], [ %8, %163 ]
  %171 = icmp sgt i64 %170, 0
  br i1 %171, label %172, label %185

172:                                              ; preds = %169
  %173 = add nsw i64 %170, -1
  %174 = getelementptr inbounds i64, ptr %5, i64 %173
  %175 = load i64, ptr %174, align 8, !tbaa !9
  %176 = getelementptr inbounds i64, ptr %166, i64 %173
  %177 = load i64, ptr %176, align 8, !tbaa !9
  %178 = icmp eq i64 %175, %177
  br i1 %178, label %169, label %179, !llvm.loop !309

179:                                              ; preds = %172
  %180 = icmp ugt i64 %175, %177
  br i1 %180, label %185, label %181

181:                                              ; preds = %179
  %182 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %21, ptr noundef %166, ptr noundef %5, i64 noundef %8) #15
  %183 = getelementptr inbounds i64, ptr %21, i64 %8
  store i64 0, ptr %183, align 8, !tbaa !9
  %184 = xor i32 %81, 1
  br label %189

185:                                              ; preds = %179, %169, %163
  %186 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %21, ptr noundef %5, ptr noundef %166, i64 noundef %8) #15
  %187 = sub i64 %165, %186
  %188 = getelementptr inbounds i64, ptr %21, i64 %8
  store i64 %187, ptr %188, align 8, !tbaa !9
  br label %189

189:                                              ; preds = %185, %181
  %190 = phi i32 [ %184, %181 ], [ %81, %185 ]
  %191 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %23, ptr noundef %0, ptr noundef %136, i64 noundef %11) #15
  %192 = icmp eq i64 %11, %8
  br i1 %192, label %234, label %193

193:                                              ; preds = %189
  %194 = getelementptr inbounds i64, ptr %23, i64 %11
  %195 = getelementptr inbounds i64, ptr %0, i64 %11
  %196 = sub nsw i64 %8, %11
  %197 = load i64, ptr %195, align 8, !tbaa !9
  %198 = add i64 %197, %191
  store i64 %198, ptr %194, align 8, !tbaa !9
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
  %207 = load i64, ptr %206, align 8, !tbaa !9
  %208 = add i64 %207, 1
  %209 = getelementptr inbounds i64, ptr %194, i64 %203
  store i64 %208, ptr %209, align 8, !tbaa !9
  %210 = add nuw i64 %203, 1
  %211 = icmp eq i64 %208, 0
  br i1 %211, label %202, label %212, !llvm.loop !310

212:                                              ; preds = %205
  %213 = icmp ne ptr %23, %0
  %214 = icmp slt i64 %210, %196
  %215 = select i1 %213, i1 %214, i1 false
  br i1 %215, label %216, label %234

216:                                              ; preds = %216, %212
  %217 = phi i64 [ %221, %216 ], [ %210, %212 ]
  %218 = getelementptr inbounds i64, ptr %195, i64 %217
  %219 = load i64, ptr %218, align 8, !tbaa !9
  %220 = getelementptr inbounds i64, ptr %194, i64 %217
  store i64 %219, ptr %220, align 8, !tbaa !9
  %221 = add nuw nsw i64 %217, 1
  %222 = icmp slt i64 %221, %196
  br i1 %222, label %216, label %234, !llvm.loop !311

223:                                              ; preds = %193
  %224 = icmp ne ptr %23, %0
  %225 = icmp sgt i64 %196, 1
  %226 = and i1 %224, %225
  br i1 %226, label %227, label %234

227:                                              ; preds = %227, %223
  %228 = phi i64 [ %232, %227 ], [ 1, %223 ]
  %229 = getelementptr inbounds i64, ptr %195, i64 %228
  %230 = load i64, ptr %229, align 8, !tbaa !9
  %231 = getelementptr inbounds i64, ptr %194, i64 %228
  store i64 %230, ptr %231, align 8, !tbaa !9
  %232 = add nuw nsw i64 %228, 1
  %233 = icmp eq i64 %232, %196
  br i1 %233, label %234, label %227, !llvm.loop !312

234:                                              ; preds = %227, %223, %216, %212, %202, %189
  %235 = phi i64 [ %191, %189 ], [ 0, %212 ], [ 0, %223 ], [ 0, %216 ], [ 1, %202 ], [ 0, %227 ]
  %236 = load i64, ptr %17, align 8, !tbaa !9
  %237 = add i64 %236, %235
  %238 = shl i64 %237, 1
  %239 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %23, ptr noundef nonnull %23, i64 noundef %8, i32 noundef 1) #15
  %240 = add i64 %238, %239
  %241 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %23, ptr noundef nonnull %23, ptr noundef %3, i64 noundef %8) #15
  %242 = sub i64 %240, %241
  %243 = getelementptr inbounds i64, ptr %23, i64 %8
  store i64 %242, ptr %243, align 8, !tbaa !9
  store i64 0, ptr %15, align 8, !tbaa !9
  %244 = getelementptr inbounds i64, ptr %21, i64 %8
  %245 = load i64, ptr %244, align 8, !tbaa !9
  %246 = getelementptr inbounds i64, ptr %16, i64 %8
  %247 = load i64, ptr %246, align 8, !tbaa !9
  %248 = or i64 %247, %245
  %249 = add i64 %248, %8
  %250 = icmp ugt i64 %249, 99
  %251 = mul i64 %8, 40
  %252 = getelementptr inbounds i8, ptr %5, i64 %251
  %253 = getelementptr inbounds i8, ptr %252, i64 40
  br i1 %250, label %255, label %254

254:                                              ; preds = %234
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef nonnull %16, i64 noundef %249, ptr noundef nonnull %21, i64 noundef %249, ptr noundef nonnull %253) #15
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
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %259, ptr noundef nonnull %18, i64 noundef %257, ptr noundef nonnull %23, i64 noundef %257, ptr noundef nonnull %262) #15
  br label %265

264:                                              ; preds = %256
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %259, ptr noundef nonnull %18, i64 noundef %257, ptr noundef nonnull %23, i64 noundef %257, ptr noundef nonnull %262)
  br label %265

265:                                              ; preds = %264, %263
  %266 = icmp sgt i64 %2, %4
  br i1 %266, label %267, label %270

267:                                              ; preds = %265
  %268 = getelementptr inbounds i64, ptr %0, i64 %12
  %269 = tail call i64 @__gmpn_mul(ptr noundef %268, ptr noundef %24, i64 noundef %10, ptr noundef %136, i64 noundef %11) #15
  br label %278

270:                                              ; preds = %265
  %271 = icmp sgt i64 %10, 99
  %272 = getelementptr inbounds i64, ptr %0, i64 %12
  %273 = mul i64 %8, 40
  %274 = getelementptr inbounds i8, ptr %5, i64 %273
  %275 = getelementptr inbounds i8, ptr %274, i64 40
  br i1 %271, label %277, label %276

276:                                              ; preds = %270
  tail call void @__gmpn_toom22_mul(ptr noundef %272, ptr noundef %24, i64 noundef %10, ptr noundef %136, i64 noundef %10, ptr noundef nonnull %275) #15
  br label %278

277:                                              ; preds = %270
  tail call void @__gmpn_toom33_mul(ptr noundef %272, ptr noundef %24, i64 noundef %10, ptr noundef %136, i64 noundef %10, ptr noundef nonnull %275)
  br label %278

278:                                              ; preds = %277, %276, %267
  %279 = getelementptr inbounds i64, ptr %0, i64 %12
  %280 = load i64, ptr %279, align 8, !tbaa !9
  %281 = getelementptr inbounds i8, ptr %279, i64 8
  %282 = load i64, ptr %281, align 8, !tbaa !9
  %283 = mul i64 %8, 40
  %284 = getelementptr inbounds i8, ptr %5, i64 %283
  %285 = getelementptr inbounds i8, ptr %284, i64 40
  br i1 %258, label %287, label %286

286:                                              ; preds = %278
  tail call void @__gmpn_toom22_mul(ptr noundef %22, ptr noundef nonnull %14, i64 noundef %257, ptr noundef %0, i64 noundef %257, ptr noundef nonnull %285) #15
  br label %288

287:                                              ; preds = %278
  tail call void @__gmpn_toom33_mul(ptr noundef %22, ptr noundef nonnull %14, i64 noundef %257, ptr noundef %0, i64 noundef %257, ptr noundef nonnull %285)
  br label %288

288:                                              ; preds = %287, %286
  store i64 %282, ptr %281, align 8, !tbaa !9
  %289 = icmp ugt i64 %7, 299
  %290 = mul i64 %8, 40
  %291 = getelementptr inbounds i8, ptr %5, i64 %290
  %292 = getelementptr inbounds i8, ptr %291, i64 40
  br i1 %289, label %294, label %293

293:                                              ; preds = %288
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %292) #15
  br label %295

294:                                              ; preds = %288
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %8, ptr noundef %3, i64 noundef %8, ptr noundef nonnull %292)
  br label %295

295:                                              ; preds = %294, %293
  %296 = getelementptr inbounds i8, ptr %15, i64 8
  %297 = add nsw i64 %10, %11
  tail call void @__gmpn_toom_interpolate_5pts(ptr noundef %0, ptr noundef nonnull %296, ptr noundef %5, i64 noundef %8, i64 noundef %297, i32 noundef %190, i64 noundef %280) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_pm2rexp(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %5, i32 noundef %6, ptr noundef %7) local_unnamed_addr #3 {
  %9 = mul i32 %6, %2
  %10 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef %3, i64 noundef %4, i32 noundef %9) #15
  %11 = getelementptr inbounds i64, ptr %0, i64 %4
  store i64 %10, ptr %11, align 8, !tbaa !9
  %12 = getelementptr inbounds i64, ptr %3, i64 %4
  %13 = add i32 %2, -1
  %14 = mul i32 %13, %6
  %15 = tail call i64 @__gmpn_lshift(ptr noundef %7, ptr noundef %12, i64 noundef %4, i32 noundef %14) #15
  %16 = getelementptr inbounds i64, ptr %7, i64 %4
  store i64 %15, ptr %16, align 8, !tbaa !9
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
  %25 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %24, i64 noundef %5) #15
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %36, label %27

27:                                               ; preds = %30, %21
  %28 = phi i64 [ %34, %30 ], [ %5, %21 ]
  %29 = icmp sgt i64 %28, %4
  br i1 %29, label %36, label %30

30:                                               ; preds = %27
  %31 = getelementptr inbounds i64, ptr %7, i64 %28
  %32 = load i64, ptr %31, align 8, !tbaa !9
  %33 = add i64 %32, 1
  %34 = add nsw i64 %28, 1
  store i64 %33, ptr %31, align 8, !tbaa !9
  %35 = icmp eq i64 %33, 0
  br i1 %35, label %27, label %36, !llvm.loop !313

36:                                               ; preds = %30, %27, %21, %20
  %37 = zext i32 %13 to i64
  %38 = mul nsw i64 %37, %4
  %39 = getelementptr inbounds i64, ptr %3, i64 %38
  %40 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %39, i64 noundef %4, i32 noundef %6) #15
  %41 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %1, i64 noundef %4) #15
  %42 = add i64 %41, %40
  %43 = load i64, ptr %11, align 8, !tbaa !9
  %44 = add i64 %42, %43
  store i64 %44, ptr %11, align 8, !tbaa !9
  br label %61

45:                                               ; preds = %8
  br i1 %19, label %61, label %46

46:                                               ; preds = %45
  %47 = zext i32 %2 to i64
  %48 = mul nsw i64 %47, %4
  %49 = getelementptr inbounds i64, ptr %3, i64 %48
  %50 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %49, i64 noundef %5) #15
  %51 = icmp eq i64 %50, 0
  br i1 %51, label %61, label %52

52:                                               ; preds = %55, %46
  %53 = phi i64 [ %59, %55 ], [ %5, %46 ]
  %54 = icmp sgt i64 %53, %4
  br i1 %54, label %61, label %55

55:                                               ; preds = %52
  %56 = getelementptr inbounds i64, ptr %0, i64 %53
  %57 = load i64, ptr %56, align 8, !tbaa !9
  %58 = add i64 %57, 1
  %59 = add nsw i64 %53, 1
  store i64 %58, ptr %56, align 8, !tbaa !9
  %60 = icmp eq i64 %58, 0
  br i1 %60, label %52, label %61, !llvm.loop !313

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
  %70 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %67, i64 noundef %4, i32 noundef %69) #15
  %71 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %1, i64 noundef %4) #15
  %72 = add i64 %71, %70
  %73 = load i64, ptr %11, align 8, !tbaa !9
  %74 = add i64 %72, %73
  store i64 %74, ptr %11, align 8, !tbaa !9
  %75 = or disjoint i32 %64, 1
  %76 = zext i32 %75 to i64
  %77 = mul nsw i64 %76, %4
  %78 = getelementptr inbounds i64, ptr %3, i64 %77
  %79 = sub i32 %2, %75
  %80 = mul i32 %79, %6
  %81 = tail call i64 @__gmpn_lshift(ptr noundef %1, ptr noundef %78, i64 noundef %4, i32 noundef %80) #15
  %82 = tail call i64 @__gmpn_add_n(ptr noundef %7, ptr noundef %7, ptr noundef %1, i64 noundef %4) #15
  %83 = add i64 %82, %81
  %84 = load i64, ptr %16, align 8, !tbaa !9
  %85 = add i64 %83, %84
  store i64 %85, ptr %16, align 8, !tbaa !9
  %86 = add i32 %64, 2
  %87 = icmp ult i32 %86, %13
  br i1 %87, label %63, label %88, !llvm.loop !314

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
  %96 = load i64, ptr %95, align 8, !tbaa !9
  %97 = getelementptr inbounds i64, ptr %7, i64 %94
  %98 = load i64, ptr %97, align 8, !tbaa !9
  %99 = icmp eq i64 %96, %98
  br i1 %99, label %90, label %100, !llvm.loop !315

100:                                              ; preds = %93
  %101 = icmp ugt i64 %96, %98
  %102 = select i1 %101, i32 1, i32 -1
  br label %103

103:                                              ; preds = %100, %90
  %104 = phi i32 [ %102, %100 ], [ 0, %90 ]
  %105 = icmp slt i32 %104, 0
  br i1 %105, label %106, label %108

106:                                              ; preds = %103
  %107 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %7, ptr noundef %0, i64 noundef %89) #15
  br label %110

108:                                              ; preds = %103
  %109 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %7, i64 noundef %89) #15
  br label %110

110:                                              ; preds = %108, %106
  %111 = ashr i32 %104, 31
  %112 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %7, i64 noundef %89) #15
  ret i32 %111
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #3 {
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
  %15 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 1, ptr noundef %0) #15
  %16 = add nuw nsw i64 %6, 2
  %17 = getelementptr inbounds i64, ptr %3, i64 %10
  %18 = getelementptr inbounds i8, ptr %17, i64 24
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #15
  %19 = shl nuw nsw i64 %7, 1
  %20 = or disjoint i64 %19, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef %3, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 0) #15
  %21 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #15
  %22 = mul nuw nsw i64 %7, 3
  %23 = getelementptr inbounds i64, ptr %3, i64 %22
  %24 = getelementptr inbounds i8, ptr %23, i64 8
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %24, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #15
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %24, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 0, i32 noundef 0) #15
  %25 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #15
  %26 = mul i64 %7, 48
  %27 = getelementptr inbounds i8, ptr %3, i64 %26
  %28 = getelementptr inbounds i8, ptr %27, i64 16
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %28, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #15
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %28, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 4) #15
  %29 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #15
  %30 = getelementptr inbounds i64, ptr %0, i64 %22
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %30, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #15
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %30, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 0) #15
  %31 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 5, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %18) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %18) #15
  tail call void @__gmpn_toom_couple_handling(ptr noundef %14, i64 noundef %20, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 2) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %18) #15
  %32 = shl nsw i64 %9, 1
  tail call void @__gmpn_toom_interpolate_12pts(ptr noundef %0, ptr noundef nonnull %28, ptr noundef nonnull %24, ptr noundef %3, i64 noundef %7, i64 noundef %32, i32 noundef 0, ptr noundef nonnull %18) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 1) i32 @__gmpn_toom_eval_dgr3_pm2(ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = shl nsw i64 %3, 4
  %8 = getelementptr inbounds i8, ptr %2, i64 %7
  %9 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %8, i64 noundef %3, i32 noundef 2) #15
  %10 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %5, ptr noundef %2, i64 noundef %3) #15
  %11 = add i64 %10, %9
  %12 = getelementptr inbounds i64, ptr %0, i64 %3
  store i64 %11, ptr %12, align 8, !tbaa !9
  %13 = mul i64 %3, 24
  %14 = getelementptr inbounds i8, ptr %2, i64 %13
  %15 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %14, i64 noundef %4, i32 noundef 2) #15
  %16 = getelementptr inbounds i64, ptr %5, i64 %4
  store i64 %15, ptr %16, align 8, !tbaa !9
  %17 = icmp slt i64 %4, %3
  %18 = getelementptr inbounds i64, ptr %2, i64 %3
  br i1 %17, label %19, label %50

19:                                               ; preds = %6
  %20 = add nsw i64 %4, 1
  %21 = icmp eq i64 %20, 0
  br i1 %21, label %35, label %22

22:                                               ; preds = %19
  %23 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %18, ptr noundef %5, i64 noundef %20) #15
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %35, label %25

25:                                               ; preds = %28, %22
  %26 = phi i64 [ %32, %28 ], [ %20, %22 ]
  %27 = icmp eq i64 %26, %3
  br i1 %27, label %47, label %28

28:                                               ; preds = %25
  %29 = getelementptr inbounds i64, ptr %18, i64 %26
  %30 = load i64, ptr %29, align 8, !tbaa !9
  %31 = add i64 %30, 1
  %32 = add i64 %26, 1
  %33 = getelementptr inbounds i64, ptr %5, i64 %26
  store i64 %31, ptr %33, align 8, !tbaa !9
  %34 = icmp eq i64 %31, 0
  br i1 %34, label %25, label %35, !llvm.loop !316

35:                                               ; preds = %28, %22, %19
  %36 = phi i64 [ %20, %22 ], [ 0, %19 ], [ %32, %28 ]
  %37 = icmp ne ptr %18, %5
  %38 = icmp slt i64 %36, %3
  %39 = and i1 %37, %38
  br i1 %39, label %40, label %47

40:                                               ; preds = %40, %35
  %41 = phi i64 [ %45, %40 ], [ %36, %35 ]
  %42 = getelementptr inbounds i64, ptr %18, i64 %41
  %43 = load i64, ptr %42, align 8, !tbaa !9
  %44 = getelementptr inbounds i64, ptr %5, i64 %41
  store i64 %43, ptr %44, align 8, !tbaa !9
  %45 = add nsw i64 %41, 1
  %46 = icmp eq i64 %45, %3
  br i1 %46, label %47, label %40, !llvm.loop !317

47:                                               ; preds = %40, %35, %25
  %48 = phi i64 [ 0, %35 ], [ 0, %40 ], [ 1, %25 ]
  %49 = getelementptr inbounds i64, ptr %5, i64 %3
  store i64 %48, ptr %49, align 8, !tbaa !9
  br label %55

50:                                               ; preds = %6
  %51 = tail call i64 @__gmpn_add_n(ptr noundef %5, ptr noundef %18, ptr noundef %5, i64 noundef %3) #15
  %52 = getelementptr inbounds i64, ptr %5, i64 %3
  %53 = load i64, ptr %52, align 8, !tbaa !9
  %54 = add i64 %53, %51
  store i64 %54, ptr %52, align 8, !tbaa !9
  br label %55

55:                                               ; preds = %50, %47
  %56 = add nsw i64 %3, 1
  %57 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %5, i64 noundef %56, i32 noundef 1) #15
  br label %58

58:                                               ; preds = %61, %55
  %59 = phi i64 [ %56, %55 ], [ %62, %61 ]
  %60 = icmp sgt i64 %59, 0
  br i1 %60, label %61, label %71

61:                                               ; preds = %58
  %62 = add nsw i64 %59, -1
  %63 = getelementptr inbounds i64, ptr %0, i64 %62
  %64 = load i64, ptr %63, align 8, !tbaa !9
  %65 = getelementptr inbounds i64, ptr %5, i64 %62
  %66 = load i64, ptr %65, align 8, !tbaa !9
  %67 = icmp eq i64 %64, %66
  br i1 %67, label %58, label %68, !llvm.loop !318

68:                                               ; preds = %61
  %69 = icmp ugt i64 %64, %66
  %70 = select i1 %69, i32 1, i32 -1
  br label %71

71:                                               ; preds = %68, %58
  %72 = phi i32 [ %70, %68 ], [ 0, %58 ]
  %73 = icmp slt i32 %72, 0
  br i1 %73, label %74, label %76

74:                                               ; preds = %71
  %75 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %5, ptr noundef %0, i64 noundef %56) #15
  br label %78

76:                                               ; preds = %71
  %77 = tail call i64 @__gmpn_sub_n(ptr noundef %1, ptr noundef %0, ptr noundef %5, i64 noundef %56) #15
  br label %78

78:                                               ; preds = %76, %74
  %79 = ashr i32 %72, 31
  %80 = tail call i64 @__gmpn_add_n(ptr noundef %0, ptr noundef %0, ptr noundef %5, i64 noundef %56) #15
  ret i32 %79
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i64 @__gmpn_bdiv_dbm1c(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2, i64 noundef %3, i64 noundef %4) local_unnamed_addr #13 {
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
  %14 = load i64, ptr %13, align 8, !tbaa !9
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
  store i64 %33, ptr %34, align 8, !tbaa !9
  %35 = add i64 %26, %27
  %36 = sub i64 %33, %35
  %37 = add i64 %36, %32
  %38 = add nuw nsw i64 %12, 1
  %39 = icmp eq i64 %38, %2
  br i1 %39, label %40, label %10, !llvm.loop !319

40:                                               ; preds = %10, %5
  %41 = phi i64 [ %4, %5 ], [ %37, %10 ]
  ret i64 %41
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = mul nsw i64 %2, 17
  %8 = mul nsw i64 %4, 18
  %9 = icmp slt i64 %7, %8
  br i1 %9, label %10, label %17, !prof !30

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
  br i1 %58, label %59, label %62, !prof !55

59:                                               ; preds = %57
  %60 = add nsw i32 %34, -2
  %61 = add nsw i64 %52, %47
  br label %67

62:                                               ; preds = %57
  %63 = icmp slt i64 %55, 1
  br i1 %63, label %64, label %67, !prof !55

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
  %80 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, i32 noundef 1, ptr noundef %0) #15
  %81 = getelementptr inbounds i64, ptr %5, i64 %75
  %82 = getelementptr inbounds i8, ptr %81, i64 24
  %83 = shl nsw i64 %68, 6
  %84 = getelementptr inbounds i8, ptr %0, i64 %83
  %85 = getelementptr inbounds i8, ptr %84, i64 8
  %86 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, i32 noundef 1, ptr noundef %0) #15
  %87 = xor i32 %86, %80
  %88 = add nuw nsw i64 %68, 1
  %89 = icmp sgt i64 %68, 98
  br i1 %89, label %94, label %90

90:                                               ; preds = %67
  %91 = mul i64 %68, 80
  %92 = getelementptr inbounds i8, ptr %5, i64 %91
  %93 = getelementptr inbounds i8, ptr %92, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %93) #15
  tail call void @__gmpn_toom22_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %93) #15
  br label %107

94:                                               ; preds = %67
  %95 = icmp sgt i64 %68, 298
  br i1 %95, label %100, label %96

96:                                               ; preds = %94
  %97 = mul i64 %68, 80
  %98 = getelementptr inbounds i8, ptr %5, i64 %97
  %99 = getelementptr inbounds i8, ptr %98, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %99) #15
  tail call void @__gmpn_toom33_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %99) #15
  br label %107

100:                                              ; preds = %94
  %101 = icmp sgt i64 %68, 348
  %102 = mul i64 %68, 80
  %103 = getelementptr inbounds i8, ptr %5, i64 %102
  %104 = getelementptr inbounds i8, ptr %103, i64 32
  br i1 %101, label %106, label %105

105:                                              ; preds = %100
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %104) #15
  tail call void @__gmpn_toom44_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %104) #15
  br label %107

106:                                              ; preds = %100
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %104)
  tail call void @__gmpn_toom6h_mul(ptr noundef %5, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %104)
  br label %107

107:                                              ; preds = %106, %105, %96, %90
  %108 = shl nuw nsw i64 %68, 1
  %109 = or disjoint i64 %108, 1
  %110 = add nuw nsw i32 %74, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef %5, i64 noundef %109, ptr noundef %0, i32 noundef %87, i64 noundef %68, i32 noundef %110, i32 noundef %74) #15
  %111 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, ptr noundef %0) #15
  %112 = icmp eq i32 %72, 3
  br i1 %112, label %113, label %115, !prof !55

113:                                              ; preds = %107
  %114 = tail call i32 @__gmpn_toom_eval_dgr3_pm1(ptr noundef nonnull %82, ptr noundef nonnull %85, ptr noundef %3, i64 noundef %68, i64 noundef %70, ptr noundef %0) #15
  br label %117

115:                                              ; preds = %107
  %116 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, ptr noundef %0) #15
  br label %117

117:                                              ; preds = %115, %113
  %118 = phi i32 [ %114, %113 ], [ %116, %115 ]
  %119 = xor i32 %118, %111
  br i1 %89, label %127, label %120

120:                                              ; preds = %117
  %121 = mul i64 %68, 80
  %122 = getelementptr inbounds i8, ptr %5, i64 %121
  %123 = getelementptr inbounds i8, ptr %122, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %123) #15
  %124 = mul i64 %68, 24
  %125 = getelementptr inbounds i8, ptr %5, i64 %124
  %126 = getelementptr inbounds i8, ptr %125, i64 8
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %126, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %123) #15
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
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %135) #15
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %131, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %135) #15
  br label %143

136:                                              ; preds = %127
  %137 = icmp sgt i64 %68, 348
  %138 = mul i64 %68, 80
  %139 = getelementptr inbounds i8, ptr %5, i64 %138
  %140 = getelementptr inbounds i8, ptr %139, i64 32
  br i1 %137, label %142, label %141

141:                                              ; preds = %136
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %140) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %131, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %140) #15
  br label %143

142:                                              ; preds = %136
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %140)
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %131, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %140)
  br label %143

143:                                              ; preds = %142, %141, %132, %120
  %144 = mul nuw nsw i64 %68, 3
  %145 = getelementptr inbounds i64, ptr %5, i64 %144
  %146 = getelementptr inbounds i8, ptr %145, i64 8
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %146, i64 noundef %109, ptr noundef %0, i32 noundef %119, i64 noundef %68, i32 noundef 0, i32 noundef 0) #15
  %147 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, i32 noundef 2, ptr noundef %0) #15
  %148 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, i32 noundef 2, ptr noundef %0) #15
  %149 = xor i32 %148, %147
  br i1 %89, label %157, label %150

150:                                              ; preds = %143
  %151 = mul i64 %68, 80
  %152 = getelementptr inbounds i8, ptr %5, i64 %151
  %153 = getelementptr inbounds i8, ptr %152, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %153) #15
  %154 = mul i64 %68, 48
  %155 = getelementptr inbounds i8, ptr %5, i64 %154
  %156 = getelementptr inbounds i8, ptr %155, i64 16
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %156, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %153) #15
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
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %165) #15
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %161, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %165) #15
  br label %173

166:                                              ; preds = %157
  %167 = icmp sgt i64 %68, 348
  %168 = mul i64 %68, 80
  %169 = getelementptr inbounds i8, ptr %5, i64 %168
  %170 = getelementptr inbounds i8, ptr %169, i64 32
  br i1 %167, label %172, label %171

171:                                              ; preds = %166
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %170) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %161, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %170) #15
  br label %173

172:                                              ; preds = %166
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %170)
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %161, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %170)
  br label %173

173:                                              ; preds = %172, %171, %162, %150
  %174 = mul i64 %68, 48
  %175 = getelementptr inbounds i8, ptr %5, i64 %174
  %176 = getelementptr inbounds i8, ptr %175, i64 16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %176, i64 noundef %109, ptr noundef %0, i32 noundef %149, i64 noundef %68, i32 noundef 2, i32 noundef 4) #15
  %177 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, i32 noundef 2, ptr noundef %0) #15
  %178 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, i32 noundef 2, ptr noundef %0) #15
  %179 = xor i32 %178, %177
  br i1 %89, label %185, label %180

180:                                              ; preds = %173
  %181 = mul i64 %68, 80
  %182 = getelementptr inbounds i8, ptr %5, i64 %181
  %183 = getelementptr inbounds i8, ptr %182, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %183) #15
  %184 = getelementptr inbounds i64, ptr %0, i64 %144
  tail call void @__gmpn_toom22_mul(ptr noundef nonnull %184, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %183) #15
  br label %199

185:                                              ; preds = %173
  %186 = icmp sgt i64 %68, 298
  %187 = getelementptr inbounds i64, ptr %0, i64 %144
  br i1 %186, label %192, label %188

188:                                              ; preds = %185
  %189 = mul i64 %68, 80
  %190 = getelementptr inbounds i8, ptr %5, i64 %189
  %191 = getelementptr inbounds i8, ptr %190, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %191) #15
  tail call void @__gmpn_toom33_mul(ptr noundef nonnull %187, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %191) #15
  br label %199

192:                                              ; preds = %185
  %193 = icmp sgt i64 %68, 348
  %194 = mul i64 %68, 80
  %195 = getelementptr inbounds i8, ptr %5, i64 %194
  %196 = getelementptr inbounds i8, ptr %195, i64 32
  br i1 %193, label %198, label %197

197:                                              ; preds = %192
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %196) #15
  tail call void @__gmpn_toom44_mul(ptr noundef nonnull %187, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %196) #15
  br label %199

198:                                              ; preds = %192
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %196)
  tail call void @__gmpn_toom6h_mul(ptr noundef nonnull %187, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %196)
  br label %199

199:                                              ; preds = %198, %197, %188, %180
  %200 = getelementptr inbounds i64, ptr %0, i64 %144
  %201 = shl nuw nsw i32 %110, 1
  %202 = shl nuw nsw i32 %74, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %200, i64 noundef %109, ptr noundef %0, i32 noundef %179, i64 noundef %68, i32 noundef %201, i32 noundef %202) #15
  %203 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %77, ptr noundef %79, i32 noundef %71, ptr noundef %1, i64 noundef %68, i64 noundef %69, ptr noundef %0) #15
  %204 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %82, ptr noundef nonnull %85, i32 noundef %72, ptr noundef %3, i64 noundef %68, i64 noundef %70, ptr noundef %0) #15
  %205 = xor i32 %204, %203
  br i1 %89, label %210, label %206

206:                                              ; preds = %199
  %207 = mul i64 %68, 80
  %208 = getelementptr inbounds i8, ptr %5, i64 %207
  %209 = getelementptr inbounds i8, ptr %208, i64 32
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %209) #15
  tail call void @__gmpn_toom22_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %209) #15
  br label %223

210:                                              ; preds = %199
  %211 = icmp sgt i64 %68, 298
  br i1 %211, label %216, label %212

212:                                              ; preds = %210
  %213 = mul i64 %68, 80
  %214 = getelementptr inbounds i8, ptr %5, i64 %213
  %215 = getelementptr inbounds i8, ptr %214, i64 32
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %215) #15
  tail call void @__gmpn_toom33_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %215) #15
  br label %223

216:                                              ; preds = %210
  %217 = icmp sgt i64 %68, 348
  %218 = mul i64 %68, 80
  %219 = getelementptr inbounds i8, ptr %5, i64 %218
  %220 = getelementptr inbounds i8, ptr %219, i64 32
  br i1 %217, label %222, label %221

221:                                              ; preds = %216
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %220) #15
  tail call void @__gmpn_toom44_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %220) #15
  br label %223

222:                                              ; preds = %216
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %79, i64 noundef %88, ptr noundef nonnull %85, i64 noundef %88, ptr noundef nonnull %220)
  tail call void @__gmpn_toom6h_mul(ptr noundef %79, ptr noundef nonnull %77, i64 noundef %88, ptr noundef nonnull %82, i64 noundef %88, ptr noundef nonnull %220)
  br label %223

223:                                              ; preds = %222, %221, %212, %206
  tail call void @__gmpn_toom_couple_handling(ptr noundef %79, i64 noundef %109, ptr noundef %0, i32 noundef %205, i64 noundef %68, i32 noundef 1, i32 noundef 2) #15
  %224 = icmp sgt i64 %68, 99
  br i1 %224, label %226, label %225

225:                                              ; preds = %223
  tail call void @__gmpn_toom22_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82) #15
  br label %233

226:                                              ; preds = %223
  %227 = icmp sgt i64 %68, 299
  br i1 %227, label %229, label %228

228:                                              ; preds = %226
  tail call void @__gmpn_toom33_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82) #15
  br label %233

229:                                              ; preds = %226
  %230 = icmp sgt i64 %68, 349
  br i1 %230, label %232, label %231

231:                                              ; preds = %229
  tail call void @__gmpn_toom44_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82) #15
  br label %233

232:                                              ; preds = %229
  tail call void @__gmpn_toom6h_mul(ptr noundef %0, ptr noundef %1, i64 noundef %68, ptr noundef %3, i64 noundef %68, ptr noundef nonnull %82)
  br label %233

233:                                              ; preds = %232, %231, %228, %225
  br i1 %73, label %254, label %234, !prof !30

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
  %245 = tail call i64 @__gmpn_mul(ptr noundef %237, ptr noundef %241, i64 noundef %69, ptr noundef %244, i64 noundef %70) #15
  br label %254

246:                                              ; preds = %234
  %247 = zext nneg i32 %72 to i64
  %248 = mul nsw i64 %68, %247
  %249 = getelementptr inbounds i64, ptr %3, i64 %248
  %250 = zext nneg i32 %71 to i64
  %251 = mul nsw i64 %68, %250
  %252 = getelementptr inbounds i64, ptr %1, i64 %251
  %253 = tail call i64 @__gmpn_mul(ptr noundef %237, ptr noundef %249, i64 noundef %70, ptr noundef %252, i64 noundef %69) #15
  br label %254

254:                                              ; preds = %246, %238, %233
  %255 = add nsw i64 %70, %69
  tail call void @__gmpn_toom_interpolate_12pts(ptr noundef %0, ptr noundef nonnull %176, ptr noundef nonnull %146, ptr noundef %5, i64 noundef %68, i64 noundef %255, i32 noundef %74, ptr noundef nonnull %82) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define noalias ptr @__gmp_tmp_reentrant_alloc(ptr nocapture noundef %0, i64 noundef %1) local_unnamed_addr #3 {
  %3 = add i64 %1, 16
  %4 = load ptr, ptr @__gmp_allocate_func, align 8, !tbaa !5
  %5 = tail call ptr %4(i64 noundef %3) #15
  %6 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 %3, ptr %6, align 8, !tbaa !320
  %7 = load ptr, ptr %0, align 8, !tbaa !5
  store ptr %7, ptr %5, align 8, !tbaa !322
  store ptr %5, ptr %0, align 8, !tbaa !5
  %8 = getelementptr inbounds i8, ptr %5, i64 16
  ret ptr %8
}

; Function Attrs: nounwind ssp uwtable
define void @__gmp_tmp_reentrant_free(ptr noundef %0) local_unnamed_addr #3 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %10, label %3

3:                                                ; preds = %3, %1
  %4 = phi ptr [ %5, %3 ], [ %0, %1 ]
  %5 = load ptr, ptr %4, align 8, !tbaa !322
  %6 = load ptr, ptr @__gmp_free_func, align 8, !tbaa !5
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  %8 = load i64, ptr %7, align 8, !tbaa !320
  tail call void %6(ptr noundef nonnull %4, i64 noundef %8) #15
  %9 = icmp eq ptr %5, null
  br i1 %9, label %10, label %3, !llvm.loop !323

10:                                               ; preds = %3, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom63_mul(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
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
  %22 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %19, ptr noundef nonnull %21, i32 noundef 5, ptr noundef %1, i64 noundef %13, i64 noundef %15, i32 noundef 2, ptr noundef %0) #15
  %23 = getelementptr inbounds i64, ptr %3, i64 %13
  %24 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %23, i64 noundef %13, i32 noundef 2) #15
  %25 = getelementptr inbounds i64, ptr %0, i64 %13
  store i64 %24, ptr %25, align 8, !tbaa !9
  %26 = mul nuw nsw i64 %13, 6
  %27 = getelementptr inbounds i64, ptr %0, i64 %26
  %28 = getelementptr inbounds i8, ptr %27, i64 24
  %29 = getelementptr inbounds i64, ptr %3, i64 %16
  %30 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %28, ptr noundef nonnull %29, i64 noundef %17, i32 noundef 4) #15
  %31 = getelementptr inbounds i64, ptr %28, i64 %17
  store i64 %30, ptr %31, align 8, !tbaa !9
  %32 = icmp eq i64 %13, %17
  br i1 %32, label %33, label %38

33:                                               ; preds = %6
  %34 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %3, i64 noundef %13) #15
  %35 = getelementptr inbounds i64, ptr %28, i64 %13
  %36 = load i64, ptr %35, align 8, !tbaa !9
  %37 = add i64 %36, %34
  store i64 %37, ptr %35, align 8, !tbaa !9
  br label %69

38:                                               ; preds = %6
  %39 = add nsw i64 %17, 1
  %40 = icmp eq i64 %39, 0
  br i1 %40, label %54, label %41

41:                                               ; preds = %38
  %42 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef %3, ptr noundef nonnull %28, i64 noundef %39) #15
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %54, label %44

44:                                               ; preds = %47, %41
  %45 = phi i64 [ %51, %47 ], [ %39, %41 ]
  %46 = icmp sgt i64 %45, %12
  br i1 %46, label %66, label %47

47:                                               ; preds = %44
  %48 = getelementptr inbounds i64, ptr %3, i64 %45
  %49 = load i64, ptr %48, align 8, !tbaa !9
  %50 = add i64 %49, 1
  %51 = add nsw i64 %45, 1
  %52 = getelementptr inbounds i64, ptr %28, i64 %45
  store i64 %50, ptr %52, align 8, !tbaa !9
  %53 = icmp eq i64 %50, 0
  br i1 %53, label %44, label %54, !llvm.loop !324

54:                                               ; preds = %47, %41, %38
  %55 = phi i64 [ %39, %41 ], [ 0, %38 ], [ %51, %47 ]
  %56 = icmp ne ptr %28, %3
  %57 = icmp sle i64 %55, %12
  %58 = select i1 %56, i1 %57, i1 false
  br i1 %58, label %59, label %66

59:                                               ; preds = %59, %54
  %60 = phi i64 [ %64, %59 ], [ %55, %54 ]
  %61 = getelementptr inbounds i64, ptr %3, i64 %60
  %62 = load i64, ptr %61, align 8, !tbaa !9
  %63 = getelementptr inbounds i64, ptr %28, i64 %60
  store i64 %62, ptr %63, align 8, !tbaa !9
  %64 = add nsw i64 %60, 1
  %65 = icmp eq i64 %60, %12
  br i1 %65, label %66, label %59, !llvm.loop !325

66:                                               ; preds = %59, %54, %44
  %67 = phi i64 [ 0, %54 ], [ 0, %59 ], [ 1, %44 ]
  %68 = getelementptr inbounds i64, ptr %28, i64 %13
  store i64 %67, ptr %68, align 8, !tbaa !9
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
  %78 = load i64, ptr %77, align 8, !tbaa !9
  %79 = getelementptr inbounds i64, ptr %0, i64 %76
  %80 = load i64, ptr %79, align 8, !tbaa !9
  %81 = icmp eq i64 %78, %80
  br i1 %81, label %88, label %82

82:                                               ; preds = %74
  %83 = icmp ugt i64 %78, %80
  br i1 %83, label %84, label %86

84:                                               ; preds = %82
  %85 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %75) #15
  br label %91

86:                                               ; preds = %82
  %87 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef %0, ptr noundef nonnull %28, i64 noundef %75) #15
  br label %91

88:                                               ; preds = %74
  %89 = getelementptr i64, ptr %71, i64 %75
  store i64 0, ptr %89, align 8, !tbaa !9
  %90 = icmp sgt i64 %75, 1
  br i1 %90, label %74, label %91, !llvm.loop !326

91:                                               ; preds = %88, %86, %84
  %92 = phi i32 [ 0, %84 ], [ -1, %86 ], [ 0, %88 ]
  %93 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %73) #15
  %94 = xor i32 %92, %22
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef nonnull %21, ptr noundef nonnull %72, i64 noundef %73) #15
  %95 = getelementptr inbounds i64, ptr %5, i64 %20
  %96 = getelementptr inbounds i8, ptr %95, i64 8
  tail call void @__gmpn_mul_n(ptr noundef nonnull %96, ptr noundef nonnull %19, ptr noundef nonnull %28, i64 noundef %73) #15
  %97 = or disjoint i64 %16, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %96, i64 noundef %97, ptr noundef %0, i32 noundef %94, i64 noundef %13, i32 noundef 2, i32 noundef 4) #15
  %98 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %19, ptr noundef nonnull %21, i32 noundef 5, ptr noundef %1, i64 noundef %13, i64 noundef %15, ptr noundef %0) #15
  %99 = getelementptr inbounds i64, ptr %5, i64 %26
  %100 = getelementptr inbounds i8, ptr %99, i64 16
  %101 = icmp eq i64 %17, 0
  br i1 %101, label %115, label %102

102:                                              ; preds = %91
  %103 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %100, ptr noundef %3, ptr noundef nonnull %29, i64 noundef %17) #15
  %104 = icmp eq i64 %103, 0
  br i1 %104, label %115, label %105

105:                                              ; preds = %108, %102
  %106 = phi i64 [ %112, %108 ], [ %17, %102 ]
  %107 = icmp sgt i64 %106, %12
  br i1 %107, label %127, label %108

108:                                              ; preds = %105
  %109 = getelementptr inbounds i64, ptr %3, i64 %106
  %110 = load i64, ptr %109, align 8, !tbaa !9
  %111 = add i64 %110, 1
  %112 = add nsw i64 %106, 1
  %113 = getelementptr inbounds i64, ptr %100, i64 %106
  store i64 %111, ptr %113, align 8, !tbaa !9
  %114 = icmp eq i64 %111, 0
  br i1 %114, label %105, label %115, !llvm.loop !324

115:                                              ; preds = %108, %102, %91
  %116 = phi i64 [ %17, %102 ], [ 0, %91 ], [ %112, %108 ]
  %117 = icmp ne ptr %100, %3
  %118 = icmp sle i64 %116, %12
  %119 = select i1 %117, i1 %118, i1 false
  br i1 %119, label %120, label %127

120:                                              ; preds = %120, %115
  %121 = phi i64 [ %125, %120 ], [ %116, %115 ]
  %122 = getelementptr inbounds i64, ptr %3, i64 %121
  %123 = load i64, ptr %122, align 8, !tbaa !9
  %124 = getelementptr inbounds i64, ptr %100, i64 %121
  store i64 %123, ptr %124, align 8, !tbaa !9
  %125 = add nsw i64 %121, 1
  %126 = icmp eq i64 %121, %12
  br i1 %126, label %127, label %120, !llvm.loop !325

127:                                              ; preds = %120, %115, %105
  %128 = phi i1 [ true, %115 ], [ true, %120 ], [ false, %105 ]
  %129 = phi i64 [ 0, %115 ], [ 0, %120 ], [ 1, %105 ]
  %130 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %100, ptr noundef nonnull %23, i64 noundef %13) #15
  %131 = add i64 %130, %129
  %132 = getelementptr inbounds i64, ptr %28, i64 %13
  store i64 %131, ptr %132, align 8, !tbaa !9
  br i1 %128, label %133, label %149

133:                                              ; preds = %136, %127
  %134 = phi i64 [ %137, %136 ], [ %13, %127 ]
  %135 = icmp sgt i64 %134, 0
  br i1 %135, label %136, label %149

136:                                              ; preds = %133
  %137 = add nsw i64 %134, -1
  %138 = getelementptr inbounds i64, ptr %100, i64 %137
  %139 = load i64, ptr %138, align 8, !tbaa !9
  %140 = getelementptr inbounds i64, ptr %23, i64 %137
  %141 = load i64, ptr %140, align 8, !tbaa !9
  %142 = icmp eq i64 %139, %141
  br i1 %142, label %133, label %143, !llvm.loop !327

143:                                              ; preds = %136
  %144 = icmp ugt i64 %139, %141
  br i1 %144, label %149, label %145

145:                                              ; preds = %143
  %146 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %23, ptr noundef nonnull %100, i64 noundef %13) #15
  %147 = getelementptr inbounds i64, ptr %72, i64 %13
  store i64 0, ptr %147, align 8, !tbaa !9
  %148 = xor i32 %98, -1
  br label %153

149:                                              ; preds = %143, %133, %127
  %150 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %100, ptr noundef nonnull %23, i64 noundef %13) #15
  %151 = sub i64 %129, %150
  %152 = getelementptr inbounds i64, ptr %72, i64 %13
  store i64 %151, ptr %152, align 8, !tbaa !9
  br label %153

153:                                              ; preds = %149, %145
  %154 = phi i32 [ %148, %145 ], [ %98, %149 ]
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef nonnull %21, ptr noundef nonnull %72, i64 noundef %73) #15
  tail call void @__gmpn_mul_n(ptr noundef %5, ptr noundef nonnull %19, ptr noundef nonnull %28, i64 noundef %73) #15
  tail call void @__gmpn_toom_couple_handling(ptr noundef %5, i64 noundef %97, ptr noundef %0, i32 noundef %154, i64 noundef %13, i32 noundef 0, i32 noundef 0) #15
  %155 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %19, ptr noundef nonnull %21, i32 noundef 5, ptr noundef %1, i64 noundef %13, i64 noundef %15, ptr noundef %0) #15
  %156 = tail call i64 @__gmpn_lshift(ptr noundef %0, ptr noundef nonnull %23, i64 noundef %13, i32 noundef 1) #15
  store i64 %156, ptr %25, align 8, !tbaa !9
  %157 = tail call i64 @__gmpn_lshift(ptr noundef nonnull %28, ptr noundef nonnull %29, i64 noundef %17, i32 noundef 2) #15
  store i64 %157, ptr %31, align 8, !tbaa !9
  br i1 %32, label %158, label %162

158:                                              ; preds = %153
  %159 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %3, i64 noundef %13) #15
  %160 = load i64, ptr %132, align 8, !tbaa !9
  %161 = add i64 %160, %159
  br label %190

162:                                              ; preds = %153
  %163 = add nsw i64 %17, 1
  %164 = icmp eq i64 %163, 0
  br i1 %164, label %178, label %165

165:                                              ; preds = %162
  %166 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef %3, ptr noundef nonnull %28, i64 noundef %163) #15
  %167 = icmp eq i64 %166, 0
  br i1 %167, label %178, label %168

168:                                              ; preds = %171, %165
  %169 = phi i64 [ %175, %171 ], [ %163, %165 ]
  %170 = icmp sgt i64 %169, %12
  br i1 %170, label %190, label %171

171:                                              ; preds = %168
  %172 = getelementptr inbounds i64, ptr %3, i64 %169
  %173 = load i64, ptr %172, align 8, !tbaa !9
  %174 = add i64 %173, 1
  %175 = add nsw i64 %169, 1
  %176 = getelementptr inbounds i64, ptr %28, i64 %169
  store i64 %174, ptr %176, align 8, !tbaa !9
  %177 = icmp eq i64 %174, 0
  br i1 %177, label %168, label %178, !llvm.loop !324

178:                                              ; preds = %171, %165, %162
  %179 = phi i64 [ %163, %165 ], [ 0, %162 ], [ %175, %171 ]
  %180 = icmp ne ptr %28, %3
  %181 = icmp sle i64 %179, %12
  %182 = select i1 %180, i1 %181, i1 false
  br i1 %182, label %183, label %190

183:                                              ; preds = %183, %178
  %184 = phi i64 [ %188, %183 ], [ %179, %178 ]
  %185 = getelementptr inbounds i64, ptr %3, i64 %184
  %186 = load i64, ptr %185, align 8, !tbaa !9
  %187 = getelementptr inbounds i64, ptr %28, i64 %184
  store i64 %186, ptr %187, align 8, !tbaa !9
  %188 = add nsw i64 %184, 1
  %189 = icmp eq i64 %184, %12
  br i1 %189, label %190, label %183, !llvm.loop !325

190:                                              ; preds = %183, %178, %168, %158
  %191 = phi i64 [ %161, %158 ], [ 0, %178 ], [ 0, %183 ], [ 1, %168 ]
  store i64 %191, ptr %132, align 8, !tbaa !9
  br label %192

192:                                              ; preds = %206, %190
  %193 = phi i64 [ %194, %206 ], [ %73, %190 ]
  %194 = add nsw i64 %193, -1
  %195 = getelementptr inbounds i64, ptr %28, i64 %194
  %196 = load i64, ptr %195, align 8, !tbaa !9
  %197 = getelementptr inbounds i64, ptr %0, i64 %194
  %198 = load i64, ptr %197, align 8, !tbaa !9
  %199 = icmp eq i64 %196, %198
  br i1 %199, label %206, label %200

200:                                              ; preds = %192
  %201 = icmp ugt i64 %196, %198
  br i1 %201, label %202, label %204

202:                                              ; preds = %200
  %203 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %193) #15
  br label %209

204:                                              ; preds = %200
  %205 = tail call i64 @__gmpn_sub_n(ptr noundef nonnull %72, ptr noundef %0, ptr noundef nonnull %28, i64 noundef %193) #15
  br label %209

206:                                              ; preds = %192
  %207 = getelementptr i64, ptr %71, i64 %193
  store i64 0, ptr %207, align 8, !tbaa !9
  %208 = icmp sgt i64 %193, 1
  br i1 %208, label %192, label %209, !llvm.loop !326

209:                                              ; preds = %206, %204, %202
  %210 = phi i32 [ 0, %202 ], [ -1, %204 ], [ 0, %206 ]
  %211 = tail call i64 @__gmpn_add_n(ptr noundef nonnull %28, ptr noundef nonnull %28, ptr noundef %0, i64 noundef %73) #15
  %212 = xor i32 %210, %155
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef nonnull %21, ptr noundef nonnull %72, i64 noundef %73) #15
  tail call void @__gmpn_mul_n(ptr noundef nonnull %21, ptr noundef nonnull %19, ptr noundef nonnull %28, i64 noundef %73) #15
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %21, i64 noundef %97, ptr noundef %0, i32 noundef %212, i64 noundef %13, i32 noundef 1, i32 noundef 2) #15
  tail call void @__gmpn_mul_n(ptr noundef %0, ptr noundef %1, ptr noundef %3, i64 noundef %13) #15
  %213 = icmp sgt i64 %15, %17
  %214 = mul i64 %13, 56
  %215 = getelementptr inbounds i8, ptr %0, i64 %214
  %216 = getelementptr inbounds i64, ptr %1, i64 %14
  br i1 %213, label %217, label %219

217:                                              ; preds = %209
  %218 = tail call i64 @__gmpn_mul(ptr noundef %215, ptr noundef nonnull %216, i64 noundef %15, ptr noundef nonnull %29, i64 noundef %17) #15
  br label %221

219:                                              ; preds = %209
  %220 = tail call i64 @__gmpn_mul(ptr noundef %215, ptr noundef nonnull %29, i64 noundef %17, ptr noundef nonnull %216, i64 noundef %15) #15
  br label %221

221:                                              ; preds = %219, %217
  %222 = add nsw i64 %15, %17
  tail call void @__gmpn_toom_interpolate_8pts(ptr noundef %0, i64 noundef %13, ptr noundef nonnull %96, ptr noundef %5, i64 noundef %222, ptr noundef nonnull %100) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3) local_unnamed_addr #3 {
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
  %15 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 3, ptr noundef %0) #15
  %16 = add nsw i64 %6, 2
  %17 = icmp sgt i64 %6, 117
  br i1 %17, label %22, label %18

18:                                               ; preds = %4
  %19 = mul i64 %7, 96
  %20 = getelementptr inbounds i8, ptr %3, i64 %19
  %21 = getelementptr inbounds i8, ptr %20, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %21) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %21) #15
  br label %35

22:                                               ; preds = %4
  %23 = icmp sgt i64 %6, 397
  br i1 %23, label %28, label %24

24:                                               ; preds = %22
  %25 = mul i64 %7, 96
  %26 = getelementptr inbounds i8, ptr %3, i64 %25
  %27 = getelementptr inbounds i8, ptr %26, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %27) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %27) #15
  br label %35

28:                                               ; preds = %22
  %29 = icmp sgt i64 %6, 447
  %30 = mul i64 %7, 96
  %31 = getelementptr inbounds i8, ptr %3, i64 %30
  %32 = getelementptr inbounds i8, ptr %31, i64 32
  br i1 %29, label %34, label %33

33:                                               ; preds = %28
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %32) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %32) #15
  br label %35

34:                                               ; preds = %28
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %32)
  tail call void @__gmpn_toom8_sqr(ptr noundef %3, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %32)
  br label %35

35:                                               ; preds = %34, %33, %24, %18
  %36 = shl nsw i64 %7, 1
  %37 = or disjoint i64 %36, 1
  tail call void @__gmpn_toom_couple_handling(ptr noundef %3, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 3, i32 noundef 0) #15
  %38 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #15
  br i1 %17, label %46, label %39

39:                                               ; preds = %35
  %40 = mul i64 %7, 96
  %41 = getelementptr inbounds i8, ptr %3, i64 %40
  %42 = getelementptr inbounds i8, ptr %41, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %42) #15
  %43 = mul i64 %7, 24
  %44 = getelementptr inbounds i8, ptr %3, i64 %43
  %45 = getelementptr inbounds i8, ptr %44, i64 8
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %45, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %42) #15
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
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %54) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %50, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %54) #15
  br label %62

55:                                               ; preds = %46
  %56 = icmp sgt i64 %6, 447
  %57 = mul i64 %7, 96
  %58 = getelementptr inbounds i8, ptr %3, i64 %57
  %59 = getelementptr inbounds i8, ptr %58, i64 32
  br i1 %56, label %61, label %60

60:                                               ; preds = %55
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %59) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %50, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %59) #15
  br label %62

61:                                               ; preds = %55
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %59)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %50, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %59)
  br label %62

62:                                               ; preds = %61, %60, %51, %39
  %63 = mul nsw i64 %7, 3
  %64 = getelementptr inbounds i64, ptr %3, i64 %63
  %65 = getelementptr inbounds i8, ptr %64, i64 8
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %65, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 0) #15
  %66 = tail call i32 @__gmpn_toom_eval_pm2(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #15
  br i1 %17, label %74, label %67

67:                                               ; preds = %62
  %68 = mul i64 %7, 96
  %69 = getelementptr inbounds i8, ptr %3, i64 %68
  %70 = getelementptr inbounds i8, ptr %69, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %70) #15
  %71 = mul i64 %7, 48
  %72 = getelementptr inbounds i8, ptr %3, i64 %71
  %73 = getelementptr inbounds i8, ptr %72, i64 16
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %73, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %70) #15
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
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %82) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %78, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %82) #15
  br label %90

83:                                               ; preds = %74
  %84 = icmp sgt i64 %6, 447
  %85 = mul i64 %7, 96
  %86 = getelementptr inbounds i8, ptr %3, i64 %85
  %87 = getelementptr inbounds i8, ptr %86, i64 32
  br i1 %84, label %89, label %88

88:                                               ; preds = %83
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %87) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %78, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %87) #15
  br label %90

89:                                               ; preds = %83
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %87)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %78, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %87)
  br label %90

90:                                               ; preds = %89, %88, %79, %67
  %91 = mul i64 %7, 48
  %92 = getelementptr inbounds i8, ptr %3, i64 %91
  %93 = getelementptr inbounds i8, ptr %92, i64 16
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %93, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 2) #15
  %94 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 3, ptr noundef %0) #15
  br i1 %17, label %102, label %95

95:                                               ; preds = %90
  %96 = mul i64 %7, 96
  %97 = getelementptr inbounds i8, ptr %3, i64 %96
  %98 = getelementptr inbounds i8, ptr %97, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %98) #15
  %99 = mul i64 %7, 72
  %100 = getelementptr inbounds i8, ptr %3, i64 %99
  %101 = getelementptr inbounds i8, ptr %100, i64 24
  tail call void @__gmpn_toom2_sqr(ptr noundef nonnull %101, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %98) #15
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
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %110) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %106, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %110) #15
  br label %118

111:                                              ; preds = %102
  %112 = icmp sgt i64 %6, 447
  %113 = mul i64 %7, 96
  %114 = getelementptr inbounds i8, ptr %3, i64 %113
  %115 = getelementptr inbounds i8, ptr %114, i64 32
  br i1 %112, label %117, label %116

116:                                              ; preds = %111
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %115) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %106, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %115) #15
  br label %118

117:                                              ; preds = %111
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %115)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %106, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %115)
  br label %118

118:                                              ; preds = %117, %116, %107, %95
  %119 = mul i64 %7, 72
  %120 = getelementptr inbounds i8, ptr %3, i64 %119
  %121 = getelementptr inbounds i8, ptr %120, i64 24
  tail call void @__gmpn_toom_couple_handling(ptr noundef nonnull %121, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 3, i32 noundef 6) #15
  %122 = tail call i32 @__gmpn_toom_eval_pm2rexp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 1, ptr noundef %0) #15
  br i1 %17, label %128, label %123

123:                                              ; preds = %118
  %124 = mul i64 %7, 96
  %125 = getelementptr inbounds i8, ptr %3, i64 %124
  %126 = getelementptr inbounds i8, ptr %125, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %126) #15
  %127 = getelementptr inbounds i64, ptr %0, i64 %63
  tail call void @__gmpn_toom2_sqr(ptr noundef %127, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %126) #15
  br label %142

128:                                              ; preds = %118
  %129 = icmp sgt i64 %6, 397
  %130 = getelementptr inbounds i64, ptr %0, i64 %63
  br i1 %129, label %135, label %131

131:                                              ; preds = %128
  %132 = mul i64 %7, 96
  %133 = getelementptr inbounds i8, ptr %3, i64 %132
  %134 = getelementptr inbounds i8, ptr %133, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %134) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %130, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %134) #15
  br label %142

135:                                              ; preds = %128
  %136 = icmp sgt i64 %6, 447
  %137 = mul i64 %7, 96
  %138 = getelementptr inbounds i8, ptr %3, i64 %137
  %139 = getelementptr inbounds i8, ptr %138, i64 32
  br i1 %136, label %141, label %140

140:                                              ; preds = %135
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %139) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %130, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %139) #15
  br label %142

141:                                              ; preds = %135
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %139)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %130, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %139)
  br label %142

142:                                              ; preds = %141, %140, %131, %123
  %143 = getelementptr inbounds i64, ptr %0, i64 %63
  tail call void @__gmpn_toom_couple_handling(ptr noundef %143, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 1, i32 noundef 0) #15
  %144 = tail call i32 @__gmpn_toom_eval_pm1(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, ptr noundef %0) #15
  br i1 %17, label %150, label %145

145:                                              ; preds = %142
  %146 = mul i64 %7, 96
  %147 = getelementptr inbounds i8, ptr %3, i64 %146
  %148 = getelementptr inbounds i8, ptr %147, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %148) #15
  %149 = getelementptr inbounds i64, ptr %0, i64 %8
  tail call void @__gmpn_toom2_sqr(ptr noundef %149, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %148) #15
  br label %164

150:                                              ; preds = %142
  %151 = icmp sgt i64 %6, 397
  %152 = getelementptr inbounds i64, ptr %0, i64 %8
  br i1 %151, label %157, label %153

153:                                              ; preds = %150
  %154 = mul i64 %7, 96
  %155 = getelementptr inbounds i8, ptr %3, i64 %154
  %156 = getelementptr inbounds i8, ptr %155, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %156) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef nonnull %152, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %156) #15
  br label %164

157:                                              ; preds = %150
  %158 = icmp sgt i64 %6, 447
  %159 = mul i64 %7, 96
  %160 = getelementptr inbounds i8, ptr %3, i64 %159
  %161 = getelementptr inbounds i8, ptr %160, i64 32
  br i1 %158, label %163, label %162

162:                                              ; preds = %157
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %161) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef nonnull %152, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %161) #15
  br label %164

163:                                              ; preds = %157
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %161)
  tail call void @__gmpn_toom8_sqr(ptr noundef nonnull %152, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %161)
  br label %164

164:                                              ; preds = %163, %162, %153, %145
  %165 = getelementptr inbounds i64, ptr %0, i64 %8
  tail call void @__gmpn_toom_couple_handling(ptr noundef %165, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 0, i32 noundef 0) #15
  %166 = tail call i32 @__gmpn_toom_eval_pm2exp(ptr noundef nonnull %12, ptr noundef %14, i32 noundef 7, ptr noundef %1, i64 noundef %7, i64 noundef %9, i32 noundef 2, ptr noundef %0) #15
  br i1 %17, label %171, label %167

167:                                              ; preds = %164
  %168 = mul i64 %7, 96
  %169 = getelementptr inbounds i8, ptr %3, i64 %168
  %170 = getelementptr inbounds i8, ptr %169, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %170) #15
  tail call void @__gmpn_toom2_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %170) #15
  br label %184

171:                                              ; preds = %164
  %172 = icmp sgt i64 %6, 397
  br i1 %172, label %177, label %173

173:                                              ; preds = %171
  %174 = mul i64 %7, 96
  %175 = getelementptr inbounds i8, ptr %3, i64 %174
  %176 = getelementptr inbounds i8, ptr %175, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %176) #15
  tail call void @__gmpn_toom3_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %176) #15
  br label %184

177:                                              ; preds = %171
  %178 = icmp sgt i64 %6, 447
  %179 = mul i64 %7, 96
  %180 = getelementptr inbounds i8, ptr %3, i64 %179
  %181 = getelementptr inbounds i8, ptr %180, i64 32
  br i1 %178, label %183, label %182

182:                                              ; preds = %177
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %181) #15
  tail call void @__gmpn_toom6_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %181) #15
  br label %184

183:                                              ; preds = %177
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %14, i64 noundef %16, ptr noundef nonnull %181)
  tail call void @__gmpn_toom8_sqr(ptr noundef %14, ptr noundef nonnull %12, i64 noundef %16, ptr noundef nonnull %181)
  br label %184

184:                                              ; preds = %183, %182, %173, %167
  tail call void @__gmpn_toom_couple_handling(ptr noundef %14, i64 noundef %37, ptr noundef %0, i32 noundef 0, i64 noundef %7, i32 noundef 2, i32 noundef 4) #15
  %185 = icmp sgt i64 %6, 118
  br i1 %185, label %190, label %186

186:                                              ; preds = %184
  %187 = mul i64 %7, 96
  %188 = getelementptr inbounds i8, ptr %3, i64 %187
  %189 = getelementptr inbounds i8, ptr %188, i64 32
  tail call void @__gmpn_toom2_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %189) #15
  br label %203

190:                                              ; preds = %184
  %191 = icmp sgt i64 %6, 398
  br i1 %191, label %196, label %192

192:                                              ; preds = %190
  %193 = mul i64 %7, 96
  %194 = getelementptr inbounds i8, ptr %3, i64 %193
  %195 = getelementptr inbounds i8, ptr %194, i64 32
  tail call void @__gmpn_toom3_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %195) #15
  br label %203

196:                                              ; preds = %190
  %197 = icmp sgt i64 %6, 448
  %198 = mul i64 %7, 96
  %199 = getelementptr inbounds i8, ptr %3, i64 %198
  %200 = getelementptr inbounds i8, ptr %199, i64 32
  br i1 %197, label %202, label %201

201:                                              ; preds = %196
  tail call void @__gmpn_toom6_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %200) #15
  br label %203

202:                                              ; preds = %196
  tail call void @__gmpn_toom8_sqr(ptr noundef %0, ptr noundef %1, i64 noundef %7, ptr noundef nonnull %200)
  br label %203

203:                                              ; preds = %202, %201, %192, %186
  %204 = shl nsw i64 %9, 1
  %205 = mul i64 %7, 96
  %206 = getelementptr inbounds i8, ptr %3, i64 %205
  %207 = getelementptr inbounds i8, ptr %206, i64 32
  tail call void @__gmpn_toom_interpolate_16pts(ptr noundef %0, ptr noundef nonnull %121, ptr noundef nonnull %93, ptr noundef nonnull %65, ptr noundef %3, i64 noundef %7, i64 noundef %204, i32 noundef 0, ptr noundef nonnull %207) #15
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i64 0, 2) i64 @__gmpn_neg(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #3 {
  %4 = load i64, ptr %1, align 8, !tbaa !9
  %5 = icmp eq i64 %4, 0
  br i1 %5, label %6, label %17

6:                                                ; preds = %12, %3
  %7 = phi i64 [ %10, %12 ], [ %2, %3 ]
  %8 = phi ptr [ %13, %12 ], [ %1, %3 ]
  %9 = phi ptr [ %14, %12 ], [ %0, %3 ]
  store i64 0, ptr %9, align 8, !tbaa !9
  %10 = add nsw i64 %7, -1
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %28, label %12

12:                                               ; preds = %6
  %13 = getelementptr inbounds i8, ptr %8, i64 8
  %14 = getelementptr inbounds i8, ptr %9, i64 8
  %15 = load i64, ptr %13, align 8, !tbaa !9
  %16 = icmp eq i64 %15, 0
  br i1 %16, label %6, label %17, !llvm.loop !328

17:                                               ; preds = %12, %3
  %18 = phi ptr [ %0, %3 ], [ %14, %12 ]
  %19 = phi ptr [ %1, %3 ], [ %13, %12 ]
  %20 = phi i64 [ %2, %3 ], [ %10, %12 ]
  %21 = phi i64 [ %4, %3 ], [ %15, %12 ]
  %22 = sub i64 0, %21
  store i64 %22, ptr %18, align 8, !tbaa !9
  %23 = add nsw i64 %20, -1
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %28, label %25

25:                                               ; preds = %17
  %26 = getelementptr inbounds i8, ptr %18, i64 8
  %27 = getelementptr inbounds i8, ptr %19, i64 8
  tail call void @__gmpn_com(ptr noundef nonnull %26, ptr noundef nonnull %27, i64 noundef %23) #15
  br label %28

28:                                               ; preds = %25, %17, %6
  %29 = phi i64 [ 1, %25 ], [ 1, %17 ], [ 0, %6 ]
  ret i64 %29
}

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #6 = { nofree nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #7 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #8 = { noreturn nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #9 = { cold noreturn nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #10 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #11 = { inlinehint nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #12 = { mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #13 = { nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #14 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #15 = { nounwind }
attributes #16 = { cold noreturn nounwind }
attributes #17 = { noreturn nounwind }
attributes #18 = { nounwind willreturn memory(none) }
attributes #19 = { nounwind willreturn memory(read) }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{!6, !6, i64 0}
!6 = !{!"any pointer", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !7, i64 0}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{!"llvm.loop.unroll.disable"}
!14 = distinct !{!14, !12, !13}
!15 = distinct !{!15, !12, !13}
!16 = distinct !{!16, !12, !13}
!17 = distinct !{!17, !12, !13}
!18 = distinct !{!18, !12, !13}
!19 = distinct !{!19, !12, !13}
!20 = distinct !{!20, !12, !13}
!21 = distinct !{!21, !12, !13}
!22 = distinct !{!22, !12, !13}
!23 = distinct !{!23, !12, !13}
!24 = distinct !{!24, !12, !13}
!25 = distinct !{!25, !12, !13}
!26 = distinct !{!26, !12, !13}
!27 = distinct !{!27, !12, !13}
!28 = distinct !{!28, !12, !13}
!29 = distinct !{!29, !12, !13}
!30 = !{!"branch_weights", !"expected", i32 2000, i32 1}
!31 = distinct !{!31, !12, !13}
!32 = distinct !{!32, !12, !13}
!33 = distinct !{!33, !12, !13}
!34 = distinct !{!34, !12, !13}
!35 = distinct !{!35, !12, !13}
!36 = distinct !{!36, !12, !13}
!37 = distinct !{!37, !12, !13}
!38 = !{!7, !7, i64 0}
!39 = distinct !{!39, !12, !13}
!40 = distinct !{!40, !12, !13}
!41 = distinct !{!41, !12, !13}
!42 = distinct !{!42, !12, !13}
!43 = distinct !{!43, !12, !13}
!44 = distinct !{!44, !12, !13}
!45 = distinct !{!45, !12, !13}
!46 = distinct !{!46, !12, !13}
!47 = distinct !{!47, !12, !13}
!48 = distinct !{!48, !12, !13}
!49 = !{!50, !50, i64 0}
!50 = !{!"int", !7, i64 0}
!51 = distinct !{!51, !12, !13}
!52 = distinct !{!52, !12, !13}
!53 = distinct !{!53, !12, !13}
!54 = distinct !{!54, !13}
!55 = !{!"branch_weights", !"expected", i32 1, i32 2000}
!56 = distinct !{!56, !12, !13}
!57 = distinct !{!57, !12, !13}
!58 = distinct !{!58, !12, !13}
!59 = distinct !{!59, !12, !13}
!60 = distinct !{!60, !13}
!61 = distinct !{!61, !12, !13}
!62 = distinct !{!62, !12, !13}
!63 = distinct !{!63, !12, !13}
!64 = distinct !{!64, !12, !13}
!65 = distinct !{!65, !12, !13}
!66 = distinct !{!66, !12, !13}
!67 = distinct !{!67, !12, !13}
!68 = distinct !{!68, !12, !13}
!69 = distinct !{!69, !12, !13}
!70 = distinct !{!70, !12, !13}
!71 = distinct !{!71, !12, !13}
!72 = distinct !{!72, !12, !13}
!73 = distinct !{!73, !12, !13}
!74 = distinct !{!74, !12, !13}
!75 = distinct !{!75, !12, !13}
!76 = distinct !{!76, !12, !13}
!77 = distinct !{!77, !12, !13}
!78 = distinct !{!78, !12, !13}
!79 = distinct !{!79, !12, !13}
!80 = distinct !{!80, !12, !13}
!81 = distinct !{!81, !12, !13}
!82 = distinct !{!82, !12, !13}
!83 = distinct !{!83, !12, !13}
!84 = distinct !{!84, !12, !13}
!85 = distinct !{!85, !12, !13}
!86 = distinct !{!86, !12, !13}
!87 = distinct !{!87, !12, !13}
!88 = distinct !{!88, !12, !13}
!89 = distinct !{!89, !12, !13}
!90 = distinct !{!90, !12, !13}
!91 = distinct !{!91, !12, !13}
!92 = distinct !{!92, !12, !13}
!93 = distinct !{!93, !12, !13}
!94 = distinct !{!94, !12, !13}
!95 = distinct !{!95, !12, !13}
!96 = distinct !{!96, !12, !13}
!97 = distinct !{!97, !12, !13}
!98 = distinct !{!98, !12, !13}
!99 = distinct !{!99, !12, !13}
!100 = distinct !{!100, !12, !13}
!101 = distinct !{!101, !12, !13}
!102 = distinct !{!102, !12, !13}
!103 = distinct !{!103, !12, !13}
!104 = distinct !{!104, !12, !13}
!105 = distinct !{!105, !12, !13}
!106 = distinct !{!106, !12, !13}
!107 = distinct !{!107, !12, !13}
!108 = distinct !{!108, !12, !13}
!109 = distinct !{!109, !12, !13}
!110 = distinct !{!110, !12, !13}
!111 = distinct !{!111, !12, !13}
!112 = distinct !{!112, !12, !13}
!113 = distinct !{!113, !12, !13}
!114 = distinct !{!114, !12, !13}
!115 = distinct !{!115, !12, !13}
!116 = distinct !{!116, !12, !13}
!117 = distinct !{!117, !12, !13}
!118 = distinct !{!118, !12, !13}
!119 = distinct !{!119, !12, !13}
!120 = distinct !{!120, !12, !13}
!121 = distinct !{!121, !12, !13}
!122 = distinct !{!122, !12, !13}
!123 = distinct !{!123, !12, !13}
!124 = distinct !{!124, !12, !13}
!125 = distinct !{!125, !12, !13}
!126 = distinct !{!126, !12, !13}
!127 = distinct !{!127, !12, !13}
!128 = distinct !{!128, !12, !13}
!129 = distinct !{!129, !12, !13}
!130 = distinct !{!130, !12, !13}
!131 = distinct !{!131, !12, !13}
!132 = distinct !{!132, !12, !13}
!133 = distinct !{!133, !12, !13}
!134 = distinct !{!134, !12, !13}
!135 = distinct !{!135, !12, !13}
!136 = distinct !{!136, !12, !13}
!137 = distinct !{!137, !12, !13}
!138 = distinct !{!138, !12, !13}
!139 = distinct !{!139, !12, !13}
!140 = distinct !{!140, !12, !13}
!141 = distinct !{!141, !12, !13}
!142 = distinct !{!142, !12, !13}
!143 = distinct !{!143, !12, !13}
!144 = distinct !{!144, !12, !13}
!145 = distinct !{!145, !12, !13}
!146 = distinct !{!146, !12, !13}
!147 = distinct !{!147, !12, !13}
!148 = distinct !{!148, !12, !13}
!149 = distinct !{!149, !12, !13}
!150 = distinct !{!150, !12, !13}
!151 = distinct !{!151, !12, !13}
!152 = distinct !{!152, !12, !13}
!153 = distinct !{!153, !12, !13}
!154 = distinct !{!154, !12, !13}
!155 = distinct !{!155, !12, !13}
!156 = distinct !{!156, !12, !13}
!157 = distinct !{!157, !12, !13}
!158 = distinct !{!158, !12, !13}
!159 = distinct !{!159, !12, !13}
!160 = distinct !{!160, !12, !13}
!161 = distinct !{!161, !12, !13}
!162 = distinct !{!162, !12, !13}
!163 = distinct !{!163, !12, !13}
!164 = distinct !{!164, !12, !13}
!165 = distinct !{!165, !12, !13}
!166 = distinct !{!166, !12, !13}
!167 = distinct !{!167, !12, !13}
!168 = distinct !{!168, !12, !13}
!169 = distinct !{!169, !12, !13}
!170 = distinct !{!170, !12, !13}
!171 = distinct !{!171, !12, !13}
!172 = distinct !{!172, !12, !13}
!173 = distinct !{!173, !12, !13}
!174 = distinct !{!174, !12, !13}
!175 = distinct !{!175, !12, !13}
!176 = distinct !{!176, !12, !13}
!177 = distinct !{!177, !12, !13}
!178 = distinct !{!178, !12, !13}
!179 = distinct !{!179, !12, !13}
!180 = distinct !{!180, !12, !13}
!181 = distinct !{!181, !12, !13}
!182 = distinct !{!182, !12, !13}
!183 = distinct !{!183, !12, !13}
!184 = distinct !{!184, !12, !13}
!185 = distinct !{!185, !12, !13}
!186 = distinct !{!186, !12, !13}
!187 = distinct !{!187, !12, !13}
!188 = distinct !{!188, !12, !13}
!189 = distinct !{!189, !12, !13}
!190 = distinct !{!190, !12, !13}
!191 = distinct !{!191, !12, !13}
!192 = distinct !{!192, !12, !13}
!193 = distinct !{!193, !13}
!194 = distinct !{!194, !12, !13}
!195 = distinct !{!195, !12, !13}
!196 = distinct !{!196, !12, !13}
!197 = !{!"branch_weights", i32 0, i32 -382854991, i32 1955078, i32 977, i32 0}
!198 = distinct !{!198, !12, !13}
!199 = distinct !{!199, !12, !13}
!200 = distinct !{!200, !12, !13}
!201 = distinct !{!201, !12, !13}
!202 = distinct !{!202, !12, !13}
!203 = distinct !{!203, !12, !13}
!204 = distinct !{!204, !12, !13}
!205 = distinct !{!205, !12, !13}
!206 = distinct !{!206, !12, !13}
!207 = distinct !{!207, !12, !13}
!208 = distinct !{!208, !12, !13}
!209 = distinct !{!209, !12, !13}
!210 = distinct !{!210, !12, !13}
!211 = distinct !{!211, !12, !13}
!212 = distinct !{!212, !12, !13}
!213 = distinct !{!213, !12, !13}
!214 = distinct !{!214, !12, !13}
!215 = distinct !{!215, !12, !13}
!216 = distinct !{!216, !12, !13}
!217 = distinct !{!217, !12, !13}
!218 = distinct !{!218, !12, !13}
!219 = distinct !{!219, !12, !13}
!220 = distinct !{!220, !12, !13}
!221 = distinct !{!221, !12, !13}
!222 = distinct !{!222, !12, !13}
!223 = distinct !{!223, !12, !13}
!224 = distinct !{!224, !12, !13}
!225 = distinct !{!225, !12, !13}
!226 = distinct !{!226, !12, !13}
!227 = distinct !{!227, !12, !13}
!228 = distinct !{!228, !12, !13}
!229 = distinct !{!229, !12, !13}
!230 = distinct !{!230, !12, !13}
!231 = distinct !{!231, !12, !13}
!232 = distinct !{!232, !12, !13}
!233 = distinct !{!233, !12, !13}
!234 = distinct !{!234, !12, !13}
!235 = distinct !{!235, !12, !13}
!236 = distinct !{!236, !12, !13}
!237 = distinct !{!237, !12, !13}
!238 = distinct !{!238, !12, !13}
!239 = distinct !{!239, !12, !13}
!240 = distinct !{!240, !12, !13}
!241 = distinct !{!241, !12, !13}
!242 = distinct !{!242, !12, !13}
!243 = distinct !{!243, !12, !13}
!244 = distinct !{!244, !12, !13}
!245 = distinct !{!245, !12, !13}
!246 = distinct !{!246, !12, !13}
!247 = distinct !{!247, !12, !13}
!248 = distinct !{!248, !12, !13}
!249 = distinct !{!249, !12, !13}
!250 = distinct !{!250, !12, !13}
!251 = distinct !{!251, !12, !13}
!252 = distinct !{!252, !12, !13}
!253 = distinct !{!253, !12, !13}
!254 = distinct !{!254, !12, !13}
!255 = distinct !{!255, !12, !13}
!256 = distinct !{!256, !12, !13}
!257 = distinct !{!257, !12, !13}
!258 = distinct !{!258, !12, !13}
!259 = distinct !{!259, !12, !13}
!260 = distinct !{!260, !12, !13}
!261 = distinct !{!261, !12, !13}
!262 = distinct !{!262, !12, !13}
!263 = distinct !{!263, !12, !13}
!264 = distinct !{!264, !12, !13}
!265 = distinct !{!265, !12, !13}
!266 = distinct !{!266, !12, !13}
!267 = distinct !{!267, !12, !13}
!268 = distinct !{!268, !12, !13}
!269 = distinct !{!269, !12, !13}
!270 = distinct !{!270, !12, !13}
!271 = distinct !{!271, !12, !13}
!272 = distinct !{!272, !12, !13}
!273 = distinct !{!273, !12, !13}
!274 = distinct !{!274, !12, !13}
!275 = distinct !{!275, !12, !13}
!276 = distinct !{!276, !12, !13}
!277 = distinct !{!277, !12, !13}
!278 = distinct !{!278, !12, !13}
!279 = distinct !{!279, !12, !13}
!280 = distinct !{!280, !12, !13}
!281 = distinct !{!281, !12, !13}
!282 = distinct !{!282, !12, !13}
!283 = distinct !{!283, !12, !13}
!284 = distinct !{!284, !12, !13}
!285 = distinct !{!285, !12, !13}
!286 = distinct !{!286, !12, !13}
!287 = distinct !{!287, !12, !13}
!288 = distinct !{!288, !12, !13}
!289 = distinct !{!289, !12, !13}
!290 = distinct !{!290, !12, !13}
!291 = distinct !{!291, !12, !13}
!292 = distinct !{!292, !12, !13}
!293 = distinct !{!293, !12, !13}
!294 = distinct !{!294, !12, !13}
!295 = distinct !{!295, !12, !13}
!296 = distinct !{!296, !12, !13}
!297 = distinct !{!297, !12, !13}
!298 = distinct !{!298, !12, !13}
!299 = distinct !{!299, !12, !13}
!300 = distinct !{!300, !12, !13}
!301 = distinct !{!301, !12, !13}
!302 = distinct !{!302, !12, !13}
!303 = distinct !{!303, !12, !13}
!304 = distinct !{!304, !12, !13}
!305 = distinct !{!305, !12, !13}
!306 = distinct !{!306, !12, !13}
!307 = distinct !{!307, !12, !13}
!308 = distinct !{!308, !12, !13}
!309 = distinct !{!309, !12, !13}
!310 = distinct !{!310, !12, !13}
!311 = distinct !{!311, !12, !13}
!312 = distinct !{!312, !12, !13}
!313 = distinct !{!313, !12, !13}
!314 = distinct !{!314, !12, !13}
!315 = distinct !{!315, !12, !13}
!316 = distinct !{!316, !12, !13}
!317 = distinct !{!317, !12, !13}
!318 = distinct !{!318, !12, !13}
!319 = distinct !{!319, !12, !13}
!320 = !{!321, !10, i64 8}
!321 = !{!"tmp_reentrant_t", !6, i64 0, !10, i64 8}
!322 = !{!321, !6, i64 0}
!323 = distinct !{!323, !12, !13}
!324 = distinct !{!324, !12, !13}
!325 = distinct !{!325, !12, !13}
!326 = distinct !{!326, !12, !13}
!327 = distinct !{!327, !12, !13}
!328 = distinct !{!328, !12, !13}
