; lowering_reject_qram_read_under_control_udiv_zero.ll — DECLINE (bd s6ao,
; Rule-13 round 2). `udiv X, Y <= X` HOLDS ONLY FOR Y != 0.
;
; `udiv X, 0` is poison, so bounding the quotient by the dividend without
; checking the divisor reinstates exactly the modulo-poison bound this fence
; exists to reject. The first draft's `UDiv` rule was an unguarded
; "<= the dividend", four lines below a `URem` rule that DID guard — an omission,
; not a policy, and the asymmetry is what makes the one-token control below work.
;
; MEASURED on the draft: this module lowered at `opt` exit 0 to an UNMASKED
; `cqrt_qram_load_f64` into a 3-cell table, `free_pairing_check.py` clean, and it
; LINKED AND RAN, printing a completely golden-plausible trace. Invisible to all
; three shipped gates, on the frozen-designate 7.5 symbol.
;
; ONE-TOKEN CONTROL, and it is the reason this fixture is a real arm-kill:
; replacing `udiv` with `urem` DECLINED on the same draft, because `URem` already
; carried the nonzero-constant guard. So the discriminator is the rule, not the
; shape of the cone.
;
; Rule 15's width-only ABI is what makes the bound describe a value the circuit
; does not compute: the emitted `cq_template_udiv_i64_hl(%h, 0)` carries no
; divide-by-zero semantics at all (a reversible restoring divider yields an
; arbitrary quotient), so nothing in the gate stream enforces "<= the dividend".
;
; This analysis has no min-value lattice, so a nonzero CONSTANT divisor is the
; only case the rule can discharge; a variable divisor now falls to `full` and is
; refused — a deliberate over-decline (safe), since a divisor that is zero on
; even one basis state poisons the bound on that state.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %hi = lshr i64 %bits, 63          ; genuinely flag-free: max 1
  %sx = udiv i64 %hi, 0             ; poison — the quotient is NOT bounded by %hi
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [3 x double], ptr @t3, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hd = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hd, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Mirrored character-for-character from `kMsgQromUnderControlBounds`.
; CHECK: error: {{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
