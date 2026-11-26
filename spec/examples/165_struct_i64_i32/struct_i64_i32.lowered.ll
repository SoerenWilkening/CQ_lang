; HAND-WRITTEN. Rules: 26, 18, 1, 3, 4, 5, §1.4.
; Checked: r.a + r.b (struct_i64_i32_one, measured); r.a and r.b (struct_i64_i32_both, each measured).
; Clean: struct_i64_i32_one: the result rail r.b (zeroed by the twin, freed by the caller), the clone's chain (the
;        sext rail is not freed: rule 6 updates it in place into the measured sum). struct_i64_i32_both: the clone's chain (both result rails are measured and stay).
; Kept: the rotated registers (p.b; p.a and p.b), frozen; the measured rails.
; Rotations: Ry(tb) on p.b; Ry(ta) on p.a and Ry(tb) on p.b.
; A 12-byte struct { long, int } is coerced to the two-register aggregate { i64, i32 } at the C ABI, in and out: here
; -O1 needs no shifts or masks, the fields already arrive as separate SSA values. Under rule 26 the aggregate is a
; tuple of fields: a quantum field is an i32 handle, a classical one keeps its C type, and extractvalue / insertvalue
; on it are classical (no gate). The clone takes the fields in order (§1.4, one digit per field of the aggregate, then
; c): __cq_q_bump_010(i64 a, i32 b handle, i32 c) returns { i64 classical r.a, i32 handle r.b } (the classical field
; r.a = a + c is ordinary host arithmetic inside the clone); __cq_q_bump_110(i32 a handle, i32 b handle, i32 c) returns
; { i32, i32 } of two handles (r.a = a + sext(c) is an add_hl of the i64 handle by the classical sign-extended c). Each
; clone copies its quantum results into fresh rails and uncomputes its chain (rule 18). struct_i64_i32_one sign-extends
; the handle r.b by a cast template and adds the classical r.a to it in place (rule 6's in-place update: the sext is
; dead after the add, so addc_i64 on its rail is the sum), runs the twin to zero r.b and frees it. struct_i64_i32_both measures both result rails directly: no twin runs (51 / 71) and
; the final add of the two outcomes is classical.
source_filename = "struct_i64_i32.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @struct_i64_i32_one(i64 noundef %0, i32 noundef %1, double noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %5 = cq_theta_si32(%1, %2)  [register p.b]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%1, %2)  [Ry]
  %6 = call fastcc { i64, i32 } @__cq_q_bump_010(i64 %0, i32 %5, i32 %3)    ; IR: %6 = call @bump(%0, %5, %3): clone for mask (p.a classical, p.b quantum, c classical); result { classical r.a, handle r.b }
  %7 = extractvalue { i64, i32 } %6, 0    ; IR: %7 = extractvalue %6, 0  (r.a: a classical i64)
  %8 = extractvalue { i64, i32 } %6, 1    ; IR: %8 = extractvalue %6, 1  (r.b: the handle of the result rail; classical)
  %9 = call i32 @cq_template_sext_i32_to_i64(i32 %8)    ; IR: %9 = sext i32 %8 to i64  [cast template]
  call void @cqrt_addc_i64(i32 %9, i64 %7)    ; IR: %10 = add nsw i64 %7, %9  [rule 6, in-place update: the sext is dead after the add, so the result IS the %9 rail]
  call fastcc void @__cq_q_bump_010_unc(i32 %8, i64 %0, i32 %5, i32 %3)    ; IR: uncompute r.b (adjoint of the call)
  call void @cqrt_free(i32 %8)    ; IR: release the r.b rail (|0>)
  %10 = call i64 @cqrt_measure_i64(i32 %9)    ; IR: %11 = cq_measure_sl(%10)
  ret i64 %10    ; IR: ret i64 %11
}

