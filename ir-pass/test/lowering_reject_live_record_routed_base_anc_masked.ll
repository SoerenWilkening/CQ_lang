; lowering_reject_live_record_routed_base_anc_masked.ll — DECLINE, BUT BY bd
; test_C_libtooling-lom0's guard, not by this campaign's. The ROUTED-BASE
; ancestor pin (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; SOURCE — a PHASE region whose routed base is a derived rail, followed by a
; chained theta on that same rail:
;     volatile int off = 3;
;     int q = cq_theta(0, 0.5);
;     int r = q * off;                          // routed base: a FRESH rail,
;                                               // so `q`'s alloc rail is a dead
;                                               // ANCESTOR of it
;     if (r == 5) { r = cq_phi(r, PI); }        // phase arm
;     r = cq_theta(r, 0.25);                    // the chained Ry
;     return cq_measure(r);
;
; MEASURED AT HEAD AND AFTER INCREMENT 3 — verdict and message IDENTICAL:
;     cq controlled lowering: condition predates a non-diagonal gate under quantum control
; This is bd lom0's position-free `wireGainsNonDiagonalGate`, firing in
; `ArmClassify` because the condition's wire (`r`) later gains a theta — an
; over-decline lom0 exists to LIFT.
;
; WHY THIS FILE EXISTS. lom0's lift (Increment 4) removes the ONLY thing standing
; between this program and the emitter, and what is behind it is exactly the
; ancestor structure Increment 3 closes: `cq_template_mul_i32_hl` mints `r` and
; keeps the alloc rail live, dead, undischarged, entangled — a dephasing Ry.
; INCREMENT 4 MUST RE-MEASURE THIS FIXTURE: when the lom0 decline lifts, this
; must land on
;     cq rotation lowering: non-diagonal gate over a live derived record
; and NOT on `opt` exit 0. If it lowers, the lift converted a masked severance
; into a live over-accept — the exact defect the Increment-1 round measured for
; the clone-return rail.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@off = global i32 3, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %o = load volatile i32, ptr @off, align 4
  %r = mul nsw i32 %o, %q                                      ; the ROUTED BASE
  %c = icmp eq i32 %r, 5
  br i1 %c, label %arm, label %merge

arm:
  %rz = call i32 @cq_phi_si32(i32 5, double 0x400921FB54442D18)
  br label %merge

merge:
  %p = phi i32 [ %rz, %arm ], [ %r, %entry ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
