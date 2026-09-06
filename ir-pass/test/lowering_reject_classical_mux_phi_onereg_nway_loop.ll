; lowering_reject_classical_mux_phi_onereg_nway_loop.ll — DECLINE: N-ary
; one-base merge phi where an arm-i gate can reach the merge through a THIRD
; edge `j` (j != i, AND j != the 1-i complement) whose phi-record OMITS the gate
; (test_C_libtooling-sbt1.3 decline complement; THE PRIMARY silent-miscompile
; guard for Phase 7.1 Increment C — the generalized (7a) over ALL other edges).
;
; This fixture ISOLATES the exact hole a naive arity-2 extension would leave: a
; 2-way lift checks (7a) against ONLY the single `1-i` (== `(i+1)%N`) complement
; edge. With N>2 there is more than one "other" edge. Here the incoming order is
;     i=0 arm1 (FIRES rz on %q) · i=1 arm2 · i=2 def · i=3 stale
; and after firing arm1's rz, a CLASSICAL sub-branch (on %k2, derived from a
; second scrutinee so -O1 cannot fold it) routes either straight to %merge (its
; OWN edge — fine) or into the SHARED block %stale, which enters %merge as a
; THIRD edge whose phi-incoming is the BASE record %q — omitting arm1's rz. So a
; shot that runs arm1, fires rz, then falls into %stale reaches the merge
; claiming the un-rotated %q while the physical register carries the rz:
; verify-clean wrong after the lift.
;
; The 1-i complement of i=0 is i=1 (arm2), which arm1's gate canNOT reach — a
; naive `1-i`-only (7a) check would look at arm2 ONLY, find no reachability, and
; SILENTLY ACCEPT (witnessed: the naive variant lifts this phi; the generalized
; j-loop over ALL j!=i sees arm1 -> stale and refuses). This is the primary
; over-accept guard the increment must NOT have.
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i32 %k, i32 %k2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %k, label %def [                  ; CLASSICAL scrutinee
    i32 1, label %arm1
    i32 2, label %arm2
  ]
arm1:
  %q1 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; fires, then may fall to %stale
  %c2 = icmp eq i32 %k2, 0                                   ; second CLASSICAL condition
  br i1 %c2, label %merge, label %stale
arm2:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.500000e-01)
  br label %merge
def:
  br label %merge
stale:
  br label %merge                              ; THIRD edge: claims base %q, omits arm1's rz
merge:
  %p = phi i32 [ %q1, %arm1 ], [ %q2, %arm2 ], [ %q, %def ], [ %q, %stale ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
