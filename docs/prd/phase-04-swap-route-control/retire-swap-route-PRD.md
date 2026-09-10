# PRD — Retire the swap route: register-free `cq_phi` (branch phase by kickback) + value arms by controlled-copy merge

> **Status:** owner-scoped 2026-09-05 (seven decisions, §2, settled in
> one owner conversation and recorded here verbatim in substance). **Increments 0
> and 1 are IMPLEMENTED, Rule-13-reviewed, and are now
> LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the
> orchestrator: the squash of branch `3qlq-inc1-fix-c1`, whose tip is recorded in
> the landing commit message; `git log main -1` shows the hash) **after the
> re-clearance verdict `CLEAR-WITH-OWNER-QUESTIONS`** (record:
> `inc1-records/session-adc5590a/clearance2.md`). **Increment 2 (§7) is ALSO
> LANDED — on `main` 2026-09-06 as ONE squash commit** (the squash of branch
> `3qlq-inc2`, whose tip is recorded in the landing commit message; `git log main
> -1` shows the hash) **after the clearance verdict `CLEAR-WITH-OWNER-QUESTIONS`**
> (record: `inc1-records/session-adc5590a/inc2/clearance_inc2.md`). HISTORY, dated:
> it was written on branch `3qlq-inc2` against the pre-Inc-1 `main`, REBASED onto
> the landed `a3c1513` on 2026-09-06, and Rule-13 reviewed TWICE there — round 2
> CLEAR ON THE MECHANISM. **With both increments landed the SWAP ROUTE IS FULLY
> RETIRED: `cqrt_cswap` is minted by the 7.2 `AbortParkEmit` alone** (MEASURED —
> `emitRoute` has ONE call site, `AbortParkEmit.cpp:396`, and 1 of 319 goldens
> contains a `cqrt_cswap`). Round 2's one LEAK finding (F-I2-1) is PRE-EXISTING on
> `main` and is filed OUT of Inc 2 as bd `test_C_libtooling-7yd0` — see **E11** and
> **E12** below and `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §4/§5.
> **HISTORY (dated, kept — do not delete it).** The first clearance
> (2026-09-05, `inc1-records/session-0a61aa31/clearance.md`) returned **BLOCK** on
> finding C-1 (a mixed loop — invariant root register with D4's per-bit condition
> PLUS a second loop-carried register — leaked its `and` rails per activation where
> the hand-unrolled twin and the pre-3qlq oracle both discharge them), and Inc 0/1
> sat off `main` on branch `3qlq-inc1` until that was disposed of.
> **2026-09-06: C-1 was FIXED on branch `3qlq-inc1-fix-c1`** — `LoopLowering`'s
> `Collapsed` branch now ALSO collects the loop-invariant root mints beside the
> carried roots (a separate set unioned into `Roots` only on success, with a
> `CarriedRoots` skip so the collapse's own rail is not judged by clause (iii)), on
> clause (ii)'s UNCHANGED (I1) proof; witnessed by
> `e2e-phase-perbit-loop-mixed-twin-identical` (rolled == hand-unrolled, 37 = 37) and
> pinned by `control_phase_kickback_mixed_invariant_carried_inloop.ll`.
> **⚠ THAT FIX TOOK THREE ROUNDS ON BRANCH `3qlq-inc1-fix-c1`, ALL 2026-09-06:**
> round 1 = the CAPABILITY (the clearance BLOCK's fix, above); **round 2** = TWO MORE
> CONFIRMED MEMBERS of the same class in the fix's own neighbourhood (F-C1-1 /
> F-C1-2) — and it introduced a confirmed silent miscompile of its OWN; **round 3** =
> the NARROWING that closes that one and a second found while building its tripwire
> (F-C1B-1 / F-C1C-1 / F-C1B-2, notes §3.11), every change in the refuse direction.
> **The independent lens on round 3 graded it CLEAR-WITH-ITEMS** (two DOC findings,
> applied; one CONFIRMED miscompile it found is PRE-EXISTING on the pre-3qlq oracle
> and is filed OUT of this epic as bd `test_C_libtooling-eqpx` — F-C1C-B, notes
> §3.12). **The RE-CLEARANCE then ran on that tree (2026-09-06,
> `inc1-records/session-adc5590a/clearance2.md`) and returned
> `CLEAR-WITH-OWNER-QUESTIONS` — the BLOCK is CLOSED and Inc 0 + Inc 1 LANDED on
> `main` the same day. What the verdict leaves open is four owner questions and one
> record item, all of them DISCLOSED leak/over-decline classes that pre-date this
> branch (OQ-C2-1 `hasOneUse` — **ANSWERED by the FOURTH C-1 round, bd `7yd0`: the conjunct
> is RETIRED, and OQ-C2-1's own `m11d` is NOT bought back by retiring it; see E2 and notes
> §3.14** — OQ-C2-2 `short`, OQ-C2-3 the Q-R1-1 disclosure,
> OQ-C2-4 the over-decline list) — see E10 below.** ⚠ READ
> **§0 ERRATA FIRST** — the sections below are left as WRITTEN so design and
> implementation can be diffed, and where they disagree the errata block wins.
> Extends Phase 4
> (`ArmClassify` / `SwapRouteEmit` / `NestedRouteEmit` — since DELETED by Inc 1 —
> / `SwitchRouteEmit` /
> `SwitchValueEmit` / `AngleSelectEmit`), the 8h7d.5 rolled in-loop path and the
> drbq control-in-place epic. **A Rule-13 core change** in every increment.
> **Adds NO runtime symbol** (§5) — the emitted set SHRINKS. **Changes the
> frontend surface** (`CQ.h`: `cq_phi` loses its register argument and its 15-width
> family, §4). Implementing epic: bd `test_C_libtooling-3qlq` (children `.1`–`.3`
> = Inc 0–2, plus filed follow-ons).

## 0. ERRATA — what implementation and review measured differently (2026-09-05; E10 added 2026-09-06 at the landing, E11 the same day by the Inc-2 Rule-13 round 2)

> **This block is dated and additive. The sections below are left as WRITTEN, so
> that what was designed and what was built can be diffed; where they disagree,
> THIS BLOCK WINS.** Reproducers and full arguments:
> `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1 (adversarial round 1, eight lenses), §2
> (round 2, two lenses + the "what else runs once before round 2" stage table) and
> §3 (the clearance, the three C-1 fix rounds and their lenses — E10).
>
> **Shipping status.** Increment 0 (docs + `cq_ry`) and **Increment 1** (the
> register-free `cq_phi` by kickback, parts A and B) are **LANDED on `main`
> 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of
> branch `3qlq-inc1-fix-c1`, whose tip is recorded in the landing commit message;
> `git log main -1` shows the hash) **after the re-clearance verdict
> `CLEAR-WITH-OWNER-QUESTIONS`** (record:
> `inc1-records/session-adc5590a/clearance2.md`). HISTORY, dated: they were
> implemented on branch `3qlq-inc1` and held OFF `main` from 2026-09-05 by the first
> clearance's BLOCK on C-1 (see the Status header); C-1 was FIXED on
> `3qlq-inc1-fix-c1` over THREE rounds on 2026-09-06 — capability, then two more
> members plus a miscompile of round 2's own, then the narrowing — the round-3 lens
> graded CLEAR-WITH-ITEMS, and the re-clearance on that tree cleared it (E10).
> **Increment 2 (value arms by controlled-copy merge, §7) IS LANDED TOO** — on
> `main` 2026-09-06 as its own ONE squash commit (the squash of branch
> `3qlq-inc2`, whose tip is recorded in the landing commit message; `git log main
> -1` shows the hash) after the clearance verdict **`CLEAR-WITH-OWNER-QUESTIONS`**
> (record: `inc1-records/session-adc5590a/inc2/clearance_inc2.md`). **So §7 is no
> longer a plan on `main`, and `cqrt_cswap` has exactly ONE minter there: the 7.2
> `AbortParkEmit`.** The epic's cswap goal is MET. Full landing summary: **E12**.
> ⚠ **HISTORY, dated 2026-09-06 — kept because the branch names are still quoted.**
> Until that day this block said Increment 2 was NOT landed and that a reader on
> branch `3qlq-inc2` was reading a file whose `main`-facing sentence was false
> there. The branch was written against the pre-Inc-1 `main` and REBASED onto the
> landed a3c1513 (`git rebase a3c1513`, 15 commits, 2 conflicts of 7 overlapping
> files — `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §3); Rule-13 round 2 then ran there
> (notes §4): ten findings, CLEAR on Inc 2's own mechanism, one LEAK that is
> PRE-EXISTING on `main` (**E11** / bd `test_C_libtooling-7yd0`) plus one
> fixture-truth repair and three record items. The clearance (notes §5) then
> cleared it and it landed.

**E1 — §3's and §7.1's "`t`, `f` freed clean" is FALSE for `t`** (Inc-2 lens
F-V1-4). In the value-arm controlled-copy merge the chain-final rail `t = R(p)` is
**not** `_unc`-reversed and **not** freed: it is left ALLOCATED and ENTANGLED with
`out`. That is physically sound while `p` is retained — nothing is freed dirty, so
Rule 6 holds — but it is not what the sentence says, and the difference matters to
anyone reasoning about ancilla cost or about a later `cq_invert`. Read §3's value-arm
paragraph and §7.1 as "`f` freed clean; `t` left allocated". A consequence worth
carrying: bd `3qlq.5` (freeing the value-arm SOURCE) is **unsound by default** under
this leak class.

> **E1a — the errata's own "`5 _unc` — the interior links" is not the count of
> anything in the trace either** (clearance record item **R-1**, 2026-09-06,
> `inc1-records/session-adc5590a/inc2/clearance_inc2.md` §3). Read the shipped
> golden instead of any number in this file:
> `tests/e2e/slice_control_value_diamond.expected.log` discharges the chain's
> INTERIOR rail `h2` with **ONE** `cq_template_mul_i32_hl_unc(h2, h1, 5)` plus
> **TWO IN-PLACE ADJOINTS** (`cqrt_xorc_i32(h2, 9)`, `cqrt_addc_i32(h2, -15)` —
> the M-C in-place links reversed on the rail itself, which is why they are not
> `_unc` calls) and **ONE** `cqrt_free(h2)`; the chain's FINAL rail `h3` (links 4–6:
> `mul_i32_hl → h3`, `addc(h3, 7)`, `xorc(h3, 2)`) is **left allocated and dirty**.
> So the emitted stream has 1 `_unc` for the chain, not 5 and not 6 — and the
> number 5 came from counting design "links", a unit the lowering does not emit
> one-for-one once M-C converts a link in place. **Do not re-derive a count from
> this PRD; count it in the golden.** The same correction applies to
> `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1.4 and to §7.1's inline errata below.

> **E1b — the SOUNDNESS SENTENCE was over-stated, and the true one is narrower**
> (clearance record item **R-2**, 2026-09-06, same record §3). Three sites said, of
> the retained chain-final rail: *"`R(p)` is a deterministic function of the
> RETAINED `p`, so tracing it out leaves the reduced state on (q, p, out)
> unchanged."* **That is FALSE as a density-matrix statement.** Writing `R(p)` into
> a fresh `|0⟩` ancilla and then tracing the ancilla out DOES change the state: the
> off-diagonals between `p` and `p′` with `R(p) ≠ R(p′)` are **dephased**. A reader
> who tests the sentence as written will find it wrong.
>
> **What is true, and what the increment actually rests on:**
> **(a)** relative to the SOURCE PROGRAM's live registers — `(q, out)` — the reduced
> state equals the ROUTE's, because the retained `p_old` already determines
> `R(p_old)`, so the ancilla records nothing the surviving registers do not already
> record; and
> **(b)** on `(q, p_old, out)` **no CQ-expressible continuation can observe the
> difference**, because `out`'s own retained label already records `R(p_old)` on the
> arm branch and `p_old` on the other, and the ABI mints **no in-place Q+Q gate on
> `out`** that could erase it (`cqrt_copy_<W>_controlled` is minted only with a
> FRESH `|0⟩` destination).
>
> Clause (b) is a statement about the shipped ABI, not a law of physics, and it is
> **exactly why bd `3qlq.5` is unsound by default**: 3qlq.5 is the continuation that
> WOULD erase it, so it must discharge the finals (and each switch delta `d_i`)
> before it frees the source. State it this way — never as "tracing it out leaves
> the reduced state unchanged".
>
> ⚠ **The sentence appears at FOUR sites, and this pass corrected THREE.** Fixed:
> `ir-pass/src/SwapRouteEmit.cpp` step 5 (comment text only — no code, no rebuild
> needed), `tests/e2e/slice_control_value_diamond.c`'s header (comment only; the
> golden does not change), and `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1.4. **STILL
> CARRYING THE FALSE SENTENCE: `ir-pass/src/SwitchValueEmit.cpp:55`** — a FOURTH
> site the clearance's R-2 did not enumerate, found while applying it, and left
> untouched only because this docs pass was scoped to two named comment edits. It
> is a one-line comment repair with no behaviour, and it is the
> `fixture-repairs-propagate-to-every-family` lesson: a correction is not applied
> until every family that carries the sentence has it.

**E11 — Inc 2's value-arm merge is a FOURTH producer of the rail shape that leaks
under a rolled per-bit kickback loop; the DEFECT is pre-existing on the landed
`main` and the FIX is not on this branch** (2026-09-06, Inc-2 Rule-13 round-2
finding F-I2-1 → bd `test_C_libtooling-7yd0`). *Placed here, out of numeric order,
because it continues E1's subject: the value-arm merge out-rail.*

The shape is **a control-owned merge whose `%out` holds a NON-constant value, then
a classical op that M-C converts IN PLACE on that out-rail, then a ROLLED in-loop
kickback region reading it.** The rolled loop mints one per-bit template rail per
trip and discharges NONE; the hand-unrolled twin discharges all K. Each leaked rail
is an entangled which-path record of one bit of the merged register, and the idiom
is the one **D4** designates for a register-wide Z. Nothing in the tree sees it:
`opt` exits 0, the module verifies, and STRICT stage 2b is **structurally blind** (a
template-minted rail has no `cqrt_alloc` to count) and reports `0 violation(s)`; the
full `ctest -j6` on the rebased tree was 361/361 green.

MEASURED: the 13-line headline reproducer contains **no Inc-2 feature at all** (a
4.4 select merge, `m = m + 7`, then D4's per-bit loop) and behaves **identically on
`main` a3c1513 and on this branch** — rolled 44 trace lines / 4 mints / **0**
`_unc`, unrolled 52 / 4 / **4**; at K=32 it is 240/32/**0** against 301/31/31, i.e.
**O(K)**. Inc 2's own value-arm merge reproduces it (52 vs 60 here, 57 vs 65 on
`main`), which is exactly what "adds a fourth producer" means: **more customers, no
new defect.** The 4.4 select merge and Inc 2's value merge are MEASURED members; the
6.5 classical-call arm is analytic; the 4.5 data-mux is measured OUT (its
all-`ConstantInt` arms let `-O1` fold any preheader op into the case constants).

Root cause (analytic from source): `LoopLowering.cpp`'s `commitOutOfLoopInPlaceOps`
refuses at `!P->hasOneUse()`, and a merge out-rail structurally cannot have one use
— the emitters write it with two `cqrt_copy_<W>_controlled` before anything reads
it. **It is the 8h7d.5 lesson in the file that documents it:** C-1 round 2 widened
the ROOT set (clause (ii-b)) and did not re-ask the question computed over the same
closure.

**WHERE THE FIX LIVES: not here.** It touches `LoopLowering.cpp`, Rule-13 core on
landed `main`, and was scheduled as a separate **C-1 round 4 on `main` AFTER Inc 2
lands** (bd `test_C_libtooling-7yd0`) — which is what happened: round 4 shipped on
branch `c1-round4` off a3c1513, was REBASED onto 258d974 on 2026-09-06, and **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash).
On the rebased binary this leak's Inc-2 spelling is GONE: `q4b_preadd` rolled ==
unrolled byte-identically at 60 lines, against 4/0 at 52 on `main` 258d974. This branch deliberately adds **no fixture
that pins the leak as an accept** — that would bless it; the round-4 fix pins the
discharge. The 18 reproducers and the full discrimination table are committed at
`inc1-records/`'s sibling `inc2-records/README.md`. Note the overlap with **OQ-C2-1**
(E10 item 5), which names the same `hasOneUse` conjunct from the other side.

**E12 — the Increment-2 LANDING (2026-09-06), in one block.** *Placed here, out of
numeric order, because it closes E1's and E11's subject.*

**Inc 2 (bd `test_C_libtooling-3qlq.3`, value arms by the controlled-copy merge)
LANDED on `main` 2026-09-06 as ONE squash commit** — the squash of branch
`3qlq-inc2`, whose tip is recorded in the landing commit message (`git log main -1`
shows the hash) — **after the independent Rule-13 clearance returned
`CLEAR-WITH-OWNER-QUESTIONS`** (record:
`inc1-records/session-adc5590a/inc2/clearance_inc2.md`; the clearance was READ-ONLY
on every checkout and its subject binary was byte-identical by `cmp` to the round-2
baseline, so every round-2 measurement transferred).

*What landed, measured, not asserted:*

* **The swap route is FULLY RETIRED.** `emitRoute` has the definition, the
  declaration and **ONE call site — `AbortParkEmit.cpp:396`** (`grep -rn
  'emitRoute(' ir-pass/src ir-pass/include`); **1 of 319 goldens** contains a
  `cqrt_cswap` (`slice_control_abort`, the 7.2 abort park); the whole-corpus census
  over 1687 fixtures finds `@cqrt_cswap` in 6 outputs — 5 abort-park and one whose
  cswaps are hand-written INPUT.
* **The witness is BYTE IDENTITY with the manually pre-hoisted `select` twin**, on
  **four** `cmp` gates —
  `e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`. That comparison is
  load-bearing precisely because the twin spelling already lowered through the
  Rule-13-cleared 4.4 `SelectMergeEmit` on the PRE-Inc-2 binary, so it compares the
  new stream against the OLD COMPILER's, not against itself. The clearance
  independently reproduced 10 further diamond/twin pairs byte-identical on the
  subject, with every twin byte-identical across all three binaries.
* **Scope of the diff:** 8 source files (all `ir-pass/`), 22 fixtures (14 A / 8 M),
  goldens 2 M + 9 A; **`tools/`, `runtime/` and `include/` UNTOUCHED** — owner
  decision **D3** honoured, no new ABI symbol. Counts after: ctest **361** (`^e2e-`
  351, `^e2e-slice-` 317), lit **1687**, goldens **319**. Full run at the landing:
  **361/361 passed**.
* **`0 RCDIFF · 0 DIAGDIFF · 8 OUTDIFF`** over the 1673 fixtures common to `main`
  (the 8 are 7 Inc-2 re-derived accepts + `lowering_switch_value_nonI32_cast`);
  injection matrix 17 accepts × 7 mutations with **0 NOT CAUGHT**; STRICT stage 2b
  rc=0 on every accepting lowering, and a free audit over 71 subject traces found
  232 frees, **every one preceded by a `*_unc` of that rail on an Inc-2 path**, and
  **0** frees of a chain final, a source `p`, a delta or a merge out-rail.
* **The OQ-22 widening is KEPT and PINNED, deliberately** (round-1 finding F-V1-1,
  owner question): an unreviewed accept-class widening at every width, retained
  with fixtures rather than narrowed away — it fires equally through the if/else
  merge and through a cast off an i8 if-merge feeding a SECOND value arm. It is on
  the owner's desk, not closed by the landing.
* **bd `3qlq.5` (free the value-arm SOURCE) is UNSOUND BY DEFAULT** under this
  stream and the landing does not change that — see **E1**/**E1b**. It must
  discharge the chain finals (and each switch delta `d_i`) before it frees `p`.
* **bd `test_C_libtooling-7yd0` (C-1 round 4)** — the PRE-EXISTING in-loop leak of
  **E11**, of which Inc 2's merge is a FOURTH producer — was **in flight on branch
  `c1-round4`** at the time of THIS landing (a one-line `LoopLowering` change: the
  `hasOneUse` conjunct retired under the round-3 tripwire) and is **NOW LANDED
  TOO**: the branch was REBASED onto 258d974 on 2026-09-06 (five docs-only
  conflicts, of which two needed hand resolution — both CLAUDE.md count
  paragraphs; `LoopLowering.cpp`, `tools/loop_twin_matrix.*` and the notes did not
  conflict) and **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash). It is
  not Inc 2's defect and was never Inc 2's to fix on its own branch. ⭐ **The rebase
  MEASURED the row round 4 could only argue** — `q4b_preadd` on the Inc-2 value-arm
  merge: `main` 258d974 rolled **4/0, 52 lines** vs its twin 4/4, 60 (`cmp` DIVERGE
  8), rebased **4/4 = 4/4, byte-identical at 60**, pinned by
  `control_phase_kickback_mixed_value_merge_preadd_inloop.ll` and
  `e2e-phase-perbit-loop-value-merge-preadd-twin-identical`.
* **What the clearance left open** is two new owner questions, both PRE-EXISTING
  and both measured identical on all three binaries (oracle 52d7764, `main`
  a3c1513, subject): **OQ-C3-1** — a value DIAMOND followed by a rotation on its
  result declines `cq opcode lowering: operand predates a non-diagonal gate` while
  the pre-hoisted `select` twin accepts, i.e. "value arm, then diffuse" is not
  writable as a diamond today; and **OQ-C3-2** — `int p = q * 3; if (q>5) R6(p);`
  declines `non-routable value multiplexer` because instcombine reassociates the
  derivation into the chain head. Both are folded into bd
  `test_C_libtooling-3qlq.14` (the base-from-cond asymmetry), together with the
  standing OQ-11/12/13/22/23. Record items **R-1**/**R-2** are applied as **E1a**
  and **E1b** above.

**E13 — bd `test_C_libtooling-eqpx` (P1) is FIXED (2026-09-06).** The PRE-EXISTING
in-place-immediate miscompile through the LOOP writers — a quantum rail handle emitted
into the `cqrt_{addc,xorc}_<W>` ABI's CLASSICAL-IMMEDIATE slot, `opt` exit 0,
verify-clean, STRICT stage-2b `0 violation(s)`, and byte-identical on the pre-3qlq
oracle 52d7764 — is closed by a DECLINE-ONLY consumer tripwire: `lowerOps` Phase 1
re-asks **G2 ALONE** (`inPlaceValueRailOperand`, under FINAL taint) for every
`taint.InPlaceRailOps` member NOT in `PreLoopCommittedInPlaceOps`, and declines loudly
with `cq loop lowering: in-place rail op no longer provable at lowering`.
**FOUR writers, not three** — the record enumerated a site that is not separate
(`tryCaseA`'s ACCEPT == "round 1's `railRoot` marking") and omitted one that is
(`emitBreakForward`, the 7.4 break path, a measured member) — and **TWO** taint-growth
events, not one (`lowerControlRegions` taints the BARE `%out`, one stage before
`repropagateControlMerges` taints its derivations). The **`add` stem** was reachable
all along and correct only by `-O1`'s exit-value rewrite. 16 lit fixtures (8 decline,
8 accept control), **0 new goldens and 0 golden churn**, `0 RCDIFF · 0 DIAGDIFF ·
0 OUTDIFF` over the 1691 pre-existing fixtures, and no new frozen symbol (D3). Full
record: `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.16**.
⚠ **THE ROUND-1 ADVERSARIAL LENS (2026-09-06, `CLEAR-WITH-ITEMS`) FOUND 15 MORE MEASURED
MEMBERS** of the class — casts (`(short)`/`(long long)`/`(unsigned char)`), a curated
`llvm.bswap` intrinsic, a classical `phi` of two derived immediates, a 4-hop derived
chain, `%out` mixed with an Argument, two rail ops on one immediate, a break loop whose
immediate is also in the break condition — every one accepting on `main` with a rail in
the immediate slot and declining on the fix, against **0 over-declines over 20
purpose-built boundary programs** and `strictimm.py`'s **0 rail producers over all 841
`fix` accepts**. Two of the fifteen change the class's own description: **at i8/i16 the
defect was never verify-clean at all** — `cqrt_xorc_i8(i32 %h2, i32 %h_op)` does not
type-check against the i8 immediate ABI, so `main` ABORTS (`LLVM ERROR: Broken module
found`, rc 134) where i32 is silent — and **the commuted `add` IS plain-C reachable**
in its wrong-IMMEDIATE face, retiring half of the "commuted is hand-IR-only" reading
(the wrong-REGISTER face stays hand IR). Programs committed at
`inc1-records/session-7bbdb89e/eqpx_reproducers_r1/`.
**LANDED on `main` 2026-09-06 as ONE squash commit of branch `eqpx-fix`** (`git log main -1`)
after two opus lenses (round 1 CLEAR-WITH-ITEMS, round 2 CLEAR-WITH-ITEMS, every item closed) and the
Fable clearance **CLEAR-WITH-OWNER-QUESTIONS** (`inc1-records/session-7bbdb89e/clearance_eqpx.md`:
the ruling matched clause by clause, corpus diff 0/0/0 re-derived, its own M1 mutant reddens exactly
the 8 declines, two MORE plain-C members found and declined; F-CL-1 corrected the W1 "no second
diagnostic" attribution — the driver exits at the first `DS_Error`, so `lowerBreakReversePlay` is
never reached). Full `ctest -j6` 367/367 (350.23 s). The two standing owner questions are
docs-level: keep/drop the operand-INDEX form (inert on the corpus, live when wrong — kept, argued
in-source), and a header note on the pre-existing (1b) template fixture.

