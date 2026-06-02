# Phase 4 PRD — IR pass: controlled-form lowering

Phase-specific design decisions, scope, and done criteria for recovering
quantum-controlled regions **structurally** from tainted branch
conditions — no user-emitted region marker — and lowering the ops inside
those regions to their controlled template variants. This is a lean PRD:
it memorializes the decisions resolved in PRD-discovery (including a
compiled catalog of what `clang -O1` actually emits for a quantum `if`)
so the rationale survives between sessions; the implementation plan
(module layout, fixture generation, commit shape) lands later as
`IMPLEMENTATION.md` alongside this file.

Companion documents:
- [`ROADMAP.md`](../../../ROADMAP.md) §Phase 4 — phase scope and place in
  the sequence; the Phase 4.1 deferral note.
- [`docs/backend.md`](../../backend.md) §8 (tainted-branch identification,
  post-dominator shadow, controlled-variant substitution), §11.4 (gate
  primitives incl. the `cqrt_toffoli` placeholder).
- [`docs/quantum-classical-handling.md`](../../quantum-classical-handling.md)
  §4.4 (control-flow taint; the φ-at-merge promotion rule).
- [`docs/frontend.md`](../../frontend.md) §8 (Stage 1 / 2 / 3 pipeline).
- [`docs/prd/phase-03-opcode-lowering/PRD.md`](../phase-03-opcode-lowering/PRD.md)
  §2.8 — the Phase 3 / Phase 4 seam this phase reopens (compares feeding
  `br i1`/`select i1` were left untouched *for* Phase 4).

---

## Status (2026-06-02)

| Sub-phase | Scope | State |
|---|---|---|
| **Phase 4 core** (WP0–WP6, epic `test_C_libtooling-656`) | controlled surface + `br`-diamond / classical-arm `select` / `&&`‖`\|\|` / nested-AND / Q+Q condition / escape *diagnostic* + e2e | ✅ **DONE** |
| **Phase 4.2** (epic `test_C_libtooling-mux`) | `[≥1 tainted arm]` data mux — mux.1 (mixed) + mux.2 (both-handle) | ✅ **DONE** (reopened only for Family F i64 width, fixed in 4.3) |
| **Phase 4.3** (epic `test_C_libtooling-u6v`, §7) | realized-`-O1` `if`-menu completeness: Families A (multi-φ keystone), C (symmetric diamond), B1/B2 (angle-select diag+lower), F (mux i64 width), D (`switch` *diagnostic* guard) + 2 re-sweep findings | ✅ **DONE** — re-sweep 29 lowered / 4 diagnosed / 1 untouched; 0 crash, 0 silent miscompile |
| **Phase 4.1** (epic `test_C_libtooling-aht`, §8) | tainted `switch` *lowering* (WP15 value-merge select-chain, WP16 angle-select-chain) + quantum-controlled escape verdict (WP17) + gated multi-arm cascade (WP18) | ✅ **DONE** (2026-06-02) — value-merge + multi-way `if` + angle dispatch lower; escape rejects source-located; gated cascade → N-way controlled substitution; 86/86 lit |

Phase 4.1 (§8, WP15–WP18) **landed 2026-06-02**: the value-merge `switch` and
multi-way value `if` lower via the select-chain normalization, the angle
`switch` via the angle-select-chain, the gated multi-arm cascade via N-way
controlled substitution, and the quantum-controlled escape (`return`/`break`/
`goto`/`measure`) rejects by default with `!dbg` source location. The spike
also closed a silent-miscompile hole — a tainted `switch` lowered by `-O1` to a
jump TABLE is now diagnosed (a tainted memory-address/index guard). §8 records
the design, re-informed by a verified cross-check against the Bennett.jl /
Sturm.jl stack + the quantum-control literature (2026-06-02;
[`bennett-jl-comparison.md`](../../bennett-jl-comparison.md)). Open follow-ons
(filed): lowering the jump-table angle dispatch + the default-direct-to-merge
gated shape, and a P1 fix for a tainted `double`-φ feeding a rotation (diamond
-form angle merge, found in review).

---

## 0. Invariant recap (not new — the ground Phase 4 stands on)

Carried from Phase 3, restated so the decisions below are unambiguous:

> **A quantum register reference is always an `i32` handle; a comparison
> yields an `i32` flag handle (logically 1 qubit), never an `i1`.**

Two invariants Phase 4 *adds*, both binding:

- **One control wire per op.** Every controlled template takes exactly
  **one** `i32` control-flag handle, prepended as the first argument.
  There is no doubly-controlled template; multi-condition control
  (nesting, `&&`/`||`) is built by combining flags into a single fresh
  flag *upstream* (decision 2.7), never by widening the template
  signature.
- **Tainted condition is necessary and sufficient.** A `select`/`br`
  whose `i1` condition is in the taint set *is* a controlled region; one
  whose condition is classical has no physical content
  ([`backend.md`](../../backend.md) §8.4) and is left untouched. There is
  no source-level marker.

---

## 1. Scope

**In scope.** Recover and lower controlled regions from the realized
`-O1` control surface (decision 2.1):

- **Detection + normalization** of tainted `select i1` and tainted
  `br i1` diamonds to one internal shape `(control flag, gated
  value-defs / in-shadow ops)` (2.2).
- **Control-wire lowering**: reopen the Phase 3 seam — a compare feeding
  a `br`/`select` now lowers, as the **control flag** (2.3). Includes
  **Q+Q conditions** via a new handle→width side-table (2.4).
- **Compound conditions** `&&` / `||` (which `-O1` spells as `select i1`
  over flags) → a single combined flag (2.5).
- **φ/select dissolution** for the two reducible arm-taint cases (2.6):
  `[modified, original]` → RAUW to the in-place handle; `[classical,
  classical]` (constant *or* runtime variable) → controlled-add of a
  host-computed difference.
- **Controlled substitution**: in-shadow ops lower to the `_controlled`
  template variant with the flag prepended (2.10), folded into the
  taint-driven lowering rather than a post-pass rewrite.
- **Nested control** via the single-flag AND model (2.7).
- **Flag lifecycle**: the control flag's compute + uncompute are
  bracketed *here*, LIFO for nests (2.9).
- **Controlled template surface**: extend `opcode_table.yaml` +
  `gen_templates.py` with `controlled` / `controlled_inv` axes, the
  controlled rotation/gate runtime symbols, and the `cqrt_toffoli`
  flag-conjunction primitive; regenerate the header; CI hash (2.8).

