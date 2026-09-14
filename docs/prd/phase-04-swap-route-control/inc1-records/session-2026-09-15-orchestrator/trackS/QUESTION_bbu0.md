# QUESTION for the OWNER — bd `test_C_libtooling-bbu0`

**Track S′, session 2026-09-15. This file states OPTIONS WITH MEASURED COSTS. It rules
NOTHING** (`CLAUDE.md` **L7**: *an agent-authored justification hardens into a ruling if
nobody rules*, and this file exists precisely because the bead's own framing is a
justification nobody has ruled on). Every number below carries the binary it was measured
on; the commands are in `GATES.md`.

---

## 0. The question as the bead put it

> `warnLiveRecordRotations` (`RotationLowering.cpp`, `kMsgLiveRecord`) is **strictly more
> complete** than `declineDephasingUnmarkedLoopRails` on the dephasing class, is a WARNING
> by owner ruling bd `lyyf` (2026-08-29) whose recorded reason is **reporting completeness,
> not benignity**, and fires on **5 of 366** accepting e2e slices — so the new fence is a
> SECOND SPELLING of a question the tree already asks, the Rule-14 / drbq Inc-3 (b′) defect.

⚠ **After this session's widening, the premise's FIRST half is still measurable and its
SECOND half is, I believe, wrong — but the correction makes the question HARDER, not
easier.** Both parts are below.

---

## 1. What I measured, and on which binary

