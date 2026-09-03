; control_angle_select_rz_dead_chain.ll — ACCEPT: the Rz stem over a DERIVED base
; whose chain is dead afterwards (bd drbq Inc 2b; the §12.1 transparency
; witness, in the select form).
;
;     int p = cq_theta(u1,.3); int r = p * 5;
;     r = cq_phi(r, q == 5 ? .9 : .3);       // r never read again
;     return cq_measure(q);
;
; WHAT IT PINS, and it is a NEGATIVE-SPACE fact worth stating precisely because
; the obvious expectation is wrong. PRD §12.1 splits the two stems: a
; `cqrt_rz_<W>_controlled` is NOT a DAG link, gets NO adjoint, and is NOT frozen,
; because a diagonal gate moves no basis label. One might therefore expect the
; dead `mul` chain to be uncomputed and freed here. It is NOT — and the emitted
; stream is BYTE-IDENTICAL to the drbq Inc-2a in-place Rz DIAMOND over the same
; dead chain (measured, hand-IR twin). So 2b inherits 2a's disposition exactly
; and moves nothing.
;
; The contrast that makes it legible: the wholly UNCONTROLLED twin
; (`r = cq_phi(r,.3); r = cq_phi(r,.6);`, no condition at all) DOES cancel its
; rotations, uncompute the `mul` and free both rails. That difference is bd
; `wt3l`'s open cancel/leak/keep question about a user Rz on a possibly-dead
; rail; this increment does not touch it in either direction, and this fixture
; exists so a future reader sees which side of it the angle select lands on.
;
; (The C-source manual by-difference twin of THIS shape declines for an unrelated
; pre-existing reason — with `r` dead, `clang -O1` leaves the diamond with no
; merge phi and `recoverRegion` refuses it. The hand-IR 2a diamond, which keeps
; the phi, is the twin that matches byte for byte.)
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %r = mul i32 %p, 5
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_phi_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE CONDITION REGISTER, ANCHORED AT ITS OWN ALLOC and never on a line of the
; stream under test (round-2 Rule-13 review, lens R2 N1 — see the note at the mint
; below for what stayed green without this).
; CHECK:      %[[QC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QC]], double 5.000000e-01)
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 3.000000e-01)
; CHECK-NEXT: %[[RB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[RB]], double 3.000000e-01)
; the CONDITION REGISTER: `%[[QC]]` was ANCHORED above at its own `cqrt_alloc`,
; so the mint and the strip must both name THAT rail — not merely the same one as
; each other (round-1 Rule-13 review L6-N3 closed mint-vs-strip DISAGREEMENT; the
; round-2 one, lens R2 N1, found that a CONSISTENTLY wrong condition rail — both
; lines rewritten to read the ROTATED register — still passed, because `%[[QC]]`
; was first bound HERE, on a line of the stream under test. On the Ry stem that
; mutant is also a Rule-6 hazard: the controlled Ry between mint and strip
; relabels the very rail being compared, so the strip does not recompute the
; predicate the mint read, the flag does not return to |0> and its `cqrt_free` is
; a hidden measurement).
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[RB]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; the dead chain is LEFT ALLOCATED — no negated-angle cancellation, no mul
; adjoint, no rail free (identical to the 2a in-place Rz diamond over this shape)
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: cq_template_mul_i32_hl_unc
; NOROUTE-NOT: double -3.000000e-01
; NOROUTE-NOT: call void @cqrt_cswap
; no polarity bracket: a select always means "A when the flag is 1"
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: select

; ONE free: the flag.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