**Out of scope.** See §5. Load-bearing exclusions: tainted-arm select
multiplexer (a *pass-side* reduction onto the already-generated `_controlled`
HH adder — **no new primitive**; Phase 4.2 — beads
[`test_C_libtooling-mux`](../../../.beads/issues.jsonl)); tainted `switch` and
quantum-controlled escape (Phase 4.1 — beads
[`test_C_libtooling-aht`](../../../.beads/issues.jsonl)); data-handle
uncomputation (Phase 5); manual inversion (Phase 7); real template bodies
(post-freeze).

---

## 2. Design decisions

Each was resolved during PRD-discovery and is binding.

### 2.1 Lower the realized `-O1` control menu, not the C `if`

Phase 4's spine, established by compiling representative quantum-`if`
patterns at `clang -O1 -emit-llvm` (the real Stage-1 command). `-O1`
**dissolves most control flow before the pass sees it**; the pass must
target what survives, not the source braces. The catalog:

| C pattern | `-O1` shape | Owner |
|---|---|---|
| `if(q) y += 1;` / `y += a;` | branchless `add y, zext(q-cmp)` / `add y, select(cmp,a,0)` | **Phase 3 already** (flag-arithmetic) |
| `if(q) y = A; else y = B;` (classical arms) | `select i1 cmp, A, B` | **Phase 4** — 2.6 reduction |
| `if(q) y = gate(y);` (opaque body) | real `br` diamond + `φ[modified, orig]` | **Phase 4** — 2.6 + 2.10 |
| `if(qa && qb)` / `if(qa \|\| qb)` | `select i1` = AND/OR of flags, then br/select | **Phase 4** — 2.5 |
| `if / else if / else` | nested `select`s | **Phase 4** — composed 2.6 |
| `if(q) y = f(q); else y = C;` (one handle arm) | `select i1 cmp, hq, C` | **Phase 4.2** (`-mux.1`) — HH-controlled-add reduction |
| `if(q) y = hp; else y = hq;` (both handle arms) | `select i1 cmp, hp, hq` | **Phase 4.2** (`-mux.2`) — `alloc(0)` + 2 controlled adds |
| `switch(q)` | real `switch` + N-way φ | **Phase 4.1** (`-aht.1` / Family E) |
| `if(q) return …;` / `break` / measure-in-arm | `br` + φ with **escape** in an arm | **Phase 4.1** (`-aht.2`) |
| `if(q){ g(u); g(v); }` (≥2 gated handles) | `br` diamond + **N φ** at merge | **Phase 4.3** (Family A) — *broke core* |
| `if(q){ y = …; g(u); }` (data **and** gate in one arm) | `br` diamond + data-φ + gate-φ | **Phase 4.3** (Family A) — *broke core* |
| `if(q){ g(u); } else { g(v); }` (gates in both arms) | symmetric two-content-arm `br` diamond | **Phase 4.3** (Family C) — *broke core* |
| `if(q){ rz(u,a); } else { rz(u,b); }` (differ by angle) | `rz(u, select(cmp, a, b))` — **angle select** | **Phase 4.3** (Family B) — *broke core* |

> **⚠ This catalog was incomplete (corrected 2026-06-02).** The last four
> rows were added after a post-landing audit (§7) found Phase 4 core
> crashes or silently miscompiles on them; the `[DONE]` marking is
> reopened. The audit also reclassified the `switch` row: `-O1` only keeps
> a real `switch` for side-effecting/sparse arms (dense constant arms fold
> to `select`s the pass already lowers), and the filed `-lowerswitch`
> default is **not** free — see §7, Family E.

The first row is the key reconciliation: `if (q) y += k` is **already
correct** under Phase 3 as `y + flag·k` — adding the flag register to `y`
*is* a controlled increment. A large slice of "quantum control" never
reaches Phase 4. Fixtures are derived from **real `-O1` output**; the
compiled menu is the IMPLEMENTATION appendix.

### 2.2 Normalize `select` and `br` to one internal shape

`-O1` chooses `select` vs `br`-diamond by **arm cost**, not canonically:
a cheap/pure/speculatable arm becomes a `select`; a side-effecting or
opaque-call arm keeps a `br` diamond + φ. Phase 4 therefore must accept
**both** and cannot assume one form. They are interconvertible
(`select i1 %f, A, B` ≡ a 2-block diamond with `φ [A, B]`), so the pass
canonicalizes to one internal representation —
`(control-flag, list of gated value-defs / in-shadow ops)` — and lowers
that, independent of source form. `br`-sourced regions additionally get
**CFG linearization** (2.11) after substitution; `select`-sourced regions
have no CFG to collapse.

### 2.3 Reopen the Phase 3 seam: the condition lowers as a control flag

Phase 3's `isDataPositionCompare` left any compare feeding a `br i1` /
`select i1` as a raw `i1` "for Phase 4"
([phase-03 PRD §2.8](../phase-03-opcode-lowering/PRD.md)). Phase 4 lowers
it — **as the control wire**, reusing the *same* Phase 3 flag-handle path
(`cq_template_icmp_<pred>_<W>_hl(handle, classical) → i32` flag). The only
change at the seam is routing the flag to controlled ops instead of to a
`zext`/measure. A `select`/`br` on a **classical** condition is not a
quantum control (§0) and stays untouched.

### 2.4 Q+Q control conditions: a handle→width side-table

`if (q1 < q2)` compiles to `icmp slt i32 %h1, %h2` (both tainted). Phase 3
**refuses** Q+Q compares (`CompareLowering.cpp` — once both operands are
laundered `i32` handles the logical compare width is unrecoverable, so it
diagnoses and bails). Phase 4 needs them. Resolution: record each handle's
logical ABI width at its `cqrt_alloc`/rotation mint point in a
`DenseMap<Value*, AbiWidth>` carried in `TaintSet` (alongside
`BirthOrder`). A Q+Q compare reads its width from the side-table; the
resulting flag is `cq_template_icmp_<pred>_<W>` (HH shape, no `_hl`). This
closes the Phase 3 Q+Q gap — for the **control** path; Q+Q compares in
pure data position remain Phase 3's deferral until the same table is
consulted there.

### 2.5 Compound conditions `&&` / `||` are flag conjunctions

