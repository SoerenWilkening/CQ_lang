; control_inplace_ry_stateprep_mbeta_base_oncone_accept.ll — ACCEPT.
;
; THE ISOLATING CONTROL for the M-beta RAUW-TARGET tripwires (bd
; `test_C_libtooling-om35`, round-2 Rule-13 review §1g). Its DECLINE twin is
; `control_inplace_ry_reject_stateprep_mbeta_base_offcone.ll`, whose header
; carries the full statement of the invariant; read it first. This module is that
; one with region A moved ONTO `%MB`'s cone: `%ta`'s arg-0 and `%MA`'s pred
; incoming both become `%MB`, and the independent rail `%q2` is dropped as it
; then has no reader.
;
; WHY THE PAIR, AND WHY THIS HALF MUST BE AN ACCEPT. The tripwire's decline is
; only evidence if the ACCEPT direction is reachable on the same skeleton — a
; decline fixture whose subject simply cannot accept pins nothing (Rule 12(c)).
; Here `%zm`'s operand chain reaches `%MB` **IN THE SOURCE**, twice over: through
; `%MA`'s pred incoming `[ %MB, %mB ]` and through `%ta = cq_theta(%MB, 0.25)`.
; So the exclusion is licensed by the SOURCE closure and not by anything M-beta's
; RAUW did — which is exactly the distinction the tripwire exists to hold. Move
; the base off the cone and the accept disappears; that is the twin.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. MEASURED: on the frozen 2026-09-14
; ORACLE (`cq-opt` sha256 f7b65d8c…, from 59ac5b7, which has no phi-descendant
; exclusion at all) this exact module DECLINES `state prep seed is proven equal
; to the condition register`. On both the un-narrowed (`147cb3d6…`) and the
; narrowed (`96fdd3a9…`) subject it ACCEPTS with the stream below.
;
; THE STREAM, READ AND NOT COUNTED (Rule 2) — and it is the M-beta chain made
; visible, which is the point of committing an accept here at all:
;   * `%h` is the source rail; the 6.5 classical-call arm is hoisted and
;     route-merged into the fresh `%out1` by 4.4 mechanics.
;   * the ROUND-2 state prep mints `%h5 = cqrt_alloc_i32(0)` and rotates it with
;     `cqrt_ry_i32_controlled(%h_cmp4, %h5, 0.5)`, the flag minted off `%out1`.
;   * REGION A's arm is `cqrt_ry_i32_controlled(%h_cmp3, %h5, 0.25)` — **IN PLACE
;     ON THE SAME `%h5`**. That second controlled Ry chained onto the first IS the
;     M-beta RAUW observable in the stream: `%MA` became `%ta`, whose arg-0 is
;     `%MB`, whose lowering is `%h5`.
;   * `%h5` is FROZEN — never `cqrt_x`-bracketed, never freed, correct because
;     `Ry(θ)|0> != |0>` (Rule 6) — while both compare flags are `_unc`-stripped
;     and freed.
;
; ⚠ RETIREMENT TRIGGER (L8): if this file ever DECLINES, the phi-descendant
; exclusion has stopped seeing a SOURCE closure it must see, and the twin's
; decline has stopped being attributable to cone membership — re-measure the pair
; together before trusting either. If the TWIN ever accepts, see its header:
; that is the F-F1-5 re-opening and this file is not the one that caught it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG   < %t.cqd0.ll

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
  %ta = call i32 @cq_theta_si32(i32 %MB, double 2.500000e-01)
  br label %mA
mA:
  %MA = phi i32 [ %ta, %armA ], [ %MB, %mB ]
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

; The source rail, then the 6.5 arm's route-merge into the round-1 out-rail.
; The CHECK-NEXT chain starts HERE and not at the prep, because a chain that
; starts later cannot see an injection before it — measured by the mutation
; matrix, which MISSED 8 of 12 against a prep-only chain (Rule 12(c)).
; CHECK:      %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK-NEXT: %r = call fastcc i32 @f(i32 4)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
; CHECK-NEXT: %out1 = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %selop = call i32 @cqrt_alloc_i32(i32 %r)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out1)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: %selop2 = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop2, i32 %out1)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
;
; The round-2 state prep mints the fresh rail %h5 ...
; CHECK-NEXT: %h_cmp4 = call i32 @cq_template_icmp_eq_i32_hl(i32 %out1, i32 13)
; CHECK-NEXT: %h5 = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp4, i32 %h5, double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp4, i32 %out1, i32 13)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp4)
;
; ... and REGION A's arm rotates THE SAME %h5 in place. This is M-beta visible in
; the stream: %MA was RAUW'd to %ta, whose arg-0 %MB lowers to %h5.
; CHECK-NEXT: %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp3, i32 %h5, double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %h, i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp3)
;
; CHECK:      %m = call i32 @cqrt_measure_i32(i32 %h)
; CHECK-NEXT: %m8 = call i32 @cqrt_measure_i32(i32 %h5)
;
; Whole-file counts, in their OWN prefixes so they cannot window a negative
; (Rule 12(a)). EXACTLY TWO controlled Ry on one rail — the prep and the arm.
; RYCNT-COUNT-2: call void @cqrt_ry_i32_controlled
; RYCNT-NOT:     call void @cqrt_ry_i32_controlled
; RYCNT-NOT:     call void @cqrt_x(i32 %h5)
;
; SIX frees: three compare flags and three arithmetic temporaries. NOT %h5.
; FCNT-COUNT-6: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; FIVE allocs: %h, %out1, %selop, %selop2, %h5.
; ACNT-COUNT-5: call i32 @cqrt_alloc_i32
; ACNT-NOT:     call i32 @cqrt_alloc_i32
;
; TWO cqrt_x, both the ancilla bracket of the 6.5 route merge.
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; THREE measures, exactly the three the source wrote (Rule 5 — none added).
; MCNT-COUNT-3: call i32 @cqrt_measure_i32
; MCNT-NOT:     call i32 @cqrt_measure_i32
;
; PURE NEGATIVES, in their own prefix so no positive above can window them.
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call void @cqrt_cswap
; NEG-NOT: call void @cqrt_rz
; NEG-NOT: call void @cqrt_toffoli
; NEG-NOT: @cq_theta
; NEG-NOT: @cq_phi
; NEG-NOT: @cq_measure_
