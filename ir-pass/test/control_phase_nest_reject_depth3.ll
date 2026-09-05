; control_phase_nest_reject_depth3.ll — DECLINE. A THREE-level register-free
; phase nest.
;
; P4's cap is depth 2, and it is enforced STRUCTURALLY rather than by a counter:
; the inner content arm must end in an UNCONDITIONAL branch to the merge, so a
; depth-3 inner arm (which ends in a tainted conditional `br`) matches neither
; orientation and the classifier returns NotApplicable. The ordinary
; `recoverRegion` path then declines `nested control flow`.
;
; The generalization is real and is not hard in principle — the conjunction is
; associative, so depth N is N-1 toffolis over N leaf flags with an LIFO teardown
; — but it needs its own probe family for the polarity combinatorics (2^N bracket
; placements) and is out of scope here. Over-declining is safe.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %mid2, label %merge
mid2:
  call void @cq_phi(double 6.250000e-01)
  %c3 = icmp eq i32 %q, 7
  br i1 %c3, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: nested control flow under quantum control