`-O1` spells short-circuit conditions as `i1` selects over flags:
`qa>0 && qb>0` → `select i1 %fa, i1 %fb, i1 false` (logical AND);
`qa>0 || qb>0` → `select i1 %fa, i1 true, i1 %fb` (logical OR). These are
**not** data selects — they combine two flags into one control wire, the
*same operation nesting needs* (2.7). AND → `cqrt_toffoli(fa, fb, |0⟩)`
into a fresh flag; OR → De Morgan (`X`-bracket the inputs/output around a
Toffoli). So `&&`/`||` and nested braces share one code path: "combine
flags into a single fresh flag."

### 2.6 φ/select dissolution — partition by arm taint

The merge node (`φ` from a `br`, or the `select` directly) is **not**
`cq_phi`; it is a stock LLVM SSA merge. It has no `cq_template_*` to
attach `_controlled` to, so it gets its own dissolution, keyed on the
taint of its two arms:

- **`[modified, original]`** — a controlled gate already mutated the
  register in place (e.g. `φ [rotated_y, y]`): RAUW the merge to the
  in-place handle; emit no merge value. This is the common `br`-diamond
  case. **Correction (2026-06-02):** as implemented this dissolved only
  the *single front* φ (`region.Merge = &MergeBB->front()`), assuming one
  gated handle per region. A merge with ≥2 φ (≥2 gated handles, or a data
  assignment alongside a gate) leaks the rest and crashes — Family A (§7),
  the audit's largest defect. Dissolution must iterate **every** merge φ.
- **`[classical, classical]`** — constant *or* runtime classical
  variable: `y = B + flag·(A−B)`. Emit a **host** classical `sub`
  (`%d = A − B`, stays a plain LLVM instruction) and one
  `cq_template_add_<W>_hl_controlled(flag, result, %d)` onto a register
  initialized to `B` (`cqrt_alloc_<W>(B)`). The `_hl` slot has always
  been a *classical operand* slot (literal or runtime), so **variable
  arms reduce identically to constant arms** — covering the
  [`backend.md`](../../backend.md) §8.2 / §4.4 headline `φ [10, 20]`.
- **`[≥1 tainted arm]`** — deferred to Phase 4.2 (§5), but **pass-side
  only, not a new primitive**: the already-generated HH controlled adder
  `cq_template_add_<W>_controlled(flag, h, h)` *is* the mux. One classical
  arm → seed `cqrt_alloc(C)` and add the register delta `Q−C` controlled
  (`-mux.1`); both arms handles → `cqrt_alloc(0)` + two controlled adds
  `f·hp + ¬f·hq` (`-mux.2`). The earlier "needs a `cswap`/Fredkin" note was
  wrong — `cswap` is only an in-place alternative.

### 2.7 Nesting: the single-flag AND model (reconciles §8.5 vs Done-when)

Every controlled op is controlled by **exactly one** flag (§0). Nest by
computing the inner flag, AND-ing it with the enclosing flag into a fresh
flag — `f_both = cqrt_toffoli(f_outer, f_inner, |0⟩)` — and controlling the
inner region's ops on `f_both`; uncompute LIFO (2.9). Depth-N reuses the
depth-1 substitution verbatim; the only added primitive is the flag
conjunction.

**Reconciliation.** [`backend.md`](../../backend.md) §8.5 lists nested
branches as "downstream backend work," but the single-flag model makes
nesting a cheap reuse of depth-1 + one `cqrt_toffoli`, so Phase 4
**includes** nested control, matching ROADMAP's Phase 4 "Done when
… including nested." Templates stay single-control regardless of depth.

### 2.8 Controlled template surface: `controlled` + `controlled_inv` axes

The controlled symbols do not exist yet (`cq_templates.h` ships 780 decls,
**zero** `_controlled`; the yaml grid is `{fwd,inv} × {qq,hl,lh}`). Phase 4
pulls this slice of Phase 8 forward, exactly as Phase 3 regenerated for
`frem`/`_lh`:

- Add `controlled` and `controlled_inv` to the variant grid.
  `controlled_inv` is **required** (confirmed in PRD-discovery): inverting
  a controlled region — Phase 5 uncomputation of a controlled gate, or a
  Phase 7 `cq_invert` bracket around one — cannot reuse the plain `_inv`
  because the control wire must thread through.
- **Naming**: `_controlled` follows the shape suffix; `_inv` stays last —
  `cq_template_<op>[_<pred>]_<W>[_<from_to>][_hl|_lh]_controlled[_inv]`.
  The control flag is always argument 0.
- **Runtime**: `cqrt_rz_<W>_controlled[_inv]` (controlled `cq_phi`),
  controlled forms of the §11.4 gate placeholders, and the
  `cqrt_toffoli` / `cqrt_toffoli_inv` flag-conjunction primitive.
- Regenerate `runtime/cq_templates.{h,c}`; update the SHA preamble; CI
  verifies. Phase 8 still owns full-surface exhaustiveness + the freeze.

### 2.9 The control flag's lifecycle is bracketed in Phase 4

The control flag is a fresh ancilla minted by the condition lowering
(2.3). Phase 4 emits **both** its compute (compare → flag) and its
uncompute (the compare template's `_inv`) bracketing the controlled
region, LIFO for nested flags. Rationale: the flag is Phase 4's own
region-scoped scratch — structurally bounded, not a data handle with an
SSA last-use. **Phase 5's last-use uncomputation owns *data* handles, not
control scratch**, so the seam is clean: Phase 4 hands Phase 5 a region
whose control ancillas are already balanced.

### 2.10 Fold control detection into taint analysis (lower-as-controlled)

The prototype's `cq-control` substituted `_controlled` *after* lowering
because it had no taint analysis (it keyed off `cq_when` markers). The
production pass does better: detect tainted control regions during/after
`propagate` (before `lowerOps`), build a control-map
`value → controlling flag`, and have `lowerOps` emit the `_controlled`
variant **directly** for in-shadow ops. One walk, no re-point. The merge
φ/select (no `cq_template_*` to substitute) is handled by the separate
dissolution step (2.6). New `ControlledLowering` module owns detection +
flag lowering + dissolution + linearization; `OpcodeLowering` consults the
control-map.

### 2.11 CFG linearization for `br`-sourced regions

After in-shadow ops are substituted to controlled straight-line form on
in-place handles and the merge φ is dissolved (2.6), the diamond's branch
and arm blocks are dead. Erase the `br i1`, splice the arm's (now
controlled, unconditional) ops into the predecessor, and merge to a single
block. Dissolve the φ **before** erasing, so no use dangles; the result is
`opt -verify` clean with no `br i32` ever created.

