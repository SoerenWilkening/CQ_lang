; ModuleID = 'build/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.gmp_pi1_t = type { i64 }

@__gmpn_clz_tab = external local_unnamed_addr constant [129 x i8], align 16

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #1

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
declare range(i64 0, 2) i64 @__gmpn_divrem_2(ptr nocapture noundef writeonly, i64 noundef, ptr nocapture noundef, i64 noundef, ptr nocapture noundef readonly) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define void @__gmpn_div_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %5) local_unnamed_addr #3 {
  %7 = alloca %struct.gmp_pi1_t, align 8
  %8 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #7
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #7
  store ptr null, ptr %8, align 8, !tbaa !5
  %9 = add nsw i64 %4, -1
  %10 = getelementptr inbounds i64, ptr %3, i64 %9
  %11 = load i64, ptr %10, align 8, !tbaa !9
  %12 = icmp eq i64 %4, 1
  br i1 %12, label %13, label %15

13:                                               ; preds = %6
  %14 = tail call i64 @__gmpn_divrem_1(ptr noundef %0, i64 noundef 0, ptr noundef %1, i64 noundef %2, i64 noundef %11) #7
  br label %1031

15:                                               ; preds = %6
  %16 = sub nsw i64 %2, %4
  %17 = add nsw i64 %16, 1
  %18 = add nsw i64 %16, 6
  %19 = icmp slt i64 %18, %4
  br i1 %19, label %488, label %20

20:                                               ; preds = %15
  %21 = icmp sgt i64 %11, -1
  br i1 %21, label %22, label %261, !prof !11

22:                                               ; preds = %27, %20
  %23 = phi i64 [ %28, %27 ], [ 56, %20 ]
  %24 = shl i64 255, %23
  %25 = and i64 %24, %11
  %26 = icmp eq i64 %25, 0
  br i1 %26, label %27, label %30

27:                                               ; preds = %22
  %28 = add nsw i64 %23, -8
  %29 = icmp eq i64 %28, 0
  br i1 %29, label %30, label %22, !llvm.loop !12

30:                                               ; preds = %27, %22
  %31 = phi i64 [ %23, %22 ], [ 0, %27 ]
  %32 = or disjoint i64 %31, 1
  %33 = lshr i64 %11, %32
  %34 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %33
  %35 = load i8, ptr %34, align 1, !tbaa !15
  %36 = zext i8 %35 to i64
  %37 = add i64 %32, %36
  %38 = trunc i64 %37 to i32
  %39 = sub i32 65, %38
  %40 = tail call i64 @__gmpn_lshift(ptr noundef %5, ptr noundef %1, i64 noundef %2, i32 noundef %39) #7
  %41 = getelementptr inbounds i64, ptr %5, i64 %2
  store i64 %40, ptr %41, align 8, !tbaa !9
  %42 = icmp ne i64 %40, 0
  %43 = zext i1 %42 to i64
  %44 = add nsw i64 %43, %2
  %45 = shl i64 %4, 3
  %46 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %45) #7
  %47 = call i64 @__gmpn_lshift(ptr noundef %46, ptr noundef %3, i64 noundef %4, i32 noundef %39) #7
  %48 = icmp eq i64 %4, 2
  br i1 %48, label %49, label %51

49:                                               ; preds = %30
  %50 = call i64 @__gmpn_divrem_2(ptr noundef %0, i64 noundef 0, ptr noundef %5, i64 noundef %44, ptr noundef %46) #7
  br label %258

51:                                               ; preds = %30
  %52 = icmp sgt i64 %4, 199
  %53 = sub nsw i64 %44, %4
  %54 = icmp sgt i64 %53, 199
  %55 = select i1 %52, i1 %54, i1 false
  br i1 %55, label %150, label %56

56:                                               ; preds = %51
  %57 = getelementptr inbounds i64, ptr %46, i64 %9
  %58 = load i64, ptr %57, align 8, !tbaa !9
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
  %103 = load i64, ptr %102, align 8, !tbaa !9
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
  br i1 %140, label %147, label %141, !prof !11

141:                                              ; preds = %138
  %142 = icmp ule i64 %136, %58
  %143 = icmp ult i64 %135, %103
  %144 = select i1 %142, i1 %143, i1 false
  %145 = add i64 %116, -2
  %146 = select i1 %144, i64 %139, i64 %145
  br label %147

