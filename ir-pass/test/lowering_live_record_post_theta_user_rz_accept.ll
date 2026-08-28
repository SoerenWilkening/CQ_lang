; lowering_live_record_post_theta_user_rz_accept.ll — ACCEPT, and it is a PINNED
; OPEN QUESTION, not a settled boundary. **PENDING OWNER RULING**, tracked on bd
; test_C_libtooling-6uqc (the Rule-13 round's F2 finding). Pinned the same way
; lowering_qram_array_record_chained_theta_accept.ll pins the QRAM-array gap: the
; suite records the shape and the disagreement, so the decision is visible
; instead of living only in an implementation detail.
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     a = cq_theta(a, 0.5);
;     int c = a + 3;          // ONE record of the wire
;     a = cq_theta(a, 0.7);   // T — chained, in-place Ry
;     c = cq_phi(c, 1.0);     // a USER Rz naming the record AFTER T
;     return cq_measure(a);
;
; VERDICT TODAY: ACCEPT, under the implemented C-LIVENESS reading of clause 3 —
; the record `%c` still has a USER instruction naming it after the gate, so it is
; read as live user data whose dephasing is source semantics.
;
; THE RULING'S OWN WORDING WOULD DECLINE IT. The owner ruled (2026-08-27, first
; round) that "a future measure/template-read/ret IS a data use" — an ENUMERATED
; list, and a user `cq_phi` is on none of it. Under that reading `%c` is dead at
; `T` and the module declines. The implementation silently chose the permissive
; side by making `isTeardownUse` answer "user rotation ⇒ not teardown ⇒ data
; use"; nothing in the ruling licensed that, and nothing recorded the choice.
;
; WHY IT MATTERS, in one line: THE PHYSICS AT `T` IS IDENTICAL to the declining
; spelling. Reordering the last two source lines —
;     int c = a + 3; c = cq_phi(c, 1.0); a = cq_theta(a, 0.7);
; — leaves exactly the same rails standing at the gate (`%c` undischarged,
; entangled with the wire, never freed) and DECLINES with the live-record
; message. The `Rz` is DIAGONAL: it changes no basis label and cannot disentangle
; `%c` from the wire, so whether it is written before or after the rotation
; changes nothing about what the rotation sees. Two spellings with the same state
; at `T` currently get opposite verdicts.
;
; DO NOT "FIX" THIS FIXTURE BY WIDENING SOMETHING. Either verdict is defensible
; and the choice belongs to the owner: accepting keeps a real user program
; compiling, declining keeps the ruled predicate literal and is the safe
; direction. If the ruling comes down for the enumerated list, this file becomes
; a negative fixture (the `not`-inverted run line) and the `isTeardownUse`
; comment loses its PENDING note.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %c  = add nsw i32 %q, 3                                      ; the record
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)   ; T — chained, in-place Ry
  %cz = call i32 @cq_phi_si32(i32 %c, double 1.000000e+00)     ; USER Rz on the record, AFTER T
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[C]], double 1.000000e+00)
; The record is never uncomputed and never freed — it IS standing at the gate:
; CHECK-NOT:  call void @cqrt_free(i32 %[[C]])
