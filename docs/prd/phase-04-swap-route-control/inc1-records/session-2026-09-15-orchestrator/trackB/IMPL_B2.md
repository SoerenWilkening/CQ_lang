# Track B — IMPLEMENTATION record: bd `xdu2` / L-1a Increment **W1, THE SECOND HALF**

Worktree `/Users/sorenwilkening/Desktop/CQ_B`, branch `railbank-accept`, off
`railbank-blockers` `9e11f524` (Track A's tip — **NOT `main`**).
Every number below was MEASURED with the command shown (Rule 19). Gate lines: `GATES.md`.
One-page statement of what now compiles: `CLAIM.md`.

**ORACLE** (frozen, read-only), verified at track open and unchanged:
`cq-opt` `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`,
`libCQPass.so` `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b`.

**BASE** (`railbank-blockers`, built clean in this worktree): `cq-opt`
`b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf`,
`libCQPass.so` `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a`.
⚠ **BIT-IDENTICAL to Track A's SUBJECT** — so "base" here is Track A's own
measured binary, and Track A's gate lines about it are citable as facts about
mine.

**SUBJECT** (final): `cq-opt`
`784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff`,
`libCQPass.so` `a4e4f6781524c569e7112f5809c2813dd250d8a1b9e02571a4095d2719ba65c6`.
⚠ **Two earlier subjects are cited in a few gate lines and they are NOT
interchangeable with this one**: `fe42a9ff…` precedes the width-pun fence of
§11.0, and `a81c4925…` precedes the two self-review fixes of §7. `GATES.md` keys
every line to the binary that actually ran it rather than pretending one binary
ran everything, and says in its own header that lines keyed to an earlier subject
are not citable for the final one.

**Both-binary discriminator run at every hash** (Track T's measured third form of
the false-green trap: `cq-opt` segfaulting while `libCQPass.so` from the same
build worked): the same stage-1 module through `cq-opt` and through
`opt -load-pass-plugin libCQPass.so` — same exit code, byte-identical stdout.

---

## 0. What shipped

| # | piece | files |
|---|---|---|
| 1 | **THE TAINT RULE** — a `load` from a `!cq.railbank` alloca is tainted, seeded inside `collectAndSeed` i.e. inside `propagate` | `TaintPropagation.cpp` |
| 1b | the record itself — `markRailBankAllocas` mints `!cq.railbank` on every alloca the carve calls **`Bank`** (never `BankRaw`), at the normaliser slot, followed by a full re-`propagate` | `RailBankPromote.{h,cpp}`, `CQLoweringPass.cpp` (both entry points) |
| 2 | **THE TYPE REWRITE** — `rewriteRailBankCellTypes`, `[N x cell]` → `[N x i32]` of handles, between `lowerRotations` and `lowerOps` | `RailBankPromote.{h,cpp}`, `CQLoweringPass.cpp` (both entry points) |
| 2a | **THE CAST SINK** — `applyBank` PASS G: the `_Bool` cell's storage `zext` leaves the region arm and the merge phi is built at the RAIL type | `RailBankPromote.cpp` |
| 3 | **THE D5 ALLOW-LIST** — `declineUnallowedRailBankReaders`, a POSITIVE enumeration; the `Bank` arm of `declineTaintEscapes` stops falling through to `kMsgStore` | `TaintPropagation.cpp` |
| D1 | **THE SPINE DOOR** — `isTerminalHandle` refuses a handle stored into a rail-bank cell (`railStoredToRailBank`) | `ChainWalk.cpp` |
| 3b | **THE WIDTH FENCE** — the `!cq.railbank` record carries the **rail** width; D5 admits a storage cast only to that width, and the rewrite erases only that cast. Closes a MEASURED over-accept this increment shipped first (§11.0) | `RailBankPromote.{h,cpp}` |

**+952 / −1 over 5 pass-source files** (`git diff --numstat`), of which ~400 are
non-comment lines. `SCOPE_B.md` §11 costed the increment at ~450–700 pass lines.

**Two new decline strings**, mirrored character-for-character by negative fixtures
(four negatives share the first):
* `cq rail bank: unsupported reader of a rail-bank cell` (D5)
* `cq rail bank: cell type rewrite failed on a proven bank` (the rewrite's own
  internal-failure string — see §7 for its reachability, which is **nil today**
  and recorded as such rather than pinned by a fixture with no subject)

---

## 1. THE RED — the vanishing-measurement silent miscompile, reproduced on MY OWN BASE before any fix

`probes/emulate_piece3.sh` takes the promoter's own output, deletes the one
surviving bank store **and its storage cast**, and re-runs. That emulates
**piece 3 alone**: the store stops declining and the loads stay classical.

```
$ W=/tmp/cqB_base BUILD=build sh probes/emulate_piece3.sh probes/b12_bank_bool_measureloop.c
b12_bank_bool_measureloop: emu ACCEPT, 6 trace lines
$ python3 tools/free_pairing_check.py /tmp/cqB_base/b12_bank_bool_measureloop.emu.s2.ll
free_pairing_check: 1 file(s), 1 rail mint(s) of which 1 left allocated,
                    0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven
$ cat /tmp/cqB_base/b12_bank_bool_measureloop.emu.trace
cqrt_alloc_i1(0) -> h0
cqrt_ry_i1(h0, 0x1p-1)
cqrt_alloc_i1(0) -> h1
cqrt_ry_i1(h1, 0x1p-1)
cqrt_alloc_i1(0) -> h2
cqrt_ry_i1(h2, 0x1p-1)
```

The source is

```c
bool b0[3]; int s = 0;
for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
```

**Three written `cq_measure` calls. Zero measurements in the trace.** `opt` exit 0,
STRICT stage 2b `0 violation(s), 0 unproven`, and a plausible six-line stream.
`MeasureLowering.cpp`'s classical split on an untainted operand emits **no gate,
no symbol and no trace line**, and a golden byte-diff cannot see a measurement
that was never emitted.

**THE GREEN**, same program, SUBJECT binary, real pipeline (no emulation):

```
$ sh probes/run.sh probes/b12_bank_bool_measureloop.c
b12_bank_bool_measureloop: ACCEPT  trace=9 lines | 2b: … 0 violation(s), 0 unproven
```

with the three `cqrt_measure_i1` lines present. This is why the three pieces are
ONE COMMIT: **half of this increment is worse than none of it.**

### 1b. THE SECOND RED — the spine, and it only exists outside `main`

`probes/b14_bank_nonmain.c` is the same program in a `noinline` helper, emulated
the same way on the BASE binary:

```
b14_bank_nonmain: emu ACCEPT, 12 trace lines
cqrt_alloc_i1(0) -> h0 / cqrt_ry_i1(h0, 0x1p-1) / cqrt_ry_i1(h0, -0x1p-1) / cqrt_free(h0)
… ×3
```

The spine **un-prepares and frees the three qubits the user is about to
measure**, at `opt` exit 0 with stage 2b reporting `1 verified, 0 violation(s),
0 unproven`. Inside `main` it cannot happen (`FreePoint.cpp:182-183`
short-circuits every handle to `Escaped`) — and that exemption covers almost
nothing: **76 of 80 sampled `tests/e2e/slice_*.c` carry quantum work outside
`main`**. The store-KEPT disposition outside `main` is the loud over-decline
`cq uncompute: tainted handle reaches an unrecognized user`, so **D1 is a
PRECONDITION of the accept, not a safety net** — without it the canonical W1
slice written in the house style does not compile at all.

**THE GREEN:** `tests/e2e/slice_railbank_nonmain.c`, registered, 9-line golden
with no `cqrt_free` and no negative-angle `cqrt_ry`, STRICT 2b
`1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s)`.

---

## 2. What now compiles (the accept surface), measured

`probes/run.sh`, SUBJECT binary. Every row was `DECLINE cq taint escape: tainted
value stored to memory` on the BASE.

| probe | verdict | trace | STRICT stage 2b |
|---|---|---|---|
| `b07_bank_uncond` (constant-index measures) | **ACCEPT** | 9 | `1 mint / 1 left allocated / 0 free sites / 0 violation(s)` |
| `b08_bank_zeroinit_uncond` | **ACCEPT** | 9 | same |
| `b11_bank_int_measureloop` (`int` cells) | **ACCEPT** | 9 | same |
| `b12_bank_bool_measureloop` (**the canonical shape**) | **ACCEPT** | 9 | same |
| `b13_…_zeroinit` (the D1/R2 twin) | **ACCEPT** | 9 | same |
| `b14_bank_nonmain` (`noinline` helper) | **ACCEPT** | 9 | same |

and, unchanged and still declining, the shapes that must:

| probe | verdict |
|---|---|
| `b06_bank_classical_cond` | `cq taint escape: tainted value muxed by a classical-condition phi` |
| `b10_bank_int_cells_uncond` | `cq rail bank: array mixes a rail cell access with an unrecognized one` (the `-O1` byte-offset gep — **not widened**, §7) |
| `d5a` / `d5b` / `d5c` | `cq rail bank: unsupported reader of a rail-bank cell` |

---

## 3. R2 — the D1 byte-identity measurement, TAKEN ON THE REAL ACCEPT

Owner ruling D1 composes the uninitialised `bool b0[3]` with bd `z9t1`, but
**`z9t1`'s `normalizeUndefRotationSeed` does not reach a MEMORY seed**, so D1
rests on **C6 totality alone** — a claim whose witness was future. It is now past.

**Population:** every accept the increment lands, paired with its written-`= {0}`
twin — `b07`/`b08`, `b12`/`b13`, and the slice pair
`slice_railbank_bool_prep_measureloop{,_zeroinit}`. **The pairing is by PROGRAM,
not by module**, and the instrument is the TRACE, not an IR diff: the zero-init
twin carries an extra `llvm.memset` that an IR diff would report and no emitted
gate can see.

**Command and result:**

```
$ diff tests/e2e/slice_railbank_bool_prep_measureloop.expected.log \
       tests/e2e/slice_railbank_bool_prep_measureloop_zeroinit.expected.log
$ shasum -a 256 tests/e2e/slice_railbank_bool_prep_measureloop*.expected.log
0eaaad138bbf2d2157ba2c7a1297d1c83dc0b399b93c1df851372a2b0690b7a0  …measureloop.expected.log
0eaaad138bbf2d2157ba2c7a1297d1c83dc0b399b93c1df851372a2b0690b7a0  …measureloop_zeroinit.expected.log
```

**DIVERGENCE COUNT: 0.** `diff` empty, equal sha-256, over 3 program pairs
(`b07`/`b08`, `b12`/`b13`, the slice pair). It is now a **gated** property:
`e2e-railbank-uninit-zeroinit-twin-identical`.

**AND THE STREAM IS THE FLAT TWIN'S, BYTE FOR BYTE.** Track I's
`w1_flat_prep_only.c` — three scalar `_Bool`s, three preps, three measures, no
array anywhere — produces the same 9 lines with the same sha-256, on the ORACLE.
Committed as `tests/e2e/slice_railbank_flat_twin.c` and gated by
`e2e-railbank-flat-twin-identical`, so the byte-identity witness `SCOPE_L1a.md`
§5 asked for is a ctest entry rather than a note.

⚠ **What the two gates do NOT witness**, said in the file headers as well as
here: the byte identity is about the emitted STREAM. It is not about the unitary
(Rule 2) and not about rail identity (that is stage 2b's, and the two programs
differ there by construction — three alloc SITES in the flat twin, one rolled
site per function in the bank).

---

## 4. The walls of the owner's program — MEASURED, and the honest claim

`example/grover/grover_oracle_uncompute.c`, code body committed verbatim as
`tests/e2e/slice_railbank_owner_cascade.c` (see §6).

| # | wall | BASE | SUBJECT |
|---|---|---|---|
| 1 | `cq taint escape: tainted value stored to memory` | fires | **gone** (W1 piece 3) |
| 2 | `cq controlled lowering: value-arm swap-route under quantum control` @ the arm's `zext i1 %q to i8` | behind 1 | **gone** (W1 piece 2a) |
| 3 | `cq controlled lowering: control flow inside a loop body under quantum control` | behind 2 | **FIRES** — `iterationLocalRollable` (c3), bd `8h7d.11` |
| 4 | `cq loop lowering: loop-carried tainted value crosses iterations` | behind 3 | behind 3 — X1 / bd `ej5w` / W3 |

Measured on the SUBJECT: `opt` exit 1, `…:83:15: cq controlled lowering: control
flow inside a loop body under quantum control`. Walls 1 and 2 are the two E5
assigns to this track and both are gone; wall 3 is what the program now hits.

**The closing claim, in the words ruling E5 requires: *the bank compiles; the
owner's cascade needs (c3) + W3.*** Not "the decline moved".

⚠ **Rows 3 and 4 are BANK-INDEPENDENT and W1 could never have moved them.**
`probes/b02_scalar_measure_a_outside.c` is the same loop with a SCALAR `bool` and
no array at all and declines row 3 identically; `b05_scalar_classical_acc.c`,
identical but with the arm not feeding `a`, ACCEPTS. The discriminator is the
tainted loop-carried accumulator.

⚠ **THE FOUR-WALL TABLE IS STILL NOT EXHAUSTIVE**, and this track did not make it
so. `LLVMContext::diagnose` EXITS on the first `DS_Error`, so each row is only
"the first decline once the row above is gone". This track now has a binary on
which rows 1 and 2 are GENUINELY absent (not hand-removed), which is new — and it
confirms row 3 and nothing beyond it. **Rows beyond 3 remain unmeasured: whoever
lands (c3) + W3 must run the sequence forward on the real subject binary and
REPORT ITS LENGTH, not assume four.** That obligation is carried in the slice's
own header.

---

## 5. The cast sink (2a), and why it is not a headline widening

The owner's `_Bool` cell forces `clang -O1` to put a `zext i1 %theta to i8`
**inside the region arm**, and the promoter then built its merge phi at the CELL
type. Measured on the BASE (`derived/B2_nostore.ll`): the arm classifies as a
VALUE arm and the module declines `value-arm swap-route`, **anchored at the
`zext` itself**. With the phi at the rail type and no cast in the arm
(`derived/B3_i1cell_nostore.ll`) it gets past.

The cast **cannot simply be deleted**: `store i1` into an `i8` cell makes the
carve answer `NotBank` at the **PUN FENCE** (`QramLowering.cpp`,
`StoreVal->getType() != CellTy`), whose header carries a retirement trigger in
BOTH directions — it and `matchQramAccess`' twin are one fence with two spellings
and neither moves without the other. **It was not moved.**

So the cast is **SUNK** to the activation-end store. The promoter now emits

```llvm
25:  %26 = call i1 @cq_theta_i1(i1 false, double 0.5)
     br label %27
27:  %cq.bank1    = phi i1 [ %26, %25 ], [ false, %21 ]
     %cq.bank.stg = zext i1 %cq.bank1 to i8
     store i8 %cq.bank.stg, ptr %cq.bank.addr, align 1
```

— measured verbatim on the owner's file, and the carve still answers
`railbank [Bank] cells=3 abi=i8 trips=3`.

⚠ **IT FIRES ONLY WHEN THE STORE'S VALUE IS A `phi`**, i.e. only on the
conditional-arm shape, which is **entirely the declining population today**. An
unconditional per-trip prep has no phi and its cast already sits directly in
front of the store; the module is byte-unchanged. **So 2a cannot move any accept
— it can only move a decline STRING (wall 2 → wall 3).** That is why it is inside
this increment's scope and not a step toward the headline.

The equivalence is `trunc(zext(x)) == x` and `trunc(0) == 0`, exact because every
incoming is a ZERO-extension from one common rail type or the zero constant and
every other user is the matching truncation. `sext` would be equally exact and is
**deliberately not admitted** — `-O1` does not emit it for a `_Bool` cell, so
admitting it would widen the population past the one this was measured on.

---

## 6. E4 — the owner's program committed as the record

`tests/e2e/slice_railbank_owner_cascade.c`, **deliberately UNREGISTERED and with
NO GOLDEN**, following the `slice_control_switch_phase.c` (2026-09-05) and bd
`3d8q` (2026-09-14) precedent: it still declines, and the e2e layer has no
decline shape (`run_slice*.sh` runs under `set -euo pipefail` and byte-diffs a
golden). Its decline is pinned in the **lit** layer by the four re-derived
`lowering_railbank_bank_anchor_*` fixtures, which mirror the string
character-for-character.

**The code body was taken from THE FILE, by the recipe, never from a brief.**

```
$ sed -n '83,95p;129,131p' example/grover/grover_oracle_uncompute.c | shasum -a 256
bf3b96de04ef60e577cdfa5a05392ee5fd0d75fd89aa0652d24ab4ff6cf0dbf1
$ diff <(sed -n '83,95p;129,131p' example/grover/grover_oracle_uncompute.c) \
       <(tail -16 tests/e2e/slice_railbank_owner_cascade.c)      # empty
```

The recipe is in the slice's own header, so a future reader can re-take the diff.
The active body is **not contiguous** in the owner's file (lines 83–95 then
129–131, with 34 lines of commented-out earlier spellings between), the trailing
space on the blank line inside the loop and the double space in
`cq_measure(b0[1])  + cq_measure(b0[2])` are the owner's and are preserved.

