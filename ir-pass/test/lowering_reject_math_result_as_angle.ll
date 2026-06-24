; lowering_reject_math_result_as_angle.ll — DECLINE: a TAINTED fp-DATA result
; reaching a rotation's arg-1 ANGLE slot in straight-line code (PRD-iw81.4 §7
; hazard 1, decline-matrix D1 — the carve-precondition headline probe).
;
; THE CLAIM THIS PINS (the one report-flagged unproven claim, iw81.4.a): once the
; fp-intrinsic family lands (iw81.4.b: sin/cos/exp/…), a tainted math result
; reaching a rotation angle — `cq_phi(u, sin(q))` — MUST still loud-decline, never
; lower a soft-float ANGLE through an fp-DATA template (the f64 angle/data silent-
; miscompile family). At THIS increment sin/etc. are NOT yet recognized, so a
; literal `sin(q)` would ride the kMsgUnknownCallee escape decline
; (lowering_reject_intrinsic_transcendental_sqrt.ll) and never reach the angle
; fence. So the probe uses the fp-DATA producer that IS already recognized — a
; tainted `fmul` (PRD §2.1, `cq_template_fmul_f64`) — as the faithful proxy: it
; reaches `lowerRotations` exactly as a recognized `sin(q)` will in .b.
;
; WHY THE PROXY IS FAITHFUL (the ordering proof, verified this session):
;   * `lowerRotations` (RotationLowering::declineTaintedAngle) runs BEFORE
;     `lowerOps` (CQLoweringPass.cpp:177 vs :178), and intrinsic lowering
;     (`rewriteIntrinsic`) lives in `lowerOps` (OpcodeLowering.cpp:299). So the
;     angle fence fires while the fp producer is STILL its source call — `fmul`
;     today, `@llvm.sin.f64` in .b — never after it is lowered away.
;   * the fence keys on `taint.Tainted.count(arg-1)` (RotationLowering.cpp:75),
;     which is PRODUCER-AGNOSTIC. `fmul(q,q)` and `sin(q)` are both ordinary
;     tainted data users of `q` (the per-use arg-1 skip, TaintPropagation.cpp:303,
;     excludes ONLY the `cq_phi` angle edge, not the producer's own taint). Both
;     are in `Tainted`, so both decline identically.
; Hence proving the fence for the recognized `fmul` proves it for the recognized
; `sin` — same `lowerOps` stage, same fence, same taint membership.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %ang = fmul double %q, %q                       ; TAINTED fp-DATA result (the recognized-math proxy)
  %qd  = call double @cq_phi_f64(double %q, double %ang)   ; %ang in the arg-1 ANGLE slot
  %m   = call double @cq_measure_f64(double %qd)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined inside lowerRotations, BEFORE lowerOps — so no fp template is ever minted:
; CHECK-NOT: cq_template_fmul
; CHECK-NOT: cqrt_rz
