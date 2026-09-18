; control_predmux_accept_rail_leaf_dead_rail_survives.ll — ACCEPT, AND THE MOST
; IMPORTANT FIXTURE THIS INCREMENT SHIPS (bd test_C_libtooling-fn1q increment 2,
; Rule-13 round 1 finding P1-1).
;
; THE DEFECT IT PINS WAS A VANISHING USER GATE. `PredMuxFlatten` tracks the values
; it replaces in `MaybeDead` and `sweepDead` erases anything `use_empty()`. Until
; increment 2 that could never reach a CQ front-end intrinsic, because the E6
; grammar admitted no `CallInst` at all — the containment was STRUCTURAL. The rail
; leaf makes a `@cq_theta_i1` call a condition-tree node, and THREE sites then put
; it into the sweep: `run()`'s `track(BI->getCondition())` (both polarities),
; `buildNegation`'s `track(V)` (false polarity) and `canonicalizePred`'s
; `trackCondCone` (true polarity).
;
; MEASURED before the fix, on this exact module: `opt` exited **0 with 0 bytes of
; stderr**, and the lowered stream contained **NO `cqrt_alloc_i1` and NO
; `cqrt_ry_i1`** — the user's rotation deleted outright (Rule 5: the compiler
; never removes a gate the user wrote any more than it inserts one). The ORACLE
; declined loudly. `opt -verify` was clean and `free_pairing_check.py` reported
; `0 violation(s), 0 unproven`, because it is structurally blind to a rail that no
; longer exists — no gate in the tree could have seen this.
;
; ⚠ THE PROJECT HAD ALREADY RULED ON THE QUESTION, IN THE SIBLING STAGE, AND THE
; RULING WAS NOT CARRIED ACROSS. `RegionFlatten.cpp`'s teardown reads
;     if (Cond && Cond->use_empty() && !isCondRailLeaf(Cond) && !isCondRailPhiShape(Cond))
; with the decision written out (bd 3qlq.4): "a RAIL-LEAF condition is the USER'S
; `cq_theta_i1` — never this stage's to erase, WHATEVER ITS USE COUNT."
; `PredMuxFlatten::sweepDead` had no such conjunct. The fix mirrors it AT THE
; SINGLE ERASER rather than at the three `track()` sites, because a per-site fence
; is only as complete as its most-forgotten site.
;
; ⚠ WHY THE SHAPE IS NOT CONTRIVED, stated honestly. Two merge phis whose every
; incoming is `i1 false` make the BoolAlg composer drop every term, so nothing
; references the edge predicates and the rail's last use — the branch — is erased
; by the flatten. The arm is on the FALSE successor so `buildNegation` runs too.
; It is hand-written IR and NO -O1 C REPRODUCER WAS PRODUCED: two attempts failed
; for opposite reasons (the rail stays live because the selects use it; or clang
; folds the region away before the pass sees a `br`). Read that as "IR-level,
; reachability from C neither shown nor disproved" — hand-written .ll is this
; tree's primary fixture surface, which is exactly why the (K5) hole mattered too.
;
; THE CORRECT ANSWER, and the control that says so: the rail lowers to its forward
; Ry, its adjoint and a proven-|0> free — BYTE-FOR-BYTE what the same dead
; `cq_theta_i1` gets with no region at all, on BOTH binaries. The deletion was
; never a general dead-code policy; it was this sweep reaching a value it does not
; own.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NRY < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOTOUCH < %t.cqd0.ll
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}

; THE USER'S RAIL IS STILL THERE: allocated, rotated, un-rotated, freed at |0>.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[R]], double 5.000000e-01)
; CHECK:     call void @cqrt_ry_i1(i32 %[[R]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[R]])

; ⚠ EXACTLY TWO `cqrt_ry_i1` — the forward gate and its adjoint, no more and no
; fewer. A count with a closing whole-file negative, so this is "exactly 2" and not
; "at least 2" (Rule-13 round 1, P3-1: an injected extra gate after the last
; positive match is MISSED by an open-ended count).
; NRY-COUNT-2: call void @cqrt_ry_i1(
; NRY-NOT:     call void @cqrt_ry_i1(

; ⚠ AND NOTHING ELSE TOUCHES THE RAIL. This module emits NO `cqrt_x` and NO
; `cqrt_rz_i1` AT ALL, so a whole-file negative is exact and total here — stronger
; than the anchored form its sibling fixtures need. Rule-13 round 2 (P3-1)
; measured BOTH of these injections MISSED by the earlier prefix set: a stray
; bracket or a stray phase gate on the user's register is the Rule-7 class, and a
; closed count over the ROTATIONS alone cannot see either of them.
;
; ⚠ AND A HYGIENE TRAP THIS FILE WALKED INTO WHILE BEING WRITTEN: naming a
; directive in PROSE CREATES ONE. The sentence above originally spelled the
; rotation count's directive literally, inside backticks, and FileCheck parsed it
; as a directive with an invalid count and failed the fixture. Refer to a directive
; by description, never by its literal token, anywhere in a check file.
; NOTOUCH-NOT: call void @cqrt_x(
; NOTOUCH-NOT: call void @cqrt_rz_i1(
