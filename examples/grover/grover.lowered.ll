; ModuleID = '<stdin>'
source_filename = "examples/grover/grover.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_grover = internal global i32 0, align 4
@__cq_act_grover_3 = internal global i32 0, align 4
@__cq_act_grover_4 = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [15 x i8] c"i32 (i32, i32)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [7 x i8] c"i32 ()\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @grover(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 16, i64 16)
  %5 = add i32 %0, -17
  %6 = icmp ult i32 %5, -16
  br i1 %6, label %7, label %9

7:                                                ; preds = %181, %9, %2
  %8 = phi i32 [ %182, %181 ], [ -1, %9 ], [ -1, %2 ]
  ret i32 %8

9:                                                ; preds = %2
  %10 = shl nuw nsw i32 1, %0
  %11 = icmp ugt i32 %10, %1
  br i1 %11, label %12, label %7

12:                                               ; preds = %9
  %13 = uitofp nneg i32 %10 to double
  %14 = tail call double @llvm.sqrt.f64(double %13)
  %15 = fmul double %14, 0x3FE921FB54442D18
  %16 = tail call double @llvm.floor.f64(double %15)
  %17 = fptosi double %16 to i32
  %18 = ptrtoint ptr %4 to i64
  %19 = call i32 @cqrt_alloc_i8(i8 0)
  br label %20

20:                                               ; preds = %20, %12
  %21 = phi i64 [ 0, %12 ], [ %23, %20 ]
  %22 = add i64 %18, %21
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %22, i32 %19)
  %23 = add nuw i64 %21, 1
  %24 = icmp eq i64 %23, 16
  br i1 %24, label %25, label %20

25:                                               ; preds = %20
  %26 = icmp sgt i32 %0, 0
  br i1 %26, label %27, label %29

27:                                               ; preds = %25
  %28 = zext nneg i32 %0 to i64
  br label %31

29:                                               ; preds = %40, %25
  %30 = icmp sgt i32 %17, 0
  br i1 %30, label %43, label %48

31:                                               ; preds = %27
  br label %33

32:                                               ; preds = %33
  br label %41

33:                                               ; preds = %33, %31
  %from = phi i32 [ 0, %33 ], [ 1, %31 ]
  %34 = phi i64 [ 0, %31 ], [ %38, %33 ]
  call void @cqrt_push(i32 %from)
  %35 = getelementptr inbounds i8, ptr %4, i64 %34
  %36 = ptrtoint ptr %35 to i64
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %36, i32 %37)
  call void @cqrt_ry_i1(i32 %37, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %36, i32 %37)
  call void @cqrt_free(i32 %37)
  %38 = add nuw nsw i64 %34, 1
  %39 = icmp eq i64 %38, %28
  br i1 %39, label %32, label %33

40:                                               ; preds = %41
  br label %29

41:                                               ; preds = %32, %41
  %42 = call i32 @cqrt_pop()
  switch i32 %42, label %41 [
    i32 1, label %40
  ]

43:                                               ; preds = %29
  %44 = zext nneg i32 %0 to i64
  %45 = zext nneg i32 %0 to i64
  %46 = zext nneg i32 %0 to i64
  %47 = zext nneg i32 %0 to i64
  br label %50

48:                                               ; preds = %158, %29
  %49 = icmp sgt i32 %0, 0
  br i1 %49, label %179, label %181

50:                                               ; preds = %43
  br label %52

51:                                               ; preds = %114
  br label %177

52:                                               ; preds = %114, %50
  %from15 = phi i32 [ 0, %114 ], [ 1, %50 ]
  %53 = phi i32 [ 0, %50 ], [ %115, %114 ]
  call void @cqrt_push(i32 %from15)
  %54 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %54)
  br i1 %26, label %55, label %57

55:                                               ; preds = %52
  %56 = call i32 @cqrt_alloc_i32(i32 0)
  br label %63

57:                                               ; preds = %52, %78
  %from14 = phi i32 [ 0, %52 ], [ 1, %78 ]
  %58 = phi i32 [ poison, %52 ], [ %56, %78 ]
  %ran = phi i1 [ false, %52 ], [ true, %78 ]
  %59 = phi i32 [ %54, %52 ], [ %72, %78 ]
  %60 = call i32 @cq_template_icmp_eq_i32_hl(i32 %59, i32 %1)
  call void @cqrt_rz_i1(i32 %60, double 0x400921FB54442D18)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %60, i32 %59, i32 %1)
  call void @cqrt_free(i32 %60)
  br i1 %ran, label %125, label %140

61:                                               ; preds = %140
  call void @cqrt_push(i32 %from14)
  call void @cqrt_invert_begin()
  br i1 %26, label %79, label %80

62:                                               ; preds = %63
  br label %78

63:                                               ; preds = %63, %55
  %from1 = phi i32 [ 0, %63 ], [ 1, %55 ]
  %64 = phi i64 [ 0, %55 ], [ %73, %63 ]
  %65 = phi i32 [ %56, %55 ], [ %72, %63 ]
  call void @cqrt_push(i32 %from1)
  %66 = getelementptr inbounds i8, ptr %4, i64 %64
  %67 = ptrtoint ptr %66 to i64
  %68 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %67)
  %69 = call i32 @cq_template_zext_i8_to_i32(i32 %68)
  %70 = trunc nuw nsw i64 %64 to i32
  %71 = call i32 @cq_template_shl_i32_hl(i32 %69, i32 %70)
  %72 = call i32 @cq_template_or_i32(i32 %71, i32 %65)
  %73 = add nuw nsw i64 %64, 1
  %74 = icmp eq i64 %73, %44
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %68)
  %75 = trunc i64 %67 to i32
  call void @cqrt_push(i32 %75)
  %76 = lshr i64 %67, 32
  %77 = trunc i64 %76 to i32
  call void @cqrt_push(i32 %77)
  br i1 %74, label %62, label %63

78:                                               ; preds = %62
  br label %57

79:                                               ; preds = %61
  br label %82

80:                                               ; preds = %82, %61
  %from12 = phi i32 [ 0, %82 ], [ 1, %61 ]
  call void @cqrt_push(i32 %from12)
  call void @cqrt_invert_end()
  %81 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %81)
  br i1 %26, label %89, label %91

82:                                               ; preds = %82, %79
  %from13 = phi i32 [ 0, %82 ], [ 1, %79 ]
  %83 = phi i64 [ 0, %79 ], [ %87, %82 ]
  call void @cqrt_push(i32 %from13)
  %84 = getelementptr inbounds i8, ptr %4, i64 %83
  %85 = ptrtoint ptr %84 to i64
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %85, i32 %86)
  call void @cqrt_ry_i1(i32 %86, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %85, i32 %86)
  call void @cqrt_free(i32 %86)
  %87 = add nuw nsw i64 %83, 1
  %88 = icmp eq i64 %87, %45
  br i1 %88, label %80, label %82

89:                                               ; preds = %80
  %90 = call i32 @cqrt_alloc_i32(i32 0)
  br label %97

91:                                               ; preds = %80, %112
  %from11 = phi i32 [ 0, %80 ], [ 1, %112 ]
  %92 = phi i32 [ poison, %80 ], [ %90, %112 ]
  %ran3 = phi i1 [ false, %80 ], [ true, %112 ]
  %93 = phi i32 [ %81, %80 ], [ %106, %112 ]
  %94 = call i32 @cq_template_icmp_eq_i32_hl(i32 %93, i32 0)
  call void @cqrt_not_i1(i32 %94)
  call void @cqrt_rz_i1(i32 %94, double 0x400921FB54442D18)
  call void @cqrt_not_i1(i32 %94)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %94, i32 %93, i32 0)
  call void @cqrt_free(i32 %94)
  br i1 %ran3, label %142, label %157

95:                                               ; preds = %157
  call void @cqrt_push(i32 %from11)
  br i1 %26, label %113, label %114

96:                                               ; preds = %97
  br label %112

97:                                               ; preds = %97, %89
  %from2 = phi i32 [ 0, %97 ], [ 1, %89 ]
  %98 = phi i64 [ 0, %89 ], [ %107, %97 ]
  %99 = phi i32 [ %90, %89 ], [ %106, %97 ]
  call void @cqrt_push(i32 %from2)
  %100 = getelementptr inbounds i8, ptr %4, i64 %98
  %101 = ptrtoint ptr %100 to i64
  %102 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %101)
  %103 = call i32 @cq_template_zext_i8_to_i32(i32 %102)
  %104 = trunc nuw nsw i64 %98 to i32
  %105 = call i32 @cq_template_shl_i32_hl(i32 %103, i32 %104)
  %106 = call i32 @cq_template_or_i32(i32 %105, i32 %99)
  %107 = add nuw nsw i64 %98, 1
  %108 = icmp eq i64 %107, %46
  call void @cqrt_push(i32 %106)
  call void @cqrt_push(i32 %105)
  call void @cqrt_push(i32 %99)
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %104)
  call void @cqrt_push(i32 %102)
  %109 = trunc i64 %101 to i32
  call void @cqrt_push(i32 %109)
  %110 = lshr i64 %101, 32
  %111 = trunc i64 %110 to i32
  call void @cqrt_push(i32 %111)
  br i1 %108, label %96, label %97

112:                                              ; preds = %96
  br label %91

113:                                              ; preds = %95
  br label %117

114:                                              ; preds = %117, %95
  %from9 = phi i32 [ 0, %117 ], [ 1, %95 ]
  call void @cqrt_push(i32 %from9)
  %115 = add nuw nsw i32 %53, 1
  %116 = icmp eq i32 %115, %17
  br i1 %116, label %51, label %52

117:                                              ; preds = %117, %113
  %from10 = phi i32 [ 0, %117 ], [ 1, %113 ]
  %118 = phi i64 [ 0, %113 ], [ %122, %117 ]
  call void @cqrt_push(i32 %from10)
  %119 = getelementptr inbounds i8, ptr %4, i64 %118
  %120 = ptrtoint ptr %119 to i64
  %121 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %120, i32 %121)
  call void @cqrt_ry_i1(i32 %121, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %120, i32 %121)
  call void @cqrt_free(i32 %121)
  %122 = add nuw nsw i64 %118, 1
  %123 = icmp eq i64 %122, %47
  br i1 %123, label %114, label %117

124:                                              ; preds = %125
  call void @cqrt_free(i32 %58)
  br label %140

125:                                              ; preds = %57, %125
  %126 = call i32 @cqrt_pop()
  %127 = zext i32 %126 to i64
  %128 = shl i64 %127, 32
  %129 = or i64 0, %128
  %130 = call i32 @cqrt_pop()
  %131 = zext i32 %130 to i64
  %132 = or i64 %129, %131
  %133 = call i32 @cqrt_pop()
  %134 = call i32 @cqrt_pop()
  %135 = call i32 @cqrt_pop()
  %136 = call i32 @cqrt_pop()
  %137 = call i32 @cqrt_pop()
  %138 = call i32 @cqrt_pop()
  call void @cq_template_or_i32_unc(i32 %138, i32 %137, i32 %136)
  call void @cqrt_free(i32 %138)
  call void @cq_template_shl_i32_hl_unc(i32 %137, i32 %135, i32 %134)
  call void @cqrt_free(i32 %137)
  call void @cq_template_zext_i8_to_i32_unc(i32 %135, i32 %133)
  call void @cqrt_free(i32 %135)
  call void @cqrt_qram_load_i8_hl_unc(i32 %133, i32 %3, i64 %132)
  call void @cqrt_free(i32 %133)
  %139 = call i32 @cqrt_pop()
  switch i32 %139, label %125 [
    i32 1, label %124
  ]

140:                                              ; preds = %124, %57
  br label %61

141:                                              ; preds = %142
  call void @cqrt_free(i32 %92)
  br label %157

142:                                              ; preds = %91, %142
  %143 = call i32 @cqrt_pop()
  %144 = zext i32 %143 to i64
  %145 = shl i64 %144, 32
  %146 = or i64 0, %145
  %147 = call i32 @cqrt_pop()
  %148 = zext i32 %147 to i64
  %149 = or i64 %146, %148
  %150 = call i32 @cqrt_pop()
  %151 = call i32 @cqrt_pop()
  %152 = call i32 @cqrt_pop()
  %153 = call i32 @cqrt_pop()
  %154 = call i32 @cqrt_pop()
  %155 = call i32 @cqrt_pop()
  call void @cq_template_or_i32_unc(i32 %155, i32 %154, i32 %153)
  call void @cqrt_free(i32 %155)
  call void @cq_template_shl_i32_hl_unc(i32 %154, i32 %152, i32 %151)
  call void @cqrt_free(i32 %154)
  call void @cq_template_zext_i8_to_i32_unc(i32 %152, i32 %150)
  call void @cqrt_free(i32 %152)
  call void @cqrt_qram_load_i8_hl_unc(i32 %150, i32 %3, i64 %149)
  call void @cqrt_free(i32 %150)
  %156 = call i32 @cqrt_pop()
  switch i32 %156, label %142 [
    i32 1, label %141
  ]

157:                                              ; preds = %141, %91
  br label %95

158:                                              ; preds = %159
  br label %48

159:                                              ; preds = %162, %163
  %160 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %160)
  %161 = call i32 @cqrt_pop()
  switch i32 %161, label %177 [
    i32 1, label %158
  ]

162:                                              ; preds = %163
  br label %159

163:                                              ; preds = %165, %168
  %164 = call i32 @cqrt_pop()
  switch i32 %164, label %159 [
    i32 1, label %162
  ]

165:                                              ; preds = %166
  br label %163

166:                                              ; preds = %166, %168
  %167 = call i32 @cqrt_pop()
  switch i32 %167, label %166 [
    i32 1, label %165
  ]

168:                                              ; preds = %171, %172
  %169 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %169)
  %170 = call i32 @cqrt_pop()
  switch i32 %170, label %166 [
    i32 1, label %163
  ]

171:                                              ; preds = %172
  br label %168

172:                                              ; preds = %174, %177
  %173 = call i32 @cqrt_pop()
  switch i32 %173, label %168 [
    i32 1, label %171
  ]

174:                                              ; preds = %175
  br label %172

175:                                              ; preds = %175, %177
  %176 = call i32 @cqrt_pop()
  switch i32 %176, label %175 [
    i32 1, label %174
  ]

177:                                              ; preds = %51, %159
  %178 = call i32 @cqrt_pop()
  switch i32 %178, label %175 [
    i32 1, label %172
  ]

179:                                              ; preds = %48
  %180 = zext nneg i32 %0 to i64
  br label %183

181:                                              ; preds = %198, %48
  %182 = phi i32 [ 0, %48 ], [ %195, %198 ]
  br label %7

183:                                              ; preds = %179
  br label %185

184:                                              ; preds = %185
  br label %199

185:                                              ; preds = %185, %183
  %from16 = phi i32 [ 0, %185 ], [ 1, %183 ]
  %186 = phi i64 [ 0, %183 ], [ %196, %185 ]
  %187 = phi i32 [ 0, %183 ], [ %195, %185 ]
  call void @cqrt_push(i32 %from16)
  %188 = getelementptr inbounds [16 x i8], ptr %4, i64 0, i64 %186
  %189 = ptrtoint ptr %188 to i64
  %190 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %189)
  %191 = call i1 @cqrt_measure_i1(i32 %190), !cq.measure !6
  %192 = zext i1 %191 to i32
  %193 = trunc nuw nsw i64 %186 to i32
  %194 = shl nuw nsw i32 %192, %193
  %195 = or i32 %194, %187
  %196 = add nuw nsw i64 %186, 1
  %197 = icmp eq i64 %196, %180
  br i1 %197, label %184, label %185

198:                                              ; preds = %199
  br label %181

199:                                              ; preds = %184, %199
  %200 = call i32 @cqrt_pop()
  switch i32 %200, label %199 [
    i32 1, label %198
  ]
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @grover_3() local_unnamed_addr #0 {
  %1 = tail call i32 @grover(i32 noundef 3, i32 noundef 5)
  ret i32 %1
}

; Function Attrs: nounwind ssp uwtable
define i32 @grover_4() local_unnamed_addr #0 {
  %1 = tail call i32 @grover(i32 noundef 4, i32 noundef 11)
  ret i32 %1
}

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i8(i8)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_free(i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare i32 @cq_template_zext_i8_to_i32(i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_or_i32(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare void @cqrt_invert_begin()

declare void @cqrt_invert_end()

declare void @cqrt_not_i1(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_or_i32_unc(i32, i32, i32)

declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)

declare void @cq_template_zext_i8_to_i32_unc(i32, i32)

declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)

declare i32 @cqrt_qram_load_i1_hl(i32, i64)

declare i1 @cqrt_measure_i1(i32)

define internal i32 @__cq_q_grover_11_t(i32 %0, i32 %1, i32 %2) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 16, i64 16)
  %6 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -17)
  %7 = call i32 @cq_template_icmp_ult_i32_hl(i32 %6, i32 -16)
  %8 = call i32 @cq_template_shl_i32_lh(i32 1, i32 %0)
  %9 = call i32 @cq_template_icmp_ugt_i32(i32 %8, i32 %1)
  %10 = call i32 @cq_template_uitofp_i32_to_f64(i32 %8)
  %11 = call i32 @cq_template_sqrt_f64(i32 %10)
  %12 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 0x3FE921FB54442D18)
  %13 = call i32 @cq_template_floor_f64(i32 %12)
  %14 = call i32 @cq_template_fptosi_f64_to_i32(i32 %13)
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_xor_i1(i32 %7, i32 %16)
  call void @cqrt_and_i1(i32 %9, i32 %16, i32 %15)
  call void @cqrt_xor_i1(i32 %7, i32 %16)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_free(i32 %16)
  %17 = ptrtoint ptr %5 to i64
  %18 = call i32 @cqrt_alloc_i8(i8 0)
  br label %19

19:                                               ; preds = %19, %3
  %20 = phi i64 [ 0, %3 ], [ %22, %19 ]
  %21 = add i64 %17, %20
  call void @cqrt_qram_store_i8_hl_controlled(i32 %15, i32 %4, i64 %21, i32 %18)
  %22 = add nuw i64 %20, 1
  %23 = icmp eq i64 %22, 16
  br i1 %23, label %24, label %19

24:                                               ; preds = %19
  %25 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  %26 = call i32 @cq_template_zext_i32_to_i64(i32 %0)
  br label %27

27:                                               ; preds = %24
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %7, i32 %30)
  call void @cqrt_and_i1(i32 %9, i32 %30, i32 %29)
  call void @cqrt_and_i1(i32 %25, i32 %29, i32 %28)
  %31 = getelementptr i8, ptr %5, i64 0
  %32 = ptrtoint ptr %31 to i64
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %28, i32 %4, i64 %32, i32 %33)
  call void @cqrt_ry_i1_controlled(i32 %28, i32 %33, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %28, i32 %4, i64 %32, i32 %33)
  call void @cqrt_free(i32 %33)
  %34 = add i64 0, 1
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_xor_i1(i32 %35, i32 %36)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %36, i32 %37)
  %38 = getelementptr i8, ptr %5, i64 %34
  %39 = ptrtoint ptr %38 to i64
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %37, i32 %4, i64 %39, i32 %40)
  call void @cqrt_ry_i1_controlled(i32 %37, i32 %40, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %37, i32 %4, i64 %39, i32 %40)
  call void @cqrt_free(i32 %40)
  %41 = add i64 %34, 1
  %42 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 %41)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_xor_i1(i32 %42, i32 %43)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %37, i32 %43, i32 %44)
  %45 = getelementptr i8, ptr %5, i64 %41
  %46 = ptrtoint ptr %45 to i64
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %44, i32 %4, i64 %46, i32 %47)
  call void @cqrt_ry_i1_controlled(i32 %44, i32 %47, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %44, i32 %4, i64 %46, i32 %47)
  call void @cqrt_free(i32 %47)
  %48 = add i64 %41, 1
  %49 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 %48)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_xor_i1(i32 %49, i32 %50)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %50, i32 %51)
  %52 = getelementptr i8, ptr %5, i64 %48
  %53 = ptrtoint ptr %52 to i64
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %51, i32 %4, i64 %53, i32 %54)
  call void @cqrt_ry_i1_controlled(i32 %51, i32 %54, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %51, i32 %4, i64 %53, i32 %54)
  call void @cqrt_free(i32 %54)
  %55 = add i64 %48, 1
  %56 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 %55)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_xor_i1(i32 %56, i32 %57)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %57, i32 %58)
  call void @cqrt_xor_i1(i32 %56, i32 %57)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %56, i32 %26, i64 %55)
  call void @cqrt_free(i32 %56)
  call void @cqrt_and_i1(i32 %44, i32 %50, i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cqrt_xor_i1(i32 %49, i32 %50)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %49, i32 %26, i64 %48)
  call void @cqrt_free(i32 %49)
  call void @cqrt_and_i1(i32 %37, i32 %43, i32 %44)
  call void @cqrt_free(i32 %44)
  call void @cqrt_xor_i1(i32 %42, i32 %43)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %42, i32 %26, i64 %41)
  call void @cqrt_free(i32 %42)
  call void @cqrt_and_i1(i32 %28, i32 %36, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_xor_i1(i32 %35, i32 %36)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %35, i32 %26, i64 %34)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %25, i32 %29, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %9, i32 %30, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_xor_i1(i32 %7, i32 %30)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_free(i32 %30)
  %59 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %14, i32 0)
  %60 = call i32 @cq_template_zext_i32_to_i64(i32 %0)
  %61 = call i32 @cq_template_zext_i32_to_i64(i32 %0)
  %62 = call i32 @cq_template_zext_i32_to_i64(i32 %0)
  %63 = call i32 @cq_template_zext_i32_to_i64(i32 %0)
  br label %64

