; HAND-WRITTEN. Rules: 27, 19, 18, 7, 2, 4, 5, §1.1 (escaped rail), §1.4 (table clones), §0.
; Checked: the returned rail ext_fn(x, c) + m, where m = cq_measure(x) (an UNMEASURED quantum result: the ret carries
;          its handle, §1.1, checked as that rail's basis value).
; Clean: the clone result r when the twin zeroes it (the twin frees it, §1.4; the caller frees no result of a table
;        clone).
; Kept: the register x (measured), the returned rail (escapes with the return; never freed), and r where ext_fn's
;       twin does not zero it (no rule-18 twin: KEPT; a FROZEN result, rule 19), as §1.4 states.
; Rotations: Ry(tx) on x.
; ext_fn has no body in this module, so rule 27 applies: the call becomes a call to the DECLARED clone, the table
; clone of §1.4 of the call's arrangement, named from the callee's C signature and which actuals are rails:
; __cq_q_ext_fn_10_t (x a rail, c classical), no _b bounds. x is passed as its handle, the classical c as its C value
; (digit 0). K follows as a trailing classical i32 (here the corpus default 4): the clone's quantum-exit loops run
; min(K, B) trips. The result r is a handle; its twin __cq_q_ext_fn_10_t_unc(r, x, c, K) always exists and pops
; what the clone pushed. Both use the default C calling convention. Whatever is linked defines them; if nothing
; does, linking fails with an undefined symbol. The call is a memory version change (rule 5); no other memory
; version change follows it, so the twin runs at its rule-18 position (rule 19): after r's last use, the add.
; r is quantum, so r + m is the out-of-place add_hl with the classical outcome m as the literal (rule 4). x is
; measured by then, which is allowed (§1.3: a measured rail may still be read as an operand); after the measurement
; every branch holds r = ext_fn(m, c), which the twin recomputes and XORs out.
source_filename = "opaque_callee.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @opaque_callee(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @__cq_q_ext_fn_10_t(i32 %4, i32 %2, i32 4)    ; IR: %5 = call @ext_fn(%4, %2): the declared (table) clone of the call's arrangement, x a handle, the classical c as its C value, then K (rule 27); a memory version change; result r is a handle  [K]
  %6 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %6 = cq_measure_si32(%4)
  %7 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %6)    ; IR: %7 = add nsw i32 %6, %5  (r quantum, m classical: commutative, spelled _hl)
  call void @__cq_q_ext_fn_10_t_unc(i32 %5, i32 %4, i32 %2, i32 4)    ; IR: twin of %5: r to |0> and freed by the twin (its last use was %7; rule 19 at its rule-18 position)  [K]
  ret i32 %7    ; IR: ret i32 %7  (the handle of the returned rail, §1.1)
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @__cq_q_ext_fn_10_t(i32, i32, i32)
declare void @__cq_q_ext_fn_10_t_unc(i32, i32, i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
