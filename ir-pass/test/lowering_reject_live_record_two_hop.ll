; lowering_reject_live_record_two_hop.ll — DECLINE: a dead INTERIOR record, two
; producer hops from the wire (M-A Increment 1, bd test_C_libtooling-6uqc).
;
; SOURCE: `a = cq_theta(a,0.5); int d = a+3; int e = d*2; m = cq_measure(e);
;          a = cq_theta(a,0.5);` — `clang -O1` reassociates `(a+3)*2` into
; `shl`+`add 6`, which is the SSA below.
;
; WHAT THIS PINS THAT THE ONE-HOP FIXTURE DOES NOT: the record closure is
; TRANSITIVE. The terminal record `%e` is EXEMPT — it is measured before the
; gate (clause 4) — so a guard that only looked one producer hop from the wire
; would accept. The violation is the INTERIOR rail `%d`, which is a record of a
; record, has no user at all after `%e`, and is never uncomputed or freed: it is
; live and entangled with `%h` when the second `Ry` fires.
;
; PHYSICS HONESTY — WHAT THIS FIXTURE DOES AND DOES NOT DEMONSTRATE. It pins the
; STRUCTURAL rule (the record closure is transitive; a one-hop walk under-declines),
; NOT an incremental physical harm in this module. `%e = %d + 6` is a BIJECTION of
; `%d`, and `%e` is MEASURED before the gate — so measuring `%e` collapses `%d`
; too, and at `T` the interior rail holds a definite basis value carrying ZERO
; INCREMENTAL WHICH-PATH INFORMATION beyond what the measurement already
; extracted. (The WIRE is only partly collapsed — `shl i32 %q, 1` is 2-to-1, so
; one bit of `%q` survives — but that residual coherence lives in `%q`, not in
; `%d`.) So this decline, like lowering_reject_live_record_dead_compare_flag.ll's,
; is a KNOWN, DELIBERATE OVER-DECLINE whose named customer is M-B (interior-rail
; uncompute, bd 6uqc option (b)). The guard's predicate is local and structural on
; purpose; bijection-collapse is a whole-stream property it cannot see. Do not
; cite this file as a caught miscompile — cite it as the transitivity pin.
;
; CONTRAST — lowering_reject_live_record_derived_cond_theta.ll IS physically
; load-bearing: there a ONE-BIT compare is measured while FULL-PRECISION f64
; `sitofp`/`fadd`/`sqrt` rails stay live, so those rails hold which-path
; information no measurement extracted and the wire really is dephased at the
; gate. The ratio of measured-to-coherent is what separates the two cases.
;
;
; VEHICLE-OP NOTE (bd test_C_libtooling-6uqc, M-C Increment 2a — `add` only).
; The terminal record used to be built with `add`. M-C now lowers a
; dead-parent `q + c` IN PLACE (`cqrt_addc_<W>`), which would COLLAPSE the two
; rails this fixture needs into one: the interior record and the terminal record
; would become the same register, the measurement would land on the interior
; record itself, and clause 4 (measured-before-the-gate ⇒ collapsed ⇒ exempt)
; would exempt it — the module would ACCEPT for a reason that has nothing to do
; with what this file pins. The vehicle is therefore `mul`, which is
; information-LOSING and so is deliberately outside the dtzb in-place bijection
; family (`inPlaceValueRailOperand`) at every batch, not just this one. The
; STRUCTURE under test — a dead interior record standing at the gate — is
; unchanged; only the arithmetic that builds the terminal record moved.
;
; ── M-B INCREMENT 5b PRESERVATION NOTE (bd test_C_libtooling-6uqc) ───────────
; The `call void @cqrt_x(i32 %d)` below is NOT part of the shape this fixture
; was written to pin, and it is not decoration either — READ THIS BEFORE
; "simplifying" it away.
;
; Without it, M-B's interior partition now DISCHARGES the two-hop interior record `%d` — uncomputes it
; with its out-first `_unc` and frees it — BEFORE the chained `cq_theta`, and the
; guard then correctly ACCEPTS on clause 2 (a record whose own discharge is
; provably before the gate is not standing at it). That accept is right, and it
; is the whole point of Increment 5; what it costs is THIS fixture's premise. The
; program stops containing a live-at-the-gate record, so it stops exercising the
; walk this file exists to pin.
;
; `cqrt_x` is a permutation gate `ChainWalk::isInPlaceGateOn` deliberately does
; not recognize, so it is neither an in-place gate the interior DAG would adjoint
; nor a forward producer: the rail is refused and LEFT ALLOCATED (pinned
; independently by lowering_uncompute_interior_leak_route_consumer.ll). It is
; ALSO a NON-use for the guard's clause-3 observing-sink walk (a route moves a
; value onto a work rail and back; nothing is observed — owner ruling
; 2026-08-28, F1), so the record stays DEAD at the gate and the decline stays
; correct physics: an undischarged basis record entangled with the wire when a
; non-diagonal gate fires.
;
; So this file still measures exactly what it always measured — the transitive DESCENDANT walk (a record two hops off the wire) — on a
; program where the record really is still standing. The version WITHOUT the
; `cqrt_x` is now an accept, and lowering_live_record_mb_discharged_accept.ll
; is the twin that pins it.
;
; THAT TWIN IS NOT A PLACEHOLDER — the un-fenced stream was READ, LINE BY LINE,
; in the Increment-5 Rule-13 round (REVIEW lens C) and is sound: `shl_unc(%d, %h, 1); free(%d)` runs before the chained `ry(%h)`, and
; `%d = 2a` on every branch, so the freed rail is |0>.
; The reviewer measured the un-fenced module DECLINING at c36934a and LOWERING
; on this build, so the flip is a real behaviour change that is pinned in BOTH
; directions — this file for the still-standing record, the twin for the lift.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_x(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = shl i32 %q, 1                                          ; INTERIOR record — dead after %e
  call void @cqrt_x(i32 %d)                                 ; see the M-B note above
  %e  = mul i32 %d, 3                                          ; terminal record — measured => exempt
  %m  = call i32 @cq_measure_si32(i32 %e)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)   ; chained, in-place Ry
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
