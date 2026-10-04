; lowering_measure_taint_fold_control.ll — the ONE-TOKEN CONTROL for
; `lowering_measure_undef_operand_after_taint_fold.ll`, and the reason that
; fixture is not vacuous.
;
; bd test_C_libtooling-fve8, owner ruling 2026-09-15 `DECISIONS.md` E9; the
; Rule-13 round's P1 `F-E2-1` (`review_r13_e2/REVIEW.md` §1, probe
; `y1_min_control.ll`).
;
; This is the SAME module as that fixture with the measure operand spelled `%1`
; — the theta's result — i.e. the program the source names once `u` is
; initialised:
;
;     int u = 0; int q = 0; cq_theta(&q, 0.3); return cq_measure(q + u);
;
; ⚠ IT ACCEPTS ON **BOTH** BINARIES (session ORACLE `cq-opt` 0e280fc6 and the
; `fve8` subject) and it emits the user's measurement. That is the whole job of
; this file: it holds everything fixed except the one token, so the ABSENCE of
; `cqrt_measure` in the other fixture is attributable to the `-O1` fold that
; erased the taint, and to nothing else about the module. A fixture pair one
; token apart is the only form of that claim that cannot rot into an assertion.
;
; ⚠ DO NOT "TIDY" THE TWO FILES INTO ONE. `LLVMContext::diagnose` EXITS on the
; first `DS_Error` (bd `br4a`), and more importantly the pair's value is that
; each module is a MUTANT of the other: run this module against the other
; fixture's `NOMEASURE` prefix and it goes RED; run that module against this
; file's `CHECK` and it goes RED.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOINTR < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main() {
  %1 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = call i32 @cq_measure_si32(i32 noundef %1)
  ret i32 %2
}
; CHECK-LABEL: define i32 @main()
; CHECK:         %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:         call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
; CHECK:         %m = call i32 @cqrt_measure_i32(i32 %h)
; CHECK:         ret i32 %m

; ── WHOLE-FILE PREFIXES (Rule 12 (a): counts in their own prefix) ─────────────
; one rail, one rotation, and EXACTLY ONE measurement gate — the user's:
; COUNT-COUNT-1: call i32 @cqrt_alloc_i32(i32 0)
; COUNT-NOT: call i32 @cqrt_alloc_i32(i32 0)
; COUNT-COUNT-1: cqrt_ry_i32(i32 %h
; COUNT-NOT: cqrt_ry_i32(i32 %h
; COUNT-COUNT-1: call i32 @cqrt_measure_i32(i32 %h)
; COUNT-NOT: call i32 @cqrt_measure_i32(i32 %h)
;
; NOINTR-NOT: call{{.*}}@cq_measure_
; NOINTR-NOT: call{{.*}}@cq_theta_
;
; ACC-NOT: undef/poison literal
; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: warning
