; control_swap_reject_post_region_theta_derived_cond.ll — DECLINE, AND THE
; MESSAGE CHANGED: this is bd test_C_libtooling-6uqc's INTERLOCK, working.
;
; THE SHAPE the Inc-4 accept must NOT swallow. A phase region whose condition is
; DERIVED (`sqrt(a+3.0) <= 5.0`, not an `icmp` on the register itself), followed
; by a chained `cq_theta` on the wire:
;     a = cq_theta(a, 0.5);
;     if (sqrt(a + 3.0) <= 5.0) { a = cq_phi(a, PI); }
;     a = cq_theta(a, 0.25);            /* <-- the post-region Ry */
;     return cq_measure(a);
;
; MEASURED, HEAD (b4e329b) vs THIS TREE — the VERDICT is identical and the
; OWNER is not:
;     HEAD  cq controlled lowering: condition predates a non-diagonal gate
;                                   under quantum control      (ArmClassify)
;     TREE  cq rotation lowering: non-diagonal gate over a live derived record
;                                                        (RotationLowering M-A)
;
; THAT IS THE POINT OF THE FILE. bd lom0's accept claim is "once the strip has
; run, the region holds no live record of the wire". It is TRUE for a DIRECT
; condition — the flag is the sole record and the `_unc` strip discharges it —
; and FALSE here: `cq_template_sitofp_i32_to_f64`, `cq_template_fadd_f64_hl` and
; `cq_template_sqrt_f64` mint rails that the flag strip never touches, so they
; are still allocated and entangled with the wire when the Ry fires (bd 6uqc's
; own measurement). Accepting this program would be a verify-clean dephasing
; miscompile — `opt` exit 0, every free paired, and the wrong unitary.
;
; Increment 4 does NOT re-prove that inside `ArmClassify`, and deliberately so
; (bd 6uqc's plan of record: "THE INTERLOCK RESOLVES VIA M-A, not via a
; direct-provenance clause in ArmClassify"). It lifts the position-free
; over-decline and lets Increment 3's live-record guard — which runs at the LATE
; post-uncompute slot on EMITTER-RECORDED gate sets, so "undischarged at the
; gate" is a fact and not a prediction — own the decline. The two increments
; were sequenced 3-before-4 for exactly this reason; if this file ever shows
; `opt` exit 0, the interlock has broken and Inc 4 has become an over-accept.
;
; NOT INTERCHANGEABLE with lowering_reject_live_record_derived_cond_theta.ll:
; that one is the STRAIGHT-LINE twin (no branch at all — the guard was the only
; layer that ever saw it). This one is the CONTROL-REGION twin, and it is the
; one whose message moved when Inc 4 landed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %cast = sitofp i32 %q to double
  %add = fadd double %cast, 3.000000e+00
  %rt = call double @llvm.sqrt.f64(double %add)
  %c = fcmp ole double %rt, 5.000000e+00
  br i1 %c, label %arm, label %merge

arm:
  %g = call i32 @cq_phi_si32(i32 %q, double 0x400921FB54442D18)
  br label %merge

merge:
  %p = phi i32 [ %g, %arm ], [ %q, %entry ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
