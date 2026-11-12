; tests/calls stdin_direct: cq-lower's output with the fgets tape entry made a direct host call (cq-cyjua)
; ModuleID = 'stdin_direct.O1.ll'
source_filename = "stdin_direct.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8
@.cq.effect.getchar = private unnamed_addr constant [8 x i8] c"getchar\00", align 1
@__cq_act_qpart = internal global i32 0, align 4
@.cq.effect.fgets = private unnamed_addr constant [6 x i8] c"fgets\00", align 1
@__cq_act_stdin_direct = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [9 x i8] c"i32 (i8)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @qpart(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @cqrt_alloc_i8(i8 %0)
  call void @cqrt_ry_i8(i32 %3, double 3.000000e-01)
  %4 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)
  %7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_xor_i1(i32 %6, i32 %7)
  %8 = call i32 @cqrt_tape_effect_i32_controlled(i32 %7, i32 %2, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_xor_i1(i32 %6, i32 %7)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_free(i32 %7)
  %9 = call i32 @cq_template_select_i32_lh(i32 %6, i32 0, i32 %8)
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %4)
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %6, i32 0, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cq_template_sext_i8_to_i32_unc(i32 %4, i32 %3)
  call void @cqrt_free(i32 %4)
  %11 = call i32 @cqrt_measure_i32(i32 %10), !cq.measure !6
  ret i32 %11
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nofree nounwind
declare noundef i32 @getchar() local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_direct(i8 noundef signext %0) local_unnamed_addr #3 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 8, i64 8)
  %5 = tail call i32 @qpart(i8 noundef signext %0)
  %6 = ptrtoint ptr %4 to i64
  %7 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %6, i32 %7)
  %cq.fp = load ptr, ptr @__stdinp, align 8
  %cq.r = call ptr @fgets(ptr %4, i32 4, ptr %cq.fp)
  %cq.ri = ptrtoint ptr %cq.r to i64
  %11 = call i32 @cqrt_alloc_i64(i64 %cq.ri)
  %12 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 0)
  %13 = call i32 @cq_template_select_i32_ll(i32 %12, i32 0, i32 3)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %12, i32 %11, i64 0)
  call void @cqrt_free(i32 %12)
  %14 = call i32 @cq_template_add_i32_hl(i32 %13, i32 %5)
  %15 = call i32 @cq_template_sub_i32_hl(i32 %14, i32 %5)
  call void @cqrt_copy_i32(i32 %15, i32 %13)
  call void @cq_template_sub_i32_hl_unc(i32 %15, i32 %14, i32 %5)
  call void @cqrt_free(i32 %15)
  call void @cqrt_free(i32 %13)
  %16 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %6)
  %17 = call i32 @cq_template_sext_i8_to_i32(i32 %16)
  %18 = call i32 @cq_template_mul_i32_hl(i32 %17, i32 5)
  %19 = call i32 @cq_template_add_i32(i32 %14, i32 %18)
  %20 = call i32 @cq_template_sub_i32(i32 %19, i32 %18)
  call void @cqrt_copy_i32(i32 %20, i32 %14)
  call void @cq_template_sub_i32_unc(i32 %20, i32 %19, i32 %18)
  call void @cqrt_free(i32 %20)
  call void @cqrt_free(i32 %14)
  call void @cq_template_mul_i32_hl_unc(i32 %18, i32 %17, i32 5)
  call void @cqrt_free(i32 %18)
  call void @cq_template_sext_i8_to_i32_unc(i32 %17, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cqrt_qram_load_i8_hl_unc(i32 %16, i32 %3, i64 %6)
  call void @cqrt_free(i32 %16)
  %21 = getelementptr inbounds i8, ptr %4, i64 1
  %22 = ptrtoint ptr %21 to i64
  %23 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %22)
  %24 = call i32 @cq_template_sext_i8_to_i32(i32 %23)
  %25 = call i32 @cq_template_mul_i32_hl(i32 %24, i32 7)
  %26 = call i32 @cq_template_add_i32(i32 %19, i32 %25)
  %27 = call i32 @cq_template_sub_i32(i32 %26, i32 %25)
  call void @cqrt_copy_i32(i32 %27, i32 %19)
  call void @cq_template_sub_i32_unc(i32 %27, i32 %26, i32 %25)
  call void @cqrt_free(i32 %27)
  call void @cqrt_free(i32 %19)
  call void @cq_template_mul_i32_hl_unc(i32 %25, i32 %24, i32 7)
  call void @cqrt_free(i32 %25)
  call void @cq_template_sext_i8_to_i32_unc(i32 %24, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cqrt_qram_load_i8_hl_unc(i32 %23, i32 %3, i64 %22)
  call void @cqrt_free(i32 %23)
  ret i32 %26
}

