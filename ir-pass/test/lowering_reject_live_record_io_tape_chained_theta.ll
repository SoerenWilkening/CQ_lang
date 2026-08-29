; lowering_reject_live_record_io_tape_chained_theta.ll — WARNING (was DECLINE). The ORIGINAL
; body of lowering_io_tape_chained_theta.ll, preserved verbatim, now that the M-A
; ANCESTOR half (Increment 3, bd test_C_libtooling-6uqc) declines it. This is
; SPIKE §2R.5's CANONICAL CASE, and it is the ruled outcome, not a surprise.
;
; SOURCE — six lines of ordinary C, the program bd 6uqc's P4 comment describes:
;     int x = cq_theta(seed, 0.5);
;     int y = x * 3;              // OUT OF PLACE (mul is information-losing, so
;                                 // M-C never converts it): a FRESH rail
;     int z = cq_theta(y, 0.25);  // T — chained, in-place Ry on the DERIVED rail
;     printf("%d", z);            // the 7.6 tape write
;
; THE PHYSICS. At `cqrt_ry_i32(%OP, 0.25)` the state is sum_a c_a |a>_H |3a>_OP.
; `%H` is a live basis record of the wire's value: it is never uncomputed before
; the gate, never freed (the 7.6 record FREEZE deliberately withholds the free
; because the rail carries a rotation and is not provably |0>), and never read
; again as user data. `%OP`'s reduced state is therefore diagonal and the Ry
; cannot interfere amplitudes across `a` — the emitted unitary is not the source's.
;
; WHY THE SPINE'S OWN TRAFFIC DOES NOT RESCUE IT — the ruled point, and the whole
; reason this fixture is a negative rather than an accept. `%H`'s only mentions
; after the gate are `cq_template_mul_i32_hl_unc(%OP, %H, 3)` — an `_unc` that
; merely READS `%H` while discharging a DIFFERENT rail — and the adjoint
; `cqrt_ry_i32(%H, -0.5)`. Census 0.1 priced all three readings of the ruling's
; clause 3 side by side (SPIKE §2R.5: 3 / 5 / 8 declining modules) and named this
; program the canonical disagreement; the owner ruled the SPINE-AWARE reading in
; (§2R.5a, approved 2026-08-27): a rail whose sole post-`T` mentions are the
; compiler undoing ITSELF was never user data at `T`. The literal reading is the
; OVER-EXEMPTING one, i.e. it under-declines — the direction the Prime Directive
; exists to stop.
;
; ITS NAMED CUSTOMER IS M-B. The right fix for this program is not a decline
; forever: it is interior-rail uncompute (bd 6uqc option (b), Increments 5/6),
; which would discharge `%H` BEFORE the gate and make the module lower with a
; coherent Ry. Until then the decline is the safe direction and the message tells
; the author what to do — read `x` after the rotation, or drop it.
;
; WHAT REPLACED IT AS THE 7.6 POSITIVE: lowering_io_tape_chained_theta.ll, which
; is this program plus one line — `int w = x * 5;` AFTER the gate, taped — giving
; `%H` an OBSERVING data use after `T` (clause 3) and so restoring the accept by
; principle. Every 7.6 freeze property it pinned is unchanged there; read its
; header for the measurement.
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
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = mul i32 %q, 3                                          ; fresh rail; %H stays live
  %q2 = call i32 @cq_theta_si32(i32 %s, double 2.500000e-01)  ; T
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q2)
  ret void
}

; WARN: warning{{.*}}in function slice{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@slice(
; LOWER: call void @cqrt_ry_i32(i32 %h_op, double 2.500000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.