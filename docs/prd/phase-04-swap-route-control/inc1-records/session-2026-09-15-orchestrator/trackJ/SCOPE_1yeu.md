# SCOPE — bd `test_C_libtooling-1yeu`: the cross-function instrument gap

**Scoping only. Nothing here was built this session, by instruction.** Binary for every
measurement: `cq-opt` `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`
(the session ORACLE, verified before use).

---

## 0. The ticket's premise, re-measured — and it is NARROWER THAN IT SAYS

bd `1yeu` states the gap structurally:

> *every corpus and gate in the tree is effectively **ONE FUNCTION PER MODULE**, so a
> cross-function defect is invisible to all of them — two over-ACCEPTs found 2026-09-14
> passed 1937 lit fixtures, 15 e2e entries, a COMPLETE corpus sweep, a 0-MISSED injection
> matrix and 328 twin cells, for that single reason.*

**That sentence is true of the moment it was written and is FALSE of `ir-pass/test` at HEAD.**
Measured over the 2038 `.ll` fixtures on this branch, counting functions that carry a
`@cq_theta_*` call (a *subject* function, not merely a `define`):

| taint-carrying functions in the module | fixtures |
|---|---|
| 0 | 6 |
| **1** | **1966** |
| 2 | 59 |
| 3 | 6 |
| 5 | 1 |
| 6 | 1 |

```
python3 - <<'EOF'   # run from the repo root
import re, glob, collections
c=collections.Counter()
for f in glob.glob('ir-pass/test/*.ll'):
    bodies=re.split(r'^define\s', open(f).read(), flags=re.M)[1:]
    c[sum(1 for b in bodies if '@cq_theta_' in b)]+=1
print(sorted(c.items()))
EOF
```

**67 fixtures already carry the axis**, and the names say who put them there: the `twofn`
family — `control_inplace_ry_inloop_twofn_mixed_clauses.ll`,
`control_inplace_ry_reject_inloop_iterlocal_twofn.ll` — plus
`trackX/probes/fp_x6_twofn_cross_function.c`. Those are Track W's and Track X's responses to
the very findings (F-W1-1 / F-W1-2) that `1yeu` was filed from. **So the first thing an
implementing increment must do is stop quoting the ticket's headline and re-measure:** the
question is no longer *"does any fixture have two functions"* — it is **"is the two-function
axis SYSTEMATIC, or is it 67 hand-placed fixtures around two known defects?"** It is the
second, and that is a different (smaller, cheaper) problem than the ticket describes.

⚠ The honest restatement, which is what an increment should be scoped against:

> **No GENERATOR in this tree varies the number of functions or the number of regions. Every
> multi-function fixture that exists was written by hand, after a defect of that class had
> already been found by review. The tree can therefore *re-catch* F-W1-1 and F-W1-2 and
> cannot *find the next one*.**

---

## 1. What is actually blind, layer by layer — measured, not assumed

