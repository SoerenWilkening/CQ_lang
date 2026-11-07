; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv1/f.O1.ll'
source_filename = "onepast.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@A = global [4 x i8] c"\01\02\03\04", align 1
@B = local_unnamed_addr global [4 x i8] c"\05\06\07\08", align 1
@__cq_act_rdend = internal global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [15 x i8] c"i32 (ptr, i32)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [23 x i8] c"i32 (i32, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @rdend(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = and i32 %1, 3
  %5 = xor i32 %4, -1
  %6 = sext i32 %5 to i64
  %7 = getelementptr inbounds i8, ptr %0, i64 %6
  %8 = ptrtoint ptr %7 to i64
  %9 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %8)
  %10 = call i32 @cq_template_sext_i8_to_i32(i32 %9)
  call void @cqrt_qram_load_i8_hl_unc(i32 %9, i32 %3, i64 %8)
  call void @cqrt_free(i32 %9)
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 %1)
  %12 = call i32 @cq_template_sub_i32_hl(i32 %11, i32 %1)
  call void @cqrt_copy_i32(i32 %12, i32 %10)
  call void @cq_template_sub_i32_hl_unc(i32 %12, i32 %11, i32 %1)
  call void @cqrt_free(i32 %12)
  call void @cqrt_free(i32 %10)
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %5, double %2)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
  %8 = call i32 @cq_template_mul_i32_hl(i32 %5, i32 3)
  %9 = and i32 %0, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x i8], ptr @B, i64 0, i64 %10
  %12 = ptrtoint ptr %11 to i64
  %13 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %7, i32 %4, i64 %12)
  %14 = call i32 @cq_template_sext_i8_to_i32(i32 %13)
  %15 = call i32 @cq_template_add_i32(i32 %8, i32 %14)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_xor_i1(i32 %7, i32 %16)
  %17 = call i32 @__cq_q_rdend_01_ctl(i32 %16, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %5)
  %18 = call i32 @cq_template_select_i32(i32 %7, i32 %15, i32 %17)
  call void @__cq_q_rdend_01_ctl_unc(i32 %16, i32 %17, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %5)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %7, i32 %16)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_add_i32_unc(i32 %15, i32 %8, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sext_i8_to_i32_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %13, i32 %7, i32 %4, i64 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i32_hl_unc(i32 %8, i32 %5, i32 3)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  %19 = call i32 @cqrt_measure_i32(i32 %18), !cq.measure !6
  ret i32 %19
}

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_rdend_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cq_template_and_i32_hl(i32 %1, i32 3)
  %6 = call i32 @cq_template_xor_i32_hl(i32 %5, i32 -1)
  %7 = call i32 @cq_template_sext_i32_to_i64(i32 %6)
  %8 = call i32 @cq_template_add_i64(i32 %0, i32 %7)
  %9 = call i32 @cqrt_qram_load_i8(i32 %4, i32 %8)
  %10 = call i32 @cq_template_sext_i8_to_i32(i32 %9)
  %11 = call i32 @cq_template_add_i32(i32 %10, i32 %1)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %11, i32 %12)
  call void @cq_template_add_i32_unc(i32 %11, i32 %10, i32 %1)
  call void @cqrt_free(i32 %11)
  call void @cq_template_sext_i8_to_i32_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i8_unc(i32 %9, i32 %4, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i64_unc(i32 %8, i32 %0, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cq_template_sext_i32_to_i64_unc(i32 %7, i32 %6)
  call void @cqrt_free(i32 %7)
  call void @cq_template_xor_i32_hl_unc(i32 %6, i32 %5, i32 -1)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %1, i32 3)
  call void @cqrt_free(i32 %5)
  ret i32 %12
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cq_template_sext_i32_to_i64(i32)

declare i32 @cq_template_add_i64(i32, i32)

declare i32 @cqrt_qram_load_i8(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

declare void @cqrt_qram_load_i8_unc(i32, i32, i32)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cq_template_sext_i32_to_i64_unc(i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_rdend_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_rdend, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_rdend, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %20

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
  %10 = call i32 @cq_template_and_i32_hl(i32 %2, i32 3)
  %11 = call i32 @cq_template_xor_i32_hl(i32 %10, i32 -1)
  %12 = call i32 @cq_template_sext_i32_to_i64(i32 %11)
  %13 = call i32 @cq_template_add_i64(i32 %1, i32 %12)
  %14 = call i32 @cqrt_qram_load_i8_controlled(i32 %0, i32 %9, i32 %13)
  %15 = call i32 @cq_template_sext_i8_to_i32(i32 %14)
  %16 = call i32 @cq_template_add_i32(i32 %15, i32 %2)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %16, i32 %17)
  call void @cq_template_add_i32_unc(i32 %16, i32 %15, i32 %2)
  call void @cqrt_free(i32 %16)
  call void @cq_template_sext_i8_to_i32_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %14, i32 %0, i32 %9, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_unc(i32 %13, i32 %1, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sext_i32_to_i64_unc(i32 %12, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_xor_i32_hl_unc(i32 %11, i32 %10, i32 -1)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %2, i32 3)
  call void @cqrt_free(i32 %10)
  %18 = load i32, ptr @__cq_act_rdend, align 4
  %19 = add i32 %18, -1
  store i32 %19, ptr @__cq_act_rdend, align 4
  ret i32 %17

20:                                               ; preds = %4
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %22)
  %23 = load i32, ptr @__cq_act_rdend, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_rdend, align 4
  ret i32 %21
}

declare i32 @cqrt_qram_load_i8_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i8_controlled_unc(i32, i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

define i32 @__cq_q_rdend_01_ctl(i32 %0, ptr %1, i32 %2) local_unnamed_addr {
  %4 = load i32, ptr @__cq_act_rdend, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_rdend, align 4
  %6 = icmp ult i32 %4, 4
  br i1 %6, label %7, label %20

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cq_template_and_i32_hl(i32 %2, i32 3)
  %10 = call i32 @cq_template_xor_i32_hl(i32 %9, i32 -1)
  %11 = call i32 @cq_template_sext_i32_to_i64(i32 %10)
  %12 = ptrtoint ptr %1 to i64
  %13 = call i32 @cq_template_add_i64_hl(i32 %11, i64 %12)
  %14 = call i32 @cqrt_qram_load_i8_controlled(i32 %0, i32 %8, i32 %13)
  %15 = call i32 @cq_template_sext_i8_to_i32(i32 %14)
  %16 = call i32 @cq_template_add_i32(i32 %15, i32 %2)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %16, i32 %17)
  call void @cq_template_add_i32_unc(i32 %16, i32 %15, i32 %2)
  call void @cqrt_free(i32 %16)
  call void @cq_template_sext_i8_to_i32_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %14, i32 %0, i32 %8, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %11, i64 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sext_i32_to_i64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_xor_i32_hl_unc(i32 %10, i32 %9, i32 -1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %2, i32 3)
  call void @cqrt_free(i32 %9)
  %18 = load i32, ptr @__cq_act_rdend, align 4
  %19 = add i32 %18, -1
  store i32 %19, ptr @__cq_act_rdend, align 4
  ret i32 %17

20:                                               ; preds = %3
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %22)
  %23 = load i32, ptr @__cq_act_rdend, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_rdend, align 4
  ret i32 %21
}

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cqrt_measure_i32(i32)