; Function Attrs: nofree nounwind
declare noundef ptr @fgets(ptr noundef, i32 noundef, ptr nocapture noundef) local_unnamed_addr #2

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

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

define internal i32 @__cq_q_qpart_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %0, i32 %4)
  call void @cqrt_ry_i8(i32 %4, double 3.000000e-01)
  %5 = alloca { i32, ptr }, align 8
  %6 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 0
  store i32 %4, ptr %6, align 4
  %7 = load ptr, ptr %cq.mints, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 1
  store ptr %7, ptr %8, align 8
  store ptr %5, ptr %cq.mints, align 8
  %9 = call i32 @cq_template_sext_i8_to_i32(i32 %4)
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 1)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 0)
  %12 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_xor_i1(i32 %11, i32 %12)
  %13 = call i32 @cqrt_tape_effect_i32_controlled(i32 %12, i32 %3, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_xor_i1(i32 %11, i32 %12)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_free(i32 %12)
  %14 = call i32 @cq_template_select_i32_lh(i32 %11, i32 0, i32 %13)
  %15 = call i32 @cq_template_add_i32(i32 %14, i32 %9)
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %16)
  call void @cq_template_add_i32_unc(i32 %15, i32 %14, i32 %9)
  call void @cqrt_free(i32 %15)
  call void @cq_template_select_i32_lh_unc(i32 %14, i32 %11, i32 0, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 0)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_sext_i8_to_i32_unc(i32 %9, i32 %4)
  call void @cqrt_free(i32 %9)
  %17 = call i32 @cqrt_measure_i32(i32 %16), !cq.measure !6
  %18 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %18)
  %19 = call i32 @cqrt_alloc_i32(i32 %17)
  ret i32 %19
}

declare void @cqrt_copy_i8(i32, i32)

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

declare void @cqrt_push(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

define internal i32 @__cq_q_qpart_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_qpart, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_qpart, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %27

7:                                                ; preds = %3
  %8 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %1, i32 %9)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %9, double 3.000000e-01)
  %10 = alloca { i32, ptr }, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 0
  store i32 %9, ptr %11, align 4
  %12 = load ptr, ptr %cq.mints, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 1
  store ptr %12, ptr %13, align 8
  store ptr %10, ptr %cq.mints, align 8
  %14 = call i32 @cq_template_sext_i8_to_i32(i32 %9)
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 1)
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  %19 = call i32 @cqrt_tape_effect_i32_controlled(i32 %17, i32 %8, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  %20 = call i32 @cq_template_select_i32_lh(i32 %16, i32 0, i32 %19)
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %14)
  %22 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %21, i32 %22)
  call void @cq_template_add_i32_unc(i32 %21, i32 %20, i32 %14)
  call void @cqrt_free(i32 %21)
  call void @cq_template_select_i32_lh_unc(i32 %20, i32 %16, i32 0, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)
  call void @cqrt_free(i32 %16)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %14, i32 1)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sext_i8_to_i32_unc(i32 %14, i32 %9)
  call void @cqrt_free(i32 %14)
  %23 = call i32 @cqrt_measure_i32(i32 %22), !cq.measure !6
  %24 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %24)
  %25 = load i32, ptr @__cq_act_qpart, align 4
  %26 = add i32 %25, -1
  store i32 %26, ptr @__cq_act_qpart, align 4
  ret i32 %22

27:                                               ; preds = %3
  %28 = call i32 @cqrt_alloc_i32(i32 0)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %29)
  call void @cqrt_push(i32 0)
  %30 = load i32, ptr @__cq_act_qpart, align 4
  %31 = add i32 %30, -1
  store i32 %31, ptr @__cq_act_qpart, align 4
  ret i32 %28
}

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i64(i64)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare void @cqrt_tape_write_i32_lit(i32, i32)