**E2 — §9's per-bit idiom row was measured FALSE, then FIXED, and is TRUE again.**
The row pins D4's register-wide Z as `and(h,1<<i) → icmp eq 0 → x → rz_i1 → x →
2 _unc → 2 free`. At the Increment-1a hand-back that held at **K = 1 only**: from
K = 2 upward the `and` rail was never uncomputed and never freed (measured: 32 mints,
**0** `_unc`, at K = 32), so each activation stranded one BIT of `q` — a which-path
record — and the diffusion that makes a phase useful ran over K live records. Rolled
and hand-unrolled were different unitaries. That was graded a **CONFIRMED miscompile**
(F-L7-2 / F-L5-1 / F-L2-1b) and fixed by `LoopLowering::invariantRegisterRoots`; the
row is now correct, MEASURED in the committed goldens —
`slice_control_phase_perbit_loop.expected.log`: 4 `and_i32_hl` / 4 `and_i32_hl_unc` /
8 `cqrt_free` at K = 4, and the K = 32 golden 32 / 32 / 64 — with
`e2e-phase-perbit-loop-twin-identical` gating rolled == hand-unrolled.

⚠ **AT THE RULE-13 CLEARANCE (2026-09-05) THIS PARAGRAPH SAID "TWO THINGS THE FIX DOES
NOT COVER". THERE WERE THREE, AND THE THIRD WAS THE BLOCK.** Finding **C-1**: add ONE
ancilla rotation to the body — `for (i…) { if ((q>>i)&1) cq_phi(θ); r = cq_theta(r,.1); }`
— and the SAME loop returns `Collapsed` from `collapseRailPhisIn` instead of
`NotClaimed`, so `invariantRegisterRoots` was never asked and `markIfRailLocal` refused
on `q` at its "accumulating loop-invariant tainted input" clause. Nothing was marked and
all K bit rails leaked again: MEASURED at 542d588 **3 mints / 0 `_unc`** against **3/3**
hand-unrolled and **3/3** on the pre-3qlq oracle's register-surface twin, at `opt` exit
0, verify-clean and STRICT stage 2b `0 violation(s)`. Same defect as F-L5-1, one
dispatch precondition over, inside D4's own idiom — a wrong unitary, not a leak, because
the post-loop diffusion interferes branches carrying distinct which-path labels (Rule 8).
**FIXED in the C-1 fix round (2026-09-06):** on the `Collapsed` branch
`collapseFlattenedLoopRails` now ALSO collects the loop-invariant roots — into a
SEPARATE set, unioned into the carried `Roots` only on success — and
`invariantRegisterRoots` SKIPS any candidate the collapse already owns (its
`CarriedRoots` parameter; without that skip the body's own `r = cq_theta(r,.1)` trips
clause (iii) and takes the whole extension down). **The proof is clause (ii)'s own (I1)
argument, unwidened**: a root mint lowers to `cqrt_alloc_<W>` and fails
`ChainWalk::isInteriorTerminalHandle` clause (I1), so no adjoint `At` can ever be placed
for it in the K-times body — a property of the ROOT, not of whether some other register
crosses the back edge. WITNESS: the rolled trace is BYTE-IDENTICAL to the hand-unrolled
twin's (37 = 37, gated by `e2e-phase-perbit-loop-mixed-twin-identical`), pinned in lit by
`control_phase_kickback_mixed_invariant_carried_inloop.ll`, and the matrix gained its
first second-CARRIED-register axis (`loop_twin_matrix.py` sub-grid F).

⚠⚠ **AND THE SECOND C-1 REVIEW ROUND (2026-09-06) FOUND TWO MORE OF THE SAME CLASS IN THE
FIX ITSELF, both CONFIRMED MISCOMPILES, both now FIXED** (notes §3.10). Read the count as
*five* things this row did not cover, found over three rounds, not two. **F-C1-1**: one
added line, `q = q + 7;` in the loop's PREHEADER, put the leak straight back (3 mints /
**0** `_unc` rolled against 3/3 hand-unrolled, on 542d588 AND on the round-1 C-1 fix, with
the pre-3qlq oracle at 3/3 rolled == unrolled) — because `invariantRegisterRoots` peels only
through ops whose DISPOSITION is `InPlace` and a preheader `add` is `Unproven` there, while
`lowerOps`' M-C lowers that very op IN PLACE. It is PRE-EXISTING and F-L5-1-era, not the C-1
fix's: the same program with NO carried register leaks identically on both binaries. Fixed
by asking the ONE owner of that decision, `ArithLowering::classifyInPlaceReassignment`, and
COMMITTING to its answer via `taint.InPlaceRailOps` (with a `hasOneUse` stability conjunct
and a rollback on failure). **F-C1-2**: the same mixed loop with an ONWARD (round-2) in-loop
region leaked for two independent reasons — the "already claimed" fact was a caller LOCAL
while the collapse happens in the ROUND-1 call (fixed by `taint.ClaimedRailRoots`, written
at both collapse sites), and the round-2 delta was keyed on block MEMBERSHIP while a round-2
region flattens into the very `Pred` a round-1 region already used (fixed by making
`taint.InLoopFlattenedPreds` a per-block COUNT). WITNESSES: `e2e-phase-perbit-loop-mixed-preadd-twin-identical`
(38 = 38, was 32 vs 38) and `e2e-phase-onward-perbit-loop-mixed-twin-identical` (47 = 47,
was 41 vs 47), plus three lit accepts and two accept-and-leak controls.

⚠⚠⚠ **AND THE THIRD C-1 REVIEW ROUND (2026-09-06) FOUND THAT THE SECOND ROUND'S OWN FIX HAD
INTRODUCED A CONFIRMED MISCOMPILE, then found a SECOND one while building the tripwire for the
first** (notes §3.11). Read the count as *seven* things this row did not cover, found over
FOUR rounds on one function, and budget a fifth. **F-C1B-1**: the F-C1-1 commit asks
`classifyInPlaceReassignment` at ROUND 1 and `lowerOps` honours the marking unconditionally,
so a "classical immediate" that becomes TAINTED at round 2 (anything derived from a 6.5/4.5
`%out`) was emitted as the classical operand of an in-place gate —
`cqrt_addc_i32(%h4, %h_op)`, a QUANTUM RAIL HANDLE IN THE ABI'S CLASSICAL-IMMEDIATE SLOT,
printed as the bare decimal `6`; the commuted spelling MUTATES THE WRONG RAIL. Four plain-C
programs, `opt` exit 0, verify-clean, STRICT 2b clean, all correct on 542d588 and on the
round-1 fix. The `hasOneUse` conjunct guarded G6/G7 and NOTHING guarded G2 — the 8h7d.5 lesson
a fifth time. **F-C1C-1**: `hasOneUse` does not bound the post-RAUW user set either, because
`lowerRotations` merges a whole theta chain onto ONE handle — `int q2=cq_theta(q,.3); int
a=q2+7; … cq_measure(q)` made `q` and `a` the SAME register on the round-2 binary (measures
`h0`,`h1`,**`h0`** where 542d588 and the hand-unrolled twin give `h0`,`h1`,**`h2`**). FIXED by
(1a) a MONOTONE `isa<Constant>(Imm)` fence at the commit and (1b) a LOUD RE-VERIFICATION of
the ONE fence at `lowerOps` for exactly the ops this path marked
(`cq loop lowering: pre-loop in-place op no longer provable at lowering`; a silent fallback to
out-of-place is not sound, because the body marking the commit licensed already stands). The
same round narrowed `taint.ClaimedRailRoots` from a module-wide set of ROOTS to
`(root, the CLAIMING loop's header)` — **F-C1B-2** — after measuring a program where loop A's
claim marked loop B's body on a rail loop B never proved.
⚠ **THE LENS ON ROUND 3 GRADED IT CLEAR-WITH-ITEMS AND FOUND A FURTHER MEMBER OF THE CLASS
THAT IS *NOT* THIS EPIC'S — do NOT fold it into the seven above; the seven are this epic's,
this one pre-dates it** — **F-C1C-B**, notes §3.12, bd `test_C_libtooling-eqpx`: the same
"classical immediate turns tainted at round 2" defect reached through the LOOP writers
(`tryCaseA`, `collapseRailPhisIn` step (3)) for the **`xor` stem, from plain C** —
`cqrt_xorc_i32(h1, 6)` where the bare `6` is a template rail's HANDLE ID — reproducing
byte-for-byte on the **pre-3qlq ORACLE 52d7764** and on every binary of this epic. It is
PRE-EXISTING, so it neither blocks nor is charged to this branch; what it does retire is the
sentence round 3 used to bound its own scope (*"the other three `InPlaceRailOps` writers mark
a rail they PROVED with their own fences"*) — **their fences prove the RAIL; none of them
proves the IMMEDIATE stays classical.** Round 3's own bound over its 262-program corpus is
likewise corrected: **6 movers in scope plus `w3` by design**, and the lens's 299-program
re-run reads **286 unchanged / 13 moved, 0 in the accept direction** (F-C1C-E).
⚠⚠⚠ **AND A FOURTH C-1 ROUND (2026-09-06, bd `7yd0` — notes §3.14) RETIRED THE `hasOneUse`
CONJUNCT ITSELF, on a LEAK the Rule-13 round on INCREMENT 2 found in the LANDED `main`
a3c1513** (`review_inc2_r2` **F-I2-1**; the same conjunct the re-clearance had already filed as
**OQ-C2-1**). Read the count as *eight* things this row did not cover, found over SIX rounds on
one function — and note that the eighth was found by a round reviewing something else. THE
PROGRAM: a 4.4 select merge, one `m = m + 7` on its `%out`, then D4's per-bit loop — thirteen
lines of plain C, **4 mints / 0 `_unc` rolled (44 lines) against a hand-unrolled twin at 4/4
(52)**, 32 / 0 at K=32, `opt` exit 0, verify-clean, STRICT 2b `0 violation(s)`. CAUSE: a
Phase-4 merge out-rail STRUCTURALLY cannot satisfy `P->hasOneUse()` — the emitters **WRITE**
`%out` (two `cqrt_copy_<W>_controlled` for the 4.4 merge and Inc 2's value merge, one
`cqrt_copy_<W>` for the Phase-4 value-arm route) before anything reads it — and `hasOneUse`
cannot tell a prior WRITER from a later READER, while `classifyInPlaceReassignment`'s own
G6/G7 pair can. FIXED by dropping the conjunct: the commit now asks (1a) `isa<Constant>(Imm)`
and M-C's own fence, and **the temporal net is round 3's (1b) tripwire**, which re-asks that
fence at `lowerOps` and declines loudly — measured, not argued: with (1b) deleted all NINE
F-C1C-1-class programs accept and `y1` reproduces the round-2 wrong unitary verbatim, while
this tree declines every one. WITNESSES: `e2e-phase-perbit-loop-merge-preadd-twin-identical`
(**52 = 52**, was 44 vs 52), one lit accept
(`control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll`, RED on `main` at CHECK/FCNT/
UCNT) and twin-matrix sub-grid **F4** (2 cells, TRACE-DIVERGENCE on `main` → ACCEPT-IDENTICAL;
286 → 288). **STATUS: **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash)**, after the branch was REBASED onto the landed Inc 2
(258d974) — the rebase RE-MEASURED the one row round 4 could only argue, the
**Inc-2 controlled-copy VALUE merge** as a FOURTH producer of the same `%out` rail:
`q4b_preadd` is **4/0, 52 lines vs 4/4, 60 on `main` 258d974** and **4/4 = 4/4,
byte-identical at 60** on the rebased binary, now pinned by the lit accept
`control_phase_kickback_mixed_value_merge_preadd_inloop.ll` and the `cmp` gate
`e2e-phase-perbit-loop-value-merge-preadd-twin-identical`.
⚠ **AND IT CORRECTS OQ-C2-1's OWN ATTRIBUTION**: `m11d` is **NOT** bought back —
measured on an instrumented build, its candidate is refused by the M-C fence itself (G7 arm
(e): loop 1's `(q>>i)&1` is a still-UNLOWERED tainted `and i32` at the commit's program point),
so its trace is byte-unchanged. The `hasOneUse` line below therefore LEAVES this list; `m11d`
stays on it, re-attributed.

⚠ **TWO THINGS THE ROUND-3 FIX DOES NOT COVER, and both are NEW ENTRIES ON THIS LIST rather
than inherited ones.** (a) A **`volatile`-load immediate** on the preheader op
(`q = q + off;`) is no longer committed, so that loop returns to the pre-round-2 leak — 3
mints / 0 `_unc`, byte-identical to 542d588 and to the round-1 fix. M-C itself still lowers
the op in place; only the PREDICTION of that answer is refused (owner question OQ-C1-8).
(b) A **chained-theta wire whose PRE-op SSA name is read after the loop** now DECLINES loudly
where 542d588 accepted-and-leaked — F-C1C-1's own program, and the one-token workaround
(dropping that read) still compiles and still discharges every per-trip rail (OQ-C1-7).

⚠ **The other two are UNCHANGED and both remain Prime-Directive refusals rather than
proofs.** (i) A hoisted loop-invariant **TEMPLATE** rail read by the body's condition is
still refused and still leaks — **and the disclosure is now "ANY loop-invariant TEMPLATE
rail", not only `q * 3`**: the clearance re-measured the class over a `sext` rail
(`long long p = q;`), a Q+Q rail (`p = q + r`) and an ONWARD hoisted `mul`, and all three
leak identically (Q-R1-1). **The second review round widened the disclosure again, and the
new members are not casts the user wrote**: a bare `short q` makes `-O1` hoist a `sext` of
its own (F-C1-3, `p/r5_short_inv.c` — a TYPE, not a cast, and the same 3/0 vs 3/3), and a
preheader dtzb `add`/`xor` whose PRE-op value is read later (`int keep = q; q = q + 7; …
cq_measure(keep)`) makes M-C itself go out of place and mint one (F-C1-1's own leak control,
`control_phase_kickback_mixed_preheader_add_outofplace_leak_control.ll`, byte-unchanged on
all three binaries). Its rolled trace is BYTE-UNCHANGED across the C-1 fix, pinned
by `control_phase_kickback_mixed_hoisted_template_leak_control.ll`. (ii) A loop whose
CONDITION REGISTER is loop-INVARIANT **and compared DIRECTLY** — `for (…) if (q == k)
cq_phi(θ);` with `q` untouched in the body — **declines** `condition predates a
non-diagonal gate`, because `-O1` LICM-hoists the compare out of the loop (bd `drbq.12`,
arm-class-independent; the workaround is a body gate on `q` or an opaque threshold).
Note (ii) is why D4's idiom uses a DERIVED per-bit condition: `(q>>i)&1` is loop-VARIANT
even when `q` is not.

⚠ **AND THE LENS ON THE REBASED ROUND-4 TREE ADDED A THIRD (2026-09-06, `review_c1e`
finding F-C1E-2, verdict CLEAR-WITH-ITEMS): a preheader in-place op whose PARENT has a
SECOND *unlowered tainted* user is refused by the M-C fence itself — G7 arm (e), or G6
when the merge's copies are emitted after the pre-op — so the commit never marks it and
the O(K) which-path leak stays.** SEVEN measured spellings, all `clang -O1` plain C, all
ACCEPT, and **byte-identical to `main` 258d974 on six of them** (`a1` a dtzb head read by
the loop 4/0 44 vs twin 4/4 52 · `a2` the preadd on the value arm's SOURCE `p` 4/0 45 vs
4/4 53 · `a3` the preadd on the CHAIN-FINAL 4/0 45 · `a9` the pre-op value measured later,
a CORRECT G6 refusal · `a11` the same over a 4.4 select · `a4` a merge `%out` feeding TWO
loops 8/0 73 vs 8/8 91); on the seventh, `a17`, round 4 strictly IMPROVES it (8/0 → **8/4**,
the first loop discharges). **Round 4 neither introduced nor widened this class**, and the
diffusion variant that would make it a wrong unitary (`a16`) **DECLINES loudly** on every
binary (`cq controlled lowering: control flow under quantum control`), so it is a LEAK —
Rule-6 safe, structurally invisible to STRICT stage 2b (a TEMPLATE-minted rail has no
`cqrt_alloc` to count). It is **OQ-C1D-1's class one shape over**, disclosed not fixed;
reproducers `inc1-records/c1-round4/c1e_a{1,2,3,4,9,11,16,17}_*.c`, narrative notes §3.15,
tracked on bd `test_C_libtooling-3qlq.13`.

**E3 — §6.3's "an arm with N>1 `cq_phi` calls" decline is NARROWED: the DIAMOND
spelling ACCEPTS.** N calls in one arm emit **N `cqrt_rz_i1` gates on the one flag**,
in source order, with one mint / strip / free and one `cqrt_x` bracket pair. Nothing
is summed at compile time — each angle passes through verbatim and
`P(φ₁)·P(φ₂) = P(φ₁+φ₂)` happens in the hardware — so §6.3's stated rationale ("summing
angles is the 2b rounding class again") **has no subject on the Rz stem**; it is a
Ry-stem reason, and declining would also have regressed four shipped accepts. Pinned by
`control_phase_kickback_two_calls.ll` (2 `cqrt_rz_i1`, 0 `cqrt_x`, 1 `cqrt_free`).
⚠ **Both `if/else` spellings still DECLINE** with ≥2 calls per arm (`-O1` emits either
two angle selects on one compare, or a diamond with two merge-tail phis). So N-per-arm
is a property of the DIAMOND spelling, not of the construct — loud and safe; widening
means accepting multiple selects / tail phis on one flag, which is the same mechanism.

**E4 — §6.2 row P5 (homogeneous phase `switch`) has NO plain-C `-O1` customer, and it
ships hand-IR only.** Measured over seven spellings: a phase arm's entire body is one
`call void @cq_phi(double)`, so every arm's suffix is identical modulo one operand and
SimplifyCFG's common-code sinking ALWAYS applies — dense case values become a
`@switch.table` of angles with ONE shared call, sparse ones a cascade joined by a
`phi double`. N-gate arms sink too (measured at 1/2/3 and 4/3/2 gates). The table's
tainted-index load makes the angle tainted, so both `-O1` outcomes are pinned as loud
declines (including `control_phase_switch_reject_table_fold.ll`, which carries the
verbatim `-O1` module). P5 therefore lowers on the IR `switch` only (3 accept + 7
decline fixtures), `tests/e2e/slice_control_switch_phase.c` is kept in the tree
**UNREGISTERED** with the measurement in its header, and its ctest entry was removed.
Owner choice: accept P5 as hand-IR-only (the footing the `if/else` kickback arm has had
since part A), or commission a TABLE-FOLD RECOGNIZER as its own increment — the table
is `private unnamed_addr constant` with `ConstantFP` entries, so the N angles are
statically known and the lowering is P5 with the case values read from the table. That
recognizer is what would give P5 a real customer.

**E5 — §6.2 row P6 does not reach P2: an ANGLE SELECT inside a rolled loop DECLINES**
(`condition predates a non-diagonal gate`), although P6 lists P1–P3 as in-loop accepts.
Pinned by `control_angle_select_phase_reject_in_loop.ll` and filed rather than fixed
(Q-R1-2 / OQ-19). P1 and P3 in-loop are unaffected and are gated by
`e2e-phase-grover-loop-twin-identical` and `e2e-phase-perbit-loop-twin-identical`.

**E6 — three §6.3 rows moved, and one moved LAYER.** The **bare tainted `i1` condition**
(Q4, filed as "Inc 1b") stayed a decline in Increment 1. The **Q+Q compare condition**
was declining in the OPCODE layer (`no template for opcode 'icmp i1' in tainted context`)
rather than the control layer — a Rule-1 "wrong layer" finding, since a fence that holds
because a template is absent downstream is the weakest kind; it now declines in the
CONTROL layer, per leaf, for P1 and P4 (P5 is structurally exempt). The **compound
condition** row gained a recorded asymmetry: `collectCondTree`'s `AllowLogicalSelect` is
ON for the branch phase and OFF for the 4.4 data select, so `if (q==5 && r==3) cq_phi(θ)`
lowers while `int x = (q==5 && r==3) ? a : b;` declines — one grammar, two verdicts,
decided by a flag. Safe direction, recorded rather than left implicit; the emitter
already handles the widened case.

**E7 — §6.4's migration estimate, re-measured against the tree.** The design figure was
"540 of 1582 lit fixtures reference `cq_phi`". What actually happened, MEASURED with
`git diff --name-status 52d7764 HEAD -- ir-pass/test`: **473 MODIFIED, 91 ADDED, 17
REMOVED** (corpus 1582 → 1656), of which 104 were re-derived from the pass output, 143
re-spelled, 16 swapped to `cq_theta` and 6 retired. **12 fixtures flipped DECLINE →
ACCEPT** and were sent to their own adversarial lens (0 over-accepts: 8 legitimate, 4
retired). ⚠ THREE fixtures LOST THEIR SUBJECT — they were built on
`cq_phi(i32 CLASSICAL, θ)`, which is an ill-formed CQ program but a well-formed LLVM
module, so no oracle comparison could see it; a mechanical re-spell would have left them
green while pinning nothing. On the slice side: 66 `.c` files touched, every changed slice run
through the full pipeline with **STRICT** stage 2b, and **30 `.c` REWRITTEN under an
explicit disposition** (each with a `⚠ REWRITTEN PROGRAM` header naming the measurement).
The ctest layer moved **+15 / −3** — MEASURED by `comm` over the two `ctest -N` name
lists, this tree against the pre-3qlq oracle build — so 327 → 339 entries, `^e2e-` 317 →
329, `^e2e-slice-` 293 → 302, over 304 committed goldens. The `--epic 3qlq` golden audit
classified the 72 changed goldens as **29 substitution-only · 1 ambiguous-d · 1
ambiguous-ca · 11 new-file · 30 FINDING**, and the 30 FINDINGs are exactly the 30
rewritten programs (`comm` empty both ways; `--selftest` PASS, 0 survivors). *(The audit
figures are prep-b2's final run; the ctest and golden counts are re-measured here.)*
*(The C-1 fix round of 2026-09-06 then took the corpus **1656 → 1660**, the ctest layer
**339 → 342** and `^e2e-` **329 → 332** — `^e2e-slice-` 302 → 304, the twin matrix 274 →
284 cells, the goldens 304 → 306 — all MEASURED in `3qlq-inc1-fix-c1` with `ls
ir-pass/test/*.ll | wc -l` and `ctest --test-dir build -N`, name-diffed against the
542d588 build's list. Everything in the paragraph above is the INC-1 measurement and
stands as written; note only that re-running its `git diff --name-status 52d7764 HEAD`
census at the fix-round HEAD reads **95 A / 17 D / 473 M**, the 4 new fixtures being the
difference. See E2 and notes §3.)*

**E8 — the §12 owner questions were proceeded on as ASSUMED, and two of the assumptions
were exercised.** Q3 (run-time angle arms admitted for the Rz stem) is load-bearing for
one shipped accept fixture and is sound for the reason §3 gives — the Rz stem performs no
subtraction, so the Ry stem's IEEE-rounding fence has no subject. Q1 (delete the unemitted
`cqrt_rz_<W>` / `_controlled` declarations at the freeze, not now) is why those symbols are
still declared; the freeze-gate decision is in `ROADMAP.md` Phase 11. Q4 (bare `i1`
condition is Inc 1b) held. Q2 (no remark on deleting an uncontrolled `cq_phi`) held.

**E9 — three CONFIRMED silent miscompiles were found IN Increment 1 by adversarial review
and none by the 1656-fixture suite**, all `opt` exit 0, verify-clean and STRICT-stage-2b
clean: the uncompute spine adjointing the kickback gate on a shared flag and cancelling
the user's phase exactly (fixed by the `!cq.branchphase` membership record, refused by
three spine predicates, recorded at all six emission sites); P7's D2 deletion running
BEFORE the second round of control detection, so a branch phase under an onward tainted
branch was deleted and its orphaned angle then lowered as quantum fp DATA (fixed by moving
the stage after the round-2 fixpoint); and a stale-header retired `@cq_phi_<sfx>` call that
was neither lowered nor declined (fixed by a reserved-name decline on any USE plus a loud
end-of-pass survivor postcondition). Round 2 added a fourth of the same family — a
once-running rail-collapse stage whose premise the second round falsifies. **Budget a
third round on any successor increment**, and read the §2 stage table as a method.
⚠ **THE HEADING'S "THREE" IS THE ROUND-1 COUNT AND IS NO LONGER THE TOTAL: it is FIVE,
and the fifth was found by the CLEARANCE, after two adversarial rounds had already run
over this exact code and handed it on.** The fifth is **C-1** (E2 above, notes §3.2): the in-loop
entangled-rail leak's THIRD instance, one dispatch precondition over from round 1's
F-L5-1 and round 2's F-R1-1, inside D4's own designated idiom, reached from four lines of
plain C, at `opt` exit 0, verify-clean and STRICT stage 2b `0 violation(s)`. **Still none
by the fixture suite** — 1656 fixtures were green at the clearance's own measured gate.
Note what this does NOT say: the clearance ran 12 probes for a third ONCE-ONLY-STAGE
instance and found none in the accept direction, so that family stands at two and C-1
belongs to the other one. Two families, two counters. **The number to quote when scoping
a successor is five confirmed silent miscompiles over three adversarial passes on ONE
increment, one of them after the increment was already reviewed twice** — budget a round
AFTER the round you think is last. ⚠ **E10 supersedes that number: it is SEVEN over FIVE
rounds, and two of the seven were introduced by a fix.**

