; ModuleID = '<stdin>'
source_filename = "fenvmerge.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.main.n = private unnamed_addr constant [4 x i64] [i64 1, i64 2, i64 3, i64 4], align 16
@__cq_act_dc = internal global i32 0, align 4
@__cq_act_mu = internal global i32 0, align 4
@__cq_act_divq = internal global i32 0, align 4
@__cq_act_main = internal global i32 0, align 4
@__cq_k = internal global i32 -1, align 4
@.cq.sig = private unnamed_addr constant [20 x i8] c"i64 (ptr, ptr, i64)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [26 x i8] c"void (ptr, ptr, i64, i64)\00", align 1
@.cq.sig.2 = private unnamed_addr constant [7 x i8] c"i32 ()\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i64 @dc(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()
  %5 = ptrtoint ptr %1 to i64
  %6 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %5)
  %7 = call i32 @cq_template_add_i64_hl(i32 %6, i64 %2)
  call void @cqrt_qram_load_i64_hl_unc(i32 %6, i32 %4, i64 %5)
  call void @cqrt_free(i32 %6)
  %8 = ptrtoint ptr %0 to i64
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %7)
  %9 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %7, i64 4)
  %10 = call i32 @cq_template_zext_i1_to_i64(i32 %9)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %9, i32 %7, i64 4)
  call void @cqrt_free(i32 %9)
  %11 = zext i32 %10 to i64
  ret i64 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define i64 @mu(ptr noundef %0, ptr noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()
  %5 = ptrtoint ptr %1 to i64
  %6 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %5)
  %7 = call i32 @cq_template_sub_i64_hl(i32 %6, i64 %2)
  call void @cqrt_qram_load_i64_hl_unc(i32 %6, i32 %4, i64 %5)
  call void @cqrt_free(i32 %6)
  %8 = ptrtoint ptr %0 to i64
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %7)
  %9 = call i32 @cq_template_icmp_slt_i64_hl(i32 %7, i64 2)
  %10 = call i32 @cq_template_zext_i1_to_i64(i32 %9)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %9, i32 %7, i64 2)
  call void @cqrt_free(i32 %9)
  %11 = zext i32 %10 to i64
  ret i64 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define void @divq(ptr noundef %0, ptr noundef %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @__cq_mem()
  %6 = getelementptr inbounds i8, ptr %1, i64 8
  %7 = ptrtoint ptr %6 to i64
  %8 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 %7)
  %9 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %8, i64 3)
  %10 = sitofp i64 %3 to double
  %11 = sitofp i64 %2 to double
  %12 = fmul double %11, 2.000000e+02
  %13 = tail call double @llvm.fmuladd.f64(double %10, double 3.600000e+03, double %12)
  %14 = fmul double %11, %10
  %15 = fcmp ogt double %13, %14
  br i1 %15, label %16, label %18

16:                                               ; preds = %4
  %17 = call i32 @__cq_q_dc_000_ctl(i32 %9, ptr %0, ptr %1, i64 %2)
  br label %18

18:                                               ; preds = %16, %4
  %19 = xor i1 %15, true
  br i1 %19, label %20, label %22

20:                                               ; preds = %18
  %21 = call i32 @__cq_q_mu_000_ctl(i32 %9, ptr %0, ptr %1, i64 %2)
  br label %22

22:                                               ; preds = %20, %18
  %23 = ptrtoint ptr %1 to i64
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_xor_i1(i32 %9, i32 %24)
  %25 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %24, i32 %5, i64 %23)
  %26 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %25, i64 1)
  %27 = sitofp i64 %3 to double
  %28 = sitofp i64 %2 to double
  %29 = fmul double %28, 2.000000e+02
  %30 = tail call double @llvm.fmuladd.f64(double %27, double 3.600000e+03, double %29)
  %31 = fmul double %28, %27
  %32 = fcmp ogt double %30, %31
  br i1 %32, label %33, label %37

33:                                               ; preds = %22
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_xor_i1(i32 %9, i32 %35)
  call void @cqrt_and_i1(i32 %26, i32 %35, i32 %34)
  %36 = call i32 @__cq_q_dc_000_ctl(i32 %34, ptr %0, ptr %1, i64 %3)
  call void @cqrt_and_i1(i32 %26, i32 %35, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_xor_i1(i32 %9, i32 %35)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %35)
  br label %37

37:                                               ; preds = %33, %22
  %38 = xor i1 %32, true
  br i1 %38, label %39, label %43

39:                                               ; preds = %37
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_xor_i1(i32 %9, i32 %41)
  call void @cqrt_and_i1(i32 %26, i32 %41, i32 %40)
  %42 = call i32 @__cq_q_mu_000_ctl(i32 %40, ptr %0, ptr %1, i64 %3)
  call void @cqrt_and_i1(i32 %26, i32 %41, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cqrt_xor_i1(i32 %9, i32 %41)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_free(i32 %41)
  br label %43

43:                                               ; preds = %39, %37
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %26, i32 %25, i64 1)
  call void @cqrt_free(i32 %26)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %25, i32 %24, i32 %5, i64 %23)
  call void @cqrt_xor_i1(i32 %9, i32 %24)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %9, i32 %8, i64 3)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i64_hl_unc(i32 %8, i32 %5, i64 %7)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #2 {
  %1 = call i32 @__cq_mem()
  %2 = call ptr @__cq_alloc(i64 32, i64 16)
  %3 = call ptr @__cq_alloc(i64 32, i64 16)
  %4 = ptrtoint ptr %2 to i64
  br label %5

5:                                                ; preds = %5, %0
  %6 = phi i64 [ 0, %0 ], [ %9, %5 ]
  %7 = add i64 ptrtoint (ptr @__const.main.n to i64), %6
  %8 = call i32 @cqrt_qram_load_i8_hl(i32 %1, i64 %7)
  call void @cqrt_push(i32 %8)
  %9 = add nuw i64 %6, 1
  %10 = icmp eq i64 %9, 32
  br i1 %10, label %11, label %5

11:                                               ; preds = %5
  br label %12

12:                                               ; preds = %11
  br label %13

