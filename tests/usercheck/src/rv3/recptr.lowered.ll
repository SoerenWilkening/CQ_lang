; ModuleID = '<stdin>'
source_filename = "recptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_r = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@__cq_act_f = internal global i32 0, align 4
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define range(i32 0, -2147483648) i32 @r(i32 noundef %0) #0 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %3, label %5

3:                                                ; preds = %5, %1
  %4 = phi i32 [ %9, %5 ], [ 0, %1 ]
  ret i32 %4

5:                                                ; preds = %1
  %6 = add nsw i32 %0, -1
  %7 = tail call i32 @r(i32 noundef %6)
  %8 = mul nuw nsw i32 %7, %7
  %9 = add nuw nsw i32 %8, %0
  br label %3
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = alloca ptr, align 8
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double 1.000000e+00)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store ptr @r, ptr %3, align 8, !tbaa !6
  %5 = load ptr, ptr %3, align 8, !tbaa !6
  %6 = call i32 @cq_template_and_i32_hl(i32 %4, i32 15)
  %7 = call ptr @__cq_clone_resolve(ptr %5, i32 0)
  %8 = icmp eq ptr %7, null
  br i1 %8, label %13, label %9

9:                                                ; preds = %1
  %10 = call i32 %7(i32 %6, i32 4)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %10, i32 %11)
  %12 = call ptr @__cq_clone_resolve(ptr %5, i32 2)
  call void %12(i32 %10, i32 %6, i32 4)
  br label %18

13:                                               ; preds = %1
  %14 = ptrtoint ptr %5 to i64
  %15 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %2, i64 %14)
  %16 = call i32 @cqrt_tape_write_i32(i32 %2, i32 %6)
  %17 = call i32 @cqrt_tape_effect_i32_controlled(i32 %15, i32 %2, ptr null)
  call void @cqrt_free(i32 %15)
  br label %18

18:                                               ; preds = %13, %9
  %19 = phi i32 [ %11, %9 ], [ %17, %13 ]
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %4, i32 15)
  call void @cqrt_free(i32 %6)
  %20 = call i32 @cqrt_measure_i32(i32 %19), !cq.measure !10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  ret i32 %20
}

define internal i32 @__cq_q_r_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)
  %5 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %5)
  call void @cqrt_xor_i1(i32 %3, i32 %5)
  %6 = call i32 @__cq_q_r_1_ctl(i32 %5, i32 %4)
  %7 = call i32 @cq_template_mul_i32(i32 %6, i32 %6)
  %8 = call i32 @cq_template_add_i32(i32 %7, i32 %0)
  %9 = call i32 @cq_template_select_i32_lh(i32 %3, i32 0, i32 %8)
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %9, i32 %10)
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %3, i32 0, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_unc(i32 %8, i32 %7, i32 %0)
  call void @cqrt_free(i32 %8)
  call void @cq_template_mul_i32_unc(i32 %7, i32 %6, i32 %6)
  call void @cqrt_free(i32 %7)
  call void @__cq_q_r_1_ctl_unc(i32 %5, i32 %6, i32 %4)
  call void @cqrt_free(i32 %6)
  call void @cqrt_xor_i1(i32 %3, i32 %5)
  call void @cqrt_not_i1(i32 %5)
  call void @cqrt_free(i32 %5)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)
  call void @cqrt_free(i32 %4)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)
  call void @cqrt_free(i32 %3)
  ret i32 %10
}

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

