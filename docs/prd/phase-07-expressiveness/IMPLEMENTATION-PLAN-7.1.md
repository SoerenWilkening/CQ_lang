# Phase 7.1 — Implementation Plan (opcode-surface completion)

> **Status:** DRAFT plan of execution, written 2026-06-19 against
> [`PRD-7.1.md`](PRD-7.1.md). Modular (each increment lands independently,
> red→green→clear) and test-driven (every accept-predicate ships a positive
> fixture **and** a mirrored negative `RUN: not … | FileCheck`, Rule 12).
> Grounded in a subsystem map of the live code (file:line anchors verified
> 2026-06-19) and hardened by an independent adversarial review whose findings
> are folded in as the **§2 resolutions** (read those first — three of them
> change *what gets built*, not just what gets tested).
>
> This document is the *execution* layer; the PRD is the *decision* layer. It
> does not restate PRD design rationale — it says exactly which lines change,
> in what order, behind which fixtures, and how each verify-clean hazard is
> fenced.

---

## 0. Cross-cutting conventions (apply to every increment)

### 0.1 The per-increment loop (Rule 12 / 13)
1. **RED** — write the negative decline fixture(s) **first** (the over-accept
   guard), then the positive accept fixture; watch them fail.
2. **IMPL** — minimal change at the mapped anchor.
3. **REGEN** — only items 4/5: `gen_templates.py` regenerate + `--check` drift
   clean (Rule 15; edit YAML, never the generated `.h/.c`).
4. **VERIFY** — `ctest` green (necessary, not sufficient, Rule 2) **plus** the
   ≥1 e2e golden smoke (the only layer that *links*, Rule 16).
5. **CLEAR** — independent adversarial Rule-13 review for any change to a
   named lowering-core file (`TaintPropagation`, the swap-route/control emitter,
   `FreePoint`, `EmitInverse`, `ChainWalk`, `Uncomputation`, `RotationLowering`,
   and — for 7.1 — `CompareLowering`/`ArithLowering`/`CastLowering`/the new
   `IntrinsicLowering`). A green suite alone does **not** clear a core change.

### 0.2 Fixture idioms (copyable skeletons)
- **Positive ir-pass** (always two RUN lines — the verify line guards the
  cross-type `i1→i32` / `iN→i32` RAUW):
  ```
  ; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
  ; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
  ; CHECK: call i32 @cq_template_<…>(
  ; CHECK-NOT: <the stock opcode it replaced>
  ```
- **Negative ir-pass** (mirror the diagnostic character-for-character):
  ```
  ; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
  ; CHECK: error{{.*}}<exact diagnostic substring>
  ; CHECK-NOT: <the symbol that must NOT be emitted>
  ```
- **Frontend** (survives `clang -O1`, no plugin): `tests/frontend/*.c`,
  `// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s`.
- ir-pass `.ll` fixtures are **auto-discovered** by `ir-pass/test/lit.cfg.py`;
  **e2e slices are NOT** — each needs a hand-written `add_test` block in
  `tests/e2e/CMakeLists.txt` **and a `cmake` reconfigure**.

### 0.3 Diagnostic literals (verified 2026-06-19 — mirror exactly)
| Constant | String |
|---|---|
| `kMsgUnknownCallee` | `cq taint escape: tainted value consumed by an unknown callee` |
| `kMsgStore` | `cq taint escape: tainted value stored to memory` |
| `kMsgOther` | `cq taint escape: tainted value reaches an unsupported instruction` |
| `kMsgNonI32Return` | `cq taint escape: tainted value returned at non-i32 width` |
| `kMsgClassicalPhi` | `cq taint escape: tainted value muxed by a classical-condition phi` |
| `diagnoseUnderControl(x)` | `cq controlled lowering: <x> under quantum control` |
| `diagnoseNoTemplate` | `no template for opcode '<detail>' in tainted context` |
| clang `_BitInt(24)` source | `controlling expression type '_BitInt(24)' not compatible with any generic association type` |

### 0.4 Build / test (LLVM 19 mandatory; `LLVM=/usr/local/opt/llvm@19/bin`)
```bash
cmake --build build --target CQPass                              # just the plugin
ctest --test-dir build -R ir-pass-lit  --output-on-failure      # *.ll lowering/control/uncompute
ctest --test-dir build -R frontend-lit --output-on-failure      # CQ.h survives clang -O1
ctest --test-dir build -R '^e2e-'      --output-on-failure      # vertical slices — the only LINK layer
ctest --test-dir build -R runtime      --output-on-failure      # trace golden + header compile
python3 tools/gen_templates.py --output-dir runtime --check     # SHA-256 drift gate (items 4/5)
python3 tools/gen_templates_test.py                             # symbol count + decl/def pairing
```
e2e link order is load-bearing: `libcq_templates.a` **before** `libcq_runtime.a`
(`run_slice.sh` already encodes this; preserve it in every new `add_test`).

### 0.5 Baseline facts (anchors verified)
- Stock `clang -O1` is the validated floor (Rule 9). The single real
  `XFAIL` is `ir-pass/test/lowering_invert_add_i32.ll` (a Phase-8 manual-inversion
  tracker) — unrelated to 7.1; leave it.
- The QQ compare template machinery **already exists end-to-end** (forward, `_inv`,
  `_unc`, the `DagTraversal` two-parent recovery, the `WidthDispatch` QQ resolver) —
  item 1 only needs to *feed it a width*.
- `cq_runtime.{h,c}` is **hand-written** (the `cqrt_*` core ABI); `cq_templates.{h,c}`
  is **generated** from `tools/opcode_table.yaml`. The generated surface is
  **1562** symbols today (`gen_templates_test.py:84`).
- `HandleWidth` (`TaintSet`, `TaintPropagation.h:80`) is a `DenseMap<Value*,StringRef>`
  with exactly **one writer** (`RotationLowering.cpp:164`, theta-source only) and
  **zero readers** today — item 1 adds the first reader.

---

## 1. Landing order, dependencies, freeze-gating

```
        ┌─ A  Q+Q data compare ───────────────┐  (no ABI)   ── creates HandleWidth's 1st reader
        ├─ B  freeze passthrough ─────────────┤  (no ABI)   ── disjoint code path
   1 →  ├─ C  N-ary classical merge ──────────┤  (no ABI)   ── disjoint code path
        ├─ D  wide widths i128/f16/_BitInt ───┐  (FROZEN ABI · Rule-13)
        └─ E  curated llvm.* intrinsics ──────┘  (FROZEN ABI · Rule-13)
```
- **A, B, C are mutually independent** and may land in any order / in parallel
  (B and C both touch `TaintPropagation.cpp` but **disjoint functions** —
  `declineTaintEscapes`/`SelectClassify` for B, `liftOneRegisterMergePhi` for C;
  only a merge-order note if co-branched).
- **D ↔ A coordination:** both touch `abiWidthFromType`. D *widens* it; A treats
  an empty lookup as **decline** (never falls back to i32), so A is
  forward-compatible. If both are in flight, **D regenerates the YAML SHA against
  the final merged YAML** (regen last) — a stale-base regen passes `--check`
  locally yet drifts on merge.