declare i32 @cqrt_tape_write_i64(i32, i32)

declare i32 @cqrt_tape_effect_i64_controlled(i32, i32, ptr, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_stdin_direct_1_t(i32 %0, i32 %1) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 8, i64 8)
  %6 = call i32 @__cq_q_qpart_1(i32 %0)
  %7 = ptrtoint ptr %5 to i64
  %8 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %7, i32 %8)
  %9 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr @__stdinp to i64))
  %10 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %7)
  call void @cqrt_tape_write_i32_lit(i32 %3, i32 4)
  %11 = call i32 @cqrt_tape_write_i64(i32 %3, i32 %9)
  call void @cqrt_qram_load_i64_hl_unc(i32 %9, i32 %4, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_free(i32 %9)
  %12 = call i32 @cqrt_tape_effect_i64_controlled(i32 %10, i32 %3, ptr @.cq.effect.fgets, i32 3)
  call void @cqrt_free(i32 %10)
  %13 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 0)
  %14 = call i32 @cq_template_select_i32_ll(i32 %13, i32 0, i32 3)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %13, i32 %12, i64 0)
  call void @cqrt_free(i32 %13)
  %15 = call i32 @cq_template_add_i32_hl(i32 %14, i32 %6)
  %16 = call i32 @cq_template_sub_i32_hl(i32 %15, i32 %6)
  call void @cqrt_copy_i32(i32 %16, i32 %14)
  call void @cq_template_sub_i32_hl_unc(i32 %16, i32 %15, i32 %6)
  call void @cqrt_free(i32 %16)
  call void @cqrt_free(i32 %14)
  %17 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %7)
  %18 = call i32 @cq_template_sext_i8_to_i32(i32 %17)
  %19 = call i32 @cq_template_mul_i32_hl(i32 %18, i32 5)
  %20 = call i32 @cq_template_add_i32(i32 %15, i32 %19)
  %21 = call i32 @cq_template_sub_i32(i32 %20, i32 %19)
  call void @cqrt_copy_i32(i32 %21, i32 %15)
  call void @cq_template_sub_i32_unc(i32 %21, i32 %20, i32 %19)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %15)
  call void @cq_template_mul_i32_hl_unc(i32 %19, i32 %18, i32 5)
  call void @cqrt_free(i32 %19)
  call void @cq_template_sext_i8_to_i32_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cqrt_qram_load_i8_hl_unc(i32 %17, i32 %4, i64 %7)
  call void @cqrt_free(i32 %17)
  %22 = getelementptr inbounds i8, ptr %5, i64 1
  %23 = ptrtoint ptr %22 to i64
  %24 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %23)
  %25 = call i32 @cq_template_sext_i8_to_i32(i32 %24)
  %26 = call i32 @cq_template_mul_i32_hl(i32 %25, i32 7)
  %27 = call i32 @cq_template_add_i32(i32 %20, i32 %26)
  %28 = call i32 @cq_template_sub_i32(i32 %27, i32 %26)
  call void @cqrt_copy_i32(i32 %28, i32 %20)
  call void @cq_template_sub_i32_unc(i32 %28, i32 %27, i32 %26)
  call void @cqrt_free(i32 %28)
  call void @cqrt_free(i32 %20)
  call void @cq_template_mul_i32_hl_unc(i32 %26, i32 %25, i32 7)
  call void @cqrt_free(i32 %26)
  call void @cq_template_sext_i8_to_i32_unc(i32 %25, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cqrt_qram_load_i8_hl_unc(i32 %24, i32 %4, i64 %23)
  call void @cqrt_free(i32 %24)
  %29 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %29)
  ret i32 %27
}

