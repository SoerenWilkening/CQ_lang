; lowering_reject_live_record_select_merge_tainted_src.ll — WARNING (was DECLINE): severance
; class 2 again, but with a TAINTED copy SOURCE rather than two constant
; ancillas (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; The companion to lowering_reject_live_record_select_merge_out.ll. There the
; only rails reachable across the copy edge besides the flag were the two
; constant `cqrt_alloc_i32(10)/(20)` ancillas — product states whose decline is a
; deliberate over-decline. Here one arm of the merge is a real computed rail, so
; the copy SOURCE edge carries a genuinely entangled record and the decline does
; not depend on the constant-ancilla reading at all.
;
; SOURCE (a 4-way `switch` that `clang -O1` canonicalizes into arithmetic + a
; single `select` — the SSA below is verbatim what it emits):
;     int a = cq_theta(u0, 0.5);
;     switch (a) { case 0: m=11; case 1: m=22; case 2: m=33; default: m=44; }
;     int w = cq_theta(m, 0.25);
;     return cq_measure(w);
;
; HEAD stream (measured, `opt` exit 0 — the over-accept this closes):
;     %h_op  = cq_template_mul_i32_hl(%h, 11) ; cqrt_addc_i32(%h_op, 11)
;     %h_cmp = cq_template_icmp_ult_i32_hl(%h, 3)
;     %out   = cqrt_alloc_i32(0)
;     cqrt_copy_i32_controlled(%h_cmp, %h_op, %out)      <-- TAINTED src
;     cqrt_x(%h_cmp)
;     %selop = cqrt_alloc_i32(44) ; cqrt_copy_i32_controlled(%h_cmp,%selop,%out)
;     cqrt_x(%h_cmp)
;     cq_template_icmp_ult_i32_hl_unc(%h_cmp,%h,3) ; cqrt_free(%h_cmp)
;     cqrt_ry_i32(%out, 0.25)                            <-- T
; `%h_op` (= 11a+11) and `%h` are both live, dead-at-the-gate basis records of
; the wire `%out`; neither is uncomputed or freed. The Ry over them is dephased.
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
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp ult i32 %q, 3
  %t0 = mul nsw i32 %q, 11
  %t1 = add nsw i32 %t0, 11
  %m  = select i1 %c, i32 %t1, i32 44                          ; merge out, TAINTED true-arm
  %w  = call i32 @cq_theta_si32(i32 %m, double 2.500000e-01)   ; T
  %r  = call i32 @cq_measure_si32(i32 %w)
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
; NOFREEREC-NOT: call void @cqrt_free(i32 %h_op)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.