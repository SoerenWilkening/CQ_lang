# Inc-1 fixture migration report — register-free `cq_phi`

> bd epic `test_C_libtooling-3qlq`, Increment 1 preparation (agent `prep_a`).
> Branch `3qlq-inc1-migration`, base `dfb8e83`. Tool:
> `tools/migrate_phi_fixtures.py`; hold list
> `tools/migrate_phi_fixtures.hold.txt`.
>
> **Every number below is MEASURED, with the command that measured it.** The
> compiler used throughout is the **ORACLE** — the pre-3qlq build at commit
> `52d7764`, `$SP/wt/pre-3qlq/build/ir-pass/{cq-opt,libCQPass.so}`. The Inc-1
> binary does not exist yet; everything that needs it is marked
> `NEEDS-REDERIVE`. **No fixture file was deleted.**

---

## 1. What the migration is

`cq_phi` becomes `void cq_phi(double)` (PRD §4.1, decisions D1/D2). In the corpus
the old spelling is `%r = call T @cq_phi_<sfx>(T %x, double THETA)`, and each CALL
SITE takes one of three treatments:

| site class | treatment |
|---|---|
| **U** uncontrolled / classically-controlled | global phase → **delete**; RAUW `%r → %x` (D2) |
| **A** inside a tainted arm | `call void @cq_phi(double THETA)`; the merge phi that carried `%r` against `%x` is **dissolved** to the pred incoming |
| **S** angle select | `call void @cq_phi(double %ang)` where `%ang` is the tainted-condition `select` — PRD §6.2 **P2**, the `-O1` fold of `if (c) cq_phi(A); else cq_phi(B);` |

A file also gets a treatment of its own: a dead `declare … @cq_phi_<sfx>` is
erased (class **D**), and a file that only MENTIONS `cq_phi` in prose or CHECK
text is untouched (class **M**).

---

## 2. Population, measured

```
$ ls ir-pass/test/*.ll | wc -l                                     1582
$ grep -l 'cq_phi' ir-pass/test/*.ll | wc -l                        540
$ grep -lE '^[^;]*call [^;]*@cq_phi_' ir-pass/test/*.ll | wc -l      396   files with >=1 CALL
$ grep -lE '^declare[^;]*@cq_phi_' ir-pass/test/*.ll | wc -l         490   files with a declare
$ grep -hoE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll | sort | uniq -c
        976 @cq_phi_si32   80 @cq_phi_f64   12 @cq_phi_sll     — 3 of the 16 suffixes
```

`python3 tools/migrate_phi_fixtures.py --report`:

| class | files | accept / decline | meaning |
|---|---:|---|---|
| U | 136 | 58 / 78 | every site UNCONTROLLED → deleted (D2) |
| A | 197 | 82 / 115 | every site IN A TAINTED ARM → void call, merge phi dissolved |
| S | 13 | 4 / 9 | ANGLE SELECT (PRD §6.2 P2) |
| MIX | 26 | 18 / 8 | a mixture of the above inside one file (the rewrite is per-SITE) |
| H | 24 | 0 / 24 | HAND-DECISION: the angle operand is TAINTED and is not a `select`/`phi` |
| D | 94 | 22 / 72 | a dead `declare … @cq_phi_<sfx>` and no call |
| M | 50 | 32 / 18 | `cq_phi` appears only in prose / CHECK text |
| **total** | **540** | | |

Call sites: **U 196 · A 336 · S 18 · H 24 = 574**, equal to the independent
`grep -hcE '^[^;]*call [^;]*@cq_phi_'` total of **574**. That equality is the
parser's own cross-check: the walker sees every call site the grep does.

---

## 3. How "inside a tainted arm" is decided, and its limits

`llvmlite` is not installed and the pass cannot be asked — roughly two thirds of
these fixtures are DECLINE fixtures, where `opt` exits non-zero and prints no
module. So the tool carries a textual SSA walker: taint seeded at `cq_theta_*`
results, sunk at `cq_measure_*`, never through the arg-1 angle (Rule 3);
post-dominators over the textual CFG; a call is in a tainted arm iff its block is
**transitively** control-dependent on a `br`/`switch` with a tainted condition.

`python3 tools/migrate_phi_fixtures.py --limits` prints the authoritative list.
The load-bearing ones:

* **memory is not modelled** — a function that stores a tainted value is forced to
  class A (3 files, note `mem-taint`);
* **interprocedural** — a callee whose call site is under tainted control has all
  its sites classified A (4 files, note `callsite-ctl`);
* **taint and control dependence are ONE fixpoint**, because a region MERGE PHI is
  re-seeded by the pass as a fresh quantum register (§4, bug 4);
* a `cq_phi` whose ANGLE is tainted is never class U.

---

## 4. Seven tool defects, all found by MEASUREMENT — and four of them the same defect

This is the part of the report worth carrying forward. The tool was written, read,
and then checked against the oracle. **The reading found nothing. The oracle and
`opt -passes=verify` found seven defects, and four of them had the identical
shape: a CONTROL-CARRYING `cq_phi` read as UNCONTROLLED, i.e. a gate that D2 would
have silently DELETED.** Deleting a controlled phase gate is not a broken build —
it is a verify-clean silent miscompile *of the fixture corpus*, which is the class
the Prime Directive exists to stop.

