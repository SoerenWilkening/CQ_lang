; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/experiments/gmp/build/pf/f/2009587540.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str.27 = external hidden unnamed_addr constant [10 x i8], align 1
@.str.4.30 = external hidden unnamed_addr constant [10 x i8], align 1
@.str.5 = external hidden unnamed_addr constant [8 x i8], align 1
@.cq.effect.__gmp_assert_fail = private unnamed_addr constant [18 x i8] c"__gmp_assert_fail\00", align 1
@__cq_act_mpn_mul_fft_decompose = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [51 x i8] c"void (ptr, ptr, i64, i64, ptr, i64, i64, i64, ptr)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
declare range(i64 0, 2) i64 @__gmpn_sub_n(ptr nocapture noundef writeonly, ptr nocapture noundef readonly, ptr nocapture noundef readonly, i64 noundef) local_unnamed_addr #3

; Function Attrs: noreturn nounwind ssp uwtable
declare void @__gmp_assert_fail(ptr noundef, i32 noundef, ptr noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @mpn_mul_fft_decompose(ptr noundef %0, ptr noundef %1, i64 noundef %2, i64 noundef %3, ptr noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, ptr noundef %8) unnamed_addr #5 {
  %10 = call i32 @cqrt_tape_alloc()
  %11 = call i32 @__cq_mem()
  %12 = call ptr @__cq_alloc(i64 8, i64 8)
  %13 = mul nsw i64 %6, %2
  %14 = ptrtoint ptr %12 to i64
  %15 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %11, i64 %14, i32 %15)
  %16 = icmp slt i64 %13, %5
  %17 = call i32 @cqrt_alloc_i64(i64 0)
  br i1 %16, label %18, label %30

18:                                               ; preds = %9
  %19 = sub nsw i64 %5, %13
  %20 = add nsw i64 %13, 1
  %21 = shl i64 %20, 3
  %22 = ptrtoint ptr %12 to i64
  %23 = call i32 @cqrt_alloc_i64(i64 %22)
  %24 = call i32 @cqrt_alloc_i64(i64 %21)
  %25 = call i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t(i32 %23, i32 %24, i32 4)
  %26 = mul i64 %13, 8
  %27 = call i32 @cq_template_add_i64_hl(i32 %25, i64 %26)
  %28 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64(i32 %11, i32 %27, i32 %28)
  call void @cq_template_add_i64_hl_unc(i32 %27, i32 %25, i64 %26)
  call void @cqrt_free(i32 %27)
  %29 = icmp sgt i64 %19, %13
  br i1 %29, label %85, label %87

30:                                               ; preds = %228, %9
  %31 = phi i32 [ %113, %228 ], [ poison, %9 ]
  %32 = phi i32 [ %112, %228 ], [ poison, %9 ]
  %33 = phi i32 [ %25, %228 ], [ poison, %9 ]
  %34 = phi i32 [ %203, %228 ], [ poison, %9 ]
  %35 = phi i32 [ %207, %228 ], [ poison, %9 ]
  %36 = phi i32 [ %208, %228 ], [ poison, %9 ]
  %37 = phi i32 [ %93, %228 ], [ poison, %9 ]
  %38 = phi i32 [ %95, %228 ], [ poison, %9 ]
  %39 = phi i32 [ %96, %228 ], [ poison, %9 ]
  %40 = phi i32 [ %97, %228 ], [ poison, %9 ]
  %41 = phi i32 [ %98, %228 ], [ poison, %9 ]
  %42 = phi i32 [ %92, %228 ], [ poison, %9 ]
  %43 = phi i32 [ %115, %228 ], [ poison, %9 ]
  %44 = phi i32 [ %131, %228 ], [ poison, %9 ]
  %45 = phi i32 [ %129, %228 ], [ poison, %9 ]
  %46 = phi i32 [ %114, %228 ], [ poison, %9 ]
  %47 = phi i32 [ %127, %228 ], [ poison, %9 ]
  %48 = phi i32 [ %128, %228 ], [ poison, %9 ]
  %49 = phi i32 [ %120, %228 ], [ poison, %9 ]
  %50 = phi i32 [ %90, %228 ], [ poison, %9 ]
  %51 = phi i32 [ %91, %228 ], [ poison, %9 ]
  %52 = phi i64 [ %117, %228 ], [ poison, %9 ]
  %53 = phi i32 [ %25, %228 ], [ poison, %9 ]
  %54 = phi i32 [ %116, %228 ], [ poison, %9 ]
  %55 = phi i32 [ %120, %228 ], [ poison, %9 ]
  %56 = phi i32 [ %119, %228 ], [ poison, %9 ]
  %57 = phi i32 [ %118, %228 ], [ poison, %9 ]
  %58 = phi i32 [ %89, %228 ], [ poison, %9 ]
  %59 = phi i32 [ %99, %228 ], [ poison, %9 ]
  %60 = phi i64 [ %19, %228 ], [ poison, %9 ]
  %61 = phi i32 [ %100, %228 ], [ poison, %9 ]
  %62 = phi i32 [ %101, %228 ], [ poison, %9 ]
  %63 = phi i32 [ %102, %228 ], [ poison, %9 ]
  %64 = phi i32 [ %103, %228 ], [ poison, %9 ]
  %65 = phi i32 [ %104, %228 ], [ poison, %9 ]
  %66 = phi i32 [ %25, %228 ], [ poison, %9 ]
  %67 = phi i32 [ %105, %228 ], [ poison, %9 ]
  %68 = phi i32 [ %106, %228 ], [ poison, %9 ]
  %69 = phi i32 [ %24, %228 ], [ poison, %9 ]
  %70 = phi i32 [ %23, %228 ], [ poison, %9 ]
  %71 = phi i32 [ %25, %228 ], [ poison, %9 ]
  %cq.run122 = phi i1 [ true, %228 ], [ false, %9 ]
  %cq.run102 = phi i1 [ %cq.run103, %228 ], [ false, %9 ]
  %72 = phi i32 [ %107, %228 ], [ poison, %9 ]
  %73 = phi i32 [ %108, %228 ], [ poison, %9 ]
  %74 = phi i32 [ %109, %228 ], [ poison, %9 ]
  %75 = phi i32 [ %110, %228 ], [ poison, %9 ]
  %76 = phi i32 [ %111, %228 ], [ poison, %9 ]
  %ran83 = phi i1 [ %ran88, %228 ], [ false, %9 ]
  %cq.run66 = phi i1 [ true, %228 ], [ false, %9 ]
  %cq.run49 = phi i1 [ %cq.run50, %228 ], [ false, %9 ]
  %cq.run31 = phi i1 [ true, %228 ], [ false, %9 ]
  %cq.run17 = phi i1 [ true, %228 ], [ false, %9 ]
  %77 = phi i32 [ %25, %228 ], [ %17, %9 ]
  %78 = phi i64 [ %5, %9 ], [ %20, %228 ]
  %79 = call i32 @cqrt_alloc_i64(i64 %78)
  %80 = ptrtoint ptr %4 to i64
  %81 = xor i1 %16, true
  %82 = call i32 @cqrt_alloc_i1(i1 %81)
  %83 = call i32 @cq_template_select_i64_lh(i32 %82, i64 %80, i32 %77)
  %84 = icmp sgt i64 %2, 0
  br i1 %84, label %238, label %245

85:                                               ; preds = %18
  %86 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %10, i64 ptrtoint (ptr @.str.27 to i64))
  call void @cqrt_tape_write_i32_lit(i32 %10, i32 747)
  call void @cqrt_tape_write_i64_lit(i32 %10, i64 ptrtoint (ptr @.str.4.30 to i64))
  call void @cqrt_tape_effect_controlled(i32 %86, i32 %10, ptr @.cq.effect.__gmp_assert_fail, i32 3)
  call void @cqrt_abort_i1(i32 %86)
  unreachable

87:                                               ; preds = %18
  %88 = icmp eq i64 %19, 0
  %89 = call i32 @cqrt_alloc_i64(i64 0)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  %92 = call i32 @cqrt_alloc_i64(i64 0)
  %93 = call i32 @cqrt_alloc_i1(i1 true)
  br i1 %88, label %94, label %134

94:                                               ; preds = %180, %87
  %95 = phi i32 [ %142, %180 ], [ poison, %87 ]
  %96 = phi i32 [ %182, %180 ], [ poison, %87 ]
  %97 = phi i32 [ %183, %180 ], [ poison, %87 ]
  %98 = phi i32 [ %154, %180 ], [ poison, %87 ]
  %99 = phi i32 [ %153, %180 ], [ poison, %87 ]
  %100 = phi i32 [ %142, %180 ], [ poison, %87 ]
  %101 = phi i32 [ %181, %180 ], [ poison, %87 ]
  %102 = phi i32 [ %140, %180 ], [ poison, %87 ]
  %103 = phi i32 [ %139, %180 ], [ poison, %87 ]
  %104 = phi i32 [ %137, %180 ], [ poison, %87 ]
  %105 = phi i32 [ %141, %180 ], [ poison, %87 ]
  %106 = phi i32 [ %142, %180 ], [ poison, %87 ]
  %cq.run107 = phi i1 [ true, %180 ], [ false, %87 ]
  %107 = phi i32 [ %144, %180 ], [ poison, %87 ]
  %108 = phi i32 [ %145, %180 ], [ poison, %87 ]
  %109 = phi i32 [ %146, %180 ], [ poison, %87 ]
  %110 = phi i32 [ %147, %180 ], [ poison, %87 ]
  %111 = phi i32 [ %142, %180 ], [ poison, %87 ]
  %ran88 = phi i1 [ true, %180 ], [ false, %87 ]
  %cq.run54 = phi i1 [ true, %180 ], [ false, %87 ]
  %112 = phi i32 [ %182, %180 ], [ %93, %87 ]
  %113 = phi i32 [ %152, %180 ], [ %92, %87 ]
  %114 = phi i32 [ %154, %180 ], [ %91, %87 ]
  %115 = phi i32 [ %142, %180 ], [ %90, %87 ]
  %116 = phi i32 [ %89, %87 ], [ %181, %180 ]
  %117 = ptrtoint ptr %4 to i64
  %118 = call i32 @cq_template_icmp_ne_i64_hl(i32 %25, i64 %117)
  %119 = call i32 @cq_template_icmp_slt_i64_hl(i32 %116, i64 %13)
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %118, i32 %119, i32 %120)
  %121 = call i32 @cq_template_shl_i64_hl(i32 %116, i64 3)
  %122 = call i32 @cq_template_add_i64(i32 %25, i32 %121)
  %123 = call i32 @cq_template_add_i64_hl(i32 %121, i64 %117)
  %124 = mul i64 %6, %2
  %125 = call i32 @cq_template_sub_i64_lh(i64 %124, i32 %116)
  %126 = call i32 @cq_template_shl_i64_hl(i32 %125, i64 3)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %128)
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  %130 = xor i1 %88, true
  %131 = call i32 @cqrt_alloc_i1(i1 %130)
  call void @cqrt_xor_i1(i32 %131, i32 %129)
  call void @cqrt_and_i1(i32 %131, i32 %115, i32 %129)
  call void @cqrt_and_i1(i32 %114, i32 %129, i32 %128)
  call void @cqrt_and_i1(i32 %120, i32 %128, i32 %127)
  %132 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %126, i64 4096)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %132, i32 %127, i32 %133)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %132, i32 %126, i64 4096)
  call void @cqrt_free(i32 %132)
  br label %184

134:                                              ; preds = %87
  %135 = getelementptr inbounds i64, ptr %4, i64 %13
  %136 = ptrtoint ptr %4 to i64
  %137 = call i32 @cqrt_alloc_i64(i64 %136)
  %138 = ptrtoint ptr %135 to i64
  %139 = call i32 @cqrt_alloc_i64(i64 %138)
  %140 = call i32 @cqrt_alloc_i64(i64 %19)
  %141 = call i32 @__cq_q___gmpn_sub_n_1111_t(i32 %25, i32 %137, i32 %139, i32 %140, i32 4)
  %142 = call i32 @cq_template_icmp_eq_i64_hl(i32 %141, i64 0)
  br label %143

143:                                              ; preds = %134
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %144)
  call void @cqrt_xor_i1(i32 %142, i32 %144)
  %145 = call i32 @cqrt_alloc_i64(i64 0)
  %146 = call i32 @cqrt_alloc_i64(i64 0)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  br label %149

148:                                              ; preds = %149
  br label %180

149:                                              ; preds = %ob.30, %143
  %from77 = phi i32 [ 0, %ob.30 ], [ 1, %143 ]
  %150 = phi i64 [ %19, %143 ], [ %161, %ob.30 ]
  %trip = phi i32 [ %144, %143 ], [ %167, %ob.30 ]
  %xcap = phi i32 [ %145, %143 ], [ %171, %ob.30 ]
  %xcap1 = phi i32 [ %146, %143 ], [ %172, %ob.30 ]
  %xcap2 = phi i32 [ %147, %143 ], [ %173, %ob.30 ]
  call void @cqrt_push(i32 %from77)
  %151 = icmp slt i64 %150, %13
  %152 = call i32 @cq_template_select_i64_lh(i32 %trip, i64 1, i32 %xcap)
  %153 = call i32 @cq_template_select_i64_lh(i32 %trip, i64 0, i32 %xcap1)
  %154 = call i32 @cq_template_select_i1_lh(i32 %trip, i1 true, i32 %xcap2)
  call void @cqrt_push(i32 %154)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %153)
  call void @cqrt_push(i32 %xcap1)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %xcap)
  br i1 %151, label %ob.30, label %148

ob.30:                                            ; preds = %149
  %155 = getelementptr inbounds i64, ptr %4, i64 %150
  %156 = ptrtoint ptr %155 to i64
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %157)
  call void @cqrt_xor_i1(i32 %142, i32 %157)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %157, i32 %158)
  %159 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %158, i32 %11, i64 %156)
  %160 = call i32 @cq_template_add_i64_hl(i32 %159, i64 -1)
  %161 = add nsw i64 %150, 1
  %162 = mul i64 %150, 8
  %163 = call i32 @cq_template_add_i64_hl(i32 %25, i64 %162)
  %164 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %164)
  call void @cqrt_xor_i1(i32 %142, i32 %164)
  %165 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %164, i32 %165)
  call void @cqrt_xor_i1(i32 %142, i32 %164)
  call void @cqrt_not_i1(i32 %164)
  call void @cqrt_free(i32 %164)
  call void @cqrt_qram_store_i64_controlled(i32 %165, i32 %11, i32 %163, i32 %160)
  call void @cq_template_add_i64_hl_unc(i32 %163, i32 %25, i64 %162)
  call void @cqrt_free(i32 %163)
  %166 = call i32 @cq_template_icmp_eq_i64_hl(i32 %159, i64 0)
  %167 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %167)
  %168 = call i32 @cqrt_alloc_i1(i1 false)
  %169 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %169)
  call void @cqrt_xor_i1(i32 %142, i32 %169)
  call void @cqrt_xor_i1(i32 %169, i32 %168)
  call void @cqrt_and_i1(i32 %169, i32 %166, i32 %168)
  %170 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %168, i32 %170)
  call void @cqrt_and_i1(i32 %trip, i32 %168, i32 %167)
  %171 = call i32 @cq_template_select_i64_lh(i32 %170, i64 0, i32 %xcap)
  %172 = call i32 @cq_template_select_i64_lh(i32 %170, i64 %161, i32 %xcap1)
  %173 = call i32 @cq_template_select_i1_lh(i32 %170, i1 false, i32 %xcap2)
  call void @cqrt_push(i32 %173)
  call void @cqrt_push(i32 %170)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %172)
  %174 = trunc i64 %161 to i32
  call void @cqrt_push(i32 %174)
  %175 = lshr i64 %161, 32
  %176 = trunc i64 %175 to i32
  call void @cqrt_push(i32 %176)
  call void @cqrt_push(i32 %xcap1)
  call void @cqrt_push(i32 %171)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %168)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %169)
  call void @cqrt_push(i32 %166)
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %158)
  %177 = trunc i64 %156 to i32
  call void @cqrt_push(i32 %177)
  %178 = lshr i64 %156, 32
  %179 = trunc i64 %178 to i32
  call void @cqrt_push(i32 %179)
  call void @cqrt_push(i32 %157)
  br label %149

180:                                              ; preds = %148
  %181 = call i32 @cq_template_select_i64_lh(i32 %142, i64 %19, i32 %153)
  %182 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %182)
  %183 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %183)
  call void @cqrt_xor_i1(i32 %142, i32 %183)
  call void @cqrt_and_i1(i32 %154, i32 %183, i32 %182)
  br label %94

184:                                              ; preds = %184, %94
  %cq.run106 = phi i1 [ %cq.run106, %184 ], [ %cq.run107, %94 ]
  %cq.run53 = phi i1 [ %cq.run53, %184 ], [ %cq.run54, %94 ]
  %185 = phi i64 [ 0, %94 ], [ %190, %184 ]
  %186 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %126, i64 %185)
  %187 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %186, i32 %127, i32 %187)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %186, i32 %126, i64 %185)
  call void @cqrt_free(i32 %186)
  %188 = call i32 @cq_template_add_i64_hl(i32 %123, i64 %185)
  %189 = call i32 @cqrt_qram_load_i8_controlled(i32 %187, i32 %11, i32 %188)
  call void @cq_template_add_i64_hl_unc(i32 %188, i32 %123, i64 %185)
  call void @cqrt_free(i32 %188)
  call void @cqrt_push(i32 %187)
  call void @cqrt_push(i32 %189)
  %190 = add nuw i64 %185, 1
  %191 = icmp eq i64 %190, 4096
  br i1 %191, label %192, label %184

192:                                              ; preds = %184
  call void @cq_template_shl_i64_hl_unc(i32 %126, i32 %125, i64 3)
  call void @cqrt_free(i32 %126)
  call void @cq_template_sub_i64_lh_unc(i32 %125, i64 %124, i32 %116)
  call void @cqrt_free(i32 %125)
  call void @cq_template_add_i64_hl_unc(i32 %123, i32 %121, i64 %117)
  call void @cqrt_free(i32 %123)
  br label %193

193:                                              ; preds = %192
  br label %194

194:                                              ; preds = %194, %193
  %cq.run105 = phi i1 [ %cq.run105, %194 ], [ %cq.run106, %193 ]
  %cq.run52 = phi i1 [ %cq.run52, %194 ], [ %cq.run53, %193 ]
  %195 = phi i64 [ 4095, %193 ], [ %199, %194 ]
  %196 = call i32 @cqrt_pop()
  %197 = call i32 @cqrt_pop()
  %198 = call i32 @cq_template_add_i64_hl(i32 %122, i64 %195)
  call void @cqrt_qram_store_i8_controlled(i32 %197, i32 %11, i32 %198, i32 %196)
  call void @cq_template_add_i64_hl_unc(i32 %198, i32 %122, i64 %195)
  call void @cqrt_free(i32 %198)
  %199 = add nsw i64 %195, -1
  %200 = icmp eq i64 %195, 0
  br i1 %200, label %201, label %194

201:                                              ; preds = %194
  call void @cq_template_add_i64_unc(i32 %122, i32 %25, i32 %121)
  call void @cqrt_free(i32 %122)
  call void @cq_template_shl_i64_hl_unc(i32 %121, i32 %116, i64 3)
  call void @cqrt_free(i32 %121)
  br label %202

202:                                              ; preds = %201
  %203 = call i32 @cq_template_select_i64_lh(i32 %112, i64 0, i32 %113)
  %204 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64(i32 %11, i32 %25, i32 %204)
  %205 = call i32 @cq_template_add_i64(i32 %204, i32 %203)
  %206 = call i32 @cq_template_sub_i64(i32 %205, i32 %203)
  call void @cqrt_copy_i64(i32 %206, i32 %204)
  call void @cq_template_sub_i64_unc(i32 %206, i32 %205, i32 %203)
  call void @cqrt_free(i32 %206)
  call void @cqrt_free(i32 %204)
  call void @cqrt_qram_swap_i64(i32 %11, i32 %25, i32 %205)
  call void @cqrt_free(i32 %205)
  %207 = call i32 @cqrt_qram_load_i64(i32 %11, i32 %25)
  %208 = call i32 @cq_template_icmp_ult_i64(i32 %207, i32 %203)
  br label %209

209:                                              ; preds = %202
  br label %210

210:                                              ; preds = %210, %209
  %cq.run104 = phi i1 [ %cq.run104, %210 ], [ %cq.run105, %209 ]
  %cq.run51 = phi i1 [ %cq.run51, %210 ], [ %cq.run52, %209 ]
  %from = phi i32 [ 0, %210 ], [ 1, %209 ]
  %211 = phi i32 [ 0, %209 ], [ %224, %210 ]
  %212 = phi i32 [ %208, %209 ], [ %222, %210 ]
  %213 = phi i32 [ %25, %209 ], [ %223, %210 ]
  call void @cqrt_push(i32 %from)
  %214 = call i32 @cq_template_add_i64_hl(i32 %213, i64 8)
  %215 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %212, i32 %11, i32 %214, i32 %215)
  %216 = call i32 @cq_template_add_i64_hl(i32 %215, i64 1)
  %217 = call i32 @cq_template_select_i64(i32 %212, i32 %216, i32 %215)
  call void @cq_template_add_i64_hl_unc(i32 %216, i32 %215, i64 1)
  call void @cqrt_free(i32 %216)
  %218 = call i32 @cq_template_sub_i64_hl(i32 %217, i64 1)
  %219 = call i32 @cq_template_select_i64(i32 %212, i32 %218, i32 %217)
  call void @cqrt_copy_i64(i32 %219, i32 %215)
  call void @cq_template_select_i64_unc(i32 %219, i32 %212, i32 %218, i32 %217)
  call void @cqrt_free(i32 %219)
  call void @cq_template_sub_i64_hl_unc(i32 %218, i32 %217, i64 1)
  call void @cqrt_free(i32 %218)
  call void @cqrt_free(i32 %215)
  call void @cqrt_qram_swap_i64_controlled(i32 %212, i32 %11, i32 %214, i32 %217)
  call void @cqrt_free(i32 %217)
  %220 = call i32 @cqrt_qram_load_i64_controlled(i32 %212, i32 %11, i32 %214)
  %221 = call i32 @cq_template_icmp_eq_i64_hl(i32 %220, i64 0)
  %222 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %212, i32 %221, i32 %222)
  %223 = call i32 @cq_template_select_i64(i32 %212, i32 %214, i32 %213)
  %224 = add i32 %211, 1
  %225 = icmp ult i32 %224, 4
  call void @cqrt_push(i32 %223)
  call void @cqrt_push(i32 %212)
  call void @cqrt_push(i32 %214)
  call void @cqrt_push(i32 %213)
  call void @cqrt_push(i32 %221)
  call void @cqrt_push(i32 %222)
  call void @cqrt_push(i32 %220)
  br i1 %225, label %210, label %226

226:                                              ; preds = %210
  %227 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %222, i32 %227)
  br label %229

228:                                              ; preds = %229
  br label %30

229:                                              ; preds = %226, %229
  %cq.run103 = phi i1 [ %cq.run104, %226 ], [ %cq.run103, %229 ]
  %cq.run50 = phi i1 [ %cq.run51, %226 ], [ %cq.run50, %229 ]
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = call i32 @cqrt_pop()
  %233 = call i32 @cqrt_pop()
  %234 = call i32 @cqrt_pop()
  %235 = call i32 @cqrt_pop()
  %236 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %236, i32 %235, i32 %234, i32 %233)
  call void @cqrt_free(i32 %236)
  call void @cqrt_and_i1(i32 %235, i32 %232, i32 %231)
  call void @cqrt_free(i32 %231)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %232, i32 %230, i64 0)
  call void @cqrt_free(i32 %232)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %230, i32 %235, i32 %11, i32 %234)
  call void @cq_template_add_i64_hl_unc(i32 %234, i32 %233, i64 8)
  call void @cqrt_free(i32 %234)
  %237 = call i32 @cqrt_pop()
  switch i32 %237, label %229 [
    i32 1, label %228
  ]

238:                                              ; preds = %30
  %239 = icmp eq i64 %3, -1
  %240 = add nsw i64 %2, -1
  %241 = add nsw i64 %3, 1
  %242 = add i64 %3, 1
  %243 = shl i64 %3, 3
  %244 = add i64 %243, 8
  br label %254

245:                                              ; preds = %30, %371
  %cq.run121 = phi i1 [ %cq.run122, %30 ], [ %cq.run129, %371 ]
  %cq.run101 = phi i1 [ %cq.run102, %30 ], [ %cq.run109, %371 ]
  %cq.run65 = phi i1 [ %cq.run66, %30 ], [ %cq.run71, %371 ]
  %cq.run48 = phi i1 [ %cq.run49, %30 ], [ %cq.run55, %371 ]
  %cq.run30 = phi i1 [ %cq.run31, %30 ], [ %cq.run38, %371 ]
  %cq.run16 = phi i1 [ %cq.run17, %30 ], [ %cq.run20, %371 ]
  %246 = phi i64 [ poison, %30 ], [ %241, %371 ]
  %ran = phi i1 [ false, %30 ], [ true, %371 ]
  %247 = phi i32 [ %79, %30 ], [ %360, %371 ]
  %248 = call i32 @cq_template_icmp_eq_i64_hl(i32 %247, i64 0)
  %249 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %249)
  call void @cqrt_xor_i1(i32 %248, i32 %249)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %248, i32 %247, i64 0)
  call void @cqrt_free(i32 %248)
  br i1 %ran, label %431, label %460

250:                                              ; preds = %460
  call void @cq_template_select_i64_lh_unc(i32 %83, i32 %82, i64 %80, i32 %77)
  call void @cqrt_free(i32 %83)
  call void @cqrt_free(i32 %82)
  call void @cqrt_free(i32 %17)
  call void @cqrt_free(i32 %79)
  br i1 %cq.run, label %.cq.arm154, label %.cq.after153

.cq.arm154:                                       ; preds = %250
  call void @cq_template_icmp_ult_i64_unc(i32 %36, i32 %35, i32 %34)
  call void @cqrt_free(i32 %36)
  call void @cqrt_qram_load_i64_unc(i32 %35, i32 %11, i32 %33)
  call void @cq_template_select_i64_lh_unc(i32 %34, i32 %32, i64 0, i32 %31)
  call void @cqrt_free(i32 %34)
  br label %.cq.after153

.cq.after153:                                     ; preds = %250, %.cq.arm154
  br i1 %cq.run26, label %.cq.arm152, label %.cq.after151

.cq.arm152:                                       ; preds = %.cq.after153
  call void @cqrt_free(i32 %37)
  br label %.cq.after151

.cq.after151:                                     ; preds = %.cq.after153, %.cq.arm152
  br i1 %cq.run44, label %.cq.arm150, label %.cq.after149

.cq.arm150:                                       ; preds = %.cq.after151
  call void @cqrt_and_i1(i32 %41, i32 %40, i32 %39)
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_free(i32 %39)
  call void @cqrt_xor_i1(i32 %38, i32 %40)
  call void @cqrt_not_i1(i32 %40)
  call void @cqrt_free(i32 %40)
  br label %.cq.after149

.cq.after149:                                     ; preds = %.cq.after151, %.cq.arm150
  br i1 %cq.run26, label %.cq.arm148, label %.cq.after147

.cq.arm148:                                       ; preds = %.cq.after149
  call void @cqrt_free(i32 %42)
  br label %.cq.after147

.cq.after147:                                     ; preds = %.cq.after149, %.cq.arm148
  br i1 %cq.run61, label %.cq.arm146, label %.cq.after145

.cq.arm146:                                       ; preds = %.cq.after147
  call void @cqrt_and_i1(i32 %49, i32 %48, i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cqrt_and_i1(i32 %46, i32 %45, i32 %48)
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_free(i32 %48)
  call void @cqrt_and_i1(i32 %44, i32 %43, i32 %45)
  call void @cqrt_xor_i1(i32 %44, i32 %45)
  call void @cqrt_free(i32 %45)
  call void @cqrt_free(i32 %44)
  br label %.cq.after145

.cq.after145:                                     ; preds = %.cq.after147, %.cq.arm146
  br i1 %cq.run26, label %.cq.arm144, label %.cq.after143

.cq.arm144:                                       ; preds = %.cq.after145
  call void @cqrt_free(i32 %51)
  call void @cqrt_free(i32 %50)
  br label %.cq.after143

.cq.after143:                                     ; preds = %.cq.after145, %.cq.arm144
  br i1 %cq.run61, label %.cq.arm142, label %.cq.after141

.cq.arm142:                                       ; preds = %.cq.after143
  call void @cqrt_and_i1(i32 %57, i32 %56, i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %56, i32 %54, i64 %13)
  call void @cqrt_free(i32 %56)
  call void @cq_template_icmp_ne_i64_hl_unc(i32 %57, i32 %53, i64 %52)
  call void @cqrt_free(i32 %57)
  br label %.cq.after141

.cq.after141:                                     ; preds = %.cq.after143, %.cq.arm142
  br i1 %cq.run26, label %.cq.arm140, label %.cq.after139

.cq.arm140:                                       ; preds = %.cq.after141
  call void @cqrt_free(i32 %58)
  br label %.cq.after139

.cq.after139:                                     ; preds = %.cq.after141, %.cq.arm140
  br i1 %cq.run44, label %.cq.arm138, label %.cq.after137

.cq.arm138:                                       ; preds = %.cq.after139
  call void @cq_template_select_i64_lh_unc(i32 %62, i32 %61, i64 %60, i32 %59)
  call void @cqrt_free(i32 %62)
  br label %.cq.after137

.cq.after137:                                     ; preds = %.cq.after139, %.cq.arm138
  br i1 %ran83, label %462, label %501

251:                                              ; preds = %501
  br i1 %cq.run95, label %.cq.arm136, label %.cq.after135

.cq.arm136:                                       ; preds = %251
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %68, i32 %67, i64 0)
  call void @cqrt_free(i32 %68)
  call void @__cq_q___gmpn_sub_n_1111_t_unc(i32 %67, i32 %66, i32 %65, i32 %64, i32 %63, i32 4)
  call void @cqrt_free(i32 %63)
  call void @cqrt_free(i32 %64)
  call void @cqrt_free(i32 %65)
  br label %.cq.after135

.cq.after135:                                     ; preds = %251, %.cq.arm136
  br i1 %cq.run115, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %.cq.after135
  call void @__cq_q___gmp_tmp_reentrant_alloc_11_t_unc(i32 %71, i32 %70, i32 %69, i32 4)
  call void @cqrt_free(i32 %69)
  call void @cqrt_free(i32 %70)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after135, %.cq.arm
  call void @cqrt_abort_i1(i32 %249)
  %252 = ptrtoint ptr %12 to i64
  %253 = call i32 @cqrt_qram_load_i64_hl(i32 %11, i64 %252)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t(i32 %253, i32 4)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_unc(i32 %253, i32 4)
  call void @cqrt_qram_load_i64_hl_unc(i32 %253, i32 %11, i64 %252)
  ret void

254:                                              ; preds = %238
  br label %256

255:                                              ; preds = %350
  br label %371

256:                                              ; preds = %350, %254
  %cq.run132 = phi i1 [ %cq.run129, %350 ], [ %cq.run122, %254 ]
  %cq.run112 = phi i1 [ %cq.run109, %350 ], [ %cq.run102, %254 ]
  %cq.run74 = phi i1 [ %cq.run71, %350 ], [ %cq.run66, %254 ]
  %cq.run58 = phi i1 [ %cq.run55, %350 ], [ %cq.run49, %254 ]
  %cq.run41 = phi i1 [ %cq.run38, %350 ], [ %cq.run31, %254 ]
  %cq.run23 = phi i1 [ %cq.run20, %350 ], [ %cq.run17, %254 ]
  %from5 = phi i32 [ 0, %350 ], [ 1, %254 ]
  %257 = phi ptr [ %0, %254 ], [ %362, %350 ]
  %258 = phi i32 [ %83, %254 ], [ %361, %350 ]
  %259 = phi i32 [ %79, %254 ], [ %360, %350 ]
  %260 = phi i64 [ 0, %254 ], [ %363, %350 ]
  call void @cqrt_push(i32 %from5)
  %261 = getelementptr inbounds ptr, ptr %1, i64 %260
  %262 = ptrtoint ptr %261 to i64
  %263 = ptrtoint ptr %257 to i64
  %264 = call i32 @cqrt_alloc_i64(i64 %263)
  call void @cqrt_qram_store_i64_hl(i32 %11, i64 %262, i32 %264)
  %265 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %259, i64 0)
  call void @cqrt_push(i32 %265)
  call void @cqrt_push(i32 %259)
  br i1 %239, label %cq.rejoinR, label %ob.112

ob.113:                                           ; No predecessors!

ob.112:                                           ; preds = %256
  %266 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %266)
  call void @cqrt_xor_i1(i32 %265, i32 %266)
  %267 = ptrtoint ptr %257 to i64
  %268 = call i32 @cqrt_alloc_i8(i8 0)
  %269 = icmp eq i64 %244, 0
  br i1 %269, label %277, label %270

270:                                              ; preds = %270, %ob.112
  %cq.run134 = phi i1 [ %cq.run134, %270 ], [ %cq.run132, %ob.112 ]
  %cq.run114 = phi i1 [ %cq.run114, %270 ], [ %cq.run112, %ob.112 ]
  %cq.run76 = phi i1 [ %cq.run76, %270 ], [ %cq.run74, %ob.112 ]
  %cq.run60 = phi i1 [ %cq.run60, %270 ], [ %cq.run58, %ob.112 ]
  %cq.run43 = phi i1 [ %cq.run43, %270 ], [ %cq.run41, %ob.112 ]
  %cq.run25 = phi i1 [ %cq.run25, %270 ], [ %cq.run23, %ob.112 ]
  %271 = phi i64 [ 0, %ob.112 ], [ %275, %270 ]
  %272 = add i64 %267, %271
  call void @cqrt_not_i1(i32 %265)
  %273 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %268, i32 %273)
  %274 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %265, i32 %274)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %274, i32 %11, i64 %272, i32 %273)
  call void @cqrt_not_i1(i32 %265)
  %275 = add nuw i64 %271, 1
  %276 = icmp eq i64 %275, %244
  br i1 %276, label %277, label %270

277:                                              ; preds = %270, %ob.112
  %cq.run133 = phi i1 [ %cq.run134, %270 ], [ %cq.run132, %ob.112 ]
  %cq.run113 = phi i1 [ %cq.run114, %270 ], [ %cq.run112, %ob.112 ]
  %cq.run75 = phi i1 [ %cq.run76, %270 ], [ %cq.run74, %ob.112 ]
  %cq.run59 = phi i1 [ %cq.run60, %270 ], [ %cq.run58, %ob.112 ]
  %cq.run42 = phi i1 [ %cq.run43, %270 ], [ %cq.run41, %ob.112 ]
  %cq.run24 = phi i1 [ %cq.run25, %270 ], [ %cq.run23, %ob.112 ]
  call void @cqrt_push(i32 %268)
  call void @cqrt_push(i32 %265)
  call void @cqrt_push(i32 %266)
  br label %cq.rejoinR

cq.rejoinR:                                       ; preds = %256, %277
  %cq.run131 = phi i1 [ %cq.run132, %256 ], [ %cq.run133, %277 ]
  %cq.run111 = phi i1 [ %cq.run112, %256 ], [ %cq.run113, %277 ]
  %cq.run73 = phi i1 [ %cq.run74, %256 ], [ %cq.run75, %277 ]
  %cq.run57 = phi i1 [ %cq.run58, %256 ], [ %cq.run59, %277 ]
  %cq.run40 = phi i1 [ %cq.run41, %256 ], [ %cq.run42, %277 ]
  %cq.run22 = phi i1 [ %cq.run23, %256 ], [ %cq.run24, %277 ]
  %from4 = phi i32 [ 0, %256 ], [ 1, %277 ]
  call void @cqrt_push(i32 %from4)
  %278 = call i32 @cq_template_icmp_sge_i64_hl(i32 %259, i64 %6)
  %279 = icmp slt i64 %260, %240
  %280 = call i32 @cq_template_select_i1_ll(i32 %278, i1 %279, i1 false)
  %281 = call i32 @cq_template_select_i64_lh(i32 %280, i64 %6, i32 %259)
  %282 = call i32 @cq_template_sub_i64(i32 %259, i32 %281)
  %283 = call i32 @cq_template_icmp_eq_i64_hl(i32 %281, i64 0)
  %284 = call i32 @cq_template_add_i64_hl(i32 %281, i64 -1)
  %285 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %265, i32 %285)
  call void @cqrt_and_i1(i32 %265, i32 %283, i32 %285)
  %286 = call i32 @cqrt_qram_load_i64_controlled(i32 %285, i32 %11, i32 %258)
  %287 = call i32 @cq_template_icmp_eq_i64_hl(i32 %284, i64 0)
  %288 = call i32 @cqrt_alloc_i1(i1 false)
  %289 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %265, i32 %289)
  call void @cqrt_and_i1(i32 %265, i32 %283, i32 %289)
  call void @cqrt_xor_i1(i32 %289, i32 %288)
  call void @cqrt_and_i1(i32 %289, i32 %287, i32 %288)
  %290 = ptrtoint ptr %8 to i64
  %291 = call i32 @cqrt_alloc_i64(i64 %290)
  call void @cqrt_push(i32 %291)
  call void @cqrt_push(i32 %289)
  call void @cqrt_push(i32 %287)
  call void @cqrt_push(i32 %288)
  call void @cqrt_push(i32 %265)
  call void @cqrt_push(i32 %283)
  call void @cqrt_push(i32 %284)
  call void @cqrt_push(i32 %286)
  call void @cqrt_push(i32 %285)
  call void @cqrt_push(i32 %258)
  call void @cqrt_push(i32 %281)
  call void @cqrt_push(i32 %282)
  call void @cqrt_push(i32 %259)
  call void @cqrt_push(i32 %280)
  call void @cqrt_push(i32 %278)
  %292 = zext i1 %279 to i32
  call void @cqrt_push(i32 %292)
  br label %293

