# The shielded-cone poison family — bd u1rp + bu96 + 94on (+ H1, + 3c6m.14.4, + 3c6m.14.6)

**Status:** SHIPPED, branch `3c6m.14-control-l6`, 2026-08-09.
**Scope:** `ir-pass/src/PredMuxFlatten.cpp` only. No frozen symbol, no YAML edit, no
new runtime template, no new gate sequence. NINE new lit fixtures, two new tools.
**Successor to** `3c6m.14.2-conedefined-decision.md`, which this session's work
assumes throughout.

**The S4 question, answered first because it changes the target.** bd 3c6m.14.2
deleted the shielded-cone pure-callee call admission (S4), reversing an ACCEPT
surface shipped and Rule-13-cleared one session earlier. That deletion **stands**,
and this session did not reopen it. Three independent legs, each re-checked on
disk rather than inherited: the purity proof reaches its verdict through
`isSpeculatableDataflow` (variable-amount shifts and `fptosi` admitted
unconditionally) and *skips terminators*, so `ret i32 poison` passes vacuously —
a category error no patch fixes; the measured population is empty, and the two
fixtures the ticket feared losing (`lowering_predmux_speccall_flatten.ll`,
`lowering_fp80_union_seed_purecall_i80cmp.ll`) are still present and ride S1/S3;
and direction (a) was actually built, and its own round found a fresh miscompile
inside it. So the cone still admits only the curated set minus the three
poison-immarg cells, and u1rp/94on keep their framing.

---

## 0. What shipped, in one table

| # | bd | change | direction |
|---|---|---|---|
| 1 | `u1rp` half 1 | `stripPoisonCone`'s walk NARROWED to exactly the set `coneDefinedAfterFlagDrop` visits-and-admits, via a shared `classifyConeNode` | fewer mutations |
| 2 | `u1rp` half 2 | the drop WIDENED to `dropPoisonGeneratingAnnotations()` — LLVM 19's third family, call return attributes | more complete drop |
| 3 | **H1 (new)** | **`cq_phi` is no longer a cone leaf at all** — its value IS operand 0, so the walk follows it (`ConeNode::PassThrough`); `cq_theta` stays a leaf; undef/poison in any rotation argument fails | **new decline — fixes a live silent miscompile** |
| 4 | `3c6m.14.4` | `isSpeculatablePureCalleeBodyImpl` gets a PER-QUERY memo + a call-count cost pin | no verdict change |
| 5 | `3c6m.14.6` | one new fixture pinning all 20 i80-compare predicate × operand-order cells | test only |
| 6 | `bu96` | **DECLINE TO FIX**, documented | no change |
| 7 | `94on`(a) | **DECLINE TO FIX — structurally unreachable**, measured | no change |

**This commit contains no accept-widening.** One two-line widening was written and
then reverted for that reason alone — see §9.

---

## 1. REACH, as numbers, before any result

Corpora rebuilt from scratch this session (the previous session's scratchpad was
gone). **Counted on disk, not by the loop that wrote them** — the prior census
lost 10 modules to basename collisions and reported the wrong number.

| population | files on disk | distinct names | carry `cq_theta` |
|---|---|---|---|
| `ir-pass/test/*.ll` fixtures | 957 pre-change / 966 after | 957 | 954 |
| e2e stage-1 modules | **257** | 257 | 237 |
| openlibm `-O1` modules | **251** | 251 | **0** |

Two counting traps worth keeping:

* the 18 `_lib.c` e2e TUs compile **only without** `-include CQ.h` (a deliberate
  C18 guard `#error`s otherwise), so a naive loop silently drops them — that is
  how "238" was reached before;
* openlibm `src/` and `ld80/` share **exactly 10 basenames** (`e_fmodl`,
  `e_hypotl`, `s_ceill`, `s_floorl`, `s_modfl`, `s_nextafterl`, `s_nexttoward`,
  `s_nexttowardf`, `s_remquol`, `s_truncl`). Writing `<dir>-<basename>.ll` fixes
  it. **0 of 251 openlibm TUs carry a taint source**, so that layer takes the
  pass's passthrough early-out on every module and has **NO FENCE POWER** — it is
  quoted below only as a shape census.

