; HAND-WRITTEN. Rules: 20, 18, 9, 5, 2.
; Checked: r = body(x, k, &signflag) = x * x (measured).
; Clean: inside the clone: the compare flag x < k and the product x * x (copied out, then uncomputed).
; Kept: the user register x; the result rail (measured); the sign rail select(x < k, -1, 1) stored into the extern
; global signflag (an output, never freed: a reader elsewhere may load the handle later).
; Rotations: Ry(th) on x.
; The lgamma shape: lgamma(x) calls lgamma_r(x, &signgam) and signgam is an `extern int` with EXTERNAL linkage,
; readable by any translation unit and by the user after the call. -O1 promotes the pointer argument, so the clone
; stores straight into the global. A global holds a HANDLE (example 67, rule 20); because this one escapes, the rail
; stored into it is an OUTPUT: it can never be uncomputed by this function (a reader elsewhere may load the handle
; later), so it stays allocated like a user register and like a tape field (47). The sign is built by a select into a
; fresh rail (rule 9); its compare flag is uncomputed as usual. The call result is the only other value and is
; measured, so no _unc twin is needed (as 51).
source_filename = "extern_global_output.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@signflag = global i32 0, align 4    ; IR: @signflag  (external slot: holds the handle of the sign rail after the call)

define i32 @extern_global_output(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call fastcc i32 @__cq_q_body_10(i32 %4, i32 %2)    ; IR: %5 = call @body(%4, %2), quantum clone (arg 0 quantum)
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define internal fastcc i32 @__cq_q_body_10(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 %1)    ; IR: %3 = icmp slt i32 %0, %1
  %4 = call i32 @cq_template_select_i32_ll(i32 %3, i32 -1, i32 1)    ; IR: %4 = select i1 %3, i32 -1, i32 1  [the sign, a fresh rail]
  store i32 %4, ptr @signflag, align 4    ; IR: store i32 %4, ptr @signflag  (the global takes the handle; the rail is an output, never freed)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 %1)    ; IR: uncompute %3 (the sign rail does not depend on the flag any more)
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  %5 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %5 = mul nsw i32 %0, %0  (the same rail in both operand slots)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %5, i32 %6)    ; IR: copy the result out
  call void @cq_template_mul_i32_unc(i32 %5, i32 %0, i32 %0)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  ret i32 %6    ; IR: ret i32 %5
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
