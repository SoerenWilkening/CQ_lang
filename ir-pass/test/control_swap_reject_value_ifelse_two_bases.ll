; control_swap_reject_value_ifelse_two_bases.ll — if/else value arms over
; DIFFERENT bases decline (4.2 WI-3; Rule-12 pin for the base-identity check
; against the arm-1-anchored routed slot; the value analog of the phase
; fixture control_swap_reject_ifelse_crosshandle.ll).
;
; `if (q > 5) { t = p + 3; } else { t = r * 7; }` — each arm is individually a
; pure value chain, but they bottom at different registers (%p vs %r): there
; is no single routed base, so the region is a two-register multiplexer (4.4
; select-family), not a routable value if/else (§0 criterion 3: the arms'
; SHARED base).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %w0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %t1 = add i32 %p, 3        ; chain over %p
  br label %merge
else:
  %t2 = mul i32 %r, 7        ; chain over %r — a DIFFERENT base
  br label %merge
merge:
  %tm = phi i32 [ %t1, %then ], [ %t2, %else ]
  %m  = call i32 @cq_measure_si32(i32 %tm)
  ret i32 %m
}