**E10 — the C-1 disposition (2026-09-06), in five lines; reproducers and full arguments in
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 (§3.1–§3.14).**
1. **Round 1 — the CAPABILITY.** The clearance BLOCK (C-1) was fixed by having
   `LoopLowering`'s `Collapsed` branch ALSO collect the loop-invariant root mints beside
   the carried roots, on clause (ii)'s UNCHANGED (I1) proof; witnessed by
   `e2e-phase-perbit-loop-mixed-twin-identical` (37 = 37) and pinned by
   `control_phase_kickback_mixed_invariant_carried_inloop.ll` (notes §3.3–§3.9).
2. **Round 2 — TWO MORE CONFIRMED MEMBERS of the same class in the fix's own
   neighbourhood** (F-C1-1, one added `q = q + 7;` in the PREHEADER; F-C1-2, the ONWARD
   round-2 in-loop region), fixed by committing to `classifyInPlaceReassignment`'s answer
   via `taint.InPlaceRailOps`, by `taint.ClaimedRailRoots` at both collapse sites, and by
   making `taint.InLoopFlattenedPreds` a per-block COUNT (notes §3.10).
3. **Round 3 — the NARROWING, because round 2 had INTRODUCED a confirmed silent miscompile
   of its own** (F-C1B-1: a quantum rail handle in `cqrt_addc`'s classical-immediate slot),
   plus a second found while building its tripwire (F-C1C-1) and a module-wide claim key
   narrowed to per-loop (F-C1B-2): a monotone `isa<Constant>(Imm)` fence at the commit and a
   LOUD re-verification of it at `lowerOps` — every change in the refuse direction
   (notes §3.11).
3b. **Round 4 — the CONJUNCT RETIRED** (bd `7yd0`, notes §3.14). The Rule-13 round on
   **Increment 2** measured a rolled ≠ unrolled leak in the LANDED `main` (F-I2-1): a
   Phase-4 MERGE OUT-RAIL structurally cannot satisfy `P->hasOneUse()`, because the emitters
   WRITE `%out` before anything reads it, so the commit refused and D4's per-bit loop leaked
   O(K) entangled which-path rails (4/0 vs 4/4 at K=4; 32/0 at K=32). The conjunct guarded
   NOTHING G6/G7 does not — measured, with programs — and is dropped; round 3's (1b) tripwire
   is the temporal net, and deleting it makes all nine F-C1C-1-class programs miscompile
   again, which is the proof that it is. Witnessed by
   `e2e-phase-perbit-loop-merge-preadd-twin-identical` (52 = 52) and sub-grid F4.
   ****LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash)**, after a rebase onto 258d974 that turned the round's one ANALYTIC row —
   Inc 2's value merge as a FOURTH producer — into a measured one (60 = 60 against
   52 vs 60 on `main`), and that folded in the round-4 lens items F-C1D-2 (the
   in-source "the commit cannot reach an Inc-2 chain head" argument, pinned by the
   new fixture's `HCNT` prefix), F-C1D-3 (three verified refinements to notes
   §3.14's 8h7d.5 closure table, including the F-3 row it lacked) and F-C1D-4 (the
   injection matrix's `extra_ry` row: 25 MISSED first, then 0 MISSED / 0 DIRTY over
   44 accepts × 17 mutations once each gained a `RYCNT` prefix).
4. **The count, said as it is: EIGHT findings of one defect class over SIX adversarial
   rounds on ONE function (`markIfRailLocal` and its dispatch precondition), TWO OF THEM
   INTRODUCED BY A FIX and the EIGHTH found by a round REVIEWING A DIFFERENT INCREMENT, plus
   ONE PRE-EXISTING member of the same class found in passing by
   the round-3 lens** — F-C1C-B, reproducing byte-for-byte on the pre-3qlq oracle `52d7764`,
   filed OUT of this epic as bd `test_C_libtooling-eqpx` (notes §3.12). **Zero** of the
   eight were found by the fixture suite. Budget a round AFTER the round you think is last.
