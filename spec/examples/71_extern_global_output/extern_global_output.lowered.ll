; HAND-WRITTEN. Rules: 20, 5 (Memory, sentence 3), 18, 9, 2; §1.3 (the bus, __cq_mem).
; Checked: r = body(x, k, &signflag) = x * x (measured, %5 -> %6); the cells of `signflag` at exit (read from the bus)
; hold select(x < k, -1, 1).
; Clean: inside the clone: the compare flag x < k (%4) and the product x * x (%6: copied out to %7, then uncomputed).
; Kept: the user register x (%4 of the caller: rotated); the result rail (%7 of the clone, %5 of the caller, measured,
; rule 2; body has no twin, rule 18); in the clone the sign rail
; select(x < k, -1, 1) (%5: the value rail of the kept store, rule 5 sentence 3) and the tape slot of the store
; `store i32 %4, ptr @signflag` (no handle: it holds the displaced content of `signflag`).
; Rotations: (Ry, x, th, 1).
; Expected for the driver extern_global_output(0, .5, 3) (analytic, not replayed): Ry(.5) flips each of the 32 bits of x
; independently with probability s = sin^2(.25) = 0.0612087; x = 0 (probability 0.132498) gives r = 0 and signflag = -1.
; The lgamma shape: lgamma(x) calls lgamma_r(x, &signgam) and signgam is an `extern int` with EXTERNAL linkage, readable
; by any translation unit and by the user after the call. -O1 promotes the pointer argument, so body stores straight
; into the global. ONE BUS (rule 20): `signflag` lives at its host address; nothing is allocated, seeded or registered
; for it, and the store is a bus store at the classical address `ptrtoint (ptr @signflag to i64)`. The clone accesses
; the bus, so it calls __cq_mem() once at its entry (§5); the caller makes no bus access. The store writes the VALUE of
; the sign into the four cells (they become QUANTUM, §1.3): it is a KEPT store (rule 5 sentence 3), no _unc exists, its
; tape slot stays for the shot and so does its value rail, the sign. A reader elsewhere loads the cells, never a handle.
; The sign is built by a select into a fresh rail (rule 9); its compare flag is uncomputed as usual (the sign rail no
; longer needs it). body writes memory (rule 5), so it has no twin (rule 18) and its result rail is KEPT by the caller;
; that result is measured anyway (as 51). The clone keeps -O1's `internal fastcc` (§1.4) and its mask 10 (arg 0 quantum).
source_filename = "extern_global_output.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@signflag = local_unnamed_addr global i32 0, align 4    ; IR: @signflag  (external linkage: lives at its host address on the bus, nothing allocated for it)

define i32 @extern_global_output(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call fastcc i32 @__cq_q_body_10(i32 %4, i32 %2)    ; IR: %5 = call @body(%4, %2), quantum clone (arg 0 quantum; a memory version change: body writes memory, no twin)
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define internal fastcc i32 @__cq_q_body_10(i32 %0, i32 %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %4 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 %1)    ; IR: %3 = icmp slt i32 %0, %1
  %5 = call i32 @cq_template_select_i32_ll(i32 %4, i32 -1, i32 1)    ; IR: %4 = select i1 %3, i32 -1, i32 1  [the sign, a fresh rail]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr @signflag to i64), i32 %5)    ; IR: store i32 %4, ptr @signflag  (a kept store at a classical address: its tape slot and its value rail %4 stay, no _unc)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %4, i32 %0, i32 %1)    ; IR: uncompute %3 (the sign rail does not depend on the flag any more)
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  %6 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %5 = mul nsw i32 %0, %0  (the same rail in both operand slots)
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %6, i32 %7)    ; IR: copy the result out
  call void @cq_template_mul_i32_unc(i32 %6, i32 %0, i32 %0)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  ret i32 %7    ; IR: ret i32 %5
}

declare i32 @__cq_mem()
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
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