- **D, E are freeze-gating** (PRD §1 table): every minted `cqrt_*_{i128,f16}` /
  `cq_template_*_{i128,f16}` / intrinsic symbol is **permanent**. Each must clear
  **independent adversarial Rule-13 review before commit** and land **before the
  Phase-11 freeze**. A and B/C add **no frozen symbols**.
- **E is independent of A and D** for the full curated set: width comes from the
  intrinsic **result** type (`iN`, never `i1`) so no `HandleWidth`, and the set
  uses only `{i8,i16,i32,i64}` so no i128/f16 dependency on D.

---

## 2. Adversarial-review resolutions (READ FIRST — these change the build)

The independent review of the draft plans surfaced one **blocker**, three
**major** items, and several minor gaps. The resolutions below are now part of
the plan; the increment sections incorporate them.

- **R-B (BLOCKER) — `freeze` must not become an escaped/measured laundering
  path.** Verified: `declineTaintEscapes` currently declines `freeze` via
  `kMsgOther` (`TaintPropagation.cpp:499`, comment at `:494` names `freeze`
  explicitly), and a tainted **i32** `ret` is an *accepted* Escaped case
  (`:482-487`). A **blanket** `isa<FreezeInst>` whitelist therefore silently
  admits `freeze i32 %escaped_handle; ret i32 %f` and `freeze` of a value also
  consumed by `cq_measure` / a fan-out lineage — exactly the PRD §4 "freeze
  re-laundering an Escaped value" decline shape, with zero coverage.
  **Resolution:** the whitelist is **narrow, not blanket** — accept a `freeze`
  only when its operand is **not** independently Escaped/Measured and the result
  is integer (the FP-angle case is fenced by the GATE-3 carrier extension).
  Add the escaped-operand and measured-fan-out negative fixtures **and** the
  standing-freeze-inside-an-uncomputed-DAG fixture; **default to decline** on any
  ambiguity (Prime Directive). Increment B is **blocked** until these land and
  the freeze↔uncompute interaction is Rule-13-cleared.

- **R-D (MAJOR) — `_BitInt(N)` round+mask invents a frozen symbol family;
  deferred to a follow-up (owner decision 2026-06-20).** The draft presented the
  mask as the primary path but left `cq_template_mask_<W>` structurally
  unspecified (no YAML row, no count delta, no `abi_codegen` shape, no `_unc`
  twin). **Resolution:** within 7.1, `_BitInt(N)` for non-ABI N **permanently
  declines** (keep `abiWidthFromType` empty → loud `no template`); the round-up +
  high-bit-mask support is a **tracked pre-freeze follow-up (D5), OUT of 7.1**.
  Increment D ships **i128 + f16 only**. This is an owner resequencing of PRD
  §2.5 (which had scoped `_BitInt` round+mask inside item 4); the follow-up must
  still land **before the Phase-11 freeze** since it adds frozen symbols. Shipping
  i128/f16 does **not** depend on it.

- **R-E (MAJOR) — the `_unc` adjoint-shape and source-liveness must be proven,
  not asserted.** Verified: the `_unc` branch (`EmitInverse.cpp:128-147`) is a
  **recompute-from-live-sources** model — `void(out, <forward operands…>)`, i.e.
  `out ^= f(operands)` — correct **only** for an **additive producer** (fresh out
  rail, source operands preserved). **Resolution:** lower **every** curated
  intrinsic (full set, owner 2026-06-20) as an **additive producer** (mirror
  `ArithLowering::rewriteUnary`/`rewriteBinary`: fresh rail, sources preserved),
  **never** an in-place gate. The generic `_unc(out, srcs…)` then zeros `out` and
  the walk frees each source via its own producer. This is *uniform* across both
  classes — the Class-2 non-injective intrinsics (`ctpop`/`smin`/`abs`/…) are
  reversible **precisely because** the `_unc` recomputes from live sources and
  never recovers the input. The load-bearing fence for Class 2 is therefore
  **source-liveness** (linear lineage, Rule 8): a source freed/uncomputed before
  its `_unc` is the silent-collapse bug. Ship a **free-count fixture** + a
  **sources-live fixture** + a per-intrinsic Rule-13 adjoint proof (Class-1
  involution/rotate-back; Class-2 recompute discharge).

- **R-A (MAJOR) — `HandleWidth` is not scrubbed on erase; A adds its first
  reader.** `scrubTaint`/`promote` touch `Tainted`/`BirthOrder`/`PhiCalls`/
  `StaleDeclined` but **not** `HandleWidth`. With `Value*` pointer reuse a stale
  entry could feed a wrong width into a later Q+Q compare (verify-clean).
  **Resolution:** add `HandleWidth.erase(orig)` to the same chokepoint that
  erases a handle, and ship a stale-on-erase adversarial probe.

- **Minor (folded into the relevant increments):** A cross-block-derived-operand
  positive fixture + the `SharedCondFlags` dual-use (control-condition-also-read-
  as-data) interaction fixture; B's e2e-constructability waiver made an explicit
  owner-accepted N/A; C's "build all N `WireChain`s before any mutation"
  pinned as a correctness invariant; D's tainted-**f16 return** decline fixture;
  E's "true-rotation-but-not-yet-curated `fshl`" still-declines fixture.

---

## 3. Increment A — Q+Q data-position compare (no ABI)

**Objective.** Lower a tainted Q+Q (both-operands-tainted) **data-position**
compare (`icmp`/`fcmp` whose result routes to data/`cq_measure`, **not** a
`br`/`select`/`switch` condition) by feeding a width recovered from
`TaintSet::HandleWidth` into the already-built `Shape::QQ` branch of
`lowerCompareImpl`. IR-pass-only; **no** YAML, **no** new frozen symbols.

**Change points**
| Anchor | Change |
|---|---|
| `ArithLowering.cpp:122-123` (binary mint+RAUW), `:151-152` (fneg) | record `taint.HandleWidth[T] = AbiWidth` (result width already at `:45`/`:134`) |
| `CastLowering.cpp:114-115` (cast mint+RAUW) | record `taint.HandleWidth[T] = cw.To` (**dest** width, captured `OpcodeLowering.cpp:223-224`) — never `cw.From`, never `i32` |
| `CompareLowering.cpp:272` (`rewriteCompare` fresh-mint call) | when both operands tainted, `wA=HandleWidth.lookup(op0)`, `wB=…(op1)`; pass `qqWidth=wA` **iff** `!wA.empty() && wA==wB`, else empty → existing loud bail at `:98-100` |
| `RotationLowering.cpp:146-148` (chained-theta reuse `Op`) | comment-only: chained handle inherits `Op`'s `HandleWidth` by SSA identity; a genuinely-missing entry rides the decline |
| **promote/scrub chokepoint** (R-A) | `HandleWidth.erase(orig)` wherever a handle is erased (mirror the `Tainted.erase`) |
| `CompareLowering.cpp:267-271` (`SharedCondFlags` fast-path) | **unchanged** — do not conflate with the data-path QQ mint |

**Reuse, do not touch:** the QQ branch `:90-105`, the `WidthDispatch.cpp:231`
QQ resolver `(i32,i32)→i32`, the `compareInScope` predicate gate `:159`, the
control-position Q+Q declines (`SwapRouteEmit` `qqWidth={}` at `296/411/573/639`,
`SelectClassify.cpp:269-271`) — all out of scope, must stay green/declining.

