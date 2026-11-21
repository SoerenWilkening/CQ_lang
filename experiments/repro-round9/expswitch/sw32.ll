; ModuleID = 'sw32.c'
source_filename = "sw32.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.Op = type { i32, i32, i32 }

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i32 @interp(ptr noundef readonly %0, i32 noundef %1, ptr noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %600

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %7

7:                                                ; preds = %594, %5
  %8 = phi i64 [ 0, %5 ], [ %597, %594 ]
  %9 = phi i32 [ 0, %5 ], [ %595, %594 ]
  %10 = getelementptr inbounds %struct.Op, ptr %0, i64 %8
  %11 = load i32, ptr %10, align 4, !tbaa !6
  switch i32 %11, label %594 [
    i32 0, label %12
    i32 1, label %34
    i32 2, label %52
    i32 3, label %70
    i32 4, label %88
    i32 5, label %106
    i32 6, label %124
    i32 7, label %142
    i32 8, label %160
    i32 9, label %178
    i32 10, label %196
    i32 11, label %214
    i32 12, label %232
    i32 13, label %250
    i32 14, label %268
    i32 15, label %286
    i32 16, label %304
    i32 17, label %322
    i32 18, label %340
    i32 19, label %358
    i32 20, label %376
    i32 21, label %394
    i32 22, label %412
    i32 23, label %430
    i32 24, label %448
    i32 25, label %466
    i32 26, label %484
    i32 27, label %502
    i32 28, label %520
    i32 29, label %538
    i32 30, label %556
    i32 31, label %574
  ]

12:                                               ; preds = %7
  %13 = getelementptr inbounds i8, ptr %10, i64 4
  %14 = load i32, ptr %13, align 4, !tbaa !11
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %2, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !12
  %18 = icmp sgt i32 %17, 0
  br i1 %18, label %19, label %27

19:                                               ; preds = %12
  %20 = mul nsw i32 %14, 3
  %21 = getelementptr inbounds i8, ptr %10, i64 8
  %22 = load i32, ptr %21, align 4, !tbaa !13
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds i32, ptr %2, i64 %23
  %25 = load i32, ptr %24, align 4, !tbaa !12
  %26 = add nsw i32 %25, %20
  store i32 %26, ptr %24, align 4, !tbaa !12
  br label %592

27:                                               ; preds = %12
  %28 = getelementptr inbounds i8, ptr %10, i64 8
  %29 = load i32, ptr %28, align 4, !tbaa !13
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds i32, ptr %2, i64 %30
  %32 = load i32, ptr %31, align 4, !tbaa !12
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %594, label %592

34:                                               ; preds = %7
  %35 = getelementptr inbounds i8, ptr %10, i64 4
  %36 = load i32, ptr %35, align 4, !tbaa !11
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds i32, ptr %2, i64 %37
  %39 = load i32, ptr %38, align 4, !tbaa !12
  %40 = icmp sgt i32 %39, 1
  %41 = getelementptr inbounds i8, ptr %10, i64 8
  %42 = load i32, ptr %41, align 4, !tbaa !13
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds i32, ptr %2, i64 %43
  %45 = load i32, ptr %44, align 4, !tbaa !12
  br i1 %40, label %46, label %49

46:                                               ; preds = %34
  %47 = shl nsw i32 %36, 2
  %48 = add nsw i32 %45, %47
  store i32 %48, ptr %44, align 4, !tbaa !12
  br label %592

49:                                               ; preds = %34
  %50 = xor i32 %9, 1
  %51 = icmp eq i32 %45, 1
  br i1 %51, label %594, label %592

52:                                               ; preds = %7
  %53 = getelementptr inbounds i8, ptr %10, i64 4
  %54 = load i32, ptr %53, align 4, !tbaa !11
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds i32, ptr %2, i64 %55
  %57 = load i32, ptr %56, align 4, !tbaa !12
  %58 = icmp sgt i32 %57, 2
  %59 = getelementptr inbounds i8, ptr %10, i64 8
  %60 = load i32, ptr %59, align 4, !tbaa !13
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds i32, ptr %2, i64 %61
  %63 = load i32, ptr %62, align 4, !tbaa !12
  br i1 %58, label %64, label %67

64:                                               ; preds = %52
  %65 = mul nsw i32 %54, 5
  %66 = add nsw i32 %63, %65
  store i32 %66, ptr %62, align 4, !tbaa !12
  br label %592

67:                                               ; preds = %52
  %68 = xor i32 %9, 2
  %69 = icmp eq i32 %63, 2
  br i1 %69, label %594, label %592

70:                                               ; preds = %7
  %71 = getelementptr inbounds i8, ptr %10, i64 4
  %72 = load i32, ptr %71, align 4, !tbaa !11
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds i32, ptr %2, i64 %73
  %75 = load i32, ptr %74, align 4, !tbaa !12
  %76 = icmp sgt i32 %75, 3
  %77 = getelementptr inbounds i8, ptr %10, i64 8
  %78 = load i32, ptr %77, align 4, !tbaa !13
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds i32, ptr %2, i64 %79
  %81 = load i32, ptr %80, align 4, !tbaa !12
  br i1 %76, label %82, label %85

82:                                               ; preds = %70
  %83 = mul nsw i32 %72, 6
  %84 = add nsw i32 %81, %83
  store i32 %84, ptr %80, align 4, !tbaa !12
  br label %592

85:                                               ; preds = %70
  %86 = xor i32 %9, 3
  %87 = icmp eq i32 %81, 3
  br i1 %87, label %594, label %592

88:                                               ; preds = %7
  %89 = getelementptr inbounds i8, ptr %10, i64 4
  %90 = load i32, ptr %89, align 4, !tbaa !11
  %91 = sext i32 %90 to i64
  %92 = getelementptr inbounds i32, ptr %2, i64 %91
  %93 = load i32, ptr %92, align 4, !tbaa !12
  %94 = icmp sgt i32 %93, 4
  %95 = getelementptr inbounds i8, ptr %10, i64 8
  %96 = load i32, ptr %95, align 4, !tbaa !13
  %97 = sext i32 %96 to i64
  %98 = getelementptr inbounds i32, ptr %2, i64 %97
  %99 = load i32, ptr %98, align 4, !tbaa !12
  br i1 %94, label %100, label %103

100:                                              ; preds = %88
  %101 = mul nsw i32 %90, 7
  %102 = add nsw i32 %99, %101
  store i32 %102, ptr %98, align 4, !tbaa !12
  br label %592

103:                                              ; preds = %88
  %104 = xor i32 %9, 4
  %105 = icmp eq i32 %99, 4
  br i1 %105, label %594, label %592

106:                                              ; preds = %7
  %107 = getelementptr inbounds i8, ptr %10, i64 4
  %108 = load i32, ptr %107, align 4, !tbaa !11
  %109 = sext i32 %108 to i64
  %110 = getelementptr inbounds i32, ptr %2, i64 %109
  %111 = load i32, ptr %110, align 4, !tbaa !12
  %112 = icmp sgt i32 %111, 5
  %113 = getelementptr inbounds i8, ptr %10, i64 8
  %114 = load i32, ptr %113, align 4, !tbaa !13
  %115 = sext i32 %114 to i64
  %116 = getelementptr inbounds i32, ptr %2, i64 %115
  %117 = load i32, ptr %116, align 4, !tbaa !12
  br i1 %112, label %118, label %121

118:                                              ; preds = %106
  %119 = shl nsw i32 %108, 3
  %120 = add nsw i32 %117, %119
  store i32 %120, ptr %116, align 4, !tbaa !12
  br label %592

121:                                              ; preds = %106
  %122 = xor i32 %9, 5
  %123 = icmp eq i32 %117, 5
  br i1 %123, label %594, label %592

124:                                              ; preds = %7
  %125 = getelementptr inbounds i8, ptr %10, i64 4
  %126 = load i32, ptr %125, align 4, !tbaa !11
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds i32, ptr %2, i64 %127
  %129 = load i32, ptr %128, align 4, !tbaa !12
  %130 = icmp sgt i32 %129, 6
  %131 = getelementptr inbounds i8, ptr %10, i64 8
  %132 = load i32, ptr %131, align 4, !tbaa !13
  %133 = sext i32 %132 to i64
  %134 = getelementptr inbounds i32, ptr %2, i64 %133
  %135 = load i32, ptr %134, align 4, !tbaa !12
  br i1 %130, label %136, label %139

136:                                              ; preds = %124
  %137 = mul nsw i32 %126, 9
  %138 = add nsw i32 %135, %137
  store i32 %138, ptr %134, align 4, !tbaa !12
  br label %592

139:                                              ; preds = %124
  %140 = xor i32 %9, 6
  %141 = icmp eq i32 %135, 6
  br i1 %141, label %594, label %592

142:                                              ; preds = %7
  %143 = getelementptr inbounds i8, ptr %10, i64 4
  %144 = load i32, ptr %143, align 4, !tbaa !11
  %145 = sext i32 %144 to i64
  %146 = getelementptr inbounds i32, ptr %2, i64 %145
  %147 = load i32, ptr %146, align 4, !tbaa !12
  %148 = icmp sgt i32 %147, 7
  %149 = getelementptr inbounds i8, ptr %10, i64 8
  %150 = load i32, ptr %149, align 4, !tbaa !13
  %151 = sext i32 %150 to i64
  %152 = getelementptr inbounds i32, ptr %2, i64 %151
  %153 = load i32, ptr %152, align 4, !tbaa !12
  br i1 %148, label %154, label %157

154:                                              ; preds = %142
  %155 = mul nsw i32 %144, 10
  %156 = add nsw i32 %153, %155
  store i32 %156, ptr %152, align 4, !tbaa !12
  br label %592

157:                                              ; preds = %142
  %158 = xor i32 %9, 7
  %159 = icmp eq i32 %153, 7
  br i1 %159, label %594, label %592

160:                                              ; preds = %7
  %161 = getelementptr inbounds i8, ptr %10, i64 4
  %162 = load i32, ptr %161, align 4, !tbaa !11
  %163 = sext i32 %162 to i64
  %164 = getelementptr inbounds i32, ptr %2, i64 %163
  %165 = load i32, ptr %164, align 4, !tbaa !12
  %166 = icmp sgt i32 %165, 8
  %167 = getelementptr inbounds i8, ptr %10, i64 8
  %168 = load i32, ptr %167, align 4, !tbaa !13
  %169 = sext i32 %168 to i64
  %170 = getelementptr inbounds i32, ptr %2, i64 %169
  %171 = load i32, ptr %170, align 4, !tbaa !12
  br i1 %166, label %172, label %175

172:                                              ; preds = %160
  %173 = mul nsw i32 %162, 11
  %174 = add nsw i32 %171, %173
  store i32 %174, ptr %170, align 4, !tbaa !12
  br label %592

175:                                              ; preds = %160
  %176 = xor i32 %9, 8
  %177 = icmp eq i32 %171, 8
  br i1 %177, label %594, label %592

178:                                              ; preds = %7
  %179 = getelementptr inbounds i8, ptr %10, i64 4
  %180 = load i32, ptr %179, align 4, !tbaa !11
  %181 = sext i32 %180 to i64
  %182 = getelementptr inbounds i32, ptr %2, i64 %181
  %183 = load i32, ptr %182, align 4, !tbaa !12
  %184 = icmp sgt i32 %183, 9
  %185 = getelementptr inbounds i8, ptr %10, i64 8
  %186 = load i32, ptr %185, align 4, !tbaa !13
  %187 = sext i32 %186 to i64
  %188 = getelementptr inbounds i32, ptr %2, i64 %187
  %189 = load i32, ptr %188, align 4, !tbaa !12
  br i1 %184, label %190, label %193

190:                                              ; preds = %178
  %191 = mul nsw i32 %180, 12
  %192 = add nsw i32 %189, %191
  store i32 %192, ptr %188, align 4, !tbaa !12
  br label %592

193:                                              ; preds = %178
  %194 = xor i32 %9, 9
  %195 = icmp eq i32 %189, 9
  br i1 %195, label %594, label %592

196:                                              ; preds = %7
  %197 = getelementptr inbounds i8, ptr %10, i64 4
  %198 = load i32, ptr %197, align 4, !tbaa !11
  %199 = sext i32 %198 to i64
  %200 = getelementptr inbounds i32, ptr %2, i64 %199
  %201 = load i32, ptr %200, align 4, !tbaa !12
  %202 = icmp sgt i32 %201, 10
  %203 = getelementptr inbounds i8, ptr %10, i64 8
  %204 = load i32, ptr %203, align 4, !tbaa !13
  %205 = sext i32 %204 to i64
  %206 = getelementptr inbounds i32, ptr %2, i64 %205
  %207 = load i32, ptr %206, align 4, !tbaa !12
  br i1 %202, label %208, label %211

208:                                              ; preds = %196
  %209 = mul nsw i32 %198, 13
  %210 = add nsw i32 %207, %209
  store i32 %210, ptr %206, align 4, !tbaa !12
  br label %592

211:                                              ; preds = %196
  %212 = xor i32 %9, 10
  %213 = icmp eq i32 %207, 10
  br i1 %213, label %594, label %592

214:                                              ; preds = %7
  %215 = getelementptr inbounds i8, ptr %10, i64 4
  %216 = load i32, ptr %215, align 4, !tbaa !11
  %217 = sext i32 %216 to i64
  %218 = getelementptr inbounds i32, ptr %2, i64 %217
  %219 = load i32, ptr %218, align 4, !tbaa !12
  %220 = icmp sgt i32 %219, 11
  %221 = getelementptr inbounds i8, ptr %10, i64 8
  %222 = load i32, ptr %221, align 4, !tbaa !13
  %223 = sext i32 %222 to i64
  %224 = getelementptr inbounds i32, ptr %2, i64 %223
  %225 = load i32, ptr %224, align 4, !tbaa !12
  br i1 %220, label %226, label %229

226:                                              ; preds = %214
  %227 = mul nsw i32 %216, 14
  %228 = add nsw i32 %225, %227
  store i32 %228, ptr %224, align 4, !tbaa !12
  br label %592

229:                                              ; preds = %214
  %230 = xor i32 %9, 11
  %231 = icmp eq i32 %225, 11
  br i1 %231, label %594, label %592

232:                                              ; preds = %7
  %233 = getelementptr inbounds i8, ptr %10, i64 4
  %234 = load i32, ptr %233, align 4, !tbaa !11
  %235 = sext i32 %234 to i64
  %236 = getelementptr inbounds i32, ptr %2, i64 %235
  %237 = load i32, ptr %236, align 4, !tbaa !12
  %238 = icmp sgt i32 %237, 12
  %239 = getelementptr inbounds i8, ptr %10, i64 8
  %240 = load i32, ptr %239, align 4, !tbaa !13
  %241 = sext i32 %240 to i64
  %242 = getelementptr inbounds i32, ptr %2, i64 %241
  %243 = load i32, ptr %242, align 4, !tbaa !12
  br i1 %238, label %244, label %247

244:                                              ; preds = %232
  %245 = mul nsw i32 %234, 15
  %246 = add nsw i32 %243, %245
  store i32 %246, ptr %242, align 4, !tbaa !12
  br label %592

247:                                              ; preds = %232
  %248 = xor i32 %9, 12
  %249 = icmp eq i32 %243, 12
  br i1 %249, label %594, label %592

250:                                              ; preds = %7
  %251 = getelementptr inbounds i8, ptr %10, i64 4
  %252 = load i32, ptr %251, align 4, !tbaa !11
  %253 = sext i32 %252 to i64
  %254 = getelementptr inbounds i32, ptr %2, i64 %253
  %255 = load i32, ptr %254, align 4, !tbaa !12
  %256 = icmp sgt i32 %255, 13
  %257 = getelementptr inbounds i8, ptr %10, i64 8
  %258 = load i32, ptr %257, align 4, !tbaa !13
  %259 = sext i32 %258 to i64
  %260 = getelementptr inbounds i32, ptr %2, i64 %259
  %261 = load i32, ptr %260, align 4, !tbaa !12
  br i1 %256, label %262, label %265

262:                                              ; preds = %250
  %263 = shl nsw i32 %252, 4
  %264 = add nsw i32 %261, %263
  store i32 %264, ptr %260, align 4, !tbaa !12
  br label %592

265:                                              ; preds = %250
  %266 = xor i32 %9, 13
  %267 = icmp eq i32 %261, 13
  br i1 %267, label %594, label %592

268:                                              ; preds = %7
  %269 = getelementptr inbounds i8, ptr %10, i64 4
  %270 = load i32, ptr %269, align 4, !tbaa !11
  %271 = sext i32 %270 to i64
  %272 = getelementptr inbounds i32, ptr %2, i64 %271
  %273 = load i32, ptr %272, align 4, !tbaa !12
  %274 = icmp sgt i32 %273, 14
  %275 = getelementptr inbounds i8, ptr %10, i64 8
  %276 = load i32, ptr %275, align 4, !tbaa !13
  %277 = sext i32 %276 to i64
  %278 = getelementptr inbounds i32, ptr %2, i64 %277
  %279 = load i32, ptr %278, align 4, !tbaa !12
  br i1 %274, label %280, label %283

280:                                              ; preds = %268
  %281 = mul nsw i32 %270, 17
  %282 = add nsw i32 %279, %281
  store i32 %282, ptr %278, align 4, !tbaa !12
  br label %592

283:                                              ; preds = %268
  %284 = xor i32 %9, 14
  %285 = icmp eq i32 %279, 14
  br i1 %285, label %594, label %592

286:                                              ; preds = %7
  %287 = getelementptr inbounds i8, ptr %10, i64 4
  %288 = load i32, ptr %287, align 4, !tbaa !11
  %289 = sext i32 %288 to i64
  %290 = getelementptr inbounds i32, ptr %2, i64 %289
  %291 = load i32, ptr %290, align 4, !tbaa !12
  %292 = icmp sgt i32 %291, 15
  %293 = getelementptr inbounds i8, ptr %10, i64 8
  %294 = load i32, ptr %293, align 4, !tbaa !13
  %295 = sext i32 %294 to i64
  %296 = getelementptr inbounds i32, ptr %2, i64 %295
  %297 = load i32, ptr %296, align 4, !tbaa !12
  br i1 %292, label %298, label %301

298:                                              ; preds = %286
  %299 = mul nsw i32 %288, 18
  %300 = add nsw i32 %297, %299
  store i32 %300, ptr %296, align 4, !tbaa !12
  br label %592

301:                                              ; preds = %286
  %302 = xor i32 %9, 15
  %303 = icmp eq i32 %297, 15
  br i1 %303, label %594, label %592

304:                                              ; preds = %7
  %305 = getelementptr inbounds i8, ptr %10, i64 4
  %306 = load i32, ptr %305, align 4, !tbaa !11
  %307 = sext i32 %306 to i64
  %308 = getelementptr inbounds i32, ptr %2, i64 %307
  %309 = load i32, ptr %308, align 4, !tbaa !12
  %310 = icmp sgt i32 %309, 16
  %311 = getelementptr inbounds i8, ptr %10, i64 8
  %312 = load i32, ptr %311, align 4, !tbaa !13
  %313 = sext i32 %312 to i64
  %314 = getelementptr inbounds i32, ptr %2, i64 %313
  %315 = load i32, ptr %314, align 4, !tbaa !12
  br i1 %310, label %316, label %319

316:                                              ; preds = %304
  %317 = mul nsw i32 %306, 19
  %318 = add nsw i32 %315, %317
  store i32 %318, ptr %314, align 4, !tbaa !12
  br label %592

319:                                              ; preds = %304
  %320 = xor i32 %9, 16
  %321 = icmp eq i32 %315, 16
  br i1 %321, label %594, label %592

322:                                              ; preds = %7
  %323 = getelementptr inbounds i8, ptr %10, i64 4
  %324 = load i32, ptr %323, align 4, !tbaa !11
  %325 = sext i32 %324 to i64
  %326 = getelementptr inbounds i32, ptr %2, i64 %325
  %327 = load i32, ptr %326, align 4, !tbaa !12
  %328 = icmp sgt i32 %327, 17
  %329 = getelementptr inbounds i8, ptr %10, i64 8
  %330 = load i32, ptr %329, align 4, !tbaa !13
  %331 = sext i32 %330 to i64
  %332 = getelementptr inbounds i32, ptr %2, i64 %331
  %333 = load i32, ptr %332, align 4, !tbaa !12
  br i1 %328, label %334, label %337

334:                                              ; preds = %322
  %335 = mul nsw i32 %324, 20
  %336 = add nsw i32 %333, %335
  store i32 %336, ptr %332, align 4, !tbaa !12
  br label %592

337:                                              ; preds = %322
  %338 = xor i32 %9, 17
  %339 = icmp eq i32 %333, 17
  br i1 %339, label %594, label %592

340:                                              ; preds = %7
  %341 = getelementptr inbounds i8, ptr %10, i64 4
  %342 = load i32, ptr %341, align 4, !tbaa !11
  %343 = sext i32 %342 to i64
  %344 = getelementptr inbounds i32, ptr %2, i64 %343
  %345 = load i32, ptr %344, align 4, !tbaa !12
  %346 = icmp sgt i32 %345, 18
  %347 = getelementptr inbounds i8, ptr %10, i64 8
  %348 = load i32, ptr %347, align 4, !tbaa !13
  %349 = sext i32 %348 to i64
  %350 = getelementptr inbounds i32, ptr %2, i64 %349
  %351 = load i32, ptr %350, align 4, !tbaa !12
  br i1 %346, label %352, label %355

352:                                              ; preds = %340
  %353 = mul nsw i32 %342, 21
  %354 = add nsw i32 %351, %353
  store i32 %354, ptr %350, align 4, !tbaa !12
  br label %592

355:                                              ; preds = %340
  %356 = xor i32 %9, 18
  %357 = icmp eq i32 %351, 18
  br i1 %357, label %594, label %592

358:                                              ; preds = %7
  %359 = getelementptr inbounds i8, ptr %10, i64 4
  %360 = load i32, ptr %359, align 4, !tbaa !11
  %361 = sext i32 %360 to i64
  %362 = getelementptr inbounds i32, ptr %2, i64 %361
  %363 = load i32, ptr %362, align 4, !tbaa !12
  %364 = icmp sgt i32 %363, 19
  %365 = getelementptr inbounds i8, ptr %10, i64 8
  %366 = load i32, ptr %365, align 4, !tbaa !13
  %367 = sext i32 %366 to i64
  %368 = getelementptr inbounds i32, ptr %2, i64 %367
  %369 = load i32, ptr %368, align 4, !tbaa !12
  br i1 %364, label %370, label %373

370:                                              ; preds = %358
  %371 = mul nsw i32 %360, 22
  %372 = add nsw i32 %369, %371
  store i32 %372, ptr %368, align 4, !tbaa !12
  br label %592

373:                                              ; preds = %358
  %374 = xor i32 %9, 19
  %375 = icmp eq i32 %369, 19
  br i1 %375, label %594, label %592

376:                                              ; preds = %7
  %377 = getelementptr inbounds i8, ptr %10, i64 4
  %378 = load i32, ptr %377, align 4, !tbaa !11
  %379 = sext i32 %378 to i64
  %380 = getelementptr inbounds i32, ptr %2, i64 %379
  %381 = load i32, ptr %380, align 4, !tbaa !12
  %382 = icmp sgt i32 %381, 20
  %383 = getelementptr inbounds i8, ptr %10, i64 8
  %384 = load i32, ptr %383, align 4, !tbaa !13
  %385 = sext i32 %384 to i64
  %386 = getelementptr inbounds i32, ptr %2, i64 %385
  %387 = load i32, ptr %386, align 4, !tbaa !12
  br i1 %382, label %388, label %391

388:                                              ; preds = %376
  %389 = mul nsw i32 %378, 23
  %390 = add nsw i32 %387, %389
  store i32 %390, ptr %386, align 4, !tbaa !12
  br label %592

391:                                              ; preds = %376
  %392 = xor i32 %9, 20
  %393 = icmp eq i32 %387, 20
  br i1 %393, label %594, label %592

394:                                              ; preds = %7
  %395 = getelementptr inbounds i8, ptr %10, i64 4
  %396 = load i32, ptr %395, align 4, !tbaa !11
  %397 = sext i32 %396 to i64
  %398 = getelementptr inbounds i32, ptr %2, i64 %397
  %399 = load i32, ptr %398, align 4, !tbaa !12
  %400 = icmp sgt i32 %399, 21
  %401 = getelementptr inbounds i8, ptr %10, i64 8
  %402 = load i32, ptr %401, align 4, !tbaa !13
  %403 = sext i32 %402 to i64
  %404 = getelementptr inbounds i32, ptr %2, i64 %403
  %405 = load i32, ptr %404, align 4, !tbaa !12
  br i1 %400, label %406, label %409

406:                                              ; preds = %394
  %407 = mul nsw i32 %396, 24
  %408 = add nsw i32 %405, %407
  store i32 %408, ptr %404, align 4, !tbaa !12
  br label %592

409:                                              ; preds = %394
  %410 = xor i32 %9, 21
  %411 = icmp eq i32 %405, 21
  br i1 %411, label %594, label %592

412:                                              ; preds = %7
  %413 = getelementptr inbounds i8, ptr %10, i64 4
  %414 = load i32, ptr %413, align 4, !tbaa !11
  %415 = sext i32 %414 to i64
  %416 = getelementptr inbounds i32, ptr %2, i64 %415
  %417 = load i32, ptr %416, align 4, !tbaa !12
  %418 = icmp sgt i32 %417, 22
  %419 = getelementptr inbounds i8, ptr %10, i64 8
  %420 = load i32, ptr %419, align 4, !tbaa !13
  %421 = sext i32 %420 to i64
  %422 = getelementptr inbounds i32, ptr %2, i64 %421
  %423 = load i32, ptr %422, align 4, !tbaa !12
  br i1 %418, label %424, label %427

424:                                              ; preds = %412
  %425 = mul nsw i32 %414, 25
  %426 = add nsw i32 %423, %425
  store i32 %426, ptr %422, align 4, !tbaa !12
  br label %592

427:                                              ; preds = %412
  %428 = xor i32 %9, 22
  %429 = icmp eq i32 %423, 22
  br i1 %429, label %594, label %592

430:                                              ; preds = %7
  %431 = getelementptr inbounds i8, ptr %10, i64 4
  %432 = load i32, ptr %431, align 4, !tbaa !11
  %433 = sext i32 %432 to i64
  %434 = getelementptr inbounds i32, ptr %2, i64 %433
  %435 = load i32, ptr %434, align 4, !tbaa !12
  %436 = icmp sgt i32 %435, 23
  %437 = getelementptr inbounds i8, ptr %10, i64 8
  %438 = load i32, ptr %437, align 4, !tbaa !13
  %439 = sext i32 %438 to i64
  %440 = getelementptr inbounds i32, ptr %2, i64 %439
  %441 = load i32, ptr %440, align 4, !tbaa !12
  br i1 %436, label %442, label %445

442:                                              ; preds = %430
  %443 = mul nsw i32 %432, 26
  %444 = add nsw i32 %441, %443
  store i32 %444, ptr %440, align 4, !tbaa !12
  br label %592

445:                                              ; preds = %430
  %446 = xor i32 %9, 23
  %447 = icmp eq i32 %441, 23
  br i1 %447, label %594, label %592

448:                                              ; preds = %7
  %449 = getelementptr inbounds i8, ptr %10, i64 4
  %450 = load i32, ptr %449, align 4, !tbaa !11
  %451 = sext i32 %450 to i64
  %452 = getelementptr inbounds i32, ptr %2, i64 %451
  %453 = load i32, ptr %452, align 4, !tbaa !12
  %454 = icmp sgt i32 %453, 24
  %455 = getelementptr inbounds i8, ptr %10, i64 8
  %456 = load i32, ptr %455, align 4, !tbaa !13
  %457 = sext i32 %456 to i64
  %458 = getelementptr inbounds i32, ptr %2, i64 %457
  %459 = load i32, ptr %458, align 4, !tbaa !12
  br i1 %454, label %460, label %463

460:                                              ; preds = %448
  %461 = mul nsw i32 %450, 27
  %462 = add nsw i32 %459, %461
  store i32 %462, ptr %458, align 4, !tbaa !12
  br label %592

463:                                              ; preds = %448
  %464 = xor i32 %9, 24
  %465 = icmp eq i32 %459, 24
  br i1 %465, label %594, label %592

466:                                              ; preds = %7
  %467 = getelementptr inbounds i8, ptr %10, i64 4
  %468 = load i32, ptr %467, align 4, !tbaa !11
  %469 = sext i32 %468 to i64
  %470 = getelementptr inbounds i32, ptr %2, i64 %469
  %471 = load i32, ptr %470, align 4, !tbaa !12
  %472 = icmp sgt i32 %471, 25
  %473 = getelementptr inbounds i8, ptr %10, i64 8
  %474 = load i32, ptr %473, align 4, !tbaa !13
  %475 = sext i32 %474 to i64
  %476 = getelementptr inbounds i32, ptr %2, i64 %475
  %477 = load i32, ptr %476, align 4, !tbaa !12
  br i1 %472, label %478, label %481

478:                                              ; preds = %466
  %479 = mul nsw i32 %468, 28
  %480 = add nsw i32 %477, %479
  store i32 %480, ptr %476, align 4, !tbaa !12
  br label %592

481:                                              ; preds = %466
  %482 = xor i32 %9, 25
  %483 = icmp eq i32 %477, 25
  br i1 %483, label %594, label %592

484:                                              ; preds = %7
  %485 = getelementptr inbounds i8, ptr %10, i64 4
  %486 = load i32, ptr %485, align 4, !tbaa !11
  %487 = sext i32 %486 to i64
  %488 = getelementptr inbounds i32, ptr %2, i64 %487
  %489 = load i32, ptr %488, align 4, !tbaa !12
  %490 = icmp sgt i32 %489, 26
  %491 = getelementptr inbounds i8, ptr %10, i64 8
  %492 = load i32, ptr %491, align 4, !tbaa !13
  %493 = sext i32 %492 to i64
  %494 = getelementptr inbounds i32, ptr %2, i64 %493
  %495 = load i32, ptr %494, align 4, !tbaa !12
  br i1 %490, label %496, label %499

496:                                              ; preds = %484
  %497 = mul nsw i32 %486, 29
  %498 = add nsw i32 %495, %497
  store i32 %498, ptr %494, align 4, !tbaa !12
  br label %592

499:                                              ; preds = %484
  %500 = xor i32 %9, 26
  %501 = icmp eq i32 %495, 26
  br i1 %501, label %594, label %592

502:                                              ; preds = %7
  %503 = getelementptr inbounds i8, ptr %10, i64 4
  %504 = load i32, ptr %503, align 4, !tbaa !11
  %505 = sext i32 %504 to i64
  %506 = getelementptr inbounds i32, ptr %2, i64 %505
  %507 = load i32, ptr %506, align 4, !tbaa !12
  %508 = icmp sgt i32 %507, 27
  %509 = getelementptr inbounds i8, ptr %10, i64 8
  %510 = load i32, ptr %509, align 4, !tbaa !13
  %511 = sext i32 %510 to i64
  %512 = getelementptr inbounds i32, ptr %2, i64 %511
  %513 = load i32, ptr %512, align 4, !tbaa !12
  br i1 %508, label %514, label %517

514:                                              ; preds = %502
  %515 = mul nsw i32 %504, 30
  %516 = add nsw i32 %513, %515
  store i32 %516, ptr %512, align 4, !tbaa !12
  br label %592

517:                                              ; preds = %502
  %518 = xor i32 %9, 27
  %519 = icmp eq i32 %513, 27
  br i1 %519, label %594, label %592

520:                                              ; preds = %7
  %521 = getelementptr inbounds i8, ptr %10, i64 4
  %522 = load i32, ptr %521, align 4, !tbaa !11
  %523 = sext i32 %522 to i64
  %524 = getelementptr inbounds i32, ptr %2, i64 %523
  %525 = load i32, ptr %524, align 4, !tbaa !12
  %526 = icmp sgt i32 %525, 28
  %527 = getelementptr inbounds i8, ptr %10, i64 8
  %528 = load i32, ptr %527, align 4, !tbaa !13
  %529 = sext i32 %528 to i64
  %530 = getelementptr inbounds i32, ptr %2, i64 %529
  %531 = load i32, ptr %530, align 4, !tbaa !12
  br i1 %526, label %532, label %535

532:                                              ; preds = %520
  %533 = mul nsw i32 %522, 31
  %534 = add nsw i32 %531, %533
  store i32 %534, ptr %530, align 4, !tbaa !12
  br label %592

535:                                              ; preds = %520
  %536 = xor i32 %9, 28
  %537 = icmp eq i32 %531, 28
  br i1 %537, label %594, label %592

538:                                              ; preds = %7
  %539 = getelementptr inbounds i8, ptr %10, i64 4
  %540 = load i32, ptr %539, align 4, !tbaa !11
  %541 = sext i32 %540 to i64
  %542 = getelementptr inbounds i32, ptr %2, i64 %541
  %543 = load i32, ptr %542, align 4, !tbaa !12
  %544 = icmp sgt i32 %543, 29
  %545 = getelementptr inbounds i8, ptr %10, i64 8
  %546 = load i32, ptr %545, align 4, !tbaa !13
  %547 = sext i32 %546 to i64
  %548 = getelementptr inbounds i32, ptr %2, i64 %547
  %549 = load i32, ptr %548, align 4, !tbaa !12
  br i1 %544, label %550, label %553

550:                                              ; preds = %538
  %551 = shl nsw i32 %540, 5
  %552 = add nsw i32 %549, %551
  store i32 %552, ptr %548, align 4, !tbaa !12
  br label %592

553:                                              ; preds = %538
  %554 = xor i32 %9, 29
  %555 = icmp eq i32 %549, 29
  br i1 %555, label %594, label %592

556:                                              ; preds = %7
  %557 = getelementptr inbounds i8, ptr %10, i64 4
  %558 = load i32, ptr %557, align 4, !tbaa !11
  %559 = sext i32 %558 to i64
  %560 = getelementptr inbounds i32, ptr %2, i64 %559
  %561 = load i32, ptr %560, align 4, !tbaa !12
  %562 = icmp sgt i32 %561, 30
  %563 = getelementptr inbounds i8, ptr %10, i64 8
  %564 = load i32, ptr %563, align 4, !tbaa !13
  %565 = sext i32 %564 to i64
  %566 = getelementptr inbounds i32, ptr %2, i64 %565
  %567 = load i32, ptr %566, align 4, !tbaa !12
  br i1 %562, label %568, label %571

568:                                              ; preds = %556
  %569 = mul nsw i32 %558, 33
  %570 = add nsw i32 %567, %569
  store i32 %570, ptr %566, align 4, !tbaa !12
  br label %592

571:                                              ; preds = %556
  %572 = xor i32 %9, 30
  %573 = icmp eq i32 %567, 30
  br i1 %573, label %594, label %592

574:                                              ; preds = %7
  %575 = getelementptr inbounds i8, ptr %10, i64 4
  %576 = load i32, ptr %575, align 4, !tbaa !11
  %577 = sext i32 %576 to i64
  %578 = getelementptr inbounds i32, ptr %2, i64 %577
  %579 = load i32, ptr %578, align 4, !tbaa !12
  %580 = icmp sgt i32 %579, 31
  %581 = getelementptr inbounds i8, ptr %10, i64 8
  %582 = load i32, ptr %581, align 4, !tbaa !13
  %583 = sext i32 %582 to i64
  %584 = getelementptr inbounds i32, ptr %2, i64 %583
  %585 = load i32, ptr %584, align 4, !tbaa !12
  br i1 %580, label %586, label %589

586:                                              ; preds = %574
  %587 = mul nsw i32 %576, 34
  %588 = add nsw i32 %585, %587
  store i32 %588, ptr %584, align 4, !tbaa !12
  br label %592

589:                                              ; preds = %574
  %590 = xor i32 %9, 31
  %591 = icmp eq i32 %585, 31
  br i1 %591, label %594, label %592

592:                                              ; preds = %586, %589, %568, %571, %550, %553, %532, %535, %514, %517, %496, %499, %478, %481, %460, %463, %442, %445, %424, %427, %406, %409, %388, %391, %370, %373, %352, %355, %334, %337, %316, %319, %298, %301, %280, %283, %262, %265, %244, %247, %226, %229, %208, %211, %190, %193, %172, %175, %154, %157, %136, %139, %118, %121, %100, %103, %82, %85, %64, %67, %46, %49, %19, %27
  %593 = phi i32 [ %9, %586 ], [ %590, %589 ], [ %9, %568 ], [ %572, %571 ], [ %9, %550 ], [ %554, %553 ], [ %9, %532 ], [ %536, %535 ], [ %9, %514 ], [ %518, %517 ], [ %9, %496 ], [ %500, %499 ], [ %9, %478 ], [ %482, %481 ], [ %9, %460 ], [ %464, %463 ], [ %9, %442 ], [ %446, %445 ], [ %9, %424 ], [ %428, %427 ], [ %9, %406 ], [ %410, %409 ], [ %9, %388 ], [ %392, %391 ], [ %9, %370 ], [ %374, %373 ], [ %9, %352 ], [ %356, %355 ], [ %9, %334 ], [ %338, %337 ], [ %9, %316 ], [ %320, %319 ], [ %9, %298 ], [ %302, %301 ], [ %9, %280 ], [ %284, %283 ], [ %9, %262 ], [ %266, %265 ], [ %9, %244 ], [ %248, %247 ], [ %9, %226 ], [ %230, %229 ], [ %9, %208 ], [ %212, %211 ], [ %9, %190 ], [ %194, %193 ], [ %9, %172 ], [ %176, %175 ], [ %9, %154 ], [ %158, %157 ], [ %9, %136 ], [ %140, %139 ], [ %9, %118 ], [ %122, %121 ], [ %9, %100 ], [ %104, %103 ], [ %9, %82 ], [ %86, %85 ], [ %9, %64 ], [ %68, %67 ], [ %9, %46 ], [ %50, %49 ], [ %9, %19 ], [ %9, %27 ]
  br label %594

594:                                              ; preds = %7, %589, %571, %553, %535, %517, %499, %481, %463, %445, %427, %409, %391, %373, %355, %337, %319, %301, %283, %265, %247, %229, %211, %193, %175, %157, %139, %121, %103, %85, %67, %49, %27, %592
  %595 = phi i32 [ %593, %592 ], [ %9, %27 ], [ %50, %49 ], [ %68, %67 ], [ %86, %85 ], [ %104, %103 ], [ %122, %121 ], [ %140, %139 ], [ %158, %157 ], [ %176, %175 ], [ %194, %193 ], [ %212, %211 ], [ %230, %229 ], [ %248, %247 ], [ %266, %265 ], [ %284, %283 ], [ %302, %301 ], [ %320, %319 ], [ %338, %337 ], [ %356, %355 ], [ %374, %373 ], [ %392, %391 ], [ %410, %409 ], [ %428, %427 ], [ %446, %445 ], [ %464, %463 ], [ %482, %481 ], [ %500, %499 ], [ %518, %517 ], [ %536, %535 ], [ %554, %553 ], [ %572, %571 ], [ %590, %589 ], [ -1, %7 ]
  %596 = phi i1 [ false, %592 ], [ true, %27 ], [ true, %49 ], [ true, %67 ], [ true, %85 ], [ true, %103 ], [ true, %121 ], [ true, %139 ], [ true, %157 ], [ true, %175 ], [ true, %193 ], [ true, %211 ], [ true, %229 ], [ true, %247 ], [ true, %265 ], [ true, %283 ], [ true, %301 ], [ true, %319 ], [ true, %337 ], [ true, %355 ], [ true, %373 ], [ true, %391 ], [ true, %409 ], [ true, %427 ], [ true, %445 ], [ true, %463 ], [ true, %481 ], [ true, %499 ], [ true, %517 ], [ true, %535 ], [ true, %553 ], [ true, %571 ], [ true, %589 ], [ true, %7 ]
  %597 = add nuw nsw i64 %8, 1
  %598 = icmp eq i64 %597, %6
  %599 = select i1 %596, i1 true, i1 %598
  br i1 %599, label %600, label %7, !llvm.loop !14

600:                                              ; preds = %594, %3
  %601 = phi i32 [ 0, %3 ], [ %595, %594 ]
  ret i32 %601
}

attributes #0 = { nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 0}
!7 = !{!"Op", !8, i64 0, !8, i64 4, !8, i64 8}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
!12 = !{!8, !8, i64 0}
!13 = !{!7, !8, i64 8}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