ORACLE `0e280fc62a91cec2…` (= `main` `74eabd2c`, the 14c fence as shipped) ·
SUBJECT `15f6a75a50faba7a…` (this track's widened fence).
Counting occurrences of `cq rotation lowering: non-diagonal gate over a live derived record`
in `opt` stderr, over the probe set in `probes/`:

| probe | ORACLE warns | ORACLE verdict | SUBJECT verdict | SUBJECT warns |
|---|---|---|---|---|
| `b7b_w2k_interfered` (bd `c767`) | **1** | ACCEPT 20 lines | **DECLINE** | 0 † |
| `b7c_w2h_interfered` (bd `c767`) | **1** | ACCEPT 34 lines | **DECLINE** | 0 † |
| `b11_cmp_rail_data` (bd `7845`) | **2** | ACCEPT 10 lines | **DECLINE** | 0 † |
| `b10_inplace_volatile` (bd `2g52`) | 0 | DECLINE | **ACCEPT 7 lines** | 0 |
| `s1_live_shift` | 0 † | DECLINE | DECLINE | 0 † |
| `s2_live_derived_region` | 0 † | DECLINE | DECLINE | 0 † |
| `s3_live_rootmint_region` (positive control) | 0 | ACCEPT 22 | ACCEPT 22 | 0 |
| `w2k` / `w2h` / `w2h3` (the three D4-BENIGN) | 0 / 0 / 0 | ACCEPT 16 / 30 / 44 | ACCEPT 16 / 30 / 44 | 0 / 0 / 0 |
| `b5_measure_owned`, `b7_pertrip_interfered`, `b4_fpcast_rail` | 0 | ACCEPT 8 / 18 / 10 | ACCEPT 8 / 18 / 10 | 0 |

† **0 BY PREEMPTION, NOT BY SILENCE.** The fence is at `CQLoweringPass.cpp:772`, the warn
stage at `:864`, and `LLVMContext::diagnose` **EXITS on the first `DS_Error`** (bd `br4a`).
A module that declines at the fence never reaches the warning. **This is the single most
important fact in this file** and §3 is about it.

**The first half of the bead's premise survives the widening.** The warning fired on all
three members the 14c fence MISSED (1, 1, 2) — it saw bd `c767` and bd `7845` before this
track did. On the measured set it has never been silent where the fence speaks.

---

## 2. The correction: the two are NOT two spellings of one question

They are two DIFFERENT questions whose populations happen to nest, and the nesting is a
consequence of the difference rather than evidence of duplication:

* **`warnLiveRecordRotations` asks a PHYSICS question about the EMITTED CIRCUIT** — *"does
  a live derived record stand at a non-diagonal gate on this wire?"* It is a property of
  one circuit. **That is exactly why it fires on `slice_control_inplace_ry_loop_leak` AND
  on its `_unrolled` twin** (the bead's own "half that kills the easy fix"): both circuits
  carry the hazard, so a predicate about circuits must report both. That is the guard
  working, not over-firing.
* **`declineDephasingUnmarkedLoopRails` asks a COMPILER-CONSISTENCY question** — *"did
  ROLLING lose a discharge that this same compiler performs on the straight-line spelling
  of the same source?"* It is a property of a **DIFFERENCE between two compilations**, and
  no single circuit can answer it.

Hence: **divergence ⇒ hazard** (if rolling drops the `_unc`, the leaked record is standing
at the gate, so the warning's premise holds), **hazard ⇏ divergence** (the twin pair). The
superset relation the bead measured is the logical shape of the pair, not an accident.

⚠ **So "a SECOND SPELLING … the Rule-14 / drbq Inc-3 (b′) defect" is, on this reading, the
wrong charge — and a WEAKER version of it is still true and still worth fixing.** The two
stages compute **overlapping RECORD SETS by two different walks**: `RecordSet` +
`collectAncestorRecords`/`collectDescendantRecords` + `recordAbsentAt`/`recordIsExemptAt`
on one side, `taintedAncestryReaches` + `railIsInterior` on the other. THAT duplication is
real. It is a duplication of the *record walk*, not of the *verdict*.

---

## 3. THE MEASUREMENT NOBODY CAN MAKE ON A SHIPPED BINARY, and why it decides the question

The question *"is the warning silent on anything the fence declines?"* is the one that
separates the options — and **it cannot be measured on any binary in the tree**, because
the fence preempts the warn stage (the † rows above). Answering it needs a deliberately
built mutant with the fence removed, which is a build and a Rule-13 round of its own.

**What I can say without it:**
* the warning's record set is **documented to be EMPTY for a rail minted inside a region by
  `cqrt_alloc`** (`RecordSet::push` clause 5 — the reason it is silent on all 42 confirmed
  miscompiles of the drbq Inc-4 F2 class, stated in its own header). A rail the fence
  reaches through `taintedAncestryReaches` and that walk refuses is a candidate for
  "fence speaks, warning silent";
* I **did not construct one**, and I am **not claiming one exists**. Round 1β's discipline
  applies to me too: *did not reproduce, did not claim unreachable.*

---

## 4. The options, with what each costs

### Option A — keep both, keep the cross-reference (status quo after this track)
Both sites already carry each other's measurement in source. **Cost:** the duplicated record
walk of §2; two places to widen next time. **Benefit:** no shipped accept moves; the decline
refuses only programs whose rolled form is provably worse than their own straight-line
spelling; bd `lyyf`'s reporting completeness is untouched. **Measured:** `ir-pass-lit`
2041 passed / 1 XFAIL, corpus movers attributable to the fence alone (§ `IMPL_S2.md`).

### Option B — promote the warning to a DECLINE and delete the fence
**Cost, measured by the bead and unchanged by this track: 5 of 366 accepting e2e slices
decline** — `slice_control_angle_select_ry_derived_base`,
`slice_control_inplace_ry_derived_base`, `slice_control_inplace_ry_loop_leak`,
`…_unrolled`, `slice_live_record_source_rail_warn`. One of those is a **byte-identical twin
PAIR** under the shipped gate `e2e-inplace-ry-loop-leak-twin-identical`, so B refuses a
program that is demonstrably rolled == unrolled. It also reverses owner ruling bd `lyyf`
unless all warnings are emitted before the decline.
⚠ **AND THE OVER-DECLINE CHARGE AGAINST B IS ITSELF UNPROVEN.** Byte identity cannot
certify that pair correct — if both halves are wrong the same way the twin witness is blind,
which is `CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` cell verbatim. **"B costs 5
slices" and "those 5 slices should decline" are both live readings and the tree cannot
distinguish them.**

### Option C — build the decline on the warning's CANDIDATE set + a divergence discriminator
What the bead proposes. The candidate set becomes `taint.UserChainedRotations` and its
record sites; the discriminator is conjuncts (1) + (3) of the present fence, i.e. **this
fence re-seeded rather than deleted**. **Cost:** a real increment with its own Rule-13
rounds, and it moves the stage AFTER `lowerRotations` (the set is filled there), which
changes the slot argument the current fence's L1 paragraph rests on. **Benefit:** one
record walk, one candidate set, the decline keeps its narrowness, bd `lyyf` untouched.

### Option D — reorder so §3 becomes measurable (an instrument change, decides nothing)
Emit the warnings **before** the fence's decline, or have the fence consult the warning's
record set. Cheapest thing on this list and the only one that turns §3 from an argument
into a measurement. **It is not a semantic choice and should not be traded against A/B/C.**

---

## 5. What the measurements point at, stated as a pointer and not a ruling

The measurements are **consistent with C** and give **no evidence for B**: the warning saw
both P1s before this fence did (§1), which is C's premise; and B's only measured cost is 5
slices whose correctness is **unresolved in both directions** (§4), which is not a number a
decision should rest on. **But §3 is the load-bearing gap, and it is unmeasured.** If the
warning is ever silent where the fence speaks, C loses coverage relative to A, and C is
exactly the change that would hide that.

**I am not ruling.** What I would want before anyone does: Option D first (it is cheap and
it makes §3 a number), then A/B/C on the number.

## 6. Carried, not answered

* bd `lyyf`'s reason was **reporting completeness, not benignity** — the downgrade never
  asserted the reported gates were harmless. Any promotion argument must engage that, and
  "emit all warnings, then decline" preserves it.
* the warning is **silent on all 42 confirmed miscompiles of the drbq Inc-4 F2 class** by
  its own header. It is specific to the "live derived record" shape and is **not** a general
  dephasing detector; neither is this fence. Neither is coverage.
