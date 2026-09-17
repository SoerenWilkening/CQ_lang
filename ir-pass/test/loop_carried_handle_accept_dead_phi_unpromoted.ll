; loop_carried_handle_accept_dead_phi_unpromoted.ll — bd `test_C_libtooling-h7ee`
; Rule-13 ROUND 2, finding R2-1: a `use_empty()` carried-handle header phi is NOT
; PROMOTED, so no qubit is minted for a value the program does not read.
;
; THE SHAPE.  `%dead` is a header phi that satisfies EVERY conjunct of
; `loopCarriedHandlePhi` — including (Z8), which is vacuous because there are no
; users to walk — and has NO users at all.
;
; WHY THE PROMOTION WAS THE LAST OWNER FOR IT, which is the whole finding.
; `declineClassicalMuxes` opens with its own `if (Phi->use_empty()) continue;`,
; so a dead tainted phi is never refused there.  Every OTHER unpromoted phi
; declines one stage later and the promotion is decline-SAFE because of it (D2);
; for THIS phi there was no later owner, and the promotion MUTATED: a
; `cqrt_alloc_<W>(seed)` qubit and a trace line for a dead value, renumbering
; every downstream handle.
;
; ⚠ IT IS A MUTATION-AVOIDANCE CLAUSE, NOT A FENCE, AND NO UNITARY WAS EVER
; WRONG.  An `alloc` is neither a measurement nor a non-diagonal gate, and Rule 6
; already accepts a left-allocated rail — which is exactly why round 2 filed it
; P3 and why this file is an ACCEPT with a negative, not a decline.
;
; ⚠ IR-LEVEL ONLY, STATED RATHER THAN IMPLIED (the bd `hrts` caveat, CLAUDE.md
; §5).  `clang -O1` deletes a dead phi, so NO C spelling reaches this shape.  An
; IR-level result is not a C-level one.
;
; ⚠ THE NEGATIVE IS IN ITS OWN WHOLE-FILE PREFIX ON PURPOSE (Rule 12 hygiene
; defect (a)): a `CHECK-NOT` interleaved with positives is WINDOWED by them and
; an injected `cqrt_alloc` outside the window is caught by nothing.  `NOMINT` runs
; over the whole file with no positive to window it.
;
; ⚠ NON-VACUITY, MEASURED, AND THE TWO PREFIXES ARE NOT EQUALLY LOAD-BEARING.
; Run against the ORACLE `cq-opt` `e7bbfd69a9e25d38…` (the pre-(P0) binary):
;     CHECK  prefix -> PASSES   (vacuous w.r.t. this finding: the real lowering
;                                is unchanged by (P0), which is the point)
;     NOMINT prefix -> FAILS    (the oracle mints `%cq.carried` for the dead phi)
; So the FINDING is pinned by `NOMINT` ALONE.  Said out loud because a green
; fixture whose green half proves nothing is how Rule 12's hygiene defects ship.
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves when clause (P0) or
; `declineClassicalMuxes`' own `use_empty()` skip changes.  RE-DERIVE it then; do
; not delete it, and do not predict the string it lands on.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d0.ll
; RUN: %filecheck %s < %t.d0.ll
; RUN: %filecheck --check-prefix=NOMINT %s < %t.d0.ll

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %dead = phi i32 [ 5, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %sub = add nsw i32 %q, -3
  %anext = select i1 %b, i32 %sub, i32 %q
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %anext)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; The module still LOWERS — the dead phi changes nothing about the real work.
; CHECK: call i32 @cqrt_alloc_i1
; CHECK: call void @cqrt_ry_i1
; CHECK: %out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled
; CHECK: call i32 @cqrt_measure_i32(i32 %out)

; THE FINDING, pinned: no trip-1 register is minted for the dead phi. `cq.carried`
; is the promotion's ONLY name for the value it materialises, so its absence is
; the whole property.
; NOMINT-NOT: cq.carried