293:                                              ; preds = %293, %cq.rejoinR
  %cq.run130 = phi i1 [ %cq.run130, %293 ], [ %cq.run131, %cq.rejoinR ]
  %cq.run110 = phi i1 [ %cq.run110, %293 ], [ %cq.run111, %cq.rejoinR ]
  %cq.run72 = phi i1 [ %cq.run72, %293 ], [ %cq.run73, %cq.rejoinR ]
  %cq.run56 = phi i1 [ %cq.run56, %293 ], [ %cq.run57, %cq.rejoinR ]
  %cq.run39 = phi i1 [ %cq.run39, %293 ], [ %cq.run40, %cq.rejoinR ]
  %cq.run21 = phi i1 [ %cq.run21, %293 ], [ %cq.run22, %cq.rejoinR ]
  %from3 = phi i32 [ 0, %293 ], [ 1, %cq.rejoinR ]
  %294 = phi i32 [ 0, %cq.rejoinR ], [ %323, %293 ]
  %295 = phi i32 [ %288, %cq.rejoinR ], [ %318, %293 ]
  %296 = phi i32 [ %284, %cq.rejoinR ], [ %320, %293 ]
  %297 = phi ptr [ %8, %cq.rejoinR ], [ %304, %293 ]
  %298 = phi i32 [ %258, %cq.rejoinR ], [ %321, %293 ]
  %299 = phi i32 [ %286, %cq.rejoinR ], [ %322, %293 ]
  %300 = phi i64 [ 0, %cq.rejoinR ], [ %319, %293 ]
  %301 = phi i32 [ %291, %cq.rejoinR ], [ %314, %293 ]
  %302 = phi i32 [ %286, %cq.rejoinR ], [ %316, %293 ]
  call void @cqrt_push(i32 %from3)
  %303 = call i32 @cq_template_add_i64_hl(i32 %298, i64 8)
  %304 = getelementptr i8, ptr %297, i64 8
  %305 = ptrtoint ptr %297 to i64
  %306 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %299, i32 %306)
  %307 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %295, i32 %307)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %307, i32 %11, i64 %305, i32 %306)
  %308 = call i32 @cqrt_qram_load_i64_controlled(i32 %295, i32 %11, i32 %303)
  %309 = call i32 @cq_template_add_i64_hl(i32 %296, i64 -1)
  %310 = call i32 @cq_template_icmp_eq_i64_hl(i32 %309, i64 0)
  %311 = ptrtoint ptr %304 to i64
  %312 = call i32 @cqrt_alloc_i64(i64 %311)
  %313 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %295, i32 %310, i32 %313)
  %314 = call i32 @cq_template_select_i64(i32 %313, i32 %312, i32 %301)
  %315 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %295, i32 %310, i32 %315)
  %316 = call i32 @cq_template_select_i64(i32 %315, i32 %308, i32 %302)
  %317 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %317)
  call void @cqrt_xor_i1(i32 %310, i32 %317)
  %318 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %295, i32 %317, i32 %318)
  %319 = add i64 %300, -1
  %320 = call i32 @cq_template_add_i64_hl(i32 %284, i64 %319)
  %321 = call i32 @cq_template_select_i64(i32 %295, i32 %303, i32 %298)
  %322 = call i32 @cq_template_select_i64(i32 %295, i32 %308, i32 %299)
  %323 = add i32 %294, 1
  %324 = icmp ult i32 %323, 4
  call void @cqrt_push(i32 %322)
  call void @cqrt_push(i32 %295)
  call void @cqrt_push(i32 %308)
  call void @cqrt_push(i32 %299)
  call void @cqrt_push(i32 %321)
  call void @cqrt_push(i32 %303)
  call void @cqrt_push(i32 %298)
  call void @cqrt_push(i32 %320)
  call void @cqrt_push(i32 %284)
  %325 = trunc i64 %319 to i32
  call void @cqrt_push(i32 %325)
  %326 = lshr i64 %319, 32
  %327 = trunc i64 %326 to i32
  call void @cqrt_push(i32 %327)
  call void @cqrt_push(i32 %317)
  call void @cqrt_push(i32 %318)
  call void @cqrt_push(i32 %310)
  call void @cqrt_push(i32 %316)
  call void @cqrt_push(i32 %315)
  call void @cqrt_push(i32 %302)
  call void @cqrt_push(i32 %314)
  call void @cqrt_push(i32 %313)
  call void @cqrt_push(i32 %312)
  call void @cqrt_push(i32 %301)
  call void @cqrt_push(i32 %309)
  call void @cqrt_push(i32 %296)
  br i1 %324, label %293, label %328

328:                                              ; preds = %293
  %329 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %318, i32 %329)
  %330 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %316, i32 %330)
  %331 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %265, i32 %331)
  call void @cqrt_and_i1(i32 %265, i32 %283, i32 %331)
  call void @cqrt_qram_store_i64_controlled(i32 %331, i32 %11, i32 %314, i32 %330)
  %332 = call i32 @cq_template_icmp_eq_i64_hl(i32 %281, i64 %241)
  %333 = call i32 @cq_template_sub_i64_lh(i64 %241, i32 %281)
  %334 = ptrtoint ptr %8 to i64
  %335 = call i32 @cq_template_mul_i64_hl(i32 %281, i64 8)
  %336 = call i32 @cq_template_add_i64_hl(i32 %335, i64 %334)
  %337 = call i32 @cq_template_shl_i64_hl(i32 %333, i64 3)
  %338 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %265, i32 %338)
  call void @cqrt_and_i1(i32 %265, i32 %332, i32 %338)
  %339 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %337, i64 4096)
  %340 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %339, i32 %338, i32 %340)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %339, i32 %337, i64 4096)
  call void @cqrt_free(i32 %339)
  %341 = call i32 @cqrt_alloc_i8(i8 0)
  br label %342

342:                                              ; preds = %342, %328
  %cq.run129 = phi i1 [ %cq.run129, %342 ], [ %cq.run130, %328 ]
  %cq.run109 = phi i1 [ %cq.run109, %342 ], [ %cq.run110, %328 ]
  %cq.run71 = phi i1 [ %cq.run71, %342 ], [ %cq.run72, %328 ]
  %cq.run55 = phi i1 [ %cq.run55, %342 ], [ %cq.run56, %328 ]
  %cq.run38 = phi i1 [ %cq.run38, %342 ], [ %cq.run39, %328 ]
  %cq.run20 = phi i1 [ %cq.run20, %342 ], [ %cq.run21, %328 ]
  %343 = phi i64 [ 0, %328 ], [ %347, %342 ]
  %344 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %337, i64 %343)
  %345 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %344, i32 %338, i32 %345)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %344, i32 %337, i64 %343)
  call void @cqrt_free(i32 %344)
  %346 = call i32 @cq_template_add_i64_hl(i32 %336, i64 %343)
  call void @cqrt_qram_store_i8_controlled(i32 %345, i32 %11, i32 %346, i32 %341)
  call void @cq_template_add_i64_hl_unc(i32 %346, i32 %336, i64 %343)
  call void @cqrt_free(i32 %346)
  %347 = add nuw i64 %343, 1
  %348 = icmp eq i64 %347, 4096
  br i1 %348, label %349, label %342

349:                                              ; preds = %342
  br label %350

350:                                              ; preds = %349
  %351 = mul i64 %6, 8
  %352 = call i32 @cq_template_add_i64_hl(i32 %258, i64 %351)
  %353 = mul nsw i64 %260, %7
  %354 = ptrtoint ptr %257 to i64
  %355 = call i32 @cqrt_alloc_i64(i64 %354)
  %356 = ptrtoint ptr %8 to i64
  %357 = call i32 @cqrt_alloc_i64(i64 %356)
  %358 = call i32 @cqrt_alloc_i64(i64 %353)
  %359 = call i32 @cqrt_alloc_i64(i64 %3)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl(i32 %265, i32 %355, i32 %357, i32 %358, i32 %359, i32 4)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl_unc(i32 %265, i32 %355, i32 %357, i32 %358, i32 %359, i32 4)
  call void @cqrt_free(i32 %359)
  call void @cqrt_free(i32 %358)
  call void @cqrt_free(i32 %357)
  call void @cqrt_free(i32 %355)
  %360 = call i32 @cq_template_select_i64(i32 %265, i32 %282, i32 %259)
  %361 = call i32 @cq_template_select_i64(i32 %265, i32 %352, i32 %258)
  %362 = getelementptr i64, ptr %257, i64 %242
  %363 = add nuw nsw i64 %260, 1
  %364 = icmp eq i64 %363, %2
  call void @cqrt_push(i32 %361)
  call void @cqrt_push(i32 %265)
  call void @cqrt_push(i32 %352)
  call void @cqrt_push(i32 %258)
  call void @cqrt_push(i32 %360)
  call void @cqrt_push(i32 %282)
  call void @cqrt_push(i32 %259)
  %365 = trunc i64 %351 to i32
  call void @cqrt_push(i32 %365)
  %366 = lshr i64 %351, 32
  %367 = trunc i64 %366 to i32
  call void @cqrt_push(i32 %367)
  call void @cqrt_push(i32 %332)
  call void @cqrt_push(i32 %338)
  call void @cqrt_push(i32 %337)
  call void @cqrt_push(i32 %333)
  call void @cqrt_push(i32 %336)
  call void @cqrt_push(i32 %335)
  %368 = trunc i64 %334 to i32
  call void @cqrt_push(i32 %368)
  %369 = lshr i64 %334, 32
  %370 = trunc i64 %369 to i32
  call void @cqrt_push(i32 %370)
  call void @cqrt_push(i32 %281)
  br i1 %364, label %255, label %256

371:                                              ; preds = %255
  br label %245

372:                                              ; preds = %373
  br label %460

373:                                              ; preds = %377, %381
  %cq.run118 = phi i1 [ %cq.run119, %377 ], [ %cq.run119, %381 ]
  %cq.run98 = phi i1 [ %cq.run99, %377 ], [ %cq.run99, %381 ]
  %cq.run62 = phi i1 [ %cq.run63, %377 ], [ %cq.run63, %381 ]
  %cq.run45 = phi i1 [ %cq.run46, %377 ], [ %cq.run46, %381 ]
  %cq.run27 = phi i1 [ %cq.run28, %377 ], [ %cq.run28, %381 ]
  %cq.run13 = phi i1 [ %cq.run14, %377 ], [ %cq.run14, %381 ]
  %374 = call i32 @cqrt_pop()
  %375 = call i32 @cqrt_pop()
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %375, i32 %374, i64 0)
  call void @cqrt_free(i32 %375)
  %376 = call i32 @cqrt_pop()
  switch i32 %376, label %431 [
    i32 1, label %372
  ]

377:                                              ; preds = %381
  %378 = call i32 @cqrt_pop()
  %379 = call i32 @cqrt_pop()
  %380 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %380)
  call void @cqrt_xor_i1(i32 %379, i32 %378)
  call void @cqrt_not_i1(i32 %378)
  call void @cqrt_free(i32 %378)
  br label %373

381:                                              ; preds = %401
  %382 = call i32 @cqrt_pop()
  %383 = or i32 0, %382
  %384 = trunc i32 %383 to i1
  %385 = call i32 @cqrt_pop()
  %386 = call i32 @cqrt_pop()
  %387 = call i32 @cqrt_pop()
  %388 = call i32 @cqrt_pop()
  %389 = call i32 @cqrt_pop()
  %390 = call i32 @cqrt_pop()
  %391 = call i32 @cqrt_pop()
  %392 = call i32 @cqrt_pop()
  %393 = call i32 @cqrt_pop()
  %394 = call i32 @cqrt_pop()
  %395 = call i32 @cqrt_pop()
  %396 = call i32 @cqrt_pop()
  %397 = call i32 @cqrt_pop()
  %398 = call i32 @cqrt_pop()
  %399 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %399)
  call void @cqrt_and_i1(i32 %398, i32 %397, i32 %396)
  call void @cqrt_xor_i1(i32 %398, i32 %396)
  call void @cqrt_free(i32 %396)
  call void @cqrt_and_i1(i32 %395, i32 %394, i32 %398)
  call void @cqrt_xor_i1(i32 %395, i32 %398)
  call void @cqrt_free(i32 %398)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %397, i32 %393, i64 0)
  call void @cqrt_free(i32 %397)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %392, i32 %391, i32 %11, i32 %390)
  call void @cqrt_and_i1(i32 %395, i32 %394, i32 %391)
  call void @cqrt_xor_i1(i32 %395, i32 %391)
  call void @cqrt_free(i32 %391)
  call void @cq_template_add_i64_hl_unc(i32 %393, i32 %389, i64 -1)
  call void @cqrt_free(i32 %393)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %394, i32 %389, i64 0)
  call void @cqrt_free(i32 %394)
  call void @cq_template_sub_i64_unc(i32 %388, i32 %387, i32 %389)
  call void @cqrt_free(i32 %388)
  call void @cq_template_select_i64_lh_unc(i32 %389, i32 %386, i64 %6, i32 %387)
  call void @cqrt_free(i32 %389)
  call void @cq_template_select_i1_ll_unc(i32 %386, i32 %385, i1 %384, i1 false)
  call void @cqrt_free(i32 %386)
  call void @cq_template_icmp_sge_i64_hl_unc(i32 %385, i32 %387, i64 %6)
  call void @cqrt_free(i32 %385)
  %400 = call i32 @cqrt_pop()
  switch i32 %400, label %373 [
    i32 1, label %377
  ]

401:                                              ; preds = %401, %431
  %cq.run119 = phi i1 [ %cq.run119, %401 ], [ %cq.run120, %431 ]
  %cq.run99 = phi i1 [ %cq.run99, %401 ], [ %cq.run100, %431 ]
  %cq.run63 = phi i1 [ %cq.run63, %401 ], [ %cq.run64, %431 ]
  %cq.run46 = phi i1 [ %cq.run46, %401 ], [ %cq.run47, %431 ]
  %cq.run28 = phi i1 [ %cq.run28, %401 ], [ %cq.run29, %431 ]
  %cq.run14 = phi i1 [ %cq.run14, %401 ], [ %cq.run15, %431 ]
  %402 = call i32 @cqrt_pop()
  %403 = call i32 @cqrt_pop()
  %404 = call i32 @cqrt_pop()
  %405 = call i32 @cqrt_pop()
  %406 = call i32 @cqrt_pop()
  %407 = call i32 @cqrt_pop()
  %408 = call i32 @cqrt_pop()
  %409 = call i32 @cqrt_pop()
  %410 = call i32 @cqrt_pop()
  %411 = call i32 @cqrt_pop()
  %412 = call i32 @cqrt_pop()
  %413 = call i32 @cqrt_pop()
  %414 = call i32 @cqrt_pop()
  %415 = zext i32 %414 to i64
  %416 = shl i64 %415, 32
  %417 = or i64 0, %416
  %418 = call i32 @cqrt_pop()
  %419 = zext i32 %418 to i64
  %420 = or i64 %417, %419
  %421 = call i32 @cqrt_pop()
  %422 = call i32 @cqrt_pop()
  %423 = call i32 @cqrt_pop()
  %424 = call i32 @cqrt_pop()
  %425 = call i32 @cqrt_pop()
  %426 = call i32 @cqrt_pop()
  %427 = call i32 @cqrt_pop()
  %428 = call i32 @cqrt_pop()
  %429 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %429, i32 %428, i32 %427, i32 %426)
  call void @cqrt_free(i32 %429)
  call void @cq_template_select_i64_unc(i32 %425, i32 %428, i32 %424, i32 %423)
  call void @cqrt_free(i32 %425)
  call void @cq_template_add_i64_hl_unc(i32 %422, i32 %421, i64 %420)
  call void @cqrt_free(i32 %422)
  call void @cqrt_and_i1(i32 %428, i32 %413, i32 %412)
  call void @cqrt_free(i32 %412)
  call void @cqrt_xor_i1(i32 %411, i32 %413)
  call void @cqrt_not_i1(i32 %413)
  call void @cqrt_free(i32 %413)
  call void @cq_template_select_i64_unc(i32 %410, i32 %409, i32 %427, i32 %408)
  call void @cqrt_free(i32 %410)
  call void @cqrt_and_i1(i32 %428, i32 %411, i32 %409)
  call void @cqrt_free(i32 %409)
  call void @cq_template_select_i64_unc(i32 %407, i32 %406, i32 %405, i32 %404)
  call void @cqrt_free(i32 %407)
  call void @cqrt_and_i1(i32 %428, i32 %411, i32 %406)
  call void @cqrt_free(i32 %406)
  call void @cqrt_free(i32 %405)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %411, i32 %403, i64 0)
  call void @cqrt_free(i32 %411)
  call void @cq_template_add_i64_hl_unc(i32 %403, i32 %402, i64 -1)
  call void @cqrt_free(i32 %403)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %427, i32 %428, i32 %11, i32 %424)
  call void @cq_template_add_i64_hl_unc(i32 %424, i32 %423, i64 8)
  call void @cqrt_free(i32 %424)
  %430 = call i32 @cqrt_pop()
  switch i32 %430, label %401 [
    i32 1, label %381
  ]

431:                                              ; preds = %245, %373
  %cq.run120 = phi i1 [ %cq.run121, %245 ], [ %cq.run118, %373 ]
  %cq.run100 = phi i1 [ %cq.run101, %245 ], [ %cq.run98, %373 ]
  %cq.run64 = phi i1 [ %cq.run65, %245 ], [ %cq.run62, %373 ]
  %cq.run47 = phi i1 [ %cq.run48, %245 ], [ %cq.run45, %373 ]
  %cq.run29 = phi i1 [ %cq.run30, %245 ], [ %cq.run27, %373 ]
  %cq.run15 = phi i1 [ %cq.run16, %245 ], [ %cq.run13, %373 ]
  %432 = call i32 @cqrt_pop()
  %433 = call i32 @cqrt_pop()
  %434 = zext i32 %433 to i64
  %435 = shl i64 %434, 32
  %436 = or i64 0, %435
  %437 = call i32 @cqrt_pop()
  %438 = zext i32 %437 to i64
  %439 = or i64 %436, %438
  %440 = call i32 @cqrt_pop()
  %441 = call i32 @cqrt_pop()
  %442 = call i32 @cqrt_pop()
  %443 = call i32 @cqrt_pop()
  %444 = call i32 @cqrt_pop()
  %445 = call i32 @cqrt_pop()
  %446 = call i32 @cqrt_pop()
  %447 = zext i32 %446 to i64
  %448 = shl i64 %447, 32
  %449 = or i64 0, %448
  %450 = call i32 @cqrt_pop()
  %451 = zext i32 %450 to i64
  %452 = or i64 %449, %451
  %453 = call i32 @cqrt_pop()
  %454 = call i32 @cqrt_pop()
  %455 = call i32 @cqrt_pop()
  %456 = call i32 @cqrt_pop()
  %457 = call i32 @cqrt_pop()
  %458 = call i32 @cqrt_pop()
  %459 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %459, i32 %458, i32 %457, i32 %456)
  call void @cqrt_free(i32 %459)
  call void @cq_template_select_i64_unc(i32 %455, i32 %458, i32 %454, i32 %453)
  call void @cqrt_free(i32 %455)
  call void @cq_template_add_i64_hl_unc(i32 %457, i32 %456, i64 %452)
  call void @cqrt_free(i32 %457)
  call void @cqrt_and_i1(i32 %458, i32 %445, i32 %444)
  call void @cqrt_xor_i1(i32 %458, i32 %444)
  call void @cqrt_free(i32 %444)
  call void @cq_template_shl_i64_hl_unc(i32 %443, i32 %442, i64 3)
  call void @cqrt_free(i32 %443)
  call void @cq_template_add_i64_hl_unc(i32 %441, i32 %440, i64 %439)
  call void @cqrt_free(i32 %441)
  call void @cq_template_mul_i64_hl_unc(i32 %440, i32 %432, i64 8)
  call void @cqrt_free(i32 %440)
  call void @cq_template_sub_i64_lh_unc(i32 %442, i64 %246, i32 %432)
  call void @cqrt_free(i32 %442)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %445, i32 %432, i64 %246)
  call void @cqrt_free(i32 %445)
  br label %401

460:                                              ; preds = %372, %245
  %cq.run117 = phi i1 [ %cq.run118, %372 ], [ %cq.run121, %245 ]
  %cq.run97 = phi i1 [ %cq.run98, %372 ], [ %cq.run101, %245 ]
  %cq.run61 = phi i1 [ %cq.run62, %372 ], [ %cq.run65, %245 ]
  %cq.run44 = phi i1 [ %cq.run45, %372 ], [ %cq.run48, %245 ]
  %cq.run26 = phi i1 [ %cq.run27, %372 ], [ %cq.run30, %245 ]
  %cq.run = phi i1 [ %cq.run13, %372 ], [ %cq.run16, %245 ]
  br label %250

461:                                              ; preds = %462
  call void @cqrt_free(i32 %75)
  call void @cqrt_free(i32 %74)
  call void @cqrt_free(i32 %73)
  call void @cqrt_xor_i1(i32 %76, i32 %72)
  call void @cqrt_not_i1(i32 %72)
  call void @cqrt_free(i32 %72)
  br label %501

462:                                              ; preds = %.cq.after137, %471
  %cq.run116 = phi i1 [ %cq.run117, %.cq.after137 ], [ %cq.run116, %471 ]
  %cq.run96 = phi i1 [ %cq.run97, %.cq.after137 ], [ %cq.run96, %471 ]
  %463 = call i32 @cqrt_pop()
  %464 = call i32 @cqrt_pop()
  %465 = call i32 @cqrt_pop()
  %466 = call i32 @cqrt_pop()
  %467 = call i32 @cqrt_pop()
  %468 = call i32 @cqrt_pop()
  %469 = call i32 @cqrt_pop()
  call void @cq_template_select_i1_lh_unc(i32 %469, i32 %468, i1 true, i32 %467)
  call void @cqrt_free(i32 %469)
  call void @cq_template_select_i64_lh_unc(i32 %466, i32 %468, i64 0, i32 %465)
  call void @cqrt_free(i32 %466)
  call void @cq_template_select_i64_lh_unc(i32 %464, i32 %468, i64 1, i32 %463)
  call void @cqrt_free(i32 %464)
  %470 = call i32 @cqrt_pop()
  switch i32 %470, label %471 [
    i32 1, label %461
  ]

471:                                              ; preds = %462
  %472 = call i32 @cqrt_pop()
  %473 = call i32 @cqrt_pop()
  %474 = zext i32 %473 to i64
  %475 = shl i64 %474, 32
  %476 = or i64 0, %475
  %477 = call i32 @cqrt_pop()
  %478 = zext i32 %477 to i64
  %479 = or i64 %476, %478
  %480 = call i32 @cqrt_pop()
  %481 = call i32 @cqrt_pop()
  %482 = call i32 @cqrt_pop()
  %483 = call i32 @cqrt_pop()
  %484 = call i32 @cqrt_pop()
  %485 = call i32 @cqrt_pop()
  %486 = call i32 @cqrt_pop()
  %487 = call i32 @cqrt_pop()
  %488 = call i32 @cqrt_pop()
  %489 = call i32 @cqrt_pop()
  %490 = call i32 @cqrt_pop()
  %491 = zext i32 %490 to i64
  %492 = shl i64 %491, 32
  %493 = or i64 0, %492
  %494 = call i32 @cqrt_pop()
  %495 = zext i32 %494 to i64
  %496 = or i64 %493, %495
  %497 = call i32 @cqrt_pop()
  %498 = call i32 @cqrt_pop()
  %499 = call i32 @cqrt_pop()
  %500 = call i32 @cqrt_pop()
  call void @cq_template_select_i1_lh_unc(i32 %500, i32 %499, i1 false, i32 %498)
  call void @cqrt_free(i32 %500)
  call void @cq_template_select_i64_lh_unc(i32 %497, i32 %499, i64 %496, i32 %489)
  call void @cqrt_free(i32 %497)
  call void @cq_template_select_i64_lh_unc(i32 %488, i32 %499, i64 0, i32 %487)
  call void @cqrt_free(i32 %488)
  call void @cqrt_and_i1(i32 %486, i32 %485, i32 %499)
  call void @cqrt_free(i32 %499)
  call void @cqrt_and_i1(i32 %486, i32 %485, i32 %484)
  call void @cqrt_xor_i1(i32 %486, i32 %484)
  call void @cqrt_free(i32 %484)
  call void @cqrt_and_i1(i32 %483, i32 %482, i32 %485)
  call void @cqrt_xor_i1(i32 %483, i32 %485)
  call void @cqrt_free(i32 %485)
  call void @cqrt_xor_i1(i32 %76, i32 %483)
  call void @cqrt_not_i1(i32 %483)
  call void @cqrt_free(i32 %483)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %482, i32 %481, i64 0)
  call void @cqrt_free(i32 %482)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %481, i32 %480, i32 %11, i64 %479)
  call void @cqrt_and_i1(i32 %486, i32 %472, i32 %480)
  call void @cqrt_free(i32 %480)
  call void @cqrt_xor_i1(i32 %76, i32 %472)
  call void @cqrt_not_i1(i32 %472)
  call void @cqrt_free(i32 %472)
  br label %462

501:                                              ; preds = %461, %.cq.after137
  %cq.run115 = phi i1 [ %cq.run116, %461 ], [ %cq.run117, %.cq.after137 ]
  %cq.run95 = phi i1 [ %cq.run96, %461 ], [ %cq.run97, %.cq.after137 ]
  br label %251
}

; Function Attrs: nounwind ssp uwtable
declare hidden fastcc void @mpn_fft_mul_2exp_modF(ptr noundef, ptr noundef, i64 noundef, i64 noundef) unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
declare noalias ptr @__gmp_tmp_reentrant_alloc(ptr nocapture noundef, i64 noundef) local_unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
declare void @__gmp_tmp_reentrant_free(ptr noundef) local_unnamed_addr #5

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i64(i64)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t(i32, i32, i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_qram_store_i64(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare void @cqrt_tape_write_i32_lit(i32, i32)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare void @cqrt_abort_i1(i32)

declare i32 @__cq_q___gmpn_sub_n_1111_t(i32, i32, i32, i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i64_lh(i32, i64, i32)

declare i32 @cq_template_select_i1_lh(i32, i1, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare void @cqrt_qram_store_i64_controlled(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare i32 @cq_template_icmp_ne_i64_hl(i32, i64)

declare i32 @cq_template_icmp_slt_i64_hl(i32, i64)

declare i32 @cq_template_shl_i64_hl(i32, i64)

declare i32 @cq_template_add_i64(i32, i32)

declare i32 @cq_template_sub_i64_lh(i64, i32)

declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)

declare void @cq_template_icmp_ugt_i64_hl_unc(i32, i32, i64)

declare i32 @cqrt_qram_load_i8_controlled(i32, i32, i32)

declare void @cqrt_push(i32)

declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)

declare void @cq_template_sub_i64_lh_unc(i32, i64, i32)

declare i32 @cqrt_pop()

declare void @cqrt_qram_store_i8_controlled(i32, i32, i32, i32)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cqrt_qram_swap_i64(i32, i32, i32)

declare i32 @cq_template_sub_i64(i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_sub_i64_unc(i32, i32, i32)

declare i32 @cqrt_qram_load_i64(i32, i32)

declare i32 @cq_template_icmp_ult_i64(i32, i32)

declare void @cqrt_qram_swap_i64_controlled(i32, i32, i32, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare i32 @cq_template_sub_i64_hl(i32, i64)

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_copy_i8(i32, i32)

declare i32 @cq_template_icmp_sge_i64_hl(i32, i64)

declare i32 @cq_template_select_i1_ll(i32, i1, i1)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl(i32, i32, i32, i32, i32, i32)

declare void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl_unc(i32, i32, i32, i32, i32, i32)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare void @__cq_q___gmp_tmp_reentrant_free_1_t(i32, i32)

declare void @__cq_q___gmp_tmp_reentrant_free_1_t_unc(i32, i32)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)

declare void @cq_template_select_i1_ll_unc(i32, i32, i1, i1)

declare void @cq_template_icmp_sge_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_ult_i64_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_ne_i64_hl_unc(i32, i32, i64)

declare void @cq_template_select_i1_lh_unc(i32, i32, i1, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @__cq_q___gmpn_sub_n_1111_t_unc(i32, i32, i32, i32, i32, i32)

declare void @__cq_q___gmp_tmp_reentrant_alloc_11_t_unc(i32, i32, i32, i32)

define void @__cq_q_mpn_mul_fft_decompose_111111111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9) {
  %11 = load i32, ptr @__cq_k, align 4
  store i32 %9, ptr @__cq_k, align 4
  %12 = call i32 @__cq_mem()
  %13 = call ptr @__cq_alloc(i64 8, i64 8)
  %14 = call i32 @cq_template_mul_i64(i32 %6, i32 %2)
  %15 = ptrtoint ptr %13 to i64
  %16 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %12, i64 %15, i32 %16)
  %17 = call i32 @cq_template_icmp_slt_i64(i32 %14, i32 %5)
  %18 = call i32 @cq_template_sub_i64(i32 %5, i32 %14)
  %19 = call i32 @cq_template_add_i64_hl(i32 %14, i64 1)
  %20 = call i32 @cq_template_shl_i64_hl(i32 %19, i64 3)
  %21 = ptrtoint ptr %13 to i64
  %22 = call i32 @cqrt_alloc_i64(i64 %21)
  %23 = call i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl(i32 %17, i32 %22, i32 %20, i32 %9)
  %24 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 8)
  %25 = call i32 @cq_template_add_i64(i32 %23, i32 %24)
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_controlled(i32 %17, i32 %12, i32 %25, i32 %26)
  call void @cq_template_add_i64_unc(i32 %25, i32 %23, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cq_template_mul_i64_hl_unc(i32 %24, i32 %14, i64 8)
  call void @cqrt_free(i32 %24)
  %27 = call i32 @cq_template_icmp_sgt_i64(i32 %18, i32 %14)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %17, i32 %28)
  call void @cq_template_icmp_sgt_i64_unc(i32 %27, i32 %18, i32 %14)
  call void @cqrt_free(i32 %27)
  %29 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64_controlled(i32 %28, i32 %18, i32 %29)
  %30 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64_controlled(i32 %28, i32 %3, i32 %30)
  call void @cqrt_abort_i1(i32 %28)
  %31 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 0)
  %32 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 8)
  %33 = call i32 @cq_template_add_i64(i32 %4, i32 %32)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %34)
  call void @cqrt_and_i1(i32 %17, i32 %31, i32 %34)
  %35 = call i32 @__cq_q___gmpn_sub_n_1111_t_ctl(i32 %34, i32 %23, i32 %4, i32 %33, i32 %18, i32 %9)
  %36 = call i32 @cq_template_icmp_eq_i64_hl(i32 %35, i64 0)
  br label %37

37:                                               ; preds = %10
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %39)
  call void @cqrt_and_i1(i32 %17, i32 %31, i32 %39)
  call void @cqrt_xor_i1(i32 %39, i32 %38)
  call void @cqrt_and_i1(i32 %39, i32 %36, i32 %38)
  %40 = call i32 @cqrt_alloc_i64(i64 0)
  %41 = call i32 @cqrt_alloc_i64(i64 0)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  %43 = call i32 @cq_template_icmp_slt_i64(i32 %18, i32 %14)
  %44 = call i32 @cqrt_alloc_i64(i64 1)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %45)
  call void @cqrt_xor_i1(i32 %43, i32 %45)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %45, i32 %46)
  %47 = call i32 @cq_template_select_i64(i32 %46, i32 %44, i32 %40)
  %48 = call i32 @cqrt_alloc_i64(i64 0)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %49)
  call void @cqrt_xor_i1(i32 %43, i32 %49)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %49, i32 %50)
  %51 = call i32 @cq_template_select_i64(i32 %50, i32 %48, i32 %41)
  %52 = call i32 @cqrt_alloc_i1(i1 true)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_xor_i1(i32 %43, i32 %53)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %53, i32 %54)
  %55 = call i32 @cq_template_select_i1(i32 %54, i32 %52, i32 %42)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %43, i32 %56)
  %57 = icmp ult i32 0, %9
  br i1 %57, label %58, label %96

58:                                               ; preds = %109, %37
  %from4 = phi i32 [ 0, %109 ], [ 1, %37 ]
  %59 = phi i32 [ 0, %37 ], [ %91, %109 ]
  %60 = phi i32 [ %56, %37 ], [ %123, %109 ]
  %61 = phi i32 [ %18, %37 ], [ %90, %109 ]
  %62 = phi i64 [ 0, %37 ], [ %89, %109 ]
  %63 = phi i32 [ %43, %37 ], [ %110, %109 ]
  %64 = phi i32 [ %47, %37 ], [ %114, %109 ]
  %65 = phi i32 [ %51, %37 ], [ %118, %109 ]
  %66 = phi i32 [ %55, %37 ], [ %122, %109 ]
  call void @cqrt_push(i32 %from4)
  %67 = call i32 @cq_template_mul_i64_hl(i32 %61, i64 8)
  %68 = call i32 @cq_template_add_i64(i32 %4, i32 %67)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %60, i32 %63, i32 %69)
  %70 = call i32 @cqrt_qram_load_i64_controlled(i32 %69, i32 %12, i32 %68)
  %71 = call i32 @cq_template_add_i64_hl(i32 %70, i64 -1)
  %72 = call i32 @cq_template_add_i64_hl(i32 %61, i64 1)
  %73 = call i32 @cq_template_mul_i64_hl(i32 %61, i64 8)
  %74 = call i32 @cq_template_add_i64(i32 %23, i32 %73)
  call void @cqrt_qram_store_i64_controlled(i32 %69, i32 %12, i32 %74, i32 %71)
  call void @cq_template_add_i64_unc(i32 %74, i32 %23, i32 %73)
  call void @cqrt_free(i32 %74)
  call void @cq_template_mul_i64_hl_unc(i32 %73, i32 %61, i64 8)
  call void @cqrt_free(i32 %73)
  %75 = call i32 @cq_template_icmp_eq_i64_hl(i32 %70, i64 0)
  %76 = call i32 @cqrt_alloc_i64(i64 0)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %63, i32 %77)
  call void @cqrt_and_i1(i32 %63, i32 %75, i32 %77)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %60, i32 %77, i32 %78)
  %79 = call i32 @cq_template_select_i64(i32 %78, i32 %76, i32 %64)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %63, i32 %80)
  call void @cqrt_and_i1(i32 %63, i32 %75, i32 %80)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %60, i32 %80, i32 %81)
  %82 = call i32 @cq_template_select_i64(i32 %81, i32 %72, i32 %65)
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %63, i32 %84)
  call void @cqrt_and_i1(i32 %63, i32 %75, i32 %84)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %60, i32 %84, i32 %85)
  %86 = call i32 @cq_template_select_i1(i32 %85, i32 %83, i32 %66)
  %87 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %75, i32 %63, i32 %87)
  %88 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %60, i32 %87, i32 %88)
  %89 = add i64 %62, 1
  %90 = call i32 @cq_template_add_i64_hl(i32 %18, i64 %89)
  %91 = add i32 %59, 1
  %92 = icmp ult i32 %91, %9
  call void @cqrt_push(i32 %90)
  %93 = trunc i64 %89 to i32
  call void @cqrt_push(i32 %93)
  %94 = lshr i64 %89, 32
  %95 = trunc i64 %94 to i32
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %67)
  br i1 %92, label %109, label %96

96:                                               ; preds = %58, %37
  %97 = phi i32 [ 0, %37 ], [ 1, %58 ]
  %98 = phi i32 [ %18, %37 ], [ %90, %58 ]
  %99 = phi i64 [ 0, %37 ], [ %89, %58 ]
  %100 = phi i32 [ %43, %37 ], [ %63, %58 ]
  %101 = phi i32 [ %47, %37 ], [ %79, %58 ]
  %102 = phi i32 [ %51, %37 ], [ %82, %58 ]
  %103 = phi i32 [ %55, %37 ], [ %86, %58 ]
  %104 = phi i32 [ %56, %37 ], [ %88, %58 ]
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %104, i32 %105)
  %106 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %101, i32 %106)
  %107 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %102, i32 %107)
  %108 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %103, i32 %108)
  br label %124

109:                                              ; preds = %58
  %110 = call i32 @cq_template_icmp_slt_i64(i32 %90, i32 %14)
  %111 = call i32 @cqrt_alloc_i64(i64 1)
  %112 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %112)
  call void @cqrt_xor_i1(i32 %110, i32 %112)
  %113 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %88, i32 %112, i32 %113)
  %114 = call i32 @cq_template_select_i64(i32 %113, i32 %111, i32 %79)
  %115 = call i32 @cqrt_alloc_i64(i64 0)
  %116 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %116)
  call void @cqrt_xor_i1(i32 %110, i32 %116)
  %117 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %88, i32 %116, i32 %117)
  %118 = call i32 @cq_template_select_i64(i32 %117, i32 %115, i32 %82)
  %119 = call i32 @cqrt_alloc_i1(i1 true)
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %120)
  call void @cqrt_xor_i1(i32 %110, i32 %120)
  %121 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %88, i32 %120, i32 %121)
  %122 = call i32 @cq_template_select_i1(i32 %121, i32 %119, i32 %86)
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %88, i32 %110, i32 %123)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %123)
  call void @cqrt_push(i32 %122)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %119)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %118)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %114)
  call void @cqrt_push(i32 %113)
  call void @cqrt_push(i32 %111)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %112)
  call void @cqrt_push(i32 %90)
  br label %58

124:                                              ; preds = %96
  %125 = call i32 @cq_template_select_i64(i32 %36, i32 %18, i32 %107)
  %126 = call i32 @cq_template_select_i64_lh(i32 %31, i64 0, i32 %125)
  %127 = call i32 @cq_template_icmp_ne_i64(i32 %23, i32 %4)
  %128 = call i32 @cq_template_icmp_slt_i64(i32 %126, i32 %14)
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %127, i32 %128, i32 %129)
  %130 = call i32 @cq_template_shl_i64_hl(i32 %126, i64 3)
  %131 = call i32 @cq_template_add_i64(i32 %23, i32 %130)
  %132 = call i32 @cq_template_add_i64(i32 %4, i32 %130)
  %133 = call i32 @cq_template_mul_i64(i32 %6, i32 %2)
  %134 = call i32 @cq_template_sub_i64(i32 %133, i32 %126)
  %135 = call i32 @cq_template_shl_i64_hl(i32 %134, i64 3)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %137)
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  %139 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %139)
  call void @cqrt_and_i1(i32 %17, i32 %31, i32 %139)
  call void @cqrt_xor_i1(i32 %139, i32 %138)
  call void @cqrt_and_i1(i32 %139, i32 %36, i32 %138)
  call void @cqrt_and_i1(i32 %108, i32 %138, i32 %137)
  call void @cqrt_and_i1(i32 %129, i32 %137, i32 %136)
  %140 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %135, i64 4096)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %140, i32 %136, i32 %141)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %140, i32 %135, i64 4096)
  call void @cqrt_free(i32 %140)
  br label %142

142:                                              ; preds = %142, %124
  %143 = phi i64 [ 0, %124 ], [ %148, %142 ]
  %144 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %135, i64 %143)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %144, i32 %136, i32 %145)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %144, i32 %135, i64 %143)
  call void @cqrt_free(i32 %144)
  %146 = call i32 @cq_template_add_i64_hl(i32 %132, i64 %143)
  %147 = call i32 @cqrt_qram_load_i8_controlled(i32 %145, i32 %12, i32 %146)
  call void @cq_template_add_i64_hl_unc(i32 %146, i32 %132, i64 %143)
  call void @cqrt_free(i32 %146)
  call void @cqrt_push(i32 %145)
  call void @cqrt_push(i32 %147)
  %148 = add nuw i64 %143, 1
  %149 = icmp eq i64 %148, 4096
  br i1 %149, label %150, label %142