### Reach of the defect being fixed

`tools/predmux_cone_census.py` (committed, self-tested against a positive and a
negative control before use):

| population | poison-shielded select-forms | cones with a call | **forms where the strip's walk EXCEEDED the proof's** |
|---|---|---|---|
| 957 fixtures | 35 | 13 | **0** |
| 257 slice modules | 19 | 3 | **0** |
| 251 openlibm modules | **39** | 5 (9 curated callees) | **0** |

So **u1rp half 1 has zero measured population.** In all corpus hits the rotation's
operands are constants or bare arguments, so there is nothing below the leaf to
over-strip. It is a discipline fix, and the honest framing is that the *value* of
narrowing the walk is that it makes half 2 safe to ship — not that it repairs a
live corpus defect.

The 39 openlibm shielded select-forms **independently reproduce** the figure
recorded in `3c6m.14.2-conedefined-decision.md` §3 from a differently-composed
corpus (251 modules incl. `bsdsrc`/`amd64` vs 248), which is a genuine
cross-check of the methodology.

**Half 2's real-code witness — and the one I got wrong.** I first cited openlibm
`sqrt` (`src/e_sqrt.c`), whose shielded cone carries
`tail call range(i32 12, 33) i32 @llvm.ctlz.i32(%x, i1 true)`. The Rule-13 round
**refuted that citation**: the `i1 true` immarg makes `curatedIntrinsicCanBePoison`
refuse the cone at CLAIM time, so the region is never claimed and the strip never
runs. It is the only `call range(...)` shape in all 251 openlibm TUs, and a
different mechanism fences it.

The witness that does hold is real C rather than libm: stock `clang -O1` on
`q > 3 && q > __builtin_popcount(c)` with a two-merge-phi arm emits
`tail call range(i32 0, 33) i32 @llvm.ctpop.i32` inside a genuine shielded
diamond, and the pre-change plugin keeps the `range` while this one drops it
(verified by the round, 11 toffolis both). Since every `range` clang actually
emits is a TRUE range, half 2 is **defence in depth**, not a live repair — say it
that way.

### Probe family reach

`tools/predmux_probe_gen.py --run … --base BASE.so --new SHIP.so`:
**REACH 17/18** — a probe is ACCEPTED only if the pre-change plugin CLAIMS AND
FLATTENS it (`opt` exit 0, no residual `br i1`/`select i1`, ≥1 `cqrt_toffoli`).
The one NO-REACH is `H7_global_undef_init_control`, which is *deliberately* kept
in the family as an expected NO-REACH — see §9.

| probe | BASE | SHIP | intended |
|---|---|---|---|
| `U1_seed_nsw`, `U2_seed_chain_nsw` | flags stripped | **flags kept** | ✔ half 1 |
| `P1_incone_nsw`, `P2_incone_through_curated` | stripped | stripped, **byte-identical** | ✔ positive controls |
| `D1_retattr_callsite` | `range()` survives | **`range()` dropped** | ✔ half 2 |
| `D2`, `N1`, `N2` | — | byte-identical | ✔ controls / 94on is a no-op |
| `H1_phi_poison_depth1` | FLATTEN | **DECLINE** | ✔ the miscompile |
| `H2_phi_poison_chained` | FLATTEN | **DECLINE** | ✔ the evasion the round found |
| `H3_phi_hop_inherent_poison` | FLATTEN | **DECLINE** | ✔ no-flag-to-drop laundering |
| `H4_phi_hop_flags` | stripped | stripped, **byte-identical** | ✔ the draft's regression, undone |
| `H5_phi_defined_control` | FLATTEN | FLATTEN | ✔ PassThrough costs no accept |
| `H6_theta_poison_seed` | FLATTEN | DECLINE | ✔ safe over-decline, `cq_theta` |
| `B1/B2/B3` ConstantExpr | accept | accept, byte-identical | ✔ bu96 unchanged |

Exactly **7 probes moved** (3 IR, 4 verdict), all intended; the rest
byte-identical.

### Verdict diff, BASE vs SHIP — 1,473 modules

