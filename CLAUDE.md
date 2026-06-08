# CQ_lang — Taint-Driven Quantum-C Compiler: Directives for AI Agents

CQ is a small extension of C for writing quantum programs. There is no
`quantum` keyword and no special type: a value becomes quantum by passing
through a `cq_*` primitive, and an out-of-tree **LLVM 19** pass propagates that
**taint** forward through stock C arithmetic, control flow, and calls — lowering
tainted opcodes to reversible runtime-template calls. **No LLVM fork, no MLIR
dialect, no AST rewriter, no custom parser, no `quantum` keyword.** Stock
`clang -O1` compiles the source; one `opt` pass (`cq-lowering`) does all the
work; the program links against the trace runtime and runs.

You are working on a **quantum reversible compiler**. The defining hazard of
this codebase is the **verify-clean silent miscompile**: a lowering that passes
`opt -verify` — and even prints a plausible trace — yet computes the wrong
unitary, drops a `phi` edge, fires a gate on the wrong branch, or collapses a
qubit by freeing an entangled rail. Everything below exists to prevent that one
class of bug.

> **Authoritative status lives in [`ROADMAP.md`](ROADMAP.md), not here.** This
> file is the *operating manual*; the ROADMAP is the *plan of record* (Phases
> 0–10 + the 10 cross-cutting design principles). **Current focus: Phase 4 —
> RSSA swap-routed tainted control flow**; clean-slate `4.0` is done, the
> swap-route emitter is in progress on branch `swap-route-control`. Read
> `ROADMAP.md` and `docs/design/rssa-swap-control/` *before* touching control
> flow. Phases 0–3 are done; 5–10 are not started.

---

## The Prime Directive — when in doubt, DECLINE

`opt -verify` clean proves the IR is **well-typed**, never that the **unitary is
correct**. Correctness here is established by statevector/trace reasoning and
golden end-to-end diffs — *not* by the verifier.

**Over-declining is always safe. Over-accepting is a silent miscompile.** When
any detection or lowering precondition is ambiguous, unproven, or off-pattern,
emit the loud `DiagnosticInfoUnsupported` (`"… under quantum control"`, `opt`
exits non-zero) and **lower nothing**. A loud reject is a feature; a silently
wrong answer is the only unforgivable bug. The bd-memory history records this
exact class hit a dozen-plus times (diamond, gated-switch, jumptable, MUX-EXCH,
angle paths) — every time caught by adversarial reasoning or e2e diff, *never*
by `opt -verify`.

---

## Non-Negotiable Rules

**Rule 0 — Institutional memory.** Durable, hard-won knowledge goes in
`bd remember` (26 memories already encode the silent-miscompile history — read
them: `bd memories <keyword>`). Design-of-record goes in `docs/` and per-phase
PRDs (`docs/prd/phase-NN-*/`). Do **not** use TodoWrite, markdown TODOs, or
`MEMORY.md`. Every gotcha, LLVM-19 quirk, and silent-miscompile root cause must
be written down — future agents (and you, after compaction) depend on it.

**Rule 1 — Fail loud, decline safe.** Use the loud diagnostic and lower nothing
when unsure (see Prime Directive). Diagnostics carry the offending instruction's
`!dbg` so they are source-located and `opt` exits non-zero. A tainted
`br` / `select` / `switch` is **never** silently passed to the backend as
classical control over quantum state — `ControlStub.cpp` exists precisely to
hold that invariant during the swap-route rebuild.

**Rule 2 — Verify-clean is necessary, never sufficient.** Establish correctness
by statevector reasoning (`docs/design/rssa-swap-control/prototype_semantics.py`
is the one-off oracle — not in the build) **plus** golden e2e trace diff (the
only layer that links and proves every emitted symbol resolves and
signature-matches). "Passes `opt -verify`" and "runs without crashing" are not
evidence.

**Rule 3 — Taint is the only Q/C boundary.** A value is quantum iff it is
(transitively, via stock LLVM data flow) derived from a `@cq_theta_*` result.
`cq_theta` (Ry) is the **sole** taint source; `cq_measure` the **sole** sink;
`cq_phi` (Rz) propagates taint but never introduces it (deleted on classical
operands). The **arg-1 angle** operand of a rotation is classical — never
propagate taint through it, and the exclusion is **per-operand-use, not
global** (a value also used as an arg-0 handle stays tainted). Never allocate a
qubit for an angle or coerce it to an `i32` handle — that is the f64/angle
miscompile family.

