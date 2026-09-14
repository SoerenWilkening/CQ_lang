# MERGE REPORT — session 2026-09-14c, ONE group, five branches

Worktree `/Users/sorenwilkening/Desktop/CQ_merge`, branch `merge-2026-09-14c` off `fa621f06`.
Gate lines, all hash-keyed and all RUN by this agent: `GATES.md`. Findings: `MERGE_FILINGS.md`.
**Gated binary: `cq-opt` `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`,
`libCQPass.so` `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b`.**

---

## 0. The headline, in the order the brief asks for it

1. **The full suite is GREEN: `442/442`, 689.58 s.** ⚠ Read the time with its cause: this was a FRESH
   build directory, so the e2e stage-1 content-addressed cache was COLD. It is not comparable with
   `CLAUDE.md`'s 130-230 s warm band and must not be quoted as a slowdown.
2. **`cq-opt-equivalence-full`: 2039 fixtures, 0 mismatches** — owed because Track A and Track S each
   moved a decline string AND an analysis site, and both flagged it.
3. **ROUTING R3 is CLOSED BY MEASUREMENT, not inherited.** One sweep, **6311 rows**, ORACLE vs merged
   on the same stage-1 module per row: **0 DECLINE→ACCEPT, 0 IRDIFF, 0 unattributable movers.**
4. **The safety property holds, including on the owner's own file** — and it holds *through a live
   promotion*, which is the strongest form available: Track A's carve says `Bank`, Track B's promoter
   FIRES, and the module still declines at the same `!dbg`.
5. **The A×B composition was NOT a formality.** Merging A and B produced a deliberate link error
   (good), and then **11 Track-B fixtures went RED** — a failure neither branch's own green suite
   could have shown. Both are reported below.
6. ⚠ **This report says plainly what the brief asked it to say: the A×B composition had been reviewed
   by NOBODY.** Track A cleared a binary without B's promoter; Track B cleared a binary without A's
   classifier. What follows is a MEASUREMENT of that composition, not a review of it. A Rule-13
   opinion on A×B is owed and is filed (`MERGE_FILINGS.md` F-1).

---

## 1. Merge order, and every conflict

`A → B → S → X → I`, each `--no-ff`, with the A×B integration as its own commit between B and S.

| # | commit | branch | tip merged | conflicts |
|---|---|---|---|---|
| 1 | `944c6376` | `railbank-carve` (A) | `44ba3345` | **none** |
| 2 | `09c9d9b0` | `railbank-promoter` (B) | `6a999d1a` | **none** |
| — | `e6946068` | *(integration — see §2)* | — | — |
| 3 | `058c778a` | `s82e-raillocal-proof` (S) | `8aa159b7` | **none** (auto-merge `ir-pass/src/CQLoweringPass.cpp`, disjoint hunks: B inserts the promoter fixpoint at the head of the `-O1`-repair normaliser family, S inserts the D4 re-ask at `lowerLoops`) |
| 4 | `0e866305` | `x5-rederivation` (X) | `c4cff67` | **none** (auto-merge `ir-pass/src/ArmClassify.cpp`: S touches 10 lines of prose/scoping, X rewrites 220 lines of the `collectStatePrepPhiDescendants` argument; disjoint) |
| 5 | `562f1e0a` | `railbank-instruments` (I) | `20174549` | **none** (python only) |

**ZERO textual conflicts across all five.** ⚠ And `tests/e2e/CMakeLists.txt` was **not touched by any
branch** — `git diff fa621f06 HEAD -- tests/e2e/CMakeLists.txt` is empty — so PROTOCOL's tail-conflict
ERRATUM did not arise this time. The three union checks were run anyway and are in `GATES.md`:
0 duplicate `add_test` names, 432 registrations, sweep still LAST.

⚠ **Zero textual conflicts is not zero integration work, and this merge is the clean demonstration of
that.** Everything in §2 below merged without git saying a word.

---

## 2. THE A×B INTEGRATION — the shim, its removal, and the re-measurement

### 2.1 The fail-loud property HOLDS, and one of its three claimed tripwires did not fire

Built with Track A's real definition and Track B's `RailBankCarveShim.cpp` both present:

