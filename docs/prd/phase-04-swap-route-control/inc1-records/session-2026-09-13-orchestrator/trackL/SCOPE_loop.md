# SCOPE — Track L: the **LOOP form** of the owner's controlled-operation cascade (bd `wx8g`, `boi6.a`, `3qlq.6`, the bool-array wall)

Session 2026-09-13, **READ-ONLY scoping**. Every verdict measured on the frozen **ORACLE**
(`PROTOCOL.md`): `build/ir-pass/cq-opt` sha256 `fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`,
`libCQPass.so` `40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93` (built 2026-09-11
22:23 from `e96f89c`). Hash verified before the first probe and unchanged after the last. **No
build, no `lit`, no `ctest`, nothing written under `ir-pass/`, `include/`, `runtime/`, `tests/`,
`tools/`.** Probes + commands: `probes/README.md`. Ready-to-land pins: `ready/`. Scratch:
`…/scratchpad/trackL/`. Line numbers as of `01c89b5`.

Companions: `../../session-boi6/SCOPE_boi6.md` (D-A's design, H-1…H-10 — this record's §3 is its
H-10), `../../session-l4x4/SCOPE_l4x4.md` §2.4 (the in-loop form with no twin),
`../probes/README.md` (the flat cascade, Tracks M and R).

---

## 0. HEADLINE — three measurements decide the shape of this track

1. **The loop is not the problem. The CASCADE is.** `w2_uncond_prep_phase_qa` — a loop-carried
   `_Bool` rail, an in-body chained `cq_theta_i1`, a phase region on the register, a second quantum
   register alongside — **ACCEPTS today**: 12 trace lines, rolled, STRICT stage 2b `2 rail mint(s)
   of which 2 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven`. What the
   owner's cascade adds to that accept is (a) a *conditional* prep and (b) a *value* arm, and each
   of those has its own wall.
2. **Q2(i) — the `bool b[N]` array spelling is FREE when the source is flat and IMPOSSIBLE at every
   N when it is rolled, and the cut is not about N.** Hand-unrolled with constant indices, `clang
   -O1` SROA-scalarises the array *completely* (**0 allocas, 0 stores** measured) and the pass sees
   exactly the flat scalar-bool file — `a_flat_n2`'s `main` is byte-identical to `../probes/vb.c`'s
   above the measures. Rolled, the array survives **and `-O1` stamps
   `!{!"llvm.loop.unroll.disable"}` on the loop**, so no small-constant N ever gets scalarised:
   `a_loop_n2`, `a_loop_n3` (= `../probes/ve.c`) and `a_loop_n8` all decline the identical
   `cq taint escape: tainted value stored to memory`, and so does the array loop with the value arm
   deleted and with the prep made unconditional. The array wall is **N-independent and upstream of
   every control stage**.
3. **Q2(ii) — the scalar spelling is a DIFFERENT CIRCUIT, and it is almost certainly not the one
   the owner wants** (§0.2). It re-fires the subtraction off a stale record, so `a` goes negative.
   Its flat twin declines too (`s_flat_n2`, `t_flat_n2`: `condition predates a non-diagonal gate`),
   which means spelling (ii) has **no oracle stream on any binary** — the usual rolled-vs-unrolled
   `compare_files` witness has nothing to compare against, exactly the `SCOPE_l4x4.md` §2.4
   situation one construct over.

### 0.1 The two canonical customers, as written

```c
/* (i) ARRAY — every trip a FRESH qubit; the flat N=2 twin IS the owner's file. */
int a = 5; bool b[N] = {0};
for (int i = 0; i < N; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5); if (b[i]) a -= 3; }

/* (ii) SCALAR — ONE qubit re-prepared each trip. */
int a = 5; bool b = 0;
for (int i = 0; i < N; ++i) { if (a >= 3) b = cq_theta(b, .5); if (b) a -= 3; }
```

