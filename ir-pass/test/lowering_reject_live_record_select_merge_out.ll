; lowering_reject_live_record_select_merge_out.ll — WARNING (was DECLINE): SEVERANCE CLASS 2,
; the 4.4 SELECT-MERGE out rail, closed by M-A Increment 3 (bd
; test_C_libtooling-6uqc).
;
; ⚠ READ THIS FIRST — IT CORRECTS A MEASURED CLAIM IN THE INCREMENT-1 NOTES.
; `RotationLowering.h`/`.cpp` said severance classes (2) and (3) "ARE masked
; today" by bd test_C_libtooling-lom0's unrelated position-free over-decline, on
; a measurement of the two natural C spellings. THAT IS FALSE FOR THE SELECT
; SPELLING, and this file is the witness: measured at HEAD before Increment 3
; this module compiles end to end, `opt` exit 0. `SelectClassify` DOES run a
; position-free wire walk of its own (SelectClassify.cpp ~691, lom0's mechanism
; transplanted), but it is seeded from the CONDITION's provenance; the merge OUT
; is a fresh `cqrt_alloc`-minted rail off that wire, so a chained theta on the
; OUT is invisible to it and there was no mask here at all.
; It was a LIVE over-accept reachable from three lines of ordinary C. Increment 3
; closes it; Increment 4 must not be planned as if it were the one lifting a mask.
;
; SOURCE (`clang -O1` emits exactly the SSA below — a `?:`, not a diamond):
;     int a = u0; cq_theta(&a, 0.5);
;     int m = (a > 3) ? 10 : 20;   // tainted-condition data mux
;     int w = m; cq_theta(&w, 0.25);  // T — chained, in-place Ry on the merge out
;     return cq_measure(w);
;
; WHAT IS STANDING AT THE GATE, from the HEAD stream:
;     %h      = cqrt_alloc_i32(%0) ; cqrt_ry_i32(%h, 0.5)
;     %h_cmp  = cq_template_icmp_sgt_i32_hl(%h, 3)
;     %out    = cqrt_alloc_i32(0)
;     %selop  = cqrt_alloc_i32(10) ; cqrt_copy_i32_controlled(%h_cmp,%selop,%out)
;     cqrt_x(%h_cmp)
;     %selop1 = cqrt_alloc_i32(20) ; cqrt_copy_i32_controlled(%h_cmp,%selop1,%out)
;     cqrt_x(%h_cmp)
;     cq_template_icmp_sgt_i32_hl_unc(%h_cmp, %h, 3) ; cqrt_free(%h_cmp)
;     cqrt_ry_i32(%out, 0.25)            <-- T
; The FLAG is stripped and freed, correctly — but `%h`, the source rail, is
; never uncomputed, never freed and never read again, and `%out` is a basis
; function of `%h` (10 or 20 according to `a > 3`). At the chained Ry the wire's
; reduced state is diagonal: the rotation acts on a mixture, not on the
; superposition the source wrote.
;
; WHY THE WALK REACHES IT. `%out` is `cqrt_alloc_i32`-minted and written only by
; VOID `cqrt_copy_i32_controlled` gates, so there is no producer edge to follow —
; the severance. Increment 3 adds the two edges that cross it: from a rail that
; is the DESTINATION (last) operand of a void copy, walk backward to the SRC and
; to the CONTROL flag. The flag `%h_cmp` is itself EXEMPT (clause 2 — `_unc`'d
; and freed before the gate), but the walk continues THROUGH it to its own
; operand `%h`, which is not, and `%h` carries the decline. The `%selop`/`%selop1`
; constant ancillas are reached on the same edge and are also dead.
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
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  %m = select i1 %c, i32 10, i32 20                            ; 4.4 controlled-XOR copy merge
  %w = call i32 @cq_theta_si32(i32 %m, double 2.500000e-01)    ; T — chained Ry on the merge out
  %r = call i32 @cq_measure_si32(i32 %w)
  ret i32 %r
}

; WARN: warning{{.*}}in function slice{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@slice(
; LOWER: call void @cqrt_ry_i32(i32 %out, double 2.500000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.