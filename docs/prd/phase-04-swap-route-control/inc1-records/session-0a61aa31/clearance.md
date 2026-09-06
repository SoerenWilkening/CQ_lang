# clearance — Rule-13 CLEARANCE review of 3qlq Inc 0 + Inc 1 (register-free `cq_phi` by kickback)

Agent `clearance`, READ-ONLY on the checkout (nothing edited, nothing rebuilt, no full ctest run by me).
SUBJECT = `/Users/sorenwilkening/Desktop/CQ_lang` @ **cd2f071** (be4e2ea + the B3 fixture re-point);
`build/` MEASURED CURRENT: `find ir-pass/src ir-pass/include ir-pass/tools -newer build/ir-pass/cq-opt` → EMPTY
(cq-opt and libCQPass.so 21:45; runtime archives 2 Sep and `git diff --stat 52d7764..HEAD -- runtime tools/opcode_table.yaml` → EMPTY, D3).
ROUND-1 SUBJECT = `$SP/wt/r1-subject` (fa96336). ORACLE = `$SP/wt/pre-3qlq` (52d7764).
Harness `$SP/progress/clearance_work/run.sh <file> <subj|r1s|orac> [extra TUs]` = stage 1 (`clang -O1`) → 2 (`cq-opt`)
→ 2b **STRICT** `free_pairing_check.py` → 3 (link, templates before runtime) → 4 (trace). Every number below is
MEASURED with that harness or the command shown; artifacts under `$SP/progress/clearance_work/{p,ll,out}/`
(96 sources, 3 binaries where a spelling exists).

## 0 — what I read (all of it, in the brief's order)
BRIEF_common, BRIEF_clearance, PRD §1–§12 (and the §0 ERRATA block the docs agent added while I worked),
impl_inc1a, impl_inc1b, fix_r1, fix_r2, review_r1_L1..L8, review_r2_R1/R2, RETIRE_SWAP_ROUTE_INC1_NOTES §1+§2
(1035 lines), OWNER_QUESTIONS (OQ-1..OQ-29, Q-R1-1..5, Q-R2-1..3), prep_a2, prep_b2, prep_d2.