`probes/a_loop_n{2,3,8}.c`, `probes/s_loop_n{2,3,8}.c`, the hand-unrolled twins
`probes/{a,s}_flat_n{2,3}.c`, and the theta-seeded variants `probes/t_loop_n{2,3,8}.c` (spelling
(ii) with the classical seed peeled, §1.2 wall L-1).

### 0.2 The state vector each spelling denotes — write this in front of the owner

`Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩`; put `c = cos .25 ≈ 0.9689`, `s = sin .25 ≈ 0.2474`. `a = 5`
is classical at the first condition, so `-O1` folds trip 0's `a >= 3` to **true** (measured — this is
why the owner's flat file's first `cqrt_ry_i1` is *uncontrolled*, `../probes/va.trace`).

**(i) `bool b[3]`, N=3 — a FIRST-SUCCESS cascade with a kept history.** `flag_i = (a ≥ 3)`, and
because `a` only ever drops below 3 once, `flag_i = (b_0 = ⋯ = b_{i−1} = 0)`:

| branch `b₀b₁b₂` | `a` | amplitude |
|---|---|---|
| `000` | 5 | `c³` |
| `001` | 2 | `c²s` |
| `010` | 2 | `c·s` |
| `100` | 2 | `s` |

(norm `c⁶ + c⁴s² + c²s² + s² = 1` ✓). Each `b_i` is a **record of whether the i-th subtraction
happened**, all N are measurable at the end, and the amplitude of "never subtracted" decays as `cᴺ`
— the textbook reversible-history shape, and the direct generalisation of the file that compiles
today (`va.c`, 19 lines). **N qubits, one per trip.**

**(ii) scalar `bool b`, N=3 — ONE qubit, and the record is reused before it is cleared.** Trip 0
gives `c|0⟩|a=5⟩ + s|1⟩|a=2⟩`. Trip 1's flag is `(a ≥ 3) ⇔ (b = 0)`, so `CRy` rotates `b` only on
the `b=0` branch — but the **value arm is conditioned on `b`, not on the flag**, so on the branch
where `b` was already 1 it subtracts **again**:

| branch | `b` | `a` | amplitude |
|---|---|---|---|
| — | 0 | 5 | `c²` |
| — | 1 | 2 | `c·s` |
| — | 1 | **−1** | `s` |

and at N=3 `a` reaches **−4**. The intermediate records are never uncomputed, so the history is
mixed into one qubit and `a` leaves the intended range. **Spelling (ii) is not the loop form of the
flat file.** If the owner wants one qubit, the source must clear or uncompute `b` inside the trip —
which is a different program again, and the one with the real Bennett shape.

**Recommendation to the owner on Q2: (i).** It is the semantics the flat file already has, it is the
only one whose per-trip record survives to be measured, and its wall (§1.1) is ONE capability with
no new runtime symbol (§2.1). (ii) should be answered with a compile-time **diagnostic about the
program**, not a lowering.

### 0.3 Target streams

* **(i) N=1 flat**: `../probes/va.trace` — 19 lines, the shipped accept (2026-09-11, `e96f89c`).
* **(i) N=2/N=3 flat**: Tracks **M** and **R** own them (`../trackM/`, `../trackR/`); today
  `a_flat_n2` declines `control flow` and `a_flat_n3` declines `state prep seed is proven equal to
  the condition register`, the same two walls `../probes/{owner_file_2026-09-13,vd}.c` take. Cite
  their records for the stream; do not wait for them — the loop walls are disjoint from theirs.
* **(i)/(ii) ROLLED**: no stream exists on any binary. The witness must be built as rolled ==
  hand-unrolled under the *new* binary (`SCOPE_l4x4.md` §2.4's internal-consistency gate, labelled
  as one) **plus** K-independence of the lowered IR, because for (i) the unrolled twin is the flat
  file Tracks M/R are landing and for (ii) there is no accepting twin at all.

---

## 1. Every wall, IN ORDER, on the ORACLE — and the peel ladder

