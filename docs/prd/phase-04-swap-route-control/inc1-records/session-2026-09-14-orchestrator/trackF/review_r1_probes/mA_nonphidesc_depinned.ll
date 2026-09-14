; control_inplace_ry_reject_stateprep_nonphidesc_collider.ll — DECLINE (F2), and
; it is THE BOUNDARY MARKER for the 2026-09-14 phi-descendant narrowing
; (bd `test_C_libtooling-om35`).
;
; THIS FILE IS HALF OF A PAIR. Its twin is
; `control_inplace_ry_stateprep_phidesc_collider_accept.ll`, which is THIS module
; with ONE operand changed: there the merge-block collider reads the region's own
; merge phi `%6`, here it reads `%2` — the CONDITION's own mux. Everything else is
; identical: same seed, same region, same block, same predicate, same constant,
; and in particular the collider is in the MERGE BLOCK, i.e. defined AFTER the
; branch, in BOTH files.
;
; WHY THE PAIR EXISTS. The narrowing excludes a collider that USES the region's
; merge phi, on the AVAILABILITY ground: such a value is at neither slot the F2
; question is about. It does NOT exclude a collider merely because of WHERE it
; sits. A dominance/position conjunct — "a collider must dominate the arm" — was
; REFUSED IN WRITING (`SCOPE_R.md` §3a), because >=11 shipped F2 fixtures pin
; MERGE-BLOCK colliders: the whole `range_forward_*` family, `sideways_offset`,
; `sideways_sdiv`, `merge_edge_sideways`, `offwire_sideways_min`, `step_cap_over`.
; Measured 2026-09-14 over the F2 corpus: `collider-uses-phi` is FALSE for 32 of
; 32 fixtures, and TRUE for all three customer programs. This file is the fixture
; that goes RED the day someone "simplifies" the conjunct into a position test.
;
; THE MODULE. `%2 = select i1 %1, i32 2, i32 5` is `a` after the FIRST region;
; `%1` is the b0 rail and the second region's condition. On the TRUE (straight-
; through) edge `%1 = {1}`, so `%2 = {2}` and `%9 = icmp sgt i32 %2, 1` is
; provably `false` — the seed. `%9` does not use `%6`, so it stays a collider and
; the region stays declined. The rival it protects against is real and writable:
; `_Bool g = (a >= 3); ... b1 = cq_theta(g, 0.5);` with `g` computed BEFORE the
; region, which is a different unitary (an in-place Ry on `g`'s rail).
;
; MEASURED on BOTH binaries — the frozen 2026-09-14 ORACLE (`cq-opt` sha256
; f7b65d8c…, from 59ac5b7) and the subject: DECLINE, same string, same anchor.
; The narrowing moved it by nothing.
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;

define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = select i1 %1, i32 2, i32 5
  br i1 %1, label %5, label %3

3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %9 = icmp sgt i32 %2, 1
  br i1 %9, label %10, label %12

10:
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %12

12:
  %13 = phi i1 [ %11, %10 ], [ false, %5 ]
  %m1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %m6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %m9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  %z1 = zext i1 %m1 to i32
  %z6 = zext i1 %m6 to i32
  %z9 = zext i1 %m9 to i32
  %a1 = add nsw i32 %z1, %z6
  %a2 = add nsw i32 %a1, %z9
  ret i32 %a2
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 zeroext)

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled
; CHECK-NOT: cqrt_alloc_i1