## 1 — the gates I was told to wait for, and what I re-ran
| gate | result |
|---|---|
| orchestrator's full `ctest -j6` (`orch_full_ctest.log`, `EXIT=8`) | **338/339 passed; the ONE red is `ir-pass-lit`, and its ONLY failing fixture is `lowering_reject_break_phase_answer.ll` asserting the PRE-re-point string** (`early break preserves a phase answer`; log line 36). The run started before cd2f071 (21:48) landed. |
| that fixture at cd2f071 | `cd build && lit ir-pass/test --filter lowering_reject_break_phase_answer` → **PASS** |
| full `lit -q ir-pass/test` at cd2f071 (mine, `clearance_work/lit_full.log`) | **1656 discovered, exit 0, 0 failures** (1 XFAIL as documented) |
| e2e in the same ctest log | **329/329 passed**, incl. `e2e-loop-twin-matrix` (399 s), `e2e-loop-twin-quarantine-selftest`, all 18 `*-twin-identical` cmp gates (the two new phase gates `e2e-phase-grover-loop-twin-identical`, `e2e-phase-perbit-loop-twin-identical` among them) |
| golden audit, re-run by me: `tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764 <the 72 changed/added goldens>` | SUBSTITUTION-ONLY 29 · AMBIGUOUS-d 1 · AMBIGUOUS-ca 1 · NEW-FILE 11 · **FINDING 30**; the 30 FINDING names == exactly GOLDEN_REGEN.md's 26 `REWRITTEN PROGRAM` table rows + the 4 §12 F-B2-3 remedies (`comm` both ways: empty). 0 unexplained. |
| tree-wide goldens (304 files) | negative-angle `cqrt_rz_i1` **0** · non-`i1` `cqrt_rz` **0** · `cqrt_rz_*_controlled` **0** · `cqrt_rz_i1` lines **168** |
| injection matrix (fix_r2's `inj.py`, REPO re-pointed at the SUBJECT; 16 mutations incl. clean + known-bad controls) | **40 core kickback/angle-select/P3/P4/P5 accepts + 28 sampled migrated `cqrt_rz_i1` accepts = 68 fixtures × 16 = 1088 cells: 0 MISSED, 0 DIRTY** (33 N/A where the shape has no such element; `inj_core.tsv`, `inj_sample.tsv`) |
| record counts | `markBranchPhaseGate` call sites **6** wrapping **6** `CreateCall(Rz` (4 files, 5 emitters) ✓ · `rzRtFn(` **4** call sites, all `"i1"` ✓ · corpus **1656** ✓ · `loop_twin_matrix.expected.txt` **245** rows, quarantine **29** cells ✓ · e2e **329** / total **339** ✓ · retired-family references in fixtures **6** (3 must keep the old spelling) ✓ · Inc 2 NOT merged (`git merge-base --is-ancestor 87a90d7 HEAD` → 1) ✓ |
| PRD §12 assumptions | Q1 declarations kept (`runtime/cq_runtime.h` still declares 18 `cqrt_rz_*_controlled[_inv]`) ✓ · Q2 no remark on deletion (only ORE in the tree is `LoopUnrollPrepass`) ✓ · Q3 Rz run-time arms ACCEPT (`g2`: `x; rz_i1(B); x; rz_i1(A)`) while the Ry stem still declines `rotation angle` (`g3`) ✓ · Q4 bare `i1` declines `branch phase on a bare i1 condition` (`g1`) ✓ |
| 15 keep-alive rewrites (3 read) | `slice_intrinsic_bswap` golden carries `cq_template_bswap_i32_unc`; `slice_fp80_union_unc` carries the whole `{bitcast,lshr,trunc,zext,and,add}_unc` chain; `slice_compare_qq` carries `cq_template_icmp_eq_i32_unc` — each exactly what its header claims ✓ |

## 2 — Question 1: is there any path on which the emitted circuit is a different unitary at `opt` exit 0?

### 2.1 Re-attacks that came out CLEAR (each measured on the subject, most also on r1s and/or the oracle)
* **Spine adjoint on the shared flag — 17 NEW spellings** (`a1`–`a20`): `sext`, `*3`, QRAM index, tape write, a second region, a P3 leaf, measured-first, Ry-after, `select` data use, derived+two uses, flag as shift amount, flag returned, negated tail φ, fp condition, dead register, Ry on a derived rail after, in-place `add`/`xor` on the condition register after. **0 negative-angle `cqrt_rz_i1` in any subject trace; 7 of the same programs emit the cancelling adjoint on the r1-subject** (the F-L7-1 class, gone). Off-pattern ones decline loudly (`control flow` ×2, `condition data use neither escaped nor measured` ×2, `condition used outside the branch`, `condition measured before the control route`, `condition predates a non-diagonal gate`). PRD §10.2(a) witness: the ORACLE's old-surface traces of `a1`/`a11` with `cqrt_rz_i32_controlled(f,h,θ)→cqrt_rz_i1(f,θ)` applied are **BYTE-IDENTICAL** to the subject's. `a18`/`a19`: with a shared flag the later `q+9`/`q^9` is lowered OUT of place (the flag record stays consistent) and without the share it is `cqrt_addc` in place after the strip — both correct.
* **The once-only-stage class (F-L3-1 / F-R1-1 shape), third instance hunt** (`b1`–`b12`): onward abort (declines, coarse carrier), onward nest (correct toffoli LIFO), onward P3 both-onward (correct), onward angle select with run-time arms (correct), onward-of-onward (3 rounds, correct), onward+share (no adjoint), onward per-bit+diffusion rolled == unrolled (42 = 42). **Q-R2-1 probed directly** (`b2`: a round-1 per-bit loop over root `q` plus a round-2 hoisted `p = y*3` read in the same body): the preheader `mul` rail is minted once, its derived rails discharge per trip, and it is left allocated — **no K-adjoint multiplicity, no dirty free**. No third instance found in the ACCEPT direction. Over-declines found (loud, safe): `b2u`/`b6u` — the FLAT twins of interleaved round-1/round-2 sequential regions decline `control flow` while the rolled forms accept (so those rolled forms have no twin witness); `b10` a P3 tree mixing a round-1 and a round-2 leaf declines `control flow`.
* **Retired-family third path — 11 hand-IR spellings** (`c1`–`c12`): mismatched-signature call, address in a global initialiser, defined-and-called, call with no quantum in the module → all decline `retired register-form cq_phi_si32; use the register-free void cq_phi(double)`; wrong-prototype void `@cq_phi` declines; unknown suffix `cq_phi_zz32` declines `control flow`; nested-same-case P5 and shared-scrutinee P5 decline. The only accepts are the disclosed ones: `c5` a decl-only UNUSED retired name with a WRONG prototype is swept silently (OQ-29 — the oracle declined it), `c6` an uncalled DEFINITION named `cq_phi_si32` is ERASED by `eraseDeadDecls` (pre-existing for all 34 reserved names: `M.getFunction(Name)` + `use_empty()` → `eraseFromParent()`), `c9` a DEFINED `void @cq_phi(double)` with an observable `store` body has its call lowered as a kickback and its definition erased (Q-R1-3, as filed).
* **Unowned shapes**: kickback + tape write in one arm declines (`kMsgIOControl`, both spellings); clone caller arm declines (`non-routable value multiplexer`); kickback on a clone's OUTPUT accepts correctly (`e2b`); `cq_phi` in a callee called from BOTH contexts declines (`quantum primitive (cq_*)`, both binaries; the r1-subject gave the wrong-ground `nested call` string); a classical-only callee with an inner `cq_phi` is deleted as global (`e7c`, 3 lines, D2); P3 with a loop-carried leaf rolled == unrolled (45 = 45); hcrg sequential derived regions inside a loop discharge 6/6; `cq_invert` brackets link-fail on BOTH binaries (Phase 8 unimplemented, pre-existing).
* **D4 per-bit + diffusion**: K=4 rolled == unrolled (45 = 45), K=31 rolled == unrolled (288 = 288); K=32 differs ONLY by the frontend `(q>>31)&1 → icmp sgt` canonicalisation R1 recorded (297 vs 294, all 32 rails discharged on both). Two invariant roots + two diffusions: 62 = 62. Chained state-prep root: 32 = 32. Trailing in-place `addc`: 31 = 31.
* **B3 reachability (the hand-off question) — REACHABLE from plain C, and the fence is doing its job**: `f1_break_kick_before.c` (a kickback on `q==5` BEFORE the shipped 7.4 break loop of `slice_loop_break.c`) declines **`cq loop lowering: early break preserves a phase answer`** on the subject (the r1-subject declined on an earlier shape fence; `f3` with a GLOBAL phase before the loop accepts byte-identical to the plain loop, so the post-dominance clause discriminates). `f2` (kickback AFTER the loop) and `f4` (kickback on an unrelated register) also take B3 — the documented coarse over-decline. **No fixture pins B3 today**; `clearance_work/out/f1_break_kick_before.subj.s1.ll` is a fixture-ready module.

### 2.2 THE BLOCKING FINDING — C-1: a loop-INVARIANT root register with a DERIVED (per-bit) kickback condition LEAKS one entangled which-path rail per activation as soon as the SAME loop also CARRIES another tainted register; the hand-unrolled twin discharges every one; the pre-3qlq ORACLE discharged them; and a later diffusion on the register runs over the live records.

**Reproducer** (plain C, `clang -O1`, `$SP/progress/clearance_work/p/d1i_mixed_invariant_interf.c`; the shape is P6's
P1-in-a-loop with D4's per-bit condition, plus an ancilla register rotated per trip):
```c
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
```
**SUBJECT, ROLLED** (`out/d1i_mixed_invariant_interf.subj.trace`; `opt` exit 0, verify-clean, STRICT stage 2b
`2 rail mint(s) of which 2 left allocated … 0 violation(s), 0 unproven`, linked, run, 31 lines):
```
cqrt_alloc_i32(5) -> h0 ; cqrt_ry_i32(h0, 0x1p-1)
cqrt_alloc_i32(5) -> h1 ; cqrt_ry_i32(h1, 0x1.3333333333333p-2)
cq_template_and_i32_hl(h0, 1) -> h2            <-- bit 0 of q, minted
cq_template_icmp_eq_i32_hl(h2, 0) -> h3
cqrt_x(h3) ; cqrt_rz_i1(h3, 0x1.999999999999ap-3) ; cqrt_x(h3)
cq_template_icmp_eq_i32_hl_unc(h3, h2, 0) ; cqrt_free(h3)      <-- flag stripped+freed, h2 NEVER
cqrt_ry_i32(h1, 0x1.999999999999ap-4)
cq_template_and_i32_hl(h0, 2) -> h4  … (same, h4 never discharged) …
cq_template_and_i32_hl(h0, 4) -> h6  … (same, h6 never discharged) …
cqrt_ry_i32(h1, 0x1.999999999999ap-4)
cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1)          <-- the diffusion, with h2/h4/h6 = bits of q LIVE
cqrt_measure_i32(h0) -> 0 ; cqrt_measure_i32(h1) -> 0
```
**SUBJECT, HAND-UNROLLED twin** (`p/d1iu_mixed_invariant_interf_unrolled.c` → `out/…unrolled.subj.trace`, 37 lines):
identical except each activation carries **`cq_template_and_i32_hl_unc(h2, h0, 1); cqrt_free(h2)`** (and h4/h6 likewise)
before the next `cqrt_ry_i32(h1, …)`. `diff` = exactly the three inserted `_unc`+`free` pairs. `and_hl`/`and_unc`:
rolled **3/0**, unrolled **3/3**.
**ORACLE, old surface** (`p/d1o_mixed_invariant_oldsurface.c`, `if((q>>i)&1) q=cq_phi(q,0.2)`): rolled == unrolled
**IDENTICAL (37 = 37)**, `and_unc` **3/3** — the oracle discharged. This is a REGRESSION against the oracle, exactly
as F-L5-1 was.

**Why it is a wrong unitary and not a Rule-6 "safe leak"** — the argument is the epic's OWN, used twice: the three
leaked rails are a reversible record of `q`'s low bits, and the `cqrt_ry_i32(h0, 0.9)` that follows mixes `x` with
`x ⊕ 2^i`; those branches now carry DISTINCT ancilla labels, so their interference is destroyed (Rule 8: "a
permutation that leaves a rail dirty AND entangled still dephases under later interference"). The unrolled twin — the
program's meaning — interferes cleanly. Round 1 graded this signature **CONFIRMED MISCOMPILE** (F-L7-2 / F-L5-1 /
F-L2-1b) and round 2 graded it **CONFIRMED** again (F-R1-1, with the same interference probe); both were fixed
before proceeding. Nothing in the record distinguishes this population from those except that it was not measured.

**Population (all plain C, all `opt` exit 0, all STRICT-2b clean, all rolled ≠ unrolled):** the carried register may be
rotated (`d1`, `d1i`), mutated in place (`d1c`: `r ^= 9`), or itself a kickback condition (`d1k`); the condition may be
a P3 tree with the per-bit leaf (`d11`, 45 vs 51); K=32 leaks **32** rails with the diffusion at line 261 (`d1w`); a
DEAD `q` leaks its root and rails, never freed dirty (`d1d` — no dirty free anywhere in the class). A DIRECT compare on
the invariant register (`d1m`) is unaffected (nothing to discharge; it takes the drbq.12 LICM over-decline instead).

**Root cause, located** (`ir-pass/src/LoopLowering.cpp:3163-3177` + `:2877-2887`): `collapseFlattenedLoopRails`
takes the `Collapsed` branch for `r`'s header phi and hands `markIfRailLocal` ONLY the carried register's `Roots`;
`invariantRegisterRoots` — the F-L5-1 fix — is reached only on `NotClaimed`, and its clause (i) refuses ANY tainted
header phi. The mixed loop is served by neither path. **The fix's own proof already covers this register**: clause
(ii)'s argument is that a root mint lowers to `cqrt_alloc_<W>` and fails `isInteriorTerminalHandle` (I1), so it can
never be the preheader forward gate with `At` in the body — a property of the ROOT, not of whether some OTHER
register crosses the back edge. This is Q-R1-1's class but NOT Q-R1-1's excuse: Q-R1-1 refuses the hoisted TEMPLATE
rail because no proof covers it; here the proof exists and a dispatch precondition excludes the customer.

**Why the record is also false here.** PRD §0 ERRATA E2: *"the row is now correct … ⚠ Two things the fix does NOT
cover"* — names the hoisted template rail and the LICM-hoisted invariant compare. This is a third, and it sits
inside the epic's flagship idiom (D4's per-bit loop) the moment the body also rotates an ancilla.

**Remedy (one bounded round + re-clearance):** either (a) the capability fix — in the `Collapsed` branch, ALSO collect
the loop-invariant ROOT MINTS (and control-owned out-rails, clause (ii-b)) into `Roots` before `markIfRailLocal`, on
the identical (I1) proof; or (b) the Prime-Directive interim — decline loudly (`classifyPhaseKickback` step 7 / the
P6 admission) when an in-loop kickback's condition mints a template rail inside `L` and the header carries a tainted
phi that is not the condition register's own. Either way: a lit accept/decline pair mirroring the string, an e2e
rolled/unrolled `cmp` twin pair for the mixed shape (`d1i` is ready), a `loop_twin_matrix` axis with a second carried
register (the matrix has none, which is why 274 cells cannot see this), and E2 corrected.

### 2.3 Other Q1 observations (no wrong unitary; listed for the record)
* Q-R1-1's class re-measured with two new spellings — a `sext` rail (`d2`: `long p = q;`) and a Q+Q rail (`d3`: `p = q+r`) — both leak like the `mul` case, rolled ≠ unrolled (25 vs 33, 28 vs 36); an ONWARD hoisted temp (`b7`) likewise. Same disclosed residual; the disclosure should say "any loop-invariant TEMPLATE rail", not only `q*3`.
* `e11`: a kickback whose condition is a const-QRAM load result accepts correctly — `-O1` folds `T[q&7]==3` to `(q&7)==2` and the mint/strip/discharge are exact.

## 3 — Question 2: does anything free a rail that is not provably |0⟩, or leave a rail dirty where the oracle discharged it?
* STRICT stage 2b on **every** accepting reproducer of this review (≈70): `0 violation(s), 0 unproven` on all of them (the 7.4 break probes need `--allow-unproven` exactly as their four shipped slices do). No dirty free found anywhere, including the C-1 class (`d1d`, register dead: root and rails left allocated).
* Rolled/unrolled twins: 9 pairs IDENTICAL; the DIVERGING ones are exactly C-1's population plus the disclosed Q-R1-1 template-rail class (and one unfaithful twin of mine, `d6u`, which `-O1` CSE'd — the rolled side discharges 6/6).
* The golden audit and the tree-wide scans are in §1; the loop twin matrix (245 expected + 29 quarantined with pinned signatures and bd issues, 2 of them class C with no issue of their own — OQ-27) passed in the orchestrator's run.
* "Where the oracle discharged it": C-1 is the one place I found (oracle 3/3, subject 3/0).

