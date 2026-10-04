; lowering_reject_io_controlled_cmp_blind_staler.ll — DECLINE (Track A.1, Rule-13
; ROUND-2 finding F-A1R2-1). A CONFIRMED silent miscompile at the 7.6 CONTROLLED
; I/O SINK, PRE-EXISTING on `main` 0c7380c, plain `clang -O1` C, single TU:
;
;     void emit(int seed) {                      /* review_a1_r2_probes/io3.c */
;       int q  = seed; cq_theta(&q, 0.5);
;       int r  = seed; cq_theta(&r, 0.25);
;       int r2 = r; cq_theta(&r2, 0.9);          /* staler ON r's WIRE */
;       if (r > 5) printf("%d", q);              /* ctrl = flag minted from r */
;       (void) cq_measure(q);
;       (void) cq_measure(r2);
;     }
;
; WHAT `main` EMITTED (rc 0, verify-clean, STRICT stage 2b `0 violation(s)`):
;     %h1 = cqrt_alloc_i32(%seed)
;     cqrt_ry_i32(%h1, 0.25)                     ; r
;     cqrt_ry_i32(%h1, 0.9)                      ; r2 — IN PLACE on the same rail
;     %h_cmp = cq_template_icmp_sgt_i32_hl(%h1, 5)     ; THE FLAG, post-Ry
;     cqrt_tape_write_i32_controlled(%h_cmp, %tape, %h)
; The source gates on `Ry(0.25)|x>`; the circuit gates on `Ry(1.15)|x>`. A
; different subspace is selected, so the controlled tape entry lands on a
; different set of amplitudes — a different unitary (Rule 2).
;
; WHY NOTHING CAUGHT IT, AND WHAT NOW DOES. `lowerControlledIOSinks` runs BEFORE
; `detectControlRegions`, so no classifier ever walks this condition's wire
; (MEASURED: `IOSinkLowering.cpp` contains no `findNonDiagonalWireGate` and no
; `condWireDisposition`), and `declineStaleRecordOps` excludes branch-condition
; compares on the premise that ArmClassify owns their stale check — which for
; this consumer it does not. `reverifyCmpCondReads` DID reach the mint (its
; record is written by the shared `lowerCompareToFlag`), but rung (iii) exempted
; every gate visible TAINT-BLIND on the ground that "the classifier ruled on it".
; The mint now records `CondReadKind::Unruled`, the exemption is empty for this
; entry, and the position-aware prong then fails at `DT.dominates(EmitPoint, T)`
; — the sibling Ry PRECEDES the mint.
;
; THE PARITY STATEMENT, and it is why this decline is not a new policy: the
; IDENTICAL wire shape at the flat phase kickback declines on BOTH binaries —
; `lowering_reject_phase_kickback_cmp_blind_staler.ll` (probe `io4.c`), which is
; committed beside this file precisely so the two verdicts can be read together.
; The ACCEPT control is `lowering_io_controlled_cmp_other_register_staler.ll`
; (probe `io6.c`): the same module with the staler on a register the condition
; does not name, GREEN on all three binaries.
;
; RED-GREEN: ORACLE (`main` 0c7380c) rc 0 — it ACCEPTS this module — and the
; PRE-ROUND-2 checkpoint b439944 rc 0 as well. The `not` inversion is therefore
; RED on both, which is the whole point of the fixture.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @emit(i32 %seed) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  %c  = icmp sgt i32 %r, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %p = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m1 = call i32 @cq_measure_si32(i32 %q)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  ret void
}

; The string is mirrored character-for-character (Rule 12). A decline writes
; NOTHING to stdout, so this is the one assertion the fixture can make; the
; "no silent fallback" property is pinned by the `not` inversion on the RUN line.
; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
