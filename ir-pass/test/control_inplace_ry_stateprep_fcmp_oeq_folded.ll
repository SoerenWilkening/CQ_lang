; control_inplace_ry_stateprep_fcmp_oeq_folded.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_fcmp_oeq_folded.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     double t = q * 2.0;  double r = 5.0;  if (t == 5.0) r = cq_theta(5.0, .9);
;
; ---- WHY IT IS AN ACCEPT NOW (bd `drbq.14`; F2's `CondWire` narrowing)
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`.
; also WE DO NOT WANT ANOTHER cq function. it should just be an
; application of gates … I dont see the need for the over-decline."* The
; trade below was put to the owner plainly and was not vetoed.
;
; F2 no longer treats a pinned value that lies on the CONDITION'S OWN
; BACKWARD WIRE as a collider. The pin here was **%t (the fcmp's tainted
; operand, via the fp ANCHOR)**, found on the
; **arm edge**; it is in `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))`,
; the set built at the caller by calling R4's own helper.
;
; THE READING THE IR NOW GETS — the drbq Inc-4 state-prep stream, unchanged:
;   `i32 @cqrt_alloc_f64(double 5.000000e+00)` at the hoisted theta (a FRESH
; rail,
;   carrying the SEED, never |0> unless the seed is), then one
;   `cqrt_ry_f64_controlled(f, %h1, 9.000000e-01)`, the ordinary flag
;   mint / `_unc` strip / free, and the prepped rail **FROZEN** — never
;   uncomputed and never freed, because a controlled gate's adjoint needs
;   its control and the flag is freed inside the region. The condition
;   register is not touched by the region at all.
;
; THE RIVAL IT SILENTLY ABSORBS (alpha reading): the source rotated the
; CONDITION'S OWN register IN PLACE — `cq_theta(<the pinned register>, θ)` —
; and `-O1` const-folded arg-0 to the literal on the edge where the equality
; is a theorem.
; ⚠ SAY IT IN THOSE WORDS: a program that was LOUDLY REFUSED before this
; ruling now receives the circuit for the OTHER reading, with no
; diagnostic. That is the trade, and it is disclosed rather than fenced —
; no fence exists, because after `-O1` the two sources are ONE module.
;
; WHAT MAKES IT ADMISSIBLE — the rival has no lowering to be robbed of.
; The UNFOLDED spelling of that same rival is `probes/alt/fcmp_oeq_folded.ll`
; in this
; increment's scoping record (`inc1-records/session-f2-i1/`), and it
; DECLINES `condition predates a non-diagonal gate`
; — MEASURED 2026-09-11 **on the narrowed binary**, not merely on `main`,
; so the narrowing did not quietly open it.
; The theorem behind the ruling: `railWireClosure` inserts its seed BEFORE
; any gate, so `RotBase` is always in `BaseWireOrder`, so
; `RotBase in CondRails => R4 declines` for EVERY chained (register-arg-0)
; rotation arm. The only way past R4 is `StatePrep` — the folded case, where
; the register is no longer in the module at all. So the alternative reading
; is not merely unimplemented, it is UNREACHABLE while R4 stands. (In
; practice a fence EARLIER than R4 fires first — see the measured string
; above — which is SCOPE H-4 and is why the retirement trigger in
; `f2SeedPinnedByLiveRegister`'s header names R4 and 2c together.)
;
; ⚠ THE NARROWING IS THE **WIRE** AND NOTHING WIDER. A register that is
; NOT in the condition's backward cone still collides and still declines:
; `control_inplace_ry_reject_stateprep_range_forward_add.ll` (a FORWARD
; user of a cone member — the F-R1-1 class) and `..._sideways_sdiv.ll` (a
; SIBLING, reached by neither direction) are both untouched, as are all
; 21 of the class-B fixtures. `..._reject_stateprep_nonwire_still_collides.ll`
; is the minimal discriminator written for this ruling.
;
; ---- HISTORY — the header this file carried as a DECLINE, VERBATIM ----
; Kept rather than deleted: it is the measured record of why the fence
; existed, and the ruling changes the DISPOSITION, not the facts.
;
; control_inplace_ry_reject_stateprep_fcmp_oeq_folded.ll — DECLINE (F2, the fp
; ANCHOR half). A LIVE f64 register pinned to a `ConstantFP` by the region's OWN
; `fcmp oeq`, with the arm's seed EQUAL to that constant.
;
; ⚠ ROUND-4 RULE-13 FINDING (lens R4, F-R4-1, CONFIRMED-MISCOMPILE, hand IR).
; Source `$S/review4/R4/h/hf01_fcmp_folded.ll`. F2's BACKWARD half is
; `LazyValueInfo::getConstantRangeOnEdge`, which is defined over `ConstantRange`
; — an INTEGER lattice — and its anchor loop was therefore
; `isIntegerTy()`-gated.
; So NO floating-point register was ever asked F2's question at all: `%t` is
; tainted, dominates the branch, and is dropped FOR ITS TYPE. The only i1 anchor
; left is the `fcmp` itself, whose sole user is the `br` (void => skipped), so
; the walk was empty and F2 returned false. MEASURED at the round-3 HEAD:
; ACCEPT, exit 0, strict-2b clean, linked, RUN — emitting a FRESH rail at 5.0,
; rotating THAT, and measuring `%t` UNROTATED.
;
; THE TWIN THAT SETTLES THE UNITARY is
; `control_inplace_ry_stateprep_fcmp_oeq_twin.ll`
; (R4's `hf04_uncond_fmul.ll`), which is byte-identical on BOTH binaries and
; lowers `cq_theta(%t, 0.9)` to an IN-PLACE `cqrt_ry_f64` on `%t`'s own rail. So
; CQ's own reading of an f64 `cq_theta` on a live register is: rotate that rail.
; Source: one wire. Accepted circuit: two, with the measured one unrotated.
; Different unitary — the F2 ambiguity, at fp.
;
; THE FIX IS AN ANCHOR, NOT A WIDER LVI QUERY (there is no wider query to make:
; LVI has no fp edge fact to give, at any predicate, ever). On the edge where an
; EQUALITY `fcmp` against a `ConstantFP` HOLDS, its tainted operand IS that
; constant — a theorem, seeded directly into `F2State::Cst`, which already
; carries an exact constant for ANY type. The FORWARD half then does the rest
; unchanged, so no second walker was minted (the 8h7d.5 F-1/F-3 discipline:
; reuse the closure rather than compute a new one beside it).
;
; ±0.0 AND NaN CONSTANTS ARE REFUSED, and the reason is in the code: `fcmp oeq
; %x, 0.0` is TRUE for `-0.0` as well as `+0.0`, so the equality edge is NOT a
; singleton and pinning would claim more than the edge supports; a NaN `K` makes
; the equality edge either unreachable (`oeq`) or universal (`ueq`), so it never
; yields a singleton either.
;
; THIS SHAPE IS NOT `clang -O1`-REACHABLE AT LLVM 19, and the fixture says so
; rather than implying otherwise: `propagateEquality` does not substitute across
; `fcmp oeq` (`+0.0 == -0.0`), and `EarlyCSE` runs before `IPSCCP`, so a
; pre-branch fp derivation is CSE'd and `PredicateInfo` has nothing to rename
; (R4 measured seven `-O1` dumps, `p/fp01`-`fp12`). The shape `clang` ACTUALLY
; produces is `control_inplace_ry_reject_stateprep_fcmp_oeq_unfolded.ll`, which
; declines on BOTH binaries with `condition predates a non-diagonal gate`. What
; made this worth fixing rather than filing is that the shipped comment
; carried a
; RETIREMENT TRIGGER asserting the clause "needs no change" the day LLVM gains
; that substitution — false in both halves, and an invitation to a future
; widener
; to read "already covered" and ship.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT    < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 5.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 5.000000e+00, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %mt = call double @cq_measure_f64(double %t)
  %s  = fadd double %mr, %mt
  ret double %s
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[H]], double 2.000000e+00)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %[[H_OP]], double 5.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[H1]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[H_OP]])

; ---------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (the drbq Inc-4 round-1 lesson: a
; POSITIVE `-COUNT-n` inside a prefix WINDOWS every negative after it, so
; every count lives in its own CNT prefix and NOROUTE carries none).
; The counts are the INJECTION MATRIX's answer for this increment: an
; extra uncontrolled `cqrt_ry` on the CONDITION register moves RYCNT, an
; extra `cqrt_free` moves FCNT, and a `_controlled` on the WRONG flag
; breaks the CHECK capture (the flag handle is captured, never typed).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; THE FREEZE: no `cqrt_free` may ever name the PREPPED rail.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL (that fires the
; rotation on BOTH branches — the wrong unitary). Named by handle AND
; angle together, since an unconditional gate at a DIFFERENT angle is a
; legitimate post-region user elsewhere in the family.
; NOROUTE-NOT: call void @cqrt_ry_f64(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_f64_controlled(
; CCNT-NOT:     call void @cqrt_ry_f64_controlled(

