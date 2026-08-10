# Phase 7.6 PRD — Reversible I/O output tape (DRAFT)

> **Status:** DRAFT, written at the start of Phase 7.6 (2026-06-21) to
> memorialize the design decisions resolved in PRD-discovery discussion + the
> verified subsystem map. Does not duplicate [`ROADMAP.md`](../../../ROADMAP.md)
> §"Phase 7 — 7.6" or the `bd memories reversible-output-tape-io` /
> `abort-exit-park-cascade` directives; captures the 7.6-specific decisions,
> deliverables, and done criteria. One PRD covers the whole I/O-tape increment
> family (owner direction 2026-06-21).
>
> **Owner decisions folded in 2026-06-21 (PRD review):** (1) dedicated
> `OutputRails` set; (2) controlled `if(q)printf` is **in** 7.6; (3) **`puts`
> dropped** — string output is a memory problem owned by 7.5; (4) Rule-13 gate
> applies despite the ABI footprint; (5) **explicit tape ABI** so the backend
> owns physical allocation / output-qubit counting / inspection / truncation —
> this makes 7.6 a pre-freeze (freeze-gating) item; (6) **the tape is a
> first-class resource handle** — `cqrt_tape_alloc()` returns a tape the writes
> are threaded through (backend owns the append cursor; **no per-write index**),
> so the write primitive is reusable across tapes (stdout / stderr / future
> reversible logs) without an ABI break, consistent with the qubit-handle pattern.

---

## 0. Invariant recap (not new — the ground 7.6 stands on)

- **Over-declining is safe; over-accepting is a silent miscompile** (Prime
  Directive). Every new accept-predicate here ships with a decline fixture +
  adversarial probe (Rule 12).
- **The compiler never inserts a measurement the user did not write** (Rule 5).
  7.6 *is* the coherent alternative to a print-site measurement — it must add
  **zero** measurement gates. The permanently-rejected `-fcq-measurement-bridge`
  (owner: *never*) is exactly what this replaces.
- **Verify-clean ≠ correct** (Rule 2). 7.6's hazards — a kept output rail
  reversed/freed by the uncompute spine, a write to the wrong tape / a non-append
  that loses the transcript, a carve-out with no emitter leaving a `printf`
  reading an `i32` runtime handle, a wrong frozen `cqrt_tape_*` signature — are
  **all verify-clean with no downstream backstop**. Cleared by analytic/trace
  reasoning + golden e2e diff + independent Rule-13 review, never by `opt -verify`.
- **Taint is the only Q/C boundary** (Rule 3). 7.6 adds **no taint source and no
  sink**; `@cq_theta` stays the sole source, `@cq_measure` the sole sink. It only
  changes *what a tainted value reaching a recognized I/O callee does* — coherent
  tape-append instead of loud decline.
- **Free only a proven-`|0⟩` rail; an Escaped/kept rail is never freed** (Rules
  6/8). An output-tape entry is a **kept output qubit** (Bennett output tape):
  never uncomputed, never freed. Routing it through `FreePoint` / `Uncomputation`
  would collapse the very output the user asked to emit.
- **The IR pass owns *reversibility*; the runtime/backend owns *physical
  resources*.** `cqrt_alloc_<W>` already returns an *opaque `i32` handle*; the IR
  pass never numbers, counts, or resets physical qubits. 7.6 keeps that line and
  extends it to tapes: the pass declares *which tape to append to* and *that the
  entry rail is kept*; the backend owns tape allocation, the append cursor, the
  output-qubit count, inspection, and truncation. A **tape handle is a classical
  resource token** (like a file descriptor) — not tainted, not a qubit; the
  uncompute spine ignores it (only the per-entry `out_handle` is `OutputRails`).
- **Handles are always `i32`; width lives in the symbol suffix** (Rule 15). The
  tape write picks `cqrt_tape_write_<W>` by the operand's ABI width, captured by
  SSA identity **before** rotation lowering RAUWs the operand to its `i32` handle.

---

## 1. Scope