64:                                               ; preds = %27
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_xor_i1(i32 %7, i32 %67)
  call void @cqrt_and_i1(i32 %9, i32 %67, i32 %66)
  call void @cqrt_and_i1(i32 %59, i32 %66, i32 %65)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %68)
  %69 = call i32 @cqrt_alloc_i32(i32 0)
  %70 = getelementptr i8, ptr %5, i64 0
  %71 = ptrtoint ptr %70 to i64
  %72 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %68, i32 %4, i64 %71)
  %73 = call i32 @cq_template_zext_i8_to_i32(i32 %72)
  %74 = trunc i64 0 to i32
  %75 = call i32 @cq_template_shl_i32_hl(i32 %73, i32 %74)
  %76 = call i32 @cq_template_or_i32(i32 %75, i32 %69)
  %77 = add i64 0, 1
  %78 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %77)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %79)
  call void @cqrt_xor_i1(i32 %78, i32 %79)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %68, i32 %79, i32 %80)
  %81 = call i32 @cq_template_select_i32(i32 %68, i32 %76, i32 %69)
  %82 = getelementptr i8, ptr %5, i64 %77
  %83 = ptrtoint ptr %82 to i64
  %84 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %80, i32 %4, i64 %83)
  %85 = call i32 @cq_template_zext_i8_to_i32(i32 %84)
  %86 = trunc i64 %77 to i32
  %87 = call i32 @cq_template_shl_i32_hl(i32 %85, i32 %86)
  %88 = call i32 @cq_template_or_i32(i32 %87, i32 %81)
  %89 = add i64 %77, 1
  %90 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %89)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %91)
  call void @cqrt_xor_i1(i32 %90, i32 %91)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %80, i32 %91, i32 %92)
  %93 = call i32 @cq_template_select_i32(i32 %80, i32 %88, i32 %81)
  %94 = getelementptr i8, ptr %5, i64 %89
  %95 = ptrtoint ptr %94 to i64
  %96 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %92, i32 %4, i64 %95)
  %97 = call i32 @cq_template_zext_i8_to_i32(i32 %96)
  %98 = trunc i64 %89 to i32
  %99 = call i32 @cq_template_shl_i32_hl(i32 %97, i32 %98)
  %100 = call i32 @cq_template_or_i32(i32 %99, i32 %93)
  %101 = add i64 %89, 1
  %102 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %101)
  %103 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %103)
  call void @cqrt_xor_i1(i32 %102, i32 %103)
  %104 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %92, i32 %103, i32 %104)
  %105 = call i32 @cq_template_select_i32(i32 %92, i32 %100, i32 %93)
  %106 = getelementptr i8, ptr %5, i64 %101
  %107 = ptrtoint ptr %106 to i64
  %108 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %104, i32 %4, i64 %107)
  %109 = call i32 @cq_template_zext_i8_to_i32(i32 %108)
  %110 = trunc i64 %101 to i32
  %111 = call i32 @cq_template_shl_i32_hl(i32 %109, i32 %110)
  %112 = call i32 @cq_template_or_i32(i32 %111, i32 %105)
  %113 = add i64 %101, 1
  %114 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %113)
  %115 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %115)
  call void @cqrt_xor_i1(i32 %114, i32 %115)
  %116 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %104, i32 %115, i32 %116)
  call void @cqrt_xor_i1(i32 %114, i32 %115)
  call void @cqrt_not_i1(i32 %115)
  call void @cqrt_free(i32 %115)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %114, i32 %60, i64 %113)
  call void @cqrt_free(i32 %114)
  %117 = call i32 @cq_template_select_i32(i32 %104, i32 %112, i32 %105)
  %118 = call i32 @cq_template_icmp_eq_i32(i32 %117, i32 %1)
  %119 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %118, i32 %119)
  call void @cqrt_rz_i1(i32 %119, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %65, i32 %118, i32 %119)
  call void @cqrt_free(i32 %119)
  call void @cq_template_icmp_eq_i32_unc(i32 %118, i32 %117, i32 %1)
  call void @cqrt_free(i32 %118)
  call void @cq_template_select_i32_unc(i32 %117, i32 %104, i32 %112, i32 %105)
  call void @cqrt_free(i32 %117)
  call void @cq_template_or_i32_unc(i32 %112, i32 %111, i32 %105)
  call void @cqrt_free(i32 %112)
  call void @cq_template_shl_i32_hl_unc(i32 %111, i32 %109, i32 %110)
  call void @cqrt_free(i32 %111)
  call void @cq_template_zext_i8_to_i32_unc(i32 %109, i32 %108)
  call void @cqrt_free(i32 %109)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %108, i32 %104, i32 %4, i64 %107)
  call void @cqrt_free(i32 %108)
  call void @cq_template_select_i32_unc(i32 %105, i32 %92, i32 %100, i32 %93)
  call void @cqrt_free(i32 %105)
  call void @cqrt_and_i1(i32 %92, i32 %103, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cqrt_xor_i1(i32 %102, i32 %103)
  call void @cqrt_not_i1(i32 %103)
  call void @cqrt_free(i32 %103)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %102, i32 %60, i64 %101)
  call void @cqrt_free(i32 %102)
  call void @cq_template_or_i32_unc(i32 %100, i32 %99, i32 %93)
  call void @cqrt_free(i32 %100)
  call void @cq_template_shl_i32_hl_unc(i32 %99, i32 %97, i32 %98)
  call void @cqrt_free(i32 %99)
  call void @cq_template_zext_i8_to_i32_unc(i32 %97, i32 %96)
  call void @cqrt_free(i32 %97)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %96, i32 %92, i32 %4, i64 %95)
  call void @cqrt_free(i32 %96)
  call void @cq_template_select_i32_unc(i32 %93, i32 %80, i32 %88, i32 %81)
  call void @cqrt_free(i32 %93)
  call void @cqrt_and_i1(i32 %80, i32 %91, i32 %92)
  call void @cqrt_free(i32 %92)
  call void @cqrt_xor_i1(i32 %90, i32 %91)
  call void @cqrt_not_i1(i32 %91)
  call void @cqrt_free(i32 %91)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %90, i32 %60, i64 %89)
  call void @cqrt_free(i32 %90)
  call void @cq_template_or_i32_unc(i32 %88, i32 %87, i32 %81)
  call void @cqrt_free(i32 %88)
  call void @cq_template_shl_i32_hl_unc(i32 %87, i32 %85, i32 %86)
  call void @cqrt_free(i32 %87)
  call void @cq_template_zext_i8_to_i32_unc(i32 %85, i32 %84)
  call void @cqrt_free(i32 %85)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %84, i32 %80, i32 %4, i64 %83)
  call void @cqrt_free(i32 %84)
  call void @cq_template_select_i32_unc(i32 %81, i32 %68, i32 %76, i32 %69)
  call void @cqrt_free(i32 %81)
  call void @cqrt_and_i1(i32 %68, i32 %79, i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cqrt_xor_i1(i32 %78, i32 %79)
  call void @cqrt_not_i1(i32 %79)
  call void @cqrt_free(i32 %79)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %78, i32 %60, i64 %77)
  call void @cqrt_free(i32 %78)
  call void @cq_template_or_i32_unc(i32 %76, i32 %75, i32 %69)
  call void @cqrt_free(i32 %76)
  call void @cq_template_shl_i32_hl_unc(i32 %75, i32 %73, i32 %74)
  call void @cqrt_free(i32 %75)
  call void @cq_template_zext_i8_to_i32_unc(i32 %73, i32 %72)
  call void @cqrt_free(i32 %73)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %72, i32 %68, i32 %4, i64 %71)
  call void @cqrt_free(i32 %72)
  call void @cqrt_free(i32 %69)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %68)
  call void @cqrt_free(i32 %68)
  call void @cqrt_invert_begin()
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %120)
  %121 = getelementptr i8, ptr %5, i64 0
  %122 = ptrtoint ptr %121 to i64
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %120, i32 %4, i64 %122, i32 %123)
  call void @cqrt_ry_i1_controlled(i32 %120, i32 %123, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %120, i32 %4, i64 %122, i32 %123)
  call void @cqrt_free(i32 %123)
  %124 = add i64 0, 1
  %125 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %124)
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %126)
  call void @cqrt_xor_i1(i32 %125, i32 %126)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %120, i32 %126, i32 %127)
  %128 = getelementptr i8, ptr %5, i64 %124
  %129 = ptrtoint ptr %128 to i64
  %130 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %127, i32 %4, i64 %129, i32 %130)
  call void @cqrt_ry_i1_controlled(i32 %127, i32 %130, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %127, i32 %4, i64 %129, i32 %130)
  call void @cqrt_free(i32 %130)
  %131 = add i64 %124, 1
  %132 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %131)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %133)
  call void @cqrt_xor_i1(i32 %132, i32 %133)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %127, i32 %133, i32 %134)
  %135 = getelementptr i8, ptr %5, i64 %131
  %136 = ptrtoint ptr %135 to i64
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %134, i32 %4, i64 %136, i32 %137)
  call void @cqrt_ry_i1_controlled(i32 %134, i32 %137, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %134, i32 %4, i64 %136, i32 %137)
  call void @cqrt_free(i32 %137)
  %138 = add i64 %131, 1
  %139 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %138)
  %140 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %140)
  call void @cqrt_xor_i1(i32 %139, i32 %140)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %134, i32 %140, i32 %141)
  %142 = getelementptr i8, ptr %5, i64 %138
  %143 = ptrtoint ptr %142 to i64
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %141, i32 %4, i64 %143, i32 %144)
  call void @cqrt_ry_i1_controlled(i32 %141, i32 %144, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %141, i32 %4, i64 %143, i32 %144)
  call void @cqrt_free(i32 %144)
  %145 = add i64 %138, 1
  %146 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %145)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %147)
  call void @cqrt_xor_i1(i32 %146, i32 %147)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %141, i32 %147, i32 %148)
  call void @cqrt_xor_i1(i32 %146, i32 %147)
  call void @cqrt_not_i1(i32 %147)
  call void @cqrt_free(i32 %147)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %146, i32 %61, i64 %145)
  call void @cqrt_free(i32 %146)
  call void @cqrt_and_i1(i32 %134, i32 %140, i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cqrt_xor_i1(i32 %139, i32 %140)
  call void @cqrt_not_i1(i32 %140)
  call void @cqrt_free(i32 %140)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %139, i32 %61, i64 %138)
  call void @cqrt_free(i32 %139)
  call void @cqrt_and_i1(i32 %127, i32 %133, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cqrt_xor_i1(i32 %132, i32 %133)
  call void @cqrt_not_i1(i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %132, i32 %61, i64 %131)
  call void @cqrt_free(i32 %132)
  call void @cqrt_and_i1(i32 %120, i32 %126, i32 %127)
  call void @cqrt_free(i32 %127)
  call void @cqrt_xor_i1(i32 %125, i32 %126)
  call void @cqrt_not_i1(i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %125, i32 %61, i64 %124)
  call void @cqrt_free(i32 %125)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %120)
  call void @cqrt_free(i32 %120)
  call void @cqrt_invert_end()
  %149 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %145)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %149, i32 %61, i64 %145)
  call void @cqrt_free(i32 %149)
  %150 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %150)
  %151 = call i32 @cqrt_alloc_i32(i32 0)
  %152 = getelementptr i8, ptr %5, i64 0
  %153 = ptrtoint ptr %152 to i64
  %154 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %150, i32 %4, i64 %153)
  %155 = call i32 @cq_template_zext_i8_to_i32(i32 %154)
  %156 = trunc i64 0 to i32
  %157 = call i32 @cq_template_shl_i32_hl(i32 %155, i32 %156)
  %158 = call i32 @cq_template_or_i32(i32 %157, i32 %151)
  %159 = add i64 0, 1
  %160 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %159)
  %161 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %161)
  call void @cqrt_xor_i1(i32 %160, i32 %161)
  %162 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %150, i32 %161, i32 %162)
  %163 = call i32 @cq_template_select_i32(i32 %150, i32 %158, i32 %151)
  %164 = getelementptr i8, ptr %5, i64 %159
  %165 = ptrtoint ptr %164 to i64
  %166 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %162, i32 %4, i64 %165)
  %167 = call i32 @cq_template_zext_i8_to_i32(i32 %166)
  %168 = trunc i64 %159 to i32
  %169 = call i32 @cq_template_shl_i32_hl(i32 %167, i32 %168)
  %170 = call i32 @cq_template_or_i32(i32 %169, i32 %163)
  %171 = add i64 %159, 1
  %172 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %171)
  %173 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %173)
  call void @cqrt_xor_i1(i32 %172, i32 %173)
  %174 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %162, i32 %173, i32 %174)
  %175 = call i32 @cq_template_select_i32(i32 %162, i32 %170, i32 %163)
  %176 = getelementptr i8, ptr %5, i64 %171
  %177 = ptrtoint ptr %176 to i64
  %178 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %174, i32 %4, i64 %177)
  %179 = call i32 @cq_template_zext_i8_to_i32(i32 %178)
  %180 = trunc i64 %171 to i32
  %181 = call i32 @cq_template_shl_i32_hl(i32 %179, i32 %180)
  %182 = call i32 @cq_template_or_i32(i32 %181, i32 %175)
  %183 = add i64 %171, 1
  %184 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %183)
  %185 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %185)
  call void @cqrt_xor_i1(i32 %184, i32 %185)
  %186 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %174, i32 %185, i32 %186)
  %187 = call i32 @cq_template_select_i32(i32 %174, i32 %182, i32 %175)
  %188 = getelementptr i8, ptr %5, i64 %183
  %189 = ptrtoint ptr %188 to i64
  %190 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %186, i32 %4, i64 %189)
  %191 = call i32 @cq_template_zext_i8_to_i32(i32 %190)
  %192 = trunc i64 %183 to i32
  %193 = call i32 @cq_template_shl_i32_hl(i32 %191, i32 %192)
  %194 = call i32 @cq_template_or_i32(i32 %193, i32 %187)
  %195 = add i64 %183, 1
  %196 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %195)
  %197 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %197)
  call void @cqrt_xor_i1(i32 %196, i32 %197)
  %198 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %186, i32 %197, i32 %198)
  call void @cqrt_xor_i1(i32 %196, i32 %197)
  call void @cqrt_not_i1(i32 %197)
  call void @cqrt_free(i32 %197)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %196, i32 %62, i64 %195)
  call void @cqrt_free(i32 %196)
  %199 = call i32 @cq_template_select_i32(i32 %186, i32 %194, i32 %187)
  %200 = call i32 @cq_template_icmp_eq_i32_hl(i32 %199, i32 0)
  %201 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %201)
  call void @cqrt_xor_i1(i32 %200, i32 %201)
  %202 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %201, i32 %202)
  call void @cqrt_rz_i1(i32 %202, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %65, i32 %201, i32 %202)
  call void @cqrt_free(i32 %202)
  call void @cqrt_xor_i1(i32 %200, i32 %201)
  call void @cqrt_not_i1(i32 %201)
  call void @cqrt_free(i32 %201)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %200, i32 %199, i32 0)
  call void @cqrt_free(i32 %200)
  call void @cq_template_select_i32_unc(i32 %199, i32 %186, i32 %194, i32 %187)
  call void @cqrt_free(i32 %199)
  call void @cq_template_or_i32_unc(i32 %194, i32 %193, i32 %187)
  call void @cqrt_free(i32 %194)
  call void @cq_template_shl_i32_hl_unc(i32 %193, i32 %191, i32 %192)
  call void @cqrt_free(i32 %193)
  call void @cq_template_zext_i8_to_i32_unc(i32 %191, i32 %190)
  call void @cqrt_free(i32 %191)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %190, i32 %186, i32 %4, i64 %189)
  call void @cqrt_free(i32 %190)
  call void @cq_template_select_i32_unc(i32 %187, i32 %174, i32 %182, i32 %175)
  call void @cqrt_free(i32 %187)
  call void @cqrt_and_i1(i32 %174, i32 %185, i32 %186)
  call void @cqrt_free(i32 %186)
  call void @cqrt_xor_i1(i32 %184, i32 %185)
  call void @cqrt_not_i1(i32 %185)
  call void @cqrt_free(i32 %185)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %184, i32 %62, i64 %183)
  call void @cqrt_free(i32 %184)
  call void @cq_template_or_i32_unc(i32 %182, i32 %181, i32 %175)
  call void @cqrt_free(i32 %182)
  call void @cq_template_shl_i32_hl_unc(i32 %181, i32 %179, i32 %180)
  call void @cqrt_free(i32 %181)
  call void @cq_template_zext_i8_to_i32_unc(i32 %179, i32 %178)
  call void @cqrt_free(i32 %179)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %178, i32 %174, i32 %4, i64 %177)
  call void @cqrt_free(i32 %178)
  call void @cq_template_select_i32_unc(i32 %175, i32 %162, i32 %170, i32 %163)
  call void @cqrt_free(i32 %175)
  call void @cqrt_and_i1(i32 %162, i32 %173, i32 %174)
  call void @cqrt_free(i32 %174)
  call void @cqrt_xor_i1(i32 %172, i32 %173)
  call void @cqrt_not_i1(i32 %173)
  call void @cqrt_free(i32 %173)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %172, i32 %62, i64 %171)
  call void @cqrt_free(i32 %172)
  call void @cq_template_or_i32_unc(i32 %170, i32 %169, i32 %163)
  call void @cqrt_free(i32 %170)
  call void @cq_template_shl_i32_hl_unc(i32 %169, i32 %167, i32 %168)
  call void @cqrt_free(i32 %169)
  call void @cq_template_zext_i8_to_i32_unc(i32 %167, i32 %166)
  call void @cqrt_free(i32 %167)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %166, i32 %162, i32 %4, i64 %165)
  call void @cqrt_free(i32 %166)
  call void @cq_template_select_i32_unc(i32 %163, i32 %150, i32 %158, i32 %151)
  call void @cqrt_free(i32 %163)
  call void @cqrt_and_i1(i32 %150, i32 %161, i32 %162)
  call void @cqrt_free(i32 %162)
  call void @cqrt_xor_i1(i32 %160, i32 %161)
  call void @cqrt_not_i1(i32 %161)
  call void @cqrt_free(i32 %161)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %160, i32 %62, i64 %159)
  call void @cqrt_free(i32 %160)
  call void @cq_template_or_i32_unc(i32 %158, i32 %157, i32 %151)
  call void @cqrt_free(i32 %158)
  call void @cq_template_shl_i32_hl_unc(i32 %157, i32 %155, i32 %156)
  call void @cqrt_free(i32 %157)
  call void @cq_template_zext_i8_to_i32_unc(i32 %155, i32 %154)
  call void @cqrt_free(i32 %155)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %154, i32 %150, i32 %4, i64 %153)
  call void @cqrt_free(i32 %154)
  call void @cqrt_free(i32 %151)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %150)
  call void @cqrt_free(i32 %150)
  %203 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %203)
  %204 = getelementptr i8, ptr %5, i64 0
  %205 = ptrtoint ptr %204 to i64
  %206 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %203, i32 %4, i64 %205, i32 %206)
  call void @cqrt_ry_i1_controlled(i32 %203, i32 %206, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %203, i32 %4, i64 %205, i32 %206)
  call void @cqrt_free(i32 %206)
  %207 = add i64 0, 1
  %208 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %207)
  %209 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %209)
  call void @cqrt_xor_i1(i32 %208, i32 %209)
  %210 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %203, i32 %209, i32 %210)
  %211 = getelementptr i8, ptr %5, i64 %207
  %212 = ptrtoint ptr %211 to i64
  %213 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %210, i32 %4, i64 %212, i32 %213)
  call void @cqrt_ry_i1_controlled(i32 %210, i32 %213, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %210, i32 %4, i64 %212, i32 %213)
  call void @cqrt_free(i32 %213)
  %214 = add i64 %207, 1
  %215 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %214)
  %216 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %216)
  call void @cqrt_xor_i1(i32 %215, i32 %216)
  %217 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %210, i32 %216, i32 %217)
  %218 = getelementptr i8, ptr %5, i64 %214
  %219 = ptrtoint ptr %218 to i64
  %220 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %217, i32 %4, i64 %219, i32 %220)
  call void @cqrt_ry_i1_controlled(i32 %217, i32 %220, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %217, i32 %4, i64 %219, i32 %220)
  call void @cqrt_free(i32 %220)
  %221 = add i64 %214, 1
  %222 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %221)
  %223 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %223)
  call void @cqrt_xor_i1(i32 %222, i32 %223)
  %224 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %223, i32 %224)
  %225 = getelementptr i8, ptr %5, i64 %221
  %226 = ptrtoint ptr %225 to i64
  %227 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %224, i32 %4, i64 %226, i32 %227)
  call void @cqrt_ry_i1_controlled(i32 %224, i32 %227, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %224, i32 %4, i64 %226, i32 %227)
  call void @cqrt_free(i32 %227)
  %228 = add i64 %221, 1
  %229 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %228)
  %230 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %230)
  call void @cqrt_xor_i1(i32 %229, i32 %230)
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %224, i32 %230, i32 %231)
  call void @cqrt_xor_i1(i32 %229, i32 %230)
  call void @cqrt_not_i1(i32 %230)
  call void @cqrt_free(i32 %230)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %229, i32 %63, i64 %228)
  call void @cqrt_free(i32 %229)
  call void @cqrt_and_i1(i32 %217, i32 %223, i32 %224)
  call void @cqrt_free(i32 %224)
  call void @cqrt_xor_i1(i32 %222, i32 %223)
  call void @cqrt_not_i1(i32 %223)
  call void @cqrt_free(i32 %223)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %222, i32 %63, i64 %221)
  call void @cqrt_free(i32 %222)
  call void @cqrt_and_i1(i32 %210, i32 %216, i32 %217)
  call void @cqrt_free(i32 %217)
  call void @cqrt_xor_i1(i32 %215, i32 %216)
  call void @cqrt_not_i1(i32 %216)
  call void @cqrt_free(i32 %216)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %215, i32 %63, i64 %214)
  call void @cqrt_free(i32 %215)
  call void @cqrt_and_i1(i32 %203, i32 %209, i32 %210)
  call void @cqrt_free(i32 %210)
  call void @cqrt_xor_i1(i32 %208, i32 %209)
  call void @cqrt_not_i1(i32 %209)
  call void @cqrt_free(i32 %209)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %208, i32 %63, i64 %207)
  call void @cqrt_free(i32 %208)
  call void @cqrt_and_i1(i32 %65, i32 %25, i32 %203)
  call void @cqrt_free(i32 %203)
  %232 = add i32 0, 1
  %233 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 %232)
  %234 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %234)
  call void @cqrt_xor_i1(i32 %233, i32 %234)
  %235 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %234, i32 %235)
  %236 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %236)
  %237 = call i32 @cqrt_alloc_i32(i32 0)
  %238 = getelementptr i8, ptr %5, i64 0
  %239 = ptrtoint ptr %238 to i64
  %240 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %236, i32 %4, i64 %239)
  %241 = call i32 @cq_template_zext_i8_to_i32(i32 %240)
  %242 = trunc i64 0 to i32
  %243 = call i32 @cq_template_shl_i32_hl(i32 %241, i32 %242)
  %244 = call i32 @cq_template_or_i32(i32 %243, i32 %237)
  %245 = add i64 0, 1
  %246 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %245)
  %247 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %247)
  call void @cqrt_xor_i1(i32 %246, i32 %247)
  %248 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %236, i32 %247, i32 %248)
  %249 = call i32 @cq_template_select_i32(i32 %236, i32 %244, i32 %237)
  %250 = getelementptr i8, ptr %5, i64 %245
  %251 = ptrtoint ptr %250 to i64
  %252 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %248, i32 %4, i64 %251)
  %253 = call i32 @cq_template_zext_i8_to_i32(i32 %252)
  %254 = trunc i64 %245 to i32
  %255 = call i32 @cq_template_shl_i32_hl(i32 %253, i32 %254)
  %256 = call i32 @cq_template_or_i32(i32 %255, i32 %249)
  %257 = add i64 %245, 1
  %258 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %257)
  %259 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %259)
  call void @cqrt_xor_i1(i32 %258, i32 %259)
  %260 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %248, i32 %259, i32 %260)
  %261 = call i32 @cq_template_select_i32(i32 %248, i32 %256, i32 %249)
  %262 = getelementptr i8, ptr %5, i64 %257
  %263 = ptrtoint ptr %262 to i64
  %264 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %260, i32 %4, i64 %263)
  %265 = call i32 @cq_template_zext_i8_to_i32(i32 %264)
  %266 = trunc i64 %257 to i32
  %267 = call i32 @cq_template_shl_i32_hl(i32 %265, i32 %266)
  %268 = call i32 @cq_template_or_i32(i32 %267, i32 %261)
  %269 = add i64 %257, 1
  %270 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %269)
  %271 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %271)
  call void @cqrt_xor_i1(i32 %270, i32 %271)
  %272 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %260, i32 %271, i32 %272)
  %273 = call i32 @cq_template_select_i32(i32 %260, i32 %268, i32 %261)
  %274 = getelementptr i8, ptr %5, i64 %269
  %275 = ptrtoint ptr %274 to i64
  %276 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %272, i32 %4, i64 %275)
  %277 = call i32 @cq_template_zext_i8_to_i32(i32 %276)
  %278 = trunc i64 %269 to i32
  %279 = call i32 @cq_template_shl_i32_hl(i32 %277, i32 %278)
  %280 = call i32 @cq_template_or_i32(i32 %279, i32 %273)
  %281 = add i64 %269, 1
  %282 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %281)
  %283 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %283)
  call void @cqrt_xor_i1(i32 %282, i32 %283)
  %284 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %272, i32 %283, i32 %284)
  call void @cqrt_xor_i1(i32 %282, i32 %283)
  call void @cqrt_not_i1(i32 %283)
  call void @cqrt_free(i32 %283)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %282, i32 %60, i64 %281)
  call void @cqrt_free(i32 %282)
  %285 = call i32 @cq_template_select_i32(i32 %272, i32 %280, i32 %273)
  %286 = call i32 @cq_template_icmp_eq_i32(i32 %285, i32 %1)
  %287 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %286, i32 %287)
  call void @cqrt_rz_i1(i32 %287, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %235, i32 %286, i32 %287)
  call void @cqrt_free(i32 %287)
  call void @cq_template_icmp_eq_i32_unc(i32 %286, i32 %285, i32 %1)
  call void @cqrt_free(i32 %286)
  call void @cq_template_select_i32_unc(i32 %285, i32 %272, i32 %280, i32 %273)
  call void @cqrt_free(i32 %285)
  call void @cq_template_or_i32_unc(i32 %280, i32 %279, i32 %273)
  call void @cqrt_free(i32 %280)
  call void @cq_template_shl_i32_hl_unc(i32 %279, i32 %277, i32 %278)
  call void @cqrt_free(i32 %279)
  call void @cq_template_zext_i8_to_i32_unc(i32 %277, i32 %276)
  call void @cqrt_free(i32 %277)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %276, i32 %272, i32 %4, i64 %275)
  call void @cqrt_free(i32 %276)
  call void @cq_template_select_i32_unc(i32 %273, i32 %260, i32 %268, i32 %261)
  call void @cqrt_free(i32 %273)
  call void @cqrt_and_i1(i32 %260, i32 %271, i32 %272)
  call void @cqrt_free(i32 %272)
  call void @cqrt_xor_i1(i32 %270, i32 %271)
  call void @cqrt_not_i1(i32 %271)
  call void @cqrt_free(i32 %271)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %270, i32 %60, i64 %269)
  call void @cqrt_free(i32 %270)
  call void @cq_template_or_i32_unc(i32 %268, i32 %267, i32 %261)
  call void @cqrt_free(i32 %268)
  call void @cq_template_shl_i32_hl_unc(i32 %267, i32 %265, i32 %266)
  call void @cqrt_free(i32 %267)
  call void @cq_template_zext_i8_to_i32_unc(i32 %265, i32 %264)
  call void @cqrt_free(i32 %265)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %264, i32 %260, i32 %4, i64 %263)
  call void @cqrt_free(i32 %264)
  call void @cq_template_select_i32_unc(i32 %261, i32 %248, i32 %256, i32 %249)
  call void @cqrt_free(i32 %261)
  call void @cqrt_and_i1(i32 %248, i32 %259, i32 %260)
  call void @cqrt_free(i32 %260)
  call void @cqrt_xor_i1(i32 %258, i32 %259)
  call void @cqrt_not_i1(i32 %259)
  call void @cqrt_free(i32 %259)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %258, i32 %60, i64 %257)
  call void @cqrt_free(i32 %258)
  call void @cq_template_or_i32_unc(i32 %256, i32 %255, i32 %249)
  call void @cqrt_free(i32 %256)
  call void @cq_template_shl_i32_hl_unc(i32 %255, i32 %253, i32 %254)
  call void @cqrt_free(i32 %255)
  call void @cq_template_zext_i8_to_i32_unc(i32 %253, i32 %252)
  call void @cqrt_free(i32 %253)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %252, i32 %248, i32 %4, i64 %251)
  call void @cqrt_free(i32 %252)
  call void @cq_template_select_i32_unc(i32 %249, i32 %236, i32 %244, i32 %237)
  call void @cqrt_free(i32 %249)
  call void @cqrt_and_i1(i32 %236, i32 %247, i32 %248)
  call void @cqrt_free(i32 %248)
  call void @cqrt_xor_i1(i32 %246, i32 %247)
  call void @cqrt_not_i1(i32 %247)
  call void @cqrt_free(i32 %247)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %246, i32 %60, i64 %245)
  call void @cqrt_free(i32 %246)
  call void @cq_template_or_i32_unc(i32 %244, i32 %243, i32 %237)
  call void @cqrt_free(i32 %244)
  call void @cq_template_shl_i32_hl_unc(i32 %243, i32 %241, i32 %242)
  call void @cqrt_free(i32 %243)
  call void @cq_template_zext_i8_to_i32_unc(i32 %241, i32 %240)
  call void @cqrt_free(i32 %241)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %240, i32 %236, i32 %4, i64 %239)
  call void @cqrt_free(i32 %240)
  call void @cqrt_free(i32 %237)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %236)
  call void @cqrt_free(i32 %236)
  call void @cqrt_invert_begin()
  %288 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %288)
  %289 = getelementptr i8, ptr %5, i64 0
  %290 = ptrtoint ptr %289 to i64
  %291 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %288, i32 %4, i64 %290, i32 %291)
  call void @cqrt_ry_i1_controlled(i32 %288, i32 %291, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %288, i32 %4, i64 %290, i32 %291)
  call void @cqrt_free(i32 %291)
  %292 = add i64 0, 1
  %293 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %292)
  %294 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %294)
  call void @cqrt_xor_i1(i32 %293, i32 %294)
  %295 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %288, i32 %294, i32 %295)
  %296 = getelementptr i8, ptr %5, i64 %292
  %297 = ptrtoint ptr %296 to i64
  %298 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %295, i32 %4, i64 %297, i32 %298)
  call void @cqrt_ry_i1_controlled(i32 %295, i32 %298, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %295, i32 %4, i64 %297, i32 %298)
  call void @cqrt_free(i32 %298)
  %299 = add i64 %292, 1
  %300 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %299)
  %301 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %301)
  call void @cqrt_xor_i1(i32 %300, i32 %301)
  %302 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %295, i32 %301, i32 %302)
  %303 = getelementptr i8, ptr %5, i64 %299
  %304 = ptrtoint ptr %303 to i64
  %305 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %302, i32 %4, i64 %304, i32 %305)
  call void @cqrt_ry_i1_controlled(i32 %302, i32 %305, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %302, i32 %4, i64 %304, i32 %305)
  call void @cqrt_free(i32 %305)
  %306 = add i64 %299, 1
  %307 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %306)
  %308 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %308)
  call void @cqrt_xor_i1(i32 %307, i32 %308)
  %309 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %302, i32 %308, i32 %309)
  %310 = getelementptr i8, ptr %5, i64 %306
  %311 = ptrtoint ptr %310 to i64
  %312 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %309, i32 %4, i64 %311, i32 %312)
  call void @cqrt_ry_i1_controlled(i32 %309, i32 %312, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %309, i32 %4, i64 %311, i32 %312)
  call void @cqrt_free(i32 %312)
  %313 = add i64 %306, 1
  %314 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %313)
  %315 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %315)
  call void @cqrt_xor_i1(i32 %314, i32 %315)
  %316 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %309, i32 %315, i32 %316)
  call void @cqrt_xor_i1(i32 %314, i32 %315)
  call void @cqrt_not_i1(i32 %315)
  call void @cqrt_free(i32 %315)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %314, i32 %61, i64 %313)
  call void @cqrt_free(i32 %314)
  call void @cqrt_and_i1(i32 %302, i32 %308, i32 %309)
  call void @cqrt_free(i32 %309)
  call void @cqrt_xor_i1(i32 %307, i32 %308)
  call void @cqrt_not_i1(i32 %308)
  call void @cqrt_free(i32 %308)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %307, i32 %61, i64 %306)
  call void @cqrt_free(i32 %307)
  call void @cqrt_and_i1(i32 %295, i32 %301, i32 %302)
  call void @cqrt_free(i32 %302)
  call void @cqrt_xor_i1(i32 %300, i32 %301)
  call void @cqrt_not_i1(i32 %301)
  call void @cqrt_free(i32 %301)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %300, i32 %61, i64 %299)
  call void @cqrt_free(i32 %300)
  call void @cqrt_and_i1(i32 %288, i32 %294, i32 %295)
  call void @cqrt_free(i32 %295)
  call void @cqrt_xor_i1(i32 %293, i32 %294)
  call void @cqrt_not_i1(i32 %294)
  call void @cqrt_free(i32 %294)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %293, i32 %61, i64 %292)
  call void @cqrt_free(i32 %293)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cqrt_invert_end()
  %317 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %313)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %317, i32 %61, i64 %313)
  call void @cqrt_free(i32 %317)
  %318 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %318)
  %319 = call i32 @cqrt_alloc_i32(i32 0)
  %320 = getelementptr i8, ptr %5, i64 0
  %321 = ptrtoint ptr %320 to i64
  %322 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %318, i32 %4, i64 %321)
  %323 = call i32 @cq_template_zext_i8_to_i32(i32 %322)
  %324 = trunc i64 0 to i32
  %325 = call i32 @cq_template_shl_i32_hl(i32 %323, i32 %324)
  %326 = call i32 @cq_template_or_i32(i32 %325, i32 %319)
  %327 = add i64 0, 1
  %328 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %327)
  %329 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %329)
  call void @cqrt_xor_i1(i32 %328, i32 %329)
  %330 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %318, i32 %329, i32 %330)
  %331 = call i32 @cq_template_select_i32(i32 %318, i32 %326, i32 %319)
  %332 = getelementptr i8, ptr %5, i64 %327
  %333 = ptrtoint ptr %332 to i64
  %334 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %330, i32 %4, i64 %333)
  %335 = call i32 @cq_template_zext_i8_to_i32(i32 %334)
  %336 = trunc i64 %327 to i32
  %337 = call i32 @cq_template_shl_i32_hl(i32 %335, i32 %336)
  %338 = call i32 @cq_template_or_i32(i32 %337, i32 %331)
  %339 = add i64 %327, 1
  %340 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %339)
  %341 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %341)
  call void @cqrt_xor_i1(i32 %340, i32 %341)
  %342 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %330, i32 %341, i32 %342)
  %343 = call i32 @cq_template_select_i32(i32 %330, i32 %338, i32 %331)
  %344 = getelementptr i8, ptr %5, i64 %339
  %345 = ptrtoint ptr %344 to i64
  %346 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %342, i32 %4, i64 %345)
  %347 = call i32 @cq_template_zext_i8_to_i32(i32 %346)
  %348 = trunc i64 %339 to i32
  %349 = call i32 @cq_template_shl_i32_hl(i32 %347, i32 %348)
  %350 = call i32 @cq_template_or_i32(i32 %349, i32 %343)
  %351 = add i64 %339, 1
  %352 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %351)
  %353 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %353)
  call void @cqrt_xor_i1(i32 %352, i32 %353)
  %354 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %342, i32 %353, i32 %354)
  %355 = call i32 @cq_template_select_i32(i32 %342, i32 %350, i32 %343)
  %356 = getelementptr i8, ptr %5, i64 %351
  %357 = ptrtoint ptr %356 to i64
  %358 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %354, i32 %4, i64 %357)
  %359 = call i32 @cq_template_zext_i8_to_i32(i32 %358)
  %360 = trunc i64 %351 to i32
  %361 = call i32 @cq_template_shl_i32_hl(i32 %359, i32 %360)
  %362 = call i32 @cq_template_or_i32(i32 %361, i32 %355)
  %363 = add i64 %351, 1
  %364 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %363)
  %365 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %365)
  call void @cqrt_xor_i1(i32 %364, i32 %365)
  %366 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %354, i32 %365, i32 %366)
  call void @cqrt_xor_i1(i32 %364, i32 %365)
  call void @cqrt_not_i1(i32 %365)
  call void @cqrt_free(i32 %365)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %364, i32 %62, i64 %363)
  call void @cqrt_free(i32 %364)
  %367 = call i32 @cq_template_select_i32(i32 %354, i32 %362, i32 %355)
  %368 = call i32 @cq_template_icmp_eq_i32_hl(i32 %367, i32 0)
  %369 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %369)
  call void @cqrt_xor_i1(i32 %368, i32 %369)
  %370 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %369, i32 %370)
  call void @cqrt_rz_i1(i32 %370, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %235, i32 %369, i32 %370)
  call void @cqrt_free(i32 %370)
  call void @cqrt_xor_i1(i32 %368, i32 %369)
  call void @cqrt_not_i1(i32 %369)
  call void @cqrt_free(i32 %369)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %368, i32 %367, i32 0)
  call void @cqrt_free(i32 %368)
  call void @cq_template_select_i32_unc(i32 %367, i32 %354, i32 %362, i32 %355)
  call void @cqrt_free(i32 %367)
  call void @cq_template_or_i32_unc(i32 %362, i32 %361, i32 %355)
  call void @cqrt_free(i32 %362)
  call void @cq_template_shl_i32_hl_unc(i32 %361, i32 %359, i32 %360)
  call void @cqrt_free(i32 %361)
  call void @cq_template_zext_i8_to_i32_unc(i32 %359, i32 %358)
  call void @cqrt_free(i32 %359)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %358, i32 %354, i32 %4, i64 %357)
  call void @cqrt_free(i32 %358)
  call void @cq_template_select_i32_unc(i32 %355, i32 %342, i32 %350, i32 %343)
  call void @cqrt_free(i32 %355)
  call void @cqrt_and_i1(i32 %342, i32 %353, i32 %354)
  call void @cqrt_free(i32 %354)
  call void @cqrt_xor_i1(i32 %352, i32 %353)
  call void @cqrt_not_i1(i32 %353)
  call void @cqrt_free(i32 %353)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %352, i32 %62, i64 %351)
  call void @cqrt_free(i32 %352)
  call void @cq_template_or_i32_unc(i32 %350, i32 %349, i32 %343)
  call void @cqrt_free(i32 %350)
  call void @cq_template_shl_i32_hl_unc(i32 %349, i32 %347, i32 %348)
  call void @cqrt_free(i32 %349)
  call void @cq_template_zext_i8_to_i32_unc(i32 %347, i32 %346)
  call void @cqrt_free(i32 %347)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %346, i32 %342, i32 %4, i64 %345)
  call void @cqrt_free(i32 %346)
  call void @cq_template_select_i32_unc(i32 %343, i32 %330, i32 %338, i32 %331)
  call void @cqrt_free(i32 %343)
  call void @cqrt_and_i1(i32 %330, i32 %341, i32 %342)
  call void @cqrt_free(i32 %342)
  call void @cqrt_xor_i1(i32 %340, i32 %341)
  call void @cqrt_not_i1(i32 %341)
  call void @cqrt_free(i32 %341)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %340, i32 %62, i64 %339)
  call void @cqrt_free(i32 %340)
  call void @cq_template_or_i32_unc(i32 %338, i32 %337, i32 %331)
  call void @cqrt_free(i32 %338)
  call void @cq_template_shl_i32_hl_unc(i32 %337, i32 %335, i32 %336)
  call void @cqrt_free(i32 %337)
  call void @cq_template_zext_i8_to_i32_unc(i32 %335, i32 %334)
  call void @cqrt_free(i32 %335)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %334, i32 %330, i32 %4, i64 %333)
  call void @cqrt_free(i32 %334)
  call void @cq_template_select_i32_unc(i32 %331, i32 %318, i32 %326, i32 %319)
  call void @cqrt_free(i32 %331)
  call void @cqrt_and_i1(i32 %318, i32 %329, i32 %330)
  call void @cqrt_free(i32 %330)
  call void @cqrt_xor_i1(i32 %328, i32 %329)
  call void @cqrt_not_i1(i32 %329)
  call void @cqrt_free(i32 %329)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %328, i32 %62, i64 %327)
  call void @cqrt_free(i32 %328)
  call void @cq_template_or_i32_unc(i32 %326, i32 %325, i32 %319)
  call void @cqrt_free(i32 %326)
  call void @cq_template_shl_i32_hl_unc(i32 %325, i32 %323, i32 %324)
  call void @cqrt_free(i32 %325)
  call void @cq_template_zext_i8_to_i32_unc(i32 %323, i32 %322)
  call void @cqrt_free(i32 %323)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %322, i32 %318, i32 %4, i64 %321)
  call void @cqrt_free(i32 %322)
  call void @cqrt_free(i32 %319)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %318)
  call void @cqrt_free(i32 %318)
  %371 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %371)
  %372 = getelementptr i8, ptr %5, i64 0
  %373 = ptrtoint ptr %372 to i64
  %374 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %371, i32 %4, i64 %373, i32 %374)
  call void @cqrt_ry_i1_controlled(i32 %371, i32 %374, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %371, i32 %4, i64 %373, i32 %374)
  call void @cqrt_free(i32 %374)
  %375 = add i64 0, 1
  %376 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %375)
  %377 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %377)
  call void @cqrt_xor_i1(i32 %376, i32 %377)
  %378 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %371, i32 %377, i32 %378)
  %379 = getelementptr i8, ptr %5, i64 %375
  %380 = ptrtoint ptr %379 to i64
  %381 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %378, i32 %4, i64 %380, i32 %381)
  call void @cqrt_ry_i1_controlled(i32 %378, i32 %381, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %378, i32 %4, i64 %380, i32 %381)
  call void @cqrt_free(i32 %381)
  %382 = add i64 %375, 1
  %383 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %382)
  %384 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %384)
  call void @cqrt_xor_i1(i32 %383, i32 %384)
  %385 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %378, i32 %384, i32 %385)
  %386 = getelementptr i8, ptr %5, i64 %382
  %387 = ptrtoint ptr %386 to i64
  %388 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %385, i32 %4, i64 %387, i32 %388)
  call void @cqrt_ry_i1_controlled(i32 %385, i32 %388, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %385, i32 %4, i64 %387, i32 %388)
  call void @cqrt_free(i32 %388)
  %389 = add i64 %382, 1
  %390 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %389)
  %391 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %391)
  call void @cqrt_xor_i1(i32 %390, i32 %391)
  %392 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %385, i32 %391, i32 %392)
  %393 = getelementptr i8, ptr %5, i64 %389
  %394 = ptrtoint ptr %393 to i64
  %395 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %392, i32 %4, i64 %394, i32 %395)
  call void @cqrt_ry_i1_controlled(i32 %392, i32 %395, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %392, i32 %4, i64 %394, i32 %395)
  call void @cqrt_free(i32 %395)
  %396 = add i64 %389, 1
  %397 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %396)
  %398 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %398)
  call void @cqrt_xor_i1(i32 %397, i32 %398)
  %399 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %392, i32 %398, i32 %399)
  call void @cqrt_xor_i1(i32 %397, i32 %398)
  call void @cqrt_not_i1(i32 %398)
  call void @cqrt_free(i32 %398)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %397, i32 %63, i64 %396)
  call void @cqrt_free(i32 %397)
  call void @cqrt_and_i1(i32 %385, i32 %391, i32 %392)
  call void @cqrt_free(i32 %392)
  call void @cqrt_xor_i1(i32 %390, i32 %391)
  call void @cqrt_not_i1(i32 %391)
  call void @cqrt_free(i32 %391)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %390, i32 %63, i64 %389)
  call void @cqrt_free(i32 %390)
  call void @cqrt_and_i1(i32 %378, i32 %384, i32 %385)
  call void @cqrt_free(i32 %385)
  call void @cqrt_xor_i1(i32 %383, i32 %384)
  call void @cqrt_not_i1(i32 %384)
  call void @cqrt_free(i32 %384)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %383, i32 %63, i64 %382)
  call void @cqrt_free(i32 %383)
  call void @cqrt_and_i1(i32 %371, i32 %377, i32 %378)
  call void @cqrt_free(i32 %378)
  call void @cqrt_xor_i1(i32 %376, i32 %377)
  call void @cqrt_not_i1(i32 %377)
  call void @cqrt_free(i32 %377)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %376, i32 %63, i64 %375)
  call void @cqrt_free(i32 %376)
  call void @cqrt_and_i1(i32 %235, i32 %25, i32 %371)
  call void @cqrt_free(i32 %371)
  %400 = add i32 %232, 1
  %401 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 %400)
  %402 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %402)
  call void @cqrt_xor_i1(i32 %401, i32 %402)
  %403 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %402, i32 %403)
  %404 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %404)
  %405 = call i32 @cqrt_alloc_i32(i32 0)
  %406 = getelementptr i8, ptr %5, i64 0
  %407 = ptrtoint ptr %406 to i64
  %408 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %404, i32 %4, i64 %407)
  %409 = call i32 @cq_template_zext_i8_to_i32(i32 %408)
  %410 = trunc i64 0 to i32
  %411 = call i32 @cq_template_shl_i32_hl(i32 %409, i32 %410)
  %412 = call i32 @cq_template_or_i32(i32 %411, i32 %405)
  %413 = add i64 0, 1
  %414 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %413)
  %415 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %415)
  call void @cqrt_xor_i1(i32 %414, i32 %415)
  %416 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %404, i32 %415, i32 %416)
  %417 = call i32 @cq_template_select_i32(i32 %404, i32 %412, i32 %405)
  %418 = getelementptr i8, ptr %5, i64 %413
  %419 = ptrtoint ptr %418 to i64
  %420 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %416, i32 %4, i64 %419)
  %421 = call i32 @cq_template_zext_i8_to_i32(i32 %420)
  %422 = trunc i64 %413 to i32
  %423 = call i32 @cq_template_shl_i32_hl(i32 %421, i32 %422)
  %424 = call i32 @cq_template_or_i32(i32 %423, i32 %417)
  %425 = add i64 %413, 1
  %426 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %425)
  %427 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %427)
  call void @cqrt_xor_i1(i32 %426, i32 %427)
  %428 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %416, i32 %427, i32 %428)
  %429 = call i32 @cq_template_select_i32(i32 %416, i32 %424, i32 %417)
  %430 = getelementptr i8, ptr %5, i64 %425
  %431 = ptrtoint ptr %430 to i64
  %432 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %428, i32 %4, i64 %431)
  %433 = call i32 @cq_template_zext_i8_to_i32(i32 %432)
  %434 = trunc i64 %425 to i32
  %435 = call i32 @cq_template_shl_i32_hl(i32 %433, i32 %434)
  %436 = call i32 @cq_template_or_i32(i32 %435, i32 %429)
  %437 = add i64 %425, 1
  %438 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %437)
  %439 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %439)
  call void @cqrt_xor_i1(i32 %438, i32 %439)
  %440 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %428, i32 %439, i32 %440)
  %441 = call i32 @cq_template_select_i32(i32 %428, i32 %436, i32 %429)
  %442 = getelementptr i8, ptr %5, i64 %437
  %443 = ptrtoint ptr %442 to i64
  %444 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %440, i32 %4, i64 %443)
  %445 = call i32 @cq_template_zext_i8_to_i32(i32 %444)
  %446 = trunc i64 %437 to i32
  %447 = call i32 @cq_template_shl_i32_hl(i32 %445, i32 %446)
  %448 = call i32 @cq_template_or_i32(i32 %447, i32 %441)
  %449 = add i64 %437, 1
  %450 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %449)
  %451 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %451)
  call void @cqrt_xor_i1(i32 %450, i32 %451)
  %452 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %440, i32 %451, i32 %452)
  call void @cqrt_xor_i1(i32 %450, i32 %451)
  call void @cqrt_not_i1(i32 %451)
  call void @cqrt_free(i32 %451)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %450, i32 %60, i64 %449)
  call void @cqrt_free(i32 %450)
  %453 = call i32 @cq_template_select_i32(i32 %440, i32 %448, i32 %441)
  %454 = call i32 @cq_template_icmp_eq_i32(i32 %453, i32 %1)
  %455 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %454, i32 %455)
  call void @cqrt_rz_i1(i32 %455, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %403, i32 %454, i32 %455)
  call void @cqrt_free(i32 %455)
  call void @cq_template_icmp_eq_i32_unc(i32 %454, i32 %453, i32 %1)
  call void @cqrt_free(i32 %454)
  call void @cq_template_select_i32_unc(i32 %453, i32 %440, i32 %448, i32 %441)
  call void @cqrt_free(i32 %453)
  call void @cq_template_or_i32_unc(i32 %448, i32 %447, i32 %441)
  call void @cqrt_free(i32 %448)
  call void @cq_template_shl_i32_hl_unc(i32 %447, i32 %445, i32 %446)
  call void @cqrt_free(i32 %447)
  call void @cq_template_zext_i8_to_i32_unc(i32 %445, i32 %444)
  call void @cqrt_free(i32 %445)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %444, i32 %440, i32 %4, i64 %443)
  call void @cqrt_free(i32 %444)
  call void @cq_template_select_i32_unc(i32 %441, i32 %428, i32 %436, i32 %429)
  call void @cqrt_free(i32 %441)
  call void @cqrt_and_i1(i32 %428, i32 %439, i32 %440)
  call void @cqrt_free(i32 %440)
  call void @cqrt_xor_i1(i32 %438, i32 %439)
  call void @cqrt_not_i1(i32 %439)
  call void @cqrt_free(i32 %439)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %438, i32 %60, i64 %437)
  call void @cqrt_free(i32 %438)
  call void @cq_template_or_i32_unc(i32 %436, i32 %435, i32 %429)
  call void @cqrt_free(i32 %436)
  call void @cq_template_shl_i32_hl_unc(i32 %435, i32 %433, i32 %434)
  call void @cqrt_free(i32 %435)
  call void @cq_template_zext_i8_to_i32_unc(i32 %433, i32 %432)
  call void @cqrt_free(i32 %433)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %432, i32 %428, i32 %4, i64 %431)
  call void @cqrt_free(i32 %432)
  call void @cq_template_select_i32_unc(i32 %429, i32 %416, i32 %424, i32 %417)
  call void @cqrt_free(i32 %429)
  call void @cqrt_and_i1(i32 %416, i32 %427, i32 %428)
  call void @cqrt_free(i32 %428)
  call void @cqrt_xor_i1(i32 %426, i32 %427)
  call void @cqrt_not_i1(i32 %427)
  call void @cqrt_free(i32 %427)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %426, i32 %60, i64 %425)
  call void @cqrt_free(i32 %426)
  call void @cq_template_or_i32_unc(i32 %424, i32 %423, i32 %417)
  call void @cqrt_free(i32 %424)
  call void @cq_template_shl_i32_hl_unc(i32 %423, i32 %421, i32 %422)
  call void @cqrt_free(i32 %423)
  call void @cq_template_zext_i8_to_i32_unc(i32 %421, i32 %420)
  call void @cqrt_free(i32 %421)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %420, i32 %416, i32 %4, i64 %419)
  call void @cqrt_free(i32 %420)
  call void @cq_template_select_i32_unc(i32 %417, i32 %404, i32 %412, i32 %405)
  call void @cqrt_free(i32 %417)
  call void @cqrt_and_i1(i32 %404, i32 %415, i32 %416)
  call void @cqrt_free(i32 %416)
  call void @cqrt_xor_i1(i32 %414, i32 %415)
  call void @cqrt_not_i1(i32 %415)
  call void @cqrt_free(i32 %415)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %414, i32 %60, i64 %413)
  call void @cqrt_free(i32 %414)
  call void @cq_template_or_i32_unc(i32 %412, i32 %411, i32 %405)
  call void @cqrt_free(i32 %412)
  call void @cq_template_shl_i32_hl_unc(i32 %411, i32 %409, i32 %410)
  call void @cqrt_free(i32 %411)
  call void @cq_template_zext_i8_to_i32_unc(i32 %409, i32 %408)
  call void @cqrt_free(i32 %409)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %408, i32 %404, i32 %4, i64 %407)
  call void @cqrt_free(i32 %408)
  call void @cqrt_free(i32 %405)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %404)
  call void @cqrt_free(i32 %404)
  call void @cqrt_invert_begin()
  %456 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %456)
  %457 = getelementptr i8, ptr %5, i64 0
  %458 = ptrtoint ptr %457 to i64
  %459 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %456, i32 %4, i64 %458, i32 %459)
  call void @cqrt_ry_i1_controlled(i32 %456, i32 %459, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %456, i32 %4, i64 %458, i32 %459)
  call void @cqrt_free(i32 %459)
  %460 = add i64 0, 1
  %461 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %460)
  %462 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %462)
  call void @cqrt_xor_i1(i32 %461, i32 %462)
  %463 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %456, i32 %462, i32 %463)
  %464 = getelementptr i8, ptr %5, i64 %460
  %465 = ptrtoint ptr %464 to i64
  %466 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %463, i32 %4, i64 %465, i32 %466)
  call void @cqrt_ry_i1_controlled(i32 %463, i32 %466, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %463, i32 %4, i64 %465, i32 %466)
  call void @cqrt_free(i32 %466)
  %467 = add i64 %460, 1
  %468 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %467)
  %469 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %469)
  call void @cqrt_xor_i1(i32 %468, i32 %469)
  %470 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %463, i32 %469, i32 %470)
  %471 = getelementptr i8, ptr %5, i64 %467
  %472 = ptrtoint ptr %471 to i64
  %473 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %470, i32 %4, i64 %472, i32 %473)
  call void @cqrt_ry_i1_controlled(i32 %470, i32 %473, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %470, i32 %4, i64 %472, i32 %473)
  call void @cqrt_free(i32 %473)
  %474 = add i64 %467, 1
  %475 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %474)
  %476 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %476)
  call void @cqrt_xor_i1(i32 %475, i32 %476)
  %477 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %470, i32 %476, i32 %477)
  %478 = getelementptr i8, ptr %5, i64 %474
  %479 = ptrtoint ptr %478 to i64
  %480 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %477, i32 %4, i64 %479, i32 %480)
  call void @cqrt_ry_i1_controlled(i32 %477, i32 %480, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %477, i32 %4, i64 %479, i32 %480)
  call void @cqrt_free(i32 %480)
  %481 = add i64 %474, 1
  %482 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %481)
  %483 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %483)
  call void @cqrt_xor_i1(i32 %482, i32 %483)
  %484 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %477, i32 %483, i32 %484)
  call void @cqrt_xor_i1(i32 %482, i32 %483)
  call void @cqrt_not_i1(i32 %483)
  call void @cqrt_free(i32 %483)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %482, i32 %61, i64 %481)
  call void @cqrt_free(i32 %482)
  call void @cqrt_and_i1(i32 %470, i32 %476, i32 %477)
  call void @cqrt_free(i32 %477)
  call void @cqrt_xor_i1(i32 %475, i32 %476)
  call void @cqrt_not_i1(i32 %476)
  call void @cqrt_free(i32 %476)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %475, i32 %61, i64 %474)
  call void @cqrt_free(i32 %475)
  call void @cqrt_and_i1(i32 %463, i32 %469, i32 %470)
  call void @cqrt_free(i32 %470)
  call void @cqrt_xor_i1(i32 %468, i32 %469)
  call void @cqrt_not_i1(i32 %469)
  call void @cqrt_free(i32 %469)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %468, i32 %61, i64 %467)
  call void @cqrt_free(i32 %468)
  call void @cqrt_and_i1(i32 %456, i32 %462, i32 %463)
  call void @cqrt_free(i32 %463)
  call void @cqrt_xor_i1(i32 %461, i32 %462)
  call void @cqrt_not_i1(i32 %462)
  call void @cqrt_free(i32 %462)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %461, i32 %61, i64 %460)
  call void @cqrt_free(i32 %461)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %456)
  call void @cqrt_free(i32 %456)
  call void @cqrt_invert_end()
  %485 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %481)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %485, i32 %61, i64 %481)
  call void @cqrt_free(i32 %485)
  %486 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %486)
  %487 = call i32 @cqrt_alloc_i32(i32 0)
  %488 = getelementptr i8, ptr %5, i64 0
  %489 = ptrtoint ptr %488 to i64
  %490 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %486, i32 %4, i64 %489)
  %491 = call i32 @cq_template_zext_i8_to_i32(i32 %490)
  %492 = trunc i64 0 to i32
  %493 = call i32 @cq_template_shl_i32_hl(i32 %491, i32 %492)
  %494 = call i32 @cq_template_or_i32(i32 %493, i32 %487)
  %495 = add i64 0, 1
  %496 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %495)
  %497 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %497)
  call void @cqrt_xor_i1(i32 %496, i32 %497)
  %498 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %486, i32 %497, i32 %498)
  %499 = call i32 @cq_template_select_i32(i32 %486, i32 %494, i32 %487)
  %500 = getelementptr i8, ptr %5, i64 %495
  %501 = ptrtoint ptr %500 to i64
  %502 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %498, i32 %4, i64 %501)
  %503 = call i32 @cq_template_zext_i8_to_i32(i32 %502)
  %504 = trunc i64 %495 to i32
  %505 = call i32 @cq_template_shl_i32_hl(i32 %503, i32 %504)
  %506 = call i32 @cq_template_or_i32(i32 %505, i32 %499)
  %507 = add i64 %495, 1
  %508 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %507)
  %509 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %509)
  call void @cqrt_xor_i1(i32 %508, i32 %509)
  %510 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %498, i32 %509, i32 %510)
  %511 = call i32 @cq_template_select_i32(i32 %498, i32 %506, i32 %499)
  %512 = getelementptr i8, ptr %5, i64 %507
  %513 = ptrtoint ptr %512 to i64
  %514 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %510, i32 %4, i64 %513)
  %515 = call i32 @cq_template_zext_i8_to_i32(i32 %514)
  %516 = trunc i64 %507 to i32
  %517 = call i32 @cq_template_shl_i32_hl(i32 %515, i32 %516)
  %518 = call i32 @cq_template_or_i32(i32 %517, i32 %511)
  %519 = add i64 %507, 1
  %520 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %519)
  %521 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %521)
  call void @cqrt_xor_i1(i32 %520, i32 %521)
  %522 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %510, i32 %521, i32 %522)
  %523 = call i32 @cq_template_select_i32(i32 %510, i32 %518, i32 %511)
  %524 = getelementptr i8, ptr %5, i64 %519
  %525 = ptrtoint ptr %524 to i64
  %526 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %522, i32 %4, i64 %525)
  %527 = call i32 @cq_template_zext_i8_to_i32(i32 %526)
  %528 = trunc i64 %519 to i32
  %529 = call i32 @cq_template_shl_i32_hl(i32 %527, i32 %528)
  %530 = call i32 @cq_template_or_i32(i32 %529, i32 %523)
  %531 = add i64 %519, 1
  %532 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %531)
  %533 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %533)
  call void @cqrt_xor_i1(i32 %532, i32 %533)
  %534 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %522, i32 %533, i32 %534)
  call void @cqrt_xor_i1(i32 %532, i32 %533)
  call void @cqrt_not_i1(i32 %533)
  call void @cqrt_free(i32 %533)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %532, i32 %62, i64 %531)
  call void @cqrt_free(i32 %532)
  %535 = call i32 @cq_template_select_i32(i32 %522, i32 %530, i32 %523)
  %536 = call i32 @cq_template_icmp_eq_i32_hl(i32 %535, i32 0)
  %537 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %537)
  call void @cqrt_xor_i1(i32 %536, i32 %537)
  %538 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %537, i32 %538)
  call void @cqrt_rz_i1(i32 %538, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %403, i32 %537, i32 %538)
  call void @cqrt_free(i32 %538)
  call void @cqrt_xor_i1(i32 %536, i32 %537)
  call void @cqrt_not_i1(i32 %537)
  call void @cqrt_free(i32 %537)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %536, i32 %535, i32 0)
  call void @cqrt_free(i32 %536)
  call void @cq_template_select_i32_unc(i32 %535, i32 %522, i32 %530, i32 %523)
  call void @cqrt_free(i32 %535)
  call void @cq_template_or_i32_unc(i32 %530, i32 %529, i32 %523)
  call void @cqrt_free(i32 %530)
  call void @cq_template_shl_i32_hl_unc(i32 %529, i32 %527, i32 %528)
  call void @cqrt_free(i32 %529)
  call void @cq_template_zext_i8_to_i32_unc(i32 %527, i32 %526)
  call void @cqrt_free(i32 %527)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %526, i32 %522, i32 %4, i64 %525)
  call void @cqrt_free(i32 %526)
  call void @cq_template_select_i32_unc(i32 %523, i32 %510, i32 %518, i32 %511)
  call void @cqrt_free(i32 %523)
  call void @cqrt_and_i1(i32 %510, i32 %521, i32 %522)
  call void @cqrt_free(i32 %522)
  call void @cqrt_xor_i1(i32 %520, i32 %521)
  call void @cqrt_not_i1(i32 %521)
  call void @cqrt_free(i32 %521)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %520, i32 %62, i64 %519)
  call void @cqrt_free(i32 %520)
  call void @cq_template_or_i32_unc(i32 %518, i32 %517, i32 %511)
  call void @cqrt_free(i32 %518)
  call void @cq_template_shl_i32_hl_unc(i32 %517, i32 %515, i32 %516)
  call void @cqrt_free(i32 %517)
  call void @cq_template_zext_i8_to_i32_unc(i32 %515, i32 %514)
  call void @cqrt_free(i32 %515)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %514, i32 %510, i32 %4, i64 %513)
  call void @cqrt_free(i32 %514)
  call void @cq_template_select_i32_unc(i32 %511, i32 %498, i32 %506, i32 %499)
  call void @cqrt_free(i32 %511)
  call void @cqrt_and_i1(i32 %498, i32 %509, i32 %510)
  call void @cqrt_free(i32 %510)
  call void @cqrt_xor_i1(i32 %508, i32 %509)
  call void @cqrt_not_i1(i32 %509)
  call void @cqrt_free(i32 %509)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %508, i32 %62, i64 %507)
  call void @cqrt_free(i32 %508)
  call void @cq_template_or_i32_unc(i32 %506, i32 %505, i32 %499)
  call void @cqrt_free(i32 %506)
  call void @cq_template_shl_i32_hl_unc(i32 %505, i32 %503, i32 %504)
  call void @cqrt_free(i32 %505)
  call void @cq_template_zext_i8_to_i32_unc(i32 %503, i32 %502)
  call void @cqrt_free(i32 %503)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %502, i32 %498, i32 %4, i64 %501)
  call void @cqrt_free(i32 %502)
  call void @cq_template_select_i32_unc(i32 %499, i32 %486, i32 %494, i32 %487)
  call void @cqrt_free(i32 %499)
  call void @cqrt_and_i1(i32 %486, i32 %497, i32 %498)
  call void @cqrt_free(i32 %498)
  call void @cqrt_xor_i1(i32 %496, i32 %497)
  call void @cqrt_not_i1(i32 %497)
  call void @cqrt_free(i32 %497)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %496, i32 %62, i64 %495)
  call void @cqrt_free(i32 %496)
  call void @cq_template_or_i32_unc(i32 %494, i32 %493, i32 %487)
  call void @cqrt_free(i32 %494)
  call void @cq_template_shl_i32_hl_unc(i32 %493, i32 %491, i32 %492)
  call void @cqrt_free(i32 %493)
  call void @cq_template_zext_i8_to_i32_unc(i32 %491, i32 %490)
  call void @cqrt_free(i32 %491)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %490, i32 %486, i32 %4, i64 %489)
  call void @cqrt_free(i32 %490)
  call void @cqrt_free(i32 %487)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %486)
  call void @cqrt_free(i32 %486)
  %539 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %539)
  %540 = getelementptr i8, ptr %5, i64 0
  %541 = ptrtoint ptr %540 to i64
  %542 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %539, i32 %4, i64 %541, i32 %542)
  call void @cqrt_ry_i1_controlled(i32 %539, i32 %542, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %539, i32 %4, i64 %541, i32 %542)
  call void @cqrt_free(i32 %542)
  %543 = add i64 0, 1
  %544 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %543)
  %545 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %545)
  call void @cqrt_xor_i1(i32 %544, i32 %545)
  %546 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %539, i32 %545, i32 %546)
  %547 = getelementptr i8, ptr %5, i64 %543
  %548 = ptrtoint ptr %547 to i64
  %549 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %546, i32 %4, i64 %548, i32 %549)
  call void @cqrt_ry_i1_controlled(i32 %546, i32 %549, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %546, i32 %4, i64 %548, i32 %549)
  call void @cqrt_free(i32 %549)
  %550 = add i64 %543, 1
  %551 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %550)
  %552 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %552)
  call void @cqrt_xor_i1(i32 %551, i32 %552)
  %553 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %546, i32 %552, i32 %553)
  %554 = getelementptr i8, ptr %5, i64 %550
  %555 = ptrtoint ptr %554 to i64
  %556 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %553, i32 %4, i64 %555, i32 %556)
  call void @cqrt_ry_i1_controlled(i32 %553, i32 %556, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %553, i32 %4, i64 %555, i32 %556)
  call void @cqrt_free(i32 %556)
  %557 = add i64 %550, 1
  %558 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %557)
  %559 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %559)
  call void @cqrt_xor_i1(i32 %558, i32 %559)
  %560 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %553, i32 %559, i32 %560)
  %561 = getelementptr i8, ptr %5, i64 %557
  %562 = ptrtoint ptr %561 to i64
  %563 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %560, i32 %4, i64 %562, i32 %563)
  call void @cqrt_ry_i1_controlled(i32 %560, i32 %563, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %560, i32 %4, i64 %562, i32 %563)
  call void @cqrt_free(i32 %563)
  %564 = add i64 %557, 1
  %565 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %564)
  %566 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %566)
  call void @cqrt_xor_i1(i32 %565, i32 %566)
  %567 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %560, i32 %566, i32 %567)
  call void @cqrt_xor_i1(i32 %565, i32 %566)
  call void @cqrt_not_i1(i32 %566)
  call void @cqrt_free(i32 %566)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %565, i32 %63, i64 %564)
  call void @cqrt_free(i32 %565)
  call void @cqrt_and_i1(i32 %553, i32 %559, i32 %560)
  call void @cqrt_free(i32 %560)
  call void @cqrt_xor_i1(i32 %558, i32 %559)
  call void @cqrt_not_i1(i32 %559)
  call void @cqrt_free(i32 %559)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %558, i32 %63, i64 %557)
  call void @cqrt_free(i32 %558)
  call void @cqrt_and_i1(i32 %546, i32 %552, i32 %553)
  call void @cqrt_free(i32 %553)
  call void @cqrt_xor_i1(i32 %551, i32 %552)
  call void @cqrt_not_i1(i32 %552)
  call void @cqrt_free(i32 %552)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %551, i32 %63, i64 %550)
  call void @cqrt_free(i32 %551)
  call void @cqrt_and_i1(i32 %539, i32 %545, i32 %546)
  call void @cqrt_free(i32 %546)
  call void @cqrt_xor_i1(i32 %544, i32 %545)
  call void @cqrt_not_i1(i32 %545)
  call void @cqrt_free(i32 %545)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %544, i32 %63, i64 %543)
  call void @cqrt_free(i32 %544)
  call void @cqrt_and_i1(i32 %403, i32 %25, i32 %539)
  call void @cqrt_free(i32 %539)
  %568 = add i32 %400, 1
  %569 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 %568)
  %570 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %570)
  call void @cqrt_xor_i1(i32 %569, i32 %570)
  %571 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %403, i32 %570, i32 %571)
  %572 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %572)
  %573 = call i32 @cqrt_alloc_i32(i32 0)
  %574 = getelementptr i8, ptr %5, i64 0
  %575 = ptrtoint ptr %574 to i64
  %576 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %572, i32 %4, i64 %575)
  %577 = call i32 @cq_template_zext_i8_to_i32(i32 %576)
  %578 = trunc i64 0 to i32
  %579 = call i32 @cq_template_shl_i32_hl(i32 %577, i32 %578)
  %580 = call i32 @cq_template_or_i32(i32 %579, i32 %573)
  %581 = add i64 0, 1
  %582 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %581)
  %583 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %583)
  call void @cqrt_xor_i1(i32 %582, i32 %583)
  %584 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %572, i32 %583, i32 %584)
  %585 = call i32 @cq_template_select_i32(i32 %572, i32 %580, i32 %573)
  %586 = getelementptr i8, ptr %5, i64 %581
  %587 = ptrtoint ptr %586 to i64
  %588 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %584, i32 %4, i64 %587)
  %589 = call i32 @cq_template_zext_i8_to_i32(i32 %588)
  %590 = trunc i64 %581 to i32
  %591 = call i32 @cq_template_shl_i32_hl(i32 %589, i32 %590)
  %592 = call i32 @cq_template_or_i32(i32 %591, i32 %585)
  %593 = add i64 %581, 1
  %594 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %593)
  %595 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %595)
  call void @cqrt_xor_i1(i32 %594, i32 %595)
  %596 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %584, i32 %595, i32 %596)
  %597 = call i32 @cq_template_select_i32(i32 %584, i32 %592, i32 %585)
  %598 = getelementptr i8, ptr %5, i64 %593
  %599 = ptrtoint ptr %598 to i64
  %600 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %596, i32 %4, i64 %599)
  %601 = call i32 @cq_template_zext_i8_to_i32(i32 %600)
  %602 = trunc i64 %593 to i32
  %603 = call i32 @cq_template_shl_i32_hl(i32 %601, i32 %602)
  %604 = call i32 @cq_template_or_i32(i32 %603, i32 %597)
  %605 = add i64 %593, 1
  %606 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %605)
  %607 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %607)
  call void @cqrt_xor_i1(i32 %606, i32 %607)
  %608 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %596, i32 %607, i32 %608)
  %609 = call i32 @cq_template_select_i32(i32 %596, i32 %604, i32 %597)
  %610 = getelementptr i8, ptr %5, i64 %605
  %611 = ptrtoint ptr %610 to i64
  %612 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %608, i32 %4, i64 %611)
  %613 = call i32 @cq_template_zext_i8_to_i32(i32 %612)
  %614 = trunc i64 %605 to i32
  %615 = call i32 @cq_template_shl_i32_hl(i32 %613, i32 %614)
  %616 = call i32 @cq_template_or_i32(i32 %615, i32 %609)
  %617 = add i64 %605, 1
  %618 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 %617)
  %619 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %619)
  call void @cqrt_xor_i1(i32 %618, i32 %619)
  %620 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %608, i32 %619, i32 %620)
  call void @cqrt_xor_i1(i32 %618, i32 %619)
  call void @cqrt_not_i1(i32 %619)
  call void @cqrt_free(i32 %619)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %618, i32 %60, i64 %617)
  call void @cqrt_free(i32 %618)
  %621 = call i32 @cq_template_select_i32(i32 %608, i32 %616, i32 %609)
  %622 = call i32 @cq_template_icmp_eq_i32(i32 %621, i32 %1)
  %623 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %622, i32 %623)
  call void @cqrt_rz_i1(i32 %623, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %571, i32 %622, i32 %623)
  call void @cqrt_free(i32 %623)
  call void @cq_template_icmp_eq_i32_unc(i32 %622, i32 %621, i32 %1)
  call void @cqrt_free(i32 %622)
  call void @cq_template_select_i32_unc(i32 %621, i32 %608, i32 %616, i32 %609)
  call void @cqrt_free(i32 %621)
  call void @cq_template_or_i32_unc(i32 %616, i32 %615, i32 %609)
  call void @cqrt_free(i32 %616)
  call void @cq_template_shl_i32_hl_unc(i32 %615, i32 %613, i32 %614)
  call void @cqrt_free(i32 %615)
  call void @cq_template_zext_i8_to_i32_unc(i32 %613, i32 %612)
  call void @cqrt_free(i32 %613)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %612, i32 %608, i32 %4, i64 %611)
  call void @cqrt_free(i32 %612)
  call void @cq_template_select_i32_unc(i32 %609, i32 %596, i32 %604, i32 %597)
  call void @cqrt_free(i32 %609)
  call void @cqrt_and_i1(i32 %596, i32 %607, i32 %608)
  call void @cqrt_free(i32 %608)
  call void @cqrt_xor_i1(i32 %606, i32 %607)
  call void @cqrt_not_i1(i32 %607)
  call void @cqrt_free(i32 %607)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %606, i32 %60, i64 %605)
  call void @cqrt_free(i32 %606)
  call void @cq_template_or_i32_unc(i32 %604, i32 %603, i32 %597)
  call void @cqrt_free(i32 %604)
  call void @cq_template_shl_i32_hl_unc(i32 %603, i32 %601, i32 %602)
  call void @cqrt_free(i32 %603)
  call void @cq_template_zext_i8_to_i32_unc(i32 %601, i32 %600)
  call void @cqrt_free(i32 %601)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %600, i32 %596, i32 %4, i64 %599)
  call void @cqrt_free(i32 %600)
  call void @cq_template_select_i32_unc(i32 %597, i32 %584, i32 %592, i32 %585)
  call void @cqrt_free(i32 %597)
  call void @cqrt_and_i1(i32 %584, i32 %595, i32 %596)
  call void @cqrt_free(i32 %596)
  call void @cqrt_xor_i1(i32 %594, i32 %595)
  call void @cqrt_not_i1(i32 %595)
  call void @cqrt_free(i32 %595)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %594, i32 %60, i64 %593)
  call void @cqrt_free(i32 %594)
  call void @cq_template_or_i32_unc(i32 %592, i32 %591, i32 %585)
  call void @cqrt_free(i32 %592)
  call void @cq_template_shl_i32_hl_unc(i32 %591, i32 %589, i32 %590)
  call void @cqrt_free(i32 %591)
  call void @cq_template_zext_i8_to_i32_unc(i32 %589, i32 %588)
  call void @cqrt_free(i32 %589)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %588, i32 %584, i32 %4, i64 %587)
  call void @cqrt_free(i32 %588)
  call void @cq_template_select_i32_unc(i32 %585, i32 %572, i32 %580, i32 %573)
  call void @cqrt_free(i32 %585)
  call void @cqrt_and_i1(i32 %572, i32 %583, i32 %584)
  call void @cqrt_free(i32 %584)
  call void @cqrt_xor_i1(i32 %582, i32 %583)
  call void @cqrt_not_i1(i32 %583)
  call void @cqrt_free(i32 %583)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %582, i32 %60, i64 %581)
  call void @cqrt_free(i32 %582)
  call void @cq_template_or_i32_unc(i32 %580, i32 %579, i32 %573)
  call void @cqrt_free(i32 %580)
  call void @cq_template_shl_i32_hl_unc(i32 %579, i32 %577, i32 %578)
  call void @cqrt_free(i32 %579)
  call void @cq_template_zext_i8_to_i32_unc(i32 %577, i32 %576)
  call void @cqrt_free(i32 %577)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %576, i32 %572, i32 %4, i64 %575)
  call void @cqrt_free(i32 %576)
  call void @cqrt_free(i32 %573)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %572)
  call void @cqrt_free(i32 %572)
  call void @cqrt_invert_begin()
  %624 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %624)
  %625 = getelementptr i8, ptr %5, i64 0
  %626 = ptrtoint ptr %625 to i64
  %627 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %624, i32 %4, i64 %626, i32 %627)
  call void @cqrt_ry_i1_controlled(i32 %624, i32 %627, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %624, i32 %4, i64 %626, i32 %627)
  call void @cqrt_free(i32 %627)
  %628 = add i64 0, 1
  %629 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %628)
  %630 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %630)
  call void @cqrt_xor_i1(i32 %629, i32 %630)
  %631 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %624, i32 %630, i32 %631)
  %632 = getelementptr i8, ptr %5, i64 %628
  %633 = ptrtoint ptr %632 to i64
  %634 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %631, i32 %4, i64 %633, i32 %634)
  call void @cqrt_ry_i1_controlled(i32 %631, i32 %634, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %631, i32 %4, i64 %633, i32 %634)
  call void @cqrt_free(i32 %634)
  %635 = add i64 %628, 1
  %636 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %635)
  %637 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %637)
  call void @cqrt_xor_i1(i32 %636, i32 %637)
  %638 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %631, i32 %637, i32 %638)
  %639 = getelementptr i8, ptr %5, i64 %635
  %640 = ptrtoint ptr %639 to i64
  %641 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %638, i32 %4, i64 %640, i32 %641)
  call void @cqrt_ry_i1_controlled(i32 %638, i32 %641, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %638, i32 %4, i64 %640, i32 %641)
  call void @cqrt_free(i32 %641)
  %642 = add i64 %635, 1
  %643 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %642)
  %644 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %644)
  call void @cqrt_xor_i1(i32 %643, i32 %644)
  %645 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %638, i32 %644, i32 %645)
  %646 = getelementptr i8, ptr %5, i64 %642
  %647 = ptrtoint ptr %646 to i64
  %648 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %645, i32 %4, i64 %647, i32 %648)
  call void @cqrt_ry_i1_controlled(i32 %645, i32 %648, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %645, i32 %4, i64 %647, i32 %648)
  call void @cqrt_free(i32 %648)
  %649 = add i64 %642, 1
  %650 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %649)
  %651 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %651)
  call void @cqrt_xor_i1(i32 %650, i32 %651)
  %652 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %645, i32 %651, i32 %652)
  call void @cqrt_xor_i1(i32 %650, i32 %651)
  call void @cqrt_not_i1(i32 %651)
  call void @cqrt_free(i32 %651)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %650, i32 %61, i64 %649)
  call void @cqrt_free(i32 %650)
  call void @cqrt_and_i1(i32 %638, i32 %644, i32 %645)
  call void @cqrt_free(i32 %645)
  call void @cqrt_xor_i1(i32 %643, i32 %644)
  call void @cqrt_not_i1(i32 %644)
  call void @cqrt_free(i32 %644)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %643, i32 %61, i64 %642)
  call void @cqrt_free(i32 %643)
  call void @cqrt_and_i1(i32 %631, i32 %637, i32 %638)
  call void @cqrt_free(i32 %638)
  call void @cqrt_xor_i1(i32 %636, i32 %637)
  call void @cqrt_not_i1(i32 %637)
  call void @cqrt_free(i32 %637)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %636, i32 %61, i64 %635)
  call void @cqrt_free(i32 %636)
  call void @cqrt_and_i1(i32 %624, i32 %630, i32 %631)
  call void @cqrt_free(i32 %631)
  call void @cqrt_xor_i1(i32 %629, i32 %630)
  call void @cqrt_not_i1(i32 %630)
  call void @cqrt_free(i32 %630)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %629, i32 %61, i64 %628)
  call void @cqrt_free(i32 %629)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %624)
  call void @cqrt_free(i32 %624)
  call void @cqrt_invert_end()
  %653 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 %649)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %653, i32 %61, i64 %649)
  call void @cqrt_free(i32 %653)
  %654 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %654)
  %655 = call i32 @cqrt_alloc_i32(i32 0)
  %656 = getelementptr i8, ptr %5, i64 0
  %657 = ptrtoint ptr %656 to i64
  %658 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %654, i32 %4, i64 %657)
  %659 = call i32 @cq_template_zext_i8_to_i32(i32 %658)
  %660 = trunc i64 0 to i32
  %661 = call i32 @cq_template_shl_i32_hl(i32 %659, i32 %660)
  %662 = call i32 @cq_template_or_i32(i32 %661, i32 %655)
  %663 = add i64 0, 1
  %664 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %663)
  %665 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %665)
  call void @cqrt_xor_i1(i32 %664, i32 %665)
  %666 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %654, i32 %665, i32 %666)
  %667 = call i32 @cq_template_select_i32(i32 %654, i32 %662, i32 %655)
  %668 = getelementptr i8, ptr %5, i64 %663
  %669 = ptrtoint ptr %668 to i64
  %670 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %666, i32 %4, i64 %669)
  %671 = call i32 @cq_template_zext_i8_to_i32(i32 %670)
  %672 = trunc i64 %663 to i32
  %673 = call i32 @cq_template_shl_i32_hl(i32 %671, i32 %672)
  %674 = call i32 @cq_template_or_i32(i32 %673, i32 %667)
  %675 = add i64 %663, 1
  %676 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %675)
  %677 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %677)
  call void @cqrt_xor_i1(i32 %676, i32 %677)
  %678 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %666, i32 %677, i32 %678)
  %679 = call i32 @cq_template_select_i32(i32 %666, i32 %674, i32 %667)
  %680 = getelementptr i8, ptr %5, i64 %675
  %681 = ptrtoint ptr %680 to i64
  %682 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %678, i32 %4, i64 %681)
  %683 = call i32 @cq_template_zext_i8_to_i32(i32 %682)
  %684 = trunc i64 %675 to i32
  %685 = call i32 @cq_template_shl_i32_hl(i32 %683, i32 %684)
  %686 = call i32 @cq_template_or_i32(i32 %685, i32 %679)
  %687 = add i64 %675, 1
  %688 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %687)
  %689 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %689)
  call void @cqrt_xor_i1(i32 %688, i32 %689)
  %690 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %678, i32 %689, i32 %690)
  %691 = call i32 @cq_template_select_i32(i32 %678, i32 %686, i32 %679)
  %692 = getelementptr i8, ptr %5, i64 %687
  %693 = ptrtoint ptr %692 to i64
  %694 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %690, i32 %4, i64 %693)
  %695 = call i32 @cq_template_zext_i8_to_i32(i32 %694)
  %696 = trunc i64 %687 to i32
  %697 = call i32 @cq_template_shl_i32_hl(i32 %695, i32 %696)
  %698 = call i32 @cq_template_or_i32(i32 %697, i32 %691)
  %699 = add i64 %687, 1
  %700 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %699)
  %701 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %701)
  call void @cqrt_xor_i1(i32 %700, i32 %701)
  %702 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %690, i32 %701, i32 %702)
  call void @cqrt_xor_i1(i32 %700, i32 %701)
  call void @cqrt_not_i1(i32 %701)
  call void @cqrt_free(i32 %701)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %700, i32 %62, i64 %699)
  call void @cqrt_free(i32 %700)
  %703 = call i32 @cq_template_select_i32(i32 %690, i32 %698, i32 %691)
  %704 = call i32 @cq_template_icmp_eq_i32_hl(i32 %703, i32 0)
  %705 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %705)
  call void @cqrt_xor_i1(i32 %704, i32 %705)
  %706 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %705, i32 %706)
  call void @cqrt_rz_i1(i32 %706, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %571, i32 %705, i32 %706)
  call void @cqrt_free(i32 %706)
  call void @cqrt_xor_i1(i32 %704, i32 %705)
  call void @cqrt_not_i1(i32 %705)
  call void @cqrt_free(i32 %705)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %704, i32 %703, i32 0)
  call void @cqrt_free(i32 %704)
  call void @cq_template_select_i32_unc(i32 %703, i32 %690, i32 %698, i32 %691)
  call void @cqrt_free(i32 %703)
  call void @cq_template_or_i32_unc(i32 %698, i32 %697, i32 %691)
  call void @cqrt_free(i32 %698)
  call void @cq_template_shl_i32_hl_unc(i32 %697, i32 %695, i32 %696)
  call void @cqrt_free(i32 %697)
  call void @cq_template_zext_i8_to_i32_unc(i32 %695, i32 %694)
  call void @cqrt_free(i32 %695)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %694, i32 %690, i32 %4, i64 %693)
  call void @cqrt_free(i32 %694)
  call void @cq_template_select_i32_unc(i32 %691, i32 %678, i32 %686, i32 %679)
  call void @cqrt_free(i32 %691)
  call void @cqrt_and_i1(i32 %678, i32 %689, i32 %690)
  call void @cqrt_free(i32 %690)
  call void @cqrt_xor_i1(i32 %688, i32 %689)
  call void @cqrt_not_i1(i32 %689)
  call void @cqrt_free(i32 %689)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %688, i32 %62, i64 %687)
  call void @cqrt_free(i32 %688)
  call void @cq_template_or_i32_unc(i32 %686, i32 %685, i32 %679)
  call void @cqrt_free(i32 %686)
  call void @cq_template_shl_i32_hl_unc(i32 %685, i32 %683, i32 %684)
  call void @cqrt_free(i32 %685)
  call void @cq_template_zext_i8_to_i32_unc(i32 %683, i32 %682)
  call void @cqrt_free(i32 %683)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %682, i32 %678, i32 %4, i64 %681)
  call void @cqrt_free(i32 %682)
  call void @cq_template_select_i32_unc(i32 %679, i32 %666, i32 %674, i32 %667)
  call void @cqrt_free(i32 %679)
  call void @cqrt_and_i1(i32 %666, i32 %677, i32 %678)
  call void @cqrt_free(i32 %678)
  call void @cqrt_xor_i1(i32 %676, i32 %677)
  call void @cqrt_not_i1(i32 %677)
  call void @cqrt_free(i32 %677)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %676, i32 %62, i64 %675)
  call void @cqrt_free(i32 %676)
  call void @cq_template_or_i32_unc(i32 %674, i32 %673, i32 %667)
  call void @cqrt_free(i32 %674)
  call void @cq_template_shl_i32_hl_unc(i32 %673, i32 %671, i32 %672)
  call void @cqrt_free(i32 %673)
  call void @cq_template_zext_i8_to_i32_unc(i32 %671, i32 %670)
  call void @cqrt_free(i32 %671)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %670, i32 %666, i32 %4, i64 %669)
  call void @cqrt_free(i32 %670)
  call void @cq_template_select_i32_unc(i32 %667, i32 %654, i32 %662, i32 %655)
  call void @cqrt_free(i32 %667)
  call void @cqrt_and_i1(i32 %654, i32 %665, i32 %666)
  call void @cqrt_free(i32 %666)
  call void @cqrt_xor_i1(i32 %664, i32 %665)
  call void @cqrt_not_i1(i32 %665)
  call void @cqrt_free(i32 %665)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %664, i32 %62, i64 %663)
  call void @cqrt_free(i32 %664)
  call void @cq_template_or_i32_unc(i32 %662, i32 %661, i32 %655)
  call void @cqrt_free(i32 %662)
  call void @cq_template_shl_i32_hl_unc(i32 %661, i32 %659, i32 %660)
  call void @cqrt_free(i32 %661)
  call void @cq_template_zext_i8_to_i32_unc(i32 %659, i32 %658)
  call void @cqrt_free(i32 %659)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %658, i32 %654, i32 %4, i64 %657)
  call void @cqrt_free(i32 %658)
  call void @cqrt_free(i32 %655)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %654)
  call void @cqrt_free(i32 %654)
  %707 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %707)
  %708 = getelementptr i8, ptr %5, i64 0
  %709 = ptrtoint ptr %708 to i64
  %710 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %707, i32 %4, i64 %709, i32 %710)
  call void @cqrt_ry_i1_controlled(i32 %707, i32 %710, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %707, i32 %4, i64 %709, i32 %710)
  call void @cqrt_free(i32 %710)
  %711 = add i64 0, 1
  %712 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %711)
  %713 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %713)
  call void @cqrt_xor_i1(i32 %712, i32 %713)
  %714 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %707, i32 %713, i32 %714)
  %715 = getelementptr i8, ptr %5, i64 %711
  %716 = ptrtoint ptr %715 to i64
  %717 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %714, i32 %4, i64 %716, i32 %717)
  call void @cqrt_ry_i1_controlled(i32 %714, i32 %717, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %714, i32 %4, i64 %716, i32 %717)
  call void @cqrt_free(i32 %717)
  %718 = add i64 %711, 1
  %719 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %718)
  %720 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %720)
  call void @cqrt_xor_i1(i32 %719, i32 %720)
  %721 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %714, i32 %720, i32 %721)
  %722 = getelementptr i8, ptr %5, i64 %718
  %723 = ptrtoint ptr %722 to i64
  %724 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %721, i32 %4, i64 %723, i32 %724)
  call void @cqrt_ry_i1_controlled(i32 %721, i32 %724, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %721, i32 %4, i64 %723, i32 %724)
  call void @cqrt_free(i32 %724)
  %725 = add i64 %718, 1
  %726 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %725)
  %727 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %727)
  call void @cqrt_xor_i1(i32 %726, i32 %727)
  %728 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %721, i32 %727, i32 %728)
  %729 = getelementptr i8, ptr %5, i64 %725
  %730 = ptrtoint ptr %729 to i64
  %731 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %728, i32 %4, i64 %730, i32 %731)
  call void @cqrt_ry_i1_controlled(i32 %728, i32 %731, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %728, i32 %4, i64 %730, i32 %731)
  call void @cqrt_free(i32 %731)
  %732 = add i64 %725, 1
  %733 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %732)
  %734 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %734)
  call void @cqrt_xor_i1(i32 %733, i32 %734)
  %735 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %728, i32 %734, i32 %735)
  call void @cqrt_xor_i1(i32 %733, i32 %734)
  call void @cqrt_not_i1(i32 %734)
  call void @cqrt_free(i32 %734)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %733, i32 %63, i64 %732)
  call void @cqrt_free(i32 %733)
  call void @cqrt_and_i1(i32 %721, i32 %727, i32 %728)
  call void @cqrt_free(i32 %728)
  call void @cqrt_xor_i1(i32 %726, i32 %727)
  call void @cqrt_not_i1(i32 %727)
  call void @cqrt_free(i32 %727)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %726, i32 %63, i64 %725)
  call void @cqrt_free(i32 %726)
  call void @cqrt_and_i1(i32 %714, i32 %720, i32 %721)
  call void @cqrt_free(i32 %721)
  call void @cqrt_xor_i1(i32 %719, i32 %720)
  call void @cqrt_not_i1(i32 %720)
  call void @cqrt_free(i32 %720)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %719, i32 %63, i64 %718)
  call void @cqrt_free(i32 %719)
  call void @cqrt_and_i1(i32 %707, i32 %713, i32 %714)
  call void @cqrt_free(i32 %714)
  call void @cqrt_xor_i1(i32 %712, i32 %713)
  call void @cqrt_not_i1(i32 %713)
  call void @cqrt_free(i32 %713)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %712, i32 %63, i64 %711)
  call void @cqrt_free(i32 %712)
  call void @cqrt_and_i1(i32 %571, i32 %25, i32 %707)
  call void @cqrt_free(i32 %707)
  %736 = add i32 %568, 1
  %737 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 %736)
  %738 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %738)
  call void @cqrt_xor_i1(i32 %737, i32 %738)
  %739 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %571, i32 %738, i32 %739)
  call void @cqrt_xor_i1(i32 %737, i32 %738)
  call void @cqrt_not_i1(i32 %738)
  call void @cqrt_free(i32 %738)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %737, i32 %14, i32 %736)
  call void @cqrt_free(i32 %737)
  call void @cqrt_and_i1(i32 %403, i32 %570, i32 %571)
  call void @cqrt_free(i32 %571)
  call void @cqrt_xor_i1(i32 %569, i32 %570)
  call void @cqrt_not_i1(i32 %570)
  call void @cqrt_free(i32 %570)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %569, i32 %14, i32 %568)
  call void @cqrt_free(i32 %569)
  call void @cqrt_and_i1(i32 %235, i32 %402, i32 %403)
  call void @cqrt_free(i32 %403)
  call void @cqrt_xor_i1(i32 %401, i32 %402)
  call void @cqrt_not_i1(i32 %402)
  call void @cqrt_free(i32 %402)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %401, i32 %14, i32 %400)
  call void @cqrt_free(i32 %401)
  call void @cqrt_and_i1(i32 %65, i32 %234, i32 %235)
  call void @cqrt_free(i32 %235)
  call void @cqrt_xor_i1(i32 %233, i32 %234)
  call void @cqrt_not_i1(i32 %234)
  call void @cqrt_free(i32 %234)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %233, i32 %14, i32 %232)
  call void @cqrt_free(i32 %233)
  call void @cqrt_and_i1(i32 %59, i32 %66, i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %9, i32 %67, i32 %66)
  call void @cqrt_free(i32 %66)
  call void @cqrt_xor_i1(i32 %7, i32 %67)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_free(i32 %67)
  %740 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  %741 = call i32 @cq_template_zext_i32_to_i64(i32 %0)
  br label %742