## 4 — Question 3: is every accept pinned, every decline mirrored, and does the record tell the truth?
* Injection: 1088 cells, 0 MISSED, 0 DIRTY (§1). Counts re-measured (§1) all reproduce.
* **Unpinned accept/decline surfaces found:** (i) the B3 fence has a plain-C customer and NO fixture (`f1`); (ii) the C-1 mixed-loop shape has neither a fixture nor a twin gate nor a matrix axis; (iii) the flat over-decline of interleaved round-1/round-2 sequential regions (`b2u`/`b6u`, `control flow`) is pinned by nothing.
* **False or incomplete sentences:** PRD §0 E2 "the row is now correct" (C-1); the Q-R1-1 disclosure names only `q*3` where any loop-invariant template rail (cast, Q+Q, onward `mul`) leaks; OQ-29's `lowering_legacy_phi_decl_prototype_family.ll` records the SWEEP but not that a wrong-prototype unused retired decl is swept where the oracle declined it (`c5`) nor that `eraseDeadDecls` erases an unused DEFINITION under a reserved name (`c6`, pre-existing for all 34 names).
* Everything else I checked in CLAUDE.md/ROADMAP/notes is true of the binary: register-free `cq_phi` prose, the six-site enumeration, "declared, unemitted since 3qlq", the 29-cell quarantine block, the four `--allow-unproven` slices, D1–D7 honoured (D6/D7: Inc 2 not merged), §12 Q1–Q4 consistent with what shipped.

