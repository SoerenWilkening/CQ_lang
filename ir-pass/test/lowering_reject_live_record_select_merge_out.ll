; lowering_reject_live_record_select_merge_out.ll — DECLINE: SEVERANCE CLASS 2,
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
;     int a = cq_theta(u0, 0.5);
;     int m = (a > 3) ? 10 : 20;   // tainted-condition data mux
;     int w = cq_theta(m, 0.25);   // T — chained, in-place Ry on the merge out
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
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

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
