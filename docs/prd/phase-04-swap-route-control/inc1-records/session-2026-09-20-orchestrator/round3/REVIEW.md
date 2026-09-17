# Rule-13 round 3 — bd `zujr` (the LOOP-CARRIED HANDLE VARIABLE) — COMPOSITION

**Theme:** *a composition is not cleared by clearing its parts.*
**Reviewer:** independent, 2026-09-20, own git worktree, own build tree.
**Verdict: `CLEAR-WITH-ITEMS`. P1 count: 0. Six findings (1 × P2, 5 × P3).**

The headline is one sentence, and both halves are measured:

> **There is a NON-EMPTY composed accept surface — nine C programs that compile
> only when bd `zujr` and bd `tu9q` P0+P3 are BOTH present — and the tree's
> strongest instruments report ZERO on it.** The 2106-fixture corpus A/B produces
> **0 composition-only movers**; the 382-cell `loop_twin_matrix` verdict tables
> are **byte-identical** between the shipped binary and the composed one; the 390
> e2e slices differ on **0** rows. Every one of the nine programs looks correct by
> every instrument I have. That is exactly the evidence Rule 2 calls **necessary
> and not sufficient**, and it is the fourth consecutive session in which the
> composed surface is cleared by measurement and by no review.

---

## 1. The binaries — four, built sequentially at `-j4` in my own worktree

Every measurement below is keyed to one of these. Hashes taken with
`shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so` immediately after
each build; no binary was relinked under a running measurement.

| tag | commit | `cq-opt` sha256 | `libCQPass.so` sha256 | what it contains |
|---|---|---|---|---|
| **BASE** | `bfb809be` (`tu9q` P2 tip) | `7c1163ad94d0632007566867a4a71bc7de9377352cddc4158425e41532594326` | `1d814022640414225ffd4cc51907c573694d57ed0b97bc52d8ce11fed6f8ff48` | neither increment: no `zujr`, no `tu9q` P0+P3, **and no bd `6n1s`** |
| **MAIN** | `00c36e93` | `e7bbfd69a9e25d3832373b8418d24239a4ddebf79d75e9e3a9252c254e0192f2` | `84061321f9d6f9747b80a29e55210674d79411ad11c104f582cc76aac4622156` | the SHIPPED compiler — `zujr` + `6n1s` + `drbq.12` + (T4) + `vsr6` |
| **TU9QONLY** | `30b80d7f` (`tu9q-p0-p3-wip`) | `e951d5d1bc072902e28bc0fd8a5d2adf1468bab100c4f1164c4e8f5f5ed21a7e` | `4de7a269d91f44194c5e40ccb54d106eda9c4466c32559add8c6109c699a9b97` | BASE + `tu9q` P0+P3 |
| **COMPOSED** | `c35d3e03` (my merge) | `df25aafd5b40af08d7d5c5b02952c4a9a3ddadabe72f45c3e8d773f548cf99fc` | `ea9c76da432f0b4cb8d79a0fbd2bc5890df0bf96c855e3ba48fe788517af31cd` | MAIN + `tu9q` P0+P3 |

**Two reproducibility facts worth recording.** `MAIN` reproduced
`e7bbfd69a9e25d383237…` exactly as the brief predicted — the tree and the primary
binary agree. `TU9QONLY` reproduced `e951d5d1bc072902…`, the hash `30b80d7f`'s own
commit message cites for its measurements; that branch is reproducible from
source two days later.

**The merge.** `git merge 30b80d7f` onto `main` conflicts in exactly one place —
`ir-pass/include/LoopPlan.h`, where `zujr`/`6n1s` and `tu9q` P0+P3 each append a
declaration block at the same anchor. Resolved **additively** (both blocks kept,
no line of either edited); `LoopLowering.cpp` and `Uncomputation.cpp` auto-merged.
Both postconditions survive with their call sites intact:
`declineUndischargedMarkedBodyRails` at `CQLoweringPass.cpp:958/1372` and
`declineUndischargedExitObligations` at `Uncomputation.cpp:2082`.

---

## 2. The findings

