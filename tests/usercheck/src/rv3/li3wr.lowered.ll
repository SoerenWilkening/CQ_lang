; ModuleID = '<stdin>'
source_filename = "li3wr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@jb = global [37 x i32] zeroinitializer, align 16
@g = local_unnamed_addr global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [15 x i8] c"i32 (i32, i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double 1.000000e+00)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)
  %6 = call i32 @setjmp(ptr noundef nonnull @jb) #3
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %5)
  %9 = icmp sgt i32 %1, 0
  br i1 %9, label %12, label %12

10:                                               ; preds = %2
  %11 = call i32 @cq_template_add_i32_hl(i32 %4, i32 6)
  br label %16

12:                                               ; preds = %8, %8
  br i1 %9, label %13, label %14

13:                                               ; preds = %12
  call void @longjmp(ptr noundef nonnull @jb, i32 noundef 1) #4
  unreachable

14:                                               ; preds = %12
  %15 = call i32 @cq_template_shl_i32_hl(i32 %5, i32 1)
  br label %16

16:                                               ; preds = %10, %14
  %cq.run = phi i1 [ true, %10 ], [ false, %14 ]
  %cq.r6.chose = phi i1 [ false, %14 ], [ true, %10 ]
  %17 = phi i32 [ %15, %14 ], [ %11, %10 ]
  br i1 %cq.run, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %16
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  br label %.cq.after

.cq.after:                                        ; preds = %16, %.cq.arm
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %17)
  %18 = call i32 @cqrt_measure_i32(i32 %17), !cq.measure !6
  ret i32 %18
}

; Function Attrs: returns_twice
declare i32 @setjmp(ptr noundef) local_unnamed_addr #1

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #2

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
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
  %10 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)
  %11 = call i32 @setjmp(ptr noundef nonnull @jb) #3
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %16

13:                                               ; preds = %3
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 ptrtoint (ptr @g to i64), i32 %10)
  %14 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  call void @cqrt_abort_i1(i32 %14)
  %15 = call i32 @cq_template_shl_i32_hl(i32 %10, i32 1)
  br label %18

16:                                               ; preds = %3
  %17 = call i32 @cq_template_add_i32_hl(i32 %5, i32 6)
  br label %18

18:                                               ; preds = %16, %13
  %cq.run = phi i1 [ true, %16 ], [ false, %13 ]
  %cq.r6.chose = phi i1 [ false, %13 ], [ true, %16 ]
  %19 = phi i32 [ %15, %13 ], [ %17, %16 ]
  br i1 %cq.run, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %18
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %5, i32 1)
  call void @cqrt_free(i32 %10)
  br label %.cq.after

.cq.after:                                        ; preds = %18, %.cq.arm
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 ptrtoint (ptr @g to i64), i32 %19)
  %20 = call i32 @cqrt_measure_i32(i32 %19), !cq.measure !6
  %21 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %21)
  %22 = call i32 @cqrt_alloc_i32(i32 %20)
  ret i32 %22
}

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_abort_i1(i32)

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
  br i1 %7, label %8, label %31

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %10)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %10, double 1.000000e+00)
  %11 = alloca { i32, ptr }, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %11, i32 0, i32 0
  store i32 %10, ptr %12, align 4
  %13 = load ptr, ptr %cq.mints, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %11, i32 0, i32 1
  store ptr %13, ptr %14, align 8
  store ptr %11, ptr %cq.mints, align 8
  %15 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)
  %16 = call i32 @setjmp(ptr noundef nonnull @jb) #3
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %22

18:                                               ; preds = %8
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 ptrtoint (ptr @g to i64), i32 %15)
  %19 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 0)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %19, i32 %20)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %19, i32 %2, i32 0)
  call void @cqrt_free(i32 %19)
  call void @cqrt_abort_i1(i32 %20)
  %21 = call i32 @cq_template_shl_i32_hl(i32 %15, i32 1)
  br label %24

22:                                               ; preds = %8
  %23 = call i32 @cq_template_add_i32_hl(i32 %10, i32 6)
  br label %24

24:                                               ; preds = %22, %18
  %cq.run = phi i1 [ true, %22 ], [ false, %18 ]
  %cq.r6.chose = phi i1 [ false, %18 ], [ true, %22 ]
  %25 = phi i32 [ %21, %18 ], [ %23, %22 ]
  br i1 %cq.run, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %24
  call void @cq_template_add_i32_hl_unc(i32 %15, i32 %10, i32 1)
  call void @cqrt_free(i32 %15)
  br label %.cq.after

.cq.after:                                        ; preds = %24, %.cq.arm
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 ptrtoint (ptr @g to i64), i32 %25)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %25, i32 %26)
  %27 = call i32 @cqrt_measure_i32(i32 %26), !cq.measure !6
  %28 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %28)
  %29 = load i32, ptr @__cq_act_f, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_f, align 4
  ret i32 %26

31:                                               ; preds = %4
  %32 = call i32 @cqrt_alloc_i32(i32 0)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %33)
  call void @cqrt_push(i32 0)
  %34 = load i32, ptr @__cq_act_f, align 4
  %35 = add i32 %34, -1
  store i32 %35, ptr @__cq_act_f, align 4
  ret i32 %32
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
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

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { returns_twice "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind returns_twice }
attributes #4 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
