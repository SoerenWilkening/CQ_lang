; control_swap_reject_select_rail_round2_measured_parent.ll — DECLINE (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1, rung (ii)
; half; the reviewer's probe `ll/e06` verbatim). The SAME round-2 taint window as
; `..._round2_sibling_theta.ll` with the MEASURE form: `cq_measure(%x)` before
; the select, where `%x` is the 6.5 classical-call-arm `%out`'s `trunc` and is
; therefore CLASSICAL when `classifySelectRegion` asks rung (ii). The wire
; closure `railWireNamesBackward` stops at `%b` (a SOURCE theta at round-1
; taint), so the measurement of the PARENT is not on the wire it asks about —
; while `lowerRotations`, at FINAL taint, lowers `%b` IN PLACE on `%x`'s rail, so
; the measured register and the controlled one are the same physical rail.
;
; RED ON f8d29e8 (the round-1-fix checkpoint), where it ACCEPTS at exit 0 and
; emits the collapse before the control read:
;
;   call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)
;   %m5 = call i1 @cqrt_measure_i1(i32 %h_cast)     <- the register is classical here
;   %bf = call i32 @cqrt_alloc_i1(i1 false)
;   call void @cqrt_cnot(i32 %h_cast, i32 %bf)      <- a post-measure control read
;
; A gate controlled on an already-collapsed register is Rule 6's loud-reject
; class. `reverifyRailCondReads` re-asks `railMeasuredBeforeReadPoint` with the
; recorded read point (the `cqrt_cnot` above) and FINAL taint, where the closure
; DOES cross to `%x` and finds `cq_measure(%x)` reaching it.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %mx = call i1 @cq_measure_i1(i1 %x)
  %a = select i1 %b, i32 2, i32 5
  %zz = zext i1 %mx to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %zz
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
