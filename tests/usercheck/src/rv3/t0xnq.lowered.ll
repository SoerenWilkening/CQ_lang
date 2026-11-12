; ModuleID = 'src/rv3/t0xnq.O1.ll'
source_filename = "src/rv3/t0xnq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@hit = internal unnamed_addr global i32 0, align 4
@__cq_sig = external global [65 x i64]
@__cq_act_f = internal global i32 0, align 4
@__cq_act_h = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [11 x i8] c"void (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double %1)
  %5 = tail call ptr @signal(i32 noundef 11, ptr noundef nonnull @h) #2
  %6 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64))
  %7 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @h to i64))
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64), i32 %7)
  %8 = call i32 @cq_template_icmp_ne_i64_hl(i32 %6, i64 0)
  %9 = call i32 @cq_template_zext_i1_to_i32(i32 %8)
  call void @cq_template_icmp_ne_i64_hl_unc(i32 %8, i32 %6, i64 0)
  call void @cqrt_free(i32 %8)
  call void @cqrt_qram_load_i64_hl_unc(i32 %6, i32 %3, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64))
  %10 = call i32 @cqrt_measure_i32(i32 %4), !cq.measure !6
  %11 = call i32 @cq_template_add_i32_hl(i32 %9, i32 %10)
  %12 = call i32 @cq_template_sub_i32_hl(i32 %11, i32 %10)
  call void @cqrt_copy_i32(i32 %12, i32 %9)
  call void @cq_template_sub_i32_hl_unc(i32 %12, i32 %11, i32 %10)
  call void @cqrt_free(i32 %12)
  call void @cqrt_free(i32 %9)
  ret i32 %11
}

declare ptr @signal(i32 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define internal void @h(i32 noundef %0) #0 {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @hit to i64), i32 %3)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %0)
  %5 = call i32 @cq_template_sub_i32_hl(i32 %4, i32 %0)
  call void @cqrt_copy_i32(i32 %5, i32 %3)
  call void @cq_template_sub_i32_hl_unc(i32 %5, i32 %4, i32 %0)
  call void @cqrt_free(i32 %5)
  call void @cqrt_free(i32 %3)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @hit to i64), i32 %4)
  call void @cqrt_free(i32 %4)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cq_template_icmp_ne_i64_hl(i32, i64)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_ne_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
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
  %10 = tail call ptr @signal(i32 noundef 11, ptr noundef nonnull @h) #2
  %11 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64))
  %12 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @h to i64))
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64), i32 %12)
  %13 = call i32 @cq_template_icmp_ne_i64_hl(i32 %11, i64 0)
  %14 = call i32 @cq_template_zext_i1_to_i32(i32 %13)
  call void @cq_template_icmp_ne_i64_hl_unc(i32 %13, i32 %11, i64 0)
  call void @cqrt_free(i32 %13)
  call void @cqrt_qram_load_i64_hl_unc(i32 %11, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64))
  %15 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %5, i32 %15)
  %16 = call i32 @cqrt_measure_i32(i32 %15), !cq.measure !6
  %17 = call i32 @cq_template_add_i32_hl(i32 %14, i32 %16)
  %18 = call i32 @cq_template_sub_i32_hl(i32 %17, i32 %16)
  call void @cqrt_copy_i32(i32 %18, i32 %14)
  call void @cq_template_sub_i32_hl_unc(i32 %18, i32 %17, i32 %16)
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %14)
  %19 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %19)
  ret i32 %17
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
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %26

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
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
  %15 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %9, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64))
  %16 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @h to i64))
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64), i32 %16)
  %17 = call i32 @cq_template_icmp_ne_i64_hl(i32 %15, i64 0)
  %18 = call i32 @cq_template_zext_i1_to_i32(i32 %17)
  call void @cq_template_icmp_ne_i64_hl_unc(i32 %17, i32 %15, i64 0)
  call void @cqrt_free(i32 %17)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %15, i32 %0, i32 %9, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 11) to i64))
  %19 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %10, i32 %19)
  %20 = call i32 @cqrt_measure_i32(i32 %19), !cq.measure !6
  %21 = call i32 @cq_template_add_i32(i32 %19, i32 %18)
  %22 = call i32 @cq_template_sub_i32(i32 %21, i32 %19)
  call void @cqrt_copy_i32(i32 %22, i32 %18)
  call void @cq_template_sub_i32_unc(i32 %22, i32 %21, i32 %19)
  call void @cqrt_free(i32 %22)
  call void @cqrt_free(i32 %18)
  %23 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %23)
  %24 = load i32, ptr @__cq_act_f, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_f, align 4
  ret i32 %21

26:                                               ; preds = %4
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %28)
  call void @cqrt_push(i32 0)
  %29 = load i32, ptr @__cq_act_f, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_f, align 4
  ret i32 %27
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)

define internal void @__cq_q_h_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @hit to i64), i32 %4)
  %5 = call i32 @cq_template_add_i32(i32 %4, i32 %0)
  %6 = call i32 @cq_template_sub_i32(i32 %5, i32 %0)
  call void @cqrt_copy_i32(i32 %6, i32 %4)
  call void @cq_template_sub_i32_unc(i32 %6, i32 %5, i32 %0)
  call void @cqrt_free(i32 %6)
  call void @cqrt_free(i32 %4)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @hit to i64), i32 %5)
  call void @cqrt_free(i32 %5)
  ret void
}

define internal void @__cq_q_h_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_h, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_h, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %16

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @hit to i64), i32 %9)
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %1)
  %11 = call i32 @cq_template_select_i32(i32 %0, i32 %10, i32 %9)
  call void @cq_template_add_i32_unc(i32 %10, i32 %9, i32 %1)
  call void @cqrt_free(i32 %10)
  %12 = call i32 @cq_template_sub_i32(i32 %11, i32 %1)
  %13 = call i32 @cq_template_select_i32(i32 %0, i32 %12, i32 %11)
  call void @cqrt_copy_i32(i32 %13, i32 %9)
  call void @cq_template_select_i32_unc(i32 %13, i32 %0, i32 %12, i32 %11)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sub_i32_unc(i32 %12, i32 %11, i32 %1)
  call void @cqrt_free(i32 %12)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @hit to i64), i32 %11)
  call void @cqrt_free(i32 %11)
  %14 = load i32, ptr @__cq_act_h, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_h, align 4
  ret void

16:                                               ; preds = %3
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %17)
  %18 = load i32, ptr @__cq_act_h, align 4
  %19 = add i32 %18, -1
  store i32 %19, ptr @__cq_act_h, align 4
  ret void
}

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  call void @__cq_clone_register(ptr @h, ptr @.cq.sig.1, ptr @__cq_q_h_1_t, ptr @__cq_q_h_1_t_ctl, ptr @__cq_q_h_1_t_unc, ptr @__cq_q_h_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

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

define internal void @__cq_q_h_1_t_unc(i32 %0, i32 %1) {
  ret void
}

define internal void @__cq_q_h_1_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_h, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_h, align 4
  %6 = load i32, ptr @__cq_act_h, align 4
  %7 = add i32 %6, -1
  store i32 %7, ptr @__cq_act_h, align 4
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
