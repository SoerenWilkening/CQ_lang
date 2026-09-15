# Track B probes — session 2026-09-15 (SCOPING ONLY)

Every verdict below is the `PROTOCOL.md` per-probe pipeline run against the **frozen ORACLE**

```
0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  build/ir-pass/cq-opt
94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  build/ir-pass/libCQPass.so
```

re-verified with `shasum -a 256` at track open. **No build, no `lit`, no `ctest`, no corpus sweep, no
injection matrix** — the PROTOCOL scoping row.

## Drivers

| script | what it does |
|---|---|
| `run.sh <probe>.c` | the plain pipeline: `clang -O1 -g` → `cq-opt` → (on accept) stage 2b + link + run. Prints `DECLINE <string>` or `ACCEPT trace=N lines \| 2b: …` |
| `emulate_piece3.sh <probe>.c` | takes the promoter's OWN output (`CQ_RAILBANK_DBG`), deletes the one surviving bank store **and its storage-extension cast**, and re-runs the ORACLE. ⚠ **This emulates PIECE 3 ALONE.** With no taint rule the bank loads stay classical and `cq_measure` emits nothing — that is the point (§3.3 of `SCOPE_B.md`) |
| `derive_owner_variants.sh [src.c]` | regenerates `derived/B*.ll` from the owner's file. The outputs are **committed** because `example/` is in `.git/info/exclude` (bd `zwtm`) and the probes would otherwise be unreproducible |

Run everything from the repo root.

---

## 1. The headline, and the wall sequence behind it

| probe | question | measured answer |
|---|---|---|
| `b01_owner_verbatim.c` | does the owner's program compile? | **DECLINE** `cq taint escape: tainted value stored to memory` at `…:92:19`; `CQ_CTRL_DBG` prints `railbank [Bank] cells=3 abi=i8 trips=3` on `store i8 %cq.bank, ptr %cq.bank.addr`. **Bank → promoted → declined at the same `!dbg`**, reproduced |
| `derived/B0_owner_promoted.ll` | what does the promoter actually emit? | the same decline, **idempotently** (B8 terminates the fixpoint). The module is `SCOPE_B.md` §2.1 |
| `derived/B2_nostore.ll` | with piece 3 alone, what is next? | **DECLINE** `cq controlled lowering: value-arm swap-route under quantum control`, anchored at **`%27 = zext i1 %26 to i8`** — the `i8`/`i1` residual makes the arm a VALUE arm |
| `derived/B3_i1cell_nostore.ll` | with pieces 2+3, what is next? | **DECLINE** `cq controlled lowering: control flow inside a loop body under quantum control`, anchored at `%24 = icmp sgt i32 %23, 2` — `iterationLocalRollable` **(c3)**, because `cq_measure(a)` reads a tainted value defined in `L` |
| `derived/B6_i1cell_nostore_noAmeasure.ll` | and behind (c3)? | **DECLINE** `cq loop lowering: loop-carried tainted value crosses iterations` — **X1**, bd `ej5w` / W3. `a` is a cross-iteration tainted accumulator |

⚠ **Piece 1 does not move B3's verdict**: (c3) quantifies over values *defined in* `L`, and the bank
loads the taint rule tags are defined *outside* it.

## 2. The bank is not the discriminator — the scalar controls

| probe | question | measured answer |
|---|---|---|
| `b02_scalar_measure_a_outside.c` | is (c3) about the bank? | **DECLINE** `control flow inside a loop body`. **No array, no store, no bank** — same wall |
| `b03_scalar_measure_a_inside.c` | does measuring `a` in-loop help? | **DECLINE** `condition measured before the control route` — a different wall |
| `b04_scalar_no_a_read_outside.c` | does removing the outside read help? | **DECLINE** `condition measured before the control route` (the in-loop `cq_measure(b)` becomes the problem) |
| `b05_scalar_classical_acc.c` | what if the arm does not feed `a`? | **ACCEPT**, 9 trace lines, STRICT 2b `1 mint / 1 left allocated / 0 violation(s)`. **The tainted loop-carried accumulator is the discriminator, and it is orthogonal to W1** |

