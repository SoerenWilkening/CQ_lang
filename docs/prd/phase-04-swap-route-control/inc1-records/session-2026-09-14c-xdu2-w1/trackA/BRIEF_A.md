# Track A — IMPLEMENTATION brief: the rail-bank CARVE CLASSIFIER (bd `xdu2` / L-1a, clauses C1–C4, C2′, C6)

Worktree `/Users/sorenwilkening/Desktop/CQ_xdu2A`, branch `railbank-carve` (off `main` `6db48142`).
Records: `$SES/trackA/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/`;
`$SESP` = `…/session-2026-09-14-orchestrator/`; `$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST, in this order:** `$SES/PROTOCOL.md` (**binding — it is the verbatim 2026-09-14 protocol,
gate table and all**), `$SES/DECISIONS.md` (**three owner rulings taken at session open; D1 and D3 are
yours**), `CLAUDE.md` (Prime Directive; Rules 1, 2, 3, 5, 6, 8, 9, **11**, 12, **13**, **14**, **17**,
19; CORRECTNESS RISK §3 **L1/L2/L3/L4/L6/L7**; §4c the bd `z9t1` disclosure **verbatim**),
`$SESP/trackL/SCOPE_L1a.md` (**the design of record — §0 H1–H4, §2 the clause table, §3 the round-2
answer, §4 the fence enumeration, §8 what it could NOT turn into a predicate**), `bd show xdu2`
(**including its 2026-09-14 note, which measures its own description FALSE in three places**),
`bd show 21re`, `bd show z9t1`.

---

## 0. ⚠ THE STAGING CONSTRAINT — READ THIS BEFORE YOU PLAN ANYTHING

**Your `Bank` verdict does NOT relax the `kMsgStore` decline this session, and that is a correctness
requirement, not a scope preference.**

W1 is three pieces. Two of them — the **taint rule** (a `load` from a `!cq.railbank` alloca is tainted)
and the **type rewrite** (`[N x i1]` → `[N x i32]`), together with the **D5 allow-list** — are
deliberately NOT this session (they carry the round-2 window and they need you and Track B landed
first). Until they land, an *accepted* bank is a **silent miscompile**, and SCOPE_L1a §4.4(D) names the
mechanism exactly:

> `cq_measure(b[i])` on an **untainted** load takes `MeasureLowering.cpp:151`'s classical split and
> emits **no gate, no symbol, no trace line** — and the golden byte-diff cannot see a measurement that
> was never emitted.

So: **`RailBankCarve::Bank` falls through to the existing generic `kMsgStore` decline**, exactly as
`QramCarve::NotQram` does today. What you ship is a **classifier plus a decline matrix**, and the
accept path is pinned by a debug anchor rather than by a lowering.

**This is a STAGED LANDING of one capability, not Rule 17's punt.** Say so in the source, in every
fixture header, and in `IMPL_A.md`. Rule 17 forbids substituting a decline for the hard work; it does
not forbid landing a multi-piece capability in the order that keeps the tree sound at every commit. If
at any point a clause tempts you to decline the *thing we set out to build* rather than an off-pattern
*input*, stop and come back to the orchestrator.

**L8 RETIREMENT TRIGGER — write it into every fixture header and into the classifier's own header,
character-for-character as the thing that will fire:**
> *"When the L-1a taint rule + type rewrite + D5 allow-list land (bd `xdu2`, the second half), the
> `Bank` verdict stops falling through to `kMsgStore` and this file's RUN line becomes an ACCEPT whose
> emitted stream is `<…>`. Re-derive it then; do NOT delete it."*

⚠ Rule 12 hygiene defect (c) — *"a decline fixture that goes green because its subject no longer exists
pins nothing"* — is the live hazard for the `Bank` path, because today its observable behaviour is
identical to doing nothing at all. **The `Bank` verdict MUST be pinned non-vacuously**: emit it on the
existing `CQ_CTRL_DBG` debug channel (grep the tree for how `CQ_CTRL_DBG` anchors are printed and
FileCheck'd — Track F used one as a byte-identical anchor against the oracle) and write fixtures that
match the anchor. A `Bank` fixture whose only check is the unchanged `kMsgStore` string pins **nothing**
and will be treated as a finding at review.

---

## 1. What you build

**One new public entry point beside `qramCarveVerdict`, in the QRAM TU** — `ir-pass/src/QramLowering.cpp`
+ `ir-pass/include/QramLowering.h` — so it can call the **file-local** `walkPtrOrigin`
(`QramLowering.cpp:316`), `matchAddressGep` (`:398`), `isDirectOriginPtr` (`:371`) and `matchQramAccess`
(`:446`, anonymous namespace) **without exporting them** (SCOPE_L1a §2, the carve/emitter discipline
paragraph; §0 H4 corrects three citations bd `xdu2` gets wrong — verify them yourself, Rule 11).

Consulted from the carve switch in `declineTaintEscapes`, `ir-pass/src/TaintPropagation.cpp` — **a
second switch beside the QRAM one at `:925-940`**, reached only after `QramCarve::NotQram` (a
classical-address / value-tainted store is precisely `NotQram`'s documented population,
`QramLowering.h:53-55`, implemented `QramLowering.cpp:985-987`).

**Strawman signature — publish your real one to `$SES/trackA/SIGNATURE.md` and REPORT IT TO THE
ORCHESTRATOR IN YOUR FIRST MESSAGE; Track B is coding against it in parallel.** Deviate freely, but
publish within your first working hour and state the deviation:

```cpp
enum class RailBankCarve {
  NotBank,          // not a rail-bank cell write at all — fall through to the existing owners
  Bank,             // C1–C4, C2', C6 all hold.  ⚠ STILL DECLINES this session (§0)
  RejectShape,      // C1
  RejectIndex,      // C2'
  RejectWidth,      // C3
  RejectAlias,      // C4
  RejectTotality,   // C6
};
RailBankCarve railBankCarveVerdict(const llvm::StoreInst *SI, const TaintSet &taint,
                                   llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                                   llvm::ScalarEvolution &SE, const char *&outMsg);
