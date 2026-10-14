; spec_accept_phantom_arg_read_classical_slot.ll — ACCEPT (bd test_C_libtooling-vsfp ROUND 2,
; subject changed in round 3 — the resolution declines QUANTUM operands only; hand IR).
;
; `@h` reads `a` and `b` only through one empty diamond: both are live in `@h`, both dead
; in its clone, and both slots are neutralised (`h(0, 0, m)`). Slot 0 held `q` (a
; `cq_theta` result — exempt), slot 1 `m * 5`, a CLASSICAL value that no rail represents:
; nothing to decline (mutant B4, which drops the "quantum" conjunct, declines).
; ⚠ ROUND 3 (bd tzfa; Rule-13 r2B F-WB-1). A slot the specializer RECORDED dead is now
; NEUTRALISED after `specialize()` (`resolvePhantomCloneArgReads`: the argument becomes `0`,
; the drop's rewrite), so the uncompute spine, M-C, M-A and stage 2b see the hand-inlined
; twin's consumer set. Round 2 instead ACCEPTED a phantom read whose operand had another
; reader and left the read in place — one consumer too many for the spine.
;
;
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_001(i32 0, i32 0, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; @h reads `a` and `b` only through ONE empty diamond on `(a > 3) & (b > 5)`: both are
; live in @h (a branch condition is a liveness root), so the dead-argument drop does
; not touch them; the CLONE's flatten removes the diamond and the specializer records
; BOTH slots dead. Slot 0 receives a `cq_theta` result (the backstop's exemption),
; slot 1 a CLASSICAL value — which the backstop must not decline: only a QUANTUM value
; kept alive by a phantom read is a hazard.
define i32 @h(i32 %a, i32 %b, i32 %k) {
entry:
  %c1 = icmp sgt i32 %a, 3
  %c2 = icmp sgt i32 %b, 5
  %c = and i1 %c1, %c2
  br i1 %c, label %t, label %e
t:
  br label %e
e:
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %kk = mul i32 %m, 5
  %t = call i32 @h(i32 %q, i32 %kk, i32 %m)
  %z = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %z, %t
  %cq.main.m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %cq.main.m
}
