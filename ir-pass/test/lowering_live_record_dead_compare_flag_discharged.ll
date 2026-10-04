; lowering_live_record_dead_compare_flag_discharged.ll — ACCEPT (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 4). The DELIBERATE RE-DISPOSITION of the
; fixture that used to pin the M-A guard's per-record decline, done the way
; lowering_live_record_derived_cond_theta_discharged.ll was done and for the same
; reason: M-B — the customer that decline NAMED — arrived.
;
;     int f = (a > 5);  cq_theta(&a, 0.25);  m = cq_measure(f);
;
; Two records are minted from the wire:
;   %c -> cq_template_icmp_sgt_i32_hl(%h, 5)   the i1 compare rail
;   %f -> cq_template_zext_i1_to_i32(%c)       the i32 copy the user named
; `%f` IS live — it is measured after the gate — so it is exempt on M-A clause 4,
; exactly as the owner's ruling requires (a live record is user data; its
; dephasing is source semantics), and it is LEFT ALLOCATED, never freed dirty
; (Rule 6). `%c` is dead after the zext, and it is now DISCHARGED: the M-B interior
; partition emits its out-first `_unc` and its `cqrt_free` BEFORE the chained Ry.
;
; WHAT THIS FILE USED TO BE, and why the change is a fix rather than a relaxation.
; As `lowering_reject_live_record_dead_compare_flag.ll` it asserted the M-A guard's
; loud "non-diagonal gate over a live derived record" (a decline until the owner's
; 2026-08-29 ruling, a warning after it), and its own header called that a
; DELIBERATE OVER-DECLINE whose "named customer is M-B (interior-rail uncompute,
; bd 6uqc option (b))". This is that customer arriving. NOT ONE CLAUSE OF THE M-A
; GUARD WAS TOUCHED — the record simply is not standing at the gate any more, so
; clause 2 (`isDischargeOf` matches the out-first `_unc` and the `cqrt_free`)
; exempts it. M-B moves the rails, M-A re-reads the settled module.
;
; WHAT CHANGED IN M-B — and this is the ROUND-4 finding, not a new mechanism. The
; borrowed-parent scan's certificates for "the mutation `M` is outside the
; discharge window" were spelt with `provablyBeforePerActivation`, which bundles a
; `DT.dominates` conjunct that NO step of the window proof uses. Here `At` — the
; discharge point, `getNextNode()` of the zext — IS the chained `cqrt_ry`, i.e.
; `M == At`, and `DT.dominates(At, M)` on one and the same instruction is not a
; question the dominator tree answers usefully. The window lemma's (W2)
; certificate, `everyPathReExecutes(M, At, First)`, places it on the barrier walk
; alone: the Ry cannot reach the discharge point at all, so it can never lie
; strictly inside the window, and the adjoints — inserted BEFORE `At` — have
; already run when it fires. THIS FIXTURE IS THE `M == At` ADJACENCY PIN for that
; leg (its rolled-loop twin is control_swap_inloop_range_cond.ll).
;
; PHYSICS, UNCHANGED AND WORTH KEEPING. `%f = zext %c` is a BIJECTION of `%c`, and
; `%f` is measured; measuring one side of a bijection collapses the other, so the
; dead `%c` carried ZERO INCREMENTAL which-path information and the old decline was
; never a caught miscompile. Do not cite the old file as one. What the discharge
; buys is not a rescued amplitude but a CLEAN CIRCUIT: no undischarged rail
; standing at a non-diagonal gate, and one fewer leaked ancilla.
;
; THE PER-RECORD LESSON IS NOT LOST WITH THE OLD VERDICT. "Exemption is PER RECORD,
; never per wire" is still pinned by lowering_reject_live_record_two_hop.ll (the
; transitivity pin) and by the anc_dead_sibling pair; what this file pins now is
; that a live measured record and a discharged dead one COEXIST in one module —
; `%h_cast` is never freed, `%h_cmp` always is.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREELIVE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 5                                     ; DEAD after the zext
  %f  = zext i1 %c to i32                                      ; LIVE — measured after the gate
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; chained, in-place Ry
  %m  = call i32 @cq_measure_si32(i32 %f)
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; NO M-A warning any more — nothing is standing at the gate. `opt` exits zero.
; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define{{.*}}@example(
; LOWER: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; LOWER-NEXT: %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp)
; The dead compare rail is reversed and freed BEFORE the chained Ry — that
; ORDER is the whole point (owner ruling 2026-08-27: a discharge must never be
; scheduled after a non-diagonal wire gate).
; LOWER-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
; LOWER: call i32 @cqrt_measure_i32(i32 %h_cast)
;
; …and the LIVE record is left allocated, never freed (Rule 6). Its own prefix with
; no positive directive, so the window is the whole module — a free emitted
; anywhere would be caught, and tools/fixture_guard_liveness.py recognizes the
; `NOFREE*` spelling as unanchored-and-therefore-not-dead.
; NOFREELIVE-NOT: call void @cqrt_free(i32 %h_cast)
