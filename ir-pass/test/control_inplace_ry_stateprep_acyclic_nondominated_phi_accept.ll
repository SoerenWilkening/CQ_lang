; control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll — ACCEPT.
;
; ⚠ **THIS FILE IS THE ACCEPT THAT bd `test_C_libtooling-hrts`' OWN TRIGGER SAID
; DID NOT YET EXIST.** That trigger read: *"the day an acyclic non-dominated-phi
; module ACCEPTS on the un-narrowed binary and DECLINES here, the capability cost
; has become observable as a lost accept and option (b) is owed."* Both the
; round-2 review (2026-09-14) and the X5 re-derivation (2026-09-14c) recorded the
; construction as FAILED — every spelling they built was masked by
; `declineClassicalMuxes`. This module is the one that is not. MEASURED:
;   ORACLE   `cq-opt` sha256 `0e280fc6…`  exit=1  F2: *state prep seed is proven
;                                                 equal to the condition register*
;   SUBJECT  `cq-opt` sha256 `8cda04ca…`  exit=0  the stream CHECK'd below
; So the over-decline was a REAL lost ACCEPT, not only a string change, and
; option (b) was owed rather than optional (owner ruling 2026-09-11).
;
; HOW IT ESCAPES THE MASK. The mask on every earlier spelling is that a phi off
; `%mB`'s dominance subtree carrying an `%MB`-descendant is a TAINTED phi under a
; CLASSICAL condition, which `declineClassicalMuxes` claims — that guard runs
; POST-detection, which is why those modules read as F2 on the ORACLE and as
; taint-escape on the subject. Here `%p` is **DEAD**: nothing consumes it, so the
; liveness filter in that guard does not claim it, and F2 was the only thing
; between this module and exit 0. ⚠ SAY THE LIMIT OUT LOUD: `clang -O1` DELETES a
; dead phi, so this shape is reachable in hand-written IR (which is this pass's
; actual input language) and NOT via the C frontend — the C spelling was built
; and measured and `-O1` DCE'd the chain, giving exit 0 on BOTH binaries
; (`trackF/probes/` — the attempt is recorded, not hidden). The honest claim is
; therefore: **an IR-level ACCEPT is recovered; a C-level one is not yet
; demonstrated.** Do not upgrade that sentence.
;
; WHY THE ACCEPT IS LICENSED — the availability ground, on this module. F2 asks
; whether the author could have written `cq_theta(&<that register>, θ)` in the
; arm. `%p` lives in `%J`; it dominates neither `%pre`'s terminator (the pred-edge
; slot) nor any block dominating `%armB` (the arm slot), so it could not have been
; SPELLED at either slot in any module — its operands did not exist there. It is
; not evidence about the source, and F2 stops counting it. The value it folds to,
; `{0}` == the seed, is a fact about `%u`, and `%u` is a NON-phi `%MB`-descendant
; which BOTH predicates exclude.
;
; THE STREAM, AND THE INVARIANTS TO READ IT BY. `%h` is the user's condition
; register: minted, rotated once, then read ONLY as the source of the eq compare
; and of a `zext` — never `cqrt_x`-bracketed, never freed. `%h_cmp` is the eq
; flag: one mint, one `_unc` strip, one free, i.e. a proven-|0> free (Rule 6).
; `%h1` is the CONTROLLED STATE PREP's register — `cqrt_alloc_i32(0)` then
; `cqrt_ry_i32_controlled(flag, %h1, 0.5)` — and is FROZEN: never reverse-played,
; never freed, because `Ry(θ)|0> != |0>`. STRICT stage 2b on this module:
; `2 rail mint(s) of which 2 left allocated, 4 cqrt_free site(s): 4 verified,
; 0 violation(s), 0 unproven`.
;
; ⚠ WHAT THIS FILE DOES **NOT** WITNESS. The dead `%u` chain is still lowered
; forward and uncomputed, and its `trunc` result is a TEMPLATE-minted rail left
; allocated. `free_pairing_check.py` is STRUCTURALLY BLIND to template-minted
; rails (there is no `cqrt_alloc` to count — CLAUDE.md, stage 2b), so the `0
; violation(s)` above is not clearance for that class.
;
; ⚠ **THAT LEAK IS A CUSTOMER THIS LANDING ADDS TO bd `test_C_libtooling-s82e`,
; NOT SOMETHING ORTHOGONAL TO IT.** The word this paragraph used to carry —
; *"ORTHOGONAL to this landing: it is the ordinary disposition of a dead tainted
; chain"* — is the SAME sentence CLAUDE.md §5 has already called false once, in
; the same words, about three other fixtures: *"Rule 6 governs whether a dirty
; rail may be FREED; it says nothing about whether leaving it entangled is
; semantically free, and Rule 8 says it is not."* Corrected 2026-09-15 at the ARM
; group gate on the Rule-13 round's R-1 (`review_r13_armclassify/REVIEW.md`).
;
; THE SPLIT THIS FILE SITS ON, and it is the reason the correction matters. THIS
; module is in the **BENIGN** half: `%MB` is measured directly and no
; non-diagonal gate runs on it after the leak, so the leftover record
; distinguishes nothing that later interferes. The capability the landing ships
; also covers the **MALIGN** half, where the same register is ROTATED after the
; leak and then measured — the leftover entangled which-path copy makes the two
; branches distinguishable and the measured distribution is the dephased one
; (Rule 8 verbatim: *"a permutation that leaves a rail dirty **and** entangled
; still dephases under later interference"*).
;
; THE WITNESSES, all three committed under
; `docs/prd/.../session-2026-09-15-orchestrator/review_r13_armclassify/probes/`:
;   `m1_malign_leak_then_rotate_measure.ll`  the malign half. ORACLE `0e280fc6…`
;       exit=1 at F2; after this landing exit=0, emitting a never-`_unc`'d
;       `cq_template_trunc_i64_to_i32` and then `cqrt_ry_i32(%h1,0.9)` +
;       `cqrt_measure_i32(%h1)`. **For that program this landing is an
;       OVER-ACCEPT, in the P1 direction. Say it in those words.**
;   `m1c_control_offdesc.ll`  ONE operand changed (`%mz = zext i32 %q`), so the
;       dead φ no longer carries an `%MB`-descendant: DECLINES at F2 on BOTH
;       binaries. It pins the flip to φ-descendant MEMBERSHIP and to nothing
;       about deadness or block layout.
;   `m2_nodeadphi_reference.ll`  `m1` with the dead φ DELETED: **ACCEPTS on the
;       ORACLE**, exit 0, and its gate stream is byte-identical to `m1`'s here
;       (re-measured at the group gate: `cqrt_alloc_i32/ry_i32/icmp_eq_hl/alloc/
;       ry_i32_controlled/…/trunc_i64_to_i32 (leaked)/…/ry_i32/measure_i32`).
;       **So the hazardous circuit already ships from `main`; this landing widens
;       its POPULATION by one spelling.** CLAUDE.md's own formulation:
;       *"'pre-existing' is true of the defect and FALSE of its population."*
;
; ⚠ NOTE FOR WHOEVER BUILDS THE FENCE: on `m2` the ORACLE already prints
; `warning: … cq rotation lowering: non-diagonal gate over a live derived record`
; at exit 0. The hazard has a WARNING and no DECLINE; that warning site is the
; obvious hook, and it is bd `s82e`'s to build — NOT this file's, and not a
; second spelling added here (Rule 14). The red-green pair to write WITH that
; fence is RED `m1`, GREEN an `m2`-shaped module with the trailing
; `cq_theta`/`cq_measure` removed (the genuine Rule-6 accepted leak), isolating
; control `m1c`. It is named here so a later reader does not mistake this file's
; green for a statement about the class.
;
; ⚠ NON-VACUITY IS PINNED BY A SIBLING. `…_acyclic_nondominated_phi_accept_
; control.ll` is this module with ONE operand changed (`%mz = zext i32 %q` for
; `zext i32 %MB`) so `%p` no longer carries an `%MB`-descendant; it DECLINES at
; F2 on BOTH binaries. That pair attributes this accept to phi-descendant
; MEMBERSHIP and to nothing about deadness, block layout or the guard order.
;
; ⚠ RETIREMENT TRIGGER (L8). If this file ever DECLINES again, the slot test has
; been reverted to a `MergeBB` proxy or the availability argument narrowed:
; re-derive `collectStatePrepPhiDescendants`' header and re-measure the back-edge
; pair `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll`
; in the same round — those two are the OVER-ACCEPT side of the same line and a
; change that flips this file without flipping them is the one to be afraid of.
;
; ⚠ SIX FileCheck PASSES OVER **ONE** `cq-opt` RUN. `ir-pass-lit` is SPAWN-bound,
; so the pass runs once into `%t.cqd0.ll` and every prefix reads that file
; (CLAUDE.md: "Adding fixtures is nearly free; adding `opt` invocations is not").
;
; ⚠ THE SPLIT IS NOT COSMETIC AND WAS MEASURED INTO EXISTENCE. With the counts
; and negatives living after the positional `CHECK`s in one prefix, the
; 2026-09-15 injection matrix scored **8 MISSED of 14** on this file: a positive
; CHECK WINDOWS every negative after it, so eight injected gates placed before
; the last positive match were invisible (CLAUDE.md fixture-hygiene defect (a),
; reproduced here rather than read about). One prefix per counted symbol is also
; forced rather than tidy — the gates INTERLEAVE in the stream
; (alloc, ry, icmp, alloc, ry_controlled, ...), and FileCheck matches strictly
; forward, so a single prefix cannot count one symbol to exhaustion and then
; start counting another. Each prefix below is a COUNT immediately followed by a
; `-NOT` of the SAME pattern, which is the FileCheck idiom for an EXACT count;
; `NEG` is a pure whole-file negative prefix with no positional anchor at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=ALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=RY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %arg) {
entry:
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %pre, label %Y
pre:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %pre ]
  %dz = zext i32 %q to i64
  %dd = add i64 %dz, -7
  %mz = zext i32 %MB to i64
  %pm = mul i64 %dd, %mz
  %u = trunc i64 %pm to i32
  %m0 = call i32 @cq_measure_si32(i32 %MB)
  br label %J