150:                                              ; preds = %142
  call void @cq_template_shl_i64_hl_unc(i32 %135, i32 %134, i64 3)
  call void @cqrt_free(i32 %135)
  call void @cq_template_sub_i64_unc(i32 %134, i32 %133, i32 %126)
  call void @cqrt_free(i32 %134)
  call void @cq_template_mul_i64_unc(i32 %133, i32 %6, i32 %2)
  call void @cqrt_free(i32 %133)
  call void @cq_template_add_i64_unc(i32 %132, i32 %4, i32 %130)
  call void @cqrt_free(i32 %132)
  br label %151

151:                                              ; preds = %150
  br label %152

152:                                              ; preds = %152, %151
  %153 = phi i64 [ 4095, %151 ], [ %157, %152 ]
  %154 = call i32 @cqrt_pop()
  %155 = call i32 @cqrt_pop()
  %156 = call i32 @cq_template_add_i64_hl(i32 %131, i64 %153)
  call void @cqrt_qram_store_i8_controlled(i32 %155, i32 %12, i32 %156, i32 %154)
  call void @cq_template_add_i64_hl_unc(i32 %156, i32 %131, i64 %153)
  call void @cqrt_free(i32 %156)
  %157 = add nsw i64 %153, -1
  %158 = icmp eq i64 %153, 0
  br i1 %158, label %159, label %152

159:                                              ; preds = %152
  call void @cq_template_add_i64_unc(i32 %131, i32 %23, i32 %130)
  call void @cqrt_free(i32 %131)
  call void @cq_template_shl_i64_hl_unc(i32 %130, i32 %126, i64 3)
  call void @cqrt_free(i32 %130)
  br label %160

160:                                              ; preds = %159
  %161 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %161)
  %162 = call i32 @cqrt_alloc_i1(i1 false)
  %163 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %163)
  call void @cqrt_xor_i1(i32 %31, i32 %163)
  call void @cqrt_xor_i1(i32 %163, i32 %162)
  call void @cqrt_and_i1(i32 %163, i32 %36, i32 %162)
  call void @cqrt_and_i1(i32 %108, i32 %162, i32 %161)
  %164 = call i32 @cq_template_select_i64_lh(i32 %161, i64 0, i32 %106)
  %165 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %17, i32 %12, i32 %23, i32 %165)
  %166 = call i32 @cq_template_add_i64(i32 %165, i32 %164)
  %167 = call i32 @cq_template_select_i64(i32 %17, i32 %166, i32 %165)
  call void @cq_template_add_i64_unc(i32 %166, i32 %165, i32 %164)
  call void @cqrt_free(i32 %166)
  %168 = call i32 @cq_template_sub_i64(i32 %167, i32 %164)
  %169 = call i32 @cq_template_select_i64(i32 %17, i32 %168, i32 %167)
  call void @cqrt_copy_i64(i32 %169, i32 %165)
  call void @cq_template_select_i64_unc(i32 %169, i32 %17, i32 %168, i32 %167)
  call void @cqrt_free(i32 %169)
  call void @cq_template_sub_i64_unc(i32 %168, i32 %167, i32 %164)
  call void @cqrt_free(i32 %168)
  call void @cqrt_free(i32 %165)
  call void @cqrt_qram_swap_i64_controlled(i32 %17, i32 %12, i32 %23, i32 %167)
  call void @cqrt_free(i32 %167)
  %170 = call i32 @cqrt_qram_load_i64_controlled(i32 %17, i32 %12, i32 %23)
  %171 = call i32 @cq_template_icmp_ult_i64(i32 %170, i32 %164)
  br label %172

172:                                              ; preds = %160
  %173 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %171, i32 %17, i32 %173)
  %174 = icmp ult i32 0, %9
  br i1 %174, label %175, label %191

175:                                              ; preds = %175, %172
  %from = phi i32 [ 0, %175 ], [ 1, %172 ]
  %176 = phi i32 [ 0, %172 ], [ %189, %175 ]
  %177 = phi i32 [ %173, %172 ], [ %187, %175 ]
  %178 = phi i32 [ %23, %172 ], [ %188, %175 ]
  call void @cqrt_push(i32 %from)
  %179 = call i32 @cq_template_add_i64_hl(i32 %178, i64 8)
  %180 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %177, i32 %12, i32 %179, i32 %180)
  %181 = call i32 @cq_template_add_i64_hl(i32 %180, i64 1)
  %182 = call i32 @cq_template_select_i64(i32 %177, i32 %181, i32 %180)
  call void @cq_template_add_i64_hl_unc(i32 %181, i32 %180, i64 1)
  call void @cqrt_free(i32 %181)
  %183 = call i32 @cq_template_sub_i64_hl(i32 %182, i64 1)
  %184 = call i32 @cq_template_select_i64(i32 %177, i32 %183, i32 %182)
  call void @cqrt_copy_i64(i32 %184, i32 %180)
  call void @cq_template_select_i64_unc(i32 %184, i32 %177, i32 %183, i32 %182)
  call void @cqrt_free(i32 %184)
  call void @cq_template_sub_i64_hl_unc(i32 %183, i32 %182, i64 1)
  call void @cqrt_free(i32 %183)
  call void @cqrt_free(i32 %180)
  call void @cqrt_qram_swap_i64_controlled(i32 %177, i32 %12, i32 %179, i32 %182)
  call void @cqrt_free(i32 %182)
  %185 = call i32 @cqrt_qram_load_i64_controlled(i32 %177, i32 %12, i32 %179)
  %186 = call i32 @cq_template_icmp_eq_i64_hl(i32 %185, i64 0)
  %187 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %177, i32 %186, i32 %187)
  %188 = call i32 @cq_template_select_i64(i32 %177, i32 %179, i32 %178)
  %189 = add i32 %176, 1
  %190 = icmp ult i32 %189, %9
  call void @cqrt_push(i32 %188)
  call void @cqrt_push(i32 %177)
  call void @cqrt_push(i32 %179)
  call void @cqrt_push(i32 %178)
  call void @cqrt_push(i32 %186)
  call void @cqrt_push(i32 %187)
  call void @cqrt_push(i32 %185)
  br i1 %190, label %175, label %191

191:                                              ; preds = %175, %172
  %192 = phi i32 [ 0, %172 ], [ 1, %175 ]
  %193 = phi i32 [ %23, %172 ], [ %188, %175 ]
  %194 = phi i32 [ %173, %172 ], [ %187, %175 ]
  %195 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %194, i32 %195)
  br label %215

196:                                              ; preds = %215, %206
  %197 = call i32 @cq_template_select_i64(i32 %17, i32 %19, i32 %5)
  %198 = call i32 @cq_template_select_i64(i32 %17, i32 %23, i32 %4)
  %199 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %2, i64 0)
  %200 = call i32 @cq_template_icmp_eq_i64_hl(i32 %3, i64 -1)
  %201 = call i32 @cq_template_add_i64_hl(i32 %2, i64 -1)
  %202 = call i32 @cq_template_add_i64_hl(i32 %3, i64 1)
  %203 = call i32 @cq_template_add_i64_hl(i32 %3, i64 1)
  %204 = call i32 @cq_template_shl_i64_hl(i32 %3, i64 3)
  %205 = call i32 @cq_template_add_i64_hl(i32 %204, i64 8)
  br label %216

206:                                              ; preds = %215, %206
  %207 = call i32 @cqrt_pop()
  %208 = call i32 @cqrt_pop()
  %209 = call i32 @cqrt_pop()
  %210 = call i32 @cqrt_pop()
  %211 = call i32 @cqrt_pop()
  %212 = call i32 @cqrt_pop()
  %213 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %213, i32 %212, i32 %211, i32 %210)
  call void @cqrt_free(i32 %213)
  call void @cqrt_and_i1(i32 %212, i32 %209, i32 %208)
  call void @cqrt_free(i32 %208)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %209, i32 %207, i64 0)
  call void @cqrt_free(i32 %209)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %207, i32 %212, i32 %12, i32 %211)
  call void @cq_template_add_i64_hl_unc(i32 %211, i32 %210, i64 8)
  call void @cqrt_free(i32 %211)
  %214 = call i32 @cqrt_pop()
  switch i32 %214, label %206 [
    i32 1, label %196
  ]

215:                                              ; preds = %191
  switch i32 %192, label %196 [
    i32 1, label %206
  ]

216:                                              ; preds = %196
  %217 = icmp ult i32 0, %9
  br i1 %217, label %218, label %236

218:                                              ; preds = %331, %216
  %from3 = phi i32 [ 0, %331 ], [ 1, %216 ]
  %219 = phi i32 [ 0, %216 ], [ %347, %331 ]
  %220 = phi i32 [ %199, %216 ], [ %343, %331 ]
  %221 = phi i32 [ %0, %216 ], [ %344, %331 ]
  %222 = phi i32 [ %198, %216 ], [ %345, %331 ]
  %223 = phi i32 [ %197, %216 ], [ %346, %331 ]
  %224 = phi i64 [ 0, %216 ], [ %340, %331 ]
  %225 = mul i64 %224, 8
  %226 = call i32 @cq_template_add_i64_hl(i32 %1, i64 %225)
  %227 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %221, i32 %227)
  %228 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %220, i32 %228)
  call void @cqrt_qram_store_i64_controlled(i32 %228, i32 %12, i32 %226, i32 %227)
  %229 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %223, i64 0)
  %230 = call i32 @cqrt_alloc_i1(i1 false)
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %231)
  call void @cqrt_xor_i1(i32 %229, i32 %231)
  call void @cqrt_xor_i1(i32 %231, i32 %230)
  call void @cqrt_and_i1(i32 %231, i32 %200, i32 %230)
  %232 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %230, i32 %232)
  %233 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %205, i64 4096)
  %234 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %233, i32 %232, i32 %234)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %233, i32 %205, i64 4096)
  call void @cqrt_free(i32 %233)
  %235 = call i32 @cqrt_alloc_i8(i8 0)
  br label %245

236:                                              ; preds = %331, %216
  %237 = phi i32 [ 0, %216 ], [ 1, %331 ]
  %238 = phi i32 [ %0, %216 ], [ %344, %331 ]
  %239 = phi i32 [ %198, %216 ], [ %345, %331 ]
  %240 = phi i32 [ %197, %216 ], [ %346, %331 ]
  %241 = phi i64 [ 0, %216 ], [ %340, %331 ]
  %242 = phi i32 [ %199, %216 ], [ %343, %331 ]
  %243 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %242, i32 %243)
  %244 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %240, i32 %244)
  br label %352

245:                                              ; preds = %245, %218
  %246 = phi i64 [ 0, %218 ], [ %250, %245 ]
  %247 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %205, i64 %246)
  %248 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %247, i32 %232, i32 %248)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %247, i32 %205, i64 %246)
  call void @cqrt_free(i32 %247)
  %249 = call i32 @cq_template_add_i64_hl(i32 %221, i64 %246)
  call void @cqrt_qram_store_i8_controlled(i32 %248, i32 %12, i32 %249, i32 %235)
  call void @cq_template_add_i64_hl_unc(i32 %249, i32 %221, i64 %246)
  call void @cqrt_free(i32 %249)
  %250 = add nuw i64 %246, 1
  %251 = icmp eq i64 %250, 4096
  br i1 %251, label %252, label %245

252:                                              ; preds = %245
  br label %253

253:                                              ; preds = %252
  call void @cqrt_push(i32 %from3)
  %254 = call i32 @cq_template_icmp_sge_i64(i32 %223, i32 %6)
  %255 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %201, i64 %224)
  %256 = call i32 @cq_template_select_i1_hl(i32 %254, i32 %255, i1 false)
  %257 = call i32 @cq_template_select_i64(i32 %256, i32 %6, i32 %223)
  %258 = call i32 @cq_template_sub_i64(i32 %223, i32 %257)
  %259 = call i32 @cq_template_icmp_eq_i64_hl(i32 %257, i64 0)
  %260 = call i32 @cq_template_add_i64_hl(i32 %257, i64 -1)
  %261 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %229, i32 %261)
  call void @cqrt_and_i1(i32 %229, i32 %259, i32 %261)
  %262 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %261, i32 %262)
  %263 = call i32 @cqrt_qram_load_i64_controlled(i32 %262, i32 %12, i32 %222)
  %264 = call i32 @cq_template_icmp_eq_i64_hl(i32 %260, i64 0)
  %265 = call i32 @cqrt_alloc_i1(i1 false)
  %266 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %229, i32 %266)
  call void @cqrt_and_i1(i32 %229, i32 %259, i32 %266)
  call void @cqrt_xor_i1(i32 %266, i32 %265)
  call void @cqrt_and_i1(i32 %266, i32 %264, i32 %265)
  %267 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %265, i32 %267)
  %268 = icmp ult i32 0, %9
  call void @cqrt_push(i32 %220)
  call void @cqrt_push(i32 %265)
  call void @cqrt_push(i32 %267)
  call void @cqrt_push(i32 %266)
  call void @cqrt_push(i32 %264)
  call void @cqrt_push(i32 %229)
  call void @cqrt_push(i32 %259)
  call void @cqrt_push(i32 %260)
  call void @cqrt_push(i32 %263)
  call void @cqrt_push(i32 %262)
  call void @cqrt_push(i32 %222)
  call void @cqrt_push(i32 %261)
  call void @cqrt_push(i32 %257)
  call void @cqrt_push(i32 %258)
  call void @cqrt_push(i32 %223)
  call void @cqrt_push(i32 %256)
  call void @cqrt_push(i32 %254)
  call void @cqrt_push(i32 %255)
  %269 = trunc i64 %224 to i32
  call void @cqrt_push(i32 %269)
  %270 = lshr i64 %224, 32
  %271 = trunc i64 %270 to i32
  call void @cqrt_push(i32 %271)
  call void @cqrt_push(i32 %230)
  call void @cqrt_push(i32 %232)
  call void @cqrt_push(i32 %231)
  call void @cqrt_push(i32 %226)
  %272 = trunc i64 %225 to i32
  call void @cqrt_push(i32 %272)
  %273 = lshr i64 %225, 32
  %274 = trunc i64 %273 to i32
  call void @cqrt_push(i32 %274)
  br i1 %268, label %275, label %302

275:                                              ; preds = %275, %253
  %from2 = phi i32 [ 0, %275 ], [ 1, %253 ]
  %276 = phi i32 [ 0, %253 ], [ %297, %275 ]
  %277 = phi i32 [ %267, %253 ], [ %291, %275 ]
  %278 = phi i32 [ %260, %253 ], [ %293, %275 ]
  %279 = phi i32 [ %8, %253 ], [ %294, %275 ]
  %280 = phi i32 [ %222, %253 ], [ %295, %275 ]
  %281 = phi i32 [ %263, %253 ], [ %296, %275 ]
  %282 = phi i64 [ 0, %253 ], [ %292, %275 ]
  call void @cqrt_push(i32 %from2)
  %283 = call i32 @cq_template_add_i64_hl(i32 %280, i64 8)
  %284 = call i32 @cq_template_add_i64_hl(i32 %279, i64 8)
  %285 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %281, i32 %285)
  %286 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %277, i32 %286)
  call void @cqrt_qram_store_i64_controlled(i32 %286, i32 %12, i32 %279, i32 %285)
  %287 = call i32 @cqrt_qram_load_i64_controlled(i32 %277, i32 %12, i32 %283)
  %288 = call i32 @cq_template_add_i64_hl(i32 %278, i64 -1)
  %289 = call i32 @cq_template_icmp_eq_i64_hl(i32 %288, i64 0)
  %290 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %290)
  call void @cqrt_xor_i1(i32 %289, i32 %290)
  %291 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %277, i32 %290, i32 %291)
  %292 = add i64 %282, -1
  %293 = call i32 @cq_template_add_i64_hl(i32 %260, i64 %292)
  %294 = call i32 @cq_template_select_i64(i32 %277, i32 %284, i32 %279)
  %295 = call i32 @cq_template_select_i64(i32 %277, i32 %283, i32 %280)
  %296 = call i32 @cq_template_select_i64(i32 %277, i32 %287, i32 %281)
  %297 = add i32 %276, 1
  %298 = icmp ult i32 %297, %9
  call void @cqrt_push(i32 %296)
  call void @cqrt_push(i32 %277)
  call void @cqrt_push(i32 %287)
  call void @cqrt_push(i32 %281)
  call void @cqrt_push(i32 %295)
  call void @cqrt_push(i32 %283)
  call void @cqrt_push(i32 %280)
  call void @cqrt_push(i32 %294)
  call void @cqrt_push(i32 %284)
  call void @cqrt_push(i32 %279)
  call void @cqrt_push(i32 %293)
  call void @cqrt_push(i32 %260)
  %299 = trunc i64 %292 to i32
  call void @cqrt_push(i32 %299)
  %300 = lshr i64 %292, 32
  %301 = trunc i64 %300 to i32
  call void @cqrt_push(i32 %301)
  call void @cqrt_push(i32 %290)
  call void @cqrt_push(i32 %291)
  call void @cqrt_push(i32 %289)
  call void @cqrt_push(i32 %288)
  call void @cqrt_push(i32 %278)
  br i1 %298, label %275, label %302

302:                                              ; preds = %275, %253
  %from1 = phi i32 [ 0, %275 ], [ 1, %253 ]
  %303 = phi i32 [ %260, %253 ], [ %293, %275 ]
  %304 = phi i32 [ %8, %253 ], [ %294, %275 ]
  %305 = phi i32 [ %222, %253 ], [ %295, %275 ]
  %306 = phi i32 [ %263, %253 ], [ %296, %275 ]
  %307 = phi i64 [ 0, %253 ], [ %292, %275 ]
  %308 = phi i32 [ %267, %253 ], [ %291, %275 ]
  %309 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %308, i32 %309)
  %310 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %306, i32 %310)
  %311 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %229, i32 %311)
  call void @cqrt_and_i1(i32 %229, i32 %259, i32 %311)
  %312 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %311, i32 %312)
  call void @cqrt_qram_store_i64_controlled(i32 %312, i32 %12, i32 %304, i32 %310)
  %313 = call i32 @cq_template_icmp_eq_i64(i32 %202, i32 %257)
  %314 = call i32 @cq_template_sub_i64(i32 %202, i32 %257)
  %315 = call i32 @cq_template_mul_i64_hl(i32 %257, i64 8)
  %316 = call i32 @cq_template_add_i64(i32 %8, i32 %315)
  %317 = call i32 @cq_template_shl_i64_hl(i32 %314, i64 3)
  %318 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %229, i32 %318)
  call void @cqrt_and_i1(i32 %229, i32 %313, i32 %318)
  %319 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %318, i32 %319)
  %320 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %317, i64 4096)
  %321 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %320, i32 %319, i32 %321)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %320, i32 %317, i64 4096)
  call void @cqrt_free(i32 %320)
  %322 = call i32 @cqrt_alloc_i8(i8 0)
  br label %323

323:                                              ; preds = %323, %302
  %324 = phi i64 [ 0, %302 ], [ %328, %323 ]
  %325 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %317, i64 %324)
  %326 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %325, i32 %319, i32 %326)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %325, i32 %317, i64 %324)
  call void @cqrt_free(i32 %325)
  %327 = call i32 @cq_template_add_i64_hl(i32 %316, i64 %324)
  call void @cqrt_qram_store_i8_controlled(i32 %326, i32 %12, i32 %327, i32 %322)
  call void @cq_template_add_i64_hl_unc(i32 %327, i32 %316, i64 %324)
  call void @cqrt_free(i32 %327)
  %328 = add nuw i64 %324, 1
  %329 = icmp eq i64 %328, 4096
  br i1 %329, label %330, label %323

330:                                              ; preds = %323
  br label %331

331:                                              ; preds = %330
  call void @cqrt_push(i32 %from1)
  %332 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 8)
  %333 = call i32 @cq_template_add_i64(i32 %222, i32 %332)
  %334 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 %224)
  %335 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %229, i32 %335)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl(i32 %335, i32 %221, i32 %8, i32 %334, i32 %3, i32 %9)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl_unc(i32 %335, i32 %221, i32 %8, i32 %334, i32 %3, i32 %9)
  call void @cqrt_and_i1(i32 %220, i32 %229, i32 %335)
  call void @cqrt_free(i32 %335)
  call void @cq_template_mul_i64_hl_unc(i32 %334, i32 %7, i64 %224)
  call void @cqrt_free(i32 %334)
  %336 = call i32 @cq_template_select_i64(i32 %229, i32 %258, i32 %223)
  %337 = call i32 @cq_template_select_i64(i32 %229, i32 %333, i32 %222)
  %338 = call i32 @cq_template_mul_i64_hl(i32 %203, i64 8)
  %339 = call i32 @cq_template_add_i64(i32 %221, i32 %338)
  %340 = add i64 %224, 1
  %341 = call i32 @cq_template_icmp_eq_i64_hl(i32 %2, i64 %340)
  %342 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %342)
  call void @cqrt_xor_i1(i32 %341, i32 %342)
  %343 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %220, i32 %342, i32 %343)
  %344 = call i32 @cq_template_select_i64(i32 %220, i32 %339, i32 %221)
  %345 = call i32 @cq_template_select_i64(i32 %220, i32 %337, i32 %222)
  %346 = call i32 @cq_template_select_i64(i32 %220, i32 %336, i32 %223)
  %347 = add i32 %219, 1
  %348 = icmp ult i32 %347, %9
  call void @cqrt_push(i32 %346)
  call void @cqrt_push(i32 %220)
  call void @cqrt_push(i32 %336)
  call void @cqrt_push(i32 %223)
  call void @cqrt_push(i32 %345)
  call void @cqrt_push(i32 %337)
  call void @cqrt_push(i32 %222)
  call void @cqrt_push(i32 %344)
  call void @cqrt_push(i32 %339)
  call void @cqrt_push(i32 %221)
  call void @cqrt_push(i32 %342)
  call void @cqrt_push(i32 %343)
  call void @cqrt_push(i32 %341)
  %349 = trunc i64 %340 to i32
  call void @cqrt_push(i32 %349)
  %350 = lshr i64 %340, 32
  %351 = trunc i64 %350 to i32
  call void @cqrt_push(i32 %351)
  call void @cqrt_push(i32 %338)
  call void @cqrt_push(i32 %229)
  call void @cqrt_push(i32 %333)
  call void @cqrt_push(i32 %258)
  call void @cqrt_push(i32 %332)
  call void @cqrt_push(i32 %318)
  call void @cqrt_push(i32 %319)
  call void @cqrt_push(i32 %313)
  call void @cqrt_push(i32 %317)
  call void @cqrt_push(i32 %314)
  call void @cqrt_push(i32 %316)
  call void @cqrt_push(i32 %315)
  call void @cqrt_push(i32 %257)
  call void @cqrt_push(i32 %259)
  call void @cqrt_push(i32 %311)
  br i1 %348, label %218, label %236

352:                                              ; preds = %236
  %353 = call i32 @cq_template_icmp_eq_i64_hl(i32 %244, i64 0)
  %354 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %354)
  call void @cqrt_xor_i1(i32 %353, i32 %354)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %353, i32 %244, i64 0)
  call void @cqrt_free(i32 %353)
  br label %461

355:                                              ; preds = %359
  call void @cq_template_add_i64_hl_unc(i32 %205, i32 %204, i64 8)
  call void @cqrt_free(i32 %205)
  call void @cq_template_shl_i64_hl_unc(i32 %204, i32 %3, i64 3)
  call void @cqrt_free(i32 %204)
  call void @cq_template_add_i64_hl_unc(i32 %203, i32 %3, i64 1)
  call void @cqrt_free(i32 %203)
  call void @cq_template_add_i64_hl_unc(i32 %202, i32 %3, i64 1)
  call void @cqrt_free(i32 %202)
  call void @cq_template_add_i64_hl_unc(i32 %201, i32 %2, i64 -1)
  call void @cqrt_free(i32 %201)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %200, i32 %3, i64 -1)
  call void @cqrt_free(i32 %200)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %199, i32 %2, i64 0)
  call void @cqrt_free(i32 %199)
  call void @cq_template_select_i64_unc(i32 %198, i32 %17, i32 %23, i32 %4)
  call void @cqrt_free(i32 %198)
  call void @cq_template_select_i64_unc(i32 %197, i32 %17, i32 %19, i32 %5)
  call void @cqrt_free(i32 %197)
  call void @cqrt_and_i1(i32 %171, i32 %17, i32 %173)
  call void @cqrt_free(i32 %173)
  call void @cq_template_icmp_ult_i64_unc(i32 %171, i32 %170, i32 %164)
  call void @cqrt_free(i32 %171)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %170, i32 %17, i32 %12, i32 %23)
  call void @cq_template_select_i64_lh_unc(i32 %164, i32 %161, i64 0, i32 %106)
  call void @cqrt_free(i32 %164)
  call void @cqrt_and_i1(i32 %108, i32 %162, i32 %161)
  call void @cqrt_not_i1(i32 %161)
  call void @cqrt_free(i32 %161)
  call void @cqrt_and_i1(i32 %163, i32 %36, i32 %162)
  call void @cqrt_xor_i1(i32 %163, i32 %162)
  call void @cqrt_free(i32 %162)
  call void @cqrt_xor_i1(i32 %31, i32 %163)
  call void @cqrt_not_i1(i32 %163)
  call void @cqrt_free(i32 %163)
  call void @cqrt_and_i1(i32 %129, i32 %137, i32 %136)
  call void @cqrt_free(i32 %136)
  call void @cqrt_and_i1(i32 %108, i32 %138, i32 %137)
  call void @cqrt_xor_i1(i32 %17, i32 %137)
  call void @cqrt_free(i32 %137)
  call void @cqrt_and_i1(i32 %139, i32 %36, i32 %138)
  call void @cqrt_xor_i1(i32 %139, i32 %138)
  call void @cqrt_free(i32 %138)
  call void @cqrt_and_i1(i32 %17, i32 %31, i32 %139)
  call void @cqrt_xor_i1(i32 %17, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_and_i1(i32 %127, i32 %128, i32 %129)
  call void @cqrt_free(i32 %129)
  call void @cq_template_icmp_slt_i64_unc(i32 %128, i32 %126, i32 %14)
  call void @cqrt_free(i32 %128)
  call void @cq_template_icmp_ne_i64_unc(i32 %127, i32 %23, i32 %4)
  call void @cqrt_free(i32 %127)
  call void @cq_template_select_i64_lh_unc(i32 %126, i32 %31, i64 0, i32 %125)
  call void @cqrt_free(i32 %126)
  call void @cq_template_select_i64_unc(i32 %125, i32 %36, i32 %18, i32 %107)
  call void @cqrt_free(i32 %125)
  br label %519

356:                                              ; preds = %463
  call void @cqrt_and_i1(i32 %38, i32 %43, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cq_template_select_i1_unc(i32 %55, i32 %54, i32 %52, i32 %42)
  call void @cqrt_free(i32 %55)
  call void @cqrt_and_i1(i32 %38, i32 %53, i32 %54)
  call void @cqrt_free(i32 %54)
  call void @cqrt_xor_i1(i32 %43, i32 %53)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cqrt_free(i32 %52)
  call void @cq_template_select_i64_unc(i32 %51, i32 %50, i32 %48, i32 %41)
  call void @cqrt_free(i32 %51)
  call void @cqrt_and_i1(i32 %38, i32 %49, i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cqrt_xor_i1(i32 %43, i32 %49)
  call void @cqrt_not_i1(i32 %49)
  call void @cqrt_free(i32 %49)
  call void @cqrt_free(i32 %48)
  call void @cq_template_select_i64_unc(i32 %47, i32 %46, i32 %44, i32 %40)
  call void @cqrt_free(i32 %47)
  call void @cqrt_and_i1(i32 %38, i32 %45, i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_xor_i1(i32 %43, i32 %45)
  call void @cqrt_not_i1(i32 %45)
  call void @cqrt_free(i32 %45)
  call void @cqrt_free(i32 %44)
  call void @cq_template_icmp_slt_i64_unc(i32 %43, i32 %18, i32 %14)
  call void @cqrt_free(i32 %43)
  call void @cqrt_free(i32 %42)
  call void @cqrt_free(i32 %41)
  call void @cqrt_free(i32 %40)
  call void @cqrt_and_i1(i32 %39, i32 %36, i32 %38)
  call void @cqrt_xor_i1(i32 %39, i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cqrt_and_i1(i32 %17, i32 %31, i32 %39)
  call void @cqrt_xor_i1(i32 %17, i32 %39)
  call void @cqrt_free(i32 %39)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %36, i32 %35, i64 0)
  call void @cqrt_free(i32 %36)
  call void @__cq_q___gmpn_sub_n_1111_t_ctl_unc(i32 %34, i32 %35, i32 %23, i32 %4, i32 %33, i32 %18, i32 %9)
  call void @cqrt_and_i1(i32 %17, i32 %31, i32 %34)
  call void @cqrt_xor_i1(i32 %17, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cq_template_add_i64_unc(i32 %33, i32 %4, i32 %32)
  call void @cqrt_free(i32 %33)
  call void @cq_template_mul_i64_hl_unc(i32 %32, i32 %14, i64 8)
  call void @cqrt_free(i32 %32)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %31, i32 %18, i64 0)
  call void @cqrt_free(i32 %31)
  call void @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl_unc(i32 %17, i32 %23, i32 %22, i32 %20, i32 %9)
  call void @cqrt_free(i32 %22)
  call void @cq_template_shl_i64_hl_unc(i32 %20, i32 %19, i64 3)
  call void @cqrt_free(i32 %20)
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %14, i64 1)
  call void @cqrt_free(i32 %19)
  call void @cq_template_sub_i64_unc(i32 %18, i32 %5, i32 %14)
  call void @cqrt_free(i32 %18)
  call void @cq_template_mul_i64_unc(i32 %14, i32 %6, i32 %2)
  call void @cqrt_free(i32 %14)
  call void @cqrt_abort_i1(i32 %354)
  %357 = ptrtoint ptr %13 to i64
  %358 = call i32 @cqrt_qram_load_i64_hl(i32 %12, i64 %357)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t(i32 %358, i32 %9)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_unc(i32 %358, i32 %9)
  call void @cqrt_qram_load_i64_hl_unc(i32 %358, i32 %12, i64 %357)
  store i32 %11, ptr @__cq_k, align 4
  ret void

359:                                              ; preds = %462, %360
  br label %355

360:                                              ; preds = %398, %424
  %361 = call i32 @cqrt_pop()
  %362 = zext i32 %361 to i64
  %363 = shl i64 %362, 32
  %364 = or i64 0, %363
  %365 = call i32 @cqrt_pop()
  %366 = zext i32 %365 to i64
  %367 = or i64 %364, %366
  %368 = call i32 @cqrt_pop()
  %369 = call i32 @cqrt_pop()
  %370 = call i32 @cqrt_pop()
  %371 = call i32 @cqrt_pop()
  %372 = call i32 @cqrt_pop()
  %373 = zext i32 %372 to i64
  %374 = shl i64 %373, 32
  %375 = or i64 0, %374
  %376 = call i32 @cqrt_pop()
  %377 = zext i32 %376 to i64
  %378 = or i64 %375, %377
  %379 = call i32 @cqrt_pop()
  %380 = call i32 @cqrt_pop()
  %381 = call i32 @cqrt_pop()
  %382 = call i32 @cqrt_pop()
  %383 = call i32 @cqrt_pop()
  %384 = call i32 @cqrt_pop()
  %385 = call i32 @cqrt_pop()
  %386 = call i32 @cqrt_pop()
  %387 = call i32 @cqrt_pop()
  %388 = call i32 @cqrt_pop()
  %389 = call i32 @cqrt_pop()
  %390 = call i32 @cqrt_pop()
  %391 = call i32 @cqrt_pop()
  %392 = call i32 @cqrt_pop()
  %393 = call i32 @cqrt_pop()
  %394 = call i32 @cqrt_pop()
  %395 = call i32 @cqrt_pop()
  %396 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %396, i32 %395, i32 %394)
  call void @cqrt_free(i32 %394)
  call void @cqrt_and_i1(i32 %393, i32 %392, i32 %395)
  call void @cqrt_xor_i1(i32 %393, i32 %395)
  call void @cqrt_free(i32 %395)
  call void @cqrt_and_i1(i32 %391, i32 %390, i32 %393)
  call void @cqrt_xor_i1(i32 %391, i32 %393)
  call void @cqrt_free(i32 %393)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %392, i32 %389, i64 0)
  call void @cqrt_free(i32 %392)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %388, i32 %387, i32 %12, i32 %386)
  call void @cqrt_and_i1(i32 %396, i32 %385, i32 %387)
  call void @cqrt_free(i32 %387)
  call void @cqrt_and_i1(i32 %391, i32 %390, i32 %385)
  call void @cqrt_xor_i1(i32 %391, i32 %385)
  call void @cqrt_free(i32 %385)
  call void @cq_template_add_i64_hl_unc(i32 %389, i32 %384, i64 -1)
  call void @cqrt_free(i32 %389)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %390, i32 %384, i64 0)
  call void @cqrt_free(i32 %390)
  call void @cq_template_sub_i64_unc(i32 %383, i32 %382, i32 %384)
  call void @cqrt_free(i32 %383)
  call void @cq_template_select_i64_unc(i32 %384, i32 %381, i32 %6, i32 %382)
  call void @cqrt_free(i32 %384)
  call void @cq_template_select_i1_hl_unc(i32 %381, i32 %380, i32 %379, i1 false)
  call void @cqrt_free(i32 %381)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %379, i32 %201, i64 %378)
  call void @cqrt_free(i32 %379)
  call void @cq_template_icmp_sge_i64_unc(i32 %380, i32 %382, i32 %6)
  call void @cqrt_free(i32 %380)
  call void @cqrt_and_i1(i32 %396, i32 %371, i32 %370)
  call void @cqrt_free(i32 %370)
  call void @cqrt_and_i1(i32 %369, i32 %200, i32 %371)
  call void @cqrt_xor_i1(i32 %369, i32 %371)
  call void @cqrt_free(i32 %371)
  call void @cqrt_xor_i1(i32 %391, i32 %369)
  call void @cqrt_not_i1(i32 %369)
  call void @cqrt_free(i32 %369)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %391, i32 %382, i64 0)
  call void @cqrt_free(i32 %391)
  call void @cq_template_add_i64_hl_unc(i32 %368, i32 %1, i64 %367)
  call void @cqrt_free(i32 %368)
  %397 = call i32 @cqrt_pop()
  switch i32 %397, label %424 [
    i32 1, label %359
  ]

398:                                              ; preds = %398, %424
  %399 = call i32 @cqrt_pop()
  %400 = call i32 @cqrt_pop()
  %401 = call i32 @cqrt_pop()
  %402 = call i32 @cqrt_pop()
  %403 = call i32 @cqrt_pop()
  %404 = call i32 @cqrt_pop()
  %405 = zext i32 %404 to i64
  %406 = shl i64 %405, 32
  %407 = or i64 0, %406
  %408 = call i32 @cqrt_pop()
  %409 = zext i32 %408 to i64
  %410 = or i64 %407, %409
  %411 = call i32 @cqrt_pop()
  %412 = call i32 @cqrt_pop()
  %413 = call i32 @cqrt_pop()
  %414 = call i32 @cqrt_pop()
  %415 = call i32 @cqrt_pop()
  %416 = call i32 @cqrt_pop()
  %417 = call i32 @cqrt_pop()
  %418 = call i32 @cqrt_pop()
  %419 = call i32 @cqrt_pop()
  %420 = call i32 @cqrt_pop()
  %421 = call i32 @cqrt_pop()
  %422 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %422, i32 %421, i32 %420, i32 %419)
  call void @cqrt_free(i32 %422)
  call void @cq_template_select_i64_unc(i32 %418, i32 %421, i32 %417, i32 %416)
  call void @cqrt_free(i32 %418)
  call void @cq_template_select_i64_unc(i32 %415, i32 %421, i32 %414, i32 %413)
  call void @cqrt_free(i32 %415)
  call void @cq_template_add_i64_hl_unc(i32 %412, i32 %411, i64 %410)
  call void @cqrt_free(i32 %412)
  call void @cqrt_and_i1(i32 %421, i32 %403, i32 %402)
  call void @cqrt_free(i32 %402)
  call void @cqrt_xor_i1(i32 %401, i32 %403)
  call void @cqrt_not_i1(i32 %403)
  call void @cqrt_free(i32 %403)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %401, i32 %400, i64 0)
  call void @cqrt_free(i32 %401)
  call void @cq_template_add_i64_hl_unc(i32 %400, i32 %399, i64 -1)
  call void @cqrt_free(i32 %400)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %420, i32 %421, i32 %12, i32 %417)
  call void @cq_template_add_i64_hl_unc(i32 %414, i32 %413, i64 8)
  call void @cqrt_free(i32 %414)
  call void @cq_template_add_i64_hl_unc(i32 %417, i32 %416, i64 8)
  call void @cqrt_free(i32 %417)
  %423 = call i32 @cqrt_pop()
  switch i32 %423, label %398 [
    i32 1, label %360
  ]