---

## 3. Deliverables

- **`opcode_table.yaml`** — add `controlled` / `controlled_inv` variants
  across the in-scope ops/widths/shapes; add `cqrt_toffoli[_inv]` and the
  `cqrt_rz_<W>_controlled[_inv]` / controlled gate symbols.
- **Runtime header/source** — regenerate `runtime/cq_templates.{h,c}` via
  `gen_templates.py`; update the SHA preamble; CI verifies the hash.
- **`TaintSet`** — add the `handle → AbiWidth` side-table (2.4) and the
  `value → control-flag` control-map (2.10); populate width at
  alloc/rotation mint points.
- **New `ControlledLowering` module** (`ir-pass/src/`) — tainted
  `select`/`br` detection + normalization (2.2), control-wire lowering
  (2.3, incl. Q+Q 2.4), flag-conjunction for `&&`/`||`/nesting (2.5, 2.7),
  φ/select dissolution (2.6), flag-lifecycle bracketing (2.9), CFG
  linearization (2.11).
- **`CompareLowering`** — `isDataPositionCompare` reopened: branch/select
  feeders now lower as control flags (2.3).
- **`OpcodeLowering`** — consult the control-map; emit `_controlled`
  variants for in-shadow ops (2.10).
- **LIT fixtures** — one per shape: single-armed controlled gate
  (`br`-diamond, φ-dissolution + linearization); classical-arm
  `select` (const and runtime-variable); `&&` and `||`
  flag-conjunction; nested (`cqrt_toffoli`, LIFO uncompute); Q+Q
  condition (side-table width); classical-condition `select`/`br` left
  untouched; quantum-controlled escape emits the loud diagnostic.
- **e2e trace smokes** — a controlled-gate program and a classical-arm
  merge program, run-and-diff against golden logs.
- **Doc cross-links** — mark ROADMAP Phase 4 done-criteria coverage; note
  the reconciliations vs [`backend.md`](../../backend.md) §8 (the `-O1`
  menu in 2.1; nested-in-core vs §8.5 in 2.7).

---

## 4. Done criteria

- A tainted single-armed `if` with a gate body lowers to the controlled
  gate (`cqrt_rz_<W>_controlled(flag, h, θ)`), the φ dissolves to the
  in-place handle, the diamond linearizes, and `opt -verify` is clean.
- A tainted `if/else` over classical arms (constant **and** runtime
  variable) lowers to `cqrt_alloc(B)` + `cq_template_add_<W>_hl_controlled`
  with a host-computed difference.
- `&&` / `||` conditions lower to a single combined flag via
  `cqrt_toffoli` (+ De Morgan `X`s for `||`) and then a controlled op.
- A nested `if` lowers with one `cqrt_toffoli` per nesting level, every op
  single-controlled, flags uncomputed LIFO.
- A Q+Q condition (`if (q1 < q2)`) lowers to a flag from the HH compare
  using the handle→width side-table.
- Each control flag carries a balanced compute/uncompute bracket; the
  region hands Phase 5 no dangling control ancilla.
- A classical-condition `select`/`br` is left byte-untouched and passes
  `opt -verify`.
- A quantum-controlled escape (`if (q) return …;`) emits the loud
  `DiagnosticInfoUnsupported` (refined to reject/bridge in Phase 4.1).
- The two e2e trace smokes diff clean against their goldens.

---

## 5. Out of scope

- **Tainted-arm select multiplexer** — `select i1 %f, A, B` (tainted
  condition, ≥1 tainted value arm). Deferred to **Phase 4.2** (beads
  [`test_C_libtooling-mux`](../../../.beads/issues.jsonl)), NOT Phase 4.1.
  **Correction (2026-06-01):** this needs **no new runtime primitive** — the
  earlier "needs a `cqrt_cswap`/Fredkin mux" claim was wrong. The two-handle
  `_controlled` adder `cq_template_<op>_<W>_controlled(flag, h, h)` (+ `_inv`)
  is already generated across the op×width grid (§2.8 / D1) and minted by
  `ControlledSymbols::controlledDataTemplateFn(stem, W, Shape::QQ, inv)`
  (`Shape::QQ` carries no `_hl`/`_lh` infix → the bare `_controlled` symbol).
  The classical-arm reduction (2.6) generalizes directly:
  - **one classical arm** (`-mux.1`, the common case) — seed
    `cqrt_alloc_<W>(C)` from the classical arm, build the register delta
    `Q − C` with the uncontrolled `cq_template_sub_<W>_hl`, then one HH
    `cq_template_add_<W>_controlled(ctrl, regC, delta)`. Identical shape to
    2.6 with `_hl`→`_hh` and a register (not host) delta.
  - **both arms handles** (`-mux.2`) — `cqrt_alloc_<W>(0)` + two controlled
    adds `f·hp + ¬f·hq` (the `¬f` via a LIFO-bracketed `cqrt_x`, reusing the
    2.5 De Morgan machinery); both source handles are read, so they survive
    for their other uses.
  Work is **pass-side only** (ControlDetection guard + a MergeDissolution
  branch); `cqrt_cswap`/Fredkin remains a future *in-place* alternative, not a
  requirement. Until this lands the unsupported shape must be **diagnosed, not
  silently passed through** (beads
  [`test_C_libtooling-mux-diag`](../../../.beads/issues.jsonl)).
- **Tainted `switch`** — Phase 4.1, beads
  [`test_C_libtooling-aht.1`](../../../.beads/issues.jsonl). **Update
  (2026-06-02):** the "pre-run stock `-lowerswitch`" default is **not**
  free — `-lowerswitch` emits a balanced pivot *tree* (`icmp slt`/`eq` +
  `br` with shared multi-pred merges) the pass currently crashes on. It
  becomes viable only after Phase 4.3 Families A + C + a closed-diamond
  guard land. The surviving `switch` silently miscompiles today (branches
  on the quantum handle id), so Phase 4.3 adds a **diagnostic guard**
  (Family D) while the lowering stays here. See §7, Families D + E.
- **Quantum-controlled escape** — `return`/`break`/`goto`/measure inside a
  tainted-branch arm. Phase 4 emits the loud diagnostic only; the
  reject-vs-`-fcq-measurement-bridge` decision is Phase 4.1, beads
  [`test_C_libtooling-aht.2`](../../../.beads/issues.jsonl).
