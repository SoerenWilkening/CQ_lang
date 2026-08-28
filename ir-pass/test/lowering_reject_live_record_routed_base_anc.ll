; lowering_reject_live_record_routed_base_anc.ll — DECLINE by THIS campaign's
; guard. The ROUTED-BASE ANCESTOR pin (M-A Increment 3, bd
; test_C_libtooling-6uqc), RE-DISPOSITIONED at Increment 4.
;
; RENAMED FROM lowering_reject_live_record_routed_base_anc_masked.ll: the
; `_masked` suffix recorded that bd test_C_libtooling-lom0's position-free
; over-decline reached this program first and hid whatever was behind it.
; Increment 4 lifted that decline for exactly this shape (flat, phase,
; `!ShareCondFlag`, gate provably after the emitted stream), and what was behind
; it is what Increment 3 shipped for. The mask is gone; the decline is not.
;
; SOURCE — a PHASE region whose routed base is a derived rail, followed by a
; chained theta on that same rail:
;     volatile int off = 3;
;     int q = cq_theta(0, 0.5);
;     int r = q * off;                          // routed base: a FRESH rail
;                                               // (mul is NOT an M-C in-place
;                                               // reassignment), so `q`'s alloc
;                                               // rail is a dead ANCESTOR of it
;     if (r == 5) { r = cq_phi(r, PI); }        // phase arm
;     r = cq_theta(r, 0.25);                    // the chained Ry
;     return cq_measure(r);
;
; MEASURED — the verdict never changed, the OWNER did:
;     HEAD b4e329b   cq controlled lowering: condition predates a non-diagonal
;                    gate under quantum control                  (ArmClassify)
;     Increment 4    cq rotation lowering: non-diagonal gate over a live
;                    derived record                        (RotationLowering)
;
; THIS IS THE INTERLOCK, AND IT IS WHY bd 6uqc SEQUENCED INC 3 BEFORE INC 4.
; `cq_template_mul_i32_hl` mints `r` and leaves `q`'s alloc rail live, dead,
; undischarged and entangled — a full basis record of the wire standing beside a
; non-diagonal gate. Increment 4's accept claim ("once the strip has run the
; region holds no live record") is a claim about the region's OWN flag; it says
; nothing about a record the region merely READ. Increment 3's ancestor walk is
; what closes that, at the late post-uncompute slot where discharge is an
; emitter-recorded fact rather than a prediction.
;
; IF THIS FILE EVER SHOWS `opt` EXIT 0, the lift converted a masked severance
; into a live over-accept — the exact defect the Increment-1 round measured for
; the clone-return rail. The two other severance pins are unmoved and are NOT
; interchangeable evidence: lowering_reject_live_record_switch_mux_out_masked.ll
; declines in `SwitchClassify` (`control flow`) and
; lowering_reject_live_record_valuearm_merge_out_masked.ll on the value-arm path
; (`value-arm swap-route`); neither ever carried lom0's message, and both are
; byte-identical across Increment 4.
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

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
