; lowering_reject_live_record_anc_dead_sibling.ll — WARNING (was DECLINE), and this fixture
; PINS THE SIBLING DECISION (M-A Increment 3, bd test_C_libtooling-6uqc;
; owner-approved default 2026-08-28). Nothing else in the suite turns on it.
;
; SOURCE (`clang -O1` emits this SSA up to strength reduction — a `* 2` arrives as
; `shl nsw …, 1`, which lowers out of place exactly like the `mul` spelled here):
;     a = cq_theta(a, 0.5);
;     int w = a * 2;             // THE WIRE
;     int b = a * 3;             // a SIBLING of the wire, off the same parent
;     int c = b * 7;             // ...whose own product is measured
;     int mc = cq_measure(c);    //    => c is EXEMPT (clause 4)
;     w = cq_theta(w, 0.5);      // T — chained, in-place Ry on the wire
;     int m  = cq_measure(w);
;     int m0 = cq_measure(a);    //    => the ANCESTOR is LIVE (clause 3) — EXEMPT
;     return m + m0 + mc;
;
; WHY THIS ONE NEEDS THE SIBLING CLOSURE AND NOTHING ELSE DOES. Walk the two
; halves separately and the module ACCEPTS:
;   * ANCESTORS of the wire = {`%h`}. `%h` is measured AFTER the gate, so it is
;     LIVE user data and the ruling EXEMPTS it (clause 3 — a live record's
;     dephasing is source semantics).
;   * DESCENDANTS of the wire = {}. Nothing is computed from `%h_op`.
; The rail that is actually standing dead at the gate is `%h_op1` — `b`, a
; DESCENDANT OF THE EXEMPT ANCESTOR. It is entangled with the wire (both are
; basis functions of `%h`), it is never read after the gate, and it is never
; uncomputed or freed. The ruling's clause 1 says "entangled with W —
; TRANSITIVELY, ancestors AND descendants", and the transitive closure is what
; reaches it: seed the descendant walk from every ancestor, not only from W.
;
; DISCRIMINATION, and it is one instruction wide: delete `%b`/`%c`/`%mc` and this
; module becomes lowering_live_record_anc_observed_after_theta_accept.ll, which
; LOWERS. That pair is what makes the sibling claim testable rather than asserted.
;
; `mul` is the vehicle at every hop (information-losing ⇒ never M-C-converted),
; so the sibling really is a separate rail and not a second name for the wire.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0 — the over-accept this closes.
;
;
; ── M-B INCREMENT 5b PRESERVATION NOTE (bd test_C_libtooling-6uqc) ───────────
; The `call void @cqrt_x(i32 %b)` below is NOT part of the shape this fixture
; was written to pin, and it is not decoration either — READ THIS BEFORE
; "simplifying" it away.
;
; Without it, M-B's interior partition now DISCHARGES the dead sibling `%b` — uncomputes it
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
; So this file still measures exactly what it always measured — the ANCESTOR pass plus the descendants-of-every-ancestor pass, the only route that reaches a dead sibling standing under a LIVE ancestor — on a
; program where the record really is still standing. The version WITHOUT the
; `cqrt_x` is now an accept, and lowering_live_record_mb_anc_dead_sibling_accept.ll
; is the twin that pins it.
;
; THAT TWIN IS NOT A PLACEHOLDER — the un-fenced stream was READ, LINE BY LINE,
; in the Increment-5 Rule-13 round (REVIEW lens C) and is sound: `mul_unc(%b, %h, 3)` recomputes `3a` from the borrowed wire and
; XORs it away, so `%b` is |0> on every branch before its `cqrt_free`, and the
; measured sibling `%c` keeps its own record untouched.
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
  %a  = mul i32 %q, 2                                          ; THE WIRE
  %b  = mul i32 %q, 3                                          ; DEAD SIBLING
  call void @cqrt_x(i32 %b)                                 ; see the M-B note above
  %c  = mul i32 %b, 7                                          ; measured => exempt
  %mc = call i32 @cq_measure_si32(i32 %c)
  %q2 = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)   ; T
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor LIVE => exempt
  %r0 = add nsw i32 %m, %m0
  %r  = add nsw i32 %r0, %mc
  ret i32 %r
}

; WARN: warning{{.*}}in function slice{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@slice(
; LOWER: call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h_op1)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.