⚠ The orchestrator's original E4 claim that the live file *"matches the session
brief's reproduction exactly"* is **false** and is recorded as false in the slice
header: it was an eyeball comparison reported as a measurement.

⚠ **bd `zwtm` does NOT close here.** It closes when (c3) + W3 land and the slice
is registered with a golden. The header carries that as its L8 trigger.

---

## 7. What was NOT built, and why — each with a measurement

* **D5 allow-list entry (3)** — *a further store into a rail-bank cell* — was
  implemented and then **REMOVED**. Measured: on `probes/d5d_bank_to_bank_copy.c`
  (`for (i<3) b1[i] = b0[i];` between the write loop and the measure loop)
  `clang -O1` **forwards the copy and deletes the second array outright**, so the
  module that reaches the pass has exactly ONE bank and the entry never fires. An
  allow-list entry with no customer is Rule 12 hygiene defect (c) — an ACCEPT
  DOOR in a Prime-Directive fence that no fixture can hold open. Removing it
  NARROWS the accept. Pinned by `railbank_accept_bank_copy_folded.ll`, which is a
  TRIPWIRE: if a future `clang` stops folding, the surviving store becomes an
  unadmitted reader, the module declines, and that fixture's RUN line (no `not`)
  goes red.
  ⚠ The removal also took a customer off **bd `yiid`**: a surviving copy makes two
  names denote one rail, so measuring both banks emits `cqrt_measure_i1(h0)` twice
  on one qubit. **MEASURED ALSO WITHOUT ANY BANK** —
  `probes/d5f_scalar_double_measure.c` (`cq_measure(q) + cq_measure(q)`, no array)
  compiles to the same double measurement on the SUBJECT *and* on the BASE — so
  that boundary is bd `yiid`'s and this increment neither creates it nor adds to it.