## 5 — OWNER QUESTIONS raised or sharpened by this review
1. **OQ-30 (C-1's disposition, if the owner prefers not to fix it now):** admit invariant root mints beside carried roots (same (I1) proof) or decline the mixed loop loudly? Shipping it silently is not an option this review can clear.
2. **B3 fixture:** `lowering_reject_break_phase_answer.ll` now pins Q1's string; B3 is reachable from plain C (`f1`). Ship `f1`'s module as the B3 pin (and keep the re-pointed file for Q1).
3. **OQ-29, sharpened:** with the corpus migrated (6 references, 3 of which are the reserved-name fixtures), tighten the retired family to the full reserved-name rule? Lost today: prototype validation of an unused wrong-typed retired decl (`c5`), and a user DEFINITION under a reserved name is erased when unused (`c6` — pre-existing for all names, now including the 15 retired ones).
4. **Q-R1-3 confirmed by measurement** (`c9`): a defined `void @cq_phi(double)` with an observable body is captured (call lowered as kickback, body erased). Decide reserved-name decline vs documented capture.
5. **Flat over-decline of interleaved onward/round-1 sequential regions** (`b2u`, `b6u`): the rolled forms accept and their flat twins decline `control flow`, so the in-loop accepts on onward registers have no twin witness. File or fix.
6. Standing owner questions I re-confirmed rather than re-raise: Q-R1-1 (now measured over `sext`, Q+Q and onward `mul` rails too), Q-R1-2/OQ-19, Q-R2-1 (probed, no multiplicity defect materialised), Q-R2-2, Q-R2-3, OQ-11 (P5 hand-IR only), OQ-27/28.

## 6 — What I ran (only this)
* `cd build && lit -q ir-pass/test` → 1656 discovered, exit 0; one fixture re-run by name → PASS.
* `tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764 <72 goldens>` → the tally in §1, reconciled by `comm` against GOLDEN_REGEN.md.
* `inj.py` (fix_r2's, re-pointed) over 68 accepts × 16 mutations → 0 MISSED / 0 DIRTY.
* ~96 reproducers (66 plain-C on the new surface, 5 old-surface twins on the oracle, 12 hand-IR modules, 13 rolled/unrolled twin pairs) through the full pipeline with STRICT 2b; the 3-binary sweep of batch 1 (`batch1_subj.log`, `batch1_r1s.log`).
* Read (not re-run): the orchestrator's `orch_full_ctest.log` (338/339; the red is the pre-re-point fixture).
* NOT run: the full `ctest` (forbidden by the brief), any rebuild.

## VERDICT
One plain-C reproducer (`d1i`) whose ROLLED circuit leaves three entangled which-path records of the register live
through a later `cqrt_ry_i32` on that register, where the hand-unrolled twin and the pre-3qlq oracle both return them
to |0⟩ — the exact signature this epic graded CONFIRMED MISCOMPILE in round 1 (F-L5-1) and round 2 (F-R1-1), on an
undisclosed population inside D4's own idiom, with a bounded remedy the shipped fix's proof already covers.

BLOCK