- **Data-handle uncomputation** / `cqrt_free` (Phase 5). Phase 4 brackets
  only the **control** flag (2.9).
- **Manual inversion** brackets (Phase 7) — but `controlled_inv` templates
  are generated now (2.8) for their and Phase 5's use.
- **Controlled allocation** — a `cq_theta` (fresh alloc) inside a shadow
  (controlled register birth). Flagged as an edge in §6; defer unless a
  fixture demands it.
- **Loops with tainted bounds** (quantum-while, post-freeze) and **real
  template bodies** (post-freeze).

---

## 6. Risks

- **`-O1` already dissolved the region (2.1).** The biggest surprise:
  `if (q) y += k` arrives as plain Q+Q arithmetic, *not* a controlled
  region — Phase 4 must **not** try to "recover" control that `-O1`
  correctly folded into a flag-add. Mitigation: the compiled menu (2.1)
  bounds what Phase 4 must see; fixtures derived from real `-O1` output;
  Phase 3 owns the flag-arithmetic rows.
- **φ-dissolution misclassification (2.6).** RAUW-ing a `[modified,
  original]` merge to the wrong handle, or treating a `[classical,
  classical]` merge as `[modified, original]`, corrupts the result.
  Mitigation: classify strictly by arm membership in the taint set + the
  in-shadow def set; one LIT fixture per arm-taint case.
- **Handle→width side-table staleness (2.4).** A handle whose width is not
  recorded at its mint point yields a wrong-width Q+Q flag symbol.
  Mitigation: populate at every `cqrt_alloc`/rotation; fixture per Q+Q
  width.
- **Flag uncompute ordering (2.9).** Non-LIFO uncompute of nested flags
  leaves a garbage ancilla entangled with the data. Mitigation: an
  explicit flag stack; a nested-region fixture asserting the
  compute/uncompute order.
- **Cross-type RAUW on dissolution (2.11).** Dissolving an `i1`/`i32`
  merge mirrors Phase 3's flag RAUW (laundered by erasure on an
  assertions-off LLVM-19). Mitigation: per-fixture `opt -verify` RUN
  lines, exactly as Phase 3.
- **Controlled surface 2× growth vs the Phase 8 freeze (2.8).**
  Autogen-cheap but enlarges the frozen ABI. Accepted: controlled +
  controlled_inv are load-bearing for the whole control/inversion story;
  Phase 8 freezes the union.
- **CFG linearization hazard (2.11).** Erasing the branch/arm blocks while
  a use of the φ or an arm value still dangles. Mitigation: dissolve the φ
  first, then erase; collection-before-mutation (Phase 3 discipline);
  `opt -verify` gate.

---

## 7. Phase 4.3 — realized-`-O1` control-shape completeness (post-landing audit, 2026-06-02)

> **Status — COMPLETE (2026-06-02).** All six families (A keystone multi-φ,
> C symmetric, B1/B2 angle diagnose+lower, D switch diagnostic, F mux i64)
> landed as WP7–WP12, plus two findings surfaced by the close-gate re-sweep:
> false-successor arm polarity + value-propagated Pred-edge φ (`-u6v.7`), and
> a catch-all diagnostic for unhandled tainted branches — quantum loop
> `break`/`goto` (`-u6v.8`). The re-sweep (34 representative `if`-shapes across
> the 8 categories plus comparator/negation variants) is **29 lowered + 4
> loudly diagnosed + 1 classical-`switch` untouched — zero crashes, zero silent
> miscompiles**. 9 new LIT fixtures; `ir-pass-lit` 74/74 (+1 XFAIL). The
> `switch` LOWERING (Family E) and the realized `break`/`goto`/`return` escape
> lowering remain Phase 4.1 (epic `test_C_libtooling-aht`). Epic
> `test_C_libtooling-u6v` closed.

**Why this section exists.** Phase 4 core (WP0–WP6) was marked `[DONE]`
against the §2.1 catalog — but that catalog was compiled from a *narrow*
set of `if` probes. A follow-up exhaustive sweep — **44** representative
quantum-`if` shapes compiled at real `clang -O1`, each run through the
pass, and **each failure adversarially re-verified from scratch** with its
root cause pinned to `file:line` — found the catalog materially
incomplete:

| audit verdict | count | meaning |
|---|---|---|
| ✅ lowered | 14 | the happy paths Phase 4 core actually covers |
| 🔴 crash | 21 | broken-module / LLVM verifier abort |
| ⚠️ silent miscompile | 7 | **valid IR that links, runs, and returns garbage** |
| 🟡 clean diagnostic | 2 | the only escapes that work (`return`/`measure`) |

**28 of 44 ordinary `if`-shapes are mis-handled, all confirmed real.**
Phase 4 core handles only the single-gated-handle, classical-arm,
single-φ happy paths. The `[DONE]` marking is **reopened**: Phase 4 is
feature-complete on its happy paths but not on the realized `-O1` `if`
menu. The failures cluster into **six root-cause families**; each has a
verified cause and a fix decision below. (The sweep's confirmation went
both ways — it also *corrected* probe attributions, e.g. the `break`
crash is loop+multi-φ, not flag-conjunction; and the `lowerswitch`+gate
case is a segfault, not the milder miscompile first claimed.)

### 7.1 The six families

**Family A — multi-φ merge dissolution (the keystone).**
*Cause:* detection records `region.Merge = &MergeBB->front()`
(`ControlDetection.cpp:407`; `:363` for nested-AND) — a single
`Instruction*` — and `dissolveBranchPhi` (`MergeDissolution.cpp:68`)
dissolves only that one φ. A merge with ≥2 φ leaks the rest, which CFG
linearization (`CFGLinearization.cpp:56`) splices mid-block →
`PHI nodes not grouped at top of basic block` broken module (or, depending
on φ order, a verify-clean **wrong** module).
*Hits:* ≥2 gated handles in one arm; a data assignment **and** a gate in
one arm (every mixed-arm shape); multi-handle arms under `&&`/`||`;
`goto`-reshaped escapes. **~15 crashes + 2 silent miscompiles — the
largest family.**
*Fix:* dissolve **every** φ in the merge block by its `region.Pred`-edge
incoming value; drop the single-merge-φ assumption (`ControlRegion::Merge`
becomes a set / the dissolver iterates `MergeBB->phis()`). One contained
change clears the majority of the audit's failures. **Sequence first.**

