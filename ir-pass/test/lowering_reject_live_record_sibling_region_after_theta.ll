; lowering_reject_live_record_sibling_region_after_theta.ll — DECLINE, and this
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %cz = call i32 @cq_phi_si32(i32 %c, double 3.000000e+00)
  br label %merge
merge:
  %p  = phi i32 [ %cz, %arm ], [ %c, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor LIVE -> exempt
  %r  = add nsw i32 %m, %m0
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