147:                                              ; preds = %141, %138, %114
  %148 = phi i64 [ %139, %138 ], [ %116, %114 ], [ %146, %141 ]
  store i64 %148, ptr %7, align 8, !tbaa !16
  %149 = call i64 @__gmpn_sbpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %44, ptr noundef %46, i64 noundef %4, i64 noundef %148) #7
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
  %161 = load i64, ptr %160, align 8, !tbaa !9
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
  %206 = load i64, ptr %205, align 8, !tbaa !9
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
  br i1 %243, label %250, label %244, !prof !11

244:                                              ; preds = %241
  %245 = icmp ule i64 %239, %161
  %246 = icmp ult i64 %238, %206
  %247 = select i1 %245, i1 %246, i1 false
  %248 = add i64 %219, -2
  %249 = select i1 %247, i64 %242, i64 %248
  br label %250

250:                                              ; preds = %244, %241, %217
  %251 = phi i64 [ %242, %241 ], [ %219, %217 ], [ %249, %244 ]
  store i64 %251, ptr %7, align 8, !tbaa !16
  %252 = call i64 @__gmpn_dcpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %44, ptr noundef %46, i64 noundef %4, ptr noundef nonnull %7) #7
  br label %258

253:                                              ; preds = %152
  %254 = call i64 @__gmpn_mu_div_q_itch(i64 noundef %44, i64 noundef %4, i32 noundef 0) #8
  %255 = shl i64 %254, 3
  %256 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %255) #7
  %257 = call i64 @__gmpn_mu_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %44, ptr noundef %46, i64 noundef %4, ptr noundef %256) #7
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
  %267 = load i64, ptr %1, align 8, !tbaa !9
  %268 = icmp eq i64 %266, 0
  br i1 %268, label %279, label %269

269:                                              ; preds = %269, %265
  %270 = phi i64 [ %276, %269 ], [ %267, %265 ]
  %271 = phi ptr [ %274, %269 ], [ %1, %265 ]
  %272 = phi ptr [ %275, %269 ], [ %5, %265 ]
  %273 = phi i64 [ %277, %269 ], [ %266, %265 ]
  %274 = getelementptr inbounds i8, ptr %271, i64 8
  %275 = getelementptr inbounds i8, ptr %272, i64 8
  store i64 %270, ptr %272, align 8, !tbaa !9
  %276 = load i64, ptr %274, align 8, !tbaa !9
  %277 = add nsw i64 %273, -1
  %278 = icmp eq i64 %277, 0
  br i1 %278, label %279, label %269, !llvm.loop !18

279:                                              ; preds = %269, %265
  %280 = phi i64 [ %267, %265 ], [ %276, %269 ]
  %281 = phi ptr [ %5, %265 ], [ %275, %269 ]
  store i64 %280, ptr %281, align 8, !tbaa !9
  br label %282

282:                                              ; preds = %279, %261
  %283 = icmp eq i64 %4, 2
  br i1 %283, label %284, label %286

284:                                              ; preds = %282
  %285 = tail call i64 @__gmpn_divrem_2(ptr noundef %0, i64 noundef 0, ptr noundef %5, i64 noundef %2, ptr noundef %3) #7
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
  %335 = load i64, ptr %334, align 8, !tbaa !9
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
  br i1 %372, label %379, label %373, !prof !11

373:                                              ; preds = %370
  %374 = icmp ule i64 %368, %11
  %375 = icmp ult i64 %367, %335
  %376 = select i1 %374, i1 %375, i1 false
  %377 = add i64 %348, -2
  %378 = select i1 %376, i64 %371, i64 %377
  br label %379

379:                                              ; preds = %373, %370, %346
  %380 = phi i64 [ %371, %370 ], [ %348, %346 ], [ %378, %373 ]
  store i64 %380, ptr %7, align 8, !tbaa !16
  %381 = tail call i64 @__gmpn_sbpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %2, ptr noundef %3, i64 noundef %4, i64 noundef %380) #7
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
  %436 = load i64, ptr %435, align 8, !tbaa !9
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
  br i1 %473, label %480, label %474, !prof !11

474:                                              ; preds = %471
  %475 = icmp ule i64 %469, %11
  %476 = icmp ult i64 %468, %436
  %477 = select i1 %475, i1 %476, i1 false
  %478 = add i64 %449, -2
  %479 = select i1 %477, i64 %472, i64 %478
  br label %480

480:                                              ; preds = %474, %471, %447
  %481 = phi i64 [ %472, %471 ], [ %449, %447 ], [ %479, %474 ]
  store i64 %481, ptr %7, align 8, !tbaa !16
  %482 = call i64 @__gmpn_dcpi1_div_q(ptr noundef %0, ptr noundef %5, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %7) #7
  br label %1026