```
duplicate symbol 'cq::railBankCarveVerdict(llvm::StoreInst const*, cq::TaintSet const&,
  llvm::DominatorTree&, llvm::LoopInfo&, llvm::ScalarEvolution&, char const*&, cq::RailBankShape*)' in:
    .../CQPass.dir/src/RailBankCarveShim.cpp.o
    .../CQPass.dir/src/QramLowering.cpp.o
ld: 1 duplicate symbols
```
— reported for **both** `libCQPass.so` and `cq-opt`, exactly as `RailBankCarve.h` predicted. **There is
no FINDING here: the build did not succeed, and nothing picked a definition silently.**

⚠ **But Track B claimed THREE tripwires and only the first can fire.** Its second —
*"`enum class RailBankCarve` … declared in `QramLowering.h` too, so any TU that sees both headers fails
to compile on a REDEFINITION — and the DEFAULT ARGUMENT `outShape = nullptr` appears in both
declarations, which is its own hard error"* — did **not** fire and **could not**: no translation unit
includes both headers (`RailBankCarveShim.cpp` and `RailBankPromote.cpp` include `RailBankCarve.h`;
only `QramLowering.cpp` includes `QramLowering.h`). The property is carried entirely by the link error.
Filed as F-4 — a tripwire that cannot fire is a tripwire nobody should count, and this one was counted
three times in Track B's own prose.

### 2.2 The removal

* `ir-pass/src/RailBankCarveShim.cpp` and `ir-pass/include/RailBankCarve.h` **deleted**; the CMake entry
  removed. Nothing else references either.
* `RailBankPromote.cpp`'s single `#include "RailBankCarve.h"` → `#include "QramLowering.h"`. **Nothing
  else in the promoter changed.** The deleted header's L8 retirement trigger named its own replacement
  text and was character-for-character correct — L8 works, again.
* The enum, the struct and the function signature are **identical in both spellings** (member names,
  member order, parameter list, the `outShape = nullptr` default). Compared by reading both, then
  proved by the fact that deleting one file left the call site resolving.

### 2.3 The two cross-seam facts the deleted header carried, re-homed rather than lost

`RailBankCarve.h` carried two facts about Track A's ACCEPT SURFACE that the promoter depends on and does
not re-ask. Deleting the file would have deleted them.

* **C4 admits the read-modify-write cell address** — already stated at length in `QramLowering.h`. Kept
  by reference from the promoter's call site. Nothing added.
* **The walk loop is OUTERMOST (`Loop::getParentLoop() == nullptr`)** — stated in `QramLowering.h` as
  *the carve's* hazard, and **nowhere** as *the promoter's*. A **CROSS-SEAM RETIREMENT TRIGGER** is now
  written at the conjunct's own source site in `QramLowering.cpp`, in the direction the next editor
  needs (the L3 MIRROR: when a predicate acquires a second caller, read its trigger and say which way
  you are using it). It names Track B's mutant M12 by name and says in terms: *relaxing this line
  without giving the promoter a clause of its own, in the same change, is an OVER-ACCEPT — a wrong
  unitary, not a wrong decline.*

### 2.4 ⚠ ELEVEN TRACK-B FIXTURES WENT RED — the composition, measured

`lit --filter railbank` on the A+B binary: **41 discovered, 30 pass, 11 FAIL.** Every one is a
`railbank_promote_reject_*.ll` whose `DECLINE` prefix pins `cq taint escape: tainted value stored to
memory`. With Track A merged, `declineTaintEscapes` consults `railBankCarveVerdict` FIRST and each shape
takes Track A's **per-clause** string instead:

