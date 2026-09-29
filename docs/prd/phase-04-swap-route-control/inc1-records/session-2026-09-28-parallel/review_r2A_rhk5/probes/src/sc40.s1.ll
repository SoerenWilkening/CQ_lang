; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5
  %4 = mul nsw i32 %3, 3
  %5 = xor i32 %4, %3
  %6 = icmp eq i32 %5, 10
  br i1 %6, label %7, label %8

7:                                                ; preds = %1
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %8

8:                                                ; preds = %7, %1
  %9 = tail call i32 @h(i32 noundef %0, i32 noundef %4) #5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %13 = add nsw i32 %0, 1
  %14 = and i32 %13, 7
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %16 = mul nsw i32 %15, 3
  %17 = xor i32 %16, %15
  %18 = icmp eq i32 %17, 11
  br i1 %18, label %19, label %20

19:                                               ; preds = %8
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %20

20:                                               ; preds = %19, %8
  %21 = tail call i32 @h(i32 noundef %0, i32 noundef %16) #5
  %22 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 0x3FE6666666666666) #5
  %23 = tail call i32 @cq_measure_si32(i32 noundef %21) #5
  %24 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  %25 = add nsw i32 %0, 2
  %26 = and i32 %25, 7
  %27 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 5.000000e-01) #5
  %28 = mul nsw i32 %27, 3
  %29 = xor i32 %28, %27
  %30 = icmp eq i32 %29, 12
  br i1 %30, label %31, label %32

31:                                               ; preds = %20
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %32

32:                                               ; preds = %31, %20
  %33 = tail call i32 @h(i32 noundef %0, i32 noundef %28) #5
  %34 = tail call i32 @cq_theta_si32(i32 noundef %27, double noundef 0x3FE6666666666666) #5
  %35 = tail call i32 @cq_measure_si32(i32 noundef %33) #5
  %36 = tail call i32 @cq_measure_si32(i32 noundef %34) #5
  %37 = add nsw i32 %0, 3
  %38 = and i32 %37, 7
  %39 = tail call i32 @cq_theta_si32(i32 noundef %38, double noundef 5.000000e-01) #5
  %40 = mul nsw i32 %39, 3
  %41 = xor i32 %40, %39
  %42 = icmp eq i32 %41, 13
  br i1 %42, label %43, label %44

43:                                               ; preds = %32
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %44

44:                                               ; preds = %43, %32
  %45 = tail call i32 @h(i32 noundef %0, i32 noundef %40) #5
  %46 = tail call i32 @cq_theta_si32(i32 noundef %39, double noundef 0x3FE6666666666666) #5
  %47 = tail call i32 @cq_measure_si32(i32 noundef %45) #5
  %48 = tail call i32 @cq_measure_si32(i32 noundef %46) #5
  %49 = xor i32 %2, 4
  %50 = tail call i32 @cq_theta_si32(i32 noundef %49, double noundef 5.000000e-01) #5
  %51 = mul nsw i32 %50, 3
  %52 = xor i32 %51, %50
  %53 = icmp eq i32 %52, 14
  br i1 %53, label %54, label %55

54:                                               ; preds = %44
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %55

55:                                               ; preds = %54, %44
  %56 = tail call i32 @h(i32 noundef %0, i32 noundef %51) #5
  %57 = tail call i32 @cq_theta_si32(i32 noundef %50, double noundef 0x3FE6666666666666) #5
  %58 = tail call i32 @cq_measure_si32(i32 noundef %56) #5
  %59 = tail call i32 @cq_measure_si32(i32 noundef %57) #5
  %60 = add nsw i32 %0, 5
  %61 = and i32 %60, 7
  %62 = tail call i32 @cq_theta_si32(i32 noundef %61, double noundef 5.000000e-01) #5
  %63 = mul nsw i32 %62, 3
  %64 = xor i32 %63, %62
  %65 = icmp eq i32 %64, 15
  br i1 %65, label %66, label %67

66:                                               ; preds = %55
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %67

