# review_r2_R2 — Rule-13 ROUND 2, lens R2: FIXTURE / DOC TRUTH of the whole branch
bd `test_C_libtooling-3qlq.2`, Increment 1 (part A + round-1 fixes + part B), merged tip.
**READ-ONLY.** Nothing in `/Users/sorenwilkening/Desktop/CQ_lang` was edited, built or
regenerated; every fixture I mutated is a COPY or a mutation of the fixture's own *output*
in a `TemporaryDirectory`.

SUBJECT  `/Users/sorenwilkening/Desktop/CQ_lang` @ **`c4bd888`** (working tree clean;
         `build/ir-pass/{cq-opt,libCQPass.so}` mtime 16:53, post-merge).
ORACLE   `$SP/wt/pre-3qlq` @ `52d7764`.  R1-SUBJECT `$SP/wt/r1-subject` @ `fa96336`.
ARTIFACTS `$SP/progress/review_r2_R2/` — `inj.py` (the lit-ShTest replica + 8 mutations),
         `m3.py`, `threebin.py`, `r1red.py`, `inherited_diff.py`, `sweep.sh`, `hygiene.py`,
         `matrix{,2,3}.tsv`, `markmap.tsv`, `threebin.tsv`, `sweep.tsv` (1661 rows),
         `inherited_diff.txt`, `decline_strings.txt`, `handlecheck.txt`, `lit_full.log`,
         `lit_r1.log`, `red.txt`, `red_r1.txt`, `newred.txt`, `selfcheck/`, `disc/`, `out/`.

---

## 0. The harness, and the four controls that make a "CAUGHT" mean something

`inj.py` mirrors lit's ShTest for these fixtures: it takes EVERY line containing `RUN:`
(lit scans all lines), expands `%cq-opt`/`%cq-pass`/`%filecheck`/`%s`/`%t` exactly as
`build/ir-pass/test/lit.site.cfg.py` + `ir-pass/test/lit.cfg.py` do, puts the FileCheck
directory on `PATH`, runs RUN-line 0 to make `%t.cqd0.ll`, MUTATES that text, then runs
every remaining RUN line and records which `--check-prefix` exits non-zero.

* **Control A — clean must PASS.** 37 of 37 accepts pass every prefix unmutated.
* **Control B — known-bad must FAIL.** Deleting the forward kickback gate fails 33 of 33
  applicable (the 4 N/A have no `cqrt_rz_i1`).
* **Control C — two DELIBERATELY BROKEN fixtures.** `selfcheck/broken_check.ll` (a
  `CHECK` retargeted at `@cqrt_ZZZ_NOT_A_SYMBOL`) and `selfcheck/broken_noroute.ll`
  (`NOROUTE-NOT: cqrt_cswap` → `NOROUTE-NOT: cqrt_free`, forbidding something the clean
  output contains). The harness reports **FAIL** on both and **PASS** on the unmodified
  original. A harness that passed there would be worthless.
* **Control D — anti-lie (the Inc-4 precedent).** Audited with `difflib`: every injection
  is a **one-line** edit (the metadata drop is one line changed) and **touches no
  `declare`**; and **every post-line-0 RUN line in all 37 accepts is a pure `%filecheck`**
  (measured — no re-parse anywhere), so an injected call needs no declaration and a catch
  is attributable to the injected text alone.

---

## 1. The corpus, measured

| claim | command | measured |
|---|---|---|
| files changed under `ir-pass/test` since `dfb8e83` | `git diff --name-status dfb8e83..c4bd888 -- ir-pass/test` | **79 A + 1 M = 80** (37 accept / 43 decline) |
| corpus / red | `cd build && lit -q ir-pass/test` | **1661 discovered, 396 FAILED** |
| the 80 branch fixtures | `comm -12 red.txt branchfx.txt` | **0 red — all 80 GREEN** |
| retired-family set | `grep -lE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll` | **493** |
| red outside it | `comm -23 red.txt migset.txt` | **∅** |
| blast radius vs `fa96336` | `comm -13 red_r1.txt red.txt` | **exactly 34 new red, 0 newly green**, all in the 493, incl. the five the notes name |
| **emitted `cqrt_rz` widths, whole corpus** | `sweep.sh` over all 1661 (633 accept) | **`cqrt_rz_i1` ONLY** — 35 fixtures emit it, 598 emit none, **0** emit any other width |
| `rzRtFn(` call sites | `grep -rn` | **4, every one `"i1"`** (+ def + decl) |
| `!cq.branchphase` invariant | per-fixture recount on all 35 rz-emitting fixtures | **`cqrt_rz_i1` count == marked count on 35/35**, and the mark never lands on any other call |
| pass postcondition | sweep, all 633 accepting fixtures | **0** leave a surviving `@cq_phi` / `@cq_phi_<sfx>` / `@cq_theta_<sfx>` CALL |
| the 12 round-1 L6 "third path" survivors | 3-binary run | **all 12 now decline** `retired register-form cq_phi_<sfx>` |
| **did the fix change anything else?** | subject vs `fa96336` over the **1581 INHERITED** fixtures | **396 changed: 15 RC 0→1, 381 message pre-emptions, and `STDOUT` changes = 0.** Every one of the 396 is the F-L6-1 reserved-name decline. **No inherited fixture's lowered OUTPUT moved.** |
| stage 2b STRICT on all 37 accept outputs | `tools/free_pairing_check.py` | **37/37 rc=0, 0 violations, 0 unproven** |
| decline strings | all 43 run, stderr captured | **43/43 rc=1 with EXACTLY ONE `error:`**; every positive `CHECK` is a **literal substring** of the emitted line; every message text is present verbatim in `ir-pass/src` **except** the two BUILT by concatenation (`retired register-form <sfx>; use …`, and the QRAM in-bounds reason) |
| handle names | `handlecheck.py`, 464 positive directives over 37 accepts | **0** literal `%name` absent from that fixture's own pass output |
| prefix hygiene | `hygiene.py` over all 80 | `NOROUTE` positives **0**; prefixes with >1 positive **0**; RUN-named prefixes with no directives **0** |