| # | defect | how it was caught | blast radius (measured) |
|---|---|---|---|
| 1 | **angle select read as uncontrolled.** `control_angle_select_rz_diamond.ll` has its `cq_phi` in a STRAIGHT-LINE block; the control lives in the ANGLE (`%ang = select i1 %c, double .9, double .3`). Class U ⇒ delete. | reading the fixture header while spot-checking the class-U list | introduced class S; **13 files / 18 sites** are class S today |
| 2 | **the immediate-post-dominator test was INVERTED.** It picked the candidate that post-dominates all others (the virtual EXIT) instead of the closest one, so the control-dependence walk never stopped at the merge and *every* block from a tainted branch to the function exit read as in-arm. | `opt -passes=verify` PARSE-FAIL on 16 migrated modules, traced back | A 204→178 after the fix; it also mis-classified a genuine merge-block gate — `control_inplace_ry_inloop_derived_cond.ll`'s loop-latch `%qn = cq_phi(%q,.1)` |
| 3 | **phi dissolution picked an arm-local incoming** (`if/else` where both arms rotate; loop-HEADER phis). | `opt -passes=verify`: `Instruction does not dominate all uses!` (9) and `use of undefined value` (7) | 16 broken modules → 0, after adding real forward dominators and resolving incomings through the `cq_phi` chain to a root |
| 4 | **a region MERGE PHI is re-seeded QUANTUM by the pass.** `%y = phi i32 [ %r, %arm ], [ 5, %entry ]` is classical by SSA data flow and is the merged quantum register `%out` after the 6.5 classical-call-arm / 4.5 switch-data-mux lowering, so `icmp sgt %y, 7` is a TAINTED compare. | ORACLE diff: the deleted call lowers on the oracle to `cqrt_rz_i32_controlled(%h_cmp2, %out, .25)` | 3 files; on `control_swap_reject_switch_datamux_angle.ll` the migration turned an ANGLE select into an fp DATA select — 2 × `cqrt_copy_f64_controlled` and 2 fresh f64 rails appeared |
| 5 | **multi-line `switch` case lists lost every successor but the first.** 36 of the 540 files spell the case list over several lines; CFG edges were read from the terminator LINE only. | the tool's own `unparsed_multiline` self-check — followed up rather than explained away | **17 files** moved MIX → A. On `control_swap_switch_phase.ll` blocks `a1`/`a2` had no incoming edge, so `%g1`/`%g2` — two `cq_phi` calls plainly inside switch arms — were class U and would have been deleted |
| 6 | **deleting a plain `CHECK:` that ANCHORS a `CHECK-NEXT` chain** leaves the surviving `-NEXT` demanding adjacency to a line it never followed. | post-migration `lit`, `control_inplace_ry_alias_chain_consumed.ll` | fixed by promoting the first surviving `-NEXT` back to a plain `CHECK` when the deleted run started on a non-`-NEXT` line |
| 7 | **deleting a `CHECK` that BINDS a FileCheck variable** still used by surviving lines → `error: undefined variable: H`. | post-migration `lit`, `lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll` | the whole file is now refused (HAND-DECISION). The rule is also the right SEMANTIC one — a fixture whose Rz CHECK is the BINDER is a fixture whose SUBJECT is the Rz |

Two of these deserve a second look.

**Bug 5 had already printed its own warning.** `unparsed_multiline` fired on 36
files and the first reading of it was "a `switch` case list, benign". It was not
benign. *A self-check that fires and is explained away is a self-check that did not
run.*

**Bug 7's fix is a semantic rule, not a workaround.**
`lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll` pins "`%p = cq_phi(%a)` is an
Rz that RAUWs `%p` to `%a`'s handle, so `fshl(%a, %p, 5)` reclassifies to the
rotation form". D1 removes that idiom outright: after migration the module is
`fshl(%a, %a, 5)` — the trivially-aliased case, not the post-RAUW-alias case the
fixture exists to pin.

---

## 5. The oracle equivalence check

`--verify-oracle` runs the ORACLE on the file and on its in-memory migration and
compares. For **class U and D the oracle is a real equivalence oracle**: the
migrated module contains no `cq_phi` at all, so the pre-3qlq binary answers it
exactly as the Inc-1 binary will. Normalisation removes uncontrolled
`cqrt_rz_<W>` call lines, `declare void @cqrt_rz_*`, `declare … @cq_phi*`,
`ModuleID`/`source_filename` and blank lines — i.e. **exactly the difference the
migration is allowed to make** — and then requires byte equality. For class
A/S/MIX/H the migrated module contains `call void @cq_phi(double)`, which the
oracle cannot lower, so the check degrades to well-formedness
(`opt -passes=verify`).

```
$ CQ_OPT=$SP/wt/pre-3qlq/build/ir-pass/cq-opt \
  CQ_PASS=$SP/wt/pre-3qlq/build/ir-pass/libCQPass.so \
  LLVM_OPT=/usr/local/opt/llvm@19/bin/opt \
  python3 -u tools/migrate_phi_fixtures.py --verify-oracle \
      --classes U,A,S,MIX,D,H --write-hold tools/migrate_phi_fixtures.hold.txt

oracle verdicts: {'A/PARSE-OK': 197, 'D/OK': 94, 'H/PARSE-OK': 24,
                  'MIX/PARSE-OK': 26, 'S/PARSE-OK': 13,
                  'U/EXIT': 22, 'U/OK': 109, 'U/STDERR': 5}
```

**The brief's step-5 invariant — "fixtures whose oracle output on the migrated IR
differs from the original by MORE than deleted `cqrt_rz` lines must be 0 for class
U" — HOLDS: EXTRA-DIFF = 0, RZ-LEFT = 0, PARSE-FAIL = 0, over all 540 files.**
Every class-U file the oracle accepts on both binaries produces output identical to
the original minus exactly the uncontrolled `cqrt_rz_<W>` lines.

What is NOT zero is the number of class-U fixtures whose **disposition** changes —
22 `opt exit 1 → 0` plus 5 whose diagnostic STRING changes. Those are not migration
errors; they are fixtures whose decline was *caused by* the gate D2 deletes. They
go on the hold list (§6).

