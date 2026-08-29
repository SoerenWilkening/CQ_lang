; lowering_reject_live_record_condtree_out_unobserved.ll — WARNING (was DECLINE), and this is the
; DISCRIMINATOR for the condition-tree hop added in round 2 of the Increment-3
; Rule-13 round (M-A, bd test_C_libtooling-6uqc, 2026-08-28).
;
; SOURCE — lowering_live_record_condtree_toffoli_observed_accept.ll's C, MINUS ONE
; INSTRUCTION (`cq_measure(m)` is gone; nothing ever reads the merge result):
;     int a = cq_theta(u0, 0.5);
;     int b = cq_theta(u0 + 1, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * k;                     // the DEAD sibling record
;     w = cq_theta(w, 0.25);             // T
;     int m = ((c > 3) & (d < 9)) ? 10 : 20;   // computed, never observed
;     return cq_measure(w) + cq_measure(a) + cq_measure(b);
;
; WHAT STANDS AT THE GATE. The same two rails as the accept twin: `%h` (the alloc
; parent, measured after the gate, exempt) and `%h_op4` (`c`). Everything the
; select mints — `%h_cmp`, `%h_cmp1`, `%g`, `%out`, the two `%selop` constants —
; is minted AFTER `T` and skipped by the clause-6 existence test. The verdict is
; `%h_op4`, and only `%h_op4`.
;
; WHY IT DECLINES — AND THIS IS EXACTLY WHAT THE NEW HOP MUST *NOT* DO. The walk
; runs the whole chain the accept twin runs:
;     c --(icmp_sgt HOP)--> %h_cmp1 --(cqrt_toffoli CONTROL, the new HOP)--> %g
;       --(cqrt_copy_i32_controlled CTRL slot, a HOP)--> %out
; and then STOPS. `%out`'s only remaining users are the two controlled copies that
; WRITE it (it is their destination, not their source or control — no hop) and
; nothing else: no measure, no return, no tape. The hop reached the out rail; the
; out rail is not a sink. Under the ruled clause 3 — "a record exempts only if its
; lineage reaches an OBSERVING sink after the gate" (owner 2026-08-28) — `c` is
; unobserved and the module DECLINES.
;
; WITHOUT THIS FIXTURE the accept twin reads as "a condition-tree gate exempts
; whatever flows into it", which is the retired MENTIONED-LATER reading the F1 fix
; removed. The pair is what pins the hop as a HOP and not as a sink.
;
; VERDICTS, MEASURED: pre-round-2 tree `opt` exit 1, post-fix `opt` exit 1 — this
; fixture is unchanged by the fix, which is the point of it. (Its accept twin went
; 1 -> 0 on the same tree pair.)
;
; NOTE THE `select` SURVIVES ITS DEAD RESULT. `SelectClassify`/`SelectMergeEmit`
; lower a tainted-condition select whether or not anybody reads the merge, so the
; whole condition network really is emitted here — measured, not assumed. This is
; therefore a genuine "hop reaches, nothing observes" module and not a module where
; the network was optimised away before the guard ran.
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
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %u1  = add nsw i32 %u0, 1
  %b   = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)  ; a SECOND wire
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %c   = mul i32 %q, 3                                          ; DEAD sibling record
  %q2  = call i32 @cq_theta_si32(i32 %w, double 2.500000e-01)   ; T
  %cc  = icmp sgt i32 %c, 3
  %cd  = icmp slt i32 %b, 9
  %cnd = and i1 %cd, %cc                                        ; AND node -> toffoli
  %m   = select i1 %cnd, i32 10, i32 20                         ; the merge OUT rail...
  %m1  = call i32 @cq_measure_si32(i32 %q2)                     ; ...which NOBODY reads
  %m2  = call i32 @cq_measure_si32(i32 %q)
  %m3  = call i32 @cq_measure_si32(i32 %b)
  %a2  = add nsw i32 %m1, %m2
  %a3  = add nsw i32 %a2, %m3
  ret i32 %a3
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
; NOFREEREC-NOT: call void @cqrt_free(i32 %h_op4)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.