13:                                               ; preds = %13, %12
  %14 = phi i64 [ 31, %12 ], [ %17, %13 ]
  %15 = call i32 @cqrt_pop()
  %16 = add i64 %4, %14
  call void @cqrt_qram_store_i8_hl(i32 %1, i64 %16, i32 %15)
  %17 = add nsw i64 %14, -1
  %18 = icmp eq i64 %14, 0
  br i1 %18, label %19, label %13

19:                                               ; preds = %13
  %20 = ptrtoint ptr %3 to i64
  %21 = call i32 @cqrt_alloc_i8(i8 0)
  br label %22

22:                                               ; preds = %22, %19
  %23 = phi i64 [ 0, %19 ], [ %25, %22 ]
  %24 = add i64 %20, %23
  call void @cqrt_qram_store_i8_hl(i32 %1, i64 %24, i32 %21)
  %25 = add nuw i64 %23, 1
  %26 = icmp eq i64 %25, 32
  br i1 %26, label %27, label %22

27:                                               ; preds = %22
  %28 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %28, double 0x3FF921FB54442D18)
  %29 = call i32 @cq_template_zext_i8_to_i32(i32 %28)
  %30 = call i32 @cq_template_and_i32_hl(i32 %29, i32 3)
  %31 = call i32 @cq_template_zext_i32_to_i64(i32 %30)
  call void @cq_template_and_i32_hl_unc(i32 %30, i32 %29, i32 3)
  call void @cqrt_free(i32 %30)
  %32 = ptrtoint ptr %2 to i64
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %32, i32 %31)
  %33 = call i32 @cq_template_lshr_i32_hl(i32 %29, i32 2)
  %34 = call i32 @cq_template_and_i32_hl(i32 %33, i32 7)
  %35 = call i32 @cq_template_zext_i32_to_i64(i32 %34)
  call void @cq_template_and_i32_hl_unc(i32 %34, i32 %33, i32 7)
  call void @cqrt_free(i32 %34)
  call void @cq_template_lshr_i32_hl_unc(i32 %33, i32 %29, i32 2)
  call void @cqrt_free(i32 %33)
  call void @cq_template_zext_i8_to_i32_unc(i32 %29, i32 %28)
  call void @cqrt_free(i32 %29)
  %36 = getelementptr inbounds i8, ptr %2, i64 8
  %37 = ptrtoint ptr %36 to i64
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %37, i32 %35)
  call void @divq(ptr noundef %3, ptr noundef %2, i64 noundef 3, i64 noundef 2)
  %38 = ptrtoint ptr %3 to i64
  %39 = call i32 @cqrt_qram_load_i64_hl(i32 %1, i64 %38)
  %40 = call i32 @cq_template_trunc_i64_to_i32(i32 %39)
  call void @cqrt_qram_load_i64_hl_unc(i32 %39, i32 %1, i64 %38)
  call void @cqrt_free(i32 %39)
  %41 = call i32 @cqrt_measure_i32(i32 %40), !cq.measure !6
  ret i32 %41
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)

declare i32 @cq_template_zext_i1_to_i64(i32)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

declare void @cqrt_free(i32)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_dc_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @__cq_mem()
  %7 = call i32 @cqrt_qram_load_i64(i32 %6, i32 %1)
  %8 = call i32 @cq_template_add_i64(i32 %7, i32 %2)
  call void @cqrt_qram_load_i64_unc(i32 %7, i32 %6, i32 %1)
  call void @cqrt_free(i32 %7)
  call void @cqrt_qram_store_i64(i32 %6, i32 %0, i32 %8)
  %9 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %8, i64 4)
  %10 = call i32 @cq_template_zext_i1_to_i64(i32 %9)
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %10, i32 %11)
  call void @cq_template_zext_i1_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %9, i32 %8, i64 4)
  call void @cqrt_free(i32 %9)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %11
}

declare i32 @cqrt_qram_load_i64(i32, i32)

declare i32 @cq_template_add_i64(i32, i32)

declare void @cqrt_qram_store_i64(i32, i32, i32)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_zext_i1_to_i64_unc(i32, i32)

declare void @cqrt_qram_load_i64_unc(i32, i32, i32)

define internal i32 @__cq_q_dc_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_dc, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_dc, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %19

10:                                               ; preds = %5
  %11 = call i32 @__cq_mem()
  %12 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %11, i32 %2)
  %13 = call i32 @cq_template_add_i64(i32 %12, i32 %3)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %12, i32 %0, i32 %11, i32 %2)
  call void @cqrt_free(i32 %12)
  call void @cqrt_qram_store_i64_controlled(i32 %0, i32 %11, i32 %1, i32 %13)
  %14 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %13, i64 4)
  %15 = call i32 @cq_template_zext_i1_to_i64(i32 %14)
  %16 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %15, i32 %16)
  call void @cq_template_zext_i1_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %14, i32 %13, i64 4)
  call void @cqrt_free(i32 %14)
  %17 = load i32, ptr @__cq_act_dc, align 4
  %18 = add i32 %17, -1
  store i32 %18, ptr @__cq_act_dc, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %16

19:                                               ; preds = %5
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %21)
  %22 = load i32, ptr @__cq_act_dc, align 4
  %23 = add i32 %22, -1
  store i32 %23, ptr @__cq_act_dc, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %20
}

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare void @cqrt_qram_store_i64_controlled(i32, i32, i32, i32)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_sub_i64_hl(i32, i64)

declare i32 @cq_template_icmp_slt_i64_hl(i32, i64)

declare void @cq_template_icmp_slt_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_mu_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @__cq_mem()
  %7 = call i32 @cqrt_qram_load_i64(i32 %6, i32 %1)
  %8 = call i32 @cq_template_sub_i64(i32 %7, i32 %2)
  call void @cqrt_qram_load_i64_unc(i32 %7, i32 %6, i32 %1)
  call void @cqrt_free(i32 %7)
  call void @cqrt_qram_store_i64(i32 %6, i32 %0, i32 %8)
  %9 = call i32 @cq_template_icmp_slt_i64_hl(i32 %8, i64 2)
  %10 = call i32 @cq_template_zext_i1_to_i64(i32 %9)
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %10, i32 %11)
  call void @cq_template_zext_i1_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %9, i32 %8, i64 2)
  call void @cqrt_free(i32 %9)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %11
}