742:                                              ; preds = %64
  call void @cq_template_zext_i32_to_i64_unc(i32 %63, i32 %0)
  call void @cqrt_free(i32 %63)
  call void @cq_template_zext_i32_to_i64_unc(i32 %62, i32 %0)
  call void @cqrt_free(i32 %62)
  call void @cq_template_zext_i32_to_i64_unc(i32 %61, i32 %0)
  call void @cqrt_free(i32 %61)
  call void @cq_template_zext_i32_to_i64_unc(i32 %60, i32 %0)
  call void @cqrt_free(i32 %60)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %59, i32 %14, i32 0)
  call void @cqrt_free(i32 %59)
  call void @cq_template_zext_i32_to_i64_unc(i32 %26, i32 %0)
  call void @cqrt_free(i32 %26)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %25, i32 %0, i32 0)
  call void @cqrt_free(i32 %25)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_floor_f64_unc(i32 %13, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_fmul_f64_hl_unc(i32 %12, i32 %11, double 0x3FE921FB54442D18)
  call void @cqrt_free(i32 %12)
  call void @cq_template_sqrt_f64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_uitofp_i32_to_f64_unc(i32 %10, i32 %8)
  call void @cqrt_free(i32 %10)
  %743 = call i32 @cqrt_alloc_i1(i1 false)
  %744 = call i32 @cqrt_alloc_i1(i1 false)
  %745 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %745)
  call void @cqrt_xor_i1(i32 %7, i32 %745)
  call void @cqrt_and_i1(i32 %9, i32 %745, i32 %744)
  call void @cqrt_and_i1(i32 %740, i32 %744, i32 %743)
  %746 = call i32 @cqrt_alloc_i32(i32 0)
  %747 = getelementptr [16 x i8], ptr %5, i64 0, i64 0
  %748 = ptrtoint ptr %747 to i64
  %749 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %743, i32 %4, i64 %748)
  %750 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %749, i32 %750)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %749, i32 %743, i32 %4, i64 %748)
  call void @cqrt_free(i32 %749)
  %751 = call i1 @cqrt_measure_i1(i32 %750), !cq.measure !6
  %752 = zext i1 %751 to i32
  %753 = trunc i64 0 to i32
  %754 = shl i32 %752, %753
  %755 = call i32 @cq_template_or_i32_hl(i32 %746, i32 %754)
  %756 = add i64 0, 1
  %757 = call i32 @cq_template_icmp_eq_i64_hl(i32 %741, i64 %756)
  %758 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %758)
  call void @cqrt_xor_i1(i32 %757, i32 %758)
  %759 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %743, i32 %758, i32 %759)
  %760 = call i32 @cq_template_select_i32(i32 %743, i32 %755, i32 %746)
  %761 = getelementptr [16 x i8], ptr %5, i64 0, i64 %756
  %762 = ptrtoint ptr %761 to i64
  %763 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %759, i32 %4, i64 %762)
  %764 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %763, i32 %764)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %763, i32 %759, i32 %4, i64 %762)
  call void @cqrt_free(i32 %763)
  %765 = call i1 @cqrt_measure_i1(i32 %764), !cq.measure !6
  %766 = zext i1 %765 to i32
  %767 = trunc i64 %756 to i32
  %768 = shl i32 %766, %767
  %769 = call i32 @cq_template_or_i32_hl(i32 %760, i32 %768)
  %770 = add i64 %756, 1
  %771 = call i32 @cq_template_icmp_eq_i64_hl(i32 %741, i64 %770)
  %772 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %772)
  call void @cqrt_xor_i1(i32 %771, i32 %772)
  %773 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %759, i32 %772, i32 %773)
  %774 = call i32 @cq_template_select_i32(i32 %759, i32 %769, i32 %760)
  %775 = getelementptr [16 x i8], ptr %5, i64 0, i64 %770
  %776 = ptrtoint ptr %775 to i64
  %777 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %773, i32 %4, i64 %776)
  %778 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %777, i32 %778)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %777, i32 %773, i32 %4, i64 %776)
  call void @cqrt_free(i32 %777)
  %779 = call i1 @cqrt_measure_i1(i32 %778), !cq.measure !6
  %780 = zext i1 %779 to i32
  %781 = trunc i64 %770 to i32
  %782 = shl i32 %780, %781
  %783 = call i32 @cq_template_or_i32_hl(i32 %774, i32 %782)
  %784 = add i64 %770, 1
  %785 = call i32 @cq_template_icmp_eq_i64_hl(i32 %741, i64 %784)
  %786 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %786)
  call void @cqrt_xor_i1(i32 %785, i32 %786)
  %787 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %773, i32 %786, i32 %787)
  %788 = call i32 @cq_template_select_i32(i32 %773, i32 %783, i32 %774)
  %789 = getelementptr [16 x i8], ptr %5, i64 0, i64 %784
  %790 = ptrtoint ptr %789 to i64
  %791 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %787, i32 %4, i64 %790)
  %792 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %791, i32 %792)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %791, i32 %787, i32 %4, i64 %790)
  call void @cqrt_free(i32 %791)
  %793 = call i1 @cqrt_measure_i1(i32 %792), !cq.measure !6
  %794 = zext i1 %793 to i32
  %795 = trunc i64 %784 to i32
  %796 = shl i32 %794, %795
  %797 = call i32 @cq_template_or_i32_hl(i32 %788, i32 %796)
  %798 = add i64 %784, 1
  %799 = call i32 @cq_template_icmp_eq_i64_hl(i32 %741, i64 %798)
  %800 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %800)
  call void @cqrt_xor_i1(i32 %799, i32 %800)
  %801 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %787, i32 %800, i32 %801)
  call void @cqrt_xor_i1(i32 %799, i32 %800)
  call void @cqrt_not_i1(i32 %800)
  call void @cqrt_free(i32 %800)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %799, i32 %741, i64 %798)
  call void @cqrt_free(i32 %799)
  %802 = call i32 @cq_template_select_i32(i32 %787, i32 %797, i32 %788)
  %803 = call i32 @cqrt_alloc_i1(i1 false)
  %804 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %804)
  call void @cqrt_xor_i1(i32 %7, i32 %804)
  call void @cqrt_and_i1(i32 %9, i32 %804, i32 %803)
  %805 = call i32 @cq_template_select_i32_hl(i32 %803, i32 %802, i32 -1)
  %806 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %806)
  %807 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %805, i32 %807)
  call void @cq_template_select_i32_hl_unc(i32 %805, i32 %803, i32 %802, i32 -1)
  call void @cqrt_free(i32 %805)
  call void @cqrt_and_i1(i32 %9, i32 %804, i32 %803)
  call void @cqrt_free(i32 %803)
  call void @cqrt_xor_i1(i32 %7, i32 %804)
  call void @cqrt_not_i1(i32 %804)
  call void @cqrt_free(i32 %804)
  call void @cq_template_select_i32_unc(i32 %802, i32 %787, i32 %797, i32 %788)
  call void @cqrt_free(i32 %802)
  call void @cq_template_or_i32_hl_unc(i32 %797, i32 %788, i32 %796)
  call void @cqrt_free(i32 %797)
  call void @cq_template_select_i32_unc(i32 %788, i32 %773, i32 %783, i32 %774)
  call void @cqrt_free(i32 %788)
  call void @cqrt_and_i1(i32 %773, i32 %786, i32 %787)
  call void @cqrt_free(i32 %787)
  call void @cqrt_xor_i1(i32 %785, i32 %786)
  call void @cqrt_not_i1(i32 %786)
  call void @cqrt_free(i32 %786)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %785, i32 %741, i64 %784)
  call void @cqrt_free(i32 %785)
  call void @cq_template_or_i32_hl_unc(i32 %783, i32 %774, i32 %782)
  call void @cqrt_free(i32 %783)
  call void @cq_template_select_i32_unc(i32 %774, i32 %759, i32 %769, i32 %760)
  call void @cqrt_free(i32 %774)
  call void @cqrt_and_i1(i32 %759, i32 %772, i32 %773)
  call void @cqrt_free(i32 %773)
  call void @cqrt_xor_i1(i32 %771, i32 %772)
  call void @cqrt_not_i1(i32 %772)
  call void @cqrt_free(i32 %772)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %771, i32 %741, i64 %770)
  call void @cqrt_free(i32 %771)
  call void @cq_template_or_i32_hl_unc(i32 %769, i32 %760, i32 %768)
  call void @cqrt_free(i32 %769)
  call void @cq_template_select_i32_unc(i32 %760, i32 %743, i32 %755, i32 %746)
  call void @cqrt_free(i32 %760)
  call void @cqrt_and_i1(i32 %743, i32 %758, i32 %759)
  call void @cqrt_free(i32 %759)
  call void @cqrt_xor_i1(i32 %757, i32 %758)
  call void @cqrt_not_i1(i32 %758)
  call void @cqrt_free(i32 %758)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %757, i32 %741, i64 %756)
  call void @cqrt_free(i32 %757)
  call void @cq_template_or_i32_hl_unc(i32 %755, i32 %746, i32 %754)
  call void @cqrt_free(i32 %755)
  call void @cqrt_free(i32 %746)
  call void @cqrt_and_i1(i32 %740, i32 %744, i32 %743)
  call void @cqrt_free(i32 %743)
  call void @cqrt_and_i1(i32 %9, i32 %745, i32 %744)
  call void @cqrt_free(i32 %744)
  call void @cqrt_xor_i1(i32 %7, i32 %745)
  call void @cqrt_not_i1(i32 %745)
  call void @cqrt_free(i32 %745)
  call void @cq_template_zext_i32_to_i64_unc(i32 %741, i32 %0)
  call void @cqrt_free(i32 %741)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %740, i32 %0, i32 0)
  call void @cqrt_free(i32 %740)
  call void @cq_template_icmp_ugt_i32_unc(i32 %9, i32 %8, i32 %1)
  call void @cqrt_free(i32 %9)
  call void @cq_template_shl_i32_lh_unc(i32 %8, i32 1, i32 %0)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %7, i32 %6, i32 -16)
  call void @cqrt_free(i32 %7)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %0, i32 -17)
  call void @cqrt_free(i32 %6)
  ret i32 %807
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare i32 @cq_template_shl_i32_lh(i32, i32)

