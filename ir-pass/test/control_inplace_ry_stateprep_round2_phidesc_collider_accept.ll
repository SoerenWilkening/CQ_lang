; control_inplace_ry_stateprep_round2_phidesc_collider_accept.ll — ACCEPT.
;
; THE ROUND-2 REACHABILITY WITNESS for the phi-descendant conjunct (bd
; `test_C_libtooling-om35`, round-2 Rule-13 review §1b). Its isolating control is
; `control_inplace_ry_reject_stateprep_round2_nonphidesc_collider.ll`, which is
; THIS module with ONE OPERAND changed — there `%mz = zext i32 %q to i64` reads
; the source rail, here `%mz = zext i32 %MB to i64` reads the region's own
; state-prep merge phi. Nothing else differs. That header carries the full
; statement of what the pair is for; read it with this one.
;
; WHY THE PAIR EXISTS. `detectControlRegions` + `lowerControlRegions` run TWICE
; (`repropagateControlMerges`), so F2's phi-descendant conjunct is recomputed in
; round 2 over a user graph round 1's EMITTERS have rewritten — the L1 PREDICATE
; species, and the species that produced bd `9pum` / `r9e5` F-B1R2-1 and bd
; `b6ap` F-B6-1. The argument that the round-2 set is still sound (it is a
; property of the EMITTERS' RAUW targets; see
; `collectStatePrepPhiDescendants`' header) is only worth making if the round-2
; call happens at all. **This pair is the only thing in the tree that pins that
; it does.**
;
; HOW ROUND 2 IS FORCED. `%out` is the merge of a 6.5 CLASSICAL-CALL ARM, so it
; is classical in round 1: `icmp eq i32 %out, 13` is not a tainted branch and the
; state prep below it is not detected until `repropagateControlMerges` re-seeds
; taint from the emitted out-rail. `CQ_CTRL_DBG=1` on the CONTROL twin names the
; decline anchor `%c2 = icmp eq i32 %out1, 13` — the operand `%out1` is the
; round-1-emitted rail, which is what makes the attribution to round 2 a
; measurement rather than a claim.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. MEASURED: on the frozen 2026-09-14
; ORACLE (`cq-opt` sha256 f7b65d8c…, from 59ac5b7, no phi-descendant exclusion)
; this exact module DECLINES `state prep seed is proven equal to the condition
; register`. On both the un-narrowed (`147cb3d6…`) and the narrowed (`96fdd3a9…`)
; subject it ACCEPTS with the stream below, and those two lowered outputs are
; BYTE-IDENTICAL — the round-1 back-edge narrowing does not touch this shape.
;
; THE STREAM, read rather than counted (Rule 2). `%h` is the source rail; the 6.5
; arm is hoisted and route-merged into the fresh `%out1` by 4.4 mechanics (two
; X-bracketed `cqrt_copy_i32_controlled`; since bd r2j3.32 the compare strip and
; the flag's free are deferred until `%out1`'s core is reversed). The ROUND-2 prep then mints `%h4 = cqrt_alloc_i32(0)` and rotates it
; with `cqrt_ry_i32_controlled(%h_cmp3, %h4, 0.5)` off a flag minted from
; `%out1`; `%h4` is FROZEN (never `cqrt_x`-bracketed, never freed — correct, as
; `Ry(θ)|0⟩ ≠ |0⟩`, Rule 6). The collider chain lowers as ordinary quantum
; arithmetic and is uncomputed LIFO, each temporary freed.
;
; ⚠ RETIREMENT TRIGGER (L8): the day `repropagateControlMerges` stops running a
; second detect+lower round, or the 6.5 classical-call arm stops being classical
; in round 1, this file stops pinning what it claims — rebuild a round-2-reaching
; skeleton rather than deleting the pair. If it ever DECLINES again, the conjunct
; has stopped firing in round 2 and `collectStatePrepPhiDescendants`' L1
; paragraph is describing a call that no longer happens.
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
  %dz = zext i32 %out to i64
  %dd = add i64 %dz, -13
  %mz = zext i32 %MB to i64
  %pm = mul i64 %dd, %mz
  %zm = trunc i64 %pm to i32
  %x0 = call i32 @cq_measure_si32(i32 %q)
  %x1 = call i32 @cq_measure_si32(i32 %MB)
  %x2 = call i32 @cq_measure_si32(i32 %zm)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; The 6.5 arm's route-merge into the round-1 out-rail.
; CHECK:      %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK:      %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1)
; CHECK-NEXT: %[[N_out1:out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; (bd dm7f.81: the TRUE arm is the classical %r, a literal xor; the FALSE arm is 0,
; no gate and no bracket.)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %h_cmp, i32 %[[N_out1]], i32 %r)
;
; THE ROUND-2 STATE PREP: the flag is minted from the ROUND-1 OUT-RAIL %out1,
; the prepped rail %h4 is fresh, and it is FROZEN (no cqrt_x on it, no free).
; CHECK-NEXT: %[[N_h_cmp3:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[N_out1]], i32 13)
; CHECK-NEXT: %[[N_h4:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[N_h_cmp3]], i32 %[[N_h4]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[N_h_cmp3]], i32 %[[N_out1]], i32 13)
; CHECK-NEXT: call void @cqrt_free(i32 %[[N_h_cmp3]])
;
; The collider chain, lowered as ordinary quantum arithmetic and uncomputed LIFO.
; CHECK-NEXT: %h_cast = call i32 @cq_template_zext_i32_to_i64(i32 %[[N_out1]])
; CHECK-NEXT: call void @cqrt_addc_i64(i32 %h_cast, i64 -13)
; CHECK-NEXT: %[[N_h_cast5:h_cast[0-9]*]] = call i32 @cq_template_zext_i32_to_i64(i32 %[[N_h4]])
; CHECK-NEXT: %h_op = call i32 @cq_template_mul_i64(i32 %h_cast, i32 %[[N_h_cast5]])
; CHECK-NEXT: %[[N_h_cast6:h_cast[0-9]*]] = call i32 @cq_template_trunc_i64_to_i32(i32 %h_op)
; bd r2j3.32: once its last reader (the M-C product chain's zext adjoint) has
; run, the merge rail %out1 is reversed -- the route-merge core re-emitted in
; reverse under the SAME %h_cmp, whose strip is DEFERRED to here -- and freed.
; CHECK:      call void @cq_template_zext_i32_to_i64_unc(i32 %h_cast, i32 %[[N_out1]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %h_cmp, i32 %[[N_out1]], i32 %r)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_free(i32 %[[N_out1]])
; CHECK:      %m = call i32 @cqrt_measure_i32(i32 %h)
; CHECK-NEXT: %[[N_m7:m[0-9]*]] = call i32 @cqrt_measure_i32(i32 %[[N_h4]])
; CHECK-NEXT: %[[N_m8:m[0-9]*]] = call i32 @cqrt_measure_i32(i32 %[[N_h_cast6]])
;
; Whole-file counts, in their OWN prefixes so they cannot window a negative
; (Rule 12(a)). EXACTLY ONE controlled Ry — the prep — and no uncontrolled Rz.
; RYCNT-COUNT-1: call void @cqrt_ry_i32_controlled
; RYCNT-NOT:     call void @cqrt_ry_i32_controlled
; RYCNT-NOT:     call void @cqrt_x(i32 %h3)
;
; SIX frees: the two compare flags, the three arithmetic temporaries
; (%h_op, %h_cast5, %h_cast) and, since bd r2j3.32, the out-rail %out1 once its
; core is reversed (it is |0> again). %h4 IS NOT AMONG THEM — the prepped rail is
; frozen (Ry|0> != |0>).
; FCNT-COUNT-6: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; THREE allocs: %h, %out1, %h4 (bd dm7f.81: the arms %r and 0 are no longer rails).
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; ACNT-COUNT-3: call i32 @cqrt_alloc_i32
; ACNT-NOT:     call i32 @cqrt_alloc_i32
;
; NO cqrt_x (bd dm7f.81): the 6.5 merge's FALSE arm is 0, which emits neither a
; write nor its bracket, forward or in the r2j3.32 reverse.
; XCNT-NOT: call void @cqrt_x(
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