5. **The re-clearance (2026-09-06, `inc1-records/session-adc5590a/clearance2.md`) returned
   `CLEAR-WITH-OWNER-QUESTIONS`** and Inc 0 + Inc 1 LANDED on `main` the same day. It
   measured the subject a strict improvement over `542d588` at every layer it could reach
   (0 DECLINE→ACCEPT flips over 404 programs; 1667/1673 fixtures and 305/308 slices
   byte-identical between the two binaries, every mover a discharge or a loud decline; 0
   stage-2b violations; 1328 injection cells 0 MISSED / 0 DIRTY; the golden audit unmoved
   beyond NEW-FILEs). What it leaves open are **four owner questions and one record item**,
   every one a DISCLOSED class that PRE-DATES this branch: **OQ-C2-1** (the `hasOneUse`
   stability conjunct refuses a commit M-C makes and the pre-3qlq oracle discharges —
   `m11d`, a two-loop spelling with a diffusion after; E2's residual list does not name it
   and no fixture pins it), **OQ-C2-2** (`short`/`sext` — F-C1-3 — is the one Q-R1-1 member
   the oracle got RIGHT, so `r5` is an oracle regression), **OQ-C2-3** (widen the Q-R1-1
   disclosure to a QROM-read invariant root and to `-O1`'s SIDEWAYS compare rewrite after a
   preadd; both oracle twins decline), **OQ-C2-4** (the over-decline list gains `s20`, a
   pre-op name measured BEFORE the op), and the record item that notes §3.12's "identical on
   `542d588`" is true of the DEFECT and not of the TRACE for the four in-region `eqpx`
   members. None is a wrong unitary this tree introduced.