| layer | axis today | blind to |
|---|---|---|
| `ir-pass/test` (2038 `.ll`) | 67 hand-written multi-subject fixtures, all post-hoc | a NEW cross-function defect; nothing generates the shape |
| e2e slices (409 `.c`, 368 lowering) | the `slice()` + `main()` pair is TWO functions but ONE kernel | a second *kernel*; and `main` is usually a bare `(void) slice();` |
| `e2e-loop-twin-matrix` (338 cells) | `cells_of_matrix()` is a closed axis product with **asserted** sub-grid sizes (120/36/118/14/50 = 338) — one kernel per cell | every cross-function and multi-region shape |
| injection matrices | mutate WITHIN one function | a mutation that must cross a function boundary to be caught (Track W's harness "moved a mutation across a function boundary" only on its second spelling, and lied in the MISSED direction before that) |
| corpus sweeps | inherit the fixtures | inherits the gap |
| `free_pairing_check.py` | **per function already** (`rail_defs` is deliberately per-function; `module_defs` is module-wide only for the `U1-cross-stream` refusal) | nothing of this class — it REFUSES a cross-function handle rather than vouching for one |

⚠ **`free_pairing_check.py` is the one layer that is NOT blind here, and it is worth saying
why**, because it is the model an increment should copy: it does not TRY to reason across
functions, it **refuses** (`U1-cross-stream`, `U3-extern-rail`, and `provably_not_a_rail`
declining to vouch for a formal parameter). A per-function analysis that refuses at the
boundary cannot leak state across it. The defects `1yeu` is about are analyses that *do not*
refuse — a `SmallPtrSet<const Loop*>` outliving the `LoopInfo` that owns its keys.

---

## 2. What it would COST

Four items, in the order an increment should take them. Estimates are stated as what they
are; only the measured line is measured.

**(a) A four-order fixture family — the cheapest thing that re-pins the known defects.**
Four `.ll` fixtures: `A establishes state; B is the subject` · the reversed order · `A writes
no state` · `A and B in the same module with no call edge between them`. Those four orders
are exactly what isolated F-W1-1. **Cost: four fixtures, no tooling.** MEASURED: adding
fixtures is nearly free — `ir-pass-lit` is spawn-bound and these reuse one `%cq-opt`
invocation each (~1.5 s per fixture in `lit --filter`, and the layer already runs 2038 of
them in ~35–55 s on a quiet box). **This is not the ticket, though**: it re-catches two known
defects. Hand-written fixtures around a found bug are what the tree already has 67 of.

**(b) A SECOND-FUNCTION AXIS in the twin-matrix generator — the one that would find the
next one.** `cells_of_matrix()` is a closed product with **asserted** sub-grid sizes, so an
axis is not a parameter, it is a new cell family with its own generator, its own expected-table
rows, its own quarantine boundary controls and its own mutant validation — the same
conclusion `MERGE_FILINGS.md` F-7 reached for four bespoke cells it therefore did NOT add.
A binary `second_function ∈ {absent, present}` axis **doubles** every sub-grid it is applied
to: 338 → up to 676 cells. The matrix is already the suite's long pole at **~180–400 s**
(it starts first and finishes last), so doubling it doubles the suite's critical path.
**Recommendation: apply the axis to ONE sub-grid, not the product** — the 50-cell `i1`
sub-grid that bd `uq96` added is the natural target, since its own history proves the point
(its first 40 `i1` cells could not see the iteration-local rail because every `B_ARM`
declared its second register *outside* the loop; it took a second pass of 10 more cells).
That is +50 cells, ~+15 % on the long pole, and it is the increment I would scope.

**(c) A second-REGION axis.** Distinct from (b) and cheaper: same function, two subject
regions. F-W1-2 ("a second region in the same module reaching a grant that carries no
record") is this axis, not the function axis. Several emitters record a fact at emission and
re-ask it after the round-2 fixpoint (`markBranchPhaseGate` — 6 call sites;
`markRailCondRead` — 6 call sites), and CLAUDE.md L1 already says in capitals that **"a
seventh emitter that forgets it re-opens the window with NO DIAGNOSTIC ANYWHERE"**. A
second-region axis is the only mechanical way to notice a forgotten call site.

**(d) A static audit, which costs an afternoon and is the highest value per hour.** The
reviewer's note says `SmallPtrSet<const Loop*>` is unique in the tree, *"but the question is
about the pattern, not the type"*. The pattern is **any analysis state whose lifetime
outlives the per-function scope that owns its keys**. That is a `grep`-shaped question over
`ir-pass/src/`: every container declared outside a `for (Function &F : M)` loop whose keys
are `Loop*`, `BasicBlock*`, `Value*` or `Instruction*`. It needs no corpus, no generator and
no suite time, and it would enumerate the population the fixtures are supposed to cover
instead of guessing at it. **Do this first.** A fixture family sized without it is sized
against one known instance.

---

## 3. What it would CATCH — and the part that is uncomfortable

**Catches:** an analysis that caches per-function-owned pointers module-wide (F-W1-1's
class); a record/re-ask pair whose recording site was forgotten by a later emitter
(F-W1-2's class, via (c)); an allocator-reuse aliasing bug, which is the nastiest member
because the second `LoopInfo` *reuses the freed allocation*, so the stale pointer COMPARES
EQUAL and the skip is silent.

**Does not catch, and an increment must say so in its own header:** a cross-*translation-unit*
defect. Every multi-function form scoped above is one module. The two `*_round2_window`
slices are the only two-TU subjects in the tree and both are unregistered records today.

⚠ **The asymmetry the ticket names is the reason to do any of this, and it deserves to be
quoted in the increment's PRD rather than paraphrased:**

> *contention and load cause false FAILURES, but a missing AXIS causes false CLEARANCES, and
> only the second kind is silent. Anything cleared by "the full suite is green" on a change
> that carries state ACROSS functions is unverified for this class.*

That sentence is the general form of this track's own brief (CLAUDE.md L10: an instrument's
failure mode is to report a pass). A missing axis is an instrument reporting a pass about a
question it never asked.

---

## 4. Recommendation, one line each

1. **(d) the static audit first** — it sizes everything else, costs no suite time, and is the
   only step that produces a POPULATION rather than an anecdote.
2. **(a) the four-order fixture family** — cheap, and it makes the two known defects
   regression-pinned rather than review-pinned.
3. **(c) the second-region axis** — the L1 "seventh emitter" hazard is live and named in
   CLAUDE.md, and nothing mechanical watches it.
4. **(b) the generator axis on ONE sub-grid** — the only step that can find the *next* defect,
   and the only one with a real suite-time cost. Scope it as its own increment with its own
   mutant validation, per `MERGE_FILINGS.md` F-7's precedent.

**Not recommended: doubling the whole twin matrix.** 338 → 676 on the suite's long pole buys
coverage of shapes (a) and (c) already cover, at the price of the gate people are most likely
to start skipping — and *a gate expected to be slow is a gate people stop running*, which is
CLAUDE.md L10 wearing the other shoe.
