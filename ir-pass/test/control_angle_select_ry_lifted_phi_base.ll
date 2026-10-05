; control_angle_select_ry_lifted_phi_base.ll — ACCEPT: the rotated base IS a
; one-register CLASSICAL join phi (bd drbq Inc 2b; the accept CONTROL for
; Inc-1 finding K's launder).
;
;     int m; if (cc) m = r; else m = r;      // classical cc
;     cq_theta(&m, q == 5 ? .9 : .3);
;
; `%m` is a phi over TWO SSA names of ONE physical rail, which
; `liftOneRegisterMergePhi` later RAUWs to the base. The rail-wire closure
; crosses phi/select/freeze FORWARD from a tainted member precisely so that a
; consumer hiding one hop behind such a phi is enumerated (finding K: `cq_measure`,
; `ret`, a tape write, a clone argument and a `cq_invert` bracket all read the
; POST-Ry register through exactly this launder, and Inc 1 shipped the hole).
;
; THIS FIXTURE IS THE OTHER DIRECTION — the phi is the BASE, not a stale record —
; and it must keep ACCEPTING. Its five decline siblings are
; `control_angle_select_reject_lifted_phi_{measure,ret,tape,clone_arg,invert}.ll`;
; read the six together, because a fence that declined this one would be an
; over-decline nobody would notice.
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %cc = icmp eq i32 %c, 0
  br i1 %cc, label %join, label %alias
alias:
  br label %join
join:
  %m = phi i32 [ %r, %alias ], [ %r, %entry ]
  %t = icmp eq i32 %q, 5
  %ang = select i1 %t, double 9.000000e-01, double 3.000000e-01
  %rt = call i32 @cq_theta_si32(i32 %m, double %ang)
  %b = call i32 @cq_measure_si32(i32 %rt)
  ret i32 %b
}

; the classical diamond SURVIVES (it is not a quantum region — nothing flattens
; it), and the whole 2b stream lands in the join block on the ONE rail the phi
; denotes.
; THE CONDITION REGISTER, ANCHORED AT ITS OWN ALLOC and never on a line of the
; stream under test (round-2 Rule-13 review, lens R2 N1 — see the note at the mint
; below for what stayed green without this).
; CHECK:      %[[QC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QC]], double 5.000000e-01)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
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
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: select
; the one-register phi is LIFTED, not left as a quantum mux
; NOROUTE-NOT: phi i32

; EXACTLY ONE flag mint. This fixture is the ONE shape in the family where a
; surviving dead tainted compare is a SILENT leak rather than a loud one (round-1
; Rule-13 review, lens L5-6): with the emitter's step-6 compare erase removed,
; every other angle-select fixture dies loudly in `Uncomputation` with
; `dead chain would free a measured register`, but this one exits 0 with a SECOND
; never-stripped, condition-entangled `cq_template_icmp_eq_i32_hl` rail — strict
; stage 2b passes and FileCheck was green. This count is what closes that cell.
; CNT-COUNT-1: cq_template_icmp_eq_i32_hl(
; CNT-NOT:     cq_template_icmp_eq_i32_hl(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
