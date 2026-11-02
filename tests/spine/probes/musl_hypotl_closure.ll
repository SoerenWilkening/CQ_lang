; cq-hfj9: musl hypotl's closure (sweep_hypotl: x quantum, y classical; musl b1efda5 src/math/hypotl.c
; and what it reaches, internalized). Uncompute's garbageReads walk (and the spine's reads walk) were
; exponential in the depth over the shared item graph: cq-lower ran past 120 s. It lowers in about a second
; now; TIMEOUT bounds it.
; TIMEOUT 60
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__rsqrt_tab = internal local_unnamed_addr constant [128 x i16] [i16 -19375, i16 -19728, i16 -20074, i16 -20412, i16 -20743, i16 -21066, i16 -21383, i16 -21693, i16 -21996, i16 -22293, i16 -22584, i16 -22870, i16 -23150, i16 -23424, i16 -23693, i16 -23957, i16 -24216, i16 -24470, i16 -24720, i16 -24965, i16 -25206, i16 -25443, i16 -25675, i16 -25903, i16 -26128, i16 -26349, i16 -26566, i16 -26779, i16 -26989, i16 -27196, i16 -27400, i16 -27600, i16 -27797, i16 -27991, i16 -28182, i16 -28370, i16 -28555, i16 -28738, i16 -28918, i16 -29095, i16 -29270, i16 -29442, i16 -29612, i16 -29780, i16 -29945, i16 -30108, i16 -30268, i16 -30427, i16 -30583, i16 -30738, i16 -30890, i16 -31040, i16 -31189, i16 -31335, i16 -31480, i16 -31623, i16 -31764, i16 -31903, i16 -32040, i16 -32176, i16 -32311, i16 -32443, i16 -32574, i16 -32704, i16 -254, i16 -754, i16 -1243, i16 -1721, i16 -2189, i16 -2646, i16 -3094, i16 -3532, i16 -3961, i16 -4381, i16 -4793, i16 -5197, i16 -5593, i16 -5981, i16 -6361, i16 -6734, i16 -7101, i16 -7460, i16 -7814, i16 -8160, i16 -8501, i16 -8835, i16 -9164, i16 -9487, i16 -9805, i16 -10117, i16 -10424, i16 -10726, i16 -11023, i16 -11315, i16 -11603, i16 -11886, i16 -12165, i16 -12439, i16 -12709, i16 -12975, i16 -13238, i16 -13496, i16 -13750, i16 -14001, i16 -14248, i16 -14492, i16 -14732, i16 -14969, i16 -15203, i16 -15433, i16 -15660, i16 -15884, i16 -16106, i16 -16324, i16 -16539, i16 -16752, i16 -16962, i16 -17169, i16 -17373, i16 -17575, i16 -17775, i16 -17972, i16 -18166, i16 -18358, i16 -18548, i16 -18736, i16 -18921, i16 -19104], align 16

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @sweep_hypotl(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #0 {
  %3 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef 3.000000e-01) #7
  %4 = tail call x86_fp80 @hypotl(x86_fp80 noundef %3, x86_fp80 noundef %1) #8
  %5 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %4) #9
  ret x86_fp80 %5
}

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #1

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fpext.f80.f64(double, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define internal range(i32 0, 5) i32 @__fpclassifyl(x86_fp80 noundef %0) local_unnamed_addr #3 {
  %2 = bitcast x86_fp80 %0 to i80
  %3 = lshr i80 %2, 64
  %4 = trunc nuw nsw i80 %3 to i32
  %5 = and i32 %4, 32767
  %6 = trunc i80 %2 to i64
  %7 = icmp ne i32 %5, 0
  %8 = icmp slt i64 %6, 0
  %9 = or i1 %8, %7
  br i1 %9, label %13, label %10

10:                                               ; preds = %1
  %11 = icmp eq i64 %6, 0
  %12 = select i1 %11, i32 2, i32 3
  br label %24

13:                                               ; preds = %1
  %14 = icmp eq i32 %5, 32767
  br i1 %14, label %15, label %20

15:                                               ; preds = %13
  br i1 %8, label %16, label %24

16:                                               ; preds = %15
  %17 = and i64 %6, 9223372036854775807
  %18 = icmp eq i64 %17, 0
  %19 = zext i1 %18 to i32
  br label %24

20:                                               ; preds = %13
  %21 = lshr i80 %2, 61
  %22 = trunc nuw nsw i80 %21 to i32
  %23 = and i32 %22, 4
  br label %24

24:                                               ; preds = %20, %16, %15, %10
  %25 = phi i32 [ %19, %16 ], [ %12, %10 ], [ 0, %15 ], [ %23, %20 ]
  ret i32 %25
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.fdiv.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define internal x86_fp80 @__math_invalidl(x86_fp80 noundef %0) local_unnamed_addr #4 {
  %2 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %0, x86_fp80 %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %3 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %0, x86_fp80 %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %4 = tail call x86_fp80 @llvm.experimental.constrained.fdiv.f80(x86_fp80 %2, x86_fp80 %3, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  ret x86_fp80 %4
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.fabs.f80(x86_fp80) #5

; Function Attrs: nounwind ssp strictfp
define internal x86_fp80 @sqrtl(x86_fp80 noundef %0) local_unnamed_addr #6 {
  %2 = bitcast x86_fp80 %0 to i80
  %3 = trunc i80 %2 to i64
  %4 = shl i64 %3, 49
  %5 = lshr i64 %3, 15
  %6 = and i64 %5, 281474976710655
  %7 = lshr i80 %2, 16
  %8 = trunc nuw i80 %7 to i64
  %9 = and i64 %8, -281474976710656
  %10 = or disjoint i64 %6, %9
  %11 = lshr i64 %8, 48
  %12 = add nsw i64 %11, -32767
  %13 = icmp ult i64 %12, -32766
  br i1 %13, label %14, label %40, !prof !7

14:                                               ; preds = %1
  %15 = and i64 %10, 9223372036854775807
  %16 = icmp eq i64 %4, 0
  %17 = or i64 %15, %4
  %18 = icmp eq i64 %17, 0
  %19 = icmp eq i64 %10, 9223090561878065152
  %20 = and i1 %16, %19
  %21 = select i1 %18, i1 true, i1 %20
  br i1 %21, label %300, label %22

22:                                               ; preds = %14
  %23 = icmp ugt i64 %8, 9223090561878065151
  br i1 %23, label %24, label %26

24:                                               ; preds = %22
  %25 = tail call x86_fp80 @__math_invalidl(x86_fp80 noundef %0) #11
  br label %300

26:                                               ; preds = %22
  %27 = tail call x86_fp80 @llvm.experimental.constrained.fpext.f80.f64(double 0x46F0000000000000, metadata !"fpexcept.ignore") #10
  %28 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %0, x86_fp80 %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %29 = bitcast x86_fp80 %28 to i80
  %30 = trunc i80 %29 to i64
  %31 = shl i64 %30, 49
  %32 = lshr i64 %30, 15
  %33 = and i64 %32, 281474976710655
  %34 = lshr i80 %29, 16
  %35 = trunc nuw i80 %34 to i64
  %36 = and i64 %35, -281474976710656
  %37 = or disjoint i64 %33, %36
  %38 = lshr i64 %35, 48
  %39 = add nsw i64 %38, -112
  br label %40

40:                                               ; preds = %26, %1
  %41 = phi i64 [ %39, %26 ], [ %11, %1 ]
  %42 = phi i64 [ %37, %26 ], [ %10, %1 ]
  %43 = phi i64 [ %31, %26 ], [ %4, %1 ]
  %44 = tail call i64 @llvm.fshl.i64(i64 %42, i64 %43, i64 15)
  %45 = or i64 %44, -9223372036854775808
  %46 = and i64 %41, 1
  %47 = icmp eq i64 %46, 0
  %48 = shl i64 %44, 63
  %49 = lshr i64 %45, %46
  %50 = select i1 %47, i64 0, i64 %48
  %51 = add nsw i64 %41, 16383
  %52 = lshr i64 %51, 1
  %53 = lshr i64 %42, 42
  %54 = and i64 %53, 127
  %55 = getelementptr inbounds [128 x i16], ptr @__rsqrt_tab, i64 0, i64 %54
  %56 = load i16, ptr %55, align 2
  %57 = zext i16 %56 to i64
  %58 = shl nuw nsw i64 %57, 16
  %59 = lshr i64 %49, 32
  %60 = mul nuw i64 %59, %58
  %61 = lshr i64 %60, 32
  %62 = mul nuw i64 %61, %58
  %63 = lshr i64 %62, 32
  %64 = sub nsw i64 3221225472, %63
  %65 = and i64 %64, 4294967295
  %66 = mul nuw i64 %65, %58
  %67 = lshr i64 %66, 31
  %68 = and i64 %67, 4294967294
  %69 = and i64 %49, 4294967295
  %70 = mul nuw i64 %68, %59
  %71 = mul nuw i64 %68, %69
  %72 = lshr i64 %71, 32
  %73 = add nuw i64 %72, %70
  %74 = lshr i64 %73, 32
  %75 = and i64 %73, 4294967295
  %76 = mul nuw i64 %74, %68
  %77 = mul nuw i64 %75, %68
  %78 = lshr i64 %77, 32
  %79 = add nuw i64 %76, %78
  %80 = sub i64 -4611686018427387904, %79
  %81 = lshr i64 %80, 32
  %82 = and i64 %80, 4294967295
  %83 = mul nuw i64 %81, %68
  %84 = mul nuw i64 %82, %68
  %85 = lshr i64 %84, 32
  %86 = add nuw i64 %85, %83
  %87 = shl i64 %86, 1
  %88 = mul nuw i64 %81, %74
  %89 = mul nuw i64 %81, %75
  %90 = lshr i64 %89, 32
  %91 = add nuw i64 %90, %88
  %92 = mul nuw i64 %82, %74
  %93 = lshr i64 %92, 32
  %94 = add nuw i64 %91, %93
  %95 = shl i64 %94, 1
  %96 = lshr i64 %95, 32
  %97 = and i64 %95, 4294967294
  %98 = lshr i64 %87, 32
  %99 = and i64 %87, 4294967294
  %100 = mul nuw i64 %96, %98
  %101 = mul nuw i64 %96, %99
  %102 = lshr i64 %101, 32
  %103 = mul nuw i64 %97, %98
  %104 = lshr i64 %103, 32
  %105 = add nuw i64 %100, %102
  %106 = add nuw i64 %105, %104
  %107 = sub i64 -4611686018427387904, %106
  %108 = lshr i64 %107, 32
  %109 = and i64 %107, 4294967295
  %110 = mul nuw i64 %108, %98
  %111 = mul nuw i64 %108, %99
  %112 = lshr i64 %111, 32
  %113 = add nuw i64 %112, %110
  %114 = mul nuw i64 %109, %98
  %115 = lshr i64 %114, 32
  %116 = add nuw i64 %113, %115
  %117 = shl i64 %116, 1
  %118 = lshr i64 %117, 32
  %119 = and i64 %117, 4294967294
  %120 = mul nuw i64 %119, %59
  %121 = and i64 %120, 4294967294
  %122 = mul nuw i64 %118, %69
  %123 = and i64 %122, 4294967295
  %124 = add nuw nsw i64 %121, %123
  %125 = mul nuw i64 %119, %69
  %126 = lshr i64 %125, 32
  %127 = add nuw nsw i64 %124, %126
  %128 = and i64 %125, 4294967294
  %129 = mul nuw i64 %118, %59
  %130 = lshr i64 %120, 32
  %131 = add nuw i64 %130, %129
  %132 = lshr i64 %122, 32
  %133 = add nuw i64 %131, %132
  %134 = lshr i64 %127, 32
  %135 = add nuw i64 %133, %134
  %136 = shl i64 %127, 32
  %137 = or disjoint i64 %136, %128
  %138 = lshr exact i64 %50, 32
  %139 = mul nuw nsw i64 %118, %138
  %140 = mul nuw nsw i64 %119, %138
  %141 = lshr exact i64 %140, 32
  %142 = or disjoint i64 %141, %139
  %143 = add i64 %142, %137
  %144 = icmp ult i64 %143, %137
  %145 = zext i1 %144 to i64
  %146 = add nuw i64 %135, %145
  %147 = lshr i64 %146, 32
  %148 = and i64 %146, 4294967295
  %149 = mul nuw i64 %147, %119
  %150 = and i64 %149, 4294967294
  %151 = mul nuw i64 %148, %118
  %152 = and i64 %151, 4294967295
  %153 = add nuw nsw i64 %150, %152
  %154 = mul nuw i64 %148, %119
  %155 = lshr i64 %154, 32
  %156 = add nuw nsw i64 %153, %155
  %157 = and i64 %154, 4294967294
  %158 = mul nuw i64 %147, %118
  %159 = lshr i64 %149, 32
  %160 = lshr i64 %151, 32
  %161 = lshr i64 %156, 32
  %162 = shl i64 %156, 32
  %163 = or disjoint i64 %162, %157
  %164 = lshr i64 %143, 32
  %165 = and i64 %143, 4294967295
  %166 = mul nuw i64 %164, %118
  %167 = mul nuw i64 %164, %119
  %168 = lshr i64 %167, 32
  %169 = add nuw i64 %168, %166
  %170 = mul nuw i64 %165, %118
  %171 = lshr i64 %170, 32
  %172 = add nuw i64 %169, %171
  %173 = add i64 %172, %163
  %174 = icmp ult i64 %173, %163
  %175 = sext i1 %174 to i64
  %176 = icmp ne i64 %173, 0
  %177 = sext i1 %176 to i64
  %178 = add nuw i64 %159, %158
  %179 = add nuw i64 %178, %160
  %180 = add nuw i64 %179, %161
  %181 = sub i64 %175, %180
  %182 = add i64 %181, %177
  %183 = add i64 %182, -4611686018427387904
  %184 = sub i64 0, %173
  %185 = lshr i64 %183, 32
  %186 = and i64 %182, 4294967295
  %187 = mul nuw i64 %185, %148
  %188 = and i64 %187, 4294967295
  %189 = mul nuw i64 %186, %147
  %190 = and i64 %189, 4294967295
  %191 = mul nuw i64 %186, %148
  %192 = lshr i64 %191, 32
  %193 = add nuw nsw i64 %192, %190
  %194 = add nuw nsw i64 %193, %188
  %195 = and i64 %191, 4294967295
  %196 = mul nuw i64 %185, %147
  %197 = lshr i64 %187, 32
  %198 = lshr i64 %189, 32
  %199 = lshr i64 %194, 32
  %200 = shl i64 %194, 32
  %201 = or disjoint i64 %200, %195
  %202 = mul nuw i64 %185, %164
  %203 = mul nuw i64 %185, %165
  %204 = lshr i64 %203, 32
  %205 = mul nuw i64 %186, %164
  %206 = lshr i64 %205, 32
  %207 = lshr i64 %184, 32
  %208 = and i64 %184, 4294967295
  %209 = mul nuw i64 %207, %147
  %210 = mul nuw i64 %207, %148
  %211 = lshr i64 %210, 32
  %212 = add nuw i64 %211, %209
  %213 = mul nuw i64 %208, %147
  %214 = lshr i64 %213, 32
  %215 = add nuw i64 %212, %214
  %216 = add nuw i64 %206, %202
  %217 = add nuw i64 %216, %204
  %218 = add i64 %217, %201
  %219 = icmp ult i64 %218, %201
  %220 = zext i1 %219 to i64
  %221 = add i64 %215, %218
  %222 = icmp ult i64 %221, %218
  %223 = zext i1 %222 to i64
  %224 = icmp ult i64 %221, 4
  %225 = sext i1 %224 to i64
  %226 = add nuw i64 %198, %196
  %227 = add nuw i64 %226, %197
  %228 = add nuw i64 %227, %199
  %229 = add i64 %228, %220
  %230 = add i64 %229, %223
  %231 = add i64 %230, %225
  %232 = add i64 %221, -4
  %233 = lshr i64 %231, 62
  %234 = tail call i64 @llvm.fshl.i64(i64 %231, i64 %232, i64 2)
  %235 = lshr i64 %234, 32
  %236 = and i64 %234, 4294967295
  %237 = mul nuw i64 %236, %235
  %238 = shl i64 %237, 1
  %239 = and i64 %238, 8589934590
  %240 = mul nuw i64 %236, %236
  %241 = lshr i64 %240, 32
  %242 = add nuw nsw i64 %239, %241
  %243 = and i64 %240, 4294967295
  %244 = mul nuw i64 %235, %235
  %245 = lshr i64 %242, 32
  %246 = shl i64 %242, 32
  %247 = or disjoint i64 %246, %243
  %248 = shl nuw nsw i64 %233, 1
  %249 = mul i64 %248, %234
  %250 = lshr i64 %237, 31
  %251 = and i64 %250, 8589934590
  %252 = icmp ult i64 %50, %247
  %253 = zext i1 %252 to i64
  %254 = sub i64 %50, %247
  %255 = icmp ult i64 %234, %254
  %256 = sext i1 %255 to i64
  %257 = sub i64 %233, %49
  %258 = add i64 %257, %244
  %259 = add i64 %258, %249
  %260 = add i64 %259, %251
  %261 = add i64 %260, %245
  %262 = add i64 %261, %253
  %263 = add i64 %262, %256
  %264 = sub i64 %234, %254
  %265 = add i64 %234, 1
  %266 = icmp eq i64 %234, -1
  %267 = zext i1 %266 to i64
  %268 = add nuw nsw i64 %233, %267
  %269 = add i64 %264, %265
  %270 = add i64 %268, %263
  %271 = icmp ult i64 %269, %265
  %272 = zext i1 %271 to i64
  %273 = add i64 %270, %272
  %274 = lshr i64 %263, 63
  %275 = add i64 %274, %234
  %276 = and i64 %51, 65534
  %277 = icmp eq i64 %276, 0
  %278 = or i64 %275, -9223372036854775808
  %279 = select i1 %277, i64 %275, i64 %278
  %280 = and i64 %52, 65535
  %281 = zext nneg i64 %280 to i80
  %282 = shl nuw i80 %281, 64
  %283 = zext i64 %279 to i80
  %284 = or disjoint i80 %282, %283
  %285 = bitcast i80 %284 to x86_fp80
  %286 = or i64 %273, %269
  %287 = icmp ne i64 %286, 0
  %288 = zext i1 %287 to i64
  %289 = xor i64 %273, %263
  %290 = lshr i64 %289, 48
  %291 = and i64 %290, 32768
  %292 = or disjoint i64 %291, %288
  %293 = select i1 %287, i64 -9223372036854775808, i64 0
  %294 = zext nneg i64 %292 to i80
  %295 = shl nuw i80 %294, 64
  %296 = zext i64 %293 to i80
  %297 = or disjoint i80 %295, %296
  %298 = bitcast i80 %297 to x86_fp80
  %299 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %285, x86_fp80 %298, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  br label %300

300:                                              ; preds = %40, %24, %14
  %301 = phi x86_fp80 [ %25, %24 ], [ %299, %40 ], [ %0, %14 ]
  ret x86_fp80 %301
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f80(x86_fp80, x86_fp80, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.fshl.i64(i64, i64, i64) #5

; Function Attrs: nounwind ssp strictfp
define internal x86_fp80 @hypotl(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #6 {
  %3 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %0)
  %4 = bitcast x86_fp80 %3 to i80
  %5 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)
  %6 = bitcast x86_fp80 %5 to i80
  %7 = lshr i80 %4, 64
  %8 = trunc nuw nsw i80 %7 to i32
  %9 = lshr i80 %6, 64
  %10 = trunc nuw nsw i80 %9 to i32
  %11 = icmp ult i32 %8, %10
  %12 = select i1 %11, x86_fp80 %3, x86_fp80 %5
  %13 = select i1 %11, x86_fp80 %5, x86_fp80 %3
  %14 = tail call i32 @llvm.umax.i32(i32 %8, i32 %10)
  %15 = tail call i32 @llvm.umin.i32(i32 %8, i32 %10)
  %16 = icmp eq i32 %14, 32767
  br i1 %16, label %17, label %21

17:                                               ; preds = %2
  %18 = tail call i32 @__fpclassifyl(x86_fp80 noundef %12) #11
  %19 = icmp eq i32 %18, 1
  %20 = select i1 %19, x86_fp80 %12, x86_fp80 %13
  br label %75

21:                                               ; preds = %2
  %22 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %23 = tail call i1 @llvm.experimental.constrained.fcmp.f80(x86_fp80 %12, x86_fp80 %22, metadata !"oeq", metadata !"fpexcept.ignore") #10
  br i1 %23, label %75, label %24

24:                                               ; preds = %21
  %25 = sub nsw i32 %14, %15
  %26 = icmp sgt i32 %25, 64
  br i1 %26, label %27, label %29

27:                                               ; preds = %24
  %28 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %13, x86_fp80 %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  br label %75

29:                                               ; preds = %24
  %30 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %31 = icmp ugt i32 %14, 24383
  br i1 %31, label %32, label %35

32:                                               ; preds = %29
  %33 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %13, x86_fp80 0xK18EF8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %34 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %12, x86_fp80 0xK18EF8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  br label %40

35:                                               ; preds = %29
  %36 = icmp ult i32 %15, 8383
  br i1 %36, label %37, label %40

37:                                               ; preds = %35
  %38 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %13, x86_fp80 0xK670F8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %39 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %12, x86_fp80 0xK670F8000000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  br label %40

40:                                               ; preds = %37, %35, %32
  %41 = phi x86_fp80 [ %34, %32 ], [ %39, %37 ], [ %12, %35 ]
  %42 = phi x86_fp80 [ %33, %32 ], [ %38, %37 ], [ %13, %35 ]
  %43 = phi x86_fp80 [ 0xK670F8000000000000000, %32 ], [ 0xK18EF8000000000000000, %37 ], [ %30, %35 ]
  %44 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %45 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 0xK401F8000000000000000, x86_fp80 %44, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %46 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %42, x86_fp80 %45, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %47 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %42, x86_fp80 %46, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %48 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %47, x86_fp80 %46, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %49 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %42, x86_fp80 %48, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %50 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %42, x86_fp80 %42, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %51 = fneg x86_fp80 %50
  %52 = tail call x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80 %48, x86_fp80 %48, x86_fp80 %51, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %53 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %54 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %53, x86_fp80 %48, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %55 = tail call x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80 %54, x86_fp80 %49, x86_fp80 %52, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %56 = tail call x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80 %49, x86_fp80 %49, x86_fp80 %55, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %57 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %58 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 0xK401F8000000000000000, x86_fp80 %57, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %59 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %41, x86_fp80 %58, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %60 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %41, x86_fp80 %59, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %61 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %60, x86_fp80 %59, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %62 = tail call x86_fp80 @llvm.experimental.constrained.fsub.f80(x86_fp80 %41, x86_fp80 %61, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %63 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %41, x86_fp80 %41, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %64 = fneg x86_fp80 %63
  %65 = tail call x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80 %61, x86_fp80 %61, x86_fp80 %64, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %66 = tail call x86_fp80 @llvm.experimental.constrained.sitofp.f80.i32(i32 2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %67 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %66, x86_fp80 %61, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %68 = tail call x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80 %67, x86_fp80 %62, x86_fp80 %65, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %69 = tail call x86_fp80 @llvm.experimental.constrained.fmuladd.f80(x86_fp80 %62, x86_fp80 %62, x86_fp80 %68, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %70 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %69, x86_fp80 %56, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %71 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %70, x86_fp80 %63, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %72 = tail call x86_fp80 @llvm.experimental.constrained.fadd.f80(x86_fp80 %71, x86_fp80 %50, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  %73 = tail call x86_fp80 @sqrtl(x86_fp80 noundef %72) #11
  %74 = tail call x86_fp80 @llvm.experimental.constrained.fmul.f80(x86_fp80 %43, x86_fp80 %73, metadata !"round.dynamic", metadata !"fpexcept.ignore") #10
  br label %75

75:                                               ; preds = %40, %27, %21, %17
  %76 = phi x86_fp80 [ %28, %27 ], [ %74, %40 ], [ %20, %17 ], [ %13, %21 ]
  ret x86_fp80 %76
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind willreturn memory(none) }
attributes #9 = { nounwind }
attributes #10 = { strictfp }
attributes #11 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{!"branch_weights", !"expected", i32 1, i32 2000}