**Family B — angle-select misclassification (a gate sunk to its classical
rotation parameter).**
*Cause:* the SelectRegion admission gate (`ControlDetection.cpp:323`)
excludes only `i1`-typed selects; it admits floating-point (and non-handle
integer) selects as data muxes. When `-O1` sinks
`if(q){rz(u,a);}else{rz(u,b);}` into `rz(u, select(cmp, a, b))`, the select
is over the **classical `double` angle**, and `dissolveSelect` emits a
controlled-add onto an allocated handle → type-mismatch crash (or a silent
miscompile when the angle is computed branchlessly).
*Hits:* symmetric-by-angle `if/else`; chained angle muxes; the
dense-`switch` self-fold.
*Decision (confirmed 2026-06-02): **diagnose-first, then lower.***
- **B1** — add an fp / non-handle guard to the SelectRegion gate so the
  shape is loudly diagnosed instead of mis-lowered (mirrors the
  `-mux-diag` precedent).
- **B2** — lower correctly as **controlled-rotation-by-difference**:
  `Rz(b)` unconditional, then `ctrl-Rz(a−b)` on the flag — valid because
  Ry/Rz are angle-additive (`Rz(b + f·(a−b)) = Rz(b)·ctrl_f Rz(a−b)`).
- plus a taint-discipline fix: the angle operand (arg 1) of
  `cq_theta`/`cq_phi` is a classical scalar and must never enter the
  quantum-handle taint set.

**Family C — symmetric (two-content-arm) diamond.**
*Cause:* `matchDiamond` (`ControlDetection.cpp:208-233`) accepts only a
*one*-content-arm diamond (one arm has content; the sibling **is** the
merge). A symmetric `if(q){g}else{g}` where both arms hold gates and both
fall through to a common merge matches nothing → it falls to
`branchEscapes`, which (arms reconverge, no `ret`/measure) treats it as
"benign control flow we do not lower" → gates lowered **uncontrolled**, a
residual `br i1` on the quantum handle survives. **Silent miscompile.**
*Fix:* `matchDiamond` must accept the symmetric shape — both successors
single-pred, both branching to a common merge `M` carrying φ(s).

**Family D — tainted `switch` (no `SwitchInst` handling at all).**
*Cause:* detection only does `dyn_cast<BranchInst>`
(`ControlDetection.cpp:343`); `grep -rn Switch ir-pass/src` returns zero.
A `switch(q)` surviving `-O1` branches on the quantum **handle id**; the
pass leaves it untouched and lowers arm gates uncontrolled. **Silent
miscompile.**
*Fix (this phase, safety only):* detect a tainted-scrutinee `SwitchInst`
→ emit the loud diagnostic. The *lowering* stays deferred to Phase 4.1
(Family E). Cheap; kills the silent miscompile.

**Family E — `-lowerswitch` pivot tree mis-handled → Phase 4.1.**
> **→ Superseded by §8.2 (2026-06-02).** The `-lowerswitch` route below is
> *not* the chosen Phase 4.1 direction. Phase 4.1 instead normalizes a
> tainted `switch` to a **data-flow `select` chain** (§8.2), which never
> produces the pivot-tree `br`-diamonds analyzed here — so the crash class
> below cannot arise, and no N-way φ dissolution / closed-diamond guard is
> needed. The analysis is retained as the record of *why* `-lowerswitch` was
> rejected.

*Finding:* the filed Phase 4.1 default ("pre-run stock `-lowerswitch`") is
**not** a free ride. `-lowerswitch` lowers a tainted switch into a
balanced pivot **tree** of `icmp slt`/`icmp eq` + conditional `br` with
**shared multi-pred** φ-merges. `matchDiamond` accepts a shared multi-pred
merge as a diamond merge; linearization then frees a still-referenced
block → crash; nested range-compare arms aren't recognized → swallowed.
*Implication:* doing `if` first is a **hard dependency** for switch, not a
priority — switch-via-`lowerswitch` becomes viable only after Families A +
C land, and even then Phase 4.1 must add a **closed-diamond guard**
(`matchDiamond`: require the merge have exactly two preds — `Pred` and
`Arm`) and re-verify the pivot-tree path. Budget a *small dedicated*
switch follow-up; do not assume free.

**Family F — mux width-collapse at i64 (a latent Phase 4.2 bug).**
*Cause:* `dissolveSelect` reads the reduction width from
`abiWidthFromType(A->getType())` (`MergeDissolution.cpp:115`); for a
both-tainted mux whose arms are direct `cq_theta_sll` (i64) results
laundered to i32 handles, it reads **i32**, emitting `cqrt_alloc_i32` +
`cq_template_add_i32_controlled` to accumulate i64 data — silent
width-collapse. (Phase 4.2 i32 muxes are unaffected.)
*Fix:* recover the logical width from the `taint.HandleWidth` side-table
(§2.4) for tainted arms, not from the SSA arm type.

### 7.2 Re-scoped sequence

| order | family | severity | fix | owner phase |
|---|---|---|---|---|
| 1 | **A** multi-φ dissolution | 🔴 ~15 crash + 2 silent | iterate every merge φ | **4.3** (keystone) |
| 2 | **C** symmetric diamond | ⚠️ silent | accept two-content-arm common-merge diamond | **4.3** |
| 3 | **B1** angle-select diagnostic | 🔴/⚠️ | fp/non-handle guard on SelectRegion → diagnose | **4.3** |
| 4 | **B2** angle-select lowering | (B1) | controlled-rotation-by-difference + angle taint-discipline | **4.3** |
| 5 | **F** mux i64 width | ⚠️ silent | width from `HandleWidth`, not arm type | **4.3** (reopens 4.2) |
| 6 | **D** switch diagnostic guard | ⚠️ silent | diagnose tainted `SwitchInst` | **4.3** (safety) |
| — | **E** switch lowering | 🔴/⚠️ | `-lowerswitch` + closed-diamond guard, re-verify | **4.1** (depends on A+C) |

The safety layer (B1, D) and the keystone (A) land first — they convert
every crash/silent-miscompile into either a correct lowering or a loud
diagnostic, so no shape miscompiles silently after Phase 4.3 begins.

### 7.3 Scope split vs Phase 4.1 / 4.2

- **Phase 4.3 (new) — `if` completeness:** Families A, C, B (diagnose +
  lower), F; plus the Family D `switch` *diagnostic guard* (safety only).
