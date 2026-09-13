
; control_swap_reject_select_mergephi_two_rails.ll — DECLINE (bd `boi6` D-B /
; Track M, probe `m29`). GREEN ON BOTH BINARIES — a discriminator, not a
; red-green pin.
;
; Track M admits ONE new select-condition shape: the `Merge` φ of a diamond the
; plan ALREADY holds as a controlled in-place Ry / state PREP. The admission is
; `Merge == P` by POINTER IDENTITY against `plan.Regions`, and this module is why
; that conjunct cannot be relaxed into "the φ's incomings are all tainted": here
; the two incomings are TWO DISTINCT REGISTERS (`%r1`, `%r2`, independent
; `cq_theta_i1` sources) merged on a CLASSICAL guard. No region's `Merge` is this
; φ — no region exists at all — so rung 0 finds nothing and gate 2 fires the
; generic `control flow`.
;
; WHY IT COULD NEVER BE AN ACCEPT, stated as physics rather than as bookkeeping:
; the φ denotes `%r1` on one edge and `%r2` on the other, so there is no single
; physical rail for `cqrt_cnot` to copy a basis label out of. The prepped-φ case
; is admissible for exactly the opposite reason — `emitInPlaceRotationRegion`
; COLLAPSES its two edges onto ONE register (M-β) before the select is emitted.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %r1 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %r2 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %a, label %b
a:
  br label %m
b:
  br label %m
m:
  %p = phi i1 [ %r1, %a ], [ %r2, %b ]
  %sel = select i1 %p, i32 2, i32 5
  %mm = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %mm
}

; CHECK: cq controlled lowering: control flow under quantum control
