; ModuleID = 'arena_word.O1.ll'
source_filename = "tests/usercheck/src/rv3/arena_word.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global [4 x i32] zeroinitializer, align 16
@a = global i32 0, align 4
@cell = local_unnamed_addr global ptr null, align 8
@b = local_unnamed_addr global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %3, double 5.000000e-01)
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64), i32 %3)
  %4 = call i32 @cqrt_alloc_i32(i32 10)
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @g, i64 8) to i64), i32 %4)
  %5 = call i32 @cqrt_alloc_i32(i32 10140)
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @g, i64 12) to i64), i32 %5)
  %6 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @a to i64))
  call void @cqrt_qram_store_i64_hl(i32 %2, i64 ptrtoint (ptr @cell to i64), i32 %6)
  %7 = call i32 @cqrt_measure_i32(i32 %3), !cq.measure !6
  ret i32 %7
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cqrt_measure_i32(i32)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %4)
  call void @cqrt_ry_i32(i32 %4, double 5.000000e-01)
  %5 = alloca { i32, ptr }, align 8
  %6 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 0
  store i32 %4, ptr %6, align 4
  %7 = load ptr, ptr %cq.mints, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 1
  store ptr %7, ptr %8, align 8
  store ptr %5, ptr %cq.mints, align 8
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %4)
  %9 = call i32 @cqrt_alloc_i32(i32 10)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @g, i64 8) to i64), i32 %9)
  %10 = call i32 @cqrt_alloc_i32(i32 10140)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @g, i64 12) to i64), i32 %10)
  %11 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @a to i64))
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 ptrtoint (ptr @cell to i64), i32 %11)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %4, i32 %12)
  %13 = call i32 @cqrt_measure_i32(i32 %12), !cq.measure !6
  %14 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %14)
  %15 = call i32 @cqrt_alloc_i32(i32 %13)
  ret i32 %15
}

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

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %22

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %9)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %9, double 5.000000e-01)
  %10 = alloca { i32, ptr }, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 0
  store i32 %9, ptr %11, align 4
  %12 = load ptr, ptr %cq.mints, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 1
  store ptr %12, ptr %13, align 8
  store ptr %10, ptr %cq.mints, align 8
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @g to i64), i32 %9)
  %14 = call i32 @cqrt_alloc_i32(i32 10)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @g, i64 8) to i64), i32 %14)
  %15 = call i32 @cqrt_alloc_i32(i32 10140)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @g, i64 12) to i64), i32 %15)
  %16 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @a to i64))
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @cell to i64), i32 %16)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %9, i32 %17)
  %18 = call i32 @cqrt_measure_i32(i32 %17), !cq.measure !6
  %19 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %19)
  %20 = load i32, ptr @__cq_act_f, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_f, align 4
  ret i32 %17

22:                                               ; preds = %3
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %24)
  call void @cqrt_push(i32 0)
  %25 = load i32, ptr @__cq_act_f, align 4
  %26 = add i32 %25, -1
  store i32 %26, ptr @__cq_act_f, align 4
  ret i32 %23
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

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

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