define internal fastcc { i64, i32 } @__cq_q_bump_010(i64 %0, i32 %1, i32 %2) {
  %4 = sext i32 %2 to i64    ; IR: %4 = sext i32 %2 to i64  (classical)
  %5 = add nsw i64 %4, %0    ; IR: %5 = add nsw i64 %4, %0  (classical: r.a)
  %6 = call i32 @cq_template_sub_i32_hl(i32 %1, i32 %2)    ; IR: %6 = sub nsw i32 %1, %2  [r.b]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: insertvalue ..., %6, 1  [result rail r.b]
  call void @cqrt_copy_i32(i32 %6, i32 %7)    ; IR: copy r.b out
  call void @cq_template_sub_i32_hl_unc(i32 %6, i32 %1, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %8 = insertvalue { i64, i32 } poison, i64 %5, 0    ; IR: %7 = insertvalue poison, %5, 0  (the classical field)
  %9 = insertvalue { i64, i32 } %8, i32 %7, 1    ; IR: %8 = insertvalue %7, %6, 1  (the handle)
  ret { i64, i32 } %9    ; IR: ret { i64, i32 } %8
}

define internal fastcc void @__cq_q_bump_010_unc(i32 %0, i64 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_sub_i32_hl(i32 %2, i32 %3)    ; IR: recompute %6 (r.b)
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: xor r.b out of the result rail
  call void @cq_template_sub_i32_hl_unc(i32 %5, i32 %2, i32 %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %5)    ; IR: release the %6 rail (|0>)
  ret void
}

define i64 @struct_i64_i32_both(i64 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %6 = cq_theta_sl(%0, %1)  [register p.a]
  call void @cqrt_ry_i64(i32 %6, double %1)    ; IR: %6 = cq_theta_sl(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register p.b]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call fastcc { i32, i32 } @__cq_q_bump_110(i32 %6, i32 %7, i32 %4)    ; IR: %8 = call @bump(%6, %7, %4): clone for mask (p.a quantum, p.b quantum, c classical); result { handle r.a, handle r.b }
  %9 = extractvalue { i32, i32 } %8, 0    ; IR: %9 = extractvalue %8, 0  (r.a: handle)
  %10 = extractvalue { i32, i32 } %8, 1    ; IR: %10 = extractvalue %8, 1  (r.b: handle)
  %11 = call i64 @cqrt_measure_i64(i32 %9)    ; IR: %11 = cq_measure_sl(%9)
  %12 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %12 = cq_measure_si32(%10)
  %13 = sext i32 %12 to i64    ; IR: %13 = sext i32 %12 to i64  (classical)
  %14 = add nsw i64 %11, %13    ; IR: %14 = add nsw i64 %11, %13  (classical)
  ret i64 %14    ; IR: ret i64 %14
}

define internal fastcc { i32, i32 } @__cq_q_bump_110(i32 %0, i32 %1, i32 %2) {
  %4 = sext i32 %2 to i64    ; IR: %4 = sext i32 %2 to i64  (classical)
  %5 = call i32 @cq_template_add_i64_hl(i32 %0, i64 %4)    ; IR: %5 = add nsw i64 %4, %0  (commutative: handle first)  [r.a]
  %6 = call i32 @cq_template_sub_i32_hl(i32 %1, i32 %2)    ; IR: %6 = sub nsw i32 %1, %2  [r.b]
  %7 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: insertvalue ..., %5, 0  [result rail r.a]
  call void @cqrt_copy_i64(i32 %5, i32 %7)    ; IR: copy r.a out
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: insertvalue ..., %6, 1  [result rail r.b]
  call void @cqrt_copy_i32(i32 %6, i32 %8)    ; IR: copy r.b out
  call void @cq_template_sub_i32_hl_unc(i32 %6, i32 %1, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %5, i32 %0, i64 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %9 = insertvalue { i32, i32 } poison, i32 %7, 0    ; IR: %7 = insertvalue poison, %5, 0  (the aggregate now carries handles)
  %10 = insertvalue { i32, i32 } %9, i32 %8, 1    ; IR: %8 = insertvalue %7, %6, 1
  ret { i32, i32 } %10    ; IR: ret { i64, i32 } %8
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i64(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_copy_i64(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_sext_i32_to_i64(i32)
declare void @cqrt_addc_i64(i32, i64)
declare void @cqrt_free(i32)
declare i64 @cqrt_measure_i64(i32)
declare i32 @cqrt_measure_i32(i32)
