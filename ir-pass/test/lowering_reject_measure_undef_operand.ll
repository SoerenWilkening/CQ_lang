; lowering_reject_measure_undef_operand.ll
;
; ⚠ THE FILENAME IS HISTORICAL AND IS KEPT ON PURPOSE. This module was a
; DECLINE from bd test_C_libtooling-21mg (2026-09-13) until the owner's ruling
; of 2026-09-15 (bd test_C_libtooling-fve8, `DECISIONS.md` E2) RETIRED clause 4
; for a whole-value `undef`/`poison` at the sink. It is now an ACCEPT. The name
; is NOT changed: bd `gahu` / CLAUDE.md L8 — a `git mv`'d fixture can be
; RESURRECTED by a merge, which would put one module under two names with
; contradictory verdicts, invisible to every review that ran before the merge.
; Rename only in a change that has no merge in front of it.
;
; ── THE RULING, AND WHAT IT RETIRED ─────────────────────────────────────────
; `cq_measure` of an `undef`/`poison` operand measures THE TYPE'S CONCRETE ZERO,
; in EVERY spelling. The asymmetry it closes is measured: bd `z9t1`'s
; `normalizeUndefRotationSeed` deleted the `undef` UPSTREAM of this sink, so the
; phi-routed spelling already compiled (4 of 710 rows, exit 1 -> exit 0, 0 bytes
; of stderr, each byte-identical to its written-zero twin), while the DIRECT
; spelling below still declined. Two well-formed C programs that differ only in
; whether `-O1` routed the value through a phi got different verdicts.
;
; ⚠ THE RAUW TARGET IS `Constant::getNullValue(Measure->getType())`, NOT THE
; OPERAND, and this file can see the difference: RAUW-to-operand leaves
; `ret i1 undef`, RAUW-to-zero leaves `ret i1 false`. The `NOCLASSICAL` prefix
; pins the first spelling out. (The stronger discriminator, where the outcome
; feeds an `add`, is `@f_beside_quantum` in
; `lowering_accept_measure_undef_zero.ll`.)
;
; ⚠ WHAT DID *NOT* RETIRE — the string is still live and still has a customer.
; `valueCarriesUndef` walks INTO a referenced global's initializer
; (`carriesUndefImpl(..., SkipGlobals=false)`), so a FULLY DEFINED operand whose
; global merely CONTAINS an `undef` field still declines on the same message.
; That residual is pinned by `lowering_reject_measure_undef_global_init.ll`.
; Only the whole-value `isa<UndefValue>` spelling is retired — bd `z9t1`'s own
; conjunct, verbatim in shape, for the identical reason: the predicate gates a
; DECLINE everywhere else and a REWRITE here.
;
; RED-GREEN: on the session ORACLE (`main` 74eabd2c, `cq-opt` 0e280fc6) this
; module DECLINES with
; `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement
; needs a defined value`, so this file is RED there on the EXIT CODE (the first
; RUN line has no `not`). It must stay an ACCEPT, with `ret i1 false`, on every
; later binary.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCLASSICAL < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i1 @cq_measure_i1(i1)

define i1 @undef_operand() {
entry:
  %m = call i1 @cq_measure_i1(i1 undef)
  ret i1 %m
}

; CHECK-LABEL: define i1 @undef_operand()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 false

; ── WHOLE-FILE NEGATIVE PREFIXES (Rule 12 (a): a negative prefix stays PURE; a
; positive count inside one WINDOWS every negative after it) ──────────────────
;
; the classical measure mints NOTHING — no rail (minting one for classical data
; is the f64/angle miscompile family), no measurement gate, no trace line:
; NOCLASSICAL-NOT: cqrt_alloc
; NOCLASSICAL-NOT: cqrt_measure_
; NOCLASSICAL-NOT: cqrt_ry
;
; the front-end intrinsic is GONE (Rule 1's checked postcondition,
; `declineSurvivingIntrinsicCalls`):
; NOCLASSICAL-NOT: call{{.*}}@cq_measure_
;
; and the RAUW target was the TYPE'S ZERO, not the operand. ⚠ NOT a bare
; `-NOT: undef`: this module's own `; ModuleID`/`source_filename` lines carry the
; word in the FILE PATH, which is bd `qta2`'s vacuity trap.
; NOCLASSICAL-NOT: ret i1 undef
;
; the whole module accepts, and it does so SILENTLY — the owner ruled twice
; against a warning on this family ("both codes are supposed to compie!! also no
; warnings"), so stderr must be empty, not merely non-fatal:
; ACC-NOT: undef/poison literal
; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: warning
