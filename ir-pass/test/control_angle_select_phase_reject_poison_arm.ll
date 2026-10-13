; control_angle_select_phase_reject_poison_arm.ll — DECLINE. Rule-13 round-1
; finding F-L4-1 (bd test_C_libtooling-3qlq Inc 1 part A, lens L4): the ONE
; clause of the 2b arm-value fence that DOES have a subject for the PHASE stem.
;
;     if (c) cq_phi(<poison>); else cq_phi(0.3);
;
; `classifyAngleSelect`'s `IsPhase` fork skipped `angleSelectArmsAdmissible`
; WHOLESALE, on the argument that the phase stem performs no arithmetic on the
; angles (it emits `P(B)` on `¬f` and `P(A)` on `f`, each value passed through
; verbatim), so every clause of that fence has no subject. That is TRUE of the
; non-finite-arm, non-finite-difference, rounding-bound and constant-arms-only
; clauses — all four fenced the `A − B` subtraction the Ry stem then performed —
; and FALSE of clause (1), `valueCarriesUndef`, which is about a value that is not
; a NUMBER AT ALL. Passing it through verbatim is exactly how it reaches a gate
; slot. (Since bd dm7f.6 the four are retired with that subtraction and clause
; (1) is `angleSelectArmsDefined`, asked for BOTH stems; this decline is
; unchanged.)
;
; MEASURED at the increment's HEAD: this module emitted
; `call void @cqrt_rz_i1(i32 %f, double poison)` — a gate whose angle operand
; denotes nothing. That is the bd xy9n literal-integrity class: at the `-O0`
; stage 3 the backend may read one `poison` as two different values, so the
; emitted angle stops denoting the source's. The pre-3qlq oracle declined the
; same shape.
;
; Hand-IR only at this clang — `-O1` does not hand a select an `poison` arm
; from any C spelling I could reach — which is why it is a fixture and not a
; slice. Its ACCEPT counterpart is
; `control_angle_select_phase_nonfinite_arm.ll`, which records that a NON-FINITE
; arm is DELIBERATELY passed through: the two files together are what say which
; half of the fence has a subject here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cqrt_rz

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @slice(i32 %0) {
  %2 = call i32 @cq_theta_si32(i32 %0, double 5.000000e-01)
  %3 = icmp eq i32 %2, 5
  %4 = select i1 %3, double poison, double 3.000000e-01
  call void @cq_phi(double %4)
  %5 = call i32 @cq_measure_si32(i32 %2)
  ret i32 %5
}
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
define i32 @main() { %1 = call i32 @slice(i32 5) ret i32 0 }