* **`cq rail bank: cell type rewrite failed on a proven bank`** has **no fixture,
  because it has no reachable subject at HEAD** — but it HAD one, and this
  track's own self-review found and closed it, which is the more useful fact.
  The rewrite's initializer test was first written as a TYPE INEQUALITY (*the
  stored value's type differs from the cell type*) while the carve's C1 asks
  `isWholeObjectZeroStore`. The two DIVERGE on a one-cell bank: for `[1 x i8]`
  the whole-object zero **is** a `store i8 0`, so the carve files it as an Init
  and the rewrite filed it as a CELL STORE — and PASS 4 would then fire this loud
  string on a shape the carve had proven. It is now asked by CALLING the carve's
  own predicate (Rule 14); a divergence between a rewrite and the carve that
  licensed it is the drbq Inc-3 (b′) defect in miniature.
  ⚠ **That route is a READING, not a measurement, and the distinction is the
  point.** It was found by putting the two predicates side by side, and this
  track could **not** construct a `-O1` module that reaches it: `bool b0[1] = {0}`
  with a one-trip loop has its loop deleted before the pass sees it (measured —
  no `[Bank]` anchor at all). So the fix removes a divergence whose reachability
  is unknown, in the safe direction, rather than closing a demonstrated hole. Say
  it that way; do not promote it to "a bug that was caught".
  The string stays an unconditional loud diagnostic so that an omission can never
  be silent — the rewrite's failure mode is a 4-byte write into a 3-byte object,
  which `opt -verify` CANNOT SEE (§8). **Recorded rather than pinned**, with the
  route that existed written down.