declare i32 @cq_template_icmp_ugt_i32(i32, i32)

declare i32 @cq_template_uitofp_i32_to_f64(i32)

declare i32 @cq_template_sqrt_f64(i32)

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare i32 @cq_template_floor_f64(i32)

declare i32 @cq_template_fptosi_f64_to_i32(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare void @cqrt_qram_swap_i1_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32(i32, i32)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare i32 @cqrt_qram_load_i1_hl_controlled(i32, i32, i64)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_or_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

define internal void @__cq_mints_push(ptr %0) {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi ptr [ %0, %1 ], [ %10, %6 ]
  %4 = phi i32 [ 0, %1 ], [ %11, %6 ]
  %5 = icmp eq ptr %3, null
  br i1 %5, label %12, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds { i32, ptr }, ptr %3, i32 0, i32 0
  %8 = load i32, ptr %7, align 4
  call void @cqrt_push(i32 %8)
  %9 = getelementptr inbounds { i32, ptr }, ptr %3, i32 0, i32 1
  %10 = load ptr, ptr %9, align 8
  %11 = add i32 %4, 1
  br label %2

12:                                               ; preds = %2
  call void @cqrt_push(i32 %4)
  ret void
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_or_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i1_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_eq_i32_unc(i32, i32, i32)

declare void @cq_template_fptosi_f64_to_i32_unc(i32, i32)

declare void @cq_template_floor_f64_unc(i32, i32)

declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

declare void @cq_template_sqrt_f64_unc(i32, i32)

declare void @cq_template_uitofp_i32_to_f64_unc(i32, i32)

declare void @cq_template_icmp_ugt_i32_unc(i32, i32, i32)

declare void @cq_template_shl_i32_lh_unc(i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_grover_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_grover, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_grover, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %819

8:                                                ; preds = %4
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @__cq_mem()
  %10 = call ptr @__cq_alloc(i64 16, i64 16)
  %11 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -17)
  %12 = call i32 @cq_template_icmp_ult_i32_hl(i32 %11, i32 -16)
  %13 = call i32 @cq_template_shl_i32_lh(i32 1, i32 %1)
  %14 = call i32 @cq_template_icmp_ugt_i32(i32 %13, i32 %2)
  %15 = call i32 @cq_template_uitofp_i32_to_f64(i32 %13)
  %16 = call i32 @cq_template_sqrt_f64(i32 %15)
  %17 = call i32 @cq_template_fmul_f64_hl(i32 %16, double 0x3FE921FB54442D18)
  %18 = call i32 @cq_template_floor_f64(i32 %17)
  %19 = call i32 @cq_template_fptosi_f64_to_i32(i32 %18)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_xor_i1(i32 %12, i32 %22)
  call void @cqrt_and_i1(i32 %14, i32 %22, i32 %21)
  call void @cqrt_and_i1(i32 %0, i32 %21, i32 %20)
  call void @cqrt_and_i1(i32 %14, i32 %22, i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cqrt_xor_i1(i32 %12, i32 %22)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_free(i32 %22)
  %23 = ptrtoint ptr %10 to i64
  %24 = call i32 @cqrt_alloc_i8(i8 0)
  br label %25

25:                                               ; preds = %25, %8
  %26 = phi i64 [ 0, %8 ], [ %28, %25 ]
  %27 = add i64 %23, %26
  call void @cqrt_qram_store_i8_hl_controlled(i32 %20, i32 %9, i64 %27, i32 %24)
  %28 = add nuw i64 %26, 1
  %29 = icmp eq i64 %28, 16
  br i1 %29, label %30, label %25

30:                                               ; preds = %25
  %31 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  %32 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  br label %33

33:                                               ; preds = %30
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_xor_i1(i32 %12, i32 %37)
  call void @cqrt_and_i1(i32 %14, i32 %37, i32 %36)
  call void @cqrt_and_i1(i32 %31, i32 %36, i32 %35)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %34)
  %38 = getelementptr i8, ptr %10, i64 0
  %39 = ptrtoint ptr %38 to i64
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %34, i32 %9, i64 %39, i32 %40)
  call void @cqrt_ry_i1_controlled(i32 %34, i32 %40, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %34, i32 %9, i64 %39, i32 %40)
  call void @cqrt_free(i32 %40)
  %41 = add i64 0, 1
  %42 = call i32 @cq_template_icmp_eq_i64_hl(i32 %32, i64 %41)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_xor_i1(i32 %42, i32 %43)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %34, i32 %43, i32 %44)
  %45 = getelementptr i8, ptr %10, i64 %41
  %46 = ptrtoint ptr %45 to i64
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %44, i32 %9, i64 %46, i32 %47)
  call void @cqrt_ry_i1_controlled(i32 %44, i32 %47, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %44, i32 %9, i64 %46, i32 %47)
  call void @cqrt_free(i32 %47)
  %48 = add i64 %41, 1
  %49 = call i32 @cq_template_icmp_eq_i64_hl(i32 %32, i64 %48)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_xor_i1(i32 %49, i32 %50)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %50, i32 %51)
  %52 = getelementptr i8, ptr %10, i64 %48
  %53 = ptrtoint ptr %52 to i64
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %51, i32 %9, i64 %53, i32 %54)
  call void @cqrt_ry_i1_controlled(i32 %51, i32 %54, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %51, i32 %9, i64 %53, i32 %54)
  call void @cqrt_free(i32 %54)
  %55 = add i64 %48, 1
  %56 = call i32 @cq_template_icmp_eq_i64_hl(i32 %32, i64 %55)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_xor_i1(i32 %56, i32 %57)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %57, i32 %58)
  %59 = getelementptr i8, ptr %10, i64 %55
  %60 = ptrtoint ptr %59 to i64
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %58, i32 %9, i64 %60, i32 %61)
  call void @cqrt_ry_i1_controlled(i32 %58, i32 %61, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %58, i32 %9, i64 %60, i32 %61)
  call void @cqrt_free(i32 %61)
  %62 = add i64 %55, 1
  %63 = call i32 @cq_template_icmp_eq_i64_hl(i32 %32, i64 %62)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %64)
  call void @cqrt_xor_i1(i32 %63, i32 %64)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %58, i32 %64, i32 %65)
  call void @cqrt_xor_i1(i32 %63, i32 %64)
  call void @cqrt_not_i1(i32 %64)
  call void @cqrt_free(i32 %64)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %63, i32 %32, i64 %62)
  call void @cqrt_free(i32 %63)
  call void @cqrt_and_i1(i32 %51, i32 %57, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_xor_i1(i32 %56, i32 %57)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %56, i32 %32, i64 %55)
  call void @cqrt_free(i32 %56)
  call void @cqrt_and_i1(i32 %44, i32 %50, i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cqrt_xor_i1(i32 %49, i32 %50)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %49, i32 %32, i64 %48)
  call void @cqrt_free(i32 %49)
  call void @cqrt_and_i1(i32 %34, i32 %43, i32 %44)
  call void @cqrt_free(i32 %44)
  call void @cqrt_xor_i1(i32 %42, i32 %43)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %42, i32 %32, i64 %41)
  call void @cqrt_free(i32 %42)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_and_i1(i32 %31, i32 %36, i32 %35)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %14, i32 %37, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_xor_i1(i32 %12, i32 %37)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_free(i32 %37)
  %66 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %19, i32 0)
  %67 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  %68 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  %69 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  %70 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  br label %71

