# bd `fn1q` — RE-DERIVED FENCE MAP (measured 2026-09-23)

```
ORACLE   main 2c08fa62
         cq-opt       1b396ed08b01b8ecac7b268ba1d11ec3a90200e945ed091a43bf34ff23ad1c9e
         libCQPass.so f3a372fc275bcf15f2b3632b1fe3b586da086d6cc2040f0147675abe6cdcbe75
```
⚠ The tree was rebuilt from scratch at the close of the measurement and came out
**BIT-IDENTICAL** to the recorded hashes. Every row below is measured on that binary
(or on a named, env-gated measurement build derived from it); nothing is copied
forward and nothing is reasoned.

Instruments used: the shipped `CQ_PREDMUX_DBG` lever (names the PredMux gate that
refused a region), `CQ_CTRL_DBG` + `CQ_CTRL_BT` (the offending instruction and the
firing predicate's frame), and three temporary env-gated bypasses added for the
measurement only (`CQ_PREDMUX_NOE2` / `NOE6` / `NOE4`; the patched source is kept
verbatim beside the probes as `PredMuxFlatten.relaxed-measurement.cpp.txt`, and the
tree is pristine).

---

## 0. HEADLINE — THE 2026-09-22 BRIEF'S FENCE `F1` IS FALSIFIED, AND THE PEEL IS A DEAD END FOR THIS SHAPE

The brief (`../session-2026-09-22-orchestrator/NEXT_SESSION_PROMPT.md` §1–§2) names
**`MergePhiPeel` P9 — "no in-loop peel"** as the owner's program's FIRST wall and
increment 2's subject. Measured:

| claim | measured |
|---|---|
| "P9 is the wall; retiring it is increment 2" | **FALSE.** A measurement build with P9 bypassed (`CQ_PEEL_NOLOOP`) compiles `owner.c` to the **same decline, same string**: `cq controlled lowering: control flow under quantum control`. |
| "a 2-φ in-loop merge has no `soleMergePhi`, so peeling it is the fix" | The peel **cannot ever fix this shape, in a loop or out of one.** Both of the owner's merge φ are **ARM-DEFINED** (`%41 = sub %25, %28`, `%44 = add %43, %26`), so each fails **P3**, `NotPeelable == 2`, and **P4** skips the site. This is not an accident of P9: `phiPeelable`'s own comment states the contract — *"an incoming defined IN AN ARM fails it, and the peel must NEVER hoist one out"*. |
| (the loop-free control) | `probes/flat2phi_b.c` — a **LOOP-FREE** 2-φ value diamond with arm-defined incomings — declines **identically**, and the peel prints `numPhis=2 peelable=0 notPeelable=2`. P9 is not reachable there at all. |

With P9 bypassed the owner's branch does not even reach P3: it is refused one clause
earlier at **P7 `condRemintableAt`** (its condition is the bank-cell rail `%cq.bank1`,
not a `CmpInst`). So the peel has **three** independent refusals in front of this
shape and retiring any one of them buys nothing.

**The over-decline verdict survives. The route does not.**

---

## 1. THE ACTUAL OWNER OF THIS SHAPE IS `PredMuxFlatten`, AND IT REFUSES AT THREE GATES

`PredMuxFlatten.h` describes exactly the needed transformation — *"recovers a maximal
eligible acyclic tainted-control region (… DAG reconvergence, **multi-phi** and
N-incoming merges) and rewrites it into straight-line code — edge predicates as
compares …, **merge phis as chained selects**. The result is exactly the straight-line
tainted-select program the shipped substrate already lowers"* — and it is the stage
`MergePhiPeel`'s P3 comment **names** as the owner of arm-hoisting (*"that is
PredMux's E4-gated job (it erases the whole arm)"*).

Measured gate chain for `probes/owner.c`, each row from `CQ_PREDMUX_DBG`:

| # | gate | why it fires on the owner's program |
|---|---|---|
| 1 | **E2-cycle** | the region lies inside the `for` loop; E2 is *"no region block (incl. entry) on any CFG cycle"* |
| 2 | **E6-condtree** | the condition is the bare `_Bool` bank-cell rail `%cq.bank1`; `isSupportedCondTree` wants a compare tree |
| 3 | **E4-gep** | the arm holds `getelementptr … @__const.main.p, i64 %24` — a CLASSICAL runtime-index load. The existing const-global admission (`classifyQromReadUnderControl`) refuses it at its **index-taint gate**: QROM is for a *quantum*-indexed table read, and this index is the classical loop counter. |

Each gate was isolated by a probe that reaches it and no other (§3).

## 2. ⚠ THE ROUTE IS PROVED, NOT PROPOSED — WITH ALL THREE BYPASSED, THE OWNER'S PROGRAM COMPILES

Measurement build (E2+E6+E4 bypassed), `probes/owner.c` verbatim:

```
opt                exit 0, stderr 0 bytes
lowered module     106 lines, and it is ROLLED — the back edge survives
                   (`br i1 %25, label %2, label %15, !llvm.loop !12`)
stage 2b STRICT    7 rail mint(s) of which 5 left allocated,
                   3 template rail mint(s) of which 2 left dirty,
                   3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven
link + run         88 trace lines
```

The emitted stream per trip is the **shipped** idiom, twice: a controlled state prep
(`icmp_slt_hl` flag → `cqrt_x` bracket → `cqrt_ry_i1_controlled` → `_unc` → free), then
the hoisted chain (`sub_i32_hl` / `add_i32_hl`) run unconditionally on the ORIGINAL
registers, then **two** ordinary value merges — each a CNOT-copy of the rail root onto
a fresh ancilla, two X-bracketed `cqrt_copy_i32_controlled` into a fresh `|0⟩` rail,
the CNOT restored and the ancilla freed at a proven `|0⟩`. Nothing new is minted and no
new runtime symbol appears.

⚠ **THIS IS A ROUTE PROOF, NOT A CLEARANCE.** The bypasses are unsound as written
(E4 in particular speculates a load the source performs conditionally). What it
establishes is that the DOWNSTREAM path — 4.4 `SelectMergeEmit`, bd `zujr`'s
loop-carried-handle promotion, the rolled in-loop collapse — already handles the
shape, which is exactly what `probes/loop2phi_const.c` independently confirms by
**accepting on the oracle**: the same program with an arm `-O1` *does* if-convert.

⚠ **THE ONE HAZARD THE ROUTE PROOF ALREADY SHOWS** (for whoever reviews the real
increments): `2 template rail mint(s) left dirty` per trip — the hoisted `sub`/`add`
results stay allocated and entangled with the registers the NEXT trip's
`cqrt_ry_i1_controlled` reads. That is the bd `s82e` / Q-R1-1 class (CLAUDE.md §5),
not a new one, but this shape **adds customers** to it and an accept-direction
widening owes it an answer.

## 3. THE AXIS, RESTATED — AND `-O1` STILL PICKS IT

The 2026-09-22 session's finding stands and this measurement sharpens it. Every
accepting neighbour accepts because `-O1` **if-converted the arm into `select`s**;
every decline is `-O1` refusing to. What was not established then is **what the
refusal costs**: it costs the region its only owner, because the `select` form goes to
`SelectMergeEmit` and the `br` form has no claimant once the merge holds two φ.

| probe | shape | verdict on the ORACLE |
|---|---|---|
| `loop2phi_const.c` | in-loop, compare cond, 2 carried values, **all-constant arm** | **ACCEPT** — `-O1` if-converted it; PredMux is never asked |
| `loop2phi_cmp.c` | the same, arm reads `g_z[i]`/`g_p[i]` | DECLINE — E2-cycle, then **E4-gep** |
| `loop2phi_p2.c` | the same with **power-of-two** tables | DECLINE — E4-gep still (the index-taint gate, not the size) |
| `loop4var_bool.c` | in-loop, **bare `_Bool` rail** cond, 4 carried values, **no memory at all** | DECLINE — E2-cycle, then **E6-condtree** |
| `flat2phi_b.c` | **loop-free**, bare rail cond, 2 φ | DECLINE — E6-condtree; peel `notPeelable=2` |
| `flat2phi_cmp.c` | **loop-free**, compare cond, 2 φ, array arm | DECLINE — **E4-gep** |
| `owner.c` | the owner's program | DECLINE — E2 → E6 → E4, all three |
| `owner_pre.c` | the owner's program with the two loads hand-hoisted in the SOURCE | DECLINE — `iteration-local value read after the loop`, a **DIFFERENT** wall (`-O1` if-converts it, but into `add(select(c, p_i, 0), P)`, whose latch value is an `add` and therefore not a bd `zujr` carried handle) |
| `owner_int.c` | the owner's program with `int b0[3]` | DECLINE — `cq rail bank: array mixes a rail cell access with an unrecognized one`; **the `bool` spelling is the supported one, do not "simplify" to `int`** |

⚠ `loop4var_bool.c` is the probe worth keeping: it reaches E6 with **no array, no
load and no memory in the arm**, which is what proves E6 and E4 are independent axes
rather than two readings of one.

## 4. WHAT THIS SAYS ABOUT F2 AND F4

Neither is on the owner's program's path.

* **F2** (`walkValueChain` empty for a classical accumulator) is reached by
  `armonly_p.c`, a *different* program. The owner's accumulators are both tainted
  (they are the region's own merge values), so `walkValueChain` is not what refuses
  them.
* **F4** (clause (c3)) is reached by `cA_zA_pK.c` and by `owner_pre.c` — again, not by
  `owner.c`, which dies three stages earlier.

They remain real over-declines worth their own beads. They are not increments 3 and 4
of *this* bead.

## 5. LESSONS THIS MEASUREMENT PAID FOR

1. **A CORRECTED BISECTION IS STILL A BISECTION, AND INHERITS THE SAME BURDEN.** The
   2026-09-22 session corrected three false claims in bd `fn1q` and wrote a four-fence
   map in their place. That map named `MergePhiPeel` P9 as fence 1. **It is wrong in
   the same way, for the same reason** — it was read off the code rather than measured
   by removing the clause. The session that files a correction is not exempt from the
   rule it is enforcing.
2. **"WHICH GATE FIRES FIRST" IS NOT "WHICH GATE IS THE WALL".** P9 *is* reached first
   in the loop form. Removing it moves the decline to P7, then to P3/P4, then back to
   `ControlDetect`. A fence chain must be measured by **bypassing each clause in turn**,
   not by reading the first one that fires.
3. **READ THE REFUSING STAGE'S COMMENT FOR WHO IT SAYS THE OWNER IS.** `phiPeelable`
   names PredMux, in writing, as the stage that hoists arms — one screen above the
   clause the brief proposed to retire.
4. **`getenv` BYPASSES ARE THE CHEAPEST HONEST INSTRUMENT IN THIS TREE**, and the
   measurement that mattered most (three gates off ⇒ the program compiles, rolled,
   2b-clean) cost one build. ⚠ And the trap: the first E2 run reported `E2-cycle`
   *because the env var was never set on the command line* — the bypass was in the
   binary and not in the environment. **Print what you bypassed, or set a boundary
   control that must move.**
