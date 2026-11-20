; ModuleID = '<stdin>'
source_filename = "sj.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, [37 x i32] }

@tab = global [2 x %struct.S] zeroinitializer, align 16
@__cq_act_f = internal global i32 0, align 4
@.cq.effect.setjmp = private unnamed_addr constant [7 x i8] c"setjmp\00", align 1
@.cq.sig = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %3, double %1)
  %4 = call i32 @cq_template_and_i32_hl(i32 %3, i32 1)
  %5 = call i32 @cq_template_zext_i32_to_i64(i32 %4)
  %6 = call i32 @cq_template_mul_i64_hl(i32 %5, i64 152)
  %7 = call i32 @cq_template_add_i64_hl(i32 %6, i64 ptrtoint (ptr @tab to i64))
  %8 = call fastcc i32 @__cq_q_g_1(i32 %7)
  call void @cq_template_add_i64_hl_unc(i32 %7, i32 %6, i64 ptrtoint (ptr @tab to i64))
  call void @cqrt_free(i32 %7)
  call void @cq_template_mul_i64_hl_unc(i32 %6, i32 %5, i64 152)
  call void @cqrt_free(i32 %6)
  call void @cq_template_zext_i32_to_i64_unc(i32 %5, i32 %4)
  call void @cqrt_free(i32 %5)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %3, i32 1)
  call void @cqrt_free(i32 %4)
  %9 = call i32 @cq_template_add_i32_hl(i32 %8, i32 1)
  %10 = call i32 @cq_template_sub_i32_hl(i32 %9, i32 1)
  call void @cqrt_copy_i32(i32 %10, i32 %8)
  call void @cq_template_sub_i32_hl_unc(i32 %10, i32 %9, i32 1)
  call void @cqrt_free(i32 %10)
  call void @cqrt_free(i32 %8)
  ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

define internal fastcc i32 @__cq_q_g_1(i32 %0) unnamed_addr {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @cq_template_add_i64_hl(i32 %0, i64 4)
  %5 = call i32 @cqrt_alloc_i1(i1 true)
  %6 = call i32 @cqrt_tape_write_i64(i32 %3, i32 %4)
  call void @cq_template_add_i64_hl_unc(i32 %4, i32 %0, i64 4)
  call void @cqrt_free(i32 %4)
  %7 = call i32 @cqrt_tape_effect_i32_controlled(i32 %5, i32 %3, ptr @.cq.effect.setjmp, i32 1)
  call void @cqrt_free(i32 %5)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %9 = call i32 @cqrt_qram_load_i32_controlled(i32 %8, i32 %2, i32 %0)
  %10 = call i32 @cq_template_select_i32_hl(i32 %8, i32 %9, i32 1)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %10, i32 %11)
  call void @cq_template_select_i32_hl_unc(i32 %10, i32 %8, i32 %9, i32 1)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %9, i32 %8, i32 %2, i32 %0)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)
  call void @cqrt_free(i32 %8)
  ret i32 %11
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %cq.mints = alloca ptr, align 8
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  store ptr null, ptr %cq.mints, align 8
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32_qangle(i32 %5, i32 %1)
  %6 = alloca { i32, ptr }, align 8
  %7 = getelementptr inbounds { i32, ptr }, ptr %6, i32 0, i32 0
  store i32 %5, ptr %7, align 4
  %8 = load ptr, ptr %cq.mints, align 8
  %9 = getelementptr inbounds { i32, ptr }, ptr %6, i32 0, i32 1
  store ptr %8, ptr %9, align 8
  store ptr %6, ptr %cq.mints, align 8
  %10 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %10)
  %12 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 152)
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 ptrtoint (ptr @tab to i64))
  %14 = call fastcc i32 @__cq_q_g_1(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 ptrtoint (ptr @tab to i64))
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i64_hl_unc(i32 %12, i32 %11, i64 152)
  call void @cqrt_free(i32 %12)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %5, i32 1)
  call void @cqrt_free(i32 %10)
  %15 = call i32 @cq_template_add_i32_hl(i32 %14, i32 1)
  %16 = call i32 @cq_template_sub_i32_hl(i32 %15, i32 1)
  call void @cqrt_copy_i32(i32 %16, i32 %14)
  call void @cq_template_sub_i32_hl_unc(i32 %16, i32 %15, i32 1)
  call void @cqrt_free(i32 %16)
  call void @cqrt_free(i32 %14)
  %17 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %17)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %15
}

