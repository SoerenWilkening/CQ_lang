; control_phase_kickback_reject_cmp_measured_before.ll — DECLINE (Track A.1, bd
; test_C_libtooling-r903 item (b)): the condition REGISTER is measured BEFORE the
; branch the kickback controls on.
;
;     int q = cq_theta(0, .5);
;     int m = cq_measure(q);
;     if (q > 3) cq_phi(.3);
;
; VERBATIM `clang -O1` (probe `r903b.c`). MEASURED on `main` 0c7380c: exit 0,
; verify-clean, STRICT stage 2b clean, and the emitted stream is
;
;     %h     = cqrt_alloc_i32(0);  cqrt_ry_i32(%h, .5)
;     %m     = cqrt_measure_i32(%h)                 <- the register collapses
;     %h_cmp = cq_template_icmp_sgt_i32_hl(%h, 3)   <- minted from it anyway
;     cqrt_rz_i1(%h_cmp, .3);  ..._unc;  cqrt_free(%h_cmp)
;
; THE ONE-TOKEN DISCRIMINATOR is the whole argument: write `bool` instead of
; `int` and the same program has DECLINED since Increment 1b, through
; `classifyPhaseKickback` step 5b's rail rung (ii). `condDataUseDisposition`'s
; `MeasuredEarly` does not cover it — that clause is about the FLAG's own data
; lineage (the ziov `atk9` share-path hazard) and has no subject here, because
; this compare has no data use at all. `condCmpMeasuredBeforeReadPoint` asks the
; register's question with `Pred->getTerminator()` as the read point.
;
; Discriminating accept: `control_phase_kickback_cmp_measure_after.ll`.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  %c = icmp sgt i32 %m, 3
  br i1 %c, label %ph, label %join

ph:
  call void @cq_phi(double 3.000000e-01)
  br label %join

join:
  ret i32 %m
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
