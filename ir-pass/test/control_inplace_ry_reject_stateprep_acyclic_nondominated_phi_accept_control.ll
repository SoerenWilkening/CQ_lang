; control_inplace_ry_reject_stateprep_acyclic_nondominated_phi_accept_control.ll
; — DECLINE (F2). **THIS FILE EXISTS ONLY TO MAKE ITS SIBLING NON-VACUOUS**, and
; the sibling is the ACCEPT `control_inplace_ry_stateprep_acyclic_nondominated_
; phi_accept.ll` that bd `test_C_libtooling-hrts`' trigger said did not exist.
;
; ⚠ AN ACCEPT FIXTURE IS THE EASIEST KIND TO FOOL. It goes green if the module
; lowers — including if it lowers because F2 lost the ability to fire on this
; CFG at all, which would be an OVER-ACCEPT and the exact bug class this fence
; exists for. The `CHECK`s on the sibling pin the STREAM, and this file pins the
; other half: that F2 is still watching this shape.
;
; THE ISOLATION IS **ONE OPERAND**, and nothing else differs — same acyclic
; bypass `entry -> %Y -> %J`, same dead phi `%p`, same state-prep diamond, same
; fold to `{0}` == the seed on the `%q == 7` edge:
;     sibling:  %mz = zext i32 %MB to i64   ; `%p`'s incoming IS an M-descendant
;     here:     %mz = zext i32 %q  to i64   ; `%p`'s incoming is NOT one
; `%u` is still TAINTED here (it derives from `%q`), so it is still an F2
; candidate and `%p` still folds to the seed; `%p` simply no longer reaches the
; merge phi `%MB` through its operands, so the phi-descendant set does not contain
; it under EITHER predicate and F2 counts it as a rival under both.
;
; MEASURED on both binaries of the landing:
;   ORACLE   `cq-opt` sha256 `0e280fc6...`  exit=1  F2, the string below
;   SUBJECT  `cq-opt` sha256 `8cda04ca...`  exit=1  F2, the string below
; i.e. this file does NOT move while its sibling goes DECLINE -> ACCEPT. So the
; sibling's accept is attributable to phi-descendant MEMBERSHIP, and not to
; deadness, block layout, guard order or F2 going quiet.
;
; ⚠ RETIREMENT TRIGGER (L8). The day this file ACCEPTS, the exclusion has been
; widened past availability and the sibling's green means nothing any more —
; re-derive both headers together and re-measure the back-edge pair. Do not
; delete either file; the pair is the instrument, not the individual fixtures.
;
; ⚠ The IR-text `CHECK-NOT`s are VACUOUS BY CONSTRUCTION (a `DS_Error` decline
; writes 0 bytes to stdout); the `not` inversion on the RUN line plus the message
; match is what pins this file (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %arg) {
entry:
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %pre, label %Y
pre:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %pre ]
  %dz = zext i32 %q to i64
  %dd = add i64 %dz, -7
  %mz = zext i32 %q to i64
  %pm = mul i64 %dd, %mz
  %u = trunc i64 %pm to i32
  %m0 = call i32 @cq_measure_si32(i32 %MB)
  br label %J
Y:
  br label %J
J:
  %p = phi i32 [ %u, %mB ], [ 0, %Y ]
  %mp = phi i32 [ %m0, %mB ], [ 0, %Y ]
  ret i32 %mp
}

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cq taint escape: tainted value muxed by a classical-condition phi
; CHECK-NOT: cqrt_ry_i32_controlled