| corpus | scanned | IR-moved | verdict-moved |
|---|---|---|---|
| `ir-pass/test/*.ll` | 965 | 5 | 3 |
| e2e stage-1 modules | 257 | **0** | **0** |
| openlibm `-O1` modules | 251 | **0** | **0** |

**Every one of the 8 fixture diffs is one of this change's own new files.** No
pre-existing fixture, no slice and no openlibm module moved in either direction.

### Arm-kill, 8/8

Each arm deleted individually turns its designated fixture RED, and every row
also runs an UNRELATED witness fixture: if the witness goes red too, the row's
RED proves nothing (contention and global breakage look identical to a
discriminating failure). All eight rows: `got=RED witness=GREEN`.

| arm | fixture it must kill |
|---|---|
| A1 revert the walk to the old wide one | `…seed_flags_preserved` |
| A2 strip mutates nothing | `…incone_flags_stripped` |
| A3 revert half 2 to two families | `…retattr_dropped` |
| A4 delete the rotation-argument scan | `…rotation_theta_poison_seed` |
| A5 / A5b `cq_phi` back to a `Leaf` | `…rotation_hop_chained` / `…hop_inherent_poison` |
| A6 delete the memo | `…purecallee_memo_cost` |
| A7 every call is a `Leaf` | `…incone_flags_stripped` |

Two rows initially reported `.so HASH UNCHANGED` — cmake compares mtimes at
second granularity and silently skipped a rebuild landing in the same second as
the restore. `touch` is not enough; the driver now deletes the object file. **A
mutant that did not build is not a passing control**, and the hash assertion is
what caught it.

Two rows also began as MISMATCHES and both were MY errors, not defects:
* **A4** killed nothing, because `PassThrough` now catches the depth-1 poison on
  its own — the argument scan is redundant for `cq_phi` and is the ONLY
  protection for `cq_theta`. Fixed by adding
  `…rotation_theta_poison_seed.ll`, without which the scan would have been an
  accept-predicate no fixture pins (Rule 12).
* **A7** killed nothing, because the flagged op in `…incone_flags_stripped` was a
  DIRECT operand of the compare — making calls leaves never blocked reaching it.
  Fixed by adding a second flagged op genuinely BELOW the curated call.

---

## 2. H1 — the one live silent miscompile, found by this session's own round

Not in any ticket. Found by the correspondence lens while auditing the *safety
precondition* of the narrowing, then reproduced end to end by the orchestrator.

`coneDefinedAfterFlagDrop` stops at a `cq_theta`/`cq_phi` call and `continue`s
WITHOUT operand recursion. That leaf assumption covers the rotation's **result** —
and for `cq_phi` the result **is** operand 0, because `RotationLowering` RAUWs it
verbatim (`Phi->replaceAllUsesWith(Op)`). So a `poison` argument does not stay in
the argument slot: it becomes the leaf's value and flows into the predicate. The
`valueCarriesUndef` fence bd 3c6m.14.2 shipped for a DIRECT poison operand was
evaded by exactly **one hop through a rotation**.

On the pre-change plugin, with `%q2 = call i32 @cq_phi_si32(i32 poison, double
2.5e-01)` feeding the shielded compare: `opt` exit 0, `opt -verify` clean,
`free_pairing_check.py` **STRICT 6/6 verified, 0 violations**. Linked at the
shipped `-O0` stage 3 the trace read, **identically across runs**:

```
cq_template_icmp_slt_i32_hl(h0, 73896)      -> h4
cq_template_icmp_slt_i32_hl_unc(h4, h0, 1401299752)
cqrt_free(h4)
```

`poison` lowers to `IMPLICIT_DEF`, which LLVM may materialise **differently per
use**. The adjoint therefore inverts a different predicate than the forward
computed; rail `h4` is left dirty **and entangled with `h0`**; and the `cqrt_free`
on the next line is a hardware reset — a hidden measurement that collapses `q`.
Rules 6 and 8, verify-clean, every gate green.

Note this is **not** the ASLR artefact refuted in bd bu96: the two literals are
deterministic and reproduce identically across runs, and `73896` is the same
number the bd 3c6m.14.2 E2 exhibit produced.