define internal void @__cq_q_rdend_01_ctl_unc(i32 %0, i32 %out, ptr %1, i32 %2) local_unnamed_addr {
  %4 = load i32, ptr @__cq_act_rdend, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_rdend, align 4
  %6 = icmp ult i32 %4, 4
  br i1 %6, label %7, label %19

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cq_template_and_i32_hl(i32 %2, i32 3)
  %10 = call i32 @cq_template_xor_i32_hl(i32 %9, i32 -1)
  %11 = call i32 @cq_template_sext_i32_to_i64(i32 %10)
  %12 = ptrtoint ptr %1 to i64
  %13 = call i32 @cq_template_add_i64_hl(i32 %11, i64 %12)
  %14 = call i32 @cqrt_qram_load_i8_controlled(i32 %0, i32 %8, i32 %13)
  %15 = call i32 @cq_template_sext_i8_to_i32(i32 %14)
  %16 = call i32 @cq_template_add_i32(i32 %15, i32 %2)
  call void @cqrt_copy_i32(i32 %16, i32 %out)
  call void @cq_template_add_i32_unc(i32 %16, i32 %15, i32 %2)
  call void @cqrt_free(i32 %16)
  call void @cq_template_sext_i8_to_i32_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %14, i32 %0, i32 %8, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %11, i64 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sext_i32_to_i64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_xor_i32_hl_unc(i32 %10, i32 %9, i32 -1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %2, i32 3)
  call void @cqrt_free(i32 %9)
  %17 = load i32, ptr @__cq_act_rdend, align 4
  %18 = add i32 %17, -1
  store i32 %18, ptr @__cq_act_rdend, align 4
  ret void

19:                                               ; preds = %3
  %20 = load i32, ptr @__cq_act_rdend, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_rdend, align 4
  ret void
}

declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %6)
  call void @cqrt_ry_i32_qangle(i32 %6, i32 %2)
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %9 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 3)
  %10 = call i32 @cq_template_and_i32_hl(i32 %0, i32 3)
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %10)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @B to i64))
  %13 = call i32 @cqrt_qram_load_i8_controlled(i32 %8, i32 %5, i32 %12)
  %14 = call i32 @cq_template_sext_i8_to_i32(i32 %13)
  %15 = call i32 @cq_template_add_i32(i32 %9, i32 %14)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_xor_i1(i32 %8, i32 %16)
  %17 = call i32 @__cq_q_rdend_01_ctl(i32 %16, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %6)
  %18 = call i32 @cq_template_select_i32(i32 %8, i32 %15, i32 %17)
  %19 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %18, i32 %19)
  call void @cq_template_select_i32_unc(i32 %18, i32 %8, i32 %15, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @__cq_q_rdend_01_ctl_unc(i32 %16, i32 %17, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %6)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %8, i32 %16)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_add_i32_unc(i32 %15, i32 %9, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sext_i8_to_i32_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %13, i32 %8, i32 %5, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @B to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %0, i32 3)
  call void @cqrt_free(i32 %10)
  call void @cq_template_mul_i32_hl_unc(i32 %9, i32 %6, i32 3)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)
  call void @cqrt_free(i32 %8)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 1)
  call void @cqrt_free(i32 %7)
  %20 = call i32 @cqrt_measure_i32(i32 %19), !cq.measure !6
  call void @cqrt_push(i32 %6)
  call void @cqrt_push(i32 %19)
  %21 = call i32 @cqrt_alloc_i32(i32 %20)
  ret i32 %21
}

