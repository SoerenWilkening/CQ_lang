; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define zeroext i16 @f(i16 noundef zeroext %0, i16 noundef zeroext %1, i16 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %0, double noundef 3.000000e-01) #4
  %5 = bitcast i16 %4 to half
  %6 = bitcast i16 %1 to half
  %7 = bitcast i16 %2 to half
  %8 = tail call half @cqsf_fma_f16(half noundef %5, half noundef %6, half noundef %7) #5
  %9 = bitcast half %8 to i16
  %10 = tail call zeroext i16 @cq_measure_ui16(i16 noundef zeroext %9) #5
  ret i16 %10
}

declare zeroext i16 @cq_theta_ui16(i16 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i16 @cq_measure_ui16(i16 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define half @cqsf_fma_f16(half noundef %0, half noundef %1, half noundef %2) local_unnamed_addr #0 {
  %4 = bitcast half %0 to i16
  %5 = bitcast half %1 to i16
  %6 = bitcast half %2 to i16
  %7 = tail call zeroext i16 @cqsfi_fma_f16(i16 noundef zeroext %4, i16 noundef zeroext %5, i16 noundef zeroext %6) #5
  %8 = bitcast i16 %7 to half
  ret half %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal zeroext i16 @cqsfi_fma_f16(i16 noundef zeroext %0, i16 noundef zeroext %1, i16 noundef zeroext %2) local_unnamed_addr #2 {
  %4 = zext i16 %0 to i32
  %5 = and i32 %4, 31744
  %6 = icmp eq i32 %5, 31744
  %7 = and i32 %4, 1023
  %8 = icmp ne i32 %7, 0
  %9 = and i1 %6, %8
  br i1 %9, label %33, label %10

10:                                               ; preds = %3
  %11 = zext i16 %1 to i32
  %12 = and i32 %11, 31744
  %13 = icmp eq i32 %12, 31744
  %14 = and i32 %11, 1023
  %15 = icmp ne i32 %14, 0
  %16 = and i1 %13, %15
  br i1 %16, label %24, label %17

17:                                               ; preds = %10
  %18 = zext i16 %2 to i32
  %19 = and i32 %18, 31744
  %20 = icmp eq i32 %19, 31744
  %21 = and i32 %18, 1023
  %22 = icmp ne i32 %21, 0
  %23 = and i1 %20, %22
  br i1 %23, label %24, label %36

24:                                               ; preds = %17, %10
  br i1 %9, label %33, label %25

25:                                               ; preds = %24
  %26 = zext i16 %1 to i32
  %27 = and i32 %26, 31744
  %28 = icmp eq i32 %27, 31744
  %29 = and i32 %26, 1023
  %30 = icmp ne i32 %29, 0
  %31 = and i1 %28, %30
  %32 = select i1 %31, i16 %1, i16 %2
  br label %33

33:                                               ; preds = %25, %24, %3
  %34 = phi i16 [ %32, %25 ], [ %0, %24 ], [ %0, %3 ]
  %35 = or i16 %34, 512
  br label %363

36:                                               ; preds = %17
  %37 = lshr i16 %0, 10
  %38 = trunc nuw nsw i16 %37 to i8
  %39 = and i8 %38, 31
  %40 = and i16 %0, 1023
  %41 = lshr i16 %1, 10
  %42 = trunc nuw nsw i16 %41 to i8
  %43 = and i8 %42, 31
  %44 = and i16 %1, 1023
  %45 = icmp slt i16 %2, 0
  %46 = lshr i16 %2, 15
  %47 = trunc nuw nsw i16 %46 to i8
  %48 = lshr i16 %2, 10
  %49 = trunc nuw nsw i16 %48 to i8
  %50 = and i8 %49, 31
  %51 = and i16 %2, 1023
  %52 = xor i16 %1, %0
  %53 = icmp slt i16 %52, 0
  %54 = lshr i16 %52, 15
  %55 = trunc nuw nsw i16 %54 to i8
  %56 = icmp eq i8 %39, 31
  br i1 %56, label %57, label %63

57:                                               ; preds = %36
  %58 = icmp eq i16 %40, 0
  br i1 %58, label %59, label %313

59:                                               ; preds = %57
  %60 = icmp eq i8 %43, 31
  %61 = icmp ne i16 %44, 0
  %62 = and i1 %61, %60
  br i1 %62, label %313, label %325

63:                                               ; preds = %36
  %64 = icmp eq i8 %43, 31
  br i1 %64, label %65, label %67

65:                                               ; preds = %63
  %66 = icmp eq i16 %44, 0
  br i1 %66, label %325, label %313

67:                                               ; preds = %63
  %68 = icmp eq i8 %50, 31
  br i1 %68, label %69, label %71

69:                                               ; preds = %67
  %70 = icmp eq i16 %51, 0
  br i1 %70, label %363, label %338

71:                                               ; preds = %67
  %72 = icmp eq i8 %39, 0
  br i1 %72, label %73, label %84

73:                                               ; preds = %71
  %74 = icmp eq i16 %40, 0
  br i1 %74, label %356, label %75

75:                                               ; preds = %73
  %76 = zext nneg i16 %40 to i32
  %77 = tail call range(i32 16, 33) i32 @llvm.ctlz.i32(i32 %76, i1 true)
  %78 = add nuw nsw i32 %77, 235
  %79 = and i32 %78, 255
  %80 = shl nuw nsw i32 %76, %79
  %81 = trunc nuw nsw i32 %77 to i8
  %82 = sub nsw i8 22, %81
  %83 = trunc i32 %80 to i16
  br label %84

84:                                               ; preds = %75, %71
  %85 = phi i16 [ %40, %71 ], [ %83, %75 ]
  %86 = phi i8 [ %39, %71 ], [ %82, %75 ]
  %87 = icmp eq i8 %43, 0
  br i1 %87, label %88, label %99

88:                                               ; preds = %84
  %89 = icmp eq i16 %44, 0
  br i1 %89, label %356, label %90

90:                                               ; preds = %88
  %91 = zext nneg i16 %44 to i32
  %92 = tail call range(i32 16, 33) i32 @llvm.ctlz.i32(i32 %91, i1 true)
  %93 = add nuw nsw i32 %92, 235
  %94 = and i32 %93, 255
  %95 = shl nuw nsw i32 %91, %94
  %96 = trunc nuw nsw i32 %92 to i8
  %97 = sub nsw i8 22, %96
  %98 = trunc i32 %95 to i16
  br label %99

99:                                               ; preds = %90, %84
  %100 = phi i16 [ %44, %84 ], [ %98, %90 ]
  %101 = phi i8 [ %43, %84 ], [ %97, %90 ]
  %102 = add nsw i8 %101, %86
  %103 = shl i16 %85, 4
  %104 = or i16 %103, 16384
  %105 = shl i16 %100, 4
  %106 = or i16 %105, 16384
  %107 = zext i16 %104 to i32
  %108 = zext i16 %106 to i32
  %109 = mul nuw i32 %108, %107
  %110 = icmp ult i32 %109, 536870912
  %111 = select i1 %110, i8 -15, i8 -14
  %112 = add nsw i8 %102, %111
  %113 = zext i1 %110 to i32
  %114 = shl nuw nsw i32 %109, %113
  %115 = icmp eq i8 %50, 0
  br i1 %115, label %116, label %135

116:                                              ; preds = %99
  %117 = icmp eq i16 %51, 0
  br i1 %117, label %118, label %126

118:                                              ; preds = %116
  %119 = add nsw i8 %112, -1
  %120 = lshr i32 %114, 15
  %121 = and i32 %114, 32512
  %122 = icmp ne i32 %121, 0
  %123 = zext i1 %122 to i32
  %124 = or i32 %120, %123
  %125 = trunc i32 %124 to i16
  br label %257

126:                                              ; preds = %116
  %127 = zext nneg i16 %51 to i32
  %128 = tail call range(i32 16, 33) i32 @llvm.ctlz.i32(i32 %127, i1 true)
  %129 = add nuw nsw i32 %128, 235
  %130 = and i32 %129, 255
  %131 = shl nuw nsw i32 %127, %130
  %132 = trunc nuw nsw i32 %128 to i8
  %133 = sub nsw i8 22, %132
  %134 = trunc i32 %131 to i16
  br label %135

135:                                              ; preds = %126, %99
  %136 = phi i16 [ %51, %99 ], [ %134, %126 ]
  %137 = phi i8 [ %50, %99 ], [ %133, %126 ]
  %138 = shl i16 %136, 3
  %139 = or i16 %138, 8192
  %140 = sub nsw i8 %112, %137
  %141 = xor i1 %53, %45
  br i1 %141, label %190, label %142

142:                                              ; preds = %135
  %143 = icmp slt i8 %140, 1
  br i1 %143, label %144, label %161

144:                                              ; preds = %142
  %145 = sext i8 %140 to i16
  %146 = sub nsw i16 16, %145
  %147 = icmp ult i16 %146, 31
  br i1 %147, label %148, label %158

148:                                              ; preds = %144
  %149 = zext nneg i16 %146 to i32
  %150 = lshr i32 %114, %149
  %151 = sub nsw i32 0, %149
  %152 = and i32 %151, 31
  %153 = shl i32 %114, %152
  %154 = icmp ne i32 %153, 0
  %155 = zext i1 %154 to i32
  %156 = or i32 %150, %155
  %157 = trunc i32 %156 to i16
  br label %158

158:                                              ; preds = %148, %144
  %159 = phi i16 [ %157, %148 ], [ 1, %144 ]
  %160 = add i16 %159, %139
  br label %183

161:                                              ; preds = %142
  %162 = icmp ult i8 %140, 31
  br i1 %162, label %163, label %174

163:                                              ; preds = %161
  %164 = zext i16 %139 to i32
  %165 = shl nuw i32 %164, 16
  %166 = zext nneg i8 %140 to i32
  %167 = lshr i32 %165, %166
  %168 = sub nsw i32 0, %166
  %169 = and i32 %168, 31
  %170 = shl i32 %165, %169
  %171 = icmp ne i32 %170, 0
  %172 = zext i1 %171 to i32
  %173 = or i32 %167, %172
  br label %174

174:                                              ; preds = %163, %161
  %175 = phi i32 [ %173, %163 ], [ 1, %161 ]
  %176 = add i32 %175, %114
  %177 = lshr i32 %176, 16
  %178 = and i32 %176, 65535
  %179 = icmp ne i32 %178, 0
  %180 = zext i1 %179 to i32
  %181 = or i32 %177, %180
  %182 = trunc nuw i32 %181 to i16
  br label %183

183:                                              ; preds = %174, %158
  %184 = phi i8 [ %137, %158 ], [ %112, %174 ]
  %185 = phi i16 [ %160, %158 ], [ %182, %174 ]
  %186 = icmp ult i16 %185, 16384
  br i1 %186, label %187, label %257

187:                                              ; preds = %183
  %188 = add nsw i8 %184, -1
  %189 = shl nuw nsw i16 %185, 1
  br label %257

190:                                              ; preds = %135
  %191 = zext i16 %139 to i32
  %192 = shl nuw i32 %191, 16
  %193 = icmp slt i8 %140, 0
  br i1 %193, label %194, label %210

194:                                              ; preds = %190
  %195 = sext i8 %140 to i16
  %196 = sub nsw i16 0, %195
  %197 = icmp ult i16 %196, 31
  br i1 %197, label %198, label %207

198:                                              ; preds = %194
  %199 = zext nneg i16 %196 to i32
  %200 = lshr i32 %114, %199
  %201 = sub nsw i32 0, %199
  %202 = and i32 %201, 31
  %203 = shl i32 %114, %202
  %204 = icmp ne i32 %203, 0
  %205 = zext i1 %204 to i32
  %206 = or i32 %200, %205
  br label %207

207:                                              ; preds = %198, %194
  %208 = phi i32 [ %206, %198 ], [ 1, %194 ]
  %209 = sub i32 %192, %208
  br label %235

210:                                              ; preds = %190
  %211 = icmp eq i8 %112, %137
  br i1 %211, label %212, label %221

212:                                              ; preds = %210
  %213 = sub i32 %114, %192
  %214 = icmp eq i32 %213, 0
  br i1 %214, label %362, label %215

215:                                              ; preds = %212
  %216 = icmp sgt i32 %213, -1
  br i1 %216, label %235, label %217

217:                                              ; preds = %215
  %218 = xor i1 %53, true
  %219 = zext i1 %218 to i8
  %220 = sub i32 0, %213
  br label %235

221:                                              ; preds = %210
  %222 = icmp ult i8 %140, 31
  br i1 %222, label %223, label %232

223:                                              ; preds = %221
  %224 = zext nneg i8 %140 to i32
  %225 = lshr i32 %192, %224
  %226 = sub nsw i32 0, %224
  %227 = and i32 %226, 31
  %228 = shl i32 %192, %227
  %229 = icmp ne i32 %228, 0
  %230 = zext i1 %229 to i32
  %231 = or i32 %225, %230
  br label %232

232:                                              ; preds = %223, %221
  %233 = phi i32 [ %231, %223 ], [ 1, %221 ]
  %234 = sub i32 %114, %233
  br label %235

235:                                              ; preds = %232, %217, %215, %207
  %236 = phi i8 [ %47, %207 ], [ %55, %232 ], [ %219, %217 ], [ %55, %215 ]
  %237 = phi i8 [ %137, %207 ], [ %112, %232 ], [ %112, %217 ], [ %112, %215 ]
  %238 = phi i32 [ %209, %207 ], [ %234, %232 ], [ %220, %217 ], [ %213, %215 ]
  %239 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %238, i1 false)
  %240 = trunc nuw nsw i32 %239 to i8
  %241 = add nsw i8 %237, 1
  %242 = sub nsw i8 %241, %240
  %243 = add nsw i32 %239, -17
  %244 = icmp ugt i32 %238, 32767
  br i1 %244, label %245, label %254

245:                                              ; preds = %235
  %246 = sub nsw i32 17, %239
  %247 = lshr i32 %238, %246
  %248 = and i32 %243, 31
  %249 = shl i32 %238, %248
  %250 = icmp ne i32 %249, 0
  %251 = zext i1 %250 to i32
  %252 = or i32 %247, %251
  %253 = trunc i32 %252 to i16
  br label %257

254:                                              ; preds = %235
  %255 = shl i32 %238, %243
  %256 = trunc i32 %255 to i16
  br label %257

257:                                              ; preds = %254, %245, %187, %183, %118
  %258 = phi i8 [ %55, %187 ], [ %55, %183 ], [ %236, %245 ], [ %236, %254 ], [ %55, %118 ]
  %259 = phi i8 [ %188, %187 ], [ %184, %183 ], [ %242, %245 ], [ %242, %254 ], [ %119, %118 ]
  %260 = phi i16 [ %189, %187 ], [ %185, %183 ], [ %253, %245 ], [ %256, %254 ], [ %125, %118 ]
  %261 = trunc nuw i8 %258 to i1
  %262 = sext i8 %259 to i16
  %263 = zext i16 %260 to i32
  %264 = trunc i16 %260 to i8
  %265 = icmp ugt i8 %259, 28
  br i1 %265, label %266, label %293

266:                                              ; preds = %257
  %267 = icmp slt i8 %259, 0
  br i1 %267, label %268, label %287

268:                                              ; preds = %266
  %269 = sub nsw i16 0, %262
  %270 = icmp ult i16 %269, 31
  br i1 %270, label %271, label %280

271:                                              ; preds = %268
  %272 = zext nneg i16 %269 to i32
  %273 = lshr i32 %263, %272
  %274 = sub nsw i32 0, %272
  %275 = and i32 %274, 31
  %276 = shl i32 %263, %275
  %277 = icmp ne i32 %276, 0
  %278 = zext i1 %277 to i32
  %279 = or i32 %273, %278
  br label %283

280:                                              ; preds = %268
  %281 = icmp ne i16 %260, 0
  %282 = zext i1 %281 to i32
  br label %283

283:                                              ; preds = %280, %271
  %284 = phi i32 [ %279, %271 ], [ %282, %280 ]
  %285 = trunc nuw i32 %284 to i16
  %286 = trunc i32 %284 to i8
  br label %293

287:                                              ; preds = %266
  %288 = icmp sgt i8 %259, 29
  %289 = icmp ugt i16 %260, 32759
  %290 = select i1 %288, i1 true, i1 %289
  br i1 %290, label %291, label %293

291:                                              ; preds = %287
  %292 = select i1 %261, i16 -1024, i16 31744
  br label %363

293:                                              ; preds = %287, %283, %257
  %294 = phi i8 [ %264, %257 ], [ %286, %283 ], [ %264, %287 ]
  %295 = phi i16 [ %260, %257 ], [ %285, %283 ], [ %260, %287 ]
  %296 = phi i16 [ %262, %257 ], [ 0, %283 ], [ %262, %287 ]
  %297 = and i8 %294, 15
  %298 = zext i16 %295 to i32
  %299 = add nuw nsw i32 %298, 8
  %300 = lshr i32 %299, 4
  %301 = icmp eq i8 %297, 8
  %302 = zext i1 %301 to i32
  %303 = xor i32 %302, -1
  %304 = and i32 %300, %303
  %305 = icmp eq i32 %304, 0
  %306 = zext i16 %296 to i32
  %307 = select i1 %261, i32 32768, i32 0
  %308 = shl nuw nsw i32 %306, 10
  %309 = select i1 %305, i32 0, i32 %308
  %310 = or disjoint i32 %304, %307
  %311 = add nuw nsw i32 %310, %309
  %312 = trunc i32 %311 to i16
  br label %363

313:                                              ; preds = %65, %59, %57
  %314 = and i32 %4, 32256
  %315 = icmp eq i32 %314, 31744
  %316 = and i32 %4, 511
  %317 = icmp ne i32 %316, 0
  %318 = and i1 %315, %317
  %319 = icmp ne i32 %5, 31744
  %320 = icmp eq i32 %7, 0
  %321 = or i1 %319, %320
  %322 = select i1 %321, i16 %1, i16 %0
  %323 = select i1 %318, i16 %0, i16 %322
  %324 = or i16 %323, 512
  br label %338

325:                                              ; preds = %65, %59
  %326 = phi i16 [ %41, %59 ], [ %37, %65 ]
  %327 = phi i16 [ %44, %59 ], [ %40, %65 ]
  %328 = and i16 %326, 31
  %329 = or i16 %328, %327
  %330 = icmp eq i16 %329, 0
  br i1 %330, label %338, label %331

331:                                              ; preds = %325
  %332 = select i1 %53, i16 -1024, i16 31744
  %333 = icmp eq i8 %50, 31
  br i1 %333, label %334, label %363

334:                                              ; preds = %331
  %335 = icmp eq i16 %51, 0
  br i1 %335, label %336, label %338

336:                                              ; preds = %334
  %337 = xor i1 %53, %45
  br i1 %337, label %338, label %363

338:                                              ; preds = %336, %334, %325, %313, %69
  %339 = phi i16 [ %324, %313 ], [ %332, %334 ], [ 0, %69 ], [ -512, %336 ], [ -512, %325 ]
  %340 = zext i16 %339 to i32
  %341 = and i32 %340, 32256
  %342 = icmp eq i32 %341, 31744
  %343 = and i32 %340, 511
  %344 = icmp ne i32 %343, 0
  %345 = and i1 %342, %344
  br i1 %345, label %353, label %346

346:                                              ; preds = %338
  %347 = and i32 %340, 31744
  %348 = icmp ne i32 %347, 31744
  %349 = and i32 %340, 1023
  %350 = icmp eq i32 %349, 0
  %351 = or i1 %348, %350
  %352 = select i1 %351, i16 %2, i16 %339
  br label %353

353:                                              ; preds = %346, %338
  %354 = phi i16 [ %352, %346 ], [ %339, %338 ]
  %355 = or i16 %354, 512
  br label %363

356:                                              ; preds = %88, %73
  %357 = and i16 %48, 31
  %358 = or i16 %357, %51
  %359 = icmp eq i16 %358, 0
  %360 = xor i1 %53, %45
  %361 = and i1 %360, %359
  br i1 %361, label %362, label %363

362:                                              ; preds = %356, %212
  br label %363

363:                                              ; preds = %362, %356, %353, %336, %331, %293, %291, %69, %33
  %364 = phi i16 [ %35, %33 ], [ %355, %353 ], [ %332, %331 ], [ %332, %336 ], [ 0, %362 ], [ %2, %356 ], [ %2, %69 ], [ %312, %293 ], [ %292, %291 ]
  ret i16 %364
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
