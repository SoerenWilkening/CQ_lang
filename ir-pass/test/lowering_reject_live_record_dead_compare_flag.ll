; lowering_reject_live_record_dead_compare_flag.ll — DECLINE: a LIVE record does
; NOT exempt a DIFFERENT, DEAD one on the same wire (M-A Increment 1).
;
; `int f = (a > 5); a = cq_theta(a, 0.25); m = cq_measure(f);` — the natural
; C spelling, and the one where the ruled clause-3 exemption is most tempting to
; apply too broadly. Two records are minted from the wire:
;   %c -> cq_template_icmp_sgt_i32_hl(%h, 5)   the i1 compare rail
;   %f -> cq_template_zext_i1_to_i32(%c)       the i32 copy the user named
; `%f` IS live — it is measured after the gate — so IT is exempt, exactly as the
; ruling requires (a live record is user data; its dephasing is source
; semantics). `%c` is not: its only reader is the zext, which precedes the gate,
; and nothing uncomputes or frees it. The decline is carried by `%c` alone.
;
; The lesson it pins: exemption is PER RECORD, never per wire. An implementation
; that stopped at the first exempt record — or that treated "some record of this
; wire is live" as an exemption — would accept a genuinely dephased program.
;
; PHYSICS HONESTY — THIS PARTICULAR DECLINE IS A DELIBERATE OVER-DECLINE, and the
; header would imply a harm that is not there without saying so. `%f = zext %c` is
; a BIJECTION of `%c`, and `%f` is MEASURED before the gate. Measuring one side of
; a bijection collapses the other: at `T` the dead `%c` holds a definite basis
; value, carrying ZERO INCREMENTAL WHICH-PATH INFORMATION about the wire beyond
; the bit the measurement already extracted. So no amplitude that the source
; wanted to interfere is actually lost here. The guard declines anyway because its
; predicate is deliberately LOCAL and STRUCTURAL — "an undischarged record is
; standing at the gate" — and proving bijection-collapse is a whole-stream
; property that belongs to M-B (interior-rail uncompute, bd 6uqc option (b)),
; which is this decline's named customer. Over-declining is the safe direction
; (Prime Directive); the point of writing it down is that a future reader must not
; cite this fixture as evidence of a miscompile that was caught.
;
; CONTRAST — lowering_reject_live_record_derived_cond_theta.ll IS physically
; load-bearing, and the difference is the RATIO of what was measured to what
; stayed coherent: there a ONE-BIT compare is measured while FULL-PRECISION f64
; `sitofp`/`fadd`/`sqrt` rails stay live, so those rails hold which-path
; information the measurement never extracted and the wire really is dephased.
; Here everything dead is a bijection of something already measured.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 5                                     ; DEAD after the zext
  %f  = zext i1 %c to i32                                      ; LIVE — measured after the gate
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; chained, in-place Ry
  %m  = call i32 @cq_measure_si32(i32 %f)
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
