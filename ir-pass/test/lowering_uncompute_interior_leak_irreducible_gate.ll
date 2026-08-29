; lowering_uncompute_interior_leak_irreducible_gate.ll — LEAK PROBE (M-B
; Increment 5, bd test_C_libtooling-4p7j Rule-13 round, finding F1). §2.9
; AT-MOST-ONCE over an IRREDUCIBLE cycle, applied to an in-place gate on an
; OWNED interior rail.
;
; THE DEFECT, MEASURED at 99211ad on exactly this module. `%h_op` is minted ONCE
; in `entry`, and `cqrt_addc_i32(%h_op, 7)` sits in `%A`, which executes K >= 1
; times (`entry -> A -> B -> A -> …`). The interior partition recovered that addc
; as an in-place link of `%h_op`'s chain and emitted, in `%exit`:
;
;     call void @cqrt_addc_i32(i32 %h_op, i32 -7)          ; ONE adjoint …
;     call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 5)
;     call void @cqrt_free(i32 %h_op)                      ; … for K applications
;
; `opt` rc=0, verify-clean, and `free_pairing_check.py` reported only
; `UNPROVEN U3-extern-rail` (not a violation) — the verify-clean silent
; miscompile this project exists to stop. For any trace that takes the cycle
; twice the freed rail holds `5h + 7(K-1)`, so the `cqrt_free` is a hardware
; reset of a NON-|0> rail: a hidden measurement that collapses `%h` (Rule 6).
;
; ROOT CAUSE. Every loop test in the partition asked `LoopInfo::getLoopFor`,
; which recognizes only NATURAL loops (a back edge to a header that dominates
; the body). Here `%A` and `%B` have two entries each and neither dominates the
; other, so the cycle is IRREDUCIBLE, `getLoopFor` returns null for both blocks,
; and every positional proof passes on the way past: `%A` dominates `%exit`,
; `%exit` post-dominates `%A`. bd c6yw / bd memory
; [free-placement-invariant-2026-08-11] recorded exactly this blindness and
; switched only the FINAL `At` test to `blockCanRepeat`; the fix generalizes it
; to the two places that decide WHICH rails and gates the group owns.
;
; THE FENCE. `canRepeat` = `LoopInfo` (fast path) OR `blockCanRepeat` (a
; reachable-from-itself successor DFS, a strict superset), asked
;   * per candidate MINT block, and
;   * per IN-PLACE GATE on a candidate rail (this fixture), and
;   * per recovered gate, as the group-level backstop.
; A repeated READ is harmless — it does not change the rail, which is why d3's
; consumer-in-a-loop shape still discharges
; (lowering_uncompute_interior_loop_consumer_and_after.ll). A repeated WRITE is
; the whole hazard, so the fence keys on writes only.
;
; WHAT STILL DISCHARGES IS THE DISCRIMINATION. `%h_op` drops out of the owned
; set and becomes a BORROWED parent of the compare rail's group; the compare
; rail `%h_cmp` is minted and read entirely inside `%exit` and is still
; discharged. Its clause-(d) obligation on the borrowed `%h_op` is met by the
; LEFT disjunct — the addc is `provablyBefore` the icmp (`%A` dominates `%exit`
; and `%exit` cannot reach `%A`), so `%h_op` holds the same value at the strip
; that it held at the forward compare. A fixture that showed NOTHING lowering
; would also pass if the whole partition were disabled.
;
; C REACHABILITY: none today. `c_goto_cycle_addc.c` (a `goto` into a `for(;;)`
; body) declines loudly upstream — the cycle-carried tainted value is a phi and
; `declineClassicalMuxes` refuses it before any uncompute runs. The pass accepts
; hand-written IR, and "the frontend probably won't" is not a proof.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_addc_i32(i32, i32)

define i32 @interior_irreducible_gate(i32 %u0, i1 %c0, i1 %c1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = mul i32 %q, 5
  br i1 %c0, label %A, label %B
A:                                        ; preds = %entry, %B — irreducible
  call void @cqrt_addc_i32(i32 %r, i32 7)
  br i1 %c1, label %B, label %exit
B:                                        ; preds = %entry, %A
  br label %A
exit:
  %c = icmp slt i32 %r, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %m2
  ret i32 %s
}

; The forward stream is untouched — the K-times addc still runs K times:
; CHECK-LABEL: define i32 @interior_irreducible_gate(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:      call void @cqrt_addc_i32(i32 %[[OP]], i32 7)
; The compare rail — minted, read and discharged entirely inside %exit:
; CHECK:      %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[OP]], i32 10)
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[CMP]], i32 %[[OP]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CMP]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Z]])

; …and the cycle-written rail is LEFT ALLOCATED: no negated adjoint of the
; K-times addc, no producer `_unc`, no free. One anchor, one prefix, so the
; window runs anchor -> EOF (bd memory [filecheck-check-not-window-trap];
; `tools/fixture_guard_liveness.py` proves it executes):
; NOFREEOP:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(
; NOFREEOP-NOT: call void @cqrt_addc_i32(i32 %[[OP2]], i32 -7)
; NOFREEOP-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEOP-NOT: call void @cqrt_free(i32 %[[OP2]])