declare i32 @cq_template_sub_i64(i32, i32)

define internal i32 @__cq_q_mu_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_mu, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_mu, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %19

10:                                               ; preds = %5
  %11 = call i32 @__cq_mem()
  %12 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %11, i32 %2)
  %13 = call i32 @cq_template_sub_i64(i32 %12, i32 %3)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %12, i32 %0, i32 %11, i32 %2)
  call void @cqrt_free(i32 %12)
  call void @cqrt_qram_store_i64_controlled(i32 %0, i32 %11, i32 %1, i32 %13)
  %14 = call i32 @cq_template_icmp_slt_i64_hl(i32 %13, i64 2)
  %15 = call i32 @cq_template_zext_i1_to_i64(i32 %14)
  %16 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %15, i32 %16)
  call void @cq_template_zext_i1_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %14, i32 %13, i64 2)
  call void @cqrt_free(i32 %14)
  %17 = load i32, ptr @__cq_act_mu, align 4
  %18 = add i32 %17, -1
  store i32 %18, ptr @__cq_act_mu, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %16

19:                                               ; preds = %5
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %21)
  %22 = load i32, ptr @__cq_act_mu, align 4
  %23 = add i32 %22, -1
  store i32 %23, ptr @__cq_act_mu, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %20
}

define i32 @__cq_q_dc_000_ctl(i32 %0, ptr %1, ptr %2, i64 %3) local_unnamed_addr {
  %5 = load i32, ptr @__cq_k, align 4
  %6 = icmp eq i32 %5, -1
  %7 = select i1 %6, i32 4, i32 %5
  %8 = load i32, ptr @__cq_act_dc, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_dc, align 4
  %10 = icmp ult i32 %8, %7
  br i1 %10, label %11, label %22

11:                                               ; preds = %4
  %12 = call i32 @__cq_mem()
  %13 = ptrtoint ptr %2 to i64
  %14 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %12, i64 %13)
  %15 = call i32 @cq_template_add_i64_hl(i32 %14, i64 %3)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %14, i32 %0, i32 %12, i64 %13)
  call void @cqrt_free(i32 %14)
  %16 = ptrtoint ptr %1 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %12, i64 %16, i32 %15)
  %17 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %15, i64 4)
  %18 = call i32 @cq_template_zext_i1_to_i64(i32 %17)
  %19 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %18, i32 %19)
  call void @cq_template_zext_i1_to_i64_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %17, i32 %15, i64 4)
  call void @cqrt_free(i32 %17)
  %20 = load i32, ptr @__cq_act_dc, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_dc, align 4
  ret i32 %19

22:                                               ; preds = %4
  %23 = call i32 @cqrt_alloc_i64(i64 0)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %24)
  %25 = load i32, ptr @__cq_act_dc, align 4
  %26 = add i32 %25, -1
  store i32 %26, ptr @__cq_act_dc, align 4
  ret i32 %23
}

define i32 @__cq_q_mu_000_ctl(i32 %0, ptr %1, ptr %2, i64 %3) local_unnamed_addr {
  %5 = load i32, ptr @__cq_k, align 4
  %6 = icmp eq i32 %5, -1
  %7 = select i1 %6, i32 4, i32 %5
  %8 = load i32, ptr @__cq_act_mu, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_mu, align 4
  %10 = icmp ult i32 %8, %7
  br i1 %10, label %11, label %22

11:                                               ; preds = %4
  %12 = call i32 @__cq_mem()
  %13 = ptrtoint ptr %2 to i64
  %14 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %12, i64 %13)
  %15 = call i32 @cq_template_sub_i64_hl(i32 %14, i64 %3)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %14, i32 %0, i32 %12, i64 %13)
  call void @cqrt_free(i32 %14)
  %16 = ptrtoint ptr %1 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %12, i64 %16, i32 %15)
  %17 = call i32 @cq_template_icmp_slt_i64_hl(i32 %15, i64 2)
  %18 = call i32 @cq_template_zext_i1_to_i64(i32 %17)
  %19 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %18, i32 %19)
  call void @cq_template_zext_i1_to_i64_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %17, i32 %15, i64 2)
  call void @cqrt_free(i32 %17)
  %20 = load i32, ptr @__cq_act_mu, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_mu, align 4
  ret i32 %19

22:                                               ; preds = %4
  %23 = call i32 @cqrt_alloc_i64(i64 0)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %24)
  %25 = load i32, ptr @__cq_act_mu, align 4
  %26 = add i32 %25, -1
  store i32 %26, ptr @__cq_act_mu, align 4
  ret i32 %23
}

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