483:                                              ; preds = %384
  %484 = tail call i64 @__gmpn_mu_div_q_itch(i64 noundef %2, i64 noundef %4, i32 noundef 0) #8
  %485 = shl i64 %484, 3
  %486 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %485) #7
  %487 = call i64 @__gmpn_mu_div_q(ptr noundef %0, ptr noundef %1, i64 noundef %2, ptr noundef %3, i64 noundef %4, ptr noundef %486) #7
  br label %1026

488:                                              ; preds = %15
  %489 = add nsw i64 %16, 2
  %490 = shl i64 %489, 3
  %491 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %490) #7
  %492 = shl nsw i64 %17, 1
  %493 = or disjoint i64 %492, 1
  %494 = icmp eq ptr %5, %1
  br i1 %494, label %495, label %499

495:                                              ; preds = %488
  %496 = shl i64 %17, 4
  %497 = add i64 %496, 16
  %498 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %497) #7
  br label %499

499:                                              ; preds = %495, %488
  %500 = phi ptr [ %498, %495 ], [ %5, %488 ]
  %501 = icmp sgt i64 %11, -1
  br i1 %501, label %502, label %752, !prof !11

502:                                              ; preds = %507, %499
  %503 = phi i64 [ %508, %507 ], [ 56, %499 ]
  %504 = shl i64 255, %503
  %505 = and i64 %504, %11
  %506 = icmp eq i64 %505, 0
  br i1 %506, label %507, label %510

507:                                              ; preds = %502
  %508 = add nsw i64 %503, -8
  %509 = icmp eq i64 %508, 0
  br i1 %509, label %510, label %502, !llvm.loop !19

510:                                              ; preds = %507, %502
  %511 = phi i64 [ %503, %502 ], [ 0, %507 ]
  %512 = or disjoint i64 %511, 1
  %513 = lshr i64 %11, %512
  %514 = getelementptr inbounds [129 x i8], ptr @__gmpn_clz_tab, i64 0, i64 %513
  %515 = load i8, ptr %514, align 1, !tbaa !15
  %516 = zext i8 %515 to i64
  %517 = add i64 %512, %516
  %518 = trunc i64 %517 to i32
  %519 = sub i32 65, %518
  %520 = getelementptr inbounds i64, ptr %1, i64 %2
  %521 = sub nsw i64 0, %493
  %522 = getelementptr inbounds i64, ptr %520, i64 %521
  %523 = call i64 @__gmpn_lshift(ptr noundef %500, ptr noundef nonnull %522, i64 noundef %493, i32 noundef %519) #7
  %524 = getelementptr inbounds i64, ptr %500, i64 %493
  store i64 %523, ptr %524, align 8, !tbaa !9
  %525 = icmp ne i64 %523, 0
  %526 = zext i1 %525 to i64
  %527 = add nsw i64 %493, %526
  %528 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %490) #7
  %529 = getelementptr inbounds i64, ptr %3, i64 %4
  %530 = sub nsw i64 -2, %16
  %531 = getelementptr inbounds i64, ptr %529, i64 %530
  %532 = call i64 @__gmpn_lshift(ptr noundef %528, ptr noundef %531, i64 noundef %489, i32 noundef %519) #7
  %533 = sub i64 %4, %16
  %534 = getelementptr i64, ptr %3, i64 %533
  %535 = getelementptr i8, ptr %534, i64 -24
  %536 = load i64, ptr %535, align 8, !tbaa !9
  %537 = add i64 %517, 4294967295
  %538 = and i64 %537, 4294967295
  %539 = lshr i64 %536, %538
  %540 = load i64, ptr %528, align 8, !tbaa !9
  %541 = or i64 %540, %539
  store i64 %541, ptr %528, align 8, !tbaa !9
  %542 = icmp eq i64 %16, 0
  br i1 %542, label %543, label %545

543:                                              ; preds = %510
  %544 = call i64 @__gmpn_divrem_2(ptr noundef %491, i64 noundef 0, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528) #7
  br label %740

545:                                              ; preds = %510
  %546 = icmp sgt i64 %16, 197
  br i1 %546, label %640, label %547

547:                                              ; preds = %545
  %548 = getelementptr inbounds i64, ptr %528, i64 %17
  %549 = load i64, ptr %548, align 8, !tbaa !9
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
  %593 = load i64, ptr %592, align 8, !tbaa !9
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
  br i1 %630, label %637, label %631, !prof !11