424:                                              ; preds = %462, %360
  %425 = call i32 @cqrt_pop()
  %426 = call i32 @cqrt_pop()
  %427 = call i32 @cqrt_pop()
  %428 = call i32 @cqrt_pop()
  %429 = call i32 @cqrt_pop()
  %430 = call i32 @cqrt_pop()
  %431 = call i32 @cqrt_pop()
  %432 = call i32 @cqrt_pop()
  %433 = call i32 @cqrt_pop()
  %434 = call i32 @cqrt_pop()
  %435 = call i32 @cqrt_pop()
  %436 = call i32 @cqrt_pop()
  %437 = call i32 @cqrt_pop()
  %438 = call i32 @cqrt_pop()
  %439 = call i32 @cqrt_pop()
  %440 = call i32 @cqrt_pop()
  %441 = zext i32 %440 to i64
  %442 = shl i64 %441, 32
  %443 = or i64 0, %442
  %444 = call i32 @cqrt_pop()
  %445 = zext i32 %444 to i64
  %446 = or i64 %443, %445
  %447 = call i32 @cqrt_pop()
  %448 = call i32 @cqrt_pop()
  %449 = call i32 @cqrt_pop()
  %450 = call i32 @cqrt_pop()
  %451 = call i32 @cqrt_pop()
  %452 = call i32 @cqrt_pop()
  %453 = call i32 @cqrt_pop()
  %454 = call i32 @cqrt_pop()
  %455 = call i32 @cqrt_pop()
  %456 = call i32 @cqrt_pop()
  %457 = call i32 @cqrt_pop()
  %458 = call i32 @cqrt_pop()
  %459 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %459, i32 %458, i32 %457, i32 %456)
  call void @cqrt_free(i32 %459)
  call void @cq_template_select_i64_unc(i32 %455, i32 %458, i32 %454, i32 %453)
  call void @cqrt_free(i32 %455)
  call void @cq_template_select_i64_unc(i32 %452, i32 %458, i32 %451, i32 %450)
  call void @cqrt_free(i32 %452)
  call void @cqrt_and_i1(i32 %458, i32 %449, i32 %448)
  call void @cqrt_free(i32 %448)
  call void @cqrt_xor_i1(i32 %447, i32 %449)
  call void @cqrt_not_i1(i32 %449)
  call void @cqrt_free(i32 %449)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %447, i32 %2, i64 %446)
  call void @cqrt_free(i32 %447)
  call void @cq_template_add_i64_unc(i32 %451, i32 %450, i32 %439)
  call void @cqrt_free(i32 %451)
  call void @cq_template_mul_i64_hl_unc(i32 %439, i32 %203, i64 8)
  call void @cqrt_free(i32 %439)
  call void @cq_template_select_i64_unc(i32 %454, i32 %438, i32 %437, i32 %453)
  call void @cqrt_free(i32 %454)
  call void @cq_template_select_i64_unc(i32 %457, i32 %438, i32 %436, i32 %456)
  call void @cqrt_free(i32 %457)
  call void @cq_template_add_i64_unc(i32 %437, i32 %453, i32 %435)
  call void @cqrt_free(i32 %437)
  call void @cq_template_mul_i64_hl_unc(i32 %435, i32 %6, i64 8)
  call void @cqrt_free(i32 %435)
  call void @cqrt_and_i1(i32 %458, i32 %434, i32 %433)
  call void @cqrt_free(i32 %433)
  call void @cqrt_and_i1(i32 %438, i32 %432, i32 %434)
  call void @cqrt_xor_i1(i32 %438, i32 %434)
  call void @cqrt_free(i32 %434)
  call void @cq_template_shl_i64_hl_unc(i32 %431, i32 %430, i64 3)
  call void @cqrt_free(i32 %431)
  call void @cq_template_add_i64_unc(i32 %429, i32 %8, i32 %428)
  call void @cqrt_free(i32 %429)
  call void @cq_template_mul_i64_hl_unc(i32 %428, i32 %427, i64 8)
  call void @cqrt_free(i32 %428)
  call void @cq_template_sub_i64_unc(i32 %430, i32 %202, i32 %427)
  call void @cqrt_free(i32 %430)
  call void @cq_template_icmp_eq_i64_unc(i32 %432, i32 %202, i32 %427)
  call void @cqrt_free(i32 %432)
  call void @cqrt_and_i1(i32 %438, i32 %426, i32 %425)
  call void @cqrt_xor_i1(i32 %438, i32 %425)
  call void @cqrt_free(i32 %425)
  %460 = call i32 @cqrt_pop()
  switch i32 %460, label %398 [
    i32 1, label %360
  ]

461:                                              ; preds = %352
  call void @cqrt_copy_i64(i32 %240, i32 %244)
  call void @cqrt_free(i32 %244)
  br label %462

462:                                              ; preds = %461
  switch i32 %237, label %359 [
    i32 1, label %424
  ]

463:                                              ; preds = %520, %464
  br label %356

464:                                              ; preds = %520, %499
  %465 = call i32 @cqrt_pop()
  %466 = call i32 @cqrt_pop()
  %467 = call i32 @cqrt_pop()
  %468 = call i32 @cqrt_pop()
  %469 = call i32 @cqrt_pop()
  %470 = call i32 @cqrt_pop()
  %471 = call i32 @cqrt_pop()
  %472 = call i32 @cqrt_pop()
  %473 = call i32 @cqrt_pop()
  %474 = call i32 @cqrt_pop()
  %475 = call i32 @cqrt_pop()
  %476 = call i32 @cqrt_pop()
  %477 = call i32 @cqrt_pop()
  %478 = call i32 @cqrt_pop()
  %479 = call i32 @cqrt_pop()
  %480 = call i32 @cqrt_pop()
  %481 = call i32 @cqrt_pop()
  %482 = call i32 @cqrt_pop()
  %483 = call i32 @cqrt_pop()
  %484 = call i32 @cqrt_pop()
  %485 = call i32 @cqrt_pop()
  %486 = call i32 @cqrt_pop()
  %487 = call i32 @cqrt_pop()
  %488 = call i32 @cqrt_pop()
  %489 = call i32 @cqrt_pop()
  %490 = call i32 @cqrt_pop()
  %491 = zext i32 %490 to i64
  %492 = shl i64 %491, 32
  %493 = or i64 0, %492
  %494 = call i32 @cqrt_pop()
  %495 = zext i32 %494 to i64
  %496 = or i64 %493, %495
  %497 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %497, i32 %18, i64 %496)
  call void @cqrt_free(i32 %497)
  call void @cqrt_and_i1(i32 %489, i32 %488, i32 %487)
  call void @cqrt_free(i32 %487)
  call void @cqrt_and_i1(i32 %486, i32 %485, i32 %488)
  call void @cqrt_free(i32 %488)
  call void @cq_template_select_i1_unc(i32 %484, i32 %483, i32 %482, i32 %481)
  call void @cqrt_free(i32 %484)
  call void @cqrt_and_i1(i32 %489, i32 %480, i32 %483)
  call void @cqrt_free(i32 %483)
  call void @cqrt_and_i1(i32 %485, i32 %486, i32 %480)
  call void @cqrt_xor_i1(i32 %485, i32 %480)
  call void @cqrt_free(i32 %480)
  call void @cqrt_free(i32 %482)
  call void @cq_template_select_i64_unc(i32 %479, i32 %478, i32 %477, i32 %476)
  call void @cqrt_free(i32 %479)
  call void @cqrt_and_i1(i32 %489, i32 %475, i32 %478)
  call void @cqrt_free(i32 %478)
  call void @cqrt_and_i1(i32 %485, i32 %486, i32 %475)
  call void @cqrt_xor_i1(i32 %485, i32 %475)
  call void @cqrt_free(i32 %475)
  call void @cq_template_select_i64_unc(i32 %474, i32 %473, i32 %472, i32 %471)
  call void @cqrt_free(i32 %474)
  call void @cqrt_and_i1(i32 %489, i32 %470, i32 %473)
  call void @cqrt_free(i32 %473)
  call void @cqrt_and_i1(i32 %485, i32 %486, i32 %470)
  call void @cqrt_xor_i1(i32 %485, i32 %470)
  call void @cqrt_free(i32 %470)
  call void @cqrt_free(i32 %472)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %486, i32 %469, i64 0)
  call void @cqrt_free(i32 %486)
  call void @cq_template_add_i64_hl_unc(i32 %477, i32 %468, i64 1)
  call void @cqrt_free(i32 %477)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %469, i32 %467, i32 %12, i32 %466)
  call void @cq_template_add_i64_unc(i32 %466, i32 %4, i32 %465)
  call void @cqrt_free(i32 %466)
  call void @cq_template_mul_i64_hl_unc(i32 %465, i32 %468, i64 8)
  call void @cqrt_free(i32 %465)
  %498 = call i32 @cqrt_pop()
  switch i32 %498, label %499 [
    i32 1, label %463
  ]

499:                                              ; preds = %464
  %500 = call i32 @cqrt_pop()
  %501 = call i32 @cqrt_pop()
  %502 = call i32 @cqrt_pop()
  %503 = call i32 @cqrt_pop()
  %504 = call i32 @cqrt_pop()
  %505 = call i32 @cqrt_pop()
  %506 = call i32 @cqrt_pop()
  %507 = call i32 @cqrt_pop()
  %508 = call i32 @cqrt_pop()
  %509 = call i32 @cqrt_pop()
  %510 = call i32 @cqrt_pop()
  %511 = call i32 @cqrt_pop()
  %512 = call i32 @cqrt_pop()
  %513 = call i32 @cqrt_pop()
  %514 = call i32 @cqrt_pop()
  %515 = call i32 @cqrt_pop()
  %516 = call i32 @cqrt_pop()
  %517 = call i32 @cqrt_pop()
  %518 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %518, i32 %517, i32 %516)
  call void @cqrt_free(i32 %516)
  call void @cq_template_select_i1_unc(i32 %515, i32 %514, i32 %513, i32 %512)
  call void @cqrt_free(i32 %515)
  call void @cqrt_and_i1(i32 %518, i32 %511, i32 %514)
  call void @cqrt_free(i32 %514)
  call void @cqrt_xor_i1(i32 %517, i32 %511)
  call void @cqrt_not_i1(i32 %511)
  call void @cqrt_free(i32 %511)
  call void @cqrt_free(i32 %513)
  call void @cq_template_select_i64_unc(i32 %510, i32 %509, i32 %508, i32 %507)
  call void @cqrt_free(i32 %510)
  call void @cqrt_and_i1(i32 %518, i32 %506, i32 %509)
  call void @cqrt_free(i32 %509)
  call void @cqrt_xor_i1(i32 %517, i32 %506)
  call void @cqrt_not_i1(i32 %506)
  call void @cqrt_free(i32 %506)
  call void @cqrt_free(i32 %508)
  call void @cq_template_select_i64_unc(i32 %505, i32 %504, i32 %503, i32 %502)
  call void @cqrt_free(i32 %505)
  call void @cqrt_and_i1(i32 %518, i32 %501, i32 %504)
  call void @cqrt_free(i32 %504)
  call void @cqrt_xor_i1(i32 %517, i32 %501)
  call void @cqrt_not_i1(i32 %501)
  call void @cqrt_free(i32 %501)
  call void @cqrt_free(i32 %503)
  call void @cq_template_icmp_slt_i64_unc(i32 %517, i32 %500, i32 %14)
  call void @cqrt_free(i32 %517)
  br label %464

519:                                              ; preds = %355
  call void @cqrt_copy_i1(i32 %103, i32 %108)
  call void @cqrt_free(i32 %108)
  call void @cqrt_copy_i64(i32 %102, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cqrt_copy_i64(i32 %101, i32 %106)
  call void @cqrt_free(i32 %106)
  br label %520

520:                                              ; preds = %519
  switch i32 %97, label %463 [
    i32 1, label %464
  ]
}

declare i32 @cq_template_mul_i64(i32, i32)

declare i32 @cq_template_icmp_slt_i64(i32, i32)

declare i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl(i32, i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i64(i32, i32)

declare void @cqrt_copy_i64_controlled(i32, i32, i32)

declare i32 @__cq_q___gmpn_sub_n_1111_t_ctl(i32, i32, i32, i32, i32, i32)

declare i32 @cq_template_select_i1(i32, i32, i32)

declare i32 @cq_template_icmp_ne_i64(i32, i32)

declare void @cq_template_mul_i64_unc(i32, i32, i32)

declare i32 @cq_template_icmp_sge_i64(i32, i32)

declare i32 @cq_template_select_i1_hl(i32, i32, i1)

declare i32 @cq_template_icmp_eq_i64(i32, i32)

declare void @cq_template_icmp_eq_i64_unc(i32, i32, i32)

declare void @cq_template_select_i1_hl_unc(i32, i32, i32, i1)

declare void @cq_template_icmp_sge_i64_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i64_unc(i32, i32, i32)

declare void @cq_template_icmp_ne_i64_unc(i32, i32, i32)

declare void @cq_template_select_i1_unc(i32, i32, i32, i32)

declare void @__cq_q___gmpn_sub_n_1111_t_ctl_unc(i32, i32, i32, i32, i32, i32, i32)

declare void @cq_template_icmp_sgt_i64_unc(i32, i32, i32)

declare void @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl_unc(i32, i32, i32, i32, i32)

define void @__cq_q_mpn_mul_fft_decompose_111111111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10) {
  %12 = load i32, ptr @__cq_k, align 4
  store i32 %10, ptr @__cq_k, align 4
  %13 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %14 = add i32 %13, 1
  store i32 %14, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %15 = icmp ult i32 %13, %10
  br i1 %15, label %16, label %539

16:                                               ; preds = %11
  %17 = call i32 @__cq_mem()
  %18 = call ptr @__cq_alloc(i64 8, i64 8)
  %19 = call i32 @cq_template_mul_i64(i32 %7, i32 %3)
  %20 = ptrtoint ptr %18 to i64
  %21 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %17, i64 %20, i32 %21)
  %22 = call i32 @cq_template_icmp_slt_i64(i32 %19, i32 %6)
  %23 = call i32 @cq_template_sub_i64(i32 %6, i32 %19)
  %24 = call i32 @cq_template_add_i64_hl(i32 %19, i64 1)
  %25 = call i32 @cq_template_shl_i64_hl(i32 %24, i64 3)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %26)
  %27 = ptrtoint ptr %18 to i64
  %28 = call i32 @cqrt_alloc_i64(i64 %27)
  %29 = call i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl(i32 %26, i32 %28, i32 %25, i32 %10)
  %30 = call i32 @cq_template_mul_i64_hl(i32 %19, i64 8)
  %31 = call i32 @cq_template_add_i64(i32 %29, i32 %30)
  %32 = call i32 @cqrt_alloc_i64(i64 0)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %33)
  call void @cqrt_qram_store_i64_controlled(i32 %33, i32 %17, i32 %31, i32 %32)
  call void @cq_template_add_i64_unc(i32 %31, i32 %29, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cq_template_mul_i64_hl_unc(i32 %30, i32 %19, i64 8)
  call void @cqrt_free(i32 %30)
  %34 = call i32 @cq_template_icmp_sgt_i64(i32 %23, i32 %19)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %34, i32 %22, i32 %36)
  call void @cqrt_and_i1(i32 %0, i32 %36, i32 %35)
  call void @cqrt_and_i1(i32 %34, i32 %22, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_sgt_i64_unc(i32 %34, i32 %23, i32 %19)
  call void @cqrt_free(i32 %34)
  %37 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64_controlled(i32 %35, i32 %23, i32 %37)
  %38 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64_controlled(i32 %35, i32 %4, i32 %38)
  call void @cqrt_abort_i1(i32 %35)
  %39 = call i32 @cq_template_icmp_eq_i64_hl(i32 %23, i64 0)
  %40 = call i32 @cq_template_mul_i64_hl(i32 %19, i64 8)
  %41 = call i32 @cq_template_add_i64(i32 %5, i32 %40)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %43)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %43)
  call void @cqrt_and_i1(i32 %0, i32 %43, i32 %42)
  %44 = call i32 @__cq_q___gmpn_sub_n_1111_t_ctl(i32 %42, i32 %29, i32 %5, i32 %41, i32 %23, i32 %10)
  %45 = call i32 @cq_template_icmp_eq_i64_hl(i32 %44, i64 0)
  br label %46

46:                                               ; preds = %16
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %49)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %49)
  call void @cqrt_xor_i1(i32 %49, i32 %48)
  call void @cqrt_and_i1(i32 %49, i32 %45, i32 %48)
  call void @cqrt_and_i1(i32 %0, i32 %48, i32 %47)
  %50 = call i32 @cqrt_alloc_i64(i64 0)
  %51 = call i32 @cqrt_alloc_i64(i64 0)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  %53 = call i32 @cq_template_icmp_slt_i64(i32 %23, i32 %19)
  %54 = call i32 @cqrt_alloc_i64(i64 1)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_xor_i1(i32 %53, i32 %55)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %55, i32 %56)
  %57 = call i32 @cq_template_select_i64(i32 %56, i32 %54, i32 %50)
  %58 = call i32 @cqrt_alloc_i64(i64 0)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %59)
  call void @cqrt_xor_i1(i32 %53, i32 %59)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %59, i32 %60)
  %61 = call i32 @cq_template_select_i64(i32 %60, i32 %58, i32 %51)
  %62 = call i32 @cqrt_alloc_i1(i1 true)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %63)
  call void @cqrt_xor_i1(i32 %53, i32 %63)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %63, i32 %64)
  %65 = call i32 @cq_template_select_i1(i32 %64, i32 %62, i32 %52)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %53, i32 %66)
  %67 = icmp ult i32 0, %10
  br i1 %67, label %68, label %106

68:                                               ; preds = %119, %46
  %from4 = phi i32 [ 0, %119 ], [ 1, %46 ]
  %69 = phi i32 [ 0, %46 ], [ %101, %119 ]
  %70 = phi i32 [ %66, %46 ], [ %133, %119 ]
  %71 = phi i32 [ %23, %46 ], [ %100, %119 ]
  %72 = phi i64 [ 0, %46 ], [ %99, %119 ]
  %73 = phi i32 [ %53, %46 ], [ %120, %119 ]
  %74 = phi i32 [ %57, %46 ], [ %124, %119 ]
  %75 = phi i32 [ %61, %46 ], [ %128, %119 ]
  %76 = phi i32 [ %65, %46 ], [ %132, %119 ]
  call void @cqrt_push(i32 %from4)
  %77 = call i32 @cq_template_mul_i64_hl(i32 %71, i64 8)
  %78 = call i32 @cq_template_add_i64(i32 %5, i32 %77)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %70, i32 %73, i32 %79)
  %80 = call i32 @cqrt_qram_load_i64_controlled(i32 %79, i32 %17, i32 %78)
  %81 = call i32 @cq_template_add_i64_hl(i32 %80, i64 -1)
  %82 = call i32 @cq_template_add_i64_hl(i32 %71, i64 1)
  %83 = call i32 @cq_template_mul_i64_hl(i32 %71, i64 8)
  %84 = call i32 @cq_template_add_i64(i32 %29, i32 %83)
  call void @cqrt_qram_store_i64_controlled(i32 %79, i32 %17, i32 %84, i32 %81)
  call void @cq_template_add_i64_unc(i32 %84, i32 %29, i32 %83)
  call void @cqrt_free(i32 %84)
  call void @cq_template_mul_i64_hl_unc(i32 %83, i32 %71, i64 8)
  call void @cqrt_free(i32 %83)
  %85 = call i32 @cq_template_icmp_eq_i64_hl(i32 %80, i64 0)
  %86 = call i32 @cqrt_alloc_i64(i64 0)
  %87 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %73, i32 %87)
  call void @cqrt_and_i1(i32 %73, i32 %85, i32 %87)
  %88 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %70, i32 %87, i32 %88)
  %89 = call i32 @cq_template_select_i64(i32 %88, i32 %86, i32 %74)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %73, i32 %90)
  call void @cqrt_and_i1(i32 %73, i32 %85, i32 %90)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %70, i32 %90, i32 %91)
  %92 = call i32 @cq_template_select_i64(i32 %91, i32 %82, i32 %75)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %73, i32 %94)
  call void @cqrt_and_i1(i32 %73, i32 %85, i32 %94)
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %70, i32 %94, i32 %95)
  %96 = call i32 @cq_template_select_i1(i32 %95, i32 %93, i32 %76)
  %97 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %73, i32 %97)
  %98 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %70, i32 %97, i32 %98)
  %99 = add i64 %72, 1
  %100 = call i32 @cq_template_add_i64_hl(i32 %23, i64 %99)
  %101 = add i32 %69, 1
  %102 = icmp ult i32 %101, %10
  call void @cqrt_push(i32 %100)
  %103 = trunc i64 %99 to i32
  call void @cqrt_push(i32 %103)
  %104 = lshr i64 %99, 32
  %105 = trunc i64 %104 to i32
  call void @cqrt_push(i32 %105)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %77)
  br i1 %102, label %119, label %106

106:                                              ; preds = %68, %46
  %107 = phi i32 [ 0, %46 ], [ 1, %68 ]
  %108 = phi i32 [ %23, %46 ], [ %100, %68 ]
  %109 = phi i64 [ 0, %46 ], [ %99, %68 ]
  %110 = phi i32 [ %53, %46 ], [ %73, %68 ]
  %111 = phi i32 [ %57, %46 ], [ %89, %68 ]
  %112 = phi i32 [ %61, %46 ], [ %92, %68 ]
  %113 = phi i32 [ %65, %46 ], [ %96, %68 ]
  %114 = phi i32 [ %66, %46 ], [ %98, %68 ]
  %115 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %114, i32 %115)
  %116 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %111, i32 %116)
  %117 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %112, i32 %117)
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %113, i32 %118)
  br label %134

119:                                              ; preds = %68
  %120 = call i32 @cq_template_icmp_slt_i64(i32 %100, i32 %19)
  %121 = call i32 @cqrt_alloc_i64(i64 1)
  %122 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %122)
  call void @cqrt_xor_i1(i32 %120, i32 %122)
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %98, i32 %122, i32 %123)
  %124 = call i32 @cq_template_select_i64(i32 %123, i32 %121, i32 %89)
  %125 = call i32 @cqrt_alloc_i64(i64 0)
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %126)
  call void @cqrt_xor_i1(i32 %120, i32 %126)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %98, i32 %126, i32 %127)
  %128 = call i32 @cq_template_select_i64(i32 %127, i32 %125, i32 %92)
  %129 = call i32 @cqrt_alloc_i1(i1 true)
  %130 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %130)
  call void @cqrt_xor_i1(i32 %120, i32 %130)
  %131 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %98, i32 %130, i32 %131)
  %132 = call i32 @cq_template_select_i1(i32 %131, i32 %129, i32 %96)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %98, i32 %120, i32 %133)
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %133)
  call void @cqrt_push(i32 %132)
  call void @cqrt_push(i32 %131)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %128)
  call void @cqrt_push(i32 %127)
  call void @cqrt_push(i32 %125)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %126)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %123)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %122)
  call void @cqrt_push(i32 %100)
  br label %68

134:                                              ; preds = %106
  %135 = call i32 @cq_template_select_i64(i32 %45, i32 %23, i32 %117)
  %136 = call i32 @cq_template_select_i64_lh(i32 %39, i64 0, i32 %135)
  %137 = call i32 @cq_template_icmp_ne_i64(i32 %29, i32 %5)
  %138 = call i32 @cq_template_icmp_slt_i64(i32 %136, i32 %19)
  %139 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %137, i32 %138, i32 %139)
  %140 = call i32 @cq_template_shl_i64_hl(i32 %136, i64 3)
  %141 = call i32 @cq_template_add_i64(i32 %29, i32 %140)
  %142 = call i32 @cq_template_add_i64(i32 %5, i32 %140)
  %143 = call i32 @cq_template_mul_i64(i32 %7, i32 %3)
  %144 = call i32 @cq_template_sub_i64(i32 %143, i32 %136)
  %145 = call i32 @cq_template_shl_i64_hl(i32 %144, i64 3)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %148)
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  %150 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %150)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %150)
  call void @cqrt_xor_i1(i32 %150, i32 %149)
  call void @cqrt_and_i1(i32 %150, i32 %45, i32 %149)
  call void @cqrt_and_i1(i32 %118, i32 %149, i32 %148)
  call void @cqrt_and_i1(i32 %139, i32 %148, i32 %147)
  call void @cqrt_and_i1(i32 %0, i32 %147, i32 %146)
  %151 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %145, i64 4096)
  %152 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %151, i32 %146, i32 %152)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %151, i32 %145, i64 4096)
  call void @cqrt_free(i32 %151)
  br label %153

153:                                              ; preds = %153, %134
  %154 = phi i64 [ 0, %134 ], [ %159, %153 ]
  %155 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %145, i64 %154)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %155, i32 %146, i32 %156)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %155, i32 %145, i64 %154)
  call void @cqrt_free(i32 %155)
  %157 = call i32 @cq_template_add_i64_hl(i32 %142, i64 %154)
  %158 = call i32 @cqrt_qram_load_i8_controlled(i32 %156, i32 %17, i32 %157)
  call void @cq_template_add_i64_hl_unc(i32 %157, i32 %142, i64 %154)
  call void @cqrt_free(i32 %157)
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %158)
  %159 = add nuw i64 %154, 1
  %160 = icmp eq i64 %159, 4096
  br i1 %160, label %161, label %153

161:                                              ; preds = %153
  call void @cq_template_shl_i64_hl_unc(i32 %145, i32 %144, i64 3)
  call void @cqrt_free(i32 %145)
  call void @cq_template_sub_i64_unc(i32 %144, i32 %143, i32 %136)
  call void @cqrt_free(i32 %144)
  call void @cq_template_mul_i64_unc(i32 %143, i32 %7, i32 %3)
  call void @cqrt_free(i32 %143)
  call void @cq_template_add_i64_unc(i32 %142, i32 %5, i32 %140)
  call void @cqrt_free(i32 %142)
  br label %162

162:                                              ; preds = %161
  br label %163

163:                                              ; preds = %163, %162
  %164 = phi i64 [ 4095, %162 ], [ %168, %163 ]
  %165 = call i32 @cqrt_pop()
  %166 = call i32 @cqrt_pop()
  %167 = call i32 @cq_template_add_i64_hl(i32 %141, i64 %164)
  call void @cqrt_qram_store_i8_controlled(i32 %166, i32 %17, i32 %167, i32 %165)
  call void @cq_template_add_i64_hl_unc(i32 %167, i32 %141, i64 %164)
  call void @cqrt_free(i32 %167)
  %168 = add nsw i64 %164, -1
  %169 = icmp eq i64 %164, 0
  br i1 %169, label %170, label %163

170:                                              ; preds = %163
  call void @cq_template_add_i64_unc(i32 %141, i32 %29, i32 %140)
  call void @cqrt_free(i32 %141)
  call void @cq_template_shl_i64_hl_unc(i32 %140, i32 %136, i64 3)
  call void @cqrt_free(i32 %140)
  br label %171

171:                                              ; preds = %170
  %172 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %172)
  %173 = call i32 @cqrt_alloc_i1(i1 false)
  %174 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %174)
  call void @cqrt_xor_i1(i32 %39, i32 %174)
  call void @cqrt_xor_i1(i32 %174, i32 %173)
  call void @cqrt_and_i1(i32 %174, i32 %45, i32 %173)
  call void @cqrt_and_i1(i32 %118, i32 %173, i32 %172)
  %175 = call i32 @cq_template_select_i64_lh(i32 %172, i64 0, i32 %116)
  %176 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %176)
  %177 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %176, i32 %17, i32 %29, i32 %177)
  %178 = call i32 @cq_template_add_i64(i32 %177, i32 %175)
  %179 = call i32 @cq_template_select_i64(i32 %176, i32 %178, i32 %177)
  call void @cq_template_add_i64_unc(i32 %178, i32 %177, i32 %175)
  call void @cqrt_free(i32 %178)
  %180 = call i32 @cq_template_sub_i64(i32 %179, i32 %175)
  %181 = call i32 @cq_template_select_i64(i32 %176, i32 %180, i32 %179)
  call void @cqrt_copy_i64(i32 %181, i32 %177)
  call void @cq_template_select_i64_unc(i32 %181, i32 %176, i32 %180, i32 %179)
  call void @cqrt_free(i32 %181)
  call void @cq_template_sub_i64_unc(i32 %180, i32 %179, i32 %175)
  call void @cqrt_free(i32 %180)
  call void @cqrt_free(i32 %177)
  call void @cqrt_qram_swap_i64_controlled(i32 %176, i32 %17, i32 %29, i32 %179)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %176)
  call void @cqrt_free(i32 %176)
  call void @cqrt_free(i32 %179)
  %182 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %182)
  %183 = call i32 @cqrt_qram_load_i64_controlled(i32 %182, i32 %17, i32 %29)
  %184 = call i32 @cq_template_icmp_ult_i64(i32 %183, i32 %175)
  br label %185

185:                                              ; preds = %171
  %186 = call i32 @cqrt_alloc_i1(i1 false)
  %187 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %184, i32 %22, i32 %187)
  call void @cqrt_and_i1(i32 %0, i32 %187, i32 %186)
  %188 = icmp ult i32 0, %10
  br i1 %188, label %189, label %205

189:                                              ; preds = %189, %185
  %from = phi i32 [ 0, %189 ], [ 1, %185 ]
  %190 = phi i32 [ 0, %185 ], [ %203, %189 ]
  %191 = phi i32 [ %186, %185 ], [ %201, %189 ]
  %192 = phi i32 [ %29, %185 ], [ %202, %189 ]
  call void @cqrt_push(i32 %from)
  %193 = call i32 @cq_template_add_i64_hl(i32 %192, i64 8)
  %194 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %191, i32 %17, i32 %193, i32 %194)
  %195 = call i32 @cq_template_add_i64_hl(i32 %194, i64 1)
  %196 = call i32 @cq_template_select_i64(i32 %191, i32 %195, i32 %194)
  call void @cq_template_add_i64_hl_unc(i32 %195, i32 %194, i64 1)
  call void @cqrt_free(i32 %195)
  %197 = call i32 @cq_template_sub_i64_hl(i32 %196, i64 1)
  %198 = call i32 @cq_template_select_i64(i32 %191, i32 %197, i32 %196)
  call void @cqrt_copy_i64(i32 %198, i32 %194)
  call void @cq_template_select_i64_unc(i32 %198, i32 %191, i32 %197, i32 %196)
  call void @cqrt_free(i32 %198)
  call void @cq_template_sub_i64_hl_unc(i32 %197, i32 %196, i64 1)
  call void @cqrt_free(i32 %197)
  call void @cqrt_free(i32 %194)
  call void @cqrt_qram_swap_i64_controlled(i32 %191, i32 %17, i32 %193, i32 %196)
  call void @cqrt_free(i32 %196)
  %199 = call i32 @cqrt_qram_load_i64_controlled(i32 %191, i32 %17, i32 %193)
  %200 = call i32 @cq_template_icmp_eq_i64_hl(i32 %199, i64 0)
  %201 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %191, i32 %200, i32 %201)
  %202 = call i32 @cq_template_select_i64(i32 %191, i32 %193, i32 %192)
  %203 = add i32 %190, 1
  %204 = icmp ult i32 %203, %10
  call void @cqrt_push(i32 %202)
  call void @cqrt_push(i32 %191)
  call void @cqrt_push(i32 %193)
  call void @cqrt_push(i32 %192)
  call void @cqrt_push(i32 %200)
  call void @cqrt_push(i32 %201)
  call void @cqrt_push(i32 %199)
  br i1 %204, label %189, label %205

205:                                              ; preds = %189, %185
  %206 = phi i32 [ 0, %185 ], [ 1, %189 ]
  %207 = phi i32 [ %29, %185 ], [ %202, %189 ]
  %208 = phi i32 [ %186, %185 ], [ %201, %189 ]
  %209 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %208, i32 %209)
  br label %229

210:                                              ; preds = %229, %220
  %211 = call i32 @cq_template_select_i64(i32 %22, i32 %24, i32 %6)
  %212 = call i32 @cq_template_select_i64(i32 %22, i32 %29, i32 %5)
  %213 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %3, i64 0)
  %214 = call i32 @cq_template_icmp_eq_i64_hl(i32 %4, i64 -1)
  %215 = call i32 @cq_template_add_i64_hl(i32 %3, i64 -1)
  %216 = call i32 @cq_template_add_i64_hl(i32 %4, i64 1)
  %217 = call i32 @cq_template_add_i64_hl(i32 %4, i64 1)
  %218 = call i32 @cq_template_shl_i64_hl(i32 %4, i64 3)
  %219 = call i32 @cq_template_add_i64_hl(i32 %218, i64 8)
  br label %230

220:                                              ; preds = %229, %220
  %221 = call i32 @cqrt_pop()
  %222 = call i32 @cqrt_pop()
  %223 = call i32 @cqrt_pop()
  %224 = call i32 @cqrt_pop()
  %225 = call i32 @cqrt_pop()
  %226 = call i32 @cqrt_pop()
  %227 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %227, i32 %226, i32 %225, i32 %224)
  call void @cqrt_free(i32 %227)
  call void @cqrt_and_i1(i32 %226, i32 %223, i32 %222)
  call void @cqrt_free(i32 %222)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %223, i32 %221, i64 0)
  call void @cqrt_free(i32 %223)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %221, i32 %226, i32 %17, i32 %225)
  call void @cq_template_add_i64_hl_unc(i32 %225, i32 %224, i64 8)
  call void @cqrt_free(i32 %225)
  %228 = call i32 @cqrt_pop()
  switch i32 %228, label %220 [
    i32 1, label %210
  ]

229:                                              ; preds = %205
  switch i32 %206, label %210 [
    i32 1, label %220
  ]

230:                                              ; preds = %210
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %213, i32 %231)
  %232 = icmp ult i32 0, %10
  br i1 %232, label %233, label %251

233:                                              ; preds = %346, %230
  %from3 = phi i32 [ 0, %346 ], [ 1, %230 ]
  %234 = phi i32 [ 0, %230 ], [ %362, %346 ]
  %235 = phi i32 [ %231, %230 ], [ %358, %346 ]
  %236 = phi i32 [ %1, %230 ], [ %359, %346 ]
  %237 = phi i32 [ %212, %230 ], [ %360, %346 ]
  %238 = phi i32 [ %211, %230 ], [ %361, %346 ]
  %239 = phi i64 [ 0, %230 ], [ %355, %346 ]
  %240 = mul i64 %239, 8
  %241 = call i32 @cq_template_add_i64_hl(i32 %2, i64 %240)
  %242 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %236, i32 %242)
  %243 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %235, i32 %243)
  call void @cqrt_qram_store_i64_controlled(i32 %243, i32 %17, i32 %241, i32 %242)
  %244 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %238, i64 0)
  %245 = call i32 @cqrt_alloc_i1(i1 false)
  %246 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %246)
  call void @cqrt_xor_i1(i32 %244, i32 %246)
  call void @cqrt_xor_i1(i32 %246, i32 %245)
  call void @cqrt_and_i1(i32 %246, i32 %214, i32 %245)
  %247 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %245, i32 %247)
  %248 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %219, i64 4096)
  %249 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %248, i32 %247, i32 %249)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %248, i32 %219, i64 4096)
  call void @cqrt_free(i32 %248)
  %250 = call i32 @cqrt_alloc_i8(i8 0)
  br label %260

251:                                              ; preds = %346, %230
  %252 = phi i32 [ 0, %230 ], [ 1, %346 ]
  %253 = phi i32 [ %1, %230 ], [ %359, %346 ]
  %254 = phi i32 [ %212, %230 ], [ %360, %346 ]
  %255 = phi i32 [ %211, %230 ], [ %361, %346 ]
  %256 = phi i64 [ 0, %230 ], [ %355, %346 ]
  %257 = phi i32 [ %231, %230 ], [ %358, %346 ]
  %258 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %257, i32 %258)
  %259 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %255, i32 %259)
  br label %367

260:                                              ; preds = %260, %233
  %261 = phi i64 [ 0, %233 ], [ %265, %260 ]
  %262 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %219, i64 %261)
  %263 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %262, i32 %247, i32 %263)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %262, i32 %219, i64 %261)
  call void @cqrt_free(i32 %262)
  %264 = call i32 @cq_template_add_i64_hl(i32 %236, i64 %261)
  call void @cqrt_qram_store_i8_controlled(i32 %263, i32 %17, i32 %264, i32 %250)
  call void @cq_template_add_i64_hl_unc(i32 %264, i32 %236, i64 %261)
  call void @cqrt_free(i32 %264)
  %265 = add nuw i64 %261, 1
  %266 = icmp eq i64 %265, 4096
  br i1 %266, label %267, label %260

267:                                              ; preds = %260
  br label %268

268:                                              ; preds = %267
  call void @cqrt_push(i32 %from3)
  %269 = call i32 @cq_template_icmp_sge_i64(i32 %238, i32 %7)
  %270 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %215, i64 %239)
  %271 = call i32 @cq_template_select_i1_hl(i32 %269, i32 %270, i1 false)
  %272 = call i32 @cq_template_select_i64(i32 %271, i32 %7, i32 %238)
  %273 = call i32 @cq_template_sub_i64(i32 %238, i32 %272)
  %274 = call i32 @cq_template_icmp_eq_i64_hl(i32 %272, i64 0)
  %275 = call i32 @cq_template_add_i64_hl(i32 %272, i64 -1)
  %276 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %244, i32 %276)
  call void @cqrt_and_i1(i32 %244, i32 %274, i32 %276)
  %277 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %276, i32 %277)
  %278 = call i32 @cqrt_qram_load_i64_controlled(i32 %277, i32 %17, i32 %237)
  %279 = call i32 @cq_template_icmp_eq_i64_hl(i32 %275, i64 0)
  %280 = call i32 @cqrt_alloc_i1(i1 false)
  %281 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %244, i32 %281)
  call void @cqrt_and_i1(i32 %244, i32 %274, i32 %281)
  call void @cqrt_xor_i1(i32 %281, i32 %280)
  call void @cqrt_and_i1(i32 %281, i32 %279, i32 %280)
  %282 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %280, i32 %282)
  %283 = icmp ult i32 0, %10
  call void @cqrt_push(i32 %235)
  call void @cqrt_push(i32 %280)
  call void @cqrt_push(i32 %282)
  call void @cqrt_push(i32 %281)
  call void @cqrt_push(i32 %279)
  call void @cqrt_push(i32 %244)
  call void @cqrt_push(i32 %274)
  call void @cqrt_push(i32 %275)
  call void @cqrt_push(i32 %278)
  call void @cqrt_push(i32 %277)
  call void @cqrt_push(i32 %237)
  call void @cqrt_push(i32 %276)
  call void @cqrt_push(i32 %272)
  call void @cqrt_push(i32 %273)
  call void @cqrt_push(i32 %238)
  call void @cqrt_push(i32 %271)
  call void @cqrt_push(i32 %269)
  call void @cqrt_push(i32 %270)
  %284 = trunc i64 %239 to i32
  call void @cqrt_push(i32 %284)
  %285 = lshr i64 %239, 32
  %286 = trunc i64 %285 to i32
  call void @cqrt_push(i32 %286)
  call void @cqrt_push(i32 %245)
  call void @cqrt_push(i32 %247)
  call void @cqrt_push(i32 %246)
  call void @cqrt_push(i32 %241)
  %287 = trunc i64 %240 to i32
  call void @cqrt_push(i32 %287)
  %288 = lshr i64 %240, 32
  %289 = trunc i64 %288 to i32
  call void @cqrt_push(i32 %289)
  br i1 %283, label %290, label %317

290:                                              ; preds = %290, %268
  %from2 = phi i32 [ 0, %290 ], [ 1, %268 ]
  %291 = phi i32 [ 0, %268 ], [ %312, %290 ]
  %292 = phi i32 [ %282, %268 ], [ %306, %290 ]
  %293 = phi i32 [ %275, %268 ], [ %308, %290 ]
  %294 = phi i32 [ %9, %268 ], [ %309, %290 ]
  %295 = phi i32 [ %237, %268 ], [ %310, %290 ]
  %296 = phi i32 [ %278, %268 ], [ %311, %290 ]
  %297 = phi i64 [ 0, %268 ], [ %307, %290 ]
  call void @cqrt_push(i32 %from2)
  %298 = call i32 @cq_template_add_i64_hl(i32 %295, i64 8)
  %299 = call i32 @cq_template_add_i64_hl(i32 %294, i64 8)
  %300 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %296, i32 %300)
  %301 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %292, i32 %301)
  call void @cqrt_qram_store_i64_controlled(i32 %301, i32 %17, i32 %294, i32 %300)
  %302 = call i32 @cqrt_qram_load_i64_controlled(i32 %292, i32 %17, i32 %298)
  %303 = call i32 @cq_template_add_i64_hl(i32 %293, i64 -1)
  %304 = call i32 @cq_template_icmp_eq_i64_hl(i32 %303, i64 0)
  %305 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %305)
  call void @cqrt_xor_i1(i32 %304, i32 %305)
  %306 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %292, i32 %305, i32 %306)
  %307 = add i64 %297, -1
  %308 = call i32 @cq_template_add_i64_hl(i32 %275, i64 %307)
  %309 = call i32 @cq_template_select_i64(i32 %292, i32 %299, i32 %294)
  %310 = call i32 @cq_template_select_i64(i32 %292, i32 %298, i32 %295)
  %311 = call i32 @cq_template_select_i64(i32 %292, i32 %302, i32 %296)
  %312 = add i32 %291, 1
  %313 = icmp ult i32 %312, %10
  call void @cqrt_push(i32 %311)
  call void @cqrt_push(i32 %292)
  call void @cqrt_push(i32 %302)
  call void @cqrt_push(i32 %296)
  call void @cqrt_push(i32 %310)
  call void @cqrt_push(i32 %298)
  call void @cqrt_push(i32 %295)
  call void @cqrt_push(i32 %309)
  call void @cqrt_push(i32 %299)
  call void @cqrt_push(i32 %294)
  call void @cqrt_push(i32 %308)
  call void @cqrt_push(i32 %275)
  %314 = trunc i64 %307 to i32
  call void @cqrt_push(i32 %314)
  %315 = lshr i64 %307, 32
  %316 = trunc i64 %315 to i32
  call void @cqrt_push(i32 %316)
  call void @cqrt_push(i32 %305)
  call void @cqrt_push(i32 %306)
  call void @cqrt_push(i32 %304)
  call void @cqrt_push(i32 %303)
  call void @cqrt_push(i32 %293)
  br i1 %313, label %290, label %317