**TDD steps**
1. **RED** `lowering_icmp_qq_mixed_width_reject.ll` — two thetas of **different**
   recovered widths (via a tainted cast chain) reach `icmp` → measure; must keep
   the loud decline (no single correct W). `CHECK: error{{.*}}no template` +
   `CHECK-NOT: cq_template_icmp` + `…fcmp`.
2. **RED** `lowering_icmp_qq_no_width_reject.ll` — an operand with **absent**
   `HandleWidth` → decline (never fall back to i32). Same diagnostic.
3. **RED→GREEN (convert)** `lowering_icmp_qq_negative.ll` → primary positive:
   two same-width `cq_theta_si32`, `icmp slt`, → `cq_measure`.
   `CHECK: call i32 @cq_template_icmp_slt_i32(` + `CHECK-NOT: …_i32_hl(` +
   `CHECK-NOT: icmp slt`.
4. **RED** per-width positives `lowering_icmp_qq_i64.ll` (proves the **logical**
   width, not laundered i32) and `lowering_fcmp_qq_f64.ll` (proves the fp-named
   symbol `cq_template_fcmp_olt_f64` + the `compareInScope` gate on the QQ path).
5. **RED** derived-operand positives `lowering_icmp_qq_arith_derived.ll`
   (`add`-result handle gets `HandleWidth=i32`) and `…_cast_derived.ll`
   (`zext i8→i32` result gets `HandleWidth=cw.To`). **+ R-A minor:** a
   **cross-block** derived-operand positive (operand defined in a dominating
   predecessor) — or document the same-block assumption if Phase-2 program-order
   makes the cross-block lookup safely decline.
6. **RED (R-A)** `lowering_icmp_qq_stale_width_probe.ll` — mint→erase→re-mint at a
   reused address then Q+Q compare; pins that the `HandleWidth.erase` scrub keeps
   a stale entry from selecting a wrong symbol.
7. **IMPL** the four change points above (prefer extending the shared `promote()`
   helper — duplicated at `ArithLowering.cpp:28`, `CastLowering.cpp:31`,
   `CompareLowering.cpp:37` — to take an optional width arg, one chokepoint, Rule 14).
8. **VERIFY** `ctest -R ir-pass-lit`; confirm the sibling control Q+Q declines and
   the HL compare positives (`lowering_icmp_slt_hl_i32.ll`,
   `lowering_fcmp_une_hl_f32.ll`) and the compare-uncompute fixtures are
   unregressed.
9. **e2e smoke** `tests/e2e/slice_compare_qq.c` (+`.expected.log`, +`add_test`,
   reconfigure): two `cq_theta`-seeded values compared, boolean `cq_measure`'d —
   the only layer that proves `cq_template_icmp_*_i32(i32,i32)` **and its `_unc`
   twin** link and signature-match.
10. **CLEAR (Rule 13)** independent review of `CompareLowering`/`ArithLowering`/
    `CastLowering`: agreement-or-decline (never pick one width on disagreement,
    never default empty→i32); bare-QQ symbol at the **logical** width with the
    correct `icmp`/`fcmp` stem + in-scope predicate; derived records use
    result-width / `cw.To`; `SharedCondFlags` + control-position declines
    unregressed; `HandleWidth` erase-scrub correct.

**Hazards → caught by:** wrong-width symbol → `_i64`/`_f64` positives +
mixed-width reject; empty→i32 fallback → no-width reject; derived-operand miss →
arith/cast positives; out-of-scope fcmp predicate → `compareInScope` gate +
adversarial probe; stale `HandleWidth` on erase → stale-width probe;
SharedCondFlags conflation → sibling control fixtures stay green.

---

## 4. Increment B — `freeze` passthrough (no ABI) — **BLOCKED on R-B**

**Objective.** Make a tainted `freeze` a basis-level identity (taint passthrough,
no gate) **without** opening either laundering vector: (i) the FP-angle leak, and
(ii) the **escaped/measured-operand** path (R-B). `propagate` already taints the
freeze result with no special case; a standing `freeze i32 %handle` is verify-
clean identity that `ChainWalk::isTerminalHandle` (`:49-50`) treats as a benign
non-call read.

**Change points**
| Anchor | Change |
|---|---|
| `SelectClassify.cpp:99` (carrier disjunction) | **MANDATORY-FIRST:** add `isa<FreezeInst>(X)` so `selReachesRotationArg1` crosses `freeze`; correct the now-false "dead code" comment at `:56-73` in the same edit |
| `TaintPropagation.cpp:~490-499` (before the `kMsgStore`/`kMsgOther` catch-all) | add the **narrow** accept-skip for `freeze` (see R-B rule below), after the `PHINode`/`SelectInst` skip (`:458`) and terminator skips (`:482-489`) |

**R-B accept rule (narrow, not blanket).** Skip a `FreezeInst` **only** when:
its result type is integer (FP rides the GATE-3 fence), **and** its tainted
operand is not independently Escaped (no `ret`/`cq_invert`/store user) and not
`Measured` outside this lineage. Anything else → fall through to the existing
decline. When the escape/ownership status cannot be cheaply proven at this point
(escape/`FreePoint` analysis runs later), **default to decline** — over-decline
is safe; the basis-level passthrough we actually want is the pure local
integer-identity case.

**TDD steps**
1. **RED** `lowering_freeze_passthrough_i32.ll` — `cq_theta`→tainted i32 op→
   `freeze i32`→`cq_measure` (no FP/select/rotation). Positive two-RUN; assert
   `freeze i32` survives (or `CHECK-NOT: freeze` if a fold is chosen — pin one).
2. **RED (R-B blocker)** `lowering_reject_freeze_escaped_return.ll` —
   `%f = freeze i32 %h; ret i32 %f` where `%h` is a tainted handle: the freeze
   must **not** launder `%h` into the accepted i32-ret Escaped path in a way that
   bypasses ownership. Decline (`kMsgOther` or a freeze-specific brand — pick and
   pin) **unless** Rule-13 proves it identical to the already-accepted `ret %h`.
3. **RED (R-B blocker)** `lowering_reject_freeze_measured_fanout.ll` — `freeze`
   of a value **also** consumed by `cq_measure` / with >1 forward consumer:
   confirm the whole-DAG uncompute does not double-free / mis-free the rail
   (linear-lineage bail, Rule 8). Decline on fan-out.
4. **RED (probe family)** keep the EXISTING `control_swap_reject_select_freeze.ll`
   declining; **flip** its CHECK from `kMsgOther` to the GATE-3 brand
   `error{{.*}}rotation angle under quantum control` + `CHECK-NOT: cq taint escape`.
5. **RED** `control_swap_reject_freeze_phi_angle.ll` — phi→`freeze`→`fpext`→
   `cq_phi` arg-1 (proves the carrier extension covers phi-routed FP); **if**
   `clang -O1` invariants make this unconstructable, degrade to a documented
   exhaustiveness comment (do not fabricate an untestable shape).
6. **IMPL** step-3-anchor edits in order: **carrier extension first**
   (`SelectClassify.cpp:99`), then the **narrow** escape-skip
   (`TaintPropagation.cpp`) — so the angle path is never momentarily open.
