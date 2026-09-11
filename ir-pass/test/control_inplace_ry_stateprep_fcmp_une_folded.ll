; control_inplace_ry_stateprep_fcmp_une_folded.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_fcmp_une_folded.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     double t = q * 2.0;  double r = 5.0;  if (t != 5.0) ; else r =
; cq_theta(5.0, .9);
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
; The UNFOLDED spelling of that same rival is `probes/alt/fcmp_une_folded.ll`
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
; control_inplace_ry_reject_stateprep_fcmp_une_folded.ll — DECLINE (F2, the fp
; ANCHOR's OTHER EXACT HALF: `une` pins on the edge where it is FALSE).
;
; `..._reject_stateprep_fcmp_oeq_folded.ll` covers `oeq`-TRUE. This covers
; `une`-FALSE, which is the SAME theorem written the way `clang` canonicalises
; `!=`: `!(x une K)` is `x oeq K`, so on the branch's FALSE edge `%t` IS `5.0`.
; The arm sits on that edge (Rule 9 — `-O1` routinely makes the gate arm the
; FALSE successor), the seed is `5.0`, and `%t` is live and MEASURED.
;
; ⚠ WHY BOTH HALVES NEED A FILE, and why the other two predicates do NOT
; (round-4 Rule-13 mini-fix, F-R4-1). The anchor's switch has two case groups:
;
;   `oeq` / `ueq` pin on the TRUE edge · `one` / `une` pin on the FALSE edge
;
; `oeq`-true and `une`-false are **EXACT**: ordered equality against a non-zero,
; non-NaN `ConstantFP` admits exactly ONE bit pattern, which is precisely the
; condition under which `clang` COULD have substituted the constant for the
; register. Both are therefore safety-critical and both are pinned — delete
; either `case` and exactly one of these two files goes red.
;
; `ueq`-true and `one`-false additionally admit `%x = NaN`, so the pin there is
; an OVER-APPROXIMATION: `clang` cannot substitute across them, so anything they
; catch is an over-decline. They are kept so the clause has no edge to get
; backwards (F2's whole design is to ask both edges and never reason about
; polarity), and they are deliberately LEFT UNPINNED because deleting them can
; only remove over-declines. **That asymmetry is stated rather than left to be
; rediscovered**: a future reader who deletes `FCMP_UEQ` and sees a green suite
; has NOT found dead code, and a future reader who deletes `FCMP_UNE` and sees a
; green suite has found a broken fixture. Measured 2026-09-05: all four
; predicates decline on this module shape (`$S/fix4/p/pol_{une,one,ueq}.ll`).
;
; Hand IR at this clang for the reason the `oeq` sibling spells out.
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
  %c = fcmp une double %t, 5.000000e+00
  br i1 %c, label %merge, label %arm
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
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_une_f64_hl(i32 %[[H_OP]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_fcmp_une_f64_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], double 5.000000e+00)
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
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_f64_controlled(
; CCNT-NOT:     call void @cqrt_ry_f64_controlled(

