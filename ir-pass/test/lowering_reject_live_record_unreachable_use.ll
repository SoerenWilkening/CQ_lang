; lowering_reject_live_record_unreachable_use.ll — WARNING (was DECLINE): a post-gate data use
; in an UNREACHABLE block cannot exempt the record (M-A Increment 1, bd
; test_C_libtooling-6uqc; the Rule-13 round's F3 finding).
;
; Clause 3 exempts a record that some USER reads after the gate, on the ruled
; ground that a live record is the program's own data and its dephasing is source
; semantics. That ground evaporates when the reader is unreachable: nothing ever
; reads `%d`, so it is a dead entangled basis record of the wire at the instant
; the chained `Ry` fires — exactly the shape the guard exists to decline.
;
; THE MECHANISM. `provablyBefore` is `DT.dominates(T, UI) &&
; !isPotentiallyReachable(UI, T)`. Both halves are VACUOUSLY TRUE for an
; instruction in a block with no predecessors — LLVM's dominator tree treats an
; unreachable block as dominated by everything, and nothing is reachable from it
; — so the exemption was granted by a use that can never execute. The fix adds
; the explicit `DT.isReachableFromEntry(UI->getParent())` test; unproven
; reachability now means NO exemption (Prime Directive).
;
; FIXTURE-ONLY TODAY, on purpose. `clang -O1` deletes unreachable blocks, so no
; `.c` spelling reaches this; the shape is written directly, the same idiom as
; lowering_uncompute_sink_move_past_unwalked_gate.ll. It is committed anyway
; because an unreachable block is reachable INSIDE the pass — Phase-4 flattening
; and the 7.4 break reverse-play both detach blocks mid-pipeline, and this guard
; runs after all of them.
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

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = add i32 %q, 1                                          ; DEAD record of the wire
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; chained, in-place Ry
  ret i32 %q2

dead:                                                          ; no predecessors
  %m = call i32 @cq_measure_si32(i32 %d)                       ; a use that can never run
  ret i32 %m
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
; NOFREEREC-NOT: call void @cqrt_free(i32 %h_op)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.