define i32 @__cq_q_r_1_ctl(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_act_r, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_r, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %18

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  %11 = call i32 @__cq_q_r_1_ctl(i32 %9, i32 %8)
  %12 = call i32 @cq_template_mul_i32(i32 %11, i32 %11)
  %13 = call i32 @cq_template_add_i32(i32 %12, i32 %1)
  %14 = call i32 @cq_template_select_i32_lh(i32 %7, i32 0, i32 %13)
  %15 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %14, i32 %15)
  call void @cq_template_select_i32_lh_unc(i32 %14, i32 %7, i32 0, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i32_unc(i32 %13, i32 %12, i32 %1)
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i32_unc(i32 %12, i32 %11, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @__cq_q_r_1_ctl_unc(i32 %9, i32 %11, i32 %8)
  call void @cqrt_free(i32 %11)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %16 = load i32, ptr @__cq_act_r, align 4
  %17 = add i32 %16, -1
  store i32 %17, ptr @__cq_act_r, align 4
  ret i32 %15

18:                                               ; preds = %2
  %19 = call i32 @cqrt_alloc_i32(i32 0)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %20)
  %21 = load i32, ptr @__cq_act_r, align 4
  %22 = add i32 %21, -1
  store i32 %22, ptr @__cq_act_r, align 4
  ret i32 %19
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_mul_i32(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_unc(i32, i32, i32)

define internal void @__cq_q_r_1_ctl_unc(i32 %0, i32 %out, i32 %1) {
  %3 = load i32, ptr @__cq_act_r, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_r, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %17

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  %11 = call i32 @__cq_q_r_1_ctl(i32 %9, i32 %8)
  %12 = call i32 @cq_template_mul_i32(i32 %11, i32 %11)
  %13 = call i32 @cq_template_add_i32(i32 %12, i32 %1)
  %14 = call i32 @cq_template_select_i32_lh(i32 %7, i32 0, i32 %13)
  call void @cqrt_copy_i32(i32 %14, i32 %out)
  call void @cq_template_select_i32_lh_unc(i32 %14, i32 %7, i32 0, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i32_unc(i32 %13, i32 %12, i32 %1)
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i32_unc(i32 %12, i32 %11, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @__cq_q_r_1_ctl_unc(i32 %9, i32 %11, i32 %8)
  call void @cqrt_free(i32 %11)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %15 = load i32, ptr @__cq_act_r, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_r, align 4
  ret void

17:                                               ; preds = %2
  %18 = load i32, ptr @__cq_act_r, align 4
  %19 = add i32 %18, -1
  store i32 %19, ptr @__cq_act_r, align 4
  ret void
}

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_r_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_r, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_r, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %19

7:                                                ; preds = %3
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %9 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  %11 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %11)
  call void @cqrt_xor_i1(i32 %8, i32 %11)
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %10)
  %12 = call i32 @__cq_q_r_1_ctl(i32 %10, i32 %9)
  %13 = call i32 @cq_template_mul_i32(i32 %12, i32 %12)
  %14 = call i32 @cq_template_add_i32(i32 %13, i32 %1)
  %15 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %14)
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %16)
  call void @cq_template_select_i32_lh_unc(i32 %15, i32 %8, i32 0, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_add_i32_unc(i32 %14, i32 %13, i32 %1)
  call void @cqrt_free(i32 %14)
  call void @cq_template_mul_i32_unc(i32 %13, i32 %12, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @__cq_q_r_1_ctl_unc(i32 %10, i32 %12, i32 %9)
  call void @cqrt_free(i32 %12)
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cqrt_xor_i1(i32 %8, i32 %11)
  call void @cqrt_not_i1(i32 %11)
  call void @cqrt_free(i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %1, i32 -1)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %1, i32 1)
  call void @cqrt_free(i32 %8)
  %17 = load i32, ptr @__cq_act_r, align 4
  %18 = add i32 %17, -1
  store i32 %18, ptr @__cq_act_r, align 4
  ret i32 %16

19:                                               ; preds = %3
  %20 = call i32 @cqrt_alloc_i32(i32 0)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %21)
  %22 = load i32, ptr @__cq_act_r, align 4
  %23 = add i32 %22, -1
  store i32 %23, ptr @__cq_act_r, align 4
  ret i32 %20
}

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare ptr @__cq_clone_resolve(ptr, i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare i32 @cqrt_tape_write_i32(i32, i32)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = alloca ptr, align 8
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32(i32 %5, double 1.000000e+00)
  %6 = alloca { i32, ptr }, align 8
  %7 = getelementptr inbounds { i32, ptr }, ptr %6, i32 0, i32 0
  store i32 %5, ptr %7, align 4
  %8 = load ptr, ptr %cq.mints, align 8
  %9 = getelementptr inbounds { i32, ptr }, ptr %6, i32 0, i32 1
  store ptr %8, ptr %9, align 8
  store ptr %6, ptr %cq.mints, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  store ptr @r, ptr %4, align 8, !tbaa !6
  %10 = load ptr, ptr %4, align 8, !tbaa !6
  %11 = call i32 @cq_template_and_i32_hl(i32 %5, i32 15)
  %12 = call ptr @__cq_clone_resolve(ptr %10, i32 0)
  %13 = icmp eq ptr %12, null
  br i1 %13, label %18, label %14

14:                                               ; preds = %2
  %15 = call i32 %12(i32 %11, i32 %1)
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %16)
  %17 = call ptr @__cq_clone_resolve(ptr %10, i32 2)
  call void %17(i32 %15, i32 %11, i32 %1)
  br label %23

18:                                               ; preds = %2
  %19 = ptrtoint ptr %10 to i64
  %20 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %19)
  %21 = call i32 @cqrt_tape_write_i32(i32 %3, i32 %11)
  %22 = call i32 @cqrt_tape_effect_i32_controlled(i32 %20, i32 %3, ptr null)
  call void @cqrt_free(i32 %20)
  br label %23

