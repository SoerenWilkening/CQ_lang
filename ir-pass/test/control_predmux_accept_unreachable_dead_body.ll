; control_predmux_accept_unreachable_dead_body.ll — ACCEPT (bd 20xt.5 (d),
; Rule-13 hardening): the accept twin, but the `unreachable` default block holds
; a NON-EMPTY PURE body (`add`/`mul` on the tainted scrutinee) before the
; `unreachable` terminator. This pins the "no SURVIVING moved body" invariant: a
; successorless `unreachable` block dominates nothing outside itself, so its SSA
; values have zero external uses; `moveBody` hoists the pure cone into the entry
; but `sweepDead` erases it (use_empty fixpoint) before `lowerOps` — no spurious
; gate, no leaked tainted producer. (An IMPURE dead body — a store/non-curated
; call — is instead excluded at E4; see control_predmux_leave_unreachable_store_arm.ll.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %sp = icmp sgt i32 %q, 100
  br i1 %sp, label %special, label %quad
special:
  %s = mul i32 %q, 2
  br label %merge
quad:
  %m = and i32 %q, 3
  switch i32 %m, label %dead [
    i32 0, label %c0
    i32 1, label %c1
    i32 2, label %c2
    i32 3, label %c3
  ]
c0:
  %a0 = add i32 %q, 10
  br label %merge
c1:
  %a1 = mul i32 %q, 5
  br label %merge
c2:
  %a2 = xor i32 %q, 7
  br label %merge
c3:
  %a3 = sub i32 %q, 4
  br label %merge
dead:
  %dv = add i32 %q, 424242          ; a NON-EMPTY pure body: dead (no external use)
  %dw = mul i32 %dv, %q             ; a second pure op in the cone
  unreachable
merge:
  %rm = phi i32 [ %s, %special ], [ %a0, %c0 ], [ %a1, %c1 ], [ %a2, %c2 ], [ %a3, %c3 ]
  %r  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %r
}

; Flattens exactly as the empty-unreachable twin; the dead pure body is swept —
; 424242 never reaches a template, no CFG survives.
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: 424242
; CHECK-NOT: switch i32
; CHECK-NOT: unreachable
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
