; control_swap_reject_select_cmp_measured_parent_name.ll — DECLINE (Track A.1,
; bd test_C_libtooling-r10v): the measurement names the compare operand's WIRE,
; not its SSA NAME.
;
;     int q  = cq_theta(0, .5);
;     int q2 = cq_theta(q, .3);        // CHAINED — in place on q's rail
;     int m  = cq_measure(q);          // names the PARENT; ONE register
;     int a  = (q2 == 1) ? 2 : 5;
;
; VERBATIM `clang -O1` (probe `d3_sel_cmp_measured_parent_name.c`), ACCEPT on
; `main` 0c7380c. `lowerRotations` RAUWs a chained-theta chain onto ONE handle
; (`Chained = taint.Tainted.count(arg0)`), so `q` and `q2` are one physical
; register and `cq_measure(q)` collapses the very register the merge then
; controls on — while `q` is no USER of `q2`, so a rung asking `q2->users()`
; sees nothing. This is round-1 item F-B1R1-1 exactly, one leaf species over:
; `railMeasuredBeforeReadPoint` asks over `railWireNamesBackward`'s closure, and
; the compare path now seeds that closure from each `condProvenance` member.
;
; The rail twin is `control_swap_reject_select_rail_measured_parent_name.ll`.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  %c = icmp eq i32 %q2, 1
  %a = select i1 %c, i32 2, i32 5
  %r = add nsw i32 %a, %m
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
