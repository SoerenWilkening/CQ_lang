; control_predmux_accept_qrom_read.ll — ACCEPT (3c6m.14 L6 Inc 3): a const-
; global QROM read under tainted control with a KNOWN-BITS-provably in-bounds
; index — the exact `hi = x - ln2HI[xsb]` openlibm shape (e_exp.c:138): the
; sign bit `lshr 63` indexes a `[2 x double]` table inside a tainted diamond
; arm. The read is claimable (QromClaim::Provable): the W4 witness claims the
; flat diamond (no other owner accepts a load-bearing arm — ArmClassify
; declines loads), PredMux speculates gep+load straight-line, and the shipped
; 7.5 QROM emitter + Phase-5 uncompute lower/reverse it. Replaces the Inc-3-
; superseded decline pin lowering_reject_qram_read_under_control.ll (the
; PRD §7 flipped-fixture pattern; the surviving decline is re-pinned by
; lowering_reject_qram_read_under_control_nonpow2.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
@ln2 = internal unnamed_addr constant [2 x double] [double 0x3FE62E42FEE00000, double 0xBFE62E42FEE00000]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @exp_like(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = lshr i64 %bits, 63                 ; tainted sign bit → provably < 2
  %cmp = fcmp olt double %q, 0.000000e+00  ; tainted condition
  br i1 %cmp, label %arm, label %merge
arm:                                       ; the const-table read is CONDITIONAL here
  %g = getelementptr inbounds [2 x double], ptr @ln2, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hi = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hi, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; speculated straight-line QROM read (no mask — the index is provable), then
; the kjd1 fp select merge routes the arm result:
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 2)
; CHECK:     call i32 @cqrt_qram_load_f64(i32 %[[T]],
; CHECK:     call i32 @cq_template_fsub_f64(
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: br i1
; CHECK-NOT: phi double
; CHECK-NOT: select i1
; CHECK-NOT: cq_template_and_i64