---

## 6. HOLD list — 27 fixtures whose ORACLE disposition changes

`tools/migrate_phi_fixtures.hold.txt` is generated by the sweep above and read back
by every later run: a held file is HAND-DECISION and `--apply` skips it. All 27 are
`RUN: not` DECLINE fixtures. A **measured** proposed disposition comes from
`--probe-theta`, which swaps every `cq_phi_<sfx>` for `cq_theta_<sfx>` and asks
whether the ORACLE reproduces the ORIGINAL diagnostic character-for-character:

```
$ for f in $(awk 'NR>2{print $1}' tools/migrate_phi_fixtures.hold.txt); do
    CQ_OPT=… CQ_PASS=… python3 tools/migrate_phi_fixtures.py --probe-theta --only "$f" …
  done                                    ->  16 THETA-OK   11 THETA-NO
```

**16 THETA-OK — proposed disposition: swap the gate to `cq_theta`, CHECK unchanged.**
`cq_phi` there is merely "a gate on a handle"; the subject is uncompute / mux /
measurement ordering.

```
control_inplace_ry_reject_inloop_lifted_phi.ll        lowering_reject_uncompute_divergent_arm_taped.ll
control_predmux_fp_diamond_rzlineage_declines.ll      lowering_reject_undef_literal_paired_rz_angle.ll
control_swap_reject_select_fp_coherent_call_derived.ll lowering_uncompute_divergent_arm.ll
lowering_reject_classical_mux_phi_crossblock_chain.ll  lowering_uncompute_escape_unrecognized.ll
lowering_reject_classical_mux_phi_loop.ll              lowering_uncompute_loop_backedge.ll
lowering_reject_classical_mux_phi_onereg_nway_crossblock_chain.ll
lowering_reject_classical_mux_phi_onereg_nway_loop.ll  lowering_uncompute_loop_backedge_irreducible.ll
lowering_reject_loop_rail_fanout_rot.ll                lowering_uncompute_postmeasure_use.ll
spec_reject_cq_primitive.ll
```

Worked example, measured: `lowering_uncompute_postmeasure_use.ll` with
`@cq_phi_si32(i32 %h, double 1.0e-01)` replaced by `@cq_theta_si32(i32 %h, …)`
emits `error: pm.c:4:9: … cq uncompute: gate applied to handle after measurement` —
byte-identical to the fixture's CHECK.

**11 THETA-NO — the fixture's SUBJECT is the Rz phase itself; no mechanical
disposition exists.**

```
control_swap_reject_abort_phase_sibling.ll           control_swap_reject_select_phase_operand.ll
control_swap_reject_phase_value_escaping.ll          control_swap_reject_select_phase_sibling_alias_i32.ll
control_swap_reject_select_coherent.ll               control_swap_reject_switch_value_clobber.ll
control_swap_reject_select_fp_coherent.ll            control_swap_reject_value_alias_cond.ll
control_swap_reject_select_fp_phase_operand.ll       lowering_reject_decl_prototype_phi.ll
control_swap_reject_select_fp_phase_sibling_alias.ll
```

Two sub-groups, both worth an owner-level read (§8):

* **the "phase-class value" family** (8 files) — `hasCoherentDownstreamUse`, the
  4.4 gate-5 backward half, the 7.2 abort-park phase sibling, the PredMux
  `rzlineage` decline. Every one of them protects *a value that carries a relative
  phase*. **After D1 no value carries one** — a phase attaches to a BRANCH.
* **`control_swap_reject_switch_value_clobber.ll`** is the **ONLY G7 fixture** (the
  §3c clobber) and its whole construction is "`%q = cq_phi(%p, θ)` is a DIAGONAL
  derivation of `%p`, so `%q` and `%p` are SSA-disjoint but wire-identical". That
  idiom has no `cq_phi` spelling after D1.
* `lowering_reject_decl_prototype_phi.ll` pins the RESERVED-NAME prototype check
  for `cq_phi_si32`. Under the new surface the reserved name is `cq_phi` with
  prototype `void(double)`; whether it stays in the 42-name surface is an Inc-1
  implementation fact.

---

## 7. HAND-DECISION set — 77 files, none deleted, none migrated

`awk -F'\t' 'NR>2 && $9!=""' <report> | wc -l` → **77**, and

```
comm -13 <hand-decision set> <files still carrying a `declare … @cq_phi_*`>   EMPTY
comm -23 <hand-decision set> <files still carrying a `declare … @cq_phi_*`>   EMPTY
```

both empty, i.e. **the 77 files that still reference the old surface are EXACTLY
the 77 hand-decision files** — none outside the set, none inside it already clean.
The brief's "the `declare` count of `@cq_phi_*` must be 0" is therefore reached the
moment these 77 are decided; it is **0 outside the hand-decision set today**.

| group | files | why it is a hand decision |
|---|---:|---|
| **HOLD** (§6) | 27 | the ORACLE disposition changes; 16 have a measured `cq_theta` disposition, 11 do not |
| **undissolvable merge phi** | 24 | the phi's two edges really do carry two DIFFERENT registers, so there is no pred incoming to dissolve to. All 24 are `RUN: not` DECLINE fixtures by construction: cross-handle, mixed arms, wrong literal, distinct base, `switch` mixed, `break`-phase-answer, quantum-bounded loop |
| **tainted angle** (class H) | 24 | the arg-1 angle is a TAINTED value that is not a `select`/`phi` — the `rotation angle under quantum control` / `unsupported quantum-derived rotation angle` decline family. `void cq_phi(double %tainted)` is presumably still a decline under Inc 1, but that is an Inc-1 fact, not an oracle fact |
| **structural** | 2 | `lowering_reject_intrinsic_invoke_phi.ll` (reaches `@cq_phi_si32` by `invoke`, which has its own decline) and `lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll` (bug 7) |

