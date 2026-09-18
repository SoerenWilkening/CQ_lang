# bd `fn1q` — what the walls ACTUALLY are (measured 2026-09-22)

Binary: `cq-opt 3368af1262695d7e4c…` / `libCQPass.so 48b8b4db61777082e9…`, `main e107a177`
(hash-checked before every measurement; the session's temporary `CQ_CTRL_BT` backtrace lever
in `ControlDetect.cpp` is env-gated and byte-neutral when unset).

## 0. HEADLINE — THREE CLAIMS IN THE BEAD ARE FALSIFIED BY MEASUREMENT

| bead claim | measured |
|---|---|
| "Va: array-valued THRESHOLD `if (Z >= z[i])` → DECLINE" | **FALSE. It ACCEPTS**, 120 lowered lines. The condition is not a wall. |
| "Vc: array value in the ARM → DECLINE" | TRUE, but **not because it is an array, and not because it is in a loop**. |
| "BOTH ARE OVER-DECLINES AND THE FLAT TWIN IS THE PROOF: hand-unroll either and it COMPILES" | **The twin proves nothing.** `-O1` const-folds `int p[]={3,2,1}` at a now-constant index and if-converts the whole thing; the unrolled IR contains `select i1 %1, i32 4, i32 5` and **no value-arm branch at all**. With an array `-O1` cannot fold (a global at a runtime index) the **loop-free** form declines too. |

**They are still over-declines.** The compiler already allocates a *runtime* classical
value as a register seed (`%selop = call i32 @cqrt_alloc_i32(i32 %1)`, measured in
`flat_k`'s lowered IR), so nothing about a runtime classical operand is unsupported.
The bead's *conclusion* survives; its *evidence and its axis* do not.

## 1. THE AXIS IS `br` VS `select`, AND `-O1` PICKS IT

Every accepting neighbour in this family accepts because **`-O1` if-converted the value
arm into `select`s**, which go down the cleared 4.4 `SelectMergeEmit` + bd `zujr`
loop-carried-handle path. Every declining neighbour declines because **`-O1` refused to
if-convert** (a non-speculatable load in the arm, or too many merge φ for the
speculation budget) and left a real `br` value-arm region.

Full 2×2×2 over the owner's three axes (condition / `Z -=` / `P +=`, K = constant,
A = array):

```
cK_zK_pK   ACCEPT 110      cA_zK_pK   ACCEPT 120     <- the CONDITION axis is free
cK_zK_pA   DECLINE         cA_zK_pA   DECLINE
cK_zA_pK   DECLINE         cA_zA_pK   DECLINE  "iteration-local value read after the loop"
cK_zA_pA   DECLINE         cA_zA_pA   DECLINE
```
`cA_zK_pK` is the refutation of "Va": array threshold, constant arm, **exit 0**.

## 2. THE WALLS ARE NOT LOOP-SPECIFIC — THREE LOOP-FREE EXHIBITS

| probe | shape | verdict | site (backtrace-confirmed) |
|---|---|---|---|
| `flat_qc_load` | flat diamond, Q+C `add` whose classical operand is `load @p[idx]` | **`impure value arm`** | `valueArmIsPureChain`, `ArmClassify.cpp:6133` — the `load`/`gep`/`sext` are **STRAY OPS** beside the chain |
| `flat_gidx` | flat diamond, merge φ incoming IS the classical load | **`value-arm swap-route`** | `ArmClassify.cpp:6193` — `walkValueChain` returns EMPTY (a `load` is not a tainted binop), `isValueChangingOp(Base)` fires |
| `wide4` | flat diamond, **EMPTY arm block**, four all-constant merge φ | **`control flow`** | `MergePhiPeel` peels all four (`NotPeelable == 0`), leaving an empty tainted diamond with **zero** φ that `recoverRegion` labels `OffPattern` |

`wide2` (the same program with two φ) ACCEPTS at 69 lines — `-O1` if-converts it.
So a **loop-free, all-constant, four-variable value arm declines**. Nothing about
arrays, loads or loops is required to reproduce the family.

## 3. THE OWNER'S PROGRAM SITS BEHIND FOUR DISTINCT FENCES, NOT TWO

In the order they are reached:

1. **`MergePhiPeel` P9 — `regionEntryInLoop(BI)` → `continue`** (`MergePhiPeel.cpp:382`).
   The owner's merge carries two φ (`Z` and `P`); in a loop the peel never runs, so
   `soleMergePhi` is null and `recoverRegion` returns `OffPattern` → `control flow`.
   ⚠ P9 is a **deliberate** refusal ("a refusal to widen two axes at once") and carries
   a written **dangling-pointer obligation**: `TaintSet::BreakRegions` holds raw
   `PHINode *` (`EscapePhi`/`CounterPhi`) that P9 + P1 are what keep safe today.
2. **`walkValueChain` returns EMPTY for an untainted accumulator** → `ArmClassify.cpp:6193`
   `value-arm swap-route`. (`armonly_p`: `P` is classical at round-1 taint, so the arm's
   `add` is not a tainted binop and the chain never starts.)
3. **`valueArmIsPureChain` stray-op rule** → `ArmClassify.cpp:6133` `impure value arm`.
   Any classical `gep`/`load`/`sext` in the arm block is a stray op.
4. **clause (c3) `iterationLocalTaintEscape`** → `iteration-local value read after the loop`
   — reached only when the SAME array value is read by both the condition and the arm.

## 4. WHY THERE IS NO BYTE-IDENTITY TWIN TO AIM AT

`owner_seltwin` — the owner's program hand-if-converted in the source
(`P += b0[i] ? p[i] : 0;`) — **also declines** (`br=3 sel=1`): `-O1` keeps the branch
because the load still guards. There is currently **no spelling of the owner's program
that compiles**, so the established `*-twin-identical` witness idiom has no baseline
here and a witness has to be constructed rather than borrowed.

## 5. INSTRUMENT NOTE

`CQ_CTRL_BT=1` (added this session beside the existing `CQ_CTRL_DBG`, env-gated,
`llvm::sys::PrintStackTrace`) is what turned "do not guess which site fires" into a
measurement. `CQ_CTRL_DBG` alone prints the offending instruction but not the site, and
three of the five sites above share a decline string.

---

## 6. WHAT HAPPENED NEXT — read this before quoting §2's table

This file records the state **before** increment 1 and is deliberately not
rewritten. Two rows moved:

* **`flat_qc_load` STILL DECLINES `impure value arm`, and that is CORRECT.** Its
  cone ends in `load i32, ptr @p[idx]` with a RUNTIME index, which (K4)
  (`isSafeToSpeculativelyExecute`) cannot prove safe to run unconditionally — and
  it is not a choice, because the condition is quantum and the emitted circuit has
  no classical branch to hide the load behind. §2 lists it as an exhibit of the
  *stray-op* fence; increment 1 fixes the scalar cone, **not that row**. A source
  program where `idx` is out of range on the non-taken path has no undefined
  behaviour; the hoisted form would. Over-declining is safe.
* **`cone_arith` (a global SCALAR load plus `mul`/`add`/`xor`) now ACCEPTS** at the
  IR level, and its C form accepts with an `int` condition. With a bare `_Bool`
  condition it moves on to the NEXT wall, `bare i1 register condition` (bd `fg9k`)
  — which is a different, already-filed capability, not a residue of this one.

§3's four-fence list is unchanged except that **F3 is closed**. F1
(`MergePhiPeel` P9), F2 (`walkValueChain`'s empty chain) and F4 (clause (c3))
remain, and the owner's program still does not compile.
