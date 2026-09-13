
; control_swap_reject_select_mergephi_tree_leaf.ll — DECLINE (bd `boi6` D-B /
; Track M, probe `m31`). GREEN ON BOTH BINARIES.
;
; THE φ AS AN INTERIOR LEAF of a compound condition tree (`if (b1 && q > 3)`),
; which `clang -O1` hands over as `and i1 %phi, %cmp`. Track M's grammar admits a
; φ leaf ONLY AS THE TREE'S ROOT (`collectCondTree`'s `AllowRailPhi` tests
; `V == Root`), so this walk returns false and gate 2 fires `control flow` — the
; string it takes today, unchanged.
;
; THE DECISION, AND IT IS A SCOPE DECISION RATHER THAN AN OBSTACLE. By emit time
; the φ has been RAUW'd to a `cq_theta_i1` CALL, so a nested φ would reach
; `CondTreeEmit`'s NON-ROOT rail path and be read as a read-only control of a node
; `cqrt_toffoli` — the shipped r9e5 treatment, which may well be correct here too.
; It has NO probe family, NO fixture and NO adversarial round, so it stays
; off-grammar (Prime Directive — over-declining is always safe), and the region
; that region DOES claim (a genuine state prep on `%b0`) is deliberately left
; unexploited.
;
; ⚠ RETIREMENT TRIGGER (L8 — they work). The increment that widens `AllowRailPhi`
; past the root must flip THIS FILE from a decline to an ACCEPT and derive its
; stream from the pass output (expect the r9e5 non-root-rail network: one compare
; flag for `%cmp`, the RAIL as a bare control, one `cqrt_toffoli` onto a fresh
; ancilla, stripped LIFO). Re-derive it then; do not delete it.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 7.000000e-01)
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %merge, label %arm
arm:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %t, %arm ], [ false, %entry ]
  %c = icmp sgt i32 %q, 3
  %and = and i1 %p, %c
  %sel = select i1 %and, i32 2, i32 5
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %z1, %m2
  ret i32 %s
}

; CHECK: cq controlled lowering: control flow under quantum control
