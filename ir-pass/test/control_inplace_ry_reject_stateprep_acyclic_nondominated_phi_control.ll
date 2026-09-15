; control_inplace_ry_reject_stateprep_acyclic_nondominated_phi_control.ll —
; DECLINE (F2). **THIS FILE EXISTS TO MAKE ITS SIBLING NON-VACUOUS** and has no
; other job. The sibling is
; `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll`, whose
; expectation was flipped on 2026-09-15 when bd `test_C_libtooling-hrts` / bd
; `test_C_libtooling-l3i1` replaced `collectStatePrepPhiDescendants`' `MergeBB`
; dominance proxy with the member-vs-SLOTS availability test.
;
; ⚠ THE HYGIENE DEFECT THIS CLOSES (CLAUDE.md Rule 12, defect (c)): *a decline
; fixture that goes green because its SUBJECT no longer exists pins nothing*.
; The sibling now matches a DIFFERENT diagnostic than it used to. That could
; mean the exclusion widened correctly — or it could mean F2 stopped being able
; to fire on this CFG at all. Only a control separates those two readings.
;
; THE ISOLATION IS **ONE OPERAND**. This module is byte-identical to the sibling
; except for a single line:
;     sibling:  %mz = zext i32 %MB to i64     ; `%p`'s incoming IS an M-descendant
;     here:     %mz = zext i32 %q  to i64     ; `%p`'s incoming is NOT one
; Everything else — the acyclic bypass `entry -> %Y -> %J`, the state-prep
; diamond, the fold to `{0}` == the seed on the `%q == 7` edge, the block
; layout, the measures — is the same. `%u` is still TAINTED here (it derives
; from `%q`), so it is still an F2 candidate; it simply no longer reaches the
; merge φ `%MB` through its operands, so the φ-descendant set does not contain
; `%p` under EITHER predicate and F2 counts it as a rival under both.
;
; MEASURED on both binaries of the landing (per-probe pipeline, PROTOCOL.md):
;   ORACLE   `cq-opt` sha256 `0e280fc6…`  exit=1  F2, the string below
;   SUBJECT  `cq-opt` sha256 `8cda04ca…`  exit=1  F2, the string below
; i.e. this file does NOT move, while its sibling does. That pair is the whole
; measurement: what changed is φ-descendant MEMBERSHIP, not F2's reach.
;
; ⚠ RETIREMENT TRIGGER (L8). The day this file's string moves to anything else,
; the two fixtures have stopped isolating and the sibling's green is unpinned
; again — re-derive both headers together; do not delete either. And if this
; file and the sibling ever print the SAME string, whichever direction they
; agreed in, the isolation is gone: that is the state the pair exists to make
; impossible to reach silently.
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
  %x2 = call i32 @cq_measure_si32(i32 %p)
  %s = add nsw i32 %mp, %x2
  ret i32 %s
}

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cq taint escape: tainted value muxed by a classical-condition phi
; CHECK-NOT: cqrt_ry_i32_controlled