631:                                              ; preds = %628
  %632 = icmp ule i64 %626, %549
  %633 = icmp ult i64 %625, %593
  %634 = select i1 %632, i1 %633, i1 false
  %635 = add i64 %606, -2
  %636 = select i1 %634, i64 %629, i64 %635
  br label %637

637:                                              ; preds = %631, %628, %604
  %638 = phi i64 [ %629, %628 ], [ %606, %604 ], [ %636, %631 ]
  store i64 %638, ptr %7, align 8, !tbaa !16
  %639 = call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528, i64 noundef %489, i64 noundef %638) #7
  br label %740

640:                                              ; preds = %545
  %641 = icmp sgt i64 %16, 1997
  br i1 %641, label %735, label %642

642:                                              ; preds = %640
  %643 = getelementptr inbounds i64, ptr %528, i64 %17
  %644 = load i64, ptr %643, align 8, !tbaa !9
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
  %688 = load i64, ptr %687, align 8, !tbaa !9
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
  br i1 %725, label %732, label %726, !prof !11

726:                                              ; preds = %723
  %727 = icmp ule i64 %721, %644
  %728 = icmp ult i64 %720, %688
  %729 = select i1 %727, i1 %728, i1 false
  %730 = add i64 %700, -2
  %731 = select i1 %729, i64 %724, i64 %730
  br label %732

732:                                              ; preds = %726, %723, %699
  %733 = phi i64 [ %724, %723 ], [ %700, %699 ], [ %731, %726 ]
  store i64 %733, ptr %7, align 8, !tbaa !16
  %734 = call i64 @__gmpn_dcpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528, i64 noundef %489, ptr noundef nonnull %7) #7
  br label %740

735:                                              ; preds = %640
  %736 = call i64 @__gmpn_mu_divappr_q_itch(i64 noundef %527, i64 noundef %489, i32 noundef 0) #8
  %737 = shl i64 %736, 3
  %738 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %737) #7
  %739 = call i64 @__gmpn_mu_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %527, ptr noundef nonnull %528, i64 noundef %489, ptr noundef %738) #7
  br label %740

740:                                              ; preds = %735, %732, %637, %543
  %741 = phi i64 [ %544, %543 ], [ %739, %735 ], [ %734, %732 ], [ %639, %637 ]
  %742 = icmp eq i64 %523, 0
  br i1 %742, label %743, label %745

743:                                              ; preds = %740
  %744 = getelementptr inbounds i64, ptr %491, i64 %17
  store i64 %741, ptr %744, align 8, !tbaa !9
  br label %971

745:                                              ; preds = %740
  %746 = icmp eq i64 %741, 0
  br i1 %746, label %971, label %747, !prof !11

747:                                              ; preds = %745
  %748 = sub nsw i64 %527, %489
  %749 = icmp sgt i64 %748, 0
  br i1 %749, label %750, label %971

750:                                              ; preds = %747
  %751 = shl nuw i64 %748, 3
  call void @llvm.memset.p0.i64(ptr align 8 %491, i8 -1, i64 %751, i1 false), !tbaa !9
  br label %971

752:                                              ; preds = %499
  %753 = getelementptr inbounds i64, ptr %1, i64 %2
  %754 = sub nsw i64 0, %493
  %755 = getelementptr inbounds i64, ptr %753, i64 %754
  %756 = load i64, ptr %755, align 8, !tbaa !9
  %757 = icmp eq i64 %17, 0
  br i1 %757, label %768, label %758

758:                                              ; preds = %758, %752
  %759 = phi i64 [ %766, %758 ], [ %492, %752 ]
  %760 = phi ptr [ %764, %758 ], [ %500, %752 ]
  %761 = phi ptr [ %763, %758 ], [ %755, %752 ]
  %762 = phi i64 [ %765, %758 ], [ %756, %752 ]
  %763 = getelementptr inbounds i8, ptr %761, i64 8
  %764 = getelementptr inbounds i8, ptr %760, i64 8
  store i64 %762, ptr %760, align 8, !tbaa !9
  %765 = load i64, ptr %763, align 8, !tbaa !9
  %766 = add nsw i64 %759, -1
  %767 = icmp eq i64 %766, 0
  br i1 %767, label %768, label %758, !llvm.loop !20

