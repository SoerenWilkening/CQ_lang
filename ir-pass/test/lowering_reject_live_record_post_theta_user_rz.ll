; lowering_reject_live_record_post_theta_user_rz.ll — WARNING (was DECLINE) (owner ruling
; 2026-08-28 on the Rule-13 round's F2 finding, bd test_C_libtooling-6uqc). This
; file was the PENDING-RULING accept pin `..._post_theta_user_rz_accept.ll`; the
; ruling came down for the ENUMERATED data-use list, so it is now the negative.
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     cq_theta(&a, 0.5);
;     int c = a + 3;          // ONE record of the wire
;     cq_theta(&a, 0.7);   // T — chained, in-place Ry
;     c = cq_phi(c, 1.0);     // a USER Rz naming the record AFTER T — and NOTHING observes c
;     return cq_measure(a);
;
; THE RULING: a bare post-gate ROTATION on a record is NOT a clause-3 data use.
; A record exempts only if its lineage reaches an OBSERVING sink after the gate
; (measure / ret / tape / a template read that flows to one). A phase written
; onto a register nothing ever observes is unobservable, so it cannot make `%c`
; "the program's own data"; `%c` is a dead, undischarged, entangled record at `T`
; and the module declines — the SAME verdict the rotation-BEFORE spelling
; (`int c = a+3; c = cq_phi(c,1.0); cq_theta(&a,0.7);`) always had, for the
; same physics at the gate (`Rz` is diagonal; it disentangles nothing).
;
; WHAT STILL ACCEPTS, so the boundary is not over-read: rotate `c` and then
; MEASURE it (or return/tape it) — the measure is an observing sink, `%c` is live
; user data, and its dephasing of `T` is source semantics
; (lowering_stale_record_add_before_theta.ll is the ruled accept boundary).
;
; The decline message tells the author exactly what to do: measure `c` or drop
; it. Zero shipped programs are affected (both spellings were constructed
; probes); the change is accept-NARROWING, the safe direction.
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
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %c  = add nsw i32 %q, 3                                      ; the record
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)   ; T — chained, in-place Ry
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; WARN: warning{{.*}}in function main{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@main(
; LOWER: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h_op)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.