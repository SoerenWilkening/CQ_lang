; control_inplace_ry_reject_stateprep_runtime_seed.ll — ⚠ NOW AN ACCEPT (bd
; test_C_libtooling-z0re, OWNER RULING 2026-09-28, option (a); PRD §14.11 Q2 GRANTED,
; bd drbq.14). The file keeps its `_reject_` name DELIBERATELY — the bd gahu
; precedent: a `git mv` can be resurrected by a merge into one module under two
; names with contradictory verdicts (CLAUDE.md L8). Read the verdict off the RUN
; lines, not off the name. RETIREMENT TRIGGER (L8, Rule-13 r1A P3-1): rename to
; `control_inplace_ry_stateprep_runtime_seed_arg.ll` in bd gahu's batch rename
; (the bead lists this file), once no merge that could resurrect the old name is
; pending — and run the duplicate-body scan after it.
;
;     int slice(int seed){ int r = seed; if (q == 5) r = cq_theta(seed, .9); }
;     // probe `p16`, from C
;
; A RUNTIME seed: the merge's Pred incoming and the theta's arg-0 are THE SAME SSA
; VALUE (a classical function argument), so the merge is faithful by SSA identity —
; on the `f=0` component the fresh rail holds the very bits the straight-through
; edge carries. `cqrt_alloc_<W>` takes a runtime value.
;
; WHAT THIS FILE USED TO SAY, AND ITS L8 TRIGGER, which fired exactly as written:
; "a DELIBERATE OVER-DECLINE OF A SHAPE THAT WOULD COST NOTHING TO ACCEPT … on the
; owner's desk (PRD §14.11 Q2) … F1 spelled 'the Pred incoming is the SAME VALUE as
; `T`'s arg-0, and that value is untainted' would pick it up with no new machinery
; and no new frozen symbol." That is what F1 now asks (`isRuntimeStatePrepSeed` +
; the unchanged pointer-identity clause). It cost ONE thing the old text did not
; foresee: an L1 record, because a runtime seed — unlike a literal — can turn
; quantum between F1's round-1 verdict and `lowerRotations`' FINAL-taint `Chained`
; decision (`…_runtime_seed_round2_quantum.ll`).
;
; The old note "the `Constant` spelling is what makes `-0.0` a decline" is not
; retired but re-grounded: for a literal seed the uniquing still does it; for a
; runtime seed SSA identity does the same job (there is no second value to be
; `-0.0` against), which is F1's own comment now.
;
; F2 is asked of the runtime seed as a RELATIONAL question (does the branch
; condition imply a live tainted value equals `%u1`?) — `icmp eq %q, 5` implies
; nothing about `%u1`, so the prep lowers. Stream read gate by gate: the flag is
; minted from `%q`, the fresh rail is `cqrt_alloc_i32(%u1)`, the Ry fires under the
; flag, the flag is stripped and freed, and `%q` is never rotated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %u1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %u1, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; NEG-NOT: cq_theta_
; NEG-NOT: = phi
; NEG-NOT: cqrt_copy

; ACNT-COUNT-2: call i32 @cqrt_alloc_i32(
; ACNT-NOT:     call i32 @cqrt_alloc_i32(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