317:                                              ; preds = %290, %268
  %from1 = phi i32 [ 0, %290 ], [ 1, %268 ]
  %318 = phi i32 [ %275, %268 ], [ %308, %290 ]
  %319 = phi i32 [ %9, %268 ], [ %309, %290 ]
  %320 = phi i32 [ %237, %268 ], [ %310, %290 ]
  %321 = phi i32 [ %278, %268 ], [ %311, %290 ]
  %322 = phi i64 [ 0, %268 ], [ %307, %290 ]
  %323 = phi i32 [ %282, %268 ], [ %306, %290 ]
  %324 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %323, i32 %324)
  %325 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %321, i32 %325)
  %326 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %244, i32 %326)
  call void @cqrt_and_i1(i32 %244, i32 %274, i32 %326)
  %327 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %326, i32 %327)
  call void @cqrt_qram_store_i64_controlled(i32 %327, i32 %17, i32 %319, i32 %325)
  %328 = call i32 @cq_template_icmp_eq_i64(i32 %216, i32 %272)
  %329 = call i32 @cq_template_sub_i64(i32 %216, i32 %272)
  %330 = call i32 @cq_template_mul_i64_hl(i32 %272, i64 8)
  %331 = call i32 @cq_template_add_i64(i32 %9, i32 %330)
  %332 = call i32 @cq_template_shl_i64_hl(i32 %329, i64 3)
  %333 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %244, i32 %333)
  call void @cqrt_and_i1(i32 %244, i32 %328, i32 %333)
  %334 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %333, i32 %334)
  %335 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %332, i64 4096)
  %336 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %335, i32 %334, i32 %336)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %335, i32 %332, i64 4096)
  call void @cqrt_free(i32 %335)
  %337 = call i32 @cqrt_alloc_i8(i8 0)
  br label %338

338:                                              ; preds = %338, %317
  %339 = phi i64 [ 0, %317 ], [ %343, %338 ]
  %340 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %332, i64 %339)
  %341 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %340, i32 %334, i32 %341)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %340, i32 %332, i64 %339)
  call void @cqrt_free(i32 %340)
  %342 = call i32 @cq_template_add_i64_hl(i32 %331, i64 %339)
  call void @cqrt_qram_store_i8_controlled(i32 %341, i32 %17, i32 %342, i32 %337)
  call void @cq_template_add_i64_hl_unc(i32 %342, i32 %331, i64 %339)
  call void @cqrt_free(i32 %342)
  %343 = add nuw i64 %339, 1
  %344 = icmp eq i64 %343, 4096
  br i1 %344, label %345, label %338

345:                                              ; preds = %338
  br label %346

346:                                              ; preds = %345
  call void @cqrt_push(i32 %from1)
  %347 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 8)
  %348 = call i32 @cq_template_add_i64(i32 %237, i32 %347)
  %349 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 %239)
  %350 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %244, i32 %350)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl(i32 %350, i32 %236, i32 %9, i32 %349, i32 %4, i32 %10)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl_unc(i32 %350, i32 %236, i32 %9, i32 %349, i32 %4, i32 %10)
  call void @cqrt_and_i1(i32 %235, i32 %244, i32 %350)
  call void @cqrt_free(i32 %350)
  call void @cq_template_mul_i64_hl_unc(i32 %349, i32 %8, i64 %239)
  call void @cqrt_free(i32 %349)
  %351 = call i32 @cq_template_select_i64(i32 %244, i32 %273, i32 %238)
  %352 = call i32 @cq_template_select_i64(i32 %244, i32 %348, i32 %237)
  %353 = call i32 @cq_template_mul_i64_hl(i32 %217, i64 8)
  %354 = call i32 @cq_template_add_i64(i32 %236, i32 %353)
  %355 = add i64 %239, 1
  %356 = call i32 @cq_template_icmp_eq_i64_hl(i32 %3, i64 %355)
  %357 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %357)
  call void @cqrt_xor_i1(i32 %356, i32 %357)
  %358 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %235, i32 %357, i32 %358)
  %359 = call i32 @cq_template_select_i64(i32 %235, i32 %354, i32 %236)
  %360 = call i32 @cq_template_select_i64(i32 %235, i32 %352, i32 %237)
  %361 = call i32 @cq_template_select_i64(i32 %235, i32 %351, i32 %238)
  %362 = add i32 %234, 1
  %363 = icmp ult i32 %362, %10
  call void @cqrt_push(i32 %361)
  call void @cqrt_push(i32 %235)
  call void @cqrt_push(i32 %351)
  call void @cqrt_push(i32 %238)
  call void @cqrt_push(i32 %360)
  call void @cqrt_push(i32 %352)
  call void @cqrt_push(i32 %237)
  call void @cqrt_push(i32 %359)
  call void @cqrt_push(i32 %354)
  call void @cqrt_push(i32 %236)
  call void @cqrt_push(i32 %357)
  call void @cqrt_push(i32 %358)
  call void @cqrt_push(i32 %356)
  %364 = trunc i64 %355 to i32
  call void @cqrt_push(i32 %364)
  %365 = lshr i64 %355, 32
  %366 = trunc i64 %365 to i32
  call void @cqrt_push(i32 %366)
  call void @cqrt_push(i32 %353)
  call void @cqrt_push(i32 %244)
  call void @cqrt_push(i32 %348)
  call void @cqrt_push(i32 %273)
  call void @cqrt_push(i32 %347)
  call void @cqrt_push(i32 %333)
  call void @cqrt_push(i32 %334)
  call void @cqrt_push(i32 %328)
  call void @cqrt_push(i32 %332)
  call void @cqrt_push(i32 %329)
  call void @cqrt_push(i32 %331)
  call void @cqrt_push(i32 %330)
  call void @cqrt_push(i32 %272)
  call void @cqrt_push(i32 %274)
  call void @cqrt_push(i32 %326)
  br i1 %363, label %233, label %251

367:                                              ; preds = %251
  %368 = call i32 @cq_template_icmp_eq_i64_hl(i32 %259, i64 0)
  %369 = call i32 @cqrt_alloc_i1(i1 false)
  %370 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %370)
  call void @cqrt_xor_i1(i32 %368, i32 %370)
  call void @cqrt_and_i1(i32 %0, i32 %370, i32 %369)
  call void @cqrt_xor_i1(i32 %368, i32 %370)
  call void @cqrt_not_i1(i32 %370)
  call void @cqrt_free(i32 %370)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %368, i32 %259, i64 0)
  call void @cqrt_free(i32 %368)
  br label %479

371:                                              ; preds = %377
  call void @cqrt_and_i1(i32 %0, i32 %213, i32 %231)
  call void @cqrt_free(i32 %231)
  call void @cq_template_add_i64_hl_unc(i32 %219, i32 %218, i64 8)
  call void @cqrt_free(i32 %219)
  call void @cq_template_shl_i64_hl_unc(i32 %218, i32 %4, i64 3)
  call void @cqrt_free(i32 %218)
  call void @cq_template_add_i64_hl_unc(i32 %217, i32 %4, i64 1)
  call void @cqrt_free(i32 %217)
  call void @cq_template_add_i64_hl_unc(i32 %216, i32 %4, i64 1)
  call void @cqrt_free(i32 %216)
  call void @cq_template_add_i64_hl_unc(i32 %215, i32 %3, i64 -1)
  call void @cqrt_free(i32 %215)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %214, i32 %4, i64 -1)
  call void @cqrt_free(i32 %214)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %213, i32 %3, i64 0)
  call void @cqrt_free(i32 %213)
  call void @cq_template_select_i64_unc(i32 %212, i32 %22, i32 %29, i32 %5)
  call void @cqrt_free(i32 %212)
  call void @cq_template_select_i64_unc(i32 %211, i32 %22, i32 %24, i32 %6)
  call void @cqrt_free(i32 %211)
  call void @cqrt_and_i1(i32 %0, i32 %187, i32 %186)
  call void @cqrt_free(i32 %186)
  call void @cqrt_and_i1(i32 %184, i32 %22, i32 %187)
  call void @cqrt_free(i32 %187)
  call void @cq_template_icmp_ult_i64_unc(i32 %184, i32 %183, i32 %175)
  call void @cqrt_free(i32 %184)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %183, i32 %182, i32 %17, i32 %29)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %182)
  call void @cqrt_free(i32 %182)
  call void @cq_template_select_i64_lh_unc(i32 %175, i32 %172, i64 0, i32 %116)
  call void @cqrt_free(i32 %175)
  call void @cqrt_and_i1(i32 %118, i32 %173, i32 %172)
  call void @cqrt_not_i1(i32 %172)
  call void @cqrt_free(i32 %172)
  call void @cqrt_and_i1(i32 %174, i32 %45, i32 %173)
  call void @cqrt_xor_i1(i32 %174, i32 %173)
  call void @cqrt_free(i32 %173)
  call void @cqrt_xor_i1(i32 %39, i32 %174)
  call void @cqrt_not_i1(i32 %174)
  call void @cqrt_free(i32 %174)
  call void @cqrt_and_i1(i32 %0, i32 %147, i32 %146)
  call void @cqrt_free(i32 %146)
  call void @cqrt_and_i1(i32 %139, i32 %148, i32 %147)
  call void @cqrt_free(i32 %147)
  call void @cqrt_and_i1(i32 %118, i32 %149, i32 %148)
  call void @cqrt_xor_i1(i32 %22, i32 %148)
  call void @cqrt_free(i32 %148)
  call void @cqrt_and_i1(i32 %150, i32 %45, i32 %149)
  call void @cqrt_xor_i1(i32 %150, i32 %149)
  call void @cqrt_free(i32 %149)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %150)
  call void @cqrt_xor_i1(i32 %22, i32 %150)
  call void @cqrt_free(i32 %150)
  call void @cqrt_and_i1(i32 %137, i32 %138, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cq_template_icmp_slt_i64_unc(i32 %138, i32 %136, i32 %19)
  call void @cqrt_free(i32 %138)
  call void @cq_template_icmp_ne_i64_unc(i32 %137, i32 %29, i32 %5)
  call void @cqrt_free(i32 %137)
  call void @cq_template_select_i64_lh_unc(i32 %136, i32 %39, i64 0, i32 %135)
  call void @cqrt_free(i32 %136)
  call void @cq_template_select_i64_unc(i32 %135, i32 %45, i32 %23, i32 %117)
  call void @cqrt_free(i32 %135)
  br label %537

372:                                              ; preds = %481
  call void @cqrt_and_i1(i32 %47, i32 %53, i32 %66)
  call void @cqrt_free(i32 %66)
  call void @cq_template_select_i1_unc(i32 %65, i32 %64, i32 %62, i32 %52)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %47, i32 %63, i32 %64)
  call void @cqrt_free(i32 %64)
  call void @cqrt_xor_i1(i32 %53, i32 %63)
  call void @cqrt_not_i1(i32 %63)
  call void @cqrt_free(i32 %63)
  call void @cqrt_free(i32 %62)
  call void @cq_template_select_i64_unc(i32 %61, i32 %60, i32 %58, i32 %51)
  call void @cqrt_free(i32 %61)
  call void @cqrt_and_i1(i32 %47, i32 %59, i32 %60)
  call void @cqrt_free(i32 %60)
  call void @cqrt_xor_i1(i32 %53, i32 %59)
  call void @cqrt_not_i1(i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cqrt_free(i32 %58)
  call void @cq_template_select_i64_unc(i32 %57, i32 %56, i32 %54, i32 %50)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %47, i32 %55, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_xor_i1(i32 %53, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cqrt_free(i32 %54)
  call void @cq_template_icmp_slt_i64_unc(i32 %53, i32 %23, i32 %19)
  call void @cqrt_free(i32 %53)
  call void @cqrt_free(i32 %52)
  call void @cqrt_free(i32 %51)
  call void @cqrt_free(i32 %50)
  call void @cqrt_and_i1(i32 %0, i32 %48, i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cqrt_and_i1(i32 %49, i32 %45, i32 %48)
  call void @cqrt_xor_i1(i32 %49, i32 %48)
  call void @cqrt_free(i32 %48)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %49)
  call void @cqrt_xor_i1(i32 %22, i32 %49)
  call void @cqrt_free(i32 %49)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %45, i32 %44, i64 0)
  call void @cqrt_free(i32 %45)
  call void @__cq_q___gmpn_sub_n_1111_t_ctl_unc(i32 %42, i32 %44, i32 %29, i32 %5, i32 %41, i32 %23, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %43, i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %43)
  call void @cqrt_xor_i1(i32 %22, i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cq_template_add_i64_unc(i32 %41, i32 %5, i32 %40)
  call void @cqrt_free(i32 %41)
  call void @cq_template_mul_i64_hl_unc(i32 %40, i32 %19, i64 8)
  call void @cqrt_free(i32 %40)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %39, i32 %23, i64 0)
  call void @cqrt_free(i32 %39)
  call void @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl_unc(i32 %26, i32 %29, i32 %28, i32 %25, i32 %10)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_shl_i64_hl_unc(i32 %25, i32 %24, i64 3)
  call void @cqrt_free(i32 %25)
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %19, i64 1)
  call void @cqrt_free(i32 %24)
  call void @cq_template_sub_i64_unc(i32 %23, i32 %6, i32 %19)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_slt_i64_unc(i32 %22, i32 %19, i32 %6)
  call void @cqrt_free(i32 %22)
  call void @cq_template_mul_i64_unc(i32 %19, i32 %7, i32 %3)
  call void @cqrt_free(i32 %19)
  call void @cqrt_abort_i1(i32 %369)
  %373 = ptrtoint ptr %18 to i64
  %374 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %17, i64 %373)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_ctl(i32 %0, i32 %374, i32 %10)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_ctl_unc(i32 %0, i32 %374, i32 %10)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %374, i32 %0, i32 %17, i64 %373)
  %375 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %376 = add i32 %375, -1
  store i32 %376, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  store i32 %12, ptr @__cq_k, align 4
  ret void

377:                                              ; preds = %480, %378
  br label %371

378:                                              ; preds = %416, %442
  %379 = call i32 @cqrt_pop()
  %380 = zext i32 %379 to i64
  %381 = shl i64 %380, 32
  %382 = or i64 0, %381
  %383 = call i32 @cqrt_pop()
  %384 = zext i32 %383 to i64
  %385 = or i64 %382, %384
  %386 = call i32 @cqrt_pop()
  %387 = call i32 @cqrt_pop()
  %388 = call i32 @cqrt_pop()
  %389 = call i32 @cqrt_pop()
  %390 = call i32 @cqrt_pop()
  %391 = zext i32 %390 to i64
  %392 = shl i64 %391, 32
  %393 = or i64 0, %392
  %394 = call i32 @cqrt_pop()
  %395 = zext i32 %394 to i64
  %396 = or i64 %393, %395
  %397 = call i32 @cqrt_pop()
  %398 = call i32 @cqrt_pop()
  %399 = call i32 @cqrt_pop()
  %400 = call i32 @cqrt_pop()
  %401 = call i32 @cqrt_pop()
  %402 = call i32 @cqrt_pop()
  %403 = call i32 @cqrt_pop()
  %404 = call i32 @cqrt_pop()
  %405 = call i32 @cqrt_pop()
  %406 = call i32 @cqrt_pop()
  %407 = call i32 @cqrt_pop()
  %408 = call i32 @cqrt_pop()
  %409 = call i32 @cqrt_pop()
  %410 = call i32 @cqrt_pop()
  %411 = call i32 @cqrt_pop()
  %412 = call i32 @cqrt_pop()
  %413 = call i32 @cqrt_pop()
  %414 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %414, i32 %413, i32 %412)
  call void @cqrt_free(i32 %412)
  call void @cqrt_and_i1(i32 %411, i32 %410, i32 %413)
  call void @cqrt_xor_i1(i32 %411, i32 %413)
  call void @cqrt_free(i32 %413)
  call void @cqrt_and_i1(i32 %409, i32 %408, i32 %411)
  call void @cqrt_xor_i1(i32 %409, i32 %411)
  call void @cqrt_free(i32 %411)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %410, i32 %407, i64 0)
  call void @cqrt_free(i32 %410)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %406, i32 %405, i32 %17, i32 %404)
  call void @cqrt_and_i1(i32 %414, i32 %403, i32 %405)
  call void @cqrt_free(i32 %405)
  call void @cqrt_and_i1(i32 %409, i32 %408, i32 %403)
  call void @cqrt_xor_i1(i32 %409, i32 %403)
  call void @cqrt_free(i32 %403)
  call void @cq_template_add_i64_hl_unc(i32 %407, i32 %402, i64 -1)
  call void @cqrt_free(i32 %407)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %408, i32 %402, i64 0)
  call void @cqrt_free(i32 %408)
  call void @cq_template_sub_i64_unc(i32 %401, i32 %400, i32 %402)
  call void @cqrt_free(i32 %401)
  call void @cq_template_select_i64_unc(i32 %402, i32 %399, i32 %7, i32 %400)
  call void @cqrt_free(i32 %402)
  call void @cq_template_select_i1_hl_unc(i32 %399, i32 %398, i32 %397, i1 false)
  call void @cqrt_free(i32 %399)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %397, i32 %215, i64 %396)
  call void @cqrt_free(i32 %397)
  call void @cq_template_icmp_sge_i64_unc(i32 %398, i32 %400, i32 %7)
  call void @cqrt_free(i32 %398)
  call void @cqrt_and_i1(i32 %414, i32 %389, i32 %388)
  call void @cqrt_free(i32 %388)
  call void @cqrt_and_i1(i32 %387, i32 %214, i32 %389)
  call void @cqrt_xor_i1(i32 %387, i32 %389)
  call void @cqrt_free(i32 %389)
  call void @cqrt_xor_i1(i32 %409, i32 %387)
  call void @cqrt_not_i1(i32 %387)
  call void @cqrt_free(i32 %387)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %409, i32 %400, i64 0)
  call void @cqrt_free(i32 %409)
  call void @cq_template_add_i64_hl_unc(i32 %386, i32 %2, i64 %385)
  call void @cqrt_free(i32 %386)
  %415 = call i32 @cqrt_pop()
  switch i32 %415, label %442 [
    i32 1, label %377
  ]

416:                                              ; preds = %416, %442
  %417 = call i32 @cqrt_pop()
  %418 = call i32 @cqrt_pop()
  %419 = call i32 @cqrt_pop()
  %420 = call i32 @cqrt_pop()
  %421 = call i32 @cqrt_pop()
  %422 = call i32 @cqrt_pop()
  %423 = zext i32 %422 to i64
  %424 = shl i64 %423, 32
  %425 = or i64 0, %424
  %426 = call i32 @cqrt_pop()
  %427 = zext i32 %426 to i64
  %428 = or i64 %425, %427
  %429 = call i32 @cqrt_pop()
  %430 = call i32 @cqrt_pop()
  %431 = call i32 @cqrt_pop()
  %432 = call i32 @cqrt_pop()
  %433 = call i32 @cqrt_pop()
  %434 = call i32 @cqrt_pop()
  %435 = call i32 @cqrt_pop()
  %436 = call i32 @cqrt_pop()
  %437 = call i32 @cqrt_pop()
  %438 = call i32 @cqrt_pop()
  %439 = call i32 @cqrt_pop()
  %440 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %440, i32 %439, i32 %438, i32 %437)
  call void @cqrt_free(i32 %440)
  call void @cq_template_select_i64_unc(i32 %436, i32 %439, i32 %435, i32 %434)
  call void @cqrt_free(i32 %436)
  call void @cq_template_select_i64_unc(i32 %433, i32 %439, i32 %432, i32 %431)
  call void @cqrt_free(i32 %433)
  call void @cq_template_add_i64_hl_unc(i32 %430, i32 %429, i64 %428)
  call void @cqrt_free(i32 %430)
  call void @cqrt_and_i1(i32 %439, i32 %421, i32 %420)
  call void @cqrt_free(i32 %420)
  call void @cqrt_xor_i1(i32 %419, i32 %421)
  call void @cqrt_not_i1(i32 %421)
  call void @cqrt_free(i32 %421)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %419, i32 %418, i64 0)
  call void @cqrt_free(i32 %419)
  call void @cq_template_add_i64_hl_unc(i32 %418, i32 %417, i64 -1)
  call void @cqrt_free(i32 %418)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %438, i32 %439, i32 %17, i32 %435)
  call void @cq_template_add_i64_hl_unc(i32 %432, i32 %431, i64 8)
  call void @cqrt_free(i32 %432)
  call void @cq_template_add_i64_hl_unc(i32 %435, i32 %434, i64 8)
  call void @cqrt_free(i32 %435)
  %441 = call i32 @cqrt_pop()
  switch i32 %441, label %416 [
    i32 1, label %378
  ]

442:                                              ; preds = %480, %378
  %443 = call i32 @cqrt_pop()
  %444 = call i32 @cqrt_pop()
  %445 = call i32 @cqrt_pop()
  %446 = call i32 @cqrt_pop()
  %447 = call i32 @cqrt_pop()
  %448 = call i32 @cqrt_pop()
  %449 = call i32 @cqrt_pop()
  %450 = call i32 @cqrt_pop()
  %451 = call i32 @cqrt_pop()
  %452 = call i32 @cqrt_pop()
  %453 = call i32 @cqrt_pop()
  %454 = call i32 @cqrt_pop()
  %455 = call i32 @cqrt_pop()
  %456 = call i32 @cqrt_pop()
  %457 = call i32 @cqrt_pop()
  %458 = call i32 @cqrt_pop()
  %459 = zext i32 %458 to i64
  %460 = shl i64 %459, 32
  %461 = or i64 0, %460
  %462 = call i32 @cqrt_pop()
  %463 = zext i32 %462 to i64
  %464 = or i64 %461, %463
  %465 = call i32 @cqrt_pop()
  %466 = call i32 @cqrt_pop()
  %467 = call i32 @cqrt_pop()
  %468 = call i32 @cqrt_pop()
  %469 = call i32 @cqrt_pop()
  %470 = call i32 @cqrt_pop()
  %471 = call i32 @cqrt_pop()
  %472 = call i32 @cqrt_pop()
  %473 = call i32 @cqrt_pop()
  %474 = call i32 @cqrt_pop()
  %475 = call i32 @cqrt_pop()
  %476 = call i32 @cqrt_pop()
  %477 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %477, i32 %476, i32 %475, i32 %474)
  call void @cqrt_free(i32 %477)
  call void @cq_template_select_i64_unc(i32 %473, i32 %476, i32 %472, i32 %471)
  call void @cqrt_free(i32 %473)
  call void @cq_template_select_i64_unc(i32 %470, i32 %476, i32 %469, i32 %468)
  call void @cqrt_free(i32 %470)
  call void @cqrt_and_i1(i32 %476, i32 %467, i32 %466)
  call void @cqrt_free(i32 %466)
  call void @cqrt_xor_i1(i32 %465, i32 %467)
  call void @cqrt_not_i1(i32 %467)
  call void @cqrt_free(i32 %467)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %465, i32 %3, i64 %464)
  call void @cqrt_free(i32 %465)
  call void @cq_template_add_i64_unc(i32 %469, i32 %468, i32 %457)
  call void @cqrt_free(i32 %469)
  call void @cq_template_mul_i64_hl_unc(i32 %457, i32 %217, i64 8)
  call void @cqrt_free(i32 %457)
  call void @cq_template_select_i64_unc(i32 %472, i32 %456, i32 %455, i32 %471)
  call void @cqrt_free(i32 %472)
  call void @cq_template_select_i64_unc(i32 %475, i32 %456, i32 %454, i32 %474)
  call void @cqrt_free(i32 %475)
  call void @cq_template_add_i64_unc(i32 %455, i32 %471, i32 %453)
  call void @cqrt_free(i32 %455)
  call void @cq_template_mul_i64_hl_unc(i32 %453, i32 %7, i64 8)
  call void @cqrt_free(i32 %453)
  call void @cqrt_and_i1(i32 %476, i32 %452, i32 %451)
  call void @cqrt_free(i32 %451)
  call void @cqrt_and_i1(i32 %456, i32 %450, i32 %452)
  call void @cqrt_xor_i1(i32 %456, i32 %452)
  call void @cqrt_free(i32 %452)
  call void @cq_template_shl_i64_hl_unc(i32 %449, i32 %448, i64 3)
  call void @cqrt_free(i32 %449)
  call void @cq_template_add_i64_unc(i32 %447, i32 %9, i32 %446)
  call void @cqrt_free(i32 %447)
  call void @cq_template_mul_i64_hl_unc(i32 %446, i32 %445, i64 8)
  call void @cqrt_free(i32 %446)
  call void @cq_template_sub_i64_unc(i32 %448, i32 %216, i32 %445)
  call void @cqrt_free(i32 %448)
  call void @cq_template_icmp_eq_i64_unc(i32 %450, i32 %216, i32 %445)
  call void @cqrt_free(i32 %450)
  call void @cqrt_and_i1(i32 %456, i32 %444, i32 %443)
  call void @cqrt_xor_i1(i32 %456, i32 %443)
  call void @cqrt_free(i32 %443)
  %478 = call i32 @cqrt_pop()
  switch i32 %478, label %416 [
    i32 1, label %378
  ]

479:                                              ; preds = %367
  call void @cqrt_copy_i64(i32 %255, i32 %259)
  call void @cqrt_free(i32 %259)
  br label %480

480:                                              ; preds = %479
  switch i32 %252, label %377 [
    i32 1, label %442
  ]

481:                                              ; preds = %538, %482
  br label %372

482:                                              ; preds = %538, %517
  %483 = call i32 @cqrt_pop()
  %484 = call i32 @cqrt_pop()
  %485 = call i32 @cqrt_pop()
  %486 = call i32 @cqrt_pop()
  %487 = call i32 @cqrt_pop()
  %488 = call i32 @cqrt_pop()
  %489 = call i32 @cqrt_pop()
  %490 = call i32 @cqrt_pop()
  %491 = call i32 @cqrt_pop()
  %492 = call i32 @cqrt_pop()
  %493 = call i32 @cqrt_pop()
  %494 = call i32 @cqrt_pop()
  %495 = call i32 @cqrt_pop()
  %496 = call i32 @cqrt_pop()
  %497 = call i32 @cqrt_pop()
  %498 = call i32 @cqrt_pop()
  %499 = call i32 @cqrt_pop()
  %500 = call i32 @cqrt_pop()
  %501 = call i32 @cqrt_pop()
  %502 = call i32 @cqrt_pop()
  %503 = call i32 @cqrt_pop()
  %504 = call i32 @cqrt_pop()
  %505 = call i32 @cqrt_pop()
  %506 = call i32 @cqrt_pop()
  %507 = call i32 @cqrt_pop()
  %508 = call i32 @cqrt_pop()
  %509 = zext i32 %508 to i64
  %510 = shl i64 %509, 32
  %511 = or i64 0, %510
  %512 = call i32 @cqrt_pop()
  %513 = zext i32 %512 to i64
  %514 = or i64 %511, %513
  %515 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %515, i32 %23, i64 %514)
  call void @cqrt_free(i32 %515)
  call void @cqrt_and_i1(i32 %507, i32 %506, i32 %505)
  call void @cqrt_free(i32 %505)
  call void @cqrt_and_i1(i32 %504, i32 %503, i32 %506)
  call void @cqrt_free(i32 %506)
  call void @cq_template_select_i1_unc(i32 %502, i32 %501, i32 %500, i32 %499)
  call void @cqrt_free(i32 %502)
  call void @cqrt_and_i1(i32 %507, i32 %498, i32 %501)
  call void @cqrt_free(i32 %501)
  call void @cqrt_and_i1(i32 %503, i32 %504, i32 %498)
  call void @cqrt_xor_i1(i32 %503, i32 %498)
  call void @cqrt_free(i32 %498)
  call void @cqrt_free(i32 %500)
  call void @cq_template_select_i64_unc(i32 %497, i32 %496, i32 %495, i32 %494)
  call void @cqrt_free(i32 %497)
  call void @cqrt_and_i1(i32 %507, i32 %493, i32 %496)
  call void @cqrt_free(i32 %496)
  call void @cqrt_and_i1(i32 %503, i32 %504, i32 %493)
  call void @cqrt_xor_i1(i32 %503, i32 %493)
  call void @cqrt_free(i32 %493)
  call void @cq_template_select_i64_unc(i32 %492, i32 %491, i32 %490, i32 %489)
  call void @cqrt_free(i32 %492)
  call void @cqrt_and_i1(i32 %507, i32 %488, i32 %491)
  call void @cqrt_free(i32 %491)
  call void @cqrt_and_i1(i32 %503, i32 %504, i32 %488)
  call void @cqrt_xor_i1(i32 %503, i32 %488)
  call void @cqrt_free(i32 %488)
  call void @cqrt_free(i32 %490)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %504, i32 %487, i64 0)
  call void @cqrt_free(i32 %504)
  call void @cq_template_add_i64_hl_unc(i32 %495, i32 %486, i64 1)
  call void @cqrt_free(i32 %495)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %487, i32 %485, i32 %17, i32 %484)
  call void @cq_template_add_i64_unc(i32 %484, i32 %5, i32 %483)
  call void @cqrt_free(i32 %484)
  call void @cq_template_mul_i64_hl_unc(i32 %483, i32 %486, i64 8)
  call void @cqrt_free(i32 %483)
  %516 = call i32 @cqrt_pop()
  switch i32 %516, label %517 [
    i32 1, label %481
  ]

517:                                              ; preds = %482
  %518 = call i32 @cqrt_pop()
  %519 = call i32 @cqrt_pop()
  %520 = call i32 @cqrt_pop()
  %521 = call i32 @cqrt_pop()
  %522 = call i32 @cqrt_pop()
  %523 = call i32 @cqrt_pop()
  %524 = call i32 @cqrt_pop()
  %525 = call i32 @cqrt_pop()
  %526 = call i32 @cqrt_pop()
  %527 = call i32 @cqrt_pop()
  %528 = call i32 @cqrt_pop()
  %529 = call i32 @cqrt_pop()
  %530 = call i32 @cqrt_pop()
  %531 = call i32 @cqrt_pop()
  %532 = call i32 @cqrt_pop()
  %533 = call i32 @cqrt_pop()
  %534 = call i32 @cqrt_pop()
  %535 = call i32 @cqrt_pop()
  %536 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %536, i32 %535, i32 %534)
  call void @cqrt_free(i32 %534)
  call void @cq_template_select_i1_unc(i32 %533, i32 %532, i32 %531, i32 %530)
  call void @cqrt_free(i32 %533)
  call void @cqrt_and_i1(i32 %536, i32 %529, i32 %532)
  call void @cqrt_free(i32 %532)
  call void @cqrt_xor_i1(i32 %535, i32 %529)
  call void @cqrt_not_i1(i32 %529)
  call void @cqrt_free(i32 %529)
  call void @cqrt_free(i32 %531)
  call void @cq_template_select_i64_unc(i32 %528, i32 %527, i32 %526, i32 %525)
  call void @cqrt_free(i32 %528)
  call void @cqrt_and_i1(i32 %536, i32 %524, i32 %527)
  call void @cqrt_free(i32 %527)
  call void @cqrt_xor_i1(i32 %535, i32 %524)
  call void @cqrt_not_i1(i32 %524)
  call void @cqrt_free(i32 %524)
  call void @cqrt_free(i32 %526)
  call void @cq_template_select_i64_unc(i32 %523, i32 %522, i32 %521, i32 %520)
  call void @cqrt_free(i32 %523)
  call void @cqrt_and_i1(i32 %536, i32 %519, i32 %522)
  call void @cqrt_free(i32 %522)
  call void @cqrt_xor_i1(i32 %535, i32 %519)
  call void @cqrt_not_i1(i32 %519)
  call void @cqrt_free(i32 %519)
  call void @cqrt_free(i32 %521)
  call void @cq_template_icmp_slt_i64_unc(i32 %535, i32 %518, i32 %19)
  call void @cqrt_free(i32 %535)
  br label %482

537:                                              ; preds = %371
  call void @cqrt_copy_i1(i32 %113, i32 %118)
  call void @cqrt_free(i32 %118)
  call void @cqrt_copy_i64(i32 %112, i32 %117)
  call void @cqrt_free(i32 %117)
  call void @cqrt_copy_i64(i32 %111, i32 %116)
  call void @cqrt_free(i32 %116)
  br label %538

538:                                              ; preds = %537
  switch i32 %107, label %481 [
    i32 1, label %482
  ]

539:                                              ; preds = %11
  %540 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %540)
  %541 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %542 = add i32 %541, -1
  store i32 %542, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  store i32 %12, ptr @__cq_k, align 4
  ret void
}

declare void @__cq_q___gmp_tmp_reentrant_free_1_t_ctl(i32, i32, i32)

declare void @__cq_q___gmp_tmp_reentrant_free_1_t_ctl_unc(i32, i32, i32)

define internal void @__cq_q_mpn_mul_fft_decompose_111111111_t_ctl_pure(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10) {
  %12 = load i32, ptr @__cq_k, align 4
  store i32 %10, ptr @__cq_k, align 4
  %13 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %14 = add i32 %13, 1
  store i32 %14, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %15 = icmp ult i32 %13, %10
  br i1 %15, label %16, label %533

16:                                               ; preds = %11
  %17 = call i32 @__cq_mem()
  %18 = call ptr @__cq_alloc(i64 8, i64 8)
  %19 = call i32 @cq_template_mul_i64(i32 %7, i32 %3)
  %20 = ptrtoint ptr %18 to i64
  %21 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %17, i64 %20, i32 %21)
  %22 = call i32 @cq_template_icmp_slt_i64(i32 %19, i32 %6)
  %23 = call i32 @cq_template_sub_i64(i32 %6, i32 %19)
  %24 = call i32 @cq_template_add_i64_hl(i32 %19, i64 1)
  %25 = call i32 @cq_template_shl_i64_hl(i32 %24, i64 3)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %26)
  %27 = ptrtoint ptr %18 to i64
  %28 = call i32 @cqrt_alloc_i64(i64 %27)
  %29 = call i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl(i32 %26, i32 %28, i32 %25, i32 %10)
  %30 = call i32 @cq_template_mul_i64_hl(i32 %19, i64 8)
  %31 = call i32 @cq_template_add_i64(i32 %29, i32 %30)
  %32 = call i32 @cqrt_alloc_i64(i64 0)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %33)
  call void @cqrt_qram_store_i64_controlled(i32 %33, i32 %17, i32 %31, i32 %32)
  call void @cq_template_add_i64_unc(i32 %31, i32 %29, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cq_template_mul_i64_hl_unc(i32 %30, i32 %19, i64 8)
  call void @cqrt_free(i32 %30)
  %34 = call i32 @cq_template_icmp_sgt_i64(i32 %23, i32 %19)
  call void @cq_template_icmp_sgt_i64_unc(i32 %34, i32 %23, i32 %19)
  call void @cqrt_free(i32 %34)
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %23, i64 0)
  %36 = call i32 @cq_template_mul_i64_hl(i32 %19, i64 8)
  %37 = call i32 @cq_template_add_i64(i32 %5, i32 %36)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %39)
  call void @cqrt_and_i1(i32 %22, i32 %35, i32 %39)
  call void @cqrt_and_i1(i32 %0, i32 %39, i32 %38)
  %40 = call i32 @__cq_q___gmpn_sub_n_1111_t_ctl(i32 %38, i32 %29, i32 %5, i32 %37, i32 %23, i32 %10)
  %41 = call i32 @cq_template_icmp_eq_i64_hl(i32 %40, i64 0)
  br label %42

42:                                               ; preds = %16
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %45)
  call void @cqrt_and_i1(i32 %22, i32 %35, i32 %45)
  call void @cqrt_xor_i1(i32 %45, i32 %44)
  call void @cqrt_and_i1(i32 %45, i32 %41, i32 %44)
  call void @cqrt_and_i1(i32 %0, i32 %44, i32 %43)
  %46 = call i32 @cqrt_alloc_i64(i64 0)
  %47 = call i32 @cqrt_alloc_i64(i64 0)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  %49 = call i32 @cq_template_icmp_slt_i64(i32 %23, i32 %19)
  %50 = call i32 @cqrt_alloc_i64(i64 1)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_xor_i1(i32 %49, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %51, i32 %52)
  %53 = call i32 @cq_template_select_i64(i32 %52, i32 %50, i32 %46)
  %54 = call i32 @cqrt_alloc_i64(i64 0)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_xor_i1(i32 %49, i32 %55)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %55, i32 %56)
  %57 = call i32 @cq_template_select_i64(i32 %56, i32 %54, i32 %47)
  %58 = call i32 @cqrt_alloc_i1(i1 true)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %59)
  call void @cqrt_xor_i1(i32 %49, i32 %59)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %59, i32 %60)
  %61 = call i32 @cq_template_select_i1(i32 %60, i32 %58, i32 %48)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %49, i32 %62)
  %63 = icmp ult i32 0, %10
  br i1 %63, label %64, label %102