Full per-file list with reasons:
`python3 tools/migrate_phi_fixtures.py --report | awk -F'\t' 'NR>2 && $9!=""'`.

---

## 8. Findings that are not mine to decide

None of these contradicts a PRD §2 decision or a §12 assumption, so none is filed
as an OWNER QUESTION. They are measured facts the orchestrator/implementer needs.

**F1 — D2 dissolves the corpus's DERIVED-BASE idiom. 28 files.**
An uncontrolled `cq_phi` whose result is in the BACKWARD SLICE of a `br`/`switch`
condition is how this corpus builds a *derived* region base:

```
%q  = cq_theta_si32(%u0, .5)
%qd = cq_phi_si32(%q, .9)          ; the fixtures' own comment: "UNCONDITIONAL pre-rotation"
%c  = icmp sgt i32 %qd, 5
```

After D2 the pre-rotation is deleted, `%qd` IS `%q`, and each of those 28 fixtures
silently becomes the plain-base fixture that already sits beside it. The migration
is correct; the fixture's PURPOSE is what dies. Under the new surface the idiom
must be spelled with a second `cq_theta` or an arithmetic op (`%qd = mul i32 %q, 3`)
— a different wire story (out of place). Canonical:
`control_swap_diamond_derived.ll` and the whole `control_swap_*_derived*` family.

**F2 — PRD §6.3's "an arm with N>1 `cq_phi` calls declines" costs 11 currently-ACCEPTING fixtures.**
19 files have >1 `cq_phi` in one arm; 11 have no `RUN: not` line today
(`control_swap_diamond.ll`, `control_swap_diamond_polarity.ll`,
`control_swap_eqfold_diamond.ll`, `control_swap_eqfold_polarity.ll`,
`control_swap_ifelse_multigate.ll`, `control_swap_nested_phase_multigate_mid.ll`,
`control_inplace_rz_multi_rz_spine.ll`, `control_swap_diamond_after_classical_lift.ll`,
`control_swap_diamond_derived.ll`, `lowering_qram_fp64_measure_no_dirty_free.ll`,
`lowering_uncompute_interior_region_ifelse_chain.ll`).
**And the stated ground for that decline does not obviously apply to the kickback
spelling.** §6.3 says "summing angles is the 2b rounding class again" — but two
`cq_phi(θ1); cq_phi(θ2)` in one arm are two `cqrt_rz_i1(f,θ1); cqrt_rz_i1(f,θ2)` on
the SAME flag: that composes exactly and performs no arithmetic on the angles,
unlike the 2b by-difference `fl(A−B)`.

**F3 — the "phase-class value" concept is retired by D1**, and eight shipped
decline gates lose their only `cq_phi` spelling (§6). The gates themselves survive
for `cq_theta` lineage; it is their fixtures that die. `control_swap_reject_switch_value_clobber.ll`
is the sharpest case — the **only** G7 fixture in the tree.

**F4 — GREEN IS NOT EVIDENCE for the migrated A/MIX fixtures.** 55 of the 223 A/MIX
fixtures PASS under the ORACLE after migration (54 `RUN: not` declines whose
diagnostic still matches, plus
`lowering_reject_live_record_qram_fp64_load_index.ll`). The oracle does not lower
`call void @cq_phi(double)` at all, so a fixture can keep passing while the
construct it pins has vanished. **This is PRD §11's "the migration hides a semantic
change" risk, measured.** Those 55 are `NEEDS-REDERIVE` exactly like the 181 red
ones.

---

## 9. What was applied, and the lit result

```
$ python3 tools/migrate_phi_fixtures.py --apply --classes U,A,S,MIX,D
$ git status --short ir-pass/test | wc -l                            413
```

413 = 540 − 50 (class M, prose only) − 77 (hand decisions).

Invariants after the apply:

```
$ grep -lE '^declare[^;]*@cq_phi_' ir-pass/test/*.ll | wc -l          77   (== the hand set, exactly)
$ grep -lE '^[^;]*call [^;]*@cq_phi_' ir-pass/test/*.ll | wc -l       76
$ grep -lE '^declare void @cq_phi\(double\)' ir-pass/test/*.ll | wc -l 212
```

lit, against the ORACLE:

```
BEFORE:  lit -q ir-pass/test  ->  exit 0, "Total Discovered Tests: 1582", no failures
AFTER :  lit -q ir-pass/test  ->  "Total Discovered Tests: 1582",  Failed: 181 (11.44%)
```

Failures by pre-apply class: **U 0/136 · A 144/197 · S 13/13 · MIX 24/26 · H 0/24 · D 0/94 · M 0/50**

Class **U, D, H and M are GREEN**, and no fixture outside the 540-file `cq_phi`
population failed. The reds are exactly the A/S/MIX fixtures whose CHECK lines were
deliberately left untouched (brief step 4) — the ORACLE cannot lower
`call void @cq_phi(double)`, so those CHECKs cannot be re-derived until the Inc-1
binary exists.

---

## 10. What still needs the Inc-1 binary

1. **Re-derive the CHECK lines of every A / S / MIX fixture** — 236 files, of which
   181 are red today and 55 are GREEN-but-untrustworthy (§8 F4).
   Handle names must be DERIVED from the pass output, never hand-typed (the Inc-4
   lesson: 9 of 20 accepts named a `%h1` that did not exist). The tool marks these
   `NEEDS-REDERIVE` when it sees a `cqrt_rz_<W>_controlled` CHECK, since the
   kickback triple's handle numbers are not mechanically derivable.
