; HAND-WRITTEN. Rules: 26, 18, 1, 3, 4, 5, §1.4.
; Checked: r.i.a + r.i.b + r.w (measured).
; Clean: the add and sitofp rails, both result rails r.i.a and r.i.b (zeroed by the twin, freed by the caller), the
;        clone's chain.
; Kept: the register x (frozen) and the measured result rail.
; Rotations: Ry(tx) on x.
; A nested struct { { int, int }, double } is 16 bytes and is returned as the two-register aggregate { i64, double }:
; the inner struct is COERCED to one i64 (-O1 packs r.i.a and r.i.b by zext / shl 32 / or disjoint in the callee and
; unpacks them by trunc / lshr 32 / trunc in the caller), the double rides in the second register. Under rule 26 the
; aggregate is a tuple of its scalar fields, flattened in field order: the two inner ints are quantum (x + c, x * c),
; one handle each, and r.w = w * 2 is classical. The coercion's packing and unpacking are CLASSICAL ABI ARITHMETIC and
; emit no gate: the fields are separate rails that never share a register. The clone __cq_q_mk_100 (§1.4, x quantum,
; c, w classical) returns the flat { i32, i32, double } (handle r.i.a, handle r.i.b, classical r.w), after copying both
; quantum results into fresh rails and uncomputing its chain (rule 18); its twin _unc(out a, out b, x, c, w) recomputes
; both, XORs them out and uncomputes. The caller's extractvalues stand for the trunc / lshr-trunc of the i64 and the
; extractvalue of the double. r.i.a + r.i.b is an out-of-place add of two handles, the int-to-double conversion a cast
; template, and the final fadd of the classical r.w and that rail is the _hl shape (commutative: handle first). LIFO:
; the cast, the add, then the twin zeroes the two result rails, which are freed.
source_filename = "nested_struct_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @nested_struct_return(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc { i32, i32, double } @__cq_q_mk_100(i32 %5, i32 %2, double %3)    ; IR: %6 = call @mk(%5, %2, %3): clone for mask (x quantum, c, w classical); result { handle r.i.a, handle r.i.b, classical r.w } (the inner struct's i64 coercion unpacked)
  %7 = extractvalue { i32, i32, double } %6, 0    ; IR: %7 = extractvalue %6, 0 (the i64 coercion); %9 = trunc i64 %7 to i32  (r.i.a: the handle, classical unpack, no gate)
  %8 = extractvalue { i32, i32, double } %6, 1    ; IR: %10 = lshr i64 %7, 32; %11 = trunc nuw i64 %10 to i32  (r.i.b: the handle, classical unpack, no gate)
  %9 = extractvalue { i32, i32, double } %6, 2    ; IR: %8 = extractvalue %6, 1  (r.w: a classical double)
  %10 = call i32 @cq_template_add_i32(i32 %8, i32 %7)    ; IR: %12 = add nsw i32 %11, %9
  %11 = call i32 @cq_template_sitofp_i32_to_f64(i32 %10)    ; IR: %13 = sitofp i32 %12 to double  [cast template]
  %12 = call i32 @cq_template_fadd_f64_hl(i32 %11, double %9)    ; IR: %14 = fadd double %8, %13  [result rail; commutative: handle first]
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %11, i32 %10)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i32_unc(i32 %10, i32 %8, i32 %7)    ; IR: uncompute %12
  call void @cqrt_free(i32 %10)    ; IR: release the %12 rail (|0>)
  call fastcc void @__cq_q_mk_100_unc(i32 %7, i32 %8, i32 %5, i32 %2, double %3)    ; IR: uncompute r.i.a and r.i.b (adjoint of the call)
  call void @cqrt_free(i32 %7)    ; IR: release the r.i.a rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the r.i.b rail (|0>)
  %13 = call double @cqrt_measure_f64(i32 %12)    ; IR: %15 = cq_measure_f64(%14)
  ret double %13    ; IR: ret double %15
}

define internal fastcc { i32, i32, double } @__cq_q_mk_100(i32 %0, i32 %1, double %2) {
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %1)    ; IR: %4 = add nsw i32 %1, %0  (commutative: handle first)  [r.i.a]
  %5 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 %1)    ; IR: %5 = mul nsw i32 %1, %0  [r.i.b]
  %6 = fmul double %2, 2.000000e+00    ; IR: %6 = fmul double %2, 2.0  (classical: r.w)
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7..%10 (zext, shl 32, zext, or disjoint: the inner struct's i64 coercion, classical packing, no gate)  [result rail r.i.a]
  call void @cqrt_copy_i32(i32 %4, i32 %7)    ; IR: copy r.i.a out
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: [result rail r.i.b]
  call void @cqrt_copy_i32(i32 %5, i32 %8)    ; IR: copy r.i.b out
  call void @cq_template_mul_i32_hl_unc(i32 %5, i32 %0, i32 %1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 %1)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %9 = insertvalue { i32, i32, double } poison, i32 %7, 0    ; IR: %11 = insertvalue poison, %10, 0  (the aggregate carries the two inner handles in place of the i64)
  %10 = insertvalue { i32, i32, double } %9, i32 %8, 1    ; IR: %11  (r.i.b's handle)
  %11 = insertvalue { i32, i32, double } %10, double %6, 2    ; IR: %12 = insertvalue %11, %6, 1  (the classical r.w)
  ret { i32, i32, double } %11    ; IR: ret { i64, double } %12
}

define internal fastcc void @__cq_q_mk_100_unc(i32 %0, i32 %1, i32 %2, i32 %3, double %4) {
  %6 = call i32 @cq_template_add_i32_hl(i32 %2, i32 %3)    ; IR: recompute %4 (r.i.a)
  %7 = call i32 @cq_template_mul_i32_hl(i32 %2, i32 %3)    ; IR: recompute %5 (r.i.b)
  call void @cqrt_copy_i32(i32 %6, i32 %0)    ; IR: xor r.i.a out of its result rail
  call void @cqrt_copy_i32(i32 %7, i32 %1)    ; IR: xor r.i.b out of its result rail
  call void @cq_template_mul_i32_hl_unc(i32 %7, i32 %2, i32 %3)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %2, i32 %3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