64:                                               ; preds = %115, %42
  %from4 = phi i32 [ 0, %115 ], [ 1, %42 ]
  %65 = phi i32 [ 0, %42 ], [ %97, %115 ]
  %66 = phi i32 [ %62, %42 ], [ %129, %115 ]
  %67 = phi i32 [ %23, %42 ], [ %96, %115 ]
  %68 = phi i64 [ 0, %42 ], [ %95, %115 ]
  %69 = phi i32 [ %49, %42 ], [ %116, %115 ]
  %70 = phi i32 [ %53, %42 ], [ %120, %115 ]
  %71 = phi i32 [ %57, %42 ], [ %124, %115 ]
  %72 = phi i32 [ %61, %42 ], [ %128, %115 ]
  call void @cqrt_push(i32 %from4)
  %73 = call i32 @cq_template_mul_i64_hl(i32 %67, i64 8)
  %74 = call i32 @cq_template_add_i64(i32 %5, i32 %73)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %69, i32 %75)
  %76 = call i32 @cqrt_qram_load_i64_controlled(i32 %75, i32 %17, i32 %74)
  %77 = call i32 @cq_template_add_i64_hl(i32 %76, i64 -1)
  %78 = call i32 @cq_template_add_i64_hl(i32 %67, i64 1)
  %79 = call i32 @cq_template_mul_i64_hl(i32 %67, i64 8)
  %80 = call i32 @cq_template_add_i64(i32 %29, i32 %79)
  call void @cqrt_qram_store_i64_controlled(i32 %75, i32 %17, i32 %80, i32 %77)
  call void @cq_template_add_i64_unc(i32 %80, i32 %29, i32 %79)
  call void @cqrt_free(i32 %80)
  call void @cq_template_mul_i64_hl_unc(i32 %79, i32 %67, i64 8)
  call void @cqrt_free(i32 %79)
  %81 = call i32 @cq_template_icmp_eq_i64_hl(i32 %76, i64 0)
  %82 = call i32 @cqrt_alloc_i64(i64 0)
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %69, i32 %83)
  call void @cqrt_and_i1(i32 %69, i32 %81, i32 %83)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %83, i32 %84)
  %85 = call i32 @cq_template_select_i64(i32 %84, i32 %82, i32 %70)
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %69, i32 %86)
  call void @cqrt_and_i1(i32 %69, i32 %81, i32 %86)
  %87 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %86, i32 %87)
  %88 = call i32 @cq_template_select_i64(i32 %87, i32 %78, i32 %71)
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %69, i32 %90)
  call void @cqrt_and_i1(i32 %69, i32 %81, i32 %90)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %90, i32 %91)
  %92 = call i32 @cq_template_select_i1(i32 %91, i32 %89, i32 %72)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %81, i32 %69, i32 %93)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %93, i32 %94)
  %95 = add i64 %68, 1
  %96 = call i32 @cq_template_add_i64_hl(i32 %23, i64 %95)
  %97 = add i32 %65, 1
  %98 = icmp ult i32 %97, %10
  call void @cqrt_push(i32 %96)
  %99 = trunc i64 %95 to i32
  call void @cqrt_push(i32 %99)
  %100 = lshr i64 %95, 32
  %101 = trunc i64 %100 to i32
  call void @cqrt_push(i32 %101)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %73)
  br i1 %98, label %115, label %102

102:                                              ; preds = %64, %42
  %103 = phi i32 [ 0, %42 ], [ 1, %64 ]
  %104 = phi i32 [ %23, %42 ], [ %96, %64 ]
  %105 = phi i64 [ 0, %42 ], [ %95, %64 ]
  %106 = phi i32 [ %49, %42 ], [ %69, %64 ]
  %107 = phi i32 [ %53, %42 ], [ %85, %64 ]
  %108 = phi i32 [ %57, %42 ], [ %88, %64 ]
  %109 = phi i32 [ %61, %42 ], [ %92, %64 ]
  %110 = phi i32 [ %62, %42 ], [ %94, %64 ]
  %111 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %110, i32 %111)
  %112 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %107, i32 %112)
  %113 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %108, i32 %113)
  %114 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %109, i32 %114)
  br label %130

115:                                              ; preds = %64
  %116 = call i32 @cq_template_icmp_slt_i64(i32 %96, i32 %19)
  %117 = call i32 @cqrt_alloc_i64(i64 1)
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %118)
  call void @cqrt_xor_i1(i32 %116, i32 %118)
  %119 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %118, i32 %119)
  %120 = call i32 @cq_template_select_i64(i32 %119, i32 %117, i32 %85)
  %121 = call i32 @cqrt_alloc_i64(i64 0)
  %122 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %122)
  call void @cqrt_xor_i1(i32 %116, i32 %122)
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %122, i32 %123)
  %124 = call i32 @cq_template_select_i64(i32 %123, i32 %121, i32 %88)
  %125 = call i32 @cqrt_alloc_i1(i1 true)
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %126)
  call void @cqrt_xor_i1(i32 %116, i32 %126)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %126, i32 %127)
  %128 = call i32 @cq_template_select_i1(i32 %127, i32 %125, i32 %92)
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %116, i32 %129)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %128)
  call void @cqrt_push(i32 %127)
  call void @cqrt_push(i32 %125)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %126)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %123)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %122)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %119)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %118)
  call void @cqrt_push(i32 %96)
  br label %64

130:                                              ; preds = %102
  %131 = call i32 @cq_template_select_i64(i32 %41, i32 %23, i32 %113)
  %132 = call i32 @cq_template_select_i64_lh(i32 %35, i64 0, i32 %131)
  %133 = call i32 @cq_template_icmp_ne_i64(i32 %29, i32 %5)
  %134 = call i32 @cq_template_icmp_slt_i64(i32 %132, i32 %19)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %133, i32 %134, i32 %135)
  %136 = call i32 @cq_template_shl_i64_hl(i32 %132, i64 3)
  %137 = call i32 @cq_template_add_i64(i32 %29, i32 %136)
  %138 = call i32 @cq_template_add_i64(i32 %5, i32 %136)
  %139 = call i32 @cq_template_mul_i64(i32 %7, i32 %3)
  %140 = call i32 @cq_template_sub_i64(i32 %139, i32 %132)
  %141 = call i32 @cq_template_shl_i64_hl(i32 %140, i64 3)
  %142 = call i32 @cqrt_alloc_i1(i1 false)
  %143 = call i32 @cqrt_alloc_i1(i1 false)
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %144)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %22, i32 %146)
  call void @cqrt_and_i1(i32 %22, i32 %35, i32 %146)
  call void @cqrt_xor_i1(i32 %146, i32 %145)
  call void @cqrt_and_i1(i32 %146, i32 %41, i32 %145)
  call void @cqrt_and_i1(i32 %114, i32 %145, i32 %144)
  call void @cqrt_and_i1(i32 %135, i32 %144, i32 %143)
  call void @cqrt_and_i1(i32 %0, i32 %143, i32 %142)
  %147 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %141, i64 4096)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %147, i32 %142, i32 %148)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %147, i32 %141, i64 4096)
  call void @cqrt_free(i32 %147)
  br label %149

149:                                              ; preds = %149, %130
  %150 = phi i64 [ 0, %130 ], [ %155, %149 ]
  %151 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %141, i64 %150)
  %152 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %151, i32 %142, i32 %152)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %151, i32 %141, i64 %150)
  call void @cqrt_free(i32 %151)
  %153 = call i32 @cq_template_add_i64_hl(i32 %138, i64 %150)
  %154 = call i32 @cqrt_qram_load_i8_controlled(i32 %152, i32 %17, i32 %153)
  call void @cq_template_add_i64_hl_unc(i32 %153, i32 %138, i64 %150)
  call void @cqrt_free(i32 %153)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %154)
  %155 = add nuw i64 %150, 1
  %156 = icmp eq i64 %155, 4096
  br i1 %156, label %157, label %149

157:                                              ; preds = %149
  call void @cq_template_shl_i64_hl_unc(i32 %141, i32 %140, i64 3)
  call void @cqrt_free(i32 %141)
  call void @cq_template_sub_i64_unc(i32 %140, i32 %139, i32 %132)
  call void @cqrt_free(i32 %140)
  call void @cq_template_mul_i64_unc(i32 %139, i32 %7, i32 %3)
  call void @cqrt_free(i32 %139)
  call void @cq_template_add_i64_unc(i32 %138, i32 %5, i32 %136)
  call void @cqrt_free(i32 %138)
  br label %158

158:                                              ; preds = %157
  br label %159

159:                                              ; preds = %159, %158
  %160 = phi i64 [ 4095, %158 ], [ %164, %159 ]
  %161 = call i32 @cqrt_pop()
  %162 = call i32 @cqrt_pop()
  %163 = call i32 @cq_template_add_i64_hl(i32 %137, i64 %160)
  call void @cqrt_qram_store_i8_controlled(i32 %162, i32 %17, i32 %163, i32 %161)
  call void @cq_template_add_i64_hl_unc(i32 %163, i32 %137, i64 %160)
  call void @cqrt_free(i32 %163)
  %164 = add nsw i64 %160, -1
  %165 = icmp eq i64 %160, 0
  br i1 %165, label %166, label %159

166:                                              ; preds = %159
  call void @cq_template_add_i64_unc(i32 %137, i32 %29, i32 %136)
  call void @cqrt_free(i32 %137)
  call void @cq_template_shl_i64_hl_unc(i32 %136, i32 %132, i64 3)
  call void @cqrt_free(i32 %136)
  br label %167

167:                                              ; preds = %166
  %168 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %168)
  %169 = call i32 @cqrt_alloc_i1(i1 false)
  %170 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %170)
  call void @cqrt_xor_i1(i32 %35, i32 %170)
  call void @cqrt_xor_i1(i32 %170, i32 %169)
  call void @cqrt_and_i1(i32 %170, i32 %41, i32 %169)
  call void @cqrt_and_i1(i32 %114, i32 %169, i32 %168)
  %171 = call i32 @cq_template_select_i64_lh(i32 %168, i64 0, i32 %112)
  %172 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %172)
  %173 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %172, i32 %17, i32 %29, i32 %173)
  %174 = call i32 @cq_template_add_i64(i32 %173, i32 %171)
  %175 = call i32 @cq_template_select_i64(i32 %172, i32 %174, i32 %173)
  call void @cq_template_add_i64_unc(i32 %174, i32 %173, i32 %171)
  call void @cqrt_free(i32 %174)
  %176 = call i32 @cq_template_sub_i64(i32 %175, i32 %171)
  %177 = call i32 @cq_template_select_i64(i32 %172, i32 %176, i32 %175)
  call void @cqrt_copy_i64(i32 %177, i32 %173)
  call void @cq_template_select_i64_unc(i32 %177, i32 %172, i32 %176, i32 %175)
  call void @cqrt_free(i32 %177)
  call void @cq_template_sub_i64_unc(i32 %176, i32 %175, i32 %171)
  call void @cqrt_free(i32 %176)
  call void @cqrt_free(i32 %173)
  call void @cqrt_qram_swap_i64_controlled(i32 %172, i32 %17, i32 %29, i32 %175)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %172)
  call void @cqrt_free(i32 %172)
  call void @cqrt_free(i32 %175)
  %178 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %178)
  %179 = call i32 @cqrt_qram_load_i64_controlled(i32 %178, i32 %17, i32 %29)
  %180 = call i32 @cq_template_icmp_ult_i64(i32 %179, i32 %171)
  br label %181

181:                                              ; preds = %167
  %182 = call i32 @cqrt_alloc_i1(i1 false)
  %183 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %180, i32 %22, i32 %183)
  call void @cqrt_and_i1(i32 %0, i32 %183, i32 %182)
  %184 = icmp ult i32 0, %10
  br i1 %184, label %185, label %201

185:                                              ; preds = %185, %181
  %from = phi i32 [ 0, %185 ], [ 1, %181 ]
  %186 = phi i32 [ 0, %181 ], [ %199, %185 ]
  %187 = phi i32 [ %182, %181 ], [ %197, %185 ]
  %188 = phi i32 [ %29, %181 ], [ %198, %185 ]
  call void @cqrt_push(i32 %from)
  %189 = call i32 @cq_template_add_i64_hl(i32 %188, i64 8)
  %190 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %187, i32 %17, i32 %189, i32 %190)
  %191 = call i32 @cq_template_add_i64_hl(i32 %190, i64 1)
  %192 = call i32 @cq_template_select_i64(i32 %187, i32 %191, i32 %190)
  call void @cq_template_add_i64_hl_unc(i32 %191, i32 %190, i64 1)
  call void @cqrt_free(i32 %191)
  %193 = call i32 @cq_template_sub_i64_hl(i32 %192, i64 1)
  %194 = call i32 @cq_template_select_i64(i32 %187, i32 %193, i32 %192)
  call void @cqrt_copy_i64(i32 %194, i32 %190)
  call void @cq_template_select_i64_unc(i32 %194, i32 %187, i32 %193, i32 %192)
  call void @cqrt_free(i32 %194)
  call void @cq_template_sub_i64_hl_unc(i32 %193, i32 %192, i64 1)
  call void @cqrt_free(i32 %193)
  call void @cqrt_free(i32 %190)
  call void @cqrt_qram_swap_i64_controlled(i32 %187, i32 %17, i32 %189, i32 %192)
  call void @cqrt_free(i32 %192)
  %195 = call i32 @cqrt_qram_load_i64_controlled(i32 %187, i32 %17, i32 %189)
  %196 = call i32 @cq_template_icmp_eq_i64_hl(i32 %195, i64 0)
  %197 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %187, i32 %196, i32 %197)
  %198 = call i32 @cq_template_select_i64(i32 %187, i32 %189, i32 %188)
  %199 = add i32 %186, 1
  %200 = icmp ult i32 %199, %10
  call void @cqrt_push(i32 %198)
  call void @cqrt_push(i32 %187)
  call void @cqrt_push(i32 %189)
  call void @cqrt_push(i32 %188)
  call void @cqrt_push(i32 %196)
  call void @cqrt_push(i32 %197)
  call void @cqrt_push(i32 %195)
  br i1 %200, label %185, label %201

201:                                              ; preds = %185, %181
  %202 = phi i32 [ 0, %181 ], [ 1, %185 ]
  %203 = phi i32 [ %29, %181 ], [ %198, %185 ]
  %204 = phi i32 [ %182, %181 ], [ %197, %185 ]
  %205 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %204, i32 %205)
  br label %225

206:                                              ; preds = %225, %216
  %207 = call i32 @cq_template_select_i64(i32 %22, i32 %24, i32 %6)
  %208 = call i32 @cq_template_select_i64(i32 %22, i32 %29, i32 %5)
  %209 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %3, i64 0)
  %210 = call i32 @cq_template_icmp_eq_i64_hl(i32 %4, i64 -1)
  %211 = call i32 @cq_template_add_i64_hl(i32 %3, i64 -1)
  %212 = call i32 @cq_template_add_i64_hl(i32 %4, i64 1)
  %213 = call i32 @cq_template_add_i64_hl(i32 %4, i64 1)
  %214 = call i32 @cq_template_shl_i64_hl(i32 %4, i64 3)
  %215 = call i32 @cq_template_add_i64_hl(i32 %214, i64 8)
  br label %226

216:                                              ; preds = %225, %216
  %217 = call i32 @cqrt_pop()
  %218 = call i32 @cqrt_pop()
  %219 = call i32 @cqrt_pop()
  %220 = call i32 @cqrt_pop()
  %221 = call i32 @cqrt_pop()
  %222 = call i32 @cqrt_pop()
  %223 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %223, i32 %222, i32 %221, i32 %220)
  call void @cqrt_free(i32 %223)
  call void @cqrt_and_i1(i32 %222, i32 %219, i32 %218)
  call void @cqrt_free(i32 %218)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %219, i32 %217, i64 0)
  call void @cqrt_free(i32 %219)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %217, i32 %222, i32 %17, i32 %221)
  call void @cq_template_add_i64_hl_unc(i32 %221, i32 %220, i64 8)
  call void @cqrt_free(i32 %221)
  %224 = call i32 @cqrt_pop()
  switch i32 %224, label %216 [
    i32 1, label %206
  ]

225:                                              ; preds = %201
  switch i32 %202, label %206 [
    i32 1, label %216
  ]

226:                                              ; preds = %206
  %227 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %209, i32 %227)
  %228 = icmp ult i32 0, %10
  br i1 %228, label %229, label %247

229:                                              ; preds = %342, %226
  %from3 = phi i32 [ 0, %342 ], [ 1, %226 ]
  %230 = phi i32 [ 0, %226 ], [ %358, %342 ]
  %231 = phi i32 [ %227, %226 ], [ %354, %342 ]
  %232 = phi i32 [ %1, %226 ], [ %355, %342 ]
  %233 = phi i32 [ %208, %226 ], [ %356, %342 ]
  %234 = phi i32 [ %207, %226 ], [ %357, %342 ]
  %235 = phi i64 [ 0, %226 ], [ %351, %342 ]
  %236 = mul i64 %235, 8
  %237 = call i32 @cq_template_add_i64_hl(i32 %2, i64 %236)
  %238 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %232, i32 %238)
  %239 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %231, i32 %239)
  call void @cqrt_qram_store_i64_controlled(i32 %239, i32 %17, i32 %237, i32 %238)
  %240 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %234, i64 0)
  %241 = call i32 @cqrt_alloc_i1(i1 false)
  %242 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %242)
  call void @cqrt_xor_i1(i32 %240, i32 %242)
  call void @cqrt_xor_i1(i32 %242, i32 %241)
  call void @cqrt_and_i1(i32 %242, i32 %210, i32 %241)
  %243 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %241, i32 %243)
  %244 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %215, i64 4096)
  %245 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %244, i32 %243, i32 %245)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %244, i32 %215, i64 4096)
  call void @cqrt_free(i32 %244)
  %246 = call i32 @cqrt_alloc_i8(i8 0)
  br label %256

247:                                              ; preds = %342, %226
  %248 = phi i32 [ 0, %226 ], [ 1, %342 ]
  %249 = phi i32 [ %1, %226 ], [ %355, %342 ]
  %250 = phi i32 [ %208, %226 ], [ %356, %342 ]
  %251 = phi i32 [ %207, %226 ], [ %357, %342 ]
  %252 = phi i64 [ 0, %226 ], [ %351, %342 ]
  %253 = phi i32 [ %227, %226 ], [ %354, %342 ]
  %254 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %253, i32 %254)
  %255 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %251, i32 %255)
  br label %363

256:                                              ; preds = %256, %229
  %257 = phi i64 [ 0, %229 ], [ %261, %256 ]
  %258 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %215, i64 %257)
  %259 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %258, i32 %243, i32 %259)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %258, i32 %215, i64 %257)
  call void @cqrt_free(i32 %258)
  %260 = call i32 @cq_template_add_i64_hl(i32 %232, i64 %257)
  call void @cqrt_qram_store_i8_controlled(i32 %259, i32 %17, i32 %260, i32 %246)
  call void @cq_template_add_i64_hl_unc(i32 %260, i32 %232, i64 %257)
  call void @cqrt_free(i32 %260)
  %261 = add nuw i64 %257, 1
  %262 = icmp eq i64 %261, 4096
  br i1 %262, label %263, label %256

263:                                              ; preds = %256
  br label %264

264:                                              ; preds = %263
  call void @cqrt_push(i32 %from3)
  %265 = call i32 @cq_template_icmp_sge_i64(i32 %234, i32 %7)
  %266 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %211, i64 %235)
  %267 = call i32 @cq_template_select_i1_hl(i32 %265, i32 %266, i1 false)
  %268 = call i32 @cq_template_select_i64(i32 %267, i32 %7, i32 %234)
  %269 = call i32 @cq_template_sub_i64(i32 %234, i32 %268)
  %270 = call i32 @cq_template_icmp_eq_i64_hl(i32 %268, i64 0)
  %271 = call i32 @cq_template_add_i64_hl(i32 %268, i64 -1)
  %272 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %240, i32 %272)
  call void @cqrt_and_i1(i32 %240, i32 %270, i32 %272)
  %273 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %272, i32 %273)
  %274 = call i32 @cqrt_qram_load_i64_controlled(i32 %273, i32 %17, i32 %233)
  %275 = call i32 @cq_template_icmp_eq_i64_hl(i32 %271, i64 0)
  %276 = call i32 @cqrt_alloc_i1(i1 false)
  %277 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %240, i32 %277)
  call void @cqrt_and_i1(i32 %240, i32 %270, i32 %277)
  call void @cqrt_xor_i1(i32 %277, i32 %276)
  call void @cqrt_and_i1(i32 %277, i32 %275, i32 %276)
  %278 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %276, i32 %278)
  %279 = icmp ult i32 0, %10
  call void @cqrt_push(i32 %231)
  call void @cqrt_push(i32 %276)
  call void @cqrt_push(i32 %278)
  call void @cqrt_push(i32 %277)
  call void @cqrt_push(i32 %275)
  call void @cqrt_push(i32 %240)
  call void @cqrt_push(i32 %270)
  call void @cqrt_push(i32 %271)
  call void @cqrt_push(i32 %274)
  call void @cqrt_push(i32 %273)
  call void @cqrt_push(i32 %233)
  call void @cqrt_push(i32 %272)
  call void @cqrt_push(i32 %268)
  call void @cqrt_push(i32 %269)
  call void @cqrt_push(i32 %234)
  call void @cqrt_push(i32 %267)
  call void @cqrt_push(i32 %265)
  call void @cqrt_push(i32 %266)
  %280 = trunc i64 %235 to i32
  call void @cqrt_push(i32 %280)
  %281 = lshr i64 %235, 32
  %282 = trunc i64 %281 to i32
  call void @cqrt_push(i32 %282)
  call void @cqrt_push(i32 %241)
  call void @cqrt_push(i32 %243)
  call void @cqrt_push(i32 %242)
  call void @cqrt_push(i32 %237)
  %283 = trunc i64 %236 to i32
  call void @cqrt_push(i32 %283)
  %284 = lshr i64 %236, 32
  %285 = trunc i64 %284 to i32
  call void @cqrt_push(i32 %285)
  br i1 %279, label %286, label %313

286:                                              ; preds = %286, %264
  %from2 = phi i32 [ 0, %286 ], [ 1, %264 ]
  %287 = phi i32 [ 0, %264 ], [ %308, %286 ]
  %288 = phi i32 [ %278, %264 ], [ %302, %286 ]
  %289 = phi i32 [ %271, %264 ], [ %304, %286 ]
  %290 = phi i32 [ %9, %264 ], [ %305, %286 ]
  %291 = phi i32 [ %233, %264 ], [ %306, %286 ]
  %292 = phi i32 [ %274, %264 ], [ %307, %286 ]
  %293 = phi i64 [ 0, %264 ], [ %303, %286 ]
  call void @cqrt_push(i32 %from2)
  %294 = call i32 @cq_template_add_i64_hl(i32 %291, i64 8)
  %295 = call i32 @cq_template_add_i64_hl(i32 %290, i64 8)
  %296 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %292, i32 %296)
  %297 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %288, i32 %297)
  call void @cqrt_qram_store_i64_controlled(i32 %297, i32 %17, i32 %290, i32 %296)
  %298 = call i32 @cqrt_qram_load_i64_controlled(i32 %288, i32 %17, i32 %294)
  %299 = call i32 @cq_template_add_i64_hl(i32 %289, i64 -1)
  %300 = call i32 @cq_template_icmp_eq_i64_hl(i32 %299, i64 0)
  %301 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %301)
  call void @cqrt_xor_i1(i32 %300, i32 %301)
  %302 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %288, i32 %301, i32 %302)
  %303 = add i64 %293, -1
  %304 = call i32 @cq_template_add_i64_hl(i32 %271, i64 %303)
  %305 = call i32 @cq_template_select_i64(i32 %288, i32 %295, i32 %290)
  %306 = call i32 @cq_template_select_i64(i32 %288, i32 %294, i32 %291)
  %307 = call i32 @cq_template_select_i64(i32 %288, i32 %298, i32 %292)
  %308 = add i32 %287, 1
  %309 = icmp ult i32 %308, %10
  call void @cqrt_push(i32 %307)
  call void @cqrt_push(i32 %288)
  call void @cqrt_push(i32 %298)
  call void @cqrt_push(i32 %292)
  call void @cqrt_push(i32 %306)
  call void @cqrt_push(i32 %294)
  call void @cqrt_push(i32 %291)
  call void @cqrt_push(i32 %305)
  call void @cqrt_push(i32 %295)
  call void @cqrt_push(i32 %290)
  call void @cqrt_push(i32 %304)
  call void @cqrt_push(i32 %271)
  %310 = trunc i64 %303 to i32
  call void @cqrt_push(i32 %310)
  %311 = lshr i64 %303, 32
  %312 = trunc i64 %311 to i32
  call void @cqrt_push(i32 %312)
  call void @cqrt_push(i32 %301)
  call void @cqrt_push(i32 %302)
  call void @cqrt_push(i32 %300)
  call void @cqrt_push(i32 %299)
  call void @cqrt_push(i32 %289)
  br i1 %309, label %286, label %313

313:                                              ; preds = %286, %264
  %from1 = phi i32 [ 0, %286 ], [ 1, %264 ]
  %314 = phi i32 [ %271, %264 ], [ %304, %286 ]
  %315 = phi i32 [ %9, %264 ], [ %305, %286 ]
  %316 = phi i32 [ %233, %264 ], [ %306, %286 ]
  %317 = phi i32 [ %274, %264 ], [ %307, %286 ]
  %318 = phi i64 [ 0, %264 ], [ %303, %286 ]
  %319 = phi i32 [ %278, %264 ], [ %302, %286 ]
  %320 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %319, i32 %320)
  %321 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %317, i32 %321)
  %322 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %240, i32 %322)
  call void @cqrt_and_i1(i32 %240, i32 %270, i32 %322)
  %323 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %322, i32 %323)
  call void @cqrt_qram_store_i64_controlled(i32 %323, i32 %17, i32 %315, i32 %321)
  %324 = call i32 @cq_template_icmp_eq_i64(i32 %212, i32 %268)
  %325 = call i32 @cq_template_sub_i64(i32 %212, i32 %268)
  %326 = call i32 @cq_template_mul_i64_hl(i32 %268, i64 8)
  %327 = call i32 @cq_template_add_i64(i32 %9, i32 %326)
  %328 = call i32 @cq_template_shl_i64_hl(i32 %325, i64 3)
  %329 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %240, i32 %329)
  call void @cqrt_and_i1(i32 %240, i32 %324, i32 %329)
  %330 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %329, i32 %330)
  %331 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %328, i64 4096)
  %332 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %331, i32 %330, i32 %332)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %331, i32 %328, i64 4096)
  call void @cqrt_free(i32 %331)
  %333 = call i32 @cqrt_alloc_i8(i8 0)
  br label %334

334:                                              ; preds = %334, %313
  %335 = phi i64 [ 0, %313 ], [ %339, %334 ]
  %336 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %328, i64 %335)
  %337 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %336, i32 %330, i32 %337)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %336, i32 %328, i64 %335)
  call void @cqrt_free(i32 %336)
  %338 = call i32 @cq_template_add_i64_hl(i32 %327, i64 %335)
  call void @cqrt_qram_store_i8_controlled(i32 %337, i32 %17, i32 %338, i32 %333)
  call void @cq_template_add_i64_hl_unc(i32 %338, i32 %327, i64 %335)
  call void @cqrt_free(i32 %338)
  %339 = add nuw i64 %335, 1
  %340 = icmp eq i64 %339, 4096
  br i1 %340, label %341, label %334

341:                                              ; preds = %334
  br label %342

342:                                              ; preds = %341
  call void @cqrt_push(i32 %from1)
  %343 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 8)
  %344 = call i32 @cq_template_add_i64(i32 %233, i32 %343)
  %345 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 %235)
  %346 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %240, i32 %346)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl(i32 %346, i32 %232, i32 %9, i32 %345, i32 %4, i32 %10)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl_unc(i32 %346, i32 %232, i32 %9, i32 %345, i32 %4, i32 %10)
  call void @cqrt_and_i1(i32 %231, i32 %240, i32 %346)
  call void @cqrt_free(i32 %346)
  call void @cq_template_mul_i64_hl_unc(i32 %345, i32 %8, i64 %235)
  call void @cqrt_free(i32 %345)
  %347 = call i32 @cq_template_select_i64(i32 %240, i32 %269, i32 %234)
  %348 = call i32 @cq_template_select_i64(i32 %240, i32 %344, i32 %233)
  %349 = call i32 @cq_template_mul_i64_hl(i32 %213, i64 8)
  %350 = call i32 @cq_template_add_i64(i32 %232, i32 %349)
  %351 = add i64 %235, 1
  %352 = call i32 @cq_template_icmp_eq_i64_hl(i32 %3, i64 %351)
  %353 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %353)
  call void @cqrt_xor_i1(i32 %352, i32 %353)
  %354 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %231, i32 %353, i32 %354)
  %355 = call i32 @cq_template_select_i64(i32 %231, i32 %350, i32 %232)
  %356 = call i32 @cq_template_select_i64(i32 %231, i32 %348, i32 %233)
  %357 = call i32 @cq_template_select_i64(i32 %231, i32 %347, i32 %234)
  %358 = add i32 %230, 1
  %359 = icmp ult i32 %358, %10
  call void @cqrt_push(i32 %357)
  call void @cqrt_push(i32 %231)
  call void @cqrt_push(i32 %347)
  call void @cqrt_push(i32 %234)
  call void @cqrt_push(i32 %356)
  call void @cqrt_push(i32 %348)
  call void @cqrt_push(i32 %233)
  call void @cqrt_push(i32 %355)
  call void @cqrt_push(i32 %350)
  call void @cqrt_push(i32 %232)
  call void @cqrt_push(i32 %353)
  call void @cqrt_push(i32 %354)
  call void @cqrt_push(i32 %352)
  %360 = trunc i64 %351 to i32
  call void @cqrt_push(i32 %360)
  %361 = lshr i64 %351, 32
  %362 = trunc i64 %361 to i32
  call void @cqrt_push(i32 %362)
  call void @cqrt_push(i32 %349)
  call void @cqrt_push(i32 %240)
  call void @cqrt_push(i32 %344)
  call void @cqrt_push(i32 %269)
  call void @cqrt_push(i32 %343)
  call void @cqrt_push(i32 %329)
  call void @cqrt_push(i32 %330)
  call void @cqrt_push(i32 %324)
  call void @cqrt_push(i32 %328)
  call void @cqrt_push(i32 %325)
  call void @cqrt_push(i32 %327)
  call void @cqrt_push(i32 %326)
  call void @cqrt_push(i32 %268)
  call void @cqrt_push(i32 %270)
  call void @cqrt_push(i32 %322)
  br i1 %359, label %229, label %247

363:                                              ; preds = %247
  %364 = call i32 @cq_template_icmp_eq_i64_hl(i32 %255, i64 0)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %364, i32 %255, i64 0)
  call void @cqrt_free(i32 %364)
  br label %473

365:                                              ; preds = %371
  call void @cqrt_and_i1(i32 %0, i32 %209, i32 %227)
  call void @cqrt_free(i32 %227)
  call void @cq_template_add_i64_hl_unc(i32 %215, i32 %214, i64 8)
  call void @cqrt_free(i32 %215)
  call void @cq_template_shl_i64_hl_unc(i32 %214, i32 %4, i64 3)
  call void @cqrt_free(i32 %214)
  call void @cq_template_add_i64_hl_unc(i32 %213, i32 %4, i64 1)
  call void @cqrt_free(i32 %213)
  call void @cq_template_add_i64_hl_unc(i32 %212, i32 %4, i64 1)
  call void @cqrt_free(i32 %212)
  call void @cq_template_add_i64_hl_unc(i32 %211, i32 %3, i64 -1)
  call void @cqrt_free(i32 %211)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %210, i32 %4, i64 -1)
  call void @cqrt_free(i32 %210)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %209, i32 %3, i64 0)
  call void @cqrt_free(i32 %209)
  call void @cq_template_select_i64_unc(i32 %208, i32 %22, i32 %29, i32 %5)
  call void @cqrt_free(i32 %208)
  call void @cq_template_select_i64_unc(i32 %207, i32 %22, i32 %24, i32 %6)
  call void @cqrt_free(i32 %207)
  call void @cqrt_and_i1(i32 %0, i32 %183, i32 %182)
  call void @cqrt_free(i32 %182)
  call void @cqrt_and_i1(i32 %180, i32 %22, i32 %183)
  call void @cqrt_free(i32 %183)
  call void @cq_template_icmp_ult_i64_unc(i32 %180, i32 %179, i32 %171)
  call void @cqrt_free(i32 %180)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %179, i32 %178, i32 %17, i32 %29)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %178)
  call void @cqrt_free(i32 %178)
  call void @cq_template_select_i64_lh_unc(i32 %171, i32 %168, i64 0, i32 %112)
  call void @cqrt_free(i32 %171)
  call void @cqrt_and_i1(i32 %114, i32 %169, i32 %168)
  call void @cqrt_not_i1(i32 %168)
  call void @cqrt_free(i32 %168)
  call void @cqrt_and_i1(i32 %170, i32 %41, i32 %169)
  call void @cqrt_xor_i1(i32 %170, i32 %169)
  call void @cqrt_free(i32 %169)
  call void @cqrt_xor_i1(i32 %35, i32 %170)
  call void @cqrt_not_i1(i32 %170)
  call void @cqrt_free(i32 %170)
  call void @cqrt_and_i1(i32 %0, i32 %143, i32 %142)
  call void @cqrt_free(i32 %142)
  call void @cqrt_and_i1(i32 %135, i32 %144, i32 %143)
  call void @cqrt_free(i32 %143)
  call void @cqrt_and_i1(i32 %114, i32 %145, i32 %144)
  call void @cqrt_xor_i1(i32 %22, i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cqrt_and_i1(i32 %146, i32 %41, i32 %145)
  call void @cqrt_xor_i1(i32 %146, i32 %145)
  call void @cqrt_free(i32 %145)
  call void @cqrt_and_i1(i32 %22, i32 %35, i32 %146)
  call void @cqrt_xor_i1(i32 %22, i32 %146)
  call void @cqrt_free(i32 %146)
  call void @cqrt_and_i1(i32 %133, i32 %134, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cq_template_icmp_slt_i64_unc(i32 %134, i32 %132, i32 %19)
  call void @cqrt_free(i32 %134)
  call void @cq_template_icmp_ne_i64_unc(i32 %133, i32 %29, i32 %5)
  call void @cqrt_free(i32 %133)
  call void @cq_template_select_i64_lh_unc(i32 %132, i32 %35, i64 0, i32 %131)
  call void @cqrt_free(i32 %132)
  call void @cq_template_select_i64_unc(i32 %131, i32 %41, i32 %23, i32 %113)
  call void @cqrt_free(i32 %131)
  br label %531

366:                                              ; preds = %475
  call void @cqrt_and_i1(i32 %43, i32 %49, i32 %62)
  call void @cqrt_free(i32 %62)
  call void @cq_template_select_i1_unc(i32 %61, i32 %60, i32 %58, i32 %48)
  call void @cqrt_free(i32 %61)
  call void @cqrt_and_i1(i32 %43, i32 %59, i32 %60)
  call void @cqrt_free(i32 %60)
  call void @cqrt_xor_i1(i32 %49, i32 %59)
  call void @cqrt_not_i1(i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cqrt_free(i32 %58)
  call void @cq_template_select_i64_unc(i32 %57, i32 %56, i32 %54, i32 %47)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %43, i32 %55, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_xor_i1(i32 %49, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cqrt_free(i32 %54)
  call void @cq_template_select_i64_unc(i32 %53, i32 %52, i32 %50, i32 %46)
  call void @cqrt_free(i32 %53)
  call void @cqrt_and_i1(i32 %43, i32 %51, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cqrt_xor_i1(i32 %49, i32 %51)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cqrt_free(i32 %50)
  call void @cq_template_icmp_slt_i64_unc(i32 %49, i32 %23, i32 %19)
  call void @cqrt_free(i32 %49)
  call void @cqrt_free(i32 %48)
  call void @cqrt_free(i32 %47)
  call void @cqrt_free(i32 %46)
  call void @cqrt_and_i1(i32 %0, i32 %44, i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cqrt_and_i1(i32 %45, i32 %41, i32 %44)
  call void @cqrt_xor_i1(i32 %45, i32 %44)
  call void @cqrt_free(i32 %44)
  call void @cqrt_and_i1(i32 %22, i32 %35, i32 %45)
  call void @cqrt_xor_i1(i32 %22, i32 %45)
  call void @cqrt_free(i32 %45)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %41, i32 %40, i64 0)
  call void @cqrt_free(i32 %41)
  call void @__cq_q___gmpn_sub_n_1111_t_ctl_unc(i32 %38, i32 %40, i32 %29, i32 %5, i32 %37, i32 %23, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %39, i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cqrt_and_i1(i32 %22, i32 %35, i32 %39)
  call void @cqrt_xor_i1(i32 %22, i32 %39)
  call void @cqrt_free(i32 %39)
  call void @cq_template_add_i64_unc(i32 %37, i32 %5, i32 %36)
  call void @cqrt_free(i32 %37)
  call void @cq_template_mul_i64_hl_unc(i32 %36, i32 %19, i64 8)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %35, i32 %23, i64 0)
  call void @cqrt_free(i32 %35)
  call void @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl_unc(i32 %26, i32 %29, i32 %28, i32 %25, i32 %10)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %22, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_shl_i64_hl_unc(i32 %25, i32 %24, i64 3)
  call void @cqrt_free(i32 %25)
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %19, i64 1)
  call void @cqrt_free(i32 %24)
  call void @cq_template_sub_i64_unc(i32 %23, i32 %6, i32 %19)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_slt_i64_unc(i32 %22, i32 %19, i32 %6)
  call void @cqrt_free(i32 %22)
  call void @cq_template_mul_i64_unc(i32 %19, i32 %7, i32 %3)
  call void @cqrt_free(i32 %19)
  %367 = ptrtoint ptr %18 to i64
  %368 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %17, i64 %367)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_ctl(i32 %0, i32 %368, i32 %10)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_ctl_unc(i32 %0, i32 %368, i32 %10)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %368, i32 %0, i32 %17, i64 %367)
  %369 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %370 = add i32 %369, -1
  store i32 %370, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  store i32 %12, ptr @__cq_k, align 4
  ret void

371:                                              ; preds = %474, %372
  br label %365

372:                                              ; preds = %410, %436
  %373 = call i32 @cqrt_pop()
  %374 = zext i32 %373 to i64
  %375 = shl i64 %374, 32
  %376 = or i64 0, %375
  %377 = call i32 @cqrt_pop()
  %378 = zext i32 %377 to i64
  %379 = or i64 %376, %378
  %380 = call i32 @cqrt_pop()
  %381 = call i32 @cqrt_pop()
  %382 = call i32 @cqrt_pop()
  %383 = call i32 @cqrt_pop()
  %384 = call i32 @cqrt_pop()
  %385 = zext i32 %384 to i64
  %386 = shl i64 %385, 32
  %387 = or i64 0, %386
  %388 = call i32 @cqrt_pop()
  %389 = zext i32 %388 to i64
  %390 = or i64 %387, %389
  %391 = call i32 @cqrt_pop()
  %392 = call i32 @cqrt_pop()
  %393 = call i32 @cqrt_pop()
  %394 = call i32 @cqrt_pop()
  %395 = call i32 @cqrt_pop()
  %396 = call i32 @cqrt_pop()
  %397 = call i32 @cqrt_pop()
  %398 = call i32 @cqrt_pop()
  %399 = call i32 @cqrt_pop()
  %400 = call i32 @cqrt_pop()
  %401 = call i32 @cqrt_pop()
  %402 = call i32 @cqrt_pop()
  %403 = call i32 @cqrt_pop()
  %404 = call i32 @cqrt_pop()
  %405 = call i32 @cqrt_pop()
  %406 = call i32 @cqrt_pop()
  %407 = call i32 @cqrt_pop()
  %408 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %408, i32 %407, i32 %406)
  call void @cqrt_free(i32 %406)
  call void @cqrt_and_i1(i32 %405, i32 %404, i32 %407)
  call void @cqrt_xor_i1(i32 %405, i32 %407)
  call void @cqrt_free(i32 %407)
  call void @cqrt_and_i1(i32 %403, i32 %402, i32 %405)
  call void @cqrt_xor_i1(i32 %403, i32 %405)
  call void @cqrt_free(i32 %405)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %404, i32 %401, i64 0)
  call void @cqrt_free(i32 %404)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %400, i32 %399, i32 %17, i32 %398)
  call void @cqrt_and_i1(i32 %408, i32 %397, i32 %399)
  call void @cqrt_free(i32 %399)
  call void @cqrt_and_i1(i32 %403, i32 %402, i32 %397)
  call void @cqrt_xor_i1(i32 %403, i32 %397)
  call void @cqrt_free(i32 %397)
  call void @cq_template_add_i64_hl_unc(i32 %401, i32 %396, i64 -1)
  call void @cqrt_free(i32 %401)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %402, i32 %396, i64 0)
  call void @cqrt_free(i32 %402)
  call void @cq_template_sub_i64_unc(i32 %395, i32 %394, i32 %396)
  call void @cqrt_free(i32 %395)
  call void @cq_template_select_i64_unc(i32 %396, i32 %393, i32 %7, i32 %394)
  call void @cqrt_free(i32 %396)
  call void @cq_template_select_i1_hl_unc(i32 %393, i32 %392, i32 %391, i1 false)
  call void @cqrt_free(i32 %393)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %391, i32 %211, i64 %390)
  call void @cqrt_free(i32 %391)
  call void @cq_template_icmp_sge_i64_unc(i32 %392, i32 %394, i32 %7)
  call void @cqrt_free(i32 %392)
  call void @cqrt_and_i1(i32 %408, i32 %383, i32 %382)
  call void @cqrt_free(i32 %382)
  call void @cqrt_and_i1(i32 %381, i32 %210, i32 %383)
  call void @cqrt_xor_i1(i32 %381, i32 %383)
  call void @cqrt_free(i32 %383)
  call void @cqrt_xor_i1(i32 %403, i32 %381)
  call void @cqrt_not_i1(i32 %381)
  call void @cqrt_free(i32 %381)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %403, i32 %394, i64 0)
  call void @cqrt_free(i32 %403)
  call void @cq_template_add_i64_hl_unc(i32 %380, i32 %2, i64 %379)
  call void @cqrt_free(i32 %380)
  %409 = call i32 @cqrt_pop()
  switch i32 %409, label %436 [
    i32 1, label %371
  ]

