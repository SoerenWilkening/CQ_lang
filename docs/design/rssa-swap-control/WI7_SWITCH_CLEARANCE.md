# WI7_SWITCH_CLEARANCE — Phase 4.5 tainted-`switch` swap-route clearance

> ⚠⚠ **THE SWAP ROUTE IS RETIRED (dated 2026-09-06, bd `test_C_libtooling-3qlq`,
> Increments 1 + 2, both LANDED on `main`).** This directory is the swap-route
> **design record** and is deliberately left as written — its arguments and its
> statevector reasoning are still quoted, and the route remains the correctness
> ORACLE the replacements were checked against. **What ships instead:**
> a **PHASE** arm is the register-free **KICKBACK** — `void cq_phi(double θ)`, the
> ordinary compare mint, `cqrt_rz_i1(f, θ)` **UNCONTROLLED** on the flag, the
> ordinary `_unc` strip, `cqrt_free(f)`, **no gate on the data register at all**
> (the motivating defect: `cqrt_rz_<W>` is TENSORED, so a routed or controlled
> W-bit Rz marks `(−1)^popcount(target)` and can never mark `|0…0⟩` — every shipped
> Grover golden was the identity on `q`; **`Rz|0⟩ = |0⟩` is RETIRED as a
> load-bearing argument**, and every "zero controlled gates" here is a statement
> about the ROUTE). A **VALUE** arm is the **CONTROLLED-COPY MERGE** — hoist the
> arm's pure chain into the pred so it runs unconditionally on the ORIGINAL
> register, mint the flag, two X-bracketed `cqrt_copy_<W>_controlled` into a fresh
> `|0⟩` rail, the chain's `_unc` by the ordinary whole-DAG spine, strip, ONE free —
> **no work rail, no route, no reverse-play in the emitter**, with the chain-final
> rail left ALLOCATED and ENTANGLED (a leak, never a dirty free — PRD §0 E1, and
> why bd `3qlq.5` is unsound by default). **`cqrt_cswap` therefore has exactly ONE
> minter left: the 7.2 `AbortParkEmit`** (MEASURED — `grep -rn 'emitRoute('
> ir-pass/src ir-pass/include` = the definition, the declaration and one call site,
> `AbortParkEmit.cpp:396`; 1 of 319 committed goldens contains one). What SURVIVES
> is the principle, not the primitive: split and join share one live condition and
> the join must be the split's undo; arm bodies still run verbatim and
> uncontrolled; adjoints are still DERIVED; and the §3c clobber decline is
> unchanged. Design of record:
> `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (§0 ERRATA first)
> + `RETIRE_SWAP_ROUTE_INC{1,2}_NOTES.md`.
>
> **For THIS file, per accept shape:** (A) homogeneous **phase** no longer routes —
> `SwitchRouteEmit`'s phase path mints a kickback gate on the eq-flag (3qlq Inc 1);
> (B) homogeneous **value** no longer routes either — since 3qlq Inc 2 it is shape
> (C)'s own preload + XOR-delta over a NON-constant base (`cqrt_copy_<W>(p, out)`
> preloaded, then per case a hoisted chain, a Q+Q `xor` delta, an eq-flag mint and
> one `cqrt_copy_<W>_controlled`, each chain uncomputed after; each delta and each
> chain final left allocated and entangled), so the §8.5 cswap-arg0 seam this
> document navigates HAS NO SUBJECT there any more; (C) the all-`ConstantInt`
> **data-mux** and (D) the **eq-folded diamond** clause are UNCHANGED. The G0–G11
> prove-or-decline ladder, the §5 const-fold re-anchor and the whole decline matrix
> are UNCHANGED and still load-bearing.

Rule-13 adversarial clearance trace for the shipped 4.5 tainted-`switch` lowering
(`SwitchClassify.cpp` + `SwitchArmProve.cpp` + `SwitchRouteEmit.cpp` (phase) +
`SwitchValueEmit.cpp` (value) + `SwitchDataMuxEmit.cpp` (data-mux) +
`EqFoldArm.cpp` (the eq-folded `br` diamond clause) + the `ControlDetect`/
`SwapRouteEmit`/`ArmClassify` thin wiring). Analytic/trace-level + lowered-IR
reading only — no backend, no statevector simulation (owner decision 2026-06-10).
Companion to the §8.11 verdict table in
`docs/prd/phase-04-swap-route-control/IMPLEMENTATION-4.5.md`. Mirrors the 4.4
`WI5_SELECT_CLEARANCE.md` and 4.3 `WI3_NESTED_TRACE.md` precedents.

**Verdict: CLEARED on all 11 §8 lenses + both residual coherence boundaries
(value-arm N-way; data-mux N-ary coherent-operand) + 3 over-accept hunters; 16
independent adversarial reviewers, 0 confirmed defects, 0 silent miscompiles, 0
uncertain.** Each reviewer extracted the **real lowered IR** (`opt -passes=
cq-lowering` on the live plugin, plus the full clang→opt→link→run e2e pipeline)
and actively tried to construct a verify-clean wrong unitary in its lens; every
attempt either declined loudly pre-mutation or was structurally impossible. The
shipped default stays conservative — the four ACCEPT shapes (homogeneous phase /
homogeneous value / all-`ConstantInt` data-mux / eq-folded `br` diamond) lower to
their pinned §4 streams; **every** other tainted-`switch` shape declines loudly
(the §0/§22 decline matrix).

The runtime semantics (trace-only `printf`, `cq_runtime.c`): `cqrt_cswap(f,a,b)`
is a Fredkin route (swap `a↔b` iff `f==1`), self-inverse; `cqrt_rz_<W>(h,θ)` a
diagonal phase (reads the angle, `Rz|0⟩=|0⟩`); `cqrt_copy_<W>(s,d)` an
uncontrolled CNOT-copy `d^=s`; `cqrt_copy_<W>_controlled(f,s,d): d^=(f?s:0)`;
`cqrt_alloc_<W>(v)` mints a fresh handle initialised to `v`; `cqrt_free` a reset
(valid only on a proven-`|0⟩` rail). Eq-flags `f_i=(q==c_i)` are minted by
`cq_template_icmp_eq_<W>_hl(q,c_i)` and stripped by the `_hl_inv` twin over the
**untouched** `q`. The golden e2e trace is the contract.

---

## 0. The four ACCEPT streams (real lowered IR, extracted)

| Class | Pinned stream (per content case `i`, then once) |
|---|---|
| **Phase** (`SwitchRouteEmit`) | `icmp_eq_<W>_hl(q,c_i)`=f_i → `alloc(0)`=rail → `cswap(f_i,q,rail)` → `rz_<W>(rail,θ_i)` *(ARG-1 angle only)* → `cswap(f_i,q,rail)` → `free(rail)` → `icmp_eq_<W>_hl_inv(q,c_i)` → `free(f_i)`; once: RAUW merge→`q`, `measure(q)`. **Zero** surviving `cq_phi`/`phi i32`. |
| **Value** (`SwitchValueEmit`) | fwd: f_i → `alloc(0)`=r_i → `cswap(f_i,p,r_i)` → chain verbatim `_hl/_lh` on r_i → `cswap(f_i,p,op_i)`; once: **one** `copy_<W>(p,out)` (after all route-backs, before any R†); LIFO R†: `cswap(f_i,p,op_i)` · body-chain `_inv` (via `emitInverseChain`, **body only**) · `cswap(f_i,p,r†_i)`; rail frees on final threaded handles + flag strip/free; RAUW merge→`out`, `measure(out)`. `p` and `out` **never** freed. |
| **Data-mux** (`SwitchDataMuxEmit`) | once: `alloc(v_d)`=out (preload); per case: f_i → `alloc(v_i⊕v_d)`=d_i → `copy_<W>_controlled(f_i,d_i,out)`; then per case `icmp_eq_<W>_hl_inv(q,c_i)` → `free(f_i)`; RAUW merge→`out`, `measure(out)`. **No** cswap, **no** `cqrt_x` (no ¬-bracket), `out`/`d_i` never freed. |
| **Eq-fold diamond** (`EqFoldArm`→`emitRegion`) | the `q==k` `br` diamond reuses the 4.1/4.2 `emitRegion` **verbatim** after `tryEqFoldArm` re-anchors `Routed`=the icmp's tainted handle `H` (D1–D7). Lowered IR routes `H`, **not** the folded const `k`, into the rails. |

---

## 1. Lens-by-lens verdicts (16 independent adversarial reviewers)

### L1 — const-fold re-anchor (§5/§6.2) · CLEARED
The §5 BLOCKER: `clang -O1` folds each phase arm gate to `cq_phi(i32 c_i, θ_i)`
(arg-0 = the case literal). If it survives to `RotationLowering`
(`CQLoweringPass.cpp:110`) the gate has an **untainted** arg-0 → no `rz` →
`replaceAllUsesWith(arg-0)` RAUWs the merge to the *constant* `c_i` → the merge
degenerates into a verify-clean **wrong data-mux** (`RotationLowering.cpp:197/207`
confirmed to be exactly this hazard). **Foreclosed** by `emitSwitchPhaseRegion`
(`SwitchRouteEmit.cpp:200-206`): RAUW merge→`q`, erase merge, then
`for (Phi : reverse(AllPhis)) { scrubTaint(Phi); erase; }`; `scrubTaint`
(`:65-73`) removes the gate from `taint.PhiCalls` via `std::remove`, so
`lowerRotations` never re-walks it. The eq-fold path (`emitRegion`,
`SwapRouteEmit.cpp:644-650`) does the identical scrub. Both run in
`lowerControlRegions` (`CQLoweringPass.cpp:84`), strictly **before**
`lowerRotations` (`:110`). Real IR: `control_swap_switch_phase.ll` (N=3) and the
**real e2e** (clang folds `cq_phi_si32(i32 0, double 0.1)` etc.) both lower to
`cqrt_rz_i32(rail, 0.1/0.2/0.3)` — the **arg-1 angles, not** the literals 0/1/2 —
with **zero** surviving `cq_phi`, verify-clean, golden-diff clean. *Refutation:*
six escape vectors (fan-out, passthrough-arm-with-a-gate, a gate the `AllPhis`
walk misses, a phi left in `PhiCalls`, an external gate user, two phis on one
gate) — each declined loudly (`impure phase arm` / `control flow` / multi-phi
`control flow`) or was structurally impossible.

### L2 — N-way order/multiset (§6.3) · CLEARED
The §4 streams have **identical symbol multisets** across many wrong orderings
(the 4.4 precedent: `copy;x;copy;x` vs `x;copy;copy;x` — same multiset, wrong
unitary). The default ordered `CHECK` prefix pins every step by **SSA-variable
capture** (`%[[F0]]`, `%[[R0]]`, `%[[OP0]]`, `%[[D0]]`), so a misordered call must
reference the wrong-case minted handle and fails. *Refutation:* 9 hand-built
same-multiset reorders (cross-case angle swap, rz-before-route-in, drop+dup a
route, FIFO reverse-play, copy-out moved into R†, swapped ¬-brackets,
cross-paired XOR-deltas, swapped flag controls, preload-after-copies) — **all 9
rejected** by the SSA-captured `CHECK` (the count-only `CNT`/`XCT` prefixes alone
passed several — they correctly *supplement*, never *substitute*). The value LIFO
reverse-play is the verified exact forward-order adjoint and is order-pinned.
**Residual (now closed):** a stray `cqrt_x` injected *before* the `cqrt_measure`
CHECK slipped the default prefix (its `CHECK-NOT` block scans only post-measure);
it was caught only by the e2e byte-diff. **Closed at the lit layer in WI-7** by a
whole-output `XCT-NOT: cqrt_x` (value) and `XCT-NOT: cqrt_x`/`cqrt_cswap`
(data-mux) — the 4.4 `control_swap_select_qc.ll` XCT precedent.

### L3 — C1 multi-phi kill-shot · CLEARED
`soleSwitchMergePhi` (`SwitchClassify.cpp:100-108`) returns null on the **second**
`PHINode` in iteration order, **content-agnostic** — never inspecting its value,
uses, or shape. Null → `diagnoseUnderControl(SI,"control flow")` at `:209`,
**before** the region is pushed (`:371`). The emitters consume the single captured
`S.Merge` and never re-scan `MergeBB->phis()`, and `flattenSwitchRegion`
(`RegionFlatten.cpp:207/218`) assumes the single phi was erased upstream — so a
surviving 2nd phi *would* dangle, but that path is unreachable for multi-phi.
*Refutation:* six 2+-phi switches (identity 2nd phi, ret-only 2nd phi,
sibling-tainted 2nd phi, swapped phi order, two valid content phis, three phis) —
**all** declined with the exact string, `opt` exit 1.

### L4 — C2 value-anchor kill-shot · CLEARED
The value routed base must be `p` = the merge straight-through incoming with
`p != q`. Enforced at **three** consistent layers on identical SSA identities (no
RAUW between detect and emit — both precede `lowerRotations`):
`proveSwitchValue:198` (`P==getCondition()` reject), per-arm `Chain.Base!=P:273`,
and emit `SwitchValueEmit.cpp:125` (`P==Q` bail). `diagonalAliasHit`
(`ArmClassify.cpp:220`) walks `p`'s `cq_phi` arg-0 closure against
`condProvenance(q)` so a **diagonal alias** of `q` (a `cq_phi(q,·)` sibling — SSA-
distinct but same wire) cannot be the routed base. Real IR: `q=%h`, `p=%h7` are
distinct allocs; eq-flags read `%h` only; all cswaps route `%h7`, never `%h`;
copy-out is `copy(%h7,%out)`; `%h`/`%h7`/`%out` never freed; verify-clean +
golden-diff clean. *Refutation:* five probes (routed base `cq_phi(q)`; arms
bottoming at distinct `p`/`q`; arm rooted at `cq_phi(q)`; arg-1-angle-exclusion
slip; the §3c clobber `q=cq_phi(p)`) — all declined (`control flow` /
`value-arm swap-route` / `arm rewrites a condition operand`). **Residual (now
fixed):** the `R.Condition` comment ("the scrutinee = the routed base (§4A)") was
phase-only and misleading for value/data-mux — corrected in `SwitchClassify.cpp`.

### L5 — C4 grouped-case kill-shot · CLEARED
G9 (`SwitchClassify.cpp:166-170`) counts case values per successor block and
declines `control flow` on the second (`++SuccValueCount[Succ] >= 2`) — the
**first** loop in `classifySwitchRegion`, pre-empting any accepting recovery. If
grouping reached emit, the eq-flag minted from `Arm.Values.front()` would route
only on `q==first` and silently drop the rest. *Refutation:* four grouped shapes
(3-grouped; grouped+valid-sibling; grouped-via-shared-subblock; default==case) —
all declined loudly (G9, or `resolveArm`'s off-pattern decline for the shared
sub-block). **Latent footgun (documented, not a live defect):** `SwitchArm.Values`
is a `SmallVector<…,2>` intended for an unimplemented OR-of-flags grouped
lowering; if a future WI implements grouped routing it **must remove G9 first** —
recommend a defensive `assert(Arm.Values.size()==1)` at each `.front()` site at
that time.

### L6 — C5 non-empty-default kill-shot · CLEARED
`DefaultDirect = (SI->getDefaultDest() == MergeBB)` (`SwitchClassify.cpp:201`) — an
**exact block-identity** test, not reachability; `MergeBB` is recovered purely
from `SI->cases()`, never the default edge; declines `control flow` otherwise,
**before** the `StraightThrough` index lookup (`:213`). *Refutation:* five probes
(default through an empty intermediate block; through an intermediate-then-gate
block; default-is-a-gate-arm; default==merge but a folded `cq_phi(q)` on the
straight edge) — all declined (DefaultDirect, plus the defense-in-depth
foreign-pred guard `:256-263`, `proveSwitchPhase:147`, and the G10 unowned-use
scan `:334-345`). The accept baseline is **not** over-broad (clean phase switch
lowers correctly).

### L7 — G8 MUX-EXCH no-cloning · CLEARED
Distinct tainted handles per case (a quantum multiplexer; XOR-delta not
const-computable; freeing superposed sources needs `cswap`, Rule 8) decline
`control flow`. `caseArmClass` routes a `cq_theta`/`cq_phi` leaf to **Phase**, and
`proveSwitchPhase` rejects it because `walkPhaseSpine` bottoms at the *handle*, not
a `ConstantInt` (`!BaseConst`, `:166`); `proveSwitchDataMux` requires every
incoming `isa<ConstantInt>` (`:310-318`). The width guard
`BaseConst->getType() != C.Value->getType()` **precedes** the `getValue()` APInt
compare via `||` short-circuit (`:166-167`) — no width-divergent over-accept, no
asserts crash. Real IR: `control_swap_reject_switch_muxexch.ll` retains a genuine
`switch i32`, declines `control flow`, emits **zero** cswap/copy/free.
*Refutation:* seven probes (distinct theta incomings; distinct value bases; Q+Q
link; mixed const+tainted; derived `cq_phi` over an independent rail; wrong-literal
fold; tainted straight-through) — all declined.

### L8 — cswap-arg0 seam (§6.6/§8.5, verify-clean-invisible) · CLEARED
`emitInverseChain` threads the live handle into `Args[0]`, which for `cqrt_cswap`
is the **flag** slot — a rail handle there is a wrong unitary. `emitSwitchValue
Region` feeds the inverter **only** `CS.Fwd` (the `rewriteBinary`-minted
`cq_template_*` body calls, `:221`) and brackets the route cswaps itself via
`emitRoute` (`:249/254`). Real IR (chain-len-1 fixture **and** a /tmp 3-link/2-link
probe): **every** `cqrt_cswap` arg-0 is an `icmp_eq` flag handle; the entire
`_inv` stream is `cq_template_*_inv` with threaded handles in the **data** slot
only; the threaded `RailFinal` lands in cswap **arg-2** (data), never arg-0. All
`emitInverseChain` callers audited — none feed route cswaps. *Refutation:* both
length regimes (where a threading off-by-one would most plausibly drift a rail
into a flag slot) verified clean.

### L9 — uncompute non-selection (§6.7) · CLEARED
`%out` (the fresh `cqrt_alloc` holding the answer) and the untainted XOR-delta
scratch `%d_i` must never become uncompute terminals (that would reverse-play +
`cqrt_free` them = double-free + a hidden measurement of the result).
`isTerminalHandle` (`ChainWalk.cpp:84-108`) returns false at the first non-benign
`CallInst` user (only in-place `ry`/`rz` and measure-sinks are benign); `%out`'s
`cqrt_copy[_controlled]` consumer and `p`'s `cqrt_cswap` consumer match neither →
both rejected. `%d_i` is **never** inserted into `taint.Tainted`
(`SwitchDataMuxEmit.cpp:176-179`) so `uncompute` never even considers it. Real IR:
data-mux frees **exactly** the 2 flags; value frees **exactly** 2 rails + 2 flags;
`%out`/`%d_i`/`p`/`q` never freed; `uncompute` (runs last) adds nothing.
*Refutation:* four probes — crucially **removing the measure entirely** (result
feeds only `ret`): `isTerminalHandle(%out)` stays false **without** a measure user
(the copy consumer alone suffices), so the no-measure escape path is also safe.

### L10 — jump-table pre-emption (§6.8) · CLEARED
A many-case data switch that `clang -O1` folds to a `@switch.table` `gep`/`load`
declines **pre-detection** at `declineTaintEscapes` (`CQLoweringPass.cpp:64`,
**before** detection at `:83`) with `tainted value reaches an unsupported
instruction` (`kMsgOther`, `TaintPropagation.cpp:330-331`) — `propagate` taints
the `zext` index → the `gep` → escape. Real IR: the fixture genuinely contains the
folded table form and declines `opt` exit 1; `control_swap_switch_datamux.ll`
retains a genuine `switch i32` (the data-mux path exercises a real switch, not a
table). `normalizeJumpTableAngle` confirmed **not revived** (three greps, zero
hits). *Refutation:* four attacks incl. **real C at `-O1`** (a 4-case folds to a
`select` → the already-cleared 4.4 path; an 8-case folds to a real table → caught
by the escape guard), plus a hybrid surviving-switch+tainted-gep (the full
all-blocks escape walk completes before any control detection). Even
counterfactually past the escape guard, `proveSwitchDataMux`'s all-`ConstantInt` +
empty-arm + sink-or-ret triple defense rejects a `load`-result incoming.

### L11 — impure-arm / G10-scrutinee declines · CLEARED
All six fixtures fire their exact v1-floor strings: `impure phase arm` /
`impure value arm` / `condition predates a non-diagonal gate` / `condition data
use neither escaped nor measured` / `control flow` (passthrough-dirty / datamux-
dirtyarm). `armPureSpine`/`valuePureChain`/the all-class empty-arm scans + the
**uniform passthrough-arm purity scan** (`SwitchClassify.cpp:276-280`) partition
every arm-with-a-block exhaustively, so a stray side-effecting op (incl. a
**vanishing user measurement** on a sibling handle, Rule 5) cannot survive a
flatten. *Refutation:* the G10 scrutinee allowlist (`isCallToPrefix("cq_measure_")`,
`:341`) was probed with `cq_measure_evil`/`cq_measure_si128` spoof sinks — both
declined at `declineTaintEscapes` (the scrutinee is **always** tainted, so the
escape guard pre-filters every unknown callee **before** G10 runs, making the
prefix check equivalent to membership on a tainted operand). The asymmetry vs the
data-mux **exact-`MeasureCalls`-membership** sink test (an *untainted* merge has
no escape pre-filter) is sound and documented.

### RA — value-arm method-B N-way coherent boundary (open-Q-7) · CLEARED
For `N>2` over a **superposed** scrutinee `q = Σⱼ αⱼ|j⟩`: the genuinely-new
condition (absent at N=2) is **multiple off-case rails**. Each off-case rail's
forward chain and its `_inv` reverse-play are **both uncontrolled/branch-
independent**, so the rail sees exactly `R∘R† = identity` and returns to `|0⟩` on
**every** basis branch `|j⟩` — provably `|0⟩` at free, **not** entangled with `q`.
Eq-flags are mutually exclusive (≤1 fires per `|j⟩`), so the matched case's
`route-in·R·route-back` settles `p` and its LIFO adjoint restores `p` to `p₀`; the
**one** `copy(p,out)` reads `p` after all route-backs (before any R†). The joint
state factors as `(Σⱼ αⱼ|j⟩_q |g_j(v)⟩_out) ⊗ |v⟩_p ⊗ |0…0⟩_anc` — `out` is the
correct `c?a:b:…` mux entangled with `q`, all ancillas factor out, no dirty free.
*Refutation:* four probes (dirty off-rail free; double-settle `p`;
out-entangled-with-leftover-rail; §8.5 flag-slot contamination at the longer LIFO)
— all foreclosed; **no `N>2`-specific failure mode beyond the `N=2` trace.**

### RB — data-mux N-ary coherent-operand gate (the §16.7 select boundary, N-ary) · CLEARED
A coherent / `Ry`-phase **data operand** must ride the conservative decline (the
basis XOR-delta recipe would dephase a superposition). `caseArmClass` routes any
**tainted** (non-`ConstantInt`) incoming to **Phase/Value**, never DataMux, and
`proveSwitchDataMux` independently requires every incoming `isa<ConstantInt>` —
belt-and-suspenders. The **untainted** `%out` (all-`ConstantInt` incomings ⇒ never
seen by forward taint, no `declineTaintedAngle` backstop at `:110`) is protected by
the **carrier-independent sink-or-ret gate** (`SwitchArmProve.cpp:363-373`): every
`S.Merge` user must be a `ret` or an **exact-`MeasureCalls`-membership** sink —
closing the gap where the merge reaches a rotation arg-1 angle through an
`icmp`/`store`/`call`/`select-condition` carrier that G3
(`mergeReachesRotationArg1`) deliberately cannot cross. *Refutation:* six probes
(angle via store/load/opaque-call/select-condition; tainted straight-through;
mixed const+theta; `cq_phi`-rail arm; fan-out to a real sink + a G3-blind angle;
merge into a `cq_phi` arg-0 handle) — all declined. The `cq_measure_si128`/
`cq_measure_evil` prefix-spoof is defeated by exact membership.

### H1/H2/H3 — over-accept hunters (phase / value / data-mux+eq-fold seams) · CLEARED
Three reviewers tried to **author new accept fixtures that miscompile**, beyond the
11 lenses. **H1 (phase):** stacked phase gates (both angles replayed, §5 scrub held
at depth-N), zero-angle gate, correct-`i1`-suffix source — all accept correctly,
zero surviving `cq_phi`, frees == rails+flags exactly. **H2 (value):** 10 probes
(Q+Q via cast / select / deep-in-chain / self-add; scrutinee-as-operand; fan-out;
sibling theta on `p`'s wire; §3c diagonal-alias clobber; width traps incl. `_lh`
non-commutative threading) — all declined or lowered with uniform widths; could
not escape `Taint.Tainted` for a second quantum operand nor slip a rail into a
cswap flag slot. **H3 (data-mux + eq-fold):** DM angle paths G3 can't cross
(store/load/opaque-call/select-condition) all hit the sink-or-ret gate; spoof
`cq_measure_si128` defeated by exact membership; eq-fold cross-handle (D3),
ordering-compare (D1), tainted-spine-angle (D7), width-mismatch (D4, no APInt
assert) all declined. The only 0-error accepts (i8-scrutinee/i32-merge mixed-width
data-mux; coherent `Ry` scrutinee) are **correct**, not miscompiles.

---

## 2. §8.11 Clearance verdict table

| Lens | Verdict | Key evidence |
|---|---|---|
| Re-anchor (§5) | **CLEARED** | scrub+erase + `PhiCalls` removal precede `lowerRotations`; `CHECK-NOT: cq_phi` + real-e2e golden clean; 6 escape vectors declined |
| N-way order/multiset | **CLEARED** | SSA-captured `CHECK` rejects all 9 same-multiset reorders; whole-output `XCT-NOT: cqrt_x` added (lit gap closed) |
| C1 multi-phi | **CLEARED** | `soleSwitchMergePhi` null-on-2nd content-agnostic, declines pre-push; 6 probes declined |
| C2 value-anchor | **CLEARED** | `p != q` at 3 layers + `diagonalAliasHit` wire-identity; 5 probes declined; stale §4A comment fixed |
| C4 grouped-case | **CLEARED** | G9 `>=2`-per-successor pre-emptive decline; 4 probes declined |
| C5 non-empty-default | **CLEARED** | `DefaultDirect` exact block-identity + 3 defense-in-depth layers; 5 probes declined |
| G8 MUX-EXCH | **CLEARED** | `!BaseConst`/all-`ConstantInt` reject; input retains `switch i32`; 7 probes declined |
| cswap-arg0 seam | **CLEARED** | body-chain-only R†; every cswap arg-0 a flag at len-1/len-3/3-case |
| Uncompute non-selection | **CLEARED** | `isTerminalHandle` rejects `%out`/`p` even with no measure user; `%d_i` untainted; exact free counts |
| Jump-table pre-emption | **CLEARED** | `kMsgOther` at `:64` pre-detection; datamux retains `switch i32`; `normalizeJumpTableAngle` not revived |
| Impure-arm / G10 scrutinee | **CLEARED** | all 6 v1-floor strings; passthrough/empty-arm scans exhaustive; scrutinee-spoof pre-filtered by escape guard |
| **RA** value-arm N-way coherent | **CLEARED** | off-rails `R∘R†=id`→`\|0⟩` per branch; `out` correct mux, no dirty free; no `N>2` failure mode |
| **RB** data-mux N-ary coherent-operand | **CLEARED** | tainted incoming never DataMux; carrier-independent exact-membership sink-or-ret gate closes the G3 carrier gap |
| H1/H2/H3 over-accept hunters | **CLEARED** | ~25 novel accept-fixtures authored; every miscompile attempt declined or lowered correctly |

---

## 3. Residuals (non-blocking; no shipped defect)

- **Closed in WI-7:** the lit-robustness gap (whole-output `XCT-NOT: cqrt_x`
  added to `control_swap_switch_value.ll` + `…_datamux.ll`; was e2e-only — L2);
  the stale `R.Condition` §4A comment (clarified — L4).
- **Documented latent couplings (re-verify if the named module changes):**
  (1) the re-anchor scrub is **duplicated** in `SwitchRouteEmit::scrubTaint` and
  `SwapRouteEmit::scrubTaint` (house style) — a future drift in either copy needs
  re-verification. (2) `flattenSwitchRegion`'s single-phi assumption is backed
  **only** by `soleSwitchMergePhi`'s upstream decline — a new switch-detection
  entrypoint that bypasses it would reintroduce the dangle (L3). (3) G9's
  block-pointer counting does not see grouping through intermediate blocks (today
  caught by `resolveArm`); a future grouped-routing WI must remove G9 and add
  `assert(Arm.Values.size()==1)` at each `.front()` site (L5). (4) the value-arm
  coherent-correctness rests on `cq_template_<op>_hl` denoting an **in-place**
  reversible gate; a future fresh-qubit backend realization would break method-B
  reverse-play (RA). (5) the data-mux sink-or-ret gate's safety rests on
  `Taint.MeasureCalls` being **exact** recognized-intrinsic membership — any move
  to a prefix/unrecognized-width match flips the spoof-sink decline to an
  over-accept (RB/L11). (6) all switch-class wire-disjointness rests on **no RAUW
  between detect and emit** (both precede `lowerRotations`); a reorder would
  require re-running `diagonalAliasHit` at emit (L4).

Each coupling is intact at HEAD and flagged for re-review if the named module is
touched. **No silent miscompile, no regression, no over-accept** across the 16
reviewers and ~50 adversarial probe fixtures.
