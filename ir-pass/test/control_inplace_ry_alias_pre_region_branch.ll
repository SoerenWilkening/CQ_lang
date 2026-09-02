; control_inplace_ry_alias_pre_region_branch.ll — ACCEPT spec: a diagonal alias
; hop on a CLASSICALLY-BRANCHED path that cannot follow the region (bd
; test_C_libtooling-drbq Inc 1, finding J — and the one shape this fix ACCEPTS
; that Inc 1 declined, pinned deliberately rather than left invisible).
;
;     if (opaque) cq_phi(r, .1);          // a real Rz, conditionally, BEFORE
;     if (q > 5)  r = cq_theta(r, .9);    // the controlled Ry
;     use(cq_measure(r));
;
; R6 asks a POSITION question about a read: can it observe the register AFTER the
; controlled Ry relabels it? Inc 1 answered with `provablyBefore`, which is that
; question (`BI` cannot reach `U`) AND a second one it never needed (`U` dominates
; `BI` — "did U definitely execute"). With the fence ranging over the rail's ALIAS
; CLOSURE the extra conjunct became WRONG-STRONG: `control_inplace_ry_sequential`'s
; region 2 has region 1's ARM THETA as a member's user, and an arm block dominates
; nothing. So an alias HOP now owes only `cannotFollowGate`; every other user keeps
; `provablyBefore` verbatim (two sets, two questions — bd 8h7d.5 round 3).
;
; The emitted order is what makes it sound, and the CHECKs below pin it: the `rz`
; stays in its own conditionally-executed block, the controlled Ry is hoisted into
; the region's pred, and the source's order (hop THEN gate) survives. Swap the
; alias to a POST-region read and it declines again —
; ..._reject_stale_diag_alias_forward.ll is that fixture.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i1 %opaque) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %opaque, label %side, label %join
side:
  %mark = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  br label %join
join:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %join ]
  %b  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %b
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; the hop lowers in its OWN conditionally-executed block, ahead of the region
; CHECK:      side:
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[R]], double 1.000000e-01)
; CHECK:      join:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
