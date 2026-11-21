; ModuleID = 'sw16.c'
source_filename = "sw16.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.Op = type { i32, i32, i32 }

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i32 @interp(ptr nocapture noundef readonly %0, i32 noundef %1, ptr noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %312

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %7

7:                                                ; preds = %306, %5
  %8 = phi i64 [ 0, %5 ], [ %309, %306 ]
  %9 = phi i32 [ 0, %5 ], [ %307, %306 ]
  %10 = getelementptr inbounds %struct.Op, ptr %0, i64 %8
  %11 = load i32, ptr %10, align 4, !tbaa !6
  switch i32 %11, label %306 [
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
  br label %304

27:                                               ; preds = %12
  %28 = getelementptr inbounds i8, ptr %10, i64 8
  %29 = load i32, ptr %28, align 4, !tbaa !13
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds i32, ptr %2, i64 %30
  %32 = load i32, ptr %31, align 4, !tbaa !12
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %306, label %304

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
  br label %304

49:                                               ; preds = %34
  %50 = xor i32 %9, 1
  %51 = icmp eq i32 %45, 1
  br i1 %51, label %306, label %304

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
  br label %304

67:                                               ; preds = %52
  %68 = xor i32 %9, 2
  %69 = icmp eq i32 %63, 2
  br i1 %69, label %306, label %304

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
  br label %304

85:                                               ; preds = %70
  %86 = xor i32 %9, 3
  %87 = icmp eq i32 %81, 3
  br i1 %87, label %306, label %304

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
  br label %304

103:                                              ; preds = %88
  %104 = xor i32 %9, 4
  %105 = icmp eq i32 %99, 4
  br i1 %105, label %306, label %304

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
  br label %304

121:                                              ; preds = %106
  %122 = xor i32 %9, 5
  %123 = icmp eq i32 %117, 5
  br i1 %123, label %306, label %304

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
  br label %304

139:                                              ; preds = %124
  %140 = xor i32 %9, 6
  %141 = icmp eq i32 %135, 6
  br i1 %141, label %306, label %304

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
  br label %304

157:                                              ; preds = %142
  %158 = xor i32 %9, 7
  %159 = icmp eq i32 %153, 7
  br i1 %159, label %306, label %304

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
  br label %304

175:                                              ; preds = %160
  %176 = xor i32 %9, 8
  %177 = icmp eq i32 %171, 8
  br i1 %177, label %306, label %304

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
  br label %304

193:                                              ; preds = %178
  %194 = xor i32 %9, 9
  %195 = icmp eq i32 %189, 9
  br i1 %195, label %306, label %304

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
  br label %304

211:                                              ; preds = %196
  %212 = xor i32 %9, 10
  %213 = icmp eq i32 %207, 10
  br i1 %213, label %306, label %304

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
  br label %304

229:                                              ; preds = %214
  %230 = xor i32 %9, 11
  %231 = icmp eq i32 %225, 11
  br i1 %231, label %306, label %304

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
  br label %304

247:                                              ; preds = %232
  %248 = xor i32 %9, 12
  %249 = icmp eq i32 %243, 12
  br i1 %249, label %306, label %304

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
  br label %304

265:                                              ; preds = %250
  %266 = xor i32 %9, 13
  %267 = icmp eq i32 %261, 13
  br i1 %267, label %306, label %304

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
  br label %304

283:                                              ; preds = %268
  %284 = xor i32 %9, 14
  %285 = icmp eq i32 %279, 14
  br i1 %285, label %306, label %304

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
  br label %304

301:                                              ; preds = %286
  %302 = xor i32 %9, 15
  %303 = icmp eq i32 %297, 15
  br i1 %303, label %306, label %304

304:                                              ; preds = %298, %301, %280, %283, %262, %265, %244, %247, %226, %229, %208, %211, %190, %193, %172, %175, %154, %157, %136, %139, %118, %121, %100, %103, %82, %85, %64, %67, %46, %49, %19, %27
  %305 = phi i32 [ %9, %298 ], [ %302, %301 ], [ %9, %280 ], [ %284, %283 ], [ %9, %262 ], [ %266, %265 ], [ %9, %244 ], [ %248, %247 ], [ %9, %226 ], [ %230, %229 ], [ %9, %208 ], [ %212, %211 ], [ %9, %190 ], [ %194, %193 ], [ %9, %172 ], [ %176, %175 ], [ %9, %154 ], [ %158, %157 ], [ %9, %136 ], [ %140, %139 ], [ %9, %118 ], [ %122, %121 ], [ %9, %100 ], [ %104, %103 ], [ %9, %82 ], [ %86, %85 ], [ %9, %64 ], [ %68, %67 ], [ %9, %46 ], [ %50, %49 ], [ %9, %19 ], [ %9, %27 ]
  br label %306

306:                                              ; preds = %7, %301, %283, %265, %247, %229, %211, %193, %175, %157, %139, %121, %103, %85, %67, %49, %27, %304
  %307 = phi i32 [ %305, %304 ], [ %9, %27 ], [ %50, %49 ], [ %68, %67 ], [ %86, %85 ], [ %104, %103 ], [ %122, %121 ], [ %140, %139 ], [ %158, %157 ], [ %176, %175 ], [ %194, %193 ], [ %212, %211 ], [ %230, %229 ], [ %248, %247 ], [ %266, %265 ], [ %284, %283 ], [ %302, %301 ], [ -1, %7 ]
  %308 = phi i1 [ false, %304 ], [ true, %27 ], [ true, %49 ], [ true, %67 ], [ true, %85 ], [ true, %103 ], [ true, %121 ], [ true, %139 ], [ true, %157 ], [ true, %175 ], [ true, %193 ], [ true, %211 ], [ true, %229 ], [ true, %247 ], [ true, %265 ], [ true, %283 ], [ true, %301 ], [ true, %7 ]
  %309 = add nuw nsw i64 %8, 1
  %310 = icmp eq i64 %309, %6
  %311 = select i1 %308, i1 true, i1 %310
  br i1 %311, label %312, label %7, !llvm.loop !14

312:                                              ; preds = %306, %3
  %313 = phi i32 [ 0, %3 ], [ %307, %306 ]
  ret i32 %313
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
