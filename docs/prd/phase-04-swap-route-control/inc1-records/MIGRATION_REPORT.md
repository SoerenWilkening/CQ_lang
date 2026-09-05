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