67:                                               ; preds = %66, %55
  %68 = tail call i32 @h(i32 noundef %0, i32 noundef %63) #5
  %69 = tail call i32 @cq_theta_si32(i32 noundef %62, double noundef 0x3FE6666666666666) #5
  %70 = tail call i32 @cq_measure_si32(i32 noundef %68) #5
  %71 = tail call i32 @cq_measure_si32(i32 noundef %69) #5
  %72 = add nsw i32 %0, 6
  %73 = and i32 %72, 7
  %74 = tail call i32 @cq_theta_si32(i32 noundef %73, double noundef 5.000000e-01) #5
  %75 = mul nsw i32 %74, 3
  %76 = xor i32 %75, %74
  %77 = icmp eq i32 %76, 16
  br i1 %77, label %78, label %79

78:                                               ; preds = %67
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %79

79:                                               ; preds = %78, %67
  %80 = tail call i32 @h(i32 noundef %0, i32 noundef %75) #5
  %81 = tail call i32 @cq_theta_si32(i32 noundef %74, double noundef 0x3FE6666666666666) #5
  %82 = tail call i32 @cq_measure_si32(i32 noundef %80) #5
  %83 = tail call i32 @cq_measure_si32(i32 noundef %81) #5
  %84 = add nsw i32 %0, 7
  %85 = and i32 %84, 7
  %86 = tail call i32 @cq_theta_si32(i32 noundef %85, double noundef 5.000000e-01) #5
  %87 = mul nsw i32 %86, 3
  %88 = xor i32 %87, %86
  %89 = icmp eq i32 %88, 17
  br i1 %89, label %90, label %91

90:                                               ; preds = %79
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %91

91:                                               ; preds = %90, %79
  %92 = tail call i32 @h(i32 noundef %0, i32 noundef %87) #5
  %93 = tail call i32 @cq_theta_si32(i32 noundef %86, double noundef 0x3FE6666666666666) #5
  %94 = tail call i32 @cq_measure_si32(i32 noundef %92) #5
  %95 = tail call i32 @cq_measure_si32(i32 noundef %93) #5
  %96 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5
  %97 = mul nsw i32 %96, 3
  %98 = xor i32 %97, %96
  %99 = icmp eq i32 %98, 18
  br i1 %99, label %100, label %101

100:                                              ; preds = %91
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %101

101:                                              ; preds = %100, %91
  %102 = tail call i32 @h(i32 noundef %0, i32 noundef %97) #5
  %103 = tail call i32 @cq_theta_si32(i32 noundef %96, double noundef 0x3FE6666666666666) #5
  %104 = tail call i32 @cq_measure_si32(i32 noundef %102) #5
  %105 = tail call i32 @cq_measure_si32(i32 noundef %103) #5
  %106 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %107 = mul nsw i32 %106, 3
  %108 = xor i32 %107, %106
  %109 = icmp eq i32 %108, 19
  br i1 %109, label %110, label %111

110:                                              ; preds = %101
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %111

111:                                              ; preds = %110, %101
  %112 = tail call i32 @h(i32 noundef %0, i32 noundef %107) #5
  %113 = tail call i32 @cq_theta_si32(i32 noundef %106, double noundef 0x3FE6666666666666) #5
  %114 = tail call i32 @cq_measure_si32(i32 noundef %112) #5
  %115 = tail call i32 @cq_measure_si32(i32 noundef %113) #5
  %116 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 5.000000e-01) #5
  %117 = mul nsw i32 %116, 3
  %118 = xor i32 %117, %116
  %119 = icmp eq i32 %118, 20
  br i1 %119, label %120, label %121

120:                                              ; preds = %111
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %121

121:                                              ; preds = %120, %111
  %122 = tail call i32 @h(i32 noundef %0, i32 noundef %117) #5
  %123 = tail call i32 @cq_theta_si32(i32 noundef %116, double noundef 0x3FE6666666666666) #5
  %124 = tail call i32 @cq_measure_si32(i32 noundef %122) #5
  %125 = tail call i32 @cq_measure_si32(i32 noundef %123) #5
  %126 = tail call i32 @cq_theta_si32(i32 noundef %38, double noundef 5.000000e-01) #5
  %127 = mul nsw i32 %126, 3
  %128 = xor i32 %127, %126
  %129 = icmp eq i32 %128, 21
  br i1 %129, label %130, label %131

