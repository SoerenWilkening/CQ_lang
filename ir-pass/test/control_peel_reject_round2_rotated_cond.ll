; control_peel_reject_round2_rotated_cond.ll — DECLINE `condition predates a
; non-diagonal gate` (bd test_C_libtooling-b6ap, the ROUND-2 DECLINE): the
; `control_peel_round2_out_cond.ll` module with region 2's arm rotating the very
; `%out` register region 2's condition reads.
;
; ⚠ IT PINS THAT THE ROUND-2 PEEL CALL IS NOT A SILENT ACCEPT. The peel DOES fire
; at round 2 here (the 2-phi wall is removed exactly as in its accept twin), and
; the region is then refused by `SelectClassify`'s gate 2c on the merits — a LOUD,
; correct, different string. On `main` 0c7380c this module says `control flow` (the
; wall), so the fixture moves DECLINE -> DECLINE with the string travelling one
; fence inward, which is what a correct normalisation looks like from the outside.
;
; Its accept twin is `control_peel_round2_out_cond.ll`; delete the round-2 call
; site and BOTH go back to `control flow`.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), one
; row of its P1-P9 DECLINE PARTITION. The peel is ACCEPT-ONLY and NEVER diagnoses:
; a shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
; loud owner unchanged. Over-declining is safe (Prime Directive); the peel's job is
; to remove a BOOKKEEPING over-decline, not to widen the accept class.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

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
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %m2, label %arm2
arm2:
  %t2 = call i32 @cq_theta_si32(i32 %out, double 5.000000e-01)
  br label %m2
m2:
  %amux = phi i32 [ 5, %arm2 ], [ 2, %m1 ]
  %b1 = phi i32 [ %t2, %arm2 ], [ 0, %m1 ]
  %x0 = call i32 @cq_measure_si32(i32 %b0)
  %x1 = call i32 @cq_measure_si32(i32 %out)
  %x2 = call i32 @cq_measure_si32(i32 %b1)
  %xa = call i32 @cq_measure_si32(i32 %amux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  %s3 = add nsw i32 %s2, %xa
  ret i32 %s3
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: condition predates a non-diagonal gate under quantum control