| # | sev | finding | probe |
|---|---|---|---|
| **F-1** | **P2** | A composed ACCEPT surface exists, is nine programs wide, includes the owner's own live cascade plus one line, and is invisible to every gate in the tree. | `d1`,`d2`,`d3r`,`e3`,`i3`,`m4`,`n1`,`n2`,`o1` (+`d3` stream-only, `j2` decline-string-only) |
| **F-2** | P3 | `tu9q` P0+P3's own headline capability is **unreachable for a BANKED loop without `zujr`** — its intended customer works alone, the same program with `bool b0[N]` needs both. | `tu9q_ht_rolled` vs `d3r` |
| **F-3** | P3 | `tu9q` P0+P3 **alone** over-accepts the bd `6n1s` g8 shape. The parked branch predates `22a0ab11`; it must never land except on top of `6n1s`. | `i1_g8_carried` |
| **F-4** | P3 | The composition creates a **new rolled-vs-unrolled trace divergence on a newly-accepted module** that no twin-matrix cell and no quarantine entry covers. Benign by analysis; unadjudicated in writing. | `d3r` vs `d3ru` |
| **F-5** | P3 (positive) | The `tu9q` (ii-d) postcondition is **NON-VACUOUS on the composed binary**, witnessed by a program neither part accepts. | `j2` |
| **F-6** | P3 | `zujr`'s (L3) written RETIREMENT TRIGGER is **still un-fired**, re-measured on the composed binary with five constructions. The claim survives the composition. | `g1`–`g5` |

### F-1 (P2) — the composed accept surface

**NINE C programs DECLINE on BASE, on MAIN and on TU9QONLY and compile only on
COMPOSED** — `d1`, `d2`, `d3r`, `e3`, `i3`, `m4`, `n1`, `n2`, `o1`. Two more move
without changing verdict on all four: `d3` is a composed-only STREAM move on an
accepting module, and `j2` is a composed-only DECLINE-STRING move (F-5). Verbatim
(`probes/abx.sh`, on the four hashes above; the column is the first `error:`
line's message, or the lowered-IR line count on exit 0; rows below the surface are
the controls named in §2 and §3):

```
PROBE                          |  BASE                                          |  MAIN                                          |  TU9QONLY                                      |  COMPOSED                                      
owner                          | controlled lowering: control flow inside a loo | ACCEPT(85 lines)                               | controlled lowering: control flow inside a loo | ACCEPT(85 lines)                              
d1_both_arms_post              | controlled lowering: control flow inside a loo | controlled lowering: control flow inside a loo | controlled lowering: control flow inside a loo | ACCEPT(107 lines)                             
d2_both_arms_nopost            | controlled lowering: control flow inside a loo | controlled lowering: control flow inside a loo | controlled lowering: control flow inside a loo | ACCEPT(106 lines)                             
d3r_phasearm_only_rot          | loop lowering: rolled body leaks a rail entang | loop lowering: rolled body leaks a rail entang | loop lowering: rolled body leaks a rail entang | ACCEPT(84 lines)                              
e3_bank_plus_hoisted           | loop lowering: loop-carried tainted value cros | loop lowering: rolled body leaks a rail entang | loop lowering: loop-carried tainted value cros | ACCEPT(101 lines)                             
i3_bodyrail_from_q             | loop lowering: loop-carried tainted value cros | loop lowering: rolled body leaks a rail entang | loop lowering: loop-carried tainted value cros | ACCEPT(116 lines)                             
n1_two_carried_hoisted         | loop lowering: loop-carried tainted value cros | loop lowering: rolled body leaks a rail entang | loop lowering: loop-carried tainted value cros | ACCEPT(110 lines)                             
n2_twofn_hoisted_carried       | loop lowering: loop-carried tainted value cros | loop lowering: rolled body leaks a rail entang | loop lowering: loop-carried tainted value cros | ACCEPT(154 lines)                             
o1_owner_plus_hoisted          | controlled lowering: control flow inside a loo | controlled lowering: control flow inside a loo | controlled lowering: control flow inside a loo | ACCEPT(111 lines)                             
d3_phasearm_only               | ACCEPT(80 lines)                               | ACCEPT(80 lines)                               | ACCEPT(80 lines)                               | ACCEPT(83 lines)                              
j2_licm_cond_hoisted_rail      | controlled lowering: condition predates a non- | controlled lowering: control flow inside a loo | controlled lowering: condition predates a non- | loop lowering: hoisted invariant rail admitted
i1_g8_carried                  | ACCEPT(60 lines)                               | loop lowering: rolled body leaks a rail entang | ACCEPT(60 lines)                               | loop lowering: rolled body leaks a rail entang
tu9q_ht_rolled                 | loop lowering: rolled body leaks a rail entang | loop lowering: rolled body leaks a rail entang | ACCEPT(67 lines)                               | ACCEPT(67 lines)                              
j1_licm_cond_carried           | controlled lowering: condition predates a non- | ACCEPT(114 lines)                              | controlled lowering: condition predates a non- | ACCEPT(114 lines)                             
m3_nested_phaseonly            | loop lowering: rolled body leaks a rail entang | loop lowering: rolled body leaks a rail entang | ACCEPT(100 lines)                              | ACCEPT(100 lines)                             
m4_nested_outer_carried        | loop lowering: loop-carried tainted value cros | loop lowering: rolled body leaks a rail entang | loop lowering: loop-carried tainted value cros | ACCEPT(103 lines)                             
```

