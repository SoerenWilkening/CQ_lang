# Staged edits for `CLAUDE.md` — session 2026-09-14 (the closing docs pass consumes this)

Each block below is authored by the track that measured it and is to be carried VERBATIM where marked.
Counts are NOT here — the closing agent re-measures them by command (Rule 19).

---

## 1. CORRECTNESS RISK §2 / §4 — F2's φ-DESCENDANT exclusion (bd `om35`, Track F). VERBATIM.

> **F2's φ-DESCENDANT exclusion (bd `om35`, owner-ruled 2026-09-14) — the ground is AVAILABILITY, and it is
> an OPERAND argument, not a position one.** F2 asks *"could the source the author wrote have been
> `cq_theta(<that register>, θ)`?"*, and that register can occupy exactly **two** slots of the module in
> front of the pass: the arm theta's arg-0, or the merge φ's PRED-edge incoming. The region's own merge φ
> `M` is defined **at the join**, so `M` is available at **neither** slot — and therefore **no value whose
> operand chain reaches `M` can be SPELLED at either slot, in any module**. Such a value is not a register
> the author could have named in the definition of `M` itself, so it is not a witness, and F2 stops counting
> it. It **removes a witness, not a decline**: any other pinned value that could occupy a slot is still
> found, on either edge, and still declines.
> ⚠ **Never compress this to "`V` sits after the join".** That sentence is about POSITION, it *is* the
> dominance conjunct that stays REFUSED IN WRITING, and it is **false** — `-O1` **sinks**, so the ≥11 shipped
> merge-block colliders (`range_forward_*`, `sideways_*`, `merge_edge_sideways`, `offwire_sideways_min`,
> `step_cap_over`) also sit after the join and are genuine rivals precisely because their position is a
> consequence of the fold, not evidence about the source. The operand form survives sinking because
> **sinking moves a definition and never rewrites its operands**; and a pre-region value cannot *acquire* a
> use of `M` in place at any `-O` level, because that is invalid SSA.
> ⚠ **The argument is a theorem only for an ACYCLIC user chain, and since 2026-09-14 that precondition is
> ENFORCED, not assumed.** A φ is the one opcode whose operand need only dominate its incoming EDGE, so a
> **loop-header φ taking an `M`-descendant on its BACK EDGE** both uses `M` and dominates both slots — the
> available collider the bullets say cannot exist (measured as a mover: ORACLE fires F2, the un-narrowed
> subject does not). `collectStatePrepPhiDescendants` therefore **skips a φ user that `M`'s block does not
> dominate**. That is a **NARROWING of the EXCLUSION set** — opposite object and opposite direction from the
> refused conjunct, which tests a *collider* against the *arm* and turns declines into accepts, where this
> tests a *member* against *`M` itself* and can only add declines. The invariant it buys is that every member
> lies in a block dominated by `M`'s block.
> ⚠ **RETIREMENT TRIGGER: bd `wx8g`, by name.** Every in-loop state prep is stopped before F2 today
> (`control flow inside a loop body`), and that open over-decline is the **only** reason the back-edge shape
> is unreachable rather than merely narrowed — in-loop regions **do** reach `classifyArms`, so the loop is
> not a blanket fence. The day `wx8g` lands, re-derive the narrowing against the shapes it admits, and do not
> assume the φ case is the only cyclic one. The fixture pair
> `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` is the tripwire.

⚠ **`wx8g` LANDS THIS SESSION (Track W).** So that retirement trigger fires immediately — the closing pass
must either record the re-derivation or record that it is owed, and the merge gate must measure the
composition. This is the second cross-track composition of the session (see `GATES.md`).

---

## 2. A standing lesson candidate — the INSTRUMENTS LIED, four times, all in the PASS direction

Every one measured this session, each by the agent that owned the instrument, and each invisible to a green
suite:

* a **vacuity checker** reported `checked 0` on a batch of 29 real negatives — a line that reads like a pass
  (Track W; the inherited script matches only handle-form negatives);
* an **injection matrix** printed `0 mutations, MISSED 0, N/A 0` when invoked with **no fixture argument**
  (Track F, found by hitting it deliberately; now exits non-zero);
* an **injection harness lied twice in the MISSED direction** before it told the truth — the first spelling
  took the entry-block alloc, the second moved a mutation **across a function boundary** (Track W; both
  bounds are now the enclosing `define`);
* an earlier matrix reported **45 MISSED against fixtures that catch everything**, because it ran
  `FileCheck --check-prefix` and dropped the RUN line's `--implicit-check-not` flags (Track U) — *"a harness
  that runs a weaker command than lit measures itself, not the fixtures."*

