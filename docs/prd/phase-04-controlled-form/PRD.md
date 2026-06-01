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

**Out of scope.** See §5. Load-bearing exclusions: handle-arm / mixed-arm
multiplexer (needs a `cswap`/Fredkin primitive); tainted `switch` and
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
| `if(q) y = hp; else y = hq;` (handle arms) | `select i1 cmp, hp, hq` | **out (§5)** — needs mux |
| `switch(q)` | real `switch` + N-way φ | **Phase 4.1** (`-aht.1`) |
| `if(q) return …;` / `break` / measure-in-arm | `br` + φ with **escape** in an arm | **Phase 4.1** (`-aht.2`) |

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
  case.
- **`[classical, classical]`** — constant *or* runtime classical
  variable: `y = B + flag·(A−B)`. Emit a **host** classical `sub`
  (`%d = A − B`, stays a plain LLVM instruction) and one
  `cq_template_add_<W>_hl_controlled(flag, result, %d)` onto a register
  initialized to `B` (`cqrt_alloc_<W>(B)`). The `_hl` slot has always
  been a *classical operand* slot (literal or runtime), so **variable
  arms reduce identically to constant arms** — covering the
  [`backend.md`](../../backend.md) §8.2 / §4.4 headline `φ [10, 20]`.
- **`[≥1 tainted arm]`** — deferred (§5); needs a true reversible
  multiplexer.

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

- **Handle-arm / mixed-arm multiplexer** — `select i1 %f, %hp, %hq` (≥1
  tainted arm). The classical-arm reduction (2.6) does not apply; this
  needs a true reversible mux (`cqrt_cswap` / Fredkin) plus its
  controlled/inverse forms. Deferred (candidate follow-up; not Phase 4.1,
  which is switch + escape).
- **Tainted `switch`** — Phase 4.1, beads
  [`test_C_libtooling-aht.1`](../../../.beads/issues.jsonl) (default:
  pre-run stock `-lowerswitch`).
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