23:                                               ; preds = %18, %14
  %24 = phi i32 [ %16, %14 ], [ %22, %18 ]
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %5, i32 15)
  call void @cqrt_free(i32 %11)
  %25 = call i32 @cqrt_measure_i32(i32 %24), !cq.measure !10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  %26 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %26)
  %27 = call i32 @cqrt_alloc_i32(i32 %25)
  ret i32 %27
}

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

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %64

7:                                                ; preds = %3
  %8 = call i32 @cqrt_tape_alloc()
  %9 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call ptr @__cq_alloc(i64 8, i64 8)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %11)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %11, double 1.000000e+00)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = ptrtoint ptr %10 to i64
  %17 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @r to i64))
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 %16, i32 %17)
  %18 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %9, i64 %16)
  %19 = call i32 @cq_template_and_i32_hl(i32 %11, i32 15)
  %20 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  br label %22

22:                                               ; preds = %27, %7
  %23 = phi i32 [ 0, %7 ], [ %38, %27 ]
  %24 = phi i32 [ %0, %7 ], [ %36, %27 ]
  %25 = phi i32 [ %21, %7 ], [ %37, %27 ]
  %26 = icmp ult i32 %23, %20
  br i1 %26, label %27, label %39

27:                                               ; preds = %22
  %28 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %23)
  %29 = ptrtoint ptr %28 to i64
  %30 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 %29)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %31)
  %32 = call ptr @__cq_clone_resolve(ptr %28, i32 1)
  %33 = call i32 %32(i32 %31, i32 %19, i32 %2)
  %34 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %33, i32 %34)
  %35 = call ptr @__cq_clone_resolve(ptr %28, i32 3)
  call void %35(i32 %31, i32 %33, i32 %19, i32 %2)
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %31)
  call void @cqrt_free(i32 %31)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_and_i1(i32 %24, i32 %30, i32 %36)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_push(i32 %24)
  %37 = call i32 @cq_template_select_i32(i32 %30, i32 %34, i32 %25)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %30)
  %38 = add i32 %23, 1
  br label %22

39:                                               ; preds = %22
  %40 = call i32 @cqrt_tape_write_i64_controlled(i32 %24, i32 %8, i32 %18)
  %41 = call i32 @cqrt_tape_write_i32_controlled(i32 %24, i32 %8, i32 %19)
  %42 = call i32 @cqrt_tape_effect_i32_controlled(i32 %24, i32 %8, ptr null)
  %43 = call i32 @cq_template_select_i32(i32 %24, i32 %42, i32 %25)
  %44 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %43, i32 %44)
  call void @cq_template_select_i32_unc(i32 %43, i32 %24, i32 %42, i32 %25)
  call void @cqrt_free(i32 %43)
  br label %45

45:                                               ; preds = %50, %39
  %46 = phi i32 [ %20, %39 ], [ %51, %50 ]
  %47 = phi i32 [ %24, %39 ], [ %55, %50 ]
  %48 = phi i32 [ %25, %39 ], [ %54, %50 ]
  %49 = icmp eq i32 %46, 0
  br i1 %49, label %58, label %50

50:                                               ; preds = %45
  %51 = add i32 %46, -1
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %48, i32 %52, i32 %53, i32 %54)
  call void @cqrt_free(i32 %48)
  call void @cqrt_not_i1(i32 %52)
  call void @cqrt_and_i1(i32 %55, i32 %52, i32 %47)
  call void @cqrt_not_i1(i32 %52)
  call void @cqrt_free(i32 %47)
  %56 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %51)
  %57 = ptrtoint ptr %56 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %52, i32 %18, i64 %57)
  call void @cqrt_free(i32 %52)
  br label %45

58:                                               ; preds = %45
  call void @cqrt_free(i32 %48)
  call void @cq_template_and_i32_hl_unc(i32 %19, i32 %11, i32 15)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %18, i32 %0, i32 %9, i64 %16)
  %59 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %44, i32 %59)
  %60 = call i32 @cqrt_measure_i32(i32 %59), !cq.measure !10
  %61 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %61)
  %62 = load i32, ptr @__cq_act_f, align 4
  %63 = add i32 %62, -1
  store i32 %63, ptr @__cq_act_f, align 4
  ret i32 %59

64:                                               ; preds = %3
  %65 = call i32 @cqrt_alloc_i32(i32 0)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %66)
  call void @cqrt_push(i32 0)
  %67 = load i32, ptr @__cq_act_f, align 4
  %68 = add i32 %67, -1
  store i32 %68, ptr @__cq_act_f, align 4
  ret i32 %65
}

declare ptr @__cq_alloc(i64, i64)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_alloc_i64(i64)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @__cq_clone_count(ptr)