| Track B fixture | merged string (Track A's) |
|---|---|
| `…reject_early_exit` · `…reject_noninjective_index` · `…reject_second_exiting_block` | `cq rail bank: cell index is not an injective per-iteration index` |
| `…reject_inloop_other_read` · `…reject_oversized_bank` · `…reject_two_cells` | `cq rail bank: array has cells no iteration writes` |
| `…reject_escaping_address` | `cq rail bank: array escapes to an unsupported user` |
| `…reject_nested_outer_loop` | `cq rail bank: the cell walk is re-executed by an enclosing loop` |
| `…reject_nonzero_init` | `cq rail bank: array has an initializer the rail model cannot represent` |
| `…reject_store_outside_loop` | `cq rail bank: array is written from more than one store site` |
| `…reject_volatile_cell` | `cq rail bank: cell address has aliasing fan-out` |

**Measured ORACLE vs merged: exit 1 on both, every one a DECLINE→DECLINE string move, never
DECLINE→ACCEPT.** Resolved by re-pinning each `DECLINE` line to the string the merged compiler
actually emits, under a header block that states the move is a COMPOSITION FACT rather than a
correction, that the clause each file is *about* is still pinned by its own `DBG`+`NOTS` prefixes (the
stage ran; the stage did not promote), and carrying a retirement trigger for the day the deferred half
lands and a `Bank` verdict stops falling through to a decline. `railbank_promote_reject_classical_store`
and `…reject_already_ssa` did **not** move and keep `kMsgStore`, correctly — the first is `NotBank` at
the carve's taint half, the second never has a bank store at all. After re-pinning: **41/41 green.**

### 2.5 THE DIFFERENTIAL — where the real predicate and the shim disagree, measured rather than argued

A **temporary AUDIT build** (`GATES.md` names it and records that it is reverted, with a `grep` for
residue at 0) carried the shim under the renamed symbol `railBankCarveVerdictShimAudit` and called BOTH
from the exported `railBankCarveVerdict`, printing on every call. So the comparison covers **every call
site** — `declineTaintEscapes`' and the promoter's `planBank` B6 — not just the one Track B could see.

**130 carve-call rows** over 2039 fixtures + 71 C probes (Track L's and Track A's):

| | count |
|---|---|
| `AB_SAME Bank` — verdict **and all seven `RailBankShape` fields** equal | **63** |
| `AB_SAME` on a non-`Bank` verdict | 47 |
| `AB_DIFF` | **20** |
| shape mismatch on a `Bank` both agree on | **0** |
| **rows where real = `Bank` and shim ≠ `Bank`** | **0** |

The 20 disagreements, every one in the direction *the real classifier is stricter or equal*:

| real ← shim | rows | what it is |
|---|---|---|
| `RejectTotality` ← **`Bank`** | 8 | Track A's C6 in-loop-read clause (*"every in-loop read is of the cell THIS trip writes"*), which the shim has **no counterpart for** |
| `RejectAlias` ← **`Bank`** | 4 | Track A's C4 second half (*exactly ONE store site in the whole bank*), which the shim **does not implement** |
| `RejectShape` ← `NotBank` | 4 | a GLOBAL array / a VLA: A resolves provenance through `walkPtrOrigin` and names the clause; the shim's narrower gep matcher just falls through. Both decline |
| `RejectIndex` ← `RejectTotality` | 2 | `second_exiting_block`: A refuses at C2′'s `getExitingBlock()`, the shim at its C6. Both decline |
| `RejectAlias` ← `RejectIndex` | 2 | `two_stores`: different clause, both decline |

### 2.6 The three named divergence candidates — ANSWERED

* **RAW vs PROMOTED — THEY AGREE, and now by measurement rather than by coincidence.** All ten modules
  that reach `Bank` are `AB_SAME Bank` with byte-equal shapes: the eight RAW read-modify-write customers
  (`a_loop_n{2,3,8}`, `a_loop_n3_noarm`, `a_loop_n3_uncond`, `L7_array_uninit`, `L8_array_int_cells`,
  `L9_array_phase_arm`) **and** `L1_promoted_store`, the PROMOTED one-use shape. One predicate, two
  shapes, one answer. Track B called the independent `hasOneUse` correction *"the strongest agreement
  evidence available without the merge"*; with the merge it is no longer evidence, it is a measurement.
* **The outermost-loop conjunct — PRESENT, FIRING, and now documented AT ITS OWN SITE.** `H1_nested_outer_rewrite.c`
  and `railbank_promote_reject_nested_outer_loop.ll` both take `cq rail bank: the cell walk is
  re-executed by an enclosing loop`, and the promoter does not fire. Track B's M12 measured that
  deleting the line makes the promoter FIRE; that sentence is now in `QramLowering.cpp` beside the line
  (§2.3). This was the candidate a per-track gate structurally could not see, and it is closed.
* **"the classified store is the only store in the bank" — CONFIRMED, and it makes Track B's
  multi-store path DEAD CODE.** Track A's C4 refuses `Stores.size() != 1` unconditionally, and B6 runs
  before every other B-clause (`RailBankPromote.cpp:268`, ahead of B5 `:324`, B1 `:334`, B8 `:352`,
  B3 `:361`, B2 `:372`, B7 `:392`). So `applyBank`'s several-stores-per-activation `SSAUpdater` path
  is not merely untested — on the merged binary it is **unreachable**. Safe direction; filed as F-2
  because unreachable-and-untested is a different maintenance fact from untested.

### 2.7 Track B's §7 clause table, re-measured — and what the merge COSTS its matrix

Every clause row still holds; every refuse fixture still refuses; **three of them stopped isolating
their clause.** `…reject_two_cells` (B2), `…reject_store_outside_loop` (B5) and
`…reject_inloop_other_read` (the *"nothing non-rewritable inside `L`"* clause) were all `Bank` to the
shim and are `Reject*` to the real carve, so B6 now refuses them before their own clause is reached.
⚠ Those are precisely the two fixtures Track B **rewrote in injection rounds 2 and 3** so that the B
clause would be the SOLE refuser. The merge undoes that work, and Track B's 22-mutant matrix — which
mutated the SHIM — no longer measures the shipped binary for them. Filed as **F-3**; not fixed here,
because a binary-mutation matrix is the implementation row's gate and costs ~22 rebuilds.

⚠ **B3 — the question Track B said could only be answered at the merge gate — is ANSWERED**, and the
answer is not the one it guessed: B3 is subsumed by Track A's real **C2′** (`!L->getExitingBlock()`),
not by C6. `railbank_promote_reject_second_exiting_block.ll` now takes `cell index is not an injective
per-iteration index`.

---

## 3. THE SAFETY PROPERTY — no program goes DECLINE → ACCEPT

**Over 6311 corpus rows: `0`.** The sweep's `VERDICTMOVE` count is 14 and every one is
`exit 0 → exit 1` (ACCEPT → DECLINE). The predicate `o_exit != 0 && s_exit == 0` matches nothing.

**And on the owner's own file, pinned beyond the sweep** (`example/grover/grover_oracle_uncompute.c`,
untracked, bd `k4fw`, copied in from the primary checkout):

