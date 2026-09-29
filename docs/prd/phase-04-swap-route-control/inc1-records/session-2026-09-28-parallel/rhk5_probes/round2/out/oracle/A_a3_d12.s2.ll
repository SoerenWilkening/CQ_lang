; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/round2/r1A/a3_d12.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %h = call i32 @cqrt_alloc_i32(i32 %6)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
  %7 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h) #6
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !10
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %7)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m2 = call i32 @cqrt_measure_i32(i32 %h)
  %8 = add nsw i32 %m2, %m
  ret i32 %8
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @a12(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483645, -2147483648) i32 @b12(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a11(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a12(i32 noundef %0)
  %3 = tail call i32 @b12(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b11(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a12(i32 noundef %0)
  %3 = tail call i32 @b12(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a10(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a11(i32 noundef %0)
  %3 = tail call i32 @b11(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b10(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a11(i32 noundef %0)
  %3 = tail call i32 @b11(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a9(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a10(i32 noundef %0)
  %3 = tail call i32 @b10(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b9(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a10(i32 noundef %0)
  %3 = tail call i32 @b10(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a8(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a9(i32 noundef %0)
  %3 = tail call i32 @b9(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b8(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a9(i32 noundef %0)
  %3 = tail call i32 @b9(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a7(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a8(i32 noundef %0)
  %3 = tail call i32 @b8(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b7(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a8(i32 noundef %0)
  %3 = tail call i32 @b8(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a6(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a7(i32 noundef %0)
  %3 = tail call i32 @b7(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b6(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a7(i32 noundef %0)
  %3 = tail call i32 @b7(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a5(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a6(i32 noundef %0)
  %3 = tail call i32 @b6(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b5(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a6(i32 noundef %0)
  %3 = tail call i32 @b6(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a4(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a5(i32 noundef %0)
  %3 = tail call i32 @b5(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b4(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a5(i32 noundef %0)
  %3 = tail call i32 @b5(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a3(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a4(i32 noundef %0)
  %3 = tail call i32 @b4(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b3(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a4(i32 noundef %0)
  %3 = tail call i32 @b4(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a2(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a3(i32 noundef %0)
  %3 = tail call i32 @b3(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b2(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a3(i32 noundef %0)
  %3 = tail call i32 @b3(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a1(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a2(i32 noundef %0)
  %3 = tail call i32 @b2(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b1(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a2(i32 noundef %0)
  %3 = tail call i32 @b2(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @a0(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a1(i32 noundef %0)
  %3 = tail call i32 @b1(i32 noundef %0)
  %4 = xor i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @b0(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @a1(i32 noundef %0)
  %3 = tail call i32 @b1(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = tail call i32 @a0(i32 noundef %1)
  ret i32 %3
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_h_10(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @__cq_q_a0_1(i32 noundef %1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %cqq.out)
  call void @__cq_q_a0_1_unc(i32 %3, i32 %1)
  call void @cqrt_free(i32 %3)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a0_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a1_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b1_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b1_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a1_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a1_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a2_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b2_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b2_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a2_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a2_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a3_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b3_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b3_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a3_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a3_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a4_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b4_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b4_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a4_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a4_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a5_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b5_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b5_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a5_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a5_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a6_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b6_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b6_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a6_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a6_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a7_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b7_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b7_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a7_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a7_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a8_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b8_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b8_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a8_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a8_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a9_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b9_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b9_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a9_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a9_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a10_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b10_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b10_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a10_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a10_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a11_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b11_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b11_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a11_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a11_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a12_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b12_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b12_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a12_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_a12_1(i32 noundef %0) local_unnamed_addr #5 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %0, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a12_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %0, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b12_1(i32 noundef %0) local_unnamed_addr #5 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %0, i32 3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b12_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %0, i32 3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare i32 @cq_template_xor_i32(i32, i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a11_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a12_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b12_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b12_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a12_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b11_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a12_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b12_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b12_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a12_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b11_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a12_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b12_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b12_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a12_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a10_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a11_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b11_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b11_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a11_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b10_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a11_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b11_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b11_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a11_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b10_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a11_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b11_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b11_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a11_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a9_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a10_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b10_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b10_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a10_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b9_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a10_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b10_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b10_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a10_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b9_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a10_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b10_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b10_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a10_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a8_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a9_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b9_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b9_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a9_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b8_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a9_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b9_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b9_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a9_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b8_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a9_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b9_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b9_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a9_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a7_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a8_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b8_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b8_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a8_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b7_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a8_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b8_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b8_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a8_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b7_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a8_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b8_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b8_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a8_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a6_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a7_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b7_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b7_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a7_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b6_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a7_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b7_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b7_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a7_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b6_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a7_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b7_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b7_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a7_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a5_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a6_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b6_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b6_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a6_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b5_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a6_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b6_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b6_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a6_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b5_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a6_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b6_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b6_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a6_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a4_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a5_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b5_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b5_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a5_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b4_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a5_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b5_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b5_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a5_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b4_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a5_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b5_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b5_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a5_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a3_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a4_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b4_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b4_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a4_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b3_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a4_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b4_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b4_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a4_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b3_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a4_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b4_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b4_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a4_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a2_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a3_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b3_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b3_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a3_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b2_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a3_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b3_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b3_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a3_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b2_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a3_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b3_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b3_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a3_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a1_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a2_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b2_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b2_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a2_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_b1_1(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a2_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b2_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b2_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a2_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_b1_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a2_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b2_1(i32 noundef %0)
  %h_op = call i32 @cq_template_add_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b2_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a2_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal void @__cq_q_a0_1_unc(i32 %out, i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @__cq_q_a1_1(i32 noundef %0)
  %3 = tail call i32 @__cq_q_b1_1(i32 noundef %0)
  %h_op = call i32 @cq_template_xor_i32(i32 %3, i32 %2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_xor_i32_unc(i32 %h_op, i32 %3, i32 %2)
  call void @__cq_q_b1_1_unc(i32 %3, i32 %0)
  call void @__cq_q_a1_1_unc(i32 %2, i32 %0)
  call void @cqrt_free(i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{}