130:                                              ; preds = %121
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %131

131:                                              ; preds = %130, %121
  %132 = tail call i32 @h(i32 noundef %0, i32 noundef %127) #5
  %133 = tail call i32 @cq_theta_si32(i32 noundef %126, double noundef 0x3FE6666666666666) #5
  %134 = tail call i32 @cq_measure_si32(i32 noundef %132) #5
  %135 = tail call i32 @cq_measure_si32(i32 noundef %133) #5
  %136 = tail call i32 @cq_theta_si32(i32 noundef %49, double noundef 5.000000e-01) #5
  %137 = mul nsw i32 %136, 3
  %138 = xor i32 %137, %136
  %139 = icmp eq i32 %138, 22
  br i1 %139, label %140, label %141

140:                                              ; preds = %131
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %141

141:                                              ; preds = %140, %131
  %142 = tail call i32 @h(i32 noundef %0, i32 noundef %137) #5
  %143 = tail call i32 @cq_theta_si32(i32 noundef %136, double noundef 0x3FE6666666666666) #5
  %144 = tail call i32 @cq_measure_si32(i32 noundef %142) #5
  %145 = tail call i32 @cq_measure_si32(i32 noundef %143) #5
  %146 = tail call i32 @cq_theta_si32(i32 noundef %61, double noundef 5.000000e-01) #5
  %147 = mul nsw i32 %146, 3
  %148 = xor i32 %147, %146
  %149 = icmp eq i32 %148, 23
  br i1 %149, label %150, label %151

150:                                              ; preds = %141
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %151

151:                                              ; preds = %150, %141
  %152 = tail call i32 @h(i32 noundef %0, i32 noundef %147) #5
  %153 = tail call i32 @cq_theta_si32(i32 noundef %146, double noundef 0x3FE6666666666666) #5
  %154 = tail call i32 @cq_measure_si32(i32 noundef %152) #5
  %155 = tail call i32 @cq_measure_si32(i32 noundef %153) #5
  %156 = tail call i32 @cq_theta_si32(i32 noundef %73, double noundef 5.000000e-01) #5
  %157 = mul nsw i32 %156, 3
  %158 = xor i32 %157, %156
  %159 = icmp eq i32 %158, 24
  br i1 %159, label %160, label %161

160:                                              ; preds = %151
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %161

161:                                              ; preds = %160, %151
  %162 = tail call i32 @h(i32 noundef %0, i32 noundef %157) #5
  %163 = tail call i32 @cq_theta_si32(i32 noundef %156, double noundef 0x3FE6666666666666) #5
  %164 = tail call i32 @cq_measure_si32(i32 noundef %162) #5
  %165 = tail call i32 @cq_measure_si32(i32 noundef %163) #5
  %166 = tail call i32 @cq_theta_si32(i32 noundef %85, double noundef 5.000000e-01) #5
  %167 = mul nsw i32 %166, 3
  %168 = xor i32 %167, %166
  %169 = icmp eq i32 %168, 25
  br i1 %169, label %170, label %171

170:                                              ; preds = %161
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %171

171:                                              ; preds = %170, %161
  %172 = tail call i32 @h(i32 noundef %0, i32 noundef %167) #5
  %173 = tail call i32 @cq_theta_si32(i32 noundef %166, double noundef 0x3FE6666666666666) #5
  %174 = tail call i32 @cq_measure_si32(i32 noundef %172) #5
  %175 = tail call i32 @cq_measure_si32(i32 noundef %173) #5
  %176 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5
  %177 = mul nsw i32 %176, 3
  %178 = xor i32 %177, %176
  %179 = icmp eq i32 %178, 26
  br i1 %179, label %180, label %181

180:                                              ; preds = %171
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %181

