; control_predmux_accept_qrom_read_nonpow2_provable.ll — ACCEPT (3c6m.14 L6
; Inc 3, Rule-13 coverage pin): a const-global QROM read under control whose
; index is KNOWN-BITS-provably in-bounds (`lshr(bits,63)` ∈ {0,1} < 3) into a
; NON-power-of-two `[3 x double]` table. The QromClaim::Provable path is
; DECOUPLED from the pow2 mask fallback — a provable index needs NO mask
; regardless of table size — so this must accept UNMASKED (no `and i64`). Pins
; that a future known-bits/pow2 refactor cannot accidentally couple Provable to
; a power-of-two check (the surviving decline
; lowering_reject_qram_read_under_control_nonpow2*.ll is the UNprovable twin).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = lshr i64 %bits, 63                 ; provably {0,1} < 3
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [3 x double], ptr @t3, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hi = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hi, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 3)
; CHECK:     call i32 @cqrt_qram_load_f64(i32 %[[T]],
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: cq_template_and_i64
; CHECK-NOT: br i1
; CHECK-NOT: phi double
