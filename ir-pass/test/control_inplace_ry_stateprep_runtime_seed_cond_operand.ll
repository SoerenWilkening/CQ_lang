; control_inplace_ry_stateprep_runtime_seed_cond_operand.ll — ACCEPT (bd
; test_C_libtooling-z0re, owner ruling 2026-09-28 option (a)): a RUNTIME state-prep
; seed that is ALSO the classical operand of the region's own condition.
;
;     int s = atoi(v[2]); int r = s; if (q == s) r = cq_theta(s, .2);   // probe e01
;
; This is the fixture the RELATIONAL half of F2 (the runtime-seed branch of
; `f2SeedPinnedByLiveRegister`) turns on. On the TRUE edge the branch condition
; `icmp eq %q, %s` IMPLIES `%q == %s` — `isImpliedCondition` answers TRUE — so a
; live tainted value IS provably equal to the seed on an edge. It is `%q`, the
; compare's own operand, hence a member of `CondWire`, and the owner's 2026-09-11
; ruling (the α trade, bd drbq.14) excludes exactly that set at the TEST. The
; accept therefore rests on the exclusion, and that is what this file pins:
; a mutant that drops `excludedAtTest` from the relational test DECLINES it
; (`state prep seed is proven equal to the condition register`), measured in
; TRACK_Z0RE.md §8.4 (M2).
; ⚠ CORRECTED (Rule-13 r1A F-r1A-3, L7): the first spelling of this header
; concluded "so the relational half is LIVE". That mutant measures the EXCLUSION,
; not the relational half. With the exclusion in place the relational half is
; FULLY MASKED by CondWire for every condition that reaches a state prep today,
; so deleting it is an equivalent mutant on every reachable input and NO fixture
; — this one included — can pin it. See F2's runtime-seed header in
; ArmClassify.cpp for why, and for the retirement triggers that make it pinnable.
;
; The rival that would make the mask matter — `if (q == s) r = cq_theta(q, .2)`,
; an in-place Ry on the CONDITION register — does NOT fold to this module at -O1
; (probe e02 keeps `%q` as arg-0: no GVN/NewGVN/JumpThreading/CVP in the -O1
; pipeline, and IPSCCP substitutes only constants) and declines `condition
; predates a non-diagonal gate` on both binaries.
;
; On the ORACLE (main 9a230646) this module DECLINES at F1's literal-only clause
; (`state prep seed does not match the merge incoming`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, %s
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %s, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %sum = add i32 %mq, %mr
  ret i32 %sum
}

; The flag is a Q+C compare against the RUNTIME `%s` (an `_hl` literal slot that
; carries a run-time value), the fresh rail is seeded by that same `%s`, and the
; condition register `%q` is never rotated.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 %s)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %s)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 %s)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

; No surviving intrinsic, no merge phi. (The condition register is never rotated
; in place: RYCNT pins exactly ONE uncontrolled Ry, the one on `%q`.)
; NEG-NOT: cq_theta_
; NEG-NOT: = phi

; ACNT-COUNT-2: call i32 @cqrt_alloc_i32(
; ACNT-NOT:     call i32 @cqrt_alloc_i32(

; RYCNT-COUNT-1: call void @cqrt_ry_i32(
; RYCNT-NOT:     call void @cqrt_ry_i32(