```
ORACLE : exit 1 · owner_grover.c:92:19 · cq taint escape: tainted value stored to memory
MERGED : exit 1 · owner_grover.c:92:19 · cq taint escape: tainted value stored to memory
```

⚠ **And the pin is stronger than "unchanged", which is the part worth reading.** Under
`CQ_RAILBANK_DBG=1` the merged binary reports
`promote bank % in @main … cells=3 cell=i8 seed=zero loads=2 stores=1` and the dumped module carries
`%cq.bank = phi i8`, `%cq.bank.addr = getelementptr inbounds [3 x i8]` and **one** `store i8 %cq.bank`
at the latch. **Track A classifies the owner's `bool b0[3]` as `Bank`, Track B promotes it, and the
program still declines at the same source location.** The staging constraint (`DECISIONS.md`,
`BRIEF_A.md` §0) is not holding because nothing happened — it is holding *through* the full A×B
mechanism on the increment's motivating customer. That is the composition's best evidence and its
sharpest warning: the only thing standing between this and a silent miscompile is that `Bank` falls
through to `kMsgStore`, exactly as designed and exactly as deferred.

---

## 4. The corpus sweep — ROUTING R3 closed BY MEASUREMENT

Track A swept 2088 of 5455 modules and argued the residue's immobility **structurally**, labelling it a
gap. R3 handed the closure here. **It is closed by running it, and the residue was NOT immobile.**

Recipe (`GATES.md`): 6311 rows = `ir-pass/test/*.ll` (2039) + every `.ll` under `docs/` (1823) + every
`.c` under `docs/` (2040) + `tests/e2e/*.c` (409). Both binaries on the SAME stage-1 module per row.
A decline row is compared by **exit code + sha256 of the FULL stderr** (PROTOCOL S3: the shared
`corpus.sh` tag regex renders a whole decline family as an empty `D:`); an accept row additionally by
the lowered-IR md5, **within the row only**.