`owner` is the control: `example/grover/grover_oracle_uncompute.c`'s rolled
cascade is **unchanged** by the composition (85 lines, lowered IR byte-identical
except the `ModuleID` comment, trace byte-identical at 50 lines).

**Why these exist — the mechanism, stated so it can be attacked.** Both increments
retire a clause of `railLocalQualifies` (`ir-pass/src/LoopLowering.cpp:4022`) and
neither retires the other's:

* `zujr` retires **two**: the header-φ refusal (via `loopCarriedHandlePhi`) and
  **(L3)**, the blanket refusal of a store of a tainted value into an alloca, for
  a proven `!cq.railbank` bank. Without (L3) **no banked loop can ever be marked**.
* `tu9q` P0+P3 retires the **"accumulating loop-invariant tainted input"** clause,
  by admitting a LICM-hoisted out-of-place `cq_template_*` rail as a Root in
  `invariantRegisterRootsImpl` clause **(ii-d)**.

A loop that has BOTH a bank (or a carried handle) AND a hoisted template rail is
refused by whichever clause the other increment did not retire. Retire both and it
is marked, the spine places per-trip discharges, and conjunct (1) of
`declineDephasingUnmarkedLoopRails` is silenced — which is why five of the nine
decline on MAIN at the bd `s82e` / `6n1s` string
`cq loop lowering: rolled body leaks a rail entangled with a rotated register`
and accept on COMPOSED.

**⚠ `o1_owner_plus_hoisted.c` is the owner's own rolled cascade with ONE LINE
ADDED** (`int p = q*3;` plus `if ((p>>i)&1) cq_phi(0.2);` in the body). This is not
an exotic corner; it is the next line of the program the project ships.

**What I could establish about the nine, and it is not enough (Rule 2).** For each:
`opt` exit 0, **stderr 0 bytes** (no warning either); stage 2b STRICT **0
violation(s), 0 unproven**; the module links and runs; and, from the emitted
traces read by `probes/mset.py`:

* **no rail is multiply-`_unc`'d or multiply-freed** in any of the nine — no
  double-uncompute, no use-after-free;
* **every rail whose ancestry reaches the register a trailing `cq_theta` rotates
  is `_unc`'d and freed BEFORE that rotation.** e.g. `d1` line 77–78
  `cq_template_mul_i32_hl_unc(h1,h0,3); cqrt_free(h1)` then line 79
  `cqrt_ry_i32(h0, 0.9)`; `i3` discharges the per-trip `ashr` rails at lines
  23/56/89 and the hoisted `mul` at 104–105 before the Ry at 106; `d3r` reaches
  stage-2b **`3 template rail mint(s) of which 0 left dirty`**;
