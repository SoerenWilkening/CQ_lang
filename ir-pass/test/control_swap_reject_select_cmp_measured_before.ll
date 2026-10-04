; control_swap_reject_select_cmp_measured_before.ll — DECLINE (Track A.1, bd
; test_C_libtooling-r903 item (b) / -r10v): the condition REGISTER is measured
; BEFORE the 4.4 data select that controls on it.
;
;     int q = 0; cq_theta(&q, .5);
;     int m = cq_measure(q);
;     int a = (q == 1) ? 2 : 5;        // the flag is minted from a COLLAPSED q
;
; VERBATIM `clang -O1` (probe `d1_sel_cmp_measured_before.c`). It ACCEPTED on
; `main` 0c7380c and emitted `cqrt_measure_i32(%h)` and then
; `cq_template_icmp_eq_i32_hl(%h, 1)` — a control read of a register the
; measurement already collapsed, Rule 6's loud-reject class — at `opt` exit 0,
; verify-clean and STRICT-stage-2b clean.
;
; THE PARITY IT REPAIRS: the one-token `_Bool` twin
; (`control_swap_reject_select_rail_measured_before.ll`) has declined since
; Increment 1b-B.1, through `classifySelectRegion`'s rail rung (ii)
; (`railMeasuredBeforeReadPoint`). The COMPARE leaf beside it was asked by NO
; rung — `condDataUseDisposition`'s `MeasuredEarly` is a `br`-path question about
; the FLAG's own data lineage and is not reached from the select path at all.
; `condCmpMeasuredBeforeReadPoint` (`ArmClassify`) now asks the SAME helper of
; every compare leaf's `condProvenance` cone, with the SELECT as the read point.
; The discriminating accept one line apart is
; `control_swap_select_cmp_measure_after.ll`.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  %c = icmp eq i32 %q, 1
  %a = select i1 %c, i32 2, i32 5
  %r = add nsw i32 %a, %m
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