71:                                               ; preds = %33
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %75)
  call void @cqrt_xor_i1(i32 %12, i32 %75)
  call void @cqrt_and_i1(i32 %14, i32 %75, i32 %74)
  call void @cqrt_and_i1(i32 %66, i32 %74, i32 %73)
  call void @cqrt_and_i1(i32 %0, i32 %73, i32 %72)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %76)
  %77 = call i32 @cqrt_alloc_i32(i32 0)
  %78 = getelementptr i8, ptr %10, i64 0
  %79 = ptrtoint ptr %78 to i64
  %80 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %76, i32 %9, i64 %79)
  %81 = call i32 @cq_template_zext_i8_to_i32(i32 %80)
  %82 = trunc i64 0 to i32
  %83 = call i32 @cq_template_shl_i32_hl(i32 %81, i32 %82)
  %84 = call i32 @cq_template_or_i32(i32 %83, i32 %77)
  %85 = add i64 0, 1
  %86 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %85)
  %87 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %87)
  call void @cqrt_xor_i1(i32 %86, i32 %87)
  %88 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %76, i32 %87, i32 %88)
  %89 = call i32 @cq_template_select_i32(i32 %76, i32 %84, i32 %77)
  %90 = getelementptr i8, ptr %10, i64 %85
  %91 = ptrtoint ptr %90 to i64
  %92 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %88, i32 %9, i64 %91)
  %93 = call i32 @cq_template_zext_i8_to_i32(i32 %92)
  %94 = trunc i64 %85 to i32
  %95 = call i32 @cq_template_shl_i32_hl(i32 %93, i32 %94)
  %96 = call i32 @cq_template_or_i32(i32 %95, i32 %89)
  %97 = add i64 %85, 1
  %98 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %97)
  %99 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %99)
  call void @cqrt_xor_i1(i32 %98, i32 %99)
  %100 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %88, i32 %99, i32 %100)
  %101 = call i32 @cq_template_select_i32(i32 %88, i32 %96, i32 %89)
  %102 = getelementptr i8, ptr %10, i64 %97
  %103 = ptrtoint ptr %102 to i64
  %104 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %100, i32 %9, i64 %103)
  %105 = call i32 @cq_template_zext_i8_to_i32(i32 %104)
  %106 = trunc i64 %97 to i32
  %107 = call i32 @cq_template_shl_i32_hl(i32 %105, i32 %106)
  %108 = call i32 @cq_template_or_i32(i32 %107, i32 %101)
  %109 = add i64 %97, 1
  %110 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %109)
  %111 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %111)
  call void @cqrt_xor_i1(i32 %110, i32 %111)
  %112 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %100, i32 %111, i32 %112)
  %113 = call i32 @cq_template_select_i32(i32 %100, i32 %108, i32 %101)
  %114 = getelementptr i8, ptr %10, i64 %109
  %115 = ptrtoint ptr %114 to i64
  %116 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %112, i32 %9, i64 %115)
  %117 = call i32 @cq_template_zext_i8_to_i32(i32 %116)
  %118 = trunc i64 %109 to i32
  %119 = call i32 @cq_template_shl_i32_hl(i32 %117, i32 %118)
  %120 = call i32 @cq_template_or_i32(i32 %119, i32 %113)
  %121 = add i64 %109, 1
  %122 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %121)
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %123)
  call void @cqrt_xor_i1(i32 %122, i32 %123)
  %124 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %112, i32 %123, i32 %124)
  call void @cqrt_xor_i1(i32 %122, i32 %123)
  call void @cqrt_not_i1(i32 %123)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %122, i32 %67, i64 %121)
  call void @cqrt_free(i32 %122)
  %125 = call i32 @cq_template_select_i32(i32 %112, i32 %120, i32 %113)
  %126 = call i32 @cq_template_icmp_eq_i32(i32 %125, i32 %2)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %126, i32 %127)
  call void @cqrt_rz_i1(i32 %127, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %72, i32 %126, i32 %127)
  call void @cqrt_free(i32 %127)
  call void @cq_template_icmp_eq_i32_unc(i32 %126, i32 %125, i32 %2)
  call void @cqrt_free(i32 %126)
  call void @cq_template_select_i32_unc(i32 %125, i32 %112, i32 %120, i32 %113)
  call void @cqrt_free(i32 %125)
  call void @cq_template_or_i32_unc(i32 %120, i32 %119, i32 %113)
  call void @cqrt_free(i32 %120)
  call void @cq_template_shl_i32_hl_unc(i32 %119, i32 %117, i32 %118)
  call void @cqrt_free(i32 %119)
  call void @cq_template_zext_i8_to_i32_unc(i32 %117, i32 %116)
  call void @cqrt_free(i32 %117)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %116, i32 %112, i32 %9, i64 %115)
  call void @cqrt_free(i32 %116)
  call void @cq_template_select_i32_unc(i32 %113, i32 %100, i32 %108, i32 %101)
  call void @cqrt_free(i32 %113)
  call void @cqrt_and_i1(i32 %100, i32 %111, i32 %112)
  call void @cqrt_free(i32 %112)
  call void @cqrt_xor_i1(i32 %110, i32 %111)
  call void @cqrt_not_i1(i32 %111)
  call void @cqrt_free(i32 %111)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %110, i32 %67, i64 %109)
  call void @cqrt_free(i32 %110)
  call void @cq_template_or_i32_unc(i32 %108, i32 %107, i32 %101)
  call void @cqrt_free(i32 %108)
  call void @cq_template_shl_i32_hl_unc(i32 %107, i32 %105, i32 %106)
  call void @cqrt_free(i32 %107)
  call void @cq_template_zext_i8_to_i32_unc(i32 %105, i32 %104)
  call void @cqrt_free(i32 %105)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %104, i32 %100, i32 %9, i64 %103)
  call void @cqrt_free(i32 %104)
  call void @cq_template_select_i32_unc(i32 %101, i32 %88, i32 %96, i32 %89)
  call void @cqrt_free(i32 %101)
  call void @cqrt_and_i1(i32 %88, i32 %99, i32 %100)
  call void @cqrt_free(i32 %100)
  call void @cqrt_xor_i1(i32 %98, i32 %99)
  call void @cqrt_not_i1(i32 %99)
  call void @cqrt_free(i32 %99)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %98, i32 %67, i64 %97)
  call void @cqrt_free(i32 %98)
  call void @cq_template_or_i32_unc(i32 %96, i32 %95, i32 %89)
  call void @cqrt_free(i32 %96)
  call void @cq_template_shl_i32_hl_unc(i32 %95, i32 %93, i32 %94)
  call void @cqrt_free(i32 %95)
  call void @cq_template_zext_i8_to_i32_unc(i32 %93, i32 %92)
  call void @cqrt_free(i32 %93)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %92, i32 %88, i32 %9, i64 %91)
  call void @cqrt_free(i32 %92)
  call void @cq_template_select_i32_unc(i32 %89, i32 %76, i32 %84, i32 %77)
  call void @cqrt_free(i32 %89)
  call void @cqrt_and_i1(i32 %76, i32 %87, i32 %88)
  call void @cqrt_free(i32 %88)
  call void @cqrt_xor_i1(i32 %86, i32 %87)
  call void @cqrt_not_i1(i32 %87)
  call void @cqrt_free(i32 %87)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %86, i32 %67, i64 %85)
  call void @cqrt_free(i32 %86)
  call void @cq_template_or_i32_unc(i32 %84, i32 %83, i32 %77)
  call void @cqrt_free(i32 %84)
  call void @cq_template_shl_i32_hl_unc(i32 %83, i32 %81, i32 %82)
  call void @cqrt_free(i32 %83)
  call void @cq_template_zext_i8_to_i32_unc(i32 %81, i32 %80)
  call void @cqrt_free(i32 %81)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %80, i32 %76, i32 %9, i64 %79)
  call void @cqrt_free(i32 %80)
  call void @cqrt_free(i32 %77)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %76)
  call void @cqrt_free(i32 %76)
  call void @cqrt_invert_begin()
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %128)
  %129 = getelementptr i8, ptr %10, i64 0
  %130 = ptrtoint ptr %129 to i64
  %131 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %128, i32 %9, i64 %130, i32 %131)
  call void @cqrt_ry_i1_controlled(i32 %128, i32 %131, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %128, i32 %9, i64 %130, i32 %131)
  call void @cqrt_free(i32 %131)
  %132 = add i64 0, 1
  %133 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %132)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %134)
  call void @cqrt_xor_i1(i32 %133, i32 %134)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %128, i32 %134, i32 %135)
  %136 = getelementptr i8, ptr %10, i64 %132
  %137 = ptrtoint ptr %136 to i64
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %135, i32 %9, i64 %137, i32 %138)
  call void @cqrt_ry_i1_controlled(i32 %135, i32 %138, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %135, i32 %9, i64 %137, i32 %138)
  call void @cqrt_free(i32 %138)
  %139 = add i64 %132, 1
  %140 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %139)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %141)
  call void @cqrt_xor_i1(i32 %140, i32 %141)
  %142 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %135, i32 %141, i32 %142)
  %143 = getelementptr i8, ptr %10, i64 %139
  %144 = ptrtoint ptr %143 to i64
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %142, i32 %9, i64 %144, i32 %145)
  call void @cqrt_ry_i1_controlled(i32 %142, i32 %145, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %142, i32 %9, i64 %144, i32 %145)
  call void @cqrt_free(i32 %145)
  %146 = add i64 %139, 1
  %147 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %146)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %148)
  call void @cqrt_xor_i1(i32 %147, i32 %148)
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %142, i32 %148, i32 %149)
  %150 = getelementptr i8, ptr %10, i64 %146
  %151 = ptrtoint ptr %150 to i64
  %152 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %149, i32 %9, i64 %151, i32 %152)
  call void @cqrt_ry_i1_controlled(i32 %149, i32 %152, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %149, i32 %9, i64 %151, i32 %152)
  call void @cqrt_free(i32 %152)
  %153 = add i64 %146, 1
  %154 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %153)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %155)
  call void @cqrt_xor_i1(i32 %154, i32 %155)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %149, i32 %155, i32 %156)
  call void @cqrt_xor_i1(i32 %154, i32 %155)
  call void @cqrt_not_i1(i32 %155)
  call void @cqrt_free(i32 %155)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %154, i32 %68, i64 %153)
  call void @cqrt_free(i32 %154)
  call void @cqrt_and_i1(i32 %142, i32 %148, i32 %149)
  call void @cqrt_free(i32 %149)
  call void @cqrt_xor_i1(i32 %147, i32 %148)
  call void @cqrt_not_i1(i32 %148)
  call void @cqrt_free(i32 %148)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %147, i32 %68, i64 %146)
  call void @cqrt_free(i32 %147)
  call void @cqrt_and_i1(i32 %135, i32 %141, i32 %142)
  call void @cqrt_free(i32 %142)
  call void @cqrt_xor_i1(i32 %140, i32 %141)
  call void @cqrt_not_i1(i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %140, i32 %68, i64 %139)
  call void @cqrt_free(i32 %140)
  call void @cqrt_and_i1(i32 %128, i32 %134, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cqrt_xor_i1(i32 %133, i32 %134)
  call void @cqrt_not_i1(i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %133, i32 %68, i64 %132)
  call void @cqrt_free(i32 %133)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %128)
  call void @cqrt_free(i32 %128)
  call void @cqrt_invert_end()
  %157 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %153)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %157, i32 %68, i64 %153)
  call void @cqrt_free(i32 %157)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %158)
  %159 = call i32 @cqrt_alloc_i32(i32 0)
  %160 = getelementptr i8, ptr %10, i64 0
  %161 = ptrtoint ptr %160 to i64
  %162 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %158, i32 %9, i64 %161)
  %163 = call i32 @cq_template_zext_i8_to_i32(i32 %162)
  %164 = trunc i64 0 to i32
  %165 = call i32 @cq_template_shl_i32_hl(i32 %163, i32 %164)
  %166 = call i32 @cq_template_or_i32(i32 %165, i32 %159)
  %167 = add i64 0, 1
  %168 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %167)
  %169 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %169)
  call void @cqrt_xor_i1(i32 %168, i32 %169)
  %170 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %158, i32 %169, i32 %170)
  %171 = call i32 @cq_template_select_i32(i32 %158, i32 %166, i32 %159)
  %172 = getelementptr i8, ptr %10, i64 %167
  %173 = ptrtoint ptr %172 to i64
  %174 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %170, i32 %9, i64 %173)
  %175 = call i32 @cq_template_zext_i8_to_i32(i32 %174)
  %176 = trunc i64 %167 to i32
  %177 = call i32 @cq_template_shl_i32_hl(i32 %175, i32 %176)
  %178 = call i32 @cq_template_or_i32(i32 %177, i32 %171)
  %179 = add i64 %167, 1
  %180 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %179)
  %181 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %181)
  call void @cqrt_xor_i1(i32 %180, i32 %181)
  %182 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %170, i32 %181, i32 %182)
  %183 = call i32 @cq_template_select_i32(i32 %170, i32 %178, i32 %171)
  %184 = getelementptr i8, ptr %10, i64 %179
  %185 = ptrtoint ptr %184 to i64
  %186 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %182, i32 %9, i64 %185)
  %187 = call i32 @cq_template_zext_i8_to_i32(i32 %186)
  %188 = trunc i64 %179 to i32
  %189 = call i32 @cq_template_shl_i32_hl(i32 %187, i32 %188)
  %190 = call i32 @cq_template_or_i32(i32 %189, i32 %183)
  %191 = add i64 %179, 1
  %192 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %191)
  %193 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %193)
  call void @cqrt_xor_i1(i32 %192, i32 %193)
  %194 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %182, i32 %193, i32 %194)
  %195 = call i32 @cq_template_select_i32(i32 %182, i32 %190, i32 %183)
  %196 = getelementptr i8, ptr %10, i64 %191
  %197 = ptrtoint ptr %196 to i64
  %198 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %194, i32 %9, i64 %197)
  %199 = call i32 @cq_template_zext_i8_to_i32(i32 %198)
  %200 = trunc i64 %191 to i32
  %201 = call i32 @cq_template_shl_i32_hl(i32 %199, i32 %200)
  %202 = call i32 @cq_template_or_i32(i32 %201, i32 %195)
  %203 = add i64 %191, 1
  %204 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %203)
  %205 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %205)
  call void @cqrt_xor_i1(i32 %204, i32 %205)
  %206 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %194, i32 %205, i32 %206)
  call void @cqrt_xor_i1(i32 %204, i32 %205)
  call void @cqrt_not_i1(i32 %205)
  call void @cqrt_free(i32 %205)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %204, i32 %69, i64 %203)
  call void @cqrt_free(i32 %204)
  %207 = call i32 @cq_template_select_i32(i32 %194, i32 %202, i32 %195)
  %208 = call i32 @cq_template_icmp_eq_i32_hl(i32 %207, i32 0)
  %209 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %209)
  call void @cqrt_xor_i1(i32 %208, i32 %209)
  %210 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %209, i32 %210)
  call void @cqrt_rz_i1(i32 %210, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %72, i32 %209, i32 %210)
  call void @cqrt_free(i32 %210)
  call void @cqrt_xor_i1(i32 %208, i32 %209)
  call void @cqrt_not_i1(i32 %209)
  call void @cqrt_free(i32 %209)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %208, i32 %207, i32 0)
  call void @cqrt_free(i32 %208)
  call void @cq_template_select_i32_unc(i32 %207, i32 %194, i32 %202, i32 %195)
  call void @cqrt_free(i32 %207)
  call void @cq_template_or_i32_unc(i32 %202, i32 %201, i32 %195)
  call void @cqrt_free(i32 %202)
  call void @cq_template_shl_i32_hl_unc(i32 %201, i32 %199, i32 %200)
  call void @cqrt_free(i32 %201)
  call void @cq_template_zext_i8_to_i32_unc(i32 %199, i32 %198)
  call void @cqrt_free(i32 %199)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %198, i32 %194, i32 %9, i64 %197)
  call void @cqrt_free(i32 %198)
  call void @cq_template_select_i32_unc(i32 %195, i32 %182, i32 %190, i32 %183)
  call void @cqrt_free(i32 %195)
  call void @cqrt_and_i1(i32 %182, i32 %193, i32 %194)
  call void @cqrt_free(i32 %194)
  call void @cqrt_xor_i1(i32 %192, i32 %193)
  call void @cqrt_not_i1(i32 %193)
  call void @cqrt_free(i32 %193)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %192, i32 %69, i64 %191)
  call void @cqrt_free(i32 %192)
  call void @cq_template_or_i32_unc(i32 %190, i32 %189, i32 %183)
  call void @cqrt_free(i32 %190)
  call void @cq_template_shl_i32_hl_unc(i32 %189, i32 %187, i32 %188)
  call void @cqrt_free(i32 %189)
  call void @cq_template_zext_i8_to_i32_unc(i32 %187, i32 %186)
  call void @cqrt_free(i32 %187)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %186, i32 %182, i32 %9, i64 %185)
  call void @cqrt_free(i32 %186)
  call void @cq_template_select_i32_unc(i32 %183, i32 %170, i32 %178, i32 %171)
  call void @cqrt_free(i32 %183)
  call void @cqrt_and_i1(i32 %170, i32 %181, i32 %182)
  call void @cqrt_free(i32 %182)
  call void @cqrt_xor_i1(i32 %180, i32 %181)
  call void @cqrt_not_i1(i32 %181)
  call void @cqrt_free(i32 %181)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %180, i32 %69, i64 %179)
  call void @cqrt_free(i32 %180)
  call void @cq_template_or_i32_unc(i32 %178, i32 %177, i32 %171)
  call void @cqrt_free(i32 %178)
  call void @cq_template_shl_i32_hl_unc(i32 %177, i32 %175, i32 %176)
  call void @cqrt_free(i32 %177)
  call void @cq_template_zext_i8_to_i32_unc(i32 %175, i32 %174)
  call void @cqrt_free(i32 %175)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %174, i32 %170, i32 %9, i64 %173)
  call void @cqrt_free(i32 %174)
  call void @cq_template_select_i32_unc(i32 %171, i32 %158, i32 %166, i32 %159)
  call void @cqrt_free(i32 %171)
  call void @cqrt_and_i1(i32 %158, i32 %169, i32 %170)
  call void @cqrt_free(i32 %170)
  call void @cqrt_xor_i1(i32 %168, i32 %169)
  call void @cqrt_not_i1(i32 %169)
  call void @cqrt_free(i32 %169)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %168, i32 %69, i64 %167)
  call void @cqrt_free(i32 %168)
  call void @cq_template_or_i32_unc(i32 %166, i32 %165, i32 %159)
  call void @cqrt_free(i32 %166)
  call void @cq_template_shl_i32_hl_unc(i32 %165, i32 %163, i32 %164)
  call void @cqrt_free(i32 %165)
  call void @cq_template_zext_i8_to_i32_unc(i32 %163, i32 %162)
  call void @cqrt_free(i32 %163)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %162, i32 %158, i32 %9, i64 %161)
  call void @cqrt_free(i32 %162)
  call void @cqrt_free(i32 %159)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %158)
  call void @cqrt_free(i32 %158)
  %211 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %211)
  %212 = getelementptr i8, ptr %10, i64 0
  %213 = ptrtoint ptr %212 to i64
  %214 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %211, i32 %9, i64 %213, i32 %214)
  call void @cqrt_ry_i1_controlled(i32 %211, i32 %214, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %211, i32 %9, i64 %213, i32 %214)
  call void @cqrt_free(i32 %214)
  %215 = add i64 0, 1
  %216 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %215)
  %217 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %217)
  call void @cqrt_xor_i1(i32 %216, i32 %217)
  %218 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %211, i32 %217, i32 %218)
  %219 = getelementptr i8, ptr %10, i64 %215
  %220 = ptrtoint ptr %219 to i64
  %221 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %218, i32 %9, i64 %220, i32 %221)
  call void @cqrt_ry_i1_controlled(i32 %218, i32 %221, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %218, i32 %9, i64 %220, i32 %221)
  call void @cqrt_free(i32 %221)
  %222 = add i64 %215, 1
  %223 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %222)
  %224 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %224)
  call void @cqrt_xor_i1(i32 %223, i32 %224)
  %225 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %218, i32 %224, i32 %225)
  %226 = getelementptr i8, ptr %10, i64 %222
  %227 = ptrtoint ptr %226 to i64
  %228 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %225, i32 %9, i64 %227, i32 %228)
  call void @cqrt_ry_i1_controlled(i32 %225, i32 %228, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %225, i32 %9, i64 %227, i32 %228)
  call void @cqrt_free(i32 %228)
  %229 = add i64 %222, 1
  %230 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %229)
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %231)
  call void @cqrt_xor_i1(i32 %230, i32 %231)
  %232 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %225, i32 %231, i32 %232)
  %233 = getelementptr i8, ptr %10, i64 %229
  %234 = ptrtoint ptr %233 to i64
  %235 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %232, i32 %9, i64 %234, i32 %235)
  call void @cqrt_ry_i1_controlled(i32 %232, i32 %235, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %232, i32 %9, i64 %234, i32 %235)
  call void @cqrt_free(i32 %235)
  %236 = add i64 %229, 1
  %237 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %236)
  %238 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %238)
  call void @cqrt_xor_i1(i32 %237, i32 %238)
  %239 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %232, i32 %238, i32 %239)
  call void @cqrt_xor_i1(i32 %237, i32 %238)
  call void @cqrt_not_i1(i32 %238)
  call void @cqrt_free(i32 %238)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %237, i32 %70, i64 %236)
  call void @cqrt_free(i32 %237)
  call void @cqrt_and_i1(i32 %225, i32 %231, i32 %232)
  call void @cqrt_free(i32 %232)
  call void @cqrt_xor_i1(i32 %230, i32 %231)
  call void @cqrt_not_i1(i32 %231)
  call void @cqrt_free(i32 %231)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %230, i32 %70, i64 %229)
  call void @cqrt_free(i32 %230)
  call void @cqrt_and_i1(i32 %218, i32 %224, i32 %225)
  call void @cqrt_free(i32 %225)
  call void @cqrt_xor_i1(i32 %223, i32 %224)
  call void @cqrt_not_i1(i32 %224)
  call void @cqrt_free(i32 %224)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %223, i32 %70, i64 %222)
  call void @cqrt_free(i32 %223)
  call void @cqrt_and_i1(i32 %211, i32 %217, i32 %218)
  call void @cqrt_free(i32 %218)
  call void @cqrt_xor_i1(i32 %216, i32 %217)
  call void @cqrt_not_i1(i32 %217)
  call void @cqrt_free(i32 %217)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %216, i32 %70, i64 %215)
  call void @cqrt_free(i32 %216)
  call void @cqrt_and_i1(i32 %72, i32 %31, i32 %211)
  call void @cqrt_free(i32 %211)
  %240 = add i32 0, 1
  %241 = call i32 @cq_template_icmp_eq_i32_hl(i32 %19, i32 %240)
  %242 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %242)
  call void @cqrt_xor_i1(i32 %241, i32 %242)
  %243 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %242, i32 %243)
  %244 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %244)
  %245 = call i32 @cqrt_alloc_i32(i32 0)
  %246 = getelementptr i8, ptr %10, i64 0
  %247 = ptrtoint ptr %246 to i64
  %248 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %244, i32 %9, i64 %247)
  %249 = call i32 @cq_template_zext_i8_to_i32(i32 %248)
  %250 = trunc i64 0 to i32
  %251 = call i32 @cq_template_shl_i32_hl(i32 %249, i32 %250)
  %252 = call i32 @cq_template_or_i32(i32 %251, i32 %245)
  %253 = add i64 0, 1
  %254 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %253)
  %255 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %255)
  call void @cqrt_xor_i1(i32 %254, i32 %255)
  %256 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %244, i32 %255, i32 %256)
  %257 = call i32 @cq_template_select_i32(i32 %244, i32 %252, i32 %245)
  %258 = getelementptr i8, ptr %10, i64 %253
  %259 = ptrtoint ptr %258 to i64
  %260 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %256, i32 %9, i64 %259)
  %261 = call i32 @cq_template_zext_i8_to_i32(i32 %260)
  %262 = trunc i64 %253 to i32
  %263 = call i32 @cq_template_shl_i32_hl(i32 %261, i32 %262)
  %264 = call i32 @cq_template_or_i32(i32 %263, i32 %257)
  %265 = add i64 %253, 1
  %266 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %265)
  %267 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %267)
  call void @cqrt_xor_i1(i32 %266, i32 %267)
  %268 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %256, i32 %267, i32 %268)
  %269 = call i32 @cq_template_select_i32(i32 %256, i32 %264, i32 %257)
  %270 = getelementptr i8, ptr %10, i64 %265
  %271 = ptrtoint ptr %270 to i64
  %272 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %268, i32 %9, i64 %271)
  %273 = call i32 @cq_template_zext_i8_to_i32(i32 %272)
  %274 = trunc i64 %265 to i32
  %275 = call i32 @cq_template_shl_i32_hl(i32 %273, i32 %274)
  %276 = call i32 @cq_template_or_i32(i32 %275, i32 %269)
  %277 = add i64 %265, 1
  %278 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %277)
  %279 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %279)
  call void @cqrt_xor_i1(i32 %278, i32 %279)
  %280 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %268, i32 %279, i32 %280)
  %281 = call i32 @cq_template_select_i32(i32 %268, i32 %276, i32 %269)
  %282 = getelementptr i8, ptr %10, i64 %277
  %283 = ptrtoint ptr %282 to i64
  %284 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %280, i32 %9, i64 %283)
  %285 = call i32 @cq_template_zext_i8_to_i32(i32 %284)
  %286 = trunc i64 %277 to i32
  %287 = call i32 @cq_template_shl_i32_hl(i32 %285, i32 %286)
  %288 = call i32 @cq_template_or_i32(i32 %287, i32 %281)
  %289 = add i64 %277, 1
  %290 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %289)
  %291 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %291)
  call void @cqrt_xor_i1(i32 %290, i32 %291)
  %292 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %280, i32 %291, i32 %292)
  call void @cqrt_xor_i1(i32 %290, i32 %291)
  call void @cqrt_not_i1(i32 %291)
  call void @cqrt_free(i32 %291)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %290, i32 %67, i64 %289)
  call void @cqrt_free(i32 %290)
  %293 = call i32 @cq_template_select_i32(i32 %280, i32 %288, i32 %281)
  %294 = call i32 @cq_template_icmp_eq_i32(i32 %293, i32 %2)
  %295 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %294, i32 %295)
  call void @cqrt_rz_i1(i32 %295, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %243, i32 %294, i32 %295)
  call void @cqrt_free(i32 %295)
  call void @cq_template_icmp_eq_i32_unc(i32 %294, i32 %293, i32 %2)
  call void @cqrt_free(i32 %294)
  call void @cq_template_select_i32_unc(i32 %293, i32 %280, i32 %288, i32 %281)
  call void @cqrt_free(i32 %293)
  call void @cq_template_or_i32_unc(i32 %288, i32 %287, i32 %281)
  call void @cqrt_free(i32 %288)
  call void @cq_template_shl_i32_hl_unc(i32 %287, i32 %285, i32 %286)
  call void @cqrt_free(i32 %287)
  call void @cq_template_zext_i8_to_i32_unc(i32 %285, i32 %284)
  call void @cqrt_free(i32 %285)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %284, i32 %280, i32 %9, i64 %283)
  call void @cqrt_free(i32 %284)
  call void @cq_template_select_i32_unc(i32 %281, i32 %268, i32 %276, i32 %269)
  call void @cqrt_free(i32 %281)
  call void @cqrt_and_i1(i32 %268, i32 %279, i32 %280)
  call void @cqrt_free(i32 %280)
  call void @cqrt_xor_i1(i32 %278, i32 %279)
  call void @cqrt_not_i1(i32 %279)
  call void @cqrt_free(i32 %279)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %278, i32 %67, i64 %277)
  call void @cqrt_free(i32 %278)
  call void @cq_template_or_i32_unc(i32 %276, i32 %275, i32 %269)
  call void @cqrt_free(i32 %276)
  call void @cq_template_shl_i32_hl_unc(i32 %275, i32 %273, i32 %274)
  call void @cqrt_free(i32 %275)
  call void @cq_template_zext_i8_to_i32_unc(i32 %273, i32 %272)
  call void @cqrt_free(i32 %273)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %272, i32 %268, i32 %9, i64 %271)
  call void @cqrt_free(i32 %272)
  call void @cq_template_select_i32_unc(i32 %269, i32 %256, i32 %264, i32 %257)
  call void @cqrt_free(i32 %269)
  call void @cqrt_and_i1(i32 %256, i32 %267, i32 %268)
  call void @cqrt_free(i32 %268)
  call void @cqrt_xor_i1(i32 %266, i32 %267)
  call void @cqrt_not_i1(i32 %267)
  call void @cqrt_free(i32 %267)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %266, i32 %67, i64 %265)
  call void @cqrt_free(i32 %266)
  call void @cq_template_or_i32_unc(i32 %264, i32 %263, i32 %257)
  call void @cqrt_free(i32 %264)
  call void @cq_template_shl_i32_hl_unc(i32 %263, i32 %261, i32 %262)
  call void @cqrt_free(i32 %263)
  call void @cq_template_zext_i8_to_i32_unc(i32 %261, i32 %260)
  call void @cqrt_free(i32 %261)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %260, i32 %256, i32 %9, i64 %259)
  call void @cqrt_free(i32 %260)
  call void @cq_template_select_i32_unc(i32 %257, i32 %244, i32 %252, i32 %245)
  call void @cqrt_free(i32 %257)
  call void @cqrt_and_i1(i32 %244, i32 %255, i32 %256)
  call void @cqrt_free(i32 %256)
  call void @cqrt_xor_i1(i32 %254, i32 %255)
  call void @cqrt_not_i1(i32 %255)
  call void @cqrt_free(i32 %255)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %254, i32 %67, i64 %253)
  call void @cqrt_free(i32 %254)
  call void @cq_template_or_i32_unc(i32 %252, i32 %251, i32 %245)
  call void @cqrt_free(i32 %252)
  call void @cq_template_shl_i32_hl_unc(i32 %251, i32 %249, i32 %250)
  call void @cqrt_free(i32 %251)
  call void @cq_template_zext_i8_to_i32_unc(i32 %249, i32 %248)
  call void @cqrt_free(i32 %249)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %248, i32 %244, i32 %9, i64 %247)
  call void @cqrt_free(i32 %248)
  call void @cqrt_free(i32 %245)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %244)
  call void @cqrt_free(i32 %244)
  call void @cqrt_invert_begin()
  %296 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %296)
  %297 = getelementptr i8, ptr %10, i64 0
  %298 = ptrtoint ptr %297 to i64
  %299 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %296, i32 %9, i64 %298, i32 %299)
  call void @cqrt_ry_i1_controlled(i32 %296, i32 %299, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %296, i32 %9, i64 %298, i32 %299)
  call void @cqrt_free(i32 %299)
  %300 = add i64 0, 1
  %301 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %300)
  %302 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %302)
  call void @cqrt_xor_i1(i32 %301, i32 %302)
  %303 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %296, i32 %302, i32 %303)
  %304 = getelementptr i8, ptr %10, i64 %300
  %305 = ptrtoint ptr %304 to i64
  %306 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %303, i32 %9, i64 %305, i32 %306)
  call void @cqrt_ry_i1_controlled(i32 %303, i32 %306, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %303, i32 %9, i64 %305, i32 %306)
  call void @cqrt_free(i32 %306)
  %307 = add i64 %300, 1
  %308 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %307)
  %309 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %309)
  call void @cqrt_xor_i1(i32 %308, i32 %309)
  %310 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %303, i32 %309, i32 %310)
  %311 = getelementptr i8, ptr %10, i64 %307
  %312 = ptrtoint ptr %311 to i64
  %313 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %310, i32 %9, i64 %312, i32 %313)
  call void @cqrt_ry_i1_controlled(i32 %310, i32 %313, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %310, i32 %9, i64 %312, i32 %313)
  call void @cqrt_free(i32 %313)
  %314 = add i64 %307, 1
  %315 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %314)
  %316 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %316)
  call void @cqrt_xor_i1(i32 %315, i32 %316)
  %317 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %310, i32 %316, i32 %317)
  %318 = getelementptr i8, ptr %10, i64 %314
  %319 = ptrtoint ptr %318 to i64
  %320 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %317, i32 %9, i64 %319, i32 %320)
  call void @cqrt_ry_i1_controlled(i32 %317, i32 %320, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %317, i32 %9, i64 %319, i32 %320)
  call void @cqrt_free(i32 %320)
  %321 = add i64 %314, 1
  %322 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %321)
  %323 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %323)
  call void @cqrt_xor_i1(i32 %322, i32 %323)
  %324 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %317, i32 %323, i32 %324)
  call void @cqrt_xor_i1(i32 %322, i32 %323)
  call void @cqrt_not_i1(i32 %323)
  call void @cqrt_free(i32 %323)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %322, i32 %68, i64 %321)
  call void @cqrt_free(i32 %322)
  call void @cqrt_and_i1(i32 %310, i32 %316, i32 %317)
  call void @cqrt_free(i32 %317)
  call void @cqrt_xor_i1(i32 %315, i32 %316)
  call void @cqrt_not_i1(i32 %316)
  call void @cqrt_free(i32 %316)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %315, i32 %68, i64 %314)
  call void @cqrt_free(i32 %315)
  call void @cqrt_and_i1(i32 %303, i32 %309, i32 %310)
  call void @cqrt_free(i32 %310)
  call void @cqrt_xor_i1(i32 %308, i32 %309)
  call void @cqrt_not_i1(i32 %309)
  call void @cqrt_free(i32 %309)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %308, i32 %68, i64 %307)
  call void @cqrt_free(i32 %308)
  call void @cqrt_and_i1(i32 %296, i32 %302, i32 %303)
  call void @cqrt_free(i32 %303)
  call void @cqrt_xor_i1(i32 %301, i32 %302)
  call void @cqrt_not_i1(i32 %302)
  call void @cqrt_free(i32 %302)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %301, i32 %68, i64 %300)
  call void @cqrt_free(i32 %301)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %296)
  call void @cqrt_free(i32 %296)
  call void @cqrt_invert_end()
  %325 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %321)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %325, i32 %68, i64 %321)
  call void @cqrt_free(i32 %325)
  %326 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %326)
  %327 = call i32 @cqrt_alloc_i32(i32 0)
  %328 = getelementptr i8, ptr %10, i64 0
  %329 = ptrtoint ptr %328 to i64
  %330 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %326, i32 %9, i64 %329)
  %331 = call i32 @cq_template_zext_i8_to_i32(i32 %330)
  %332 = trunc i64 0 to i32
  %333 = call i32 @cq_template_shl_i32_hl(i32 %331, i32 %332)
  %334 = call i32 @cq_template_or_i32(i32 %333, i32 %327)
  %335 = add i64 0, 1
  %336 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %335)
  %337 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %337)
  call void @cqrt_xor_i1(i32 %336, i32 %337)
  %338 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %326, i32 %337, i32 %338)
  %339 = call i32 @cq_template_select_i32(i32 %326, i32 %334, i32 %327)
  %340 = getelementptr i8, ptr %10, i64 %335
  %341 = ptrtoint ptr %340 to i64
  %342 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %338, i32 %9, i64 %341)
  %343 = call i32 @cq_template_zext_i8_to_i32(i32 %342)
  %344 = trunc i64 %335 to i32
  %345 = call i32 @cq_template_shl_i32_hl(i32 %343, i32 %344)
  %346 = call i32 @cq_template_or_i32(i32 %345, i32 %339)
  %347 = add i64 %335, 1
  %348 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %347)
  %349 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %349)
  call void @cqrt_xor_i1(i32 %348, i32 %349)
  %350 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %338, i32 %349, i32 %350)
  %351 = call i32 @cq_template_select_i32(i32 %338, i32 %346, i32 %339)
  %352 = getelementptr i8, ptr %10, i64 %347
  %353 = ptrtoint ptr %352 to i64
  %354 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %350, i32 %9, i64 %353)
  %355 = call i32 @cq_template_zext_i8_to_i32(i32 %354)
  %356 = trunc i64 %347 to i32
  %357 = call i32 @cq_template_shl_i32_hl(i32 %355, i32 %356)
  %358 = call i32 @cq_template_or_i32(i32 %357, i32 %351)
  %359 = add i64 %347, 1
  %360 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %359)
  %361 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %361)
  call void @cqrt_xor_i1(i32 %360, i32 %361)
  %362 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %350, i32 %361, i32 %362)
  %363 = call i32 @cq_template_select_i32(i32 %350, i32 %358, i32 %351)
  %364 = getelementptr i8, ptr %10, i64 %359
  %365 = ptrtoint ptr %364 to i64
  %366 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %362, i32 %9, i64 %365)
  %367 = call i32 @cq_template_zext_i8_to_i32(i32 %366)
  %368 = trunc i64 %359 to i32
  %369 = call i32 @cq_template_shl_i32_hl(i32 %367, i32 %368)
  %370 = call i32 @cq_template_or_i32(i32 %369, i32 %363)
  %371 = add i64 %359, 1
  %372 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %371)
  %373 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %373)
  call void @cqrt_xor_i1(i32 %372, i32 %373)
  %374 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %362, i32 %373, i32 %374)
  call void @cqrt_xor_i1(i32 %372, i32 %373)
  call void @cqrt_not_i1(i32 %373)
  call void @cqrt_free(i32 %373)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %372, i32 %69, i64 %371)
  call void @cqrt_free(i32 %372)
  %375 = call i32 @cq_template_select_i32(i32 %362, i32 %370, i32 %363)
  %376 = call i32 @cq_template_icmp_eq_i32_hl(i32 %375, i32 0)
  %377 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %377)
  call void @cqrt_xor_i1(i32 %376, i32 %377)
  %378 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %377, i32 %378)
  call void @cqrt_rz_i1(i32 %378, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %243, i32 %377, i32 %378)
  call void @cqrt_free(i32 %378)
  call void @cqrt_xor_i1(i32 %376, i32 %377)
  call void @cqrt_not_i1(i32 %377)
  call void @cqrt_free(i32 %377)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %376, i32 %375, i32 0)
  call void @cqrt_free(i32 %376)
  call void @cq_template_select_i32_unc(i32 %375, i32 %362, i32 %370, i32 %363)
  call void @cqrt_free(i32 %375)
  call void @cq_template_or_i32_unc(i32 %370, i32 %369, i32 %363)
  call void @cqrt_free(i32 %370)
  call void @cq_template_shl_i32_hl_unc(i32 %369, i32 %367, i32 %368)
  call void @cqrt_free(i32 %369)
  call void @cq_template_zext_i8_to_i32_unc(i32 %367, i32 %366)
  call void @cqrt_free(i32 %367)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %366, i32 %362, i32 %9, i64 %365)
  call void @cqrt_free(i32 %366)
  call void @cq_template_select_i32_unc(i32 %363, i32 %350, i32 %358, i32 %351)
  call void @cqrt_free(i32 %363)
  call void @cqrt_and_i1(i32 %350, i32 %361, i32 %362)
  call void @cqrt_free(i32 %362)
  call void @cqrt_xor_i1(i32 %360, i32 %361)
  call void @cqrt_not_i1(i32 %361)
  call void @cqrt_free(i32 %361)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %360, i32 %69, i64 %359)
  call void @cqrt_free(i32 %360)
  call void @cq_template_or_i32_unc(i32 %358, i32 %357, i32 %351)
  call void @cqrt_free(i32 %358)
  call void @cq_template_shl_i32_hl_unc(i32 %357, i32 %355, i32 %356)
  call void @cqrt_free(i32 %357)
  call void @cq_template_zext_i8_to_i32_unc(i32 %355, i32 %354)
  call void @cqrt_free(i32 %355)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %354, i32 %350, i32 %9, i64 %353)
  call void @cqrt_free(i32 %354)
  call void @cq_template_select_i32_unc(i32 %351, i32 %338, i32 %346, i32 %339)
  call void @cqrt_free(i32 %351)
  call void @cqrt_and_i1(i32 %338, i32 %349, i32 %350)
  call void @cqrt_free(i32 %350)
  call void @cqrt_xor_i1(i32 %348, i32 %349)
  call void @cqrt_not_i1(i32 %349)
  call void @cqrt_free(i32 %349)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %348, i32 %69, i64 %347)
  call void @cqrt_free(i32 %348)
  call void @cq_template_or_i32_unc(i32 %346, i32 %345, i32 %339)
  call void @cqrt_free(i32 %346)
  call void @cq_template_shl_i32_hl_unc(i32 %345, i32 %343, i32 %344)
  call void @cqrt_free(i32 %345)
  call void @cq_template_zext_i8_to_i32_unc(i32 %343, i32 %342)
  call void @cqrt_free(i32 %343)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %342, i32 %338, i32 %9, i64 %341)
  call void @cqrt_free(i32 %342)
  call void @cq_template_select_i32_unc(i32 %339, i32 %326, i32 %334, i32 %327)
  call void @cqrt_free(i32 %339)
  call void @cqrt_and_i1(i32 %326, i32 %337, i32 %338)
  call void @cqrt_free(i32 %338)
  call void @cqrt_xor_i1(i32 %336, i32 %337)
  call void @cqrt_not_i1(i32 %337)
  call void @cqrt_free(i32 %337)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %336, i32 %69, i64 %335)
  call void @cqrt_free(i32 %336)
  call void @cq_template_or_i32_unc(i32 %334, i32 %333, i32 %327)
  call void @cqrt_free(i32 %334)
  call void @cq_template_shl_i32_hl_unc(i32 %333, i32 %331, i32 %332)
  call void @cqrt_free(i32 %333)
  call void @cq_template_zext_i8_to_i32_unc(i32 %331, i32 %330)
  call void @cqrt_free(i32 %331)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %330, i32 %326, i32 %9, i64 %329)
  call void @cqrt_free(i32 %330)
  call void @cqrt_free(i32 %327)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %326)
  call void @cqrt_free(i32 %326)
  %379 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %379)
  %380 = getelementptr i8, ptr %10, i64 0
  %381 = ptrtoint ptr %380 to i64
  %382 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %379, i32 %9, i64 %381, i32 %382)
  call void @cqrt_ry_i1_controlled(i32 %379, i32 %382, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %379, i32 %9, i64 %381, i32 %382)
  call void @cqrt_free(i32 %382)
  %383 = add i64 0, 1
  %384 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %383)
  %385 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %385)
  call void @cqrt_xor_i1(i32 %384, i32 %385)
  %386 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %379, i32 %385, i32 %386)
  %387 = getelementptr i8, ptr %10, i64 %383
  %388 = ptrtoint ptr %387 to i64
  %389 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %386, i32 %9, i64 %388, i32 %389)
  call void @cqrt_ry_i1_controlled(i32 %386, i32 %389, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %386, i32 %9, i64 %388, i32 %389)
  call void @cqrt_free(i32 %389)
  %390 = add i64 %383, 1
  %391 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %390)
  %392 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %392)
  call void @cqrt_xor_i1(i32 %391, i32 %392)
  %393 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %386, i32 %392, i32 %393)
  %394 = getelementptr i8, ptr %10, i64 %390
  %395 = ptrtoint ptr %394 to i64
  %396 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %393, i32 %9, i64 %395, i32 %396)
  call void @cqrt_ry_i1_controlled(i32 %393, i32 %396, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %393, i32 %9, i64 %395, i32 %396)
  call void @cqrt_free(i32 %396)
  %397 = add i64 %390, 1
  %398 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %397)
  %399 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %399)
  call void @cqrt_xor_i1(i32 %398, i32 %399)
  %400 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %393, i32 %399, i32 %400)
  %401 = getelementptr i8, ptr %10, i64 %397
  %402 = ptrtoint ptr %401 to i64
  %403 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %400, i32 %9, i64 %402, i32 %403)
  call void @cqrt_ry_i1_controlled(i32 %400, i32 %403, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %400, i32 %9, i64 %402, i32 %403)
  call void @cqrt_free(i32 %403)
  %404 = add i64 %397, 1
  %405 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %404)
  %406 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %406)
  call void @cqrt_xor_i1(i32 %405, i32 %406)
  %407 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %400, i32 %406, i32 %407)
  call void @cqrt_xor_i1(i32 %405, i32 %406)
  call void @cqrt_not_i1(i32 %406)
  call void @cqrt_free(i32 %406)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %405, i32 %70, i64 %404)
  call void @cqrt_free(i32 %405)
  call void @cqrt_and_i1(i32 %393, i32 %399, i32 %400)
  call void @cqrt_free(i32 %400)
  call void @cqrt_xor_i1(i32 %398, i32 %399)
  call void @cqrt_not_i1(i32 %399)
  call void @cqrt_free(i32 %399)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %398, i32 %70, i64 %397)
  call void @cqrt_free(i32 %398)
  call void @cqrt_and_i1(i32 %386, i32 %392, i32 %393)
  call void @cqrt_free(i32 %393)
  call void @cqrt_xor_i1(i32 %391, i32 %392)
  call void @cqrt_not_i1(i32 %392)
  call void @cqrt_free(i32 %392)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %391, i32 %70, i64 %390)
  call void @cqrt_free(i32 %391)
  call void @cqrt_and_i1(i32 %379, i32 %385, i32 %386)
  call void @cqrt_free(i32 %386)
  call void @cqrt_xor_i1(i32 %384, i32 %385)
  call void @cqrt_not_i1(i32 %385)
  call void @cqrt_free(i32 %385)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %384, i32 %70, i64 %383)
  call void @cqrt_free(i32 %384)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %379)
  call void @cqrt_free(i32 %379)
  %408 = add i32 %240, 1
  %409 = call i32 @cq_template_icmp_eq_i32_hl(i32 %19, i32 %408)
  %410 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %410)
  call void @cqrt_xor_i1(i32 %409, i32 %410)
  %411 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %243, i32 %410, i32 %411)
  %412 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %412)
  %413 = call i32 @cqrt_alloc_i32(i32 0)
  %414 = getelementptr i8, ptr %10, i64 0
  %415 = ptrtoint ptr %414 to i64
  %416 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %412, i32 %9, i64 %415)
  %417 = call i32 @cq_template_zext_i8_to_i32(i32 %416)
  %418 = trunc i64 0 to i32
  %419 = call i32 @cq_template_shl_i32_hl(i32 %417, i32 %418)
  %420 = call i32 @cq_template_or_i32(i32 %419, i32 %413)
  %421 = add i64 0, 1
  %422 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %421)
  %423 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %423)
  call void @cqrt_xor_i1(i32 %422, i32 %423)
  %424 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %412, i32 %423, i32 %424)
  %425 = call i32 @cq_template_select_i32(i32 %412, i32 %420, i32 %413)
  %426 = getelementptr i8, ptr %10, i64 %421
  %427 = ptrtoint ptr %426 to i64
  %428 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %424, i32 %9, i64 %427)
  %429 = call i32 @cq_template_zext_i8_to_i32(i32 %428)
  %430 = trunc i64 %421 to i32
  %431 = call i32 @cq_template_shl_i32_hl(i32 %429, i32 %430)
  %432 = call i32 @cq_template_or_i32(i32 %431, i32 %425)
  %433 = add i64 %421, 1
  %434 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %433)
  %435 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %435)
  call void @cqrt_xor_i1(i32 %434, i32 %435)
  %436 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %424, i32 %435, i32 %436)
  %437 = call i32 @cq_template_select_i32(i32 %424, i32 %432, i32 %425)
  %438 = getelementptr i8, ptr %10, i64 %433
  %439 = ptrtoint ptr %438 to i64
  %440 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %436, i32 %9, i64 %439)
  %441 = call i32 @cq_template_zext_i8_to_i32(i32 %440)
  %442 = trunc i64 %433 to i32
  %443 = call i32 @cq_template_shl_i32_hl(i32 %441, i32 %442)
  %444 = call i32 @cq_template_or_i32(i32 %443, i32 %437)
  %445 = add i64 %433, 1
  %446 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %445)
  %447 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %447)
  call void @cqrt_xor_i1(i32 %446, i32 %447)
  %448 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %436, i32 %447, i32 %448)
  %449 = call i32 @cq_template_select_i32(i32 %436, i32 %444, i32 %437)
  %450 = getelementptr i8, ptr %10, i64 %445
  %451 = ptrtoint ptr %450 to i64
  %452 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %448, i32 %9, i64 %451)
  %453 = call i32 @cq_template_zext_i8_to_i32(i32 %452)
  %454 = trunc i64 %445 to i32
  %455 = call i32 @cq_template_shl_i32_hl(i32 %453, i32 %454)
  %456 = call i32 @cq_template_or_i32(i32 %455, i32 %449)
  %457 = add i64 %445, 1
  %458 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %457)
  %459 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %459)
  call void @cqrt_xor_i1(i32 %458, i32 %459)
  %460 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %448, i32 %459, i32 %460)
  call void @cqrt_xor_i1(i32 %458, i32 %459)
  call void @cqrt_not_i1(i32 %459)
  call void @cqrt_free(i32 %459)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %458, i32 %67, i64 %457)
  call void @cqrt_free(i32 %458)
  %461 = call i32 @cq_template_select_i32(i32 %448, i32 %456, i32 %449)
  %462 = call i32 @cq_template_icmp_eq_i32(i32 %461, i32 %2)
  %463 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %462, i32 %463)
  call void @cqrt_rz_i1(i32 %463, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %411, i32 %462, i32 %463)
  call void @cqrt_free(i32 %463)
  call void @cq_template_icmp_eq_i32_unc(i32 %462, i32 %461, i32 %2)
  call void @cqrt_free(i32 %462)
  call void @cq_template_select_i32_unc(i32 %461, i32 %448, i32 %456, i32 %449)
  call void @cqrt_free(i32 %461)
  call void @cq_template_or_i32_unc(i32 %456, i32 %455, i32 %449)
  call void @cqrt_free(i32 %456)
  call void @cq_template_shl_i32_hl_unc(i32 %455, i32 %453, i32 %454)
  call void @cqrt_free(i32 %455)
  call void @cq_template_zext_i8_to_i32_unc(i32 %453, i32 %452)
  call void @cqrt_free(i32 %453)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %452, i32 %448, i32 %9, i64 %451)
  call void @cqrt_free(i32 %452)
  call void @cq_template_select_i32_unc(i32 %449, i32 %436, i32 %444, i32 %437)
  call void @cqrt_free(i32 %449)
  call void @cqrt_and_i1(i32 %436, i32 %447, i32 %448)
  call void @cqrt_free(i32 %448)
  call void @cqrt_xor_i1(i32 %446, i32 %447)
  call void @cqrt_not_i1(i32 %447)
  call void @cqrt_free(i32 %447)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %446, i32 %67, i64 %445)
  call void @cqrt_free(i32 %446)
  call void @cq_template_or_i32_unc(i32 %444, i32 %443, i32 %437)
  call void @cqrt_free(i32 %444)
  call void @cq_template_shl_i32_hl_unc(i32 %443, i32 %441, i32 %442)
  call void @cqrt_free(i32 %443)
  call void @cq_template_zext_i8_to_i32_unc(i32 %441, i32 %440)
  call void @cqrt_free(i32 %441)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %440, i32 %436, i32 %9, i64 %439)
  call void @cqrt_free(i32 %440)
  call void @cq_template_select_i32_unc(i32 %437, i32 %424, i32 %432, i32 %425)
  call void @cqrt_free(i32 %437)
  call void @cqrt_and_i1(i32 %424, i32 %435, i32 %436)
  call void @cqrt_free(i32 %436)
  call void @cqrt_xor_i1(i32 %434, i32 %435)
  call void @cqrt_not_i1(i32 %435)
  call void @cqrt_free(i32 %435)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %434, i32 %67, i64 %433)
  call void @cqrt_free(i32 %434)
  call void @cq_template_or_i32_unc(i32 %432, i32 %431, i32 %425)
  call void @cqrt_free(i32 %432)
  call void @cq_template_shl_i32_hl_unc(i32 %431, i32 %429, i32 %430)
  call void @cqrt_free(i32 %431)
  call void @cq_template_zext_i8_to_i32_unc(i32 %429, i32 %428)
  call void @cqrt_free(i32 %429)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %428, i32 %424, i32 %9, i64 %427)
  call void @cqrt_free(i32 %428)
  call void @cq_template_select_i32_unc(i32 %425, i32 %412, i32 %420, i32 %413)
  call void @cqrt_free(i32 %425)
  call void @cqrt_and_i1(i32 %412, i32 %423, i32 %424)
  call void @cqrt_free(i32 %424)
  call void @cqrt_xor_i1(i32 %422, i32 %423)
  call void @cqrt_not_i1(i32 %423)
  call void @cqrt_free(i32 %423)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %422, i32 %67, i64 %421)
  call void @cqrt_free(i32 %422)
  call void @cq_template_or_i32_unc(i32 %420, i32 %419, i32 %413)
  call void @cqrt_free(i32 %420)
  call void @cq_template_shl_i32_hl_unc(i32 %419, i32 %417, i32 %418)
  call void @cqrt_free(i32 %419)
  call void @cq_template_zext_i8_to_i32_unc(i32 %417, i32 %416)
  call void @cqrt_free(i32 %417)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %416, i32 %412, i32 %9, i64 %415)
  call void @cqrt_free(i32 %416)
  call void @cqrt_free(i32 %413)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %412)
  call void @cqrt_free(i32 %412)
  call void @cqrt_invert_begin()
  %464 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %464)
  %465 = getelementptr i8, ptr %10, i64 0
  %466 = ptrtoint ptr %465 to i64
  %467 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %464, i32 %9, i64 %466, i32 %467)
  call void @cqrt_ry_i1_controlled(i32 %464, i32 %467, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %464, i32 %9, i64 %466, i32 %467)
  call void @cqrt_free(i32 %467)
  %468 = add i64 0, 1
  %469 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %468)
  %470 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %470)
  call void @cqrt_xor_i1(i32 %469, i32 %470)
  %471 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %464, i32 %470, i32 %471)
  %472 = getelementptr i8, ptr %10, i64 %468
  %473 = ptrtoint ptr %472 to i64
  %474 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %471, i32 %9, i64 %473, i32 %474)
  call void @cqrt_ry_i1_controlled(i32 %471, i32 %474, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %471, i32 %9, i64 %473, i32 %474)
  call void @cqrt_free(i32 %474)
  %475 = add i64 %468, 1
  %476 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %475)
  %477 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %477)
  call void @cqrt_xor_i1(i32 %476, i32 %477)
  %478 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %471, i32 %477, i32 %478)
  %479 = getelementptr i8, ptr %10, i64 %475
  %480 = ptrtoint ptr %479 to i64
  %481 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %478, i32 %9, i64 %480, i32 %481)
  call void @cqrt_ry_i1_controlled(i32 %478, i32 %481, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %478, i32 %9, i64 %480, i32 %481)
  call void @cqrt_free(i32 %481)
  %482 = add i64 %475, 1
  %483 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %482)
  %484 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %484)
  call void @cqrt_xor_i1(i32 %483, i32 %484)
  %485 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %478, i32 %484, i32 %485)
  %486 = getelementptr i8, ptr %10, i64 %482
  %487 = ptrtoint ptr %486 to i64
  %488 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %485, i32 %9, i64 %487, i32 %488)
  call void @cqrt_ry_i1_controlled(i32 %485, i32 %488, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %485, i32 %9, i64 %487, i32 %488)
  call void @cqrt_free(i32 %488)
  %489 = add i64 %482, 1
  %490 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %489)
  %491 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %491)
  call void @cqrt_xor_i1(i32 %490, i32 %491)
  %492 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %485, i32 %491, i32 %492)
  call void @cqrt_xor_i1(i32 %490, i32 %491)
  call void @cqrt_not_i1(i32 %491)
  call void @cqrt_free(i32 %491)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %490, i32 %68, i64 %489)
  call void @cqrt_free(i32 %490)
  call void @cqrt_and_i1(i32 %478, i32 %484, i32 %485)
  call void @cqrt_free(i32 %485)
  call void @cqrt_xor_i1(i32 %483, i32 %484)
  call void @cqrt_not_i1(i32 %484)
  call void @cqrt_free(i32 %484)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %483, i32 %68, i64 %482)
  call void @cqrt_free(i32 %483)
  call void @cqrt_and_i1(i32 %471, i32 %477, i32 %478)
  call void @cqrt_free(i32 %478)
  call void @cqrt_xor_i1(i32 %476, i32 %477)
  call void @cqrt_not_i1(i32 %477)
  call void @cqrt_free(i32 %477)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %476, i32 %68, i64 %475)
  call void @cqrt_free(i32 %476)
  call void @cqrt_and_i1(i32 %464, i32 %470, i32 %471)
  call void @cqrt_free(i32 %471)
  call void @cqrt_xor_i1(i32 %469, i32 %470)
  call void @cqrt_not_i1(i32 %470)
  call void @cqrt_free(i32 %470)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %469, i32 %68, i64 %468)
  call void @cqrt_free(i32 %469)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %464)
  call void @cqrt_free(i32 %464)
  call void @cqrt_invert_end()
  %493 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %489)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %493, i32 %68, i64 %489)
  call void @cqrt_free(i32 %493)
  %494 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %494)
  %495 = call i32 @cqrt_alloc_i32(i32 0)
  %496 = getelementptr i8, ptr %10, i64 0
  %497 = ptrtoint ptr %496 to i64
  %498 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %494, i32 %9, i64 %497)
  %499 = call i32 @cq_template_zext_i8_to_i32(i32 %498)
  %500 = trunc i64 0 to i32
  %501 = call i32 @cq_template_shl_i32_hl(i32 %499, i32 %500)
  %502 = call i32 @cq_template_or_i32(i32 %501, i32 %495)
  %503 = add i64 0, 1
  %504 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %503)
  %505 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %505)
  call void @cqrt_xor_i1(i32 %504, i32 %505)
  %506 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %494, i32 %505, i32 %506)
  %507 = call i32 @cq_template_select_i32(i32 %494, i32 %502, i32 %495)
  %508 = getelementptr i8, ptr %10, i64 %503
  %509 = ptrtoint ptr %508 to i64
  %510 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %506, i32 %9, i64 %509)
  %511 = call i32 @cq_template_zext_i8_to_i32(i32 %510)
  %512 = trunc i64 %503 to i32
  %513 = call i32 @cq_template_shl_i32_hl(i32 %511, i32 %512)
  %514 = call i32 @cq_template_or_i32(i32 %513, i32 %507)
  %515 = add i64 %503, 1
  %516 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %515)
  %517 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %517)
  call void @cqrt_xor_i1(i32 %516, i32 %517)
  %518 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %506, i32 %517, i32 %518)
  %519 = call i32 @cq_template_select_i32(i32 %506, i32 %514, i32 %507)
  %520 = getelementptr i8, ptr %10, i64 %515
  %521 = ptrtoint ptr %520 to i64
  %522 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %518, i32 %9, i64 %521)
  %523 = call i32 @cq_template_zext_i8_to_i32(i32 %522)
  %524 = trunc i64 %515 to i32
  %525 = call i32 @cq_template_shl_i32_hl(i32 %523, i32 %524)
  %526 = call i32 @cq_template_or_i32(i32 %525, i32 %519)
  %527 = add i64 %515, 1
  %528 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %527)
  %529 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %529)
  call void @cqrt_xor_i1(i32 %528, i32 %529)
  %530 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %518, i32 %529, i32 %530)
  %531 = call i32 @cq_template_select_i32(i32 %518, i32 %526, i32 %519)
  %532 = getelementptr i8, ptr %10, i64 %527
  %533 = ptrtoint ptr %532 to i64
  %534 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %530, i32 %9, i64 %533)
  %535 = call i32 @cq_template_zext_i8_to_i32(i32 %534)
  %536 = trunc i64 %527 to i32
  %537 = call i32 @cq_template_shl_i32_hl(i32 %535, i32 %536)
  %538 = call i32 @cq_template_or_i32(i32 %537, i32 %531)
  %539 = add i64 %527, 1
  %540 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %539)
  %541 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %541)
  call void @cqrt_xor_i1(i32 %540, i32 %541)
  %542 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %530, i32 %541, i32 %542)
  call void @cqrt_xor_i1(i32 %540, i32 %541)
  call void @cqrt_not_i1(i32 %541)
  call void @cqrt_free(i32 %541)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %540, i32 %69, i64 %539)
  call void @cqrt_free(i32 %540)
  %543 = call i32 @cq_template_select_i32(i32 %530, i32 %538, i32 %531)
  %544 = call i32 @cq_template_icmp_eq_i32_hl(i32 %543, i32 0)
  %545 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %545)
  call void @cqrt_xor_i1(i32 %544, i32 %545)
  %546 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %545, i32 %546)
  call void @cqrt_rz_i1(i32 %546, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %411, i32 %545, i32 %546)
  call void @cqrt_free(i32 %546)
  call void @cqrt_xor_i1(i32 %544, i32 %545)
  call void @cqrt_not_i1(i32 %545)
  call void @cqrt_free(i32 %545)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %544, i32 %543, i32 0)
  call void @cqrt_free(i32 %544)
  call void @cq_template_select_i32_unc(i32 %543, i32 %530, i32 %538, i32 %531)
  call void @cqrt_free(i32 %543)
  call void @cq_template_or_i32_unc(i32 %538, i32 %537, i32 %531)
  call void @cqrt_free(i32 %538)
  call void @cq_template_shl_i32_hl_unc(i32 %537, i32 %535, i32 %536)
  call void @cqrt_free(i32 %537)
  call void @cq_template_zext_i8_to_i32_unc(i32 %535, i32 %534)
  call void @cqrt_free(i32 %535)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %534, i32 %530, i32 %9, i64 %533)
  call void @cqrt_free(i32 %534)
  call void @cq_template_select_i32_unc(i32 %531, i32 %518, i32 %526, i32 %519)
  call void @cqrt_free(i32 %531)
  call void @cqrt_and_i1(i32 %518, i32 %529, i32 %530)
  call void @cqrt_free(i32 %530)
  call void @cqrt_xor_i1(i32 %528, i32 %529)
  call void @cqrt_not_i1(i32 %529)
  call void @cqrt_free(i32 %529)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %528, i32 %69, i64 %527)
  call void @cqrt_free(i32 %528)
  call void @cq_template_or_i32_unc(i32 %526, i32 %525, i32 %519)
  call void @cqrt_free(i32 %526)
  call void @cq_template_shl_i32_hl_unc(i32 %525, i32 %523, i32 %524)
  call void @cqrt_free(i32 %525)
  call void @cq_template_zext_i8_to_i32_unc(i32 %523, i32 %522)
  call void @cqrt_free(i32 %523)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %522, i32 %518, i32 %9, i64 %521)
  call void @cqrt_free(i32 %522)
  call void @cq_template_select_i32_unc(i32 %519, i32 %506, i32 %514, i32 %507)
  call void @cqrt_free(i32 %519)
  call void @cqrt_and_i1(i32 %506, i32 %517, i32 %518)
  call void @cqrt_free(i32 %518)
  call void @cqrt_xor_i1(i32 %516, i32 %517)
  call void @cqrt_not_i1(i32 %517)
  call void @cqrt_free(i32 %517)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %516, i32 %69, i64 %515)
  call void @cqrt_free(i32 %516)
  call void @cq_template_or_i32_unc(i32 %514, i32 %513, i32 %507)
  call void @cqrt_free(i32 %514)
  call void @cq_template_shl_i32_hl_unc(i32 %513, i32 %511, i32 %512)
  call void @cqrt_free(i32 %513)
  call void @cq_template_zext_i8_to_i32_unc(i32 %511, i32 %510)
  call void @cqrt_free(i32 %511)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %510, i32 %506, i32 %9, i64 %509)
  call void @cqrt_free(i32 %510)
  call void @cq_template_select_i32_unc(i32 %507, i32 %494, i32 %502, i32 %495)
  call void @cqrt_free(i32 %507)
  call void @cqrt_and_i1(i32 %494, i32 %505, i32 %506)
  call void @cqrt_free(i32 %506)
  call void @cqrt_xor_i1(i32 %504, i32 %505)
  call void @cqrt_not_i1(i32 %505)
  call void @cqrt_free(i32 %505)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %504, i32 %69, i64 %503)
  call void @cqrt_free(i32 %504)
  call void @cq_template_or_i32_unc(i32 %502, i32 %501, i32 %495)
  call void @cqrt_free(i32 %502)
  call void @cq_template_shl_i32_hl_unc(i32 %501, i32 %499, i32 %500)
  call void @cqrt_free(i32 %501)
  call void @cq_template_zext_i8_to_i32_unc(i32 %499, i32 %498)
  call void @cqrt_free(i32 %499)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %498, i32 %494, i32 %9, i64 %497)
  call void @cqrt_free(i32 %498)
  call void @cqrt_free(i32 %495)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %494)
  call void @cqrt_free(i32 %494)
  %547 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %547)
  %548 = getelementptr i8, ptr %10, i64 0
  %549 = ptrtoint ptr %548 to i64
  %550 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %547, i32 %9, i64 %549, i32 %550)
  call void @cqrt_ry_i1_controlled(i32 %547, i32 %550, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %547, i32 %9, i64 %549, i32 %550)
  call void @cqrt_free(i32 %550)
  %551 = add i64 0, 1
  %552 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %551)
  %553 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %553)
  call void @cqrt_xor_i1(i32 %552, i32 %553)
  %554 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %547, i32 %553, i32 %554)
  %555 = getelementptr i8, ptr %10, i64 %551
  %556 = ptrtoint ptr %555 to i64
  %557 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %554, i32 %9, i64 %556, i32 %557)
  call void @cqrt_ry_i1_controlled(i32 %554, i32 %557, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %554, i32 %9, i64 %556, i32 %557)
  call void @cqrt_free(i32 %557)
  %558 = add i64 %551, 1
  %559 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %558)
  %560 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %560)
  call void @cqrt_xor_i1(i32 %559, i32 %560)
  %561 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %554, i32 %560, i32 %561)
  %562 = getelementptr i8, ptr %10, i64 %558
  %563 = ptrtoint ptr %562 to i64
  %564 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %561, i32 %9, i64 %563, i32 %564)
  call void @cqrt_ry_i1_controlled(i32 %561, i32 %564, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %561, i32 %9, i64 %563, i32 %564)
  call void @cqrt_free(i32 %564)
  %565 = add i64 %558, 1
  %566 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %565)
  %567 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %567)
  call void @cqrt_xor_i1(i32 %566, i32 %567)
  %568 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %561, i32 %567, i32 %568)
  %569 = getelementptr i8, ptr %10, i64 %565
  %570 = ptrtoint ptr %569 to i64
  %571 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %568, i32 %9, i64 %570, i32 %571)
  call void @cqrt_ry_i1_controlled(i32 %568, i32 %571, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %568, i32 %9, i64 %570, i32 %571)
  call void @cqrt_free(i32 %571)
  %572 = add i64 %565, 1
  %573 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %572)
  %574 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %574)
  call void @cqrt_xor_i1(i32 %573, i32 %574)
  %575 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %568, i32 %574, i32 %575)
  call void @cqrt_xor_i1(i32 %573, i32 %574)
  call void @cqrt_not_i1(i32 %574)
  call void @cqrt_free(i32 %574)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %573, i32 %70, i64 %572)
  call void @cqrt_free(i32 %573)
  call void @cqrt_and_i1(i32 %561, i32 %567, i32 %568)
  call void @cqrt_free(i32 %568)
  call void @cqrt_xor_i1(i32 %566, i32 %567)
  call void @cqrt_not_i1(i32 %567)
  call void @cqrt_free(i32 %567)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %566, i32 %70, i64 %565)
  call void @cqrt_free(i32 %566)
  call void @cqrt_and_i1(i32 %554, i32 %560, i32 %561)
  call void @cqrt_free(i32 %561)
  call void @cqrt_xor_i1(i32 %559, i32 %560)
  call void @cqrt_not_i1(i32 %560)
  call void @cqrt_free(i32 %560)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %559, i32 %70, i64 %558)
  call void @cqrt_free(i32 %559)
  call void @cqrt_and_i1(i32 %547, i32 %553, i32 %554)
  call void @cqrt_free(i32 %554)
  call void @cqrt_xor_i1(i32 %552, i32 %553)
  call void @cqrt_not_i1(i32 %553)
  call void @cqrt_free(i32 %553)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %552, i32 %70, i64 %551)
  call void @cqrt_free(i32 %552)
  call void @cqrt_and_i1(i32 %411, i32 %31, i32 %547)
  call void @cqrt_free(i32 %547)
  %576 = add i32 %408, 1
  %577 = call i32 @cq_template_icmp_eq_i32_hl(i32 %19, i32 %576)
  %578 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %578)
  call void @cqrt_xor_i1(i32 %577, i32 %578)
  %579 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %411, i32 %578, i32 %579)
  %580 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %580)
  %581 = call i32 @cqrt_alloc_i32(i32 0)
  %582 = getelementptr i8, ptr %10, i64 0
  %583 = ptrtoint ptr %582 to i64
  %584 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %580, i32 %9, i64 %583)
  %585 = call i32 @cq_template_zext_i8_to_i32(i32 %584)
  %586 = trunc i64 0 to i32
  %587 = call i32 @cq_template_shl_i32_hl(i32 %585, i32 %586)
  %588 = call i32 @cq_template_or_i32(i32 %587, i32 %581)
  %589 = add i64 0, 1
  %590 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %589)
  %591 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %591)
  call void @cqrt_xor_i1(i32 %590, i32 %591)
  %592 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %580, i32 %591, i32 %592)
  %593 = call i32 @cq_template_select_i32(i32 %580, i32 %588, i32 %581)
  %594 = getelementptr i8, ptr %10, i64 %589
  %595 = ptrtoint ptr %594 to i64
  %596 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %592, i32 %9, i64 %595)
  %597 = call i32 @cq_template_zext_i8_to_i32(i32 %596)
  %598 = trunc i64 %589 to i32
  %599 = call i32 @cq_template_shl_i32_hl(i32 %597, i32 %598)
  %600 = call i32 @cq_template_or_i32(i32 %599, i32 %593)
  %601 = add i64 %589, 1
  %602 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %601)
  %603 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %603)
  call void @cqrt_xor_i1(i32 %602, i32 %603)
  %604 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %592, i32 %603, i32 %604)
  %605 = call i32 @cq_template_select_i32(i32 %592, i32 %600, i32 %593)
  %606 = getelementptr i8, ptr %10, i64 %601
  %607 = ptrtoint ptr %606 to i64
  %608 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %604, i32 %9, i64 %607)
  %609 = call i32 @cq_template_zext_i8_to_i32(i32 %608)
  %610 = trunc i64 %601 to i32
  %611 = call i32 @cq_template_shl_i32_hl(i32 %609, i32 %610)
  %612 = call i32 @cq_template_or_i32(i32 %611, i32 %605)
  %613 = add i64 %601, 1
  %614 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %613)
  %615 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %615)
  call void @cqrt_xor_i1(i32 %614, i32 %615)
  %616 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %604, i32 %615, i32 %616)
  %617 = call i32 @cq_template_select_i32(i32 %604, i32 %612, i32 %605)
  %618 = getelementptr i8, ptr %10, i64 %613
  %619 = ptrtoint ptr %618 to i64
  %620 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %616, i32 %9, i64 %619)
  %621 = call i32 @cq_template_zext_i8_to_i32(i32 %620)
  %622 = trunc i64 %613 to i32
  %623 = call i32 @cq_template_shl_i32_hl(i32 %621, i32 %622)
  %624 = call i32 @cq_template_or_i32(i32 %623, i32 %617)
  %625 = add i64 %613, 1
  %626 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %625)
  %627 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %627)
  call void @cqrt_xor_i1(i32 %626, i32 %627)
  %628 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %616, i32 %627, i32 %628)
  call void @cqrt_xor_i1(i32 %626, i32 %627)
  call void @cqrt_not_i1(i32 %627)
  call void @cqrt_free(i32 %627)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %626, i32 %67, i64 %625)
  call void @cqrt_free(i32 %626)
  %629 = call i32 @cq_template_select_i32(i32 %616, i32 %624, i32 %617)
  %630 = call i32 @cq_template_icmp_eq_i32(i32 %629, i32 %2)
  %631 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %630, i32 %631)
  call void @cqrt_rz_i1(i32 %631, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %579, i32 %630, i32 %631)
  call void @cqrt_free(i32 %631)
  call void @cq_template_icmp_eq_i32_unc(i32 %630, i32 %629, i32 %2)
  call void @cqrt_free(i32 %630)
  call void @cq_template_select_i32_unc(i32 %629, i32 %616, i32 %624, i32 %617)
  call void @cqrt_free(i32 %629)
  call void @cq_template_or_i32_unc(i32 %624, i32 %623, i32 %617)
  call void @cqrt_free(i32 %624)
  call void @cq_template_shl_i32_hl_unc(i32 %623, i32 %621, i32 %622)
  call void @cqrt_free(i32 %623)
  call void @cq_template_zext_i8_to_i32_unc(i32 %621, i32 %620)
  call void @cqrt_free(i32 %621)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %620, i32 %616, i32 %9, i64 %619)
  call void @cqrt_free(i32 %620)
  call void @cq_template_select_i32_unc(i32 %617, i32 %604, i32 %612, i32 %605)
  call void @cqrt_free(i32 %617)
  call void @cqrt_and_i1(i32 %604, i32 %615, i32 %616)
  call void @cqrt_free(i32 %616)
  call void @cqrt_xor_i1(i32 %614, i32 %615)
  call void @cqrt_not_i1(i32 %615)
  call void @cqrt_free(i32 %615)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %614, i32 %67, i64 %613)
  call void @cqrt_free(i32 %614)
  call void @cq_template_or_i32_unc(i32 %612, i32 %611, i32 %605)
  call void @cqrt_free(i32 %612)
  call void @cq_template_shl_i32_hl_unc(i32 %611, i32 %609, i32 %610)
  call void @cqrt_free(i32 %611)
  call void @cq_template_zext_i8_to_i32_unc(i32 %609, i32 %608)
  call void @cqrt_free(i32 %609)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %608, i32 %604, i32 %9, i64 %607)
  call void @cqrt_free(i32 %608)
  call void @cq_template_select_i32_unc(i32 %605, i32 %592, i32 %600, i32 %593)
  call void @cqrt_free(i32 %605)
  call void @cqrt_and_i1(i32 %592, i32 %603, i32 %604)
  call void @cqrt_free(i32 %604)
  call void @cqrt_xor_i1(i32 %602, i32 %603)
  call void @cqrt_not_i1(i32 %603)
  call void @cqrt_free(i32 %603)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %602, i32 %67, i64 %601)
  call void @cqrt_free(i32 %602)
  call void @cq_template_or_i32_unc(i32 %600, i32 %599, i32 %593)
  call void @cqrt_free(i32 %600)
  call void @cq_template_shl_i32_hl_unc(i32 %599, i32 %597, i32 %598)
  call void @cqrt_free(i32 %599)
  call void @cq_template_zext_i8_to_i32_unc(i32 %597, i32 %596)
  call void @cqrt_free(i32 %597)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %596, i32 %592, i32 %9, i64 %595)
  call void @cqrt_free(i32 %596)
  call void @cq_template_select_i32_unc(i32 %593, i32 %580, i32 %588, i32 %581)
  call void @cqrt_free(i32 %593)
  call void @cqrt_and_i1(i32 %580, i32 %591, i32 %592)
  call void @cqrt_free(i32 %592)
  call void @cqrt_xor_i1(i32 %590, i32 %591)
  call void @cqrt_not_i1(i32 %591)
  call void @cqrt_free(i32 %591)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %590, i32 %67, i64 %589)
  call void @cqrt_free(i32 %590)
  call void @cq_template_or_i32_unc(i32 %588, i32 %587, i32 %581)
  call void @cqrt_free(i32 %588)
  call void @cq_template_shl_i32_hl_unc(i32 %587, i32 %585, i32 %586)
  call void @cqrt_free(i32 %587)
  call void @cq_template_zext_i8_to_i32_unc(i32 %585, i32 %584)
  call void @cqrt_free(i32 %585)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %584, i32 %580, i32 %9, i64 %583)
  call void @cqrt_free(i32 %584)
  call void @cqrt_free(i32 %581)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %580)
  call void @cqrt_free(i32 %580)
  call void @cqrt_invert_begin()
  %632 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %632)
  %633 = getelementptr i8, ptr %10, i64 0
  %634 = ptrtoint ptr %633 to i64
  %635 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %632, i32 %9, i64 %634, i32 %635)
  call void @cqrt_ry_i1_controlled(i32 %632, i32 %635, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %632, i32 %9, i64 %634, i32 %635)
  call void @cqrt_free(i32 %635)
  %636 = add i64 0, 1
  %637 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %636)
  %638 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %638)
  call void @cqrt_xor_i1(i32 %637, i32 %638)
  %639 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %632, i32 %638, i32 %639)
  %640 = getelementptr i8, ptr %10, i64 %636
  %641 = ptrtoint ptr %640 to i64
  %642 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %639, i32 %9, i64 %641, i32 %642)
  call void @cqrt_ry_i1_controlled(i32 %639, i32 %642, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %639, i32 %9, i64 %641, i32 %642)
  call void @cqrt_free(i32 %642)
  %643 = add i64 %636, 1
  %644 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %643)
  %645 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %645)
  call void @cqrt_xor_i1(i32 %644, i32 %645)
  %646 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %639, i32 %645, i32 %646)
  %647 = getelementptr i8, ptr %10, i64 %643
  %648 = ptrtoint ptr %647 to i64
  %649 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %646, i32 %9, i64 %648, i32 %649)
  call void @cqrt_ry_i1_controlled(i32 %646, i32 %649, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %646, i32 %9, i64 %648, i32 %649)
  call void @cqrt_free(i32 %649)
  %650 = add i64 %643, 1
  %651 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %650)
  %652 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %652)
  call void @cqrt_xor_i1(i32 %651, i32 %652)
  %653 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %646, i32 %652, i32 %653)
  %654 = getelementptr i8, ptr %10, i64 %650
  %655 = ptrtoint ptr %654 to i64
  %656 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %653, i32 %9, i64 %655, i32 %656)
  call void @cqrt_ry_i1_controlled(i32 %653, i32 %656, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %653, i32 %9, i64 %655, i32 %656)
  call void @cqrt_free(i32 %656)
  %657 = add i64 %650, 1
  %658 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %657)
  %659 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %659)
  call void @cqrt_xor_i1(i32 %658, i32 %659)
  %660 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %653, i32 %659, i32 %660)
  call void @cqrt_xor_i1(i32 %658, i32 %659)
  call void @cqrt_not_i1(i32 %659)
  call void @cqrt_free(i32 %659)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %658, i32 %68, i64 %657)
  call void @cqrt_free(i32 %658)
  call void @cqrt_and_i1(i32 %646, i32 %652, i32 %653)
  call void @cqrt_free(i32 %653)
  call void @cqrt_xor_i1(i32 %651, i32 %652)
  call void @cqrt_not_i1(i32 %652)
  call void @cqrt_free(i32 %652)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %651, i32 %68, i64 %650)
  call void @cqrt_free(i32 %651)
  call void @cqrt_and_i1(i32 %639, i32 %645, i32 %646)
  call void @cqrt_free(i32 %646)
  call void @cqrt_xor_i1(i32 %644, i32 %645)
  call void @cqrt_not_i1(i32 %645)
  call void @cqrt_free(i32 %645)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %644, i32 %68, i64 %643)
  call void @cqrt_free(i32 %644)
  call void @cqrt_and_i1(i32 %632, i32 %638, i32 %639)
  call void @cqrt_free(i32 %639)
  call void @cqrt_xor_i1(i32 %637, i32 %638)
  call void @cqrt_not_i1(i32 %638)
  call void @cqrt_free(i32 %638)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %637, i32 %68, i64 %636)
  call void @cqrt_free(i32 %637)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %632)
  call void @cqrt_free(i32 %632)
  call void @cqrt_invert_end()
  %661 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 %657)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %661, i32 %68, i64 %657)
  call void @cqrt_free(i32 %661)
  %662 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %662)
  %663 = call i32 @cqrt_alloc_i32(i32 0)
  %664 = getelementptr i8, ptr %10, i64 0
  %665 = ptrtoint ptr %664 to i64
  %666 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %662, i32 %9, i64 %665)
  %667 = call i32 @cq_template_zext_i8_to_i32(i32 %666)
  %668 = trunc i64 0 to i32
  %669 = call i32 @cq_template_shl_i32_hl(i32 %667, i32 %668)
  %670 = call i32 @cq_template_or_i32(i32 %669, i32 %663)
  %671 = add i64 0, 1
  %672 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %671)
  %673 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %673)
  call void @cqrt_xor_i1(i32 %672, i32 %673)
  %674 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %662, i32 %673, i32 %674)
  %675 = call i32 @cq_template_select_i32(i32 %662, i32 %670, i32 %663)
  %676 = getelementptr i8, ptr %10, i64 %671
  %677 = ptrtoint ptr %676 to i64
  %678 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %674, i32 %9, i64 %677)
  %679 = call i32 @cq_template_zext_i8_to_i32(i32 %678)
  %680 = trunc i64 %671 to i32
  %681 = call i32 @cq_template_shl_i32_hl(i32 %679, i32 %680)
  %682 = call i32 @cq_template_or_i32(i32 %681, i32 %675)
  %683 = add i64 %671, 1
  %684 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %683)
  %685 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %685)
  call void @cqrt_xor_i1(i32 %684, i32 %685)
  %686 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %674, i32 %685, i32 %686)
  %687 = call i32 @cq_template_select_i32(i32 %674, i32 %682, i32 %675)
  %688 = getelementptr i8, ptr %10, i64 %683
  %689 = ptrtoint ptr %688 to i64
  %690 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %686, i32 %9, i64 %689)
  %691 = call i32 @cq_template_zext_i8_to_i32(i32 %690)
  %692 = trunc i64 %683 to i32
  %693 = call i32 @cq_template_shl_i32_hl(i32 %691, i32 %692)
  %694 = call i32 @cq_template_or_i32(i32 %693, i32 %687)
  %695 = add i64 %683, 1
  %696 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %695)
  %697 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %697)
  call void @cqrt_xor_i1(i32 %696, i32 %697)
  %698 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %686, i32 %697, i32 %698)
  %699 = call i32 @cq_template_select_i32(i32 %686, i32 %694, i32 %687)
  %700 = getelementptr i8, ptr %10, i64 %695
  %701 = ptrtoint ptr %700 to i64
  %702 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %698, i32 %9, i64 %701)
  %703 = call i32 @cq_template_zext_i8_to_i32(i32 %702)
  %704 = trunc i64 %695 to i32
  %705 = call i32 @cq_template_shl_i32_hl(i32 %703, i32 %704)
  %706 = call i32 @cq_template_or_i32(i32 %705, i32 %699)
  %707 = add i64 %695, 1
  %708 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %707)
  %709 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %709)
  call void @cqrt_xor_i1(i32 %708, i32 %709)
  %710 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %698, i32 %709, i32 %710)
  call void @cqrt_xor_i1(i32 %708, i32 %709)
  call void @cqrt_not_i1(i32 %709)
  call void @cqrt_free(i32 %709)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %708, i32 %69, i64 %707)
  call void @cqrt_free(i32 %708)
  %711 = call i32 @cq_template_select_i32(i32 %698, i32 %706, i32 %699)
  %712 = call i32 @cq_template_icmp_eq_i32_hl(i32 %711, i32 0)
  %713 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %713)
  call void @cqrt_xor_i1(i32 %712, i32 %713)
  %714 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %713, i32 %714)
  call void @cqrt_rz_i1(i32 %714, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %579, i32 %713, i32 %714)
  call void @cqrt_free(i32 %714)
  call void @cqrt_xor_i1(i32 %712, i32 %713)
  call void @cqrt_not_i1(i32 %713)
  call void @cqrt_free(i32 %713)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %712, i32 %711, i32 0)
  call void @cqrt_free(i32 %712)
  call void @cq_template_select_i32_unc(i32 %711, i32 %698, i32 %706, i32 %699)
  call void @cqrt_free(i32 %711)
  call void @cq_template_or_i32_unc(i32 %706, i32 %705, i32 %699)
  call void @cqrt_free(i32 %706)
  call void @cq_template_shl_i32_hl_unc(i32 %705, i32 %703, i32 %704)
  call void @cqrt_free(i32 %705)
  call void @cq_template_zext_i8_to_i32_unc(i32 %703, i32 %702)
  call void @cqrt_free(i32 %703)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %702, i32 %698, i32 %9, i64 %701)
  call void @cqrt_free(i32 %702)
  call void @cq_template_select_i32_unc(i32 %699, i32 %686, i32 %694, i32 %687)
  call void @cqrt_free(i32 %699)
  call void @cqrt_and_i1(i32 %686, i32 %697, i32 %698)
  call void @cqrt_free(i32 %698)
  call void @cqrt_xor_i1(i32 %696, i32 %697)
  call void @cqrt_not_i1(i32 %697)
  call void @cqrt_free(i32 %697)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %696, i32 %69, i64 %695)
  call void @cqrt_free(i32 %696)
  call void @cq_template_or_i32_unc(i32 %694, i32 %693, i32 %687)
  call void @cqrt_free(i32 %694)
  call void @cq_template_shl_i32_hl_unc(i32 %693, i32 %691, i32 %692)
  call void @cqrt_free(i32 %693)
  call void @cq_template_zext_i8_to_i32_unc(i32 %691, i32 %690)
  call void @cqrt_free(i32 %691)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %690, i32 %686, i32 %9, i64 %689)
  call void @cqrt_free(i32 %690)
  call void @cq_template_select_i32_unc(i32 %687, i32 %674, i32 %682, i32 %675)
  call void @cqrt_free(i32 %687)
  call void @cqrt_and_i1(i32 %674, i32 %685, i32 %686)
  call void @cqrt_free(i32 %686)
  call void @cqrt_xor_i1(i32 %684, i32 %685)
  call void @cqrt_not_i1(i32 %685)
  call void @cqrt_free(i32 %685)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %684, i32 %69, i64 %683)
  call void @cqrt_free(i32 %684)
  call void @cq_template_or_i32_unc(i32 %682, i32 %681, i32 %675)
  call void @cqrt_free(i32 %682)
  call void @cq_template_shl_i32_hl_unc(i32 %681, i32 %679, i32 %680)
  call void @cqrt_free(i32 %681)
  call void @cq_template_zext_i8_to_i32_unc(i32 %679, i32 %678)
  call void @cqrt_free(i32 %679)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %678, i32 %674, i32 %9, i64 %677)
  call void @cqrt_free(i32 %678)
  call void @cq_template_select_i32_unc(i32 %675, i32 %662, i32 %670, i32 %663)
  call void @cqrt_free(i32 %675)
  call void @cqrt_and_i1(i32 %662, i32 %673, i32 %674)
  call void @cqrt_free(i32 %674)
  call void @cqrt_xor_i1(i32 %672, i32 %673)
  call void @cqrt_not_i1(i32 %673)
  call void @cqrt_free(i32 %673)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %672, i32 %69, i64 %671)
  call void @cqrt_free(i32 %672)
  call void @cq_template_or_i32_unc(i32 %670, i32 %669, i32 %663)
  call void @cqrt_free(i32 %670)
  call void @cq_template_shl_i32_hl_unc(i32 %669, i32 %667, i32 %668)
  call void @cqrt_free(i32 %669)
  call void @cq_template_zext_i8_to_i32_unc(i32 %667, i32 %666)
  call void @cqrt_free(i32 %667)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %666, i32 %662, i32 %9, i64 %665)
  call void @cqrt_free(i32 %666)
  call void @cqrt_free(i32 %663)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %662)
  call void @cqrt_free(i32 %662)
  %715 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %715)
  %716 = getelementptr i8, ptr %10, i64 0
  %717 = ptrtoint ptr %716 to i64
  %718 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %715, i32 %9, i64 %717, i32 %718)
  call void @cqrt_ry_i1_controlled(i32 %715, i32 %718, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %715, i32 %9, i64 %717, i32 %718)
  call void @cqrt_free(i32 %718)
  %719 = add i64 0, 1
  %720 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %719)
  %721 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %721)
  call void @cqrt_xor_i1(i32 %720, i32 %721)
  %722 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %715, i32 %721, i32 %722)
  %723 = getelementptr i8, ptr %10, i64 %719
  %724 = ptrtoint ptr %723 to i64
  %725 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %722, i32 %9, i64 %724, i32 %725)
  call void @cqrt_ry_i1_controlled(i32 %722, i32 %725, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %722, i32 %9, i64 %724, i32 %725)
  call void @cqrt_free(i32 %725)
  %726 = add i64 %719, 1
  %727 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %726)
  %728 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %728)
  call void @cqrt_xor_i1(i32 %727, i32 %728)
  %729 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %722, i32 %728, i32 %729)
  %730 = getelementptr i8, ptr %10, i64 %726
  %731 = ptrtoint ptr %730 to i64
  %732 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %729, i32 %9, i64 %731, i32 %732)
  call void @cqrt_ry_i1_controlled(i32 %729, i32 %732, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %729, i32 %9, i64 %731, i32 %732)
  call void @cqrt_free(i32 %732)
  %733 = add i64 %726, 1
  %734 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %733)
  %735 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %735)
  call void @cqrt_xor_i1(i32 %734, i32 %735)
  %736 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %729, i32 %735, i32 %736)
  %737 = getelementptr i8, ptr %10, i64 %733
  %738 = ptrtoint ptr %737 to i64
  %739 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %736, i32 %9, i64 %738, i32 %739)
  call void @cqrt_ry_i1_controlled(i32 %736, i32 %739, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %736, i32 %9, i64 %738, i32 %739)
  call void @cqrt_free(i32 %739)
  %740 = add i64 %733, 1
  %741 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 %740)
  %742 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %742)
  call void @cqrt_xor_i1(i32 %741, i32 %742)
  %743 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %736, i32 %742, i32 %743)
  call void @cqrt_xor_i1(i32 %741, i32 %742)
  call void @cqrt_not_i1(i32 %742)
  call void @cqrt_free(i32 %742)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %741, i32 %70, i64 %740)
  call void @cqrt_free(i32 %741)
  call void @cqrt_and_i1(i32 %729, i32 %735, i32 %736)
  call void @cqrt_free(i32 %736)
  call void @cqrt_xor_i1(i32 %734, i32 %735)
  call void @cqrt_not_i1(i32 %735)
  call void @cqrt_free(i32 %735)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %734, i32 %70, i64 %733)
  call void @cqrt_free(i32 %734)
  call void @cqrt_and_i1(i32 %722, i32 %728, i32 %729)
  call void @cqrt_free(i32 %729)
  call void @cqrt_xor_i1(i32 %727, i32 %728)
  call void @cqrt_not_i1(i32 %728)
  call void @cqrt_free(i32 %728)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %727, i32 %70, i64 %726)
  call void @cqrt_free(i32 %727)
  call void @cqrt_and_i1(i32 %715, i32 %721, i32 %722)
  call void @cqrt_free(i32 %722)
  call void @cqrt_xor_i1(i32 %720, i32 %721)
  call void @cqrt_not_i1(i32 %721)
  call void @cqrt_free(i32 %721)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %720, i32 %70, i64 %719)
  call void @cqrt_free(i32 %720)
  call void @cqrt_and_i1(i32 %579, i32 %31, i32 %715)
  call void @cqrt_free(i32 %715)
  %744 = add i32 %576, 1
  %745 = call i32 @cq_template_icmp_eq_i32_hl(i32 %19, i32 %744)
  %746 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %746)
  call void @cqrt_xor_i1(i32 %745, i32 %746)
  %747 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %579, i32 %746, i32 %747)
  call void @cqrt_xor_i1(i32 %745, i32 %746)
  call void @cqrt_not_i1(i32 %746)
  call void @cqrt_free(i32 %746)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %745, i32 %19, i32 %744)
  call void @cqrt_free(i32 %745)
  call void @cqrt_and_i1(i32 %411, i32 %578, i32 %579)
  call void @cqrt_free(i32 %579)
  call void @cqrt_xor_i1(i32 %577, i32 %578)
  call void @cqrt_not_i1(i32 %578)
  call void @cqrt_free(i32 %578)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %577, i32 %19, i32 %576)
  call void @cqrt_free(i32 %577)
  call void @cqrt_and_i1(i32 %243, i32 %410, i32 %411)
  call void @cqrt_free(i32 %411)
  call void @cqrt_xor_i1(i32 %409, i32 %410)
  call void @cqrt_not_i1(i32 %410)
  call void @cqrt_free(i32 %410)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %409, i32 %19, i32 %408)
  call void @cqrt_free(i32 %409)
  call void @cqrt_and_i1(i32 %72, i32 %242, i32 %243)
  call void @cqrt_free(i32 %243)
  call void @cqrt_xor_i1(i32 %241, i32 %242)
  call void @cqrt_not_i1(i32 %242)
  call void @cqrt_free(i32 %242)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %241, i32 %19, i32 %240)
  call void @cqrt_free(i32 %241)
  call void @cqrt_and_i1(i32 %0, i32 %73, i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cqrt_and_i1(i32 %66, i32 %74, i32 %73)
  call void @cqrt_free(i32 %73)
  call void @cqrt_and_i1(i32 %14, i32 %75, i32 %74)
  call void @cqrt_free(i32 %74)
  call void @cqrt_xor_i1(i32 %12, i32 %75)
  call void @cqrt_not_i1(i32 %75)
  call void @cqrt_free(i32 %75)
  %748 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  %749 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  br label %750

750:                                              ; preds = %71
  call void @cq_template_zext_i32_to_i64_unc(i32 %70, i32 %1)
  call void @cqrt_free(i32 %70)
  call void @cq_template_zext_i32_to_i64_unc(i32 %69, i32 %1)
  call void @cqrt_free(i32 %69)
  call void @cq_template_zext_i32_to_i64_unc(i32 %68, i32 %1)
  call void @cqrt_free(i32 %68)
  call void @cq_template_zext_i32_to_i64_unc(i32 %67, i32 %1)
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %66, i32 %19, i32 0)
  call void @cqrt_free(i32 %66)
  call void @cq_template_zext_i32_to_i64_unc(i32 %32, i32 %1)
  call void @cqrt_free(i32 %32)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %31, i32 %1, i32 0)
  call void @cqrt_free(i32 %31)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_floor_f64_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cq_template_fmul_f64_hl_unc(i32 %17, i32 %16, double 0x3FE921FB54442D18)
  call void @cqrt_free(i32 %17)
  call void @cq_template_sqrt_f64_unc(i32 %16, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_uitofp_i32_to_f64_unc(i32 %15, i32 %13)
  call void @cqrt_free(i32 %15)
  %751 = call i32 @cqrt_alloc_i1(i1 false)
  %752 = call i32 @cqrt_alloc_i1(i1 false)
  %753 = call i32 @cqrt_alloc_i1(i1 false)
  %754 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %754)
  call void @cqrt_xor_i1(i32 %12, i32 %754)
  call void @cqrt_and_i1(i32 %14, i32 %754, i32 %753)
  call void @cqrt_and_i1(i32 %748, i32 %753, i32 %752)
  call void @cqrt_and_i1(i32 %0, i32 %752, i32 %751)
  %755 = call i32 @cqrt_alloc_i32(i32 0)
  %756 = getelementptr [16 x i8], ptr %10, i64 0, i64 0
  %757 = ptrtoint ptr %756 to i64
  %758 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %751, i32 %9, i64 %757)
  %759 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %0, i32 %758, i32 %759)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %758, i32 %751, i32 %9, i64 %757)
  call void @cqrt_free(i32 %758)
  %760 = call i1 @cqrt_measure_i1(i32 %759), !cq.measure !6
  %761 = call i32 @cq_template_zext_i1_to_i32(i32 %759)
  %762 = trunc i64 0 to i32
  %763 = call i32 @cq_template_shl_i32_hl(i32 %761, i32 %762)
  %764 = call i32 @cq_template_or_i32(i32 %763, i32 %755)
  %765 = add i64 0, 1
  %766 = call i32 @cq_template_icmp_eq_i64_hl(i32 %749, i64 %765)
  %767 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %767)
  call void @cqrt_xor_i1(i32 %766, i32 %767)
  %768 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %751, i32 %767, i32 %768)
  %769 = call i32 @cq_template_select_i32(i32 %751, i32 %764, i32 %755)
  %770 = getelementptr [16 x i8], ptr %10, i64 0, i64 %765
  %771 = ptrtoint ptr %770 to i64
  %772 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %768, i32 %9, i64 %771)
  %773 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %0, i32 %772, i32 %773)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %772, i32 %768, i32 %9, i64 %771)
  call void @cqrt_free(i32 %772)
  %774 = call i1 @cqrt_measure_i1(i32 %773), !cq.measure !6
  %775 = call i32 @cq_template_zext_i1_to_i32(i32 %773)
  %776 = trunc i64 %765 to i32
  %777 = call i32 @cq_template_shl_i32_hl(i32 %775, i32 %776)
  %778 = call i32 @cq_template_or_i32(i32 %777, i32 %769)
  %779 = add i64 %765, 1
  %780 = call i32 @cq_template_icmp_eq_i64_hl(i32 %749, i64 %779)
  %781 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %781)
  call void @cqrt_xor_i1(i32 %780, i32 %781)
  %782 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %768, i32 %781, i32 %782)
  %783 = call i32 @cq_template_select_i32(i32 %768, i32 %778, i32 %769)
  %784 = getelementptr [16 x i8], ptr %10, i64 0, i64 %779
  %785 = ptrtoint ptr %784 to i64
  %786 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %782, i32 %9, i64 %785)
  %787 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %0, i32 %786, i32 %787)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %786, i32 %782, i32 %9, i64 %785)
  call void @cqrt_free(i32 %786)
  %788 = call i1 @cqrt_measure_i1(i32 %787), !cq.measure !6
  %789 = call i32 @cq_template_zext_i1_to_i32(i32 %787)
  %790 = trunc i64 %779 to i32
  %791 = call i32 @cq_template_shl_i32_hl(i32 %789, i32 %790)
  %792 = call i32 @cq_template_or_i32(i32 %791, i32 %783)
  %793 = add i64 %779, 1
  %794 = call i32 @cq_template_icmp_eq_i64_hl(i32 %749, i64 %793)
  %795 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %795)
  call void @cqrt_xor_i1(i32 %794, i32 %795)
  %796 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %782, i32 %795, i32 %796)
  %797 = call i32 @cq_template_select_i32(i32 %782, i32 %792, i32 %783)
  %798 = getelementptr [16 x i8], ptr %10, i64 0, i64 %793
  %799 = ptrtoint ptr %798 to i64
  %800 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %796, i32 %9, i64 %799)
  %801 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %0, i32 %800, i32 %801)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %800, i32 %796, i32 %9, i64 %799)
  call void @cqrt_free(i32 %800)
  %802 = call i1 @cqrt_measure_i1(i32 %801), !cq.measure !6
  %803 = call i32 @cq_template_zext_i1_to_i32(i32 %801)
  %804 = trunc i64 %793 to i32
  %805 = call i32 @cq_template_shl_i32_hl(i32 %803, i32 %804)
  %806 = call i32 @cq_template_or_i32(i32 %805, i32 %797)
  %807 = add i64 %793, 1
  %808 = call i32 @cq_template_icmp_eq_i64_hl(i32 %749, i64 %807)
  %809 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %809)
  call void @cqrt_xor_i1(i32 %808, i32 %809)
  %810 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %796, i32 %809, i32 %810)
  call void @cqrt_xor_i1(i32 %808, i32 %809)
  call void @cqrt_not_i1(i32 %809)
  call void @cqrt_free(i32 %809)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %808, i32 %749, i64 %807)
  call void @cqrt_free(i32 %808)
  %811 = call i32 @cq_template_select_i32(i32 %796, i32 %806, i32 %797)
  %812 = call i32 @cqrt_alloc_i1(i1 false)
  %813 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %813)
  call void @cqrt_xor_i1(i32 %12, i32 %813)
  call void @cqrt_and_i1(i32 %14, i32 %813, i32 %812)
  %814 = call i32 @cq_template_select_i32_hl(i32 %812, i32 %811, i32 -1)
  %815 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %815)
  %816 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %814, i32 %816)
  call void @cq_template_select_i32_hl_unc(i32 %814, i32 %812, i32 %811, i32 -1)
  call void @cqrt_free(i32 %814)
  call void @cqrt_and_i1(i32 %14, i32 %813, i32 %812)
  call void @cqrt_free(i32 %812)
  call void @cqrt_xor_i1(i32 %12, i32 %813)
  call void @cqrt_not_i1(i32 %813)
  call void @cqrt_free(i32 %813)
  call void @cq_template_select_i32_unc(i32 %811, i32 %796, i32 %806, i32 %797)
  call void @cqrt_free(i32 %811)
  call void @cq_template_or_i32_unc(i32 %806, i32 %805, i32 %797)
  call void @cqrt_free(i32 %806)
  call void @cq_template_shl_i32_hl_unc(i32 %805, i32 %803, i32 %804)
  call void @cqrt_free(i32 %805)
  call void @cq_template_zext_i1_to_i32_unc(i32 %803, i32 %801)
  call void @cqrt_free(i32 %803)
  call void @cq_template_select_i32_unc(i32 %797, i32 %782, i32 %792, i32 %783)
  call void @cqrt_free(i32 %797)
  call void @cqrt_and_i1(i32 %782, i32 %795, i32 %796)
  call void @cqrt_free(i32 %796)
  call void @cqrt_xor_i1(i32 %794, i32 %795)
  call void @cqrt_not_i1(i32 %795)
  call void @cqrt_free(i32 %795)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %794, i32 %749, i64 %793)
  call void @cqrt_free(i32 %794)
  call void @cq_template_or_i32_unc(i32 %792, i32 %791, i32 %783)
  call void @cqrt_free(i32 %792)
  call void @cq_template_shl_i32_hl_unc(i32 %791, i32 %789, i32 %790)
  call void @cqrt_free(i32 %791)
  call void @cq_template_zext_i1_to_i32_unc(i32 %789, i32 %787)
  call void @cqrt_free(i32 %789)
  call void @cq_template_select_i32_unc(i32 %783, i32 %768, i32 %778, i32 %769)
  call void @cqrt_free(i32 %783)
  call void @cqrt_and_i1(i32 %768, i32 %781, i32 %782)
  call void @cqrt_free(i32 %782)
  call void @cqrt_xor_i1(i32 %780, i32 %781)
  call void @cqrt_not_i1(i32 %781)
  call void @cqrt_free(i32 %781)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %780, i32 %749, i64 %779)
  call void @cqrt_free(i32 %780)
  call void @cq_template_or_i32_unc(i32 %778, i32 %777, i32 %769)
  call void @cqrt_free(i32 %778)
  call void @cq_template_shl_i32_hl_unc(i32 %777, i32 %775, i32 %776)
  call void @cqrt_free(i32 %777)
  call void @cq_template_zext_i1_to_i32_unc(i32 %775, i32 %773)
  call void @cqrt_free(i32 %775)
  call void @cq_template_select_i32_unc(i32 %769, i32 %751, i32 %764, i32 %755)
  call void @cqrt_free(i32 %769)
  call void @cqrt_and_i1(i32 %751, i32 %767, i32 %768)
  call void @cqrt_free(i32 %768)
  call void @cqrt_xor_i1(i32 %766, i32 %767)
  call void @cqrt_not_i1(i32 %767)
  call void @cqrt_free(i32 %767)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %766, i32 %749, i64 %765)
  call void @cqrt_free(i32 %766)
  call void @cq_template_or_i32_unc(i32 %764, i32 %763, i32 %755)
  call void @cqrt_free(i32 %764)
  call void @cq_template_shl_i32_hl_unc(i32 %763, i32 %761, i32 %762)
  call void @cqrt_free(i32 %763)
  call void @cq_template_zext_i1_to_i32_unc(i32 %761, i32 %759)
  call void @cqrt_free(i32 %761)
  call void @cqrt_free(i32 %755)
  call void @cqrt_and_i1(i32 %0, i32 %752, i32 %751)
  call void @cqrt_free(i32 %751)
  call void @cqrt_and_i1(i32 %748, i32 %753, i32 %752)
  call void @cqrt_free(i32 %752)
  call void @cqrt_and_i1(i32 %14, i32 %754, i32 %753)
  call void @cqrt_free(i32 %753)
  call void @cqrt_xor_i1(i32 %12, i32 %754)
  call void @cqrt_not_i1(i32 %754)
  call void @cqrt_free(i32 %754)
  call void @cq_template_zext_i32_to_i64_unc(i32 %749, i32 %1)
  call void @cqrt_free(i32 %749)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %748, i32 %1, i32 0)
  call void @cqrt_free(i32 %748)
  call void @cq_template_icmp_ugt_i32_unc(i32 %14, i32 %13, i32 %2)
  call void @cqrt_free(i32 %14)
  call void @cq_template_shl_i32_lh_unc(i32 %13, i32 1, i32 %1)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %12, i32 %11, i32 -16)
  call void @cqrt_free(i32 %12)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %1, i32 -17)
  call void @cqrt_free(i32 %11)
  %817 = load i32, ptr @__cq_act_grover, align 4
  %818 = add i32 %817, -1
  store i32 %818, ptr @__cq_act_grover, align 4
  ret i32 %816