* the rails that ARE left dirty (`cq_template_add_i32_hl`, the value arm's hoisted
  chain) have ancestry reaching only a **classical** seed (`cqrt_alloc_i32(5)`),
  never the rotated register — so conjunct (3)'s `taintedAncestryReaches` is
  correctly false for them, and they are the pre-existing accepted-leak class;
* **symbol multisets match the hand-unrolled twin** modulo `-O1`'s trip-1
  const-fold, which is the divergence §4e ruling 2 blesses. For `e3`:
  `cq_template_add_i32_hl 3 vs 2` and `cqrt_alloc_i32 5 vs 6` — the flat form
  folds `5-3` to `cqrt_alloc_i32(2)`; every other symbol is equal;
* **K-independent**: `k3_e3` / `k64_e3` / `k1000_e3` all lower to **101 lines**;
* `n2` is a **two-function** module (bd `1yeu`'s structural blind spot) and both
  functions' hoisted rails are discharged (`cq_template_mul_i32_hl` 2 mints, 2
  `_unc`s, each before its own trailing `cqrt_ry_i32`).

**That list is the finding, not its refutation.** Track `zujr`'s Rule-13 round 1
saw a binary on which all nine decline; `tu9q` P0+P3's own measurements saw a
binary on which seven of them decline. Neither round could have found this
surface, and neither did. **The disposition owed before `tu9q` P0+P3 lands is a
Rule-13 round aimed at these nine programs, plus Rule-12 red-green fixtures for
at least `d3r` and `o1`** (there is no shipped fixture of this shape — see the
corpus result below).

### F-2 (P3) — `tu9q` P0+P3's capability is BANK-BLOCKED without `zujr`

```
tu9q_ht_rolled   | BASE: rolled body leaks… | MAIN: rolled body leaks… | TU9QONLY: ACCEPT(67) | COMPOSED: ACCEPT(67)
d3r_…_rot        | BASE: rolled body leaks… | MAIN: rolled body leaks… | TU9QONLY: rolled body leaks… | COMPOSED: ACCEPT(84)
```

`tu9q_ht_rolled.c` is copied verbatim from
`session-2026-09-18-orchestrator/trackT2/probes/ht_rolled.c` — the increment's own
intended customer — and `tu9q` P0+P3 flips it ALONE. `d3r_phasearm_only_rot.c` is
the **same shape with `bool b0[3]` in place of the scalar carried `r`**, and tu9q
alone does not flip it: (L3) refuses the marking for a banked body, and (L3) is
`zujr`'s. **So a capability the parked branch presents as its own is, for the
bank spelling, a joint one.** That is worth saying in the branch's own record
before it is landed or costed.

`d3_phasearm_only.c` (the same program **without** the trailing rotation) makes the
same point in the stream rather than the verdict: identical 34-line traces
(sha `9b1ddd16921800ea`) on BASE, MAIN **and** TU9QONLY, and **40 lines**
(`53d1f8e22bb1d8f9`) on COMPOSED. The six added lines are three
`cq_template_and_i32_hl_unc` + `cqrt_free` pairs — three per-trip which-path rails
of `q` that all three single binaries leak and only the composition discharges.

### F-3 (P3) — `tu9q` P0+P3 alone over-accepts the bd `6n1s` g8 shape

```
i1_g8_carried | BASE: ACCEPT(60) | MAIN: rolled body leaks… | TU9QONLY: ACCEPT(60) | COMPOSED: rolled body leaks…
```

On BASE and TU9QONLY the module compiles at exit 0 carrying only the bd `lyyf`
WARNING `cq rotation lowering: non-diagonal gate over a live derived record`; on
MAIN and COMPOSED it declines. The cause is structural and benign in the end: the
branch base `bfb809be` is the `tu9q` P2 tip and **predates the `6n1s` F-1 fix
`22a0ab11`**, so `declineUndischargedMarkedBodyRails` does not exist on it.
Merging P0+P3 onto `main` restores the backstop, which is what COMPOSED shows.
**Action: record in the branch that it is only ever mergeable onto a tree carrying
`6n1s`, and never rebased below it.** Not a defect in either piece; a merge-order
obligation that currently exists only in my measurement.

### F-4 (P3) — a new, unadjudicated rolled-vs-unrolled divergence

