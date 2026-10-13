; control_angle_select_ry_then_region.ll — ACCEPT: an angle-select gate FOLLOWED
; by an Inc-1 in-place rotation DIAMOND on the SAME register (bd drbq Inc 2b).
;
;     cq_theta(&r, q == 5 ? .9 : .3);      // 2b angle select (dm7f.6 stream)
;     if (q == 6) cq_theta(&r, .8);        // Inc 1, in place
;
; A COMPOSITION FIXTURE, and the thing it actually probes is EMISSION ORDER, not
; the two lowerings separately. Both regions are pushed by ONE
; `detectControlRegions` sweep (the branch first, from the terminator dispatch;
; the angle select second, from the same block's instruction scan), and
; `lowerControlRegions` emits them in that plan order — so the DIAMOND is emitted
; BEFORE the angle select even though its gate comes second in the source.
;
; The emitted stream is still in SOURCE order, because each emitter inserts
; POSITIONALLY (the angle select's stream lands immediately before its consumer,
; which precedes the branch). That is the same invariant the bd `hcrg` sequential
; Kahn ordering rests on, exercised here across two DIFFERENT region kinds.
;
; It also pins that the angle select's re-validation survives an earlier
; emitter's mutation: by the time this region emits, the diamond has been
; FLATTENED (its arm and merge blocks erased, its merge phi RAUW'd), and every
; identity this emitter re-checks — the consumer, its angle operand, the sole
; use, the compare — is still live.
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %c2 = icmp eq i32 %q, 6
  br i1 %c2, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %t, double 8.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %t, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; SOURCE ORDER SURVIVES A REVERSED EMISSION ORDER — the 2b stream first, the
; diamond's second, as an adjacency chain.
;
; ⚠ THE ORDER OF `%c2` AND `%t` IN THE SOURCE ABOVE IS LOAD-BEARING, AND THE
; REVERSE DECLINES (round-1 Rule-13 review, lens L1-4). `%c2` — the FOLLOWING
; diamond's compare — is written AFTER the angle select's consumer `%t`. Write it
; BEFORE and the module declines `condition predates a non-diagonal gate`: the
; diamond's own positional prong (`ArmClassify`'s gate 2c reading) scans
; `[c2, br)` for a tainted `cq_theta`, and `%t` is one. That is an OVER-DECLINE
; and it is PRE-EXISTING — the pre-2b binary refuses the same reordering, and it
; refuses it for the diamond, not for anything 2b added — but it means this
; fixture pins ONE of the two source orders, and a reader must not conclude from
; it that composition is order-free. It is not; it is recorded as a follow-on.
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the CONDITION REGISTER, bound ONCE so the mint and the strip must name the
; SAME rail (round-1 Rule-13 review, L6-N3: with both spelled `%{{...}}` a strip
; on the WRONG register stayed green — the flag would then not return to |0> and
; its `cqrt_free` would be a hidden measurement, Rule 6).
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[QC:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; the SECOND region reads the SAME condition register — pinning `%[[QC]]` here
; rather than a wildcard is what makes "both regions control off one rail" an
; assertion instead of a comment.
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[QC]], i32 6)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R]], double 8.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[QC]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; the diamond is FLATTENED and neither region routed anything
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: select
; NOROUTE-NOT: br i1

; two flags, two frees, and the register (frozen) is not freed
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
