# Track D — bd `test_C_libtooling-bbu0`, owner ruling **E6 = option (D)**: make the gap a number

**Subject:** the ordering between `LoopLowering::declineDephasingUnmarkedLoopRails`
(`CQLoweringPass.cpp:772`) and `RotationLowering::warnLiveRecordRotations` (`:864`).
**Branch** `bbu0-warn-reorder`, worktree `/Users/sorenwilkening/Desktop/CQ_D`, based on
**`dephase-fence-r2` `6882685b`** (Track S′'s tip) — **not** on `main`. Files touched under
`ir-pass/`: **`src/LoopLowering.cpp`**, **`include/LoopPlan.h`**, **`src/CQLoweringPass.cpp`**
(plus one fixture). ⚠ The first two are shared with Track S′ and Track T — same GROUP.

> **THIS TRACK DECIDES NOTHING SEMANTICALLY.** Option (D) was ruled ahead of A/B/C because
> it is *"the only one that turns the gap from an argument into a number"* (`DECISIONS.md`
> E6). The number is in **`MEASUREMENT.md`**; A/B/C are ruled next session **on it**. Nothing
> here is an argument for any of them, and no predicate was adjusted to make the number
> come out any particular way.

---

## 0. The gap, stated so the instrument can be checked against it

The question that separates options A/B/C is

> *is `warnLiveRecordRotations` ever **SILENT** on a module `declineDephasingUnmarkedLoopRails`
> **DECLINES**?*

and it **cannot be asked of any binary in the tree**. The fence is called at
`CQLoweringPass.cpp:772`, the warn stage at `:864`, and `LLVMContext::diagnose` **EXITS on
the first `DS_Error`** (bd `br4a`) — so a module that declines at the fence **never reaches
the warning**, and every "0 warnings" row over a declining module is **0 BY PREEMPTION, NOT
BY SILENCE**.

⚠ Track S′ was explicit that it **did not construct a counter-example and does not claim one
exists** (*"round 1β's discipline applies to me too: did not reproduce, did not claim
unreachable"*). **That discipline is inherited here verbatim.** This track builds the
instrument, takes the measurement, and reports whatever it says.

---

## 1. WHICH SPELLING, AND WHY — both literal readings of the ruling are unimplementable

The ruling allows two spellings: *"emit the warnings **before** the fence's decline, or have
the fence **consult the warning's record set**."* **Read against the source (Rule 11), both
fail — and they fail for the same reason, which is worth stating once because it is also the
reason the gap exists at all: the warning is a question about a LOWERED module and the fence
is a question about an UNLOWERED one.**

* **"Move the warnings earlier."** `warnLiveRecordRotations` opens with
  `if (taint.UserChainedRotations.empty()) return false;` and then matches `cqrt_ry_<W>` /
  `cqrt_ry_<W>_controlled` **calls**. `UserChainedRotations` is filled by `lowerRotations`,
  which runs at `:774` — **after** the fence. Called at the fence's slot the stage returns on
  its first line and is silent on **everything**, which would move the verdict of every
  accepting module that warns today (the 5 e2e slices `QUESTION_bbu0.md` §4 names). A
  "measurement" taken that way would read `SILENT` on 100 % of the population and mean
  nothing.
* **"Have the fence consult the warning's record set."** That set (`RecordSet` +
  `collectAncestorRecords` / `collectDescendantRecords`) is built **inside** the warn stage
  out of emitted `cqrt_*` calls. At the fence's slot it does not exist. Re-deriving it there
  is precisely the **second-spelling** defect (Rule 14 / drbq Inc-3 (b′)) that the ruling's
  own §2 identifies as the *real* duplication — and it is **option C**, which is **not
  ruled**.

**What IS implementable is the third reading of the same sentence:** leave both stages where
they are and **defer the FENCE'S DECLINE past the warn stage**, so the warnings come out
first. That is literally *"emit the warnings before the fence's decline"*, and it is the
cheapest thing that produces the number.

### 1.1 Why deferring the decline gives the RIGHT number, not merely a number

`LoopPlan.h` documents the fence as *"**PURE ANALYSIS** — declines or does nothing; mutates
no IR and no `taint` set"*, and the body was **re-read for this change** rather than
inherited: it builds a `GateCalls` set, a `DominatorTree`, a `LoopInfo`, and calls
`peelInPlaceBase` (`const TaintSet &`), `mintsOutOfPlaceTemplateRail`, `railIsInterior` and
`taintedAncestryReaches` — every one a read. So **suppressing its `diagnose` yields exactly
the pipeline that a build with the fence DELETED would run**, and the module the warn stage
then sees is exactly the circuit the fence exists to refuse. That is the decision-relevant
question for options B and C, asked without building a second compiler.

### 1.2 Why the instrument cannot turn a decline into an accept

Not a hope — a control-flow fact. Under the gate the verdict is **recorded** and re-emitted
by `emitDeferredDephasingDecline`, which is called **unconditionally** in **both** entry
points, immediately after `warnLiveRecordRotations`. The only paths that skip it are ones a
`DS_Error` has already exited on. **The environment variable changes WHEN the decline is
emitted, never WHETHER** — and that property is **pinned by a fixture whose gated RUN line is
a `not %cq-opt`** (`loop_leak_dephase_reject_inloop_rotation.ll`, `DEFER` prefix), so the
suite fails if the gate ever accepts.

### 1.3 Why env-gated rather than unconditional

The brief's hard constraint is **no verdict may move**. An unconditional deferral moves the
fence past `lowerRotations` / `lowerOps` / `lowerMeasures` / `uncompute` /
`declineUnpairedUndefLiterals`, every one of which can emit a `DS_Error` of its own — so on
any module where one of them speaks, the decline→decline **string** would move. That is a
real cost, it is **measured** in `MEASUREMENT.md` §4 (the `PREEMPTED` bucket **is** that
cost), and it is reported rather than risked. With the variable unset the code path is the
shipped `diagnose(&I, …); return;` and the `getenv` is evaluated **at most once per module,
only on the declining path** — never on an accept.

The precedent for the mechanism is in-tree and long-standing: `CQ_CTRL_DBG`,
`CQ_RAILBANK_DBG`, `CQ_PREDMUX_DBG`, `CQ_PREDMUX_COUNT`, `CQ_UNROLL_DBG`, `CQ_CTLZ_DBG`,
`CQ_FP80_DBG`, `CQ_SPEC_DBG`, and 27 fixtures already set one on a RUN line.

---

## 2. The change, file by file — **237 insertions, 0 deletions**

`git diff --stat` against `dephase-fence-r2`:

```
 ir-pass/include/LoopPlan.h                                  |  26 ++
 ir-pass/src/CQLoweringPass.cpp                              |  14 ++
 ir-pass/src/LoopLowering.cpp                                | 167 ++++++++++
 ir-pass/test/loop_leak_dephase_reject_inloop_rotation.ll    |  30 ++
 4 files changed, 237 insertions(+)
```

**Nothing is deleted and nothing is reworded.** That is not a coincidence to be admired, it
is the shape the "no verdict may move" constraint forces: the only change to an existing
control path is a guard placed *in front of* the shipped `diagnose(&I, …); return;`, and that
guard is `false` unless the environment variable is set.

* **`LoopLowering.cpp`** — `deferDephasingDecline()` (the `getenv`), the `DeferredDephasing`
  slot, one branch inside `declineDephasingUnmarkedLoopRails` at the diagnose point, one
  unconditional slot-clear at the top of that function, and `emitDeferredDephasingDecline`.
  ⚠ The slot carries a **function NAME and a `DebugLoc`, never an `Instruction *` or a
  `Function *`**: `lowerRotations` / `lowerOps` / `lowerMeasures` /
  `lowerBreakReversePlay` / `lowerLateReassignments` / `uncompute` all run inside the
  deferral window and all RAUW and erase, so a raw pointer held across it is the
  *"dereferences freed memory (SIGSEGV on valid input)"* shape `CLAUDE.md` L9 has already
  charged this project once. A `DILocation` is context-uniqued, so the deferred diagnostic
  carries the **same source location** the un-deferred one does — which is what makes a
  deferred row comparable to its control row byte for byte apart from ORDER.
* **`LoopPlan.h`** — the declaration, with the call-site contract stated in both directions:
  **earlier than "immediately after `warnLiveRecordRotations`"** and the marker stops proving
  the warn stage ran (the measurement's only vacuity guard); **omitted from one entry point**
  and that path loses the verdict, i.e. a gated module exits ZERO — the one outcome the
  instrument must never produce.
* **`CQLoweringPass.cpp`** — the call, in **both** entry points (`run` and `runOnFunction`),
  immediately after the warn stage. Twin-pipeline parity is mandatory here for a reason
  stronger than WI-1.12 tidiness; see the previous bullet.
* **the fixture** — a second RUN line under `env CQ_BBU0_DEFER_DEPHASE_FENCE=1` and a
  whole-file `DEFER` prefix. **It is a `not %cq-opt`**, so the suite fails the day the gate
  turns this decline into an accept. Two prefixes, not one, because they are two verdicts
  about two different commands (fixture-hygiene (a): a positive check above a negative
  windows it).

### 2.1 Rule-12 red-green, with the RED quoted

The fixture was written and run **before** any source edit, on the BASE binary
`15f6a75a50faba7a`:

```
lit -v ir-pass/test --filter 'loop_leak_dephase_reject_inloop_rotation'
...
check:84     X~~~~~~~ error: no match found
Failed Tests (1): CQ IR-pass :: loop_leak_dephase_reject_inloop_rotation.ll
```

Line 84 is the marker check. The decline itself matched on the same run — i.e. **the RED is
exactly the gap and nothing else**: the gated command behaved identically to the ungated one,
which is the observation `QUESTION_bbu0.md` §3 is about.

### 2.2 A verification of the base that was worth taking (Rule 11)

#### The base build

This worktree's first build came out **BIT-IDENTICAL to Track S′'s recorded SUBJECT (final)**
— `cq-opt` `15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d`, `libCQPass.so`
`e39dba218d4ba6988fedb66ace582c82af2e9214963ad07f3501a90367579ef2`, both matching
`trackS/GATES.md` character for character. So the base is provably S′'s gated binary, every
S′ gate line at that hash is CITABLE here, and every delta below is attributable to this
edit and to nothing else.

---

## 3. What the instrument found — the headline, with the write-up in `MEASUREMENT.md`

**`warnLiveRecordRotations` is SILENT on ZERO of the 12 programs the fence declines.** It
fires on all 12; the fence still declines all 12; `opt` exits 1 on every row with the gate on
and with it off. `SILENT 0 · PREEMPTED 0 · CRASH 0 · INSTRUMENT-BROKEN 0 · CONTROL-BROKEN 0`.

Two results that are not the headline and are worth as much:

* **The instrument is validated EMPIRICALLY, not only by the purity argument of §1.1.** Five
  of the 12 programs **ACCEPT on the frozen ORACLE** — no fence in front of the warn stage at
  all — and their ORACLE warn counts (1 · 1 · 2 · 1 · 2) are **identical** to what the
  deferred run reports. Five independent controls that deferring the decline does not perturb
  what the warn stage sees.
* **`PREEMPTED = 0` measures the cost of the UNCONDITIONAL form of spelling (i).** Not one of
  these modules acquires a different first diagnostic when the decline moves to the late slot.
  It is still shipped **env-gated** — zero over 12 programs is not a proof over the class, and
  `MEASUREMENT.md` §5.1 says exactly how small and how self-selected that population is.

## 4. Two things I did NOT do, stated because their absence is the honest part

* **I did not adjust either predicate.** The brief forbids tuning for a prettier number and
  nothing here touches `declineDephasingUnmarkedLoopRails`' conjuncts or
  `warnLiveRecordRotations`' clauses. The diff is 237 insertions and 0 deletions.
* **I did not construct a counter-example, and I do not claim none exists.** Track S′'s
  candidate — a rail minted **inside a region** by `cqrt_alloc`, whose record set
  `RecordSet::push` clause 5 leaves EMPTY — is **not represented in this population at all**,
  so this measurement does not test it. *Did not reproduce, did not claim unreachable.*

## 5. One residual, stated rather than mitigated away

Between the fence's slot and the drain there is **exactly one early return** in each entry
point — `if (declineUnpairedUndefLiterals(M)) return …` (`run` `:830`, `runOnFunction`
`:1223`), verified by reading both windows, not assumed. On a host where `DS_Error` **exits**
(the shipped one, bd `br4a`) that return is unreachable, because the guard has already
diagnosed. **On a hypothetical host that swallows `DS_Error`**, a module that is (a) gated,
(b) trips this fence and (c) also trips the literal-integrity guard would **lose the deferred
verdict** and exit 0.

That is bounded and it is not new: `CQLoweringPass.cpp`'s own comment at that guard already
records that the pass *"still hands back a MUTATED module on such a host — that is a
pass-wide property of every post-mutation decline … filed as its own follow-up rather than
papered over here."* The instrument inherits that property; it does not create it, it cannot
be reached with the variable unset, and there is no reordering that removes it, because the
drain **must** stay after `warnLiveRecordRotations` and the warn stage is already after that
guard. **Recorded, not fixed.**
