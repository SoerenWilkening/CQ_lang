; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-adaaa90a106d20464/tests/calls/probes/meas_only_ctl_qbranch.O1.ll'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang2/.claude/worktrees/agent-adaaa90a106d20464/tests/calls/probes/meas_only_ctl_qbranch.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_mm = internal global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [15 x i8] c"i32 (i32, i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @mm(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = add nsw i32 %0, 1
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %0, %1 ]
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %3, double 1.000000e+00)
  %4 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %4, double 1.000000e+00)
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)
  %7 = call i32 @__cq_q_mm_1(i32 %3)
  %8 = call i32 @cq_template_select_i32_lh(i32 %6, i32 0, i32 %7)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  %9 = call i32 @cqrt_measure_i32(i32 %8), !cq.measure !6
  ret i32 %9
}

define internal i32 @__cq_q_mm_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_and_i32_hl(i32 %0, i32 1)
  %4 = call i32 @cq_template_icmp_eq_i32_hl(i32 %3, i32 0)
  %5 = call i32 @cqrt_measure_i32(i32 %0), !cq.measure !6
  %6 = add nsw i32 %5, 1
  %7 = call i32 @cq_template_select_i32_ll(i32 %4, i32 %6, i32 %5)
  call void @cq_template_select_i32_ll_unc(i32 %7, i32 %4, i32 %6, i32 %5)
  call void @cqrt_free(i32 %7)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %4, i32 %3, i32 0)
  call void @cqrt_free(i32 %4)
  call void @cq_template_and_i32_hl_unc(i32 %3, i32 %0, i32 1)
  call void @cqrt_free(i32 %3)
  %8 = and i32 %5, 1
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, i32 %6, i32 %5
  %11 = call i32 @cqrt_alloc_i32(i32 %10)
  ret i32 %11
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_mm_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_mm, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_mm, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %17

7:                                                ; preds = %3
  %8 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %1, i32 %10)
  %11 = call i32 @cqrt_measure_i32(i32 %10), !cq.measure !6
  %12 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)
  %13 = call i32 @cq_template_select_i32(i32 %9, i32 %12, i32 %1)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %13, i32 %14)
  call void @cq_template_select_i32_unc(i32 %13, i32 %9, i32 %12, i32 %1)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %10, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %1, i32 1)
  call void @cqrt_free(i32 %8)
  %15 = load i32, ptr @__cq_act_mm, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_mm, align 4
  ret i32 %14

17:                                               ; preds = %3
  %18 = call i32 @cqrt_alloc_i32(i32 0)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %19)
  %20 = load i32, ptr @__cq_act_mm, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_mm, align 4
  ret i32 %18
}

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_ry_i32(i32, double)

define i32 @__cq_q_mm_1(i32 %0) local_unnamed_addr {
  %2 = call i32 @cq_template_and_i32_hl(i32 %0, i32 1)
  %3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %2, i32 0)
  %4 = call i32 @cqrt_measure_i32(i32 %0), !cq.measure !6
  %5 = add nsw i32 %4, 1
  %6 = call i32 @cq_template_select_i32_ll(i32 %3, i32 %5, i32 %4)
  call void @cq_template_select_i32_ll_unc(i32 %6, i32 %3, i32 %5, i32 %4)
  call void @cqrt_free(i32 %6)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %3, i32 %2, i32 0)
  call void @cqrt_free(i32 %3)
  call void @cq_template_and_i32_hl_unc(i32 %2, i32 %0, i32 1)
  call void @cqrt_free(i32 %2)
  %7 = and i32 %4, 1
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %8, i32 %5, i32 %4
  %10 = call i32 @cqrt_alloc_i32(i32 %9)
  ret i32 %10
}

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %4)
  call void @cqrt_ry_i32(i32 %4, double 1.000000e+00)
  %5 = alloca { i32, ptr }, align 8
  %6 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 0
  store i32 %4, ptr %6, align 4
  %7 = load ptr, ptr %cq.mints, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 1
  store ptr %7, ptr %8, align 8
  store ptr %5, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %9)
  call void @cqrt_ry_i32(i32 %9, double 1.000000e+00)
  %10 = alloca { i32, ptr }, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 0
  store i32 %9, ptr %11, align 4
  %12 = load ptr, ptr %cq.mints, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 1
  store ptr %12, ptr %13, align 8
  store ptr %10, ptr %cq.mints, align 8
  %14 = call i32 @cq_template_and_i32_hl(i32 %9, i32 1)
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  %16 = call i32 @__cq_q_mm_1(i32 %4)
  %17 = call i32 @cq_template_select_i32_lh(i32 %15, i32 0, i32 %16)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %15, i32 %14, i32 0)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %9, i32 1)
  call void @cqrt_free(i32 %14)
  %18 = call i32 @cqrt_measure_i32(i32 %17), !cq.measure !6
  %19 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %19)
  %20 = call i32 @cqrt_alloc_i32(i32 %18)
  ret i32 %20
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

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %28