```
6236 SAME · 38 STRMOVE · 14 VERDICTMOVE · 23 CLANGERR · 0 IRDIFF · 0 DECLINE→ACCEPT
```

### 4.1 Every mover attributed, BY STRING

* **38 STRMOVE → Track A, 38/38.** Every one is `cq taint escape: tainted value stored to memory` →
  a `cq rail bank: <clause>` string, across eleven distinct clause strings. 26 are `ir-pass/test`
  fixtures (15 Track A `lowering_reject_railbank_*`, **11 Track B `railbank_promote_reject_*`** — the
  §2.4 composition rows, Track B's files taking Track A's string) and 12 are `.c` probes (4 Track L
  `N*`, 8 Track A `A*`/`H*`).
* **14 VERDICTMOVE → Track S, 14/14**, every one ACCEPT → DECLINE carrying the single new string
  `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop`.
  Three are the `*_leak_control.ll` fixtures (`MERGE_BRIEF` §6.1 — the increment, not a regression),
  two are Track S's own red-green pair, six are Track S's `s1`/`s2` probes reached through three paths
  each, and **three are records NO track swept** (§4.2).
* **Track B: 0 movers of its own** — as predicted. Every railbank fixture that moved moved on Track A's
  string.
* **Track X: 0 movers.** Its own claim is a bit-identical binary; across 6311 rows nothing it touched
  moved, and `0 IRDIFF` says no accepted module's lowered IR changed at all.
* **Track I: 0 movers** (no pass source).
* **0 unattributable movers.**

### 4.2 ⚠ What the residue was hiding — three more Track-S movers, and they are GENUINE

R3's warning was right and the structural argument would have lost. Three record programs outside every
track's corpus move ACCEPT → DECLINE:

`inc1-records/c1-round3/z21_preadd_volatile_imm.c` · `inc1-records/c1-round4/c2_m11d_two_loops_no_preadd.c`
· `inc1-records/session-adc5590a/c1_reproducers/r5_short_inv.c`

Read, not inferred: all three are the `*_leak_control.ll` shape verbatim —
`for(i<3){ if((q>>i)&1) cq_phi(…); r=cq_theta(r,…); } q=cq_theta(q,0.9); return cq_measure(q)+…` — a
rolled body leaking a rail entangled with `q`, which is **re-rotated after the loop and measured**.
That is D4's divergent sub-case, so they are genuine instances and the direction is correct. **The
class's known record population is 6 programs, not 3**, and Track S's IMPL_S §18 count of 7 movers is
a fact about a 2013-row corpus, not about the tree. Filed as F-5 so the number is not re-quoted as
complete.

### 4.3 The 23 CLANGERR rows, all pre-existing and none a compiler fact

17 are `tests/e2e/*_lib.c`, the classical halves of multi-TU slices, which carry their own
`#error "C18 violation: CQ.h was -include'd into a classical lib TU"` — my sweep recipe `-include CQ.h`
trips their guard by design; the full suite exercises them properly. `A4_bitint96_cells.c` is Track A's
documented non-compiling `_BitInt(96)` probe. `U0_uncommented.c` uses the retired two-argument
`cq_phi`. `e1_i128cond.c` is an inc2 record. And the two `tests/e2e/slice_control_select_*_round2_window.c`
do not compile because their 2026-09-14 conversion header nests `/*` inside a block comment, so the
prose leaks into the code — pre-existing on `main`, harmless (both are UNREGISTERED), and filed as F-6
because a record kept *"as the record of a program that used to lower"* should be compilable.

---

## 5. `!dbg` accounting — 0 lost, 0 gained

2661 sweep rows where either binary declines. Among the 2647 where **both** decline:
**0 LOST source locations, 0 GAINED.** (The 1007 → 1018 raw counts differ only by the 14 rows that are
newly declines on the subject side.) 0 lost locations was the 2026-09-14 gate's standard and it is met.

---

## 6. Duplicate-body scan, and the L8 rename check

