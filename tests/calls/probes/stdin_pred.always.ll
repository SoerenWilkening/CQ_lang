; ModuleID = 'tests/calls/probes/stdin_pred.O1.ll'
source_filename = "stdin_pred.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8
@.cq.effect.getchar = private unnamed_addr constant [8 x i8] c"getchar\00", align 1
@.cq.effect.fread = private unnamed_addr constant [6 x i8] c"fread\00", align 1
@__cq_act_stdin_pred = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [9 x i8] c"i32 (i8)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_pred(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call ptr @__cq_alloc(i64 4, i64 4)
  %5 = call i32 @cqrt_alloc_i8(i8 %0)
  call void @cqrt_ry_i8(i32 %5, double 3.000000e-01)
  %6 = call i32 @cq_template_sext_i8_to_i32(i32 %5)
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %9)
  call void @cqrt_xor_i1(i32 %8, i32 %9)
  %cq.mut = call i32 @cqrt_alloc_i1(i1 true)
  %10 = call i32 @cqrt_tape_effect_i32_controlled(i32 %cq.mut, i32 %3, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_free(i32 %cq.mut)
  call void @cqrt_xor_i1(i32 %8, i32 %9)
  call void @cqrt_not_i1(i32 %9)
  call void @cqrt_free(i32 %9)
  %11 = call i32 @cq_template_mul_i32_hl(i32 %10, i32 7)
  %12 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %11)
  %13 = call i32 @cqrt_alloc_i1(i1 true)
  %14 = call i32 @cqrt_tape_effect_i32_controlled(i32 %13, i32 %3, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_free(i32 %13)
  %15 = ptrtoint ptr %4 to i64
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 %15, i32 %16)
  %17 = call i32 @cqrt_qram_load_i64_hl(i32 %2, i64 ptrtoint (ptr @__stdinp to i64))
  %18 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %15)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 1)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 3)
  %19 = call i32 @cqrt_tape_write_i64(i32 %3, i32 %17)
  call void @cqrt_qram_load_i64_hl_unc(i32 %17, i32 %2, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_free(i32 %17)
  call void @cqrt_tape_effect_controlled(i32 %18, i32 %3, ptr @.cq.effect.fread, i32 4)
  call void @cqrt_free(i32 %18)
  %20 = call i32 @cq_template_mul_i32_hl(i32 %14, i32 3)
  %21 = call i32 @cqrt_qram_load_i8_hl(i32 %2, i64 %15)
  %22 = call i32 @cq_template_sext_i8_to_i32(i32 %21)
  %23 = getelementptr inbounds i8, ptr %4, i64 2
  %24 = ptrtoint ptr %23 to i64
  %25 = call i32 @cqrt_qram_load_i8_hl(i32 %2, i64 %24)
  %26 = call i32 @cq_template_sext_i8_to_i32(i32 %25)
  %27 = call i32 @cq_template_mul_i32_hl(i32 %26, i32 5)
  %28 = call i32 @cq_template_add_i32(i32 %12, i32 %6)
  call void @cq_template_select_i32_lh_unc(i32 %12, i32 %8, i32 0, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i32_hl_unc(i32 %11, i32 %10, i32 7)
  call void @cqrt_free(i32 %11)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)
  call void @cqrt_free(i32 %8)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 1)
  call void @cqrt_free(i32 %7)
  call void @cq_template_sext_i8_to_i32_unc(i32 %6, i32 %5)
  call void @cqrt_free(i32 %6)
  %29 = call i32 @cq_template_add_i32(i32 %28, i32 %20)
  %30 = call i32 @cq_template_sub_i32(i32 %29, i32 %20)
  call void @cqrt_copy_i32(i32 %30, i32 %28)
  call void @cq_template_sub_i32_unc(i32 %30, i32 %29, i32 %20)
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %28)
  call void @cq_template_mul_i32_hl_unc(i32 %20, i32 %14, i32 3)
  call void @cqrt_free(i32 %20)
  %31 = call i32 @cq_template_add_i32(i32 %29, i32 %22)
  %32 = call i32 @cq_template_sub_i32(i32 %31, i32 %22)
  call void @cqrt_copy_i32(i32 %32, i32 %29)
  call void @cq_template_sub_i32_unc(i32 %32, i32 %31, i32 %22)
  call void @cqrt_free(i32 %32)
  call void @cqrt_free(i32 %29)
  call void @cq_template_sext_i8_to_i32_unc(i32 %22, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cqrt_qram_load_i8_hl_unc(i32 %21, i32 %2, i64 %15)
  call void @cqrt_free(i32 %21)
  %33 = call i32 @cq_template_add_i32(i32 %31, i32 %27)
  %34 = call i32 @cq_template_sub_i32(i32 %33, i32 %27)
  call void @cqrt_copy_i32(i32 %34, i32 %31)
  call void @cq_template_sub_i32_unc(i32 %34, i32 %33, i32 %27)
  call void @cqrt_free(i32 %34)
  call void @cqrt_free(i32 %31)
  call void @cq_template_mul_i32_hl_unc(i32 %27, i32 %26, i32 5)
  call void @cqrt_free(i32 %27)
  call void @cq_template_sext_i8_to_i32_unc(i32 %26, i32 %25)
  call void @cqrt_free(i32 %26)
  call void @cqrt_qram_load_i8_hl_unc(i32 %25, i32 %2, i64 %24)
  call void @cqrt_free(i32 %25)
  %35 = call i32 @cqrt_measure_i32(i32 %33), !cq.measure !6
  ret i32 %35
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nofree nounwind
declare noundef i32 @getchar() local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i64 @fread(ptr nocapture noundef, i64 noundef, i64 noundef, ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare i32 @cqrt_tape_write_i64(i32, i32)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_stdin_pred_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %5 = call ptr @__cq_alloc(i64 4, i64 4)
  %6 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %0, i32 %6)
  call void @cqrt_ry_i8(i32 %6, double 3.000000e-01)
  %7 = alloca { i32, ptr }, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 0
  store i32 %6, ptr %8, align 4
  %9 = load ptr, ptr %cq.mints, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 1
  store ptr %9, ptr %10, align 8
  store ptr %7, ptr %cq.mints, align 8
  %11 = call i32 @cq_template_sext_i8_to_i32(i32 %6)
  %12 = call i32 @cq_template_and_i32_hl(i32 %11, i32 1)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_xor_i1(i32 %13, i32 %14)
  %15 = call i32 @cqrt_tape_effect_i32_controlled(i32 %14, i32 %4, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_xor_i1(i32 %13, i32 %14)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_free(i32 %14)
  %16 = call i32 @cq_template_mul_i32_hl(i32 %15, i32 7)
  %17 = call i32 @cq_template_select_i32_lh(i32 %13, i32 0, i32 %16)
  %18 = call i32 @cqrt_alloc_i1(i1 true)
  %19 = call i32 @cqrt_tape_effect_i32_controlled(i32 %18, i32 %4, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_free(i32 %18)
  %20 = ptrtoint ptr %5 to i64
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %20, i32 %21)
  %22 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 ptrtoint (ptr @__stdinp to i64))
  %23 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 %20)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 1)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 3)
  %24 = call i32 @cqrt_tape_write_i64(i32 %4, i32 %22)
  call void @cqrt_qram_load_i64_hl_unc(i32 %22, i32 %3, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_free(i32 %22)
  call void @cqrt_tape_effect_controlled(i32 %23, i32 %4, ptr @.cq.effect.fread, i32 4)
  call void @cqrt_free(i32 %23)
  %25 = call i32 @cq_template_mul_i32_hl(i32 %19, i32 3)
  %26 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %20)
  %27 = call i32 @cq_template_sext_i8_to_i32(i32 %26)
  %28 = getelementptr inbounds i8, ptr %5, i64 2
  %29 = ptrtoint ptr %28 to i64
  %30 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %29)
  %31 = call i32 @cq_template_sext_i8_to_i32(i32 %30)
  %32 = call i32 @cq_template_mul_i32_hl(i32 %31, i32 5)
  %33 = call i32 @cq_template_add_i32(i32 %17, i32 %11)
  %34 = call i32 @cq_template_add_i32(i32 %33, i32 %25)
  %35 = call i32 @cq_template_add_i32(i32 %34, i32 %27)
  %36 = call i32 @cq_template_add_i32(i32 %35, i32 %32)
  %37 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %36, i32 %37)
  call void @cq_template_add_i32_unc(i32 %36, i32 %35, i32 %32)
  call void @cqrt_free(i32 %36)
  call void @cq_template_add_i32_unc(i32 %35, i32 %34, i32 %27)
  call void @cqrt_free(i32 %35)
  call void @cq_template_add_i32_unc(i32 %34, i32 %33, i32 %25)
  call void @cqrt_free(i32 %34)
  call void @cq_template_add_i32_unc(i32 %33, i32 %17, i32 %11)
  call void @cqrt_free(i32 %33)
  call void @cq_template_mul_i32_hl_unc(i32 %32, i32 %31, i32 5)
  call void @cqrt_free(i32 %32)
  call void @cq_template_sext_i8_to_i32_unc(i32 %31, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cqrt_qram_load_i8_hl_unc(i32 %30, i32 %3, i64 %29)
  call void @cqrt_free(i32 %30)
  call void @cq_template_sext_i8_to_i32_unc(i32 %27, i32 %26)
  call void @cqrt_free(i32 %27)
  call void @cqrt_qram_load_i8_hl_unc(i32 %26, i32 %3, i64 %20)
  call void @cqrt_free(i32 %26)
  call void @cq_template_mul_i32_hl_unc(i32 %25, i32 %19, i32 3)
  call void @cqrt_free(i32 %25)
  call void @cq_template_select_i32_lh_unc(i32 %17, i32 %13, i32 0, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_mul_i32_hl_unc(i32 %16, i32 %15, i32 7)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)
  call void @cqrt_free(i32 %13)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %11, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cq_template_sext_i8_to_i32_unc(i32 %11, i32 %6)
  call void @cqrt_free(i32 %11)
  %38 = call i32 @cqrt_measure_i32(i32 %37), !cq.measure !6
  %39 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %39)
  %40 = call i32 @cqrt_alloc_i32(i32 %38)
  ret i32 %40
}

