# FIX — Track F, ROUND-2 items (bd `test_C_libtooling-om35`), DOC + FIXTURE round

**Agent:** trackF-fix-r2. **Date:** 2026-09-14. **Worktree:** `/Users/sorenwilkening/Desktop/CQ_f2phi`,
branch `f2-phi-descendant`. **Input:** `REVIEW_F_R2.md` (CLEAR-WITH-ITEMS) + `review_r2_probes/`.

**NO PREDICATE CHANGED.** Source edits are COMMENTS ONLY; the binary is bit-identical to the reviewed
one (`96fdd3a9d2c1cd36deb607f0440db0157280a7784a7766bdce04044cd3234cd1`) after two full rebuilds in
which both `.o` files were genuinely recompiled. Every gate line any earlier round recorded against
`96fdd3a9` therefore remains a fact about the binary on disk and none was re-run for that reason.

## What landed

### 1. F-F2-1 — the L1 paragraph (FIX BEFORE MERGE). Landed, substantially as drafted.

The old paragraph said the set is *"a pure function of the module in front of this call, so recomputing
it in BOTH detection rounds is automatic and there is no premise for `repropagateControlMerges` to
falsify"*. I agree with the reviewer that this is **backwards**: recomputation over a graph a previous
round mutated IS the L1 PREDICATE species (bd `9pum`/`r9e5` F-B1R2-1; bd `b6ap` F-B6-1). I re-derived
the replacement rather than pasting it, and verified every file:line it cites by reading (see
`fix_r2_probes/MEASURED.txt`, "SOURCE CITATIONS VERIFIED BY READING").

**One correction to the drafted text, measured:** the (a) row is not *"a fresh `cqrt_alloc` result (no
operands)"* — `SwitchDataMuxEmit.cpp:142` mints `cqrt_alloc(Vd)` where `Vd` is a `ConstantInt` proved
by G6 (`:112`). The row is therefore spelled **"whose ONLY operand is a CONSTANT"**, which is what the
closure argument actually needs (a constant has no producer, so it is never `M`-reachable) and is true
of all three sites.

**Also landed, per the reviewer's suggestion and L1's own prescription** (record where the answer is
known, ask where it is needed): a pointer in `SwapRouteEmit.cpp` **beside** the M-β RAUW saying that
F2's conjunct depends on what this line targets, naming both tripwire fixtures and naming
`ArmClassify.cpp:823`'s `hasOneUse` as a second way to fire the same trigger. The coupling is now
visible from the side that can break it.

### 2. F-F2-2 — documentation only, as recommended (option (a)). Landed, and given a TRIPWIRE.

Retirement trigger (3) in `collectStatePrepPhiDescendants`' header is now split into **(3a) CYCLIC =
bd `wx8g`** (unchanged wording) and **(3b) ACYCLIC = bd `test_C_libtooling-hrts`** (filed this round),
with the measured `r20` mover named. The in-helper comment carries the same warning, and BOTH back-edge
fixture headers now say they pin the CYCLIC half only.

**Beyond the recommendation:** `r20` is committed as a fixture. The reviewer's option (a) was prose
alone, but `r20`'s STRING moves between the two binaries (`taint escape … classical-condition phi` ->
F2's), so a lit fixture CAN distinguish them — which means the acyclic half can have a tripwire, and
prose that nothing tests is exactly the L7 shape the finding is about. Its header states in terms
that cannot be misread that **the day option (b) lands, this file's string changes back and that is
the FIX ARRIVING, not a regression.**

Option (b) — test the MEMBER against the SLOTS — is **NOT taken**, per the brief and the reviewer.

### 3. Tripwires committed — SIX fixtures, not one.

| fixture | verdict | what it pins |
|---|---|---|
| `control_inplace_ry_reject_stateprep_mbeta_base_offcone.ll` (r7) | DECLINE F2 | the M-β RAUW-target invariant, diamond spelling. **Goes GREEN iff** an emitter retargets the merge-φ RAUW to a non-incoming-descendant, or `:823`'s `hasOneUse` is relaxed |
| `control_inplace_ry_reject_stateprep_mbeta_ifelse_rechain.ll` (r12) | DECLINE F2 | the same, for the **if/else `T2->setArgOperand(0,T1)` re-chain** at `:948` — the one M-β form that creates a genuinely new SSA edge |
| `control_inplace_ry_stateprep_mbeta_base_oncone_accept.ll` (r6) | **ACCEPT** | the ISOLATING CONTROL: one region moved onto `%MB`'s cone and it accepts, so the two declines above are attributable to CONE MEMBERSHIP and not to the skeleton (Rule 12(c) — a decline fixture whose subject cannot accept pins nothing). Its stream shows the M-β chain: two `cqrt_ry_i32_controlled` on ONE frozen rail `%h5` |
| `control_inplace_ry_stateprep_round2_phidesc_collider_accept.ll` (r5) | **ACCEPT** | that the conjunct is **REACHED IN ROUND 2 AT ALL** — the precondition without which F-F1-5 is a question about nothing |
| `control_inplace_ry_reject_stateprep_round2_nonphidesc_collider.ll` (r5c) | DECLINE F2 | its one-operand isolating control |
| `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll` (r20) | DECLINE F2 | the ACYCLIC half of the dominance skip (F-F2-2 / bd `hrts`) |