### The first fix was wrong, and the Rule-13 round proved it in three spellings

The draft fence inspected the rotation's ARGUMENTS for `undef`/`poison`. That
fences depth 1 and nothing else, because at depth 2 operand 0 is an
*Instruction*, not an `undef` Constant:

```llvm
%r1 = call i32 @cq_phi_si32(i32 poison, double 2.500000e-01)   ; caught
%r2 = call i32 @cq_phi_si32(i32 %r1,    double 7.500000e-01)   ; NOT caught
```

The round exhibited that chained form end to end — same `73896` /
`1401299752` pairing break, `opt` exit 0, free-pairing STRICT 6/6 — and showed it
is **reachable from stock `clang -O1`** via an uninitialised local through two
chained phases. It then found two more spellings of the same root cause:

| spelling | pre-change | draft fence | shipped |
|---|---|---|---|
| `cq_phi(poison)` | FLATTEN (miscompile) | DECLINE | DECLINE |
| `cq_phi(cq_phi(poison))` | FLATTEN (miscompile) | **FLATTEN** | DECLINE |
| `shl i32 %c, %d` one hop above (inherent poison, no flag to drop) | FLATTEN | **FLATTEN** | DECLINE |
| same `shl` directly in the cone (control) | DECLINE | DECLINE | DECLINE |
| `add nsw nuw` one hop below | stripped | **flags KEPT** (my regression) | stripped |

The root cause in one sentence: **`cq_phi` is not a leaf, because
`RotationLowering` RAUWs its result to operand 0 verbatim.** `cq_theta` *is* a
leaf — its result is a fresh `cqrt_alloc_<W>` handle that does not depend on the
seed, so poison there reaches exactly one site and there is no pair to break.
Treating the two alike was the error. `ConeNode::PassThrough` follows operand 0
and closes all three rows at a measured cost of zero.

Note row 4: the draft's own narrowing had *stopped stripping* flags below the
hop, because it applied "a `Leaf` needs no drop" to `cq_phi`. So the draft
contained a regression that the same one-line misconception produced. That is
the third consecutive round on this file to find a fresh over-accept inside the
fix under review.

**Scope of the fix, stated so it is not later "generalised" wrongly.** The same
poison-rotation with a plain `and i1 %a, %b` instead of the shielded select still
lowers, and that is CORRECT: there the poison reaches the `br`, so the **source**
is already UB and nothing well-defined is broken. Only the shielded form is a
miscompile, because `select i1 %a, i1 %b, i1 false` yields `false` **cleanly**
when `%a` is false and the flatten's `and` destroys that. The fence therefore
lives in the cone proof, not in the lowering.

---

## 3. bu96 — DECLINE TO FIX, and the trap in the ticket's own prescription

**The ticket's proposed predicate does not work.** Measured with a standalone
LLVM 19.1.7 probe:

| constant | `canCreateUndefOrPoison` | `isGuaranteedNotToBeUndefOrPoison` |
|---|---|---|
| the bu96 witness `ptrtoint(gep inbounds OOB)` | **0 — MISSES IT** | 0 ✔ catches |
| a benign in-bounds `gep` constexpr | **1 — inverted** | 0 (over-declines) |

`canCreateUndefOrPoison` is a shallow query on the OUTERMOST operator — `ptrtoint`,
which cannot create poison — while the poison comes from the inner
`gep inbounds`. **Implementing bu96 as written ships a no-op that reads as a fix.**
Anyone reopening this must use `!isGuaranteedNotToBeUndefOrPoison(C)` scoped to
`isa<Constant>`.

**The decision, on the owner's stated criterion ("can a Constant produce a wrong
circuit at all?"): NO for a ConstantExpr — decline.** The answer turns out to be
*per-kind*, and the discriminator is the **pairing channel**, which also explains
why the shipped `valueCarriesUndef` check is load-bearing and why H1 is not the
same question:

| leaf kind | distinct literals across the 4 paired fwd/`_unc` sites, `-O0` | adjoint pairs? |
|---|---|---|
| poison-generating **ConstantExpr** | **1** (uniqued → one link-time relocation) | yes → no wrong circuit |
| provably-defined `ptrtoint (ptr @g)` control | 1 | yes |
| literal **`poison`** (the E2 / H1 kind) | **2** — `73896` vs `1401299752` | **NO → dirty rail → hidden measurement** |