declare void @cqrt_copy_i8(i32, i32)

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

declare void @cqrt_push(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

define internal i32 @__cq_q_stdin_pred_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_stdin_pred, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_stdin_pred, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %46

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call ptr @__cq_alloc(i64 4, i64 4)
  %11 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %1, i32 %11)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %11, double 3.000000e-01)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @cq_template_sext_i8_to_i32(i32 %11)
  %17 = call i32 @cq_template_and_i32_hl(i32 %16, i32 1)
  %18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 0)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_xor_i1(i32 %18, i32 %20)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  %21 = call i32 @cqrt_tape_effect_i32_controlled(i32 %19, i32 %9, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_xor_i1(i32 %18, i32 %20)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_free(i32 %20)
  %22 = call i32 @cq_template_mul_i32_hl(i32 %21, i32 7)
  %23 = call i32 @cq_template_select_i32_lh(i32 %18, i32 0, i32 %22)
  %24 = call i32 @cqrt_tape_effect_i32_controlled(i32 %0, i32 %9, ptr @.cq.effect.getchar, i32 0)
  %25 = ptrtoint ptr %10 to i64
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %8, i64 %25, i32 %26)
  %27 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_tape_write_i64_lit(i32 %9, i64 %25)
  call void @cqrt_tape_write_i64_lit(i32 %9, i64 1)
  call void @cqrt_tape_write_i64_lit(i32 %9, i64 3)
  %28 = call i32 @cqrt_tape_write_i64_controlled(i32 %0, i32 %9, i32 %27)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %27, i32 %0, i32 %8, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_free(i32 %27)
  call void @cqrt_tape_effect_controlled(i32 %0, i32 %9, ptr @.cq.effect.fread, i32 4)
  %29 = call i32 @cq_template_mul_i32_hl(i32 %24, i32 3)
  %30 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %25)
  %31 = call i32 @cq_template_sext_i8_to_i32(i32 %30)
  %32 = getelementptr inbounds i8, ptr %10, i64 2
  %33 = ptrtoint ptr %32 to i64
  %34 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %33)
  %35 = call i32 @cq_template_sext_i8_to_i32(i32 %34)
  %36 = call i32 @cq_template_mul_i32_hl(i32 %35, i32 5)
  %37 = call i32 @cq_template_add_i32(i32 %23, i32 %16)
  %38 = call i32 @cq_template_add_i32(i32 %37, i32 %29)
  %39 = call i32 @cq_template_add_i32(i32 %38, i32 %31)
  %40 = call i32 @cq_template_add_i32(i32 %39, i32 %36)
  %41 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %40, i32 %41)
  call void @cq_template_add_i32_unc(i32 %40, i32 %39, i32 %36)
  call void @cqrt_free(i32 %40)
  call void @cq_template_add_i32_unc(i32 %39, i32 %38, i32 %31)
  call void @cqrt_free(i32 %39)
  call void @cq_template_add_i32_unc(i32 %38, i32 %37, i32 %29)
  call void @cqrt_free(i32 %38)
  call void @cq_template_add_i32_unc(i32 %37, i32 %23, i32 %16)
  call void @cqrt_free(i32 %37)
  call void @cq_template_mul_i32_hl_unc(i32 %36, i32 %35, i32 5)
  call void @cqrt_free(i32 %36)
  call void @cq_template_sext_i8_to_i32_unc(i32 %35, i32 %34)
  call void @cqrt_free(i32 %35)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %34, i32 %0, i32 %8, i64 %33)
  call void @cqrt_free(i32 %34)
  call void @cq_template_sext_i8_to_i32_unc(i32 %31, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %30, i32 %0, i32 %8, i64 %25)
  call void @cqrt_free(i32 %30)
  call void @cq_template_mul_i32_hl_unc(i32 %29, i32 %24, i32 3)
  call void @cqrt_free(i32 %29)
  call void @cq_template_select_i32_lh_unc(i32 %23, i32 %18, i32 0, i32 %22)
  call void @cqrt_free(i32 %23)
  call void @cq_template_mul_i32_hl_unc(i32 %22, i32 %21, i32 7)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %18, i32 %17, i32 0)
  call void @cqrt_free(i32 %18)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %16, i32 1)
  call void @cqrt_free(i32 %17)
  call void @cq_template_sext_i8_to_i32_unc(i32 %16, i32 %11)
  call void @cqrt_free(i32 %16)
  %42 = call i32 @cqrt_measure_i32(i32 %41), !cq.measure !6
  %43 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %43)
  %44 = load i32, ptr @__cq_act_stdin_pred, align 4
  %45 = add i32 %44, -1
  store i32 %45, ptr @__cq_act_stdin_pred, align 4
  ret i32 %41