define internal void @__cq_q_divq_1111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @__cq_mem()
  %8 = call i32 @cq_template_add_i64_hl(i32 %1, i64 8)
  %9 = call i32 @cqrt_qram_load_i64(i32 %7, i32 %8)
  %10 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %9, i64 3)
  %11 = call i32 @cq_template_sitofp_i64_to_f64(i32 %3)
  %12 = call i32 @cq_template_sitofp_i64_to_f64(i32 %2)
  %13 = call i32 @cq_template_fmul_f64_hl(i32 %12, double 2.000000e+02)
  %14 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 3.600000e+03)
  %15 = call i32 @cq_template_fadd_f64(i32 %14, i32 %13)
  %16 = call i32 @cq_template_fmul_f64(i32 %12, i32 %11)
  %17 = call i32 @cq_template_fcmp_ogt_f64(i32 %15, i32 %16)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %10, i32 %18)
  %19 = call i32 @__cq_q_dc_111_ctl(i32 %18, i32 %0, i32 %1, i32 %2)
  call void @cqrt_and_i1(i32 %17, i32 %10, i32 %18)
  call void @cqrt_free(i32 %18)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %20)
  call void @cqrt_and_i1(i32 %10, i32 %17, i32 %20)
  %21 = call i32 @__cq_q_mu_111_ctl(i32 %20, i32 %0, i32 %1, i32 %2)
  call void @cqrt_and_i1(i32 %10, i32 %17, i32 %20)
  call void @cqrt_xor_i1(i32 %10, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %17, i32 %15, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_fmul_f64_unc(i32 %16, i32 %12, i32 %11)
  call void @cqrt_free(i32 %16)
  call void @cq_template_fadd_f64_unc(i32 %15, i32 %14, i32 %13)
  call void @cqrt_free(i32 %15)
  call void @cq_template_fmul_f64_hl_unc(i32 %14, i32 %11, double 3.600000e+03)
  call void @cqrt_free(i32 %14)
  call void @cq_template_fmul_f64_hl_unc(i32 %13, i32 %12, double 2.000000e+02)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %12, i32 %2)
  call void @cqrt_free(i32 %12)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %11, i32 %3)
  call void @cqrt_free(i32 %11)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_xor_i1(i32 %10, i32 %22)
  %23 = call i32 @cqrt_qram_load_i64_controlled(i32 %22, i32 %7, i32 %1)
  %24 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %23, i64 1)
  %25 = call i32 @cq_template_sitofp_i64_to_f64(i32 %3)
  %26 = call i32 @cq_template_sitofp_i64_to_f64(i32 %2)
  %27 = call i32 @cq_template_fmul_f64_hl(i32 %26, double 2.000000e+02)
  %28 = call i32 @cq_template_fmul_f64_hl(i32 %25, double 3.600000e+03)
  %29 = call i32 @cq_template_fadd_f64(i32 %28, i32 %27)
  %30 = call i32 @cq_template_fmul_f64(i32 %26, i32 %25)
  %31 = call i32 @cq_template_fcmp_ogt_f64(i32 %29, i32 %30)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_xor_i1(i32 %10, i32 %34)
  call void @cqrt_and_i1(i32 %24, i32 %34, i32 %33)
  call void @cqrt_and_i1(i32 %31, i32 %33, i32 %32)
  %35 = call i32 @__cq_q_dc_111_ctl(i32 %32, i32 %0, i32 %1, i32 %3)
  call void @cqrt_and_i1(i32 %31, i32 %33, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cqrt_and_i1(i32 %24, i32 %34, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cqrt_xor_i1(i32 %10, i32 %34)
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_free(i32 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %38)
  call void @cqrt_xor_i1(i32 %10, i32 %38)
  call void @cqrt_and_i1(i32 %24, i32 %38, i32 %37)
  call void @cqrt_xor_i1(i32 %37, i32 %36)
  call void @cqrt_and_i1(i32 %37, i32 %31, i32 %36)
  %39 = call i32 @__cq_q_mu_111_ctl(i32 %36, i32 %0, i32 %1, i32 %3)
  call void @cqrt_and_i1(i32 %37, i32 %31, i32 %36)
  call void @cqrt_xor_i1(i32 %37, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_and_i1(i32 %24, i32 %38, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_xor_i1(i32 %10, i32 %38)
  call void @cqrt_not_i1(i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %31, i32 %29, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cq_template_fmul_f64_unc(i32 %30, i32 %26, i32 %25)
  call void @cqrt_free(i32 %30)
  call void @cq_template_fadd_f64_unc(i32 %29, i32 %28, i32 %27)
  call void @cqrt_free(i32 %29)
  call void @cq_template_fmul_f64_hl_unc(i32 %28, i32 %25, double 3.600000e+03)
  call void @cqrt_free(i32 %28)
  call void @cq_template_fmul_f64_hl_unc(i32 %27, i32 %26, double 2.000000e+02)
  call void @cqrt_free(i32 %27)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %26, i32 %2)
  call void @cqrt_free(i32 %26)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %25, i32 %3)
  call void @cqrt_free(i32 %25)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %24, i32 %23, i64 1)
  call void @cqrt_free(i32 %24)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %23, i32 %22, i32 %7, i32 %1)
  call void @cqrt_xor_i1(i32 %10, i32 %22)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %10, i32 %9, i64 3)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i64_unc(i32 %9, i32 %7, i32 %8)
  call void @cq_template_add_i64_hl_unc(i32 %8, i32 %1, i64 8)
  call void @cqrt_free(i32 %8)
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

declare i32 @cq_template_sitofp_i64_to_f64(i32)

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare i32 @cq_template_fadd_f64(i32, i32)

declare i32 @cq_template_fmul_f64(i32, i32)

declare i32 @cq_template_fcmp_ogt_f64(i32, i32)

define i32 @__cq_q_dc_111_ctl(i32 %0, i32 %1, i32 %2, i32 %3) local_unnamed_addr {
  %5 = load i32, ptr @__cq_k, align 4
  %6 = icmp eq i32 %5, -1
  %7 = select i1 %6, i32 4, i32 %5
  %8 = load i32, ptr @__cq_act_dc, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_dc, align 4
  %10 = icmp ult i32 %8, %7
  br i1 %10, label %11, label %20

11:                                               ; preds = %4
  %12 = call i32 @__cq_mem()
  %13 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %12, i32 %2)
  %14 = call i32 @cq_template_add_i64(i32 %13, i32 %3)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %13, i32 %0, i32 %12, i32 %2)
  call void @cqrt_free(i32 %13)
  call void @cqrt_qram_store_i64_controlled(i32 %0, i32 %12, i32 %1, i32 %14)
  %15 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %14, i64 4)
  %16 = call i32 @cq_template_zext_i1_to_i64(i32 %15)
  %17 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %16, i32 %17)
  call void @cq_template_zext_i1_to_i64_unc(i32 %16, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %15, i32 %14, i64 4)
  call void @cqrt_free(i32 %15)
  %18 = load i32, ptr @__cq_act_dc, align 4
  %19 = add i32 %18, -1
  store i32 %19, ptr @__cq_act_dc, align 4
  ret i32 %17

20:                                               ; preds = %4
  %21 = call i32 @cqrt_alloc_i64(i64 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %22)
  %23 = load i32, ptr @__cq_act_dc, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_dc, align 4
  ret i32 %21
}