So the refinement argument (LangRef permits any value) is *true of both* and is
**not** what makes E2 wrong; the pairing break is. That resolves the apparent
inconsistency of rejecting a contained `UndefValue` while accepting a
poison-generating ConstantExpr — they are different defects, not two views of one.

Supporting measurements: a ConstantExpr can only reach a `cq_template_*_hl`
**literal** slot or a `cqrt_alloc_<W>` init literal, never a rail **handle** slot
(handle slots are filled only from `taint.Tainted`, which holds `Instruction*`
only, or from a freshly emitted call).

Population: **zero ConstantExprs in any shielded cone**, on **two independently
written detectors**, each self-tested against known positives and negatives before
use — the committed `tools/predmux_cone_census.py` (93 shielded forms over 1465
modules) and the bu96 lens's own detector (78 forms over 1464). The two disagree
on how many *forms* they count, because they differ on how the `||` spelling
`select i1 %a, i1 true, i1 %b` is enumerated; **they agree exactly on the answer
that matters, 0.** Do not quote the form counts as interchangeable. Separately,
44/44 real-code poison-generating ConstantExprs are operands of a `load` or `gep`
— both of which `definedOpAfterFlagDrop` already refuses. **The hole is
unreachable by construction, not by luck.**

**RE-OPEN IF:** `definedOpAfterFlagDrop` is widened to admit `load` or
`getelementptr` (a plausible QROM / lookup-table widening — and note the correct
predicate over-declines a *benign* in-bounds gep constexpr, which is 37 of 40
real-code occurrences, so that widening and this fix must be decided together);
or stage 3 stops being `-O0` (bd `szpr`); or any emitter starts placing a
non-tainted `Value*` in a handle slot.

---

## 4. 94on(a) — DECLINE TO FIX, structurally unreachable, MEASURED

`dropPoisonGeneratingReturnAttributes()` writes CALL-SITE attributes only, while
`CallBase::getRetAttr` falls back to the callee DECLARATION (`InstrTypes.h:1680`,
read) — so a lying declaration-level `range` would be neither seen nor dropped.

It cannot arise on this surface. `classifyConeNode`'s call clause admits only
`isCuratedReversibleIntrinsic`, which requires a real `IntrinsicInst`
(`IntrinsicLowering.cpp:216`), and **LLVM 19 normalises intrinsic declarations at
parse time**. Verified with stock `opt -passes=verify` and NO plugin, over all
eight curated stems:

```
in:   declare range(i32 0, 33) i32 @llvm.ctpop.i32(i32)
out:  declare i32 @llvm.ctpop.i32(i32) #0
```

A non-intrinsic declaration keeps its `range`, which is the control that makes the
measurement meaningful. Real `clang -O1` likewise puts `range` on the CALL SITE
and nothing on the declaration.

**Why not add the guard anyway as defence in depth:** it would be dead code with
no reaching fixture, and **Rule 12 forbids shipping an accept-predicate without
one**. 94on(b) — parameter-level attributes on a qubit-handle argument — is a
Specialization question reproducible with no select-form at all, and stays filed.

---

## 5. 3c6m.14.4 — the memo, and why the ticket's prescription was wrong

The ticket said "memoise on the `Function*`", i.e. module-lifetime. **That is
UNSOUND, and it is measured, not argued.** `unrollConstTripLoops`
(`CQLoweringPass.cpp` ~200) runs BETWEEN the two `flattenPredMuxRegions` fixpoints
(~178, ~202) and removes CFG cycles, so a callee that failed the `scc_iterator`
check at the first fixpoint passes at the second. Reproduced with a
**one-character edit** to a shipped fixture — take
`lowering_predmux_leave_speccall_loop.ll` and make its data-dependent loop bound
`icmp slt i32 %i2, %a` a constant `, 4`:

| module | `opt` exit | DBG | clone minted |
|---|---|---|---|
| shipped fixture | 1 (loud decline) | `gate=E4-dataflow` | 0 |
| one-char edit | **0** | **same leave line still printed** | `__cq_q_purefn` ×2 |

Same `Function*`, two verdicts, one `opt` invocation. A module-lifetime memo would
serve the stale FALSE and silently kill the composition — and this is not a
contrived overlap: the unroller's tainted-callee cone seeds on the **same**
"direct call, visible callee, ≥1 tainted argument" predicate the E4 site requires,
so every callee the proof can be asked about is in the unroller's cone by
construction. `promoteFp80Union`'s own fixpoint is a second FALSE→TRUE generator
by design.

**What shipped is a PER-QUERY memo**, which needs no staleness argument at all:
`Impl` takes a `const Function *` and mutates nothing, so within one query the
module is provably fixed. It removes the whole blowup, because the exponential is
strictly **intra-query** — `OnStack` is erased on exit, so it is a cycle breaker,
never a visited set, and the invocation count is the number of distinct **paths**
through the call DAG.

### The cost pin

Asserted as a CALL COUNT, never a wall time (bd `xzdx` precedent). Closed forms
for a chain where every `f_i` calls `f_{i+1}` twice:

```
no memo     invocations = bodies = 2^(D+1) - 1
per-query   invocations = 2D + 1,  bodies = D + 1,  hits = D
```

`lowering_predmux_purecallee_memo_cost.ll` pins **two** depths — D=4 (9/5/4) and
D=12 (25/13/12) — because one point cannot distinguish `2D+1` from any other law
through it. The **divergence** between `invocations` and `bodies` is itself the
assertion that the memo is live.

**Deliberately NOT D=24**, against the audit's recommendation. D=24 is
33,554,431 invocations and ~43 s un-memoised, which is "unmistakably
pathological" — but a fixture whose FAILURE costs 43 s is a fixture people
disable, and it buys nothing the count assertion does not already give. At
D=4/D=12 the module runs in **0.37 s**, faster than the shipped
`lowering_predmux_speccall_flatten.ll` it is modelled on, and the red run costs
8191 invocations.

### Honest scoping — the DoS is only HALF closed

The ticket framed this as a DoS. **It is not fully resolved and must not be
claimed as such.** With the memo in place, a doubling call graph still costs
~100 s at D=24, while proof invocations sit at 49 and the Phase-6 clone count is
linear. Measured growth on SHIP: D=19 → 2.92 s, D=20 → 4.75 s, D=21 → 6.59 s,
D=22 → 11.69 s — still doubling per unit depth. It reproduces **even when the
region declines and the proof is never queried at all**, so it is neither the
pure-callee proof nor Phase-6 specialization. Filed as a separate follow-up.

### Consumer census, re-derived (the third attempt; the first two were wrong)

`grep -rnE "isSpeculatablePureCallee(Body(Impl)?)?\(" ir-pass/src ir-pass/include`

| unit | count |
|---|---|
| textual call **expressions** | **5** |
| … minus the self-recursion | 4 |
| … minus recursion and the two pure forwarders | **2** |
| distinct CONSUMERS making an accept decision | **2** |
| distinct CONTEXTS those consumers run in | **3** |

The in-source comment claiming "THREE textual call sites plus one recursion" is
not reproducible under any consistent unit and is corrected in the same commit —
in the very block that warns against inheriting the number.

---

## 6. 3c6m.14.6 — the i80 predicate sweep

Before: of 20 cells (10 predicates × 2 operand orders) exactly **2** were pinned by
a CHECK line — `eq` handle-left, and `ugt` arriving via the `ult` flip. `icmp eq
i80` appears 24 times in the tree, `ult` once, the other eight predicates **zero**.

The E4 accept clause is predicate-BLIND, and there is **no `_lh` compare row at any
width** (verified three ways: YAML, 0 such symbols among 2880 defined
`cq_template_*` in the archive, and `CompareLowering.cpp` setting `Shape::HL` on
both branches and applying `flipPredicate` instead). So one fixture with two
functions covers all 20 cells.