768:                                              ; preds = %758, %752
  %769 = phi ptr [ %500, %752 ], [ %764, %758 ]
  %770 = phi i64 [ %756, %752 ], [ %765, %758 ]
  store i64 %770, ptr %769, align 8, !tbaa !9
  %771 = getelementptr inbounds i64, ptr %3, i64 %4
  %772 = sub nsw i64 -2, %16
  %773 = getelementptr inbounds i64, ptr %771, i64 %772
  %774 = icmp eq i64 %16, 0
  br i1 %774, label %775, label %777

775:                                              ; preds = %768
  %776 = call i64 @__gmpn_divrem_2(ptr noundef %491, i64 noundef 0, ptr noundef %500, i64 noundef %493, ptr noundef nonnull %773) #7
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
  %823 = load i64, ptr %822, align 8, !tbaa !9
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
  br i1 %860, label %867, label %861, !prof !11

861:                                              ; preds = %858
  %862 = icmp ule i64 %856, %11
  %863 = icmp ult i64 %855, %823
  %864 = select i1 %862, i1 %863, i1 false
  %865 = add i64 %835, -2
  %866 = select i1 %864, i64 %859, i64 %865
  br label %867

867:                                              ; preds = %861, %858, %834
  %868 = phi i64 [ %859, %858 ], [ %835, %834 ], [ %866, %861 ]
  store i64 %868, ptr %7, align 8, !tbaa !16
  %869 = call i64 @__gmpn_sbpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %493, ptr noundef %773, i64 noundef %489, i64 noundef %868) #7
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
  %916 = load i64, ptr %915, align 8, !tbaa !9
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
  br i1 %953, label %960, label %954, !prof !11

954:                                              ; preds = %951
  %955 = icmp ule i64 %949, %11
  %956 = icmp ult i64 %948, %916
  %957 = select i1 %955, i1 %956, i1 false
  %958 = add i64 %928, -2
  %959 = select i1 %957, i64 %952, i64 %958
  br label %960

960:                                              ; preds = %954, %951, %927
  %961 = phi i64 [ %952, %951 ], [ %928, %927 ], [ %959, %954 ]
  store i64 %961, ptr %7, align 8, !tbaa !16
  %962 = call i64 @__gmpn_dcpi1_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %493, ptr noundef nonnull %773, i64 noundef %489, ptr noundef nonnull %7) #7
  br label %968

963:                                              ; preds = %870
  %964 = call i64 @__gmpn_mu_divappr_q_itch(i64 noundef %493, i64 noundef %489, i32 noundef 0) #8
  %965 = shl i64 %964, 3
  %966 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %965) #7
  %967 = call i64 @__gmpn_mu_divappr_q(ptr noundef %491, ptr noundef %500, i64 noundef %493, ptr noundef nonnull %773, i64 noundef %489, ptr noundef %966) #7
  br label %968

968:                                              ; preds = %963, %960, %867, %775
  %969 = phi i64 [ %776, %775 ], [ %967, %963 ], [ %962, %960 ], [ %869, %867 ]
  %970 = getelementptr inbounds i64, ptr %491, i64 %17
  store i64 %969, ptr %970, align 8, !tbaa !9
  br label %971

971:                                              ; preds = %968, %750, %747, %745, %743
  %972 = icmp eq i64 %17, 0
  br i1 %972, label %992, label %973

973:                                              ; preds = %971
  %974 = getelementptr inbounds i8, ptr %491, i64 8
  %975 = load i64, ptr %974, align 8, !tbaa !9
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
  store i64 %983, ptr %981, align 8, !tbaa !9
  %985 = getelementptr inbounds i8, ptr %982, i64 8
  %986 = load i64, ptr %982, align 8, !tbaa !9
  %987 = add nsw i64 %980, -1
  %988 = icmp eq i64 %987, 0
  br i1 %988, label %989, label %979, !llvm.loop !21

989:                                              ; preds = %979, %973
  %990 = phi ptr [ %0, %973 ], [ %984, %979 ]
  %991 = phi i64 [ %975, %973 ], [ %986, %979 ]
  store i64 %991, ptr %990, align 8, !tbaa !9
  br label %992

992:                                              ; preds = %989, %971
  %993 = load i64, ptr %491, align 8, !tbaa !9
  %994 = icmp ult i64 %993, 5
  br i1 %994, label %995, label %1029

