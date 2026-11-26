; HAND-WRITTEN. Rules: §1.1 (escaped rail), 19, 18, 2, 4, 5, 6, §0.
; Checked: quantum_return_consumer's measured q * 2. quantum_return_entry returns an UNMEASURED quantum value: its
;          `ret i32` carries the HANDLE of the x + c rail (§1.1), checked as that rail's basis value.
; Clean: nothing: in the entry rule 6's in-place update leaves no old x and no inverse to free; in the consumer
;        nothing (its only garbage-free rail is the frozen result of the call).
; Kept: quantum_return_entry: the returned rail (%4, the x rail updated in place; escapes with the return; never freed).
;       quantum_return_consumer: the rail the call returns (FROZEN: the rule-6 image of the register x the callee minted
;       and rotated; never uncomputed, never freed) and the measured rail.
; Rotations: Ry(tx) on x in the entry (reached once per consumer call).
; An ENTRY function keeps its C signature (i32), and a quantum value returned through it is the i32 handle of the rail:
; the rail escapes to the caller and is never freed by the callee. The register x is dead after the add, a bijection in x
; for fixed c, so rule 6 applies before the return: a caller may rotate the returned rail, and a kept x would dephase it.
; The add is rule 6's in-place update: ONE core gate, addc_i32(x, c), on the x rail, which is returned directly. The CONSUMER
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
  call void @cqrt_addc_i32(i32 %4, i32 %2)    ; IR: %5 = add nsw i32 %4, %2  [rule 6, in-place update: x is dead after the add, so the result IS the x rail]
  ret i32 %4    ; IR: ret i32 %5  (the i32 is the HANDLE of the x + c rail: an escaped rail, never freed; x was updated in place by rule 6)
}

define i32 @quantum_return_consumer(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @quantum_return_entry(i32 %0, double %1, i32 %2)    ; IR: %4 = call @quantum_return_entry(%0, %1, %2): no quantum argument, called as it is; the i32 is the HANDLE of the x + c rail, FROZEN (rule 19: the rule-6 image of the register the callee minted), kept
  %5 = call i32 @cq_template_shl_i32_hl(i32 %4, i32 1)    ; IR: %5 = shl nsw i32 %4, 1  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6  (the returned %4 rail stays allocated: frozen, never freed)
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_addc_i32(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