**Rule 4 — No fork, no rewriter, no new intrinsics.** Stock LLVM 19, out-of-tree
MODULE plugin. The frontend is `CQ.h` only. There are **no** quantum arithmetic
intrinsics (`cq_add_qq`, …) — stock LLVM opcodes on tainted operands are lowered
to templates. The retired `quantum`-keyword / cast-as-measurement /
libtooling-transpiler design lives in `archive/` and `docs/archive/old-design/`
— **reference only; never revive** (see Key Prohibitions).

**Rule 5 — Coherent-first; never insert a measurement.** The compiler **never**
emits a measurement the user did not write (hard project invariant). There is
**no** measure-only / forward-only mode (struck 2026-06-08) — it silently
corrupts under downstream interference (Grover/QPE). Region-local **reverse-play**
uncompute (the adjoint of the forward stream, via `EmitInverse`) is **mandatory
in every increment**, never deferred.

**Rule 6 — Reverse-play before free.** `cqrt_free` is **compiler-emitted only**
and is a hardware reset = projective measurement. Emit it on a rail **only after**
reverse-play has returned it to `|0⟩`. Never free a handle that **Escaped**
(`ret` / `cq_invert_*`) or is **Measured** — the caller / the measurement owns
it. Route every free through the `FreePoint` post-dominator discipline; a
post-measure gate, a loop-backedge live range, or an unrecognized user is a
**loud reject**, never a silent skip.

**Rule 7 — Method matches arm class.** Rotation arms (Rz / Ry) keep the answer
**in place on `q`** and clean only the work rail with a controlled-adjoint
(**method-A**). Classical-permutation arms (`add`/`mul`/`x`/`toffoli`) use
compute → copy-out → reverse-play (**method-B**, `cqrt_copy_<W>`). **Never apply
method-B to a rotation arm** — a CNOT copies a basis *label*, not a *phase*, so
`R†` cancels the very superposition that was the answer (verified P0
0.585 → 0.500, fully dephased).

**Rule 8 — No-cloning / linearity.** Copy + uncompute cannot disentangle a
superposition. Freeing a source that carries superposition requires
controlled-SWAP (`cqrt_cswap` / Fredkin), not copy + uncompute. Whole-chain
reversal requires **linear lineage** — bail on fan-out (>1 forward consumer on a
non-terminal handle) or you double-uncompute the shared prefix (use-after-free +
double-free). Only Rz (phase) and Ry (superposition) create quantum coherence;
`x`/`toffoli`/`cswap` are permutations — but a permutation that leaves a rail
dirty **and entangled** still dephases under later interference.

**Rule 9 — Stock LLVM IR is not stable; `-O1` is the validated floor.** Never
assume formatting, instruction order, naming, or branch polarity. `clang -O1`
canonicalizes (`if(u!=k)` → `icmp eq; br eq, Merge, Arm`), swapping successors
and value-propagating the straight-through edge to a constant — so the gate arm
is often the **false** successor and a gate-body phi must RAUW to the **tainted**
incoming, not the Pred edge. Detection is **pure analysis by SSA-value identity,
before any mutation** (so it survives rotation lowering's RAUW-to-handle; never
cache block pointers across erasures). `mem2reg`/SROA must have run (`-O0`
unsupported); `-O2`/`-O3` break taint signatures, post-dominators, and handle
identity (regression-matrix only).

**Rule 10 — All bugs are deep and interlocked.** Never assume a shallow bug.
Investigate root cause fully; a fix that passes one test but violates an
invariant elsewhere is not a fix. Off-by-one and "it works now" are suspect.
Nearly every silent miscompile in the history (f64 φ, gated-switch mixed/distinct
φ, MUX-EXCH G3b stray rotation, jumptable over-match, nested-merge UAF) was found
by a deliberate **adversarial probe family**, not by the positive suite.

**Rule 11 — Skepticism.** Verify everything — subagent output, prior sessions
(against `git log`), and **bd memories** (they reflect what was true *when
written*; a named file/flag may be gone — e.g. `ControlDetection.cpp` and
`MergeDissolution.cpp` were **excised** in `7cde677`). Extract and read the
actual lowered IR before implementing; do not guess LLVM patterns.

