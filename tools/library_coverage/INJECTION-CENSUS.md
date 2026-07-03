# Source-Injection Census — math.h via openlibm (opcode-lowering path)

> **Point-in-time findings, 2026-07-02** (this box: x86_64 darwin, Homebrew LLVM 19,
> real `cq-lowering` pass). This is a *different lowering strategy* from
> [`COVERAGE.md`](COVERAGE.md) and does **not** replace it — see "Two strategies" below.
> A naïve off-the-shelf-libm **baseline**, deliberately measured to learn requirements.

## What this measures

The [`COVERAGE.md`](COVERAGE.md) census measures the **template-recognition** strategy:
`cq-lowering` recognizes a `math.h` intrinsic/libcall by name and emits a *per-function
frozen reversible template* (`cq_template_<fn>`). This census measures the **opcode-lowering**
strategy instead: inject an existing libm's **source** so LLVM inlines it to stock **opcodes**
*before* `cq-lowering`, and let taint propagate through those opcodes — **no per-function
template, no hand-written quantum routine.**

Pipeline, per function (all pre-IR-pass except the last step):

```
clang -O1 -fno-builtin-<fn>   # the call becomes a NAMED @fn (not @llvm.<fn>)
llvm-link probe.bc openlibm-<fn>-closure.bc   # inject openlibm's real body + its kernels
opt internalize, always-inline, globaldce, O2 # decompose the body to opcodes
opt -passes=cq-lowering                        # <-- accept or loud-decline (measured here)
```

Source = **openlibm** (JuliaMath/openlibm), compiled to bitcode with the installed clang.
It is **not on the machine by default** (system libm is native machine code, uninlinable);
the census clones it to scratch. `alwaysinline` is forced on the openlibm bodies (mirrors how
a vendored soft-lib would be marked); dependency-closure linking pulls each function's kernels.

A function counts **COMPILES** only when its body is **fully inlined** (no surviving `@fn`
call) **and** `cq-lowering` exits zero. A surviving `@fn` call is *not* a compile (exit-zero
on an un-inlined call is meaningless — see "Over-accept" below).

## Headline result

**44 `math.h` double functions censused · 3 COMPILE · 41 decline — and not one decline is on a
missing opcode.**

