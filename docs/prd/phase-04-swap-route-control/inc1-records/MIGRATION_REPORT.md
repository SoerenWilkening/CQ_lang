# Inc-1 fixture migration report — register-free `cq_phi`

> bd epic `test_C_libtooling-3qlq`, Increment 1 preparation (agent `prep_a`).
> Branch `3qlq-inc1-migration`, base `dfb8e83`. Tool:
> `tools/migrate_phi_fixtures.py`.
>
> **Every number below is MEASURED, with the command that measured it.** The
> compiler used throughout is the **ORACLE** — the pre-3qlq build at commit
> `52d7764`, `$SP/wt/pre-3qlq/build/ir-pass/{cq-opt,libCQPass.so}`. The Inc-1
> binary does not exist yet; everything that needs it is marked
> `NEEDS-REDERIVE`. **No fixture file was deleted.**

---

## 1. What the migration is

`cq_phi` becomes `void cq_phi(double)` (PRD §4.1, decisions D1/D2). In the
corpus the old spelling is
`%r = call T @cq_phi_<sfx>(T %x, double THETA)`, and each CALL SITE takes one of
three treatments:

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
        976 @cq_phi_si32   80 @cq_phi_f64   12 @cq_phi_sll        3 suffixes of the 16
```

`python3 tools/migrate_phi_fixtures.py --report`:

| class | files | meaning |
|---|---:|---|
| U | 136 | every site UNCONTROLLED → deleted (D2) |
| A | 197 | every site IN A TAINTED ARM → `call void @cq_phi(double)`, merge phi dissolved |
| S | 13 | ANGLE SELECT (PRD §6.2 P2) |
| MIX | 26 | a mixture of the above inside one file (the rewrite is per-SITE) |
| H | 24 | HAND-DECISION: the angle operand is TAINTED and is not a `select`/`phi` |
| D | 94 | a dead `declare … @cq_phi_<sfx>` and no call |
| M | 50 | `cq_phi` appears only in prose / CHECK text |
| **total** | **540** | |

Call sites: **U 196 · A 336 · S 18 · H 24 = 574**, which equals the independent
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

Run `python3 tools/migrate_phi_fixtures.py --limits` for the authoritative list.
The load-bearing ones:

* **memory is not modelled** — a function that stores a tainted value is forced
  to class A (3 files, note `mem-taint`);
* **interprocedural** — a callee whose call site is under tainted control has all
  its sites classified A (4 files, note `callsite-ctl`);
* **taint and control dependence are ONE fixpoint**, because a region MERGE PHI
  is re-seeded by the pass as a fresh quantum register (§4, bug 4);
* a `cq_phi` whose ANGLE is tainted is never class U.

---

## 4. Five tool bugs, all found by MEASUREMENT — and four of them the same bug

This is the part of the report worth carrying forward. The tool was written,
read, and then checked against the oracle. **The reading found nothing; the
oracle found five defects, and four of them had the identical shape: a
CONTROL-CARRYING `cq_phi` read as UNCONTROLLED, i.e. a gate that D2 would have
DELETED.** Deleting a controlled phase gate is not a broken build — it is a
verify-clean silent miscompile of the fixture corpus, which is exactly the class
`CLAUDE.md`'s Prime Directive is about.

| # | defect | how it was caught | blast radius (measured) |
|---|---|---|---|
| 1 | **angle select read as uncontrolled.** `control_angle_select_rz_diamond.ll` has its `cq_phi` in a STRAIGHT-LINE block; the control lives in the ANGLE (`%ang = select i1 %c, double .9, double .3`). Class U ⇒ delete. | reading the fixture header while spot-checking the class-U list | introduced class S; **13 files + 18 sites** are class S today |
| 2 | **the immediate-post-dominator test was INVERTED.** It selected the candidate that post-dominates all others (the virtual EXIT) instead of the closest one, so the control-dependence walk never stopped at the merge and *every* block from a tainted branch to the function exit read as in-arm. | `opt -passes=verify` PARSE-FAIL on 16 migrated modules, traced back | direction was over-marking (A 204→178 after the fix), but it also mis-migrated a genuine merge-block gate: `control_inplace_ry_inloop_derived_cond.ll`'s loop-latch `%qn = cq_phi(%q,.1)` was class A |
| 3 | **phi dissolution picked an arm-local incoming.** `if/else` where both arms rotate, and loop-HEADER phis. | `opt -passes=verify`: `Instruction does not dominate all uses!` (9) and `use of undefined value` (7) | 16 broken modules → 0 after adding real forward dominators + resolving incomings through the `cq_phi` chain to a root |
| 4 | **a region MERGE PHI is re-seeded QUANTUM by the pass.** `%y = phi i32 [ %r, %arm ], [ 5, %entry ]` is classical by SSA data flow and is the merged quantum register `%out` after the 6.5 classical-call arm / 4.5 switch data mux lowering, so `icmp sgt %y, 7` is a TAINTED compare. | ORACLE diff: the deleted call lowers on the oracle to `cqrt_rz_i32_controlled(%h_cmp2, %out, .25)` | 3 files, one of which (`control_swap_reject_switch_datamux_angle.ll`) turned an ANGLE select into an fp DATA select — 2 × `cqrt_copy_f64_controlled` and 2 fresh f64 rails appeared in the migrated stream |
| 5 | **multi-line `switch` case lists lost every successor but the first.** 36 of the 540 files spell the case list over several lines; edges were read from the terminator LINE only. | the `unparsed_multiline` self-check, followed up rather than dismissed | **17 files** moved MIX → A. On `control_swap_switch_phase.ll` the blocks `a1`/`a2` had no incoming edge at all, so `%g1`/`%g2` — two `cq_phi` calls plainly inside switch arms — were class U and would have been deleted |

Bug 5 is worth a second look: the tool had *already printed* a warning
(`unparsed_multiline`, 36 files) and the first reading of it was "a `switch` case
list, benign". It was not benign. **A self-check that fires and is explained away
is a self-check that did not run.**

---

## 5. The oracle equivalence check

`--verify-oracle` runs the ORACLE on the file and on its in-memory migration and
compares. For **class U and D the oracle is a real equivalence oracle**: the
migrated module contains no `cq_phi` at all, so the pre-3qlq binary answers it
exactly as the Inc-1 binary will. Normalisation removes uncontrolled
`cqrt_rz_<W>` call lines, `declare void @cqrt_rz_*`, `declare … @cq_phi*`,
`ModuleID`/`source_filename` and blank lines — i.e. **exactly the difference the
migration is allowed to make**. For class A/S/MIX/H the migrated module contains
`call void @cq_phi(double)`, which the oracle cannot lower, so the check degrades
to well-formedness (`opt -passes=verify`).

```
$ CQ_OPT=$SP/wt/pre-3qlq/build/ir-pass/cq-opt \
  CQ_PASS=$SP/wt/pre-3qlq/build/ir-pass/libCQPass.so \
  LLVM_OPT=/usr/local/opt/llvm@19/bin/opt \
  python3 -u tools/migrate_phi_fixtures.py --verify-oracle \
      --classes U,A,S,MIX,D,H --write-hold tools/migrate_phi_fixtures.hold.txt
```

RESULT_PLACEHOLDER

**The brief's step-5 invariant — "fixtures whose oracle output on the migrated IR
differs from the original by MORE than deleted `cqrt_rz` lines must be 0 for
class U" — holds: EXTRA_DIFF_PLACEHOLDER.** Every class-U file that the oracle
ACCEPTS on both binaries produces output identical to the original minus exactly
the uncontrolled `cqrt_rz_<W>` lines.

What is NOT zero is the number of class-U fixtures whose **disposition** changes
— see §6. Those are not migration errors; they are fixtures whose decline was
*caused by* the gate D2 deletes.

---

## 6. HOLD list — fixtures the mechanical migration must not touch

`tools/migrate_phi_fixtures.hold.txt` is generated by the sweep above and read
back by every later run: a held file is HAND-DECISION and `--apply` skips it.
Entries fall in three groups.

HOLD_PLACEHOLDER

---

## 7. HAND-DECISION set (not migrated; **no file deleted**)

HAND_PLACEHOLDER

---

## 8. Findings that are not mine to decide

FINDINGS_PLACEHOLDER

---

## 9. What was applied, and the lit result

APPLY_PLACEHOLDER

---

## 10. What still needs the Inc-1 binary

NEEDS_PLACEHOLDER