46:                                               ; preds = %3
  %47 = call i32 @cqrt_alloc_i32(i32 0)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %48)
  call void @cqrt_push(i32 0)
  %49 = load i32, ptr @__cq_act_stdin_pred, align 4
  %50 = add i32 %49, -1
  store i32 %50, ptr @__cq_act_stdin_pred, align 4
  ret i32 %47
}

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @stdin_pred, ptr @.cq.sig, ptr @__cq_q_stdin_pred_1_t, ptr @__cq_q_stdin_pred_1_t_ctl, ptr @__cq_q_stdin_pred_1_t_unc, ptr @__cq_q_stdin_pred_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_stdin_pred_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_pop()
  br label %5

5:                                                ; preds = %8, %3
  %6 = phi i32 [ %4, %3 ], [ %10, %8 ]
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = call i32 @cqrt_pop()
  %10 = sub i32 %6, 1
  br label %5

11:                                               ; preds = %5
  ret void
}

define internal void @__cq_q_stdin_pred_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_stdin_pred, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stdin_pred, align 4
  %7 = load i32, ptr @__cq_act_stdin_pred, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_stdin_pred, align 4
  %9 = call i32 @cqrt_pop()
  br label %10

10:                                               ; preds = %13, %4
  %11 = phi i32 [ %9, %4 ], [ %15, %13 ]
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_pop()
  %15 = sub i32 %11, 1
  br label %10

16:                                               ; preds = %10
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