2. **Decide the 77 hand-decision files** (§7), taking the 16 measured `cq_theta`
   dispositions as the default for the THETA-OK group.
3. **Confirm the class-H disposition**: 24 fixtures pin `rotation angle under
   quantum control` / `unsupported quantum-derived rotation angle` on a
   register-carrying `cq_phi`. Whether `call void @cq_phi(double %tainted)` still
   declines with the same string is an Inc-1 fact.
4. **Re-run `--verify-oracle` with the Inc-1 binary as the SUBJECT** and the
   pre-3qlq build as the ORACLE, for the classes the oracle could not answer
   (A/S/MIX/H). Only that comparison can witness the kickback stream.
5. **Rule 12 red-green for PRD §6.2 P1–P7 and §6.3** is the implementer's, not
   this migration's: no fixture for the new lowering was created here.

---
---

# PART II — the RE-DERIVATION on the Inc-1 binary (agent `prep_a2`)

> Branch `3qlq-inc1-migration`, REBASED onto the merged Inc-1 tip `c4bd888`
> (Inc 1a + the round-1 fixes + Inc 1b). **SUBJECT** = this worktree's
> `build/ir-pass/cq-opt` (built 2026-09-05 16:56, sources 16:51 — not stale);
> **ORACLE** = the pre-3qlq build at `52d7764`. Part I's `NEEDS-REDERIVE` markers
> and its 77 hand decisions are what this part discharges.
>
> **Every number below is MEASURED, with the command that measured it.**

## 11. Step 1 — the red partition. **(iii) OTHER IS EMPTY.**

```
$ cd build && lit -q ir-pass/test          # SUBJECT
Total Discovered Tests: 1661     Failed: 201 (12.10%)
```

Partitioned as a SET DIFFERENCE, not by eye:

```
red                                                                      201
set_migrated  = git diff --name-only 7f1d834~2 7f1d834 -- ir-pass/test    413
set_retired   = sed 's/;.*//' | grep -qE '@cq_phi_[a-z0-9]+'               79
comm -23  red  (set_migrated ∪ set_retired)                              ***0***
```

**No implementer regression.** Refined: 76 red in the retired-family (hand
decision) set, 125 red in the migrated set, overlap 0, and **0 migrated reds
outside A/S/MIX** — classes U and D are green on the Inc-1 binary, which is the
first evidence that Part I's class-U rewrite was right about the *lowering* and
not only about the *text*.

Three details Part I could not have known:

* the hand set is **76, not 77** — Part I's 77th
  (`lowering_reject_decl_prototype_phi.ll`) was rewritten by the implementer;
* three files match `@cq_phi_` only inside a `;` COMMENT and are correctly green;
* **three fixtures deliberately KEEP the retired spelling** —
  `lowering_reject_legacy_phi_register_form{,_eqfold}.ll` and
  `lowering_legacy_phi_decl_prototype_family.ll` — they pin round-1 finding
  F-L6-1's reserved-name decline and MUST NOT be migrated.

Class table re-derived by running `--report` on the rebased pre-migration tree
(`git archive c9a9811~1`): `A 198 · D 95 · H 24 · M 121 · MIX 26 · S 13 · U 136
· X 6` (X = 6 NEW implementer fixtures the textual parser cannot parse; all green).
A/S/MIX = 237 minus one new implementer fixture = **236**, Part I's figure exactly.
Of those, **212 were migrated** and **24 are the undissolvable-merge-phi hand
decisions**.

## 12. Steps 2–5 — the 212 A/S/MIX fixtures

