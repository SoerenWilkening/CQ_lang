; ModuleID = 'unreach.O1.ll'
source_filename = "unreach.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %2, double 3.000000e-01)
  switch i32 %0, label %3 [
    i32 0, label %4
    i32 1, label %7
    i32 2, label %10
  ]

3:                                                ; preds = %1
  unreachable

4:                                                ; preds = %1
  %5 = call i32 @cq_template_sext_i8_to_i32(i32 %2)
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)
  br label %13

7:                                                ; preds = %1
  %8 = call i32 @cq_template_xor_i8_hl(i32 %2, i8 5)
  %9 = call i32 @cq_template_sext_i8_to_i32(i32 %8)
  call void @cq_template_xor_i8_hl_unc(i32 %8, i32 %2, i8 5)
  call void @cqrt_free(i32 %8)
  br label %13

10:                                               ; preds = %1
  %11 = call i32 @cq_template_sext_i8_to_i32(i32 %2)
  %12 = call i32 @cq_template_add_i32_hl(i32 %11, i32 9)
  br label %13

13:                                               ; preds = %10, %7, %4
  %14 = phi i32 [ %11, %10 ], [ poison, %7 ], [ poison, %4 ]
  %15 = phi i32 [ poison, %10 ], [ poison, %7 ], [ %5, %4 ]
  %cq.run7 = phi i1 [ false, %10 ], [ false, %7 ], [ true, %4 ]
  %cq.run = phi i1 [ true, %10 ], [ false, %7 ], [ false, %4 ]
  %cq.r6.chose1 = phi i1 [ false, %10 ], [ false, %7 ], [ true, %4 ]
  %cq.r6.chose = phi i1 [ true, %10 ], [ false, %7 ], [ false, %4 ]
  %16 = phi i32 [ %12, %10 ], [ %9, %7 ], [ %6, %4 ]
  br i1 %cq.run, label %.cq.arm9, label %.cq.after8

.cq.arm9:                                         ; preds = %13
  call void @cq_template_sext_i8_to_i32_unc(i32 %14, i32 %2)
  call void @cqrt_free(i32 %14)
  br label %.cq.after8