181:                                              ; preds = %180, %171
  %182 = tail call i32 @h(i32 noundef %0, i32 noundef %177) #5
  %183 = tail call i32 @cq_theta_si32(i32 noundef %176, double noundef 0x3FE6666666666666) #5
  %184 = tail call i32 @cq_measure_si32(i32 noundef %182) #5
  %185 = tail call i32 @cq_measure_si32(i32 noundef %183) #5
  %186 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %187 = mul nsw i32 %186, 3
  %188 = xor i32 %187, %186
  %189 = icmp eq i32 %188, 27
  br i1 %189, label %190, label %191

190:                                              ; preds = %181
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %191

191:                                              ; preds = %190, %181
  %192 = tail call i32 @h(i32 noundef %0, i32 noundef %187) #5
  %193 = tail call i32 @cq_theta_si32(i32 noundef %186, double noundef 0x3FE6666666666666) #5
  %194 = tail call i32 @cq_measure_si32(i32 noundef %192) #5
  %195 = tail call i32 @cq_measure_si32(i32 noundef %193) #5
  %196 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 5.000000e-01) #5
  %197 = mul nsw i32 %196, 3
  %198 = xor i32 %197, %196
  %199 = icmp eq i32 %198, 28
  br i1 %199, label %200, label %201

200:                                              ; preds = %191
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %201

201:                                              ; preds = %200, %191
  %202 = tail call i32 @h(i32 noundef %0, i32 noundef %197) #5
  %203 = tail call i32 @cq_theta_si32(i32 noundef %196, double noundef 0x3FE6666666666666) #5
  %204 = tail call i32 @cq_measure_si32(i32 noundef %202) #5
  %205 = tail call i32 @cq_measure_si32(i32 noundef %203) #5
  %206 = tail call i32 @cq_theta_si32(i32 noundef %38, double noundef 5.000000e-01) #5
  %207 = mul nsw i32 %206, 3
  %208 = xor i32 %207, %206
  %209 = icmp eq i32 %208, 29
  br i1 %209, label %210, label %211

210:                                              ; preds = %201
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %211

211:                                              ; preds = %210, %201
  %212 = tail call i32 @h(i32 noundef %0, i32 noundef %207) #5
  %213 = tail call i32 @cq_theta_si32(i32 noundef %206, double noundef 0x3FE6666666666666) #5
  %214 = tail call i32 @cq_measure_si32(i32 noundef %212) #5
  %215 = tail call i32 @cq_measure_si32(i32 noundef %213) #5
  %216 = tail call i32 @cq_theta_si32(i32 noundef %49, double noundef 5.000000e-01) #5
  %217 = mul nsw i32 %216, 3
  %218 = xor i32 %217, %216
  %219 = icmp eq i32 %218, 30
  br i1 %219, label %220, label %221

220:                                              ; preds = %211
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %221

221:                                              ; preds = %220, %211
  %222 = tail call i32 @h(i32 noundef %0, i32 noundef %217) #5
  %223 = tail call i32 @cq_theta_si32(i32 noundef %216, double noundef 0x3FE6666666666666) #5
  %224 = tail call i32 @cq_measure_si32(i32 noundef %222) #5
  %225 = tail call i32 @cq_measure_si32(i32 noundef %223) #5
  %226 = tail call i32 @cq_theta_si32(i32 noundef %61, double noundef 5.000000e-01) #5
  %227 = mul nsw i32 %226, 3
  %228 = xor i32 %227, %226
  %229 = icmp eq i32 %228, 31
  br i1 %229, label %230, label %231

230:                                              ; preds = %221
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %231

231:                                              ; preds = %230, %221
  %232 = tail call i32 @h(i32 noundef %0, i32 noundef %227) #5
  %233 = tail call i32 @cq_theta_si32(i32 noundef %226, double noundef 0x3FE6666666666666) #5
  %234 = tail call i32 @cq_measure_si32(i32 noundef %232) #5
  %235 = tail call i32 @cq_measure_si32(i32 noundef %233) #5
  %236 = tail call i32 @cq_theta_si32(i32 noundef %73, double noundef 5.000000e-01) #5
  %237 = mul nsw i32 %236, 3
  %238 = xor i32 %237, %236
  %239 = icmp eq i32 %238, 32
  br i1 %239, label %240, label %241