`d3r` (rolled, composed-only accept) against its hand-unrolled twin `d3ru`, both on
COMPOSED: 41 vs 45 trace lines. `probes/mset.py` delta:

```
cqrt_free      7 vs 9   (-2)
cqrt_ry_i1     3 vs 5   (-2)
DIRTY template rails: []  in BOTH        MULTIPLY _unc'd or freed: []  in BOTH
alloc rails never freed: rolled [h0,h4,h7,h10]   unrolled [h0,h4]
```

Two differences, and I argue both benign: (a) the rolled form discharges the `and`
rails **per trip** and the flat form at the **end of the whole DAG** — the rails
are disjoint, each minted once and `_unc`'d once, so the two orders are the same
unitary; (b) the flat form proves `Ry(0.5)|0⟩` back to `|0⟩` for the two unmeasured
`b0[1]`/`b0[2]` prep rails and frees them, while the rolled form leaves them
allocated — a Rule-6 accepted leak of rails that are in a **product** state,
unentangled with `h0`, so nothing dephases.

**The item is not the divergence, it is that nobody has written that argument
down.** `tools/loop_twin_matrix.py` has no cell of this shape and the quarantine
has no entry for it, so the divergence would ship un-adjudicated. Per bd `gfsk`,
a `_live` cell is adjudicated **in writing**, never by `--regenerate`.

### F-5 (P3, positive) — the (ii-d) postcondition fires on the composed binary

`j2_licm_cond_hoisted_rail.c` declines on BASE/TU9QONLY at `condition predates a
non-diagonal gate`, on MAIN at `control flow inside a loop body`, and on COMPOSED at

```
error: <unknown>:0:0: in function slice i32 (i32): cq loop lowering: hoisted
invariant rail admitted for in-loop discharge was not discharged
```

i.e. `kMsgExitObligation`, `declineUndischargedExitObligations`. **A program only
the composition can reach proves the composed binary's newest postcondition is not
vacuous.** Recorded because an instrument that has never been made to fire is an
instrument nobody should cite (L10).

### F-6 (P3) — `zujr`'s (L3) retirement trigger is still un-fired

(L3)'s source comment says the exemption's ground is `isInteriorTerminalHandle`'s
**(I1)** ("every rail a bank can hold today IS alloc-minted") with the trigger
*"the day a bank cell can hold a TEMPLATE-minted rail, (I1) stops covering it and
only (I3) does. Re-derive this exemption then."* It records that gap as MEASURED
EMPTY **on the `zujr` oracle and subject** — binaries that do not know how to treat
a template rail as a root. I re-measured it on COMPOSED with five constructions:

* `g1` (`bool b[3]; b[i] = (q>>i)&1;`) and `g2` (`int c[3]; c[i] = q*(i+2);`) both
  die at `cq rail bank: unsupported reader of a rail-bank cell` on **all four**
  binaries;
* `g3`, `g5` never reach the bank question (earlier walls, same on all four);
* `g4` (`c[i] = cq_theta(c[i],0.5); c[i] = c[i] + 1;`) ACCEPTS at 70 lines on all
  four — but M-C lowers the `+1` **in place**, so no template rail is minted and
  the bank never holds one.

