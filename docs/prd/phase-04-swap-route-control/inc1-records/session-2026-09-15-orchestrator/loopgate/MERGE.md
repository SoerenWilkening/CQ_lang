# loop-group MERGE — the four resolutions, each by MEANING

Worktree `/Users/sorenwilkening/Desktop/CQ_LOOPGATE`, branch `loop-group-gate`, from
`loop-group-fix` (`d70f47e9`) with `bbu0-warn-reorder` (`30e213a7`) merged in.

`loop-group-fix` is itself Track S′ `dephase-fence-r2` + Track T `inloop-pairing` + the bd
`test_C_libtooling-emkg` P1 fix; Track D is based on `dephase-fence-r2` alone, so the three
files it shares with S′/T conflicted.

## 0. The differential check that makes "by meaning" checkable rather than asserted

Before any narrative, the two directions (`git diff --stat`, `ir-pass/` only):

| direction | result |
|---|---|
| **merged vs `loop-group-fix`** | `LoopPlan.h` +26, `CQLoweringPass.cpp` +14, `LoopLowering.cpp` +167, one fixture +60 — **267 insertions, 0 deletions** |
| **merged vs `bbu0-warn-reorder`** | 657 insertions, 46 deletions — every deletion a Track T signature change (`void`→`bool` on `markIfIterationLocal` / `markIfRailLocal`) |

⚠ The first row is the load-bearing one. Track D's own record (`trackD/IMPL_D2.md` §2) states
its source diff against its base as **`LoopPlan.h` 26 / `CQLoweringPass.cpp` 14 /
`LoopLowering.cpp` 167, 237 insertions and 0 deletions**. The merged tree reproduces those
three counts **exactly**, and contributes **zero deletions** to the fix branch. So Track D
transferred whole, took nothing away, and the only number that differs is its fixture (+60
rather than +30) — which is §4, the one resolution that is not a union.

## 1. `ir-pass/include/LoopPlan.h` — UNION

Both sides appended a declaration at the same anchor: Track T's
`declineRound2FalsifiedRailGrants` (bd `tu9q`) and Track D's `emitDeferredDephasingDecline`
(bd `bbu0`). Different functions, different stages, no shared state. **Reason: the conflict is
positional, not semantic** — two independent additions to one header. Both kept, both comment
blocks kept verbatim. Verified: `:389` and `:416`.

## 2. `ir-pass/src/LoopLowering.cpp` — UNION inside the anonymous namespace

Both sides appended to the tail of the same anonymous namespace:

* HEAD — `bodyBlocksMarked(L, LI, taint)`, the bd `emkg` P1 fix: the ONE spelling of *"are
  `L`'s OWN body blocks marked iteration-local?"*, replacing conjunct (1)'s `ANY` over the raw
  `L->blocks()` (which includes every strictly-deeper subloop's blocks, so a marked INNER loop
  silenced the fence for its enclosing OUTER loop).
* `bbu0` — `deferDephasingDecline()` (the `getenv`), `struct DeferredDephasing`,
  `deferredDephasingSlot()`.

**Reason: disjoint subjects.** `bodyBlocksMarked` answers a question about `LoopInfo` and the
taint set; the Track D trio is a process-lifetime slot for a deferred diagnostic. Neither reads
the other. The only textual overlap was the closing brace the two blocks shared at the conflict
boundary, which is why git could not auto-merge them.

Verified after resolution, by symbol and by call site:

* `bodyBlocksMarked` defined `:4435`, **called at BOTH** its sites — `:4746`
  (`declineDephasingUnmarkedLoopRails` conjunct (1), the fix) and `:5345`
  (`declineUnmarkedRolledIterLocal` conjunct 2, the reference reading whose behaviour is
  unchanged);
* Track D's slot clear stands at the TOP of `declineDephasingUnmarkedLoopRails` (`:4678`,
  before the `Tainted.empty()` early-out, as its comment requires) and its record-instead-of-
  diagnose branch at the diagnose point (`:4865`), i.e. **inside the function the `emkg` fix
  also edits, and after the fix's conjunct (1)**. The composition is the intended one: the gate
  defers whatever verdict the fixed conjuncts reach.

