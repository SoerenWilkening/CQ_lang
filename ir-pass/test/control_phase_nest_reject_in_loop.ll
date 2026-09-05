; control_phase_nest_reject_in_loop.ll — DECLINE. A depth-2 register-free phase
; nest whose entry block sits on a CFG cycle.
;
; The 8h7d.5 in-loop narrowing — which lets a FLAT tainted phase region lower
; ROLLED inside a classically-bounded loop — was proven for a region with ONE arm
; and ONE merge (`flatRegionRollableInLoop` names exactly those), and nothing has
; re-derived it for a three-block region tree. So the nest keeps the d8jl decline
; and its existing `nested control flow` string.
;
; This is an over-decline with a plausible lowering, not an impossibility: a
; nest's ancillas are all minted, stripped and freed INSIDE the iteration, which
; is the property the flat narrowing turns on. Widening it means a twin matrix of
; its own (rolled vs hand-unrolled, byte-identical) and an adversarial round —
; the 8h7d.5 record on loop widenings is 4-for-4 on "the first round finds a
; confirmed silent miscompile".
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %i1, %merge ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %i1 = add i32 %i, 1
  %done = icmp slt i32 %i1, 3
  br i1 %done, label %head, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: nested control flow under quantum control
