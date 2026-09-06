# WI5_SELECT_CLEARANCE — Phase 4.4 tainted-select controlled-XOR copy merge

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
> **For THIS file the banner is a PROMOTION, not a retirement.** The 4.4
> controlled-XOR copy merge this clearance covers is **not** retired — it is the
> mechanism the whole epic moved TO. Since 3qlq Inc 2 (2026-09-06)
> `SelectMergeEmit` is also the **value-arm** emitter: `emitValueRegion` hoists the
> arm's chain, builds a `select`, and calls this cleared emitter VERBATIM, which is
> why the value diamond's stream is byte-identical to the manually pre-hoisted
> `select` twin's (four `cmp` twin gates) and why Inc 2 inherits this clearance
> rather than needing a second one. **Read it as load-bearing, current
> documentation** — with one thing it does not cover: the value path's HOISTED
> chain and the chain-final rail it leaves allocated (PRD §0 E1), which is Inc 2's
> own, not this emitter's.

Rule-13 adversarial clearance trace for the shipped 4.4 emitter
(`SelectClassify.cpp` + `SelectMergeEmit.cpp`). Analytic/trace-level + lowered-IR
reading only — no backend, no statevector simulation (owner decision 2026-06-10).
Companion to the verdict table in `docs/prd/phase-04-swap-route-control/IMPLEMENTATION-4.4.md`
§8.11. Mirrors the 4.3 `WI3_NESTED_TRACE.md` precedent. **Verdict: CLEARED on all
five lenses; 0 confirmed defects; 0 silent miscompiles. Shipped default stays
conservative** (classical/basis-integer operands accept; coherent + fp-data decline).

The runtime semantics (trace-only printf, `cq_runtime.c`): the merge primitive is a
controlled CNOT-copy involution
`cqrt_copy_<W>_controlled(f, src, dst): dst ^= (f==1 ? src : 0)`, and `cqrt_x(f)` is a
self-inverse bit-flip on the flag. `%out` is freshly allocated to `|0⟩`.

## 1. The ¬flag bracket-order two-row trace (§8.1 — the load-bearing, verify-clean-invisible hazard)

The emitter stream (`SelectMergeEmit.cpp:140,146,148,149`) is
`copy_c(f,a,out); x(f); copy_c(f,b,out); x(f)` — the `cqrt_x` brackets **only** the
second copy. With `out=|0⟩`, `a=TrueValue`, `b=FalseValue`:

