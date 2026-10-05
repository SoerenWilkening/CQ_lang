; lowering_reject_live_record_two_hop.ll — WARNING (was DECLINE): a dead INTERIOR record, two
; producer hops from the wire (M-A Increment 1, bd test_C_libtooling-6uqc).
;
; SOURCE: `cq_theta(&a,0.5); int d = a+3; int e = d*2; m = cq_measure(e);
;          cq_theta(&a,0.5);` — `clang -O1` reassociates `(a+3)*2` into
; `shl`+`add 6`, which is the SSA below.
;
; WHAT THIS PINS THAT THE ONE-HOP FIXTURE DOES NOT: the record closure is
; TRANSITIVE. The terminal record `%e` is EXEMPT — it is measured before the
; gate (clause 4) — so a guard that only looked one producer hop from the wire
; would accept. The violation is the INTERIOR rail `%d`, which is a record of a
; record, has no user at all after `%e`, and is never uncomputed or freed: it is
; live and entangled with `%h` when the second `Ry` fires.
;
; RETIRED INTO THIS FILE (bd jttf, 2026-10-05):
; lowering_reject_live_record_sibling_alias.ll (M-A Increment 1), whose chained
; theta named the DIAGONAL SIBLING `%qd = cq_phi(%q, ·)` of the wire its record
; was built from (pre-3qlq register form). The 3qlq migration deleted that alias,
; which left the same structure as this file (a dead interior record behind the
; same `cqrt_x` fence, a `mul` terminal measured before the chained Ry, the same
; warning) with `add %q, 3` for `shl %q, 1`. A register-free phase creates no
; sibling SSA name, so its subject has no spelling. Its un-fenced twin
; lowering_live_record_mb_sibling_alias_accept.ll was re-spelled with a branch
; phase on the wire instead.
;
; PHYSICS HONESTY — WHAT THIS FIXTURE DOES AND DOES NOT DEMONSTRATE. It pins the
; STRUCTURAL rule (the record closure is transitive; a one-hop walk under-declines),
; NOT an incremental physical harm in this module. `%e = %d + 6` is a BIJECTION of
; `%d`, and `%e` is MEASURED before the gate — so measuring `%e` collapses `%d`
; too, and at `T` the interior rail holds a definite basis value carrying ZERO
; INCREMENTAL WHICH-PATH INFORMATION beyond what the measurement already
; extracted. (The WIRE is only partly collapsed — `shl i32 %q, 1` is 2-to-1, so
; one bit of `%q` survives — but that residual coherence lives in `%q`, not in
; `%d`.) So this decline is a KNOWN, DELIBERATE OVER-DECLINE whose named customer
; is M-B (interior-rail uncompute, bd 6uqc option (b)). The guard's predicate is
; local and structural on purpose; bijection-collapse is a whole-stream property it
; cannot see. Do not cite this file as a caught miscompile — cite it as the
; transitivity pin. Its former companion in this paragraph,
; lowering_reject_live_record_dead_compare_flag.ll, has since had that customer
; ARRIVE and ships as lowering_live_record_dead_compare_flag_discharged.ll (bd
; 8h7d.5 Rule-13 round 4). This one has not: `%d` is a `mul` rail two hops up whose
; own component the interior partition still leaves borrowed.
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
;
; ⚠ NOW A WARNING, NOT A DECLINE — owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, shipped as M-A Increment 7b): "we can always apply any
; unitary operation we want … it is the user's fault to have produced a badly
; functioning code" (Rule 17). The dephasing-by-leftover-record class is the
; USER's circuit, so `opt` prints `warning: …`, exits ZERO, and hands back the
; lowered module. THE ANALYSIS AND THE MESSAGE STRING ARE UNCHANGED — only the
; severity moved, so everything this header says about WHY the record counts
; still holds verbatim. The record is LEFT ALLOCATED and never freed (Rule 6 is
; untouched: nothing frees a rail that is not provably |0>), which the
; `NOFREEREC` prefix below pins alongside the gate that IS now emitted. The file KEEPS its
; `reject_` name deliberately — see RotationLowering.h, which also states what
; the ruling does NOT cover (every wrong-value and dirty-free guard stays loud).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEREC < %t.cqd0.ll
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

; WARN: warning{{.*}}in function slice{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@slice(
; LOWER: %m3 = call i32 @cqrt_measure_i32(i32 %h_op1)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h_op)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.