define i32 @__cq_q_qpart_1(i32 %0) local_unnamed_addr {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %0, i32 %3)
  call void @cqrt_ry_i8(i32 %3, double 3.000000e-01)
  %4 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)
  %7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_xor_i1(i32 %6, i32 %7)
  %8 = call i32 @cqrt_tape_effect_i32_controlled(i32 %7, i32 %2, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_xor_i1(i32 %6, i32 %7)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_free(i32 %7)
  %9 = call i32 @cq_template_select_i32_lh(i32 %6, i32 0, i32 %8)
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %4)
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %6, i32 0, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cq_template_sext_i8_to_i32_unc(i32 %4, i32 %3)
  call void @cqrt_free(i32 %4)
  %11 = call i32 @cqrt_measure_i32(i32 %10), !cq.measure !6
  ret i32 %11
}

define internal i32 @__cq_q_stdin_direct_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_stdin_direct, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_stdin_direct, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %36

7:                                                ; preds = %3
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_tape_alloc()
  %9 = call i32 @__cq_mem()
  %10 = call ptr @__cq_alloc(i64 8, i64 8)
  %11 = call i32 @__cq_q_qpart_1_ctl(i32 %0, i32 %1)
  %12 = ptrtoint ptr %10 to i64
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 %12, i32 %13)
  %14 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %9, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_tape_write_i64_lit(i32 %8, i64 %12)
  call void @cqrt_tape_write_i32_lit(i32 %8, i32 4)
  %15 = call i32 @cqrt_tape_write_i64_controlled(i32 %0, i32 %8, i32 %14)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %14, i32 %0, i32 %9, i64 ptrtoint (ptr @__stdinp to i64))
  call void @cqrt_free(i32 %14)
  %16 = call i32 @cqrt_tape_effect_i64_controlled(i32 %0, i32 %8, ptr @.cq.effect.fgets, i32 3)
  %17 = call i32 @cq_template_icmp_eq_i64_hl(i32 %16, i64 0)
  %18 = call i32 @cq_template_select_i32_ll(i32 %17, i32 0, i32 3)
  %19 = call i32 @cq_template_add_i32(i32 %18, i32 %11)
  %20 = call i32 @cq_template_sub_i32(i32 %19, i32 %18)
  call void @cqrt_copy_i32(i32 %20, i32 %11)
  call void @cq_template_sub_i32_unc(i32 %20, i32 %19, i32 %18)
  call void @cqrt_free(i32 %20)
  call void @cqrt_free(i32 %11)
  call void @cq_template_select_i32_ll_unc(i32 %18, i32 %17, i32 0, i32 3)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %17, i32 %16, i64 0)
  call void @cqrt_free(i32 %17)
  %21 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %9, i64 %12)
  %22 = call i32 @cq_template_sext_i8_to_i32(i32 %21)
  %23 = call i32 @cq_template_mul_i32_hl(i32 %22, i32 5)
  %24 = call i32 @cq_template_add_i32(i32 %19, i32 %23)
  %25 = call i32 @cq_template_sub_i32(i32 %24, i32 %23)
  call void @cqrt_copy_i32(i32 %25, i32 %19)
  call void @cq_template_sub_i32_unc(i32 %25, i32 %24, i32 %23)
  call void @cqrt_free(i32 %25)
  call void @cqrt_free(i32 %19)
  call void @cq_template_mul_i32_hl_unc(i32 %23, i32 %22, i32 5)
  call void @cqrt_free(i32 %23)
  call void @cq_template_sext_i8_to_i32_unc(i32 %22, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %21, i32 %0, i32 %9, i64 %12)
  call void @cqrt_free(i32 %21)
  %26 = getelementptr inbounds i8, ptr %10, i64 1
  %27 = ptrtoint ptr %26 to i64
  %28 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %9, i64 %27)
  %29 = call i32 @cq_template_sext_i8_to_i32(i32 %28)
  %30 = call i32 @cq_template_mul_i32_hl(i32 %29, i32 7)
  %31 = call i32 @cq_template_add_i32(i32 %24, i32 %30)
  %32 = call i32 @cq_template_sub_i32(i32 %31, i32 %30)
  call void @cqrt_copy_i32(i32 %32, i32 %24)
  call void @cq_template_sub_i32_unc(i32 %32, i32 %31, i32 %30)
  call void @cqrt_free(i32 %32)
  call void @cqrt_free(i32 %24)
  call void @cq_template_mul_i32_hl_unc(i32 %30, i32 %29, i32 7)
  call void @cqrt_free(i32 %30)
  call void @cq_template_sext_i8_to_i32_unc(i32 %29, i32 %28)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %28, i32 %0, i32 %9, i64 %27)
  call void @cqrt_free(i32 %28)
  %33 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %33)
  %34 = load i32, ptr @__cq_act_stdin_direct, align 4
  %35 = add i32 %34, -1
  store i32 %35, ptr @__cq_act_stdin_direct, align 4
  ret i32 %31