240:                                              ; preds = %231
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %241

241:                                              ; preds = %240, %231
  %242 = tail call i32 @h(i32 noundef %0, i32 noundef %237) #5
  %243 = tail call i32 @cq_theta_si32(i32 noundef %236, double noundef 0x3FE6666666666666) #5
  %244 = tail call i32 @cq_measure_si32(i32 noundef %242) #5
  %245 = tail call i32 @cq_measure_si32(i32 noundef %243) #5
  %246 = tail call i32 @cq_theta_si32(i32 noundef %85, double noundef 5.000000e-01) #5
  %247 = mul nsw i32 %246, 3
  %248 = xor i32 %247, %246
  %249 = icmp eq i32 %248, 33
  br i1 %249, label %250, label %251

250:                                              ; preds = %241
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %251

251:                                              ; preds = %250, %241
  %252 = tail call i32 @h(i32 noundef %0, i32 noundef %247) #5
  %253 = tail call i32 @cq_theta_si32(i32 noundef %246, double noundef 0x3FE6666666666666) #5
  %254 = tail call i32 @cq_measure_si32(i32 noundef %252) #5
  %255 = tail call i32 @cq_measure_si32(i32 noundef %253) #5
  %256 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5
  %257 = mul nsw i32 %256, 3
  %258 = xor i32 %257, %256
  %259 = icmp eq i32 %258, 34
  br i1 %259, label %260, label %261

260:                                              ; preds = %251
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %261

261:                                              ; preds = %260, %251
  %262 = tail call i32 @h(i32 noundef %0, i32 noundef %257) #5
  %263 = tail call i32 @cq_theta_si32(i32 noundef %256, double noundef 0x3FE6666666666666) #5
  %264 = tail call i32 @cq_measure_si32(i32 noundef %262) #5
  %265 = tail call i32 @cq_measure_si32(i32 noundef %263) #5
  %266 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %267 = mul nsw i32 %266, 3
  %268 = xor i32 %267, %266
  %269 = icmp eq i32 %268, 35
  br i1 %269, label %270, label %271

270:                                              ; preds = %261
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %271

271:                                              ; preds = %270, %261
  %272 = tail call i32 @h(i32 noundef %0, i32 noundef %267) #5
  %273 = tail call i32 @cq_theta_si32(i32 noundef %266, double noundef 0x3FE6666666666666) #5
  %274 = tail call i32 @cq_measure_si32(i32 noundef %272) #5
  %275 = tail call i32 @cq_measure_si32(i32 noundef %273) #5
  %276 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 5.000000e-01) #5
  %277 = mul nsw i32 %276, 3
  %278 = xor i32 %277, %276
  %279 = icmp eq i32 %278, 36
  br i1 %279, label %280, label %281

280:                                              ; preds = %271
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %281

281:                                              ; preds = %280, %271
  %282 = tail call i32 @h(i32 noundef %0, i32 noundef %277) #5
  %283 = tail call i32 @cq_theta_si32(i32 noundef %276, double noundef 0x3FE6666666666666) #5
  %284 = tail call i32 @cq_measure_si32(i32 noundef %282) #5
  %285 = tail call i32 @cq_measure_si32(i32 noundef %283) #5
  %286 = tail call i32 @cq_theta_si32(i32 noundef %38, double noundef 5.000000e-01) #5
  %287 = mul nsw i32 %286, 3
  %288 = xor i32 %287, %286
  %289 = icmp eq i32 %288, 37
  br i1 %289, label %290, label %291

290:                                              ; preds = %281
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %291