Each slot carries a **unique constant** (`LDBL_NBIT + slot`) — load-bearing: with a
shared constant an ordered CHECK can slide forward to a later line bearing the
wanted predicate, so a `flipPredicate` deletion would fail late or, for a cyclic
permutation, not at all.

**The SPLITS requirement was verified independently by the orchestrator**, not
taken on report: six mutations of the real lowered output all go RED (flip
deleted → RED at the first divergent slot; one forward predicate drift; fwd/`_unc`
predicate drift; a dropped `_unc` strip; an `_unc` naming the wrong rail; the mask
op changed) with the unmutated control GREEN. One mutation initially read GREEN
because the `sed` had not applied — **a mutation that does not change the file is
not a passing control**, and it was redone against the real operand names.

---

## 7. What this does NOT establish, and what is filed

* `stripPoisonCone`'s drop is **not invisible to the rest of the pass**. The old
  comment "flag/metadata-stripping only widens definedness, so every other user of
  a cone value is unaffected" was **falsified with a run**:
  `qromIndexKnownInBounds` reaches `computeKnownBits`, which consults `nuw`, and
  that reader runs at `declineTaintEscapes` — AFTER both PredMux fixpoints.
  Deleting `nuw` can turn a claimed QROM read into a loud decline. Direction is
  safe, PRE-EXISTING; narrowing the walk strictly reduces it but does not close
  it. **Filed.**
* `moveBody` drops poison flags over every arm instruction of every claimed
  region, unconditionally and bounded only by a SPECULATION proof rather than a
  definedness one. A far larger surface than `stripPoisonCone`; sound for a
  different reason (an arm value feeds the data **mux**, and `select` does not
  propagate poison from the unselected operand, whereas a cone value feeds the
  **predicate**, which does). The two sites must NOT be unified. **Filed.**
* The `xor` asymmetry: `isSupportedCondTree` admits `xor(X, true)` and proves a
  select-form's cone underneath it, but `canonicalizePred` does not descend
  through `xor` and never strips it — so the correspondence is
  `proof-roots ⊇ strip-roots`, not equality. Today that is a loud over-decline.
  **Nobody may "fix" the over-decline by making `canonicalizePred` descend through
  `xor` without adding the strip there.** **Filed.**
* A second, independent exponential in the pipeline on a doubling call graph
  (§5). **Filed.**
* `Fp80Union.cpp:836-840` reads `nsw`/`nuw`/`exact` as a poison-flag blocker and is
  ordered before every strip — but only by statement order, with nothing
  enforcing it. Not a live defect; recorded so a future reorder is not silent.

---

## 8. The Rule-13 round — verdict CLEARED, and what it cost

Six independent adversarial lenses plus a judge who reproduced every claim on the
pinned plugins before adjudicating it. **Verdict: CLEARED** — no silent
miscompile caused by this change; across 1,471 modules the change is byte-neutral
except its own fixtures.

What it changed in the shipped code, all of it before commit:

1. **`cq_phi` → `PassThrough`** (§2 above). The round's top recommendation; it
   closes three measured holes at zero cost. Without it the H1 fixture was, in
   the judge's words, "one hop from vacuous".
2. **`hits` is now COUNTED, not inferred.** `Invocations − BodiesWalked` also
   absorbed guard rejects and cycle returns, so a module with one `declare`d
   callee and no memo activity reported `hits=1`. `Invocations` also moved below
   the F-local guard.
3. **Six false or unverifiable claims in load-bearing comments, corrected** —
   including two I wrote this session. The openlibm `sqrt`/`ctlz` witness for
   half 2 **does not reach** (the `i1 true` immarg makes the cone fail at claim
   time, before the strip runs); the real-C `__builtin_popcount` witness does,
   and replaced it. The memo comment's "removes the entire blowup" and "43 s
   un-memoised" were wrong. The consumer-census grep could not match the new
   `…BodyWalk`.
4. **Fixture hygiene.** `retattr_dropped.ll`'s input declaration is now
   non-canonical so its normalisation CHECK observes something real;
   `incone_flags_stripped.ll` now says plainly that it is a CONTROL, green on
   both plugins by design, whose discriminating power comes from arm-kill and
   not from a differential; a pointless `--implicit-check-not='nonnull'` is gone.