**The gap is still empty.** ⚠ It is owed again on any binary that widens
`RailBankPromote` (bd `xdu2`'s second half) — that, not (ii-d), is the trigger.

---

## 3. What I attacked and did NOT find

*"No finding" without the list is worthless.*

**Systematic instruments (all three report ZERO composition effect):**

1. **4-way corpus A/B over all 2106 `ir-pass/test/*.ll`**, recording exit code,
   first diagnostic **and a sha-256 of the lowered stdout** (so a stream move on an
   accepting module is visible — the `zujr` session's own `sweep.py` used
   `-o /dev/null` and could not see one). `probes/corpus.py`,
   `corpus4_summary.txt`:
   * `MAIN → COMPOSED` movers: **8**
   * `BASE → TU9QONLY` movers: **8**
   * **the two sets are IDENTICAL** (checked by name, not by count)
   * **COMPOSITION-ONLY movers: 0**
   * `A → D` in the composed direction: **0**; `D → A`: 4.
   * The 8 are exactly `tu9q` P0+P3's own declared movers, including its
     already-flagged #7 `loop_pairing_reject_round2_falsified.ll`
     (DECLINE → exit 0, retiring another owner's fence) and #8
     `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll`
     (→ the postcondition string). `zujr` neither fixes nor worsens either.
   * For reference: `BASE → MAIN` is **26** movers, 21 D→A and 2 A→D (both the
     `6n1s` fence landings).
2. **`tools/loop_twin_matrix.py --phi-surface void`, run against MAIN and against
   COMPOSED with `--out`** (the committed table was never touched). Both:
   *"all cells match `loop_twin_matrix.expected.txt`; all 70 quarantined cells
   diverge with their pinned signature; 4 of 4 boundary controls as pinned"*,
   **382 cells**, `exit=0`. `diff matrix.MAIN.txt matrix.COMPOSED.txt` is
   **empty** — zero cells moved.
3. **All 390 `tests/e2e/slice_*.c`, compiled → lowered → linked → run → byte-diffed
   against the committed `.expected.log`**, on MAIN and COMPOSED
   (`probes/slices.py`): **0 of 390 differ**; 377 GOLD-OK on both; the 13
   non-GOLD-OK rows are identical on both and are the known unregistered /
   multi-TU / deliberately-declining slices (my harness is single-TU, so the four
   `_lib`/`_caller` rows are harness LINKFAILs, not compiler results).
   Corroborated in passing: `slice_control_inplace_ry_loop_leak_unrolled.c`
   accepts with **no golden and no gate** on both binaries — the open bd `jlf8`
   item CLAUDE.md §4d names, unmoved by this composition.

**Directed probes that found nothing (all 4-way):**

* **The multiplicity hazard** — *"K adjoints against ONE forward gate"*, the
  danger `railLocalQualifies`' own comment and `tu9q`'s (ii-d) both name. Three
  constructions: a rail minted in the OUTER preheader whose only users are in the
  INNER body, so the inner loop's exit block (P2's anchor) sits inside the outer
  loop (`m1`, `m3`, `m4`); a rail minted in the outer BODY (`f1`); two loops
  sharing one hoisted rail (`e2`). `m3` and `m4` are accepts and both emit
  `cq_template_mul_i32_hl` **1 mint / 1 `_unc`** — `anchorForConsumer`'s outermost
  walk covers the nest. The others decline earlier.
* **Multi-exit** (where `loopExitDischargePoint` returns `nullptr`, so a (ii-d)
  grant would leak with the dephasing fence already silenced): `break` with and
  without a carried handle (`e5`, `f2`, `h1`, `h2`), an early `return` from the
  body (`f3`). All decline on all four, at earlier walls.
* **Double-free / use-after-free**: no rail is multiply-`_unc`'d or multiply-freed
  in **any** of the nine composed accepts, nor in any of their twins.
* **A rail freed while not provably `|0⟩`**: every `cqrt_free` in the composed
  traces is preceded by the matching `_unc` or by the `x⊕x=0` CNOT return; stage
  2b STRICT reports `0 violation(s), 0 unproven` on all nine (⚠ cited only as a
  rail-identity check — 2b's VIOLATION layer is structurally blind to
  template-minted rails, so the template ledger above is the load-bearing half).
* **The bd `zujr` L8 tripwire** `loop_carried_handle_reject_postloop_rotation.ll`
  — the fixture whose header says *"THE DAY THE SELECT WALL MOVES … THIS MODULE
  ACCEPTS, AND WHAT IT ACCEPTS IS THE RULE-8 HAZARD"*. Same string
  (`cq controlled lowering: control flow under quantum control`) on MAIN and on
  COMPOSED. The composition does not move that wall.
* **bd `drbq.12` × `zujr`** (`j1_licm_cond_carried.c`, an LICM-hoisted
  loop-invariant compare `q >= 3` as the region condition with a trailing
  `cq_theta(q,0.9)`): accepts at 114 lines on MAIN and on COMPOSED with
  **byte-identical traces**. The per-trip `icmp_sgt` rail is re-minted, `_unc`'d
  and freed on every trip before the Ry (`crossBlockCompareMintable` doing exactly
  what it says). Declines on BASE/TU9QONLY at the 2c fence.
* **bd `h1ip` / (Z8), the guarded loop, × tu9q** (`j3`): the rail-bank injectivity
  fence speaks first on all four; the composition does not reach it.
* **Cross-function ledger clearing** — both new postconditions are MODULE-scoped
  ledgers that CLEAR themselves, and bd `1yeu` records that every corpus here is
  one function per module. `n2_twofn_hoisted_carried.c` puts two quantum functions
  each carrying a (ii-d) obligation in one module: **both** discharged, both before
  their own trailing rotation.
* **A Q+Q value arm reading the hoisted rail** (`f4`, `c3`, `i2`) and **the carried
  handle's exit value rotated after the loop** (`k1`): decline on all four. `k1`'s
  FLAT twin accepts at 113 lines on all four — a pre-existing rolled/flat
  over-decline asymmetry, unmoved by the composition, and not mine to file.

---

## 4. What I did NOT do

* **No `ctest`, no `ir-pass-lit`, no full suite.** The protocol allows
  `ir-pass-lit` once to attribute a finding and I did not need it. ⚠ The
  consequence is precise and must not be glossed: my corpus A/B checks exit code,
  diagnostic string and lowered-IR hash for all 2106 fixtures, which is a
  **superset of what `ir-pass-lit` measures about the IR** and a **subset of what
  it asserts** — it does not run one `FileCheck` line. A fixture whose verdict and
  stream are unchanged but whose `CHECK` prefixes no longer match would be
  invisible to me.
* **No simulator** (Rule 2, owner decision 2026-06-10). Every unitary claim above
  is analytic/trace-level.
* **No mutation or injection matrix** over the composed accepts, and **no lit
  fixture written** for any of them. Rule 12's red-green for this surface is owed
  by whoever lands `tu9q` P0+P3, not discharged here.
* **The twin matrix was run on MAIN and COMPOSED only**, not on BASE or TU9QONLY,
  and it was never run with `--regenerate` or `--refresh-quarantine`.
* **The e2e slice sweep was run on MAIN and COMPOSED only.** Four `_lib`/`_caller`
  multi-TU slices are harness LINKFAILs in my single-TU driver on both binaries;
  I did not port `run_slice_multi.sh`.
* I did not attack the composed surface against a `break` loop, an irreducible or
  multi-latch body, or the `use_empty()` / `liftOneRegisterMergePhi` residuals that
  round 1's F-4 names — beyond the probes listed in §3, which all declined at
  earlier walls.
* Nothing was committed to `main`, nothing pushed, no `bd` write, and the main
  checkout's `build/` was never touched. The only files I wrote in the main
  checkout are this directory.

---

## 5. Reproducing this

```bash
# the four binaries, built SEQUENTIALLY at -j4 in a worktree
git checkout <commit>; cmake --build build -j4      # never --target CQPass alone
shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so

# one probe, four binaries
./probes/abx.sh probes/d3r_phasearm_only_rot.c

# one probe, full pipeline on one binary (stage 1 -> 2 -> 2b -> 3 -> trace)
./probes/run.sh probes/d3r_phasearm_only_rot.c COMPOSED

# the gate-symbol multiset + per-rail mint/_unc/free ledger of a trace pair
python3 probes/mset.py <rolled>.trace <unrolled>.trace

# the 4-way corpus (2106 fixtures x 4 binaries, ~35 min)
python3 probes/corpus.py

# the 390-slice e2e sweep, MAIN vs COMPOSED (~20 min)
python3 probes/slices.py MAIN COMPOSED

# the twin matrix against one of my binaries, WITHOUT touching the committed table
./probes/matrix.sh COMPOSED
```

Artefacts in this directory: `probes/` (all probe sources and harnesses),
`corpus4_summary.txt`, `matrix.MAIN.txt`, `matrix.COMPOSED.txt`,
`verdict_table.txt`, `slices_MAIN_vs_COMPOSED.txt`.