291:                                              ; preds = %290, %281
  %292 = tail call i32 @h(i32 noundef %0, i32 noundef %287) #5
  %293 = tail call i32 @cq_theta_si32(i32 noundef %286, double noundef 0x3FE6666666666666) #5
  %294 = tail call i32 @cq_measure_si32(i32 noundef %292) #5
  %295 = tail call i32 @cq_measure_si32(i32 noundef %293) #5
  %296 = tail call i32 @cq_theta_si32(i32 noundef %49, double noundef 5.000000e-01) #5
  %297 = mul nsw i32 %296, 3
  %298 = xor i32 %297, %296
  %299 = icmp eq i32 %298, 38
  br i1 %299, label %300, label %301

300:                                              ; preds = %291
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %301

301:                                              ; preds = %300, %291
  %302 = tail call i32 @h(i32 noundef %0, i32 noundef %297) #5
  %303 = tail call i32 @cq_theta_si32(i32 noundef %296, double noundef 0x3FE6666666666666) #5
  %304 = tail call i32 @cq_measure_si32(i32 noundef %302) #5
  %305 = tail call i32 @cq_measure_si32(i32 noundef %303) #5
  %306 = tail call i32 @cq_theta_si32(i32 noundef %61, double noundef 5.000000e-01) #5
  %307 = mul nsw i32 %306, 3
  %308 = xor i32 %307, %306
  %309 = icmp eq i32 %308, 39
  br i1 %309, label %310, label %311

310:                                              ; preds = %301
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %311

311:                                              ; preds = %310, %301
  %312 = tail call i32 @h(i32 noundef %0, i32 noundef %307) #5
  %313 = tail call i32 @cq_theta_si32(i32 noundef %306, double noundef 0x3FE6666666666666) #5
  %314 = tail call i32 @cq_measure_si32(i32 noundef %312) #5
  %315 = tail call i32 @cq_measure_si32(i32 noundef %313) #5
  %316 = tail call i32 @cq_theta_si32(i32 noundef %73, double noundef 5.000000e-01) #5
  %317 = mul nsw i32 %316, 3
  %318 = xor i32 %317, %316
  %319 = icmp eq i32 %318, 40
  br i1 %319, label %320, label %321

320:                                              ; preds = %311
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %321

321:                                              ; preds = %320, %311
  %322 = tail call i32 @h(i32 noundef %0, i32 noundef %317) #5
  %323 = tail call i32 @cq_theta_si32(i32 noundef %316, double noundef 0x3FE6666666666666) #5
  %324 = tail call i32 @cq_measure_si32(i32 noundef %322) #5
  %325 = tail call i32 @cq_measure_si32(i32 noundef %323) #5
  %326 = tail call i32 @cq_theta_si32(i32 noundef %85, double noundef 5.000000e-01) #5
  %327 = mul nsw i32 %326, 3
  %328 = xor i32 %327, %326
  %329 = icmp eq i32 %328, 41
  br i1 %329, label %330, label %331

330:                                              ; preds = %321
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %331

331:                                              ; preds = %330, %321
  %332 = tail call i32 @h(i32 noundef %0, i32 noundef %327) #5
  %333 = tail call i32 @cq_theta_si32(i32 noundef %326, double noundef 0x3FE6666666666666) #5
  %334 = tail call i32 @cq_measure_si32(i32 noundef %332) #5
  %335 = tail call i32 @cq_measure_si32(i32 noundef %333) #5
  %336 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5
  %337 = mul nsw i32 %336, 3
  %338 = xor i32 %337, %336
  %339 = icmp eq i32 %338, 42
  br i1 %339, label %340, label %341

340:                                              ; preds = %331
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %341

341:                                              ; preds = %340, %331
  %342 = tail call i32 @h(i32 noundef %0, i32 noundef %337) #5
  %343 = tail call i32 @cq_theta_si32(i32 noundef %336, double noundef 0x3FE6666666666666) #5
  %344 = tail call i32 @cq_measure_si32(i32 noundef %342) #5
  %345 = tail call i32 @cq_measure_si32(i32 noundef %343) #5
  %346 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %347 = mul nsw i32 %346, 3
  %348 = xor i32 %347, %346
  %349 = icmp eq i32 %348, 43
  br i1 %349, label %350, label %351