define i32 @__cq_q_mu_111_ctl(i32 %0, i32 %1, i32 %2, i32 %3) local_unnamed_addr {
  %5 = load i32, ptr @__cq_k, align 4
  %6 = icmp eq i32 %5, -1
  %7 = select i1 %6, i32 4, i32 %5
  %8 = load i32, ptr @__cq_act_mu, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_mu, align 4
  %10 = icmp ult i32 %8, %7
  br i1 %10, label %11, label %20

11:                                               ; preds = %4
  %12 = call i32 @__cq_mem()
  %13 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %12, i32 %2)
  %14 = call i32 @cq_template_sub_i64(i32 %13, i32 %3)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %13, i32 %0, i32 %12, i32 %2)
  call void @cqrt_free(i32 %13)
  call void @cqrt_qram_store_i64_controlled(i32 %0, i32 %12, i32 %1, i32 %14)
  %15 = call i32 @cq_template_icmp_slt_i64_hl(i32 %14, i64 2)
  %16 = call i32 @cq_template_zext_i1_to_i64(i32 %15)
  %17 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %16, i32 %17)
  call void @cq_template_zext_i1_to_i64_unc(i32 %16, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %15, i32 %14, i64 2)
  call void @cqrt_free(i32 %15)
  %18 = load i32, ptr @__cq_act_mu, align 4
  %19 = add i32 %18, -1
  store i32 %19, ptr @__cq_act_mu, align 4
  ret i32 %17

20:                                               ; preds = %4
  %21 = call i32 @cqrt_alloc_i64(i64 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %22)
  %23 = load i32, ptr @__cq_act_mu, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_mu, align 4
  ret i32 %21
}

declare void @cq_template_fcmp_ogt_f64_unc(i32, i32, i32)

declare void @cq_template_fmul_f64_unc(i32, i32, i32)

declare void @cq_template_fadd_f64_unc(i32, i32, i32)

declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

declare void @cq_template_sitofp_i64_to_f64_unc(i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

define internal void @__cq_q_divq_1111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_divq, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_divq, align 4
  %10 = icmp ult i32 %8, %5
  br i1 %10, label %11, label %52

11:                                               ; preds = %6
  %12 = call i32 @__cq_mem()
  %13 = call i32 @cq_template_add_i64_hl(i32 %2, i64 8)
  %14 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %12, i32 %13)
  %15 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %14, i64 3)
  %16 = call i32 @cq_template_sitofp_i64_to_f64(i32 %4)
  %17 = call i32 @cq_template_sitofp_i64_to_f64(i32 %3)
  %18 = call i32 @cq_template_fmul_f64_hl(i32 %17, double 2.000000e+02)
  %19 = call i32 @cq_template_fmul_f64_hl(i32 %16, double 3.600000e+03)
  %20 = call i32 @cq_template_fadd_f64(i32 %19, i32 %18)
  %21 = call i32 @cq_template_fmul_f64(i32 %17, i32 %16)
  %22 = call i32 @cq_template_fcmp_ogt_f64(i32 %20, i32 %21)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %15, i32 %24)
  call void @cqrt_and_i1(i32 %0, i32 %24, i32 %23)
  %25 = call i32 @__cq_q_dc_111_ctl(i32 %23, i32 %1, i32 %2, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %24, i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %22, i32 %15, i32 %24)
  call void @cqrt_free(i32 %24)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %27)
  call void @cqrt_and_i1(i32 %15, i32 %22, i32 %27)
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %26)
  %28 = call i32 @__cq_q_mu_111_ctl(i32 %26, i32 %1, i32 %2, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %15, i32 %22, i32 %27)
  call void @cqrt_xor_i1(i32 %15, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %22, i32 %20, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_fmul_f64_unc(i32 %21, i32 %17, i32 %16)
  call void @cqrt_free(i32 %21)
  call void @cq_template_fadd_f64_unc(i32 %20, i32 %19, i32 %18)
  call void @cqrt_free(i32 %20)
  call void @cq_template_fmul_f64_hl_unc(i32 %19, i32 %16, double 3.600000e+03)
  call void @cqrt_free(i32 %19)
  call void @cq_template_fmul_f64_hl_unc(i32 %18, i32 %17, double 2.000000e+02)
  call void @cqrt_free(i32 %18)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %17, i32 %3)
  call void @cqrt_free(i32 %17)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %16, i32 %4)
  call void @cqrt_free(i32 %16)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %15, i32 %30)
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %29)
  %31 = call i32 @cqrt_qram_load_i64_controlled(i32 %29, i32 %12, i32 %2)
  %32 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %31, i64 1)
  %33 = call i32 @cq_template_sitofp_i64_to_f64(i32 %4)
  %34 = call i32 @cq_template_sitofp_i64_to_f64(i32 %3)
  %35 = call i32 @cq_template_fmul_f64_hl(i32 %34, double 2.000000e+02)
  %36 = call i32 @cq_template_fmul_f64_hl(i32 %33, double 3.600000e+03)
  %37 = call i32 @cq_template_fadd_f64(i32 %36, i32 %35)
  %38 = call i32 @cq_template_fmul_f64(i32 %34, i32 %33)
  %39 = call i32 @cq_template_fcmp_ogt_f64(i32 %37, i32 %38)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_xor_i1(i32 %15, i32 %43)
  call void @cqrt_and_i1(i32 %32, i32 %43, i32 %42)
  call void @cqrt_and_i1(i32 %39, i32 %42, i32 %41)
  call void @cqrt_and_i1(i32 %0, i32 %41, i32 %40)
  %44 = call i32 @__cq_q_dc_111_ctl(i32 %40, i32 %1, i32 %2, i32 %4)
  call void @cqrt_and_i1(i32 %0, i32 %41, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cqrt_and_i1(i32 %39, i32 %42, i32 %41)
  call void @cqrt_free(i32 %41)
  call void @cqrt_and_i1(i32 %32, i32 %43, i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cqrt_xor_i1(i32 %15, i32 %43)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_free(i32 %43)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_xor_i1(i32 %15, i32 %48)
  call void @cqrt_and_i1(i32 %32, i32 %48, i32 %47)
  call void @cqrt_xor_i1(i32 %47, i32 %46)
  call void @cqrt_and_i1(i32 %47, i32 %39, i32 %46)
  call void @cqrt_and_i1(i32 %0, i32 %46, i32 %45)
  %49 = call i32 @__cq_q_mu_111_ctl(i32 %45, i32 %1, i32 %2, i32 %4)
  call void @cqrt_and_i1(i32 %0, i32 %46, i32 %45)
  call void @cqrt_free(i32 %45)
  call void @cqrt_and_i1(i32 %47, i32 %39, i32 %46)
  call void @cqrt_xor_i1(i32 %47, i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_and_i1(i32 %32, i32 %48, i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cqrt_xor_i1(i32 %15, i32 %48)
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_free(i32 %48)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %39, i32 %37, i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_fmul_f64_unc(i32 %38, i32 %34, i32 %33)
  call void @cqrt_free(i32 %38)
  call void @cq_template_fadd_f64_unc(i32 %37, i32 %36, i32 %35)
  call void @cqrt_free(i32 %37)
  call void @cq_template_fmul_f64_hl_unc(i32 %36, i32 %33, double 3.600000e+03)
  call void @cqrt_free(i32 %36)
  call void @cq_template_fmul_f64_hl_unc(i32 %35, i32 %34, double 2.000000e+02)
  call void @cqrt_free(i32 %35)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %34, i32 %3)
  call void @cqrt_free(i32 %34)
  call void @cq_template_sitofp_i64_to_f64_unc(i32 %33, i32 %4)
  call void @cqrt_free(i32 %33)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %32, i32 %31, i64 1)
  call void @cqrt_free(i32 %32)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %31, i32 %29, i32 %12, i32 %2)
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_xor_i1(i32 %15, i32 %30)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %15, i32 %14, i64 3)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %14, i32 %0, i32 %12, i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %2, i64 8)
  call void @cqrt_free(i32 %13)
  %50 = load i32, ptr @__cq_act_divq, align 4
  %51 = add i32 %50, -1
  store i32 %51, ptr @__cq_act_divq, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret void

