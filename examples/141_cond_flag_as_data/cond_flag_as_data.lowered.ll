; HAND-WRITTEN. Rules: 10, 8, 11, 15, 9, 5, 2.
; Checked: flag_as_data: r + f + x, f = (x > k); compare_shared_by_region_and_angle: r + x (measured).
; Clean: compare_shared_by_region_and_angle's flag (x == k) and its angle rail A, uncomputed and freed.
; Kept: the user register x of each function; r (flag_as_data: rotated under control, frozen, measured;
; compare_shared_by_region_and_angle: rotated by the angle rail, measured); flag_as_data's compare rail f (user data,
; measured, never uncomputed).
; Rotations: flag_as_data: (Ry, x, th, 1); (Ry, r, t, x > k). compare_shared_by_region_and_angle: (Ry, x, th, 1);
; (P, f, p, x == k); (Ry, r, val(A), 1) with A = select(x == k, a, b).
; A compare that is both a CONDITION and DATA has one rail: the controlled Ry reads it as its control (rule 10), and
; afterwards the flag is not stripped but kept as the register the user wrote (measured here), as any other live
; derived value. One compare that feeds a phase REGION and an ANGLE (-O1 CSEs the two x == k into one icmp and carries
; the angle in the region's merge phi) is likewise one flag shared by both consumers: the kickback cqrt_rz_i1 (rule 8),
; then the merge phi as a QUANTUM ANGLE (rule 11): the phi's two runtime-classical incomings a, b become one
; cq_template_select_f64_ll on the same flag (rule 9), and ONE cqrt_ry_i32_qangle(r, A) consumes it (rule 15); the
; compiler never expands it into per-arm controlled Ry. The angle rail is uncomputed and freed after its consumer, then
; the flag once (rule 5). The compare is computed once and never re-derived.
source_filename = "cond_flag_as_data.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @flag_as_data(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp sgt i32 %6, %2  [register f: the condition AND a measured value]
  %8 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %11 = phi i32 [ %9, %8 ], [ %3, %5 ]  [register r, starts as %3]
  call void @cqrt_ry_i32_controlled(i32 %7, i32 %8, double %4)    ; IR: block %8: %9 = cq_theta_si32(%3, %4)  [Ry under f; f is not stripped: it is live data]
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %12 = cq_measure_si32(%11)
  %10 = call i1 @cqrt_measure_i1(i32 %7)    ; IR: %13 = cq_measure_i1(%7)
  %11 = zext i1 %10 to i32    ; IR: %14 = zext i1 %13 to i32  (classical)
  %12 = add nsw i32 %9, %11    ; IR: %15 = add nsw i32 %12, %14  (classical)
  %13 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %16 = cq_measure_si32(%6)
  %14 = add nsw i32 %12, %13    ; IR: %17 = add nsw i32 %15, %16  (classical)
  ret i32 %14    ; IR: ret i32 %17
}

define i32 @compare_shared_by_region_and_angle(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 %2)    ; IR: %9 = icmp eq i32 %8, %2  [path predicate of block %10 and flag of the angle phi %12]
  call void @cqrt_rz_i1(i32 %9, double %4)    ; IR: block %10: cq_phi(%4)  [kickback on the flag]
  %10 = call i32 @cq_template_select_f64_ll(i32 %9, double %5, double %6)    ; IR: %12 = phi double [ %5, %10 ], [ %6, %7 ]  [angle rail A: select on the flag]
  %11 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %13 = cq_theta_si32(%3, %12)  [register r, seeded with r0]
  call void @cqrt_ry_i32_qangle(i32 %11, i32 %10)    ; IR: %13 = cq_theta_si32(%3, %12)  [Ry(val(A)) on r]
  call void @cq_template_select_f64_ll_unc(i32 %10, i32 %9, double %5, double %6)    ; IR: uncompute %12
  call void @cqrt_free(i32 %10)    ; IR: release the angle rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %9 (once, after both consumers)
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %14 = cq_measure_si32(%13)
  %13 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %15 = cq_measure_si32(%8)
  %14 = add nsw i32 %13, %12    ; IR: %16 = add nsw i32 %15, %14  (classical)
  ret i32 %14    ; IR: ret i32 %16
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_ry_i32_qangle(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