bool isRailBankAlloca(const llvm::AllocaInst *A);     // metadata-keyed, §4.3
bool railStoredToRailBank(const llvm::Value *H);      // the durable membership record, §4.3
```

### 1.1 ScalarEvolution is NOT available at the carve today — and there is a precedent to CALL

`declineTaintEscapes` builds `DominatorTree` and `LoopInfo` **on demand**
(`TaintPropagation.cpp:926-929`, `DT.emplace(F); LInfo.emplace(*DT);`). There is **no** `ScalarEvolution`
anywhere in that file. C2′ needs one. **Rule 14: the tree already spells this twice** —
`LoopLowering.cpp:4165` and `LoopUnrollPrepass.cpp:242` both construct
`ScalarEvolution SE(F, TLI, AC, DT, LI)` standalone. Read both, copy the live one, and say in
`IMPL_A.md` which you copied and why.

⚠ **`TaintPropagation.cpp:1861-1863` carries a warning that applies to you:** *"a `LoopInfo` built
mid-fixpoint would describe a loop the next iteration reshapes."* Your SE is built at
`declineTaintEscapes`, which is **pre-detection and pre-flatten**, so it sees the source loop — which is
what C2′ wants. **State that in writing**, do not inherit it.

### 1.2 The clauses

`SCOPE_L1a.md` §2 is the table and it is authoritative; this is what is BINDING on top of it.

* **C1 — non-escaping bounded alloca.** `walkPtrOrigin` (rejects `isArrayAllocation()` VLAs and
  non-`ArrayType` allocated types) + `isDirectOriginPtr` (provable zero net base offset) + the
  alloca-WIDE user scan of `processShadowAlloca` (`:1936-1975`) admitting only access GEPs, a
  constant-zero `llvm.memset` and lifetime markers.
  ⚠ **OWNER RULING D1 CHANGES THIS CLAUSE.** `$SES/DECISIONS.md` D1: an alloca with **NO initializer at
  all** is admitted as well as one with a constant-zero memset, because the owner's file writes
  `bool b0[3];` and bd `z9t1` already rules that an `undef` seed at a SOURCE `cq_theta` becomes the
  type's concrete zero at the allocation. You are **composing with `z9t1`, deliberately**. Carry the
  three `z9t1` retirement triggers (`CLAUDE.md` §4c) into your header as a second customer, and carry
  the **disclosure** obligation: the composition turns a loud refusal into a silent compile, no fence can
  separate the readings after `-O1`, and **no warning is added** (owner, 2026-09-14: *"both codes are
  supposed to compie!! also no warnings."*). A disclosure owes two halves — the rival reading stated
  **as a program**, and why it has **no lowering to be robbed of**.
* **C2 — classical index.** `matchAddressGep(..., requireTaintedIndex)` at `:398`, decisive `:421-422`.
  Call it with `requireTaintedIndex=false` **and then require the NEGATION**: a tainted index must fall
  to 7.5's owner and keep 7.5's own string. **The axes are already separated; keep them so.**
* **C2′ — INJECTIVITY. NEW, and Prime-Directive load-bearing.** The index must be an affine
  `SCEVAddRecExpr` of the enclosing loop, unit step, start 0, with the loop's **constant** max trip count
  `≤ N`. ⚠ **Read the constant-max BTC as an `APInt` at its own width** and carry a
  **reachability-total** conjunct: `CLAUDE.md` Rule 18 records `getSmallConstantMaxTripCount` returning
  `4294967295` on some vacuous bounds and `0` on others, so **neither return value distinguishes
  vacuity**. ⚠ Do **NOT** reuse `hasFiniteClassicalTripBound` (`LoopLowering.cpp:1239`) — it is the 7.4
  `break` path and answers a different question; **cite it, do not call it**.
  *Why it is load-bearing:* if two activations can write one cell, a later trip's SEED load reads a
  previously-stored HANDLE and Track B's promotion forwards the wrong value.
* **C3 — cell width.** `abiWidthFromType` (`OpcodeSupport.cpp:230`) then **`widthHasReversibleCopy`**
  (`:267`, `{i1,i8,i16,i32,i64}`). ⚠ **NOT `.empty()`** — `OpcodeSupport.h:88-91` is explicit that `i128`
  has a width string and no reversible copy. ⚠ `matchQramAccess` **never looks at `StoreVal`** except the
  pun fence at `:476-484`; the value-side taint + width test is genuinely new code.
* **C4 — no aliasing fan-out / no mixed use.** `matchQramAccess`'s `GEP->hasOneUse()` (`:467-469`) +
  the C1 scan's `kMsgQramMixed` arm. **CALL `matchQramAccess`; do not re-spell the provenance walk**
  (Rule 14; the drbq Inc-3 (b′) precedent).
  ⚠ SCOPE_L1a §8.1: **this clause's negative has no `-O1`-floor spelling** — `-O1` CSEs or sinks every
  two-user GEP the scoping agent tried. You must write it as **hand IR**.
* **C6 — TOTALITY. NEW.** Every cell of the bank is stored before any cell is loaded, and `N` equals the
  proven trip count. *Why:* after the (later) type rewrite a never-written cell reads as handle `0`,
  and `h0` is a **live rail** in this runtime (`cqrt_alloc_i1(0) -> h0`). With C2′'s `{0,+,1}` index, a
  constant trip count equal to `N`, and no early exit, it holds. The no-quantum-exit half is
  `taintedExit` (`LoopLowering.cpp:1073`).

### 1.3 The membership record — metadata, NEVER a `Value *` set

`!cq.railbank` on the `AllocaInst`, carrying the element ABI width; the `!cq.branchphase` pattern
(`markBranchPhaseGate`/`isBranchPhaseGate`, `ChainWalk.cpp`) is this project's answer to *"a durable
membership record no RAUW can dangle"*. ⚠ **`TaintPropagation.h:198-225` forbids the obvious spelling
and records it as a silent miscompile** — *"THERE IS NO `ControlledRotationRails` MEMBER, AND ITS
ABSENCE IS THE FIX … the set then held a dangling pointer … `opt` exit 0, verify-clean, a hidden
measurement."* **Read that function's header before writing any `Value *`-keyed owner set.**

### 1.4 The D3 ruling — the `staleRailRecordRead` grouping key

`$SES/DECISIONS.md` D3: **refuse loudly, then measure.** A bank rail has no root mint, so it cannot be
grouped by `ChainsByRoot`/`ByRoot` at all; `(alloca, index SCEV)` is SCOPE_L1a §8.2's **unmeasured**
proposal and the owner ruled it is **not** built this session. Your obligation is **not** to build the
key. It is to:
1. state in `IMPL_A.md` **exactly where** the refusal conjunct will sit and **what it will test**, and
2. hand Rule-13 round 1 the measurement question: *does the owner's cascade actually reach
   `staleRailRecordRead`?* If round 1 measures that it does, the refusal becomes an **over-decline** and
   the key must be built — that goes back to the owner, not into a quiet stub (D3's Rule-17 note).

---

## 2. L1, L2, L3 — answer these in writing in `IMPL_A.md`, they are not rhetorical

* **L1 (the round-2 window).** Control detect+lower run TWICE. SCOPE_L1a §3 answers it for you and you
  must **VERIFY it, not inherit it**: the carve verdict is a **pure predicate**, and
  `adjudicateTaintDelta` (`TaintPropagation.cpp:1609`) re-runs `declineTaintEscapes` at `:1645`, which
  `repropagateControlMerges` goes through — so the carve is **re-asked at the fixpoint automatically, in
  BOTH entry points**. Prove it by reading both entry points (`CQLoweringPass.cpp` ~`:455`/`:489` and
  ~`:942`/`:948`) and say so. A relaxation here is symmetric by construction **iff** that holds.
* **Does it GROW the taint set?** Your piece must not. Say so explicitly. (The taint rule that does is
  the piece deliberately deferred, §0.)
* **L2 (widen a set → what OTHER set shares the closure).** You widen no rail set this session. State
  that, and state per entry of SCOPE_L1a §4.5's list that it holds.
* **L3's MIRROR — the one that cost a P1 filing on 2026-09-14.** You are ADDING A CALLER to
  `walkPtrOrigin`, `matchAddressGep`, `isDirectOriginPtr` and `matchQramAccess`. **Read each callee's
  retirement trigger / header caveat and state which DIRECTION you are using it in.** `WireWalk.h`'s
  precedent: a shared predicate said "NOT EXPLOITABLE *for the callers it then had*" and instructed the
  next caller to widen the vocabulary or fence itself in the same change; a third granting caller
  arrived, nobody read the trigger, and it is `IMPL_D.md` §15.4, open, P1.
* ⚠ **`f2SeedPinnedByLiveRegister`'s RETIREMENT TRIGGER, `ArmClassify.cpp:1283-1295`** — *"if
  `railWireClosure` as called here and R4's `CondRails` ever DIVERGE … this narrowing must be
  RE-DERIVED FROM SCRATCH."* SCOPE_L1a §4.4(C) is explicit: **teaching `railWireClosure` a memory hop
  trips it. Do NOT teach it one.** If your design drifts toward a memory hop in any wire walker, stop
  and report — that is the F2 narrowing the owner's own three-bool file depends on. (Track X is
  re-deriving the *neighbouring* `om35` trigger this session; coordinate through the orchestrator, do
  not edit `ArmClassify.cpp`.)

---

## 3. Rule 12 — fixtures FIRST, red-green

~**12 decline fixtures**, one per clause, each mirroring its diagnostic **character-for-character**,
plus the `Bank`-verdict anchor positives. SCOPE_L1a §6.1 lists them; the named starting probes live in
`$SESP/trackL/probes/`:

| clause | fixture | note |
|---|---|---|
| C1 | `N1` VLA bound · `N2` escaping address · `N3` global array · **non-zero initializer** | all four `kMsgStore` today |
| C1/D1 | **`L7_array_uninit` becomes a `Bank` POSITIVE** (owner ruling D1) | it is `kMsgStore` today; after you it is `Bank` + still `kMsgStore` + the anchor |
| C2 | `N4` tainted index | ⚠ **must keep 7.5's string**, not a new one |
| C2′ | `N5b` non-injective variable index (`b[i>>1]`) | ⚠ `N5_double_write` is **DEGENERATE** — `-O1` SROAs it to scalar spelling (ii) and it takes the §3c clobber; do not use it |
| C3 | unsupported cell width (`_BitInt(96)` / `long double`) | owed — `L8_array_int_cells` is an **accept-side** probe, not a negative |
| C4 | aliasing fan-out | ⚠ **hand IR only** (§8.1) |
| C6 | over-sized bank (`bool b[8]`, `for (i<3)`) | owed |

**Hygiene — all three defects have each shipped through a green suite:**
* counts go in their **own whole-file prefix** (a positive `CHECK-COUNT` inside a negative prefix
  **windows** every negative after it — caught by 0 of 20 blocks);
* a `DS_Error` decline writes **0 bytes to stdout**, so a decline fixture's IR-text `CHECK-NOT`s are
  **vacuous** — the property is pinned by the `not` on the RUN line;
* a bare `-NOT: <word>` can match the module's own path/header line (bd `qta2`);
* run `$PREV/trackM/probes/impl/vacuity.py` over **every** new accept-fixture batch;
* ⚠ **`LLVMContext::diagnose` EXITS on the first `DS_Error`** (bd `br4a`) — a fixture pins **ONE**
  diagnostic. Do not write a fixture expecting two.
* **Reuse one `%cq-opt … > %t.cqd0.ll`** and point every extra `--check-prefix` at that file;
  `ir-pass-lit` is SPAWN-bound and adding `opt` invocations is not free.

---

## 4. Rule 13 — budget FOUR rounds for the increment; round 1 is scoped for you

SCOPE_L1a §6.5: **four, not three.** L-1a gives the C-1 in-loop entangled-rail family its **first
memory-resident subject** and touches the `collectRailGates` walk whose F-1/F-3 pair were confirmed
silent miscompiles. **Round 1 is scoped to SCOPE_L1a §4's fence enumeration alone.**

You do not run the review; the orchestrator spawns it. `IMPL_A.md` must hand the reviewer a written
**ATTACK SURFACE**: every predicate you touched, every callee whose retirement trigger you read and in
which direction, the L1/L2/L3 answers, the D1 composition disclosure, the D3 refusal site, and **the
three programs you think are most likely to be the next hole**.

---

## 5. Gates you own — PROTOCOL §matrix, do not exceed it

Configure + build **once per edit batch** (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release`, then `cmake --build build -j8`).
⚠ **NEVER `--target CQPass` alone** — `cq-opt` is a separate target from the same sources and a
CQPass-only rebuild leaves lit on a STALE binary reporting FALSE GREEN (measured: 100% pass on a
knowingly broken pass, then 49 reds). Record `shasum -a 256 build/ir-pass/cq-opt` in
`$SES/trackA/GATES.md` after **every** rebuild, in the PROTOCOL's line format.