| Outcome | Count | Functions |
|---|---:|---|
| ✅ **COMPILES** (straight-line bit-ops) | **3** | `fabs`, `nearbyint`, `copysign` |
| ❌ tainted **control flow** (nested range-reduction branches) | 23 | `asin acos atan sinh cosh tanh asinh acosh atanh expm1 log log1p logb cbrt floor trunc round ceil atan2 pow remainder fdim scalbn` |
| ❌ tainted **memory** (multi-word scratch buffers → Phase-7.5 Shadow) | 14 | `sin cos tan exp exp2 log2 log10 rint hypot fmod fmax fmin nextafter erf` |
| ❌ taint-escape / other | 2 | `sqrt`, `fma` (openlibm's software `fma` is a large multi-precision body) |
| ❌ not separately re-injected (harness link gap; polynomial+branch family) | 2 | `erfc`, `lgamma` |

`copysign` compiles for the `(quantum, classical)` mixture; the `(quantum, quantum)` mixture
surfaced the **only opcode-ish gap** in the whole census — a missing template for that shape.

## The requirement map (what we learn)

1. **Opcodes are not the blocker — they are essentially complete.** Every transcendental
   inlines to `fadd/fmul/fsub/fdiv/fcmp` + casts, all of which `cq-lowering` already lowers
   (the `opcode_table.yaml` fp-arith family, f16–f80). Zero declines were "no opcode." The
   opcode-lowering premise is **sound**.
2. **Blocker #1 — tainted control flow at scale (23 functions).** Off-the-shelf libm does
   argument range-reduction and special-casing with data-dependent branches (e.g. `sin`/`cos`
   carry 126+ branches). `cq-lowering` routes only specific diamond/switch shapes and declines
   the rest ("control flow under quantum control").
3. **Blocker #2 — tainted memory / Shadow (14 functions).** Multi-word range reduction writes
   the reduced value into a scratch `double[]` and reads it back — a tainted store→load that is
   Phase-7.5 QRAM/Shadow territory ("tainted value stored to memory").
4. **Consequence.** Injecting *off-the-shelf* libm is blocked almost entirely by control flow +
   scratch memory. Two ways forward, both compatible with the opcode-lowering premise:
   - build tainted-control-flow-at-scale + Shadow support (large core work), **or**
   - inject **branchless, register-only** implementations (the reason Bennett.jl's `soft_*` are
     branchless integer bodies — branchlessness, not integer-ness, is what keeps them lowerable;
     see the `math-source-injection-opcode-lowering` bd memory).
5. **Only pure straight-line bit-functions compile today** (`fabs`, `nearbyint`, `copysign`) —
   exactly the functions with no control flow and no scratch memory.

## Two strategies, one goal (not a replacement)

| | Template-recognition (`COVERAGE.md`) | Source-injection (this doc) |
|---|---|---|
| Mechanism | recognize `@llvm.<fn>` → emit `cq_template_<fn>` | inject libm source → inline to opcodes → taint |
| Per-fn frozen ABI symbol | yes (one per function) | **no** |
| Reversible backend for transcendentals | `open` (deferred) | free once it lowers (stock reversible opcodes) |
| Today's math.h reach | 165/174 lower | 3/44 compile (naïve openlibm baseline) |

## Caveats (honest)

- **Naïve baseline.** These numbers are *off-the-shelf openlibm*, which is branchy and
  memory-heavy by design. Branchless/register-only implementations would compile far more — the
  3/44 is the floor, not the ceiling of the injection approach.
- **Harness gaps.** `erf`/`erfc`/`lgamma`/`ceil` initially mis-reported as "no impl" due to a
  greedy dedup/link gap; re-injected individually, `ceil`→control-flow and `erf`→memory. `erfc`
  and `lgamma` were not separately re-injected (link closure gap) — they belong to the
  polynomial+branch family.
- **Potential over-accept (needs a fix, not part of the count).** A tainted value passed to an
  *undefined* `memory(none)` libm declare (e.g. `@erf` when its body is not linked) made
  `cq-lowering` **exit-0** instead of declining — it neither lowered nor loud-declined the
  tainted arg into an unknown pure callee. This looks like a silent-accept gap in the
  taint-escape guard for `memory(none)` externals and should be investigated independently of
  this census (Prime Directive).

## Re-measurement 2026-07-03 (post kjd1 + 9ymx fp-select/loop work) — NET ZERO movement

The fp-DATA select un-staging (kjd1) and in-loop select accept (9ymx) landed on
`injection-census` 2026-07-03. Both target **blocker #1** (control flow). Re-ran this
census on the current pass via the now-**reproducible** harness `inject_census.py`
(the original was manual — that gap is now closed):

| Outcome | Count | vs 2026-07-02 baseline |
|---|---:|---|
| ✅ **COMPILES** (fully inlined + lowers) | **2** (`fabs`, `copysign`) | 3 → 2–3 (`nearbyint` now gated only by a `fegetenv` link-gap in the harness) — **no net change** |
| ❌ **nested** control flow under quantum control | 24 | the transcendentals (`asin acos atan sinh…atan2 pow hypot fmax fmin log`) |
| ❌ tainted store to memory (Shadow) | 4 | `sin cos tan nextafter` |
| ❌ unsupported instruction | 8 | `exp exp2 log2 log10 rint fmod erf erfc` |
| ❌ uninlined kernel / self-ref (harness gap) | 4 | `sqrt scalbn lgamma nearbyint` |

**The fp-select unlock moved 0 functions into COMPILES.** Verified the bodies genuinely
inline and taint reaches the internals (e.g. `atan` fully inlines to 21 fp-arith opcodes +
10 branches, then declines at a **nested** tainted branch). kjd1 unlocked *single-level*
tainted fp `select` (clang -O1 flattens a lone `?:`); openlibm's real range reduction is
*multi-level* `if/br` (decline reason is literally "**nested** control flow under quantum
control"), which the 4.4/4.5 single-diamond/switch shapes don't match. **Consequence
(unchanged): off-the-shelf branchy libm is still blocked by nested control flow + scratch
memory; the unlock only pays off with BRANCHLESS-authored bodies** (the
`math-source-injection-opcode-lowering` bd memory's thesis). Raw per-fn results:
`inject_results.json`.

## Reproduce

Requires cloning openlibm (not a runtime dependency — a one-time source fetch; the shipped
compiler would vendor its own injectable soft-lib and never download). The
`inject_census.py` harness automates the per-function pipeline; its module docstring has the
exact bitcode-corpus build commands:

```
git clone --depth 1 https://github.com/JuliaMath/openlibm <scratch>/openlibm
# build src/*.c + bsdsrc/*.c to bitcode (-I include -I src -I amd64 -I bsdsrc) into <scratch>/bc,
# then: BC=<scratch>/bc python3 tools/library_coverage/inject_census.py
# (per-function: clang -fno-builtin-<fn> -> iterative closure llvm-link ->
#  opt 'internalize,always-inline,globaldce,default<O2>' -> opt -passes=cq-lowering)
```