819:                                              ; preds = %4
  %820 = call i32 @cqrt_alloc_i32(i32 0)
  %821 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %821)
  call void @cqrt_push(i32 0)
  %822 = load i32, ptr @__cq_act_grover, align 4
  %823 = add i32 %822, -1
  store i32 %823, ptr @__cq_act_grover, align 4
  ret i32 %820
}

declare void @cqrt_copy_i1_controlled(i32, i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare void @cq_template_zext_i1_to_i32_unc(i32, i32)

define internal i32 @__cq_q_grover_3_v_t(i32 %0) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %2 = tail call i32 @grover(i32 noundef 3, i32 noundef 5)
  %3 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %3)
  %4 = call i32 @cqrt_alloc_i32(i32 %2)
  ret i32 %4
}

define internal i32 @__cq_q_grover_3_v_t_ctl(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_act_grover_3, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_grover_3, align 4
  %5 = icmp ult i32 %3, %1
  br i1 %5, label %6, label %12

6:                                                ; preds = %2
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %7 = call i32 @__cq_q_grover_00_ctl(i32 %0, i32 3, i32 5)
  %8 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %8)
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %7, i32 %9)
  %10 = load i32, ptr @__cq_act_grover_3, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_grover_3, align 4
  ret i32 %9

12:                                               ; preds = %2
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %14)
  call void @cqrt_push(i32 0)
  %15 = load i32, ptr @__cq_act_grover_3, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_grover_3, align 4
  ret i32 %13
}

