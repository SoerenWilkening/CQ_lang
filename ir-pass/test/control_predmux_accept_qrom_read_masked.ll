; control_predmux_accept_qrom_read_masked.ll — ACCEPT (3c6m.14 L6 Inc 3): a
; const-global QROM read under tainted control whose index is NOT provably
; in-bounds (a raw sign-extended i32) but whose table is a POWER-OF-TWO size —
; QromClaim::NeedsMask. Speculating the read out of its guard would be OOB on
; the basis states the guard excluded, so the flatten rewrites the gep index
; to `and idx, N-1`: on every in-bounds basis state the mask is the identity
; (the guard implies idx < N there), and on excluded states the masked read
; returns a garbage ROW whose value is excluded downstream by the same
; ∧-with-block-predicate argument as every speculated arm value (PRD §4.4/
; §6.1) — the atan atanhi[id] mechanism (its id phi carries −1, so known-bits
; provably cannot cover it).
;
; bd 01po.2: the mask is built on the STRIPPED i32 source of the -O1 `sext`
; (`and i32 q, 3`, re-widened by a `zext` the QRAM emitter strips), so the read
; takes the masked i32 rail directly: no `sext_i32_to_i64`, no `and_i64_hl`, no
; per-call `trunc_i64_to_i32` bracket. The NARROW prefix scans the whole module.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NARROW %s < %t.cqd0.ll
@tbl = internal unnamed_addr constant [4 x i32] [i32 7, i32 9, i32 11, i32 13]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ult i32 %q, 4                  ; guard implies in-bounds ON PATH only
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i32 %q to i64                ; raw index — known-bits UNPROVABLE
  %g = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; the table handle births first, then the masked index (and i32 q, 3) on the
; theta rail itself feeds the read with no cast bracket, its `_unc` and free
; follow the read, then the integer select merge routes the arm value:
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK:     %[[MSK:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[MSK]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[MSK]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[MSK]])
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
; NARROW-NOT: cq_template_sext_i32_to_i64
; NARROW-NOT: cq_template_and_i64
; NARROW-NOT: cq_template_trunc_i64_to_i32
