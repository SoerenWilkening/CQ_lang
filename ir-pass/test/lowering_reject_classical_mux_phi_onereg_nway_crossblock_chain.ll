; lowering_reject_classical_mux_phi_onereg_nway_crossblock_chain.ll — DECLINE:
; N-ary one-base merge phi whose gate chain ESCAPES its incoming block
; (test_C_libtooling-sbt1.3 decline complement; pins condition (6) under N>2).
;
; All 3 incomings resolve to the one base %q — but the arm2 incoming's chain is
; {%q2b in %arm2, %q2a in %entry}: the %q2a = cq_phi(%q, x) gate fired BEFORE the
; switch, unconditionally, on every path. The arm1 incoming %q1 then claims a
; record (q rotated by 0.25 only) that the physical register never holds in
; isolation (it always carries the pre-branch %q2a rz too), and the default %q
; claims the pre-%q2a record: stale on every path. Accepting + RAUW to %q would
; be the verify-clean wrong-unitary class, so the single-block-arm condition (6)
; (every chain call's parent == its edge's incoming block) refuses — the %q2a
; gate sits in %entry, not in %arm2 — and the wi5 decline fires.
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

define i32 @main(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2a = call i32 @cq_theta_si32(i32 %q, double 1.250000e-01)   ; pre-branch gate
  switch i32 %k, label %merge [               ; CLASSICAL scrutinee
    i32 1, label %arm1
    i32 2, label %arm2
  ]
arm1:
  %q1 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)
  br label %merge
arm2:
  %q2b = call i32 @cq_theta_si32(i32 %q2a, double 7.500000e-01) ; chain escapes block
  br label %merge
merge:
  %p = phi i32 [ %q, %entry ], [ %q1, %arm1 ], [ %q2b, %arm2 ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