.cq.after8:                                       ; preds = %13, %.cq.arm9
  br i1 %cq.run7, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %.cq.after8
  call void @cq_template_sext_i8_to_i32_unc(i32 %15, i32 %2)
  call void @cqrt_free(i32 %15)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after8, %.cq.arm
  %17 = call i32 @cqrt_measure_i32(i32 %16), !cq.measure !6
  ret i32 %17
}

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_xor_i8_hl(i32, i8)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_xor_i8_hl_unc(i32, i32, i8)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %3, double 3.000000e-01)
  %4 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_xor_i8_hl(i32 %3, i8 5)
  %7 = call i32 @cq_template_sext_i8_to_i32(i32 %6)
  %8 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %9 = call i32 @cq_template_add_i32_hl(i32 %8, i32 9)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 0)
  %11 = call i32 @cq_template_select_i32(i32 %10, i32 %5, i32 %9)
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 1)
  %13 = call i32 @cq_template_select_i32(i32 %12, i32 %7, i32 %11)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %13, i32 %14)
  call void @cq_template_select_i32_unc(i32 %13, i32 %12, i32 %7, i32 %11)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %0, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cq_template_select_i32_unc(i32 %11, i32 %10, i32 %5, i32 %9)
  call void @cqrt_free(i32 %11)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %0, i32 0)
  call void @cqrt_free(i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %8, i32 9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_sext_i8_to_i32_unc(i32 %8, i32 %3)
  call void @cqrt_free(i32 %8)
  call void @cq_template_sext_i8_to_i32_unc(i32 %7, i32 %6)
  call void @cqrt_free(i32 %7)
  call void @cq_template_xor_i8_hl_unc(i32 %6, i32 %3, i8 5)
  call void @cqrt_free(i32 %6)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cq_template_sext_i8_to_i32_unc(i32 %4, i32 %3)
  call void @cqrt_free(i32 %4)
  %15 = call i32 @cqrt_measure_i32(i32 %14), !cq.measure !6
  call void @cqrt_push(i32 %3)
  call void @cqrt_push(i32 %14)
  %16 = call i32 @cqrt_alloc_i32(i32 %15)
  ret i32 %16
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_push(i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %28

7:                                                ; preds = %3
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %8, double 3.000000e-01)
  %9 = alloca { i32, ptr }, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 0
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %cq.mints, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  store ptr %9, ptr %cq.mints, align 8
  %13 = call i32 @cq_template_sext_i8_to_i32(i32 %8)
  %14 = call i32 @cq_template_add_i32_hl(i32 %13, i32 1)
  %15 = call i32 @cq_template_xor_i8_hl(i32 %8, i8 5)
  %16 = call i32 @cq_template_sext_i8_to_i32(i32 %15)
  %17 = call i32 @cq_template_sext_i8_to_i32(i32 %8)
  %18 = call i32 @cq_template_add_i32_hl(i32 %17, i32 9)
  %19 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 0)
  %20 = call i32 @cq_template_select_i32(i32 %19, i32 %14, i32 %18)
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 1)
  %22 = call i32 @cq_template_select_i32(i32 %21, i32 %16, i32 %20)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %22, i32 %23)
  call void @cq_template_select_i32_unc(i32 %22, i32 %21, i32 %16, i32 %20)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %1, i32 1)
  call void @cqrt_free(i32 %21)
  call void @cq_template_select_i32_unc(i32 %20, i32 %19, i32 %14, i32 %18)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %19, i32 %1, i32 0)
  call void @cqrt_free(i32 %19)
  call void @cq_template_add_i32_hl_unc(i32 %18, i32 %17, i32 9)
  call void @cqrt_free(i32 %18)
  call void @cq_template_sext_i8_to_i32_unc(i32 %17, i32 %8)
  call void @cqrt_free(i32 %17)
  call void @cq_template_sext_i8_to_i32_unc(i32 %16, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_xor_i8_hl_unc(i32 %15, i32 %8, i8 5)
  call void @cqrt_free(i32 %15)
  call void @cq_template_add_i32_hl_unc(i32 %14, i32 %13, i32 1)
  call void @cqrt_free(i32 %14)
  call void @cq_template_sext_i8_to_i32_unc(i32 %13, i32 %8)
  call void @cqrt_free(i32 %13)
  %24 = call i32 @cqrt_measure_i32(i32 %23), !cq.measure !6
  %25 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %25)
  %26 = load i32, ptr @__cq_act_f, align 4
  %27 = add i32 %26, -1
  store i32 %27, ptr @__cq_act_f, align 4
  ret i32 %23

28:                                               ; preds = %3
  %29 = call i32 @cqrt_alloc_i32(i32 0)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %30)
  call void @cqrt_push(i32 0)
  %31 = load i32, ptr @__cq_act_f, align 4
  %32 = add i32 %31, -1
  store i32 %32, ptr @__cq_act_f, align 4
  ret i32 %29
}

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

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

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = call i32 @cqrt_pop()
  %4 = call i32 @cqrt_pop()
  %5 = call i32 @cq_template_sext_i8_to_i32(i32 %4)
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_xor_i8_hl(i32 %4, i8 5)
  %8 = call i32 @cq_template_sext_i8_to_i32(i32 %7)
  %9 = call i32 @cq_template_sext_i8_to_i32(i32 %4)
  %10 = call i32 @cq_template_add_i32_hl(i32 %9, i32 9)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 0)
  %12 = call i32 @cq_template_select_i32(i32 %11, i32 %6, i32 %10)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 1)
  %14 = call i32 @cq_template_select_i32(i32 %13, i32 %8, i32 %12)
  call void @cq_template_select_i32_unc(i32 %14, i32 %13, i32 %8, i32 %12)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %0, i32 1)
  call void @cqrt_free(i32 %13)
  call void @cq_template_select_i32_unc(i32 %12, i32 %11, i32 %6, i32 %10)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %0, i32 0)
  call void @cqrt_free(i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %9, i32 9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_sext_i8_to_i32_unc(i32 %9, i32 %4)
  call void @cqrt_free(i32 %9)
  call void @cq_template_sext_i8_to_i32_unc(i32 %8, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cq_template_xor_i8_hl_unc(i32 %7, i32 %4, i8 5)
  call void @cqrt_free(i32 %7)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  call void @cq_template_sext_i8_to_i32_unc(i32 %5, i32 %4)
  call void @cqrt_free(i32 %5)
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

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