36:                                               ; preds = %3
  %37 = call i32 @cqrt_alloc_i32(i32 0)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %38)
  call void @cqrt_push(i32 0)
  %39 = load i32, ptr @__cq_act_stdin_direct, align 4
  %40 = add i32 %39, -1
  store i32 %40, ptr @__cq_act_stdin_direct, align 4
  ret i32 %37
}

define i32 @__cq_q_qpart_1_ctl(i32 %0, i32 %1) local_unnamed_addr {
  %3 = load i32, ptr @__cq_act_qpart, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_qpart, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %21

6:                                                ; preds = %2
  %7 = call i32 @cqrt_tape_alloc()
  %8 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %1, i32 %8)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %8, double 3.000000e-01)
  %9 = call i32 @cq_template_sext_i8_to_i32(i32 %8)
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 1)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 0)
  %12 = call i32 @cqrt_alloc_i1(i1 false)
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %13)
  call void @cqrt_xor_i1(i32 %11, i32 %13)
  call void @cqrt_and_i1(i32 %0, i32 %13, i32 %12)
  %14 = call i32 @cqrt_tape_effect_i32_controlled(i32 %12, i32 %7, ptr @.cq.effect.getchar, i32 0)
  call void @cqrt_and_i1(i32 %0, i32 %13, i32 %12)
  call void @cqrt_free(i32 %12)
  call void @cqrt_xor_i1(i32 %11, i32 %13)
  call void @cqrt_not_i1(i32 %13)
  call void @cqrt_free(i32 %13)
  %15 = call i32 @cq_template_select_i32_lh(i32 %11, i32 0, i32 %14)
  %16 = call i32 @cq_template_add_i32(i32 %15, i32 %9)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %16, i32 %17)
  call void @cq_template_add_i32_unc(i32 %16, i32 %15, i32 %9)
  call void @cqrt_free(i32 %16)
  call void @cq_template_select_i32_lh_unc(i32 %15, i32 %11, i32 0, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 0)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_sext_i8_to_i32_unc(i32 %9, i32 %8)
  call void @cqrt_free(i32 %9)
  %18 = call i32 @cqrt_measure_i32(i32 %17), !cq.measure !6
  %19 = load i32, ptr @__cq_act_qpart, align 4
  %20 = add i32 %19, -1
  store i32 %20, ptr @__cq_act_qpart, align 4
  ret i32 %17

21:                                               ; preds = %2
  %22 = call i32 @cqrt_alloc_i32(i32 0)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %23)
  %24 = load i32, ptr @__cq_act_qpart, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_qpart, align 4
  ret i32 %22
}

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @qpart, ptr @.cq.sig, ptr @__cq_q_qpart_1_t, ptr @__cq_q_qpart_1_t_ctl, ptr @__cq_q_qpart_1_t_unc, ptr @__cq_q_qpart_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @stdin_direct, ptr @.cq.sig, ptr @__cq_q_stdin_direct_1_t, ptr @__cq_q_stdin_direct_1_t_ctl, ptr @__cq_q_stdin_direct_1_t_unc, ptr @__cq_q_stdin_direct_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_qpart_1_t_unc(i32 %0, i32 %1, i32 %2) {
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

define internal void @__cq_q_qpart_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_qpart, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_qpart, align 4
  %7 = load i32, ptr @__cq_act_qpart, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_qpart, align 4
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

define internal void @__cq_q_stdin_direct_1_t_unc(i32 %0, i32 %1, i32 %2) {
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

define internal void @__cq_q_stdin_direct_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_stdin_direct, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stdin_direct, align 4
  %7 = load i32, ptr @__cq_act_stdin_direct, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_stdin_direct, align 4
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

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