## 3. `ir-pass/src/CQLoweringPass.cpp` — auto-merged, then VERIFIED rather than trusted

git merged this file without conflict; the merge-and-gate agent does not take that as evidence.
Both entry points were read and both carry the full chain in the same order:

| stage | `run()` | `runOnFunction()` |
|---|---|---|
| `declineUnmarkedRolledIterLocal` | :614 | :1152 |
| `declineDephasingUnmarkedLoopRails` | :772 | :1212 |
| `declineRound2FalsifiedRailGrants` (T) | :779 | :1219 |
| `warnLiveRecordRotations` | :871 | :1243 |
| `emitDeferredDephasingDecline` (D) | :879 | :1249 |

Track T's slot contract (*"strictly below the round-2 fixpoint and strictly above
`lowerRotations`"*) holds — `lowerRotations` follows at `:782` / `:1222`. Track D's contract
(*"unconditionally, immediately after `warnLiveRecordRotations`, in BOTH entry points"*) holds.
**Twin-pipeline parity (WI-1.12) is load-bearing here and not tidiness**: an entry point that
records a deferral and never drains it would hand back `opt` exit 0 on a program the fence
refused.

## 4. `ir-pass/test/loop_leak_dephase_reject_inloop_rotation.ll` — NOT a union: the pin was RELOCATED, because the file's own L8 trigger said to

This is the one conflict where taking either side would have been wrong.

* **HEAD** converts the file to an **ACCEPT** (Track T's bd `tu9q` pairing; 24 rolled == 24
  twin). That conversion is one of the two the merge, and neither track, produced.
* **Track D** added a second RUN line to the same file under
  `env CQ_BBU0_DEFER_DEPHASE_FENCE=1` — **a `not %cq-opt`** — pinning the instrument's one
  safety property (*the gate changes WHEN the decline is emitted, never WHETHER*).

Taking Track D's side would have kept a `not` RUN line on a module that now accepts: a red
suite. Taking HEAD's side alone would have **silently dropped the instrument's only pin** —
the failure mode the brief's trap list names.

**Track D's own text resolved it.** Its header carried:

> *"⚠ L8 RETIREMENT TRIGGER: this pin dies with the file when bd `tu9q` turns it into an
> ACCEPT. MOVE the two `RUN`/`DEFER` blocks to whichever module still declines at this fence
> then; do not silently drop them."*

The trigger fired exactly as written, so the pin was **moved**, not dropped. The new host was
chosen **by measurement on the merged binary**, not by inspection: of the 16
`loop_leak_dephase_*` / `loop_pairing_*` fixtures, **5 still decline at this fence**
(`probes/fence_hosts.sh`), and `loop_leak_dephase_reject_region_derivedbase_live.ll` is the
flat (non-nested) one among them — so the pin does not also depend on the `emkg` nesting fix.

⚠ **The relocation makes the pin STRICTLY STRONGER, and that is measured, not hoped.** The new
host also WARNS. Its `DEFER` prefix now pins, in order:

```
DEFER: cq rotation lowering: non-diagonal gate over a live derived record
DEFER: cq bbu0 instrument: dephasing decline DEFERRED past the warn stage
DEFER: cq loop lowering: rolled body leaks a rail entangled with a rotated register
```

so the fixture witnesses not only *"the gate does not lose the verdict"* but *"the gate
actually lets the warn stage speak on a module the fence refuses"* — which is the
measurement's whole subject. On the old host the warn stage was silent, so that half was
unpinned.

**Validated by BINARY MUTATION, not by re-reading the prefixes** (Rule 12 hygiene (b) — a
`DS_Error` writes 0 bytes to stdout, so IR-text `CHECK-NOT`s here would be vacuous):

| binary | `FileCheck --check-prefix=DEFER` |
|---|---|
| FIX `9dd81edb…` (merged, **no Track D**) | **exit 1 — "DEFER: expected string not found"** |
| MERGED `f2ee2eb6…` | exit 0 |

and `lit --filter loop_leak_dephase_reject_region_derivedbase_live` **PASS**.

A carried-forward, re-aimed L8 trigger is written into the new host: this pin dies with *that*
file the day anything turns *it* into an accept, and `probes/fence_hosts.sh` is the cheap way
to find the next host.