declare ptr @__cq_clone_at(ptr, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare i32 @cqrt_pop()

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

define internal i32 @__cq_q_f_1_t_pure(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = alloca ptr, align 8
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32(i32 %5, double 1.000000e+00)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  store ptr @r, ptr %4, align 8, !tbaa !6
  %6 = load ptr, ptr %4, align 8, !tbaa !6
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 15)
  %8 = call ptr @__cq_clone_resolve(ptr %6, i32 0)
  %9 = icmp eq ptr %8, null
  br i1 %9, label %14, label %10

10:                                               ; preds = %2
  %11 = call i32 %8(i32 %7, i32 %1)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %11, i32 %12)
  %13 = call ptr @__cq_clone_resolve(ptr %6, i32 2)
  call void %13(i32 %11, i32 %7, i32 %1)
  br label %19

14:                                               ; preds = %2
  %15 = ptrtoint ptr %6 to i64
  %16 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %15)
  %17 = call i32 @cqrt_tape_write_i32(i32 %3, i32 %7)
  %18 = call i32 @cqrt_tape_effect_i32_controlled(i32 %16, i32 %3, ptr null)
  call void @cqrt_free(i32 %16)
  br label %19

19:                                               ; preds = %14, %10
  %20 = phi i32 [ %12, %10 ], [ %18, %14 ]
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 15)
  call void @cqrt_free(i32 %7)
  %21 = call i32 @cqrt_measure_i32(i32 %20), !cq.measure !10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  %22 = call i32 @cqrt_alloc_i32(i32 %21)
  ret i32 %22
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @r, ptr @.cq.sig, ptr @__cq_q_r_1_t, ptr @__cq_q_r_1_t_ctl, ptr @__cq_q_r_1_t_unc, ptr @__cq_q_r_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_r_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)
  %5 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %5)
  call void @cqrt_xor_i1(i32 %3, i32 %5)
  %6 = call i32 @__cq_q_r_1_ctl(i32 %5, i32 %4)
  %7 = call i32 @cq_template_mul_i32(i32 %6, i32 %6)
  %8 = call i32 @cq_template_add_i32(i32 %7, i32 %0)
  %9 = call i32 @cq_template_select_i32_lh(i32 %3, i32 0, i32 %8)
  call void @cqrt_copy_i32(i32 %9, i32 %out)
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %3, i32 0, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_unc(i32 %8, i32 %7, i32 %0)
  call void @cqrt_free(i32 %8)
  call void @cq_template_mul_i32_unc(i32 %7, i32 %6, i32 %6)
  call void @cqrt_free(i32 %7)
  call void @__cq_q_r_1_ctl_unc(i32 %5, i32 %6, i32 %4)
  call void @cqrt_free(i32 %6)
  call void @cqrt_xor_i1(i32 %3, i32 %5)
  call void @cqrt_not_i1(i32 %5)
  call void @cqrt_free(i32 %5)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)
  call void @cqrt_free(i32 %4)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %out)
  ret void
}

define internal void @__cq_q_r_1_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_r, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_r, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %18

7:                                                ; preds = %3
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %9 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  %11 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %11)
  call void @cqrt_xor_i1(i32 %8, i32 %11)
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %10)
  %12 = call i32 @__cq_q_r_1_ctl(i32 %10, i32 %9)
  %13 = call i32 @cq_template_mul_i32(i32 %12, i32 %12)
  %14 = call i32 @cq_template_add_i32(i32 %13, i32 %1)
  %15 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %14)
  call void @cqrt_copy_i32(i32 %15, i32 %out)
  call void @cq_template_select_i32_lh_unc(i32 %15, i32 %8, i32 0, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_add_i32_unc(i32 %14, i32 %13, i32 %1)
  call void @cqrt_free(i32 %14)
  call void @cq_template_mul_i32_unc(i32 %13, i32 %12, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @__cq_q_r_1_ctl_unc(i32 %10, i32 %12, i32 %9)
  call void @cqrt_free(i32 %12)
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cqrt_xor_i1(i32 %8, i32 %11)
  call void @cqrt_not_i1(i32 %11)
  call void @cqrt_free(i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %1, i32 -1)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %1, i32 1)
  call void @cqrt_free(i32 %8)
  %16 = load i32, ptr @__cq_act_r, align 4
  %17 = add i32 %16, -1
  store i32 %17, ptr @__cq_act_r, align 4
  call void @cqrt_free(i32 %out)
  ret void

18:                                               ; preds = %3
  %19 = load i32, ptr @__cq_act_r, align 4
  %20 = add i32 %19, -1
  store i32 %20, ptr @__cq_act_r, align 4
  call void @cqrt_free(i32 %out)
  ret void
}

define internal void @__cq_q_f_1_t_unc(i32 %0, i32 %1, i32 %2) {
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

define internal void @__cq_q_f_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_f, align 4
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

attributes #0 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{}
