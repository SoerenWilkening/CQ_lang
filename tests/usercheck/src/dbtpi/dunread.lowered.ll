; ModuleID = 'src/dbtpi/dunread.O1.ll'
source_filename = "src/dbtpi/dunread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external local_unnamed_addr global ptr, align 8
@.cq.effect.fwide = private unnamed_addr constant [6 x i8] c"fwide\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %5, double %1)
  %6 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))
  %7 = call i32 @cqrt_alloc_i1(i1 true)
  %8 = call i32 @cqrt_tape_write_i64(i32 %3, i32 %6)
  call void @cqrt_qram_load_i64_hl_unc(i32 %6, i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cqrt_tape_write_i32(i32 %3, i32 %5)
  call void @cqrt_tape_effect_controlled(i32 %7, i32 %3, ptr @.cq.effect.fwide, i32 2)
  call void @cqrt_free(i32 %7)
  %10 = call i32 @cq_template_add_i32_hl(i32 %5, i32 5)
  %11 = call i32 @cqrt_measure_i32(i32 %10), !cq.measure !6
  ret i32 %11
}

declare i32 @fwide(ptr noundef, i32 noundef) local_unnamed_addr #1

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_write_i64(i32, i32)

declare i32 @cqrt_tape_write_i32(i32, i32)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_free(i32)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %6 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %6)
  call void @cqrt_ry_i32_qangle(i32 %6, i32 %1)
  %7 = alloca { i32, ptr }, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 0
  store i32 %6, ptr %8, align 4
  %9 = load ptr, ptr %cq.mints, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 1
  store ptr %9, ptr %10, align 8
  store ptr %7, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 ptrtoint (ptr @__stdoutp to i64))
  %12 = call i32 @cqrt_alloc_i1(i1 true)
  %13 = call i32 @cqrt_tape_write_i64(i32 %4, i32 %11)
  call void @cqrt_qram_load_i64_hl_unc(i32 %11, i32 %5, i64 ptrtoint (ptr @__stdoutp to i64))
  call void @cqrt_free(i32 %11)
  %14 = call i32 @cqrt_tape_write_i32(i32 %4, i32 %6)
  call void @cqrt_tape_effect_controlled(i32 %12, i32 %4, ptr @.cq.effect.fwide, i32 2)
  call void @cqrt_free(i32 %12)
  %15 = call i32 @cq_template_add_i32_hl(i32 %6, i32 5)
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %16)
  call void @cq_template_add_i32_hl_unc(i32 %15, i32 %6, i32 5)
  call void @cqrt_free(i32 %15)
  %17 = call i32 @cqrt_measure_i32(i32 %16), !cq.measure !6
  %18 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %18)
  %19 = call i32 @cqrt_alloc_i32(i32 %17)
  ret i32 %19
}

declare void @cqrt_copy_i32(i32, i32)

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

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %25

8:                                                ; preds = %4
  %9 = call i32 @cqrt_tape_alloc()
  %10 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %11)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %11, i32 %2)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %10, i64 ptrtoint (ptr @__stdoutp to i64))
  %17 = call i32 @cqrt_tape_write_i64_controlled(i32 %0, i32 %9, i32 %16)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %16, i32 %0, i32 %10, i64 ptrtoint (ptr @__stdoutp to i64))
  call void @cqrt_free(i32 %16)
  %18 = call i32 @cqrt_tape_write_i32_controlled(i32 %0, i32 %9, i32 %11)
  call void @cqrt_tape_effect_controlled(i32 %0, i32 %9, ptr @.cq.effect.fwide, i32 2)
  %19 = call i32 @cq_template_add_i32_hl(i32 %11, i32 5)
  %20 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %19, i32 %20)
  call void @cq_template_add_i32_hl_unc(i32 %19, i32 %11, i32 5)
  call void @cqrt_free(i32 %19)
  %21 = call i32 @cqrt_measure_i32(i32 %20), !cq.measure !6
  %22 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %22)
  %23 = load i32, ptr @__cq_act_f, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_f, align 4
  ret i32 %20

25:                                               ; preds = %4
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %27)
  call void @cqrt_push(i32 0)
  %28 = load i32, ptr @__cq_act_f, align 4
  %29 = add i32 %28, -1
  store i32 %29, ptr @__cq_act_f, align 4
  ret i32 %26
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_copy_i1(i32, i32)

define internal i32 @__cq_q_f_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32_qangle(i32 %5, i32 %1)
  %6 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))
  call void @cqrt_qram_load_i64_hl_unc(i32 %6, i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))
  call void @cqrt_free(i32 %6)
  %7 = call i32 @cq_template_add_i32_hl(i32 %5, i32 5)
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %7, i32 %8)
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %5, i32 5)
  call void @cqrt_free(i32 %7)
  %9 = call i32 @cqrt_measure_i32(i32 %8), !cq.measure !6
  %10 = call i32 @cqrt_alloc_i32(i32 %9)
  ret i32 %10
}

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
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