| original f | copy_c(f,a,out) | x(f)→f' | copy_c(f',b,out) | x(f')→f | **out** |
|---|---|---|---|---|---|
| **1** | out=0^a=a | f'=0 | f'=0 ⇒ no write, out=a | f=1 | **a** ✓ |
| **0** | f=0 ⇒ no write, out=0 | f'=1 | out=0^b=b | f=0 | **b** ✓ |

⇒ `out = f ? a : b`, **exactly one write per basis branch**, flag restored.

**The same-multiset mis-bracket** `x(f); copy_c(f,a,out); copy_c(f,b,out); x(f)`
(identical symbol multiset {2×copy, 2×x, …} — invisible to a count-only CHECK):

| original f | x(f)→f' | copy_c(f',a,out) | copy_c(f',b,out) | x→f | **out** |
|---|---|---|---|---|---|
| **1** | f'=0 | no write | no write | f=1 | **0** ✗ (want a) |
| **0** | f'=1 | out=a | out=a^b | f=0 | **a^b** ✗ (want b; double-write) |

⇒ `out = f ? 0 : (a^b)` — a wrong unitary with an identical multiset. Caught only by
an **ordered** check. The §5a `ORD` FileCheck pins `copy→x→copy→x` (rejects all six
same-multiset misorders). The WI-5 adversarial refutation additionally found a
**stray-x** variant `x;copy;x;copy;x` (3 x's, `out=f?b:a` — swapped operands + dirty
flag) that *passed* `ORD` (which is count-blind); closed by the new
`XCT-COUNT-2`/`XCT-NOT cqrt_x` pin in `control_swap_select_qc.ll`, plus the e2e
byte-diff (`tests/e2e/slice_control_select.expected.log`) which pins every line
positionally.

## 2. The entangled-flag joint-state walk (§8.3 — coherent correctness for a superposed condition)

The flag is **not** an independent basis qubit — it is minted from `f = icmp(q,k)`,
so it is entangled with the superposed condition register `q`. The question: does that
entanglement corrupt the basis copy? Walk `|q⟩|f⟩|out⟩` for the canonical `(q>5)?q:x`
(`q = Σⱼ αⱼ|j⟩`, `bⱼ = [j>5]`, `x₀` the classical false operand):

```
mint  f=[j>5]:    Σⱼ αⱼ |j⟩ |bⱼ⟩ |0⟩
copy_c(f,q,out):  Σⱼ αⱼ |j⟩ |bⱼ⟩ |bⱼ·j⟩         ; out=j iff j>5, else 0
x(f):             Σⱼ αⱼ |j⟩ |¬bⱼ⟩ |…⟩
copy_c(f,x₀,out): Σⱼ αⱼ |j⟩ |¬bⱼ⟩ |rⱼ⟩          ; rⱼ = (j>5)?j:x₀ — exactly ONE copy fires per branch
x(f):             Σⱼ αⱼ |j⟩ |bⱼ⟩ |rⱼ⟩
icmp_inv(q,k):    Σⱼ αⱼ |j⟩ |0⟩ |rⱼ⟩            ; f cleanly back to |0⟩
```

`bⱼ` and `¬bⱼ` are complementary per branch ⇒ on each `|j⟩` exactly one of the two
controlled copies writes `out` — **no double-write, no XOR cancellation**. `x(f)` is an
*uncontrolled* flip applied uniformly across all branches, so it commutes with the
superposition (it just relabels `bⱼ↔¬bⱼ` everywhere). The flag is reversibly uncomputed
by the exact inverse of its mint (`icmp`/`icmp_inv` over the **untouched** `q`),
returning it to `|0⟩` — so `cqrt_free(f)` is a valid reset, **not** a projective
collapse of an entangled rail (Rule 6/8 satisfied). `out` ends correlated with `q` as
`(q>5)?q:x`. For a `cq_theta` (Ry, real-amplitude) operand the result `Σ αⱼ|j⟩|rⱼ⟩` has
the correct marginal `P(out=v)=Σ_{rⱼ=v}|αⱼ|²` — the right `c?a:b` distribution. There is
**no relative phase to lose**; dephasing requires an `Rz`/`cq_phi` relative phase, which
gate 5 (`operandCarriesPhase` backward + `hasCoherentDownstreamUse` forward) declines.
Verified for `(q>5)?q:q+1` (out-of-place add handle, `q` untouched) and inverted-polarity
`(q==5)?x:q` (operands correctly mapped to flag branches).

## 3. Lens verdicts (independently second-reviewed)

| Lens | Verdict |
|---|---|
| 1. ¬flag bracket-order | CLEARED (§1; `ORD`+`XCT` pin order+count; e2e pins positions) |
| 2. angle-gate airtightness | CLEARED (`selReachesRotationArg1` fires at detection; value-changing ops backstopped at L64/L110; `rotation angle` fires on real `-O1`) |
| 3. coherent-operand boundary | CLEARED (§2; basis-theta accept correct; `cq_phi`-lineage/downstream-rotation decline; no over-accept leak across 20+ hostile probes) |
| 4. emitter-fidelity | CLEARED (real IR == §4/§5a/§5b/§5c; `ret` emits no measure; polarity maps true→f=1) |
| 5. frees/width/ChainWalk | CLEARED (one free; i8 width pre-RAUW; `ChainWalk.cpp` unchanged — copy counts as consumer, entangled rail left allocated) |

**Residuals (non-blocking, no shipped defect):** the closed lit-count gap (§1); and the
documented cross-module couplings (angle-gate ↔ L64/L110 backstops; gate-5 ↔
`RotationLowering` classical-`cq_phi` deletion, now noted in the gate-5 comment;
single-free ↔ `isTerminalHandle` name-prefix classification) — each intact at HEAD,
flagged for re-review if the coupled module changes.
