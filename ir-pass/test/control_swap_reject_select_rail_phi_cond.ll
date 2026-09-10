; control_swap_reject_select_rail_phi_cond.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1): a `phi i1` select condition is NOT a rail
; leaf — the companion discriminator to `..._reject_select_rail_trunc_cond.ll`.
; A phi over two rotations of one register is a MERGE rail (which name does it
; denote? — the two incomings are different basis labels of the same wire), and
; the loop-carried spelling is bd `test_C_libtooling-boi6` (1b-D). Neither is
; admitted; `collectCondTree` returns false and gate 2 declines generically.
;
; GREEN ON BOTH BINARIES — a discriminator, not a red-green pin; see
; `..._reject_select_rail_trunc_cond.ll` for the measured mutant (admitting an
; i1 `trunc`/`phi` as a rail leaf reddens SIX fixtures across all four
; consumers of the shared predicate, of which this is one). The plain-C
; loop-carried spelling declines one layer earlier still
; (`cq loop lowering: loop-carried tainted value crosses iterations`, probe
; `s20`), which is why this module is hand-written IR with a classical guard.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %side, label %join
side:
  %b2 = call i1 @cq_theta_i1(i1 %b, double 2.000000e-01)
  br label %join
join:
  %p = phi i1 [ %b2, %side ], [ %b, %entry ]
  %a = select i1 %p, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %m = call i1 @cq_measure_i1(i1 %p)
  %z = zext i1 %m to i32
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: control flow under quantum control