* **The `int`-cell bank with CONSTANT-INDEX measures** still declines
  `cq rail bank: array mixes a rail cell access with an unrecognized one`: at
  `-O1` clang emits those reads as **byte-offset** geps
  (`getelementptr inbounds i8, ptr %b, i64 4`), which the carve's cell-type
  agreement refuses. The `_Bool` bank escapes it only because its cell type IS
  `i8`. **Not widened** — it is a separate, costed question, and `SCOPE_B.md` §10
  item 4 already files it.

* **A cast with a SURVIVING consumer is left standing.** The first spelling of
  PASS 4 erased the store's storage cast unconditionally, after
  `replaceAllUsesWith(Poison)`. No clause of the carve constrains the STORED
  VALUE's other users, so a cast that still had one would have been left reading
  poison — verify-clean, wrong at run time. It is now erased only when
  `use_empty()`; a cast with another consumer keeps its `cq_template_*` lowering,
  which is what that consumer genuinely wants, and the bank stores the raw handle
  either way.

* **`FreePoint::isRecognizedEscapeUser`** was NOT taught about a bank store.
  `SCOPE_B.md` §5.2 recommended both doors; with `isTerminalHandle` refusing the
  nomination at source, `computeFreePoint` is never reached for a parked rail, so
  the second door has **no subject** and would be an unpinnable predicate (hygiene
  (c) again). Leaving it blind is the SAFE direction: a future path that does
  nominate such a handle gets a loud decline, not a silent free.

* **`LoopLowering.cpp` was not touched at all**, exactly as the brief required.
  D3's ruled decline is realised by NOT WIDENING and costs zero lines there: a
  bank LOAD cannot become a `staleRailRecordRead` member without a `LoadInst` arm
  in `peelInPlaceStep`, and there is none in the file.

---

## 8. Two things the verifier cannot see, written at their sites