**2039 fixtures · 9 duplicate-body groups · 0 groups with CONTRADICTORY verdicts.** All nine are the
same nine Track A measured at 2015 fixtures — pre-existing, each a pair whose two files declare the
same verdict. **No `*railbank*` fixture duplicates anything**, so none of the ~45 fixtures added this
session across three branches resurrected an old body under a new name.

The scan reads each duplicate's CLAIMED verdict off its own RUN lines (`not %cq-opt` ⇒ DECLINE) rather
than off its filename. And the L8 resurrection check proper: `git diff --name-status -M fa621f06 HEAD`
reports **0 renames and 0 deletions** anywhere in the tree — Track S's three `*_leak_control.ll`
conversions and Track X's two tripwire-header corrections are all `M`, in place, as they said.

---

## 7. The twin-matrix cells Track S requested — GENERATED, and ADJUDICATED IN WRITING

Run on the merged binary through the matrix's own per-side stages (`clang -O1 -emit-llvm` → `cq-opt` →
**STRICT** `free_pairing_check.py` → link templates-before-runtime → run → compare traces).
⚠ **`--regenerate` was not invoked, and neither `tools/loop_twin_matrix.expected.txt` nor
`…quarantine.txt` was written to** (bd `gfsk`).

| requested cell | Track S expected | **MEASURED on `0e280fc6`** |
|---|---|---|
| `m_noregion_invread_dead` (`w2k` + twin) | DIVERGE, quarantined | **TRACE-DIVERGENCE**, rolled 16 / unrolled 20. Tool-exact `divergence_signature` **`07ae35c484747c29`**, first rolled `cq_template_and_i32_hl(h0, 1) -> h1`, first unrolled `cqrt_alloc_i32(6) -> h1`. Counts (`_unc`, `cqrt_free`, mints): rolled **(0, 0, 8)**, unrolled **(2, 2, 8)** |
| `m_noregion_invread_live` (`s1` + twin) | DECLINE-BOTH-SIDES | ⚠ **`UNROLLED-ONLY`** — the rolled form DECLINES with D4's string; **the unrolled twin still ACCEPTS** and emits 14 lines, STRICT 2b `0 violation(s), 0 unproven` |
| `m_region_derivedbase_live` (`s2` + twin) | DECLINE-BOTH-SIDES | ⚠ **`UNROLLED-ONLY`** — rolled DECLINES, unrolled ACCEPTS 25 lines, STRICT 2b clean |
| `m_region_rootmint_live` (`s3` + twin) | ACCEPT-IDENTICAL 22 == 22 | **`ACCEPT-IDENTICAL`, 22 == 22.** The positive control HOLDS on the merged binary |

**Adjudication.**

1. ⚠ **Track S's prediction for two of the four is WRONG, and the correction matters more than the
   cells do.** D4's decline is **ASYMMETRIC**: it fires on the ROLLED spelling only, and the
   hand-unrolled twin of the very same source still compiles and still emits the correct circuit. In
   the matrix's own vocabulary (`verdict()`, `loop_twin_matrix.py:2143`) that is `UNROLLED-ONLY`, a
   recordable verdict — not `DECLINE-BOTH`. This is exactly D4's stated and accepted cost said in
   traces: *"programs that could be compiled correctly decline until the pairing is built"*, where
   "could be" now has a measured witness (14 and 25 lines) rather than an argument.
2. `m_region_rootmint_live` is the only one of the four that is an `ACCEPT-IDENTICAL` and it holds.
   Without it the other three read as *"rolled loops leak"* instead of *"this closure gap leaks"*.
3. **None of the four was ADDED to the matrix, and the reason is structural rather than a preference.**
   `cells_of_matrix()` is a closed product of axis grammars with **asserted** sub-grid sizes
   (`120/36/118/14/50 = 338`, `loop_twin_matrix.py:2089`); these four are BESPOKE SOURCES, so adding
   them means adding a new cell family with its own source generator, moving the assert, and giving it
   its own red-green and mutant validation. That is an instrument increment of Track I's class, not a
   merge-and-gate edit, and dropping a hand-written row into either file for a cell the generator
   cannot produce would leave the quarantine's own boundary controls (*"the cell stopped diverging"*,
   *"the cell appears in both files"*) unable to evaluate it — stale by construction, which is the
   failure mode those controls exist to catch. Filed as **F-7** with the four measured verdicts and
   the tool-exact signature, so the increment that builds the family starts from data.