52:                                               ; preds = %6
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %53)
  %54 = load i32, ptr @__cq_act_divq, align 4
  %55 = add i32 %54, -1
  store i32 %55, ptr @__cq_act_divq, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cq_template_zext_i8_to_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_trunc_i64_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cq_template_zext_i8_to_i32_unc(i32, i32)

define internal i32 @__cq_q_main_v_t(i32 %0) {
  %cq.mints = alloca ptr, align 8
  %2 = load i32, ptr @__cq_k, align 4
  store i32 %0, ptr @__cq_k, align 4
  store ptr null, ptr %cq.mints, align 8
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 32, i64 16)
  %5 = call ptr @__cq_alloc(i64 32, i64 16)
  %6 = ptrtoint ptr %4 to i64
  br label %7

7:                                                ; preds = %7, %1
  %8 = phi i64 [ 0, %1 ], [ %11, %7 ]
  %9 = add i64 ptrtoint (ptr @__const.main.n to i64), %8
  %10 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %9)
  call void @cqrt_push(i32 %10)
  %11 = add nuw i64 %8, 1
  %12 = icmp eq i64 %11, 32
  br i1 %12, label %13, label %7

13:                                               ; preds = %7
  br label %14

14:                                               ; preds = %13
  br label %15

15:                                               ; preds = %15, %14
  %16 = phi i64 [ 31, %14 ], [ %19, %15 ]
  %17 = call i32 @cqrt_pop()
  %18 = add i64 %6, %16
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %18, i32 %17)
  %19 = add nsw i64 %16, -1
  %20 = icmp eq i64 %16, 0
  br i1 %20, label %21, label %15

21:                                               ; preds = %15
  %22 = ptrtoint ptr %5 to i64
  %23 = call i32 @cqrt_alloc_i8(i8 0)
  br label %24

24:                                               ; preds = %24, %21
  %25 = phi i64 [ 0, %21 ], [ %27, %24 ]
  %26 = add i64 %22, %25
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %26, i32 %23)
  %27 = add nuw i64 %25, 1
  %28 = icmp eq i64 %27, 32
  br i1 %28, label %29, label %24

29:                                               ; preds = %24
  %30 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %30, double 0x3FF921FB54442D18)
  %31 = alloca { i32, ptr }, align 8
  %32 = getelementptr inbounds { i32, ptr }, ptr %31, i32 0, i32 0
  store i32 %30, ptr %32, align 4
  %33 = load ptr, ptr %cq.mints, align 8
  %34 = getelementptr inbounds { i32, ptr }, ptr %31, i32 0, i32 1
  store ptr %33, ptr %34, align 8
  store ptr %31, ptr %cq.mints, align 8
  %35 = call i32 @cq_template_zext_i8_to_i32(i32 %30)
  %36 = call i32 @cq_template_and_i32_hl(i32 %35, i32 3)
  %37 = call i32 @cq_template_zext_i32_to_i64(i32 %36)
  call void @cq_template_and_i32_hl_unc(i32 %36, i32 %35, i32 3)
  call void @cqrt_free(i32 %36)
  %38 = ptrtoint ptr %4 to i64
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %38, i32 %37)
  %39 = call i32 @cq_template_lshr_i32_hl(i32 %35, i32 2)
  %40 = call i32 @cq_template_and_i32_hl(i32 %39, i32 7)
  %41 = call i32 @cq_template_zext_i32_to_i64(i32 %40)
  call void @cq_template_and_i32_hl_unc(i32 %40, i32 %39, i32 7)
  call void @cqrt_free(i32 %40)
  call void @cq_template_lshr_i32_hl_unc(i32 %39, i32 %35, i32 2)
  call void @cqrt_free(i32 %39)
  call void @cq_template_zext_i8_to_i32_unc(i32 %35, i32 %30)
  call void @cqrt_free(i32 %35)
  %42 = getelementptr inbounds i8, ptr %4, i64 8
  %43 = ptrtoint ptr %42 to i64
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %43, i32 %41)
  call void @divq(ptr noundef %5, ptr noundef %4, i64 noundef 3, i64 noundef 2)
  %44 = ptrtoint ptr %5 to i64
  %45 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %44)
  %46 = call i32 @cq_template_trunc_i64_to_i32(i32 %45)
  %47 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %46, i32 %47)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %46, i32 %45)
  call void @cqrt_free(i32 %46)
  call void @cqrt_qram_load_i64_hl_unc(i32 %45, i32 %3, i64 %44)
  call void @cqrt_free(i32 %45)
  %48 = call i32 @cqrt_measure_i32(i32 %47), !cq.measure !6
  %49 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %49)
  %50 = call i32 @cqrt_alloc_i32(i32 %48)
  store i32 %2, ptr @__cq_k, align 4
  ret i32 %50
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

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

declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)

define internal i32 @__cq_q_main_v_t_ctl(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = load i32, ptr @__cq_act_main, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_main, align 4
  %6 = icmp ult i32 %4, %1
  br i1 %6, label %7, label %57

7:                                                ; preds = %2
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 32, i64 16)
  %10 = call ptr @__cq_alloc(i64 32, i64 16)
  %11 = ptrtoint ptr %9 to i64
  br label %12

12:                                               ; preds = %12, %7
  %13 = phi i64 [ 0, %7 ], [ %16, %12 ]
  %14 = add i64 ptrtoint (ptr @__const.main.n to i64), %13
  %15 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %14)
  call void @cqrt_push(i32 %15)
  %16 = add nuw i64 %13, 1
  %17 = icmp eq i64 %16, 32
  br i1 %17, label %18, label %12

18:                                               ; preds = %12
  br label %19

19:                                               ; preds = %18
  br label %20

20:                                               ; preds = %20, %19
  %21 = phi i64 [ 31, %19 ], [ %24, %20 ]
  %22 = call i32 @cqrt_pop()
  %23 = add i64 %11, %21
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %23, i32 %22)
  %24 = add nsw i64 %21, -1
  %25 = icmp eq i64 %21, 0
  br i1 %25, label %26, label %20

26:                                               ; preds = %20
  %27 = ptrtoint ptr %10 to i64
  %28 = call i32 @cqrt_alloc_i8(i8 0)
  br label %29

29:                                               ; preds = %29, %26
  %30 = phi i64 [ 0, %26 ], [ %32, %29 ]
  %31 = add i64 %27, %30
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %31, i32 %28)
  %32 = add nuw i64 %30, 1
  %33 = icmp eq i64 %32, 32
  br i1 %33, label %34, label %29

34:                                               ; preds = %29
  %35 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %35, double 0x3FF921FB54442D18)
  %36 = alloca { i32, ptr }, align 8
  %37 = getelementptr inbounds { i32, ptr }, ptr %36, i32 0, i32 0
  store i32 %35, ptr %37, align 4
  %38 = load ptr, ptr %cq.mints, align 8
  %39 = getelementptr inbounds { i32, ptr }, ptr %36, i32 0, i32 1
  store ptr %38, ptr %39, align 8
  store ptr %36, ptr %cq.mints, align 8
  %40 = call i32 @cq_template_zext_i8_to_i32(i32 %35)
  %41 = call i32 @cq_template_and_i32_hl(i32 %40, i32 3)
  %42 = call i32 @cq_template_zext_i32_to_i64(i32 %41)
  call void @cq_template_and_i32_hl_unc(i32 %41, i32 %40, i32 3)
  call void @cqrt_free(i32 %41)
  %43 = ptrtoint ptr %9 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %43, i32 %42)
  %44 = call i32 @cq_template_lshr_i32_hl(i32 %40, i32 2)
  %45 = call i32 @cq_template_and_i32_hl(i32 %44, i32 7)
  %46 = call i32 @cq_template_zext_i32_to_i64(i32 %45)
  call void @cq_template_and_i32_hl_unc(i32 %45, i32 %44, i32 7)
  call void @cqrt_free(i32 %45)
  call void @cq_template_lshr_i32_hl_unc(i32 %44, i32 %40, i32 2)
  call void @cqrt_free(i32 %44)
  call void @cq_template_zext_i8_to_i32_unc(i32 %40, i32 %35)
  call void @cqrt_free(i32 %40)
  %47 = getelementptr inbounds i8, ptr %9, i64 8
  %48 = ptrtoint ptr %47 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %48, i32 %46)
  call void @__cq_q_divq_0000_ctl(i32 %0, ptr %10, ptr %9, i64 3, i64 2)
  %49 = ptrtoint ptr %10 to i64
  %50 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %8, i64 %49)
  %51 = call i32 @cq_template_trunc_i64_to_i32(i32 %50)
  %52 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %51, i32 %52)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %51, i32 %50)
  call void @cqrt_free(i32 %51)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %50, i32 %0, i32 %8, i64 %49)
  call void @cqrt_free(i32 %50)
  %53 = call i32 @cqrt_measure_i32(i32 %52), !cq.measure !6
  %54 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %54)
  %55 = load i32, ptr @__cq_act_main, align 4
  %56 = add i32 %55, -1
  store i32 %56, ptr @__cq_act_main, align 4
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %52

57:                                               ; preds = %2
  %58 = call i32 @cqrt_alloc_i32(i32 0)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %59)
  call void @cqrt_push(i32 0)
  %60 = load i32, ptr @__cq_act_main, align 4
  %61 = add i32 %60, -1
  store i32 %61, ptr @__cq_act_main, align 4
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %58
}

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

define void @__cq_q_divq_0000_ctl(i32 %0, ptr %1, ptr %2, i64 %3, i64 %4) local_unnamed_addr {
  %6 = load i32, ptr @__cq_k, align 4
  %7 = icmp eq i32 %6, -1
  %8 = select i1 %7, i32 4, i32 %6
  %9 = load i32, ptr @__cq_act_divq, align 4
  %10 = add i32 %9, 1
  store i32 %10, ptr @__cq_act_divq, align 4
  %11 = icmp ult i32 %9, %8
  br i1 %11, label %12, label %59

12:                                               ; preds = %5
  %13 = call i32 @__cq_mem()
  %14 = getelementptr inbounds i8, ptr %2, i64 8
  %15 = ptrtoint ptr %14 to i64
  %16 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %13, i64 %15)
  %17 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %16, i64 3)
  %18 = sitofp i64 %4 to double
  %19 = sitofp i64 %3 to double
  %20 = fmul double %19, 2.000000e+02
  %21 = tail call double @llvm.fmuladd.f64(double %18, double 3.600000e+03, double %20)
  %22 = fmul double %19, %18
  %23 = fcmp ogt double %21, %22
  br i1 %23, label %24, label %27