### 1.1 Spelling (i), the array

| # | wall | string (verbatim) | site / anchor | owner |
|---|---|---|---|---|
| **A-1** | the tainted store | `cq taint escape: tainted value stored to memory` | `TaintPropagation.cpp:526` (`kMsgStore`) from `declineTaintEscapes`; `a_loop_n3.c:6:26`, the store of the theta result into `b[i]` | **unowned** → file **L-1a**, the bounded rail-array (§2.1) |
| A-2 | — | — | nothing else was reachable: the wall is before `lowerLoops` (`CQLoweringPass.cpp:373`) and before detection (`:455`) | — |

**Peeled, three ways, and it does not move.** Delete the value arm (`a_loop_n3_noarm`) → same
string. Make the prep unconditional so there is no region at all (`a_loop_n3_uncond`) → same string,
col 14. Raise N to 8 → same string. **The only peel that works is unrolling the SOURCE**
(`a_flat_n2/n3`), which deletes the array (`grep -cE 'alloca|store'` → **0**) and hands the program
to Tracks M/R. So for spelling (i) the wall list is **exactly one item long**, and behind it sit
Tracks M and R's walls, not new ones.

**Is it in Phase 7.5's shipped accept-shape? No, and it is not even the same axis.** 7.5 is a
**tainted INDEX** over classical memory — a const-global QROM read (`QramLowering.h:1-17`) and the
`iw81.7` Shadow store into a bounded alloca. Ours is the mirror: a **classical index** (the
induction variable) with a **tainted value**. `qramCarveVerdict` names that case explicitly and
routes it away: *"`NotQram` — not a tainted-index access (a classical-address / value-tainted store
…): fall through to the GENERIC taint-escape decline (`kMsgStore`)"* (`QramLowering.h:56-60`). The
smallest shape that would work is in §2.1; it needs **no new frozen symbol**, which is why it is
cheap enough to be a real option.

### 1.2 Spelling (ii), the scalar — four walls, and the first one is a surprise

Measured order for the owner's literal source (`s_loop_n2`, and identically at N=3 and N=8):

