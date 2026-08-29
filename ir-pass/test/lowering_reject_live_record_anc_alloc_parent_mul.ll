; lowering_reject_live_record_anc_alloc_parent_mul.ll — WARNING (was DECLINE): the ANCESTOR
; half of clause 1, in its smallest form — a dead `cqrt_alloc_*`-minted PARENT
; (M-A Increment 3, bd test_C_libtooling-6uqc; bd test_C_libtooling-nepx's `h0`
; class, reached through a NON-M-C op).
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     a = cq_theta(a, 0.5);       // source theta: mints the wire
;     int d = a * 3;              // OUT-OF-PLACE — mul is information-losing,
;                                 // so M-C never converts it: a FRESH rail
;     d = cq_theta(d, -0.5);      // T — chained, in-place Ry on the mul rail
;     return cq_measure(d);
;
; WHAT IS STANDING AT THE GATE. `cq_template_mul_i32_hl(%h, 3)` mints `%h_op`
; and KEEPS `%h` — the source rail — allocated and holding |a>. At the chained
; `cqrt_ry_i32(%h_op, -0.5)` the state is sum_a c_a |a>_h |3a>_h_op: `%h` is a
; basis record of the wire's value, `%h_op`'s reduced state is diagonal, and the
; Ry cannot interfere amplitudes across `a`. That is bd nepx's own argument with
; the record on the ANCESTOR side of the producer edge.
;
; WHY INCREMENT 1 MISSED IT, precisely. `collectDescendantRecords` walked FORWARD
; from the wire only, and `%h` is BACKWARD of it: `%h_op`'s producer, not its
; product. Nothing downstream of `%h_op` exists at all here, so the Inc-1 walk
; returned an empty record set and the module lowered.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0, two `cqrt_ry_i32` emitted, zero
; diagnostics — the over-accept this fixture closes.
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
  %d  = mul i32 %q, 3                                          ; fresh rail; %h stays live
  %q2 = call i32 @cq_theta_si32(i32 %d, double -5.000000e-01)  ; T — chained Ry on the mul rail
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
; LOWER: call void @cqrt_ry_i32(i32 %h_op, double -5.000000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.