; control_predmux_reject_degenerate_phi_classical.ll — DECLINE (bd q2wk, PRD
; §4.4b). The adversarial probe for sub-rule (B)'s documented residual, pinned
; so the residual can never quietly become a silent accept.
;
; Sub-rule (B) widened E6's classical-branch gate to admit a condition
; `valueWillTaintAfterFlatten` proves the flatten will taint — region-internal
; and transitively phi-derived. That predicate says YES for `%cc` here, because
; `%ph` is a region-internal PHI. But `%ph` has only ONE incoming block, so
; `convertPhis` does NOT take the boolean-algebra path (which needs
; `In.size() > 1`); it RAUWs the phi to its single incoming — the FUNCTION
; ARGUMENT `%arg`, which is genuinely classical AND a runtime (non-constant)
; value. So the claim is, in this one shape, wider than the taint reality.
;
; The q2wk Rule-13 round CLOSED this residual at the claim gate rather than
; leaving it to a downstream decline. `valueWillTaintAfterFlatten` now mirrors
; what `convertPhis` actually does: a phi whose unique-block incoming VALUES are
; all ONE Value is RAUW'd to that Value, so the predicate recurses into it
; instead of answering "will taint" — and a phi in `R.Entry` (never converted)
; answers false outright. So this input leaves at `gate=E6-classicalbr` with the
; region UNTOUCHED (detect-before-mutate), and `ControlDetect` owns the decline.
; Byte-identical posture and diagnostic to the pre-q2wk plugin, which declined
; the same input by the same route.
;
; The earlier version of this fixture pinned the WEAKER outcome (claim + flatten,
; then a loud downstream decline) and its header cited PRD §4.4b's "loud, never
; silent" assertion. Both are corrected: that assertion was measurably false in
; general — a region that mints no select compiles silently — and the residual it
; described is now fenced rather than merely backstopped. See §4.4b.
;
; If a future change makes this input EXIT 0, that is a q2wk over-accept
; regression, not an improvement — re-derive the taint argument before touching
; this fixture.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %arg) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %A, label %B

A:
  br label %A2

A2:                                               ; single predecessor
  %ph = phi i32 [ %arg, %A ]                      ; degenerate 1-incoming phi
  %cc = icmp eq i32 %ph, 0                        ; classical RUNTIME condition
  br i1 %cc, label %J, label %Ag

Ag:
  %ga = mul i32 %q, 7
  br label %J

B:
  %b = add i32 %q, 3
  br label %J

J:
  %r = phi i32 [ %ga, %Ag ], [ %q, %A2 ], [ %b, %B ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
