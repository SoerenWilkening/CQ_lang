; control_inplace_ry_reject_derived_base.ll — DECLINE: the rotated register is
; DERIVED from the condition register by an `add`, so nothing at DETECTION time
; proves the two are different physical rails (control-in-place-PRD §4 R4, bd
; test_C_libtooling-drbq).
;
;     int q = 0; cq_theta(&q,.5); int r = q + 1;
;     if (q > 5) cq_theta(&r, .9);
;
; THE ONE FIXTURE THAT REACHES R4 ITSELF, and the reason it must exist: every
; other wire-overlap spelling (the condition register, an SSA alias, a diagonal
; alias) is caught EARLIER by `condWireDisposition`, so without this one R4 would
; be an unexercised rule. Here the condition's wire gains no gate — the Ry is on
; `%r` — and the hazard is instead that `%r` may BE `%q`'s rail: an `add` with one
; tainted operand lowers IN PLACE (`cqrt_addc_<W>` on the parent's own rail) when
; the M-C fence admits it, OUT of place otherwise, and that fence lives in
; `lowerOps`, which runs long after detection. `railWireClosure` therefore admits
; BOTH roots and the region declines.
;
; DELIBERATELY AN OVER-DECLINE: M-C would in fact refuse this particular `add`
; (`%q` is read later), so the two rails really are disjoint here. Over-declining
; is always safe (Prime Directive) and the shape is outside the Inc-1 accept class
; either way.
;
; ⚠ THEREFORE THIS FIXTURE IS NOT R4's WITNESS, and must not be read as one. The
; TRUE-POSITIVE — a base that genuinely IS the condition's rail — is
; `control_inplace_ry_reject_inplace_alias_base.ll` (with its M-C witness
; `control_inplace_ry_inplace_alias_witness.ll`), added by the round-1 Rule-13
; review after it observed that a narrowing of the `add`/`sub`/`xor` hop would
; keep THIS fixture green while admitting that one. The `sub` spelling is
; `control_inplace_ry_reject_derived_base_sub.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation arm on a condition wire under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = add nsw i32 %q, 1
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