define i32 @__cq_q_grover_00_ctl(i32 %0, i32 %1, i32 %2) local_unnamed_addr {
  %4 = load i32, ptr @__cq_act_grover, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_grover, align 4
  %6 = icmp ult i32 %4, 4
  br i1 %6, label %7, label %219

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 16, i64 16)
  %10 = add i32 %1, -17
  %11 = icmp ult i32 %10, -16
  %12 = call i32 @cqrt_alloc_i32(i32 -1)
  br i1 %11, label %13, label %22

13:                                               ; preds = %7, %22, %188
  %14 = phi i32 [ poison, %7 ], [ %25, %22 ], [ %25, %188 ]
  %15 = phi i32 [ poison, %7 ], [ poison, %22 ], [ %64, %188 ]
  %16 = phi i32 [ poison, %7 ], [ poison, %22 ], [ %189, %188 ]
  %ran = phi i1 [ false, %7 ], [ false, %22 ], [ %ran39, %188 ]
  %cq.run35 = phi i1 [ true, %188 ], [ false, %22 ], [ false, %7 ]
  %cq.run = phi i1 [ true, %188 ], [ true, %22 ], [ false, %7 ]
  %17 = phi i32 [ %12, %7 ], [ %25, %22 ], [ %190, %188 ]
  %18 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %17, i32 %18)
  br i1 %cq.run, label %.cq.arm64, label %.cq.after63