**Rule 12 — Every accept-predicate ships with a decline fixture + adversarial
probe.** Red-green: write the lit fixture first (positive `CHECK` **plus** a
negative `RUN: not … | FileCheck` that mirrors the diagnostic string
character-for-character), watch it fail, implement minimally. A new shape-matcher
without a probe family is incomplete. `ir-pass-lit` and the e2e goldens are
regression baselines — keep them green; regenerate baselines deliberately, never
by reflex.

**Rule 13 — Core lowering changes get adversarial verification, not just green
tests.** Changes to the lowering core (`TaintPropagation`, the swap-route /
control emitter, `FreePoint`, `EmitInverse`, `ChainWalk`, `Uncomputation`,
`RotationLowering`) are where the silent miscompiles live. Before committing,
clear the change against statevector/trace reasoning (or an independent second
reviewer/agent). A green suite alone does **not** clear a core change.

**Rule 14 — Reuse before reinvention; no duplicated lowering.** Check existing
handlers (`OpcodeSupport` / `ArithLowering` / `CompareLowering` / `CastLowering`,
the `EmitInverse` adjoint spine, the Phase-5 uncompute spine
`ChainWalk`/`FreePoint`/`Uncomputation`, and the `cqrt_cswap`/`cqrt_toffoli`
primitives) before adding a new one. The swap-route rebuild **reuses**
`emit_inverse` for reverse-play and `FreePoint` for rail cleanup — extend, do
not fork.

**Rule 15 — Width-only ABI; edit the YAML, never the generated files.** The
runtime template surface is generated:
`tools/opcode_table.yaml` → `tools/gen_templates.py` → `runtime/cq_templates.{h,c}`.
Edit the YAML and regenerate; the SHA-256 drift check (`gen_templates.py
--check`) gates it. Signedness lives in the opcode (`add nsw` vs `nuw`,
`icmp slt` vs `ult`); the IR pass strips it — a runtime handle is **always
`i32`** regardless of width.

**Rule 16 — Phase discipline.** Each phase carries a PRD written at its start,
not in advance. Don't implement out-of-scope features or skip a phase's
done-criteria (both lit fixtures **and** ≥1 e2e golden smoke). The bd tracker
spans **two design generations** — closed old AST-frontend / transpiler issues
do **not** indicate new-design progress.

---

## Pipeline Architecture

```
 plain C + CQ.h
      │  clang -O1   (stock; no CQ parser — intrinsics survive as @cq_* calls on plain SSA)
      ▼
 LLVM 19 IR ──► opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering
      │            │
      │            ├─ propagate()        forward taint  (@cq_theta = source · @cq_measure = sink)
      │            ├─ detectControl()    tainted br/select/switch → LOUD DECLINE (swap-route stub)
      │            ├─ lowerRotations()   theta → cqrt_alloc_<W> + cqrt_ry_<W> ; phi → cqrt_rz_<W>
      │            ├─ lowerOps()         tainted add/mul/icmp/cast → cq_template_*[_hl|_lh]
      │            ├─ lowerMeasures()    cq_measure → cqrt_measure_<W>
      │            └─ uncompute()        per-op adjoint at SSA last-use + cqrt_free   (runs LAST)
      ▼
 lowered IR  (only cqrt_* and cq_template_* externs — all cq_* intrinsics gone)
      │  clang + link   (libcq_templates.a BEFORE libcq_runtime.a — load-bearing order)
      ▼
 executable → prints one trace line per gate → byte-diff vs golden .expected.log
```

Orchestrated by `CQLoweringPass::run` (`ir-pass/src/CQLoweringPass.cpp`); a
module with no theta/phi/measure is left **byte-identical** (passthrough).
Runtime is **trace-only** (each `cqrt_*` / `cq_template_*` prints
`symbol(args) -> ret`; `measure` returns 0; no simulation) — the golden trace is
the contract.

---

## CORRECTNESS RISK — Tainted control flow (the live work, the deepest hazard)

Tainted `br` / `select` / `switch` is the construct that has produced every
verify-clean silent miscompile in this project's history. The **old controlled-op
lowering** (mint a flag → substitute each arm gate with a `_controlled` template
→ dissolve the φ → uncompute the flag → linearize the CFG) shipped and was then
**removed wholesale** (`7cde677`) so the new **RSSA swap-route** design is built
without it shaping the implementation. Today `detectControlRegions`
(`ControlStub.cpp`) only **loudly declines** any tainted condition and returns an
empty plan; the real emitter is being built. The enduring lessons — restructured,
**not deleted** — that any control work must respect:

- **RSSA φ appear on BOTH splits and joins.** The merge is the **adjoint of the
  branch**, sharing the **same live condition**: `br` routes the operand *in*
  (`cqrt_cswap` into a work rail), `phi` routes the active result *back*
  (`cqrt_cswap`). The join is literally the inverse of the split.
- **RSSA proves *classical* reversibility only.** Mogensen RSSA does **not** hand
  you quantum-coherence correctness. The superposed-control / no-cloning /
  Rz·Ry / reverse-play layer is the **original** part of this design, validated
  by statevector simulation — never "it's RSSA, therefore correct" (SCOPING §0).
- **Method-A vs method-B is by arm class, not convenience** (Rule 7). Bennett
  compute→copy→uncompute is the *special* case (basis-valued arms), not the
  general one; it **dephases** rotation answers.
- **Branch polarity is inverted by `clang -O1`** (Rule 9): the gate arm is often
  the *false* successor; control on `¬flag` via a self-inverse `cqrt_x` bracket,
  and dissolve a gate-body φ to the **tainted** incoming, not the Pred edge.
- **An unlowerable merge φ must DECLINE, never dangle.** Integer merge φ is a
  real **data mux**; floating-point merge φ is a rotation **angle** — do not
  cross these wires. Test FP-ness with `isFPOrFPVectorTy()` (scalar-only
  `isFloatingPointTy()` misses `<2 x double>`); never key data-mux lowering on
  `abiWidthFromType()` non-empty (f64 has a valid width yet is an angle — that
  was the f64 silent miscompile). A φ the reduction skips dangles into a broken
  module.
- **Free only a proven-`|0⟩` rail** (Rule 6) and **never free a source carrying
  superposition by copy+uncompute** — that needs `cqrt_cswap` (Rule 8).
- **Block lifetime under sequential lowering:** linearization erases merge
  blocks; a region whose predecessor is another region's merge block dereferences
  freed memory (SIGSEGV on valid input). Capture identities before the first
  erase, or decline while blocks are still valid. Do **not** blanket-decline
  every shared merge — the legitimate nested-AND `if(a){if(b)}` is a coordinated
  pair that shares its merge and lowers correctly.

When you cannot *prove* the shape, **decline loudly** (Prime Directive).

---

## Hallucination-Risk Callouts (specific things agents get wrong)