1. **After `lowerRotations`, `store i32 %h, ptr %cell` into a `[3 x i8]` alloca is
   WELL-TYPED.** Opaque pointers give a `store` no pointee constraint, so a
   4-byte write into a 3-byte object is `opt -verify` clean. Retyping the object
   (PASS 1) is therefore semantically load-bearing and invisible to the verifier —
   Rule 2's exact shape. Injection mutant **M3** (skip PASS 1) confirms `opt`
   stays at exit 0 and the verifier stays silent; it is caught by the accept
   fixtures' IR checks and by nothing else.
2. **A `!range` whose type no longer matches the instruction is a VERIFIER
   ERROR**, not cosmetic staleness — `clang` puts `!range !{i8 0, i8 2}` on every
   `_Bool` cell load. The rewrite drops `!range` and `!tbaa` on every retyped
   memop. (This one the verifier *does* catch, which is why it is worth saying
   that the other one it does not.)

---

## 9. The L1 (round-2) answer, stated for each new stage

* **The taint rule** lives inside `collectAndSeed`, i.e. inside `propagate` — the
  single funnel BOTH entry points and every re-propagation fixpoint come through.
  Structural, no record, no second call site (the same argument bd `z9t1`'s seed
  clause makes).
* **`markRailBankAllocas`** GROWS THE TAINT SET and is sound only by its SLOT: it
  runs above every stage that adjudicates consumers of tainted values
  (`foldIdentityBitcasts`, the PredMux flattener, `unrollConstTripLoops`,
  `recognizeCtlzIdiomLoops`, `detectSpecializations`, `declineTaintEscapes`,
  `declineStaleRecordOps`, `recordStaleQuantumReaders`, the peel and both
  detection rounds), and it publishes the growth with a **full `propagate`**
  rather than a delta. Retirement trigger at the call site in both entry points.
* **D5** lives *inside* `declineTaintEscapes`, which `adjudicateTaintDelta` and
  `repropagateControlMerges` both call — so the round-2 re-ask is free, with
  nothing new to remember (L1's PREDICATE species, discharged by an existing
  caller).
* **The type rewrite** is strictly after `repropagateControlMerges`, so the taint
  it reads is FINAL.
* ⚠ **The mint is placed BELOW the `CQ_RAILBANK_DBG` module dump**, deliberately:
  seven shipped `railbank_promote_*` fixtures pin `NOMD-NOT: !cq.railbank` on that
  dump, and that check is what keeps the RETIRED clause **B9** retired (*the
  promoter mints nothing* — merge filing F-9). Minting above the dump would make
  all seven vacuously unable to see a promoter that started minting again.

⚠ **F-9, recorded as the trap it is.** `IMPL_B.md` §2.3 / §7 / §8 / §10.1 carry
the retired clause-B9 wording (*"NOT ALREADY PROMOTED (`isRailBankAlloca` — the
`!cq.railbank` record this stage MINTS)"*) and are HISTORY. **This increment makes
half of that wording true again**: the mint is back. It still does not license
B9 — **B8** is what terminates the promoter's fixpoint, and a membership guard
there would MASK a B8 regression rather than back it up. The mint arrives AFTER
the promoter's fixpoint has settled, so the promoter never sees it. That sentence
is at the mint's call site and in `RailBankPromote.h`, not only here.

---

## 10. F-3 — the three re-spellings: MEASURED, and the answer is "structurally shadowed"

`SCOPE_B.md` §8 asked for three fixtures to be re-spelled so the **B** clause they
claim to isolate is the sole refuser. Measured on the SUBJECT, all three are
refused by Track A's **carve** before any B-clause is asked, and a re-spelling was
attempted for each:

| fixture | clause | what refuses it | can it be re-spelled? |
|---|---|---|---|
| `railbank_promote_reject_two_cells` | **B2** | carve C6 `RejectTotality` | **NO** — measured three ways |
| `railbank_promote_reject_store_outside_loop` | **B5** | carve C4 `RejectAlias` | **NO** — Track B's scoping predicted this |
| `railbank_promote_reject_inloop_other_read` | **B4′** | carve C6 `RejectTotality` | **NO** — Track A recorded it from the other side (SIGNATURE T5) |