**On the brief's premise "`cqrt_cswap` is minted by `AbortParkEmit` only": that is the
POST-Inc-2 END STATE, not true at this HEAD, and it is not a defect of this branch.**
`ControlledSymbols::cswapFn()` has ONE caller, `SwapRouteEmit::emitRoute`, which is called
from `AbortParkEmit.cpp:396` (the 7.2 park), `SwapRouteEmit.cpp:380/414/441/455` (the 4.2
VALUE arm) and `SwitchValueEmit.cpp:204/228/257/266` (the 4.5 value switch). 12 fixtures
emit `cqrt_cswap`: 4 abort-park + 8 value routes. PRD line 133/234 states the
"abort-park only" end state as an Inc-2 (D6) deliverable, which is unshipped.

---

## 2. Per-accept assertion matrix (10 injections × 37 accepts, `matrix{,2,3}.tsv`)

`gates` = number of emitted `cqrt_rz_i1`. "caught" = at least one `--check-prefix` exits
non-zero. Injections `rz_f80`/`rz_f16`/`cswap` are placed **before `ret`** (outside any
`CHECK-NEXT` window) so a catch is attributable to a negative and not to adjacency.
| accept fixture | gates | rz_f80/f16 | cswap | unpaired cqrt_x | extra cqrt_free | drop !cq.branchphase |
|---|---|---|---|---|---|---|
| `control_angle_select_phase_constants.ll` | 2 | caught/caught | caught | caught | caught | MISS |
| `control_angle_select_phase_nonfinite_arm.ll` | 2 | caught/caught | caught | MISS | MISS | caught |
| `control_angle_select_phase_runtime.ll` | 2 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_and2.ll` | 1 | MISS/MISS | caught | MISS | caught | caught |
| `control_phase_kickback_and3_tree.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_kickback_andbo.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_kickback_derived_cond.ll` | 1 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_diamond.ll` | 1 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_f64_cond.ll` | 1 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_ifelse.ll` | 2 | caught/caught | caught | caught | MISS | caught |
| `control_phase_kickback_ifelse_tail_armfalse.ll` | 4 | caught/caught | caught | caught | MISS | caught |
| `control_phase_kickback_ifelse_tail_phi.ll` | 3 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_inloop.ll` | 1 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_inloop_body_gate.ll` | 1 | caught/caught | caught | caught | MISS | caught |
| `control_phase_kickback_inloop_derived_cond.ll` | 1 | caught/caught | caught | MISS | caught | caught |
| `control_phase_kickback_inloop_reject_hoisted_temp.ll` | 1 | caught/caught | caught | MISS | MISS | caught |
| `control_phase_kickback_negated.ll` | 1 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_negated_tail_phi.ll` | 3 | caught/caught | caught | caught | MISS | caught |
| `control_phase_kickback_onward_merge.ll` | 4 | MISS/MISS | MISS | MISS | MISS | caught |
| `control_phase_kickback_or2.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_kickback_seq.ll` | 2 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_share_flag.ll` | 1 | MISS/MISS | caught | MISS | caught | caught |
| `control_phase_kickback_share_flag_negated.ll` | 2 | MISS/MISS | caught | caught | caught | caught |
| `control_phase_kickback_tree_negated.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_kickback_tree_shared_leaf.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_kickback_two_calls.ll` | 2 | caught/caught | caught | caught | caught | MISS |
| `control_phase_kickback_xor2.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_nest_kickback.ll` | 2 | MISS/MISS | caught | MISS | MISS | caught |
| `control_phase_nest_kickback_compound_inner.ll` | 2 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_nest_kickback_empty_outer_arm.ll` | 1 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_nest_kickback_inner_negated.ll` | 2 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_nest_kickback_outer_negated.ll` | 2 | MISS/MISS | caught | MISS | MISS | MISS |
| `control_phase_switch_kickback.ll` | 3 | MISS/MISS | caught | MISS | MISS | caught |
| `control_phase_switch_kickback_empty_case.ll` | 2 | MISS/MISS | caught | MISS | caught | MISS |
| `control_phase_switch_kickback_multigate.ll` | 4 | MISS/MISS | caught | MISS | caught | MISS |
| `lowering_legacy_phi_decl_prototype_family.ll` | 0 | caught/caught | MISS | MISS | MISS | n/a |
| `lowering_phi_uncontrolled_deleted.ll` | 0 | caught/caught | caught | caught | caught | n/a |

**Roll-up (measured, `matrix3.tsv`; all 37 accepts are applicable in every column):**
`cqrt_rz_f80` and `cqrt_rz_f16` MISSED in **18**; `cqrt_rz_i64` MISSED in **3**;
`cqrt_rz_i32` MISSED in **0**; `cqrt_cswap` and `cqrt_ry_i32_controlled` MISSED in **2**
(`onward_merge` plus the inert decl-only file); an **unpaired `cqrt_x`** MISSED in **21**
(20 lowering accepts + the inert one); an **extra `cqrt_free`** MISSED in **20** (19
lowering accepts + the inert one); a **dropped `!cq.branchphase`** MISSED in **22 of 35**
gate-bearing accepts. A surviving `@cq_phi` call and a surviving `@cq_phi_<sfx>` call are caught in
**36 of 37** (the exception is `lowering_legacy_phi_decl_prototype_family.ll`, whose
`SWEPT` prefix forbids `@cq_phi_` and `cqrt_rz` but not the void `@cq_phi(`).

**The NOROUTE Rz-width negative, by form (measured `grep`, and it partitions exactly):**

| form | files | blind to |
|---|---|---|
| complement regex `@cqrt_rz_{{(i8\|i16\|i32\|i64\|f16\|f32\|f64\|f80)}}(` | **18** | nothing |
| six-width ENUMERATION `cqrt_rz_i8 … f64` | **15** | `f16`, `f80` |
| ONE width `@cqrt_rz_i32` | **3** | 7 of the 8 |
| none | 1 (`lowering_legacy_phi_decl_prototype_family.ll`, blanket `SWEPT-NOT: cqrt_rz`) | — |

**Provenance explains the partition exactly** (`git log --diff-filter=A`): the 18 with the
complement are part A's 11 (`4d0cb82`, repaired in `f1ca58c`) plus the 7 accepts the fix
agent wrote *after* that repair. The 15 enumerating files are **exactly** part B's
(`1230737`, a parallel branch that never saw the repair). The 3 one-width files are
`share_flag`, `share_flag_negated` (`315cadf`) and `onward_merge` (`6eded46`) — the fix
agent's OWN accepts, written *before* it repaired the same defect in 11 inherited files
and never revisited.

### 2b. Per-decline table (43 files) — emitted diagnostic, and how it moves vs the two other binaries

| decline fixture | emitted message (the CHECK is a literal substring of it) | vs `fa96336` | vs ORACLE |
|---|---|---|---|
| `control_angle_select_phase_reject_empty_arm_phi.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_in_loop.ll` | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_nested_sel.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_phi_and_theta.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_poison_arm.ll` | `cq controlled lowering: rotation angle under quantum control` | RC 0->1 | MSG-DIFF |
| `control_angle_select_phase_reject_qq_cond.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_sharecond.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_two_consumers.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_angle_select_phase_reject_undef_arm.ll` | `cq controlled lowering: rotation angle under quantum control` | RC 0->1 | MSG-DIFF |
| `control_phase_kickback_reject_bare_i1.ll` | `cq controlled lowering: branch phase on a bare i1 condition under quantum control` | SAME-MSG | MSG-DIFF |
| `control_phase_kickback_reject_compound_cond.ll` | `cq controlled lowering: control flow under quantum control` | MSG-DIFF | SAME-MSG |
| `control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | SAME-MSG | MSG-DIFF |
| `control_phase_kickback_reject_irreducible_loop.ll` | `cq controlled lowering: control flow inside a loop body under quantum control` | SAME-MSG | MSG-DIFF |
| `control_phase_kickback_reject_mixed_arm.ll` | `cq controlled lowering: control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_kickback_reject_multiblock_arm.ll` | `cq controlled lowering: control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_kickback_reject_onward_mixed_arm.ll` | `cq controlled lowering: impure value arm under quantum control` | RC 0->1 | SAME-MSG |
| `control_phase_kickback_reject_qq_compare.ll` | `no template for opcode 'icmp i1' in tainted context` | SAME-MSG | MSG-DIFF |
| `control_phase_kickback_reject_tainted_angle.ll` | `cq controlled lowering: rotation angle under quantum control` | SAME-MSG | MSG-DIFF |
| `control_phase_kickback_reject_tree_classical_leaf.ll` | `cq controlled lowering: control flow under quantum control` | MSG-DIFF | SAME-MSG |
| `control_phase_kickback_reject_tree_cross_block_leaf.ll` | `cq controlled lowering: control flow under quantum control` | MSG-DIFF | SAME-MSG |
| `control_phase_kickback_reject_tree_data_use.ll` | `cq controlled lowering: condition used outside the branch under quantum control` | MSG-DIFF | MSG-DIFF |
| `control_phase_kickback_reject_tree_notform.ll` | `cq controlled lowering: control flow under quantum control` | MSG-DIFF | SAME-MSG |
| `control_phase_kickback_reject_tree_qq_leaf.ll` | `cq controlled lowering: control flow under quantum control` | MSG-DIFF | SAME-MSG |
| `control_phase_kickback_reject_tree_stale_leaf.ll` | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | MSG-DIFF | MSG-DIFF |
| `control_phase_kickback_reject_tree_too_deep.ll` | `cq controlled lowering: branch phase condition tree too deep under quantum control` | MSG-DIFF | MSG-DIFF |
| `control_phase_nest_reject_block_order.ll` | `cq controlled lowering: control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_nest_reject_depth3.ll` | `cq controlled lowering: nested control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_nest_reject_in_loop.ll` | `cq controlled lowering: nested control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_nest_reject_merge_phi.ll` | `cq controlled lowering: impure phase arm under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_nest_reject_mixed_arm.ll` | `cq controlled lowering: impure phase arm under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_nest_reject_tainted_angle.ll` | `cq controlled lowering: rotation angle under quantum control` | MSG-DIFF | MSG-DIFF |
| `control_phase_switch_reject_default_body.ll` | `cq controlled lowering: control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_switch_reject_grouped.ll` | `cq controlled lowering: control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_switch_reject_merge_phi.ll` | `cq controlled lowering: control flow under quantum control` | SAME-MSG | SAME-MSG |
| `control_phase_switch_reject_scrutinee_datause.ll` | `cq controlled lowering: condition data use neither escaped nor measured under quantum control` | MSG-DIFF | MSG-DIFF |
| `control_phase_switch_reject_stale_scrutinee.ll` | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | MSG-DIFF | MSG-DIFF |
| `control_phase_switch_reject_table_fold.ll` | `cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)` | SAME-MSG | SAME-MSG |
| `control_phase_switch_reject_tainted_angle.ll` | `cq controlled lowering: rotation angle under quantum control` | MSG-DIFF | MSG-DIFF |
| `lowering_reject_decl_prototype_phi.ll` | `cq rotation lowering: unsupported declared prototype for cq_phi` | SAME-MSG | RC 0->1 |
| `lowering_reject_legacy_phi_register_form_eqfold.ll` | `cq rotation lowering: retired register-form cq_phi_si32; use the register-free void cq_phi(double)` | RC 0->1 | RC 0->1 |
| `lowering_reject_legacy_phi_register_form.ll` | `cq rotation lowering: retired register-form cq_phi_si32; use the register-free void cq_phi(double)` | MSG-DIFF | RC 0->1 |
| `lowering_reject_phi_address_taken.ll` | `cq taint propagation: front-end intrinsic cq_phi has its address taken; only a direct call is supported` | RC 0->1 | RC 0->1 |
| `lowering_reject_spec_branch_phase.ll` | `cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted` | MSG-DIFF | MSG-DIFF |

All 43 exit 1 with exactly ONE `error:`. `SAME-MSG` = byte-identical stderr; `MSG-DIFF` =
the message moved; `RC 0->1` = that binary ACCEPTED and this one declines (an over-accept
the round-1 fix closed).

---

## 3. Findings

### F-R2-1 — DOC-OR-FIXTURE-TRUTH (the headline). The round-1 fixture repairs were applied to part A and to nothing else in the merged tree; three assertion families are systematically absent from part B's 15 accepts and from 3 of the fix agent's own.

**The claim being falsified** is written in the shipped notes
(`RETIRE_SWAP_ROUTE_INC1_NOTES.md`, §"F-L6-3 / F-L6-4 / F-L8-1 / F-L8-2 / F-L4-2"):
*"**All 11** enumerating accepts listed SIX of the EIGHT non-`i1` Rz widths … Replaced with
ONE complement regex"* and *"Three fixtures that emit NO `cqrt_x` had no negative for it …
Added."* Both were true of the corpus the fix agent could see. **In the tree those
sentences ship in, 18 accepts under-enumerate and 20 lowering accepts have no `cqrt_x`
assertion at all.** Fifteen of those 18 carry, verbatim, the same header sentence the
repair was made to make true: *"a `cqrt_rz_<W>` for W != i1 (the TENSORED per-register Rz
PRD §1 records as the defect)"* — e.g. `control_phase_nest_kickback.ll:78`,
`control_phase_switch_kickback.ll:86`, `control_phase_kickback_or2.ll:68`.

**Measured, with the discriminating control in every case.** Injecting one line before
`ret` into each fixture's own output, fixtures unmodified:
* `cqrt_rz_f80` / `cqrt_rz_f16` → **NOT CAUGHT** in `and2`, `and3_tree`, `andbo`, `or2`,
  `xor2`, `tree_negated`, `tree_shared_leaf`, all five `nest_kickback*`, all three
  `switch_kickback*`, `share_flag`, `share_flag_negated`, `onward_merge` (**18**);
  **CAUGHT** in the other 18 by `NOROUTE`. The only difference between the two groups is
  the directive line — `cqrt_rz_i32` is caught in all 37.
* `call void @cqrt_x(i32 0)` → **NOT CAUGHT** in 21 of 37, incl. every P4 nest and every
  P5 switch accept. An unpaired `cqrt_x` on the flag is a **wrong-branch phase** — the
  L1-lens miscompile class. **Seven** of the blind files legitimately emit `cqrt_x`
  (`onward_merge` 8×, `nest_kickback_outer_negated` 6×, `nest_kickback_inner_negated` 4×,
  and `nonfinite_arm` / `inloop_derived_cond` / `inloop_reject_hoisted_temp` /
  `tree_negated` 2× each), so they need an `XCNT-COUNT-n` + `XCNT-NOT` pair (as `ifelse`,
  `ifelse_tail_armfalse`, `negated_tail_phi` and `share_flag_negated` already have); the
  other **13** emit none and need the blanket `; NOROUTE-NOT: call void @cqrt_x(` that
  `diamond`, `f64_cond`, `seq`, `inloop`, `inloop_body_gate` and `two_calls` already carry.
* `call void @cqrt_free(i32 0)` → **NOT CAUGHT** in 20 of 37 (19 lowering accepts). An extra `cqrt_free` is a
  hidden measurement (Rule 6).
* DROP the compare `_unc` strip (so the flag is freed **dirty**) → **NOT CAUGHT** in 3
  (`nonfinite_arm`, `onward_merge`, `share_flag_negated`).

**Why this is worse than the same finding was in round 1, and it is the part that matters.**
Round 1 could grade the width gap "assertion-completeness, not a live miscompile" because a
*substitution* was still caught by the count prefixes and because the e2e layer's stage 2b
backs the `cqrt_x` / `cqrt_free` classes. **Neither mitigation is wired at `c4bd888`:**
* stage 2b **does** catch all three of dropstrip / extrafree / unpaired-`cqrt_x` on exactly
  the nest and switch shapes whose fixtures are blind — **measured rc=1 on all three, on
  `control_phase_nest_kickback` and `control_phase_switch_kickback`** — and it is
  **structurally blind to the Rz-width class** (measured rc=0 on an injected `cqrt_rz_f80`;
  `cqrt_rz` is deliberately transparent, which the notes state);
* **but 63 of the 66 `tests/e2e/*.c` that call `cq_phi` FAIL STAGE 1 against this branch's
  own header** (measured: `error: too many arguments … expected single argument 'angle'`).
  There is **no runnable e2e witness for any shape Inc 1 lowers** in this tree, so stage 2b
  runs on none of them. `ir-pass-lit` is the only gate this branch has.

**Fix (validated in both directions by the same harness).** (i) Replace the six-width
enumeration in the 15 part-B accepts and the one-width negative in the 3 fix-agent accepts
with the shipped complement regex — clean output passes, `f80`/`f16`/`i16`/`i32` injections
fail, and the trailing `(` is load-bearing (`cqrt_rz_i1` is a textual prefix of
`cqrt_rz_i16`). (ii) Add `; NOROUTE-NOT: call void @cqrt_x(` to the 13 blind accepts whose
correct stream has zero `cqrt_x`, and an `XCNT-COUNT-n` + `XCNT-NOT` pair to the 7 that
legitimately emit them. (iii) Add a `FCNT-COUNT-n` + `FCNT-NOT` pair to the 19 lowering accepts with no
`cqrt_free` assertion (the counts are in `§2`'s table and in `matrix2.tsv`). (iv) Correct
the notes' two "all 11 / three fixtures" sentences to the post-merge population.

### F-R2-2 — DOC-TRUTH. The shipped notes say the branch-phase record is at "all THREE emission sites"; the tree they ship in has SIX, and the next sentence is the sentinel for the round's #1 miscompile.

`RETIRE_SWAP_ROUTE_INC1_NOTES.md:64-66`: *"**Recorded at all THREE emission sites**
(`SwapRouteEmit::emitPhaseKickbackRegion`'s arm loop and its merge-tail loop, and
`AngleSelectEmit`'s Rz stem). A fourth emitter that mints a kickback gate and forgets the
call re-opens this with no diagnostic anywhere."*

MEASURED at `c4bd888` — `grep -rn 'markBranchPhaseGate' ir-pass/src`: **six call sites** —
`SwapRouteEmit.cpp:1538` (arm loop), `:1568` (merge tail), **`:1773` (the P4 nest)**,
**`SwitchRouteEmit.cpp:179` (the P5 switch)**, `AngleSelectEmit.cpp:179` and `:181`.
The merge DID find and mark the two new minters — that is recorded in
`$SP/progress/fix_r1.md` under "⚠ WHAT THE MERGE EXPOSED" — but **the shipped notes were
never updated**, and `markBranchPhaseGate` appears in that file at only two lines (57, 64),
neither mentioning the nest or the switch. A reader auditing "is every emitter marked?"
against the shipped record gets a count that is short by two, on the one sentence whose
whole purpose is to make that audit possible. Fix: one sentence, and name all six.

### F-R2-3 — DOC-OR-FIXTURE-TRUTH. Two shipped fixture headers still carry the retired "BROKEN MODULE at `opt` exit 0" claim that round-1 F-L3-5 measured FALSE, and one of them was written AFTER the correction.

Round-1 F-L3-5 established, and the notes record, that `cq-opt` runs
`CQLoweringPass → VerifierPass → print` with LLVM's default `FatalErrors=true`, so a broken
OUTPUT module **aborts** (exit 134) rather than exiting 0. The notes say *"Both comments
corrected"* — and the two SOURCE comments **are** (`ir-pass/include/ArmAnalysis.h:253-254`
and `ir-pass/src/SwapRouteEmit.cpp:1402` both now carry `⚠ NOT "at opt exit 0" — MEASURED
FALSE`). Two FIXTURE headers were not in that set:
* `ir-pass/test/control_phase_kickback_ifelse_tail_phi.ll:27-28` — *"`PHI nodes not grouped
  at top of basic block!` at **opt exit 0**"*;
* `ir-pass/test/control_phase_nest_reject_merge_phi.ll:6-7` — *"a BROKEN MODULE at `opt`
  exit 0 (`PHI nodes not grouped at top of basic block!`)"*.

The second is **part B's** (`1230737`), i.e. the false claim has already propagated once
onto a branch that never saw the correction — which is exactly the
hardened-by-repetition mode F-L3-5 was filed to stop. (`grep -rn 'PHI nodes not grouped'`
finds no other live occurrence outside `docs/archive/`.) I VERIFIED the wiring by reading
`ir-pass/tools/cq_opt_main.cpp:110-112` (`MPM.addPass(VerifierPass())`, default ctor ⇒
`FatalErrors=true`) and MEASURED that the INPUT verifier gives rc=1 with
`cq-opt: input module is broken`; I did **not** reproduce the exit-134 output-verifier abort,
because I could not construct a module this pass breaks — say it that way, not "confirmed".

### F-R2-4 — DOC-OR-FIXTURE-TRUTH. Three shipped fixture headers, and the notes' own e2e witness, cite `tests/e2e` artifacts that are absent or non-compiling in the tree they ship in.

| citation | state at `c4bd888` |
|---|---|
| `control_phase_kickback_and2.ll:28` — *"The e2e layer is where the two SOURCES are distinguished (`slice_control_phase_andcond.c` vs `slice_control_phase_nest.c`, whose goldens must match byte for byte)"* | **both files ABSENT** |
| `control_phase_nest_reject_mixed_arm.ll:3` — *"the migrated `slice_control_phase_nest_deep.c`"* | **ABSENT** |
| `control_phase_kickback_ifelse_tail_phi.ll:5-6` — *"This module is `clang -O1`'s OUTPUT for `tests/e2e/slice_control_phase_ifelse_derived.c`, transcribed"* | file PRESENT but on the **RETIRED** surface (`q = cq_phi(q, 0.9)`); `clang` refuses it, so the transcription cannot be re-derived |
| notes §F-L7-1 — *"prep-b's already-rewritten `tests/e2e/slice_control_cond_datause.c` run on this binary is BYTE-IDENTICAL to its committed golden except the two intended lines"* | the committed file is the **old-surface** one (`slice_control_cond_datause.c:34`), which does not compile here |

MEASURED: of the 66 `tests/e2e/*.c` that mention `cq_phi`, **63 fail stage 1** on this
branch's header and the 3 that compile do not call it. This is prep-b's unmerged scope and
both implementers recorded it — the finding is that four shipped documents point a reader
at witnesses that are not in the tree, and that (with F-R2-1) `ir-pass-lit` is the branch's
only gate. Fix: mark each citation "prep-b, not yet merged", or move the claims to the
merge that lands the slices.

### F-R2-5 — DOC-TRUTH (a count that does not reproduce, in the document that records F-L6-2).

The notes' deviation rationale for using metadata over a `TaintSet` set says the three spine
predicates are *"asked from **19 call sites in 6 files**"*. MEASURED
(`grep -rn 'isInPlaceGateOn(\|preservesBasisUnderRecord(\|isInverseEmittable('`, excluding
definitions and declarations): **21 call sites in 7 files** — `ArithLowering` 1,
`BennettWrap` 1, `BreakReversePlay` 2, `ChainWalk` 6, `DagTraversal` 3, `EmitInverse` 1,
`Uncomputation` 7 — and **identically 21/7 at `fa96336` and at `71d4cce`**, so it is not a
figure that went stale. The ARGUMENT is unaffected (the true number is larger and the three
`TaintSet`-less callers the notes name are all present), but this is the F-L6-2 class —
a census in a write-up that does not reproduce — inside the paragraph that records F-L6-2.

### F-R2-6 — FIXTURE-TRUTH. `control_phase_switch_reject_default_body.ll` does not pin what its name and first line say, and the shape it actually excludes is pinned by nothing.

Its first line: *"a tainted-scrutinee phase `switch` with a **NON-EMPTY default arm** (the
4.5 C5 shape)"*. Removing the named cause — deleting the `call void @cq_phi(double 9.0e-01)`
from `%def`, leaving `def: br label %merge` — still **DECLINES** with the identical
`cq controlled lowering: control flow under quantum control` (`disc/d1.ll`, rc=1). Only
re-pointing the default EDGE at `%merge` and deleting the block makes it accept
(`disc/d1b.ll`, rc=0). The accept fixture confirms it: `control_phase_switch_kickback.ll`'s
switch is `switch i32 %q, label %merge [...]`. So the fixture discriminates *"the default
edge does not go straight to the merge"* — which its own third sentence states correctly —
and an **empty but distinct** default block is an unpinned over-decline (not plain-C
reachable: SimplifyCFG folds it). By contrast `control_phase_switch_reject_grouped.ll` and
`control_phase_switch_reject_merge_phi.ll` ARE discriminators (ungrouping → rc=0; removing
the merge φ → rc=0, `disc/d2.ll`, `disc/d3.ll`). Fix: retitle to the edge condition, or add
the empty-default-block row as its own fixture.

### F-R2-7 — FIXTURE-TRUTH. The record that stops F-L7-1 recurring hangs, for the whole angle-select stem, on ONE file whose stated subject is something else.

Per-gate mark-drop map (`markmap.tsv`, every `!cq.branchphase` dropped one gate at a time):
every one of the six emission sites IS pinned by at least one fixture — `and2` (MDTAG),
`nest_kickback` (MDTAG-COUNT-2), `switch_kickback` (MDTAG-COUNT-3), `ifelse` /
`ifelse_tail_armfalse` / `negated_tail_phi` (the merge-tail loop, CHECK), `share_flag*` and
the three `inloop_*` (the arm loop, CHECK) — **but the `AngleSelectEmit` stem is pinned by
exactly one file in 1661: `control_angle_select_phase_nonfinite_arm.ll`**, whose header's
own subject is the deliberate `inf`-arm pass-through and which exists so *"nobody re-enables
the whole fence later"*. Its two flagship siblings `control_angle_select_phase_constants.ll`
and `..._runtime.ll` assert nothing about the record, and both are **ALL-PASS on the
`fa96336` binary** (measured, `r1red.py`), i.e. they pin nothing the round-1 fix changed.
Dropping the mark at `AngleSelectEmit.cpp:179`/`:181` reddens 1 fixture. Fix: add the
`, !cq.branchphase` suffix to the two `CHECK-NEXT` gate lines in `_constants` and `_runtime`
(they already `CHECK-NEXT` those exact calls — a one-token edit, validated: the r1 binary's
output lacks the suffix, so the edit is red-green on a binary in the tree).

### F-R2-8 — FIXTURE-TRUTH (informational). `control_phase_kickback_onward_merge.ll` is the weakest accept in the family, on the axis its own finding is about.

It is the ACCEPT half of F-L3-1, whose reproducer **B** was an over-accept in which a value
arm was **`cqrt_cswap`-routed under the very flag whose phase had been deleted**. It is the
**only** kickback accept in the branch with **no `NOROUTE-NOT: cqrt_cswap`** (measured: the
`cswap` injection is NOT CAUGHT; every other kickback accept catches it), its Rz negative is
the one-width `@cqrt_rz_i32`, and it has no `cqrt_free` count and no `cqrt_x` assertion —
6 of 10 injections MISSED. Its CHECK chain also starts at the SECOND region (`%h_cmp2`), so
the round-1 6.5 classical-call-arm region in the same function is entirely unasserted.

### F-R2-9 — informational. 13 prose lines in 12 fixtures parse as FileCheck directives under a naive scanner.

`; MEASURED:` ×2, `; ROLLED:`, `; DROPPED:`, `; MISCOMPILE:`, `; POLARITY-DEPENDENT:`,
`; before:`, `; first:`, `; carrying:` ×3, `; branch:`, `; widening:`, `; meaningful:`.
**Inert today** — FileCheck honours only prefixes named on its command line, and none is
named — so this is not a live hole; it is flagged because two of them (`DROPPED`,
`MISCOMPILE`) would become live assertions the moment a RUN line grew a
`--check-prefixes=CHECK,DROPPED`, and because a reviewer's scanner reads them as dead
directives. Full list in `hygiene2.txt`.

### F-R2-10 — informational. `control_phase_switch_reject_table_fold.ll` says "VERBATIM `-O1` output"; the module is transcribed.

Re-derived from C: `clang -O1` on the source in the header does produce
`@switch.table.example = private unnamed_addr constant [3 x double] [...]` + `zext`/`gep`/
`load double` + `tail call void @cq_phi(double noundef %7)` — the load-bearing structure
reproduces exactly, so the fixture's POINT stands. The committed module is edited
(declarations hoisted, function renamed `@example` while its table keeps the name
`@switch.table.**main**`, attributes stripped), so "VERBATIM" is not the right word.
`control_phase_kickback_ifelse_tail_phi.ll` says "transcribed" for the same kind of file,
which is the honest spelling.

### F-R2-11 — informational (minor). The MDCNT/MDTAG pair works; its shipped explanation is inexact.

`control_phase_kickback_and2.ll:126-129` says *"A future emitter that mints a gate and
forgets the call moves the first count and not the second, and this file goes red."*
MEASURED: an extra gate placed AFTER the marked one moves **both** (`MDCNT` and `MDTAG`);
an unmarked gate placed BEFORE the marked one moves only `MDCNT`; a **dropped mark** moves
only `MDTAG`, at every gate index, in all three MD fixtures. The intended property is true;
the sentence describes one of three cases.

---

## 4. CLEAR — measured and true, stated so it is not re-run

1. **The emitted Rz set IS `cqrt_rz_i1` only**, corpus-wide, not just on the branch:
   1661 fixtures swept, 633 accept, **35 emit `cqrt_rz_i1`, 598 emit no `cqrt_rz`, 0 emit
   any other width**; and all 35 are branch fixtures. `rzRtFn(` has exactly 4 call sites,
   all `"i1"`; `controlledRotationFn(` has 2, both `RotStem::Ry` explicit. PRD §5's table
   row is TRUE at this HEAD.
2. **Every emitted `cqrt_rz_i1` carries `!cq.branchphase`** — recounted per fixture on all
   35: `cqrt_rz_i1` count == marked count, 35/35 — and the mark never lands on any other
   call in any of the 37 accept outputs.
3. **The pass's postcondition holds**: 0 of the 633 accepting fixtures leave a surviving
   `@cq_phi` / `@cq_phi_<sfx>` / `@cq_theta_<sfx>` CALL. All 12 of round-1 L6's third-path
   survivors now decline `retired register-form cq_phi_si32`.
4. **The fix changed nothing else.** Over the **1581 inherited** fixtures, subject vs
   `fa96336`: 396 rows change, **15 RC 0→1 + 381 message pre-emptions, and ZERO stdout
   (lowered-output) changes** — every one of them the F-L6-1 reserved-name decline.
5. **Blast radius reproduces exactly**: 34 new red vs `fa96336`, 0 newly green, all inside
   the 493-file family set, including the five the notes single out.
6. **F-L6-2's census reproduces EXACTLY at `fa96336`** (I re-ran lit there): 1602
   discovered / 362 failed / 491 family files / **129 green = 103 declines + 26 accepts**;
   **35 with a live CALL, of which 4 accept**. The retired "155 = 104 + 51" is properly
   corrected in the notes.
7. **F-L6-3's frontend repair is real, validated by injection**:
   `tests/frontend/cq_phi_smoke.c` clean passes both prefixes; a `call i32 @cq_phi_si32`
   **inside `@use()`** is CAUGHT by `NOFAM` (rc=1, the case that was NOT caught before), a
   `declare` at EOF is CAUGHT, and dropping a `cq_phi` call is CAUGHT by `CHECK`.
8. **Decline-string truth**: 43/43 declines exit 1 with exactly one `error:`; every
   positive `CHECK` is a literal substring of the emitted line; the `CHECK-NOT: bare i1
   condition` pair in `..._reject_compound_cond.ll` / `..._reject_tree_notform.ll` are real
   discriminators for the F-L3-7 message split, and the subject now emits the ORACLE's
   message on both (`SAME-MSG`, `threebin.tsv`).
9. **`control_phase_kickback_and2.ll`'s byte-identity claim reproduces**: I compiled both C
   spellings (`&&` and the folded nest) at `-O1` and `diff` of the two `@slice` bodies is
   **empty**. So the deliberate absence of a second `.ll` is correct, not a coverage gap.
10. **`control_phase_kickback_diamond.ll`'s header claim** that all three `recoverRegion`
    recognizers require a non-null `soleMergePhi` holds at `c4bd888`
    (`ControlDetect.cpp:298`, `:312`, `:333`).
11. **Prefix hygiene**: `NOROUTE` is pure-negative and whole-file in **80 of 80**; every
    `C<n>`/`ACNT`/`FCNT`/`XCNT`/`UCNT`/`MDCNT`/`MDTAG` prefix carries exactly ONE positive
    followed by its `-NOT`; no RUN-named prefix lacks directives; **0** literal `%name` in
    any of the 464 positive directives is absent from that fixture's own output. The
    Inc-3 F-L6-1 windowing defect and the Inc-4 "9 of 20 named a `%h1` that does not exist"
    defect are both genuinely absent from what shipped.
12. **Stage 2b STRICT** passes on all 37 accept outputs (0 violations, 0 unproven), and it
    **does** catch dropstrip / extra-free / unpaired-`cqrt_x` on the nest and switch shapes
    (rc=1) — it is simply not wired to any kickback program at this HEAD (F-R2-1, F-R2-4).
13. The nine declared Rz ABI widths in `runtime/cq_runtime.h:140-148` match the notes'
    "NINE Rz widths"; `runtime/` and `tools/opcode_table.yaml` are untouched by the branch
    (`git diff --name-only dfb8e83..c4bd888` — no runtime file listed), so the epic's
    "NO new frozen symbol" rule holds.

---

## 5. Things I did NOT verify, said first

* I did **not** reproduce the exit-134 output-verifier abort (F-R2-3) — I read the wiring
  and measured only the INPUT verifier's rc=1.
* I did **not** rebuild any binary, so the "each emission site is pinned" claim in F-R2-7 is
  established by **output** mutation (dropping `!cq.branchphase` per gate), not by deleting
  a `markBranchPhaseGate` call and rebuilding; the fix agent did the latter for 3 of the 6.
* I did **not** run the full `ctest`, any e2e slice, or `e2e-loop-twin-matrix`.
* I did **not** re-review the LOWERING (R1's lens). Every finding here is about what the
  fixtures and the shipped prose ASSERT, not about what the pass computes.
* The per-fixture "MISS" cells are statements about **that injection at that position**.
  Where a miss is an artifact of the injection landing in territory the fixture does not
  claim (the round-1 6.5 region inside `onward_merge`), I say so rather than counting it.

---

## VERDICT — R2 (fixture / doc truth): **NOT CLEAR — 0 miscompiles, 0 over-accepts, but 5 substantive DOC-OR-FIXTURE-TRUTH findings, one of them systemic.**

The branch's *measurable* claims hold and hold cleanly: the emitted Rz set really is
`cqrt_rz_i1` and nothing else across all 1661 fixtures; every emitted gate really does carry
the `!cq.branchphase` record; the pass postcondition holds on all 633 accepting fixtures;
the round-1 fix changed **no** inherited fixture's lowered output; the red partition, the
blast radius and F-L6-2's corrected census all reproduce to the file; every decline string
is character-for-character what the source builds; and no handle name is typed rather than
derived.

What is NOT true is the fixture layer's own account of itself, and the shape of the failure
is the epic's own standing lesson one level down: **the round-1 repairs were applied to the
set that was in front of the fix agent, and the SAME question was never asked of the set the
merge brought in.** Part B's 15 accepts and 3 of the fix agent's own carry the exact
assertion gaps round 1 was convened to close — 18 blind to `cqrt_rz_f16`/`f80`, 21 blind to
an unpaired `cqrt_x` (a wrong-branch phase), 20 blind to an extra `cqrt_free` (a hidden
measurement) — while 15 of them repeat, verbatim, the header sentence the repair made true
elsewhere (**F-R2-1**). The shipped notes still say the branch-phase record sits at "THREE
emission sites" when the tree has six, in the sentence whose job is to let a reader audit
exactly that (**F-R2-2**). Two fixture headers still carry the "broken module at `opt` exit
0" claim round 1 measured false, one of them written after the correction (**F-R2-3**). Four
shipped documents cite e2e witnesses that are absent or non-compiling here (**F-R2-4**), and
that is what raises F-R2-1 above bookkeeping: **63 of 66 `cq_phi` e2e slices fail stage 1 on
this branch's header, so stage 2b — which I measured DOES catch the dropped-strip,
extra-free and unpaired-`cqrt_x` classes on precisely the nest and switch shapes whose
fixtures are blind — runs on not one program Inc 1 lowers.** `ir-pass-lit` is the only gate
this branch has, and on three axes it is weaker than the round that just cleared it believes.
Everything in **F-R2-1/2/3/4/6/7** is a fixture-or-prose edit; none of it asks the lowering
to change.
