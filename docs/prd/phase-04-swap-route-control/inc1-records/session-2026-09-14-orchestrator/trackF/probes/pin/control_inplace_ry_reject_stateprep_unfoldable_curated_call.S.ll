; control_inplace_ry_reject_stateprep_unfoldable_curated_call.ll — DECLINE (F2,
; the CONSERVATIVE half, on a `CallBase`). A tainted operand EXACTLY PINNED by
; the edge feeds a call CQ LOWERS TO A RAIL that LLVM refuses to constant-fold.
;
; ⚠ ROUND-4 RULE-13 FINDING (lens R4, F-R4-3 item 1, DOC-FALSE with a MEASURED
; over-accept). F2's header states the conservative rule as "if an instruction
; HAS a tainted operand that is EXACTLY PINNED and we still produce no abstract
; value for it, we DECLINE". That was FALSE for the entire `CallBase` class:
; `f2Model` took `if (!Callee || !canConstantFoldCallTo(CB, Callee)) return
; true;` BEFORE `AnyPinnedOperand` was ever computed, so the rule was not asked
; there at all. The order is now reversed and this file is the red-green.
;
; THE MODULE. `%q` is pinned to `{5}` on the arm edge. `llvm.bswap.i32(5)` is
; 83886080, which IS the seed — so this is a genuine F2 ambiguity, not a
; bookkeeping check. The `nobuiltin` call-site attribute is what makes
; `canConstantFoldCallTo` REFUSE the call (`ConstantFolding.cpp`'s first line);
; MEASURED at the round-3 HEAD: ACCEPT. With the order fixed: DECLINE.
;
; WHY THE FIX IS NOT "DECLINE FOR EVERY UNFOLDABLE CALL". The skip's own
; justification — `clang`'s lattice is overdefined here too, so it cannot have
; substituted the seed FROM this value — is CORRECT for an OPAQUE callee
; (`@cq_theta` / `@cq_phi`, a Phase-6 specialised clone, any declaration), and
; `..._stateprep_post_region_theta_cond.ll` accepts BECAUSE of it. It is not
; correct for a CURATED REVERSIBLE INTRINSIC: those are pure, total functions of
; their operands that CQ lowers to real rails, so "`canConstantFoldCallTo` said
; no" is an artefact of LLVM's fold TABLE — a `nobuiltin` call site here, a
; signature mismatch, or a future curated id LLVM never learned — and not
; evidence that the value is unknowable. The clause therefore asks
; `isCuratedReversibleIntrinsic`, which is the SAME predicate `OpcodeLowering`
; enqueues on, so the "what CQ lowers" set and the "what F2 refuses to guess at"
; set cannot drift (Rule 14).
;
; NO LIVE CUSTOMER TODAY, SAID OUT LOUD. At LLVM 19 all 16 integer idiom ids and
; the 13 curated fp ids ARE `canConstantFoldCallTo`-able (R4's `h/hi01`-`hi16`;
; and `..._reject_stateprep_intrinsic_bswap.ll` declines through the EXACT fold,
; while `..._stateprep_intrinsic_bswap_accept.ll` — the same module without
; `nobuiltin` and with a non-fold seed — ACCEPTS). This is therefore defence in
; depth WITH a red-green fixture, which is the entire point: the shipped shape
; had neither, and `..._unevaluable_pinned_operand.ll` (which uses
; `llvm.fshl`, itself foldable) reaches the operand loop and so cannot witness
; this branch — R4 graded it a WEAK-PIN for exactly that reason.
;
; TWO DIRECTIONS THE RULE STILL CANNOT REACH, recorded rather than implied:
;   * a `load` — the rule keys on `f2Exact` over `I->operands()`, and a `load`'s
;     only operand is a POINTER, never an exactly-pinned integer, so
;     `AnyPinnedOperand` is always false and every `load` is SKIPPED. No
;     reachable customer: a tainted store declines earlier at
;     `declineTaintEscapes` (R4's `p/ld01`, `h/hz03_alloca_load`), and an SROA'd
;     alloca declines at F2 (`p/ld02`).
;   * `extractvalue` and friends — same shape, same skip.
;
;
; ---- STILL A DECLINE AFTER THE 2026-09-11 NARROWING (bd `drbq.14`) ----
;
; F2 was narrowed on 2026-09-11 (owner ruling): a pinned value that lies on the
; CONDITION'S OWN BACKWARD WIRE — `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))` — is
; no longer a collider, and NINETEEN fixtures of this family flipped to ACCEPT
; (they are now `control_inplace_ry_stateprep_*`). **THIS ONE DID NOT, and the
; reason is not an accident:**
;
; THIS DECLINE NEVER REACHES THE EQUALITY TEST AT ALL, so `CondWire` cannot
; and does not narrow it: the evaluation sets `Truncated` and the caller
; declines on that alone. That is SCOPE H-8, and it is the reason no
; `CondWire` check sits on any path that sets `Truncated` — the
; conservative half (what LLVM's own machinery cannot evaluate) must not
; become selectively skippable. ⚠ MEASURED 2026-09-11: under a deliberate
; ANCHOR-spelling mutant this fixture ACCEPTS, because a smaller candidate
; list never trips the bound. That is the second half of the H-6 tripwire.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.bswap.i32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %z = call i32 @llvm.bswap.i32(i32 %q) #0
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 77, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 77, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %rm)
  %m2 = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %m1, %m2
  ret i32 %s
}

attributes #0 = { nobuiltin }
