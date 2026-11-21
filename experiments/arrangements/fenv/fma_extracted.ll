; ModuleID = 'st/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fpext.f64.f32(float, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define double @scalbn(double noundef %0, i32 noundef %1) #2 {
  %3 = icmp sgt i32 %1, 1023
  br i1 %3, label %4, label %12

4:                                                ; preds = %2
  %5 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 0x7FE0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %6 = add nsw i32 %1, -1023
  %7 = icmp sgt i32 %1, 2046
  br i1 %7, label %8, label %22

8:                                                ; preds = %4
  %9 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double 0x7FE0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %10 = tail call i32 @llvm.smin.i32(i32 %1, i32 3069)
  %11 = add nsw i32 %10, -2046
  br label %22

12:                                               ; preds = %2
  %13 = icmp slt i32 %1, -1022
  br i1 %13, label %14, label %22

14:                                               ; preds = %12
  %15 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 0x360000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %16 = add nuw nsw i32 %1, 969
  %17 = icmp slt i32 %1, -1991
  br i1 %17, label %18, label %22

18:                                               ; preds = %14
  %19 = tail call double @llvm.experimental.constrained.fmul.f64(double %15, double 0x360000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %20 = tail call i32 @llvm.smax.i32(i32 %1, i32 -2960)
  %21 = add nsw i32 %20, 1938
  br label %22

22:                                               ; preds = %18, %14, %12, %8, %4
  %23 = phi i32 [ %11, %8 ], [ %6, %4 ], [ %21, %18 ], [ %16, %14 ], [ %1, %12 ]
  %24 = phi double [ %9, %8 ], [ %5, %4 ], [ %19, %18 ], [ %15, %14 ], [ %0, %12 ]
  %25 = add nsw i32 %23, 1023
  %26 = zext i32 %25 to i64
  %27 = shl i64 %26, 52
  %28 = bitcast i64 %27 to double
  %29 = tail call double @llvm.experimental.constrained.fmul.f64(double %24, double %28, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  ret double %29
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #1

; Function Attrs: nounwind ssp strictfp
define double @fma(double noundef %0, double noundef %1, double noundef %2) #3 {
  %4 = bitcast double %0 to i64
  %5 = lshr i64 %4, 52
  %6 = trunc nuw nsw i64 %5 to i32
  %7 = and i32 %6, 2047
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %18

9:                                                ; preds = %3
  %10 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 0x43E0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %11 = bitcast double %10 to i64
  %12 = lshr i64 %11, 52
  %13 = trunc nuw nsw i64 %12 to i32
  %14 = and i32 %13, 2047
  %15 = icmp eq i32 %14, 0
  %16 = add nsw i32 %14, -63
  %17 = select i1 %15, i32 2048, i32 %16
  br label %18

18:                                               ; preds = %9, %3
  %19 = phi i32 [ %7, %3 ], [ %17, %9 ]
  %20 = phi i64 [ %4, %3 ], [ %11, %9 ]
  %21 = shl i64 %20, 1
  %22 = add nsw i32 %19, -1076
  %23 = shl nuw nsw i64 %5, 32
  %24 = and i64 %23, 8796093022208
  %25 = zext i32 %22 to i64
  %26 = or disjoint i64 %24, %25
  %27 = bitcast double %1 to i64
  %28 = lshr i64 %27, 52
  %29 = trunc nuw nsw i64 %28 to i32
  %30 = and i32 %29, 2047
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %32, label %41

32:                                               ; preds = %18
  %33 = tail call double @llvm.experimental.constrained.fmul.f64(double %1, double 0x43E0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %34 = bitcast double %33 to i64
  %35 = lshr i64 %34, 52
  %36 = trunc nuw nsw i64 %35 to i32
  %37 = and i32 %36, 2047
  %38 = icmp eq i32 %37, 0
  %39 = add nsw i32 %37, -63
  %40 = select i1 %38, i32 2048, i32 %39
  br label %41

41:                                               ; preds = %32, %18
  %42 = phi i32 [ %30, %18 ], [ %40, %32 ]
  %43 = phi i64 [ %27, %18 ], [ %34, %32 ]
  %44 = shl i64 %43, 1
  %45 = add nsw i32 %42, -1076
  %46 = shl nuw nsw i64 %28, 32
  %47 = and i64 %46, 8796093022208
  %48 = zext i32 %45 to i64
  %49 = or disjoint i64 %47, %48
  %50 = bitcast double %2 to i64
  %51 = lshr i64 %50, 52
  %52 = trunc nuw nsw i64 %51 to i32
  %53 = and i32 %52, 2047
  %54 = icmp eq i32 %53, 0
  br i1 %54, label %55, label %64

55:                                               ; preds = %41
  %56 = tail call double @llvm.experimental.constrained.fmul.f64(double %2, double 0x43E0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %57 = bitcast double %56 to i64
  %58 = lshr i64 %57, 52
  %59 = trunc nuw nsw i64 %58 to i32
  %60 = and i32 %59, 2047
  %61 = icmp eq i32 %60, 0
  %62 = add nsw i32 %60, -63
  %63 = select i1 %61, i32 2048, i32 %62
  br label %64

64:                                               ; preds = %55, %41
  %65 = phi i32 [ %53, %41 ], [ %63, %55 ]
  %66 = phi i64 [ %50, %41 ], [ %57, %55 ]
  %67 = shl i64 %66, 1
  %68 = and i64 %67, 9007199254740990
  %69 = or disjoint i64 %68, 9007199254740992
  %70 = add nsw i32 %65, -1076
  %71 = shl nuw nsw i64 %51, 32
  %72 = and i64 %71, 8796093022208
  %73 = icmp sgt i32 %19, 2046
  %74 = icmp sgt i32 %42, 2046
  %75 = select i1 %73, i1 true, i1 %74
  br i1 %75, label %76, label %78

76:                                               ; preds = %64
  %77 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %0, double %1, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %278

78:                                               ; preds = %64
  %79 = icmp sgt i32 %65, 2046
  br i1 %79, label %80, label %84

80:                                               ; preds = %78
  %81 = icmp eq i32 %70, 971
  br i1 %81, label %278, label %82

82:                                               ; preds = %80
  %83 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %278

84:                                               ; preds = %78
  %85 = and i64 %21, 4294967294
  %86 = lshr i64 %21, 32
  %87 = and i64 %86, 2097151
  %88 = or disjoint i64 %87, 2097152
  %89 = and i64 %44, 4294967294
  %90 = lshr i64 %44, 32
  %91 = and i64 %90, 2097151
  %92 = or disjoint i64 %91, 2097152
  %93 = mul nuw i64 %89, %85
  %94 = mul nuw nsw i64 %92, %85
  %95 = mul nuw nsw i64 %89, %88
  %96 = add nuw nsw i64 %94, %95
  %97 = mul nuw nsw i64 %92, %88
  %98 = shl i64 %96, 32
  %99 = add i64 %98, %93
  %100 = lshr i64 %96, 32
  %101 = add nuw nsw i64 %100, %97
  %102 = icmp ugt i64 %93, %99
  %103 = zext i1 %102 to i64
  %104 = add nuw nsw i64 %101, %103
  %105 = add nsw i32 %45, %22
  %106 = sub nsw i32 %70, %105
  %107 = icmp sgt i32 %106, 0
  br i1 %107, label %108, label %134

108:                                              ; preds = %84
  %109 = icmp slt i32 %106, 64
  br i1 %109, label %110, label %116

110:                                              ; preds = %108
  %111 = zext nneg i32 %106 to i64
  %112 = shl i64 %69, %111
  %113 = sub nuw nsw i32 64, %106
  %114 = zext nneg i32 %113 to i64
  %115 = lshr i64 %69, %114
  br label %148

116:                                              ; preds = %108
  %117 = add nsw i32 %65, -1140
  %118 = add nsw i32 %106, -64
  %119 = icmp eq i32 %118, 0
  br i1 %119, label %148, label %120

120:                                              ; preds = %116
  %121 = icmp slt i32 %106, 128
  br i1 %121, label %122, label %148

122:                                              ; preds = %120
  %123 = sub nsw i32 128, %106
  %124 = zext nneg i32 %123 to i64
  %125 = shl i64 %104, %124
  %126 = zext nneg i32 %118 to i64
  %127 = lshr i64 %99, %126
  %128 = or i64 %125, %127
  %129 = shl i64 %99, %124
  %130 = icmp ne i64 %129, 0
  %131 = zext i1 %130 to i64
  %132 = or i64 %128, %131
  %133 = lshr i64 %104, %126
  br label %148

134:                                              ; preds = %84
  %135 = sub nsw i32 0, %106
  %136 = icmp eq i32 %105, %70
  br i1 %136, label %148, label %137

137:                                              ; preds = %134
  %138 = icmp sgt i32 %106, -64
  br i1 %138, label %139, label %148

139:                                              ; preds = %137
  %140 = zext nneg i32 %135 to i64
  %141 = lshr i64 %69, %140
  %142 = add nsw i32 %106, 64
  %143 = zext nneg i32 %142 to i64
  %144 = shl i64 %69, %143
  %145 = icmp ne i64 %144, 0
  %146 = zext i1 %145 to i64
  %147 = or i64 %141, %146
  br label %148

148:                                              ; preds = %139, %137, %134, %122, %120, %116, %110
  %149 = phi i64 [ %104, %110 ], [ %104, %116 ], [ %133, %122 ], [ %104, %134 ], [ %104, %139 ], [ %104, %137 ], [ 0, %120 ]
  %150 = phi i64 [ %99, %110 ], [ %99, %116 ], [ %132, %122 ], [ %99, %134 ], [ %99, %139 ], [ %99, %137 ], [ 1, %120 ]
  %151 = phi i32 [ %105, %110 ], [ %117, %116 ], [ %117, %122 ], [ %105, %134 ], [ %105, %139 ], [ %105, %137 ], [ %117, %120 ]
  %152 = phi i64 [ %112, %110 ], [ 0, %116 ], [ 0, %122 ], [ %69, %134 ], [ %147, %139 ], [ 1, %137 ], [ 0, %120 ]
  %153 = phi i64 [ %115, %110 ], [ %69, %116 ], [ %69, %122 ], [ 0, %134 ], [ 0, %139 ], [ 0, %137 ], [ %69, %120 ]
  %154 = xor i64 %49, %26
  %155 = lshr i64 %154, 32
  %156 = trunc nuw nsw i64 %155 to i32
  %157 = xor i64 %154, %72
  %158 = icmp ult i64 %157, 4294967296
  br i1 %158, label %159, label %165

159:                                              ; preds = %148
  %160 = add i64 %152, %150
  %161 = icmp ult i64 %160, %152
  %162 = zext i1 %161 to i64
  %163 = add nuw nsw i64 %153, %149
  %164 = add nuw nsw i64 %163, %162
  br label %184

165:                                              ; preds = %148
  %166 = sub i64 %150, %152
  %167 = sub nsw i64 %149, %153
  %168 = icmp ult i64 %150, %152
  %169 = sext i1 %168 to i64
  %170 = add nsw i64 %167, %169
  %171 = icmp sgt i64 %170, -1
  br i1 %171, label %179, label %172

172:                                              ; preds = %165
  %173 = sub i64 0, %166
  %174 = icmp ne i64 %166, 0
  %175 = sext i1 %174 to i64
  %176 = sub nsw i64 %175, %170
  %177 = icmp ult i64 %154, 4294967296
  %178 = zext i1 %177 to i32
  br label %179

179:                                              ; preds = %172, %165
  %180 = phi i64 [ %170, %165 ], [ %176, %172 ]
  %181 = phi i64 [ %166, %165 ], [ %173, %172 ]
  %182 = phi i32 [ %156, %165 ], [ %178, %172 ]
  %183 = icmp eq i64 %180, 0
  br label %184

184:                                              ; preds = %179, %159
  %185 = phi i64 [ %164, %159 ], [ %180, %179 ]
  %186 = phi i64 [ %160, %159 ], [ %181, %179 ]
  %187 = phi i32 [ %156, %159 ], [ %182, %179 ]
  %188 = phi i1 [ false, %159 ], [ %183, %179 ]
  br i1 %188, label %203, label %189

189:                                              ; preds = %184
  %190 = add nsw i32 %151, 64
  %191 = tail call range(i64 0, 65) i64 @llvm.ctlz.i64(i64 %185, i1 true) #4
  %192 = trunc nuw nsw i64 %191 to i32
  %193 = add nsw i32 %192, -1
  %194 = zext i32 %193 to i64
  %195 = shl i64 %185, %194
  %196 = sub nuw nsw i64 65, %191
  %197 = lshr i64 %186, %196
  %198 = or i64 %195, %197
  %199 = shl i64 %186, %194
  %200 = icmp ne i64 %199, 0
  %201 = zext i1 %200 to i64
  %202 = or i64 %198, %201
  br label %219

203:                                              ; preds = %184
  %204 = icmp eq i64 %186, 0
  br i1 %204, label %217, label %205

205:                                              ; preds = %203
  %206 = tail call range(i64 0, 65) i64 @llvm.ctlz.i64(i64 %186, i1 true) #4
  %207 = trunc nuw nsw i64 %206 to i32
  %208 = add nsw i32 %207, -1
  %209 = icmp eq i64 %206, 0
  br i1 %209, label %210, label %214

210:                                              ; preds = %205
  %211 = lshr i64 %186, 1
  %212 = and i64 %186, 1
  %213 = or i64 %211, %212
  br label %219

214:                                              ; preds = %205
  %215 = zext nneg i32 %208 to i64
  %216 = shl i64 %186, %215
  br label %219

217:                                              ; preds = %203
  %218 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %0, double %1, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %278

219:                                              ; preds = %214, %210, %189
  %220 = phi i64 [ %213, %210 ], [ %216, %214 ], [ %202, %189 ]
  %221 = phi i32 [ %151, %210 ], [ %151, %214 ], [ %190, %189 ]
  %222 = phi i32 [ %208, %210 ], [ %208, %214 ], [ %193, %189 ]
  %223 = sub nsw i32 %221, %222
  %224 = icmp eq i32 %187, 0
  %225 = sub nsw i64 0, %220
  %226 = select i1 %224, i64 %220, i64 %225
  %227 = tail call double @llvm.experimental.constrained.sitofp.f64.i64(i64 %226, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %228 = icmp slt i32 %223, -1084
  br i1 %228, label %229, label %275

229:                                              ; preds = %219
  %230 = icmp eq i32 %223, -1085
  br i1 %230, label %231, label %266

231:                                              ; preds = %229
  %232 = select i1 %224, double 0x43E0000000000000, double 0xC3E0000000000000
  %233 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %227, double %232, metadata !"oeq", metadata !"fpexcept.strict") #4
  br i1 %233, label %234, label %243

234:                                              ; preds = %231
  %235 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0x3810000000000000, metadata !"fpexcept.strict") #4
  %236 = tail call double @llvm.experimental.constrained.fmul.f64(double 0x3BFFFFFFF0000000, double %235, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %237 = tail call double @llvm.experimental.constrained.fmul.f64(double %236, double %227, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %238 = tail call float @llvm.experimental.constrained.fptrunc.f32.f64(double %237, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %239 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0x3810000000000000, metadata !"fpexcept.strict") #4
  %240 = tail call double @llvm.experimental.constrained.fdiv.f64(double 0x10000000000000, double %239, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %241 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float %238, metadata !"fpexcept.strict") #4
  %242 = tail call double @llvm.experimental.constrained.fmul.f64(double %240, double %241, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %263

243:                                              ; preds = %231
  %244 = and i64 %220, 2047
  %245 = icmp eq i64 %244, 0
  br i1 %245, label %263, label %246

246:                                              ; preds = %243
  %247 = lshr i64 %220, 1
  %248 = and i64 %220, 1
  %249 = or i64 %248, %247
  %250 = or i64 %249, 4611686018427387904
  %251 = sub nsw i64 0, %250
  %252 = select i1 %224, i64 %250, i64 %251
  %253 = tail call double @llvm.experimental.constrained.sitofp.f64.i64(i64 %252, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %254 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 2, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %255 = fneg double %232
  %256 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %254, double %253, double %255, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %257 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0x3810000000000000, metadata !"fpexcept.strict") #4
  %258 = tail call double @llvm.experimental.constrained.fdiv.f64(double 0x10000000000000, double %257, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %259 = tail call double @llvm.experimental.constrained.fmul.f64(double %258, double %256, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %260 = tail call double @llvm.experimental.constrained.fmul.f64(double %259, double %259, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %261 = tail call double @llvm.experimental.constrained.fsub.f64(double %256, double %256, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %262 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %260, double %261, double %256, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %263

263:                                              ; preds = %246, %243, %234
  %264 = phi double [ %227, %234 ], [ %262, %246 ], [ %227, %243 ]
  %265 = phi double [ %242, %234 ], [ undef, %246 ], [ undef, %243 ]
  br i1 %233, label %278, label %275

266:                                              ; preds = %229
  %267 = and i64 %220, 1023
  %268 = icmp eq i64 %267, 0
  %269 = select i1 %268, i64 0, i64 1024
  %270 = and i64 %220, -1024
  %271 = or i64 %269, %270
  %272 = sub nsw i64 0, %271
  %273 = select i1 %224, i64 %271, i64 %272
  %274 = tail call double @llvm.experimental.constrained.sitofp.f64.i64(i64 %273, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %275

275:                                              ; preds = %266, %263, %219
  %276 = phi double [ %264, %263 ], [ %274, %266 ], [ %227, %219 ]
  %277 = tail call double @scalbn(double noundef %276, i32 noundef %223) #5
  br label %278

278:                                              ; preds = %275, %263, %217, %82, %80, %76
  %279 = phi double [ %77, %76 ], [ %83, %82 ], [ %2, %80 ], [ %218, %217 ], [ %277, %275 ], [ %265, %263 ]
  ret double %279
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctlz.i64(i64, i1 immarg) #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i64(i64, metadata, metadata) #0

attributes #0 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { strictfp }
attributes #5 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
