; control_phase_nest_reject_qq_leaf.ll — DECLINE. A Q+Q leaf (BOTH compare
; operands tainted) inside the COMPOUND INNER condition of a depth-2 phase nest
; (P4). bd test_C_libtooling-3qlq Inc 1, Rule-13 ROUND-2 finding F-B2-2.
;
;     if (q > 5) { cq_phi(0.25); if (q < r && r == 3) cq_phi(0.75); }
;
; This is the P4 twin of `control_phase_kickback_reject_tree_qq_leaf.ll`, and it
; exists so the SHARED string is a discriminator at BOTH classifiers rather than
; asserted at one. F-B2-2 moved the phase path's Q+Q refusal into the control
; layer under ONE spelling (`kQQCondReason`, `ArmClassify.cpp`); before that,
; P1's single-compare path declined in the OPCODE net
; (`no template for opcode 'icmp i1' in tainted context`) with the tainted `br`
; neither claimed nor declined by the control layer, and P1's tree path and this
; nest ladder both said the generic `control flow`. Three spellings of one
; question, in two layers. Now one.
;
; The mechanism is unchanged and is the ziov.4 mutate-then-decline class: the
; branch-phase network mints with `AllowQQLeaves = false`, so a Q+Q leaf's
; `lowerCompareToFlag` returns null MID-NETWORK, after earlier leaf flags and
; node ancillas exist. Refusing at DETECTION is what keeps the module untouched.
;
; NOTE the OUTER leaf `%c1` is Q+C and perfectly mintable — it is the INNER
; tree's `%ca = icmp slt i32 %q, %r` that is Q+Q, so this file also pins that the
; ladder is asked per LEAF and not per region.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

; CHECK: cq controlled lowering: quantum-quantum compare condition under quantum control
; The CONTROL layer refuses; the opcode net must never be the one that speaks.
; CHECK-NOT: no template for opcode

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %ca = icmp slt i32 %q, %r
  %cb = icmp eq i32 %r, 3
  %c2 = select i1 %ca, i1 %cb, i1 false
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}
