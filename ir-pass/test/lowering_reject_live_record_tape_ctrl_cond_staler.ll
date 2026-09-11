; lowering_reject_live_record_tape_ctrl_cond_staler.ll — DECLINE. ⚠ THIS FILE WAS
; `lowering_live_record_tape_ctrl_observed_accept.ll`, A SHIPPED ACCEPT, until the
; Track A.1 Rule-13 ROUND-2 fix (finding F-A1R2-1, 2026-09-11). It is `git mv`'d
; rather than deleted, and the header says both what it used to pin and why the
; verdict moved, because a capability pin was LOST here and hiding that in a
; rename is exactly the coverage-overclaim this project files as a defect.
;
; THE PROGRAM IS UNCHANGED (the reviewer's d5 witness, plain `clang -O1` C):
;     static volatile int k = 3;
;     int a = cq_theta(u0, 0.5);
;     int c = a * k;                     // the ONLY record (volatile k so -O1
;                                        //   keeps the multiply)
;     a = cq_theta(a, 0.25);             // T — chained, IN PLACE on the alloc rail
;     if (c > 3) printf("%d", a);        // c -> the CTRL of the guarded tape write
;
; ── WHAT IT USED TO PIN, AND WHAT THAT PIN COST ─────────────────────────────
; It was the sole fixture for the CTRL-slot arm of `reachesObservingSink` (M-A,
; bd test_C_libtooling-6uqc, round 2 of the Increment-3 Rule-13 round,
; 2026-08-28): `cqrt_tape_write_<W>_controlled(ctrl, tape, src)` writes an entry
; IFF `ctrl` is set, so a reader of the output tape learns the flag from the
; PRESENCE OR ABSENCE of the entry — an observation of `c` just as surely as a
; write of `c` would be. That ruling is UNCHANGED and the predicate is untouched;
; what is gone is this program as its witness.
;
; ⚠ AND THE ARM IS NOW UNPINNABLE BY CONSTRUCTION — say it plainly rather than
; leave the next reader hunting for a replacement. The M-A subject requires a
; record whose READ comes AFTER a non-diagonal gate on its wire; the CTRL slot of
; a guarded write IS the region's condition, so that record is the condition; and
; the condition-wire fence (`condWireDisposition` and now this backstop) accepts a
; gate on the condition's provenance wire only when the gate is provably AFTER
; every execution of the read point. "Read after the gate" and "gate after the
; read" cannot both hold, so no straight-line program exhibits the CTRL-slot arm
; and passes the wire fence. The SRC-slot arm keeps its pin
; (`lowering_live_record_sibling_read_taped_accept.ll`) and the toffoli-control
; HOP keeps its own (`lowering_live_record_condtree_toffoli_observed_accept.ll`,
; where the gate rides `w = a*2`'s rail, which is NOT in the condition's cone —
; that file is GREEN here and is the discriminator for this one).
;
; ── WHY IT NOW DECLINES ──────────────────────────────────────────────────────
; `reverifyCmpCondReads` rung (iii). The condition's `condProvenance` cone is
; `{%q, %c}`; `T` is a non-diagonal gate on `%q`'s wire; `T` PRECEDES the flag
; mint, so the position-aware prong cannot prove it post-emission. Until this
; round the gate was exempted as "visible taint-blind ⇒ the classifier ruled on
; it" — but `lowerControlledIOSinks` runs BEFORE `detectControlRegions`, so NO
; classifier ruled on it, and that same exemption was keeping two CONFIRMED
; silent miscompiles open (`lowering_reject_io_controlled_cmp_blind_staler.ll`,
; `lowering_reject_guarded_store_cmp_blind_staler.ll`). The mint now records
; `CondReadKind::Unruled` and the re-ask is unexempted.
;
; ── THE HONEST PART: THIS PARTICULAR CIRCUIT WAS FAITHFUL ────────────────────
; `%c` is an OUT-OF-PLACE `mul` rail, written BEFORE `T`, so the flag
; `cq_template_icmp_sgt_i32_hl(%c, 3)` really did encode the source's `c > 3`.
; The decline is therefore an OVER-DECLINE of this program — and it is PARITY,
; not a new policy, because the identical wire shape at every consumer that DOES
; have a wire clause already declines. MEASURED on the ORACLE (`main` 0c7380c),
; on this program with the sink replaced by a flat phase kickback:
;     %q  = cq_theta(%u0, 0.5)
;     %c  = mul %q, 3
;     %q2 = cq_theta(%q, 0.25)
;     if (%c > 3) cq_phi(0.3)
;   ⇒ ORACLE rc 1, `condition predates a non-diagonal gate` — the same string.
; So the question this file now raises is not "is the backstop too strict?" but
; "should `condWireDisposition` seed rung (iii) from the whole cone, or from the
; compare's DIRECT operand wires (the F-A1-3 distinction) at EVERY consumer?".
; That is a widening of a Rule-13-core predicate in the ACCEPT direction, it is
; older and wider than Track A.1, and it is recorded as an owner question in
; `FIX_A1_R2.md` rather than taken here (Prime Directive).
;
; RED-GREEN: the ORACLE and the pre-round-2 checkpoint b439944 both return rc 0
; on this module, so the `not` inversion is RED on both.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = mul i32 %q, 3                                          ; the ONLY record
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; T — in place on %h
  %cc = icmp sgt i32 %c, 3
  br i1 %cc, label %emit, label %done
emit:
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q2)
  br label %done
done:
  ret void
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
