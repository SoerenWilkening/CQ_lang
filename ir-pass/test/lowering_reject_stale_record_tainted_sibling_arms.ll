; lowering_reject_stale_record_tainted_sibling_arms.ll — DECLINE (bd
; test_C_libtooling-r2j3.2, review round 1 F1): the shape the relaxed stale proof
; must keep refusing. A tainted `add` reads `%q` in one arm of a TAINTED branch and
; an in-place `cq_theta` on `%q` sits in the SIBLING arm. In the CFG neither can
; reach the other, so leg 1 alone would call the gate harmless; but under quantum
; control both arms run, and the control emitters linearize them in an order the
; CFG does not fix (a value arm's chain is hoisted into the pred, an in-place Ry arm
; becomes a controlled Ry), so the read's order against the Ry is not established
; by the CFG. `gateFollowsRead` requires the gate to post-dominate the read, which
; a sibling arm never does, so this declines at the early stale sweep with the
; pure-op message. Classical twin (also still declined):
; lowering_reject_stale_record_exclusive_arms.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 0, double 7.000000e-01)
  %cc = icmp sgt i32 %c, 3                        ; TAINTED condition
  br i1 %cc, label %a, label %b

a:
  %d = add i32 %q, 3                              ; reads %q in one arm
  br label %merge

b:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)   ; Ry in the sibling
  br label %merge

merge:
  %r = phi i32 [ %d, %a ], [ %q2, %b ]
  %m = call i32 @cq_measure_si32(i32 %r)
  %mc = call i32 @cq_measure_si32(i32 %c)
  %s = add i32 %m, %mc
  ret i32 %s
}