410:                                              ; preds = %410, %436
  %411 = call i32 @cqrt_pop()
  %412 = call i32 @cqrt_pop()
  %413 = call i32 @cqrt_pop()
  %414 = call i32 @cqrt_pop()
  %415 = call i32 @cqrt_pop()
  %416 = call i32 @cqrt_pop()
  %417 = zext i32 %416 to i64
  %418 = shl i64 %417, 32
  %419 = or i64 0, %418
  %420 = call i32 @cqrt_pop()
  %421 = zext i32 %420 to i64
  %422 = or i64 %419, %421
  %423 = call i32 @cqrt_pop()
  %424 = call i32 @cqrt_pop()
  %425 = call i32 @cqrt_pop()
  %426 = call i32 @cqrt_pop()
  %427 = call i32 @cqrt_pop()
  %428 = call i32 @cqrt_pop()
  %429 = call i32 @cqrt_pop()
  %430 = call i32 @cqrt_pop()
  %431 = call i32 @cqrt_pop()
  %432 = call i32 @cqrt_pop()
  %433 = call i32 @cqrt_pop()
  %434 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %434, i32 %433, i32 %432, i32 %431)
  call void @cqrt_free(i32 %434)
  call void @cq_template_select_i64_unc(i32 %430, i32 %433, i32 %429, i32 %428)
  call void @cqrt_free(i32 %430)
  call void @cq_template_select_i64_unc(i32 %427, i32 %433, i32 %426, i32 %425)
  call void @cqrt_free(i32 %427)
  call void @cq_template_add_i64_hl_unc(i32 %424, i32 %423, i64 %422)
  call void @cqrt_free(i32 %424)
  call void @cqrt_and_i1(i32 %433, i32 %415, i32 %414)
  call void @cqrt_free(i32 %414)
  call void @cqrt_xor_i1(i32 %413, i32 %415)
  call void @cqrt_not_i1(i32 %415)
  call void @cqrt_free(i32 %415)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %413, i32 %412, i64 0)
  call void @cqrt_free(i32 %413)
  call void @cq_template_add_i64_hl_unc(i32 %412, i32 %411, i64 -1)
  call void @cqrt_free(i32 %412)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %432, i32 %433, i32 %17, i32 %429)
  call void @cq_template_add_i64_hl_unc(i32 %426, i32 %425, i64 8)
  call void @cqrt_free(i32 %426)
  call void @cq_template_add_i64_hl_unc(i32 %429, i32 %428, i64 8)
  call void @cqrt_free(i32 %429)
  %435 = call i32 @cqrt_pop()
  switch i32 %435, label %410 [
    i32 1, label %372
  ]

436:                                              ; preds = %474, %372
  %437 = call i32 @cqrt_pop()
  %438 = call i32 @cqrt_pop()
  %439 = call i32 @cqrt_pop()
  %440 = call i32 @cqrt_pop()
  %441 = call i32 @cqrt_pop()
  %442 = call i32 @cqrt_pop()
  %443 = call i32 @cqrt_pop()
  %444 = call i32 @cqrt_pop()
  %445 = call i32 @cqrt_pop()
  %446 = call i32 @cqrt_pop()
  %447 = call i32 @cqrt_pop()
  %448 = call i32 @cqrt_pop()
  %449 = call i32 @cqrt_pop()
  %450 = call i32 @cqrt_pop()
  %451 = call i32 @cqrt_pop()
  %452 = call i32 @cqrt_pop()
  %453 = zext i32 %452 to i64
  %454 = shl i64 %453, 32
  %455 = or i64 0, %454
  %456 = call i32 @cqrt_pop()
  %457 = zext i32 %456 to i64
  %458 = or i64 %455, %457
  %459 = call i32 @cqrt_pop()
  %460 = call i32 @cqrt_pop()
  %461 = call i32 @cqrt_pop()
  %462 = call i32 @cqrt_pop()
  %463 = call i32 @cqrt_pop()
  %464 = call i32 @cqrt_pop()
  %465 = call i32 @cqrt_pop()
  %466 = call i32 @cqrt_pop()
  %467 = call i32 @cqrt_pop()
  %468 = call i32 @cqrt_pop()
  %469 = call i32 @cqrt_pop()
  %470 = call i32 @cqrt_pop()
  %471 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %471, i32 %470, i32 %469, i32 %468)
  call void @cqrt_free(i32 %471)
  call void @cq_template_select_i64_unc(i32 %467, i32 %470, i32 %466, i32 %465)
  call void @cqrt_free(i32 %467)
  call void @cq_template_select_i64_unc(i32 %464, i32 %470, i32 %463, i32 %462)
  call void @cqrt_free(i32 %464)
  call void @cqrt_and_i1(i32 %470, i32 %461, i32 %460)
  call void @cqrt_free(i32 %460)
  call void @cqrt_xor_i1(i32 %459, i32 %461)
  call void @cqrt_not_i1(i32 %461)
  call void @cqrt_free(i32 %461)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %459, i32 %3, i64 %458)
  call void @cqrt_free(i32 %459)
  call void @cq_template_add_i64_unc(i32 %463, i32 %462, i32 %451)
  call void @cqrt_free(i32 %463)
  call void @cq_template_mul_i64_hl_unc(i32 %451, i32 %213, i64 8)
  call void @cqrt_free(i32 %451)
  call void @cq_template_select_i64_unc(i32 %466, i32 %450, i32 %449, i32 %465)
  call void @cqrt_free(i32 %466)
  call void @cq_template_select_i64_unc(i32 %469, i32 %450, i32 %448, i32 %468)
  call void @cqrt_free(i32 %469)
  call void @cq_template_add_i64_unc(i32 %449, i32 %465, i32 %447)
  call void @cqrt_free(i32 %449)
  call void @cq_template_mul_i64_hl_unc(i32 %447, i32 %7, i64 8)
  call void @cqrt_free(i32 %447)
  call void @cqrt_and_i1(i32 %470, i32 %446, i32 %445)
  call void @cqrt_free(i32 %445)
  call void @cqrt_and_i1(i32 %450, i32 %444, i32 %446)
  call void @cqrt_xor_i1(i32 %450, i32 %446)
  call void @cqrt_free(i32 %446)
  call void @cq_template_shl_i64_hl_unc(i32 %443, i32 %442, i64 3)
  call void @cqrt_free(i32 %443)
  call void @cq_template_add_i64_unc(i32 %441, i32 %9, i32 %440)
  call void @cqrt_free(i32 %441)
  call void @cq_template_mul_i64_hl_unc(i32 %440, i32 %439, i64 8)
  call void @cqrt_free(i32 %440)
  call void @cq_template_sub_i64_unc(i32 %442, i32 %212, i32 %439)
  call void @cqrt_free(i32 %442)
  call void @cq_template_icmp_eq_i64_unc(i32 %444, i32 %212, i32 %439)
  call void @cqrt_free(i32 %444)
  call void @cqrt_and_i1(i32 %450, i32 %438, i32 %437)
  call void @cqrt_xor_i1(i32 %450, i32 %437)
  call void @cqrt_free(i32 %437)
  %472 = call i32 @cqrt_pop()
  switch i32 %472, label %410 [
    i32 1, label %372
  ]

473:                                              ; preds = %363
  call void @cqrt_copy_i64(i32 %251, i32 %255)
  call void @cqrt_free(i32 %255)
  br label %474

474:                                              ; preds = %473
  switch i32 %248, label %371 [
    i32 1, label %436
  ]

475:                                              ; preds = %532, %476
  br label %366

476:                                              ; preds = %532, %511
  %477 = call i32 @cqrt_pop()
  %478 = call i32 @cqrt_pop()
  %479 = call i32 @cqrt_pop()
  %480 = call i32 @cqrt_pop()
  %481 = call i32 @cqrt_pop()
  %482 = call i32 @cqrt_pop()
  %483 = call i32 @cqrt_pop()
  %484 = call i32 @cqrt_pop()
  %485 = call i32 @cqrt_pop()
  %486 = call i32 @cqrt_pop()
  %487 = call i32 @cqrt_pop()
  %488 = call i32 @cqrt_pop()
  %489 = call i32 @cqrt_pop()
  %490 = call i32 @cqrt_pop()
  %491 = call i32 @cqrt_pop()
  %492 = call i32 @cqrt_pop()
  %493 = call i32 @cqrt_pop()
  %494 = call i32 @cqrt_pop()
  %495 = call i32 @cqrt_pop()
  %496 = call i32 @cqrt_pop()
  %497 = call i32 @cqrt_pop()
  %498 = call i32 @cqrt_pop()
  %499 = call i32 @cqrt_pop()
  %500 = call i32 @cqrt_pop()
  %501 = call i32 @cqrt_pop()
  %502 = call i32 @cqrt_pop()
  %503 = zext i32 %502 to i64
  %504 = shl i64 %503, 32
  %505 = or i64 0, %504
  %506 = call i32 @cqrt_pop()
  %507 = zext i32 %506 to i64
  %508 = or i64 %505, %507
  %509 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %509, i32 %23, i64 %508)
  call void @cqrt_free(i32 %509)
  call void @cqrt_and_i1(i32 %501, i32 %500, i32 %499)
  call void @cqrt_free(i32 %499)
  call void @cqrt_and_i1(i32 %498, i32 %497, i32 %500)
  call void @cqrt_free(i32 %500)
  call void @cq_template_select_i1_unc(i32 %496, i32 %495, i32 %494, i32 %493)
  call void @cqrt_free(i32 %496)
  call void @cqrt_and_i1(i32 %501, i32 %492, i32 %495)
  call void @cqrt_free(i32 %495)
  call void @cqrt_and_i1(i32 %497, i32 %498, i32 %492)
  call void @cqrt_xor_i1(i32 %497, i32 %492)
  call void @cqrt_free(i32 %492)
  call void @cqrt_free(i32 %494)
  call void @cq_template_select_i64_unc(i32 %491, i32 %490, i32 %489, i32 %488)
  call void @cqrt_free(i32 %491)
  call void @cqrt_and_i1(i32 %501, i32 %487, i32 %490)
  call void @cqrt_free(i32 %490)
  call void @cqrt_and_i1(i32 %497, i32 %498, i32 %487)
  call void @cqrt_xor_i1(i32 %497, i32 %487)
  call void @cqrt_free(i32 %487)
  call void @cq_template_select_i64_unc(i32 %486, i32 %485, i32 %484, i32 %483)
  call void @cqrt_free(i32 %486)
  call void @cqrt_and_i1(i32 %501, i32 %482, i32 %485)
  call void @cqrt_free(i32 %485)
  call void @cqrt_and_i1(i32 %497, i32 %498, i32 %482)
  call void @cqrt_xor_i1(i32 %497, i32 %482)
  call void @cqrt_free(i32 %482)
  call void @cqrt_free(i32 %484)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %498, i32 %481, i64 0)
  call void @cqrt_free(i32 %498)
  call void @cq_template_add_i64_hl_unc(i32 %489, i32 %480, i64 1)
  call void @cqrt_free(i32 %489)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %481, i32 %479, i32 %17, i32 %478)
  call void @cq_template_add_i64_unc(i32 %478, i32 %5, i32 %477)
  call void @cqrt_free(i32 %478)
  call void @cq_template_mul_i64_hl_unc(i32 %477, i32 %480, i64 8)
  call void @cqrt_free(i32 %477)
  %510 = call i32 @cqrt_pop()
  switch i32 %510, label %511 [
    i32 1, label %475
  ]

511:                                              ; preds = %476
  %512 = call i32 @cqrt_pop()
  %513 = call i32 @cqrt_pop()
  %514 = call i32 @cqrt_pop()
  %515 = call i32 @cqrt_pop()
  %516 = call i32 @cqrt_pop()
  %517 = call i32 @cqrt_pop()
  %518 = call i32 @cqrt_pop()
  %519 = call i32 @cqrt_pop()
  %520 = call i32 @cqrt_pop()
  %521 = call i32 @cqrt_pop()
  %522 = call i32 @cqrt_pop()
  %523 = call i32 @cqrt_pop()
  %524 = call i32 @cqrt_pop()
  %525 = call i32 @cqrt_pop()
  %526 = call i32 @cqrt_pop()
  %527 = call i32 @cqrt_pop()
  %528 = call i32 @cqrt_pop()
  %529 = call i32 @cqrt_pop()
  %530 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %530, i32 %529, i32 %528)
  call void @cqrt_free(i32 %528)
  call void @cq_template_select_i1_unc(i32 %527, i32 %526, i32 %525, i32 %524)
  call void @cqrt_free(i32 %527)
  call void @cqrt_and_i1(i32 %530, i32 %523, i32 %526)
  call void @cqrt_free(i32 %526)
  call void @cqrt_xor_i1(i32 %529, i32 %523)
  call void @cqrt_not_i1(i32 %523)
  call void @cqrt_free(i32 %523)
  call void @cqrt_free(i32 %525)
  call void @cq_template_select_i64_unc(i32 %522, i32 %521, i32 %520, i32 %519)
  call void @cqrt_free(i32 %522)
  call void @cqrt_and_i1(i32 %530, i32 %518, i32 %521)
  call void @cqrt_free(i32 %521)
  call void @cqrt_xor_i1(i32 %529, i32 %518)
  call void @cqrt_not_i1(i32 %518)
  call void @cqrt_free(i32 %518)
  call void @cqrt_free(i32 %520)
  call void @cq_template_select_i64_unc(i32 %517, i32 %516, i32 %515, i32 %514)
  call void @cqrt_free(i32 %517)
  call void @cqrt_and_i1(i32 %530, i32 %513, i32 %516)
  call void @cqrt_free(i32 %516)
  call void @cqrt_xor_i1(i32 %529, i32 %513)
  call void @cqrt_not_i1(i32 %513)
  call void @cqrt_free(i32 %513)
  call void @cqrt_free(i32 %515)
  call void @cq_template_icmp_slt_i64_unc(i32 %529, i32 %512, i32 %19)
  call void @cqrt_free(i32 %529)
  br label %476

531:                                              ; preds = %365
  call void @cqrt_copy_i1(i32 %109, i32 %114)
  call void @cqrt_free(i32 %114)
  call void @cqrt_copy_i64(i32 %108, i32 %113)
  call void @cqrt_free(i32 %113)
  call void @cqrt_copy_i64(i32 %107, i32 %112)
  call void @cqrt_free(i32 %112)
  br label %532

532:                                              ; preds = %531
  switch i32 %103, label %475 [
    i32 1, label %476
  ]

533:                                              ; preds = %11
  %534 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %534)
  %535 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %536 = add i32 %535, -1
  store i32 %536, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  store i32 %12, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_mpn_mul_fft_decompose_111111111_t_pure(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9) {
  %11 = load i32, ptr @__cq_k, align 4
  store i32 %9, ptr @__cq_k, align 4
  %12 = call i32 @__cq_mem()
  %13 = call ptr @__cq_alloc(i64 8, i64 8)
  %14 = call i32 @cq_template_mul_i64(i32 %6, i32 %2)
  %15 = ptrtoint ptr %13 to i64
  %16 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %12, i64 %15, i32 %16)
  %17 = call i32 @cq_template_icmp_slt_i64(i32 %14, i32 %5)
  %18 = call i32 @cq_template_sub_i64(i32 %5, i32 %14)
  %19 = call i32 @cq_template_add_i64_hl(i32 %14, i64 1)
  %20 = call i32 @cq_template_shl_i64_hl(i32 %19, i64 3)
  %21 = ptrtoint ptr %13 to i64
  %22 = call i32 @cqrt_alloc_i64(i64 %21)
  %23 = call i32 @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl(i32 %17, i32 %22, i32 %20, i32 %9)
  %24 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 8)
  %25 = call i32 @cq_template_add_i64(i32 %23, i32 %24)
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_controlled(i32 %17, i32 %12, i32 %25, i32 %26)
  call void @cq_template_add_i64_unc(i32 %25, i32 %23, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cq_template_mul_i64_hl_unc(i32 %24, i32 %14, i64 8)
  call void @cqrt_free(i32 %24)
  %27 = call i32 @cq_template_icmp_sgt_i64(i32 %18, i32 %14)
  call void @cq_template_icmp_sgt_i64_unc(i32 %27, i32 %18, i32 %14)
  call void @cqrt_free(i32 %27)
  %28 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 0)
  %29 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 8)
  %30 = call i32 @cq_template_add_i64(i32 %4, i32 %29)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %31)
  call void @cqrt_and_i1(i32 %17, i32 %28, i32 %31)
  %32 = call i32 @__cq_q___gmpn_sub_n_1111_t_ctl(i32 %31, i32 %23, i32 %4, i32 %30, i32 %18, i32 %9)
  %33 = call i32 @cq_template_icmp_eq_i64_hl(i32 %32, i64 0)
  br label %34

34:                                               ; preds = %10
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %36)
  call void @cqrt_and_i1(i32 %17, i32 %28, i32 %36)
  call void @cqrt_xor_i1(i32 %36, i32 %35)
  call void @cqrt_and_i1(i32 %36, i32 %33, i32 %35)
  %37 = call i32 @cqrt_alloc_i64(i64 0)
  %38 = call i32 @cqrt_alloc_i64(i64 0)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  %40 = call i32 @cq_template_icmp_slt_i64(i32 %18, i32 %14)
  %41 = call i32 @cqrt_alloc_i64(i64 1)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_xor_i1(i32 %40, i32 %42)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %42, i32 %43)
  %44 = call i32 @cq_template_select_i64(i32 %43, i32 %41, i32 %37)
  %45 = call i32 @cqrt_alloc_i64(i64 0)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %46)
  call void @cqrt_xor_i1(i32 %40, i32 %46)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %46, i32 %47)
  %48 = call i32 @cq_template_select_i64(i32 %47, i32 %45, i32 %38)
  %49 = call i32 @cqrt_alloc_i1(i1 true)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_xor_i1(i32 %40, i32 %50)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %50, i32 %51)
  %52 = call i32 @cq_template_select_i1(i32 %51, i32 %49, i32 %39)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %40, i32 %53)
  %54 = icmp ult i32 0, %9
  br i1 %54, label %55, label %93

55:                                               ; preds = %106, %34
  %from4 = phi i32 [ 0, %106 ], [ 1, %34 ]
  %56 = phi i32 [ 0, %34 ], [ %88, %106 ]
  %57 = phi i32 [ %53, %34 ], [ %120, %106 ]
  %58 = phi i32 [ %18, %34 ], [ %87, %106 ]
  %59 = phi i64 [ 0, %34 ], [ %86, %106 ]
  %60 = phi i32 [ %40, %34 ], [ %107, %106 ]
  %61 = phi i32 [ %44, %34 ], [ %111, %106 ]
  %62 = phi i32 [ %48, %34 ], [ %115, %106 ]
  %63 = phi i32 [ %52, %34 ], [ %119, %106 ]
  call void @cqrt_push(i32 %from4)
  %64 = call i32 @cq_template_mul_i64_hl(i32 %58, i64 8)
  %65 = call i32 @cq_template_add_i64(i32 %4, i32 %64)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %60, i32 %66)
  %67 = call i32 @cqrt_qram_load_i64_controlled(i32 %66, i32 %12, i32 %65)
  %68 = call i32 @cq_template_add_i64_hl(i32 %67, i64 -1)
  %69 = call i32 @cq_template_add_i64_hl(i32 %58, i64 1)
  %70 = call i32 @cq_template_mul_i64_hl(i32 %58, i64 8)
  %71 = call i32 @cq_template_add_i64(i32 %23, i32 %70)
  call void @cqrt_qram_store_i64_controlled(i32 %66, i32 %12, i32 %71, i32 %68)
  call void @cq_template_add_i64_unc(i32 %71, i32 %23, i32 %70)
  call void @cqrt_free(i32 %71)
  call void @cq_template_mul_i64_hl_unc(i32 %70, i32 %58, i64 8)
  call void @cqrt_free(i32 %70)
  %72 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 0)
  %73 = call i32 @cqrt_alloc_i64(i64 0)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %60, i32 %74)
  call void @cqrt_and_i1(i32 %60, i32 %72, i32 %74)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %74, i32 %75)
  %76 = call i32 @cq_template_select_i64(i32 %75, i32 %73, i32 %61)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %60, i32 %77)
  call void @cqrt_and_i1(i32 %60, i32 %72, i32 %77)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %77, i32 %78)
  %79 = call i32 @cq_template_select_i64(i32 %78, i32 %69, i32 %62)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %60, i32 %81)
  call void @cqrt_and_i1(i32 %60, i32 %72, i32 %81)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %81, i32 %82)
  %83 = call i32 @cq_template_select_i1(i32 %82, i32 %80, i32 %63)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %60, i32 %84)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %84, i32 %85)
  %86 = add i64 %59, 1
  %87 = call i32 @cq_template_add_i64_hl(i32 %18, i64 %86)
  %88 = add i32 %56, 1
  %89 = icmp ult i32 %88, %9
  call void @cqrt_push(i32 %87)
  %90 = trunc i64 %86 to i32
  call void @cqrt_push(i32 %90)
  %91 = lshr i64 %86, 32
  %92 = trunc i64 %91 to i32
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %64)
  br i1 %89, label %106, label %93

93:                                               ; preds = %55, %34
  %94 = phi i32 [ 0, %34 ], [ 1, %55 ]
  %95 = phi i32 [ %18, %34 ], [ %87, %55 ]
  %96 = phi i64 [ 0, %34 ], [ %86, %55 ]
  %97 = phi i32 [ %40, %34 ], [ %60, %55 ]
  %98 = phi i32 [ %44, %34 ], [ %76, %55 ]
  %99 = phi i32 [ %48, %34 ], [ %79, %55 ]
  %100 = phi i32 [ %52, %34 ], [ %83, %55 ]
  %101 = phi i32 [ %53, %34 ], [ %85, %55 ]
  %102 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %101, i32 %102)
  %103 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %98, i32 %103)
  %104 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %99, i32 %104)
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %100, i32 %105)
  br label %121

106:                                              ; preds = %55
  %107 = call i32 @cq_template_icmp_slt_i64(i32 %87, i32 %14)
  %108 = call i32 @cqrt_alloc_i64(i64 1)
  %109 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %109)
  call void @cqrt_xor_i1(i32 %107, i32 %109)
  %110 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %109, i32 %110)
  %111 = call i32 @cq_template_select_i64(i32 %110, i32 %108, i32 %76)
  %112 = call i32 @cqrt_alloc_i64(i64 0)
  %113 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %113)
  call void @cqrt_xor_i1(i32 %107, i32 %113)
  %114 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %113, i32 %114)
  %115 = call i32 @cq_template_select_i64(i32 %114, i32 %112, i32 %79)
  %116 = call i32 @cqrt_alloc_i1(i1 true)
  %117 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %117)
  call void @cqrt_xor_i1(i32 %107, i32 %117)
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %117, i32 %118)
  %119 = call i32 @cq_template_select_i1(i32 %118, i32 %116, i32 %83)
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %107, i32 %120)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %107)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %119)
  call void @cqrt_push(i32 %118)
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %114)
  call void @cqrt_push(i32 %112)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %113)
  call void @cqrt_push(i32 %111)
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %108)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %109)
  call void @cqrt_push(i32 %87)
  br label %55

121:                                              ; preds = %93
  %122 = call i32 @cq_template_select_i64(i32 %33, i32 %18, i32 %104)
  %123 = call i32 @cq_template_select_i64_lh(i32 %28, i64 0, i32 %122)
  %124 = call i32 @cq_template_icmp_ne_i64(i32 %23, i32 %4)
  %125 = call i32 @cq_template_icmp_slt_i64(i32 %123, i32 %14)
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %124, i32 %125, i32 %126)
  %127 = call i32 @cq_template_shl_i64_hl(i32 %123, i64 3)
  %128 = call i32 @cq_template_add_i64(i32 %23, i32 %127)
  %129 = call i32 @cq_template_add_i64(i32 %4, i32 %127)
  %130 = call i32 @cq_template_mul_i64(i32 %6, i32 %2)
  %131 = call i32 @cq_template_sub_i64(i32 %130, i32 %123)
  %132 = call i32 @cq_template_shl_i64_hl(i32 %131, i64 3)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %134)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %17, i32 %136)
  call void @cqrt_and_i1(i32 %17, i32 %28, i32 %136)
  call void @cqrt_xor_i1(i32 %136, i32 %135)
  call void @cqrt_and_i1(i32 %136, i32 %33, i32 %135)
  call void @cqrt_and_i1(i32 %105, i32 %135, i32 %134)
  call void @cqrt_and_i1(i32 %126, i32 %134, i32 %133)
  %137 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %132, i64 4096)
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %137, i32 %133, i32 %138)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %137, i32 %132, i64 4096)
  call void @cqrt_free(i32 %137)
  br label %139

139:                                              ; preds = %139, %121
  %140 = phi i64 [ 0, %121 ], [ %145, %139 ]
  %141 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %132, i64 %140)
  %142 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %141, i32 %133, i32 %142)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %141, i32 %132, i64 %140)
  call void @cqrt_free(i32 %141)
  %143 = call i32 @cq_template_add_i64_hl(i32 %129, i64 %140)
  %144 = call i32 @cqrt_qram_load_i8_controlled(i32 %142, i32 %12, i32 %143)
  call void @cq_template_add_i64_hl_unc(i32 %143, i32 %129, i64 %140)
  call void @cqrt_free(i32 %143)
  call void @cqrt_push(i32 %142)
  call void @cqrt_push(i32 %144)
  %145 = add nuw i64 %140, 1
  %146 = icmp eq i64 %145, 4096
  br i1 %146, label %147, label %139

147:                                              ; preds = %139
  call void @cq_template_shl_i64_hl_unc(i32 %132, i32 %131, i64 3)
  call void @cqrt_free(i32 %132)
  call void @cq_template_sub_i64_unc(i32 %131, i32 %130, i32 %123)
  call void @cqrt_free(i32 %131)
  call void @cq_template_mul_i64_unc(i32 %130, i32 %6, i32 %2)
  call void @cqrt_free(i32 %130)
  call void @cq_template_add_i64_unc(i32 %129, i32 %4, i32 %127)
  call void @cqrt_free(i32 %129)
  br label %148

148:                                              ; preds = %147
  br label %149

149:                                              ; preds = %149, %148
  %150 = phi i64 [ 4095, %148 ], [ %154, %149 ]
  %151 = call i32 @cqrt_pop()
  %152 = call i32 @cqrt_pop()
  %153 = call i32 @cq_template_add_i64_hl(i32 %128, i64 %150)
  call void @cqrt_qram_store_i8_controlled(i32 %152, i32 %12, i32 %153, i32 %151)
  call void @cq_template_add_i64_hl_unc(i32 %153, i32 %128, i64 %150)
  call void @cqrt_free(i32 %153)
  %154 = add nsw i64 %150, -1
  %155 = icmp eq i64 %150, 0
  br i1 %155, label %156, label %149

156:                                              ; preds = %149
  call void @cq_template_add_i64_unc(i32 %128, i32 %23, i32 %127)
  call void @cqrt_free(i32 %128)
  call void @cq_template_shl_i64_hl_unc(i32 %127, i32 %123, i64 3)
  call void @cqrt_free(i32 %127)
  br label %157

157:                                              ; preds = %156
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %158)
  %159 = call i32 @cqrt_alloc_i1(i1 false)
  %160 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %160)
  call void @cqrt_xor_i1(i32 %28, i32 %160)
  call void @cqrt_xor_i1(i32 %160, i32 %159)
  call void @cqrt_and_i1(i32 %160, i32 %33, i32 %159)
  call void @cqrt_and_i1(i32 %105, i32 %159, i32 %158)
  %161 = call i32 @cq_template_select_i64_lh(i32 %158, i64 0, i32 %103)
  %162 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %17, i32 %12, i32 %23, i32 %162)
  %163 = call i32 @cq_template_add_i64(i32 %162, i32 %161)
  %164 = call i32 @cq_template_select_i64(i32 %17, i32 %163, i32 %162)
  call void @cq_template_add_i64_unc(i32 %163, i32 %162, i32 %161)
  call void @cqrt_free(i32 %163)
  %165 = call i32 @cq_template_sub_i64(i32 %164, i32 %161)
  %166 = call i32 @cq_template_select_i64(i32 %17, i32 %165, i32 %164)
  call void @cqrt_copy_i64(i32 %166, i32 %162)
  call void @cq_template_select_i64_unc(i32 %166, i32 %17, i32 %165, i32 %164)
  call void @cqrt_free(i32 %166)
  call void @cq_template_sub_i64_unc(i32 %165, i32 %164, i32 %161)
  call void @cqrt_free(i32 %165)
  call void @cqrt_free(i32 %162)
  call void @cqrt_qram_swap_i64_controlled(i32 %17, i32 %12, i32 %23, i32 %164)
  call void @cqrt_free(i32 %164)
  %167 = call i32 @cqrt_qram_load_i64_controlled(i32 %17, i32 %12, i32 %23)
  %168 = call i32 @cq_template_icmp_ult_i64(i32 %167, i32 %161)
  br label %169

169:                                              ; preds = %157
  %170 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %168, i32 %17, i32 %170)
  %171 = icmp ult i32 0, %9
  br i1 %171, label %172, label %188

172:                                              ; preds = %172, %169
  %from = phi i32 [ 0, %172 ], [ 1, %169 ]
  %173 = phi i32 [ 0, %169 ], [ %186, %172 ]
  %174 = phi i32 [ %170, %169 ], [ %184, %172 ]
  %175 = phi i32 [ %23, %169 ], [ %185, %172 ]
  call void @cqrt_push(i32 %from)
  %176 = call i32 @cq_template_add_i64_hl(i32 %175, i64 8)
  %177 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %174, i32 %12, i32 %176, i32 %177)
  %178 = call i32 @cq_template_add_i64_hl(i32 %177, i64 1)
  %179 = call i32 @cq_template_select_i64(i32 %174, i32 %178, i32 %177)
  call void @cq_template_add_i64_hl_unc(i32 %178, i32 %177, i64 1)
  call void @cqrt_free(i32 %178)
  %180 = call i32 @cq_template_sub_i64_hl(i32 %179, i64 1)
  %181 = call i32 @cq_template_select_i64(i32 %174, i32 %180, i32 %179)
  call void @cqrt_copy_i64(i32 %181, i32 %177)
  call void @cq_template_select_i64_unc(i32 %181, i32 %174, i32 %180, i32 %179)
  call void @cqrt_free(i32 %181)
  call void @cq_template_sub_i64_hl_unc(i32 %180, i32 %179, i64 1)
  call void @cqrt_free(i32 %180)
  call void @cqrt_free(i32 %177)
  call void @cqrt_qram_swap_i64_controlled(i32 %174, i32 %12, i32 %176, i32 %179)
  call void @cqrt_free(i32 %179)
  %182 = call i32 @cqrt_qram_load_i64_controlled(i32 %174, i32 %12, i32 %176)
  %183 = call i32 @cq_template_icmp_eq_i64_hl(i32 %182, i64 0)
  %184 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %174, i32 %183, i32 %184)
  %185 = call i32 @cq_template_select_i64(i32 %174, i32 %176, i32 %175)
  %186 = add i32 %173, 1
  %187 = icmp ult i32 %186, %9
  call void @cqrt_push(i32 %185)
  call void @cqrt_push(i32 %174)
  call void @cqrt_push(i32 %176)
  call void @cqrt_push(i32 %175)
  call void @cqrt_push(i32 %183)
  call void @cqrt_push(i32 %184)
  call void @cqrt_push(i32 %182)
  br i1 %187, label %172, label %188

188:                                              ; preds = %172, %169
  %189 = phi i32 [ 0, %169 ], [ 1, %172 ]
  %190 = phi i32 [ %23, %169 ], [ %185, %172 ]
  %191 = phi i32 [ %170, %169 ], [ %184, %172 ]
  %192 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %191, i32 %192)
  br label %212

193:                                              ; preds = %212, %203
  %194 = call i32 @cq_template_select_i64(i32 %17, i32 %19, i32 %5)
  %195 = call i32 @cq_template_select_i64(i32 %17, i32 %23, i32 %4)
  %196 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %2, i64 0)
  %197 = call i32 @cq_template_icmp_eq_i64_hl(i32 %3, i64 -1)
  %198 = call i32 @cq_template_add_i64_hl(i32 %2, i64 -1)
  %199 = call i32 @cq_template_add_i64_hl(i32 %3, i64 1)
  %200 = call i32 @cq_template_add_i64_hl(i32 %3, i64 1)
  %201 = call i32 @cq_template_shl_i64_hl(i32 %3, i64 3)
  %202 = call i32 @cq_template_add_i64_hl(i32 %201, i64 8)
  br label %213

203:                                              ; preds = %212, %203
  %204 = call i32 @cqrt_pop()
  %205 = call i32 @cqrt_pop()
  %206 = call i32 @cqrt_pop()
  %207 = call i32 @cqrt_pop()
  %208 = call i32 @cqrt_pop()
  %209 = call i32 @cqrt_pop()
  %210 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %210, i32 %209, i32 %208, i32 %207)
  call void @cqrt_free(i32 %210)
  call void @cqrt_and_i1(i32 %209, i32 %206, i32 %205)
  call void @cqrt_free(i32 %205)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %206, i32 %204, i64 0)
  call void @cqrt_free(i32 %206)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %204, i32 %209, i32 %12, i32 %208)
  call void @cq_template_add_i64_hl_unc(i32 %208, i32 %207, i64 8)
  call void @cqrt_free(i32 %208)
  %211 = call i32 @cqrt_pop()
  switch i32 %211, label %203 [
    i32 1, label %193
  ]

212:                                              ; preds = %188
  switch i32 %189, label %193 [
    i32 1, label %203
  ]

213:                                              ; preds = %193
  %214 = icmp ult i32 0, %9
  br i1 %214, label %215, label %233

215:                                              ; preds = %328, %213
  %from3 = phi i32 [ 0, %328 ], [ 1, %213 ]
  %216 = phi i32 [ 0, %213 ], [ %344, %328 ]
  %217 = phi i32 [ %196, %213 ], [ %340, %328 ]
  %218 = phi i32 [ %0, %213 ], [ %341, %328 ]
  %219 = phi i32 [ %195, %213 ], [ %342, %328 ]
  %220 = phi i32 [ %194, %213 ], [ %343, %328 ]
  %221 = phi i64 [ 0, %213 ], [ %337, %328 ]
  %222 = mul i64 %221, 8
  %223 = call i32 @cq_template_add_i64_hl(i32 %1, i64 %222)
  %224 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %218, i32 %224)
  %225 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %217, i32 %225)
  call void @cqrt_qram_store_i64_controlled(i32 %225, i32 %12, i32 %223, i32 %224)
  %226 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %220, i64 0)
  %227 = call i32 @cqrt_alloc_i1(i1 false)
  %228 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %228)
  call void @cqrt_xor_i1(i32 %226, i32 %228)
  call void @cqrt_xor_i1(i32 %228, i32 %227)
  call void @cqrt_and_i1(i32 %228, i32 %197, i32 %227)
  %229 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %227, i32 %229)
  %230 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %202, i64 4096)
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %230, i32 %229, i32 %231)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %230, i32 %202, i64 4096)
  call void @cqrt_free(i32 %230)
  %232 = call i32 @cqrt_alloc_i8(i8 0)
  br label %242

233:                                              ; preds = %328, %213
  %234 = phi i32 [ 0, %213 ], [ 1, %328 ]
  %235 = phi i32 [ %0, %213 ], [ %341, %328 ]
  %236 = phi i32 [ %195, %213 ], [ %342, %328 ]
  %237 = phi i32 [ %194, %213 ], [ %343, %328 ]
  %238 = phi i64 [ 0, %213 ], [ %337, %328 ]
  %239 = phi i32 [ %196, %213 ], [ %340, %328 ]
  %240 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %239, i32 %240)
  %241 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %237, i32 %241)
  br label %349