## 3. Piece 2 — the `i8`/`i1` residual and the pun fence

| probe | question | measured answer |
|---|---|---|
| `b09_bool_zext_to_int.c` | what does a tainted `zext i1 → i32` lower to? | **ACCEPT** — `cq_template_zext_i1_to_i32(h0) -> h1`: **a second rail**, `h0` left allocated. A bank whose storage cast reaches `lowerOps` stores a different, entangled rail from the one it rotated |
| `derived/B8_2a_normalised.ll` | can the cast just be deleted (`store i1` into an `i8` cell)? | **NO.** The carve answers **`NotBank`** — the **PUN FENCE** `QramLowering.cpp:1263`. `CQ_CTRL_DBG` prints **no** `railbank` line |
| `derived/B7_i1phi_zextsunk_store.ll` | can it be SUNK to the store instead? | **YES** — `CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3` on `store i8 %cq.bank.i8, …`. The `i1` merge φ and the pun fence coexist. **This is the design** |
| `b10_bank_int_cells_uncond.c` | `int` cells with constant-index measures? | **DECLINE** `cq rail bank: array mixes a rail cell access with an unrecognized one` — `-O1` emits the constant-index reads of `[3 x i32]` as **byte-offset** geps. `SCOPE_B.md` §10 item 4 |
| `b11_bank_int_measureloop.c` | `int` cells with a measure loop? | **DECLINE** `kMsgStore`, carve **`Bank`, `abi=i32`**, no cast anywhere. The `int` spelling has no residual; the `_Bool` one is the owner's |

## 4. The silent miscompiles — reproduced

| probe | question | measured answer |
|---|---|---|
| `emulate_piece3.sh b12_bank_bool_measureloop.c` | what does piece 3 **without** piece 1 emit? | **`opt` exit 0, STRICT 2b `0 violation(s), 0 unproven`, 6-line trace** — `alloc_i1; ry_i1` ×3 and **ZERO measurements** for three written `cq_measure(b0[i])`. The golden byte-diff cannot see a measurement that was never emitted |
| `emulate_piece3.sh b14_bank_nonmain.c` | and outside `main`? | **`opt` exit 0, 2b `1 verified, 0 violation(s)`, 12-line trace** — `ry(+0.5); ry(−0.5); cqrt_free` **per cell**: the spine un-prepares and frees the three qubits the user is about to measure. ⚠ **Impossible inside `main`** (`FreePoint.cpp:182-183` → `Escaped`). `noinline` is load-bearing — without it `-O1` inlines `kern` and the question disappears (measured) |
| e2e-slice residency sample (80 `tests/e2e/slice_*.c`, `-O1`, attributed per defining function) | is the `main` short-circuit the common case? | **NO — it is the exception.** `4` confine the quantum work to `main`, `10` to a non-`main` helper, **`66` to both**: `76/80` carry it outside `main`. `58/60` still define >1 function after inlining. ⚠ This **refutes** the claim I first wrote into `SCOPE_B.md`, and makes D1 a **precondition of the accept** rather than defence in depth (§5.2) |
| `derived/B9_classcond_livephi.ll` | a bank stored under a CLASSICAL condition? | **DECLINE** `cq taint escape: tainted value muxed by a classical-condition phi`. Safe |
| `derived/B10_classcond_deadphi_crash.ll` | …and if that φ becomes DEAD? | **`LLVM ERROR: Broken module found, compilation aborted!`** — `PHI node operands are not the same type as the result! %cq.bank = phi i1 [ %h, … ]`. Unreachable in the shipped design (the store keeps the φ live) and **one DCE away**. `SCOPE_B.md` §5.3 |

⚠ `B9`/`B10` are derived from `b06_bank_classical_cond.c`'s promoter output the same way
`derive_owner_variants.sh` derives the rest; `B10` is the store-deleted form and `B9` replaces the
store with a `cq_measure` so the φ stays live.

## 5. R2 — the D1 byte-identity measurement, pre-taken