declare void @cqrt_ry_i32_qangle(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_push(i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = icmp ult i32 %6, %4
  br i1 %8, label %9, label %35

9:                                                ; preds = %5
  %10 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %11)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %11, i32 %3)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @cq_template_and_i32_hl(i32 %11, i32 1)
  %17 = call i32 @cq_template_icmp_eq_i32_hl(i32 %16, i32 0)
  %18 = call i32 @cq_template_mul_i32_hl(i32 %11, i32 3)
  %19 = call i32 @cq_template_and_i32_hl(i32 %1, i32 3)
  %20 = call i32 @cq_template_zext_i32_to_i64(i32 %19)
  %21 = call i32 @cq_template_add_i64_hl(i32 %20, i64 ptrtoint (ptr @B to i64))
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %22)
  %23 = call i32 @cqrt_qram_load_i8_controlled(i32 %22, i32 %10, i32 %21)
  %24 = call i32 @cq_template_sext_i8_to_i32(i32 %23)
  %25 = call i32 @cq_template_add_i32(i32 %18, i32 %24)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_xor_i1(i32 %17, i32 %27)
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %26)
  %28 = call i32 @__cq_q_rdend_01_ctl(i32 %26, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %11)
  %29 = call i32 @cq_template_select_i32(i32 %17, i32 %25, i32 %28)
  %30 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %29, i32 %30)
  call void @cq_template_select_i32_unc(i32 %29, i32 %17, i32 %25, i32 %28)
  call void @cqrt_free(i32 %29)
  call void @__cq_q_rdend_01_ctl_unc(i32 %26, i32 %28, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %11)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cqrt_xor_i1(i32 %17, i32 %27)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i32_unc(i32 %25, i32 %18, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cq_template_sext_i8_to_i32_unc(i32 %24, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %23, i32 %22, i32 %10, i32 %21)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %20, i64 ptrtoint (ptr @B to i64))
  call void @cqrt_free(i32 %21)
  call void @cq_template_zext_i32_to_i64_unc(i32 %20, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_and_i32_hl_unc(i32 %19, i32 %1, i32 3)
  call void @cqrt_free(i32 %19)
  call void @cq_template_mul_i32_hl_unc(i32 %18, i32 %11, i32 3)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %17, i32 %16, i32 0)
  call void @cqrt_free(i32 %17)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %11, i32 1)
  call void @cqrt_free(i32 %16)
  %31 = call i32 @cqrt_measure_i32(i32 %30), !cq.measure !6
  %32 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %32)
  %33 = load i32, ptr @__cq_act_f, align 4
  %34 = add i32 %33, -1
  store i32 %34, ptr @__cq_act_f, align 4
  ret i32 %30