242:                                              ; preds = %242, %215
  %243 = phi i64 [ 0, %215 ], [ %247, %242 ]
  %244 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %202, i64 %243)
  %245 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %244, i32 %229, i32 %245)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %244, i32 %202, i64 %243)
  call void @cqrt_free(i32 %244)
  %246 = call i32 @cq_template_add_i64_hl(i32 %218, i64 %243)
  call void @cqrt_qram_store_i8_controlled(i32 %245, i32 %12, i32 %246, i32 %232)
  call void @cq_template_add_i64_hl_unc(i32 %246, i32 %218, i64 %243)
  call void @cqrt_free(i32 %246)
  %247 = add nuw i64 %243, 1
  %248 = icmp eq i64 %247, 4096
  br i1 %248, label %249, label %242

249:                                              ; preds = %242
  br label %250

250:                                              ; preds = %249
  call void @cqrt_push(i32 %from3)
  %251 = call i32 @cq_template_icmp_sge_i64(i32 %220, i32 %6)
  %252 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %198, i64 %221)
  %253 = call i32 @cq_template_select_i1_hl(i32 %251, i32 %252, i1 false)
  %254 = call i32 @cq_template_select_i64(i32 %253, i32 %6, i32 %220)
  %255 = call i32 @cq_template_sub_i64(i32 %220, i32 %254)
  %256 = call i32 @cq_template_icmp_eq_i64_hl(i32 %254, i64 0)
  %257 = call i32 @cq_template_add_i64_hl(i32 %254, i64 -1)
  %258 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %226, i32 %258)
  call void @cqrt_and_i1(i32 %226, i32 %256, i32 %258)
  %259 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %258, i32 %259)
  %260 = call i32 @cqrt_qram_load_i64_controlled(i32 %259, i32 %12, i32 %219)
  %261 = call i32 @cq_template_icmp_eq_i64_hl(i32 %257, i64 0)
  %262 = call i32 @cqrt_alloc_i1(i1 false)
  %263 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %226, i32 %263)
  call void @cqrt_and_i1(i32 %226, i32 %256, i32 %263)
  call void @cqrt_xor_i1(i32 %263, i32 %262)
  call void @cqrt_and_i1(i32 %263, i32 %261, i32 %262)
  %264 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %262, i32 %264)
  %265 = icmp ult i32 0, %9
  call void @cqrt_push(i32 %217)
  call void @cqrt_push(i32 %262)
  call void @cqrt_push(i32 %264)
  call void @cqrt_push(i32 %263)
  call void @cqrt_push(i32 %261)
  call void @cqrt_push(i32 %226)
  call void @cqrt_push(i32 %256)
  call void @cqrt_push(i32 %257)
  call void @cqrt_push(i32 %260)
  call void @cqrt_push(i32 %259)
  call void @cqrt_push(i32 %219)
  call void @cqrt_push(i32 %258)
  call void @cqrt_push(i32 %254)
  call void @cqrt_push(i32 %255)
  call void @cqrt_push(i32 %220)
  call void @cqrt_push(i32 %253)
  call void @cqrt_push(i32 %251)
  call void @cqrt_push(i32 %252)
  %266 = trunc i64 %221 to i32
  call void @cqrt_push(i32 %266)
  %267 = lshr i64 %221, 32
  %268 = trunc i64 %267 to i32
  call void @cqrt_push(i32 %268)
  call void @cqrt_push(i32 %227)
  call void @cqrt_push(i32 %229)
  call void @cqrt_push(i32 %228)
  call void @cqrt_push(i32 %223)
  %269 = trunc i64 %222 to i32
  call void @cqrt_push(i32 %269)
  %270 = lshr i64 %222, 32
  %271 = trunc i64 %270 to i32
  call void @cqrt_push(i32 %271)
  br i1 %265, label %272, label %299

272:                                              ; preds = %272, %250
  %from2 = phi i32 [ 0, %272 ], [ 1, %250 ]
  %273 = phi i32 [ 0, %250 ], [ %294, %272 ]
  %274 = phi i32 [ %264, %250 ], [ %288, %272 ]
  %275 = phi i32 [ %257, %250 ], [ %290, %272 ]
  %276 = phi i32 [ %8, %250 ], [ %291, %272 ]
  %277 = phi i32 [ %219, %250 ], [ %292, %272 ]
  %278 = phi i32 [ %260, %250 ], [ %293, %272 ]
  %279 = phi i64 [ 0, %250 ], [ %289, %272 ]
  call void @cqrt_push(i32 %from2)
  %280 = call i32 @cq_template_add_i64_hl(i32 %277, i64 8)
  %281 = call i32 @cq_template_add_i64_hl(i32 %276, i64 8)
  %282 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %278, i32 %282)
  %283 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %274, i32 %283)
  call void @cqrt_qram_store_i64_controlled(i32 %283, i32 %12, i32 %276, i32 %282)
  %284 = call i32 @cqrt_qram_load_i64_controlled(i32 %274, i32 %12, i32 %280)
  %285 = call i32 @cq_template_add_i64_hl(i32 %275, i64 -1)
  %286 = call i32 @cq_template_icmp_eq_i64_hl(i32 %285, i64 0)
  %287 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %287)
  call void @cqrt_xor_i1(i32 %286, i32 %287)
  %288 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %274, i32 %287, i32 %288)
  %289 = add i64 %279, -1
  %290 = call i32 @cq_template_add_i64_hl(i32 %257, i64 %289)
  %291 = call i32 @cq_template_select_i64(i32 %274, i32 %281, i32 %276)
  %292 = call i32 @cq_template_select_i64(i32 %274, i32 %280, i32 %277)
  %293 = call i32 @cq_template_select_i64(i32 %274, i32 %284, i32 %278)
  %294 = add i32 %273, 1
  %295 = icmp ult i32 %294, %9
  call void @cqrt_push(i32 %293)
  call void @cqrt_push(i32 %274)
  call void @cqrt_push(i32 %284)
  call void @cqrt_push(i32 %278)
  call void @cqrt_push(i32 %292)
  call void @cqrt_push(i32 %280)
  call void @cqrt_push(i32 %277)
  call void @cqrt_push(i32 %291)
  call void @cqrt_push(i32 %281)
  call void @cqrt_push(i32 %276)
  call void @cqrt_push(i32 %290)
  call void @cqrt_push(i32 %257)
  %296 = trunc i64 %289 to i32
  call void @cqrt_push(i32 %296)
  %297 = lshr i64 %289, 32
  %298 = trunc i64 %297 to i32
  call void @cqrt_push(i32 %298)
  call void @cqrt_push(i32 %287)
  call void @cqrt_push(i32 %288)
  call void @cqrt_push(i32 %286)
  call void @cqrt_push(i32 %285)
  call void @cqrt_push(i32 %275)
  br i1 %295, label %272, label %299

299:                                              ; preds = %272, %250
  %from1 = phi i32 [ 0, %272 ], [ 1, %250 ]
  %300 = phi i32 [ %257, %250 ], [ %290, %272 ]
  %301 = phi i32 [ %8, %250 ], [ %291, %272 ]
  %302 = phi i32 [ %219, %250 ], [ %292, %272 ]
  %303 = phi i32 [ %260, %250 ], [ %293, %272 ]
  %304 = phi i64 [ 0, %250 ], [ %289, %272 ]
  %305 = phi i32 [ %264, %250 ], [ %288, %272 ]
  %306 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %305, i32 %306)
  %307 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %303, i32 %307)
  %308 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %226, i32 %308)
  call void @cqrt_and_i1(i32 %226, i32 %256, i32 %308)
  %309 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %308, i32 %309)
  call void @cqrt_qram_store_i64_controlled(i32 %309, i32 %12, i32 %301, i32 %307)
  %310 = call i32 @cq_template_icmp_eq_i64(i32 %199, i32 %254)
  %311 = call i32 @cq_template_sub_i64(i32 %199, i32 %254)
  %312 = call i32 @cq_template_mul_i64_hl(i32 %254, i64 8)
  %313 = call i32 @cq_template_add_i64(i32 %8, i32 %312)
  %314 = call i32 @cq_template_shl_i64_hl(i32 %311, i64 3)
  %315 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %226, i32 %315)
  call void @cqrt_and_i1(i32 %226, i32 %310, i32 %315)
  %316 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %315, i32 %316)
  %317 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %314, i64 4096)
  %318 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %317, i32 %316, i32 %318)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %317, i32 %314, i64 4096)
  call void @cqrt_free(i32 %317)
  %319 = call i32 @cqrt_alloc_i8(i8 0)
  br label %320

320:                                              ; preds = %320, %299
  %321 = phi i64 [ 0, %299 ], [ %325, %320 ]
  %322 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %314, i64 %321)
  %323 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %322, i32 %316, i32 %323)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %322, i32 %314, i64 %321)
  call void @cqrt_free(i32 %322)
  %324 = call i32 @cq_template_add_i64_hl(i32 %313, i64 %321)
  call void @cqrt_qram_store_i8_controlled(i32 %323, i32 %12, i32 %324, i32 %319)
  call void @cq_template_add_i64_hl_unc(i32 %324, i32 %313, i64 %321)
  call void @cqrt_free(i32 %324)
  %325 = add nuw i64 %321, 1
  %326 = icmp eq i64 %325, 4096
  br i1 %326, label %327, label %320

327:                                              ; preds = %320
  br label %328

328:                                              ; preds = %327
  call void @cqrt_push(i32 %from1)
  %329 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 8)
  %330 = call i32 @cq_template_add_i64(i32 %219, i32 %329)
  %331 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 %221)
  %332 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %226, i32 %332)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl(i32 %332, i32 %218, i32 %8, i32 %331, i32 %3, i32 %9)
  call void @__cq_q_mpn_fft_mul_2exp_modF_1111_t_ctl_unc(i32 %332, i32 %218, i32 %8, i32 %331, i32 %3, i32 %9)
  call void @cqrt_and_i1(i32 %217, i32 %226, i32 %332)
  call void @cqrt_free(i32 %332)
  call void @cq_template_mul_i64_hl_unc(i32 %331, i32 %7, i64 %221)
  call void @cqrt_free(i32 %331)
  %333 = call i32 @cq_template_select_i64(i32 %226, i32 %255, i32 %220)
  %334 = call i32 @cq_template_select_i64(i32 %226, i32 %330, i32 %219)
  %335 = call i32 @cq_template_mul_i64_hl(i32 %200, i64 8)
  %336 = call i32 @cq_template_add_i64(i32 %218, i32 %335)
  %337 = add i64 %221, 1
  %338 = call i32 @cq_template_icmp_eq_i64_hl(i32 %2, i64 %337)
  %339 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %339)
  call void @cqrt_xor_i1(i32 %338, i32 %339)
  %340 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %217, i32 %339, i32 %340)
  %341 = call i32 @cq_template_select_i64(i32 %217, i32 %336, i32 %218)
  %342 = call i32 @cq_template_select_i64(i32 %217, i32 %334, i32 %219)
  %343 = call i32 @cq_template_select_i64(i32 %217, i32 %333, i32 %220)
  %344 = add i32 %216, 1
  %345 = icmp ult i32 %344, %9
  call void @cqrt_push(i32 %343)
  call void @cqrt_push(i32 %217)
  call void @cqrt_push(i32 %333)
  call void @cqrt_push(i32 %220)
  call void @cqrt_push(i32 %342)
  call void @cqrt_push(i32 %334)
  call void @cqrt_push(i32 %219)
  call void @cqrt_push(i32 %341)
  call void @cqrt_push(i32 %336)
  call void @cqrt_push(i32 %218)
  call void @cqrt_push(i32 %339)
  call void @cqrt_push(i32 %340)
  call void @cqrt_push(i32 %338)
  %346 = trunc i64 %337 to i32
  call void @cqrt_push(i32 %346)
  %347 = lshr i64 %337, 32
  %348 = trunc i64 %347 to i32
  call void @cqrt_push(i32 %348)
  call void @cqrt_push(i32 %335)
  call void @cqrt_push(i32 %226)
  call void @cqrt_push(i32 %330)
  call void @cqrt_push(i32 %255)
  call void @cqrt_push(i32 %329)
  call void @cqrt_push(i32 %315)
  call void @cqrt_push(i32 %316)
  call void @cqrt_push(i32 %310)
  call void @cqrt_push(i32 %314)
  call void @cqrt_push(i32 %311)
  call void @cqrt_push(i32 %313)
  call void @cqrt_push(i32 %312)
  call void @cqrt_push(i32 %254)
  call void @cqrt_push(i32 %256)
  call void @cqrt_push(i32 %308)
  br i1 %345, label %215, label %233

349:                                              ; preds = %233
  %350 = call i32 @cq_template_icmp_eq_i64_hl(i32 %241, i64 0)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %350, i32 %241, i64 0)
  call void @cqrt_free(i32 %350)
  br label %457

351:                                              ; preds = %355
  call void @cq_template_add_i64_hl_unc(i32 %202, i32 %201, i64 8)
  call void @cqrt_free(i32 %202)
  call void @cq_template_shl_i64_hl_unc(i32 %201, i32 %3, i64 3)
  call void @cqrt_free(i32 %201)
  call void @cq_template_add_i64_hl_unc(i32 %200, i32 %3, i64 1)
  call void @cqrt_free(i32 %200)
  call void @cq_template_add_i64_hl_unc(i32 %199, i32 %3, i64 1)
  call void @cqrt_free(i32 %199)
  call void @cq_template_add_i64_hl_unc(i32 %198, i32 %2, i64 -1)
  call void @cqrt_free(i32 %198)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %197, i32 %3, i64 -1)
  call void @cqrt_free(i32 %197)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %196, i32 %2, i64 0)
  call void @cqrt_free(i32 %196)
  call void @cq_template_select_i64_unc(i32 %195, i32 %17, i32 %23, i32 %4)
  call void @cqrt_free(i32 %195)
  call void @cq_template_select_i64_unc(i32 %194, i32 %17, i32 %19, i32 %5)
  call void @cqrt_free(i32 %194)
  call void @cqrt_and_i1(i32 %168, i32 %17, i32 %170)
  call void @cqrt_free(i32 %170)
  call void @cq_template_icmp_ult_i64_unc(i32 %168, i32 %167, i32 %161)
  call void @cqrt_free(i32 %168)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %167, i32 %17, i32 %12, i32 %23)
  call void @cq_template_select_i64_lh_unc(i32 %161, i32 %158, i64 0, i32 %103)
  call void @cqrt_free(i32 %161)
  call void @cqrt_and_i1(i32 %105, i32 %159, i32 %158)
  call void @cqrt_not_i1(i32 %158)
  call void @cqrt_free(i32 %158)
  call void @cqrt_and_i1(i32 %160, i32 %33, i32 %159)
  call void @cqrt_xor_i1(i32 %160, i32 %159)
  call void @cqrt_free(i32 %159)
  call void @cqrt_xor_i1(i32 %28, i32 %160)
  call void @cqrt_not_i1(i32 %160)
  call void @cqrt_free(i32 %160)
  call void @cqrt_and_i1(i32 %126, i32 %134, i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cqrt_and_i1(i32 %105, i32 %135, i32 %134)
  call void @cqrt_xor_i1(i32 %17, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cqrt_and_i1(i32 %136, i32 %33, i32 %135)
  call void @cqrt_xor_i1(i32 %136, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cqrt_and_i1(i32 %17, i32 %28, i32 %136)
  call void @cqrt_xor_i1(i32 %17, i32 %136)
  call void @cqrt_free(i32 %136)
  call void @cqrt_and_i1(i32 %124, i32 %125, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cq_template_icmp_slt_i64_unc(i32 %125, i32 %123, i32 %14)
  call void @cqrt_free(i32 %125)
  call void @cq_template_icmp_ne_i64_unc(i32 %124, i32 %23, i32 %4)
  call void @cqrt_free(i32 %124)
  call void @cq_template_select_i64_lh_unc(i32 %123, i32 %28, i64 0, i32 %122)
  call void @cqrt_free(i32 %123)
  call void @cq_template_select_i64_unc(i32 %122, i32 %33, i32 %18, i32 %104)
  call void @cqrt_free(i32 %122)
  br label %515

352:                                              ; preds = %459
  call void @cqrt_and_i1(i32 %35, i32 %40, i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cq_template_select_i1_unc(i32 %52, i32 %51, i32 %49, i32 %39)
  call void @cqrt_free(i32 %52)
  call void @cqrt_and_i1(i32 %35, i32 %50, i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cqrt_xor_i1(i32 %40, i32 %50)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cqrt_free(i32 %49)
  call void @cq_template_select_i64_unc(i32 %48, i32 %47, i32 %45, i32 %38)
  call void @cqrt_free(i32 %48)
  call void @cqrt_and_i1(i32 %35, i32 %46, i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cqrt_xor_i1(i32 %40, i32 %46)
  call void @cqrt_not_i1(i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_free(i32 %45)
  call void @cq_template_select_i64_unc(i32 %44, i32 %43, i32 %41, i32 %37)
  call void @cqrt_free(i32 %44)
  call void @cqrt_and_i1(i32 %35, i32 %42, i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cqrt_xor_i1(i32 %40, i32 %42)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cqrt_free(i32 %41)
  call void @cq_template_icmp_slt_i64_unc(i32 %40, i32 %18, i32 %14)
  call void @cqrt_free(i32 %40)
  call void @cqrt_free(i32 %39)
  call void @cqrt_free(i32 %38)
  call void @cqrt_free(i32 %37)
  call void @cqrt_and_i1(i32 %36, i32 %33, i32 %35)
  call void @cqrt_xor_i1(i32 %36, i32 %35)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %17, i32 %28, i32 %36)
  call void @cqrt_xor_i1(i32 %17, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %33, i32 %32, i64 0)
  call void @cqrt_free(i32 %33)
  call void @__cq_q___gmpn_sub_n_1111_t_ctl_unc(i32 %31, i32 %32, i32 %23, i32 %4, i32 %30, i32 %18, i32 %9)
  call void @cqrt_and_i1(i32 %17, i32 %28, i32 %31)
  call void @cqrt_xor_i1(i32 %17, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_add_i64_unc(i32 %30, i32 %4, i32 %29)
  call void @cqrt_free(i32 %30)
  call void @cq_template_mul_i64_hl_unc(i32 %29, i32 %14, i64 8)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %28, i32 %18, i64 0)
  call void @cqrt_free(i32 %28)
  call void @__cq_q___gmp_tmp_reentrant_alloc_11_t_ctl_unc(i32 %17, i32 %23, i32 %22, i32 %20, i32 %9)
  call void @cqrt_free(i32 %22)
  call void @cq_template_shl_i64_hl_unc(i32 %20, i32 %19, i64 3)
  call void @cqrt_free(i32 %20)
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %14, i64 1)
  call void @cqrt_free(i32 %19)
  call void @cq_template_sub_i64_unc(i32 %18, i32 %5, i32 %14)
  call void @cqrt_free(i32 %18)
  call void @cq_template_mul_i64_unc(i32 %14, i32 %6, i32 %2)
  call void @cqrt_free(i32 %14)
  %353 = ptrtoint ptr %13 to i64
  %354 = call i32 @cqrt_qram_load_i64_hl(i32 %12, i64 %353)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t(i32 %354, i32 %9)
  call void @__cq_q___gmp_tmp_reentrant_free_1_t_unc(i32 %354, i32 %9)
  call void @cqrt_qram_load_i64_hl_unc(i32 %354, i32 %12, i64 %353)
  store i32 %11, ptr @__cq_k, align 4
  ret void

355:                                              ; preds = %458, %356
  br label %351

356:                                              ; preds = %394, %420
  %357 = call i32 @cqrt_pop()
  %358 = zext i32 %357 to i64
  %359 = shl i64 %358, 32
  %360 = or i64 0, %359
  %361 = call i32 @cqrt_pop()
  %362 = zext i32 %361 to i64
  %363 = or i64 %360, %362
  %364 = call i32 @cqrt_pop()
  %365 = call i32 @cqrt_pop()
  %366 = call i32 @cqrt_pop()
  %367 = call i32 @cqrt_pop()
  %368 = call i32 @cqrt_pop()
  %369 = zext i32 %368 to i64
  %370 = shl i64 %369, 32
  %371 = or i64 0, %370
  %372 = call i32 @cqrt_pop()
  %373 = zext i32 %372 to i64
  %374 = or i64 %371, %373
  %375 = call i32 @cqrt_pop()
  %376 = call i32 @cqrt_pop()
  %377 = call i32 @cqrt_pop()
  %378 = call i32 @cqrt_pop()
  %379 = call i32 @cqrt_pop()
  %380 = call i32 @cqrt_pop()
  %381 = call i32 @cqrt_pop()
  %382 = call i32 @cqrt_pop()
  %383 = call i32 @cqrt_pop()
  %384 = call i32 @cqrt_pop()
  %385 = call i32 @cqrt_pop()
  %386 = call i32 @cqrt_pop()
  %387 = call i32 @cqrt_pop()
  %388 = call i32 @cqrt_pop()
  %389 = call i32 @cqrt_pop()
  %390 = call i32 @cqrt_pop()
  %391 = call i32 @cqrt_pop()
  %392 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %392, i32 %391, i32 %390)
  call void @cqrt_free(i32 %390)
  call void @cqrt_and_i1(i32 %389, i32 %388, i32 %391)
  call void @cqrt_xor_i1(i32 %389, i32 %391)
  call void @cqrt_free(i32 %391)
  call void @cqrt_and_i1(i32 %387, i32 %386, i32 %389)
  call void @cqrt_xor_i1(i32 %387, i32 %389)
  call void @cqrt_free(i32 %389)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %388, i32 %385, i64 0)
  call void @cqrt_free(i32 %388)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %384, i32 %383, i32 %12, i32 %382)
  call void @cqrt_and_i1(i32 %392, i32 %381, i32 %383)
  call void @cqrt_free(i32 %383)
  call void @cqrt_and_i1(i32 %387, i32 %386, i32 %381)
  call void @cqrt_xor_i1(i32 %387, i32 %381)
  call void @cqrt_free(i32 %381)
  call void @cq_template_add_i64_hl_unc(i32 %385, i32 %380, i64 -1)
  call void @cqrt_free(i32 %385)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %386, i32 %380, i64 0)
  call void @cqrt_free(i32 %386)
  call void @cq_template_sub_i64_unc(i32 %379, i32 %378, i32 %380)
  call void @cqrt_free(i32 %379)
  call void @cq_template_select_i64_unc(i32 %380, i32 %377, i32 %6, i32 %378)
  call void @cqrt_free(i32 %380)
  call void @cq_template_select_i1_hl_unc(i32 %377, i32 %376, i32 %375, i1 false)
  call void @cqrt_free(i32 %377)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %375, i32 %198, i64 %374)
  call void @cqrt_free(i32 %375)
  call void @cq_template_icmp_sge_i64_unc(i32 %376, i32 %378, i32 %6)
  call void @cqrt_free(i32 %376)
  call void @cqrt_and_i1(i32 %392, i32 %367, i32 %366)
  call void @cqrt_free(i32 %366)
  call void @cqrt_and_i1(i32 %365, i32 %197, i32 %367)
  call void @cqrt_xor_i1(i32 %365, i32 %367)
  call void @cqrt_free(i32 %367)
  call void @cqrt_xor_i1(i32 %387, i32 %365)
  call void @cqrt_not_i1(i32 %365)
  call void @cqrt_free(i32 %365)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %387, i32 %378, i64 0)
  call void @cqrt_free(i32 %387)
  call void @cq_template_add_i64_hl_unc(i32 %364, i32 %1, i64 %363)
  call void @cqrt_free(i32 %364)
  %393 = call i32 @cqrt_pop()
  switch i32 %393, label %420 [
    i32 1, label %355
  ]

394:                                              ; preds = %394, %420
  %395 = call i32 @cqrt_pop()
  %396 = call i32 @cqrt_pop()
  %397 = call i32 @cqrt_pop()
  %398 = call i32 @cqrt_pop()
  %399 = call i32 @cqrt_pop()
  %400 = call i32 @cqrt_pop()
  %401 = zext i32 %400 to i64
  %402 = shl i64 %401, 32
  %403 = or i64 0, %402
  %404 = call i32 @cqrt_pop()
  %405 = zext i32 %404 to i64
  %406 = or i64 %403, %405
  %407 = call i32 @cqrt_pop()
  %408 = call i32 @cqrt_pop()
  %409 = call i32 @cqrt_pop()
  %410 = call i32 @cqrt_pop()
  %411 = call i32 @cqrt_pop()
  %412 = call i32 @cqrt_pop()
  %413 = call i32 @cqrt_pop()
  %414 = call i32 @cqrt_pop()
  %415 = call i32 @cqrt_pop()
  %416 = call i32 @cqrt_pop()
  %417 = call i32 @cqrt_pop()
  %418 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %418, i32 %417, i32 %416, i32 %415)
  call void @cqrt_free(i32 %418)
  call void @cq_template_select_i64_unc(i32 %414, i32 %417, i32 %413, i32 %412)
  call void @cqrt_free(i32 %414)
  call void @cq_template_select_i64_unc(i32 %411, i32 %417, i32 %410, i32 %409)
  call void @cqrt_free(i32 %411)
  call void @cq_template_add_i64_hl_unc(i32 %408, i32 %407, i64 %406)
  call void @cqrt_free(i32 %408)
  call void @cqrt_and_i1(i32 %417, i32 %399, i32 %398)
  call void @cqrt_free(i32 %398)
  call void @cqrt_xor_i1(i32 %397, i32 %399)
  call void @cqrt_not_i1(i32 %399)
  call void @cqrt_free(i32 %399)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %397, i32 %396, i64 0)
  call void @cqrt_free(i32 %397)
  call void @cq_template_add_i64_hl_unc(i32 %396, i32 %395, i64 -1)
  call void @cqrt_free(i32 %396)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %416, i32 %417, i32 %12, i32 %413)
  call void @cq_template_add_i64_hl_unc(i32 %410, i32 %409, i64 8)
  call void @cqrt_free(i32 %410)
  call void @cq_template_add_i64_hl_unc(i32 %413, i32 %412, i64 8)
  call void @cqrt_free(i32 %413)
  %419 = call i32 @cqrt_pop()
  switch i32 %419, label %394 [
    i32 1, label %356
  ]

420:                                              ; preds = %458, %356
  %421 = call i32 @cqrt_pop()
  %422 = call i32 @cqrt_pop()
  %423 = call i32 @cqrt_pop()
  %424 = call i32 @cqrt_pop()
  %425 = call i32 @cqrt_pop()
  %426 = call i32 @cqrt_pop()
  %427 = call i32 @cqrt_pop()
  %428 = call i32 @cqrt_pop()
  %429 = call i32 @cqrt_pop()
  %430 = call i32 @cqrt_pop()
  %431 = call i32 @cqrt_pop()
  %432 = call i32 @cqrt_pop()
  %433 = call i32 @cqrt_pop()
  %434 = call i32 @cqrt_pop()
  %435 = call i32 @cqrt_pop()
  %436 = call i32 @cqrt_pop()
  %437 = zext i32 %436 to i64
  %438 = shl i64 %437, 32
  %439 = or i64 0, %438
  %440 = call i32 @cqrt_pop()
  %441 = zext i32 %440 to i64
  %442 = or i64 %439, %441
  %443 = call i32 @cqrt_pop()
  %444 = call i32 @cqrt_pop()
  %445 = call i32 @cqrt_pop()
  %446 = call i32 @cqrt_pop()
  %447 = call i32 @cqrt_pop()
  %448 = call i32 @cqrt_pop()
  %449 = call i32 @cqrt_pop()
  %450 = call i32 @cqrt_pop()
  %451 = call i32 @cqrt_pop()
  %452 = call i32 @cqrt_pop()
  %453 = call i32 @cqrt_pop()
  %454 = call i32 @cqrt_pop()
  %455 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %455, i32 %454, i32 %453, i32 %452)
  call void @cqrt_free(i32 %455)
  call void @cq_template_select_i64_unc(i32 %451, i32 %454, i32 %450, i32 %449)
  call void @cqrt_free(i32 %451)
  call void @cq_template_select_i64_unc(i32 %448, i32 %454, i32 %447, i32 %446)
  call void @cqrt_free(i32 %448)
  call void @cqrt_and_i1(i32 %454, i32 %445, i32 %444)
  call void @cqrt_free(i32 %444)
  call void @cqrt_xor_i1(i32 %443, i32 %445)
  call void @cqrt_not_i1(i32 %445)
  call void @cqrt_free(i32 %445)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %443, i32 %2, i64 %442)
  call void @cqrt_free(i32 %443)
  call void @cq_template_add_i64_unc(i32 %447, i32 %446, i32 %435)
  call void @cqrt_free(i32 %447)
  call void @cq_template_mul_i64_hl_unc(i32 %435, i32 %200, i64 8)
  call void @cqrt_free(i32 %435)
  call void @cq_template_select_i64_unc(i32 %450, i32 %434, i32 %433, i32 %449)
  call void @cqrt_free(i32 %450)
  call void @cq_template_select_i64_unc(i32 %453, i32 %434, i32 %432, i32 %452)
  call void @cqrt_free(i32 %453)
  call void @cq_template_add_i64_unc(i32 %433, i32 %449, i32 %431)
  call void @cqrt_free(i32 %433)
  call void @cq_template_mul_i64_hl_unc(i32 %431, i32 %6, i64 8)
  call void @cqrt_free(i32 %431)
  call void @cqrt_and_i1(i32 %454, i32 %430, i32 %429)
  call void @cqrt_free(i32 %429)
  call void @cqrt_and_i1(i32 %434, i32 %428, i32 %430)
  call void @cqrt_xor_i1(i32 %434, i32 %430)
  call void @cqrt_free(i32 %430)
  call void @cq_template_shl_i64_hl_unc(i32 %427, i32 %426, i64 3)
  call void @cqrt_free(i32 %427)
  call void @cq_template_add_i64_unc(i32 %425, i32 %8, i32 %424)
  call void @cqrt_free(i32 %425)
  call void @cq_template_mul_i64_hl_unc(i32 %424, i32 %423, i64 8)
  call void @cqrt_free(i32 %424)
  call void @cq_template_sub_i64_unc(i32 %426, i32 %199, i32 %423)
  call void @cqrt_free(i32 %426)
  call void @cq_template_icmp_eq_i64_unc(i32 %428, i32 %199, i32 %423)
  call void @cqrt_free(i32 %428)
  call void @cqrt_and_i1(i32 %434, i32 %422, i32 %421)
  call void @cqrt_xor_i1(i32 %434, i32 %421)
  call void @cqrt_free(i32 %421)
  %456 = call i32 @cqrt_pop()
  switch i32 %456, label %394 [
    i32 1, label %356
  ]

457:                                              ; preds = %349
  call void @cqrt_copy_i64(i32 %237, i32 %241)
  call void @cqrt_free(i32 %241)
  br label %458

458:                                              ; preds = %457
  switch i32 %234, label %355 [
    i32 1, label %420
  ]

459:                                              ; preds = %516, %460
  br label %352

460:                                              ; preds = %516, %495
  %461 = call i32 @cqrt_pop()
  %462 = call i32 @cqrt_pop()
  %463 = call i32 @cqrt_pop()
  %464 = call i32 @cqrt_pop()
  %465 = call i32 @cqrt_pop()
  %466 = call i32 @cqrt_pop()
  %467 = call i32 @cqrt_pop()
  %468 = call i32 @cqrt_pop()
  %469 = call i32 @cqrt_pop()
  %470 = call i32 @cqrt_pop()
  %471 = call i32 @cqrt_pop()
  %472 = call i32 @cqrt_pop()
  %473 = call i32 @cqrt_pop()
  %474 = call i32 @cqrt_pop()
  %475 = call i32 @cqrt_pop()
  %476 = call i32 @cqrt_pop()
  %477 = call i32 @cqrt_pop()
  %478 = call i32 @cqrt_pop()
  %479 = call i32 @cqrt_pop()
  %480 = call i32 @cqrt_pop()
  %481 = call i32 @cqrt_pop()
  %482 = call i32 @cqrt_pop()
  %483 = call i32 @cqrt_pop()
  %484 = call i32 @cqrt_pop()
  %485 = call i32 @cqrt_pop()
  %486 = call i32 @cqrt_pop()
  %487 = zext i32 %486 to i64
  %488 = shl i64 %487, 32
  %489 = or i64 0, %488
  %490 = call i32 @cqrt_pop()
  %491 = zext i32 %490 to i64
  %492 = or i64 %489, %491
  %493 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %493, i32 %18, i64 %492)
  call void @cqrt_free(i32 %493)
  call void @cqrt_and_i1(i32 %485, i32 %484, i32 %483)
  call void @cqrt_free(i32 %483)
  call void @cqrt_and_i1(i32 %482, i32 %481, i32 %484)
  call void @cqrt_free(i32 %484)
  call void @cq_template_select_i1_unc(i32 %480, i32 %479, i32 %478, i32 %477)
  call void @cqrt_free(i32 %480)
  call void @cqrt_and_i1(i32 %485, i32 %476, i32 %479)
  call void @cqrt_free(i32 %479)
  call void @cqrt_and_i1(i32 %481, i32 %482, i32 %476)
  call void @cqrt_xor_i1(i32 %481, i32 %476)
  call void @cqrt_free(i32 %476)
  call void @cqrt_free(i32 %478)
  call void @cq_template_select_i64_unc(i32 %475, i32 %474, i32 %473, i32 %472)
  call void @cqrt_free(i32 %475)
  call void @cqrt_and_i1(i32 %485, i32 %471, i32 %474)
  call void @cqrt_free(i32 %474)
  call void @cqrt_and_i1(i32 %481, i32 %482, i32 %471)
  call void @cqrt_xor_i1(i32 %481, i32 %471)
  call void @cqrt_free(i32 %471)
  call void @cq_template_select_i64_unc(i32 %470, i32 %469, i32 %468, i32 %467)
  call void @cqrt_free(i32 %470)
  call void @cqrt_and_i1(i32 %485, i32 %466, i32 %469)
  call void @cqrt_free(i32 %469)
  call void @cqrt_and_i1(i32 %481, i32 %482, i32 %466)
  call void @cqrt_xor_i1(i32 %481, i32 %466)
  call void @cqrt_free(i32 %466)
  call void @cqrt_free(i32 %468)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %482, i32 %465, i64 0)
  call void @cqrt_free(i32 %482)
  call void @cq_template_add_i64_hl_unc(i32 %473, i32 %464, i64 1)
  call void @cqrt_free(i32 %473)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %465, i32 %463, i32 %12, i32 %462)
  call void @cq_template_add_i64_unc(i32 %462, i32 %4, i32 %461)
  call void @cqrt_free(i32 %462)
  call void @cq_template_mul_i64_hl_unc(i32 %461, i32 %464, i64 8)
  call void @cqrt_free(i32 %461)
  %494 = call i32 @cqrt_pop()
  switch i32 %494, label %495 [
    i32 1, label %459
  ]

495:                                              ; preds = %460
  %496 = call i32 @cqrt_pop()
  %497 = call i32 @cqrt_pop()
  %498 = call i32 @cqrt_pop()
  %499 = call i32 @cqrt_pop()
  %500 = call i32 @cqrt_pop()
  %501 = call i32 @cqrt_pop()
  %502 = call i32 @cqrt_pop()
  %503 = call i32 @cqrt_pop()
  %504 = call i32 @cqrt_pop()
  %505 = call i32 @cqrt_pop()
  %506 = call i32 @cqrt_pop()
  %507 = call i32 @cqrt_pop()
  %508 = call i32 @cqrt_pop()
  %509 = call i32 @cqrt_pop()
  %510 = call i32 @cqrt_pop()
  %511 = call i32 @cqrt_pop()
  %512 = call i32 @cqrt_pop()
  %513 = call i32 @cqrt_pop()
  %514 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %514, i32 %513, i32 %512)
  call void @cqrt_free(i32 %512)
  call void @cq_template_select_i1_unc(i32 %511, i32 %510, i32 %509, i32 %508)
  call void @cqrt_free(i32 %511)
  call void @cqrt_and_i1(i32 %514, i32 %507, i32 %510)
  call void @cqrt_free(i32 %510)
  call void @cqrt_xor_i1(i32 %513, i32 %507)
  call void @cqrt_not_i1(i32 %507)
  call void @cqrt_free(i32 %507)
  call void @cqrt_free(i32 %509)
  call void @cq_template_select_i64_unc(i32 %506, i32 %505, i32 %504, i32 %503)
  call void @cqrt_free(i32 %506)
  call void @cqrt_and_i1(i32 %514, i32 %502, i32 %505)
  call void @cqrt_free(i32 %505)
  call void @cqrt_xor_i1(i32 %513, i32 %502)
  call void @cqrt_not_i1(i32 %502)
  call void @cqrt_free(i32 %502)
  call void @cqrt_free(i32 %504)
  call void @cq_template_select_i64_unc(i32 %501, i32 %500, i32 %499, i32 %498)
  call void @cqrt_free(i32 %501)
  call void @cqrt_and_i1(i32 %514, i32 %497, i32 %500)
  call void @cqrt_free(i32 %500)
  call void @cqrt_xor_i1(i32 %513, i32 %497)
  call void @cqrt_not_i1(i32 %497)
  call void @cqrt_free(i32 %497)
  call void @cqrt_free(i32 %499)
  call void @cq_template_icmp_slt_i64_unc(i32 %513, i32 %496, i32 %14)
  call void @cqrt_free(i32 %513)
  br label %460

515:                                              ; preds = %351
  call void @cqrt_copy_i1(i32 %100, i32 %105)
  call void @cqrt_free(i32 %105)
  call void @cqrt_copy_i64(i32 %99, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cqrt_copy_i64(i32 %98, i32 %103)
  call void @cqrt_free(i32 %103)
  br label %516

516:                                              ; preds = %515
  switch i32 %94, label %459 [
    i32 1, label %460
  ]
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @mpn_mul_fft_decompose, ptr @.cq.sig, ptr @__cq_q_mpn_mul_fft_decompose_111111111_t, ptr @__cq_q_mpn_mul_fft_decompose_111111111_t_ctl, ptr @__cq_q_mpn_mul_fft_decompose_111111111_t_unc, ptr @__cq_q_mpn_mul_fft_decompose_111111111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define void @__cq_q_mpn_mul_fft_decompose_111111111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9) {
  %11 = load i32, ptr @__cq_k, align 4
  store i32 %9, ptr @__cq_k, align 4
  store i32 %11, ptr @__cq_k, align 4
  ret void
}

define void @__cq_q_mpn_mul_fft_decompose_111111111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10) {
  %12 = load i32, ptr @__cq_k, align 4
  store i32 %10, ptr @__cq_k, align 4
  %13 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %14 = add i32 %13, 1
  store i32 %14, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %15 = load i32, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_mpn_mul_fft_decompose, align 4
  store i32 %12, ptr @__cq_k, align 4
  ret void
}

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nofree norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #4 = { noreturn nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }
attributes #5 = { nounwind ssp uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="broadwell" "target-features"="+adx,+avx,+avx2,+bmi,+bmi2,+cmov,+crc32,+cx16,+cx8,+f16c,+fma,+fsgsbase,+fxsr,+invpcid,+lzcnt,+mmx,+movbe,+pclmul,+popcnt,+prfchw,+rdrnd,+rdseed,+sahf,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+ssse3,+x87,+xsave,+xsaveopt" "tune-cpu"="skylake" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