7. **VERIFY** `ctest -R ir-pass-lit`: the i32 passthrough passes; the escaped/
   measured/angle declines hold; `lowering_reject_taint_escape_gep.ll` /
   `_store_global.ll` / `_opaque_call.ll` all still decline (the skip did **not**
   broaden to gep/store/unknown-callee).
8. **e2e smoke** `tests/e2e/slice_freeze_passthrough.c` — **owner-accepted N/A
   contingency:** `clang -O1` rarely synthesizes a tainted `freeze` from C
   source (it is a mid-pipeline insertion). If unconstructable, document the
   slice N/A in its header; the lit fixture is the authoritative accept proof and
   no new symbol needs link-resolution. (This waiver must be **explicit**, not a
   silent skip — Rule 16.)
9. **CLEAR (Rule 13)** review of the taint-escape guard + angle fence: the
   skip is exactly `isa<FreezeInst>` + the R-B narrowing (no broadening to
   gep/store/unknown-callee/atomicrmw); the carrier extension crosses `freeze`
   for **all** value-preserving FP routing; the escape-guard-before-control-
   detection ordering (`CQLoweringPass.cpp:77` vs `:96`) means a whitelisted
   angle-freeze is re-caught at GATE 3; **and** the freeze↔whole-DAG-uncompute
   interaction (standing freeze = benign non-call read; no dirty-free) is sound.

**Hazards → caught by:** FP-angle laundering → flipped `…select_freeze.ll`;
escaped/measured laundering (R-B) → the two new reject fixtures; whitelist
over-broadening → gep/store/unknown-callee fixtures stay declining; stale
"dead code" comment → corrected in the same edit (step 6).

---

## 5. Increment C — N-ary classical-condition merge-φ lift (no ABI)

**Objective.** Generalize `liftOneRegisterMergePhi` (`TaintPropagation.cpp:628-729`)
from the hard 2-incoming gate (`:635 != 2`) to **N** incoming, so the natural
classical N-way `switch` around an in-place quantum gate on **one** register lifts
(RAUW to the wire base, scrub, erase) instead of declining at `kMsgClassicalPhi`.
Pure analysis change; **no** symbols. The whole correctness payload is the
per-edge conditional-execution proof generalized to **all** other edges, not the
2-way `1-i` complement.

**Reuse (already arity-agnostic):** `resolveWireBase` (`:589-603`),
`terminatorIsClassical` (`:614-620`, already accepts a classical `switch`), the
idom-terminator check (`:661-666`), the `LiftedConsumers` re-sweep
(`:722-724` + `CQLoweringPass.cpp:119`), `scrubTaint` (`:726`).

**IMPL (the single load-bearing edit, `TaintPropagation.cpp`)**
- `:635` → `unsigned N = Phi->getNumIncomingValues(); if (N < 2) return false;`
- `:646-649` → build `SmallVector<WireChain,4> Chains` over `incoming_values()`;
  require every `Chains[k].Base == Chains[0].Base` **and** `Chains[0].Base != Phi`.
- `:667-670` → pred-terminator loop `for i in [0,N)`.
- `:677-701` **CORE** → drop the `Chains[2]` array and `Other = getIncomingBlock(1-i)`;
  for each edge `i`, each gate `G` in `Chains[i].Gates`: keep (6) `G->getParent()!=Self → false`,
  keep (7b) `isPotentiallyReachable(Self->getTerminator(), G) → false`, and
  generalize (7a) to **all** other edges:
  `for j in [0,N), j!=i: if (isPotentiallyReachable(G, IncomingBlock(j)->getTerminator(), nullptr, &*DT)) return false;`
- ACCEPT tail (`:722-727`) unchanged → RAUW to `Chains[0].Base`.
- **Correctness invariant (minor finding):** build **all N** `WireChain`s and
  complete every proof **before** any mutation — the function stays pure-analysis
  until the ACCEPT tail (a partial-mutation-then-bail corrupts the module).
- `N==2` must reduce **exactly** to the prior `1-i` logic.

**TDD steps**
1. **RED** positive `lowering_classical_mux_phi_onereg_switch_nway.ll` — classical
   `switch i32 %k` (≥3 arms) each doing in-place `cq_phi(%q, …)` on the one base,
   joined at one merge φ. `CHECK`: one `cqrt_alloc_i32`, each `cqrt_rz_i32` inside
   its own case block, merge `cqrt_measure_i32`; `CHECK-NOT: phi i32`, `cq_phi_si32`.
2. **RED** decline probe family (each mirrors `kMsgClassicalPhi`):
   - `…_nway_loop.ll` — gate in arm-i reaches the merge via a **third** edge `j`
     (`j!=i`, `j!=1-i`) — the exact hole a naive `1-i` extension leaves (**the
     primary silent-miscompile guard**).
   - `…_nway_crossblock_chain.ll` — one arm's gate chain has a call outside its
     incoming block (condition (6)).
   - `…_nway_mixedbase.ll` — one incoming resolves to a different wire base.
   - `…_nway_mixed_incoming.ll` — one incoming is untainted (a literal).
3. **IMPL** the edit above; step-1 goes green, step-2 stays declining.
4. **VERIFY** `ctest -R ir-pass-lit` — every pre-existing arity-2 fixture
   (`_onereg*`, `_reject_classical_mux_phi_*`) **behaviorally unchanged**; the
   `SelectInst` branch (`:766-776`) is **not** touched (a select's gate dominates
   it → lifting would turn `rotate iff c` into `always rotate`).
5. **e2e smoke** `tests/e2e/slice_classical_switch_gate.c` — classical `switch`
   derived from `argc` (un-foldable) around in-place `cq_phi` arms on one register,
   then `cq_measure`; golden shows only the executed arm's `cqrt_rz`.
6. **CLEAR (Rule 13)** review of the generalized (7a): no accepted N-ary φ admits
   a path that fires an arm-i gate then enters the merge through a different edge
   `j` whose record omits `G`; the third-edge probe is caught; the
   `LiftedConsumers` re-sweep still fires for **transitive** stale ops downstream
   of an N-ary lift.

**Hazards → caught by:** third-edge staleness → `…_nway_loop.ll` + Rule-13
third-edge probe; multi-base alias → `…_nway_mixedbase.ll`/`…_mixed_incoming.ll`;
cross-block gate → `…_nway_crossblock_chain.ll`; arity-2 regression → existing
fixtures unchanged.

---

## 6. Increment D — wide / intermediate widths (FROZEN ABI · Rule-13)

**Objective.** Widen the recognized ABI set from `{i1,i8,i16,i32,i64,f32,f64}` to
add **i128** (int) and **f16** (fp), wired across **four lockstep sites** (YAML+regen
· hand-written runtime core ABI · IR-pass recognizers · `CQ.h` `_Generic`), and
add `__int128`/`unsigned __int128`/`_Float16` as first-class frontend **source**
types. **`_BitInt(N)` for non-ABI N DECLINES within 7.1 (R-D, owner decision
2026-06-20);** its round-up+mask support is a tracked pre-freeze **follow-up
(D5), out of this increment**. Increment D ships **i128 + f16 only**.