350:                                              ; preds = %341
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %351

351:                                              ; preds = %350, %341
  %352 = tail call i32 @h(i32 noundef %0, i32 noundef %347) #5
  %353 = tail call i32 @cq_theta_si32(i32 noundef %346, double noundef 0x3FE6666666666666) #5
  %354 = tail call i32 @cq_measure_si32(i32 noundef %352) #5
  %355 = tail call i32 @cq_measure_si32(i32 noundef %353) #5
  %356 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 5.000000e-01) #5
  %357 = mul nsw i32 %356, 3
  %358 = xor i32 %357, %356
  %359 = icmp eq i32 %358, 44
  br i1 %359, label %360, label %361

360:                                              ; preds = %351
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %361

361:                                              ; preds = %360, %351
  %362 = tail call i32 @h(i32 noundef %0, i32 noundef %357) #5
  %363 = tail call i32 @cq_theta_si32(i32 noundef %356, double noundef 0x3FE6666666666666) #5
  %364 = tail call i32 @cq_measure_si32(i32 noundef %362) #5
  %365 = tail call i32 @cq_measure_si32(i32 noundef %363) #5
  %366 = tail call i32 @cq_theta_si32(i32 noundef %38, double noundef 5.000000e-01) #5
  %367 = mul nsw i32 %366, 3
  %368 = xor i32 %367, %366
  %369 = icmp eq i32 %368, 45
  br i1 %369, label %370, label %371

370:                                              ; preds = %361
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %371

371:                                              ; preds = %370, %361
  %372 = tail call i32 @h(i32 noundef %0, i32 noundef %367) #5
  %373 = tail call i32 @cq_theta_si32(i32 noundef %366, double noundef 0x3FE6666666666666) #5
  %374 = tail call i32 @cq_measure_si32(i32 noundef %372) #5
  %375 = tail call i32 @cq_measure_si32(i32 noundef %373) #5
  %376 = tail call i32 @cq_theta_si32(i32 noundef %49, double noundef 5.000000e-01) #5
  %377 = mul nsw i32 %376, 3
  %378 = xor i32 %377, %376
  %379 = icmp eq i32 %378, 46
  br i1 %379, label %380, label %381

380:                                              ; preds = %371
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %381

381:                                              ; preds = %380, %371
  %382 = tail call i32 @h(i32 noundef %0, i32 noundef %377) #5
  %383 = tail call i32 @cq_theta_si32(i32 noundef %376, double noundef 0x3FE6666666666666) #5
  %384 = tail call i32 @cq_measure_si32(i32 noundef %382) #5
  %385 = tail call i32 @cq_measure_si32(i32 noundef %383) #5
  %386 = tail call i32 @cq_theta_si32(i32 noundef %61, double noundef 5.000000e-01) #5
  %387 = mul nsw i32 %386, 3
  %388 = xor i32 %387, %386
  %389 = icmp eq i32 %388, 47
  br i1 %389, label %390, label %391

390:                                              ; preds = %381
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %391

391:                                              ; preds = %390, %381
  %392 = tail call i32 @h(i32 noundef %0, i32 noundef %387) #5
  %393 = tail call i32 @cq_theta_si32(i32 noundef %386, double noundef 0x3FE6666666666666) #5
  %394 = tail call i32 @cq_measure_si32(i32 noundef %392) #5
  %395 = tail call i32 @cq_measure_si32(i32 noundef %393) #5
  %396 = tail call i32 @cq_theta_si32(i32 noundef %73, double noundef 5.000000e-01) #5
  %397 = mul nsw i32 %396, 3
  %398 = xor i32 %397, %396
  %399 = icmp eq i32 %398, 48
  br i1 %399, label %400, label %401

400:                                              ; preds = %391
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %401