8:                                                ; preds = %4
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %9)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %9, double 1.000000e+00)
  %10 = alloca { i32, ptr }, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 0
  store i32 %9, ptr %11, align 4
  %12 = load ptr, ptr %cq.mints, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 1
  store ptr %12, ptr %13, align 8
  store ptr %10, ptr %cq.mints, align 8
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %14)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %14, double 1.000000e+00)
  %15 = alloca { i32, ptr }, align 8
  %16 = getelementptr inbounds { i32, ptr }, ptr %15, i32 0, i32 0
  store i32 %14, ptr %16, align 4
  %17 = load ptr, ptr %cq.mints, align 8
  %18 = getelementptr inbounds { i32, ptr }, ptr %15, i32 0, i32 1
  store ptr %17, ptr %18, align 8
  store ptr %15, ptr %cq.mints, align 8
  %19 = call i32 @cq_template_and_i32_hl(i32 %14, i32 1)
  %20 = call i32 @cq_template_icmp_eq_i32_hl(i32 %19, i32 0)
  %21 = call i32 @__cq_q_mm_1(i32 %9)
  %22 = call i32 @cq_template_select_i32_lh(i32 %20, i32 0, i32 %21)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %22, i32 %23)
  call void @cq_template_select_i32_lh_unc(i32 %22, i32 %20, i32 0, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %20, i32 %19, i32 0)
  call void @cqrt_free(i32 %20)
  call void @cq_template_and_i32_hl_unc(i32 %19, i32 %14, i32 1)
  call void @cqrt_free(i32 %19)
  %24 = call i32 @cqrt_measure_i32(i32 %23), !cq.measure !6
  %25 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %25)
  %26 = load i32, ptr @__cq_act_f, align 4
  %27 = add i32 %26, -1
  store i32 %27, ptr @__cq_act_f, align 4
  ret i32 %23

28:                                               ; preds = %4
  %29 = call i32 @cqrt_alloc_i32(i32 0)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %30)
  call void @cqrt_push(i32 0)
  %31 = load i32, ptr @__cq_act_f, align 4
  %32 = add i32 %31, -1
  store i32 %32, ptr @__cq_act_f, align 4
  ret i32 %29
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @mm, ptr @.cq.sig, ptr @__cq_q_mm_1_t, ptr @__cq_q_mm_1_t_ctl, ptr @__cq_q_mm_1_t_unc, ptr @__cq_q_mm_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_mm_1_t_unc(i32 %0, i32 %1, i32 %2) {
  ret void
}

define internal void @__cq_q_mm_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_mm, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_mm, align 4
  %7 = load i32, ptr @__cq_act_mm, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_mm, align 4
  ret void
}

define internal void @__cq_q_f_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
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

define internal void @__cq_q_f_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_f, align 4
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

declare i32 @cqrt_pop()

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