995:                                              ; preds = %992
  %996 = add i64 %2, 1
  %997 = shl i64 %996, 3
  %998 = call noalias ptr @__gmp_tmp_reentrant_alloc(ptr noundef nonnull %8, i64 noundef %997) #7
  %999 = getelementptr inbounds i8, ptr %491, i64 8
  %1000 = call i64 @__gmpn_mul(ptr noundef %998, ptr noundef %3, i64 noundef %4, ptr noundef nonnull %999, i64 noundef %17) #7
  %1001 = getelementptr inbounds i64, ptr %998, i64 %2
  %1002 = load i64, ptr %1001, align 8, !tbaa !9
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
  %1013 = load i64, ptr %1012, align 8, !tbaa !9
  %1014 = getelementptr inbounds i64, ptr %998, i64 %1011
  %1015 = load i64, ptr %1014, align 8, !tbaa !9
  %1016 = icmp eq i64 %1013, %1015
  br i1 %1016, label %1007, label %1017, !llvm.loop !22

1017:                                             ; preds = %1010
  %1018 = icmp ugt i64 %1013, %1015
  br i1 %1018, label %1029, label %1019

1019:                                             ; preds = %1017, %995
  br label %1020

1020:                                             ; preds = %1020, %1019
  %1021 = phi ptr [ %1022, %1020 ], [ %0, %1019 ]
  %1022 = getelementptr inbounds i8, ptr %1021, i64 8
  %1023 = load i64, ptr %1021, align 8, !tbaa !9
  %1024 = add i64 %1023, -1
  store i64 %1024, ptr %1021, align 8, !tbaa !9
  %1025 = icmp eq i64 %1023, 0
  br i1 %1025, label %1020, label %1029, !llvm.loop !23

1026:                                             ; preds = %483, %480, %379, %284, %258
  %1027 = phi i64 [ %259, %258 ], [ %285, %284 ], [ %482, %480 ], [ %487, %483 ], [ %381, %379 ]
  %1028 = getelementptr inbounds i64, ptr %0, i64 %16
  store i64 %1027, ptr %1028, align 8, !tbaa !9
  br label %1029

1029:                                             ; preds = %1026, %1020, %1017, %1007, %992, %258
  %1030 = load ptr, ptr %8, align 8, !tbaa !5
  call void @__gmp_tmp_reentrant_free(ptr noundef %1030) #7
  br label %1031

1031:                                             ; preds = %1029, %13
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #7
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
declare i64 @__gmpn_lshift(ptr nocapture noundef writeonly, ptr nocapture noundef readonly, i64 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
declare i64 @__gmpn_dcpi1_divappr_q(ptr noundef, ptr noundef, i64 noundef, ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
declare i64 @__gmpn_dcpi1_div_q(ptr noundef writeonly, ptr nocapture noundef readonly, i64 noundef, ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
declare range(i64 0, 2) i64 @__gmpn_sbpi1_divappr_q(ptr nocapture noundef writeonly, ptr noundef, i64 noundef, ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
declare range(i64 0, 2) i64 @__gmpn_mu_divappr_q(ptr noundef, ptr noundef, i64 noundef, ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
declare i64 @__gmpn_mu_divappr_q_itch(i64 noundef, i64 noundef, i32 noundef) local_unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
declare i64 @__gmpn_sbpi1_div_q(ptr noundef, ptr noundef, i64 noundef, ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
declare i64 @__gmpn_mu_div_q(ptr noundef writeonly, ptr noundef, i64 noundef, ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
declare i64 @__gmpn_mu_div_q_itch(i64 noundef, i64 noundef, i32 noundef) local_unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
declare i64 @__gmpn_mul(ptr noundef, ptr noundef, i64 noundef, ptr noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none) uwtable
declare i64 @__gmpn_divrem_1(ptr nocapture noundef writeonly, i64 noundef, ptr nocapture noundef readonly, i64 noundef, i64 noundef) local_unnamed_addr #6

; Function Attrs: nounwind ssp uwtable
declare noalias ptr @__gmp_tmp_reentrant_alloc(ptr nocapture noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
declare void @__gmp_tmp_reentrant_free(ptr noundef) local_unnamed_addr #3

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #2 = { nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #3 = { nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #6 = { nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #7 = { nounwind }
attributes #8 = { nounwind willreturn memory(none) }

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
!11 = !{!"branch_weights", !"expected", i32 2000, i32 1}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = !{!7, !7, i64 0}
!16 = !{!17, !10, i64 0}
!17 = !{!"", !10, i64 0}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
!20 = distinct !{!20, !13, !14}
!21 = distinct !{!21, !13, !14}
!22 = distinct !{!22, !13, !14}
!23 = distinct !{!23, !13, !14}
