; lowering_reject_live_record_spine_only_use.ll — WARNING (was DECLINE): the record's ONLY
; mention after the gate is the SPINE READING it while discharging a DIFFERENT
; rail. This is the defining case of the SPINE-AWARE deadness reading the owner
; ruled on 2026-08-27 (bd test_C_libtooling-6uqc, second ruling point 3; census
; SPIKE §2R.5 / §2R.5a), and it is the ONE fixture that separates that reading
; from the literal one.
;
; THE TWO READINGS, MEASURED ON THIS EXACT MODULE:
;   * LITERAL: clause 3's discharge exception covers only `R`'s OWN discharge, so
;     `cq_template_add_i32_hl_unc(%e, %d, 2)` — which zeroes `%e` and merely
;     READS `%d` — counts as a data use of `%d` and EXEMPTS it. With `%e` already
;     exempt (it escapes via `ret`), NOTHING counts and the module ACCEPTS.
;   * SPINE-AWARE (RULED, and what ships): that `_unc` is the compiler undoing
;     ITSELF, not the user reading data, so `%d` has no user data use after the
;     gate at all. It is DEAD. DECLINE.
; The literal reading is the under-declining one, which is the direction the
; Prime Directive exists to stop: `%d` really is a live, entangled basis record
; of `%q` at the instant the `Ry` fires, and no later spine traffic can undo the
; dephasing that already happened there.
;
; WHY `%e` HAS TO ESCAPE, and it is not decoration. The separation only shows if
; every OTHER rail is exempt, so that the verdict turns purely on how the `_unc`
; is read. `%e` is exempt because `ret` is a plain user data use after the gate;
; `%d` is then the sole candidate. An earlier draft of this fixture ended
; `ret i32 %q2` instead, which left `%e` dead as well — so it declined under BOTH
; readings and pinned nothing. Both verdicts here are MEASURED, on a surrogate
; build with clause 3's teardown test narrowed to `R`'s own discharge (old body:
; declines under both; this body: `opt` exit 0 under literal, exit 1 under
; spine-aware). Note also that MEASURING `%e` instead of returning
; it does not work either: the Phase-5 spine reaches `dead chain would free a
; measured register` first and the module declines with a different message.
;
; ALREADY-LOWERED FORM ON PURPOSE. The `_unc` has to sit AFTER the gate and
; before the wire escapes, which no `.c` spelling can force; the raw
; `cq_template_*` / `_unc` calls here are the same fixture idiom as
; lowering_uncompute_sink_move_past_unwalked_gate.ll. Note the rotations are
; REAL `@cq_theta_si32` calls, so they are emitter-recorded sites — a raw
; hand-written `cqrt_ry` would NOT be one (that is exactly why the census's two
; hand-written-`cqrt_ry` artefacts are invisible to this guard).
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
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = call i32 @cq_template_add_i32_hl(i32 %q, i32 1)         ; DESCENDANT record of the wire
  %e  = call i32 @cq_template_add_i32_hl(i32 %d, i32 2)         ; a record OF the record
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)    ; chained, in-place Ry
  call void @cq_template_add_i32_hl_unc(i32 %e, i32 %d, i32 2)  ; discharges %e, READS %d
  ret i32 %e                                                    ; %e escapes => exempt
}

; WARN: warning{{.*}}in function example{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@example(
; LOWER: call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %d)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.