Plus two that destroy evidence rather than misreport it: **`--regenerate` silently ate 54 lines of Rule-13
ruling prose** from a baseline header and reported success (Track T, bd filed), and **a 0-byte `.ll` module
ACCEPTS** via the passthrough early-out, so six probes scored false ACCEPTs on nothing (Track F, bd memory
`empty-module-accepts-vacuity-trap`).

Proposed wording for L10's neighbourhood: *an instrument's failure mode is to report a PASS, so the only
instrument worth citing is one that has been made to fail on purpose.* Owner ruling not required; this is a
restatement of L10, not a new rule — but it belongs in the file, because six measured instances in one
session is not anecdote.

---

## 3. Counts — DO NOT COPY, re-measure

`ctest --test-dir build -N`, `ls ir-pass/test/*.ll | wc -l`, `ls tests/e2e/*.expected.log | wc -l`, and the
twin-matrix `grep -c` lines. Known to have MOVED this session: the twin matrix (was 259 + 29 = 288; Track T
took it to 299 + 29 = 328 and is adding ~10 more), the fixture count (several tracks), goldens, and ctest
entries. `docs/prd/.../trackL/SCOPE_L1a.md` §5's blind-spot row (`grep -c -i bool` == 2) is also stale.

---

## 4. CORRECTNESS RISK §4 — the bd `z9t1` DISCLOSURE (Track U). NORMATIVE COPY IS IN THE WORKTREE.

**Do not re-author this. The normative text is `IMPL_U.md` §2(b′)** on branch `undef-seed-zero`
(tip `4e7ef89f`), and the same text is carried at the mechanism in `RotationLowering.cpp`. Copy it verbatim.
`CLAUDE.md` §4 **requires** this paragraph for a widening of this class and it did not exist until round 3
asked for it.

Its headline, so the closing agent can recognise the right block: **136 modules that the ORACLE loudly
REFUSED now compile SILENTLY, and 116 of them move through one mechanism** — F1's second sub-clause is a
literal `Value*` comparison (`ArmClassify.cpp:3905-3908`) and `Constant::getNullValue` is **uniqued**, so
rewriting a seed `undef` and a straight-through `undef` to "the type's zero" makes them **the same
`Value*`**, for two operands the source never equated. The rival reading stated as a **program**: the seed
and the straight-through incoming were **two different uninitialized C objects** (minimal witness
`pD_two_objects`, moves D→A on that ground alone). Why the rival has no lowering to be robbed of, in two
halves: on the oracle the two-object module is a **loud decline**, so nothing is displaced; and the accept
is a **refinement**, since LangRef lets an `undef` stand for any value of its type, so `0` at each read was
already licensed and the stream is byte-identical to a written `= 0` — measured on all **164** modules of
the φ half's population, 0 divergences, 0 A→D. Why disclosure and not a predicate: after `-O1` the
one-object and two-object readings **are the same module** (`undef` is uniqued per type, so the IR carries
no record of how many C objects there were), and a warning was deliberately NOT added for the reason §4
already gives — it would fire on the owner's own ruled spelling.

Three retirement triggers travel with it, and each names what would make the paragraph **wrong** rather than
merely stale: (i) F1's second sub-clause stops being a `Value*` **identity** test; (ii) the clause rewrites
anything that is not `isa<UndefValue>`, **or** `undef` stops being uniqued per type — the refinement's only
two load-bearing facts; (iii) the 4 `cq_measure` rows are **NOT** covered by it — a ruled clause reached by
a new route, open with the owner.

⚠ **Two different 164s, equal by coincidence** — *"164 of 972 carried thetas"* is a count of THETAS from the
census; *"164 modules"* is the φ half's MODULE population from the isolation sweep. Different instruments,
different denominators. **Never cite one as evidence for the other.** The warning is carried at every site
either number appears; carry it into `CLAUDE.md` too if either number goes there.

⚠ **A LESSON THAT BELONGS IN THE FILE, not just the bead.** The false sentence — *"i.e. only where the
object was undefined on BOTH edges"* — was corrected in the RECORD in round 1 and **never landed in the
SOURCE**; round 2 found it again and specified the fix; **that fix did not land either**; round 3 found it a
third time and measured it *wronger than round 2 had* (the "i.e." describes a rule whose population is
about **four** modules; the shipped clause's is **164**). **A record correction that is not applied to the
source is not a correction.** This is L7 with a twist: the justification was not merely unruled, it was
*ruled wrong three times* and kept being read off the source comment that still carried it.