Every header carries an explicit L8 retirement trigger naming **what would make it go green** and what
to do then.

### 4. F-F2-3 — the duplicate-body count: RECORDED AS SETTLED.

Re-ran `dupscan.py` myself on this tree (1938 fixtures): **7 / 9 / 6 / 8** across the four
normalisations. All three numbers on record (implementer 7 and 9, round-1 reviewer 8) reconcile; the
axis is comment detection (`lstrip` vs column 0) crossed with blank-line handling, and `8` is what the
natural spelling `if line.startswith(';'): continue` gives, since it keeps INDENTED comment lines as
body. Counts are **unchanged from the reviewer's 1932-file run**, and a targeted check reports
**0 collisions involving the six new fixtures** under all four normalisations. No contradictory-verdict
group (L8's resurrection hazard) exists.

### 5. Two items from the review's §3 taken as well (they are prose in the same files)

* The sentence *"its users are never enqueued either, because whatever it carries forward is likewise
  slot-available"* stated a **non-theorem** (a user of a slot-available loop-header φ, in the loop body,
  need not be slot-available). Replaced with the direction argument, which does hold, and the old
  wording is named as the mistake so it is not re-derived.
* The `DT.dominates` null-node question is now answered IN THE SOURCE with the verified citation
  (`GenericDomTree.h:937-947` -> `:430-442`), beside the function that already warns about
  `LazyValueInfo` SIGSEGV-ing on an API precondition. I read those lines in the installed LLVM 19
  headers rather than trusting the review.

## A DEFECT I FOUND IN MY OWN WORK, and it is the reason a mutation matrix exists

The first injection-matrix run over the two new ACCEPT fixtures reported **24 mutations, MISSED 8**.
All eight were on `…_mbeta_base_oncone_accept.ll`: I had started its `CHECK-NEXT` chain at the round-2
prep, so every injection placed BEFORE the prep fell outside every prefix's window, and the file
carried only `RYCNT`/`FCNT`. A fixture that cannot be made to fail pins nothing (Rule 12(c)). Fixed by
starting the chain at the first `cqrt_alloc` and adding `ACNT` / `XCNT` / `MCNT` / `NEG` in their own
whole-file prefixes (Rule 12(a)). **Final: 24 mutations, MISSED 0, N/A 2**, both `n/a-shape`.

## Instrument fix (PROTOCOL S3)

`probes/injection_matrix.py`'s M9 and M10 were spelled for the i1 bool fixture and read **N/A** — i.e.
HOLE — on every i32 accept fixture. Made width-generic (new `mut_resub`), and M11 is now declared
`SHAPE_SPECIFIC` so it reports `n/a-shape` rather than sharing a label with a real harness hole.
Re-run on the ROUND-1 accept fixture to prove the generalisation did not weaken it: **12 / MISSED 0 /
N/A 0**, unchanged.

## What I did NOT run, deliberately

No corpus sweep (one per session, the merge gate's) · no full `ctest -j6` · no `^e2e-` · no
`cq-opt-equivalence-full` · no twin matrix · no e2e slice. Justification: **no predicate changed and
the binary is bit-identical**, so every layer below the fixture corpus is answering a question about a
binary that did not move. `ir-pass-lit` is the layer that can witness a fixture edit and it was run.

## Still owed at the merge gate (unchanged from REVIEW_F_R2.md §6)

1. **F-F1-3** — `p9_undef_seed.ll` plus the undef spelling of each Track-F customer, on the COMBINED
   (Track U + Track F) binary, answering in writing whether a normalized zero seed makes a
   φ-descendant collision reachable that was not before.
2. `cq-opt-equivalence-full` (a diagnostic-surface change landed earlier in this branch) and the full
   `ctest -j6` (Rule 19 moments 1 and 5 for the round-1 predicate change).