4. ⚠ **And one lesson the cells hand over for free.** `m_noregion_invread_dead`'s counts —
   rolled (0, 0, 8) vs unrolled (2, 2, 8) — are the **same structural signature** as the two `_live`
   cells the fence now refuses. D4 classifies this one BENIGN because its entangled partner is dead
   after the trip; **that distinction is invisible in the trace and the twin matrix cannot make it.**
   Only the fence can. This is `CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` lesson arriving
   from the other side, and it is why the `dead` cell must never be read as evidence about the `live`
   ones.

---

## 8. Behaviour that appears ONLY with two or more branches present

| # | composition | what appears |
|---|---|---|
| 1 | A × B | the duplicate-symbol **link failure** (§2.1) — the intended tripwire, and the only one of Track B's three that can fire |
| 2 | A × B | **11 red fixtures** (§2.4). Track B's files, Track A's diagnostic. Green on either branch alone |
| 3 | A × B | Track A's carve says **`Bank`** on the owner's file and Track B's promoter **fires** on it (§3). Neither branch alone can produce that sentence |
| 4 | A × B | the promoter's multi-store `SSAUpdater` path goes from *untested* to **unreachable** (§2.6, F-2) |
| 5 | A × B | three Track-B fixtures stop isolating their clause, and Track B's mutation matrix stops measuring the shipped binary for them (§2.7, F-3) |
| 6 | A × B | **B3's subsumption question, answered** — by Track A's C2′, not by C6 (§2.7) |
| 7 | S × X | **nothing.** Both edit `ArmClassify.cpp`; the merge is textually clean, the suite is green, and the sweep attributes every mover to exactly one track. Measured-absent, not assumed-absent |
| 8 | (A+B) × I | **Track I's new `adjudicate_memory` rules have NO customer in the merged tree** — every rail bank declines at `declineTaintEscapes`, far above lowering, so no `!cq.railbank` load ever reaches stage 2b. The door is closed before it can be opened. Sound, and worth saying out loud (F-8) |

---

## 9. ROUTING items

* **R3 — CLOSED by this agent, by measurement** (§4). The residue was not immobile: three more movers.
* **R1 — still "UNMEASURABLE TODAY", and now measurably so.** The D3 question (*does a bank rail reach
  `staleRailRecordRead`?*) cannot be asked on this binary for a reason stronger than W2/W3: the whole
  bank population dies at `declineTaintEscapes` (`CQLoweringPass.cpp`), which is ABOVE `lowerLoops`, and
  `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`). Measured on the owner's file: the
  promoter fires and the decline is the next thing that happens. The refusal STAYS; the measurement is
  deferred to the increment that creates its subject. Round 1 must be told this in these words.
* **R2 — still OWED, unchanged.** No accept path exists, so D1's byte-identity measurement cannot be
  taken. This gate did not take it and does not claim it.
* **R4 — untouched** (it is addressed to whoever next quotes `SCOPE_L1a` §5/§7).

---

## 10. What this agent could NOT do

1. **A Rule-13 opinion on A×B.** I measured the composition; I did not review it. §2.5's differential
   says the two predicates agree on every customer and that the real one is strictly stricter
   everywhere else — that is Rule 2's *necessary*, not its *sufficient*. Filed as **F-1**.
2. **Re-run Track B's injection matrix against the real carve** (F-3). It mutates the BINARY, one clause
   per mutant, ~22 rebuilds.
3. **Extend `loop_twin_matrix.py` with Track S's four cells** (F-7, §7.3).
4. **Adjudicate the three newly-found Track-S movers individually** beyond reading their sources and
   matching them to the class (§4.2). They are genuine by shape; whether any is an over-decline in the
   D4 sense is a question for the pairing increment.
5. **Anything requiring the deferred half** — the taint rule, the type rewrite, the D5 allow-list. Every
   statement in this report about rail banks is a statement about programs that DECLINE.