24:                                               ; preds = %12
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %25)
  %26 = call i32 @__cq_q_dc_000_ctl(i32 %25, ptr %1, ptr %2, i64 %3)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %25)
  call void @cqrt_free(i32 %25)
  br label %27

27:                                               ; preds = %24, %12
  %28 = xor i1 %23, true
  br i1 %28, label %29, label %32

29:                                               ; preds = %27
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %30)
  %31 = call i32 @__cq_q_mu_000_ctl(i32 %30, ptr %1, ptr %2, i64 %3)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %30)
  call void @cqrt_free(i32 %30)
  br label %32

32:                                               ; preds = %29, %27
  %33 = ptrtoint ptr %2 to i64
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_xor_i1(i32 %17, i32 %35)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %34)
  %36 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %34, i32 %13, i64 %33)
  %37 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %36, i64 1)
  %38 = sitofp i64 %4 to double
  %39 = sitofp i64 %3 to double
  %40 = fmul double %39, 2.000000e+02
  %41 = tail call double @llvm.fmuladd.f64(double %38, double 3.600000e+03, double %40)
  %42 = fmul double %39, %38
  %43 = fcmp ogt double %41, %42
  br i1 %43, label %44, label %49

44:                                               ; preds = %32
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_xor_i1(i32 %17, i32 %47)
  call void @cqrt_and_i1(i32 %37, i32 %47, i32 %46)
  call void @cqrt_and_i1(i32 %0, i32 %46, i32 %45)
  %48 = call i32 @__cq_q_dc_000_ctl(i32 %45, ptr %1, ptr %2, i64 %4)
  call void @cqrt_and_i1(i32 %0, i32 %46, i32 %45)
  call void @cqrt_free(i32 %45)
  call void @cqrt_and_i1(i32 %37, i32 %47, i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_xor_i1(i32 %17, i32 %47)
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_free(i32 %47)
  br label %49

49:                                               ; preds = %44, %32
  %50 = xor i1 %43, true
  br i1 %50, label %51, label %56

51:                                               ; preds = %49
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_xor_i1(i32 %17, i32 %54)
  call void @cqrt_and_i1(i32 %37, i32 %54, i32 %53)
  call void @cqrt_and_i1(i32 %0, i32 %53, i32 %52)
  %55 = call i32 @__cq_q_mu_000_ctl(i32 %52, ptr %1, ptr %2, i64 %4)
  call void @cqrt_and_i1(i32 %0, i32 %53, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cqrt_and_i1(i32 %37, i32 %54, i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cqrt_xor_i1(i32 %17, i32 %54)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_free(i32 %54)
  br label %56

56:                                               ; preds = %51, %49
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %37, i32 %36, i64 1)
  call void @cqrt_free(i32 %37)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %36, i32 %34, i32 %13, i64 %33)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_xor_i1(i32 %17, i32 %35)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %35)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %17, i32 %16, i64 3)
  call void @cqrt_free(i32 %17)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %16, i32 %0, i32 %13, i64 %15)
  %57 = load i32, ptr @__cq_act_divq, align 4
  %58 = add i32 %57, -1
  store i32 %58, ptr @__cq_act_divq, align 4
  ret void

59:                                               ; preds = %5
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %60)
  %61 = load i32, ptr @__cq_act_divq, align 4
  %62 = add i32 %61, -1
  store i32 %62, ptr @__cq_act_divq, align 4
  ret void
}

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @dc, ptr @.cq.sig, ptr @__cq_q_dc_111_t, ptr @__cq_q_dc_111_t_ctl, ptr @__cq_q_dc_111_t_unc, ptr @__cq_q_dc_111_t_ctl_unc)
  call void @__cq_clone_register(ptr @mu, ptr @.cq.sig, ptr @__cq_q_mu_111_t, ptr @__cq_q_mu_111_t_ctl, ptr @__cq_q_mu_111_t_unc, ptr @__cq_q_mu_111_t_ctl_unc)
  call void @__cq_clone_register(ptr @divq, ptr @.cq.sig.1, ptr @__cq_q_divq_1111_t, ptr @__cq_q_divq_1111_t_ctl, ptr @__cq_q_divq_1111_t_unc, ptr @__cq_q_divq_1111_t_ctl_unc)
  call void @__cq_clone_register(ptr @main, ptr @.cq.sig.2, ptr @__cq_q_main_v_t, ptr @__cq_q_main_v_t_ctl, ptr @__cq_q_main_v_t_unc, ptr @__cq_q_main_v_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_dc_111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_dc_111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_dc, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_dc, align 4
  %10 = load i32, ptr @__cq_act_dc, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_dc, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_mu_111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_mu_111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_mu, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_mu, align 4
  %10 = load i32, ptr @__cq_act_mu, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_mu, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_divq_1111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_divq_1111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_divq, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_divq, align 4
  %10 = load i32, ptr @__cq_act_divq, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_divq, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_main_v_t_unc(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cqrt_pop()
  br label %5

5:                                                ; preds = %8, %2
  %6 = phi i32 [ %4, %2 ], [ %10, %8 ]
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = call i32 @cqrt_pop()
  %10 = sub i32 %6, 1
  br label %5

11:                                               ; preds = %5
  store i32 %3, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_main_v_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_main, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_main, align 4
  %7 = load i32, ptr @__cq_act_main, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_main, align 4
  %9 = call i32 @cqrt_pop()
  br label %10

10:                                               ; preds = %13, %3
  %11 = phi i32 [ %9, %3 ], [ %15, %13 ]
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_pop()
  %15 = sub i32 %11, 1
  br label %10

16:                                               ; preds = %10
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: write) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