**B2's three routes, each measured:** a second in-`L` address with a LOAD is
`RejectTotality` (C6 requires `SE.getSCEV(LIdx) == IdxS`) — measured on the
fixture's own `b[2-i]` **and** on a purpose-built `b[i+1]` probe
(`cq rail bank: array has cells no iteration writes`); with a STORE it is
`RejectAlias` (C4's `Stores.size() != 1`); with NO user `planBank`'s own
`if (!G || G->use_empty()) return false;` refuses it ABOVE B2.

**What shipped instead of a papered-over hand-IR module** (`SCOPE_B.md` §8
forbids exactly that): each fixture keeps pinning the two things that are still
true — the module is LOUDLY REFUSED, and the promoter does NOT fire on it — and
each header now states, in the L8 retirement-trigger form, that its clause's
subject is **structurally unreachable**, which widening restores isolation, and
that the `promote bank` negative is satisfied **vacuously**.

⚠ **NO B CLAUSE WAS DELETED.** Deleting a defensive clause in a Rule-13-core
stage because a conjunct in ANOTHER FILE currently shadows it is precisely the
`MERGE_FILINGS` F-1 mistake, and B9's own retirement trigger governs the widening
that would make B5 reachable. **This is a scope question and it goes back to the
orchestrator with a measurement rather than a decision.**

---

## 11. The injection matrix — 11 mutants, **MISSED 2**, and the ONE OVER-ACCEPT IT FOUND

`probes/inject.py`. Each mutant is a source edit, rebuilt (BOTH targets), gated by
**`lit` and `ctest` THEMSELVES** — never a hand-rolled FileCheck, because *a
harness that runs a weaker command than lit measures itself, not the fixtures*.
Three holes are closed by construction: an edit whose anchor does not apply is
`EDIT-FAILED` (never `n/a`), a failed build is `BUILD-FAILED` (never CAUGHT), and
an **empty selection exits 2** rather than printing `0 mutations, MISSED 0`
(self-tested: `inject.py M9` before M9 existed → exit 2).

| # | what it breaks | verdict | caught by |
|---|---|---|---|
| M1 | **piece 1 removed** — the bank load stops being tainted (THE silent miscompile) | CAUGHT | the accept fixtures' `cqrt_measure` checks |
| M2 | the `isRailBankAlloca` conjunct on the `Bank` arm dropped | **MISSED** | — (§11.1) |
| M3 | type rewrite PASS 1 skipped (object keeps `[N x cell]`) | CAUGHT | 4 accept fixtures |
| M4 | type rewrite PASS 2, **flat element-form gep** skipped | CAUGHT | `railbank_promote_unrolled_reads.ll` **only** |
| M5 | **piece 3 (D5) removed** | CAUGHT | the 4 `railbank_reject_*` negatives |
| M6 | **the D1 spine door removed** | CAUGHT | `railbank_accept_nonmain.ll`, `…_k1000`, `…_unpromoted` |
| M7 | **the cast sink disabled** | CAUGHT | 6 re-derived promote/anchor fixtures |
| M8 | initializer kept at its OLD length (the control — §11.2) | CAUGHT | `railbank_accept_zeroinit_memset.ll` |
| M8b | initializer **RESCALED** instead of deleted | CAUGHT | `railbank_accept_zeroinit_memset.ll` |
| M9 | **D5's WIDTH conjunct dropped** | CAUGHT | `railbank_reject_measure_width_pun.ll` |
| M10 | the type rewrite's half of the width fence dropped | MISSED **by design** — §11.3 |

**M4 is caught by exactly ONE fixture**, and that is worth knowing: the flat
element-form gep appears in only one module in the tree. If
`railbank_promote_unrolled_reads.ll` is ever deleted or re-spelled, that half of
PASS 2 becomes unpinned.

### 11.0 ⚠ THE WIDTH PUN — an OVER-ACCEPT this increment SHIPPED and then found

Found by this track's own self-review while writing the matrix, not by any gate.
Before the fix:

```c
int b0[3];  for (i<3) b0[i] = cq_theta(b0[i], 0.5);
            for (i<3) s += cq_measure((short) b0[i]);
```

compiled, and emitted

```
cqrt_alloc_i32(0) -> h0 ; cqrt_ry_i32(h0, 0x1p-1)   … ×3
cqrt_measure_i16(h0) -> 0                            <-- an i32 rail measured at i16
```

**The truncation GATE was dropped entirely.** The register spelling of the same
program — `probes/d5h_scalar_width_pun.c`, `int q = cq_theta(q,.5);
cq_measure((short) q);`, **no array anywhere** — emits
`cq_template_trunc_i32_to_i16(h0) -> h1` and measures the NEW rail, on this
binary **and on the ORACLE**. So it was not a boundary the language already had:
the bank LOST a gate the register spelling emits.

`opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s), 0 unproven`, a
plausible nine-line trace. **Nothing else in the tree would have seen it.** It is
the same family as the shipped PUN FENCE (`QramLowering.cpp`'s
`StoreVal->getType() != CellTy`, whose own comment says *a sub-width type-punned
access would resolve the ABI width from the ORIGIN and mint a wrong-width gate
stream — verify-clean and wrong*).

**The fix, in two spellings that must move together** (and each says so at its
site): D5 admits a storage TRUNCATION only **to the rail type**, and a DIRECT
measure of the load only when the cell type **IS** the rail type; the type
rewrite's PASS 5 erases only a `trunc` **to the rail type**. The rail width is
carried in the `!cq.railbank` record itself, because after `lowerRotations`'
cross-type RAUW the store's extension cast reads `zext i32 %h to i8` and its
original source type is **unrecoverable**. Pinned by
`railbank_reject_measure_width_pun.ll` and by mutant **M9**.

⚠ **The lesson is L2's.** The rail bank widened *"what can be a rail"* to a
memory cell; the set computed over the same closure was *"which cast is the
compiler's storage bridge and which is the user's arithmetic"*, and the first
implementation answered it by OPCODE (`is it a trunc?`) instead of by WIDTH.

### 11.0b THE WRITE-SIDE TWIN — measured SAFE, and filed as an OVER-DECLINE

The same question asked of the STORE side: the rail-width derivation reads the
cast in front of the bank store, and it accepts ANY cast to the cell type, not
only a WIDENING one. So for

```c
char b0[3];  for (i<3) { int q = cq_theta(argc, 0.5); b0[i] = (char) q; }
             for (i<3) s += cq_measure(b0[i]);
```

the cast is a `trunc i32 -> i8` — a genuine GATE, not a storage bridge — and the
derivation reads the rail as **i32** when the cell parks an **i8** rail.

**MEASURED, on the final subject: the module DECLINES**
`cq rail bank: unsupported reader of a rail-bank cell`
(`probes/d5i_store_side_width_pun.c`). The mis-derivation is **self-fencing** in
this direction, and the reason is structural rather than lucky: with a NARROWING
store cast the derived rail is WIDER than the cell, so D5's entry (1) fails (the
load's type is the cell's, not the rail's) and entry (2) is impossible (a `trunc`
from the cell type to a WIDER type does not exist). **Every reader is unadmitted,
so the whole module declines.** Two neighbours confirm the direction:
`probes/d5l_store_double_cast.c` (`(int)(char) q` into an `int` bank) also
declines at D5, and `probes/d5k_store_value_is_compare.c` declines earlier still.

