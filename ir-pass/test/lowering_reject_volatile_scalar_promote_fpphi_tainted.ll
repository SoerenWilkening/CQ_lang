; lowering_reject_volatile_scalar_promote_fpphi_tainted.ll — SAFETY-NET PIN (bd
; zco4): the change's most dangerous IR PRODUCT. A volatile fp accumulator stored
; on BOTH arms of a TAINTED branch and reloaded after the merge — the distilled
; e_log10l.c `z` shape (`if (frac < SQRTH) z = ...; else z = ...`; both %40/%41 in
; the real body are tainted). promoteVolatileScalarLocals FIRES here (it must —
; that is the whole point): it clears volatile and PromoteMemToReg builds an
; x86_fp80/f64 PHI merging the two arm values, EXACTLY the SSA clang's mem2reg
; yields for the same body with `volatile` removed. That exposes an fp merge phi
; UNDER TAINTED CONTROL — a rotation ANGLE at a control merge, NOT data ("a
; floating-point merge φ is an angle, not data"). The control machinery then
; LOUD-DECLINES it ("control flow under quantum control") — it never silently
; lowers an fp-angle merge. This is the faithful-reproduction safety net: the
; non-`volatile` twin of this body declines with the IDENTICAL message, so
; promotion introduces no new accept behavior — it only routes the volatile idiom
; to the machinery the pass already adjudicates. In the real log10l cell this exact
; shape is currently MASKED by the earlier `ldexpl` unknown-callee decline (Inc 2
; removes that mask); this fixture guards the end-to-end net directly, so a future
; control-lowering over-accept regression on the exposed fp phi is caught here.
; That promotion advanced the decline FROM kMsgStore (the still-volatile store) TO
; this control message is the proof promotion fired.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %z = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01            ; TAINTED condition
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q, -5.000000e-01               ; z = q - 0.5   (one arm)
  store volatile double %a, ptr %z, align 8
  br label %merge
hi:
  %b = fmul double %q, 2.000000e+00                ; z = q * 2     (other arm)
  store volatile double %b, ptr %z, align 8
  br label %merge
merge:
  %zv = load volatile double, ptr %z, align 8      ; promotion → fp phi under tainted control
  %m = call double @cq_measure_f64(double %zv)
  ret double %m
}

; Promotion fired (advanced PAST the store-to-memory decline) and the exposed
; fp-angle merge under tainted control is loud-declined, never silently lowered.
; CHECK:     error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: tainted value stored to memory
