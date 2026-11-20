; ModuleID = '<stdin>'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.effect.abort = private unnamed_addr constant [6 x i8] c"abort\00", align 1
@__cq_act_stub = internal global i32 0, align 4
@__cq_k = internal global i32 -1, align 4
@.cq.sig = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [10 x i8] c"i32 (ptr)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %3, double %1)
  %4 = call i32 @cq_template_and_i32_hl(i32 %3, i32 1)
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)
  %6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_xor_i1(i32 %5, i32 %6)
  %7 = call i32 @__cq_q_stub_0_ctl(i32 %6, ptr @cell)
  call void @cqrt_xor_i1(i32 %5, i32 %6)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_free(i32 %6)
  %8 = icmp eq i32 %7, 0
  %9 = add nsw i32 %7, 1
  %10 = select i1 %8, i32 7, i32 %9
  %11 = call i32 @cq_template_select_i32_ll(i32 %5, i32 2, i32 %10)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 0)
  call void @cqrt_free(i32 %5)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %3, i32 1)
  call void @cqrt_free(i32 %4)
  ret i32 %11
}

; Function Attrs: noreturn nounwind ssp uwtable
define noundef i32 @stub(ptr noundef %0) local_unnamed_addr #1 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_effect_controlled(i32 %3, i32 %2, ptr @.cq.effect.abort, i32 0)
  call void @cqrt_abort_i1(i32 %3)
  unreachable
}

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

define i32 @__cq_q_stub_0_ctl(i32 %0, ptr %1) local_unnamed_addr {
  %3 = load i32, ptr @__cq_k, align 4
  %4 = icmp eq i32 %3, -1
  %5 = select i1 %4, i32 4, i32 %3
  %6 = load i32, ptr @__cq_act_stub, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_stub, align 4
  %8 = icmp ult i32 %6, %5
  br i1 %8, label %9, label %13

9:                                                ; preds = %2
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %10)
  call void @cqrt_abort_i1(i32 %10)
  %11 = load i32, ptr @__cq_act_stub, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_stub, align 4
  ret i32 0

13:                                               ; preds = %2
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %14)
  %15 = load i32, ptr @__cq_act_stub, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_stub, align 4
  ret i32 0
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32_qangle(i32 %5, i32 %1)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
  %8 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  %9 = call i32 @__cq_q_stub_0_ctl(i32 %8, ptr @cell)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_free(i32 %8)
  %10 = icmp eq i32 %9, 0
  %11 = add nsw i32 %9, 1
  %12 = select i1 %10, i32 7, i32 %11
  %13 = call i32 @cq_template_select_i32_ll(i32 %7, i32 2, i32 %12)
  call void @cqrt_push(i32 %5)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %13, i32 %14)
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %7, i32 2, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %14
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_ry_i32_qangle(i32, i32)

declare void @cqrt_push(i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %23

9:                                                ; preds = %4
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %10)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %10, i32 %2)
  %11 = call i32 @cq_template_and_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %11, i32 0)
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_xor_i1(i32 %12, i32 %14)
  call void @cqrt_and_i1(i32 %0, i32 %14, i32 %13)
  %15 = call i32 @__cq_q_stub_0_ctl(i32 %13, ptr @cell)
  call void @cqrt_and_i1(i32 %0, i32 %14, i32 %13)
  call void @cqrt_free(i32 %13)
  call void @cqrt_xor_i1(i32 %12, i32 %14)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_free(i32 %14)
  %16 = icmp eq i32 %15, 0
  %17 = add nsw i32 %15, 1
  %18 = select i1 %16, i32 7, i32 %17
  %19 = call i32 @cq_template_select_i32_ll(i32 %12, i32 2, i32 %18)
  call void @cqrt_push(i32 %10)
  %20 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %19, i32 %20)
  call void @cq_template_select_i32_ll_unc(i32 %19, i32 %12, i32 2, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %11, i32 0)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  %21 = load i32, ptr @__cq_act_f, align 4
  %22 = add i32 %21, -1
  store i32 %22, ptr @__cq_act_f, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %20

23:                                               ; preds = %4
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %25)
  call void @cqrt_push(i32 0)
  %26 = load i32, ptr @__cq_act_f, align 4
  %27 = add i32 %26, -1
  store i32 %27, ptr @__cq_act_f, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %24
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare void @cqrt_abort_i1(i32)

define internal i32 @__cq_q_stub_1_t(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_effect_controlled(i32 %5, i32 %4, ptr @.cq.effect.abort, i32 0)
  call void @cqrt_abort_i1(i32 %5)
  unreachable
}

define internal i32 @__cq_q_stub_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_stub, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stub, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %13

8:                                                ; preds = %3
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %9)
  call void @cqrt_abort_i1(i32 %9)
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  %11 = load i32, ptr @__cq_act_stub, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_stub, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %10

13:                                               ; preds = %3
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %15)
  %16 = load i32, ptr @__cq_act_stub, align 4
  %17 = add i32 %16, -1
  store i32 %17, ptr @__cq_act_stub, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %14
}

define internal i32 @__cq_q_stub_1_t_ctl_pure(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_stub, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stub, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %12

8:                                                ; preds = %3
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  %10 = load i32, ptr @__cq_act_stub, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_stub, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %9

12:                                               ; preds = %3
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %14)
  %15 = load i32, ptr @__cq_act_stub, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_stub, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %13
}

define internal i32 @__cq_q_stub_1_t_pure(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %4
}