5. **Two new decline fixtures and a seven-probe `H` family** in the committed
   generator, because a surface that has produced a fresh over-accept in three
   consecutive rounds does not get to ship with one decline fixture.

### Findings the round confirmed that this change does NOT fix

All PRE-EXISTING and BASE-identical, all filed:

* **`blockaddress` in an erased region block silently becomes `i32 1`** — and
  unlike everything else in this family the source program is **well-defined**,
  so no refinement argument excuses it. The most serious thing the round found.
* **The 4.4 select surface has the same pairing break with no branch and no UB
  anywhere** — same physics as H1, different owner (`SelectClassify` /
  `SelectMergeEmit`), not covered by a fence that lives in the cone proof.
* **`nofpclass` is a fourth poison-generating family** LLVM does not count in
  `hasPoisonGeneratingAnnotations()`, and `nofpclass` parameters falsify the
  "an `Argument` is a defined leaf" assumption. Stock
  `clang -O1 -ffinite-math-only` emits them.
* **The second exponential**, localised by the judge to `SpecializeReject.cpp`'s
  `scanBody`, which self-recurses with a fresh per-candidate `OnStack` popped on
  exit — byte-for-byte the shape fixed here.

---

## 9. The widening that was written and reverted

`constantCarriesUndef` recurses into a `GlobalValue`'s operands — which are its
**initializer** — while the value under test is the global's **address**, which
is defined no matter what it is initialised to. So a global with any `undef`
field, reached through a `ptrtoint`, reads as an undef leaf and the cone
declines.

The two-line fix (`if (isa<GlobalValue>(C)) return false;`) was written, and then
**reverted on measurement**: the pre-change plugin declines that shape too, so
the fix is an accept **widening**, and a widening does not belong in a commit
whose entire purpose is tightening. The round had attributed the over-decline to
this change; that attribution is **corrected** — its probe put the `ptrtoint` in
a rotation *seed*, a position only the new argument check reaches, whereas as a
*compare operand* it has always declined.

Direction is safe, population is zero, and the probe family keeps
`H7_global_undef_init_control` as a deliberate **expected NO-REACH** so the day it
starts reaching is visible. Filed with its own red-green pair owed.

---

## 10. Method notes worth carrying

* **The round's own history is the load-bearing fact for scoping the next one.**
  Three consecutive Rule-13 rounds on this file have found a fresh over-accept
  *inside the fix under review* — 3c6m.14.1 → 3c6m.14.2 → this one. Budget the
  adversarial round up front and do not treat a green suite plus a clean corpus
  diff as clearance; both were clean here while the chained-`cq_phi` hole was
  wide open.
* **Two tools are now committed** rather than rebuilt a fourth time:
  `tools/predmux_cone_census.py` (shape census over `.ll`, self-tested against a
  positive and a negative control) and `tools/predmux_probe_gen.py` (the
  reach-gated probe family, with the reach gate built into `--run` so a probe that
  does not reach cannot be reported as a pass).
* **A probe counts only if the PRE-CHANGE plugin accepts it.** Encoded in the
  tool, not left to discipline.
* **A mutation that does not change the file is not a control.** Assert that the
  edit applied before reading its verdict — this bit twice this session (once on a
  fixture mutation, once on a `.so` rebuild).
* **Contention makes wall-time measurements worthless.** Figures of 65 s and
  2.39 s taken while a review workflow was running re-measured to 0.5 s
  uncontended; the shipped baseline fixture is itself 0.5 s of plugin startup.
  Sequential BASE-vs-SHIP on the eight slowest fixtures: **1.20 s vs 1.18 s** — the
  change costs nothing.
* **FileCheck parses directives out of PROSE.** A comment line ending in the bare
  not-directive spelling fails the fixture with "found empty check string".
* **`opt` emits the FIRST `DS_Error` and exits**, so a decline fixture can assert
  exactly one diagnostic no matter how many functions it contains. A two-function
  decline "pair" cannot be written as one file.
* **A control that is green on both plugins is doing its job**, and saying so in
  the header is better than letting a reviewer discover it is absent from the
  differential and conclude it pins nothing.