7.6 widens the **accepted-C subset** so a **tainted I/O sink** — `printf` /
`putchar` — lowers **coherently** instead of loud-declining at
`declineTaintEscapes`. Today a tainted scalar consumed by `printf` false-declines
with `kMsgUnknownCallee` ("cq taint escape: tainted value consumed by an unknown
callee", `TaintPropagation.cpp:330-331,533-539`). 7.6 replaces that decline, **for
the proven integer-scalar shape only**, with an **append-only output tape**: each
tainted integer-scalar argument is appended to a tape (`cqrt_tape_alloc()` +
`cqrt_tape_write_<W>`) as a **fresh `|0⟩` output rail** that is kept (never freed,
never uncomputed). The measurement is **deferred to tape inspection** (a backend
concern), so the user's register `q` stays coherent.

**`puts` is out of scope (owner decision 3).** `puts`/`printf("%s")` take a
**pointer**; taint never lives on a pointer in this model. The only way a quantum
value reaches them is by being *stored into a buffer* first — which declines
upstream at the **store guard** `kMsgStore` ("tainted value stored to memory"),
not at the call. Making that path coherent is a **reversible-memory** problem
owned by **Phase 7.5** (Shadow `store`), not 7.6.

**Frozen-ABI fault line (the one axis that matters):**

| Item | New frozen ABI? | Freeze-gating? |
|------|-----------------|----------------|
| Tape resource | **Yes** — `cqrt_tape_alloc` (width-agnostic) | **Yes** |
| Uncontrolled tape write (`printf`/`putchar` integer scalars) | **Yes** — `cqrt_tape_write_<W>` | **Yes** |
| Controlled tape write (`if(q)printf`, Tier 0) | **Yes** — `cqrt_tape_write_<W>_controlled` | **Yes** |

7.6 adds a **small new frozen `cqrt_*` core-ABI family** (§2.8) so the backend can
own the physical side of the tape. The symbols are **hand-written core ABI**
(`runtime/cq_runtime.{h,c}`), **not** YAML-generated templates (Rule 15 governs
`cq_template_*`, not `cqrt_*`). Because the surface is frozen at Phase 11, **7.6
must land pre-freeze** and is cleared by independent Rule-13 review (§4) — both for
the frozen signatures and because it edits the escape/uncompute spine (where every
silent miscompile has lived).

---

## 2. Design decisions

### 2.1 One PRD; controlled `if(q)printf` is **in** 7.6 (owner decision 2)
The roadmap's "one PRD per increment" governs: 7.6 is a single PRD covering the
uncontrolled tape write and the controlled (`if(q)printf`, Tier-0) write. The
controlled case is a **firm** member of 7.6 (not a defer-if-hard hedge): it
composes with the existing swap-route control machinery via a single
`cqrt_tape_write_<W>_controlled` and is the second increment (§7).

### 2.2 Carve `{printf, putchar}` out of `declineTaintEscapes` by **exact name**, never prefix
Recognition is a `continue` inserted in the `CallBase` branch of
`declineTaintEscapes` (`TaintPropagation.cpp:468-540`), **between** the curated-
intrinsic check (~`:532`) and the generic `kMsgUnknownCallee` decline (`:537`) —
structurally identical to the existing carve-outs: `cq_invert_` (1c, `:499-501`),
`shouldSpecialize`/`plan6.Diagnosed` (1d-Phase6, `:515-517`), and
`isCuratedReversibleIntrinsic` (1d-Phase7.1-E, `:530-531`). **Decision: exact-name
membership over a fixed `{"printf","putchar"}` set** — *never* a `starts_with`
prefix accept (the "`cq_theta_evil`" over-accept hazard: a user function named
`printf_helper` must not slip through). Mirrored into the `runOnFunction` dead
shim (`CQLoweringPass.cpp:159-216`) for twin-pipeline parity.

### 2.3 The tape emitter runs **before `lowerRotations`** (pre-RAUW SSA identity)
A new `lowerIOSinks` step is wired into `CQLoweringPass::run`, after control
lowering (`:96-97`) and **before `lowerRotations` (`:132`)** — the same constraint
control lowering obeys. After `lowerRotations`, every tainted value *is* its `i32`
runtime handle, so a surviving `printf` reading it is verify-clean (the exact
opaque-call silent miscompile). The emitter references the **still-present tainted
SSA values** and reads each operand's ABI width before the launder. Mirrored into
the `runOnFunction` shim per §2.2.

### 2.4 Append-only **tape via a first-class handle** — never overwrite, never lose the transcript (owner decision 6)
The emitter keeps a small **`stream → tape handle` registry** and emits **one**
`cqrt_tape_alloc()` lazily per distinct tape (just one — stdout — in v1), threading
that handle into every write. For each tainted integer-scalar arg it emits
`cqrt_tape_write_<W>(i32 tape, i32 src) → i32 out_handle` (**append**; the backend
owns the cursor, so there is **no per-write index**) and erases the original sink
call (`putchar` wholesale; `printf` once all its tainted scalar args are appended).
**Decision: append, never an XOR-accumulator** — each value gets its own fresh kept
rail, or the transcript is lost (verify-clean wrong output). The IR pass does
**not** allocate the physical rail or count qubits — `cqrt_tape_write_<W>` is the
declarative point at which the **backend** allocs the entry rail + advances the
cursor; the pass only holds the returned `out_handle` and marks it kept (§2.5).

**Tape length is classical/deterministic** (fixed by the static site count, per
`bd memories reversible-output-tape-io`; dynamic growth for unbounded loops is
post-freeze). This is what makes append coherent: even a **controlled**
`if(q)printf` (§2.1) *always* appends an entry — only the entry's *content* is
conditional (`q` if the flag else `|0⟩`). There is never a superposition over "the
tape has N vs N+1 entries."

The source `src` is *preserved as a register* — the tape write is CNOT-class,
control-preserving, not a destructive sink like `cqrt_measure` — so it does not
collapse `src` and does not consume it: `src` stays a terminal candidate and its
DAG is still recovered. **A welcome consequence of the explicit symbol:**
`cqrt_tape_write_<W>` is *not* a recognized reversible gate the uncompute spine
re-emits, so the "involution re-emit XORs the rail back to `|0⟩`" collapse hazard
cannot arise — the spine simply never reverses a tape write (it is sink-class,
like `cqrt_measure`).

> **NARROWED by owner ruling 2026-08-10 (bd `261j`).** This paragraph used to
> continue "…so `src`'s own lineage **uncomputes normally** through the Phase-5
> spine; only the kept output rail is special." **That step is false**, and it is
> the false step that shipped a hidden measurement into `slice_io`. "Bennett
> copy-out" is sound only when the *reversal* also restores the copy's
> destination; here the destination is a **kept** rail the reversal never touches,
> so the record leaves `src` **entangled** with it.
>
> The correct condition is per rail, not per surface. Let `R` be a rail, `W` its
> forward chain, `cond(W)` the non-`R` SSA operands `W` reads, and `C` a record of
> `R` on a kept carrier. Freeing `R` is Rule-6-legal iff `R` starts at `|0⟩`,
> `W(|0⟩_R ⊗ |c⟩) = |g(c)⟩_R ⊗ |c⟩` on the reachable subspace (a basis permutation
> of `cond(W)` up to a label-diagonal phase), the emitted reversal is `W†`, and
> every register in `cond(W)` still holds its forward value when `W†` fires
> (reverse program order already gives the last one). Then `W† C W` returns `R` to
> `|0⟩` for **arbitrarily many** kept records — which is why a *derived* rail
> still uncomputes and frees.
>
> **Clause (d) is the delicate one.** "Forward value" means the value the register
> held *when the forward gate ran*, not its value at the end of the forward stream.
> Reverse program order supplies (d) for free — but only because the reversal
> adjoints **every** recovered gate, frozen rails included. The freeze therefore
> suppresses the **`cqrt_free`, never an adjoint**: a frozen rail is still fully
> reverse-played, and only its free is dropped. The first implementation of this
> ruling skipped frozen rails' adjoints as well, and the Rule-13 round measured
> **four** independent hidden measurements from it (a surviving reader's `_unc`
> recomputing from a rail that a skipped rotation had moved), two of them on the
> QRAM surface via `cqrt_qram_load_unc`'s index slot. Pinned by
> `ir-pass/test/lowering_io_tape_{interleaved_rotation,qram_borrowed_index}.ll`.
>
> **Decisive corollary:** `cond(W) = ∅` ⇒ `R` is freeable only if `W` is trivial on
> `|0⟩`. `cqrt_ry_<W>(H, θ)` has an empty condition set (its only other operand is
> a **classical** angle, Rule 3) and is *not* trivial on `|0⟩` — it is the gate
> that creates the superposition. So a recorded Ry rail freezes: **no
> `cqrt_free`**, left allocated (Rule 6's stated fallback, not a decline) — while
> still being reverse-played like any other rail.
>
> Decided in `DagTraversal` step 3b (`preservesBasisUnderRecord` +
> `recordsIntoKeptCarrier`, backward-closed over the DAG ancestor edges), executed
> in `Uncomputation::emitDagReversal` via `DataDag::FrozenRails`. Pinned by
> `ir-pass/test/lowering_io_tape_*.ll` (eleven fixtures: the four shipped tape
> shapes plus `chained_theta`, `frozen_two_writes`, `controlled_ctrl_slot`,
> `partial_freeze_order`, `interleaved_rotation`, `qq_both_parents`,
> `rz_preserving`, `qram_borrowed_index`) and the three
> `lowering_reject_uncompute_*_taped.ll` mechanism negatives.
>
> **Honesty bound:** the observable damage was NIL. The free is local to `src`, so
> it cannot change the kept tape's reduced density matrix (no-signalling) — the
> copy had already mixed it. What was wrong is a violated hard invariant carrying a
> provably false written justification inside a freeze-gating ABI. Do not quote
> this as "`slice_io` printed the wrong answer."

### 2.5 Output rails are kept via a **dedicated `OutputRails` set** (owner decision 1), subtracted at **both** spine sites
"Escaped" is recomputed every uncompute run in **two** independent places —
`FreePoint` (terminal handles, `isRecognizedEscapeUser`, `FreePoint.cpp:68-77`)
and `DagTraversal` (intermediate rails, `recoverDataDag`,
`DagTraversal.cpp:121-132`). **Decision: a dedicated `TaintSet::OutputRails`
`SmallPtrSet<Value*,8>`** (sibling of `ControlOwnedRails`, `TaintPropagation.h:144`
— *not* reusing it; semantic clarity, cheap), into which the emitter registers
each `out_handle`. It is subtracted at the **same two spine sites** the proven
`ControlOwnedRails` image already uses — terminal selection
(`Uncomputation.cpp:175-176`) and the DAG closure scan
(`DagTraversal.cpp:107-110`). The `cqrt_tape_write_` symbol is **also** added to
the spine's sink/non-reversible recognition (mirroring how `cqrt_measure_` is
recognized as a sink) so the write itself is never recovered as a reversible gate.
The **tape handle** from `cqrt_tape_alloc` is a classical resource token — not
tainted, not a rail — so the spine never touches it. **Do not rely on the closure
scan incidentally catching the rail** (`DagTraversal.cpp:104-106` warns the
explicit image is load-bearing). Registering at only one of the two sites is the
silent output-collapse hazard (§6.1).

### 2.6 **Integer scalars only**; width read pre-RAUW, gated on `widthHasReversibleCopy`
Width comes from `abiWidthFromType` (`OpcodeSupport.cpp:155-178`) read at **emit
time** (the `SelectMergeEmit.cpp:99` precedent — before `lowerRotations` launders
to `i32`), and tape-write availability is gated on **`widthHasReversibleCopy`**
(`OpcodeSupport.cpp:180-187`, true only for integer widths `i1..i64`) — **never**
on the `abiWidthFromType`-non-empty check (an `i128` scalar passes non-empty but
has **no** `cqrt_tape_write_i128`; an unguarded mint phantom-creates a symbol that
verify-clean **link-fails**). Per `bd memories reversible-output-tape-io`: **fp
`%f`/`double` args are OUT** (fp-data in a rail is the f64/angle silent-miscompile
family — test `isFPOrFPVectorTy()`, not scalar-only `isFloatingPointTy`); **`%s`
/ pointer args are OUT** (decline upstream at the `kMsgStore` store-guard;
coherent string output is 7.5, §1).

### 2.7 `abort`/`exit` is **NOT** 7.6 — it is the 7.2 park cascade; 7.6 supplies the truncation hook
Per `bd memories abort-exit-park-cascade`: a noreturn sink (`abort`/`exit`/
`__assert_fail`/`llvm.trap`) under tainted control joins the Phase-7.2/7.4
**exit-priority park cascade** (mint the abort flag, `cqrt_cswap` live regs into a
graveyard, let downstream run uncontrolled, **truncate the tape at inspection**).
**Gate-the-tape (a controlled `cqrt_tape_write`) is reserved strictly for the
non-terminating conditional-output Tier-0 case** (`if(q)printf`, §2.1). 7.6's
obligation toward 7.2 is satisfied **for free** by the tape-handle model:
truncation is an **inspection-time** operation — the backend records the abort
flag and knows the tape's (classical, static) length at the abort site, so it
truncates tape `T` to that length at inspection. **No per-write index, no
`cqrt_tape_truncate` runtime symbol** is needed.

### 2.8 The explicit tape ABI (NEW frozen `cqrt_*` core symbols)
Hand-written core ABI added to `runtime/cq_runtime.{h,c}` (trace-only bodies),
frozen at Phase 11:

- `int32_t cqrt_tape_alloc(void);` — register a tape; the backend allocates the
  physical tape and returns its handle (a classical resource token).
  **Width-agnostic — one symbol** (a tape holds mixed-width entries, e.g.
  `printf("%d%c")`).
- `int32_t cqrt_tape_write_<W>(int32_t tape, int32_t src);` — **append** `src` to
  `tape` as a fresh `|0⟩` output rail (CNOT-class copy, `src` preserved); the
  backend advances the cursor and returns the new kept `out_handle`.
- `int32_t cqrt_tape_write_<W>_controlled(int32_t ctrl, int32_t tape, int32_t src);`
  — Tier-0 conditional output (`if(q)printf`); the appended entry's content is
  committed under `ctrl` (`ctrl` is arg-0, matching `cqrt_copy_<W>_controlled`).
  The entry is **always** appended (deterministic length); only its content is
  conditional.
- **Write widths `W ∈ {i1, i8, i16, i32, i64}`** (the `widthHasReversibleCopy`
  set; realistic `printf`/`putchar` args are `i32` after varargs promotion, but
  the family is uniform with the copy family). No fp, no `i128`.
- **Trace format** (the golden contract): `cqrt_tape_alloc() -> tN`,
  `cqrt_tape_write_i32(tN, src) -> out`, and
  `cqrt_tape_write_i32_controlled(ctrl, tN, src) -> out`.

This family lets the **backend** own tape allocation, the append cursor, the
output-qubit **count** (= number of `cqrt_tape_write` entries on a tape), tape
**inspection**, and the 7.2 **truncation** hook — with the IR pass declaring only
*which tape* + *the value*. The write is **distinct** from `cqrt_copy_<W>` so the
backend can always tell an output qubit from a scratch copy, and so the uncompute
spine never reverses it (§2.4). The tape handle generalizes the write across tapes
(stdout / stderr / future reversible logs) without an ABI break.

### 2.9 Trace-only posture unchanged
The runtime stays trace-only (owner decision 2026-06-10). The "tape" in v1 **is**
the ordered sequence of `cqrt_tape_write_<W>` trace lines on a tape handle; the
format string + literal text stay **classical** (a documentation/inspection
concept, not a simulated runtime feature). No simulation, no measurement.

---

## 3. Deliverables

1. **Frozen ABI** (`runtime/cq_runtime.{h,c}`, hand-written): `cqrt_tape_alloc`
   (width-agnostic) + the `cqrt_tape_write_<W>` + `cqrt_tape_write_<W>_controlled`
   families for `W ∈ {i1,i8,i16,i32,i64}`, trace-only bodies, trace format per
   §2.8. Write/controlled callees minted lazily in the pass via a
   `WidthDispatch`/`ControlledSymbols`-style helper (mirror `copyFn`/
   `copyControlledFn`); `cqrt_tape_alloc` minted once.
2. **Carve-out** of `{printf,putchar}` from `declineTaintEscapes` by exact name,
   mirrored into the `runOnFunction` shim. Lands **together** with the emitter
   (Rule 12/13 — a carve-out without an emitter is the opaque-call silent
   miscompile).
3. **`lowerIOSinks` emitter** (new module in `ir-pass/src/`, `cq` namespace),
   wired into `CQLoweringPass::run` before `lowerRotations`: a `stream → tape`
   registry that emits one lazy `cqrt_tape_alloc`; per recognized sink, emit one
   `cqrt_tape_write_<W>(tape, src)` per tainted integer-scalar arg, erase the
   original call, register each `out_handle` in `OutputRails`. Reuse
   `abiWidthFromType` + `widthHasReversibleCopy` and the `materializeCopySource`
   pattern (`SelectMergeEmit.cpp:66-75`).
4. **`OutputRails` set** (`TaintPropagation.h`) + its subtraction at both spine
   sites (`Uncomputation.cpp:175-176`, `DagTraversal.cpp:107-110`) + the
   `cqrt_tape_write_` sink recognition; a probe asserting the rail survives
   uncompute (no `cqrt_free`, no adjoint, not selected as a terminal).
5. **Decline fixtures** (Rule 12, mirrored char-for-char): fp arg (`%f`/`double`),
   string/pointer arg (`%s`, via `kMsgStore`), `i128`/non-copy-width scalar arg,
   `invoke`'d I/O, a tainted `printf` **result** feeding back into taint, and a
   look-alike callee (`printf_helper`) proving exact-name discipline.
6. **Positive lit fixtures** (two RUN lines incl. `-passes=verify`, CHECK +
   CHECK-NOT pins per `lowering_freeze_passthrough_i32.ll`): `printf("%d",x)`,
   `putchar(x)`, derived `putchar(x+1)`, and a **multi-emit** fixture proving a
   *tape* (one `cqrt_tape_alloc`, multiple `cqrt_tape_write` appends, distinct
   `out_handle`s) not an accumulator. `CHECK-NOT: @printf` surviving;
   `CHECK: cqrt_tape_write_`.
7. **(Increment B) Controlled `if(q)printf`** → one `cqrt_tape_write_<W>_controlled`
   (Tier 0), reusing the 4.4/6.5 controlled-XOR-copy mechanics; handles **both**
   branch polarities (gate arm is TRUE for `sgt`, FALSE for the `clang -O1`-
   canonicalized `!=` shape — read the actual successor edges; Rule 9).
8. **≥1 e2e golden smoke** (Rule 16; `tests/e2e/run_slice.sh` + a new
   `add_test(NAME e2e-slice-io …)` block in `tests/e2e/CMakeLists.txt` — **cmake
   re-configure required**, e2e does not auto-discover): a program emitting tainted
   `printf`/`putchar` lowers to `cqrt_tape_alloc` + `cqrt_tape_write` lines, **no
   measurement**, `opt -verify` clean, golden trace diff clean.

---

## 4. Done criteria

- Programs emitting tainted `printf`/`putchar` **integer-scalar** output lower to
  `cqrt_tape_alloc` + `cqrt_tape_write_<W>` append sequences — **zero measurement
  gates**, `opt -verify` clean, golden e2e trace diffs clean, output rails left
  **kept** (never freed, never reversed, never selected as terminals) through the
  whole-DAG uncompute pass.
- Every off-pattern shape declines **loudly** with a source-located diagnostic:
  fp (`%f`) arg, string/pointer (`%s`) arg, `i128`/non-`widthHasReversibleCopy`
  scalar, `invoke`'d I/O, a tainted `printf` result re-entering taint, a look-alike
  callee, and any `abort`/`exit` under tainted control (that path belongs to 7.2).
- `gen_templates.py --check` SHA-256 drift clean (the new symbols are hand-written
  `cqrt_*`, **not** YAML — confirm the drift check stays green and the new core
  symbols are declared in `cq_runtime.h` with matching `.c` bodies).
- Each lit accept-predicate has a mirrored negative `RUN: not … | FileCheck`
  (Rule 12), diagnostic matched character-for-character.
- **The tape lowering is cleared by independent adversarial Rule-13 review** — a
  green suite alone does not clear it — covering **both** the new **frozen
  `cqrt_tape_alloc` / `cqrt_tape_write_<W>` signatures** (a wrong frozen ABI is
  permanent) **and** the escape/uncompute-spine edits (the verify-clean
  output-collapse / non-append hazards of §6).

---

## 5. Out of scope (declines, or other phases)

- **`puts` / `printf("%s")` / string output** — a reversible-memory problem owned
  by **Phase 7.5** (Shadow `store`); declines today at `kMsgStore`. Not 7.6.
- **`abort`/`exit`/noreturn sinks under tainted control** — the Phase-7.2 park
  cascade; 7.6's tape-length + inspection-time truncation is the hook it reads.
- **Dynamic tape growth** for unbounded loops (fixed, classical tape length from
  the static site count in v1; dynamic growth is post-freeze).
- **fp I/O args** — permanent decline (angle family).
- **I/O surfaces other than `printf`/`putchar`** (`fprintf`, `snprintf`, `write`,
  `<iostream>`, …) — not curated; they keep declining. (The tape **handle** is the
  seam that lets `fprintf`/multi-stream land later with no ABI break.)
- **Tape inspection / format-string replay / physical qubit numbering / multiple
  live tapes** — backend concerns; v1 emits one stdout tape and records it as
  `cqrt_tape_*` trace lines, no simulation.
- **Controlled-I/O beyond the single-sink Tier-0 `if(q)printf`** — deeper or
  non-homogeneous control nests around an I/O sink decline loudly.
- All other 7.x items: controlled `return`/`abort`-`exit` (7.2), bounded loops
  (7.3), `break` (7.4), QRAM (7.5).

---

## 6. Risks (the verify-clean ones first)

1. **Output-rail collapse / mis-free by the uncompute spine** — the central
   Rule-13 hazard. The kept rail must be skipped at **both** spine sites (§2.5)
   and `cqrt_tape_write_` must be recognized as sink-class (never recovered as a
   reversible gate). Missing the `DagTraversal` site (the intermediate-rail case)
   is the easy-to-miss silent collapse. Mitigation: the dedicated `OutputRails`
   image subtracted at both sites + sink recognition + an adversarial probe that
   the rail and write survive uncompute untouched. (The explicit symbol already
   removes the double-XOR re-emit hazard, §2.4.)
2. **Lost transcript** — writing to the wrong tape, or overwriting rather than
   appending, loses the record (verify-clean wrong output). Mitigation: a single
   lazy `cqrt_tape_alloc` per stream + append-only `cqrt_tape_write`; a multi-emit
   fixture asserting one `tape_alloc` and distinct `out_handle`s.
3. **Source-lineage interaction** — the tape write reads the tainted scalar `src`;
   `src`'s own lineage must still uncompute normally **without** the write being
   pulled into `src`'s reversal DAG. Fan-out (`src` consumed by the write **and**
   elsewhere) must respect the Rule-8 linear-lineage bail. Mitigation: analytic
   trace of the write/source split + a fan-out decline fixture.
