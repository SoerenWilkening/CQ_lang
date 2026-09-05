; control_inplace_ry_stateprep_seed_other_users.ll — ACCEPT: the SEED LITERAL has
; OTHER USERS in the same function (PRD §14.3 row A-26 and §14.5's trap; probe
; `q31`).
;
;     int r = 0; if (q == 5) r = cq_theta(0, .9);
;     int u = cq_theta(0, .25);           // the literal `i32 0` again, AFTER the region
;
; ⚠ THIS FIXTURE IS THE VACUITY PIN FOR R4/R6, AND IT REDDENS IF ANYONE POINTS
; THEM AT THE `Constant`. `railWireClosure` does `Out.insert(W)` BEFORE its taint
; gate, so `railWireClosure(ConstantInt 0, …)` returns `BaseWire = { i32 0 }` —
; and an LLVM `ConstantInt` is uniqued PER `LLVMContext`, so its use list spans
; the whole module. R6 would then enumerate the literal's users, find this second
; `cq_theta` sitting AFTER the region, fail `provablyBefore` on it, and decline
; `stale rail record read past a controlled Ry` on a program with no record at
; all. (Users in OTHER functions are skipped only because
; `DT->isReachableFromEntry` returns false for a foreign block — i.e. by accident
; of a guard written for a different purpose.)
;
; So R4 and R6 are SKIPPED for a state prep, not handed an empty closure, and the
; reason is structural rather than a proof about the program: the rotated rail is
; minted by the hoisted `T` itself, so NO PRE-REGION SSA NAME FOR IT EXISTS.
; There is no wire to intersect with the condition's (R4) and no record that
; could be read after the region (R6).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %u  = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mu = call i32 @cq_measure_si32(i32 %u)
  %s1 = add i32 %mq, %mr
  %s2 = add i32 %s1, %mu
  ret i32 %s2
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the SECOND, unrelated theta on the same literal — an ordinary source mint
; CHECK-NEXT: %[[U:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[U]], double 2.500000e-01)

; ---------------------------------------------------------------------------
; ⚠ THE NEGATIVE ASSERTIONS, REGENERATED 2026-09-05 (round-1 Rule-13 review,
; lens L7 findings F-L7-1 / F-L7-2 — the Inc-3 F-L6-1 recurrence).
;
; A POSITIVE directive inside a prefix WINDOWS every negative one of that prefix:
; FileCheck scans a "not" directive only between the previous and the next
; positive match. The shipped Inc-4 blocks put a positive COUNT of `cqrt_free`
; INSIDE the NOROUTE prefix, so every negative after it stopped scanning at the
; FLAG's free — which is exactly where the uncompute spine emits. MEASURED at
; hand-back: an injected `_controlled_inv` after the free was caught by 0 of 20
; NOROUTE blocks (7 of 20 caught it in NO prefix at all). NOROUTE is therefore
; PURE-NEGATIVE and WHOLE-FILE from here on, and every count lives in the CNT
; (or XCNT) prefix, where a positive directive is the point.
;
; THE HANDLE NAMES BELOW ARE THE LOWERED MODULE'S, DERIVED FROM THE PASS OUTPUT
; RATHER THAN TYPED (F-L7-2: 9 of 20 files named a `%h1` that does not exist in
; their own output, so the M7 assertion they carried was vacuous).

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_
; THE FREEZE, whole-file: no `cqrt_free` may EVER name a PREPPED rail. A
; controlled gate's adjoint needs its CONTROL, and the flag is stripped and freed
; inside the region, so emitting one would be a use-after-free of the flag
; followed by a dirty free of a condition-entangled rail (the measured Inc-1
; defect). The rail is LEFT ALLOCATED — Rule 6's sanctioned fallback.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL (mutation M7 — that fires the
; rotation on BOTH branches, the wrong unitary this whole clause exists to
; avoid). Named by HANDLE AND ANGLE together, because an unconditional
; `cqrt_ry_<W>` on the prepped rail at a DIFFERENT angle is a legitimate
; post-region user (`..._then_uncond_theta.ll` has exactly one).
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-3: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