⚠ **So this is an OVER-DECLINE, not a hazard** — the `char`-cell bank is a valid
circuit the compiler refuses — and by the owner's 2026-09-11 ruling that is a
**defect to file, not a safety margin**. It is NOT fixed here, deliberately:
making it accept means (a) deriving the rail width from a WIDENING cast only and
(b) teaching PASS 4 to leave a non-bridge cast standing for `lowerOps` — and
**(a) without (b) is a MISCOMPILE**, because PASS 4 would then erase the user's
`trunc` and store the un-truncated handle. That is a two-sided change to a
Rule-13-core stage and it needs its own round, not a last-hour edit. **Filed.**

⚠ **AN INSTRUMENT LESSON FROM THE SAME PROBE.** Its first spelling wrote
`int q = cq_theta(q, 0.5);` inside the loop — UB, which `clang -O1` collapses to a
bare `unreachable`: the stage-1 module was the single instruction
`unreachable`, the pipeline reported **ACCEPT with `0 rail mint(s)`**, and the
linked binary died with `Illegal instruction`. It reproduced identically on the
ORACLE, which is what identified it as a bad probe rather than a finding. **A
probe whose stage-1 module is `unreachable` measures NOTHING** — the same family
as bd memory `empty-module-accepts-vacuity-trap`, one optimisation further on.

### 11.1 M2 — MISSED, and the subject is structurally unreachable

The conjunct makes the `Bank` arm `continue` **only with the record present**. To
construct a `Bank`-without-record module, a stage would have to MANUFACTURE a bank
shape between the mark slot and `declineTaintEscapes`; none does. So the mutant is
invisible and no fixture can be written for it today.

**It is kept anyway, and the direction is why:** dropping it makes the compiler
accept MORE (a bank whose loads were never tainted — the §1 miscompile). Keeping a
defensive conjunct whose alternative failure is silent is the same discipline
`Uncomputation.cpp` records for its `ControlOwnedRails`/`OutputRails` subtractions
(*"do not 'simplify' them away on the grounds that they never fire"*). **Reported
as MISSED rather than quietly dropped from the matrix.**

### 11.2 M8 / M8b — a mutant that was not a defect, and a hole that was

M8 (keep the initializer at its old 3-byte length) is **not a defect**: C6
TOTALITY says every cell is stored before any cell is loaded, so a short fill is
never observed. It is the control, and it was MISSED until the fixture below
existed.

M8b (RESCALE the fill to 12 bytes) is the hazard the deletion is actually about —
a rescaled memset writes handle `0` into every cell and **handle 0 IS A LIVE RAIL**
(`cqrt_alloc_i1(0) -> h0`). It was **MISSED by every railbank fixture, every
railbank e2e slice and stage 2b**: the emitted trace is byte-identical either way,
and `free_pairing_check.py` does not model memory. A fixture was written for it —
`railbank_accept_zeroinit_memset.ll`, whose `NOTS-NOT: call void @llvm.memset` on
the lowered module is the ONLY instrument in the tree that separates the two — and
M8 and M8b are now both CAUGHT.

⚠ The source comment at PASS 3 was **corrected in the same change**: it claimed
deletion "has the better failure mode", which is true only COUNTERFACTUALLY (while
C6 holds the two are indistinguishable, measured). L7-with-a-twist: a record
correction that is not applied to the source is not a correction.

### 11.3 M10 — MISSED by design, and it is the L3 shape

The width fence has two spellings: D5 refuses the READER, PASS 5 refuses the
ERASURE. M10 drops the second; D5 refuses the input first, so nothing moves.
**The second spelling is kept anyway** — the two ask different questions (*may
this consumer read a parked rail?* vs *is this cast the compiler's storage
bridge?*), and if a future widening admits a reader D5 currently refuses, PASS 5
is what stops the gate being dropped. Both sites carry the "these move together"
sentence.

## 12. Rule-13 budget — FOUR rounds, and what each must attack

`SCOPE_B.md` §12 budgeted four with named subjects. **This track ran none of them
— they are a REVIEWER's, and they are owed.** What this record hands them:

* **Round 1 — the two measurements the scoping could not take.** §10 items 1 and 5
  of `SCOPE_B.md`: (a) the spine's disposition of a STORE-KEPT parked rail
  **outside `main`** — now measurable, and measured here as an over-decline before
  the fix and as `Escaped`-by-non-nomination after it, but the reviewer must
  re-take it rather than read it; (b) `classifyArms` on a module with BOTH the
  sunk cast and a surviving store — *this track still could not measure it*,
  because with the store surviving the module accepts and there is no arm. Plus
  §6's restated D3 question **in its restated words**.
* **Round 2 — the taint rule's blast radius.** Attack D5 with shapes nobody
  listed: a bank load into a `phi`, a `select`, a `freeze`, a second `cq_measure`
  of a DIFFERENT width, a `ret`, a `cq_invert_*`. This track probed three
  (branch condition, `cq_theta` arg-0, arithmetic) and **those are the three the
  scoping named** — the unlisted ones are exactly what round 2 is for. Carry L4:
  the walk enumerates the load's users and takes the difference; it does not stop
  at the first bad one.
* **Round 3 — the type rewrite against the verifier's blindness.** §8 above. The
  question is not "does it verify" (it does) but "is every bank-touching construct
  retyped". M3 and M4 are two mutants of that family; the reviewer should find a
  third the matrix does not have — in particular a construct the C1 user scan
  admits that the rewrite's own enumeration does not name.