Y:
  br label %J
J:
  %p = phi i32 [ %u, %mB ], [ 0, %Y ]
  %mp = phi i32 [ %m0, %mB ], [ 0, %Y ]
  ret i32 %mp
}

; The condition register: one mint, one UNCONTROLLED Ry, read only as a source.
; CHECK: %[[H:[a-zA-Z0-9_]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; The eq flag, then the CONTROLLED state prep on a fresh |0> rail.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 5.000000e-01)
; The flag is stripped and freed; the prepped register is NOT.
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK: %{{[a-zA-Z0-9_]+}} = call i32 @cqrt_measure_i32(i32 %[[R]])
;
; ---- THE WHOLE-MODULE GATE CENSUS: exact counts, one prefix per symbol ----
;
; ALLOC-COUNT-2: call i32 @cqrt_alloc
; ALLOC-NOT: call i32 @cqrt_alloc
;
; Two rotations and no more: ONE uncontrolled `Ry` on the condition register and
; ONE `Ry_controlled` for the prep. A third would be the f8eu shape (a stray
; uncontrolled rotation landing on a user register after the flag is gone).
; RY-COUNT-2: call void @cqrt_ry
; RY-NOT: call void @cqrt_ry
;
; Four frees: the eq flag and the three template rails of the dead chain. The
; condition register and the prepped rail are NOT among them.
; FREE-COUNT-4: call void @cqrt_free
; FREE-NOT: call void @cqrt_free
;
; MEAS: call i32 @cqrt_measure
; MEAS-NOT: call i32 @cqrt_measure
;
; ---- the `NEG` prefix — pure negatives, whole file, no positional anchor ----
; ⚠ That heading is spelled with the prefix name in BACKTICKS and never as
; `<PREFIX>` followed by a colon: FileCheck parses ANY line containing
; `<PREFIX>:` as a POSITIVE directive, prose included. Measured on this file's
; second run, and then AGAIN on the third when this very explanation quoted the
; offending heading verbatim: a section title naming the prefix before a colon
; became a positive check for the prose that followed it, twice. Same
; family as bd `test_C_libtooling-qta2` (a bare `-NOT` matching the module's own
; header line): a fixture's COMMENTS are input to FileCheck, not decoration.
; Nothing non-diagonal touches a user register, no permutation primitive is
; emitted, the retired tensored Rz never appears, and no cq_* intrinsic survives.
; ⚠ Spelled `call void @cqrt_x(` / `call{{.*}}@cq_theta_` and NOT as bare names:
; `cqrt_x` is DECLARED in the lowered module even though it is never called, so a
; bare `-NOT: @cqrt_x` matches the declaration and fails on a module that is in
; fact clean (bd `test_C_libtooling-qta2`, measured here on this file's first run).
; NEG-NOT: call void @cqrt_x(
; NEG-NOT: call void @cqrt_cnot(
; NEG-NOT: call void @cqrt_cswap(
; NEG-NOT: call void @cqrt_rz
; NEG-NOT: call{{.*}}@cq_theta_
; NEG-NOT: call{{.*}}@cq_measure_si32
; NEG-NOT: call{{.*}}@cq_phi
