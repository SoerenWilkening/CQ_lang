; control_angle_select_ry_alias_pre_gate.ll — ACCEPT: a diagonal ALIAS of the
; rotated register, READ BEFORE the gate (bd drbq Inc 2b; the accept control for
; the S9 stale-record fence).
;
;     int mark = cq_phi(r,.1); int mm = cq_measure(mark);   // BEFORE
;     cq_theta(&r, q == 5 ? .9 : .3);
;
; `%mark` is a second SSA name for `r`'s physical rail (Rz is diagonal and always
; lowers in place), so it IS a member of the base's rail closure and S9
; enumerates its users. Reading it here is fine — `cq_measure(mark)` is provably
; BEFORE the controlled Ry, so the source's record and the register agree at the
; point of the read.
;
; Move that same measurement AFTER the gate and it becomes the wrong-VALUE class
; the whole fence exists for: see
; `control_angle_select_reject_stale_measure.ll`, which is this IR with
; the `cq_measure` relocated and nothing else changed. Read the two together.
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

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %r)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %m, %mm
  ret i32 %s
}

; THE CONDITION REGISTER, ANCHORED AT ITS OWN ALLOC and never on a line of the
; stream under test (round-2 Rule-13 review, lens R2 N1 — see the note at the mint
; below for what stayed green without this).
; CHECK:      %[[QC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QC]], double 5.000000e-01)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the alias and its read, BOTH before the gate
; CHECK-NEXT: %[[MM:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
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
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
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

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