4. **Permanent frozen-surface error** — `cqrt_tape_alloc` + `cqrt_tape_write_<W>`
   (and its controlled twin) freeze at Phase 11. A wrong signature (arg order,
   width set, append vs index semantics, the tape-handle type) or a missing width
   is a permanent v1 ABI defect. Mitigation: the §4 Rule-13 gate on the
   signatures; mirror the proven `cqrt_copy_<W>` / `cqrt_copy_<W>_controlled` arg
   conventions exactly (ctrl arg-0).
5. **Carve-out without emitter** — suppressing the decline but not lowering the
   `printf` leaves it reading the `i32` runtime handle after `lowerRotations`
   (the `lowering_reject_taint_escape_opaque_call.ll` hazard). Mitigation:
   carve-out + emitter in the **same** increment (Rule 12).
6. **`starts_with` over-accept** — a user `printf`-ish function slipping through.
   Mitigation: exact-name membership over `{printf,putchar}` (§2.2) + the
   look-alike-callee negative fixture.
7. **fp laundering** — a tainted `double` reaching a rail is the angle miscompile
   family. Mitigation: `isFPOrFPVectorTy()` decline (not scalar-only
   `isFloatingPointTy`).
8. **Phase-vs-basis (Rule 7)** — confirm analytically that a tainted `i32`
   `printf` arg is always **basis-encoded data** (CNOT-copy correct), never an
   in-place **phase** answer (CNOT copies a basis label, not a phase, and would
   dephase). The integer-scalar-only scope (§2.6) is the structural guard; the
   Rule-13 clearance states the argument explicitly.

---

## 7. Increments (each red → green → clear, Rule 12/13)

1. **Uncontrolled tape write** — the frozen ABI (deliverable 1) + carve-out
   (§2.2) + `lowerIOSinks` emitter with the stream→tape registry (§2.3, §2.4) +
   `OutputRails` keep-logic (§2.5) + the §2.6 integer-only width gate + decline
   fixtures (deliverable 5) + positive/multi-emit fixtures (deliverable 6) + the
   e2e golden smoke (deliverable 8). **Frozen-ABI + core escape/uncompute-spine
   change → independent adversarial Rule-13 clearance before commit** (the
   signatures + the §6.1–6.3 hazards).
2. **Controlled `if(q)printf` (Tier 0)** — `cqrt_tape_write_<W>_controlled`
   reusing the 4.4/6.5 controlled-copy mechanics, both branch polarities
   (deliverable 7) + its own positive + decline (deeper-nest) fixtures.
   **Rule-13 clearance** for the control-composition edge.

> Both increments must land **before the Phase-11 freeze** (frozen ABI) and each
> must clear independent adversarial review before commit.
