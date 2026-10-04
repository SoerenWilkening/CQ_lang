; lowering_reject_live_record_clone_call_hop.ll — WARNING (was DECLINE): the record closure
; must walk THROUGH a Phase-6 clone call (M-A Increment 1, bd
; test_C_libtooling-6uqc; the Rule-13 round's F1 blocker).
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     __attribute__((noinline)) static int inner(int x){ return x + 3; }
;     cq_theta(&a, 0.5);
;     int r = inner(a);        // clone-call hop
;     int s = (r > 100);       // a 1-bit compare of the clone's result
;     int m = cq_measure(s);   // only that ONE bit leaves
;     cq_theta(&a, 0.7);    // <-- THIS GATE
;
; THE DEFECT THIS PINS. `collectDescendantRecords` follows PRODUCER edges, and a
; non-void `__cq_q_<inner>_<mask>` clone call is not a producer by clause 1's
; families — so before the fix the walk STOPPED at the call and every record
; downstream of it was invisible. Measured at HEAD-before-fix: this module
; compiled end to end (`opt` exit 0, `free_pairing_check.py` 0 violations) while
; the semantically IDENTICAL inline spelling — `int r = a + 3;`, no call hop —
; declined. A clone call is a value-preserving hop, not a coherence boundary:
; putting `x + 3` behind a `noinline static` cannot change what the wire is
; entangled with, so a guard that answers differently for the two spellings is
; over-accepting one of them.
;
; WHAT CARRIES THE DECLINE. The clone returns a fresh `cqrt_alloc`-minted
; `cqq.out` rail (Bennett-wrapped: compute, `cqrt_copy_i32` out, uncompute).
; `cq_template_icmp_sgt_i32_hl` of THAT rail is a genuine clause-1 record, its
; only reader is the `zext` that precedes the gate, and nothing uncomputes or
; frees it — so it is live and entangled with the wire when the second `Ry`
; fires. The `zext` rail itself is exempt (measured before the gate, clause 4).
;
; THE CLONE'S OWN RESULT is NOT counted — the walk traverses it without
; recording it. That rail is `cqrt_alloc`-minted and written by a VOID
; `cqrt_copy_i32`, i.e. the copy-destination class named in
; `RotationLowering.h`'s scope note and deferred with the ancestor half
; (Inc 3 / Inc 4). Recording it here would be a scope widening, not a fix.
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

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)                        ; CLONE HOP — value-preserving
  %c  = icmp sgt i32 %r, 100                                  ; DEAD record of the clone result
  %f  = zext i1 %c to i32                                     ; measured => exempt
  %m  = call i32 @cq_measure_si32(i32 %f)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; chained, in-place Ry
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %s  = add nsw i32 %m2, %m
  ret i32 %s
}

define internal fastcc i32 @inner(i32 %x) {
  %a = add nsw i32 %x, 3
  ret i32 %a
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
; NOFREEREC-NOT: call void @cqrt_free(i32 %r)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.