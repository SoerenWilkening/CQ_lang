; lowering_reject_live_record_anc_router_phi.ll — WARNING (was DECLINE): the gate reaches its
; wire through a one-register ROUTER PHI (the bd tayx spelling) and the dead
; record is an ANCESTOR of that wire (M-A Increment 3, bd
; test_C_libtooling-6uqc).
;
; The ancestor twin of lowering_reject_live_record_router_phi.ll: same router
; construction, but the record sits UPSTREAM of the wire instead of downstream.
;
; SOURCE SHAPE:
;     cq_theta(&a, 0.5);      // mints %h
;     int d = a * 3;             // out-of-place: THE WIRE; %h stays live
;     if (c) d = cq_phi(d, .25); // CLASSICAL condition (pre-3qlq register form)
;     cq_theta(&d, 0.125);    // T — chained Ry reached through the merge phi
;     return cq_measure(d);
; The 3qlq migration deleted that classical-condition phase; the IR keeps the phi.
;
; WHAT IS STANDING AT THE GATE: `%h`, the `cqrt_alloc_i32`-minted parent of the
; mul rail, never read again, never uncomputed, never freed.
;
; WHY THE PHI IS NOT ITSELF THE PROBLEM, and why that matters here.
; `declineClassicalMuxes`'s one-register merge-phi LIFT (test_C_libtooling-5j5)
; runs at run-line 381, ~90 lines before `lowerRotations`, and proves `%p` a pure
; SSA renaming of the mul rail — so at this LATE slot the recorded `cqrt_ry`'s
; arg-0 already IS the rail and the ancestor walk starts from it with no alias
; closure of any kind. bd tayx measured that a router phi hides a chained theta
; from the position-free wire walks on three separate paths; the ancestor half
; must not be evadable the same way, and it is not — structurally, not by a
; special case. (The guard nonetheless walks phi/select incomings backward, for
; the shapes the lift declines to collapse.)
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0, ONE `cqrt_alloc_i32`, the phi gone
; — the over-accept this closes.
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
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul i32 %q, 3                                           ; the WIRE; %h = DEAD ancestor
  br i1 %c, label %arm, label %merge                           ; CLASSICAL condition

arm:
  br label %merge

merge:
  %p  = phi i32 [ %d, %arm ], [ %d, %entry ]                  ; the one-register router
  %q2 = call i32 @cq_theta_si32(i32 %p, double 1.250000e-01)   ; T — chained Ry THROUGH the phi
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m2
}

; WARN: warning{{.*}}in function example{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@example(
; LOWER: call void @cqrt_ry_i32(i32 %h_op, double 1.250000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.