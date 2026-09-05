; lowering_reject_live_record_sibling_region_after_theta.ll — WARNING (was DECLINE), and this
; is THE F1 fixture (M-A, bd test_C_libtooling-6uqc; owner ruling 2026-08-28:
; "a record exempts only if its lineage reaches an OBSERVING sink after the gate
; — measure / ret / tape / a template read that itself flows to one").
;
; SOURCE:
;     a = cq_theta(a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // a DEAD SIBLING of the wire
;     w = cq_theta(w, 0.5);              // T — chained, in-place Ry on the wire
;     if (c == 5) { c = cq_phi(c, 3.0); }   // a phase region ON THE SIBLING
;     int m  = cq_measure(w);
;     int m0 = cq_measure(a);            // the ANCESTOR is LIVE => exempt
;     return m + m0;                     // ...and NOTHING ever observes `c`
;
; WHAT STANDS AT THE GATE. Three rails: `%h` (the alloc parent), `%h_op1` (`c`)
; and, after the region lowers, `%h_cmp` (the eq flag). `%h_op1` is allocated,
; entangled with the wire (both are basis functions of `%h`), and never
; discharged before `T`. Its ONLY post-gate fate is the compare, whose flag is
; routed through `cqrt_cswap`, stripped by the `_unc`, and freed. Nothing
; c-derived is ever measured, returned or taped: the region computes a phase onto
; a work rail that is immediately thrown away.
;
; WHY IT USED TO ACCEPT, AND WHY THAT WAS WRONG. Clause 3 used to exempt a record
; on ANY post-gate use that was neither teardown nor a recorded user rotation, so
; the compare — and the two `cqrt_cswap` route gates — read as "the program's own
; data". They are not. A ROUTE is not an observation (a routed value comes back to
; its own rail), and a COMPARE whose flag is stripped observes nothing either.
; MEASURED at the pre-fix tree: `opt` exit 0.
;
; THE BEFORE/AFTER ASYMMETRY THIS CLOSES. Move the region one line EARLIER, before
; the gate, and the pre-fix compiler DECLINED it —
; lowering_reject_live_record_anc_dead_sibling.ll is that shape (a dead sibling
; standing under a live, exempt ancestor). Same rails, same physics at the gate,
; opposite verdicts, decided only by where the never-observed region was written.
; The F2 ruling (2026-08-28) eliminated exactly that asymmetry for a bare post-gate
; ROTATION; this fixture is the same ruling applied to the rest of the use grammar.
;
; DISCRIMINATION, one instruction wide: add `int mp = cq_measure(c);` after the
; region and the module LOWERS — that is
; lowering_live_record_sibling_region_then_measured_accept.ll. The compare then
; hops to a rail the user really reads, and `c` is live user data whose dephasing
; is source semantics (the ruled accept).
;
; IR-REACHABLE ONLY. `clang -O1` DCEs an unobserved region on a dead value, so
; this exact SSA does not arrive from that C text (measured in the Inc-3 Rule-13
; round). It is not a lesser fixture for that: the F2 ruling was likewise made on
; constructed probes and chose the DECLINE, on the ground that a register nothing
; observes buys nothing by being accepted, and that the two spellings must get the
; same verdict for the same physics at the gate.
;
; NOTE WHICH RAIL CARRIES IT. `%h_cmp` is minted AFTER the gate, so the F2 skip
; passes over it (it cannot dephase a gate that already fired); `%h` is measured
; after the gate and is exempt. The decline is `%h_op1`, and only `%h_op1`.
;
; `mul` is the vehicle at both hops (information-losing ⇒ never M-C-converted in
; place), so the sibling really is a separate rail and not a second name for the
; wire.
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
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w  = mul i32 %q, 2                                          ; THE WIRE
  %c  = mul i32 %q, 3                                          ; DEAD sibling record
  %q2 = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %cc = icmp eq i32 %c, 5
  br i1 %cc, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e+00)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor LIVE -> exempt
  %r  = add nsw i32 %m, %m0
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