### D1 — YAML + codegen (source of truth)
- `opcode_table.yaml:81-88` widths map: `i128: {bits:128, c_type:"__int128", domain:int}`,
  `f16: {bits:16, c_type:"_Float16", domain:fp}`.
- Append **i128** to **all** int binary rows (`:110-123`) + `icmp` widths (`:147`);
  append **f16** to **all** fp binary rows (`:125-129`), the `fneg` unary (`:135`),
  `fcmp` widths (`:148`). **Symmetry hazard:** a width in some rows but not all
  (`add_i128` exists, `mul_i128` missing) is an inconsistent mid-function reject —
  add to **all** rows of the matching domain.
- **Cast pairs (`:155-278`, the largest, most dangerous edit):** hand-add every
  legitimate `{from,to}` touching i128 (`sext/zext {i1,i8,i16,i32,i64}→i128`,
  `trunc i128→…`) and f16 (`fpext f16→{f32,f64}`, `fptrunc {f32,f64}→f16`,
  `sitofp/uitofp ints→f16`, `fptosi/fptoui f16→ints`, the i128↔fp pairs).
  **Direction hazard:** an invalid pair (`fpext f64→f16` is a *narrow*) creates a
  symbol contradicting its kind — `castInScope` (`OpcodeSupport.cpp:106-131` via
  `intBits`/`fpBits`) must reject it. f16 is 16-bit but **fp-domain** — never route
  it through integer-width casts.
- `abi_codegen.py:30-38` `WIDTH_INFO`: `f16 → {ctype:"_Float16", fmt:"%f", cast:"(double)"}`
  (the explicit `(double)` cast is mandatory or `-Werror` trips on `_Float16→%f`);
  **i128 has no native printf conversion** — `%lld` **silently truncates** 128
  bits (a clean-compiling trace miscompile only the e2e golden catches). Use a
  `%llx`-split or string formatter; record the choice as load-bearing.

### D2 — regen + counts
`python3 tools/gen_templates.py --output-dir runtime`; recompute the hard-coded
total in `gen_templates_test.py:84` (was **1562**) and the per-kind breakdown
comment (`:78-83` + `opcode_table.yaml:61-72`); `--check` exits 0;
`gen_templates_test.py` passes. The `yaml-sha256` banner at line 1 of the
generated files changes — that is the expected drift anchor.

### D3 — hand-written runtime core ABI (NOT generated)
Add to `cq_runtime.{h,c}`: `cqrt_alloc_{i128,f16}`, `cqrt_measure_{i128,f16}`,
`cqrt_ry_{i128,f16}`, `cqrt_rz_{i128,f16}` (+ controlled `_rz` twins),
`cqrt_copy_i128` — **but NOT `cqrt_copy_f16`** (`copyFn` returns null for fp,
`WidthDispatch.cpp:128-130`; this preserves the f16-angle-vs-data fence). A
recognized width with **no** matching hand-written `cqrt_alloc_<W>` is an
**unresolved-symbol link failure** at e2e (invisible to `opt -verify`). Update
`runtime/test_trace.{c,expected.log}` so `runtime_trace_test` stays green.

### D4 — IR-pass recognizers (the ENABLING change; lockstep last)
- `OpcodeSupport.cpp abiWidthFromType`: `case 128: return "i128";` and
  `if (ty->isHalfTy()) return "f16";` before the final `return {}` (`:163`).
  Keep it **pure power-of-2** — no round-up logic here (it returns only a
  `StringRef`).
- `OpcodeSupport.cpp intBits/fpBits`: `i128→128`, `f16→16`.
- `WidthDispatch.cpp typeForAbiWidth (:43-52)`: `i128→getInt128Ty`, `f16→getHalfTy`.
- **copyFn hazard:** once i128 is a recognized integer it mints `cqrt_copy_i128`
  (must exist, D3). f16 must **never** get a `cqrt_copy` (the `!isIntegerTy`
  null-guard) — enabling f16 without preserving that null is the f16-angle
  silent-dephasing miscompile (the f64 family at a new width).

### D5 — `_BitInt(N)` round-up + visible mask — **FOLLOW-UP, out of 7.1**

