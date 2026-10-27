; HAND-WRITTEN. Rules: 18, 20, 5, §1.4.
; Checked: lo + hi (measured, %8 -> %9).
; Clean: the clone's result rail %6 (lo) and the hi rail %7 loaded from the slot, both zeroed by the clone's _unc twin and
; freed by the caller; inside the clone and its twin the shifted rail (%4) and the masked rail (%7) are uncomputed and
; freed.
; Kept: x (%5, the rotated register) and the sum rail %8 (measured); nothing else.
; Rotations: (Ry, x, th, 1).
; The out-parameter is a non-escaping alloca: a classical slot, and because the
; callee stores a quantum value into it, the slot holds the HANDLE of that rail. The clone __cq_q_split_100 (mask left to
; right, §1.4: v quantum, k classical, the slot carries no quantum field on entry) writes the handle, the caller loads it.
; The body has two templates, so BOTH results are copied out (rule 18): v >> k into a fresh rail whose handle goes into
; the slot, and the masked value into the returned rail; the clone then uncomputes its ashr and and rails.
; Both results are garbage after the add, so the caller runs the clone's _unc twin, which takes (out, args, old slot
; handle): it zeroes the returned rail and the slot's rail by recomputation and restores the slot's content from before
; the call (hi was never written, so the caller passes poison). The caller then frees both rails.
source_filename = "pointer_out_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @pointer_out_param(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca i32, align 4    ; IR: %4 = alloca i32  (classical slot; holds the handle of hi)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_split_100(i32 %5, i32 %2, ptr %4)    ; IR: %6 = call @split(%5, %2, %4), quantum clone (arg 0 quantum)
  %7 = load i32, ptr %4, align 4    ; IR: %7 = load i32, ptr %4  (the handle written by the clone)
  %8 = call i32 @cq_template_add_i32(i32 %7, i32 %6)    ; IR: %8 = add nsw i32 %7, %6
  call fastcc void @__cq_q_split_100_unc(i32 %6, i32 %5, i32 %2, ptr %4, i32 poison)    ; IR: uncompute %6 and the slot's rail (adjoint of the call); the last argument is the slot's content before the call (hi was never written: poison)
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the hi rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_split_100(i32 %0, i32 %1, ptr %2) {
  %4 = call i32 @cq_template_ashr_i32_hl(i32 %0, i32 %1)    ; IR: %4 = ashr i32 %0, %1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 %4, ptr %2  [slot result rail]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: store i32 %4, ptr %2  [copy the slot result out]
  store i32 %5, ptr %2, align 4    ; IR: store i32 %4, ptr %2  (store the copy's handle)
  %6 = shl nsw i32 -1, %1    ; IR: %5 = shl nsw i32 -1, %1  (classical)
  %7 = xor i32 %6, -1    ; IR: %6 = xor i32 %5, -1  (classical)
  %8 = call i32 @cq_template_and_i32_hl(i32 %0, i32 %7)    ; IR: %7 = and i32 %6, %0  (commutative: classical operand moved to the _hl slot)
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %7  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %7  [copy the result out]
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %0, i32 %7)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %4, i32 %0, i32 %1)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %9    ; IR: ret i32 %7
}


define internal fastcc void @__cq_q_split_100_unc(i32 %0, i32 %1, i32 %2, ptr %3, i32 %4) {
  %6 = load i32, ptr %3, align 4    ; IR: the handle the clone stored into %2 (the slot result rail)
  %7 = call i32 @cq_template_ashr_i32_hl(i32 %1, i32 %2)    ; IR: recompute %4
  call void @cqrt_copy_i32(i32 %7, i32 %6)    ; IR: xor %4 out of the slot result rail
  %8 = shl nsw i32 -1, %2    ; IR: %5 (classical)
  %9 = xor i32 %8, -1    ; IR: %6 (classical)
  %10 = call i32 @cq_template_and_i32_hl(i32 %1, i32 %9)    ; IR: recompute %7
  call void @cqrt_copy_i32(i32 %10, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %1, i32 %9)    ; IR: uncompute %7
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %7, i32 %1, i32 %2)    ; IR: uncompute %4
  call void @cqrt_free(i32 %7)    ; IR: release the %4 rail (|0>); the caller frees the slot result rail
  store i32 %4, ptr %3, align 4    ; IR: restore the slot's content from before the call (§1.4: old slot handles last)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_ashr_i32_hl(i32, i32)
declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