| probe pair | question | measured answer |
|---|---|---|
| `b12_bank_bool_measureloop.c` vs `b13_…_zeroinit.c` | does the uninitialised bank emit what a written `= {0}` emits? | **BYTE-IDENTICAL**, `diff` empty, equal sha256 `ef75e8d7936811dbaa9f600b4851feabd6dd03ea924fbaaccfabc3d50f34005a` (6 gate lines each, under `emulate_piece3.sh`) |
| `b07_bank_uncond.c` vs `b08_…_zeroinit.c` | the same, at the promoted-IR level | identical apart from the surviving `llvm.memset` and attribute renumbering. The theta seed is `i1 false` in **both** |
| `…/session-2026-09-14c-xdu2-w1/trackI/probes/w1_flat_prep_only.c` | what stream must the bank reproduce? | **ACCEPT**, 9 trace lines: `alloc_i1/ry_i1` ×3 then `cqrt_measure_i1` ×3. Its **6 gate lines are byte-identical** to `b12`'s emulated 6 — the 3 measures are exactly the delta piece 1 restores |

⚠ **What the pre-measurement does not witness:** the three measures, which do not exist under the
emulation. The real measurement is still **owed with the accept** (R2).

## 6. The W1 accept candidates (all `Bank`, all at the wall today)

| probe | carve verdict | note |
|---|---|---|
| `b06_bank_classical_cond.c` | `Bank cells=3 abi=i8 trips=3` | ⚠ **NOT an accept candidate** — §4 above: `kMsgClassicalPhi` |
| `b07_bank_uncond.c` | `Bank cells=3` | constant-index measures, uninitialised |
| `b08_bank_zeroinit_uncond.c` | `Bank cells=3` | the R2 twin |
| `b12_bank_bool_measureloop.c` | `Bank cells=3 abi=i8 trips=3` | **the canonical W1 slice** |
| `b13_bank_bool_measureloop_zeroinit.c` | `Bank` | its R2 twin |
| `b11_bank_int_measureloop.c` | `Bank cells=3 abi=i32 trips=3` | the width axis |
| `b14_bank_nonmain.c` | `Bank` | **the mandatory non-`main` fixture** (§4) |

## 7. Re-measured from earlier sessions (Rule 11)

| probe | recorded verdict | THIS ORACLE |
|---|---|---|
| `…/session-2026-09-14-orchestrator/trackL/probes/a_flat_n3.c` | DECLINE `state prep seed is proven equal to the condition register` (SCOPE_L1a §7/§9) | ⚠ **ACCEPT** — `SCOPE_L1a` is STALE; corrected in place, routing item **R4** |
| `…/trackL/probes/a_flat_n2.c` | ACCEPT | ACCEPT — unchanged |
| `…/trackL/probes/a_loop_n3.c` | `kMsgStore` | unchanged |
| `…/trackL/probes/L1_promoted_nostore.c` | `control flow inside a loop body` | unchanged — and now explained: `iterationLocalRollable` (c3) |
| `…/trackL/probes/L7_array_uninit.c`, `L8_array_int_cells.c` | `kMsgStore` | unchanged |

## 8. F-3 — the three fixtures that stopped isolating their clause

`CQ_CTRL_DBG=1 CQ_RAILBANK_DBG=1 cq-opt … ir-pass/test/<f>.ll`:

| fixture | claims to isolate | what refuses it today |
|---|---|---|
| `railbank_promote_reject_two_cells.ll` | B2 | carve `cq rail bank: array has cells no iteration writes` |
| `railbank_promote_reject_store_outside_loop.ll` | B5 | carve `cq rail bank: array is written from more than one store site` |
| `railbank_promote_reject_inloop_other_read.ll` | *"nothing non-rewritable inside `L`"* | carve `cq rail bank: array has cells no iteration writes` |

All three still pass lit; their `NOTS-NOT: CQ_RAILBANK_DBG: promote bank` check is **vacuous** because
the promoter never runs. `SCOPE_B.md` §8 — and ⚠ **B5 may be structurally unreachable**, not merely
mis-spelled.