.cq.arm64:                                        ; preds = %13
  call void @cqrt_free(i32 %14)
  br label %.cq.after63

.cq.after63:                                      ; preds = %13, %.cq.arm64
  call void @cqrt_free(i32 %12)
  br i1 %cq.run35, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %.cq.after63
  call void @cqrt_free(i32 %15)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after63, %.cq.arm
  br i1 %ran, label %210, label %218

19:                                               ; preds = %218
  %20 = load i32, ptr @__cq_act_grover, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_grover, align 4
  ret i32 %18

22:                                               ; preds = %7
  %23 = shl nuw nsw i32 1, %1
  %24 = icmp ugt i32 %23, %2
  %25 = call i32 @cqrt_alloc_i32(i32 -1)
  br i1 %24, label %26, label %13

26:                                               ; preds = %22
  %27 = uitofp nneg i32 %23 to double
  %28 = tail call double @llvm.sqrt.f64(double %27)
  %29 = fmul double %28, 0x3FE921FB54442D18
  %30 = tail call double @llvm.floor.f64(double %29)
  %31 = fptosi double %30 to i32
  %32 = ptrtoint ptr %9 to i64
  %33 = call i32 @cqrt_alloc_i8(i8 0)
  br label %34

34:                                               ; preds = %34, %26
  %35 = phi i64 [ 0, %26 ], [ %37, %34 ]
  %36 = add i64 %32, %35
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %36, i32 %33)
  %37 = add nuw i64 %35, 1
  %38 = icmp eq i64 %37, 16
  br i1 %38, label %39, label %34

39:                                               ; preds = %34
  %40 = icmp sgt i32 %1, 0
  br i1 %40, label %41, label %43

41:                                               ; preds = %39
  %42 = zext nneg i32 %1 to i64
  br label %45

43:                                               ; preds = %54, %39
  %44 = icmp sgt i32 %31, 0
  br i1 %44, label %57, label %62

45:                                               ; preds = %41
  br label %47

46:                                               ; preds = %47
  br label %55

47:                                               ; preds = %47, %45
  %from = phi i32 [ 0, %47 ], [ 1, %45 ]
  %48 = phi i64 [ 0, %45 ], [ %52, %47 ]
  call void @cqrt_push(i32 %from)
  %49 = getelementptr inbounds i8, ptr %9, i64 %48
  %50 = ptrtoint ptr %49 to i64
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %8, i64 %50, i32 %51)
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %51, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %8, i64 %50, i32 %51)
  call void @cqrt_free(i32 %51)
  %52 = add nuw nsw i64 %48, 1
  %53 = icmp eq i64 %52, %42
  br i1 %53, label %46, label %47

54:                                               ; preds = %55
  br label %43

55:                                               ; preds = %46, %55
  %56 = call i32 @cqrt_pop()
  switch i32 %56, label %55 [
    i32 1, label %54
  ]

57:                                               ; preds = %43
  %58 = zext nneg i32 %1 to i64
  %59 = zext nneg i32 %1 to i64
  %60 = zext nneg i32 %1 to i64
  %61 = zext nneg i32 %1 to i64
  br label %65

62:                                               ; preds = %133, %43
  %63 = icmp sgt i32 %1, 0
  %64 = call i32 @cqrt_alloc_i32(i32 0)
  br i1 %63, label %186, label %188

65:                                               ; preds = %57
  br label %67

66:                                               ; preds = %123
  br label %184

67:                                               ; preds = %123, %65
  %from9 = phi i32 [ 0, %123 ], [ 1, %65 ]
  %68 = phi i32 [ 0, %65 ], [ %124, %123 ]
  call void @cqrt_push(i32 %from9)
  %69 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %69)
  br i1 %40, label %70, label %72

70:                                               ; preds = %67
  %71 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %71)
  br label %76

72:                                               ; preds = %76, %67
  %from7 = phi i32 [ 0, %76 ], [ 1, %67 ]
  %73 = phi i32 [ %69, %67 ], [ %85, %76 ]
  call void @cqrt_push(i32 %from7)
  %74 = call i32 @cq_template_icmp_eq_i32_hl(i32 %73, i32 %2)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %74, i32 %75)
  call void @cqrt_rz_i1(i32 %75, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %0, i32 %74, i32 %75)
  call void @cqrt_free(i32 %75)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %74, i32 %73, i32 %2)
  call void @cqrt_free(i32 %74)
  call void @cqrt_invert_begin()
  br i1 %40, label %91, label %92

76:                                               ; preds = %76, %70
  %from8 = phi i32 [ 0, %76 ], [ 1, %70 ]
  %77 = phi i64 [ 0, %70 ], [ %86, %76 ]
  %78 = phi i32 [ %71, %70 ], [ %85, %76 ]
  call void @cqrt_push(i32 %from8)
  %79 = getelementptr inbounds i8, ptr %9, i64 %77
  %80 = ptrtoint ptr %79 to i64
  %81 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %80)
  %82 = call i32 @cq_template_zext_i8_to_i32(i32 %81)
  %83 = trunc nuw nsw i64 %77 to i32
  %84 = call i32 @cq_template_shl_i32_hl(i32 %82, i32 %83)
  %85 = call i32 @cq_template_or_i32(i32 %84, i32 %78)
  %86 = add nuw nsw i64 %77, 1
  %87 = icmp eq i64 %86, %58
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %81)
  %88 = trunc i64 %80 to i32
  call void @cqrt_push(i32 %88)
  %89 = lshr i64 %80, 32
  %90 = trunc i64 %89 to i32
  call void @cqrt_push(i32 %90)
  br i1 %87, label %72, label %76

91:                                               ; preds = %72
  br label %94

92:                                               ; preds = %94, %72
  %from5 = phi i32 [ 0, %94 ], [ 1, %72 ]
  call void @cqrt_push(i32 %from5)
  call void @cqrt_invert_end()
  %93 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %93)
  br i1 %40, label %101, label %103

94:                                               ; preds = %94, %91
  %from6 = phi i32 [ 0, %94 ], [ 1, %91 ]
  %95 = phi i64 [ 0, %91 ], [ %99, %94 ]
  call void @cqrt_push(i32 %from6)
  %96 = getelementptr inbounds i8, ptr %9, i64 %95
  %97 = ptrtoint ptr %96 to i64
  %98 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %8, i64 %97, i32 %98)
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %98, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %8, i64 %97, i32 %98)
  call void @cqrt_free(i32 %98)
  %99 = add nuw nsw i64 %95, 1
  %100 = icmp eq i64 %99, %59
  br i1 %100, label %92, label %94

101:                                              ; preds = %92
  %102 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %102)
  br label %107

103:                                              ; preds = %107, %92
  %from3 = phi i32 [ 0, %107 ], [ 1, %92 ]
  %104 = phi i32 [ %93, %92 ], [ %116, %107 ]
  call void @cqrt_push(i32 %from3)
  %105 = call i32 @cq_template_icmp_eq_i32_hl(i32 %104, i32 0)
  %106 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %105)
  call void @cqrt_and_i1(i32 %0, i32 %105, i32 %106)
  call void @cqrt_rz_i1(i32 %106, double 0x400921FB54442D18)
  call void @cqrt_and_i1(i32 %0, i32 %105, i32 %106)
  call void @cqrt_not_i1(i32 %105)
  call void @cqrt_free(i32 %106)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %105, i32 %104, i32 0)
  call void @cqrt_free(i32 %105)
  br i1 %40, label %122, label %123

107:                                              ; preds = %107, %101
  %from4 = phi i32 [ 0, %107 ], [ 1, %101 ]
  %108 = phi i64 [ 0, %101 ], [ %117, %107 ]
  %109 = phi i32 [ %102, %101 ], [ %116, %107 ]
  call void @cqrt_push(i32 %from4)
  %110 = getelementptr inbounds i8, ptr %9, i64 %108
  %111 = ptrtoint ptr %110 to i64
  %112 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %111)
  %113 = call i32 @cq_template_zext_i8_to_i32(i32 %112)
  %114 = trunc nuw nsw i64 %108 to i32
  %115 = call i32 @cq_template_shl_i32_hl(i32 %113, i32 %114)
  %116 = call i32 @cq_template_or_i32(i32 %115, i32 %109)
  %117 = add nuw nsw i64 %108, 1
  %118 = icmp eq i64 %117, %60
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %109)
  call void @cqrt_push(i32 %113)
  call void @cqrt_push(i32 %114)
  call void @cqrt_push(i32 %112)
  %119 = trunc i64 %111 to i32
  call void @cqrt_push(i32 %119)
  %120 = lshr i64 %111, 32
  %121 = trunc i64 %120 to i32
  call void @cqrt_push(i32 %121)
  br i1 %118, label %103, label %107

122:                                              ; preds = %103
  br label %126

123:                                              ; preds = %126, %103
  %from1 = phi i32 [ 0, %126 ], [ 1, %103 ]
  call void @cqrt_push(i32 %from1)
  %124 = add nuw nsw i32 %68, 1
  %125 = icmp eq i32 %124, %31
  br i1 %125, label %66, label %67

126:                                              ; preds = %126, %122
  %from2 = phi i32 [ 0, %126 ], [ 1, %122 ]
  %127 = phi i64 [ 0, %122 ], [ %131, %126 ]
  call void @cqrt_push(i32 %from2)
  %128 = getelementptr inbounds i8, ptr %9, i64 %127
  %129 = ptrtoint ptr %128 to i64
  %130 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %8, i64 %129, i32 %130)
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %130, double 0x3FF921FB54442D18)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %8, i64 %129, i32 %130)
  call void @cqrt_free(i32 %130)
  %131 = add nuw nsw i64 %127, 1
  %132 = icmp eq i64 %131, %61
  br i1 %132, label %123, label %126

133:                                              ; preds = %134
  br label %62

134:                                              ; preds = %137, %154
  %135 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %135)
  %136 = call i32 @cqrt_pop()
  switch i32 %136, label %184 [
    i32 1, label %133
  ]

137:                                              ; preds = %139
  %138 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %138)
  br label %134

139:                                              ; preds = %139, %154
  %140 = call i32 @cqrt_pop()
  %141 = zext i32 %140 to i64
  %142 = shl i64 %141, 32
  %143 = or i64 0, %142
  %144 = call i32 @cqrt_pop()
  %145 = zext i32 %144 to i64
  %146 = or i64 %143, %145
  %147 = call i32 @cqrt_pop()
  %148 = call i32 @cqrt_pop()
  %149 = call i32 @cqrt_pop()
  %150 = call i32 @cqrt_pop()
  %151 = call i32 @cqrt_pop()
  %152 = call i32 @cqrt_pop()
  call void @cq_template_or_i32_unc(i32 %152, i32 %151, i32 %150)
  call void @cqrt_free(i32 %152)
  call void @cq_template_shl_i32_hl_unc(i32 %151, i32 %149, i32 %148)
  call void @cqrt_free(i32 %151)
  call void @cq_template_zext_i8_to_i32_unc(i32 %149, i32 %147)
  call void @cqrt_free(i32 %149)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %147, i32 %0, i32 %8, i64 %146)
  %153 = call i32 @cqrt_pop()
  switch i32 %153, label %139 [
    i32 1, label %137
  ]

154:                                              ; preds = %156, %159
  %155 = call i32 @cqrt_pop()
  switch i32 %155, label %139 [
    i32 1, label %134
  ]

156:                                              ; preds = %157
  br label %154

157:                                              ; preds = %157, %159
  %158 = call i32 @cqrt_pop()
  switch i32 %158, label %157 [
    i32 1, label %156
  ]

159:                                              ; preds = %162, %179
  %160 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %160)
  %161 = call i32 @cqrt_pop()
  switch i32 %161, label %157 [
    i32 1, label %154
  ]

162:                                              ; preds = %164
  %163 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %163)
  br label %159

164:                                              ; preds = %164, %179
  %165 = call i32 @cqrt_pop()
  %166 = zext i32 %165 to i64
  %167 = shl i64 %166, 32
  %168 = or i64 0, %167
  %169 = call i32 @cqrt_pop()
  %170 = zext i32 %169 to i64
  %171 = or i64 %168, %170
  %172 = call i32 @cqrt_pop()
  %173 = call i32 @cqrt_pop()
  %174 = call i32 @cqrt_pop()
  %175 = call i32 @cqrt_pop()
  %176 = call i32 @cqrt_pop()
  %177 = call i32 @cqrt_pop()
  call void @cq_template_or_i32_unc(i32 %177, i32 %176, i32 %175)
  call void @cqrt_free(i32 %177)
  call void @cq_template_shl_i32_hl_unc(i32 %176, i32 %174, i32 %173)
  call void @cqrt_free(i32 %176)
  call void @cq_template_zext_i8_to_i32_unc(i32 %174, i32 %172)
  call void @cqrt_free(i32 %174)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %172, i32 %0, i32 %8, i64 %171)
  %178 = call i32 @cqrt_pop()
  switch i32 %178, label %164 [
    i32 1, label %162
  ]

179:                                              ; preds = %181, %184
  %180 = call i32 @cqrt_pop()
  switch i32 %180, label %164 [
    i32 1, label %159
  ]

181:                                              ; preds = %182
  br label %179

182:                                              ; preds = %182, %184
  %183 = call i32 @cqrt_pop()
  switch i32 %183, label %182 [
    i32 1, label %181
  ]

184:                                              ; preds = %66, %134
  %185 = call i32 @cqrt_pop()
  switch i32 %185, label %182 [
    i32 1, label %179
  ]

186:                                              ; preds = %62
  %187 = zext nneg i32 %1 to i64
  br label %191

188:                                              ; preds = %208, %62
  %189 = phi i32 [ %192, %208 ], [ poison, %62 ]
  %ran39 = phi i1 [ true, %208 ], [ false, %62 ]
  %190 = phi i32 [ %64, %62 ], [ %205, %208 ]
  br label %13

191:                                              ; preds = %186
  %192 = call i32 @cqrt_alloc_i32(i32 0)
  br label %194

193:                                              ; preds = %194
  br label %208

194:                                              ; preds = %194, %191
  %from38 = phi i32 [ 0, %194 ], [ 1, %191 ]
  %195 = phi i64 [ 0, %191 ], [ %206, %194 ]
  %196 = phi i32 [ %192, %191 ], [ %205, %194 ]
  call void @cqrt_push(i32 %from38)
  %197 = getelementptr inbounds [16 x i8], ptr %9, i64 0, i64 %195
  %198 = ptrtoint ptr %197 to i64
  %199 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %0, i32 %8, i64 %198)
  %200 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %0, i32 %199, i32 %200)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %199, i32 %0, i32 %8, i64 %198)
  call void @cqrt_free(i32 %199)
  %201 = call i1 @cqrt_measure_i1(i32 %200), !cq.measure !6
  %202 = call i32 @cq_template_zext_i1_to_i32(i32 %200)
  %203 = trunc nuw nsw i64 %195 to i32
  %204 = call i32 @cq_template_shl_i32_hl(i32 %202, i32 %203)
  %205 = call i32 @cq_template_or_i32(i32 %204, i32 %196)
  %206 = add nuw nsw i64 %195, 1
  %207 = icmp eq i64 %206, %187
  call void @cqrt_push(i32 %205)
  call void @cqrt_push(i32 %204)
  call void @cqrt_push(i32 %196)
  call void @cqrt_push(i32 %202)
  call void @cqrt_push(i32 %203)
  call void @cqrt_push(i32 %200)
  br i1 %207, label %193, label %194

208:                                              ; preds = %193
  br label %188

209:                                              ; preds = %210
  call void @cqrt_free(i32 %16)
  br label %218

210:                                              ; preds = %.cq.after, %210
  %211 = call i32 @cqrt_pop()
  %212 = call i32 @cqrt_pop()
  %213 = call i32 @cqrt_pop()
  %214 = call i32 @cqrt_pop()
  %215 = call i32 @cqrt_pop()
  %216 = call i32 @cqrt_pop()
  call void @cq_template_or_i32_unc(i32 %216, i32 %215, i32 %214)
  call void @cqrt_free(i32 %216)
  call void @cq_template_shl_i32_hl_unc(i32 %215, i32 %213, i32 %212)
  call void @cqrt_free(i32 %215)
  call void @cq_template_zext_i1_to_i32_unc(i32 %213, i32 %211)
  call void @cqrt_free(i32 %213)
  %217 = call i32 @cqrt_pop()
  switch i32 %217, label %210 [
    i32 1, label %209
  ]

218:                                              ; preds = %209, %.cq.after
  br label %19

219:                                              ; preds = %3
  %220 = call i32 @cqrt_alloc_i32(i32 0)
  %221 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %221)
  %222 = load i32, ptr @__cq_act_grover, align 4
  %223 = add i32 %222, -1
  store i32 %223, ptr @__cq_act_grover, align 4
  ret i32 %220
}

define internal i32 @__cq_q_grover_4_v_t(i32 %0) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %2 = tail call i32 @grover(i32 noundef 4, i32 noundef 11)
  %3 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %3)
  %4 = call i32 @cqrt_alloc_i32(i32 %2)
  ret i32 %4
}

define internal i32 @__cq_q_grover_4_v_t_ctl(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_act_grover_4, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_grover_4, align 4
  %5 = icmp ult i32 %3, %1
  br i1 %5, label %6, label %12

6:                                                ; preds = %2
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %7 = call i32 @__cq_q_grover_00_ctl(i32 %0, i32 4, i32 11)
  %8 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %8)
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %7, i32 %9)
  %10 = load i32, ptr @__cq_act_grover_4, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_grover_4, align 4
  ret i32 %9

12:                                               ; preds = %2
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %14)
  call void @cqrt_push(i32 0)
  %15 = load i32, ptr @__cq_act_grover_4, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_grover_4, align 4
  ret i32 %13
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @grover, ptr @.cq.sig, ptr @__cq_q_grover_11_t, ptr @__cq_q_grover_11_t_ctl, ptr @__cq_q_grover_11_t_unc, ptr @__cq_q_grover_11_t_ctl_unc)
  call void @__cq_clone_register(ptr @grover_3, ptr @.cq.sig.1, ptr @__cq_q_grover_3_v_t, ptr @__cq_q_grover_3_v_t_ctl, ptr @__cq_q_grover_3_v_t_unc, ptr @__cq_q_grover_3_v_t_ctl_unc)
  call void @__cq_clone_register(ptr @grover_4, ptr @.cq.sig.1, ptr @__cq_q_grover_4_v_t, ptr @__cq_q_grover_4_v_t_ctl, ptr @__cq_q_grover_4_v_t_unc, ptr @__cq_q_grover_4_v_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_grover_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cqrt_pop()
  br label %6

6:                                                ; preds = %9, %4
  %7 = phi i32 [ %5, %4 ], [ %11, %9 ]
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %6
  %10 = call i32 @cqrt_pop()
  %11 = sub i32 %7, 1
  br label %6

12:                                               ; preds = %6
  ret void
}

define internal void @__cq_q_grover_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_grover, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_grover, align 4
  %8 = load i32, ptr @__cq_act_grover, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_grover, align 4
  %10 = call i32 @cqrt_pop()
  br label %11

11:                                               ; preds = %14, %5
  %12 = phi i32 [ %10, %5 ], [ %16, %14 ]
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %17, label %14

14:                                               ; preds = %11
  %15 = call i32 @cqrt_pop()
  %16 = sub i32 %12, 1
  br label %11

17:                                               ; preds = %11
  ret void
}

define internal void @__cq_q_grover_3_v_t_unc(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_pop()
  br label %4

4:                                                ; preds = %7, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %7 ]
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %4
  %8 = call i32 @cqrt_pop()
  %9 = sub i32 %5, 1
  br label %4

10:                                               ; preds = %4
  ret void
}

define internal void @__cq_q_grover_3_v_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_grover_3, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_grover_3, align 4
  %6 = load i32, ptr @__cq_act_grover_3, align 4
  %7 = add i32 %6, -1
  store i32 %7, ptr @__cq_act_grover_3, align 4
  %8 = call i32 @cqrt_pop()
  br label %9

9:                                                ; preds = %12, %3
  %10 = phi i32 [ %8, %3 ], [ %14, %12 ]
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %9
  %13 = call i32 @cqrt_pop()
  %14 = sub i32 %10, 1
  br label %9

15:                                               ; preds = %9
  ret void
}

define internal void @__cq_q_grover_4_v_t_unc(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_pop()
  br label %4

4:                                                ; preds = %7, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %7 ]
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %4
  %8 = call i32 @cqrt_pop()
  %9 = sub i32 %5, 1
  br label %4

10:                                               ; preds = %4
  ret void
}

define internal void @__cq_q_grover_4_v_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_grover_4, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_grover_4, align 4
  %6 = load i32, ptr @__cq_act_grover_4, align 4
  %7 = add i32 %6, -1
  store i32 %7, ptr @__cq_act_grover_4, align 4
  %8 = call i32 @cqrt_pop()
  br label %9

9:                                                ; preds = %12, %3
  %10 = phi i32 [ %8, %3 ], [ %14, %12 ]
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %9
  %13 = call i32 @cqrt_pop()
  %14 = sub i32 %10, 1
  br label %9

15:                                               ; preds = %9
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
