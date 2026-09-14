; control_inplace_ry_reject_stateprep_mbeta_base_offcone.ll — DECLINE (F2).
;
; ⚠ THIS FILE IS A **TRIPWIRE FOR AN EMITTER INVARIANT IN ANOTHER FILE**, not a
; test of the shape it looks like. It is one of only two anywhere (its sibling is
; `control_inplace_ry_reject_stateprep_mbeta_ifelse_rechain.ll`), and it exists
; because the invariant had NO fixture at all until the round-2 Rule-13 review of
; bd `test_C_libtooling-om35` (finding F-F1-5 / F-F2-1).
;
; THE INVARIANT. `ArmClassify.cpp`'s F2 conjunct `!PhiDesc.count(V)` excludes the
; transitive SSA USER closure of a state-prep region's OWN merge phi, on the
; AVAILABILITY ground. Detection runs TWICE (`repropagateControlMerges`), so the
; round-2 call reads a user graph round 1's EMITTERS have already rewritten — the
; L1 PREDICATE species. What keeps the round-2 set sound is a property of the
; emitters: **every merge-phi RAUW in the tree targets either a fresh
; `cqrt_alloc` whose only operand is a constant (the closure SHRINKS) or one of
; the phi's own INCOMINGS, or a descendant of one.** For M-beta
; (`SwapRouteEmit.cpp:1105`, target `Gates.back().first`) that holds because
; `inPlaceRotationArmTheta` (`ArmClassify.cpp:823`,
; `!T->hasOneUse() || T->user_back() != MergePhi`) admits an arm theta ONLY when
; the merge phi is its SOLE USER — so `X ->* T  =>  X ->* M  =>  X ->* users(M)`
; ALREADY held before the RAUW, and no other region's closure can grow.
;
; WHAT THIS MODULE IS. Three regions, in source order:
;   * region C — a 6.5 classical-call arm producing `%out`, CLASSICAL in round 1;
;   * region B — `icmp eq i32 %out, 13`, a STATE PREP with seed `i32 0`,
;     therefore detected and classified ONLY in ROUND 2, after the re-seed;
;   * region A — an in-place controlled Ry whose base is `%q2`, a rail that is
;     **OFF `%MB`'s cone**. Region A is emitted in round 1 and its merge phi
;     `%MA` IS RAUW'd by M-beta.
; The collider `%zm = trunc (mul (add (zext %out), -13), (zext %MA))` is a user of
; that RAUW'd phi, and folds to `{0}` == the seed on region B's TRUE edge. The
; i64 hop is deliberate: it keeps the pinned intermediate off the TEST's
; `V->getType() == Seed->getType()` clause, so the value that reaches the test is
; `%zm` and not `%dd` (two earlier attempts were VACUOUS for exactly that reason).
;
; WHAT WOULD MAKE IT GO GREEN — i.e. what it detects. `%zm`'s operand chain does
; NOT reach `%MB` in the source (region A's base is `%q2`), so `%zm` is not in
; `PhiDesc(%MB)`, is not excluded, is a collider, and F2 fires. **If M-beta's RAUW
; ever retargets `%MA` to something `%MB` can reach — or if `:823`'s `hasOneUse`
; is relaxed so the arm theta stops being sole-used by the merge phi — `%zm`
; becomes a manufactured `%MB`-descendant, gets excluded, and THIS FILE ACCEPTS.**
; That accept is the re-opening of F-F1-5 and it is what this file is here to
; catch. Do not delete it; re-derive `collectStatePrepPhiDescendants`' header
; argument from scratch, and re-read `SwapRouteEmit.cpp`'s pointer beside the
; RAUW, which names this file by name.
;
; ITS ISOLATING CONTROL IS AN **ACCEPT**:
; `control_inplace_ry_stateprep_mbeta_base_oncone_accept.ll` is this module with
; region A moved ONTO `%MB`'s cone — `%ta`'s arg-0 and `%MA`'s pred incoming both
; become `%MB`, and the independent rail `%q2` is dropped as it then has no
; reader — and it ACCEPTS, because there `%zm`'s chain reaches `%MB` in the
; SOURCE twice over (through `%MA`'s pred incoming AND through `%ta`'s base), so
; the exclusion is licensed by the source closure and not by any RAUW. The pair
; is what makes this file's decline attributable to CONE MEMBERSHIP and not to
; anything incidental about the three-region skeleton. Measured on all three
; binaries of the increment
; (ORACLE `f7b65d8c…`, un-narrowed `147cb3d6…`, subject `96fdd3a9…`): this file
; DECLINES on all three, the on-cone twin ACCEPTS on the latter two.
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}
define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 0, double 7.500000e-01)
  %c1 = icmp eq i32 %q, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %m1 ]
  %c3 = icmp eq i32 %q, 7
  br i1 %c3, label %armA, label %mA
armA:
  %ta = call i32 @cq_theta_si32(i32 %q2, double 2.500000e-01)
  br label %mA
mA:
  %MA = phi i32 [ %ta, %armA ], [ %q2, %mB ]
  %dz = zext i32 %out to i64
  %dd = add i64 %dz, -13
  %mz = zext i32 %MA to i64
  %pm = mul i64 %dd, %mz
  %zm = trunc i64 %pm to i32
  %x0 = call i32 @cq_measure_si32(i32 %q)
  %x1 = call i32 @cq_measure_si32(i32 %MA)
  %x2 = call i32 @cq_measure_si32(i32 %zm)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; CHECK-NOT: cqrt_alloc_i32