Inner loop = `cd build && lit -v ir-pass/test --filter '<name>'` (1.5 s) + single e2e slices (1.7 s).
**ONCE at hand-off:** `ctest --test-dir build -R ir-pass-lit`, one ORACLE-vs-SUBJECT corpus sweep →
`$SES/trackA/probes/corpus_<hash16>.txt`, one injection (mutation) matrix with **MISSED reported**.
**NEVER** the full suite, **NEVER** `^e2e-`, **NEVER** the equivalence sweep, **NEVER** the twin matrix.

⚠ **ORACLE** for this session (read-only, frozen): the primary checkout's
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`. `shasum -a 256` it before your
first probe; if it differs, **STOP and report**. The primary `build/` is **READ-ONLY** — never relink a
binary under a running measurement, never `pkill` by pattern.

⚠ **Expected corpus movers: DECLINE→DECLINE rows only, where the ORACLE string was `kMsgStore` and
yours is a new per-clause string.** ⚠ **ANY `DECLINE→ACCEPT` row is a FINDING and must stop you** — §0
says your accept path does not exist yet. ⚠ `$SES/PROTOCOL.md` S3: the shared `corpus.sh` tag regex
renders the whole `cq_measure_<sfx>` family as an empty `D:`, so a decline→decline string change inside
it is **INVISIBLE** — close it with a full-stderr + exit byte-compare over the decline rows. Lowered-IR
md5s are **NOT comparable across sweeps**.

---

## 6. Deliverables

`$SES/trackA/{IMPL_A.md, SIGNATURE.md, GATES.md, probes/}`: the signature (published in hour 1 and
reported to the orchestrator), the clause table as SHIPPED with each predicate's `file:line`, the
L1/L2/L3 answers, the D1 composition disclosure in the two-halves form, the D3 refusal site and its
measurement question, the fixture table, the corpus movers with the stderr byte-compare, the mutation
MISSED count, the vacuity-check output, and the attack surface.

Commit on your branch (**no push, never touch `main`, never write outside your worktree**), message
`feat(taint): bd xdu2 — …` with the two `CLAUDE.md` trailers. Report back: branch tip, binary hash,
gate lines in the PROTOCOL format, the fixture table, the round budget, and **anything you could not
do**. **Rule 19: report only what you ran** — "lit green (N)" if you ran `ir-pass-lit`, never "tests
pass".
