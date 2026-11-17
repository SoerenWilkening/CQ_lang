; HAND-WRITTEN. Rules: §1.1 (escaped rail), 19, 18, 2, 4, 5, 6, §0.
; Checked: quantum_return_consumer's measured q * 2. quantum_return_entry returns an UNMEASURED quantum value: its
;          `ret i32` carries the HANDLE of the x + c rail (§1.1), checked as that rail's basis value.
; Clean: in the entry the old x rail (%4, rule 6: |0> after the copy) and t = r - c (%6), both freed; in the consumer
;        nothing (its only garbage-free rail is the frozen result of the call).
; Kept: quantum_return_entry: the returned rail (escapes with the return; never freed).
;       quantum_return_consumer: the rail the call returns (FROZEN: the rule-6 image of the register x the callee minted
;       and rotated; never uncomputed, never freed) and the measured rail.
; Rotations: Ry(tx) on x in the entry (reached once per consumer call).
; An ENTRY function keeps its C signature (i32), and a quantum value returned through it is the i32 handle of the rail:
; the rail escapes to the caller and is never freed by the callee. The register x is dead after the add, a bijection in x
; for fixed c, so rule 6 cleans it before the return: a caller may rotate the returned rail, and a kept x would dephase it.
; Inside the entry the body is the ordinary rule-4 chain: one add_hl into a fresh rail, returned directly. The CONSUMER
; calls the entry (rule 19, ruling 2026-11-02: the compiler never inlines; a callee reached with no quantum argument whose
; body reaches a rotation is called as it is). The callee's result record says the returned handle is a FROZEN rail: the
; rule-6 image of the register x minted inside, so no twin exists for it and the consumer keeps it exactly as it would keep
; a register of its own. q * 2 (-O1: shl 1) is a fresh rail, measured; the returned rail stays allocated. A clone
; __cq_q_quantum_return_entry_000 would have the entry's own signature and body (no quantum argument, no extra result: the
; minted register was absorbed by rule 6), so the entry IS the clone and the call targets it (§1.4). Until 2026-11-02 this
; consumer inlined the entry's body (x minted here, q uncomputed against it); same rotation, same qubit count kept.
source_filename = "quantum_return_entry.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_return_entry(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: %5 = add nsw i32 %4, %2  [the result rail]
  %6 = call i32 @cq_template_sub_i32_hl(i32 %5, i32 %2)    ; IR: rule 6: t = r - c recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %6, i32 %4)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0> after the copy)
  ret i32 %5    ; IR: ret i32 %5  (the i32 is the HANDLE of the x + c rail: an escaped rail, never freed; x was cleaned by rule 6)
}

define i32 @quantum_return_consumer(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @quantum_return_entry(i32 %0, double %1, i32 %2)    ; IR: %4 = call @quantum_return_entry(%0, %1, %2): no quantum argument, called as it is; the i32 is the HANDLE of the x + c rail, FROZEN (rule 19: the rule-6 image of the register the callee minted), kept
  %5 = call i32 @cq_template_shl_i32_hl(i32 %4, i32 1)    ; IR: %5 = shl nsw i32 %4, 1  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6  (the returned %4 rail stays allocated: frozen, never freed)
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