- **`ControlDetection.cpp` / `MergeDissolution.cpp` no longer exist.** They were
  excised (`7cde677`, branch `swap-route-control`). The live tree has
  `ControlStub.cpp` (loud-decline only) and `ControlPlan.h` (struct kept; rich
  fields **unpopulated** — only `InShadow` is read, and it's empty). The old
  logic is recoverable from git history but is **not** the path forward.
- **Phase 4 is *not* done.** The controlled-op Phase 4 shipped and was **removed
  wholesale**; the current Phase 4 is the swap-route rebuild — `4.0` clean-slate
  done, emitter (`4.1`+) in progress. Old ROADMAP/issue references to a "finished"
  controlled-form Phase 4 describe the deleted generation.
- **Casts are representation changes, NEVER measurements.** The only path to a
  measurement gate is an explicit `cq_measure(...)`. There is no flag/syntax to
  turn a cast into a measurement (this asymmetry is by design; it's what lets
  plain C functions with hidden internal casts lift to quantum callers).
- **`cqrt_free` is compiler-emitted only**, and freeing an entangled rail is a
  **hidden measurement** that collapses `q` (Rule 6) — not a benign lifetime op.
- **A floating-point merge φ is an angle, not data** (see Correctness Risk).
- **"No new primitive" holds only for keep-sources-live additive copy.** Freeing
  a superposed source needs `cqrt_cswap` (Rule 8).

---

## Build & Test

LLVM 19 is **mandatory** (CMake `FATAL_ERROR`s otherwise). On this machine
`opt` / `clang` / `FileCheck` are **not on `PATH`** — they live only in
`/usr/local/opt/llvm@19/bin` (the lit/ctest harnesses bake absolute paths in, so
they work; by-hand `opt`/`clang` need the absolute path). Only `lit` is on
`PATH`.

```bash
# Configure (one-time; LLVM_DIR must be passed explicitly — it is not auto-discovered)
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release

# Build everything (the cq-lowering plugin + runtime archives + test exes)
cmake --build build -j8
cmake --build build --target CQPass        # just the pass → build/ir-pass/libCQPass.so

# Full suite (7 ctest entries; ~27s, expect 100% pass)
cmake --build build && ctest --test-dir build --output-on-failure

# One layer at a time
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # 66 *.ll lowering/control/uncompute fixtures
ctest --test-dir build -R frontend-lit --output-on-failure   # CQ.h surface survives clang -O1 (no plugin)
ctest --test-dir build -R '^e2e-'      --output-on-failure   # 3 vertical slices — the only layer that LINKS
ctest --test-dir build -R runtime      --output-on-failure   # trace golden-diff + header compile

# One fixture (lit --filter matches the test display name)
cd build && lit -v ir-pass/test --filter 'lowering_basic'

# Run the pass on one .ll by hand (absolute tool path required)
/usr/local/opt/llvm@19/bin/opt -load-pass-plugin build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S ir-pass/test/lowering_basic.ll \
  | /usr/local/opt/llvm@19/bin/FileCheck ir-pass/test/lowering_basic.ll
```

**Full pipeline for one `.c`** (mirrors `tests/e2e/run_slice.sh`; `LLVM=/usr/local/opt/llvm@19/bin`):

```bash
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S file.c -o /tmp/s1.ll          # 1: frontend
"$LLVM/opt" -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
            -S /tmp/s1.ll -o /tmp/s2.ll                                               # 2: cq-lowering
"$LLVM/clang" /tmp/s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o /tmp/a  # 3: link*
/tmp/a                                                                                # 4: run → trace
```

\* **Link order is load-bearing:** `libcq_templates.a` **before** `libcq_runtime.a`
(template `_hl` symbols call `cqrt_*`; single-pass `ld` needs the caller first).

There is **no GitHub CI** (no `.github/` exists); all quality gates run locally
through `ctest` (LIT+FileCheck for ir-pass/frontend, shell+golden-diff for e2e)
plus `gen_templates.py --check` drift verification. Do not add CI.

---

## Conventions

- **C11 / C++17**, `CXX_EXTENSIONS OFF`. `-Wall -Wextra` propagated to every
  sub-build — deliberately **not** `-Werror`.
- The pass is a **MODULE** library (`libCQPass.so`, `.so` even on macOS) that
  **does not link LLVM** — symbols resolve from the host `opt`/`clang` at
  `dlopen` (`-undefined dynamic_lookup` on Apple). Loaded with the **new** PM
  `-load-pass-plugin`, never legacy `-load`. The pass name is exactly
  **`cq-lowering`**.
- Pass code is split **one width-parametric module per concern** in
  `ir-pass/src/`, each in the `cq` namespace; `Plugin.cpp` registers,
  `CQLoweringPass.cpp` orchestrates.
- **Two runtime symbol families:** `cqrt_*` = the hand-written core ABI (7
  allocators + 7 measure + `cqrt_free` + `ry`/`rz`/`x`/`cnot`/`toffoli`/`cswap`,
  plus controlled twins); `cq_template_*` = the **autogenerated** reversible-op
  bodies for stock opcodes. Naming grammar:
  `cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]`
  (HL = handle+literal, LH = literal+handle, QQ = both handles; `_inv` = adjoint
  twin). Handles are always `i32`; signedness stripped.
- **Diagnostics are loud and source-located** (`DiagnosticInfoUnsupported`,
  `DS_Error`, `!dbg` attached). Negative fixtures mirror the message
  character-for-character so code and test cannot drift.
- **Non-interactive shell flags always** (`cp -f`, `mv -f`, `rm -f`, `rm -rf`) —
  `cp`/`mv`/`rm` may be aliased to interactive `-i` and hang the agent
  (see `AGENTS.md`).

---

## Key Prohibitions

- **Do NOT revive the libtooling AST rewriter / transpiler.** It is archived
  (`archive/transpiler/`, `archive/tests/e2e/`); `find_package(Clang)` is gone.
  The frontend is a header lowered entirely in the IR pass — no AST pass, no
  parser, no rewriter.
- **Do NOT reintroduce the old `quantum`-keyword design or its surfaces** — the
  keyword/macro, `qint_mid_t` mid-structs, `cq_init_*` / `cq_alloc_*` families,
  `cq_when_begin/_end` brackets, the `MidHandleRebind` module, and
  **cast-as-measurement** are all eliminated.
- **Do NOT rebuild the excised controlled-op control path** (`ControlDetection`,
  `ControlFlag`, `ControlledLowering`, `ControlledSubstitution`,
  `FlagConjunction`, `CFGLinearization`, `MergeDissolution`,
  `SwitchNormalization`). The swap-route design replaces them. The `_controlled`
  template family is retained **only** as a reserve for the optional §6a
  control-in-place peephole — not as the control mechanism.
- **Do NOT add quantum arithmetic intrinsics** (`cq_add_qq`, …). Arithmetic is
  stock LLVM opcodes identified by taint.
- **Do NOT make `cq_phi` (Rz) a taint source** or allocate a qubit for it on a
  classical operand — only `cq_theta` allocates and creates taint.
- **Do NOT promote a classical operand to a qubit handle** in mixed Q+C ops —
  pass the literal through to the `_hl`/`_lh` template; never `cqrt_alloc` it
  (`quantum-classical-handling.md` §5.2, non-negotiable).
- **Do NOT insert any measurement the user did not write, and do NOT free a rail
  before reverse-play returns it to `|0⟩`** (Rules 5, 6).
- **Do NOT fork LLVM or add an MLIR dialect.** No-fork stock-LLVM-19 is locked
  for v1; MLIR re-evaluation is deferred to the Phase 10 freeze gate.
- **Do NOT add GitHub CI**, and **do NOT use TodoWrite / markdown TODOs /
  `MEMORY.md`** — use `bd` and `bd remember`.
- **Do NOT use `-O0`** (mem2reg/SROA must have run) and avoid `-O2`/`-O3` at
  Stage 1 outside the regression matrix (inlining pre-empts clone-on-taint,
  SimplifyCFG flattens post-dominators, GVN/SLP fuse handles).

---

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->

---

## Where Things Live

| Path | Responsibility |
|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | Orchestrator: `propagate → detectControl → lowerRotations → lowerOps → lowerMeasures → uncompute`; passthrough early-out |
| `ir-pass/src/TaintPropagation.cpp` | Forward taint: seed at `@cq_theta` results, propagate through users, stop at `@cq_measure`, skip the arg-1 angle |
| `ir-pass/src/RotationLowering.cpp` | `theta → cqrt_alloc_<W> + cqrt_ry_<W>` (qubit allocation point); `phi → cqrt_rz_<W>`; RAUW result to the `i32` handle |
| `ir-pass/src/OpcodeLowering.cpp` + `Arith/Compare/Cast` | Tainted `add/mul/icmp/fcmp/cast/fneg → cq_template_*`; up-front cast-width capture before RAUW |
| `ir-pass/src/OpcodeSupport.cpp` · `TemplateName.cpp` · `WidthDispatch.cpp` | Supported-set/commutativity/predicate policy · symbol-string grammar · suffix→width + lazy `FunctionCallee` minting |
| `ir-pass/src/MeasureLowering.cpp` | `@cq_measure_<sfx> → cqrt_measure_<W>` |
| `ir-pass/src/ControlStub.cpp` · `include/ControlPlan.h` | **Transitional** loud-decline for tainted control · region vocabulary (only `InShadow` read, empty) |
| `ir-pass/src/Uncomputation.cpp` · `ChainWalk.cpp` · `FreePoint.cpp` · `EmitInverse.cpp` | Per-op uncompute spine (runs last): terminal/chain recovery · post-dom free point · reversed adjoint + `cqrt_free` |
| `runtime/cq_runtime.{h,c}` | Hand-written `cqrt_*` core ABI (trace-only) |
| `runtime/cq_templates.{h,c}` | **Autogenerated** `cq_template_*` bodies — edit `tools/opcode_table.yaml`, not these |
| `include/CQ.h` | User-facing intrinsic surface (14 types × 3 families via `_Generic` + `cq_invert_*`) |

**Docs map:** `ROADMAP.md` (plan of record) · `docs/frontend.md` (intrinsic
surface) · `docs/backend.md` (IR pass + runtime ABI) ·
`docs/quantum-classical-handling.md` (taint as the Q/C boundary; mixed-operand
semantics) · `docs/design/rssa-swap-control/{OVERVIEW,SCOPING}.md` (the in-flight
control design + `prototype_semantics.py` oracle) · `docs/llvm-implementation.md`
(stock LLVM-19 C++ APIs) · `docs/prd/` (per-phase PRDs) ·
`docs/archive/old-design/` (retired design — reference only).