* **Round 4 — the spine, outside `main`.** L2: when you widen *"what can be a
  rail"*, ask what OTHER set was computed over the same closure. D6's five
  subtraction sites in `Uncomputation.cpp` / `DagTraversal.cpp` /
  `ArithLowering.cpp` were **NOT** given `railStoredToRailBank`, because
  `isTerminalHandle` stops the nomination at source and they were measured
  unreachable for a bank rail — **that is exactly the closure question, and it is
  the one this track is least confident about.**

⚠ The measured hit rate says round 4 finds something. Budget it before round 1.

---

## 11c. The corpus sweep — 86 movers, **0 A→D**, every one attributable by string

`probes/corpus.sh` on the final subject, `probes/corpus_784c14fa05c16c50.txt`
(movers extracted to `…movers.txt`). **5586 inputs → 5557 rows**; the 29-row gap
is exactly the count of `*_lib.c` / `lib*.c` link-partner files the recipe skips
by design (verified by `find`, not assumed).

| class | count | what |
|---|---|---|
| **A→D** | **0** | no shipped accept was lost |
| D→A | 27 | **every one a rail-bank program** — the accept surface |
| D→D | 59 | `kMsgStore` → a MORE SPECIFIC decline |

The D→D breakdown, and it is the increment's signature:

| from → to | n |
|---|---|
| `tainted value stored to memory` → `control flow inside a loop body` (wall 3) | 34 |
| `tainted value stored to memory` → **`cq rail bank: unsupported reader of a rail-bank cell`** | 15 |
| `tainted value stored to memory` → `loop-carried tainted value crosses iterations` (wall 4) | 6 |
| `tainted value stored to memory` → `tainted value muxed by a classical-condition phi` | 2 |
| `tainted value stored to memory` → `control flow` (tag truncated at 80 chars) | 1 |
| an unchanged ABORT on BOTH binaries | 1 |

⚠ **The last row is not a mover in substance.** `probes/derived/B10_classcond_deadphi_crash.ll`
is the hand-derived dead-φ module `SCOPE_B.md` §5.3 built on purpose; it
`report_fatal_error`s with the SAME `PHI node operands are not the same type as
the result!` on the ORACLE and on the subject, and the stderr shas differ only in
the crash backtrace. It is a committed PROBE, never a fixture, and it cannot
arise from C — the live-φ spelling is the shipped decline
`railbank_reject_classical_cond_bank.ll`.

**Five of the 27 D→A rows are not this track's probes**, and all five were
spot-checked end to end rather than counted: `L9_array_phase_arm.c` (a bank with a
bare-rail PHASE arm — 12 lines, `cqrt_rz_i1` on the rail itself, which is the
shipped `RootIsRail` kickback), `a_loop_n3_noarm.c` (9 lines; `cq_measure(a)` on
the classical `a` emits nothing, bd `21mg`), `H17_narrow_index.c` (a 200-cell bank
walked by an `unsigned char` index — 200 allocs, 200 measures, ROLLED to one alloc
site), `w1_bank_prep_only.c` and `r1_rail_bank.c`. **All STRICT 2b clean, `0
violation(s), 0 unproven`.**

⚠ **BASE is pinned to ORACLE by CITATION, not by a second sweep** — Track A
measured 0 verdict movers and 0 stderr-byte movers over 5582 modules on the
bit-identical binary (`trackA/GATES.md`). The three-way attribution the brief asks
for is therefore ORACLE→SUBJ with BASE≡ORACLE cited, and `GATES.md` says so.

## 12b. An instrument that lied, caught by its own output

⚠ **THE CORPUS-SWEEP HARNESS REPORTED SUCCESS WHILE MEASURING NOTHING, AND IT IS
RECORDED HERE BECAUSE IT IS THIS PROJECT'S OWN FAILURE MODE (L10).** Parallelising
`probes/corpus.sh` accidentally deleted its `OUT=` assignment; `sort > ""` and
`echo DONE >> ""` both failed, the invocation's `2>/dev/null` swallowed the
errors, the run **EXITED 0**, and the output file still held 45 rows from an
earlier partial run — a plausible-looking sweep with `0 movers`. It was caught
only by noticing that 45 ≠ 5579 and that the last line was not `DONE`.

Three guards now run on every invocation: the input list must be non-empty, the
row count must be within 10% of it, and the file ends with
`DONE inputs=<n> rows=<m>`. **A caller that does not see that line has not got a
sweep.**

## 13. Filings

* **bd `yiid` (P1, open)** — this increment's measured contact with it is recorded
  in §7 and in `railbank_accept_bank_copy_folded.ll`: the scalar control
  `cq_measure(q) + cq_measure(q)` compiles to a double measurement of one qubit on
  the BASE and on the SUBJECT alike, with no array anywhere. **Not created here,
  not added to here** (entry (3)'s removal took the only new customer off it).
* **bd `zwtm`** — does NOT close. `tests/e2e/slice_railbank_owner_cascade.c` is
  committed as the record; registration waits on (c3) + W3.
* **bd `8h7d.11` ((c3)) and bd `ej5w` / W3 (X1)** — named by the re-derived
  fixture headers and the slice header as the two remaining walls, with the
  "report the sequence's LENGTH" obligation attached.
* **F-3 (this record §10)** — three promoter clauses whose subjects are
  structurally unreachable. A scope question for the orchestrator.
* **The `char`-cell bank over-decline (§11.0b)** — a valid circuit the rail-width
  derivation refuses. Costed there as a two-sided change needing its own Rule-13
  round; **do not fix half of it.**
* **The `int`-cell CONSTANT-INDEX bank** (`cq rail bank: array mixes a rail cell
  access with an unrecognized one`) — the `-O1` byte-offset gep, `SCOPE_B.md` §10
  item 4, unchanged and not widened.
* **`cq-opt-equivalence-full` is OWED**: this increment moves decline populations
  (two new strings, one arm that stops declining) and changes analysis sites.