- **Phase 4.1 (re-informed) — `switch` + escape lowering:** Family E
  (`switch` lowering) and the escape reject-vs-`-fcq-measurement-bridge`
  decision (`-aht.2`), which now also covers the `goto`/`break` escapes
  that currently crash through Family A. **Design finalized in §8**
  (2026-06-02): `switch` → **select-chain normalization** (supersedes the
  `-lowerswitch` path); escape verdict = **reject-default**.
- **Phase 4.2 — mux:** landed, reopened only for Family F (i64 width).

**Audit method (reproducible).** 8-category fan-out over the `if`-shape
space; per shape: `clang -I<inc> -include CQ.h -O1 -emit-llvm` →
`opt -load-pass-plugin libCQPass.so -passes=cq-lowering` →
`opt -passes=verify`; each crash/silent-miscompile re-derived and
confirmed by an independent adversarial verifier. The rubric treats a
verify-clean module that still carries a `switch`/`br i1` on a quantum
handle as a **silent miscompile**, not a pass.

---

## 8. Phase 4.1 — `switch` lowering + quantum-controlled escape (design)

> **Status — DONE (landed 2026-06-02; design finalized 2026-06-02).** Tracked
> by epic `test_C_libtooling-aht` (`-aht.1` switch + angle, `-aht.2` escape,
> `-aht.3` gated multi-arm cascade §8.5 — all closed). Re-informed by a
> **verified** cross-check against Tobias Osborne's Julia stack —
> **Bennett.jl** (classical→reversible compiler) and **Sturm.jl** (quantum
> DSL) — plus the quantum-control-flow literature (Quantum Control Machine,
> Silq, Janus). Sources fetched + adversarially verified 2026-06-02; full
> write-up in [`bennett-jl-comparison.md`](../../bennett-jl-comparison.md).

### 8.1 The reframe — `switch` and multi-way `if` are one problem

At the opcode level CQ's job is uniform: **replace tainted ops with quantum
functionality**. A `switch (q)` and an `if/else if/else` chain on a tainted
scrutinee are the *same* construct — **multi-way dispatch** — and the right
move (the one Bennett also makes) is to **eliminate the N-way control by
reducing it to constructs the existing opcode pipeline already lowers**,
rather than to grow a bespoke N-way control-region matcher.

Bennett does this at extract time with `_expand_switches`: it desugars an
N-way `switch` into a **linear cascade of `icmp eq` + 2-way `br` diamonds**
(its `phi.jl` MUX-chain machinery then emits the gates). CQ makes the *same
move* but to a **different normal form** — because CQ's downstream is
opcode-replacement over data flow, not gate-emission over a CFG, the right
target is a **`select` chain**, not a `br` cascade. A `select` is the
value-form of an `if`; a `select` chain is the value-form of a `switch`.

This **supersedes the Family E `-lowerswitch` default** (§7.1):
`-lowerswitch` emits a balanced pivot *tree* with shared multi-pred
φ-merges that crash linearization. The select-chain normalization never
produces `br`-diamonds, so it sidesteps that entire failure class — and
needs **no new control region and no N-way φ dissolution** (the N-way φ
never forms).

### 8.2 Switch lowering — `normalizeTaintedSwitch` (data-flow, opcode-level)

A pass step wedged **between taint propagation and opcode/region lowering**:

```
taint propagation → normalizeTaintedSwitch → (control-region detect +) opcode lowering → cqrt_*
                    switch + N-way φ  ⇒  icmp-eq flags + select chain   (dissolveSelect — unchanged)
```

**Gate:** fire only on a tainted scrutinee
(`taint.Tainted.count(Sw->getCondition())`) — exactly where the Phase 4.3
Family D guard (WP12) currently diagnoses. A classical-scrutinee `switch`
stays untouched for the classical backend.

**Algorithm (value-merge form — the common case).** Read the case values
off the `SwitchInst` (`cases()` → `{ConstantInt, BasicBlock}`,
`getDefaultDest()`) and the per-arm values off the merge φ:

1. For each case `(val_k, block_k)`: `A_k` = the merge-φ incoming from
   `block_k`; `A_default` = the incoming from the default block.
2. Emit eq-flags + a nested select chain (default = innermost base):

   ```
   f_k = icmp eq %q, val_k
   acc = A_default ; acc = select f_k, A_k, acc      // folded per case
   ```

3. RAUW the merge φ with the final `acc`; delete the arm blocks, the
   `switch`, and the φ; fall the switch block straight through to the merge.

Before (post-`-O1`) → after:

```llvm
switch i32 %q, label %dflt [ i32 1,%c1  i32 2,%c2 ]   %f1 = icmp eq i32 %q, 1
c1/c2/dflt: br %merge                                  %f2 = icmp eq i32 %q, 2
merge: %y = phi [10,%c1],[20,%c2],[99,%dflt]           %s1 = select %f1, 10, 99   ; dflt = base
                                                       %y  = select %f2, 20, %s1
```

Then **existing opcode lowering finishes it, with zero new lowering code**:
`%f1,%f2` → `cqrt_template_icmp_eq_<W>_hl` flags (the same eq-flag the
`if (u != 5)` diamond path mints); `%s1` (`[classical,classical]`) →
`reduceClassicalMux` (WP4); `%y` (mixed) → `dissolveSelect` mux.1. Eq-flags
are mutually exclusive, so the nesting is order-independent and correct.

**Properties.**
1. **Scales to any N** — a linear chain of N eq-flags + N selects; sparse vs
   dense case values are identical (we never build a jump table).
2. **Sidesteps both Phase-4.3 gaps** — no N-way φ (collapsed to binary
   selects), and no shared-multi-pred-merge crash (no `br`-diamonds).
3. **Never inherits Bennett's `_expand_switches` U11 φ-rewrite trap** — CQ
   *reads then deletes* the φ; the merge becomes single-predecessor, so
   there is nothing to re-key.
4. **No new ABI** — reuses the select-mux template surface.
5. **New code is just the normalization** (read cases + φ, build the chain,
   delete the diamond); everything downstream is untouched.
6. Linear *depth* (N sequential controlled-adds) → a deep circuit for huge
   N; the log-depth fix (unary iteration / QROM, Babbush et al. 2018,
   arXiv:1805.03662) lives *below* the `cqrt_*` ABI and is a runtime/template
   concern, **not** a pass concern — the pass stays correct at any N.

