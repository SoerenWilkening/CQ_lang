; control_swap_reject_select_theta_alias_cond.ll — DECLINE (bd big5, 2026-07-31).
; THE ADVERSARIAL PROBE THAT PAIRS WITH THE WIDENING (Rule 12: every accept-
; predicate ships with a decline fixture). It is the exact twin of
; control_swap_accept_select_rail_alias_cond.ll with ONE token changed —
; `cq_phi` → `cq_theta` — and it must NEVER lower.
;
; WHY THE ACCEPT IS SOUND, STATED AS THE INVARIANT THIS FIXTURE ENFORCES. The
; aliased-condition accept rests on the alias being created by a DIAGONAL gate:
; `cq_phi` (Rz) leaves the BASIS LABEL of the rail untouched, so `%q` and
; `%r = cq_phi(%q,·)` denote the SAME basis value and collapsing `icmp slt(a,a)`
; to a constant is the CORRECT answer, not an approximation.
;
; SWAP IN A NON-DIAGONAL GATE AND THAT STOPS BEING TRUE. `cq_theta` on an ALREADY
; TAINTED operand is an in-place Ry that ALSO RAUWs the chain to one handle
; (RotationLowering.cpp), so `%q` and `%r = cq_theta(%q,·)` are likewise ONE RAIL —
; but Ry CHANGES the basis, so the source means "the pre-Ry record vs the post-Ry
; record", two genuinely different logical values. Lowering that to
; `cq_template_icmp_slt_i32(%h, %h)` == constant FALSE would be a VERIFY-CLEAN
; SILENT MISCOMPILE. It is the one aliased shape where the Case-A degeneracy is
; not merely a cheap circuit but a WRONG ANSWER.
;
; WHO OWNS THE DECLINE, AND WHY THAT IS WORTH RECORDING. Not the reverted fence —
; `operandsAlias` (SelectClassify.cpp) walks `cq_phi` calls only, so it never saw
; this shape either. It is ArmClassify's gate 2c (`findNonDiagonalWireGate`), the
; STALE-CONDITION guard introduced by kjd1 for an unrelated reason. Before this
; fixture, the widened accept's most dangerous neighbour was protected by a guard
; nobody had connected to it, and every committed `stalecond` fixture used a
; NON-aliased condition (`icmp sgt i32 %q, 5`). This turns an accidental
; interaction into a stated, tested invariant. Found by the bd big5 Rule-13 round.
;
; MEASURED: this input declines identically under all three pinned plugins — the
; pre-revert HEAD, the reverted tree, and dd2c103^ — so the widening did not move
; it, and this fixture pins that it stays put.
;
; 3qlq (note added 2026-10-04, bd v7oh): `%r = cq_phi(%q,·)` above is the RETIRED
; register form. bd 3qlq made `cq_phi` register-free, and the accept twin's alias was
; deleted as a global phase (its own `3qlq:` note). This fixture never contained a
; `cq_phi`; its `cq_theta` decline is unchanged.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
;
; Nothing may be emitted — above all not the constant-FALSE flag that would be the
; wrong answer here:
; NOLOWER-NOT: cq_template_icmp_slt_i32
; NOLOWER-NOT: cqrt_copy_i32_controlled
; NOLOWER-NOT: cqrt_cswap
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOLOWER
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)  ; in-place Ry: SAME
                                                             ; rail, NON-diagonal
  %c = icmp slt i32 %q, %r                                   ; two DIFFERENT
                                                             ; logical records
  %s = select i1 %c, i32 11, i32 22
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
