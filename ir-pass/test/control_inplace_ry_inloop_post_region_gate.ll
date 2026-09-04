; control_inplace_ry_inloop_post_region_gate.ll — ACCEPT: shape S1 (PRD §13.3),
; the in-loop Ry arm with a POST-REGION gate on the rotated register.
;
;     for (...) { if (q > 5) r = cq_theta(r, .9); r = cq_theta(r, .25); }
;
; THIS IS THE FAN-OUT SHAPE, and it is the second of the two M-β repairs. Under
; the pre-Inc-3 convention the emitter RAUW'd the merge φ to the BASE, so the
; loop-carried header φ `%r` acquired TWO in-place `cq_theta` users — the hoisted
; arm gate and the post-region `%rn` — and `collapseRailPhisIn` step (2) fired
; `loop-carried rail has multiple in-place consumers` (Rule 8) on a program whose
; hand-unrolled twin compiles. M-β RAUWs to the hoisted gate, so the chain reads
; `%r -> T -> %rn -> %r` and every rail value has exactly ONE in-place user.
;
; R6 PER ACTIVATION is what admits it: `%rm` (the merge φ) is a wire MEMBER via
; the header φ's latch incoming, and its user `%rn` is a HOP whose read position
; is reached only through the merge block — so every `BI -> %rn` path re-executes
; `%rm` first and the record is live where it is read. The FLAT predicates
; (`provablyBefore` / `cannotFollowGate`) both contain the reachability conjunct
; that the back edge falsifies, and both refuse it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; The post-region gate lands UNCONTROLLED on the same handle, after the strip:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 2.5
;
; WHOLE-FILE, via the `NOROUTE` prefix rather than a trailing `CHECK-NOT` (bd
; drbq Inc 3, round-1 lens L6, F-L6-1): a `CHECK-NOT` here would have scanned
; only from the last positive match to EOF, leaving the ENTRY BLOCK — where a
; route or an unlowered rotation would be just as wrong — unchecked.
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %rn    = call i32 @cq_theta_si32(i32 %rm, double 2.500000e-01)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rn)
  ret i32 %m
}