401:                                              ; preds = %400, %391
  %402 = tail call i32 @h(i32 noundef %0, i32 noundef %397) #5
  %403 = tail call i32 @cq_theta_si32(i32 noundef %396, double noundef 0x3FE6666666666666) #5
  %404 = tail call i32 @cq_measure_si32(i32 noundef %402) #5
  %405 = tail call i32 @cq_measure_si32(i32 noundef %403) #5
  %406 = tail call i32 @cq_theta_si32(i32 noundef %85, double noundef 5.000000e-01) #5
  %407 = mul nsw i32 %406, 3
  %408 = xor i32 %407, %406
  %409 = icmp eq i32 %408, 49
  br i1 %409, label %410, label %411

410:                                              ; preds = %401
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %411

411:                                              ; preds = %410, %401
  %412 = tail call i32 @h(i32 noundef %0, i32 noundef %407) #5
  %413 = tail call i32 @cq_theta_si32(i32 noundef %406, double noundef 0x3FE6666666666666) #5
  %414 = tail call i32 @cq_measure_si32(i32 noundef %412) #5
  %415 = tail call i32 @cq_measure_si32(i32 noundef %413) #5
  %416 = add i32 %12, %11
  %417 = add i32 %416, %23
  %418 = add i32 %417, %24
  %419 = add i32 %418, %35
  %420 = add i32 %419, %36
  %421 = add i32 %420, %47
  %422 = add i32 %421, %48
  %423 = add i32 %422, %58
  %424 = add i32 %423, %59
  %425 = add i32 %424, %70
  %426 = add i32 %425, %71
  %427 = add i32 %426, %82
  %428 = add i32 %427, %83
  %429 = add i32 %428, %94
  %430 = add i32 %429, %95
  %431 = add i32 %430, %104
  %432 = add i32 %431, %105
  %433 = add i32 %432, %114
  %434 = add i32 %433, %115
  %435 = add i32 %434, %124
  %436 = add i32 %435, %125
  %437 = add i32 %436, %134
  %438 = add i32 %437, %135
  %439 = add i32 %438, %144
  %440 = add i32 %439, %145
  %441 = add i32 %440, %154
  %442 = add i32 %441, %155
  %443 = add i32 %442, %164
  %444 = add i32 %443, %165
  %445 = add i32 %444, %174
  %446 = add i32 %445, %175
  %447 = add i32 %446, %184
  %448 = add i32 %447, %185
  %449 = add i32 %448, %194
  %450 = add i32 %449, %195
  %451 = add i32 %450, %204
  %452 = add i32 %451, %205
  %453 = add i32 %452, %214
  %454 = add i32 %453, %215
  %455 = add i32 %454, %224
  %456 = add i32 %455, %225
  %457 = add i32 %456, %234
  %458 = add i32 %457, %235
  %459 = add i32 %458, %244
  %460 = add i32 %459, %245
  %461 = add i32 %460, %254
  %462 = add i32 %461, %255
  %463 = add i32 %462, %264
  %464 = add i32 %463, %265
  %465 = add i32 %464, %274
  %466 = add i32 %465, %275
  %467 = add i32 %466, %284
  %468 = add i32 %467, %285
  %469 = add i32 %468, %294
  %470 = add i32 %469, %295
  %471 = add i32 %470, %304
  %472 = add i32 %471, %305
  %473 = add i32 %472, %314
  %474 = add i32 %473, %315
  %475 = add i32 %474, %324
  %476 = add i32 %475, %325
  %477 = add i32 %476, %334
  %478 = add i32 %477, %335
  %479 = add i32 %478, %344
  %480 = add i32 %479, %345
  %481 = add i32 %480, %354
  %482 = add i32 %481, %355
  %483 = add i32 %482, %364
  %484 = add i32 %483, %365
  %485 = add i32 %484, %374
  %486 = add i32 %485, %375
  %487 = add i32 %486, %384
  %488 = add i32 %487, %385
  %489 = add i32 %488, %394
  %490 = add i32 %489, %395
  %491 = add i32 %490, %404
  %492 = add i32 %491, %405
  %493 = add i32 %492, %414
  %494 = add i32 %493, %415
  ret i32 %494
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @slice(i32 noundef %5)
  %7 = and i32 %6, 1
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