| # | wall | string | site / anchor | owner |
|---|---|---|---|---|
| **S-1** | the §3c **clobber** fence, reached **through the BACK EDGE** | `cq controlled lowering: arm rewrites a condition operand under quantum control` | `ArmClassify.cpp:4593` — `diagonalAliasHit(Routed, Prov)` with `StraightThrough && Hit == Routed`; anchor `Chain.Ops.front()` = `%17 = zext i1 %16 to i8` (the prep arm's own output) | **unowned** → file **L-2** |
| **S-2** | the 2c wire fence on the **LICM-hoisted invariant compare** | `condition predates a non-diagonal gate` | anchor `%4 = icmp sgt i32 %1, 2`, hoisted to the preheader; row W | bd `drbq.12`, the compare half of bd **`wx8g`** |
| **S-3** | the rail root is a **CLASSICAL `false`** | `cq taint escape: tainted value muxed by a classical-condition phi` | `TaintPropagation.cpp:958`, `declineClassicalMuxes`, **after** detection | **unowned** → file **L-3** |
| **S-4** | the value arm | `cq loop lowering: loop-carried tainted value crosses iterations` | `LoopLowering.cpp:2108` (`kMsgCrossIter`, the **X1** clause: the latch incoming peels to a FRESH value-op rail), from `lowerLoops` at `CQLoweringPass.cpp:373` — **before** detection | the **loop layer**, not bd `3qlq.6` (§4) |

**Why S-1 is first and why that is an over-decline.** The condition is `icmp sgt i32 %12, 2` on `a`'s
header φ; `condProvenance` walks that φ to the latch incoming `%22 = select i1 %20, %21, %12`, whose
condition derives from the arm's own `%17` around the back edge. So the fence's question — *does the
arm rewrite a value the condition reads?* — is answered **true by the loop**, although **within one
activation the flag is minted strictly before the arm writes**. This is the position-free-walker
pattern CLAUDE.md L4/L6 describe: a *structural* guard doing a *semantic* job. `WireWalk`'s
`provablyBeforePerActivation` is the existing machinery for the per-activation reading, and the
value-arm §3c prong is the last consumer that has not been given it.

**Proof of the order, by peeling.**

| peel | probe | what fires next |
|---|---|---|
| arm → phase, `a` quantum (removes S-1's routed slot) | `w1_phase_quantum_a` | **S-2** (`condition predates a non-diagonal gate`, the hoisted `icmp`) |
| prep condition reads a DIFFERENT register `q` (removes the clobber, keeps both regions) | `w8`, `w9` | **S-2**, same anchor — so S-1 is not the prep region's only wall |
| prep region removed (unconditional prep), phase arm, classical seed | `s_loop_uncond_phase` | **S-3** — the minimal witness that `bool b = 0` *alone* is a wall |
| … the same with a **theta seed** | `p2` | **ACCEPT, rolled** (9 trace lines, 50 lowered lines) |
| prep region removed, VALUE arm, theta seed | `t_loop_uncond_value` | **S-4** |
| value arm as a two-op DIAMOND (not a select), no prep at all | `w3_value_diamond` | **S-4**, identical string |
| value arm as a select with a loop-INVARIANT bool | `w5_invariant_bool_value` | **S-4**, identical string |

**A FIFTH wall that only the loop form has, and nobody has recorded it: the carried `_Bool` is an
`i8` wire.** In the flat file `-O1` keeps the merge φ at `i1` (`../probes/README.md`:
`%6 = phi i1 …`). In the loop form it keeps `_Bool` at its **memory type**: measured in
`t_loop_n2`'s stage-1 IR, `%11 = phi i8`, `%15 = trunc nuw i8 %11 to i1`, `%17 = zext i1 %16 to i8`,
`%19 = phi i8`, `%20 = trunc nuw i8 %19 to i1`. So the region condition is a **`trunc`**, not a
`cq_theta_i1` call — bd **`r903`**'s residual construct (`trunc`/`zext`/phi/argument `i1`), which is
*decorative* in the flat file and **load-bearing** in the loop one. Any in-loop `_Bool` widening
that does not make the rail identity transparent to a `trunc`/`zext` pair will land on S-1/S-2 and
then die at `branch phase on a bare i1 condition` or `control flow` anyway. **Probe it first.**

### 1.3 What ALREADY works in a loop (the controls — keep these byte-identical)

| probe | shape | result |
|---|---|---|
| `p23` | loop-INVARIANT `_Bool`, phase region | ACCEPT, 6 lines (the shipped 1b accept) |
| `p2` / `p9` | loop-CARRIED `_Bool`, condition = the in-body chained theta, `if (b)` / `if (!b)` | **ACCEPT rolled**, 9 lines, K-independent — **pinned by nothing**; §3 fixes that |
| `p2u` / `p9u` | their hand-unrolled K=3 twins | ACCEPT, traces byte-identical |
| `w2` | `p2` + a second quantum register present | ACCEPT, 12 lines, 2 rails left allocated |
| `p1` | the carried **header φ** as the condition (theta AFTER the region) | DECLINE `branch phase on a bare i1 condition` — bd `boi6.a` |

---

## 2. The increment plan

### 2.1 L-1a — the bounded **rail array** (spelling (i)): the whole of Q2(i), and no new ABI

The observation that makes it small: **after lowering, a rail is an `i32` handle, i.e. a classical
integer** (Rule 15). `b[i] = cq_theta(b[i], .5)` wants to become
`h = cqrt_alloc_i1(0); cqrt_ry_i1(h, .5); handles[i] = h` with `handles` an ordinary `[N x i32]`
alloca in classical memory, and `cq_measure(b[k])` a `cqrt_measure_i1(handles[k])`. Nothing about
that needs a qubit-array ABI; the **only** reason it declines is that `declineTaintEscapes` runs
*before* lowering, on the still-`i1` tainted value.

The shape to accept (all five clauses, each a measured decline today):

1. a **non-escaping** `alloca` of a bounded, statically-known element count (the existing escape /
   address-taken analysis answers this);
2. **every** access is a classical-index `getelementptr` into that alloca, provably in bounds — a
   tainted index is 7.5's axis and must keep declining there;
3. the stored **value** is tainted and the element type has an ABI width (`WidthDispatch`);
4. no aliasing fan-out, no mixed classical/quantum use of the same cell (7.5's `matchQramAccess`
   provenance walk is the one owner of this question — **call it**, Rule 14);
5. the alloca's element type is rewritten to the handle type and the `store`/`load` pair carries
   handles; the **carve and the emitter must share one predicate**, the `isRecognizedIOSink` /
   `qramCarveVerdict` discipline the file already states, so a carve can never become a silent
   accept.

**The fence that makes it sound, and it must be written as a fence, not a hope:** a rail whose
handle is stored to memory is **FROZEN** — the uncompute spine cannot walk through memory, so such a
rail is never reverse-played, never in-place rewritten, and **never freed** (left allocated, Rule 6,
the qubits-not-scarce regime). Every in-place/stale-record fence keyed on SSA wires must refuse a
member whose handle escaped to a cell, loudly.

⚠ **Two instrument blind spots this increment creates.** (a) `free_pairing_check.py` counts
`cqrt_alloc` **sites**, so a rolled per-trip alloc reads as *one* rail left allocated when the
circuit mints K — it is already structurally blind to template-minted rails (CLAUDE.md) and this
adds a second family; say so in the slice header rather than citing 2b as clearance. (b) the golden
trace **does** see all K allocs, so the e2e diff is the witness here, not stage 2b — the reverse of
the usual division of labour.

### 2.2 L-2 — the §3c clobber fence, per activation (S-1)

The one-line statement: `diagonalAliasHit`'s verdict must be asked **per activation**, so an
overlap that exists only around the back edge is not a clobber. The machinery exists
(`provablyBeforePerActivation`, `phiTracksWire`, `recordLivePerActivation` — `WireWalk.{h,cpp}`);
this is the last §3c prong that reads a position-free walker. Rule 13's L2 applies directly: **when
you widen this set, ask what other set was computed over the same closure** — `condProvenance`'s φ
walk (`ArmClassify.cpp:231-261`) feeds the 2c fence too, and narrowing one without the other is the
r9e5 "two rungs, two closures" finding again.

### 2.3 L-3 — a CLASSICAL rail root for a carried `_Bool` (S-3)

`bool b = 0` before the loop makes the header φ's external incoming the constant `false`, so
`railPhiRootMint` (`LoopPlan.h:353-400`) finds **no mint** and `collapseRailPhisIn` refuses the φ;
the surviving tainted-φ-with-classical-incoming is then caught by `declineClassicalMuxes`. The deep
reason is worth stating because it bounds the fix: the body's `cq_theta_i1(%φ, θ)` is a taint
**SOURCE** on trip 0 (arg-0 classical) and **CHAINED** on trips 1…K−1, and one rolled gate cannot be
both `alloc+ry` and `ry`. So the increment is: **materialise the root mint in the PREHEADER** —
`cqrt_alloc_<W>(seed)` for a classical external incoming that is a constant — and let the body's
theta lower as chained for every activation. That is exactly what `lowerRotations` already does for
`p2`, with the alloc coming from the user's pre-loop `cq_theta`; here the pass supplies it. It is
also the only one of the four walls whose absence is *invisible in the flat file*, which is why it
has no bd and no fixture.

### 2.4 L-4 — the in-loop VALUE arm (S-4): the loop layer's X1 clause, not bd `3qlq.6`

See §4. The customer needs the X1 clause to admit a latch incoming that peels to a **controlled-copy
merge output** (a fresh rail per activation) rather than declining it as a cross-iteration dirty
rail. This is the expensive one: it is the 3qlq Inc-2 value path *inside* the 8h7d.5 rolled loop,
with the per-activation record fences applying to the hoisted chain's operands, and it is where the
**C-1 in-loop entangled-rail family** (eight instances over six adversarial rounds, two introduced
by a fix, the eighth found by a round reviewing a different increment) gets its first carried-rail
subject. Budget **three** rounds; CLAUDE.md's measured hit rate says the third finds something.

### 2.5 What each increment needs from the drbq Inc-3 in-loop machinery

| machinery | site | what L-1a/L-2/L-3/L-4 owe it |
|---|---|---|
| `collapseRailPhisIn` / `collapseFlattenedLoopRails` | `LoopLowering.cpp`, called `CQLoweringPass.cpp:473` | L-3 changes its **step (1)** premise (an external incoming that is a constant, not a mint); L-4 changes its **X1** clause (`:2108`, and the round-2 twin at `:2551` — BOTH, or round 2 re-declines what round 1 accepted) |
| `railPhiRootMint` (+ the lifted `railPhiSelfCycleClosed`, SCOPE_boi6 §2.1) | `LoopPlan.h:353-400` | the **one** owner of "will the collapse claim this φ" — L-3 extends its answer, never re-derives it (Rule 14; the drbq Inc-3 (b′) precedent) |
| `staleRailRecordRead` | `LoopLowering.cpp:1042` | L-4's merge output is a new **record** class; L-1a's memory-resident handle must be refused as a record source |
| `markIfRailLocal` / `invariantRegisterRoots` / `CarriedRoots` | `LoopLowering.cpp` ~3221-3465 | L-4 mixes an invariant rail with a carried one — the C-1 family's exact subject (SCOPE_l4x4 §2.4, SCOPE_boi6 H-6) |
| `recordLivePerActivation` / `provablyBeforePerActivation` | `WireWalk.{h,cpp}` | L-2 **is** this call; L-4 needs it for the hoisted chain |
| M-β (RAUW to the last hoisted gate) | `SwapRouteEmit.cpp` | L-4's merge under a loop; the M-α/M-β split (bd `drbq.10`) is unretired and must be decided per stem, not inherited |
| the structural freeze of a LOOP-CARRIED rotated register | drbq Inc 3 | L-1a's memory-resident rails are a **second** freeze class; write one rule, two members |
| `reverifyRailCondReads` | `ArmClassify.cpp` ~2060-2110, run `CQLoweringPass.cpp:510` | **SCOPE_boi6 H-1 verbatim**: it `dyn_cast`s the record to `CallInst` and its `WeakTrackingVH` follows the collapse's RAUW. Owner question **Q1 is still open**; the brief's instruction stands — assume option (a) *ask rung (iii) BEFORE the collapse and record the verdict*, and cost (1) (+20–40 lines, a second loop-aware barrier spelling, pays the Rule-14 cost) and (3) (record `(root mint, read, loop header)` and teach the stage the back edge is the barrier, ~same size, one new fixture family) |

### 2.6 The `_Bool` axis the twin matrix lacks

`grep -c bool tools/loop_twin_matrix.py` → **2**, both inside `phi_surface_of_header`. Cells:
`grep -c '^m_' tools/loop_twin_matrix.expected.txt` **259** + `grep -c '^cell '
tools/loop_twin_matrix.quarantine.txt` **29** = **288**, and every one of them is blind to a
carried `_Bool` condition. L-2/L-3/L-4 each give the C-1 leak family a subject it has never had, and
the twin matrix is **the only instrument in the tree that can see a leaked template-minted rail**.
A sub-grid is not optional: condition ∈ {`if (b)`, `if (!b)`, `if (b && q==k)`, **the `i8`
trunc/zext spelling of §1.2**} × {phase arm, value arm, prep} × {invariant, carried} × the existing
PREFIX/SUFFIX and preheader-op axes ≈ **24–40 cells**; both tables regenerate
(`--regenerate` refuses while a boundary control has moved), and `e2e-loop-twin-matrix` is the
~180–400 s long pole of the suite.

---

## 3. The H-10 pins — WRITTEN, validated, under `ready/`

SCOPE_boi6 §0.4/H-10: `p2` and `p9` are **shipped accepts that no fixture and no slice pins**, and
they are the discriminator that bd `boi6.a` changes no existing stream. Re-measured here on the
ORACLE and delivered ready to land (`ready/README.md` carries the commands):

| file | destination | measured |
|---|---|---|
| `control_phase_kickback_rail_inloop_carried_theta_first.ll` | `ir-pass/test/` | pass exit 0; every `CHECK` copied from the ORACLE's output **on this exact file** |
| `control_phase_kickback_rail_inloop_carried_theta_first_negated.ll` | `ir-pass/test/` | exit 0; `cqrt_rz_i1(%h, 0xBFE6666666666666)` — the diagonal ¬-arm, **no `cqrt_x`** |
| `slice_control_phase_bool_carried_theta_first.c` + `.expected.log` | `tests/e2e/` | exit 0, 9 trace lines, golden `diff`-clean, STRICT 2b `1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven` |
| `…_unrolled.c` + `.expected.log` | `tests/e2e/` | exit 0, 9 lines, **byte-identical** to the rolled golden |
| `CMakeLists.lines.txt` | append after `e2e-phase-bool-loop-twin-identical` (line 5181) | 2 slices + 1 `compare_files` twin gate |

**K-independence, measured without `-g`** (debug metadata inflates the count — a `-g` number is not
comparable): the lowered module is **50 lines at K=3 and 50 lines at K=1000**, traces 9 and 2003;
the hand-unrolled K=3 twin is 42 lines. One `cqrt_alloc_i1` in the preheader, one `cqrt_ry_i1` + one
`cqrt_rz_i1` in the single body block, no `cqrt_x`, no `cqrt_free`, no mint, no `cq_template_*`.

⚠ **`lit` was NOT run** (PROTOCOL.md scoping row). What was run is the pass itself on both fixtures
and the full e2e pipeline on both slices, including stage 2b and the link. The landing agent owes
`lit --filter 'carried_theta_first'`, the three ctest entries, and the injection matrix (the
`RYCNT`/`ACNT`/`MDCNT`/`MDTAG` prefixes and `NOROUTE-NOT: phi i1` exist for the moved-gate,
extra-gate and collapse-did-not-run mutants) — `ready/README.md` §"What the landing agent still
owes".

---

## 4. §4 answered: the value arm's wall is the LOOP LAYER, not bd `3qlq.6`

`if (b) a -= 3` folds to `select i1 %b, %a-3, %a` at `-O1`, so it is the 4.4 data select — but it
never reaches `SelectClassify`. **Three independent spellings all die at the loop layer, before
detection:** `t_loop_uncond_value` (select, carried bool), `w5_invariant_bool_value` (select,
*invariant* bool, no prep region at all), `w3_value_diamond` (a genuine two-op **diamond**, so not a
select at all), plus boi6's `p6` re-measured — all four print
`cq loop lowering: loop-carried tainted value crosses iterations`, which is `LoopLowering.cpp:2108`'s
**X1** clause (the latch incoming peels to a fresh value-op rail), reached from `lowerLoops`
(`CQLoweringPass.cpp:373`) before `detectControlRegions` (`:455`).

So bd `3qlq.6`'s own decline (in-loop value arms inside the rolled loop) is **unreachable** for this
customer: the subject is the carried register `a`, and the loop layer judges it first. The
consequence for planning is concrete — **L-4 must be scoped on `LoopLowering`'s X1 clause with
`3qlq.6` as its downstream**, not the other way round, and both the pre-detection site (`:2108`) and
its round-2 twin (`:2551`) must move together or round 2 re-declines what round 1 accepted (CLAUDE.md
L1, the "stage that runs once" lesson, in its `RailRound2` form).

---

## 5. Cost, and the order to recommend

| increment | production lines | fixtures | goldens / ctest | matrix cells | rounds | one-line reason |
|---|---|---|---|---|---|---|
| **L-0** the H-10 pins (`ready/`) | **0** | 2 | +2 goldens, +3 ctest | 0 | 0 | already written and validated; it is the discriminator every later increment needs, and it is free |
| **L-3** classical rail root in the preheader | ~60–90 (`LoopLowering` step (1), `railPhiRootMint`, one emitter line) | ~10 | +2 / +3 | 4 | 2 | the ONLY wall invisible in the flat file, and every owner spelling (`bool b = 0`) hits it |
| **L-2** §3c clobber per activation | ~70–110 (`ArmClassify` §3c + the `condProvenance` closure question) | ~14 | +2 / +3 | 6 | **3** | the FIRST wall of the owner's scalar loop, and a structural guard wearing a semantic label (L6) |
| **L-1a** the bounded rail array | ~150–220 (`TaintPropagation` carve + a `QramLowering`-shaped predicate + the freeze fence) | ~20 | +4 / +6 | 8 | **3** | the whole of Q2(i); no new frozen symbol; reuses 7.5's provenance walk |
| **L-4** the in-loop value arm (X1) | ~200–300 (`LoopLowering` X1 ×2 sites, the merge under a loop, M-β) | ~28 | +6 / +9 | 12–20 | **3** | the cascade's `a -= 3`; the C-1 family's first carried-rail subject |
| **boi6.a** the header-φ rail leaf | ~190–260 (SCOPE_boi6 §6) | ~36 | +6 / +9 | 24–40 | **3** | independent of the cascade; H-1 must be answered by the owner first |
| **wx8g** / `drbq.12` the in-loop prep + hoisted compare | ~120–180 | ~18 | +4 / +6 | 8 | 3 | S-2; wx8g's cost is **total** today (no spelling compiles) |

**Recommended order — and the first two are decided by Q2, not by cost.**

1. **L-0 now.** Zero risk, zero production lines, and nothing later is safe without it.
2. **If Q2 = (i) (recommended): L-1a.** One wall, N-independent, no new ABI, and it finishes the
   owner's sentence — *"a large loop where MANY of those controlled operations are applied"* — with
   the semantics the flat file already has. Its unrolled twin is Tracks M/R's program, so the two
   tracks compose into one witness instead of two.
3. **If Q2 = (ii): L-3, then L-2, then L-4** — in that order, because each is the next wall the
   previous one exposes (§1.2's peel table) and L-3 is the smallest. ⚠ But say the §0.2 finding out
   loud first: (ii) denotes a circuit whose `a` goes negative, so the owner may not want it at all.
4. **L-2 regardless of Q2**, third at the latest: it is an over-decline of a valid circuit (the
   owner's 2026-09-11 ruling makes that a defect), it is the wall a user hits first, and it unblocks
   every `if (cond on a) … ; if (b) a -= 3;` loop in the language.
5. **`boi6.a` and `wx8g` stay separate beads**, after the cascade: `boi6.a` needs owner answer Q1
   (H-1) before a line is written, and `wx8g`'s compare half is `drbq.12`'s 2c window, which L-2's
   per-activation work will have already rehearsed.

**New beads to file (none of these has an owner today):** **L-1a** the bounded value-tainted rail
array (escape-carve + freeze fence); **L-2** the §3c clobber fence's back-edge over-decline;
**L-3** the classical rail root for a loop-carried rail; and an **L-5 note on bd `r903`** recording
that the `trunc`/`zext` `i8` spelling of a carried `_Bool` is load-bearing in every loop form
(§1.2) — today it is filed as a flat-shape residual.