**E14 — Increment 1b, the BARE `_Bool` CONDITION, is BUILT (bd `test_C_libtooling-3qlq.4`,
2026-09-10; §13).** `_Bool b = cq_theta(b0, θ); if (b) cq_phi(φ)` — §6.3's third row, the
"gate belongs on `b`'s rail" residual — lowers: the condition grammar admits a **RAIL LEAF**
(`isCondRailLeaf`: a `cq_theta_i1` result, root or chained, alone or as a child of an
`and`/`or`/`xor`/logical-select node), `CondTreeEmit` maps it to ITSELF, and the three
register-free phase emitters (flat kickback, depth-2 nest, Rz-stem angle select) put
`cqrt_rz_i1(h_b, θ)` on the register's own rail with **no mint, no strip, no free** — and
**no `cqrt_x` on a user register, ever**: a gate that fires on `b == 0` is the diagonal
`rz(h_b, −θ)`, on `X·P(θ)·X = diag(e^{iθ},1) = e^{iθ}·P(−θ)` (a GLOBAL phase, which D2
already discards; `fneg` is exact). Every other tree consumer (the 4.4 data select, the
value arm, the in-place Ry arm / state prep, the Ry-stem angle select, the clone lift)
declines a rail leaf loudly with ONE new string, `bare i1 register condition` — those are
the follow-ons 1b-B/1b-C, not omissions. Residuals keep `branch phase on a bare i1
condition`: a loop-CARRIED `_Bool` (a header-phi condition), a `trunc`/`zext`/phi/argument
`i1`, and a NEGATED rail level in the nest. **17 accept + 9 decline fixtures, 9 e2e
slices (all STRICT stage 2b) + 1 rolled == unrolled `cmp` gate — **plus 4 declines from the
Rule-13 round (§13.6: a CONFIRMED sibling-theta miscompile, fixed in the shared wire walker)**;
exactly TWO pre-existing fixtures moved**: the discriminator itself (`control_phase_kickback_reject_bare_i1.ll`,
`git mv`'d to `..._rail_diamond.ll` and rewritten as the accept its header promised) and
the drbq-era `control_inplace_ry_reject_raw_i1_cond.ll`, which keeps its decline and takes
the new string (it IS 1b-C's flip target; a duplicate pin of it was dropped).

**E15 — Increment 1b-B.1, the 4.4 DATA SELECT on a bare `_Bool`, is BUILT (bd
`test_C_libtooling-r9e5`, 2026-09-10; §14).** `int a = 5; _Bool b = cq_theta(b0, θ); if (b) a -= 3;`
— the owner's own program, which `clang -O1` folds to `select i1 %b, i32 2, i32 5` — lowers. The
merge stream is the Rule-13-cleared 4.4 one VERBATIM; what changes is where the FLAG comes from: a
CNOT COPY of the rail (`bf = cqrt_alloc_i1(0); cqrt_cnot(h_b, bf)` … `cqrt_cnot(h_b, bf);
cqrt_free(bf)`), minted and stripped by `CondTreeEmit` under a trailing `CopyRailRoot` parameter
(every phase caller byte-unchanged), so **no `cqrt_x` ever lands on a user register** and the only
gates touching it are read-only controls — the gate class §13's nest already emits. Classifier: the
§13.3 ladder with the SELECT as the read point (measured-before asked positionally and by
reachability; the wire question with the DT prong for RAIL seeds only, so the S† `b = cq_theta(b,
−θ)` after the select accepts and in-loop stale names decline). **The VALUE arm and the 6.5 arm on a
rail are NOT this increment** — measured, the short value arm IS a select at `-O1` and lowers now;
the unfolded diamond (≥5-op chain, hand IR) and the 6.5 arm are bd `test_C_libtooling-fg9k` /
`test_C_libtooling-54ur` (`inc1-records/session-r9e5/SCOPE_B2.md`). One CONFIRMED plain-C
over-accept was found by the orchestrator on the first build and fixed before the independent round
(F-B1-1, §14.7: the same-block measure-after-select in a loop); its COMPARE twin is PRE-EXISTING on
`main` (bd `test_C_libtooling-r10v`). 13 accept + 9 decline fixtures, 7 STRICT e2e slices + 1
rolled == unrolled `cmp` gate (39 = 39); exactly ONE pre-existing fixture moved (the discriminator
`control_swap_reject_select_rail_cond.ll`, `git mv`'d to `control_swap_select_rail_const.ll`). **Its Rule-13
round 2 then BLOCKED on the ROUND-2 TAINT WINDOW (§14.7 F-B1R2-1, a PREDICATE asked at round-1 taint whose
relation `lowerRotations` decides at final taint — plain C, two TUs, pre-existing for the compare select,
bd `test_C_libtooling-9pum`) and the fix is `reverifyRailCondReads` (§14.8): every emitted rail read is
recorded at four sites (the fourth, the nest's conjunction toffoli, found by the fix itself) and re-verified
under FINAL taint after the fixpoint, in both entry points, declining loudly.**

## 1. Motivation — the shipped Grover goldens are the identity

Measured 2026-09-05 at HEAD `52d7764`. The runtime ABI pins `cqrt_rz_<W>` as
**tensored** — "Rz on each qubit of the register" (`docs/backend.md:995`,
`docs/frontend.md:192`). The flagship customer program therefore lowers to a gate
that is not an oracle:

```
if (q == 5) q = cq_phi(q, PI);            // slice_control_seq_grover.c:142  "oracle: mark |5>"
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1.921fb54442d18p+1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
```

On the marked branch the phase is `e^{iπ·popcount(5)} = +1` (under EITHER Rz
convention the marked phase is `(−1)^popcount(target)`). The reflection
`if (q == 0) q = cq_phi(q, PI)` is worse: a per-qubit diagonal gate fixes
`|0…0⟩`, so it can never put `−1` there. **Every `slice_control_*grover*` golden is
a self-consistent trace of the identity on `q`.** Rule 2 says exactly why nothing
caught it: the golden byte-diff proves every symbol resolves and signature-matches;
it does not witness the unitary, and there is no simulator (owner decision
2026-06-10).

The explicit-ancilla spelling — `bool m = (q == 5); m = cq_phi(m, PI);` with `m`
then dead — is the physically correct kickback and **declines** at HEAD in both
measured spellings with `cq uncompute: dead chain would free a measured register`
(the spine walks the dead `icmp→rz` chain back to the measured source). So Grover
is not expressible at HEAD by any spelling.

## 2. Owner decisions (2026-09-05)

| # | decision |
|---|---|
| **D1** | `cq_phi` becomes **register-free**: `void cq_phi(double θ)` = "multiply the amplitude of the CURRENT BRANCH by `e^{iθ}`". Under tainted control it lowers by **kickback**: flag mint → **uncontrolled** `cqrt_rz_i1(flag, θ)` → the ordinary `_unc` strip → `cqrt_free`. The flag returns to `|0⟩` on every branch (§3). |
| **D2** | An uncontrolled or classically-controlled `cq_phi` is a global phase and is **deleted**. This is a documented semantic, not a diagnostic. |
| **D3** | **No new runtime symbol.** The two frontend concepts (per-qubit Rz, branch phase) would be redundant; only the branch phase survives. The emitted Rz set shrinks to `cqrt_rz_i1`. |
| **D4** | **No multi-bit Rz.** The documented idiom for a register-wide Z rotation is a classical loop, `for (i…) if ((q >> i) & 1) cq_phi(θ)` (measured: lowers ROLLED at K=4 and K=32 today, IR size independent of K). "Rz directly on qubit `i`" is a **backend** peephole over a fixed gate idiom; the width-only ABI cannot address a qubit and gets no symbol for it (Rule 15). |
| **D5** | `cq_theta` keeps `a = cq_theta(a, θ)`. `a = cq_theta(θ)` is impossible: after mem2reg there is no variable `a`, and a register-free theta is byte-identical to today's fresh-register state prep (measured, §4.2). The rule "no different integers in the expression" is enforced in its **semantic** form — after a rotation, the pre-gate SSA value has no use that executes after the gate — stated ONCE in `frontend.md`; `cq_ry(x, θ)` becomes the documented statement-macro surface. Strict single-use is rejected: it would decline Grover (the compare and the rotation both read `q`). |
| **D6** | **Value arms leave the cswap route** for the controlled-copy merge: hoist the arm's pure out-of-place chain into the pred, two `cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail, chain `_unc`, strip. This is the 4.4 `SelectMergeEmit` mechanism applied to the diamond (Rule 14); the `?:` select twin is the byte-identity oracle. Measured saving per arm: ~`2W` Toffoli + `9W` CNOT and one W-bit rail (§7). |
| **D7** | Increments in this order: **Inc 0** docs + `cq_ry` macro (no pass change) · **Inc 1** register-free `cq_phi` (the Grover fix, the smaller change) · **Inc 2** value arms. |

## 3. Physics, stated once

**Kickback.** With `f = c(x)` minted into a `|0⟩` ancilla, the state is
`Σ a_x |x⟩|c(x)⟩`. `P(θ) = diag(1, e^{iθ})` on the ancilla gives
`Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`; the compare `_unc` (a permutation
`|x, c(x)⟩ → |x, 0⟩`) gives `Σ a_x e^{iθ c(x)} |x⟩|0⟩`. The ancilla is provably
`|0⟩` on every branch (Rule 6) and the phase is on the branch. Under
`Rz(θ) = diag(e^{−iθ/2}, e^{iθ/2})` the difference from `P(θ)` is a global phase,
so `cqrt_rz_i1` is the gate either way. A `¬flag` arm is `x(f)·P(θ)·x(f)`; the
sign-fold `x·P(θ)·x = e^{iθ}·P(−θ)` is a valid peephole but the shipped form keeps
the `cqrt_x` bracket, matching every existing `¬flag` emission.

**Why neither route is needed for a phase arm.** The cswap route (`cswap; Rz(w);
cswap`) and the controlled-copy route (`w ^= f·q; Rz(w); w ^= f·q`) are BOTH
junk-free for a diagonal gate — the first because a swap moves and `Rz|0⟩ = |0⟩`,
the second because a diagonal gate does not change the label the second copy
un-copies. They cost `2W` Fredkin and `2W` Toffoli respectively; the kickback
costs ONE single-qubit gate and no work rail. Both routes fail for non-diagonal
gates, which is why value arms are method-B and Ry arms are controlled-in-place.

**Compound conditions.** `-O1` folds `if (a) { if (b) cq_phi(θ); }` and
`if (a && b) cq_phi(θ)` into ONE branch on `select i1 %a, i1 %b, false`
(measured, §6.1). The flag is the conjunction `cqrt_toffoli(f_a, f_b) → f_ab`,
`P(θ)` on `f_ab`, LIFO uncompute (toffoli first, then each leaf strip). This is
what `tools/opcode_table.yaml:46` has always said nesting does ("combines flags
via cqrt_toffoli, PRD §2.7").

**Angle select.** `-O1` sinks `if (c) cq_phi(A); else cq_phi(B);` into one call
on `select i1 %c, double A, double B` (measured). Lowering: `x(f); rz_i1(f, B);
x(f); rz_i1(f, A)` — `P(A)` on `f=1`, `P(B)` on `f=0`, **exact, no subtraction**.
The 2b by-difference form and its `2^-40` rounding fence are RETIRED for the Rz
stem, and a run-time arm is admissible for Rz (nothing is computed from the
angles). The Ry stem is untouched (constant arms only, 2b clearance F-11).

**Value arm by controlled copy** (Bennett, keep-source-live):
`t = R(p)` out of place on the ORIGINAL `p`, unconditionally; `out = |0⟩`;
`out ^= f ? t : 0`; `out ^= ¬f ? p : 0`; `t` uncomputed by `_unc` (a function of
the unchanged `p`); strip `f`. `out = f ? R(p) : p`; `t`, `f` freed clean; `p`
stays allocated and entangled with `out` — exactly as the swap route leaves it.

> ⚠ **ERRATA (Inc-2 Rule-13 round 1, findings F-V1-4 / F-V2-3 — measured, not a
> design change).** The two sentences above are true of `f` and of `p` and FALSE
> of `t`. As shipped, the chain's INTERMEDIATES are `_unc`'d and freed by the
> whole-DAG spine, but the chain's FINAL rail `t = R(p)` — whose live consumer is
> the controlled copy — is left **allocated and DIRTY**, never `_unc`'d and never
> freed (an if/else leaks two; the §7.2 V3 switch also leaks each delta `d_i`).
> Rule-6 sound while `p` is retained, and `free_pairing_check.py` STRICT is clean
> — it is a leak, never a dirty free — but the LEAK CLASS is not the route's: the
> route returned every rail it minted to |0⟩. Consequence for §9 follow-on
> **3qlq.5 (free the value-arm SOURCE): it is UNSOUND BY DEFAULT under this
> stream** and must discharge the finals/deltas first, because they still record
> `p`. Full account and the measured allocated/dirty counts:
> `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1. ⚠ **And do not restate the soundness of
> that leak as "tracing the ancilla out leaves the reduced state unchanged" — that
> is FALSE as a density-matrix claim** (it dephases the off-diagonals between `p`
> and `p′` with `R(p) ≠ R(p′)`). The true and sufficient statement is §0 **E1b**:
> relative to the source's live registers the reduced state equals the ROUTE's
> because the retained `p_old` already determines `R(p_old)`, and no
> CQ-expressible continuation can observe the difference because `out`'s own
> retained label records it and the ABI mints no in-place Q+Q gate on `out` —
> which is exactly why 3qlq.5 is the continuation that breaks it.
Speculating `R` is sound because every arm op is a pure TOTAL template and the
§3c clobber decline already refuses an arm that rewrites a register the
condition reads; the 6.5 classical-call arm hoisted on the same argument.

## 4. Surface change (`CQ.h`, `frontend.md`)

### 4.1 `cq_phi`

- `void cq_phi(double angle);` — ONE extern. The 15-width `cq_phi_<sfx>(x, θ)`
  family and its `_Generic` dispatch are **removed**. A program using the old
  spelling fails to compile against the header; nothing needs a migration shim.
- `frontend.md` §3.3 rewritten: branch phase; uncontrolled = global phase =
  deleted; the per-bit loop idiom (D4); the Grover oracle and the `|0⟩`
  reflection as the two worked examples.
- The taint model is unchanged: `cq_theta` remains the sole source and
  `cq_measure` the sole sink. `cq_phi` no longer propagates anything — it has no
  data operand. It is ordered by the block it sits in, not by taint.

### 4.2 `cq_theta` / `cq_ry` (Inc 0, docs + macro only)

- `#define cq_ry(x, angle) ((x) = cq_theta((x), (angle)))` — the documented
  statement surface. `cq_theta` stays declared (state prep `r = cq_theta(5, θ)`;
  `int r = 5; cq_ry(r, θ)` is the same IR after `-O1`).
- `frontend.md` gains the **linear rule** as language semantics: "a rotation
  consumes the old name; a read of the pre-gate value that the compiler cannot
  prove executes before the gate is refused". `R6`, `staleRailRecordRead` and
  `declineStaleRecordOps` are named as the three SITES of that one rule. No
  disposition changes in Inc 0; a `frontend-lit` check pins that `cq_ry`
  survives `-O1` as the same IR as the spelled-out form.
- Measured refutation of `a = cq_theta(θ)`, kept for the record: with
  `int cq_theta_noreg(double)`, `q = cq_theta(q,.3); q = cq_theta_noreg(.7);`
  arrives as two unrelated calls; nothing ties `%4` to `%2`.

## 5. ABI — no new symbol; the emitted set shrinks

| symbol family | before | after |
|---|---|---|
| `cqrt_rz_i1` | emitted | emitted (the ONLY Rz) |
| `cqrt_rz_{i8,i16,i32,i64,f16,f32,f64,f80}` | emitted (uncontrolled phi) | **not emitted** |
| `cqrt_rz_<W>_controlled[_inv]` ×9 | emitted (2a flat path, 2b Rz stem) | **not emitted** |
| `cqrt_cswap` | phase route (nest, switch), value route (flat, switch), 7.2 abort-park | **7.2 abort-park only** |
| `cqrt_copy_<W>_controlled` | 4.4 select merge, 6.5 arm | + value arms (Inc 2) |
| `cqrt_toffoli` | nest flags | + compound-condition flags |
| `cq_template_*_controlled` (532) | unemitted reserve | unemitted reserve (unchanged) |

Declarations are NOT deleted by this epic (owner question Q1, §12). `ROADMAP.md`'s
freeze list loses `cqrt_rz_<W>_controlled` as a *live* family; the note records
"declared, unemitted since 3qlq". A `_controlled` in-place permutation
(`cqrt_addc_<W>_controlled`) was considered for in-place value arms and is
REJECTED by D3; value arms stay keep-source-live.

## 6. Increment 1 — register-free `cq_phi`

### 6.1 Measured `-O1` shapes (2026-09-05, `void cq_phase(double)` stand-in)

| source | arrives as |
|---|---|
| `if (q == 5) cq_phi(A);` | diamond, arm = one void call, **no merge φ** |
| `if (q == 5) cq_phi(A); else cq_phi(B);` | ONE call on `select i1 %c, double A, double B` |
| `if (q == 5) { if (r == 3) cq_phi(A); }` | ONE branch on `select i1 %a, i1 %b, false` (the nest is FOLDED) |
| `if (q == 5 && r == 3) cq_phi(A);` | identical to the row above |
| `if (c) cq_phi(A);` (classical `c`) | classical diamond |
| `cq_phi(A);` | straight-line call |
| `for (…) { if (q == 5) cq_phi(A); q = cq_theta(q,.2); }` | the 8h7d.5 in-loop diamond, no merge φ |

A nest whose inner block carries more than a cheap compare survives as a genuine
nest (SimplifyCFG's fold threshold); both forms are in scope.

### 6.2 Accept shapes

| # | shape | mechanism |
|---|---|---|
| P1 | flat diamond, single-compare tainted condition, arm = ONE `cq_phi` | mint → `rz_i1(f, θ)` (`x`-bracketed for `¬f`) → strip → free. The 2a `emitInPlaceRotationRegion` Rz path is REPLACED; no RAUW convention exists (no φ). |
| P2 | angle select (if/else folded) | two gates on the flag, exact (§3); `AngleSelectEmit` Rz stem rewritten; run-time arms ADMITTED for Rz; Ry stem byte-for-byte unchanged |
| P3 | compound condition tree (`and`/`or`/`xor` over tainted compare leaves, the `select i1` spellings) | leaf flags via the existing mint; combine via `cqrt_toffoli` / the OR and XOR node emissions `SelectMergeEmit` already has (reuse `collectCondTree`, Rule 14); `P(θ)` on the root flag; LIFO uncompute |
| P4 | genuine depth-2 nest (4.3 `RegionTreeDetect`) | DETECTION kept; `NestedRouteEmit`'s route replaced by P3's conjunction flag |
| P5 | switch, homogeneous phase (4.5) | per-case eq-flag → `P(θ_i)` on it → strip. The §5 **const-fold re-anchor scrub** is RETIRED: there is no arg-0 to fold |
| P6 | in-loop rolled (8h7d.5), P1–P3 inside a classically-bounded loop | as today's phase-region path; `collapseFlattenedLoopRails` has nothing to collapse for a phase arm (no gate on `q`), and every "Rz is diagonal and exempt" clause becomes vacuous rather than deleted |
| P7 | uncontrolled / classically-controlled `cq_phi` | deleted AFTER `detectControl` has claimed or declined every tainted `br` (Rule 1: no third path, so a surviving `cq_phi` under an unclaimed tainted `br` is an assert, never a delete) |

### 6.3 Decline partition (loud, `DiagnosticInfoUnsupported`)

- an arm with N>1 `cq_phi` calls (summing angles is the 2b rounding class again;
  follow-on, not this increment)
- mixed arms: `cq_phi` beside a value op or an Ry in the same arm
- ~~a bare tainted `i1` condition with no compare (`_Bool b = cq_theta(b0,θ); if (b) cq_phi(θ)`)
  — the gate belongs on `b`'s rail with no mint; filed as **Inc 1b** (Q4)~~ — **BUILT
  2026-09-10 (E14, §13)**; what remains declined is a NON-register `i1` (a `trunc`/`zext`/
  phi/argument), a loop-carried `_Bool`, and a negated rail level in the nest
- a Q+Q compare condition (pre-existing: the flag mint passes no Q+Q width)
- a multi-block arm (`cq_phi` under a classical branch inside a tainted arm)
- `cq_phi` inside a value (method-B) region, a loop with a quantum-bounded exit,
  an irreducible or multi-latch loop, a nested loop — all as today

### 6.4 Migration cost (measured 2026-09-05)

| population | count | treatment |
|---|---|---|
| lit fixtures referencing `cq_phi` | **540 of 1582** | a migration tool `tools/migrate_phi_fixtures.py`: an UNCONTROLLED `%r = call T @cq_phi_<sfx>(T %x, double θ)` becomes RAUW `%r → %x` + delete (D2); a call inside a tainted arm becomes `call void @cq_phi(double θ)` with its merge φ dissolved to the pred incoming. Every CHECK line is then **re-derived from the pass output**, never hand-edited (the Inc-4 handle-name lesson). Fixtures whose PURPOSE was the per-register Rz (`lowering_phi_*`, the 2a peephole family, the 2b Rz-stem family) are rewritten or deleted by hand, each with the decision in its header. |
| e2e `.c` slices using `cq_phi` | **66** | rewritten to the new surface; the Grover slices' "oracle: mark \|5>" headers become TRUE |
| e2e goldens containing `cqrt_rz` | **63** (30 with `_controlled`) | regenerated; the diff is audited (§10.2) |

### 6.5 Fixtures, slices, gates

- Red-green per Rule 12: every row of §6.2 gets an accept fixture and every row
  of §6.3 a `RUN: not` decline mirroring the string.
- New slices: `slice_control_phase_grover{,_loop,_loop_unrolled}` (the correct
  oracle), `slice_control_phase_perbit_loop{,_unrolled}` (D4's idiom, K=4 and
  K=32 — the replacement for a deleted capability), `slice_control_phase_nest`
  vs `slice_control_phase_andcond` (byte-identical by construction),
  `slice_control_phase_angle_select{,_runtime_arms}`.
- Twin gates (`cmp`): rolled vs unrolled for the loop pairs; nest vs `&&`.
- `e2e-loop-twin-matrix`, `inplace_twin_matrix`, `angle_select_twin_matrix`
  re-run; cells whose Rz stem changes are regenerated with the pre/post tables
  committed as a PAIR (the Inc-4 precedent).

## 7. Increment 2 — value arms by controlled-copy merge

> **STATUS (2026-09-06). LANDED on `main`** as ONE squash commit — the squash of
> branch `3qlq-inc2`, whose tip is recorded in the landing commit message (`git log
> main -1` shows the hash) — **after the independent Rule-13 clearance returned
> `CLEAR-WITH-OWNER-QUESTIONS`** (record:
> `inc1-records/session-adc5590a/inc2/clearance_inc2.md`). Full landing summary and
> every measured figure: **§0 E12**. History: implemented on branch `3qlq-inc2`,
> **rebased onto the landed `a3c1513`** (notes §3), Rule-13 reviewed **twice** —
> round 1 (notes §1) and round 2 (notes §4) — with round 2 CLEAR on the mechanism
> (0 RCDIFF / 0 DIAGDIFF over the 1673 fixtures common to `main`, zero value-path
> `cqrt_cswap`, per-fixture `cqrt_rz_i1` / `!cq.branchphase` parity, four `cmp` twin
> gates, and a 15 × 7 injection matrix with 0 NOT CAUGHT), then cleared (notes §5)
> and landed. **With Inc 1 this fully retires the swap route:** `cqrt_cswap` is
> minted by the 7.2 `AbortParkEmit` alone (`emitRoute` = ONE call site,
> `AbortParkEmit.cpp:396`; 1 of 319 goldens). Round 2's one LEAK (F-I2-1) is
> PRE-EXISTING on `main`, is not introduced here, and is filed out of this epic as
> bd `test_C_libtooling-7yd0` (C-1 round 4, in flight on branch `c1-round4` at THIS
> landing and **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash)); Inc 2's only relationship to it is that its value-arm merge
> is a FOURTH producer of the rail shape (E11) — and the round-4 rebase MEASURED
> that fourth producer rather than arguing it (E12's `7yd0` bullet). The sections below are the
> DESIGN as written; where they and the errata disagree, §0 wins.

### 7.1 The shipped stream, and the replacement

`slice_control_value_diamond` (`if (q > 5) { p = p+3; p = p*5; p = p^9; p = p+1;
p = p*7; p = p^2; }`), per arm today: `alloc w; cswap(f,p,w); 6 ops on w;
cswap(f,p,h9); alloc out; copy(p,out); cswap; 6 _unc; cswap; free w; strip; free f`
— **4 `cswap_W` (= 4W Toffoli + 8W CNOT), 1 `copy_W` (W CNOT), one work rail**.

After: `6 ops on p → h9; alloc out; copy_controlled(f, h9, out); x(f);
copy_controlled(f, p, out); x(f); 6 _unc; strip; free f` — **2 `copy_controlled_W`
(2W Toffoli), no work rail**. The arm's ops run twice in both.

> ⚠ **ERRATA (same finding as §3's).** "`6 _unc`" is the design intent and not
> what ships: the chain final `h9` is left allocated and dirty, and the interior
> links are reversed but **not as five `_unc` calls** — see §0 **E1a** for the
> shipped count, taken from the golden. *(This sentence read "it is **5** here —
> the interior links" until 2026-09-06; the clearance's record item R-1 measured
> that 5 is not the count of anything in the trace. The flagship golden's interior
> rail is discharged by ONE `cq_template_mul_i32_hl_unc` + TWO in-place adjoints +
> ONE free, because M-C converts the `add`/`xor` links IN PLACE on the fresh
> intermediate rails, and an in-place link is reversed by an in-place adjoint, not
> by an `_unc` call. Count it in the golden, never here.)* Two further deltas from this sentence, both measured and
> both `lowerOps` consequences of hoisting the links as ordinary instructions
> rather than emitting a gate stream: (i) the hoisted chain is NOT all
> out-of-place, because M-C converts `add`/`xor` links IN PLACE on the FRESH
> intermediate rails (never on `p`, which always has a later reader — that
> disposition is now pinned by `control_swap_value_ifelse_head_out_of_place.ll`);
> and (ii) the emitted stream is byte-identical to the manually pre-hoisted
> `select` twin BECAUSE of (i), so forcing the chain out of place would break the
> increment's own witness.

The tree already does this INCONSISTENTLY: `-O1` speculates a short pure arm into
a `select` itself, so a one-op arm takes `SelectMergeEmit` and a six-op arm takes
the swap route — same source semantics, two mechanisms, chosen by SimplifyCFG's
cost threshold.

### 7.2 Accept shapes

| # | shape | mechanism |
|---|---|---|
| V1 | flat value diamond (`if (c) p = R(p)`), derived bases included | hoist chain to pred; two controlled copies; `_unc`; strip |
| V2 | if/else value arms (`R1` / `R2`) | both chains hoisted; `out ^= f?R1(p):0; out ^= ¬f?R2(p):0` |
| V3 | switch, homogeneous value (4.5) | preload `copy(p, out)`; per case `d_i = R_i(p) ^ p` (QQ xor), `copy_controlled(f_i, d_i, out)`, uncompute `d_i`, `R_i` — the 4.5 data-mux "preload + XOR-delta" precedent, no conjunction flag |

`SwapRouteEmit`'s value path and `SwitchValueEmit`'s route are replaced;
`cqrt_cswap` is then minted only by `AbortParkEmit` (7.2).

### 7.3 Unchanged preconditions and declines

§3c clobber (arm rewrites a register the condition reads); arm ops restricted to
the pure total template set (no calls, no memory); in-loop value arms keep the
loop decline (follow-on); mixed arms decline.

### 7.4 Witness

**Byte identity with the `?:` twin**: `p = c ? R(p) : p` (with `R` an inline
function so the chain is straight-line) arrives as a `select` and lowers through
the Rule-13-cleared `SelectMergeEmit`; the diamond form must emit the identical
stream. `cmp` twin gates on ≥3 pairs (one-op, six-op, if/else). Goldens
touched: `slice_control_value_diamond`, `slice_control_switch_value` and every
other value-arm golden (measure with `grep -l cqrt_cswap tests/e2e/*.expected.log`
minus the abort and phase ones — 2 at HEAD); lit fixtures mentioning `cqrt_cswap`:
227 at HEAD, most of them declines or prose; re-derive rather than hand-edit.

## 8. Increment 0 — docs + `cq_ry` (no pass change)

`CQ.h` macro; `frontend.md` §3.2/§3.3/§7 rewritten (linear rule, branch phase,
per-bit idiom, Grover as the worked example); `docs/backend.md` Rz row; a
`frontend-lit` fixture for `cq_ry`. `CLAUDE.md` gains the Grover finding in the
Correctness-Risk section and drops "Rz|0⟩ = |0⟩ for free" as a load-bearing
argument (it becomes history). Ships before Inc 1 so the semantics are written
down before the lowering exists (Rule 16).

## 9. Deferred / out of scope (with re-opening condition)

| item | re-open when |
|---|---|
| ~~Inc 1b: bare tainted `i1` condition (gate on the rail, no mint)~~ **DONE 2026-09-10, §13** | — |
| 1b-B (bd `test_C_libtooling-r9e5`): the 4.4 data select / value arm / 6.5 arm on a bare `_Bool` condition (copy merge controlled on the register) | a probe family for the borrowed flag |
| 1b-C (bd `test_C_libtooling-l4x4`): the in-place Ry arm / state prep / Ry-stem angle select on a bare `_Bool` condition | R4/S7–S9/the freeze re-argued for a BORROWED control |
| 1b-D (bd `test_C_libtooling-boi6`): a loop-CARRIED `_Bool` (the header-phi rail as a leaf, via `railPhiRootMint`) and a region-merge-phi rail | the C-1 in-loop budget (eight instances over six rounds) |
| negated rail level in the nest / NOT-carrying rail leaves / derived-`i1` (`trunc`) conditions (bd `test_C_libtooling-r903`) | the `Toff(¬a,b,g) = CNOT(b,g)·Toff(a,b,g)` lift; a NegL/NegR rail leaf; a mint+discharge flag for a derived rail |
| N `cq_phi` calls in one arm (angle sum) | an owner ruling on the rounding fence for sums |
| Q+Q compare condition mint | pre-existing; unchanged by this epic |
| freeing the value-arm SOURCE (`p ^= f ? R⁻¹(out) : out` with the flag alive past the merge — all existing symbols) | a customer that runs out of qubits |
| in-loop value arms | after Inc 2; the 8h7d.5 record says budget ≥3 rounds |
| deletion of the unemitted `cqrt_rz_<W>`/`_controlled` declarations | the Phase-11 freeze (Q1) |
| "Rz on qubit `i`" for the per-bit idiom | Phase-9 backend peephole over the fixed idiom `and(h,1<<i) → icmp eq 0 → x → rz_i1 → x → 2 _unc → 2 free` |
| a `-Rpass` remark when an uncontrolled `cq_phi` is deleted | Q2 |

## 10. Verification plan

### 10.1 Layers (Rule 19)
`ir-pass-lit` while iterating on the pass; the touched slices and twin gates for
goldens; the FULL suite before every commit (Rule-13 core, accept/decline
predicates change, templates untouched).

### 10.2 The golden audit (Inc 1)
Extend `tools/golden_multiset_audit.py` (the Inc-2a instrument): for each of the
63 regenerated goldens the diff must be EXACTLY one of — (a) the flat 2a
substitution `cqrt_rz_<W>_controlled(f, h, θ)` → `cqrt_rz_i1(f, θ)`; (b) the
routed quintuple `alloc(0)→w; cswap; rz_<W>(w,θ); cswap; free w` → the one
`rz_i1` line; (c) an uncontrolled `cqrt_rz_<W>(h, θ)` line DELETED; (d) the 2b
`rz(h,B); rz_controlled(f,h,A−B)` pair → the exact two-gate form — and nothing
else, handle renumbering aside. Any other diff is a finding.

### 10.3 Rule-13 lenses (per increment, ≥3 rounds budgeted)
The record for this file's neighbours is 4-for-4 on "the first adversarial round
finds a confirmed silent miscompile", and F2 took FOUR generations. Lenses:

1. **Kickback polarity** — `¬f` arms, the `select i1` spellings of NOT
   (`xor i1 %c, true`, swapped successors after `-O1` canonicalisation, Rule 9).
2. **Strip after a diagonal gate on the flag** — the compare `_unc` reads its
   OPERAND registers, which no phase arm touches; prove no path relabels them
   between mint and strip (a value op between is a mixed arm → decline).
3. **Compound-flag LIFO** — toffoli uncompute BEFORE leaf strips; an OR/XOR node
   minted onto a fresh ancilla must be freed after its uncompute, never before.
4. **P7's boundary** — a `cq_phi` that is neither claimed nor declined must be
   impossible; probe: `cq_phi` under a tainted `br` that `detectControl` declines
   (opt must exit non-zero, the call must NOT be deleted first).
5. **Angle select run-time arms (Rz only)** — the two stems now have DIFFERENT
   dispositions in one classifier; pin both directions (Ry run-time arm still
   declines; Rz run-time arm accepts; a `double` `ConstantExpr` arm still refused).
6. **In-loop per-activation** — the phase arm no longer relabels `q`; check that
   removing the rail collapse for phase arms does not silently widen the loop
   accept for MIXED loops (an Ry arm elsewhere in the same body).
7. **Migration audit** — a sample of ≥50 migrated fixtures re-derived from the
   pass, plus the `cq_opt_equivalence` full sweep; every deleted fixture's
   purpose recorded.
8. **Inc 2** — speculation totality (`sdiv`/`srem` by a tainted operand that is
   zero on the inactive branch: the template must be total; pin it), §3c
   coverage under the hoist, the select-twin byte identity, the switch XOR-delta
   with overlapping case values (impossible by `switch` semantics — assert).

## 11. Risks

- **The migration hides a semantic change.** 540 fixtures change meaning
  (an uncontrolled `cq_phi` used to be a gate that kept taint flowing and is now
  nothing). A fixture that was pinning a *lowering* of Rz keeps passing after the
  gate vanishes if its CHECKs are weak; hence "re-derive, never hand-edit" and
  the whole-file `NOROUTE`-style negatives.
- **Compound conditions are NEW core** for `br` regions (today they decline). P3
  is the largest new surface in Inc 1 and gets its own lens rounds.
- **The old goldens' story must be recorded, not erased**: the pre-3qlq Grover
  goldens encoded a controlled tensored Rz. Their `.c` headers get the finding;
  the `inc-records/` pair keeps the before/after tables.
- **Two RAUW conventions become one** (`drbq.10`): the Rz stem's M-α leaves
  `SwapRouteEmit`; only M-β (Ry) remains — a simplification that must be
  re-verified, not assumed.

## 12. Questions for the owner

- **Q1** — delete the unemitted `cqrt_rz_<W>` (W>1) / `cqrt_rz_<W>_controlled[_inv]`
  declarations now, or at the freeze? (PRD assumes: at the freeze.)
- **Q2** — emit an optimisation remark when an uncontrolled `cq_phi` is deleted?
  (PRD assumes: no diagnostic, documented semantic.)
- **Q3** — confirm run-time angle arms are ADMITTED for the Rz stem of the
  angle select, since no arithmetic is performed on them. (PRD assumes: yes.)
- **Q4** — bare-`i1` condition in Inc 1 or as Inc 1b? (PRD assumes: 1b.) **Answered by
  events: built as Inc 1b on 2026-09-10 (E14, §13).**


## 13. Increment 1b — the bare `_Bool` condition (bd `test_C_libtooling-3qlq.4`, 2026-09-10)

### 13.1 The shape, and why it is not a compare

`_Bool b = cq_theta(b0, θ); if (b) cq_phi(φ);` reaches the pass as `br i1 %b` where `%b`
IS the `@cq_theta_i1` call: a one-qubit REGISTER, with no compare to mint a flag from.
`clang -O1` produces it from every natural `bool` spelling — `if (b)`, `if (!b)`,
`if (b == 1)`, `if (b == 0)` (the last three by successor polarity, never by an `icmp`),
`if (b) cq_phi(A); else cq_phi(B);` (folded to ONE `cq_phi` whose angle is
`select i1 %b, double A, double B`), `if (b && q == 5)` (`select i1 %b, i1 %cmp, i1 false`),
`if (b == c)` (`xor i1 %b, %c`), and the owner's cascade `int a = 5; if (b0 == 1) a -= 3;
if (a >= 3) cq_phi(θ)`, which IPSCCP collapses to `br i1 %b0` outright (the HANDOFF of
2026-09-10, wall 3). Measured on `main` 170ede1: every one of these declined.

### 13.2 The lowering — the register is its own flag

The §3 kickback derivation reads `f = c(x)` in an ancilla, `P(θ)` on the ancilla, then the
compare's `_unc` to return it to `|0⟩`. With `c(x) = b` the ancilla would be a CNOT copy of
`b` — and `P(θ)` on a copy of `b` equals `P(θ)` on `b` itself (both are `diag(1, e^{iθ})` in
the `b` basis, and the copy is uncomputed afterwards). So the mint, the strip and the free
are all identity work: the gate belongs directly on `b`'s rail, ONE gate, nothing else.

Three emitters now do this, through ONE grammar change:

* **`CondTree::RailLeaves`** (`SelectClassify.h`): `collectCondTree` admits a leaf that is a
  `cq_theta_i1` call (`isCondRailLeaf`, deliberately that narrow — see 13.4). A rail may be
  the whole condition or a child of any node the grammar already knew.
* **`CondTreeEmit`** maps a rail leaf to ITSELF (`FlagOf[rail] = rail`): the node gates read
  the register as a CONTROL (`toffoli(h_b, f, g)`, `cnot(h_b, g)`) and mint nothing; the
  LIFO strip frees the node ancillas and the compare flags only. `CondNetwork::RootIsRail`
  tells a caller when the root is the user's register.
* **`SwapRouteEmit::emitKickbackGroup`** — ONE spelling of "fire `P(θ)` when `ctl == v`"
  for the flat kickback (arms and merge-tail incomings) and the nest (outer arm on its
  root, inner arm on the conjunction), and the same two-gate form in
  `AngleSelectEmit::emitPhaseAngleSelect`: on an ANCILLA the pre-1b stream verbatim
  (`x; rz…; x` for `¬ctl`); on a RAIL, `rz(h, θ)` for `ctl == 1` and **`rz(h, −θ)` for
  `ctl == 0`**.

**The polarity identity, and why it is the invariant and not a peephole.**
`X·P(θ)·X = diag(e^{iθ}, 1) = e^{iθ}·diag(1, e^{−iθ}) = e^{iθ}·P(−θ)` — the same unitary up
to the GLOBAL phase `e^{iθ}`, which owner decision D2 already declares unobservable (an
uncontrolled `cq_phi` is deleted on exactly that ground). `−θ` is `fneg`: exact in IEEE
for every double, constant-folded for a `ConstantFP`, no `fsub`, so none of the 2b
rounding class exists here. The reason to prefer it over the bracket is not elegance:
**no non-diagonal gate is ever emitted on a user's register by a phase emitter**, and
three predicates that read the lowered stream depend on that — `Uncomputation::
preservesBorrowedParent` admits an uncontrolled `cqrt_rz_` on a borrowed parent BY NAME
and fails CLOSED on anything it does not name (with a bracket, every chain borrowing the
register — a `zext`, a compare, an `add` — would freeze and leak; measured discharged in
`control_phase_kickback_rail_data_use.ll`), `ChainWalk::isInPlaceGateOn` deliberately
never recovers `cqrt_x`, and every wire fence in `ArmClassify` argues from "this region
emits no non-diagonal gate on any condition register".

**The spine.** The kickback gate is `!cq.branchphase`-recorded exactly as on a flag, so
`isInPlaceGateOn`/`preservesBasisUnderRecord`/`isInverseEmittable` refuse it, the
register's DAG is NOT CLOSED, and a DEAD register is LEFT ALLOCATED — the Rule-6
direction, and the right answer: `Ry(−θ)·P(φ)·Ry(θ)|0⟩ ≠ |0⟩`, so a free after an
"adjoint" would be a hidden measurement (`control_phase_kickback_rail_dead.ll`). A
measured register is the user's and was never the spine's.

### 13.3 The classifier ladder for a rail leaf (`classifyPhaseKickback` step 5b)

A rail leaf has no predicate, no template, no mint, no i1-operand, no in-`Pred`
requirement and no `ShareCondFlag` — none of the compare-leaf gates has a subject. What it
needs instead, each asked for the flat path, the nest (both levels) and the angle select:

1. **tainted** (by construction; defence in depth);
2. **not measured before the branch** (`railMeasuredBeforeBranch`: a `cq_measure` user in
   `Pred`, or in a block that dominates `Pred`; without a dominator tree any measurement
   outside `Pred` refuses) — the mirror of the compare's `MeasuredEarly`; a measurement
   downstream owns the register from there on, as for a compare;
3. **the wire question** (`railCondWireDisposition`): the SSA name the branch reads is
   stale iff a non-diagonal gate fires on the rail's wire between its def and the branch.
   `wireGainsNonDiagonalGate` — the SAME walker, the SAME `condProvenance` seed — with the
   DT prong: a gate not provably post-branch declines `condition predates a non-diagonal
   gate` (the stale-name spelling `%b = θ(u); %c = θ(%b, .25); br i1 %b`), a gate proven
   post-branch is admitted (`ProvenPostRegion` — the P1 argument: a kickback leaves nothing
   for a later gate to invalidate). Two prongs of the compare version are DROPPED because
   they have no subject: the same-block/positional scan (it bounds a compare→branch window;
   a rail's window is its whole wire, which the walk already asks — so a rail defined in
   another block ACCEPTS, `control_phase_kickback_rail_cross_block.ll`, where a compare is
   the documented `hoisted compare` over-decline) and the `ShareCondFlag` clause (nothing
   is minted, nothing outlives the region). A tree with rail leaves goes through
   `condWireDisposition` unchanged, the rails riding in `Prov`.
4. Its OTHER users are ordinary (it is the user's register): the tree-wide "used outside
   the branch" fence excludes rail leaves; the single-leaf `HasDataUse` machinery is not
   asked; the angle select's `hasOneUse` and plan-collision checks are skipped for a rail
   (two regions may share one register — `control_phase_kickback_rail_two_regions.ll`).
5. **In a loop (P6):** an INVARIANT `_Bool` lowers ROLLED with one `rz` per activation and
   NOTHING minted per trip, so the whole C-1 in-loop entangled-rail family has no subject
   (`slice_control_phase_bool_loop` == its hand-unrolled twin, 12 = 12 lines; a compare on
   an invariant register is the `hoisted compare` over-decline). A loop-CARRIED `_Bool` is
   a header phi, not a rail leaf — residual 1b-D.
6. **Nest:** a rail must be defined outside `Mid`/`InnerArm` (it is a rotation under the
   outer condition there, not a hoistable phase); a NEGATED level whose root is a bare rail
   declines — the conjunction `g = ¬a ∧ b` realizes a negated control by `cqrt_x`-bracketing
   it, and the identity `Toff(¬a,b,g) = CNOT(b,g)·Toff(a,b,g)` that would lift it with no
   gate on `a` is filed, not built.

### 13.4 The decline partition, and the one new string

* `branch phase on a bare i1 condition` SURVIVES for the non-register `i1` residuals and
  is thereby a discriminator: a `trunc`/`zext`/`sext` (a DERIVED rail that would need a
  mint+discharge design), a phi (loop-carried, or a region merge a preceding emitter
  dissolves), a template result, a clone `Argument`, a QRAM load, a negated rail level in
  the nest. `isCondRailLeaf` is `cq_theta_i1`-only on purpose.
* **`bare i1 register condition`** (`kBareRailCondReason`, `SelectClassify.h`) is the ONE
  string for a rail reaching a consumer that does not lower it yet: the 4.4 data select
  (`int a = 5; if (b) a -= 3;`), a value arm — bd `test_C_libtooling-r9e5` (1b-B) — the
  in-place Ry arm and state prep (`if (b) r = cq_theta(r, θ)`), the Ry-stem angle select —
  bd `test_C_libtooling-l4x4` (1b-C). Each follow-on flips its own fixture and no other.
  The loop-carried `_Bool` and the region-merge-phi rail are bd `test_C_libtooling-boi6`
  (1b-D); the negated nest level, NOT-carrying rail leaves and derived-`i1` conditions are
  bd `test_C_libtooling-r903`.
* `condition measured before the control route` / `condition predates a non-diagonal
  gate`: 13.3 items 2 and 3, the compare path's strings, unchanged.

### 13.5 Measured (2026-09-10, branch `3qlq-inc1b-rail-cond`)

* Probe family: 20 + 15 + 4 plain-C `bool` programs (`inc1-records/session-3qlq4/`).
  On `main` 170ede1 every `bool`-conditioned shape declined; on the branch the kickback
  family accepts (diamond, negated, folded if/else, `&&`/`||`/`==` trees incl. De Morgan
  rewrites, dead register, post-region Ry, cross-block rail, two regions on one register,
  nest at either level, invariant-register loop rolled, one-qubit Grover flat) and the
  select / value / Ry / state-prep / loop-carried / negated-nest shapes decline with the
  strings above. Every accept is STRICT stage-2b clean.
* `ir-pass-lit`: 1707 → **1738** fixtures (+31: 18 accept, 14 decline incl. the round-1 four and the round-2 pair; the old
  `reject_bare_i1` `git mv`'d and rewritten), exactly TWO pre-existing fixtures moved: that
  discriminator, and `control_inplace_ry_reject_raw_i1_cond.ll`'s string (`control flow` →
  `bare i1 register condition`, disposition unchanged) — found by the full `ctest -j6`
  (376/377, that one entry), because the `classifyArms` message change post-dated the
  earlier full `lit` run. ctest **367 → 377** (`^e2e-` 357 → 367, `^e2e-slice-` 321 → 330,
  `twin-identical` 26 → 27), goldens 323 → 332.
* No new runtime symbol, no ABI change, `tools/`, `runtime/`, `include/` untouched (D3).
* `cq-opt` vs stock `opt` full equivalence sweep (required after a diagnostic-surface change):
  `cmake --build build --target cq-opt-equivalence-full` → **1736 fixtures, 0 mismatches** (after the round-1 fix).

### 13.6 Rule-13 round 1 (2026-09-10, `inc1-records/session-3qlq4/review_1b_r1.md`) — BLOCK, fixed

The independent lens returned **BLOCK on one CONFIRMED silent miscompile, F-1b-1**, plus
one SUSPECTED, two DOC items and an over-decline list; the probe families that found
nothing (the polarity identity on 14 shapes incl. every merge-tail polarity and three rolled
loops; the spine on 12 borrowed-rail shapes; 5/5 rolled == unrolled pairs; Rule 1's no-third-
path over every arm class; `main`-vs-branch over all 1707 pre-existing fixtures = 1 RCDIFF /
2 DIAGDIFF / 1 OUTDIFF, both intended) are its negative space.

**F-1b-1 (CONFIRMED, plain C, `opt` exit 0, verify-clean, stage-2b clean; `main` declined).**
`int q = cq_theta(0,.3); bool t = (bool)(q & 1); bool b = cq_theta(t,.5); bool c =
cq_theta(t,.9); if (b) cq_phi(.7); return cq_measure(c);` — `b` and `c` are SIBLING in-place
Ry on ONE physical rail (both chained on the template result `t`), the branch reads the
STALE name `b`, and the first build emitted `ry(h,.5); ry(h,.9); rz(h,.7)`: byte-identical to
the stream for `if (c)` and for the well-formed chain `c0 = θ(t,.5); c = θ(c0,.9); if (c)`.
**Root cause, PRE-EXISTING for the compare path:** `WireWalk::findNonDiagonalWireGate`'s
backward ancestry crossed a chained theta's arg-0 edge only when the parent was spelled
`cq_theta_`/`cq_phi_`, so a TEMPLATE parent stopped the closure at `b` and the sibling `c` —
a user of the PARENT, never of the seed — was invisible to every fence that asks the walker.
The `int`/compare twin (`if (zext(b) == 1)`) ACCEPTED on `main` with the same wrong stream
(the compare's positional prong starts at the compare, after the sibling). The header of
`railCondWireDisposition` had recorded "the positional prong is already what the
position-free walk asks" as the reason for dropping the prong — **measurably false**
(F-1b-4), and the sentence this record replaces.

**Fix (in the walker, not in the rail fence):** `findNonDiagonalWireGate` (and its
`collectWireValues` mirror) take an optional `const TaintSet *` and cross a chained theta's
arg-0 edge whenever the parent is TAINTED — the one relation `lowerRotations` decides
in-place-ness by (`Chained = taint.Tainted.count(arg0)`) — so the closure reasons about the
rail the lowering will build. Threaded to every condition-wire caller (the two flat
dispositions, `classifyArms`' routed base, the nest, `RegionTreeDetect`, both switch fences,
the 4.4 select's gate 2c, `declineStaleRecordOps`, `SwitchArmProve`); a null `Taint` keeps
the old ancestry for the per-activation `thetaOnPathTo` caller (parity recorded with bd
`test_C_libtooling-r903`). Monotone toward DECLINE. **Measured:** the rail (same-block and
cross-block) and the compare twin decline; 13 accept controls (chained-after, dead, loops,
two regions, tail phi…) unchanged; **the whole lit corpus 1735 pass / 1 XFAIL of 1736 —
zero pre-existing fixtures flipped; the e2e layer 367/367 with ZERO golden churn**
(`git status --porcelain tests/e2e/*.expected.log` empty after the run).

**F-1b-2 (SUSPECTED → fixed):** `railMeasuredBeforeBranch` was dominance-based, so a measure
on a classically-guarded side path accepted; now `isPotentiallyReachable(measure, branch)`.
**F-1b-3 (DOC → fixed):** the phase-stem angle-select erase site gained the
`!isCondRailLeaf` guard the three flatten sites have. **F-1b-4 (DOC → fixed):** both
false justifications rewritten in place. **F-1b-5:** the over-decline list, all as
documented. Four fixtures pin the round: `control_phase_kickback_reject_rail_sibling_theta
{,_crossblock}.ll`, `..._reject_sibling_theta_template_parent_cmp.ll` (the pre-existing half,
declining in the opcode layer on the stale `zext`), `..._reject_rail_measured_sidepath.ll`.
Reproducers: `inc1-records/session-3qlq4/review_1b_r1_probes/`.

### 13.7 Rule-13 round 2 on the fix (`review_1b_r2.md`) — CLEAR-WITH-ITEMS

The widening is **decline-monotone**: analytically (the new crossing adds only NON-theta
values to the per-seed exempt set, so no previously-flagged gate can become exempt; `Work`
only grows; `gateIsHarmless` is untouched) and measured (**0 RCDIFF / 0 DIAGDIFF / 0 OUTDIFF
over all 1732 pre-existing fixtures; 19 movers over 124 plain-C programs, every one
accept → decline; Rule 1 clean, 65 accept / 59 decline, no surviving `@cq_*` call or tainted
`br`**). It closes a CLASS: compare, cast, 4.4 select-merge, in-place-`xor`, 4.5 switch-mux
and QROM parents all accepted a sibling theta pre-fix and decline now; the accept boundary
is pinned by 11 pre-existing fixtures (a blanket-refusal mutant reddens them). Four items:

* **F-1b2-1 — CONFIRMED, PRE-EXISTING (identical on `main`), filed as bd `test_C_libtooling-3d8q` (P1).**
  `int b = cq_theta(q,.5); int c = cq_theta(q,.9); return cq_measure(b) + cq_measure(c);`
  — one line, no control flow — lowers as the well-formed chain (byte-identical). The
  pass-wide stale-record guard sweeps PURE ops only (`inLowerOpsScope`); a `cq_theta` or
  `cq_measure` READER of a stale name is never asked, so the (now correct) walker is never
  called for it. CLAUDE.md's own 8h7d.5 F-3 shape accepts out of loop. Fix sketch in the
  issue; it is a Rule-13-core widening of `declineStaleRecordOps` and gets its own round.
  **F-1b2-2** is its in-loop member: the rolled spelling accepts (the condition IS fresh per
  trip) while the hand-unrolled twin now declines on the stale condition — a disposition
  split that closes with that fix.
* **F-1b2-3 — fixed.** `collectWireValues`' new `Taint` parameter had NO caller supplying
  it (file-local, one 3-arg caller), so "the mirror" half of §13.6's fix was inert — the
  parameter is DELETED and the prose restated: `thetaOnPathTo`'s closure keeps the narrow
  ancestry on purpose, because its only consumer `phiTracksWire` GRANTS on it (an
  accept-direction predicate; the parity gap stays on bd `r903` with its own round).
* **F-1b2-4 — fixed.** The rewritten `railCondWireDisposition` header covered the
  same-wire half only; the compare path's positional prong also targets a theta on
  ANOTHER wire aliasing the rail through a dtzb in-place `add`/`xor`, which no walk
  crosses. The rail path drops the prong on a STRUCTURAL ground now stated in the header
  and pinned: a condition rail is always read later by its own branch, so M-C's G6 refuses
  the in-place conversion and the `xor` lowers OUT of place onto a fresh rail
  (`control_phase_kickback_rail_inplace_xor_bridge.ll`, accept, with the lyyf
  warn-and-lower on stderr); the compare spelling over-declines
  (`..._reject_cmp_inplace_xor_bridge.ll`, pre-existing, pinned as the asymmetry).
* **F-1b2-5 / OQ-1b-R2-4:** the stricter reachability fence stays; `p20` (the side-path
  measure) is the documented over-decline, pinned by `..._reject_rail_measured_sidepath.ll`.

Fixture count after both rounds: **1738** (+31 over 1707: 18 accepts, one of them the
rewritten discriminator, and 14 declines, one duplicate dropped). Probes:
`inc1-records/session-3qlq4/review_1b_r2_probes/` (57 files + harnesses).

## 14. Increment 1b-B.1 — the 4.4 DATA select on a bare `_Bool` (bd `test_C_libtooling-r9e5`, 2026-09-10)

### 14.1 The shape, and why §13 left it declining

`_Bool b = cq_theta(b0, θ); if (b) a -= 3;` reaches the pass as `select i1 %b, i32 2, i32 5` — the
register ITSELF as the select's condition, with no compare anywhere in the module. `clang -O1` produces
it from every `bool`-guarded straight-line assignment: `if (b) a -= 3`, `b ? q : 9`, `b ? q : p`,
`b ? 1.5 : 2.5`, `b ? c : d` over three `_Bool`s, `(b != c) ? 2 : 5` (an `xor i1` root over two rails),
and the owner's own cascade `int a = 5; bool b0 = 0; if (a >= 3) b0 = cq_theta(b0,.5); if (b0 == 1)
a -= 3;`, which IPSCCP collapses to exactly that select.

§13 admitted the rail as a LEAF of the condition grammar (`CondTree::RailLeaves`, `isCondRailLeaf`) and
lowered it at the three REGISTER-FREE PHASE emitters only; every other consumer declined
`bare i1 register condition` (`kBareRailCondReason`), the 4.4 data select among them, as filed follow-on
1b-B. **This increment is the DATA-SELECT half of that follow-on.** The value arm (`classifyArms` →
`emitValueRegion`) and the 6.5 classical-call arm are 1b-B.2 and still decline —
`control_swap_reject_value_rail_cond.ll` is unchanged and green.

### 14.2 The lowering — the merge stream is the shipped one; only the FLAG changes

The §5a controlled-XOR copy merge (`SelectMergeEmit` steps 1–6, Rule-13-cleared, byte-pinned by the
`control_swap_select_*` fixtures and the `slice_control_select*` goldens) is emitted **instruction for
instruction unchanged**. What changes is where the flag comes from:

```
   bf = cqrt_alloc_i1(0)                    the copy flag, |0>
   cqrt_cnot(h_b, bf)                       Σ_x α_x |x⟩_b |x⟩_bf
   out = cqrt_alloc_<W>(0)                  the |0> result rail          ┐
   cqrt_copy_<W>_controlled(bf, T, out)     writes T iff x = 1           │ the shipped
   cqrt_x(bf)                                                           │ §5a stream,
   cqrt_copy_<W>_controlled(bf, F, out)     writes F iff x = 0           │ verbatim
   cqrt_x(bf)                                                           ┘
   cqrt_cnot(h_b, bf)                       bf back to x ⊕ x = 0
   cqrt_free(bf)                            a proven-|0> free (Rule 6)
```

**WHY A COPIED ANCILLA AND NOT THE REGISTER, and it is the whole design decision.** Step 4 must fire the
second copy on `¬flag`, and the project's only spelling of that is a self-inverse `cqrt_x` bracket. A
rail root is the USER'S REGISTER and may never carry a `cqrt_x` — bd memory
`diagonal-only-on-user-registers-3qlq4` names the three lowered-stream predicates that go wrong or
over-freeze: `Uncomputation::preservesBorrowedParent` admits an uncontrolled `cqrt_rz_` on a borrowed
parent BY NAME and FAILS CLOSED on anything it does not name (a bracket would freeze and leak every
chain that borrows the register — a `zext`, a compare, an `add`), `ChainWalk::isInPlaceGateOn`
deliberately never recovers a `cqrt_x`, and every `ArmClassify` wire fence argues from "this region emits
no non-diagonal gate on any condition register". §13.2's escape — the diagonal identity
`X·P(θ)·X = e^{iθ}·P(−θ)` — exists only for a DIAGONAL gate; a controlled basis COPY has no diagonal form
for its ¬-half. So the flag is copied out of the register instead, and the two gates that touch the
register are `cqrt_cnot(h_b, ·)` with it at ARG 0 — a READ-ONLY control, the SAME gate class §13's nest
already emits on a rail (`cnot(h_b, g)` / `toffoli(h_b, f, g)`, cleared in §13.6/§13.7). **No new gate
class on a user register, no new gate class in the merge, and no new frozen symbol** (owner D3:
`cqrt_alloc_i1`, `cqrt_cnot`, `cqrt_free` and `cqrt_copy_<W>_controlled` all already ship).

**The unitary (analytic — Rule 2).** `bf` is minted `|0⟩`; `cnot(b, bf)` gives `Σ_x α_x |x⟩_b |x⟩_bf`, a
basis-label COPY of a register that STAYS LIVE, so Rule 8 (which forbids freeing a superposed source by
copy+uncompute) has no subject. One copy fires per basis branch, `b` is untouched throughout (the copies
write `out`, the brackets act on `bf`), the second `cnot` returns `bf` to `x ⊕ x = 0` on EVERY branch,
and the free is clean. Net `|b⟩ ⊗ |out = b ? T : F⟩` — the SAME unitary the compare stream realizes with
`c(x) = b`, which is why every §5a invariant (the bracket SCOPE, the `cqrt_x` COUNT, the single free —
bd memory `swap-route-select-merge-invariants`) carries over untouched.

**A NON-ROOT rail leaf needs nothing new.** `(b != c) ? 2 : 5` is `xor i1 %b, %c`, whose tree ROOT is the
xor NODE: `CondTreeEmit` allocates its ordinary ancilla `%g`, writes it with two `cqrt_cnot` whose
CONTROLS are the registers, and the merge brackets `%g`. `RootIsRail` is false, no copy flag is minted.

**Where it lives.** `CondTreeEmit::emitCondNetwork` gains a trailing `bool CopyRailRoot = false` and
`CondNetwork` gains `RailRoot`/`RailRootFlag`, so the ONE network implementation serves 1b-B.2's
emitters too (Rule 14) and every phase caller — which must keep reading `RootIsRail` — is byte-unchanged.
With `CopyRailRoot && RootIsRail` the ancilla is minted AFTER the walk (a bare rail root has no nodes and
no compare leaves, so it is the only thing minted), `Out.Root` becomes the ancilla and `RootIsRail` goes
FALSE; `stripCondNetwork` strips it FIRST (it was minted LAST — exact LIFO).
`SelectMergeEmit`'s pre-emission `kBareRailCondReason` guard is INVERTED: if a rail root ever reaches
step 3 still being the register, bail LOUDLY with `control flow` (Rule 1 — never silently), because the
only alternative is a `cqrt_x` on a user register.

### 14.3 The classifier ladder for a rail leaf (`classifySelectRegion`)

Asked PER RAIL LEAF, root or not, with the **SELECT** as the read point (`SelectMergeEmit` inserts every
gate immediately before it). §13.3's ladder with one substitution, and that substitution is the increment:

1. **tainted** — by construction (`cq_theta_i1` IS the taint source); re-asked as defence in depth.
2. **not measured before the SELECT** — `railMeasuredBeforeReadPoint` (`ArmClassify`, generalised from
   §13.3's `railMeasuredBeforeBranch`; ONE spelling, three callers). String:
   `condition measured before the control route`. **THE READ POINT IS THE SUBSTITUTION.** The kickback's
   gate is emitted AT the branch, so §13 could treat any same-block measurement as "before"; this stream
   is emitted MID-BLOCK, so a same-block measurement must be tested POSITIONALLY. A measure AFTER the
   select is the ordinary downstream case and ACCEPTS (`control_swap_select_rail_measure_after.ll`,
   plain `-O1` C); one line earlier it declines (`..._reject_select_rail_measured_before.ll`). The two
   kickback callers pass `Pred->getTerminator()` and are byte-unchanged by construction — a
   `cq_measure` user is never a terminator, so a same-block one always `comesBefore` it. A measurement
   elsewhere is refused on REACHABILITY, not dominance (§13's F-1b-2 fix, inherited).
3. **the wire question, with the DT prong for RAIL seeds.** Gate 2c now builds TWO seed sets. COMPARE
   seeds keep the POSITION-FREE walk verbatim (the mint point is unrelated to the compare's own
   schedule, so no positional accept is possible), and with no rail leaves the set is the pre-1b-B `Prov`
   insertion-for-insertion — every compare-conditioned select is byte-unchanged. RAIL seeds get
   `railCondWireDisposition`'s spelling: position-free CLEAN ⇒ accept; else no `DT` ⇒ decline (Prime
   Directive — no tree, no proof); else re-ask `findNonDiagonalWireGate` with `EmitPoint = Sel`, so a
   gate not provably after every execution of the select declines and one PROVEN after it is
   `ProvenPostRegion` and ACCEPTS. The P1 argument transfers exactly: the copies read `b`'s basis label
   AT the select, the flag is minted, stripped and freed inside the stream, and nothing of the region
   survives on `b` for a later gate to invalidate. The same-block positional prong stays COMPARE-only,
   and the freeze fence runs over both sets.
   **What this buys, measured:** `if (b) a -= 3; b = cq_theta(b, -0.5);` — the S† the owner's Grover
   cascade writes — declined `condition predates a non-diagonal gate` on `main` and lowers now
   (`control_swap_select_rail_post_ry.ll`, `slice_control_select_bool_sdagger`). It is the same
   over-decline bd `lom0` Inc 4 removed for the flat PHASE region, one construct later.
   **What it does NOT buy:** a theta BETWEEN the rail's def and the select, a SIBLING theta on the same
   physical rail (the §13.6 F-1b-1 class, which the walker's tainted-parent ancestry sees), and any
   in-LOOP body theta (the back edge defeats `provablyBefore`'s reachability half) all keep declining.
4. **its other users are ordinary** — it is the user's register. No `hasOneUse`, no `ShareCondFlag`, no
   "used outside the branch" fence: nothing is minted from it that could outlive the region, and the
   merge writes only `%out`. Two regions may share one register
   (`control_swap_select_rail_{two_regions,then_select}.ll`).
5. **Gates 4 (width), 5 (coherent operand, both halves) and 6 (operand alias) apply UNCHANGED.** They ask
   about the select's RESULT TYPE and its ARM OPERANDS, never about the condition; a rail CONDITION with
   a downstream rotation is fine, exactly as a compare's register is. No "arm operand aliases the
   condition rail" fence was added and none is owed: with the ancilla form the control `f` and any source
   are distinct rails, and `copy_c(f, h_b, out)` is CASE A of the aliased-operand ruling (bd `big5`).
6. **The angle hand-off ORDERING is preserved.** The rail rungs run BEFORE gate 3, so the Rz-stem angle
   select on a rail still reaches `classifyAngleSelect` and lowers (`control_angle_select_phase_rail.ll`)
   and the Ry stem still declines `kBareRailCondReason` INSIDE that classifier (1b-C, bd
   `test_C_libtooling-l4x4` — `control_angle_select_reject_rail_ry.ll`).
7. **`AllowLogicalSelect` stays FALSE for the data select**, so `b && q == 5` as a DATA-select condition
   keeps declining `control flow` (`control_swap_reject_select_i1sel_combinator.ll`). Filed, not built.
8. **In a loop:** an INVARIANT rail lowers ROLLED with the whole merge inside the intact body — a FRESH
   copy ancilla, a FRESH `|0⟩` out rail, and its own free per activation, so nothing accumulates across
   the back edge and the C-1 in-loop entangled-rail family (bd `7yd0`) has no subject. Rolled ==
   hand-unrolled, **39 = 39 lines** (`e2e-select-bool-loop-twin-identical`).

### 14.4 The decline partition

* `kBareRailCondReason` (`bare i1 register condition`) SURVIVES and stays a discriminator: the VALUE arm
  and the in-place-Ry / state-prep arms (1b-B.2, bd `test_C_libtooling-r9e5`) and the Ry-stem angle
  select (1b-C, bd `test_C_libtooling-l4x4`). It no longer fires for the data select — that fixture is
  `git mv`'d to `control_swap_select_rail_const.ll` and rewritten as the accept its header anticipated.
* `condition measured before the control route` — rung 2 (same-block-before, or reachable side path).
* `condition predates a non-diagonal gate` — rung 3 (a stale sibling or chained theta, or any in-loop
  body theta on the condition rail).
* `control flow` — a condition that is NOT a rail leaf: a `trunc`/`zext`/`sext`, a `phi` (loop-carried,
  bd `test_C_libtooling-boi6`; or a region merge), a template result, a clone `Argument`, a QRAM load.
  `isCondRailLeaf` is `cq_theta_i1`-only on purpose (§13.4), and MEASURED: admitting an i1 `trunc`/`phi`
  reddens SIX fixtures across all four consumers of the shared predicate.
* The emitter's drift guard is now the OPPOSITE assertion and declines `control flow` if a rail root
  reaches step 3 unwrapped — never silently (Rule 1).

### 14.5 Measured (2026-09-10, branch `3qlq-inc1b-b-rail-select`)

* **The owner's program compiles.** `example/grover/grover_oracle_uncompute.c`'s `main()` as of the
  session-3qlq4 close declined `bare i1 register condition` on `main` 87d0699 and now lowers to 15 trace
  lines, stage 2b `1 verified, 0 violation(s), 0 unproven`. Committed verbatim as
  `tests/e2e/slice_control_select_bool.c`.
* Probe family: **33 plain-C programs** (29 from the build + the F-B1-1 family `m1`–`m4`) (`inc1-records/session-r9e5/probes/`, with a PRE/POST table).
  13 accept shapes move DECLINE → ACCEPT, 5 decline shapes keep or sharpen their string, and the
  orchestrator's `k1`/`k2`/`k4` controls do NOT move. Every ACCEPT is STRICT stage-2b clean.
* `ir-pass-lit`: 1738 → **1759** fixtures (+21 net: 13 accepts and 9 declines, one of the accepts being
  the `git mv`'d discriminator; two of the declines are F-B1-1's, §14.7). `lit -s ir-pass/test` → 1759
  discovered · 1758 passed · 1 expectedly failed · 0 unexpected. **Exactly ONE pre-existing fixture moved** — the `git mv` target — measured by a
  full corpus diff of return code + stdout + stderr over all 1738 pre-existing fixtures:
  **RCDIFF 1 · DIAGDIFF 1 · OUTDIFF 1, the same file all three times.**
  Re-run after the F-B1-1 fix over the 1759 files on disk: every differing file is a NEW fixture
  (13 accepts, 4 declines whose string sharpened) and **0 / 0 / 0 over the pre-existing set** (the
  `git mv`'d discriminator is no longer on disk to differ).
* ctest **377 → 385** (`^e2e-` 367 → 375, `^e2e-slice-` 330 → 337, `twin-identical` 27 → 28); goldens
  332 → **339**; **ZERO pre-existing golden churn** (`git status --porcelain tests/` lists only new
  files and `CMakeLists.txt`). `ctest -j6 -R '^e2e-'` **375/375**; `ir-pass-lit` Passed;
  the other 9 entries Passed; the full `ctest -j6` after the F-B1-1 fix **385/385, 458.8 s** (under
  concurrent review load — not a quiet-box figure).
* Injection matrix over the 13 accepts × 11 mutations = **143, 0 MISSED / 0 DIRTY** — after the first run
  read 1 MISSED: on the two-select fixture a BRACKET SLIDE in region 1 slid into region 2 and satisfied a
  seven-entry `ORD` block. Fixed by pinning the full fourteen-entry stream. *An `ORD` block is only as
  strong as the number of regions it covers.*
* `cq-opt` vs stock `opt` full equivalence sweep (required after a diagnostic-surface change):
  **1757 fixtures, 0 mismatches** before the F-B1-1 fix and **1759 fixtures, 0 mismatches** after it
  (`cmake --build build --target cq-opt-equivalence-full`).
* No new runtime symbol, no ABI change; `runtime/`, `tools/opcode_table.yaml` and `include/` untouched.

### 14.6 Owner questions

1. **`p09`'s reclassification.** The brief scoped `if (b) a = a + 3` on a quantum `a` as 1b-B.2's value
   arm. MEASURED, `-O1` HOISTS the add and folds it to a DATA select with two tainted operands — this
   sub-increment's shape — and its COMPARE twin has accepted through that path since 4.4 shipped. B.2's
   real population is the shapes `-O1` leaves as diamonds with a merge φ; worth re-scoping against
   measured `-O1` output rather than source syntax.
2. **The side-path measure over-declines.** Rung 2 refuses on REACHABILITY, so a program whose classical
   guard is never taken declines anyway. Inherited from §13 (OQ-1b-R2-4), not widened here.
3. **The borrowed-parent freeze.** `Uncomputation::preservesBorrowedParent` refuses `cqrt_cnot` (it fails
   closed), so a chain borrowing the condition register now sees two unrecognized users where a
   compare-conditioned select left none. That is the LEAK direction (Rule 6 safe) and matches §13's
   disposition for a rail under a kickback, but it is a real cost; widening the row to an uncontrolled
   `cqrt_cnot` whose TARGET is not the parent is a Rule-13 change and was NOT made.
4. **`AllowLogicalSelect`** stays off for the data select (`b && q == 5` as a data condition keeps
   declining) — the shipped decline fixture is untouched and widening it is a separate increment.

### 14.7 Rule-13 rounds

**F-B1-1 (orchestrator, on the first B.1 build, 2026-09-10 — plain-C reachable, CONFIRMED, fixed
before the independent round).** Rung 2's read-point helper returned `M->comesBefore(ReadPoint)` for
a same-block measure and never asked reachability, so `for (i…) { int a = b ? i : 5; acc +=
cq_measure(a) + cq_measure(b); }` — the select stays in the loop body because its arm is
loop-VARIANT — ACCEPTED (exit 0, verify-clean, STRICT 2b `0 violation(s)`), with every activation
after the first controlling its copies on a register the previous trip had COLLAPSED: a post-measure
gate, Rule 6's loud-reject class, which the kickback's block-terminator read point refuses on the same
program. Fix: the same-block shortcut is deleted and `isPotentiallyReachable(M, ReadPoint, nullptr,
DT)` is asked for every measure (LLVM answers the same-block case itself — before ⇒ true; after ⇒ true
iff the block can reach itself, false in the entry block or an acyclic one); the kickback callers are
unaffected by construction. Pinned by `control_swap_reject_select_rail_inloop_measure_after.ll` (the
plain-C module) and `..._constarm.ll` (hand IR — `-O1` LICM-hoists a constant-arm select out of the
loop, where the measures are genuinely downstream and `..._rail_measure_after.ll` accepts). **The
COMPARE twin of that program accepts on `main`**: the 4.4 compare-select classifier has NO
measured-before rung at all — PRE-EXISTING, filed as bd `test_C_libtooling-r10v` (P1), not this
increment's. The lesson is 8h7d.5's once more: the read POINT was parameterised (a widening), and the
same-block clause was a second predicate over the same closure that was not re-derived with it.
Record: `inc1-records/session-r9e5/IMPL_B1.md` §8, `probes/m1`–`m4`.

**Round 1 (independent, opus; `inc1-records/session-r9e5/review_b1_r1.md`) — CLEAR-WITH-ITEMS.**
108 adversarial programs (65 plain C at `-O1`, 43 hand IR) on both binaries: 63 movers, ALL
DECLINE → ACCEPT, 0 accept → decline; the 13 that accept on both byte-identical below the module
header; an independent whole-corpus differential over the 1737 pre-existing fixtures 0/0/0; a
mechanical scan of all 58 accepted lowered modules found zero `cqrt_x`/`cqrt_free`/`cqrt_cswap`/
target-slot `cnot`/`_unc` on any rail carrying a `cqrt_ry`, every `cnot` control use evenly paired.
The DT prong was attacked from six directions and held. Four items, every one acted on in the fix
round (uncommitted at the time of the round-2 review; landed with the increment):

* **F-B1R1-1 — OVER-ACCEPT-ARGUED, PRE-EXISTING and shared with §13's kickback (plain-C reachable).**
  The 8h7d.5 question asked of this increment's own widening: rung (ii)'s measure set was the rail's
  SSA NAME (`Rail->users()`) while rung (iii)'s gate set is the rail's WIRE (the walker closes each
  seed backward through chained-theta arg-0 hops). So `bool b0 = 0; b0 = cq_theta(b0,.5); bool b =
  cq_theta(b0,.3); int m = cq_measure(b0); int a = b ? 2 : 5;` — `b` and `b0` are ONE register
  after `lowerRotations` — accepted, emitting `cqrt_measure_i1(h0)` immediately followed by the
  merge's `cqrt_cnot(h0, …)`; the kickback twin gave the identical trace on `main` (the helper is
  shared; bd `3d8q`/`r903` are the neighbouring classes). Graded ARGUED rather than CONFIRMED
  because the emitted order is faithful to the source and the defect is in the FENCE the project uses
  to refuse the whole class. **Fixed in the shared helper, both callers at once:**
  `railWireNamesBackward` (the rail, each chained ancestor theta while its arg-0 is TAINTED —
  `lowerRotations`' own `Chained` relation — and the first non-theta tainted parent, collected and
  not entered, since its operands are other rails; forward names are rung (iii)'s subject) and
  `railMeasuredBeforeReadPoint` asks its question over that closure. Re-running the reviewer's
  108-program corpus moves exactly `r02`, `r22`, `h14` (select) and `r21`, `r41` (kickback), all to
  `condition measured before the control route`; nothing else moves. Pinned by
  `control_swap_reject_select_rail_measured_{parent_name,parent_before_chain,template_parent}.ll`,
  `control_phase_kickback_reject_rail_measured_parent_name.ll` (an ACCEPT on `main` b00fdc2) and the
  STOP pin `control_swap_select_rail_other_register_measured.ll` (a measurement of the cast's SOURCE,
  a different rail, still accepts). Probes `n01`–`n05`.
* **F-B1R1-2 — ITEM (forward-looking, unreachable today).** The emitter's old rail decline was a
  caller-independent backstop for THREE callers; its `RootIsRail` replacement is dead code, and
  `SwapRouteEmit::emitValueRegion` builds its own `SelectRegion` and calls the emitter directly,
  bypassing the rail ladder — safe today only because `classifyArms` is `CmpInst`-only, which bd
  `fg9k` is defined to widen. **Fixed with a real tripwire:** `ControlRegion::RailLadderProven`, set
  by `classifySelectRegion` on ACCEPT iff the tree carries a rail leaf; `emitSelectRegion` refuses a
  rail-carrying tree without it, with the original `bare i1 register condition` string, before any
  emission. B.2's brief carries it as a stated precondition.
* **F-B1R1-3 — DOC.** The F-1b2-4 structural ground ("a condition rail is always read later by its
  own branch") is inherited by the select, holds (the xor bridge lowers out of place, the second Ry
  moves the fresh rail), and had one pin. Now named for both consumers in
  `railCondWireDisposition`'s header and pinned at the select by
  `control_swap_select_rail_inplace_xor_bridge.ll`.
* **F-B1R1-4 — DOC.** `IMPL_B1.md`'s table said 1757 where the tree had 1759; annotated.

Lit corpus after the fix round: **1765** (+6: 4 declines, 2 accepts).

**Round 2 (independent, opus; `review_b1_r2.md`) — BLOCK.** The round-1 fix itself was re-derived
and attacked and held: `railWireNamesBackward` follows exactly `RotationLowering`'s `Chained` edge
(compared clause by clause with `WireWalk::collectWireValues`), its stop is right in both directions,
a whole-corpus differential over all 1765 fixtures moves exactly the 23 new B.1 files and 0 others,
`lit --filter rail` 118/118, all 17 pre-existing kickback/nest rail accepts unaffected, 76 fresh
programs (26 C, 47 hand IR, 3 two-TU) with 0 accept → decline. Then the "fifth thing":

* **F-B1R2-1 — CONFIRMED SILENT MISCOMPILE, plain C (two TUs), the round-2 TAINT WINDOW.** Two
  predicates ask "same physical rail?" about the same edge at two different times: the fence's
  closures (`railWireNamesBackward`; `findNonDiagonalWireGate`'s F-1b-1 crossing, both
  `Taint.Tainted.count(arg0)`) inside `detectControlRegions` at ROUND-1 taint, and `lowerRotations`'
  `Chained = taint.Tainted.count(Op)` at FINAL taint. `repropagateControlMerges` re-seeds from the
  6.5/4.5 `%out` rails (the emitters taint `%out` ITSELF, so a `%out` ARM is a handle — measured — but
  everything DERIVED from it becomes tainted only in the later round). In that window `int y = 5; if
  (q > 5) y = ext_f(7); int keep = cq_measure(y); bool x = (y != 0); bool b = cq_theta(x, .25); bool
  b3 = cq_theta(x, .9); int a = b ? 2 : 5;` is a SOURCE theta to the fence (sibling off the closure,
  rung (iii) clean) and a CHAINED theta to the lowering (both siblings on ONE rail). PRE: `bare i1
  register condition`. POST: exit 0, STRICT 2b clean, `ry(h5,.25); ry(h5,.9); cnot(h5,bf)` — the copies
  controlled on `Ry(.9)Ry(.25)|x⟩` while the condition names `Ry(.25)|x⟩`. Discriminators: `e05` (`x =
  trunc %q`, tainted at round 1) DECLINES on both; `e11` (an opaque classical seed that STAYS
  classical) accepts CORRECTLY as two separate registers; `e06`/`c/e02` are the rung-(ii) form
  (measure) of the same window. **PRE-EXISTING for the COMPARE select**: `e08` (hand IR) and `e13`
  (plain C, two TUs) accept on BOTH binaries with byte-identical modules — `main` b00fdc2 miscompiles
  that class today through the 4.4 compare select; filed as bd `test_C_libtooling-9pum` (P1), not this
  increment's. Nothing catches it: `declineStaleRecordOps` excludes select-condition compares and by
  its round-2 re-sweep the compare is erased; for the rail the stale consumer is the emitter's own
  `cqrt_cnot`; stage 2b sees perfect pairing; the golden would record a self-consistent stream. It is
  the standing lesson "a stage that runs ONCE has a round-2-FALSE premise" (F-L3-1, F-R1-1) one species
  over — a PREDICATE — and the third instance of the family. **Fix decided: option 1, re-verify, do not
  re-derive** (the bd `eqpx` (1b) tripwire pattern; option 2 is a PREDICTION of what round 2 will
  taint, option 3 costs `e11`): record every emitted rail READ (`TaintSet::RailCondReads` — the rail and
  the first emitted `cqrt_*` call reading it, at `CondTreeEmit`'s `CopyRailRoot` cnot / first node gate,
  `SwapRouteEmit::emitKickbackGroup` and `AngleSelectEmit`), and a stage after the round-2 fixpoint in
  BOTH entry points re-asks rungs (ii) and (iii) with FINAL taint and a fresh dominator tree, declining
  loudly with the same two strings. The kickback and nest inherit it from the shared sites. Measurements
  of the fix: §14.8.
* **F-B1R2-2 — DOC.** The helper's "no forward names" justification is right for `gateIsHarmless`
  leg 1 (if leg 1 accepted, no measure of the forward theta's result can precede the read); leg 2's
  barrier accept needs its own argument — every path from the forward theta to the read executes the
  seed's definition (a barrier), so the barrier sits between any such measurement and the control read
  (the reviewer's derivation; `a11`/`a17`/`j01`). Written at the helper.
* **F-B1R2-3 — DOC.** The closure's stop at a non-theta parent rests on M-C's G6/G7 in another file
  (a measured parent is always lowered out of place — `a09`), so it carries a written retirement trigger
  now, the F-B1R1-3 species.
* **F-B1R2-4 — LEAK, pre-existing.** A dead chain off `%out` or off a borrowed condition register is
  emitted forward and left allocated (`b07`, `d01`); the compare twins are byte-identical. Rule-6 safe.
* **F-B1R2-5 — DOC.** `RailLadderProven` is right and measurably unreachable from all three callers
  (`b01`–`b04`); it cannot go stale across `repropagateControlMerges` (a fresh plan per round; a
  round-1 select is erased by its own emitter). A sentence at `emitValueRegion`'s region build carries
  the precondition to bd `fg9k`.

### 14.8 The round-2 fix (re-verification under final taint) — measured

Built 2026-09-10/11 (`inc1-records/session-r9e5/FIX_B1_R2.md`; checkpoint a1e6d62). Eight files
under `ir-pass/`, +313/−12 lines, no new runtime symbol:

* `TaintSet::RailCondReads` — `(WeakTrackingVH Rail, WeakTrackingVH FirstRead)` per emitted rail read;
  `markRailCondRead` records at FOUR sites, and the fourth was found by the fix itself: inside
  `emitCondNode` (ANY node control — the 4.4 select's non-root rail leaf AND the 4.3 nest's conjunction
  toffoli, which `emitPhaseKickbackNestRegion` emits by calling `emitCondNode` directly and which, for
  an inner rail, is that rail's ONLY read: probe `w5`, `if (b) { if (c) cq_phi(θ); }` with `c` off a
  `%out`-derived seed, ACCEPTED on f8d29e8 with `ry(h,.5); ry(h,.9); toffoli(h,…,g)`), the
  `CopyRailRoot` cnot, `emitKickbackGroup` (flat and nest root), `AngleSelectEmit`. The
  `markBranchPhaseGate` lesson again: every emission site, or none.
* `reverifyRailCondReads(M, taint)` (`ArmClassify.cpp`) — after `repropagateControlMerges` in BOTH
  entry points of `CQLoweringPass.cpp` (the `deleteGlobalPhases`/P7 slot), before `lowerRotations`;
  per-function cached `DominatorTree`; a nulled or cross-function entry is skipped; once per rail:
  rung (ii) `railMeasuredBeforeReadPoint(Rail, Read, …)`, rung (iii) position-free ∧ position-aware
  `findNonDiagonalWireGate({Rail}, …, &taint)` under FINAL taint. Loud, final, anchored on the read
  point; no silent fallback. Sound after emission because the walker looks only for `cq_theta_`-prefixed
  users and `MeasureCalls` still holds the `@cq_measure_*` calls.

Measured: the whole lit corpus f8d29e8 → fix, `SCANNED=1773 MOVERS=5` — all five the NEW decline
fixtures (`0 → 1`), the **1765 pre-existing fixtures 0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF**, the three new
accepts byte-identical on both. Round 2's corpus (73 + 3 two-TU): `e04` (rung iii) and `e06` (rung ii)
ACCEPT → DECLINE, **`multi/e16` — the plain-C two-TU CONFIRMED MISCOMPILE — ACCEPT (29 lines, 2b
clean) → DECLINE**, `e13` (the compare twin, bd `9pum`) byte-identical, `e11` (the opaque seed) unmoved.
Three probes the brief expected to move did not, each measured: `e07` accepts and is CORRECT (the
sibling is AFTER the select; the emitted stream is source order — now the e2e accept slice
`slice_control_select_bool_round2_window`), `c/e02` already declined on f8d29e8 (`-O1` inlines its
`static f`, so the seed is a round-1 compare), `e11` is the intended accept. Round 1's 108: 0 movers;
`probes/`: 0 movers. Fixtures **1765 → 1773**: 5 declines each RED on f8d29e8 —
`control_swap_reject_select_rail_round2_{sibling_theta,measured_parent,plainc_twotu}` (the last is the
`clang -O1` + `llvm-link` stage-1 module of `e16`, because the e2e harness has NO decline mode),
`control_phase_kickback_reject_rail_round2_sibling_theta`, `control_phase_nest_reject_rail_round2_sibling_theta`
— and 3 accepts `control_swap_select_rail_round2_opaque_seed_accept`,
`control_phase_kickback_rail_round2_window_accept`, `control_phase_nest_rail_round2_window_accept`
(injection matrix 16 mutations, 0 MISSED). e2e +2 slices (`…_round2_window` two-TU accept,
`…_round2_opaque_seed`), goldens 339 → **341**, 0 pre-existing changed; ctest 385 → **387** (`^e2e-`
377, `^e2e-slice-` 339); `ir-pass-lit` Passed, `lit -s` 1773 discovered · 1772 passed · 1 XFAIL;
`ctest -j6 -R '^e2e-'` 377/377; full `ctest -j6` **387/387, 357.2 s**. Open (fix report §4): `e07`'s
accept re-derived by round 3; "one diagnostic per rail" (the reader stops at a rail's first decline —
true while every emitter reads a rail at contiguous positions); the compare select (bd `9pum`), for
which the record's shape was chosen so the extension is compare SEEDS, not a second stage.

**Round 3 (independent, opus; `review_b1_r3.md`) — CLEAR-WITH-ITEMS; the BLOCK is closed.** 54 fresh
programs (40 hand IR, 4 plain C, 10 two-TU); no new silent miscompile, no over-accept; the fix is
decline-monotone over the whole 1773-fixture corpus (`MOVERS=5`, its own declines, the other 1768
0/0/0); rounds 1 and 2's corpora reproduce line for line. It found ELEVEN more programs the fix closes
that nobody had written down — each exit 0 / verify-clean / STRICT-2b clean on f8d29e8 and declining
now, each with a byte-identical control — reaching all four recording sites and all four consumers:
a rail as condition AND arm, a non-root rail leaf in an `or`/`xor` tree, the nest's INNER level, the
Rz-stem angle select (two-TU plain C `m10` — the program the fix report had looked for and not found),
rung (ii) through kickback / nest / angle select, two rails in one node, one rail in two nodes, `e07`'s
shape inside a loop, a read whose block a round-2 flatten folds away. Three of them are now pinned:
`control_phase_nest_reject_rail_round2_inner_sibling_theta.ll`,
`control_angle_select_reject_phase_rail_round2_sibling_theta.ll`,
`control_phase_kickback_reject_rail_round2_measured_parent.ll` (corpus 1773 → **1776**). `e07`'s accept
was re-derived independently and is correct (the chained theta is in place, so `%b`/`%x` name one
register and the cnot lands before the sibling's Ry). One over-decline, intended: two selects on two
sibling rails of one round-2 wire (`r29`) now declines — its round-1 twin declines on all three
binaries, so the window is made consistent with the shipped disposition. Three DOC items, all written
at the stage header: **F-B1R3-1** the placement argument is not the soundness argument (four
`taint.Tainted` mutations run after the stage — `lowerIOSinks`, `lowerQramReads`, `lowerShadowMemory`,
`specialize`'s scrub — none re-opens the window, for reasons in other files: `propagateWorklist` taints
every user of a tainted value so a QROM/Shadow load at a tainted index is tainted at round 1, and a
classical-index Shadow access declines; a written retirement trigger); **F-B1R3-2** "loud and final"
is a property of the host tool's default diagnostic handler, not of the stage (`exit(1)` inside
`diagnose`; the `Diagnosed`/`bool` machinery is dead under `opt`); **F-B1R3-3** the re-ask seeds
`{Rail}` while the classifiers seed a `condProvenance` union — equal for a rail leaf, and the mixed-tree
gap is bd `9pum`'s half (0 reachable programs found).