`tools/migrate_phi_fixtures_rederive.py` (new; companion to Part I's tool).
Sweeping the SUBJECT over the 288-file work population gave a clean three-way split:

| | pins ACCEPT | pins DECLINE |
|---|---|---|
| SUBJECT accepts | **104 → re-derive the stream** | **13 → DISPOSITION FLIP** |
| SUBJECT declines | 0 | **95 → re-spell the diagnostic** |

**104 ACCEPTS re-derived** (commit `21bcece`, lit 201 → 105; 0 of the 104 still
red). The generated assertions follow the three rules that are each a recorded
defect, not a style preference: handle names are DERIVED and bound as FileCheck
variables at their definition so the chain asserts operand IDENTITY (bd drbq
Inc 4: 9 of 20 accepts named a `%h1` the pass never emits); `CHECK-NEXT` appears
ONLY where the two lines are literally consecutive in the output; NOROUTE is
whole-file and PURE-NEGATIVE (Inc-3 F-L6-1 and its Inc-4 recurrence). Two
properties of the generator are worth carrying:

* **a candidate negative ships only after FileCheck ITSELF measures that it does
  not fire on the clean output**, and one that would fire is DROPPED *and printed
  in the file*. The same for every ORIGINAL `-NOT`: re-measured whole-file, kept
  or recorded. A `-NOT` that used to sit after a positive of its prefix was
  WINDOWED; the whole-file re-ask is strictly stronger, and where the pattern is
  counted the `-COUNT-n`+`-NOT` pair pins *exactly n*.
* the STDERR half of a fixture (21 of the 104 assert a WARNING) is carried across
  VERBATIM with its RUN lines and directives. Regenerating the RUN block wholesale
  would have destroyed it silently.

**95 DECLINES re-spelled** (commit `a8dbf51`, lit 105 → 92): 16 CLAUSE-MOVED,
44 WIDENED, 35 already exact.

> ⚠ **The first draft put a FALSE SENTENCE in 44 headers, and the diff caught it,
> not the test.** It wrote "the CLAUSE that refuses it moved" for every edit — but
> 44 of the 60 were the SAME clause with the assertion widened from a suffix to
> the whole `DS_Error` text (`nested control flow …` → `cq controlled lowering:
> nested control flow …`). Only 16 were a real disposition change. The tool now
> splits on `newdiag.endswith(old)` and emits two different notes. Cross-check:
> the 16 CLAUSE-MOVED are **exactly** the 16 that were RED (`diff` of the two
> sets: identical).

### 12.1 ⚠ FINDING — three fixtures LOST THEIR SUBJECT, and a mechanical re-spell would have made them GREEN while pinning nothing they claim

Three of the 16 moved to `cq_measure_<sfx> operand not recognized; expected a
tainted i32 handle` — a MODULE WELL-FORMEDNESS error, not a control decline:

| fixture | now measures |
|---|---|
| `control_swap_reject_eqfold_wrong_edge_ifelse.ll` | `i32 7` |
| `control_inplace_ry_reject_stateprep_rz_prep.ll` | `i32 0` |
| `control_tainted_diag.ll` | `i32 %y0` (a plain argument) |

All three are built on `cq_phi_<sfx>(i32 <CLASSICAL>, θ)` — a phase gate whose
arg-0 is a constant or an untainted argument. **That call was the only thing
making the merged value quantum.** Part I's class-A rewrite dissolved the merge φ
to the pred incoming exactly as the rule says, and the pred incoming is that
classical value, so the migrated module feeds a constant to `cq_measure`. **The
migration is correct; the fixture's program is no longer a well-formed CQ
program.**

Population MEASURED on the pre-migration tree: **40 files** carry a
classical-literal arg-0 `cq_phi` and **32 of them migrated**; only these 3 reach a
quantum SINK with it.

⚠ **Part I's oracle check could not see this**, and the reason generalises: for
class A the check degrades to `opt -passes=verify`, and *an ill-formed CQ program
is a perfectly well-formed LLVM module*.

## 13. The 77 (measured: 76) hand decisions

| group | files | disposition |
|---|---:|---|
| class **H**, tainted angle | 24 | 22 MIGRATED to the void call (+2 held with the next group) |
| **HOLD**, THETA-OK | 16 | swapped to `cq_theta`, CHECK unchanged |
| **HOLD**, THETA-NO | 10 | 7 RE-SPELLED, 3 RETIRED |
| **undissolvable merge φ** (+2 H) | 26 | migrated under the new `--keep-merge-phi` |
| **structural** | 2 | 1 hand-migrated, 1 RETIRED |

### 13.1 class H — MIGRATED, not deleted (commit `702bd8f`)

An H site is, *by construction of Part I's own classifier branch*, an
UNCONTROLLED site (`blk not in under`) whose ANGLE is tainted. The naive D2
reading deletes it as a global phase and takes the fixture's subject with it.
MEASURED on the SUBJECT instead:

```
uncontrolled  call void @cq_phi(double %tainted)
    -> exit 1  cq rotation lowering: unsupported quantum-derived rotation angle
the same call INSIDE a tainted arm
    -> exit 1  cq controlled lowering: rotation angle under quantum control
```

The pass refuses the call **before** it decides whether it is a global phase, so
the tainted-angle rule survives D2 verbatim and the correct rewrite is the void
call. New `--migrate-tainted-angle` flag on Part I's tool, with that measurement
written at the site. 20 of the 22 keep a tainted-angle decline; 3 have the clause
PRE-EMPTED by an earlier guard and say so in their header.

### 13.2 HOLD/THETA-OK — 16, re-measured on the SUBJECT (commit `c854c3e`)

Part I measured these 16 against the ORACLE; this is the independent
re-measurement on the Inc-1 binary, and the counts agree exactly (**16 OK / 10
NO**). ⚠ The naive `sed` swap produces a DUPLICATE `declare` and `cq-opt` reports
`invalid redefinition`, which reads as THETA-MOVED — the first probe said 26/26
MOVED for that reason alone. With the declare deduped, each of the 16 reproduces
its ORIGINAL diagnostic character-for-character and the CHECK lines are unchanged.
The headers record what the swap does *not* preserve: Rz is diagonal and Ry is
not, so a rule turning on diagonality would move — none of these 16 do, and the
character-for-character reproduction is what establishes it.

### 13.3 ⚠ STRUCTURAL FINDING — `diagonalAliasHit`'s hop and `walkPhaseSpine`'s loop are now UNREACHABLE

`diagonalAliasHit` (`ArmClassify.cpp:275`) hops only through `isPhiCall`, and
`isPhiCall(V)` is `isCallToPrefix(V, "cq_phi_")` — the RETIRED family. Since
round-1 finding F-L6-1 that name is RESERVED and any module declaring it declines
*before analysis runs*, so **no module that reaches `diagonalAliasHit` can contain
one**. Its hop loop is therefore structurally unreachable at HEAD, and so is
`walkPhaseSpine`'s (same prefix test) and `SwitchArmProve`'s `Hit != P` branch.

That is Part I's finding F1 / OQ-9 confirmed by reading **and** by measurement.
Left in place per PRD P6 ("vacuous, not deleted"); **listed for the owner as
freeze-time dead code.**

### 13.4 HOLD/THETA-NO — 7 re-spelled, 3 retired (commit `f4960ad`)

* **G7 KEEPS ITS FIXTURE** (the brief's hard requirement).
  `control_swap_reject_switch_value_clobber.ll` is re-spelled with an ARITHMETIC
  scrutinee (`add i32 %p, 1`), which reaches the SAME function's ZERO-HOP arm
  (`Prov.count(V)`) and renders the same PERMANENT string.
  **MUTATION-VALIDATED BOTH WAYS:** with the clobber (also the `xor`/`mul`
  variants) exit 1 `arm rewrites a condition operand`; with the arms rewriting a
  DISJOINT register, exit 0 ACCEPTS — and the committed
  `control_swap_switch_value.ll` **is** that accepting twin, so the discriminator
  lives in the tree. Recorded third variant: a scrutinee that IS `%p` hits the C2
  mis-anchor (`value-arm swap-route`) first, so the *derived* scrutinee is
  load-bearing.
* **`phase-class value escaping` IS reachable** from the register-free surface — a
  kickback arm that also escapes the register it phased. Both fixtures
  discriminate: the same module minus the one `cq_phi` line declines on a
  DIFFERENT clause. ⚠ **Say this claim exactly**: fix_r1 recorded the F-L5-6
  fences BOTH as "pinned by: none reachable" AND as "no plain-C program reaches
  any of the three". These fixtures correct the FIRST only — they pin the fence in
  HAND IR. Plain-C reachability was not re-measured and must not be inferred.
* gate-5 **channel B** (the operand's WIRE is rotated elsewhere) is
  stem-independent → 2 re-spelled with `cq_theta`. ⚠ The condition had to move to
  its OWN register: the in-place swap makes the compare read a register a
  NON-DIAGONAL gate later rewrites, so `condition predates a non-diagonal gate`
  pre-empts gate 5. Rz was diagonal, Ry is not — the one substantive stem
  difference, and it lands here rather than in the property being pinned.
* the alias-REBASE evasion is about SSA ANCHORING, not diagonality → 2 re-spelled.
* **RETIRED 3**: `select_phase_operand` + `select_fp_phase_operand` (gate-5
  **channel A**, "the operand CARRIES a phase" — MEASURED: an operand that is
  merely a rotation OUTPUT now ACCEPTS, so channel A has no spelling at all) and
  `value_alias_cond` (pinned the `Hit != P` branch, which needs the dead hop; its
  surviving half is covered by 20+ diamond clobber fixtures).

### 13.5 undissolvable merge φ — the new `--keep-merge-phi` (commit `b3f2ea6`)

Part I refused these because the φ's incomings carry DIFFERENT registers.
**Dissolving was never the right move for this shape**: they are the MIXED-arm /
CROSS-HANDLE / DISTINCT-BASE decline fixtures, where the φ *is* a genuine data mux
and *is* the thing being refused. Under the register-free surface the phase arm
stops producing a value, so the only edit the site needs is the RAUW of the call's
result to its base — the φ survives with one incoming now naming the base.
**26/26 migrated · 26/26 `opt -passes=verify` clean · 26/26 still DECLINE.**

### 13.6 the last five (commit `7653786`)

* `control_angle_select_reject_runtime_arms_rz.ll` → **ACCEPT** (owner PRD §12 Q3).
  **The ground is not a relaxed tolerance: under kickback there IS no
  subtraction.** Each run-time arm's angle reaches its own `cqrt_rz_i1` verbatim
  under its own polarity bracket, so the whole 2b residual — the `fl(A−B)`
  rounding, the `inf`/`NaN` from finite arms, the `2^-40` fence — has no object.
  Kept as the STEM SEPARATOR (its Ry twin still declines, measured on the same
  binary) and pins `NOROUTE-NOT: fsub`. ⚠ It is **not** a red-green against the
  ORACLE: the oracle declines this module `tainted value consumed by an unknown
  callee`, not the old `rotation angle`.
* `lowering_reject_intrinsic_invoke_phi.ll` — hand-migrated (Part I's tool refuses
  the `invoke` form by design, defect #1's fix). Guard unchanged; only the
  reserved NAME moves.
* `control_tainted_diag.ll` — re-spelled with `cq_theta`, and its STATED GROUND
  corrected: it no longer fails "accept-criterion 3 (quantum base)"; drbq Inc 4's
  F1 fires first. Its assertion is the loose tail, so the assertion is unchanged.
* RETIRED `lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll` (Part I bug 7's
  semantic conclusion, confirmed: D1 leaves `fshl(%a,%a,5)`, already covered by
  `lowering_intrinsic_fshl_rotation_i32.ll`), plus the two §12.1 lost-subject files.

## 14. FLIPS — 12 fixtures that pinned a DECLINE and now ACCEPT

**They keep their `RUN: not` and stay RED, deliberately.** A flip toward accept is
a potential over-accept and belongs to a reviewer, not to a migration agent.
The remaining lit reds are **exactly** these 12 (`diff` of the two sets: identical).

| fixture | string it pinned |
|---|---|
| `control_angle_select_reject_loop_rail_exit_block_rz.ll` | control flow inside a loop body |
| `control_angle_select_reject_rounding_one_1e300.ll` | rotation angle |
| `control_swap_reject_diamond_derived_crosshandle.ll` | control flow |
| `control_swap_reject_eqfold_wrong_edge_eq.ll` | control flow |
| `control_swap_reject_eqfold_wrong_edge_ne.ll` | control flow |
| `control_swap_reject_fanout.ll` | impure phase arm |
| `control_swap_reject_ifelse_derived_mixed.ll` | control flow |
| `control_swap_reject_nested_multireg.ll` | nested control flow |
| `control_swap_reject_nested_twophi.ll` | control flow |
| `control_swap_reject_seq_ifelse_second.ll` | value-arm swap-route |
| `control_swap_reject_switch_datamux_angle_runtime.ll` | rotation angle |
| `control_swap_reject_switch_impure_phase.ll` | impure phase arm |

Two obvious groups to look at first: the `rounding`/`runtime` angle pair (2b's
`fl(A−B)` fence has no object under kickback — the same argument that made
`runtime_arms_rz` a legitimate accept, so these two may be legitimate too), and
the `eqfold_wrong_edge_{eq,ne}` pair (the const-fold re-anchor has no arg-0 to
re-anchor on the phase stem — the same root cause as their `_ifelse` sibling,
which §12.1 retired). **Neither is asserted here; both are for the reviewers.**

## 15. Fixture-integrity injection — and it FOUND A BLIND SPOT

`tools/migrate_phi_fixtures_inject.py`, over **all 104** re-derived accepts (the
brief asked for ≥40).

> ⚠ **The first version of the harness was worthless and scored 104/104 on
> everything.** It appended INSIDE the function body — in the middle of the
> derived `CHECK-NEXT` chain — so *any* extra line broke adjacency and every
> injection reported "caught". That measures the chain and says nothing about the
> NOROUTE negatives. The line now goes AFTER the last closing brace, past the
> chain, where only a whole-file negative can see it; and a **HARMLESS CONTROL**
> runs at the same site and must NOT be caught.

At the honest site, **4 of 104 were BLIND to an injected
`cqrt_rz_i32_controlled`** — the pre-Inc-1 TENSORED gate this increment exists to
remove. Cause: those 4 legitimately emit `cqrt_ry_i32_controlled` /
`cqrt_copy_i32_controlled`, so the generator had correctly measured the blanket
`_controlled` negative as inapplicable and DROPPED it — and that took the only
catch for a controlled Rz with it. The width complement cannot cover the gap
either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(`
has `_controlled` in between. Fixed by a NARROW twin,
`call void @cqrt_rz_{{[a-z0-9]+}}_controlled(`.

| injection | caught |
|---|---|
| CLEAN (no injection) — every prefix must pass | 104 / 104 |
| (a) `cqrt_cswap` | **104 / 104** |
| (b) `cqrt_rz_i32_controlled` | **104 / 104** (was 100/104 before the fix) |
| (c) surviving `call void @cq_phi` | **104 / 104** |
| (d) a DROPPED flag `cqrt_free` (a deletion, not an insertion) | **101 / 101** (3 n/a — no free emitted) |
| HARMLESS CONTROL — **must NOT be caught** | **0 / 104** |

## 16. The SUBJECT-vs-ORACLE kickback witness (§10 item 4, discharged)

Part I's `--verify-oracle` could not look at the emitted GATE STREAM for A/S/MIX,
because the oracle cannot lower `void @cq_phi(double)` at all.
`tools/migrate_phi_fixtures_kickback.py` closes that by comparing DIFFERENT INPUTS
on purpose — ORACLE on the PRE-migration module, SUBJECT on the POST-migration one
— after applying PRD §10.2 diff class (a) to the oracle's output
(`cqrt_rz_<W>_controlled(%f,%h,θ) → cqrt_rz_i1(%f,θ)`; uncontrolled
`cqrt_rz_<W>` deleted per D2), modulo SSA renumbering.

**83 MATCH · 21 MISMATCH, and every one of the 21 falls in a NAMED class — 0 in
"OTHER, inspect":**

| n | class |
|---:|---|
| 10 | **ROUTE → KICKBACK** — the oracle used `cqrt_cswap`; the P4 nest and P5 switch, whose routed emitter Inc 1b DELETED |
| 7 | **BY-DIFFERENCE → TWO VERBATIM GATES** — the 2b angle select; the subject performs no `fsub` and brackets with one `cqrt_x` pair |
| 4 | **class (a) + EXTRA `_unc`/`free` the ORACLE LEAKED** |

The last class deserves the second look: the class-(a) substitution *is* present
and the subject additionally discharges a rail the pre-3qlq binary left allocated
(e.g. `control_swap_cond_datause_measured` gains
`cq_template_zext_i1_to_i32_unc` + `cqrt_free` for the cast rail). A paired
`_unc`+`free` is the correct Rule-6 discharge, so this reads as an improvement —
but it is a capability difference PRD §10.2 does not list, and it is **recorded
here rather than blessed**.

## 17. Final corpus state

```
$ ls ir-pass/test/*.ll | wc -l                                          1655   (was 1661; 6 retired)
$ <live, non-comment references to @cq_phi_<sfx>>                          3
     lowering_legacy_phi_decl_prototype_family.ll
     lowering_reject_legacy_phi_register_form.ll
     lowering_reject_legacy_phi_register_form_eqfold.ll     <- the implementer's
     own reserved-name fixtures; these MUST keep the old spelling.
$ git diff --name-only 85ec83a..HEAD -- ir-pass/test | wc -l             241
```

**Part I's invariant "the `declare` count of `@cq_phi_*` must be 0" is reached**:
zero outside the three files whose whole purpose is to declare it and be refused.

### Retired (6 files, each with its reason above)

```
control_inplace_ry_reject_stateprep_rz_prep.ll        §12.1 + no arg-0 to state-prep
control_swap_reject_eqfold_wrong_edge_ifelse.ll       §12.1 + no arg-0 to re-anchor
control_swap_reject_select_fp_phase_operand.ll        gate-5 channel A has no spelling
control_swap_reject_select_phase_operand.ll           gate-5 channel A has no spelling
control_swap_reject_value_alias_cond.ll               the dead `Hit != P` branch
lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll   the POST-RAUW alias idiom
```

## 18. What is left after Part II

1. **The 12 FLIPS (§14)** — a reviewer decision, not a migration one. Each is still
   RED and still carries its `RUN: not`.
2. **The dead alias machinery (§13.3)** — `diagonalAliasHit`'s hop,
   `walkPhaseSpine`'s loop, `SwitchArmProve`'s `Hit != P` branch: owner
   dead-code candidates at the freeze.
3. **The 4 class-(iii) stream differences (§16)** — extra `_unc`/`free` the oracle
   leaked. Recorded, not blessed.
4. **e2e** is prep-b's, not this branch's.
