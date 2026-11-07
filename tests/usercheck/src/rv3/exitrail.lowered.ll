; ModuleID = 'exitrail.c'
source_filename = "exitrail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.cq.effect.exit = private unnamed_addr constant [5 x i8] c"exit\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %3, double 5.000000e-01)
  %4 = and i32 %0, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %1
  %7 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %3, i32 %7)
  %8 = call i8 @cqrt_measure_i8(i32 %7), !cq.measure !6
  %9 = sext i8 %8 to i32
  br label %14

10:                                               ; preds = %1
  %11 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %12 = call i32 @cqrt_alloc_i1(i1 true)
  %13 = call i32 @cqrt_tape_write_i32(i32 %2, i32 %11)
  call void @cq_template_sext_i8_to_i32_unc(i32 %11, i32 %3)
  call void @cqrt_free(i32 %11)
  call void @cqrt_tape_effect_controlled(i32 %12, i32 %2, ptr @.cq.effect.exit, i32 1)
  call void @cqrt_abort_i1(i32 %12)
  br label %14

14:                                               ; preds = %10, %6
  %cq.retval = phi i32 [ 0, %10 ], [ %9, %6 ]
  ret i32 %cq.retval
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #1

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare void @cqrt_copy_i8(i32, i32)

declare i8 @cqrt_measure_i8(i32)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_write_i32(i32, i32)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare void @cqrt_abort_i1(i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

declare void @cqrt_free(i32)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %3 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %3, double 5.000000e-01)
  %4 = alloca { i32, ptr }, align 8
  %5 = getelementptr inbounds { i32, ptr }, ptr %4, i32 0, i32 0
  store i32 %3, ptr %5, align 4
  %6 = load ptr, ptr %cq.mints, align 8
  %7 = getelementptr inbounds { i32, ptr }, ptr %4, i32 0, i32 1
  store ptr %6, ptr %7, align 8
  store ptr %4, ptr %cq.mints, align 8
  %8 = call i32 @cq_template_and_i32_hl(i32 %0, i32 1)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %10 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %3, i32 %10)
  %11 = call i8 @cqrt_measure_i8(i32 %10), !cq.measure !6
  %12 = sext i8 %11 to i32
  %13 = sext i8 %11 to i32
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %14)
  call void @cqrt_xor_i1(i32 %9, i32 %14)
  call void @cqrt_abort_i1(i32 %14)
  %15 = call i32 @cq_template_select_i32_ll(i32 %9, i32 %12, i32 0)
  %16 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %16)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %17)
  call void @cq_template_select_i32_ll_unc(i32 %15, i32 %9, i32 %12, i32 0)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %0, i32 1)
  call void @cqrt_free(i32 %8)
  ret i32 %17
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

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

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %26

7:                                                ; preds = %3
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %8, double 5.000000e-01)
  %9 = alloca { i32, ptr }, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 0
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %cq.mints, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  store ptr %9, ptr %cq.mints, align 8
  %13 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)
  %15 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8_controlled(i32 %0, i32 %8, i32 %15)
  %16 = call i8 @cqrt_measure_i8(i32 %15), !cq.measure !6
  %17 = call i32 @cq_template_sext_i8_to_i32(i32 %15)
  %18 = call i32 @cq_template_sext_i8_to_i32(i32 %8)
  call void @cq_template_sext_i8_to_i32_unc(i32 %18, i32 %8)
  call void @cqrt_free(i32 %18)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_xor_i1(i32 %14, i32 %20)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  call void @cqrt_xor_i1(i32 %14, i32 %20)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cqrt_abort_i1(i32 %19)
  %21 = call i32 @cq_template_select_i32_hl(i32 %14, i32 %17, i32 0)
  %22 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %22)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %21, i32 %23)
  call void @cq_template_select_i32_hl_unc(i32 %21, i32 %14, i32 %17, i32 0)
  call void @cqrt_free(i32 %21)
  call void @cq_template_sext_i8_to_i32_unc(i32 %17, i32 %15)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %13, i32 0)
  call void @cqrt_free(i32 %14)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %1, i32 1)
  call void @cqrt_free(i32 %13)
  %24 = load i32, ptr @__cq_act_f, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_f, align 4
  ret i32 %23

26:                                               ; preds = %3
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %28)
  call void @cqrt_push(i32 0)
  %29 = load i32, ptr @__cq_act_f, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_f, align 4
  ret i32 %27
}

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_copy_i8_controlled(i32, i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

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

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