**First-cut scope:** value-merge, `break`-terminated, clean reconverging
arms, merge predecessors = case/default blocks only (same gatekeepers as the
escape rule). Follow-ons: fall-through (no `break`), `default` as a real
body, sparse/range cases, merges with extra non-switch predecessors — each a
guard or diagnose-and-punt, as in the `if`-shape sweep.

### 8.3 Multi-way value `if` — comes along for free

The same normal form covers `if/else if/else` value dispatch. When `-O1`
already emits a `select` chain (`y = c1?A : c2?B : C`), `dissolveSelect`
lowers it **today** — it is exactly the shape §8.2 produces. When `-O1`
instead emits a `br` cascade (an N-way merge φ), the *same* select-chain
normalization, generalized to "any multi-way value merge → select chain,"
closes it — and with it the general N-way-φ case Phase 4.3 left to 4.1.

### 8.4 The rotation-parameter slice — angle-select-chain

A `switch`/`if` whose arms differ only in a **rotation parameter**
(`case k: rz(u, a_k)`) is the select-chain applied to the *angle*: `-O1`
sinks it to `rz(u, <select-chain over q>)`, which is the WP10 angle-select
(`reduceAngleSelect`) generalized from a single select to a select *chain* —
base rotation `Rz(a_default)` + one controlled-difference rotation per case
(LIFO-bracketed flags). Same mechanism as §8.2; specify it alongside (WP10
already notes the N-way generalization).

### 8.5 The gated multi-arm cascade — the one genuinely separate mechanism

The only multi-way shape that does **not** fold into the select form is a
cascade of arms with **arbitrary side-effecting gate bodies** (distinct gate
sequences / controlled arithmetic per case, not just a value or an angle).
There is no value to select; each arm's ops must become `_controlled` on its
eq-flag. This is the **controlled-region** path (the Phase 4.3 symmetric
two-content-arm diamond generalized to an N-way false-arm chain), *not* the
opcode/select path. It is the CQ analog of Bennett's `_expand_switches`
branch-cascade and is the right place for that **Option-B fallback** if a
real call site needs it. Tracked as a **separate follow-on** — do not
conflate with the select-chain unit.

### 8.6 Quantum-controlled escape — the verdict

A tainted-branch arm that **escapes** (`return`/`break`/`goto`, or a
`cq_measure` inside the arm) is not a clean controlled shadow. The
cross-check against the Julia stack and the literature is unambiguous and
**confirms the current loud-reject posture** as the correct terminal state,
not a stopgap:

- **Measurement under quantum control → reject, permanently.** Bennett has
  no measurement op at all (classical→reversible; measurement lives in
  Sturm/Orkan). Sturm forbids `measure`/`return` inside `when(q)`. Silq's
  rejected `condMeas` *is* this exact program — a measurement gated on a
  superposed predicate is unphysical (you would have to measure the control
  first). Keep the `DiagnosticInfoUnsupported`.
- **`return`/`break`/`goto` under quantum control → reject by default.**
  Bennett raises a loud, specific error on non-reconverging exits
  (`lower_loop!: IRRet in loop body … not supported`). The Quantum Control
  Machine result (arXiv:2304.15000) proves a superposed jump/return is
  non-injective and cannot be a unitary; the necessary-and-sufficient
  conditions are **injectivity** + **synchronization** (all branches
  reconverge to one join). Janus / reversible-flowchart theory bans
  arbitrary `goto`/`break`/`return` and proves (Structured Reversible
  Program Theorem) no expressive power is lost — the programmer refactors.
- **`-fcq-measurement-bridge` — accept only as an explicit demotion.** The
  bridge is sound **iff** framed honestly as *promoting quantum control to
  classical control via deferred measurement*: insert the measure **at the
  region boundary** (collapsing the predicate before the body), opt-in, with
  a loud diagnostic, and **statically reject** the case where the measured
  value re-enters a still-coherent region. That is exactly Silq's sanctioned
  fix and the OpenQASM-3 feed-forward model. Sold as a transparent lowering
  of "the same `if`," it is an anti-pattern (it silently changes observable
  behavior — Silq/Q#/Quipper refuse it). Sturm ships the *dual*
  (`deferred_measurement.jl`): recognize measure-then-classical-branch and
  **promote** it to a coherent controlled gate — a collapse-free
  optimization worth a separate future pass.

**Future-phase extension (recorded, not in scope) — `return`/`break` via
predication.** For the *bounded, reconverging* subset only — an exit that
reconverges at the post-dominator join with a classically-bounded enclosing
loop — the established technique is **done-flag (guard-qubit) predication**
(the quantum lift of classical if-conversion; QCM / Tower): allocate a
`retval` register **and** a `done` ancilla; on the exit predicate write
`retval` and set `done`; **control every op after the exit point on
`¬done`** (one more wire on the existing AND-into-Toffoli control stack);
the final return writes `retval` on `¬done`; **uncompute `done`** at
function exit (recompute the predicate from the still-live args, CNOT it
off) or it leaks as garbage entangled with the result. A true
non-reconverging escape stays rejected. Later phase — capture only.

### 8.7 What the cross-check confirms (don't rediscover)

| established mechanism | source (verified 2026-06-02) | CQ component |
|---|---|---|
| eliminate `switch` by reducing to the existing dispatch machinery | Bennett `_expand_switches` (extract-time desugar) | §8.2 `normalizeTaintedSwitch` (to **selects**, not `br`) |
| controlled-rotation-by-difference for parameter dispatch | Ry/Rz angle-additivity (Sturm rotations) | §8.4 angle-select-chain (WP10 generalized) |
| reject non-reconverging exit at the structure break | Bennett `cfg.jl`; QCM injectivity+synchronization | §8.6 escape diagnostic |
| reject measurement under quantum control | Silq `condMeas`; Sturm `when` rule; Q#/Quipper | §8.6 measure diagnostic |
| deferred-measurement: measure-then-branch → controlled gate | Sturm `deferred_measurement.jl` (Nielsen–Chuang §4.4) | the collapse-free dual to the bridge (future pass) |
| done-flag predication for bounded reconverging exits | QCM / Tower / classical if-conversion | §8.6 future-phase `return`/`break` extension |
| gate-level depth opt (unary iteration / QROM) | Babbush et al. 2018 (arXiv:1805.03662) | **below** the `cqrt_*` ABI — runtime/template, not pass |
