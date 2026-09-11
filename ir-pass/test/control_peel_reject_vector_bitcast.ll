; control_peel_reject_vector_bitcast.ll — DECLINE `no template for opcode
; 'bitcast <2 x i16>' in tainted context` (bd test_C_libtooling-b6ap, Rule-13
; ROUND-2 finding F-B6R2-1). THE DISCRIMINATING PARTNER of the accept
; `control_peel_identity_bitcast.ll`: the same module, ONE TOKEN apart — the
; bitcast's destination type is `<2 x i16>` instead of `i32`.
;
; `foldIdentityBitcasts` is now call 1 of `adjudicateTaintDelta`, and this fixture
; is what says the fifth call REUSES that stage's eligibility test rather than
; widening it. The test is unchanged and mirrors `castInScope`'s `bitcast` accept
; exactly: BOTH sides scalar integer, equal width — an identity, `result ===
; operand`, zero gates. A VECTOR (or pointer) bitcast is NOT an identity, must not
; be RAUW'd away, and keeps its existing loud decline at `castInScope`.
;
; A mutant that relaxed the fold to "any tainted bitcast" would take this module
; from a loud decline to a silently rewritten one — so the boundary is pinned from
; both sides: the accept above proves the fold fires, this proves it does not fire
; one type over. (An fp<->int bitcast is deliberately NOT the partner here: it is
; not folded either, but it has its own `cq_template_bitcast_i32_to_f32` row and
; LOWERS, so it would pin nothing.)
;
; RED-GREEN, MEASURED: `control flow under quantum control` on `main` 0c7380c (the
; 2-φ merge declines before the cast is ever adjudicated) and on the round-1 fix
; tree b7d646c; the string below now — i.e. the peel fires and the deeper fence
; owns the decline, the SCOPE H-2 "string moves" class.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %m
arm:
  %a2 = call i32 @cq_theta_si32(i32 %a, double 9.000000e-01)
  br label %m
m:
  %ap = phi i32 [ %a2, %arm ], [ %a, %entry ]
  %mux = phi i32 [ 7, %arm ], [ 5, %entry ]
  %nux = phi i32 [ 2, %arm ], [ 1, %entry ]
  %bc = bitcast i32 %mux to <2 x i16>
  %w = add <2 x i16> %bc, <i16 3, i16 0>
  %wi = bitcast <2 x i16> %w to i32
  %x0 = call i32 @cq_measure_si32(i32 %ap)
  %x1 = call i32 @cq_measure_si32(i32 %wi)
  %x2 = call i32 @cq_measure_si32(i32 %nux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}

define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}

; CHECK: no template for opcode 'bitcast <2 x i16>' in tainted context
