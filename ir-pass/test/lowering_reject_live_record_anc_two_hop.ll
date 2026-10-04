; lowering_reject_live_record_anc_two_hop.ll — WARNING (was DECLINE): the ancestor closure is
; TRANSITIVE (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     cq_theta(&a, 0.5);
;     int p = a * 3;              // ancestor, ONE producer hop up
;     int b = p * 5;              // the wire
;     cq_theta(&b, 0.5);       // T — chained, in-place Ry on `b`'s rail
;     return cq_measure(b);
;
; THE PIN THAT THE ONE-HOP FIXTURE DOES NOT GIVE: two rails stand at the gate,
; `%h_op` (one hop up, template-minted) and `%h` (two hops up, alloc-minted), and
; BOTH are dead — neither is read again, uncomputed or freed. A backward walk
; that stopped at the immediate producer would still leave `%h` live, so this
; file is the ancestor mirror of lowering_reject_live_record_two_hop.ll's
; descendant transitivity claim.
;
; `mul` is the vehicle at BOTH hops on purpose: it is information-losing and so
; is outside the dtzb in-place bijection family (`inPlaceValueRailOperand`) at
; every M-C batch, which is what keeps two distinct rails in the stream. With
; `add` both hops would convert to `cqrt_addc_i32` and the program would become
; the one-rail shape this fixture is not about.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0 — the over-accept this closes.
;
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

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 3                                          ; ancestor, hop 1
  %b  = mul i32 %a, 5                                          ; the wire
  %q2 = call i32 @cq_theta_si32(i32 %b, double 5.000000e-01)   ; T
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; WARN: warning{{.*}}in function slice{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@slice(
; LOWER: call void @cqrt_ry_i32(i32 %h_op1, double 5.000000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.