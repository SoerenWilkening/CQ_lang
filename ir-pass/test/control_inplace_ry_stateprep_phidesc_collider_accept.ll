; control_inplace_ry_stateprep_phidesc_collider_accept.ll — ACCEPT.
;
; bd `test_C_libtooling-om35`, OWNER-RULED 2026-09-14: a pinned value in the
; transitive USER closure of the region's OWN state-prep merge phi is NOT an F2
; collider. THE GROUND IS AVAILABILITY, NOT "THE SAME WIRE".
;
; THE MODULE is the N=3 cascade minimised to hand IR — it is
; `tests/e2e/slice_control_cascade_three_bools.c` with the classical scaffolding
; removed. `%6` is the b1 prep's merge phi, seed `i1 false`. The collider F2 used
; to find is
;     %8 = select i1 %6, i32 -1, i32 %2     ; `a` after `if (b1) a -= 3`
;     %9 = icmp sgt i32 %8, 2               ; the THIRD region's own guard
; On the STRAIGHT-THROUGH edge of `br i1 %1`, `f2Model`'s SelectInst arm UNIONS
; the two value operands (it never reads the select's condition), giving
; `%8 = [-1, 2]`, so `%9` is provably `false` — which IS the seed. F2 read that as
; "the author might have written `cq_theta(%9, 0.5)`" and declined.
;
; WHY IT IS NOT A READING OF ANY SOURCE. `%9` USES `%6`. The phi is defined AT THE
; JOIN, so nothing computed from it is available at either slot the F2 question is
; about: not the ARM theta's arg-0 (the phi does not dominate the arm — the arm is
; a PREDECESSOR of the phi's block), and not the phi's own PRED-edge incoming
; (use-before-def). A value that did not exist yet at either slot is not a
; register the author could have rotated.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY, NOT A PREDICTION. MEASURED on the
; frozen 2026-09-14 ORACLE (`cq-opt` sha256 f7b65d8c…, built from 59ac5b7): this
; exact module DECLINES `state prep seed is proven equal to the condition
; register`. On the subject it ACCEPTS with the stream below.
;
; ⚠ ITS BOUNDARY IS A SEPARATE FIXTURE AND THE PAIR IS THE POINT:
; `control_inplace_ry_reject_stateprep_nonphidesc_collider.ll` is THIS module with
; the collider reading `%2` (the CONDITION's own mux) instead of `%8`, i.e. the
; SAME position — the merge block, after the branch — and it still DECLINES, on
; both binaries. "Defined after the branch" is NOT "uses the region's phi", and a
; dominance conjunct (which would flip both, and with them the whole
; `range_forward_*` / `sideways_*` family) stays REFUSED.
;
; ⚠ RETIREMENT TRIGGER (L8): `f2Model`'s `SelectInst` arm is what makes `%9`
; reachable at all, via `unionWith` of the two value operands. If that union ever
; stops being a union — reads the condition, or splits per edge — re-derive the
; availability argument from scratch; this file is where it shows up first.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOF2   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNCNT  < %t.cqd0.ll

define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = select i1 %1, i32 2, i32 5
  br i1 %1, label %5, label %3

3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %8 = select i1 %6, i32 -1, i32 %2
  %9 = icmp sgt i32 %8, 2
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

; b0's rail, then the `a`-mux as the rail-root CNOT-copy merge.
; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[TWO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[TWO]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[FIVE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[FIVE]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; b1's rail: prepped, rotated unconditionally, cancelled under b0 by additivity.
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double -5.000000e-01)
; The `b1`-select copies the `a`-mux rail as its false source.
; CHECK-NEXT: %[[BF2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[BF2]])
; CHECK-NEXT: %[[OUT3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 -1)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[M1]], i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[OUT]], i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; THE THIRD REGION — the guard is minted as a real flag off the merged `a` rail,
; b2 is prepared controlled on it, the flag is stripped by its own `_unc`.
; CHECK-NEXT: %[[HC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT3]], i32 2)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[HC]], i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[HC]], i32 %[[OUT3]], i32 2)
; bd r2j3.32: the guard's strip is %OUT3's last reader, so the `b1`-select rail
; is reversed right there (its core re-emitted in reverse under the same copy
; flag, whose strip is deferred to here) and freed; then the `a`-mux rail
; %OUT, whose last reader was that reversal (LIFO). Since the R11 round-1 fix
; the prep's `cqrt_ry_i1_controlled(b0, b1, -.5)` in %OUT's window is admitted
; as what it is — a CONTROL-slot read of b0, which keeps b0's label — so %OUT
; is no longer left allocated.
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[OUT]], i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[M1]], i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[FIVE]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[TWO]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[HC]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[H2]])

; PURE negatives, whole file, no CHECK-COUNT above them (Rule 12(a): a positive
; CHECK-COUNT inside a negative prefix WINDOWS every negative after it).
; NOF2-NOT: @cq_theta_
; NOF2-NOT: @cq_phi
; NOF2-NOT: @cq_measure_i1(i1
; NOF2-NOT: @cqrt_cswap
; NOF2-NOT: @cqrt_rz
; NOF2-NOT: @cqrt_toffoli

; Counts, each in its OWN whole-file prefix.
; ACNT-COUNT-10: call i32 @cqrt_alloc_
; ACNT-NOT:      call i32 @cqrt_alloc_
; FCNT-COUNT-5:  call void @cqrt_free(
; FCNT-NOT:      call void @cqrt_free(
; XCNT-COUNT-8:  call void @cqrt_x(
; XCNT-NOT:      call void @cqrt_x(
; RYCNT-COUNT-4: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-2:  call void @cqrt_ry_i1_controlled(
; CCNT-NOT:      call void @cqrt_ry_i1_controlled(
; CNCNT-COUNT-4: call void @cqrt_cnot(
; CNCNT-NOT:     call void @cqrt_cnot(