declare void @cqrt_ry_i32_qangle(i32, i32)

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

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %25

9:                                                ; preds = %4
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %10)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %10, i32 %2)
  %11 = alloca { i32, ptr }, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %11, i32 0, i32 0
  store i32 %10, ptr %12, align 4
  %13 = load ptr, ptr %cq.mints, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %11, i32 0, i32 1
  store ptr %13, ptr %14, align 8
  store ptr %11, ptr %cq.mints, align 8
  %15 = call i32 @cq_template_and_i32_hl(i32 %10, i32 1)
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %15)
  %17 = call i32 @cq_template_mul_i64_hl(i32 %16, i64 152)
  %18 = call i32 @cq_template_add_i64_hl(i32 %17, i64 ptrtoint (ptr @tab to i64))
  %19 = call fastcc i32 @__cq_q_g_1_ctl(i32 %0, i32 %18)
  call void @cq_template_add_i64_hl_unc(i32 %18, i32 %17, i64 ptrtoint (ptr @tab to i64))
  call void @cqrt_free(i32 %18)
  call void @cq_template_mul_i64_hl_unc(i32 %17, i32 %16, i64 152)
  call void @cqrt_free(i32 %17)
  call void @cq_template_zext_i32_to_i64_unc(i32 %16, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %10, i32 1)
  call void @cqrt_free(i32 %15)
  %20 = call i32 @cq_template_add_i32_hl(i32 %19, i32 1)
  %21 = call i32 @cq_template_sub_i32_hl(i32 %20, i32 1)
  call void @cqrt_copy_i32(i32 %21, i32 %19)
  call void @cq_template_sub_i32_hl_unc(i32 %21, i32 %20, i32 1)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %19)
  %22 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %22)
  %23 = load i32, ptr @__cq_act_f, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_f, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %20

25:                                               ; preds = %4
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %27)
  call void @cqrt_push(i32 0)
  %28 = load i32, ptr @__cq_act_f, align 4
  %29 = add i32 %28, -1
  store i32 %29, ptr @__cq_act_f, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %26
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

define internal fastcc i32 @__cq_q_g_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @cq_template_add_i64_hl(i32 %1, i64 4)
  %6 = call i32 @cqrt_tape_write_i64_controlled(i32 %0, i32 %4, i32 %5)
  call void @cq_template_add_i64_hl_unc(i32 %5, i32 %1, i64 4)
  call void @cqrt_free(i32 %5)
  %7 = call i32 @cqrt_tape_effect_i32_controlled(i32 %0, i32 %4, ptr @.cq.effect.setjmp, i32 1)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %9)
  %10 = call i32 @cqrt_qram_load_i32_controlled(i32 %9, i32 %3, i32 %1)
  %11 = call i32 @cq_template_select_i32_hl(i32 %8, i32 %10, i32 1)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %11, i32 %12)
  call void @cq_template_select_i32_hl_unc(i32 %11, i32 %8, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %10, i32 %9, i32 %3, i32 %1)
  call void @cqrt_free(i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)
  call void @cqrt_free(i32 %8)
  ret i32 %12
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_write_i64(i32, i32)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_pop()
  br label %7

7:                                                ; preds = %10, %4
  %8 = phi i32 [ %6, %4 ], [ %12, %10 ]
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %13, label %10

10:                                               ; preds = %7
  %11 = call i32 @cqrt_pop()
  %12 = sub i32 %8, 1
  br label %7

13:                                               ; preds = %7
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = load i32, ptr @__cq_act_f, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_f, align 4
  %11 = call i32 @cqrt_pop()
  br label %12

12:                                               ; preds = %15, %5
  %13 = phi i32 [ %11, %5 ], [ %17, %15 ]
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %18, label %15

15:                                               ; preds = %12
  %16 = call i32 @cqrt_pop()
  %17 = sub i32 %13, 1
  br label %12

18:                                               ; preds = %12
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