> **RESOLVED 2026-06-21 (test_C_libtooling-m0yi) — NO new frozen ABI needed; the
> frozen-mask-family design below is SUPERSEDED.** The design below rested on the
> premise that clang emits a *raw* `add i40` (→ `abiWidthFromType` empty → "no
> template"), so CQ would have to round up to i64 *and insert its own* masked-op
> family. **That premise is false for `-O1` (verified against clang 19.1.7,
> darwin+linux).** clang **itself** rounds `_BitInt(N≤64)` up to the ABI storage
> width *and emits the wraparound mask as a stock op*:
> - unsigned `_BitInt(40)`: `add i64` then `and i64 %s, 1099511627775` (= 2⁴⁰−1);
> - signed `_BitInt(40)`: `add i64` then `shl i64 %s, 24` + `ashr i64 %sh, 24`
>   (sign-extend from bit 40).
>
> Every one of these is a stock op with an **existing frozen template**
> (`cq_template_add_i64`, `cq_template_and_i64_hl`, `cq_template_shl_i64_hl`,
> `cq_template_ashr_i64_hl`), so `_BitInt(N≤64)` **already lowers end-to-end today**
> (`opt -verify` clean, links, runs) with **zero** new symbols. The mask even
> reverses correctly in the whole-DAG `_unc` via the ordinary
> `cq_template_and_i64_hl_unc(out, src, lit)` — no masking-specific uncompute.
> `_BitInt(N)` for `64 < N ≤ 128` rounds to **i128** and declines via the existing
> i128 gap (ties to `test_C_libtooling-n0ui`).
>
> The `lowering_reject_bitint_intermediate_unmasked.ll` "standing decline" named
> below **was never created**; clang does not emit a raw non-ABI `iN` at `-O1`. The
> realistic non-ABI gate is a **cast** to the width, so the safety-net guard is
> `lowering_reject_bitint_raw_iN.ll` (tainted `trunc i64 → i40` → loud
> `no template for opcode 'trunc i40' in tainted context`). **Shipped instead of
> the frozen family:** positive `lowering_bitint_intermediate_masked_i40.ll`
> (unsigned, incl. the and-mask `_unc`) + `lowering_bitint_signed_i40.ll` (shl/ashr)
> + the safety-net decline + the `e2e-slice-bitint` golden round-trip. This
> **removes D5 from the freeze-gating set** (it adds no frozen symbol). The
> superseded design is retained below for history. See memory
> `bitint-already-lowers-clang-rounds-and-masks`.

Owner decision 2026-06-20 (superseded above): this is a **tracked pre-freeze follow-up**, not part of
Increment D. **Within 7.1, `_BitInt(N)` for non-ABI N permanently declines:** keep
`abiWidthFromType` empty for non-power-of-2 `iN` → loud `no template`. The decline
fixture `lowering_reject_bitint_intermediate_unmasked.ll` (`add i40` → `no
template`) is a **standing decline** for 7.1 (not flipped), and is the regression
anchor the follow-up will later convert.

**What the follow-up must ship (recorded here so the scope is not lost; must land
before the Phase-11 freeze since it adds frozen symbols):**
- a **new frozen** masked-op family enumerated in `opcode_table.yaml` (its own
  rows, `abi_codegen` shape, `WIDTH_INFO`, and a **count delta** in
  `gen_templates_test.py`) — e.g. `cq_template_mask_<W>_hl(handle, lit=2^N−1)`;
- the mask as a **visible IR-level reversible op** inserted in `ArithLowering`
  *after* the arith template call and *before* the RAUW — it **cannot** hide in
  the trace-only runtime body (`cq_templates.c` does zero arithmetic, e.g.
  `cq_template_add_i32` at `runtime/cq_templates.c:139`);
- the literal **exactly `2^N − 1`** (`2^N` / `2^(N-1)` is itself a miscompile,
  Rule 10);
- the mask op **participates in the whole-DAG `_unc` reversal** (`cq_template_`-
  prefixed so `EmitInverse:128-147` handles it — but prove the `_unc` shape is
  correct for a masking op) + an `_unc`-shape fixture;
- Rule-13 analytic proof that no unmasked path exists, then flip the standing
  decline fixture to a positive `lowering_bitint_intermediate_masked_i40.ll`.

### D6 — CQ.h `_Generic` sources (frozen frontend)
- Backing externs (`CQ.h:20-67`): `cq_theta_si128`/`_ui128`/`_f16`, mirrored in
  `cq_phi_*`, `cq_measure_*` (measure has no `double` angle); **no purity
  attribute** (or DCE/CSE strips them — the `cq_theta_o1_survival.c` invariant).
- `_Generic` arms in **all three** blocks (`:81-96`, `:99-114`, `:117-132`):
  `__int128: …_si128,` `unsigned __int128: …_ui128,` `_Float16: …_f16,`. An arm
  in `theta` but not `measure` is a hard compile error (no `default:` — loud,
  never silent). **Do NOT add a `default:` arm** to "handle" `_BitInt` — that
  silently routes `_BitInt(24)` to a wrong-width symbol; the source decline
  **must** stay a `_Generic` compile error.
- Lockstep: `WidthDispatch.cpp` `kRows (:31-36)` add `{"si128","i128"}`,
  `{"ui128","i128"}`, `{"f16","f16"}`; `allSuffixes (:70-75)` extend;
  `frontEndIntrinsicNames (:283-300)` add the theta/phi/measure triples;
  `declMatchesPrototype` needs `llvmTypeFor("si128")==…("ui128")==i128`,
  `…("f16")==half`. A CQ.h suffix **not** in `kRows` is silently skipped
  (`TaintPropagation.cpp:226-227`) — a source that compiles+links but is never
  tainted (verify-clean silent miss).

**TDD steps (interleave RED→GREEN as D1–D6 land)**
- **RED frontend** `tests/frontend/cq_theta_bitint_nonabi_reject.c` — `cq_theta`
  on `_BitInt(24)` → the clang `_Generic` decline (permanent). Capture the exact
  wording by running clang by hand first.
- **RED baseline** confirm `control_swap_reject_select_i128.ll`,
  `control_swap_reject_value_i128_merge.ll`, `spec_reject_intermediate_width.ll`,
  `spec_overaccept_probe_i128_return.ll` decline today; **re-point** the
  value-merge + intermediate-width fixtures from i128 to a **still-unsupported**
  width (`i256` / `_BitInt(200)>i128`) so the over-accept guard survives the i128
  flip; keep `…_i128_return.ll` declining (i128 **return** still rejected — D does
  **not** touch the `kMsgNonI32Return` gate at `:482-489`).
- **RED (minor finding)** `lowering_reject_f16_return.ll` — a tainted **f16
  return** (newly reachable once f16 is recognized) still declines (via the
  specialization fp-no-reversible-copy path, not `kMsgNonI32Return`).
- **RED** `lowering_reject_f16_merge_angle.ll` — an f16 merge φ over tainted data
  is an **angle**, must decline (`isFPOrFPVectorTy` true; `copyFn` null for f16).
- **RED** `lowering_reject_fpext_f64_to_f16.ll` — a narrowing `fpext` declines.
- **GREEN** positives: frontend survival rows in `cq_theta_smoke.c`/`cq_phi_smoke.c`/
  `cq_measure_smoke.c` (`CHECK: call {{.*}} @cq_theta_si128(`/`_ui128(`/`_f16(`,
  source order); `lowering_add_qq_i128.ll`, `lowering_mul_qq_i128.ll`,
  `lowering_fadd_qq_f16.ll`, `lowering_fneg_f16.ll`, `lowering_zext_i64_to_i128.ll`,
  `lowering_trunc_i128_to_i32.ll`, `lowering_fpext_f16_to_f32.ll` — each with the
  verify RUN line + `CHECK-NOT` on the stock opcode.
- **VERIFY** `ctest -R ir-pass-lit -R frontend-lit -R runtime`; `--check` 0;
  `gen_templates_test.py` (new count); `runtime_header_compile` `-Werror` clean.
- **e2e smoke** `tests/e2e/slice_wide_i128.c` (cq_theta `__int128` + i128 arith +
  measure; golden round-trips a **>64-bit** value, catching `%lld` truncation) and
  `tests/e2e/slice_f16.c` (cq_theta `_Float16` + fadd + measure). Capture goldens
  by hand; add `add_test` blocks + reconfigure.
- **CLEAR (Rule 13, MANDATORY pre-commit, frozen ABI)** over the four hazards:
  (1) `_BitInt` mask literal `=2^N−1` + reversible + present in `_unc` (or
  `_BitInt` non-ABI N still declines, D5 default); (2) `__int128` trace format —
  no `%lld` truncation, e2e round-trips >64 bits; (3) f16-angle fence —
  `copyFn` null for f16, f16 merge φ declines as angle; (4) frozen four-way
  lockstep exact, no width added to one site but not another. Record the verdict +
  frozen symbol list in this PRD folder and a `bd remember`.

**Hazards → caught by:** verify-clean overflow (`_BitInt` unmasked) → permanent
7.1 decline (`abiWidthFromType` empty → `no template`; mask is the D5 follow-up);
wrong-width symbol → positive `_i128`/`_f16`
fixtures + `CHECK-NOT` + e2e link; f16-angle dephasing → `copyFn` null +
`…_f16_merge_angle.ll`; invalid cast direction → `…_fpext_f64_to_f16.ll` +
`castInScope`; `__int128` printf truncation → `WIDTH_INFO` decision + e2e golden;
lockstep drift / link-miss → e2e link + `--check` + frontend survival; relaxed
return gate → `spec_overaccept_probe_i128_return.ll` + `lowering_reject_f16_return.ll`
stay green; frozen-symbol permanence → Rule-13 enumeration.

---

## 7. Increment E — curated reversible `llvm.*` idiom intrinsics (FROZEN ABI · Rule-13)

**Objective.** Replace the blanket `kMsgUnknownCallee` decline of tainted-arg
`llvm.*` intrinsics (`TaintPropagation.cpp:437-438`, comment names `llvm.smin`)
with an **EXACT-allowlist** accept path for the **full PRD §2.6 curated set**
(owner decision 2026-06-20), lowering each to a `cq_template_<op>_<W>` **additive
producer** so the existing whole-DAG `_unc` Bennett spine, `DagTraversal` producer
recovery, terminal test, and invertibility pre-scan accept it with **zero new
uncompute code**. Modeled as a **sibling** `tools/intrinsic_table.yaml` →
`runtime/cq_intrinsic_templates.{h,c}` (separate SHA banner; the `1562` count
**untouched**).

**The curated set, by mechanism class (PRD §2.6):**
- **Class 1 — bijections** (`fwd`/`inv`/`unc`; additive producer; analytic adjoint):
  `bswap` (`{i16,i32,i64}` — `llvm.bswap` requires a 16-bit-multiple width, so
  **no `bswap.i8`**) and `bitreverse` (`{i8,i16,i32,i64}`) are **self-inverse
  involutions** (`_inv` = re-apply); `fshl`/`fshr` **rotation** (`{i8,i16,i32,i64}`)
  is a bijection **only** in the `x==y` case (`_inv` = rotate by `W−n`).
- **Class 2 — non-injective but pure** (`fwd`/`unc` only — **no `_inv`**, the
  function is not invertible; reuse the Phase-5 compare `_unc` Bennett model
  verbatim): `smin`/`smax`/`umin`/`umax`, `abs`, `ctpop`, `ctlz`/`cttz`, and the
  saturating `uadd.sat`/`usub.sat`/`sadd.sat`/`ssub.sat` family, over
  `{i8,i16,i32,i64}`. **These are reversibilizable precisely because the `_unc`
  recomputes `f(sources)` from the still-live source operands and XORs the out
  rail to `|0⟩` — it never recovers the input.** The load-bearing fence is
  therefore **source-liveness**: the lowering must keep every operand live
  (linear lineage, Rule 8) so the recompute is valid; a freed/uncomputed source
  before the `_unc` is the silent-collapse bug.

**Arity / shape.** Class-1 + unary Class-2 (`abs`, `ctpop`, `ctlz`, `cttz` — the
trailing `i1` poison/zero flag is a constant `immarg`, rides the `_hl`
handle+literal shape) are unary-data; binary Class-2 (`smin`/`smax`/`umin`/`umax`,
`*.sat`) ride the existing QQ/HL/LH shapes exactly like `add`/`mul`. **Width comes
from the intrinsic RESULT type (a real `iN`), not `HandleWidth`** (the result is
`iN`, not `i1`) — so **E stays independent of Increment A**.

**Excluded → still decline loudly** (PRD §2.6 "OUT"): `*.with.overflow`
(`{iN,i1}` aggregate result — needs `extractvalue` routing, a separate heavier
mechanism), fp transcendentals (`llvm.sqrt`/`sin`/… — a separate Phase-6 Path-1
libm-substitution problem), and the **general (`x≠y`) funnel shift** (not
enumerated — only the rotation case is curated).

**Reuse (Rule 14, no edits):** `EmitInverse.cpp:128-147` `_unc` branch (recognizes
the `cq_template_` prefix), `DagTraversal.cpp:32-39` `isTemplateProducer`,
`Uncomputation.cpp:227-236` invertibility pre-scan, `WidthDispatch.cpp:200-202`
`Shape::Unary` + the QQ/HL/LH callees, `abi_codegen.py` `a1`/`ua1`/`hl`/`qq` shapes.

**Curation guard (Prime Directive).** An intrinsic enters the table **only** with
an analytically-derived, written adjoint proof (Class-1: the involution/rotate-back;
Class-2: the recompute-from-live-sources discharge). The table is curated, never
pattern-matched; a side-effecting or partial-domain intrinsic is a loud decline,
never a row.

**TDD steps**
1. **RED (over-accept fences — stay green forever):** `…_overflow_uadd.ll`
   (`{iN,i1}` aggregate → `kMsgUnknownCallee`), `…_transcendental_sqrt.ll`
   (fp transcendental → decline), `…_funnel_fshl_general.ll` (general `x≠y` funnel
   shift → decline). Each: `CHECK: error{{.*}}<the exact decline string>` +
   `CHECK-NOT: cq_template_<op>`. **Note:** `ctpop`/`smin`/`abs`/`ctlz`/`cttz`/sat
   are **no longer fences** — they ACCEPT via Class-2 Bennett (the draft's
   "ctpop is unforgivable" framing was the minimal-set posture; under the full
   set, sources-live recompute makes them reversible).
2. **RED (per-class / per-shape positives, fail until 5/7 land):** one positive
   fixture per representative shape — `lowering_intrinsic_bswap_i32.ll` (Class-1
   involution, unary), `lowering_intrinsic_fshl_rotation_i32.ll` (Class-1 rotation,
   `x==y`, `_inv`=rotate-back), `lowering_intrinsic_ctpop_i32.ll` (Class-2 unary,
   `fwd`+`unc` only, **no** `_inv`), `lowering_intrinsic_smin_qq_i32.ll` +
   `…_smin_hl_i32.ll` (Class-2 binary, QQ + handle+literal). Each: positive two-RUN
   (FileCheck + verify), `CHECK: call i32 @cq_template_<op>_<W>(`,
   `CHECK-NOT: @llvm.<op>`, plus a `--check-prefix=UNC` RUN asserting the
   `cq_template_<op>_<W>_unc(` twin emits.
3. **RED (R-E adjoint-shape / source-liveness, the deepest fences):**
   - `lowering_intrinsic_bswap_uncompute_shape.ll` — pin the **exact**
     `cq_template_bswap_i32_unc(%out, %src)` arg order and `cqrt_free` count
     (involution additive producer).
   - `lowering_intrinsic_ctpop_sources_live.ll` — pin that the Class-2 `_unc`
     reads the **live source** and that **no source rail is freed** before the
     `_unc` (the recompute-from-live-sources discipline; the silent-collapse class).
   - `lowering_reject_intrinsic_smin_source_clobber.ll` — a Class-2 binary whose
     source has fan-out / is uncomputed early **declines** (linear-lineage bail).
4. **RED** `tools/intrinsic_table.yaml` (NEW sibling) — `version`/`phase` banner,
   a `widths` reference, and one row per curated intrinsic carrying explicit
   `class` (1|2), `reversibility` (`self_inverse` | `rotate_back` |
   `pure_noninjective`), `widths`, `arity`, and `variants`
   (Class-1 `[fwd,inv,unc]`, Class-2 `[fwd,unc]`). Add a **new**
   `gen_templates_test.py` assertion for the sibling surface symbol count
   (computed from the table: Σ over rows of widths×variants×shapes, decl/def
   paired); the `1562` opcode-table assert stays **untouched** (separate artifact).
5. **IMPL generator** — `enumerate_intrinsics(table)` in `gen_templates.py` reusing
   `VARIANT_INFO` and the existing `a1`/`ua1` (unary) + `hl`/`lh`/`qq` (binary)
   shapes — **no `abi_codegen` edit** (the unary `i1`-flag intrinsics ride `hl`).
   Emit into the **separate** `runtime/cq_intrinsic_templates.{h,c}` with its own
   `yaml-sha256` banner; extend `check_mode` to diff the sibling. The emitted
   symbol **must** be `cq_template_<op>_<W>[…]` (not `llvm.*`, not `cqrt_`) so the
   producer-recovery / `_unc` / terminal / invertibility quartet recognize it by
   prefix.
6. **REGEN** `gen_templates.py --output-dir runtime`; `--check` 0 for **both**
   surfaces; wire `cq_intrinsic_templates.c` into `runtime/CMakeLists.txt`'s
   `libcq_templates.a` (committed static artifact, same model as `cq_templates.c`).
   No new hand-written `cqrt_*` (these are pure data templates).
7. **IMPL accept path (two coupled edits, land together):**
   - `TaintPropagation.cpp` before the `kMsgUnknownCallee` at `:437`: accept-skip a
     `CallInst` whose callee is in the curated set by **exact `Intrinsic::ID`
     membership** (a `switch`/set over `Intrinsic::{bswap,bitreverse,fshl,fshr,
     smin,smax,umin,umax,abs,ctpop,ctlz,cttz,uadd_sat,usub_sat,sadd_sat,ssub_sat}`),
     tainted operands are the data args, width `∈` the row's set. For `fshl`/`fshr`
     **require `arg0==arg1`** (rotation) else fall through to decline. **NEVER**
     accept-by-name-prefix `starts_with("llvm.")` (the `cq_theta_evil` hazard,
     comment `:393-398`).
   - new `ir-pass/src/IntrinsicLowering.cpp` (registered like `ArithLowering`):
     enqueue the curated `IntrinsicInst` in `OpcodeLowering.cpp` Phase-1
     (`:209-226`); dispatch in Phase-2 (`:239-249`) → `dataTemplateFn(stem, abiWidth,
     Shape::{Unary|QQ|HL|LH})` → `CreateCall` → RAUW → `promote` — mirror
     `ArithLowering::rewriteUnary`/`rewriteBinary` **exactly** (the **additive
     producer**, sources kept live). Width from the intrinsic **result** type.
8. **VERIFY** `ctest -R ir-pass-lit` — step-2/3 positives green, step-1 fences
   stay declining, no other `lowering_reject_taint_escape_*.ll` flipped.
9. **e2e smokes** (Rule 16 — the only LINK layer; ≥1 per mechanism class):
   `tests/e2e/slice_intrinsic_bswap.c` (`__builtin_bswap32` → `llvm.bswap.i32`,
   Class 1) and `tests/e2e/slice_intrinsic_ctpop.c` (`__builtin_popcount` →
   `llvm.ctpop.i32`, Class 2) — each `cq_theta`-seeded → intrinsic → `cq_measure`.
   Goldens pin the forward producer, the measure, the whole-DAG `_unc` twin, and
   the asserted `cqrt_free` lines (Class-2 golden proves the source stays live
   through its own `_unc`). Add `add_test` blocks + reconfigure.
10. **CLEAR (Rule 13, MANDATORY pre-commit, frozen ABI):** (a) allowlist is exact
    `Intrinsic::ID`, never prefix (grep proves no `starts_with("llvm.")` accept,
    and `fshl`/`fshr` require `x==y`); (b) **per-intrinsic written adjoint proof** —
    Class-1 involution/rotate-back, Class-2 recompute-from-live-sources — matching
    the table `reversibility` column; (c) the excluded families
    (`*.with.overflow`, transcendentals, general funnel shift) decline; (d) **R-E
    adjoint-shape + source-liveness** — the generic `ua1`/`unc` correctly zeros the
    out rail for both an additive involution producer **and** a Class-2 producer
    whose sources stay live, freed exactly once (no dirty-free, no double-free),
    backed by the free-count + sources-live fixtures; (e) `--check` drift-clean,
    `1562` untouched. Record the full curated-set adjoint proofs + the exclusion
    list in `INTRINSIC_TABLE_CLEARANCE.md` + a `bd remember`.

**Hazards → caught by:** over-accept by prefix → exact-ID requirement + the three
exclusion fences + Rule-13(a); general funnel shift admitted → the `x==y`
requirement + `…_funnel_fshl_general.ll`; **Class-2 source freed before `_unc`
(silent collapse / wrong unitary)** → the sources-live + source-clobber fixtures +
Rule-13(d) (this is the full-set's central hazard, replacing the minimal-set's
"never curate ctpop"); wrong-width symbol → per-width positives (result-type
width); verify-clean-but-link-fails → `--check` + the two e2e links; dirty-free /
double-free → additive-producer mandate + free-count fixture + Rule-13(d); count
entanglement → sibling table + separate artifact/SHA.

---

## 8. Done-criteria roll-up (maps to PRD §4)

A 7.1 increment is **complete** only when all hold:
1. Its accept programs lower to the expected `cqrt_*` / `cq_template_*` sequences —
   `opt -verify` clean **and** golden e2e trace diff clean.
2. Every off-pattern shape declines **loudly**, source-located: `*.with.overflow`,
   fp transcendentals, arbitrary-N `_BitInt` **source** seed, vector/aggregate
   operands, a `freeze` re-laundering an Escaped/Measured value (R-B), an f16/i128
   **return**, a narrowing cast, and a non-curated intrinsic (`*.with.overflow`,
   an fp transcendental, or a general `x≠y` funnel shift).
3. (items 4/5) `gen_templates.py --check` SHA-256 drift clean after regen;
   `gen_templates_test.py` count updated (4) / sibling-count added (5).
4. Each accept-predicate ships a mirrored negative `RUN: not … | FileCheck`
   (Rule 12).
5. **Items 4 and 5 are cleared by independent adversarial Rule-13 review before
   commit** (frozen ABI; verify-clean hazards). A and B/C clear Rule-13 because
   they touch named core files even though no-ABI.
6. ≥1 e2e golden smoke per increment (Rule 16) — or, for B only, an
   **explicitly owner-accepted** N/A waiver (R-B/§4 minor).

---

## 9. Open owner-decision flags (carried from the review)

1. **B — escaped/measured `freeze` disposition.** The plan defaults these to
   **decline** (safe). If Rule-13 proves `freeze i32 %h; ret i32 %f` is provably
   identical to the already-accepted `ret %h`, the owner may relax that one shape
   to accept. Default stands until then.
2. **D5 — `_BitInt(N)` round+mask.** **RESOLVED (owner, 2026-06-20): tracked
   pre-freeze follow-up, out of 7.1.** Increment D ships i128 + f16 only;
   `_BitInt(N)` non-ABI N permanently declines within 7.1. The follow-up (full
   masked-op symbol family + `_unc` proof) must land before the Phase-11 freeze.
3. **E — curated set breadth.** **RESOLVED (owner, 2026-06-20): full PRD §2.6
   set** — Class 1 (`bswap`, `bitreverse`, `fshl`/`fshr` rotation) + Class 2
   (`smin`/`smax`/`umin`/`umax`, `abs`, `ctpop`, `ctlz`/`cttz`, `*.sat`), minus
   `*.with.overflow` and fp transcendentals. Each row ships a written adjoint
   proof; the central hazard is now Class-2 source-liveness (§2 R-E), not
   set-size minimalism.

---

*Provenance: this plan was produced by a multi-agent workflow — 9 parallel
subsystem mappers (file:line anchors verified against the live tree
2026-06-19), 5 per-increment TDD drafters, and one adversarial completeness
critic — then reconciled by hand. The §2 resolutions are the critic's
blocker/major findings, re-verified against source (`TaintPropagation.cpp:482-499`,
`EmitInverse.cpp:128-147`) before adoption.*
