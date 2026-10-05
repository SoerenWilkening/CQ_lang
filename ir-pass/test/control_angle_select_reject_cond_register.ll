; control_angle_select_reject_cond_register.ll — DECLINE: an in-place Ry on the
; register the CONDITION reads (bd drbq Inc 2b).
;
;     int q = 3; cq_theta(&q,.5);
;     cq_theta(&q, q == 5 ? .9 : .3);
;
; THE STEM SEPARATOR. `control_angle_select_rz_cond_register.ll` applies the
; register-free `cq_phi(q == 5 ? .9 : .3)` instead; that one ACCEPTS and this one
; declines. Read the pair together — it is the whole content of PRD §3c.
;
; An in-place Ry RELABELS the register's computational basis, so after it the
; minted flag is no longer a function of `q`'s basis and the `icmp_..._unc` strip
; cannot return it to |0>. The `cqrt_free` that follows would then be a free of a
; DIRTY, condition-entangled ancilla — a hidden measurement that collapses `q`
; (Rules 6/8). The twin's kickback Rz on the flag moves no basis label of `q`.
;
; WHICH GUARD FIRES, stated because two could: `SelectClassify`'s GATE 2c wins.
; Its prong (a) is position-free — `findNonDiagonalWireGate` over
; `condProvenance(%c)` finds the `cq_theta` on `%q`'s own wire wherever it sits —
; and gate 2c runs BEFORE gate 3's angle hook, so the message is `condition
; predates a non-diagonal gate` rather than S8's `rotation arm on a condition
; wire`. S8 would have refused it too (`%q` is in both the condition closure and
; the base closure); the two fences overlap here on purpose, and the ORDER is what
; picks the message.
;
;
; ── MERGED 2026-09-29 (bd test_C_libtooling-2dfk, exact-duplicate removal) ──
; `control_angle_select_reject_cond_alias.ll` was DELETED: it was this module with this
; file's RUN and CHECK lines byte-for-byte (every non-comment line and every
; directive identical, so it re-ran this exact test). Why: its `qd = cq_phi(q, .1)` alias hop was deleted by the bd 3qlq register-free cq_phi migration, so the module is this one.
; Its unique header prose follows VERBATIM, because it carries the history (and
; any retirement trigger) of the shape it once pinned:
;
; │ control_angle_select_reject_cond_alias.ll — DECLINE: the rotated base is a
; │ DIAGONAL ALIAS of the condition register (bd drbq Inc 2b).
; │
; │ int qd = cq_phi(q, .1);
; │ cq_theta(&qd, q == 5 ? .9 : .3);   // rotates q's OWN physical rail
; │
; │ SSA-value disjointness is NOT wire disjointness: rotation lowering RAUWs
; │ `%qd = cq_phi(%q, .)` and `%q` onto the SAME `cqrt_alloc_i32` handle, so this
; │ Ry lands on the rail the condition reads. Same physics as
; │ `..._reject_cond_register.ll`, one alias hop out.
; │
; │ GATE 2c fires first here too (prong (a) crosses the diagonal `cq_phi` and finds
; │ the `cq_theta` on `%q`'s wire), so the message is `condition predates a
; │ non-diagonal gate`. S8 is the backstop and would name the same rail through
; │ `railWireClosure`'s `cq_phi` hop; neither is redundant — 2c is position-free
; │ over the CONDITION's provenance while S8 intersects two RAIL closures, and the
; │ shapes they cover are only overlapping, not equal.
; │
; │ 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %q, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