35:                                               ; preds = %5
  %36 = call i32 @cqrt_alloc_i32(i32 0)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %37)
  call void @cqrt_push(i32 0)
  %38 = load i32, ptr @__cq_act_f, align 4
  %39 = add i32 %38, -1
  store i32 %39, ptr @__cq_act_f, align 4
  ret i32 %36
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

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

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @rdend, ptr @.cq.sig, ptr @__cq_q_rdend_11_t, ptr @__cq_q_rdend_11_t_ctl, ptr @__cq_q_rdend_11_t_unc, ptr @__cq_q_rdend_11_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_rdend_11_t_unc(i32 %out, i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cq_template_and_i32_hl(i32 %1, i32 3)
  %6 = call i32 @cq_template_xor_i32_hl(i32 %5, i32 -1)
  %7 = call i32 @cq_template_sext_i32_to_i64(i32 %6)
  %8 = call i32 @cq_template_add_i64(i32 %0, i32 %7)
  %9 = call i32 @cqrt_qram_load_i8(i32 %4, i32 %8)
  %10 = call i32 @cq_template_sext_i8_to_i32(i32 %9)
  %11 = call i32 @cq_template_add_i32(i32 %10, i32 %1)
  call void @cqrt_copy_i32(i32 %11, i32 %out)
  call void @cq_template_add_i32_unc(i32 %11, i32 %10, i32 %1)
  call void @cqrt_free(i32 %11)
  call void @cq_template_sext_i8_to_i32_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i8_unc(i32 %9, i32 %4, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i64_unc(i32 %8, i32 %0, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cq_template_sext_i32_to_i64_unc(i32 %7, i32 %6)
  call void @cqrt_free(i32 %7)
  call void @cq_template_xor_i32_hl_unc(i32 %6, i32 %5, i32 -1)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %1, i32 3)
  call void @cqrt_free(i32 %5)
  call void @cqrt_free(i32 %out)
  ret void
}

define internal void @__cq_q_rdend_11_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_rdend, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_rdend, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %19

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
  %10 = call i32 @cq_template_and_i32_hl(i32 %2, i32 3)
  %11 = call i32 @cq_template_xor_i32_hl(i32 %10, i32 -1)
  %12 = call i32 @cq_template_sext_i32_to_i64(i32 %11)
  %13 = call i32 @cq_template_add_i64(i32 %1, i32 %12)
  %14 = call i32 @cqrt_qram_load_i8_controlled(i32 %0, i32 %9, i32 %13)
  %15 = call i32 @cq_template_sext_i8_to_i32(i32 %14)
  %16 = call i32 @cq_template_add_i32(i32 %15, i32 %2)
  call void @cqrt_copy_i32(i32 %16, i32 %out)
  call void @cq_template_add_i32_unc(i32 %16, i32 %15, i32 %2)
  call void @cqrt_free(i32 %16)
  call void @cq_template_sext_i8_to_i32_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %14, i32 %0, i32 %9, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_unc(i32 %13, i32 %1, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sext_i32_to_i64_unc(i32 %12, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_xor_i32_hl_unc(i32 %11, i32 %10, i32 -1)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %2, i32 3)
  call void @cqrt_free(i32 %10)
  %17 = load i32, ptr @__cq_act_rdend, align 4
  %18 = add i32 %17, -1
  store i32 %18, ptr @__cq_act_rdend, align 4
  call void @cqrt_free(i32 %out)
  ret void

19:                                               ; preds = %4
  %20 = load i32, ptr @__cq_act_rdend, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_rdend, align 4
  call void @cqrt_free(i32 %out)
  ret void
}

define internal void @__cq_q_f_111_t_unc(i32 %out, i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cqrt_pop()
  %6 = call i32 @cqrt_pop()
  %7 = call i32 @__cq_mem()
  %8 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %10 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 3)
  %11 = call i32 @cq_template_and_i32_hl(i32 %0, i32 3)
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 ptrtoint (ptr @B to i64))
  %14 = call i32 @cqrt_qram_load_i8_controlled(i32 %9, i32 %7, i32 %13)
  %15 = call i32 @cq_template_sext_i8_to_i32(i32 %14)
  %16 = call i32 @cq_template_add_i32(i32 %10, i32 %15)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_xor_i1(i32 %9, i32 %17)
  %18 = call i32 @__cq_q_rdend_01_ctl(i32 %17, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %6)
  %19 = call i32 @cq_template_select_i32(i32 %9, i32 %16, i32 %18)
  call void @cq_template_select_i32_unc(i32 %19, i32 %9, i32 %16, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @__cq_q_rdend_01_ctl_unc(i32 %17, i32 %18, ptr getelementptr inbounds (i8, ptr @A, i64 4), i32 %6)
  call void @cqrt_free(i32 %18)
  call void @cqrt_xor_i1(i32 %9, i32 %17)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i32_unc(i32 %16, i32 %10, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_sext_i8_to_i32_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %14, i32 %9, i32 %7, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 ptrtoint (ptr @B to i64))
  call void @cqrt_free(i32 %13)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %0, i32 3)
  call void @cqrt_free(i32 %11)
  call void @cq_template_mul_i32_hl_unc(i32 %10, i32 %6, i32 3)
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %6, i32 1)
  call void @cqrt_free(i32 %8)
  ret void
}

define internal void @__cq_q_f_111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = load i32, ptr @__cq_act_f, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_f, align 4
  %11 = call i32 @cqrt_pop()
  br label %12

12:                                               ; preds = %15, %6
  %13 = phi i32 [ %11, %6 ], [ %17, %15 ]
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %18, label %15

15:                                               ; preds = %12
  %16 = call i32 @cqrt_pop()
  %17 = sub i32 %13, 1
  br label %12

18:                                               ; preds = %12
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
