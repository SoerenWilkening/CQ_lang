; lowering_reject_uncompute_premeasure_taped.ll — ACCEPT since bd
; test_C_libtooling-ptue (was a DECLINE; third sibling of
; lowering_reject_uncompute_uninvertible_taped.ll, bd 261j(a) family). The name
; is kept so a merge cannot resurrect the old decline under it (CLAUDE.md L7).
;
; lowering_uncompute_dead_sibling_premeasure.ll's shape — a dead template terminal
; `%dead = q + 7` whose register lineage is LATER measured through `%q` — PLUS a
; tape write on `%dead`, so `%dead` is RECORDED into a kept carrier.
;
; WHAT THIS PINNED, AND WHAT IT PINS NOW. It pinned that the record freeze does
; not reorder the driver's checks, so a measured lineage could never degrade into
; the silent "left allocated" outcome (a freed or un-rotated `q` was the hazard).
; Since ptue the driver retries with the measured `q` BORROWED — never walked,
; adjointed or freed — so that hazard cannot arise, and the reduced plan is the
; textbook Bennett compute / copy / uncompute. Hand trace, Ry(.25)|x> = Σ_v a_v|v>:
;   add_hl(q, 7)           Σ a_v |v>|v+7>|0>_T
;   tape_write(T, dead)    Σ a_v |v>|v+7>|v+7>_T    (the user's printf record)
;   add_hl_unc(dead, q, 7) Σ a_v |v>|0>|v+7>_T      (q's label unchanged)
;   cqrt_free(dead)        |0> in a product state — no information learned
;   measure(q)             P(v) = |a_v|^2; the tape stays correlated, as printed
; The record freeze (step 3b) re-proves `%dead`'s chain: `add_hl` is a basis
; permutation of the live `q`, so the rail is NOT frozen and is freed (step 3b's
; "descendant of a recorded rail" algebra; `q` is borrowed and never re-proved).
; What still must hold, and is pinned: `q` is never un-rotated or freed (NOQ), and
; the reversal sits AFTER the tape read of the rail it frees (the 8gi5 anchor).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %x) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %dead = add i32 %q, 7                                      ; tainted template terminal
  %r    = call i32 (ptr, ...) @printf(ptr @.str, i32 %dead)  ; RECORDED onto the kept tape
  %m    = call i32 @cq_measure_si32(i32 %q)                  ; measures the register upstream
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(i32 %x)
; CHECK:       %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT:  %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[D]])
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 7)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; The measured register is never un-rotated and never freed (window = alloc -> EOF):
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
