; control_predmux_accept_unreachable_default_switch.ll — ACCEPT (3c6m.14 L6,
; bd 20xt.5 (d)): a tainted region whose arm hosts an EXHAUSTIVE `switch` whose
; default `clang -O1` proved dead and lowered to a shared `unreachable` block
; (the atan2l quadrant-switch shape: a 2-bit sign pack `switch i32 %m [0..3]`
; with `default.unreachable`, nested under a tainted special-case branch).
;
; LLVM's PostDominatorTree treats `unreachable` as a SECOND function exit
; alongside `ret`, so `entry`'s immediate post-dominator is the VIRTUAL ROOT
; (getBlock()==nullptr) and PredMux's standard merge lookup bails silently — the
; region then declines as `nested control flow`. (d) recomputes the merge
; IGNORING the unreachable exit (pure analysis): the reachable case + special-
; case edges reconverge at `merge`, the `unreachable` arm is a dead sink (UB —
; no basis state enters it, Rule 5), erased with NO merge-phi incoming and NO
; moved body. The whole nest flattens to one predicated select stream.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %sp = icmp sgt i32 %q, 100
  br i1 %sp, label %special, label %quad     ; tainted special-case branch (root)
special:
  %s = mul i32 %q, 2
  br label %merge
quad:
  %m = and i32 %q, 3                         ; a 2-bit pack — exhaustively {0,1,2,3}
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
  unreachable
merge:
  %rm = phi i32 [ %s, %special ], [ %a0, %c0 ], [ %a1, %c1 ], [ %a2, %c2 ], [ %a3, %c3 ]
  %r  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %r
}

; The nest flattens to a 4-select chain: `case 3` is the FALLBACK (its
; ne-conjunction is dead-swept), so only eq/sgt flags appear. Each quad case
; edge is a Toffoli conjunction of the (q<=100) quad-predicate and its case-eq
; flag; the special edge is the bare (q>100) compare. The `unreachable` default
; contributes NO predicate and NO merge incoming — no CFG survives.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl(
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: switch i32
; CHECK-NOT: unreachable
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