define i32 @__cq_q_stub_0_ctl_pure(i32 %0, ptr %1) local_unnamed_addr {
  %3 = load i32, ptr @__cq_k, align 4
  %4 = icmp eq i32 %3, -1
  %5 = select i1 %4, i32 4, i32 %3
  %6 = load i32, ptr @__cq_act_stub, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_stub, align 4
  %8 = icmp ult i32 %6, %5
  br i1 %8, label %9, label %12

9:                                                ; preds = %2
  %10 = load i32, ptr @__cq_act_stub, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_stub, align 4
  ret i32 0

12:                                               ; preds = %2
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %13)
  %14 = load i32, ptr @__cq_act_stub, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_stub, align 4
  ret i32 0
}

define internal i32 @__cq_q_f_11_t_ctl_pure(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %23

9:                                                ; preds = %4
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %10)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %10, i32 %2)
  %11 = call i32 @cq_template_and_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %11, i32 0)
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_xor_i1(i32 %12, i32 %14)
  call void @cqrt_and_i1(i32 %0, i32 %14, i32 %13)
  %15 = call i32 @__cq_q_stub_0_ctl_pure(i32 %13, ptr @cell)
  call void @cqrt_and_i1(i32 %0, i32 %14, i32 %13)
  call void @cqrt_free(i32 %13)
  call void @cqrt_xor_i1(i32 %12, i32 %14)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_free(i32 %14)
  %16 = icmp eq i32 %15, 0
  %17 = add nsw i32 %15, 1
  %18 = select i1 %16, i32 7, i32 %17
  %19 = call i32 @cq_template_select_i32_ll(i32 %12, i32 2, i32 %18)
  call void @cqrt_push(i32 %10)
  %20 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %19, i32 %20)
  call void @cq_template_select_i32_ll_unc(i32 %19, i32 %12, i32 2, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %11, i32 0)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  %21 = load i32, ptr @__cq_act_f, align 4
  %22 = add i32 %21, -1
  store i32 %22, ptr @__cq_act_f, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %20

23:                                               ; preds = %4
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %25)
  call void @cqrt_push(i32 0)
  %26 = load i32, ptr @__cq_act_f, align 4
  %27 = add i32 %26, -1
  store i32 %27, ptr @__cq_act_f, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %24
}

define internal i32 @__cq_q_f_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32_qangle(i32 %5, i32 %1)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
  %8 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  %9 = call i32 @__cq_q_stub_0_ctl_pure(i32 %8, ptr @cell)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_free(i32 %8)
  %10 = icmp eq i32 %9, 0
  %11 = add nsw i32 %9, 1
  %12 = select i1 %10, i32 7, i32 %11
  %13 = call i32 @cq_template_select_i32_ll(i32 %7, i32 2, i32 %12)
  call void @cqrt_push(i32 %5)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %13, i32 %14)
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %7, i32 2, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %14
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  call void @__cq_clone_register(ptr @stub, ptr @.cq.sig.1, ptr @__cq_q_stub_1_t, ptr @__cq_q_stub_1_t_ctl, ptr @__cq_q_stub_1_t_unc, ptr @__cq_q_stub_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_11_t_unc(i32 %out, i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @cqrt_pop()
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
  %8 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  %9 = call i32 @__cq_q_stub_0_ctl_pure(i32 %8, ptr @cell)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_free(i32 %8)
  %10 = icmp eq i32 %9, 0
  %11 = add nsw i32 %9, 1
  %12 = select i1 %10, i32 7, i32 %11
  %13 = call i32 @cq_template_select_i32_ll(i32 %7, i32 2, i32 %12)
  call void @cqrt_copy_i32(i32 %13, i32 %out)
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %7, i32 2, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  call void @cqrt_free(i32 %out)
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_11_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_pop()
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = icmp ult i32 %7, %3
  br i1 %9, label %10, label %22

10:                                               ; preds = %4
  %11 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %11, i32 0)
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_xor_i1(i32 %12, i32 %14)
  call void @cqrt_and_i1(i32 %0, i32 %14, i32 %13)
  %15 = call i32 @__cq_q_stub_0_ctl_pure(i32 %13, ptr @cell)
  call void @cqrt_and_i1(i32 %0, i32 %14, i32 %13)
  call void @cqrt_free(i32 %13)
  call void @cqrt_xor_i1(i32 %12, i32 %14)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_free(i32 %14)
  %16 = icmp eq i32 %15, 0
  %17 = add nsw i32 %15, 1
  %18 = select i1 %16, i32 7, i32 %17
  %19 = call i32 @cq_template_select_i32_ll(i32 %12, i32 2, i32 %18)
  call void @cqrt_copy_i32(i32 %19, i32 %out)
  call void @cq_template_select_i32_ll_unc(i32 %19, i32 %12, i32 2, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %11, i32 0)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %6, i32 1)
  call void @cqrt_free(i32 %11)
  %20 = load i32, ptr @__cq_act_f, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void

22:                                               ; preds = %4
  %23 = load i32, ptr @__cq_act_f, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_stub_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  call void @cqrt_free(i32 %out)
  store i32 %3, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_stub_1_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_stub, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stub, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %11

8:                                                ; preds = %3
  %9 = load i32, ptr @__cq_act_stub, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_stub, align 4
  call void @cqrt_free(i32 %out)
  store i32 %4, ptr @__cq_k, align 4
  ret void

11:                                               ; preds = %3
  %12 = load i32, ptr @__cq_act_stub, align 4
  %13 = add i32 %12, -1
  store i32 %13, ptr @__cq_act_stub, align 4
  call void @cqrt_free(i32 %out)
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
