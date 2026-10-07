; spec_accept_select_nonzero_false.ll — ACCEPT (bd p3kd.7.1; was
; spec_reject_select_nonzero_false.ll, a 5po2 slice-1 accept-shape boundary): a
; lifted `select` whose FALSE arm is the non-zero constant 7. The retired
; `isLiftableSelect` admitted a constant false arm only when it was ZERO (the
; one-copy fast path), so this declined `InBodyControl`, although
; `lowerCloneSelect` lowers it with the two-copy stream: copy `b` on the flag,
; then the X-bracketed ¬flag copy of the materialized |7> rail (left allocated).
; The Bennett reverse replays both copies in reverse order inside the bracket,
; then the compare `_unc`, and frees the flag and the select rail.
;
; Trace check, |b>: flag = [b < 5]; sel = flag·b ⊕ ¬flag·7 = (b<5) ? b : 7.
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list (main's 4.4
; CondTreeEmit flag + SelectMergeEmit controlled-copy merge; `lowerCloneSelect` is
; gone). The two-copy stream and the |7> materialization are unchanged; what moved
; is the bracket: main's merge strips its flag (trailing `cqrt_x`, compare `_unc`,
; free) and inside a clone the Bennett wrap elides that strip, so the forward ends
; with the bracket OPEN (flag = [b>=5]) and the mirror's first `cqrt_x` closes it.
; Hand trace, |b>: forward sel = (b<5)?b:7, out = sel; mirror: sel ^= [b>=5]·7,
; flag→[b<5], sel ^= [b<5]·b (sel = 0), the `_unc` zeroes the flag. Flag and sel
; are |0> at their frees; the |7> rail K7 is never written and is NOT freed (a
; non-zero constant rail stays allocated), which the full-body CHECK-NEXT pin
; through `}` enforces.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %b, i32 7   ; non-zero false arm
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %b, i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  %[[K7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K7]], i32 %[[SEL]])
; Bennett copy-out; the merge's flag strip was elided, the bracket is still open.
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; The exact mirror: both copies in reverse order, the `cqrt_x` between them.
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K7]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %b, i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
